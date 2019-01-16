pragma solidity ^0.4.9;
 
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}
 
contract ERC223Token is SafeMath, Owned {
    
  event Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);

  mapping(address => uint) balances;
  mapping(address => bool) public verified;
  
  string public name    = "Storh";
  string public symbol  = "STORH";
  uint8 public decimals = 14;
  uint public totalSupply;
  uint public startTime;
  
  modifier isVerified(address reciever) {
        require(verified[msg.sender]);
        require(verified[reciever]);
        _;
    } 
    
  modifier hasMinBalance(uint value) {
      if(now < (startTime + 365 days) && msg.sender == owner){
        require(balances[owner] >= ((totalSupply*5)/100) + value);
      }
      _;
  }

  constructor () public
  {
      balances[msg.sender] = 12000000000000000000000;
      totalSupply = balances[msg.sender];
      verified[msg.sender] = true;
      startTime = now;
  }
  
  function verifyAccount(address account) public onlyOwner {
      verified[account] = true;
  }
  
  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public isVerified(_to) hasMinBalance(_value) returns (bool success) {
      
    if(isContract(_to)) {
        require(balanceOf(msg.sender) >= _value);
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        assert(_to.call.value(0)(bytes4(keccak256(abi.encodePacked(_custom_fallback))), msg.sender, _value, _data));
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}

  function setStartTime(uint _startTime) public {
    startTime = _startTime;
  }

  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data) public isVerified(_to) hasMinBalance(_value) returns (bool success) {
      
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}
  
  // Standard function transfer similar to ERC20 transfer with no _data .
  // Added due to backwards compatibility reasons .
  function transfer(address _to, uint _value) public isVerified(_to) hasMinBalance(_value) returns (bool success) {
      
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
    require(balanceOf(msg.sender) >= _value);
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }
  
  //function that is called when transaction target is a contract
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    require(balanceOf(msg.sender) >= _value);
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
}


  function balanceOf(address _owner) constant public returns (uint balance) {
    return balances[_owner];
  }
}