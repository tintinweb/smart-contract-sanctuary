//SourceUnit: token.sol

pragma solidity ^0.4.24;

/* Base token contract for the forgable tokens and also the Arcadium Token */

contract Owned {
  address public owner;
  address public oldOwner;
  uint public tokenId = 1002567;
  uint lastChangedOwnerAt;
  constructor() {
    owner = msg.sender;
    oldOwner = owner;
  }
  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }
  modifier isOldOwner() {
    require(msg.sender == oldOwner);
    _;
  }
  modifier sameOwner() {
    address addr = msg.sender;
    // Ensure that the address is a contract
    uint size;
    assembly { size := extcodesize(addr) }
    require(size > 0);

    // Ensure that the contract's parent is
    Owned own = Owned(addr);
    require(own.owner() == owner);
     _;
  }
  // Be careful with this option!
  function changeOwner(address newOwner) public isOwner {
    lastChangedOwnerAt = now;
    oldOwner = owner;
    owner = newOwner;
  }
  // Allow a revert to old owner ONLY IF it has been less than a day
  function revertOwner() public isOldOwner {
    require(oldOwner != owner);
    require((now - lastChangedOwnerAt) * 1 seconds < 86400);
    owner = oldOwner;
  }
}

contract ForgableToken is Owned {
/// @return total amount of tokens
  function totalSupply() public view returns (uint256 supply) {}
  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) public view returns (uint256 balance) {}
  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) returns (bool success) {}
  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) returns (bool success) {}
  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {}
  /// @return Whether the forging was successful or not

  // Forge specific properties that need to be included in the contract
  function forge() external payable returns (bool success) {}
  function maxForge() public view returns (uint256 amount) {}
  function baseConversionRate() public view returns (uint256 best_price) {}
  function timeToForge(address addr) public view returns (uint256 time) {}
  function forgePrice() public view returns (uint256 price) {}
  function smithCount() public view returns (uint256 count) {}
  function smithFee() public view returns (uint256 fee) {}
  function canSmith() public view returns (bool able) {}
  function totalWRLD() public view returns (uint256 wrld) {}
  function firstMint() public view returns (uint256 date) {}
  function lastMint() public view returns (uint256 date) {}
  function paySmithingFee() external payable returns (bool fee) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event Forged(address indexed _to, uint _cost, uint _amt);
  event NewSmith(address indexed _address, uint _fee);
}

// Health Coin
contract PHCToken is ForgableToken {
  constructor() {
    totalSupply = 2000000000000; // Start with two million tokens...
    name = "Public Health Coin";
    symbol = "PHC";
    decimals = 6;
    sendTo = msg.sender;
    emit Forged(msg.sender, 0, totalSupply);
    emit Transfer(this, msg.sender, totalSupply);
    balances[msg.sender] = totalSupply;
  }
  function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
          balances[msg.sender] -= _value;
          balances[_to] += _value;
          emit Transfer(msg.sender, _to, _value);
          return true;
      } else { return false; }
  }
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
          balances[_to] += _value;
          balances[_from] -= _value;
          allowed[_from][msg.sender] -= _value;
          emit Transfer(_from, _to, _value);
          return true;
      } else { return false; }
  }
  function balanceOf(address _owner) public view returns (uint256 balance) {
      return balances[_owner];
  }
  function approve(address _spender, uint256 _value) returns (bool success) {
      allowed[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);
      return true;
  }
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  uint256 public totalSupply;
  string public name;
  string public symbol;
  uint8 public decimals;
  /* This is where all the special operations will occur */
  // Returns the maximum amount of WRLD that can be sent to mint new tokens
  function maxForge() public view returns (uint256) {
    if (totalWRLD / 1000 < 100000000000) return 100000000000;
    return totalWRLD / 1000;
  }
  // Returns the number of seconds until the user can mint tokens again
  function timeToForge(address addr) public view returns (uint256) {
    uint256 dif = (now - lastMinted[addr]);
    if (dif > 3600) return 0;
    return 3600 - dif;
  }
  // Mints new tokens based on how many tokens have already been minted
  // Tempted to require a minting fee...
  function forge() external payable returns (bool success) {
    // Limit minting rate to the greater of 0.1% of the amount of WRLD frozen so far or 100,000 WRLD
    require(msg.tokenid == tokenId, "Wrong Token");
    require(msg.tokenvalue <= 100000000000 || msg.tokenvalue <= totalWRLD / 1000, "Maximum WRLD Exceeded");
    require(msg.sender == owner || paid[msg.sender], "Not a Registered Smith");

    // Only let a person mint once per hour
    uint256 start = now;
    require(start - lastMinted[msg.sender] > 3600, "Too Soon to Forge Again");

    // Calculate the amount of token to be minted. Make sure that there's no chance of overflow!
    uint256 amt = msg.tokenvalue / _calculateCost(start);

    // Freeze WRLD
    sendTo.transferToken(msg.tokenvalue, tokenId);

    // Mint tokens
    totalSupply += amt;
    emit Forged(msg.sender, msg.tokenvalue, amt);

    // Send them to the minter
    balances[msg.sender] += amt;
    emit Transfer(this, msg.sender, amt);
    lastMinted[msg.sender] = start;
    if (firstMint == 0) firstMint = start;
    lastMint = start;
    totalWRLD += msg.tokenvalue;
    return true;
  }

  // Base Minting
  // While the forge system is open to everyone, and can be used to increase the supply at a cost of WRLD, a supply of tokens will be needed to distribute to our responders.
  // This function will allow a cetain number of tokens to be minted to fund this effort.
  uint256 public lastOwnerMint;
  uint8 public remaining = 24; // Used to decrease the owner mint rate over time, allowing for an initially high rate to fund initial efforts.
  function ownerMint() public isOwner returns (bool success) {
    uint256 start = now;
    if (start - lastOwnerMint > 2592000) {
      lastOwnerMint = start;
      uint256 amt = (totalSupply * remaining) / 2400;
      totalSupply += amt;
      emit Forged(owner, 0, amt);
      if (remaining > 1) remaining -= 1;
      balances[owner] += amt;
      emit Transfer(this, owner, amt);
      return true;
    }
    return false;
  }

  // Get the current conversion rate
  function _calculateCost(uint256 _now) internal returns (uint256) {
    if (firstMint == 0) return baseConversionRate;
    uint256 time1 = (_now - firstMint);
    uint256 time2 = (_now - lastMint);
    uint256 conv = (time1 * 100) / (time2 * time2 * time2 + 1);
    if (conv < 100) conv = 100; // Don't let people forge for free!
    if (conv > 10000) conv = 10000;
    return (baseConversionRate * conv) / 100;
  }
  // Price to mint one ARC token
  function forgePrice() public view returns (uint256) {
    return _calculateCost(now);
  }
  // Allow's the change of the address to which frozen tokens go. Can only be done if sendTo is the default or within the first week after it's changed
  function changeSendTo(address newAddr) public isOwner {
    require(sendTo == owner || (now - setAt) < 604800);
    setAt = now;
    sendTo = newAddr;
  }
  function canSmith(address addr) public view returns (bool) {
    return addr == owner || paid[msg.sender];
  }
  function canSmith() public view returns (bool) {
    return canSmith(msg.sender);
  }
  function paySmithingFee() external payable returns (bool success) {
    if (paid[msg.sender] || msg.value != smithFee || msg.sender == owner) return false;
    owner.transfer(msg.value);
    // Every ten smiths increases the smith fee by 100 TRX
    if (smithFee < 1000000000 && (smithCount + 1) % 10 == 0) smithFee += 100000000;
    smithCount++;
    paid[msg.sender] = true;
    emit NewSmith(msg.sender, msg.value);
    return true;
  }
  mapping (address => uint256) public lastMinted;
  mapping (address => bool) public paid;
  uint256 public smithCount;
  uint256 public smithFee = 10000000;
  uint256 public baseConversionRate = 10; // 10 WRLD = 1 ARC
  uint256 public totalWRLD; // Total amount of world used to mint
  uint256 public firstMint; // Date of the first minting
  uint256 public lastMint; // Date of most recent minting
  address public sendTo;
  uint256 setAt;
}