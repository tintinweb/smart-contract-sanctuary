pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
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
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
}

/**
 * @title Contract that will work with ERC223 tokens.
 */
 
contract ERC223ReceivingContract {

  struct TKN {
    address sender;
    uint value;
    bytes data;
    bytes4 sig;
  }

  /**
   * @dev Standard ERC223 function that will handle incoming token transfers.
   *
   * @param _from  Token sender address.
   * @param _value Amount of tokens.
   * @param _data  Transaction metadata.
   */
  function tokenFallback(address _from, uint _value, bytes _data) public pure {
    TKN memory tkn;
    tkn.sender = _from;
    tkn.value = _value;
    tkn.data = _data;
    if(_data.length > 0) {
      uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      tkn.sig = bytes4(u);
    }

    /* tkn variable is analogue of msg variable of Ether transaction
    *  tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
    *  tkn.value the number of tokens that were sent   (analogue of msg.value)
    *  tkn.data is data of token transaction   (analogue of msg.data)
    *  tkn.sig is 4 bytes signature of function
    *  if data of token transaction is a function execution
    */
  }

}

contract ERC223Interface {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);
  function allowedAddressesOf(address who) public view returns (bool);
  function getTotalSupply() public view returns (uint);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);

  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Unity Token is ERC223 token.
 * @author Vladimir Kovalchuk
 */

contract UnityToken is ERC223Interface {
  using SafeMath for uint;

  string public constant name = "Unity Token";
  string public constant symbol = "UNT";
  uint8 public constant decimals = 18;


  /* The supply is initially 100UNT to the precision of 18 decimals */
  uint public constant INITIAL_SUPPLY = 100000 * (10 ** uint(decimals));

  mapping(address => uint) balances; // List of user balances.
  mapping(address => bool) allowedAddresses;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function addAllowed(address newAddress) public onlyOwner {
    allowedAddresses[newAddress] = true;
  }

  function removeAllowed(address remAddress) public onlyOwner {
    allowedAddresses[remAddress] = false;
  }


  address public owner;

  /* Constructor initializes the owner&#39;s balance and the supply  */
  function UnityToken() public {
    owner = msg.sender;
    totalSupply = INITIAL_SUPPLY;
    balances[owner] = INITIAL_SUPPLY;
  }

  function getTotalSupply() public view returns (uint) {
    return totalSupply;
  }

  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
    if (isContract(_to)) {
      require(allowedAddresses[_to]);
      if (balanceOf(msg.sender) < _value)
        revert();

      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
      Transfer(msg.sender, _to, _value);
      return true;
    }
    else {
      return transferToAddress(_to, _value);
    }
  }


  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data) public returns (bool success) {

    if (isContract(_to)) {
      return transferToContract(_to, _value, _data);
    } else {
      return transferToAddress(_to, _value);
    }
  }

  // Standard function transfer similar to ERC20 transfer with no _data .
  // Added due to backwards compatibility reasons .
  function transfer(address _to, uint _value) public returns (bool success) {
    //standard function transfer similar to ERC20 transfer with no _data
    //added due to backwards compatibility reasons
    bytes memory empty;
    if (isContract(_to)) {
      return transferToContract(_to, _value, empty);
    }
    else {
      return transferToAddress(_to, _value);
    }
  }

  //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) private view returns (bool is_contract) {
    uint length;
    assembly {
    //retrieve the size of the code on target address, this needs assembly
      length := extcodesize(_addr)
    }
    return (length > 0);
  }

  //function that is called when transaction target is an address
  function transferToAddress(address _to, uint _value) private returns (bool success) {
    if (balanceOf(msg.sender) < _value)
      revert();
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  //function that is called when transaction target is a contract
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    require(allowedAddresses[_to]);
    if (balanceOf(msg.sender) < _value)
      revert();
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value);
    return true;
  }


  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }

  function allowedAddressesOf(address _owner) public view returns (bool allowed) {
    return allowedAddresses[_owner];
  }
}