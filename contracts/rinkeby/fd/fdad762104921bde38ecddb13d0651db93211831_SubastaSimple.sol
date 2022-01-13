/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

contract SubastaSimple {
    // Parámetros de la subasta. Los tiempos son
    // o timestamps estilo unix (segundos desde 1970-01-01)
    // o periodos de tiempo en segundos.
    address public beneficiario;
    uint public subastaComienza;
    uint public subastaTiempo;

    // Estado actual de la subasta.
    address public pujadorMaximo;
    uint public pujaMaxima;

    //El propietario (el que deploya) podrá llamar métodos especiales
    address public propietario;
    
    modifier soloPropietario() {

        require(msg.sender == propietario,"No eres el propietario, no puedes hacer esto");
        _; //_ ejecuta el cuerpo de la función que tiene el modificador
    }

    // Retiradas de dinero permitidas de las anteriores pujas
    mapping(address => uint) reembolsosPendientes;

    // Fijado como true al final, no permite ningún cambio.
    bool finalizada;

    // Eventos que serán emitidos al realizar algún cambio
    event PujaMaximaIncrementada(address pujador, uint cantidad);
    event SubastaFinalizada(address ganador, uint cantidad);

    // Lo siguiente es lo que se conoce como un comentario natspec,
    // se identifican por las tres barras inclinadas.
    // Se mostrarán cuando se pregunte al usuario
    // si quiere confirmar la transacción.
    // Es el constructor. 
    //El que deploya elige en los parámetros del constructor
    // el address del beneficiario y el tiempo de puja, en segundos

    /// Crea una subasta sencilla con un periodo de pujas
    /// de `_biddingTime` segundos. El beneficiario de
    /// las pujas es la dirección `_beneficiary`.
    constructor(
        address _beneficiario,
         uint _subastaTiempo
    ) {
        beneficiario = _beneficiario;
        subastaComienza = block.timestamp; //block.timestamp como now, el tiempo Ahora
        subastaTiempo = _subastaTiempo;
        //el propietario del contrato se asigna al que deploya
        propietario = msg.sender;
    }

    /// Puja en la subasta con el valor enviado
    /// en la misma transacción.
    /// El valor pujado sólo será devuelto
    /// si la puja no es ganadora.
    function puja() payable public {
        // No hacen falta argumentos, toda
        // la información necesaria es parte de
        // la transacción. La palabra payable
        // es necesaria para que la función pueda recibir Ether.

        // Revierte la llamada si el periodo
        // de pujas ha finalizado.
        //block.timestamp como now, el tiempo Ahora
        require(block.timestamp <= (subastaComienza + subastaTiempo));

        // Si la puja no es la más alta,
        // envía el dinero de vuelta.
        // msg es quien invoca al método puja del contrato.
        // msg.sender es quien llama a la función y msg.value la cantidad
        // todo ello se realiza con metamask en una blockchain real
        //Si la puja no es más alta falla la transacción
        require(msg.value > pujaMaxima);

        //Si llega hasta aquí es que se ha superado la puja anterior,
        //y hay que devolver el dinero al máximo anterior
        if (pujadorMaximo != address(0)) {
            // Devolver el dinero usando
            // highestBidder.send(highestBid) es un riesgo
            // de seguridad, porque la llamada puede ser evitada
            // por el usuario elevando la pila de llamadas a 1023.
            // Siempre es más seguro dejar que los receptores
            // saquen su propio dinero.

            //El pujador máximo puede ser superado muchas veces, y 
            //ser la misma persona, por lo que se suman todas sus
            //derrotas para ser devuelto el total de todas sus pujas
            reembolsosPendientes[pujadorMaximo] += pujaMaxima;
        }
        pujadorMaximo = msg.sender;
        pujaMaxima = msg.value;
        //se emite el evento que se guarda en los logs, fuera de la blocchain
        emit PujaMaximaIncrementada(msg.sender, msg.value); 
    }

    //retiro devuelve TRUE si se consigue devolver la cantidad
    /// El llamador retira la suma de sus pujas que fueron superadas.
    function retiro() public returns (bool) {

        uint cantidad = reembolsosPendientes[msg.sender];
        if (cantidad > 0) {
            // Es importante poner esto a cero porque el receptor
            // puede llamar de nuevo a esta función como parte
            // de la recepción antes de que `send` devuelva su valor.
            reembolsosPendientes[msg.sender] = 0;

            //Se envia eth al llamador. Devuelve TRUE si  va bien
            //Hay que castearlo como payable para que no falle
            if (!payable(msg.sender).send(cantidad)) {
                // Aquí no es necesario lanzar una excepción.
                // Basta con reiniciar la cantidad que se debe devolver.
                reembolsosPendientes[msg.sender] = cantidad;
                return false;
            }
        }
        return true;
    }

    /// Finaliza la subasta y envía la puja más alta al beneficiario.
    function subastaFin() public {
        // Es una buena práctica estructurar las funciones que interactúan
        // con otros contratos (i.e. llaman a funciones o envían ether)
        // en tres fases:
        // 1. comprobación de las condiciones
        // 2. ejecución de las acciones (pudiendo cambiar las condiciones)
        // 3. interacción con otros contratos
        // Si estas fases se entremezclasen, otros contratos podrían
        // volver a llamar a este contrato y modificar el estado
        // o hacer que algunas partes (pago de ether) se ejecute multiples veces.
        // Si se llama a funciones internas que interactúan con otros contratos,
        // deben considerarse como interacciones con contratos externos.

        // 1. Condiciones
        //block.timestamp como now, el tiempo Ahora
        require(block.timestamp >= (subastaComienza + subastaTiempo)); // la subasta aún no ha acabado
        require(!finalizada); // esta función ya ha sido llamada

        // 2. Ejecución
        finalizada = true;
        //Emite el evento que se mete en los logs, fuera de la blockchain
        emit SubastaFinalizada(pujadorMaximo, pujaMaxima);

        // 3. Interacción
        //Hay que castear al beneficiario como payable, para que no falle
        payable(beneficiario).transfer(pujaMaxima);
    }
    //Al propietario del contrato, el que deploya, se le permite
    //reiniciar el contrato con nuevo beneficiario y tiempo
    function reiniciarSubasta (
        address _beneficiario,uint _subastaTiempo
        ) soloPropietario public {
            beneficiario = _beneficiario;
            subastaComienza = block.timestamp; //block.timestamp como now, el tiempo Ahora
            subastaTiempo = _subastaTiempo;

    }
}