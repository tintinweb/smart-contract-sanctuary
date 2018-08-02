pragma solidity 0.4.24;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract owned {
    address public owner;
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}


contract token {
    string public name; 
    string public symbol; 
    uint8 public decimals = 8;  
    uint256 public totalSupply; 

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value); 
    event Burn(address indexed from, uint256 value);  

    constructor(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        balances[msg.sender] = totalSupply;                        //balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;

    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
      require(_to != 0x0);
      require(balances[_from] >= _value);
      require(balances[_to] + _value > balances[_to]);
      uint previousBalances = balances[_from] + balances[_to];
      balances[_from] -= _value;
      balances[_to] += _value;
      emit Transfer(_from, _to, _value);
      assert(balances[_from] + balances[_to] == previousBalances);

    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

  
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);         // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
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
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balances[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }

}

contract SVC is owned, token {
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);

    constructor(
      uint256 initialSupply,
      string tokenName,
      string tokenSymbol
    ) token (initialSupply, tokenName, tokenSymbol) public {}


    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);
        require (balances[_from] > _value);
        require (balances[_to] + _value > balances[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);

    }

 
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {

        balances[target] += mintedAmount;
        totalSupply += mintedAmount;

        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

  
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

}