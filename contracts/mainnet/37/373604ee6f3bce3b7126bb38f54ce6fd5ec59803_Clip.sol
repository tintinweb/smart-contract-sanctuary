pragma solidity ^0.4.20;

/**
 * @title ContractReceiver
 * @dev Receiver for ERC223 tokens
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


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

contract ERC223 {
  uint public totalSupply;

  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function decimals() public view returns (uint8 _decimals);
  function totalSupply() public view returns (uint256 _supply);
  function balanceOf(address who) public view returns (uint);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract Clip is ERC223, Ownable {
  using SafeMath for uint256;

  string public name = "ClipToken";
  string public symbol = "CLIP";
  uint8 public decimals = 8;
  uint256 public initialSupply = 120e8 * 1e8;
  uint256 public totalSupply;
  uint256 public distributeAmount = 0;
  bool public mintingFinished = false;

  mapping (address => uint) balances;
  mapping (address => bool) public frozenAccount;
  mapping (address => uint256) public unlockUnixTime;

  event FrozenFunds(address indexed target, bool frozen);
  event LockedFunds(address indexed target, uint256 locked);
  event Burn(address indexed burner, uint256 value);
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  function Clip() public {
    totalSupply = initialSupply;
    balances[msg.sender] = totalSupply;
  }

  function name() public view returns (string _name) {
      return name;
  }

  function symbol() public view returns (string _symbol) {
      return symbol;
  }

  function decimals() public view returns (uint8 _decimals) {
      return decimals;
  }

  function totalSupply() public view returns (uint256 _totalSupply) {
      return totalSupply;
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }

  modifier onlyPayloadSize(uint256 size){
    assert(msg.data.length >= size + 4);
    _;
  }

  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
    require(_value > 0
            && frozenAccount[msg.sender] == false
            && frozenAccount[_to] == false
            && now > unlockUnixTime[msg.sender]
            && now > unlockUnixTime[_to]);

    if(isContract(_to)) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
        balances[_to] = SafeMath.add(balanceOf(_to), _value);
        assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
        Transfer(msg.sender, _to, _value, _data);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
  }


  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
    require(_value > 0
            && frozenAccount[msg.sender] == false
            && frozenAccount[_to] == false
            && now > unlockUnixTime[msg.sender]
            && now > unlockUnixTime[_to]);

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
    require(_value > 0
            && frozenAccount[msg.sender] == false
            && frozenAccount[_to] == false
            && now > unlockUnixTime[msg.sender]
            && now > unlockUnixTime[_to]);

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

  // assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) private view returns (bool is_contract) {
    uint length;
    assembly {
      // retrieve the size of the code on target address, this needs assembly
      length := extcodesize(_addr)
    }
    return (length>0);
  }

  // function that is called when transaction target is an address
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
    balances[_to] = SafeMath.add(balanceOf(_to), _value);
    Transfer(msg.sender, _to, _value, _data);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  //function that is called when transaction target is a contract
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
    balances[_to] = SafeMath.add(balanceOf(_to), _value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value, _data);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Prevent targets from sending or receiving tokens
   * @param targets Addresses to be frozen
   * @param isFrozen either to freeze it or not
   */
  function freezeAccounts(address[] targets, bool isFrozen) onlyOwner public {
    require(targets.length > 0);

    for (uint i = 0; i < targets.length; i++) {
      require(targets[i] != 0x0);
      frozenAccount[targets[i]] = isFrozen;
      FrozenFunds(targets[i], isFrozen);
    }
  }

  /**
   * @dev Prevent targets from sending or receiving tokens by setting Unix times
   * @param targets Addresses to be locked funds
   * @param unixTimes Unix times when locking up will be finished
   */
  function lockupAccounts(address[] targets, uint[] unixTimes) onlyOwner public {
    require(targets.length > 0
            && targets.length == unixTimes.length);

    for(uint i = 0; i < targets.length; i++){
      require(unlockUnixTime[targets[i]] < unixTimes[i]);
      unlockUnixTime[targets[i]] = unixTimes[i];
      LockedFunds(targets[i], unixTimes[i]);
    }
  }

  /**
   * @dev Burns a specific amount of tokens.
   * @param _from The address that will burn the tokens.
   * @param _unitAmount The amount of token to be burned.
   */
  function burn(address _from, uint256 _unitAmount) onlyOwner public {
    require(_unitAmount > 0
            && balanceOf(_from) >= _unitAmount);

    balances[_from] = SafeMath.sub(balances[_from], _unitAmount);
    totalSupply = SafeMath.sub(totalSupply, _unitAmount);
    Burn(_from, _unitAmount);
  }

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _unitAmount The amount of tokens to mint.
   */
  function mint(address _to, uint256 _unitAmount) onlyOwner canMint public returns (bool) {
    require(_unitAmount > 0);

    totalSupply = SafeMath.add(totalSupply, _unitAmount);
    balances[_to] = SafeMath.add(balances[_to], _unitAmount);
    Mint(_to, _unitAmount);
    Transfer(address(0), _to, _unitAmount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

  /**
   * @dev Function to distribute tokens to the list of addresses by the provided amount
   */
  function distributeTokens(address[] addresses, uint256 amount) public returns (bool) {
    require(amount > 0
            && addresses.length > 0
            && frozenAccount[msg.sender] == false
            && now > unlockUnixTime[msg.sender]);

    amount = SafeMath.mul(amount, 1e8);
    uint256 totalAmount = SafeMath.mul(amount, addresses.length);
    require(balances[msg.sender] >= totalAmount);

    for (uint i = 0; i < addresses.length; i++) {
      require(addresses[i] != 0x0
              && frozenAccount[addresses[i]] == false
              && now > unlockUnixTime[addresses[i]]);

      balances[addresses[i]] = SafeMath.add(balances[addresses[i]], amount);
      Transfer(msg.sender, addresses[i], amount);
    }
    balances[msg.sender] = SafeMath.sub(balances[msg.sender], totalAmount);
    return true;
  }

  /**
   * @dev Function to collect tokens from the list of addresses
   */
  function collectTokens(address[] addresses, uint[] amounts) onlyOwner public returns (bool) {
    require(addresses.length > 0
            && addresses.length == amounts.length);

    uint256 totalAmount = 0;

    for (uint i = 0; i < addresses.length; i++) {
      require(amounts[i] > 0
              && addresses[i] != 0x0
              && frozenAccount[addresses[i]] == false
              && now > unlockUnixTime[addresses[i]]);

      amounts[i] = SafeMath.mul(amounts[i], 1e8);
      require(balances[addresses[i]] >= amounts[i]);
      balances[addresses[i]] = SafeMath.sub(balances[addresses[i]], amounts[i]);
      totalAmount = SafeMath.add(totalAmount, amounts[i]);
      Transfer(addresses[i], msg.sender, amounts[i]);
    }
    balances[msg.sender] = SafeMath.add(balances[msg.sender], totalAmount);
    return true;
  }

  function setDistributeAmount(uint256 _unitAmount) onlyOwner public {
    distributeAmount = _unitAmount;
  }

  /**
   * @dev Function to distribute tokens to the msg.sender automatically
   *      If distributeAmount is 0, this function doesn&#39;t work
   */
  function autoDistribute() payable public {
    require(distributeAmount > 0
            && balanceOf(owner) >= distributeAmount
            && frozenAccount[msg.sender] == false
            && now > unlockUnixTime[msg.sender]);
    if (msg.value > 0) owner.transfer(msg.value);

    balances[owner] = SafeMath.sub(balances[owner], distributeAmount);
    balances[msg.sender] = SafeMath.add(balances[msg.sender], distributeAmount);
    Transfer(owner, msg.sender, distributeAmount);
  }

  /**
   * @dev token fallback function
   */
  function() payable public {
    autoDistribute();
  }
}