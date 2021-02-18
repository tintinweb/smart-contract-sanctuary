/**
 *Submitted for verification at Etherscan.io on 2021-02-18
*/

pragma solidity ^0.4.11;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */

//NOTA: Constant fue removido en versiones de la 0.5.0 en adelante, usar view o pure para reemplazarlo

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b; //multiplica los valores a y b para obtener c
        assert(a == 0 || c / a == b); //es error si a es 0 O si b es el cociente entre el resultado c entre a // esto cambia en versiones posteriores
        return c; //retorna c
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
        //NOTA: Al hacer la división NUNCA el resultado será un decimal, el resultado será un entero y el residuo será deprecado
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a); //es error porque no puede dar como resultado un entero negativo o 0 //impide el UNDERFLOW
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a); //indica que a no puede ser negativo o menor al resultado esperado, además, IMPIDE QUE EL RESULTADO DE C SE DESBORDE
        return c; //si ya se verificó que c alcanzó ese valor máximo y no se desbordó, lo puede retornar
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply; //asigna el suministro total de la moneda, interfaz llamada desde POSToken
    function balanceOf(address who) constant returns (uint256); //muestra el balance actual de la dirección indicadda
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title PoSTokenStandard
 * @dev the interface of PoSTokenStandard
 */
contract PoSTokenStandard {
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    function mint() returns (bool);
    function coinAge() constant returns (uint256);
    function annualInterest() constant returns (uint256);
    event Mint(address indexed _address, uint _reward);
}


contract PoSToken is ERC20,PoSTokenStandard,Ownable {
    using SafeMath for uint256; //se opera con SafeMath todos los valores asignados en uint256

    string public name = "PoSToken"; //nombre del token tipo string
    string public symbol = "POS"; //simbolo
    uint public decimals = 18; //es 18 debido a que el supply está en wei

    uint public chainStartTime; //chain start time
    uint public chainStartBlockNumber; //Índice del bloque de partida
    uint public stakeStartTime; //stake start time
    uint public stakeMinAge = 1 minutes; // minimum age for coin age: 3D
    uint public stakeMaxAge = 5 minutes; // stake age of full weight: 90D
    uint public maxMintProofOfStake = 10**17; // default 10% annual interest (podría ser cualquier porcentaje expresado en wei)

    uint public totalSupply; //total de monedas creadas
    uint public maxTotalSupply; //total de monedas creadas (haciendo staking)
    uint public totalInitialSupply; //total de monedas en circulación al empezar el deploy

    
    //Este struct determina info de una transferencia, cantidad y momento en la que se hizo
    struct transferInStruct{
    uint128 amount;
    uint64 time;
    }

    mapping(address => uint256) balances; //asigna un balance por dirección
    mapping(address => mapping (address => uint256)) allowed; //Cantidad que define cuánto permite transferir en balance una cuenta a otra
    mapping(address => transferInStruct[]) transferIns; //devuelve la info de una transferencia (cantidad y tiempo) según la dirección

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Fix for the ERC20 short address attack.
     * Determina la longitud de la dirección que llama la transacción debe ser MAYOR a los bytes  requeridos y así evitar un ataque de dirección corta de ERC20
     * Se le suman 4 bytes porque esos son los bytes que pone la function signature al momento de procesar la transacción, llegando, en este caso puntual, a 68 bytes 
     */
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }
    
    /*
    Indica que la moneda se puede generar y operar si el totalSupply actual es menor al maxTotalSupply
    */
    modifier canPoSMint() {
        require(totalSupply < maxTotalSupply);
        _;
    }

    //función constructora para esta versión de solidity
    function PoSToken() {
        maxTotalSupply = 10**25; // 10 Mil.
        totalInitialSupply = 10**24; // 1 Mil.

        chainStartTime = now; //indica que el tiempo de partida de la cadena de bloques empieza a correr inmediatamente después del deploy
        chainStartBlockNumber = block.number; //Indica el bloque actual de transacción

        balances[msg.sender] = totalInitialSupply; //Indica que el supply inicial le pertenecerá a la dirección ejecutora del deploy
        totalSupply = totalInitialSupply; //Indica que ese supply inicial será el total por el momento
    }

    //_to es la dirección a la que queremos transferir
    //_value es el monto que le queremos transferir a una dirección
    //onlyPayloadSize(2 * 32) indica que la info de la transferencia recibirá dos parámetros (address y value), cada una de 32 bytes
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool) {
        if(msg.sender == _to) return mint(); //si el user se quiere enviar a sí mismo los tokens, ejecutar la función mint(), si no, seguir
        balances[msg.sender] = balances[msg.sender].sub(_value); //se le resta el value a transferir a la dirección origen, mediante SafeMath
        balances[_to] = balances[_to].add(_value); //se le suma el value transferido al destinatario
        Transfer(msg.sender, _to, _value); //se produce un evento al ejecutar la función
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender]; //elimina historial de transferencias previas a ésta
        uint64 _now = uint64(now); //asigna el tiempo actual y la guarda en la variable _now
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now)); //guarda en el struct el balance que quedó después de la transferencia y el momento en que se hizo
        transferIns[_to].push(transferInStruct(uint128(_value),_now)); //guarda el valor que recibió el destinatario y el momento
        return true; //una vez se haya ejecutado con éxito, valida la tranferencia
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner]; //muestra el balance actual de la dirección
    }

    //Esta función indica desde donde se transfiere, a quien, y el valor que se podrá transferir
    //onlyPayloadSize(3 * 32) indica que la función recibirá 3 parámetros, cada uno de 32 bytes, lo que dará 96 bytes. Si le sumo
    //4 bytes en el modifier por el signature de la transacción, darán 100 bytes, tamaño mínimo para evitar short address attack
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) returns (bool) {
        require(_to != address(0)); //indicca que la dirección que recibirá el monto NO debe ser address(0)

        //Cuanto se permite transferir desde la dirección de origen al ejecutor de la función
        var _allowance = allowed[_from][msg.sender]; //el resultado se almacena en la variable _allowance
        

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balances[_from] = balances[_from].sub(_value); //se le resta el value indicado a la dirección de origen
        balances[_to] = balances[_to].add(_value); //se le suma el valor a la dirección de destino
        allowed[_from][msg.sender] = _allowance.sub(_value); //Se resta el value permitido en la transacción entre la dirección de origen y el que ejecuta la función
        Transfer(_from, _to, _value); //se emite el evento de transferencia
        if(transferIns[_from].length > 0) delete transferIns[_from]; //elimina historial de transferencias previas a ésta
        uint64 _now = uint64(now); //asigna el tiempo actual y la guarda en la variable _now
        transferIns[_from].push(transferInStruct(uint128(balances[_from]),_now)); //guarda en el struct el balance que quedó después de la transferencia y el momento en que se hizo
        transferIns[_to].push(transferInStruct(uint128(_value),_now)); //guarda el valor que recibió el destinatario y el momento
        return true;
    }

    //Función que "autoriza" a una cuenta spender transferiri desde mi cuenta
    function approve(address _spender, uint256 _value) returns (bool) {
        
        //exige que el value inicial sea 0 o que lo permitido y autorizado a transferir de una cuenta respecto a la otra sea 0 para ese momento
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value; //asigna el value indicado como valor permitido por el ejecutor al spender para transferir
        Approval(msg.sender, _spender, _value); //emite un evento de Approval, indicando que la autorización ya se dio
        return true; //return true si todo lo anterior se cumple
    }

    //Función que permite visualizar el monto autorizado por una cuenta owner hacia una spender
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    //Función que permite "acuñar monedas", es decir, añadir monedas que NO estaban disponibles en el totalSupply
    //a la cuenta que generó el reward
    //Utiliza el modifier canPOSMint para indicar que sólo se puede hacer mint si aun no se ha llegado al máximo del supply creado
    function mint() canPoSMint returns (bool) {
        if(balances[msg.sender] <= 0) return false; //No hay recompensa si el balance de la cuenta del ejecutor es 0 o menos
        if(transferIns[msg.sender].length <= 0) return false; //Si no hay historial de transferencias previas, no se puede hacer mint

        uint reward = getProofOfStakeReward(msg.sender); //reward se calcula en función de getProofOfStakeReward, y el valor obtenido se suma al totalSupply
        if(reward <= 0) return false; //si no se generó reward, no puede haber mint de nuevas monedas

        totalSupply = totalSupply.add(reward); //si el mint es exitoso, se agregan "nuevas" monedas al totalSupply, SIN SUPERAR AÚN EL MÁXIMO
        balances[msg.sender] = balances[msg.sender].add(reward); //ese reward generado va directo a la cuenta que tiene las monedas y ejecutó la función
        delete transferIns[msg.sender]; //elimina historial de transferencias previas para esa dirección
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now))); //guarda en el struct el balance que quedó después del mint y el momento en que se hizo

        Mint(msg.sender, reward); //se emite un evento informando que el mint se ha realizado
        return true;
    }

    //Esta función permite obtener el bloque actual de la transacción
    function getBlockNumber() returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber); //bN = kewyord - bloque inicial
    }

    //Esta función permite obtener el tiempo de vida que tiene una moneda en cierta dirección
    function coinAge() constant returns (uint myCoinAge) {
        myCoinAge = getCoinAge(msg.sender,now);
    }

    //Esta función calcula interés anual teniendo en cuenta el momento en que empieza el staking en un rango de 1 año
    function annualInterest() constant returns(uint interest) {
        uint _now = now; //define el momento de ejecutar la transacción y lo guarda en la variable _now
        interest = maxMintProofOfStake; //10**17

        //si al momento de ahora se le resta el momento de inicio de staking y luego se divide en 1 año (84600 seg) y eso es igual a 0
        //pero si al momento de ahora se le resta el momento de inicio de staking y luego se divide en 1 año y eso es igual a 1
        //En otras palabras, el interés nominal será 77% si no se ha superado el 1er año
        //NOTA: NO se utiliza el concepto de "years" en versiones posteriores a la 0.5.0
        if((_now.sub(stakeStartTime)).div(1 years) == 0) {
            //el interés será (770*(10**17))/100 = 0,77 o 77%  (obviando los 18 dígitos)
            interest = (770 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 1){
            //el interés será (435*(10**17))/100 = 0,435 o 43,5%  (obviando los 18 dígitos)
            interest = (435 * maxMintProofOfStake).div(100);
        }
    }

    //Esta función determina el cálculo de la recompensa obtenida en función del tiempo que la dirección haya tenido las monedas
    function getProofOfStakeReward(address _address) internal returns (uint) {
        
        //se exige que el tiempo actual sea mayor o igual al momento de iniciar el staking y que este tiempo sea si o si mayor a 0
        require( (now >= stakeStartTime) && (stakeStartTime > 0) ); 

        uint _now = now; //define el momento de ejecutar la transacción y lo guarda en la variable _now
        uint _coinAge = getCoinAge(_address, _now); //devuelve el resultado de getCoinAge para una dirección y la almacena. Si no hay registro de transacciones, el valor es 0
        if(_coinAge <= 0) return 0; //No habrá recompensa si no hubo transacciones ni la dirección nunca tuvo monedas

        uint interest = maxMintProofOfStake;
        // Due to the high interest rate for the first two years, compounding should be taken into account.
        // Effective annual interest rate = (1 + (nominal rate / number of compounding periods)) ^ (number of compounding periods) - 1
        if((_now.sub(stakeStartTime)).div(1 years) == 0) {
            // 1st year effective annual interest rate is 100% when we select the stakeMaxAge (90 days) as the compounding period. //DEPRECAR ESTA LINEA DE COMENTARIO
            //https://github.com/EthereumCommonwealth/Auditing/issues/129
            //misma situación en ambos años
            interest = (770 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 1){
            // 2nd year effective annual interest rate is 50% //DEPRECAR ESTA LINEA DE COMENTARIO
            interest = (435 * maxMintProofOfStake).div(100);
        }

        //NOTA: EL 770 Y EL 435 SON OPCIONALES Y VAN DE LA MANO CON LA ESTRATEGIA DE NEGOCIO IMPLANTADA

        //365 determina la cantidad de días y se multiplica por 10**18 para dar formato en wei
        //NOTA: Revisar plazos de conversión en el divisor (365)
        return (_coinAge * interest).div(365 * (10**decimals)); //Retorna el resultado del rewardPOS y lo manda a la funcion mint()
    }

    //Esta función obtiene el tiempo que ha durado la moneda en una dirección haciendo staking
    function getCoinAge(address _address, uint _now) internal returns (uint _coinAge) {
        if(transferIns[_address].length <= 0) return 0; //No toma en cuenta direcciones que no hayan hecho transacciones antes

        //Busca dentro del mapping de struct los tiempos de staking que lleva una cuenta y la moneda que en ella tenga
        for (uint i = 0; i < transferIns[_address].length; i++){
            
            //Se puede continuar con la búsqueda si el tiempo indicado por el ejecutor es menor al tiempo registrado por la dirección en el mapping
            //añadiendo los 3 min de mínimo de Staking. En otras palabras, si el staking lleva menos de 3 min NO CONTINUAR 
            if( _now < uint(transferIns[_address][i].time).add(stakeMinAge) ) continue;

            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time)); //mide el tiempo de staking que ha transcurrido. Necesario para calcular reward
            if( nCoinSeconds > stakeMaxAge ) nCoinSeconds = stakeMaxAge; //Limita el tiempo máximo de staking a 90 días, haciendo que no se obtenga un reward mayor

            //el resultado es la cantidad de monedas en una dirección por la cantidad de DIAS que han permanecido en dicha dirección
            //esos días son el resultado del tiempo en staking/84600 segundos
            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * nCoinSeconds.div(1 days));
        }
    }

    //Esta función indica el tiempo en que empiece el staking. Definido sólo por el owner
    function ownerSetStakeStartTime(uint timestamp) onlyOwner {
        require((stakeStartTime <= 0) && (timestamp >= chainStartTime)); //no debe haber staking previo y además el tiempo debe ser el mismo del inicio del primer bloque 
        stakeStartTime = timestamp;
    }

    //Función que sirve para quemar monedas a lo mal hecho :v
    function ownerBurnToken(uint _value) onlyOwner {
        require(_value > 0); //Exige que el value a quemar sea mayor a 0

        balances[msg.sender] = balances[msg.sender].sub(_value); //Se resta el value en el balance del ejecutor (owner)
        delete transferIns[msg.sender]; //se elimina registro de transacciones previo
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now))); //actualiza el balance y el momento en que se ejecutó el Burn

        totalSupply = totalSupply.sub(_value); //el totalSupply también se le restará ese value
        totalInitialSupply = totalInitialSupply.sub(_value); //el totalInitialSupply también se le restará ese valu
        maxTotalSupply = maxTotalSupply.sub(_value*10); //al maxTotalSupply se le restará 10 veces más el value (limita el staking de futuras monedas)

        Burn(msg.sender, _value); //se emite evento que indica que las monedas se han quemado a lo maldita sea
    }

    /* Batch token transfer. Used by contract creator to distribute initial tokens to holders */
    //Función que permite la transferencia de lotes de monedas. Ayuda a la distribución inicial de monedas
    //recipients es el array de direcciones que recibirán esos lotes
    //values es el valor que el owner quiera darle a esas direcciones
    function batchTransfer(address[] _recipients, uint[] _values) onlyOwner returns (bool) {
        
        //exige que haya direcciones en el array y que la cantidad de direcciones sea la misma que la cantidad de values. NO DEBE HABER SOBRANTES
        require( _recipients.length > 0 && _recipients.length == _values.length);

        uint total = 0; //índice de control
        for(uint i = 0; i < _values.length; i++){
            
            //Asigna un valor que hayamos indicado a cada índice del array (la cantidad es igual para todos)
            total = total.add(_values[i]);
        }
        require(total <= balances[msg.sender]); //Para continuar se exige que el valor total en ese lote sea menor o igual al balance del owner

        uint64 _now = uint64(now);
        for(uint j = 0; j < _recipients.length; j++){
            
            balances[_recipients[j]] = balances[_recipients[j]].add(_values[j]); //Añade el value asignado 1 por 1 a cada índice en el array de direcciones
            transferIns[_recipients[j]].push(transferInStruct(uint128(_values[j]),_now)); //registra la transacción para cada dirección individualmente
            Transfer(msg.sender, _recipients[j], _values[j]); //se emite evento de la transferencia
        }

        balances[msg.sender] = balances[msg.sender].sub(total); //Se resta el total en value indicado al owner
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender]; //se elimina registro previo de transferencias
        if(balances[msg.sender] > 0) transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now)); //Registra la transacción en la cuenta owner

        return true; //retorna true si todo tuvo éxito
    }
}