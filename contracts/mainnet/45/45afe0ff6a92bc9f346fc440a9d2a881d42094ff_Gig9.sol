pragma solidity ^0.4.18;


 /*
 * Contract that is working with ERC223 tokens
 */


library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
} 
 contract ContractReceiver {
     
   struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }
    
    address [] public senders;
    function tokenFallback(address _from, uint _value, bytes _data) public  {
        require(_from != address(0));
        require(_value>0);
        TKN memory tkn;
        tkn.sender = _from;
        tkn.value = _value;
        tkn.data = _data;
        uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
        tkn.sig = bytes4(u);
        senders.push(_from);
    }
}
contract ERC223Interface {
  function balanceOf(address who) public view returns (uint);
  
  function name() public view returns (string);
  function symbol() public view returns (string);
  function decimals() public view returns (uint);
  function totalSupply() public view returns (uint256);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC223Token  is ERC223Interface  {

  mapping(address => uint) balances;
  
  string internal _name;
  string internal _symbol;
  uint internal _decimals;
  uint256 internal _totalSupply;
   using SafeMath for uint;
  
  
  // Function to access name of token .
  function name() public view returns (string) {
      return _name;
  }
  // Function to access symbol of token .
  function symbol() public view returns (string) {
      return _symbol;
  }
  // Function to access decimals of token .
  function decimals() public view returns (uint ) {
      return _decimals;
  }
  // Function to access total supply of tokens .
  function totalSupply() public view returns (uint256 ) {
      return _totalSupply;
  }
  
  
  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
     require(_to != address(0));
    if(isContract(_to)) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add( _value);
        assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
        emit Transfer(msg.sender, _to, _value);
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
    require(_value>0);
    require(balanceOf(msg.sender)>=_value);
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add( _value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  
  //function that is called when transaction target is a contract
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    require(_value>0);
    require(balanceOf(msg.sender)>=_value);
    balances[msg.sender] = balanceOf(msg.sender).sub( _value);
    balances[_to] = balanceOf(_to).add(_value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    emit Transfer(msg.sender, _to, _value);
    return true;
}


  function balanceOf(address _owner) public view returns (uint) {
    return balances[_owner];
  }
}
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Balances is Ownable,
ERC223Token {
    mapping(address => bool)public modules;
    using SafeMath for uint256; 
    address public tokenTransferAddress;  
     function Balances()public {
        // constructor
    }
    // Address where funds are collected

    function updateModuleStatus(address _module, bool status)public onlyOwner {
        require(_module != address(0));
        modules[_module] = status;
    }

    function updateTokenTransferAddress(address _tokenAddr)public onlyOwner {
        require(_tokenAddr != address(0));
        tokenTransferAddress = _tokenAddr;

    }

    modifier onlyModule() {
        require(modules[msg.sender] == true);
        _;
    }

    function increaseBalance(address recieverAddr, uint256 _tokens)onlyModule public returns(
        bool
    ) {
        require(recieverAddr != address(0));
        require(balances[tokenTransferAddress] >= _tokens);
        balances[tokenTransferAddress] = balances[tokenTransferAddress].sub(_tokens);
        balances[recieverAddr] = balances[recieverAddr].add(_tokens);
        emit Transfer(tokenTransferAddress,recieverAddr,_tokens);
        return true;
    }
    function decreaseBalance(address recieverAddr, uint256 _tokens)onlyModule public returns(
        bool
    ) {
        require(recieverAddr != address(0));
        require(balances[recieverAddr] >= _tokens);
        balances[recieverAddr] = balances[recieverAddr].sub(_tokens);
        balances[tokenTransferAddress] = balances[tokenTransferAddress].add(_tokens);
        emit Transfer(tokenTransferAddress,recieverAddr,_tokens);
        return true;
    }

   
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}
/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {

  function Destructible() public payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

contract Gig9 is Balances,
Pausable,
Destructible {
    
    function Gig9()public {
        _name = "GIG9";
        _symbol = "GIG";
        _decimals = 8;
        _totalSupply = 268000000 * (10 ** _decimals);
        owner = msg.sender;
        balances[0x0A35230Af852bc0C094978851640Baf796f1cC9D] = _totalSupply;
        tokenTransferAddress = 0x0A35230Af852bc0C094978851640Baf796f1cC9D;
    }

    function ()public {
        revert();

    }

   

}