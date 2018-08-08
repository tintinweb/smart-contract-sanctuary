pragma solidity ^0.4.16;

contract owned {
    address public owner;
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenMomos is owned{

    string public name = "Momocoin";
    string public symbol = "MOMO";
    uint8 public decimals = 18;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    uint256 public totalSupply;

    bytes32 public currentChallenge;  
    uint256 public timeOfLastProof;                             
    uint256 public difficulty = 10**32;   
    
    // Esto genera un evento p&#250;blico en el blockchain que notificar&#225; a los clientes
    event Transfer(address indexed from, address indexed to, uint256 value); //Va de ley, no quitar
    
    // Esto genera un evento p&#250;blico en el blockchain que notificar&#225; a los clientes
    event Approval(address indexed _owner, address indexed _spender, uint256 _value); //Va de ley, no quitar

    // Esto notifica a los clientes sobre la cantidad quemada
    event Burn(address indexed from, uint256 value);
    
    constructor(uint256 momos) public {
        totalSupply = momos * 10 ** uint256(decimals);  // Actualizar el suministro total con la cantidad decimal
        balanceOf[msg.sender] = totalSupply;            // Dale al creador todos los tokens iniciales
        timeOfLastProof = now;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        // Impedir la transferencia a la direcci&#243;n 0x0.
        require(_to != 0x0);
        // Verifica si el remitente tiene suficiente
        require(balanceOf[_from] >= _value);
         // Verificar desbordamientos
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Guarda esto para una afirmaci&#243;n en el futuro
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         // Resta del remitente
        balanceOf[_from] -= _value;
        // Agregue lo mismo al destinatario
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         // Los asertos se usan para usar an&#225;lisis est&#225;ticos para encontrar errores en su c&#243;digo. Nunca deber&#237;an fallar
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Verifica si el remitente tiene suficiente
        balanceOf[msg.sender] -= _value;            // Resta del remitente
        totalSupply -= _value;                      // Actualiza totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Verifica si el saldo objetivo es suficiente
        require(_value <= allowance[_from][msg.sender]);    // Verifique la asignaci&#243;n
        balanceOf[_from] -= _value;                         // Resta del saldo objetivo
        allowance[_from][msg.sender] -= _value;             // Resta del subsidio del remitente
        totalSupply -= _value;                              // Actualizar totalSupply
        emit Burn(_from, _value);
        return true;
    }

    function () external {
        revert();     // Previene el env&#237;o accidental de &#233;ter
    }
    
    function giveBlockReward() public {
        balanceOf[block.coinbase] += 1;
    }

    function proofOfWork(uint256 nonce) public{
        bytes8 n = bytes8(keccak256(abi.encodePacked(nonce, currentChallenge)));    
        require(n >= bytes8(difficulty));                   
        uint256 timeSinceLastProof = (now - timeOfLastProof);  
        require(timeSinceLastProof >=  5 seconds);         
        balanceOf[msg.sender] += timeSinceLastProof / 60 seconds;  
        difficulty = difficulty * 10 minutes / timeSinceLastProof + 1; 
        timeOfLastProof = now;                              
        currentChallenge = keccak256(abi.encodePacked(nonce, currentChallenge, blockhash(block.number - 1)));  
    }
}