pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
  * @dev Transfer token for a specified addresses
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract ERC20Burnable is ERC20 {

  /**
   * @dev Burns a specific amount of tokens.
   * @param value The amount of token to be burned.
   */
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param from address The address which you want to send tokens from
   * @param value uint256 The amount of token to be burned
   */
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
  }
}

// File: openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <<span class="__cf_email__" data-cfemail="afddcac2ccc0ef9d">[email&#160;protected]</span>π.com>, Eenae <<span class="__cf_email__" data-cfemail="e48588819c819da4898d9c869d908197ca8d8b">[email&#160;protected]</span>>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /// @dev counter to allow mutex lock with only one SSTORE operation
  uint256 private _guardCounter;

  constructor() internal {
    // The counter starts at one to prevent changing it from zero to a non-zero
    // value, which is a more expensive operation.
    _guardCounter = 1;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and make it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}

// File: contracts/LTOTokenSale.sol

/**
 * @title ERC20 LTO Network token
 * @dev see https://github.com/legalthings/tokensale
 */
contract LTOTokenSale is Ownable, ReentrancyGuard {

  using SafeMath for uint256;

  uint256 constant minimumAmount = 0.1 ether;     // Minimum amount of ether to transfer
  uint256 constant maximumCapAmount = 40 ether;  // Maximium amount of ether you can send with being caplisted
  uint256 constant ethDecimals = 1 ether;         // Amount used to divide ether with to calculate proportion
  uint256 constant ltoEthDiffDecimals = 10**10;   // Amount used to get the number of desired decimals, so  convert from 18 to 8
  uint256 constant bonusRateDivision = 10000;     // Amount used to divide the amount so the bonus can be calculated

  ERC20Burnable public token;
  address public receiverAddr;
  uint256 public totalSaleAmount;
  uint256 public totalWannaBuyAmount;
  uint256 public startTime;
  uint256 public bonusEndTime;
  uint256 public bonusPercentage;
  uint256 public bonusDecreaseRate;
  uint256 public endTime;
  uint256 public userWithdrawalStartTime;
  uint256 public clearStartTime;
  uint256 public withdrawn;
  uint256 public proportion = 1 ether;
  uint256 public globalAmount;
  uint256 public rate;
  uint256 public nrOfTransactions = 0;

  address public capListAddress;
  mapping (address => bool) public capFreeAddresses;

  struct PurchaserInfo {
    bool withdrew;
    bool recorded;
    uint256 received;     // Received ether
    uint256 accounted;    // Received ether + bonus
    uint256 unreceived;   // Ether stuck because failed withdraw
  }

  struct Purchase {
    uint256 received;     // Received ether
    uint256 used;         // Received ether multiplied by the proportion
    uint256 tokens;       // To receive tokens
  }
  mapping(address => PurchaserInfo) public purchaserMapping;
  address[] public purchaserList;

  modifier onlyOpenTime {
    require(isStarted());
    require(!isEnded());
    _;
  }

  modifier onlyAutoWithdrawalTime {
    require(isEnded());
    _;
  }

  modifier onlyUserWithdrawalTime {
    require(isUserWithdrawalTime());
    _;
  }

  modifier purchasersAllWithdrawn {
    require(withdrawn==purchaserList.length);
    _;
  }

  modifier onlyClearTime {
    require(isClearTime());
    _;
  }

  modifier onlyCapListAddress {
    require(msg.sender == capListAddress);
    _;
  }

  constructor(address _receiverAddr, ERC20Burnable _token, uint256 _totalSaleAmount, address _capListAddress) public {
    require(_receiverAddr != address(0));
    require(_token != address(0));
    require(_capListAddress != address(0));
    require(_totalSaleAmount > 0);

    receiverAddr = _receiverAddr;
    token = _token;
    totalSaleAmount = _totalSaleAmount;
    capListAddress = _capListAddress;
  }

  function isStarted() public view returns(bool) {
    return 0 < startTime && startTime <= now && endTime != 0;
  }

  function isEnded() public view returns(bool) {
    return 0 < endTime && now > endTime;
  }

  function isUserWithdrawalTime() public view returns(bool) {
    return 0 < userWithdrawalStartTime && now > userWithdrawalStartTime;
  }

  function isClearTime() public view returns(bool) {
    return 0 < clearStartTime && now > clearStartTime;
  }

  function isBonusPeriod() public view returns(bool) {
    return now >= startTime && now <= bonusEndTime;
  }

  function startSale(uint256 _startTime, uint256 _rate, uint256 duration,
    uint256 bonusDuration, uint256 _bonusPercentage, uint256 _bonusDecreaseRate,
    uint256 userWithdrawalDelaySec, uint256 clearDelaySec) public onlyOwner {
    require(endTime == 0);
    require(_startTime > 0);
    require(_rate > 0);
    require(duration > 0);
    require(token.balanceOf(this) == totalSaleAmount);

    rate = _rate;
    bonusPercentage = _bonusPercentage;
    bonusDecreaseRate = _bonusDecreaseRate;
    startTime = _startTime;
    bonusEndTime = startTime.add(bonusDuration);
    endTime = startTime.add(duration);
    userWithdrawalStartTime = endTime.add(userWithdrawalDelaySec);
    clearStartTime = endTime.add(clearDelaySec);
  }

  function getPurchaserCount() public view returns(uint256) {
    return purchaserList.length;
  }

  function _calcProportion() internal {
    assert(totalSaleAmount > 0);

    if (totalSaleAmount >= totalWannaBuyAmount) {
      proportion = ethDecimals;
      return;
    }
    proportion = totalSaleAmount.mul(ethDecimals).div(totalWannaBuyAmount);
  }

  function getSaleInfo(address purchaser) internal view returns (Purchase p) {
    PurchaserInfo storage pi = purchaserMapping[purchaser];
    return Purchase(
      pi.received,
      pi.received.mul(proportion).div(ethDecimals),
      pi.accounted.mul(proportion).div(ethDecimals).mul(rate).div(ltoEthDiffDecimals)
    );
  }

  function getPublicSaleInfo(address purchaser) public view returns (uint256, uint256, uint256) {
    Purchase memory purchase = getSaleInfo(purchaser);
    return (purchase.received, purchase.used, purchase.tokens);
  }

  function () payable public {
    buy();
  }

  function buy() payable public onlyOpenTime {
    require(msg.value >= minimumAmount);

    uint256 amount = msg.value;
    PurchaserInfo storage pi = purchaserMapping[msg.sender];
    if (!pi.recorded) {
      pi.recorded = true;
      purchaserList.push(msg.sender);
    }
    uint256 totalAmount = pi.received.add(amount);
    if (totalAmount > maximumCapAmount && !isCapFree(msg.sender)) {
      uint256 recap = totalAmount.sub(maximumCapAmount);
      amount = amount.sub(recap);
      if (amount <= 0) {
        revert();
      } else {
        msg.sender.transfer(recap);
      }
    }
    pi.received = pi.received.add(amount);

    globalAmount = globalAmount.add(amount);
    if (isBonusPeriod() && bonusDecreaseRate.mul(nrOfTransactions) < bonusPercentage) {
      uint256 percentage = bonusPercentage.sub(bonusDecreaseRate.mul(nrOfTransactions));
      uint256 bonus = amount.div(bonusRateDivision).mul(percentage);
      amount = amount.add(bonus);
    }
    pi.accounted = pi.accounted.add(amount);
    totalWannaBuyAmount = totalWannaBuyAmount.add(amount.mul(rate).div(ltoEthDiffDecimals));
    _calcProportion();
    nrOfTransactions = nrOfTransactions.add(1);
  }

  function _withdrawal(address purchaser) internal {
    require(purchaser != 0x0);
    PurchaserInfo storage pi = purchaserMapping[purchaser];
    if (pi.withdrew || !pi.recorded) {
      return;
    }
    pi.withdrew = true;
    withdrawn = withdrawn.add(1);
    Purchase memory purchase = getSaleInfo(purchaser);
    if (purchase.used > 0 && purchase.tokens > 0) {
      receiverAddr.transfer(purchase.used);
      require(token.transfer(purchaser, purchase.tokens));

      uint256 unused = purchase.received.sub(purchase.used);
      if (unused > 0) {
        if (!purchaser.send(unused)) {
          pi.unreceived = unused;
        }
      }
    } else {
      assert(false);
    }
    return;
  }

  function withdrawal() public onlyUserWithdrawalTime {
    _withdrawal(msg.sender);
  }

  function withdrawalFor(uint256 index, uint256 stop) public onlyAutoWithdrawalTime onlyOwner {
    for (; index < stop; index++) {
      _withdrawal(purchaserList[index]);
    }
  }

  function clear(uint256 tokenAmount, uint256 etherAmount) public purchasersAllWithdrawn onlyClearTime onlyOwner {
    if (tokenAmount > 0) {
      token.burn(tokenAmount);
    }
    if (etherAmount > 0) {
      receiverAddr.transfer(etherAmount);
    }
  }

  function withdrawFailed(address alternativeAddress) public onlyUserWithdrawalTime nonReentrant {
    require(alternativeAddress != 0x0);
    PurchaserInfo storage pi = purchaserMapping[msg.sender];

    require(pi.recorded);
    require(pi.unreceived > 0);
    if (alternativeAddress.send(pi.unreceived)) {
      pi.unreceived = 0;
    }
  }

  function addCapFreeAddress(address capFreeAddress) public onlyCapListAddress {
    require(capFreeAddress != address(0));

    capFreeAddresses[capFreeAddress] = true;
  }

  function removeCapFreeAddress(address capFreeAddress) public onlyCapListAddress {
    require(capFreeAddress != address(0));

    capFreeAddresses[capFreeAddress] = false;
  }

  function isCapFree(address capFreeAddress) internal view returns (bool) {
    return (capFreeAddresses[capFreeAddress]);
  }

  function currentBonus() public view returns(uint256) {
    return bonusPercentage.sub(bonusDecreaseRate.mul(nrOfTransactions));
  }
}