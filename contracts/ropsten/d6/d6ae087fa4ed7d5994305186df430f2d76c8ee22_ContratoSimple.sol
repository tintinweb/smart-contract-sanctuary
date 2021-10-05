/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

abstract contract IERC20 {
    string public name;
    uint8 public decimals;
    string public symbol;
    function totalSupply() public view virtual returns (uint256);
    function balanceOf(address _who) public view virtual returns (uint256);
    function transfer(address _to, uint256 _value) public virtual returns (bool);
    function allowance(address _owner, address _spender) public view virtual returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool);
    function approve(address _spender, uint256 _value) public virtual returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ContratoSimple {

        // cuanto duran nuestros contratos
    uint256 public duracion;
        // cada cuanto se verifican progresos
    uint256 public periodo;
        // lista de socios; distribución igualitaria
    address[] public socios;
        // numero de tareas netas
    uint8 public tareas;
        // asset aprobado para el pago
    IERC20 public dolares;

    struct Presupuesto {
        uint8   tarea;
        uint256 saldo;
        uint256 quota;
        uint256 bono;
    }

    struct Proyecto {
        address cliente;
        uint256 arranque;
    }

        
    mapping(address => bool) public inversores;
        // quienes pueden contratarnos
    mapping(address => Presupuesto) public fondos;
        // aportes que cada inversor ha hecho
    mapping(uint8 => Proyecto) public contratos;
        // numero de tarea => [{ patrocinador, fecha de inicio}]
    mapping(uint8 => mapping(uint8 => uint256[2])) public pagos;
        // numero de socio => numero de tarea => [saldo a favor, fecha de ultimo cobro]

    event NuevoInversor(address indexed _inversor);
    event NuevoSocio(address _socio);
    event Bonificacion(uint8 indexed _tarea, uint256 _deposito);
    event Anulacion(uint8 indexed _tarea);

    /**
         * solo en esta ocasion se puede setear el dolar
         * de resto añadiriamos otro factor de confianza
         */
    constructor(address activo) {

        dolares = IERC20(address(activo));
        socios.push() = msg.sender;
            // 3 semanas de asesoría
        // duracion = 1814400;
            // SUM y chequeo de estatus diario
        // periodo = 86400;
        /**
         * para fimes de pruebas: 1 dia = 20 min = 1200
         * para un periodo de 7 dias = 7*20 min = 8400
         */
        duracion = 8400;
        periodo = 1200;

    }

    modifier soloInversores() {

        require(inversores[msg.sender] == true, "contratador no aprobado");
        _;
    }

    modifier soloManager() {

        require(socios[0] == msg.sender, "cambio sin autorizacion");
        _;
    }

    /**
     * @dev Cada address de un inversor, vendrá vinculada a una sola tarea
     * @param abono cantidad aprobada en presupuesto
     * costo actual de gas aprox: 181.894
     */
    function aporte(uint256 abono) external soloInversores {

        dolares.transferFrom(msg.sender, address(this), abono);
        
        // necesito la quota para cada socio
        uint256 _socios = uint256(socios.length);
        uint _ahora = block.timestamp;        

        if (fondos[msg.sender].tarea == 0) {

        ++tareas;
        contratos[tareas].arranque = _ahora;
        contratos[tareas].cliente = msg.sender;
        fondos[msg.sender].tarea = tareas;

        }

        uint256 etapa = _ahora - contratos[fondos[msg.sender].tarea].arranque;
        if (duracion > etapa) {

            uint256 faltan = (duracion - etapa)/periodo;
            uint256 pedazos = _socios*faltan;
            uint256 _quota = abono/pedazos;
            /**
            * cualquier saldo diferencial podrá retirarlo el inversor
            * mediante el metodo rescindir()
            */ 
            fondos[msg.sender].quota += _quota;

        } else {

            uint256 _quota = abono/_socios;
            fondos[msg.sender].bono = _quota;
            // hacer disponible al inversor el residuo
            fondos[msg.sender].saldo += (abono - _quota*_socios);

        }

        fondos[msg.sender].saldo += abono;   
        emit Bonificacion(fondos[msg.sender].tarea, abono);     
        
    }

    /**
     * @dev la tarea "0" se inutiliza
     * los pagos deben actualizar tanto la fecha
     * del ultimo cobro, como el disponible para
     * retiro, a favor del socio
     */
    function cobrar(uint8 _tarea) public {

        // si msg.sender no es ningun socio, se revierte
        uint8 socio = _hallarSocio(msg.sender);
        uint256 _ahora = block.timestamp;
        
        // el patrocinador de la tarea
        address _cliente = contratos[_tarea].cliente;
        
        uint256 delta = _ahora - contratos[_tarea].arranque;
        /**
         * @dev la division en solidity es entera con redondeo al cero:
         * ((a - c)/d - (b - c)/d) != (a - b)/d
         */
        uint256 cuotas = duracion > delta ? delta/periodo + 1 : duracion/periodo;

        // si el pago no ha sido inicializado...
        if (pagos[socio][_tarea][1] == 0) {
            
            /**
             * se inicializa: 
             * el "ahora" puede ser posterior a la culminacion
             * del contrato: _ahora - arranque > duracion
             * pero sería entonces el unico seteo para esa tarea 
             */
            pagos[socio][_tarea][1] = _ahora;
            fondos[_cliente].saldo -= cuotas*fondos[_cliente].quota;
            pagos[socio][_tarea][0] += cuotas*fondos[_cliente].quota;

        }

        // justificación: ultimaCuota puede exceder duracion/periodo
        uint256 ultimaCuota = pagos[socio][_tarea][1] - contratos[_tarea].arranque;
        ultimaCuota = duracion > ultimaCuota ? ultimaCuota/periodo + 1 : duracion/periodo;

        // se ejecuta sea o no la inicialización        
        if (duracion > delta) {

            /** 
             * si "_ahora" no ha rebasado el proximo período, 
             * "cuotas" queda en cero; si se acaba de inicializar,
             * "cuotas" queda en cero. 
             */
            cuotas -= ultimaCuota;

            // cambios de estado solo si cuotas no es cero
            if (cuotas != 0) {
            
            fondos[_cliente].saldo -= cuotas*fondos[_cliente].quota;
            pagos[socio][_tarea][0] += cuotas*fondos[_cliente].quota;
            
                // por ultimo se re-setea la fecha de ultimo pago
                if (pagos[socio][_tarea][1] < _ahora) {
                    // pero unicamente si no se había hecho
                    pagos[socio][_tarea][1] = _ahora;
                    }

            }
        // si el periodo del proyecto ya culmino...
        } else {
            
            cuotas -= ultimaCuota;
            fondos[_cliente].saldo -= cuotas*fondos[_cliente].quota;
            /**
             * esta rutina asegura que los socios puedan cobrar
             * cualquier bono depositado al final de un proyecto
             */
            uint256 _bono = fondos[_cliente].bono;
            fondos[_cliente].bono = 0;
            pagos[socio][_tarea][0] += cuotas*fondos[_cliente].quota + _bono;

            // pero siendo esta una etapa postuma, 
            // ya no se re-setea la fecha del ultimo pago

        }

    }

    /**
     * @dev se reserva esta funcion para prevenir escenarios conflictivos entre socios
     */
    function cobroGlobal(uint8 _tarea) public {

        for (uint8 i; i < socios.length; ++i) {

            _cobrar(_tarea, socios[i]);

        }

    }

    /**
     * El cliente puede rescindir en cualquier momento un contrato
     * queda de parte de los socios realizar a tiempo los respectivos
     * cobros (un bot-manager es idoneo)
     */
    function rescindir() public soloInversores {

        uint256 N = fondos[msg.sender].saldo;
        fondos[msg.sender].saldo = 0;
        dolares.transfer(msg.sender, N);
        emit Anulacion(fondos[msg.sender].tarea);
        
    }

    function admitirInversor(address inversor) public soloManager {
        inversores[inversor] = true;
        emit NuevoInversor(inversor);
    }

    /**
     * @dev solo se designa una función para añadir socios
     * si hubiere una funcion para retirarlos, se requiere confianza en
     * el manager. En un futuro un tercer "socio" sería un contrato multifirma.
     */
    function masSocios(address socioNuevo) public soloManager {
        socios.push() = socioNuevo;
        emit NuevoSocio(socioNuevo);
    }

    /**
     * @dev mediante esta funcion los socios hacen efectivo sus recompensas
     */
    function retirar(uint8 _tarea) public {

        // si msg.sender no es ningun socio, se revierte
        uint8 socio = _hallarSocio(msg.sender);
        uint256 N = pagos[socio][_tarea][0];
        pagos[socio][_tarea][0] = 0;
        dolares.transfer(msg.sender, N);

    }

        /* operaciones internas del contrato */

    function _hallarSocio(address cobrador) internal view returns (uint8 _socio) {

        bool socioEncontrado;
        for (uint8 i; i < socios.length; ++i) {
            if (socios[i] == cobrador) {
                _socio = i;
                socioEncontrado = true;
                break;
            }
        }
        require(socioEncontrado, "Ud. no es socio");

    }

    /**
     * @dev si se deja enteramente la responsabilidad de asegurar su pago a cada socio
     * puede darte un escenario de juego conflictivo si el cliende rescinde
     * cuando unos socios han cobrado y otros no.
     * esta funcion interna es el envoltorio parcial de un metodo de cobro global
     */
    function _cobrar(uint8 _tarea, address _socio) internal {

        // si _socio no esta en el array "socios", esto revierte
        uint8 socio = _hallarSocio(_socio);
        uint256 _ahora = block.timestamp;
        
        // el patrocinador de la tarea
        address _cliente = contratos[_tarea].cliente;
        
        uint256 delta = _ahora - contratos[_tarea].arranque;
        /**
         * @dev la division en solidity es entera con redondeo al cero:
         * ((a - c)/d - (b - c)/d) != (a - b)/d
         */
        uint256 cuotas = duracion > delta ? delta/periodo + 1 : duracion/periodo;

        // si el pago no ha sido inicializado...
        if (pagos[socio][_tarea][1] == 0) {
            
            /**
             * se inicializa: 
             * el "ahora" puede ser posterior a la culminacion
             * del contrato: _ahora - arranque > duracion
             * pero sería entonces el unico seteo para esa tarea 
             */
            pagos[socio][_tarea][1] = _ahora;
            fondos[_cliente].saldo -= cuotas*fondos[_cliente].quota;
            pagos[socio][_tarea][0] += cuotas*fondos[_cliente].quota;

        }

        // justificación: ultimaCuota puede exceder duracion/periodo
        uint256 ultimaCuota = pagos[socio][_tarea][1] - contratos[_tarea].arranque;
        ultimaCuota = duracion > ultimaCuota ? ultimaCuota/periodo + 1 : duracion/periodo;

        // se ejecuta sea o no la inicialización        
        if (duracion > delta) {

            /** 
             * si "_ahora" no ha rebasado el proximo período, 
             * "cuotas" queda en cero; si se acaba de inicializar,
             * "cuotas" queda en cero. 
             */
            cuotas -= ultimaCuota;

            // cambios de estado solo si cuotas no es cero
            if (cuotas != 0) {
            
            fondos[_cliente].saldo -= cuotas*fondos[_cliente].quota;
            pagos[socio][_tarea][0] += cuotas*fondos[_cliente].quota;
            
                // por ultimo se re-setea la fecha de ultimo pago
                if (pagos[socio][_tarea][1] < _ahora) {
                    // pero unicamente si no se había hecho
                    pagos[socio][_tarea][1] = _ahora;
                    }

            }
        // si el periodo del proyecto ya culmino...
        } else {
            
            cuotas -= ultimaCuota;
            fondos[_cliente].saldo -= cuotas*fondos[_cliente].quota;
            /**
             * esta rutina asegura que los socios puedan cobrar
             * cualquier bono depositado al final de un proyecto
             */
            uint256 _bono = fondos[_cliente].bono;
            fondos[_cliente].bono = 0;
            pagos[socio][_tarea][0] += cuotas*fondos[_cliente].quota + _bono;

            // pero siendo esta una etapa postuma, 
            // ya no se re-setea la fecha del ultimo pago

        }

    }

}