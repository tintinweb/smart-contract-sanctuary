/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

pragma solidity ^0.5.8;

contract PasesInvitados {

    // Owner del contrato
    address public owner;

    // Mapeo de numero de socio a un address. Actualmente el club posee unos 3000 socios.
    mapping (address => uint16) cuentas_socios;
    mapping (uint16 => address) socios_cuentas;

    // Pases comprados de los socios
    // pases_socios[N&#250;mero de socio] = cantidad pases;
    mapping (uint16 => uint) pases_socios;

    // Pases Libres de los socios
    // pases_libres_socios_anio[a&#241;o][N&#250;mero de socio] = 1;
    mapping (uint32 => mapping (uint => uint)) pases_libres_socios_anio;

    /*
    Pases Libres Asignados en el mes, llevamos un control de los pases libres
    ya asignados para no asignar mas de una vez en un mes
    pases_libres_socios_asignados[Fecha Mes][N&#250;mero de socio] = 1
    Ej. pases_libres_socios_asignados[201907][1] = 1
    */

    enum EstadoAsignacion { NoAsignado, Asignado}
    mapping (uint32 => mapping (uint16 => EstadoAsignacion)) pases_libres_socios_asignados;

    /* Los estados de un socio se asignan mensualmente
    estado_socios[Fecha Mes][N&#250;mero de socio] = Estado;
    estado_socios[201901][1] = Deudor;
    */
    enum EstadoSocio { NoAsignado, Deudor, PagaEnTermino, InscriptoEscuela }
    mapping (uint32 => mapping (uint16 => EstadoSocio)) estado_socios;

    /* Los tipos de pase nos indican en el momento de gastar el pase que tipo de pase es, los
    de la noche cuestan la mitad de las unidades pases que el del dia */
    enum TipoPase { NoAsignado, Noche, Dia}

    enum TipoTemporada { NoAsignado, Alta, Baja}

    // Balance del socio gastado en wei.
    mapping (uint16 => uint256) balance_socios;

    /* El precio de unidad de pase, es el precio en unidad de ethereum que se compra una
    unidad de pase in wei */
    uint256 precio_unidad_pase = 100000;
    uint256 precio_precision = 10 ** 18;

    // Eventos
    event EventPasesUsados(uint32 fecha, uint16 socio, uint16 pases);
    event EventCompraUnidadesPases(uint16 socio, uint8 unidades, uint256 costo_unidad, uint256 total);
    event EventAsignarPasesLibres(uint16 socio, uint32 mes, uint16 pases);

    // En el momento de la creacion guardamos quien es el owner
    // del contrato
    constructor() public {
        owner = msg.sender;
    }

    // Cambiar de owner
    function setOwner(address _owner) public {
        require(msg.sender == owner, "Debe ser owner para cambiar a otro owner");
        owner = _owner;
    }

    // Modificador: solo puede acceder un owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Solamente accesible para el owner");
        _;
    }

    // Balance del contrato
    function Balance() public onlyOwner view returns (uint256 _balance) {
        _balance = address(this).balance;
    }

    // Transferir fondos a ...
    function TransferTo(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
    }

    /* Establecer el precio en wei de una unidad de pase */
    function SetPrecioUnidadPase(uint256 _precio) public onlyOwner {
        require(_precio > 0, "Debe ingresar un precio valido");
        precio_unidad_pase = _precio;
    }

    /* Devuelve el valor de una unidad de pase */
    function PrecioUnidadPase() public view returns (uint256 _precio) {
        _precio = precio_unidad_pase;
    }

    /* Compra de unidades de pases
    _n_socio: Es el n&#250;mero de socio, el n&#250;mero va de 1 a 65500
    _unidades: Cantidad de unidades a comprar
    Es payable, el valor por unidad es el establecido en Set Precio unidad de pase.
    Por lo que si se compran 2 unidades a precio base 100.000 wei, se deben transferir
    200.000 y unidades=2.
    Se emite un evento de compra.
     */
    function CompraUnidadesPases(uint16 _n_socio, uint8 _unidades) public payable onlyOwner {

        require(_n_socio > 0, "Debe ingresar un numero de socio");
        require(_unidades >= 1, "Debe ingresar al menos una unidad");
        require(msg.value == (_unidades * precio_unidad_pase), "Precio insuficiente en compra de unidades");

        cuentas_socios[msg.sender] = _n_socio;
        socios_cuentas[_n_socio] = msg.sender;

        // Incrementamos el balance de pases comprados
        pases_socios[_n_socio] += _unidades;

        // Incrementamos el balance de un socio
        balance_socios[_n_socio] += msg.value;

        // Evento de compra de unidades pases
        emit EventCompraUnidadesPases(_n_socio, _unidades, 1 * precio_unidad_pase, _unidades * precio_unidad_pase);
    }

    /* Asignamos el estado de un socio correspondiente al mes pasado como parametro, debido a
    que cada fecha de mes se debe evaluar el estado del socio */
    function AsignarEstadoSocio(uint16 _n_socio, uint32 _mes, EstadoSocio _estado_socio) public onlyOwner {
        require(_n_socio > 0, "Debe ingresar un numero de socio");
        require(_mes > 201901, "Mes incorrecto debe ser mayor a 201901");
        require(_mes < 210012, "Mes incorrecto debe ser menor a 210012");
        estado_socios[_mes][_n_socio] = _estado_socio;
    }

    /* Dado un socio y el mes correspondiente devuelve su estado */
    function VerEstadoSocio(uint16 _n_socio, uint32 _mes) public view returns (EstadoSocio _estado_socio) {
        _estado_socio = estado_socios[_mes][_n_socio];
    }

    /* Asignar los pases libres que le corresponde al socio de acuerdo al estado del mismo
    se debe llamar todos los meses al comenzar el mes, esto es debido a que antes no podemos hacerlo
    ya que no conocemos la situaci&#243;n de estado de un socio, osea si a pagado o no, o si ese mes
    est&#225; inscripto o se dio de baja en la escuela. Solamente se aceptan los meses desde Abril a Octubre del a&#241;o
    que corresponde a temporada baja, en temporada alta no se asignan pases libres */
    function AsignarPasesLibres(uint16 _n_socio, uint32 _fecha_mes) public onlyOwner {
        require(_n_socio > 0, "Debe ingresar un numero de socio");
        require(_fecha_mes > 201901, "Mes incorrecto debe ser mayor a 201901");
        require(_fecha_mes < 210012, "Mes incorrecto debe ser menor a 210012");
        require((_fecha_mes % 100 >= 1) && (_fecha_mes % 100 <= 12), "No es un mes v&#225;lido");
        require((_fecha_mes % 100 >= 4) && (_fecha_mes % 100 < 11), "Solamente los meses desde Abril a Octubre se pueden asignar pases libres");
        require(pases_libres_socios_asignados[_fecha_mes][_n_socio] == EstadoAsignacion.NoAsignado,
        "Ya se encuentra asignado los pases libres para dicho mes");
        require(estado_socios[_fecha_mes][_n_socio] != EstadoSocio.NoAsignado,
        "No se asignado estado de socio para dicho mes");

        // Lo que hacemos extraer el a&#241;o de la variable mes
        uint32 fecha_anio = _fecha_mes / 100;

        // Marcamos como asignado para dicho mes
        pases_libres_socios_asignados[_fecha_mes][_n_socio] = EstadoAsignacion.Asignado;

        if (estado_socios[_fecha_mes][_n_socio] == EstadoSocio.PagaEnTermino) {
            // Paga en t&#233;rmino le corresponde 1 pase libre
            pases_libres_socios_anio[fecha_anio][_n_socio] += 1;

            // Asignamos un 1 pase
            emit EventAsignarPasesLibres(_n_socio, _fecha_mes, 1);

        } else if (estado_socios[_fecha_mes][_n_socio] == EstadoSocio.InscriptoEscuela) {
            // Paga en t&#233;rmino y est&#225; inscripto a Escuela le corresponden 2 pases
            pases_libres_socios_anio[fecha_anio][_n_socio] += 2;

            // Asignamos 2 pases
            emit EventAsignarPasesLibres(_n_socio, _fecha_mes, 2);
        }
    }

    /* Asignamos el estado de un socio correspondiente al mes pasado como parametro, debido a
    que cada fecha de mes se debe evaluar el estado del socio */
    function UsarPases(uint16 _n_socio, uint32 _fecha, TipoPase _tipo_pase) public onlyOwner {
        require(_n_socio > 0, "Debe ingresar un numero de socio");
        require(_tipo_pase != TipoPase.NoAsignado, "No es valido el tipo pase");
        require(_fecha > 20190101, "Mes incorrecto debe ser mayor a 201901");
        require(_fecha < 21001231, "Mes incorrecto debe ser menor a 210012");
        require((_fecha % 100 >= 1) && (_fecha % 100 <= 31), "No es un d&#237;a v&#225;lido");

        // Sacamos el mes
        uint32 fecha_mes = _fecha / 100;
        require((fecha_mes % 100 >= 1) && (fecha_mes % 100 <= 12), "No es un mes v&#225;lido");

        // Sacamos el a&#241;o
        uint32 fecha_anio = fecha_mes / 100;

        TipoTemporada temporada;
        if ((fecha_mes % 100 >= 4) && (fecha_mes % 100 < 11)) {
            temporada = TipoTemporada.Baja;
        } else {
            temporada = TipoTemporada.Alta;
        }

        uint256 unidades_necesarias;
        if ((_tipo_pase == TipoPase.Noche) && (temporada == TipoTemporada.Baja)) {
            unidades_necesarias = 1;
        } else if ((_tipo_pase == TipoPase.Dia) && (temporada == TipoTemporada.Baja)) {
            unidades_necesarias = 2;
        } else if ((_tipo_pase == TipoPase.Noche) && (temporada == TipoTemporada.Alta)) {
            unidades_necesarias = 2;
        } else if ((_tipo_pase == TipoPase.Dia) && (temporada == TipoTemporada.Alta)) {
            unidades_necesarias = 4;
        }

        // Si es temporada baja podemos gastar los pases libres
        if (temporada == TipoTemporada.Baja) {
            if (pases_libres_socios_anio[fecha_anio][_n_socio] >= unidades_necesarias) {
                // genial puede usar los pases libres para el pase
                pases_libres_socios_anio[fecha_anio][_n_socio] -= unidades_necesarias;
            } else {
                // No alcanzan los pases libres tiene que usar unidades pagas
                uint256 unidades_pagas = unidades_necesarias - pases_libres_socios_anio[fecha_anio][_n_socio];
                require(pases_socios[_n_socio] >= unidades_pagas, "No posee suficientes unidades de pases, compre!");
                // Sacamos el credito de pases libres
                pases_libres_socios_anio[fecha_anio][_n_socio] = 0;
                // Sacamos las unidades pagas
                pases_socios[_n_socio] -= unidades_pagas;

            }

        } else {
            // Es la temporada Alta no tenemos pases libres solamente pagas
            require(pases_socios[_n_socio] >= unidades_necesarias, "No posee suficientes unidades de pases, compre!");
            // Sacamos las unidades necesarias para ingresar
            pases_socios[_n_socio] -= unidades_necesarias;

        }

        // Evento de uso de pase
        emit EventPasesUsados(_fecha, _n_socio, 1);
    }

    /* Pases requeridos nos indica la cantidad de pases unidades que debemos comprar. La
    misma se calcula teniendo en cuenta los pases libres. Por lo tanto si por ejemplo para ingresar
    necesitamos 4 unidades pases y tenemos 2 pases libres s&#243;lo debemos comprar 2 unidades pases  */
    function PasesRequeridos(uint16 _n_socio, uint32 _fecha, TipoPase _tipo_pase) public onlyOwner view returns (uint256 _pases_requeridos) {
        require(_n_socio > 0, "Debe ingresar un numero de socio");
        require(_tipo_pase != TipoPase.NoAsignado, "No es valido el tipo pase");
        require(_fecha > 20190101, "Mes incorrecto debe ser mayor a 201901");
        require(_fecha < 21001231, "Mes incorrecto debe ser menor a 210012");
        require((_fecha % 100 >= 1) && (_fecha % 100 <= 31), "No es un d&#237;a v&#225;lido");

        // Sacamos el mes
        uint32 fecha_mes = _fecha / 100;
        require((fecha_mes % 100 >= 1) && (fecha_mes % 100 <= 12), "No es un mes v&#225;lido");

        // Sacamos el a&#241;o
        uint32 fecha_anio = fecha_mes / 100;

        TipoTemporada temporada;
        if ((fecha_mes % 100 >= 4) && (fecha_mes % 100 < 11)) {
            temporada = TipoTemporada.Baja;
        } else {
            temporada = TipoTemporada.Alta;
        }

        uint256 unidades_necesarias;
        if ((_tipo_pase == TipoPase.Noche) && (temporada == TipoTemporada.Baja)) {
            unidades_necesarias = 1;
        } else if ((_tipo_pase == TipoPase.Dia) && (temporada == TipoTemporada.Baja)) {
            unidades_necesarias = 2;
        } else if ((_tipo_pase == TipoPase.Noche) && (temporada == TipoTemporada.Alta)) {
            unidades_necesarias = 2;
        } else if ((_tipo_pase == TipoPase.Dia) && (temporada == TipoTemporada.Alta)) {
            unidades_necesarias = 4;
        }

        // Si es temporada baja podemos gastar los pases libres
        if (temporada == TipoTemporada.Baja) {
            if (pases_libres_socios_anio[fecha_anio][_n_socio] >= unidades_necesarias) {
                // genial puede usar los pases libres para el pase
                _pases_requeridos = 0;
            } else {
                // No alcanzan los pases libres tiene que usar unidades pagas
                uint256 unidades_pagas = unidades_necesarias - pases_libres_socios_anio[fecha_anio][_n_socio];
                _pases_requeridos = unidades_pagas;
            }

        } else {
            // Es la temporada Alta no tenemos pases libres solamente pagas
            require(pases_socios[_n_socio] >= unidades_necesarias, "No posee suficientes unidades de pases, compre!");
            // Sacamos las unidades necesarias para ingresar
            _pases_requeridos = unidades_necesarias;

        }
    }

    /* Pases libres que posee un socio */
    function PasesLibresSocio(uint16 _n_socio, uint16 _anio_asig) public view returns (uint256 _pases_libres) {
        _pases_libres = pases_libres_socios_anio[_anio_asig][_n_socio];
    }

    /* Pases en unidad de pases que posee un socio */
    function PasesSocio(uint16 _n_socio) public view returns (uint256 _pases_socio) {
        _pases_socio = pases_socios[_n_socio];
    }

    /* La cuenta de un socio determinado */
    function GetCuentaSocio(uint16 _n_socio) public view returns (address _address) {
        _address = socios_cuentas[_n_socio];
    }

    /* Dado un address devuelve un socio */
    function GetSocioFromCuenta(address _address) public view returns (uint16 _n_socio) {
        _n_socio = cuentas_socios[_address];
    }


}