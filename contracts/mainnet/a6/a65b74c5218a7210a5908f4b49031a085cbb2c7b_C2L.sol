/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  uint constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

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
}

/*
  Contract to handle all behavior related to ownership of contracts
  -handles tracking current owner and transferring ownership to new owners
*/
contract Owned {
  address public owner;
  address private newOwner;

  event OwnershipTransferred(address indexed_from, address indexed_to);

  function Owned() public {
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
    newOwner = address(0); //reset newOwner to 0/null
  }
}

/*
  Interface for being ERC223 compliant
  -ERC223 is an industry standard for smart contracts
*/
contract ERC223 {
  function balanceOf(address who) public view returns (uint);
  
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function decimals() public view returns (uint8 _decimals);
  function totalSupply() public view returns (uint256 _supply);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
  
  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

/*
 * Contract that is working with ERC223 tokens as a receiver for contract transfers
 */
 
 contract ContractReceiver {
     
    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }
    
    
    function tokenFallback(address _from, uint _value, bytes _data) public pure {
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

/*
  @author Nicholas Tuley
  @desc Contract for the C2L token that carries out all token-specific behaviors for the C2L token
*/
contract C2L is ERC223, Owned {
  //constants
  uint internal constant INITIAL_COIN_BALANCE = 21000000; //starting balance of 21 million coins

  //variables
  string public name = "C2L"; //name of currency
  string public symbol = "C2L";
  uint8 public decimals = 0;
  mapping(address => bool) beingEdited; //mapping to prevent multiple edits of the same account occuring at the same time (reentrancy)

  uint public totalCoinSupply = INITIAL_COIN_BALANCE; //number of this coin in active existence
  mapping(address => uint) internal balances; //balances of users with this coin
  mapping(address => mapping(address => uint)) internal allowed; //map holding how much each user is allowed to transfer out of other addresses
  address[] addressLUT;

  //C2L contract constructor
  function C2L() public {
    totalCoinSupply = INITIAL_COIN_BALANCE;
    balances[owner] = totalCoinSupply;
    updateAddresses(owner);
  }

  //getter methods for basic contract info
  function name() public view returns (string _name) {
    return name;
  }

  function symbol() public view returns (string _symbol) {
    return symbol;
  }

  function decimals() public view returns (uint8 _decimals) {
    return decimals;
  }

  /*
    @return the total supply of this coin
  */
  function totalSupply() public view returns (uint256 _supply) {
    return totalCoinSupply;
  }

  //toggle beingEdited status of this account
  function setEditedTrue(address _subject) private {
    beingEdited[_subject] = true;
  }

  function setEditedFalse(address _subject) private {
    beingEdited[_subject] = false;
  }

  /*
    get the balance of a given user
    @param tokenOwner the address of the user account being queried
    @return the balance of the given account
  */
  function balanceOf(address who) public view returns (uint) {
    return balances[who];
  }

  /*
    Check if the given address is a contract
  */
  function isContract(address _addr) private view returns (bool is_contract) {
    uint length;
    assembly {
          //retrieve the size of the code on target address, this needs assembly
          length := extcodesize(_addr)
    }
    return (length>0);
  }

  /*
    owner mints new coins
    @param amount The number of coins to mint
    @condition
      -the sender of this message must be the owner/minter/creator of this contract
  */
  function mint(uint amount) public onlyOwner {
    require(beingEdited[owner] != true);
    setEditedTrue(owner);
    totalCoinSupply = SafeMath.add(totalCoinSupply, amount);
    balances[owner] = SafeMath.add(balances[owner], amount);
    setEditedFalse(owner);
  }

  /*
    transfer tokens to a user from the msg sender
    @param _to The address of the user coins are being sent to
    @param _value The number of coins to send
    @param _data The msg data for this transfer
    @param _custom_fallback A custom fallback function for this transfer
    @conditions:
      -coin sender must have enough coins to carry out transfer
      -the balances of the sender and receiver of the tokens must not be being edited by another transfer at the same time
    @return True if execution of transfer is successful, False otherwise
  */
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
    if(isContract(_to)) {
      require(beingEdited[_to] != true && beingEdited[msg.sender] != true);
      //make sure the sender has enough coins to transfer
      require (balances[msg.sender] >= _value); 
      setEditedTrue(_to);
      setEditedTrue(msg.sender);
      //transfer the coins
      balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
      balances[_to] = SafeMath.add(balances[_to], _value);
      assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
      emit Transfer(msg.sender, _to, _value, _data); //log the transfer
      setEditedFalse(_to);
      setEditedFalse(msg.sender);
      updateAddresses(_to);
      updateAddresses(msg.sender);
      return true;
    }
    else {
      return transferToAddress(_to, _value, _data);
    }
  }

  /*
    Carry out transfer of tokens between accounts
    @param _to The address of the user coins are being sent to
    @param _value The number of coins to send
    @param _data The msg data for this transfer
    @conditions:
      -coin sender must have enough coins to carry out transfer
      -the balances of the sender and receiver of the tokens must not be being edited by another transfer at the same time
    @return True if execution of transfer is successful, False otherwise
  */
  function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
      if(isContract(_to)) {
          return transferToContract(_to, _value, _data);
      }
      else {
          return transferToAddress(_to, _value, _data);
      }
  }

  /*
    Backwards compatible transfer function to satisfy ERC20
  */
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

  //transfer function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
      require(beingEdited[_to] != true && beingEdited[msg.sender] != true);
      require (balanceOf(msg.sender) >= _value);
      setEditedTrue(_to);
      setEditedTrue(msg.sender);
      balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
      balances[_to] = SafeMath.add(balanceOf(_to), _value);
      emit Transfer(msg.sender, _to, _value, _data);
      setEditedFalse(_to);
      setEditedFalse(msg.sender);
      updateAddresses(_to);
      updateAddresses(msg.sender);
      return true;
    }

  //transfer function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
      require(beingEdited[_to] != true && beingEdited[msg.sender] != true);
      require (balanceOf(msg.sender) >= _value);
      setEditedTrue(_to);
      setEditedTrue(msg.sender);
      balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
      balances[_to] = SafeMath.add(balanceOf(_to), _value);
      ContractReceiver receiver = ContractReceiver(_to);
      receiver.tokenFallback(msg.sender, _value, _data);
      emit Transfer(msg.sender, _to, _value, _data);
      setEditedFalse(_to);
      setEditedFalse(msg.sender);
      updateAddresses(_to);
      updateAddresses(msg.sender);
      return true;
  }

  /*
    update the addressLUT list of addresses by checking if the address is in the list already, and if not, add the address to the list
    @param _lookup The address to check if it is in the list
  */
  function updateAddresses(address _lookup) private {
    for(uint i = 0; i < addressLUT.length; i++) {
      if(addressLUT[i] == _lookup) return;
    }
    addressLUT.push(_lookup);
  }

  //default, fallback function
  function () public payable {
  }

  //self-destruct function for this contract
  function killCoin() public onlyOwner {
    selfdestruct(owner);
  }

}