Smart Credit (MVP + Quark ID Integration)

Autor: vvcc77

Descripción del Proyecto: Smart Credit es un MVP que ofrece préstamos descentralizados en un entorno multichain, con verificación DID a través de Quark ID, multiple esquemas de amortización y ahora la incorporación de “creditokens” como indicador del nivel de crédito del usuario. Cada 4:20 horas se pueden recalcular condiciones, actualizar creditokens o ajustar las políticas ante cambios de liquidez.

La aplicación móvil (Android, iOS) presentará una UI amigable, con login vía Quark ID, visualización de creditokens, y un marketplace minimalista de bienes (electrodomésticos, tecnología, autos/motos, propiedades) cuyo precio y disponibilidad dependen del balance en creditokens. Además, integra flujos de compra con confirmación, selección del esquema de amortización (francés o alemán) y número de cuotas (3, 6, 12).

Puntos Clave:

    Integración DID con Quark ID, login con wallet.
    Creditokens para reflejar nivel de crédito del usuario.
    Esquemas de amortización: francés, alemán, americano, mixto.
    Ajustes de tokens ante pérdida de liquidez (funciones para admins).
    Mercado de bienes con precios según oráculos, actualizados cada 4:20 horas.
    Licencia adaptada, con revenue-sharing a acordar con el autor.

Visión de Negocio:

    Permite escalabilidad, adaptación regulatoria.
    Diferenciación con verificación DID y creditokens.
    Mercado DeFi en crecimiento, nicho para préstamos flexibles.
    Modelo comercial: requiere acuerdo con vvcc77 para monetización.

Licencia: Ver archivo LICENSE. Uso comercial requiere acuerdo previo.

Requisitos Técnicos:

    Node.js, npm, Truffle.
    Conexión a testnets (Goerli, Sepolia) si se desea testear en entorno real.
    Android Studio para compilar la app móvil.

Pasos para Probar:

    git clone https://github.com/vvcc77/SmartCredit.git
    npm install
    truffle compile
    truffle migrate
    Interacción vía consola Truffle (crear préstamos, asignar creditokens).

Futuras Mejoras:

    Integración real con Quark ID en la app móvil.
    Implementar cifrado homomórfico (ZAMA).
    UI más sofisticada en la app, nuevas categorías de bienes.
    Ajustes dinámicos de creditokens basados en scoring crediticio detallado.

Contacto: vvcc77