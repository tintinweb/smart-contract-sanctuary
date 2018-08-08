pragma solidity ^0.4.9;

contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  
  function name() constant returns (string _name);
  function symbol() constant returns (string _symbol);
  function decimals() constant returns (uint8 _decimals);
  function totalSupply() constant returns (uint256 _supply);

  function transfer(address to, uint value) returns (bool ok);
  function transfer(address to, uint value, bytes data) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ContractReceiver {
     
    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }
    
    
    function tokenFallback(address _from, uint _value, bytes _data){
      TKN memory tkn;
      tkn.sender = _from;
      tkn.value = _value;
      tkn.data = _data;
      uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      tkn.sig = bytes4(u);
      
      /* tkn variable is analogue of msg variable of Ether transaction
      *  tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
      *  tkn.value the number of tokens that were sent   (analogue of msg.value)
      *  tkn.data is data of token transaction   (analogue of msg.data)
      *  tkn.sig is 4 bytes signature of function
      *  if data of token transaction is a function execution
      */
    }
}
 /**
 * ERC23 token by Dexaran
 *
 * https://github.com/Dexaran/ERC23-tokens
 */
 
 
 /* https://github.com/LykkeCity/EthereumApiDotNetCore/blob/master/src/ContractBuilder/contracts/token/SafeMath.sol */
contract SafeMath {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert(x <= MAX_UINT256 - y);
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert(x >= y);
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (y == 0) return 0;
        assert(x <= MAX_UINT256 / y);
        return x * y;
    }
}
 
/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    assert(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    assert(!halted);
    _;
  }

  modifier onlyInEmergency {
    assert(halted);
    _;
  }

  // called by the owner on emergency, triggers stopped state
  function halt() external onlyOwner {
    halted = true;
  }

  // called by the owner on end of emergency, returns to normal state
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}

contract ERC223Token is ERC223, SafeMath, Haltable {

  mapping(address => uint) balances;
  
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  
  
  // Function to access name of token .
  function name() constant returns (string _name) {
      return name;
  }
  // Function to access symbol of token .
  function symbol() constant returns (string _symbol) {
      return symbol;
  }
  // Function to access decimals of token .
  function decimals() constant returns (uint8 _decimals) {
      return decimals;
  }
  // Function to access total supply of tokens .
  function totalSupply() constant returns (uint256 _totalSupply) {
      return totalSupply;
  }
  
  

  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data) returns (bool success) {
      
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}
  
  // Standard function transfer similar to ERC20 transfer with no _data .
  // Added due to backwards compatibility reasons .
  function transfer(address _to, uint _value) returns (bool success) {
      
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
  function isContract(address _addr) private returns (bool is_contract) {
      uint length;
      assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        if(length>0) {
            return true;
        }
        else {
            return false;
        }
    }

  //function that is called when transaction target is an address
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    assert(balanceOf(msg.sender) >= _value);
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    Transfer(msg.sender, _to, _value, _data);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  
  //function that is called when transaction target is a contract
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    assert(balanceOf(msg.sender) >= _value);
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    ContractReceiver reciever = ContractReceiver(_to);
    reciever.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value, _data);
    Transfer(msg.sender, _to, _value);
    return true;
}


  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
  
  
}

contract MindToken is ERC223Token {

    address public beneficiary;
    event Buy(address indexed participant, uint tokens, uint eth);
    event GoalReached(uint amountRaised);

    uint public cap = 20000000000000;
    uint public price;
    uint public collectedTokens;
    uint public collectedEthers;

    uint public tokensSold = 0;
    uint public weiRaised = 0;
    uint public investorCount = 0;

    uint public startTime;
    uint public endTime;

    bool public capReached = false;
    bool public presaleFinished = false;

  /**
   * @dev Contructor that gives msg.sender all of existing tokens. 
   */
    function MindToken() {
            
        name = "Mind10 Token";
        symbol = "Mind10";
        decimals = 8;
        totalSupply = 500000000000000;
    
        address _beneficiary = 0x0980eaD74d176025F2962f8b5535346c77ffd2f5;
        //uint _price = 0.00001;
        uint _price = 150;
        uint _startTime = 1502704800;
        uint _duration = 15;
            
        balances[msg.sender] = totalSupply;
        
        beneficiary = _beneficiary;
        price = _price;

        startTime = _startTime;
        endTime = _startTime + _duration * 1 minutes;
        
    }
    
    modifier onlyAfter(uint time) {
        assert(now >= time);
        _;
    }

    modifier onlyBefore(uint time) {
        assert(now <= time);
        _;
    }
    
    function () payable stopInEmergency {
        assert(msg.value >= 0.01 * 1 ether);
        doPurchase();
        
        //if (msg.value < 0.01 * 1 ether) throw;
        
    }
    
    function doPurchase() private onlyAfter(startTime) onlyBefore(endTime) {

        assert(!presaleFinished);
        
        uint tokens = msg.value * price / 10000000000;

        if (balanceOf(msg.sender) == 0) investorCount++;
        
        balances[owner] -= tokens;
        balances[msg.sender] += tokens;
        
        collectedTokens = safeAdd(collectedTokens, tokens);
        collectedEthers = safeAdd(collectedEthers, msg.value);
        
        //assert(collectedTokens <= cap);
        
        weiRaised = safeAdd(weiRaised, msg.value);
        tokensSold = safeAdd(tokensSold, tokens);
        
        bytes memory empty;
        Transfer(owner, msg.sender, tokens, empty);
        Transfer(owner, msg.sender, tokens);
        
        Buy(msg.sender, tokens, msg.value);
        
        if (collectedTokens == cap) {
            GoalReached(cap);
        }

    }
    
    function withdraw() onlyOwner onlyAfter(endTime) returns (bool) {
        //assert(capReached);
        if (!beneficiary.send(collectedEthers)) {
            return false;
        }
        //token.transfer(beneficiary, token.balanceOf(this));
        presaleFinished = true;
        return true;
    }
    
    
}