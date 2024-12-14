// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SmartCredit (MVP) - Tokens y Ajustes por Liquidez
 * @author vvcc77
 * @notice SmartCredit integra un sistema de creditokens, un indicador del nivel de
 *         crédito del usuario, y contempla funciones para ajustar dichos tokens en caso de pérdida de liquidez
 *         o cambios en las condiciones del mercado. Mantiene esquemas de amortización, oráculos, DID y 
 *         licenciamiento flexible.
 * @dev Este contrato se ajusta a la lógica económica previa, agregando mayor dinamismo en la disponibilidad 
 *      de crédito. Las actualizaciones periódicas (cada 4:20 horas) y otros eventos pueden ser disparados 
 *      externamente, mientras que el contrato provee las herramientas para mantener la integridad.
 */

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface IGenericOracle {
    function getLatestData() external view returns (uint256 price, uint256 updatedAt);
}

contract SmartCredit {
    enum Amortization { FRANCES, ALEMAN, AMERICANO, MIXTO }

    struct OracleInfo {
        address oracle;
        uint256 weight;
        bool active;
    }

    struct Loan {
        address borrower;
        address collateralToken;
        address creditToken;
        uint256 collateralAmount;
        uint256 principal;
        uint256 interestRate; // basis points (ej: 500 = 5%)
        uint256 duration;
        uint256 startTime;
        Amortization amortization;
        bool settled;
    }

    address public owner;
    mapping(address => bool) public admins;
    mapping(address => bool) public supportedTokens;
    mapping(address => bool) public userDIDVerified;

    // Mapeo de creditokens por usuario:
    mapping(address => uint256) public creditTokensBalance;

    OracleInfo[] public oracles;
    Loan[] public loans;

    modifier onlyOwner { require(msg.sender == owner, "O"); _; }
    modifier onlyAdmin { require(admins[msg.sender], "A"); _; }
    modifier onlyDIDVerified(address u) { require(userDIDVerified[u], "DID"); _; }

    event LoanCreated(uint256 indexed loanId, address indexed borrower, uint256 collateralAmount, uint256 principal);
    event InstallmentPaid(uint256 indexed loanId, address indexed payer, uint256 amount);
    event CollateralLiquidated(uint256 indexed loanId, address indexed borrower, uint256 amount);
    event CreditTokensUpdated(address indexed user, uint256 newBalance);

    constructor() {
        owner = msg.sender;
        admins[msg.sender] = true;
    }

    function addOracle(address o, uint256 w) external onlyAdmin {
        oracles.push(OracleInfo(o, w, true));
    }

    function addSupportedToken(address t) external onlyAdmin {
        supportedTokens[t] = true;
    }

    function setDID(address u, bool v) external onlyAdmin {
        userDIDVerified[u] = v;
    }

    /**
     * @dev Asignar creditokens a un usuario. Estos tokens representan su nivel de crédito. 
     *      El ajuste se puede hacer tras una evaluación periódica (cada 4:20 horas) off-chain.
     */
    function setCreditTokens(address user, uint256 amount) external onlyAdmin {
        creditTokensBalance[user] = amount;
        emit CreditTokensUpdated(user, amount);
    }

    /**
     * @dev Reducir creditokens en caso de pérdida de liquidez o cambios en la política de riesgo.
     *      Este método permite reaccionar a condiciones de mercado, asegurando la estabilidad del sistema.
     */
    function reduceCreditTokens(address user, uint256 amount) external onlyAdmin {
        require(creditTokensBalance[user] >= amount, "Not enough creditokens");
        creditTokensBalance[user] -= amount;
        emit CreditTokensUpdated(user, creditTokensBalance[user]);
    }

    function createLoan(
        address collateralToken,
        address creditToken,
        uint256 collateralAmount,
        uint256 principal,
        uint256 interestRate,
        uint256 duration,
        Amortization amortization
    ) external onlyDIDVerified(msg.sender) {
        require(supportedTokens[collateralToken] && supportedTokens[creditToken], "TOK");
        require(IERC20(collateralToken).transferFrom(msg.sender, address(this), collateralAmount), "COL");

        loans.push(Loan({
            borrower: msg.sender,
            collateralToken: collateralToken,
            creditToken: creditToken,
            collateralAmount: collateralAmount,
            principal: principal,
            interestRate: interestRate,
            duration: duration,
            startTime: block.timestamp,
            amortization: amortization,
            settled: false
        }));
        emit LoanCreated(loans.length - 1, msg.sender, collateralAmount, principal);
    }

    function calculateInstallment(uint256 loanId) external view returns (uint256) {
        Loan memory L = loans[loanId];
        if (L.amortization == Amortization.FRANCES) return _calcFrances(L);
        else if (L.amortization == Amortization.ALEMAN) return _calcAleman(L);
        else if (L.amortization == Amortization.AMERICANO) return _calcAmericano(L);
        return _calcMixto(L);
    }

    function payInstallment(uint256 loanId, uint256 amount) external {
        Loan storage L = loans[loanId];
        require(!L.settled && L.borrower == msg.sender, "LN");
        require(IERC20(L.creditToken).transferFrom(msg.sender, address(this), amount), "PAY");
        L.settled = true;
        emit InstallmentPaid(loanId, msg.sender, amount);
    }

    function liquidateCollateral(uint256 loanId) external onlyAdmin {
        Loan storage L = loans[loanId];
        require(!L.settled, "STL");
        IERC20(L.collateralToken).transfer(owner, L.collateralAmount);
        L.settled = true;
        emit CollateralLiquidated(loanId, L.borrower, L.collateralAmount);
    }

    function getAggregatedPrice() external view returns (uint256 price) {
        uint256 totalW;
        uint256 sum;
        for (uint256 i; i < oracles.length; i++) {
            if (oracles[i].active) {
                (uint256 p,) = IGenericOracle(oracles[i].oracle).getLatestData();
                sum += p * oracles[i].weight;
                totalW += oracles[i].weight;
            }
        }
        require(totalW > 0, "NO");
        price = sum / totalW;
    }

    // Funciones internas de cálculo de amortización
    function _calcFrances(Loan memory L) internal pure returns (uint256) {
        uint256 installments = 12;
        uint256 iPerInst = (L.principal * L.interestRate / 10000) / installments;
        return (L.principal / installments) + iPerInst;
    }

    function _calcAleman(Loan memory L) internal pure returns (uint256) {
        return _calcFrances(L) - 10;
    }

    function _calcAmericano(Loan memory L) internal pure returns (uint256) {
        uint256 installments = 12;
        return (L.principal * L.interestRate / 10000) / installments;
    }

    function _calcMixto(Loan memory L) internal pure returns (uint256) {
        return _calcFrances(L) + 10;
    }
}