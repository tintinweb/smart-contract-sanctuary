pragma solidity 0.4.24;

// File: contracts/external/Token.sol

/*
  Abstract contract for the full ERC 20 Token standard
  https://github.com/ethereum/EIPs/issues/20
*/
contract Token {
  /* This is a slight change to the ERC20 base standard.
  function totalSupply() view returns (uint supply);
  is replaced map:
  uint public totalSupply;
  This automatically creates a getter function for the totalSupply.
  This is moved to the base contract since public getter functions are not
  currently recognised as an implementation of the matching abstract
  function by the compiler.
  */
  /// total amount of tokens
  uint public totalSupply;

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) public view returns (uint balance);

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint _value) public returns (bool success);

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint _value) public returns (bool success);

  /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of tokens to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint _value) public returns (bool success);

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) public view returns (uint remaining);

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}

// File: contracts/registry/Registry.sol

interface Registry {

  function contains(address apiKey) external view returns (bool);

  function register(address apiKey) external;
  function registerWithUserAgreement(address apiKey, bytes32 userAgreement) external;
  event Registered(address apiKey, address indexed account);

  function translate(address apiKey) external view returns (address);
}

// File: contracts/custodian/Withdrawing.sol

interface Withdrawing {

  function withdraw(address[] addresses, uint[] uints, bytes signature, bytes proof, bytes32 root) external;

  function claimExit(address[] addresses, uint[] uints, bytes signature, bytes proof, bytes32 root) external;

  function exit(bytes32 entryHash, bytes proof, bytes32 root) external;

  function exitOnHalt(address[] addresses, uint[] uints, bytes signature, bytes proof, bytes32 root) external;
}

// File: contracts/Math.sol

/* @title Math provides arithmetic functions for uint type pairs.
  You can safely `plus`, `minus`, `times`, and `divide` uint numbers without fear of integer overflow.
  You can also find the `min` and `max` of two numbers.
*/
library Math {

  function min(uint x, uint y) internal pure returns (uint) { return x <= y ? x : y; }
  function max(uint x, uint y) internal pure returns (uint) { return x >= y ? x : y; }


  /** @dev adds two numbers, reverts on overflow */
  function plus(uint x, uint y) internal pure returns (uint z) { require((z = x + y) >= x, "bad addition"); }

  /** @dev subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend) */
  function minus(uint x, uint y) internal pure returns (uint z) { require((z = x - y) <= x, "bad subtraction"); }


  /** @dev multiplies two numbers, reverts on overflow */
  function times(uint x, uint y) internal pure returns (uint z) { require(y == 0 || (z = x * y) / y == x, "bad multiplication"); }

  /** @dev divides two numbers and returns the remainder (unsigned integer modulo), reverts when dividing by zero */
  function mod(uint x, uint y) internal pure returns (uint z) {
    require(y != 0, "bad modulo; using 0 as divisor");
    z = x % y;
  }

  /** @dev integer division of two numbers, reverts if x % y != 0 */
  function dividePerfectlyBy(uint x, uint y) internal pure returns (uint z) {
    require((z = x / y) * y == x, "bad division; leaving a reminder");
  }

  //fixme: debate whether this should be here at all, as it does nothing but return ( a / b )
  /** @dev Integer division of two numbers truncating the quotient, reverts on division by zero */
  function div(uint a, uint b) internal pure returns (uint c) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
  }

}

// File: contracts/Validating.sol

contract Validating {

  modifier notZero(uint number) { require(number != 0, "invalid 0 value"); _; }
  modifier notEmpty(string text) { require(bytes(text).length != 0, "invalid empty string"); _; }
  modifier validAddress(address value) { require(value != address(0x0), "invalid address");  _; }

}

// File: contracts/HasOwners.sol

contract HasOwners is Validating {

  mapping(address => bool) public isOwner;
  address[] private owners;

  constructor(address[] _owners) public {
    for (uint i = 0; i < _owners.length; i++) _addOwner_(_owners[i]);
    owners = _owners;
  }

  modifier onlyOwner { require(isOwner[msg.sender], "invalid sender; must be owner"); _; }

  function getOwners() public view returns (address[]) { return owners; }

  function addOwner(address owner) external onlyOwner {  _addOwner_(owner); }

  function _addOwner_(address owner) validAddress(owner) private {
    if (!isOwner[owner]) {
      isOwner[owner] = true;
      owners.push(owner);
      emit OwnerAdded(owner);
    }
  }
  event OwnerAdded(address indexed owner);

  function removeOwner(address owner) external onlyOwner {
    if (isOwner[owner]) {
      require(owners.length > 1, "removing the last owner is not allowed");
      isOwner[owner] = false;
      for (uint i = 0; i < owners.length - 1; i++) {
        if (owners[i] == owner) {
          owners[i] = owners[owners.length - 1]; // replace map last entry
          delete owners[owners.length - 1];
          break;
        }
      }
      owners.length -= 1;
      emit OwnerRemoved(owner);
    }
  }
  event OwnerRemoved(address indexed owner);
}

// File: contracts/external/StandardToken.sol

/*
  You should inherit from StandardToken or, for a token like you would want to
  deploy in something like Mist, see HumanStandardToken.sol.
  (This implements ONLY the standard functions and NOTHING else.
  If you deploy this, you won"t have anything useful.)

  Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
*/
contract StandardToken is Token {

  function transfer(address _to, uint _value) public returns (bool success) {
    //Default assumes totalSupply can"t be over max (2^256 - 1).
    //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
    //Replace the if map this one instead.
    //require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
    require(balances[msg.sender] >= _value, "sender has insufficient token balance");
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    //same as above. Replace this line map the following if you want to protect against wrapping uints.
    //require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
    require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value,
      "either from address has insufficient token balance, or insufficient amount was approved for sender");
    balances[_to] += _value;
    balances[_from] -= _value;
    allowed[_from][msg.sender] -= _value;
    emit Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint remaining) {
    return allowed[_owner][_spender];
  }

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;
}

// File: contracts/staking/Fee.sol

/**
  * @title FEE is an ERC20 token used to pay for trading on the exchange.
  * For deeper rational read https://leverj.io/whitepaper.pdf.
  * FEE tokens do not have limit. A new token can be generated by owner.
  */
contract Fee is HasOwners, StandardToken {

  /* This notifies clients about the amount burnt */
  event Burn(address indexed from, uint value);

  string public name;                   //fancy name: eg Simon Bucks
  uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
  string public symbol;                 //An identifier: eg SBX
  string public version = "F0.2";       //human 0.1 standard. Just an arbitrary versioning scheme.
  address public minter;

  modifier onlyMinter { require(msg.sender == minter, "invalid sender; must be minter"); _; }

  constructor(address[] owners, string tokenName, uint8 decimalUnits, string tokenSymbol)
    HasOwners(owners)
    public notEmpty(tokenName) notEmpty(tokenSymbol)
  {
    name = tokenName;
    decimals = decimalUnits;
    symbol = tokenSymbol;
  }

  function setMinter(address _minter) external onlyOwner validAddress(_minter) {
    minter = _minter;
  }

  /// @notice To eliminate tokens and adjust the price of the FEE tokens
  /// @param quantity Amount of tokens to delete
  function burnTokens(uint quantity) public notZero(quantity) {
    require(balances[msg.sender] >= quantity, "fixme: need a message");
    balances[msg.sender] = Math.minus(balances[msg.sender], quantity);
    totalSupply = Math.minus(totalSupply, quantity);
    emit Burn(msg.sender, quantity);
  }

  /// @notice To send tokens to another user. New FEE tokens are generated when
  /// doing this process by the minter
  /// @param to The receiver of the tokens
  /// @param quantity The amount o
  function sendTokens(address to, uint quantity) public onlyMinter validAddress(to) notZero(quantity) {
    balances[to] = Math.plus(balances[to], quantity);
    totalSupply = Math.plus(totalSupply, quantity);
    emit Transfer(0x0, to, quantity);
  }
}

// File: contracts/staking/Stake.sol

//interface Custodian {
//  function withdraw(address[] addresses, uint[] uints, bytes signature, bytes proof, bytes32 root) external;
//  function exitOnHalt(address[] addresses, uint[] uints, bytes signature, bytes proof, bytes32 root) external;
//}

contract Stake is HasOwners {
  using Math for uint;

  string public version;
  uint public weiPerFEE; // Wei for each Fee token
  Token public LEV;
  Fee public FEE;
  address public wallet;
  address public operator;
  uint public intervalSize;

  bool public halted;
  uint public FEE2Distribute;
  uint public totalStakedLEV;
  uint public latest = 1;

  mapping (address => UserStake) public stakes;
  mapping (uint => Interval) public intervals;


  // events
  event Staked(address indexed user, uint levs, uint startBlock, uint endBlock, uint intervalId);
  event Restaked(address indexed user, uint levs, uint startBlock, uint endBlock, uint intervalId);
  event Redeemed(address indexed user, uint levs, uint feeEarned, uint startBlock, uint endBlock, uint intervalId);
  event FeeCalculated(uint feeCalculated, uint feeReceived, uint weiReceived, uint startBlock, uint endBlock, uint intervalId);
  event NewInterval(uint start, uint end, uint intervalId);
  event Halted(uint block, uint intervalId);

  //account
  struct UserStake {uint intervalId; uint quantity; uint worth;}
  // per staking interval data
  struct Interval {uint worth; uint generatedFEE; uint start; uint end;}


  constructor(address[] _owners, address _operator, address _wallet, uint _weiPerFee, address _levToken, address _feeToken, uint _intervalSize, address registry, address apiKey, bytes32 userAgreement, string _version)
    HasOwners(_owners)
    public validAddress(_wallet) validAddress(_levToken) validAddress(_feeToken) notZero(_weiPerFee) notZero(_intervalSize)
  {
    wallet = _wallet;
    weiPerFEE = _weiPerFee;
    LEV = Token(_levToken);
    FEE = Fee(_feeToken);
    intervalSize = _intervalSize;
    intervals[latest].start = block.number;
    intervals[latest].end = intervals[latest].start + intervalSize;
    version = _version;
    operator = _operator;
    Registry(registry).registerWithUserAgreement(apiKey, userAgreement);
  }

  modifier notHalted { require(!halted, "exchange is halted"); _; }
  modifier onlyOperator { require(msg.sender == operator, "Only operator is allowed to perform this action"); _; }

  function() external payable {}

  function setWallet(address _wallet) external validAddress(_wallet) onlyOwner {
    ensureInterval();
    wallet = _wallet;
  }

  function setIntervalSize(uint _intervalSize) external notZero(_intervalSize) onlyOwner {
    ensureInterval();
    intervalSize = _intervalSize;
  }

  /// @notice establish an interval if none exist yet
  function ensureInterval() public notHalted {
    if (intervals[latest].end > block.number) return;

    Interval storage interval = intervals[latest];
    (uint feeEarned, uint ethEarned) = calculateIntervalEarning(interval.start, interval.end);
    interval.generatedFEE = feeEarned.plus(ethEarned.div(weiPerFEE));
    FEE2Distribute = FEE2Distribute.plus(interval.generatedFEE);
    if (ethEarned.div(weiPerFEE) > 0) FEE.sendTokens(this, ethEarned.div(weiPerFEE));
    emit FeeCalculated(interval.generatedFEE, feeEarned, ethEarned, interval.start, interval.end, latest);
    if (ethEarned > 0) wallet.transfer(ethEarned);

    uint diff = (block.number - intervals[latest].end) % intervalSize;
    latest += 1;
    intervals[latest].start = intervals[latest - 1].end;
    intervals[latest].end = block.number - diff + intervalSize;
    emit NewInterval(intervals[latest].start, intervals[latest].end, latest);
  }

  function restake(int signedQuantity) private {
    UserStake storage stake = stakes[msg.sender];
    if (stake.intervalId == latest || stake.intervalId == 0) return;
    uint lev = stake.quantity;
    uint withdrawLev = signedQuantity >= 0 ?
      0 :
      uint(signedQuantity * - 1) >= stake.quantity ?
        stake.quantity :
        uint(signedQuantity * - 1);
    redeem(withdrawLev);
    stake.quantity = lev.minus(withdrawLev);
    if (stake.quantity == 0) {
      delete stakes[msg.sender];
      return;
    }
    Interval storage interval = intervals[latest];
    stake.intervalId = latest;
    stake.worth = stake.quantity.times(interval.end.minus(interval.start));
    interval.worth = interval.worth.plus(stake.worth);
    emit Restaked(msg.sender, stake.quantity, interval.start, interval.end, latest);
  }

  function stake(int signedQuantity) external notHalted {
    ensureInterval();
    restake(signedQuantity);
    if (signedQuantity <= 0) return;
    stakeInCurrentPeriod(uint(signedQuantity));
  }

  function stakeInCurrentPeriod(uint quantity) private {
    require(LEV.allowance(msg.sender, this) >= quantity, "Approve LEV tokens first");
    Interval storage interval = intervals[latest];
    stakes[msg.sender].intervalId = latest;
    stakes[msg.sender].worth = stakes[msg.sender].worth.plus(quantity.times(intervals[latest].end.minus(block.number)));
    stakes[msg.sender].quantity = stakes[msg.sender].quantity.plus(quantity);
    interval.worth = interval.worth.plus(quantity.times(interval.end.minus(block.number)));
    require(LEV.transferFrom(msg.sender, this, quantity), "LEV token transfer was not successful");
    totalStakedLEV = totalStakedLEV.plus(quantity);
    emit Staked(msg.sender, quantity, interval.start, interval.end, latest);
  }

  function withdraw() external {
    if (!halted) ensureInterval();
    if (stakes[msg.sender].intervalId == 0 || stakes[msg.sender].intervalId == latest) return;
    redeem(stakes[msg.sender].quantity);
  }

  function halt() external notHalted onlyOwner {
    intervals[latest].end = block.number;
    ensureInterval();
    halted = true;
    emit Halted(block.number, latest - 1);
  }

  function transferToWalletAfterHalt() public onlyOwner {
    require(halted, "Stake is not halted yet.");
    uint feeEarned = FEE.balanceOf(this).minus(FEE2Distribute);
    uint ethEarned = address(this).balance;
    if (feeEarned > 0) FEE.transfer(wallet, feeEarned);
    if (ethEarned > 0) wallet.transfer(ethEarned);
  }

  function transferToken(address token) public validAddress(token) {
    if (token == address(FEE)) return;
    uint balance = Token(token).balanceOf(this);
    if (token == address(LEV)) balance = balance.minus(totalStakedLEV);
    if (balance > 0) Token(token).transfer(wallet, balance);
  }

  function redeem(uint howMuchLEV) private {
    uint intervalId = stakes[msg.sender].intervalId;
    Interval memory interval = intervals[intervalId];
    uint earnedFEE = stakes[msg.sender].worth.times(interval.generatedFEE).div(interval.worth);
    delete stakes[msg.sender];
    if (earnedFEE > 0) {
      FEE2Distribute = FEE2Distribute.minus(earnedFEE);
      require(FEE.transfer(msg.sender, earnedFEE), "Fee transfer to account failed");
    }
    if (howMuchLEV > 0) {
      totalStakedLEV = totalStakedLEV.minus(howMuchLEV);
      require(LEV.transfer(msg.sender, howMuchLEV), "Redeeming LEV token to account failed.");
    }
    emit Redeemed(msg.sender, howMuchLEV, earnedFEE, interval.start, interval.end, intervalId);
  }

  // public for testing purposes only. not intended to be called directly
  function calculateIntervalEarning(uint start, uint end) public view returns (uint earnedFEE, uint earnedETH) {
    earnedFEE = FEE.balanceOf(this).minus(FEE2Distribute);
    earnedETH = address(this).balance;
    earnedFEE = earnedFEE.times(end.minus(start)).div(block.number.minus(start));
    earnedETH = earnedETH.times(end.minus(start)).div(block.number.minus(start));
  }

  function registerApiKey(address registry, address apiKey, bytes32 userAgreement) public onlyOwner {
    Registry(registry).registerWithUserAgreement(apiKey, userAgreement);
  }

  function withdrawFromCustodian(address custodian, address[] addresses, uint[] uints, bytes signature, bytes proof, bytes32 root) public onlyOperator {
    Withdrawing(custodian).withdraw(addresses, uints, signature, proof, root);
  }

  function exitOnHaltFromCustodian(address custodian, address[] addresses, uint[] uints, bytes signature, bytes proof, bytes32 root) public onlyOperator {
    Withdrawing(custodian).exitOnHalt(addresses, uints, signature, proof, root);
  }
}