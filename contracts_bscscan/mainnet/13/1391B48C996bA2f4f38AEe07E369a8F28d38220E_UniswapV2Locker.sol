// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED
// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.

// This contract locks Safemoonswap v1 liquidity tokens. Used to give investors peace of mind a token team has locked liquidity
// and that the liquidity tokens cannot be removed from the AMM until the specified unlock date has been reached. This is one of many
// important industry standards to ensure safety.

pragma solidity ^0.8.0;

import "./TransferHelper.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ICountryList.sol";

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IERCBurn {
    function burn(uint256 _amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IUniFactory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}

interface IMigrator {
    function migrate(address lpToken, uint256 amount, uint256 unlockDate, address owner, uint16 countryCode, uint256 option) external returns (bool);
}

contract UniswapV2Locker is Ownable, ReentrancyGuard {
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;

  IUniFactory public uniswapFactory;

  struct UserInfo {
    EnumerableSet.AddressSet lockedTokens; // records all unique tokens the user has locked
    mapping(address => EnumerableSet.UintSet) locksForToken; // map erc20 address to lock id list for that user / token.
  }

  struct TokenLock {
    address lpToken; // The LP token
    uint256 lockDate; // the date the token was locked
    uint256 amount; // the amount of tokens still locked (initialAmount minus withdrawls)
    uint256 initialAmount; // the initial lock amount
    uint256 unlockDate; // the date the token can be withdrawn
    uint256 lockID; // lockID nonce per uni pair
    address owner; // who can withdraw the lock
    uint16 countryCode; // the country code of the locker / business
  }

  mapping(address => UserInfo) private USERS; // Get lock user info

  mapping(uint256 => TokenLock) public LOCKS; // ALL locks are registered here in chronological lock id order.
  uint256 public NONCE = 0; // incremental lock nonce counter, this is the unique ID for the next lock

  EnumerableSet.AddressSet private lockedTokens; // a list of all unique locked liquidity tokens
  mapping(address => uint256[]) public TOKEN_LOCKS; // map univ2 pair to an array of all its lock ids
  
  struct FeeStruct {
    uint256 ethFee; // Small eth fee to prevent spam on the platform
    IERCBurn secondaryFeeToken; // UNCX or UNCL
    uint256 secondaryTokenFee; // optional, UNCX or UNCL
    uint256 secondaryTokenDiscount; // discount on liquidity fee for burning secondaryToken
    uint256 liquidityFee; // fee on univ2 liquidity tokens
    uint256 referralPercent; // fee for referrals
    IERCBurn referralToken; // token the refferer must hold to qualify as a referrer
    uint256 referralHold; // balance the referrer must hold to qualify as a referrer
    uint256 referralDiscount; // discount on flatrate fees for using a valid referral address
  }
    
  FeeStruct public gFees;
  EnumerableSet.AddressSet private feeWhitelist;
  
  address payable devaddr;
  
  IMigrator public migrator; // migration contract
  ICountryList public COUNTRY_LIST;

  event onNewLock(uint256 lockID, address lpToken, address owner, uint256 amount, uint256 lockDate, uint256 unlockDate, uint16 countryCode);
  event onRelock(uint256 lockID, address lpToken, address owner, uint256 amountRemainingInLock, uint256 liquidityFee, uint256 unlockDate);
  event onWithdraw(uint256 lockID, address lpToken, address owner, uint256 amountRemainingInLock, uint256 amountRemoved);
  event onIncrementLock(uint256 lockID, address lpToken, address owner, address payer, uint256 amountRemainingInLock, uint256 amountAdded, uint256 liquidityFee);
  event onSplitLock(uint256 lockID, address lpToken, address owner, uint256 amountRemainingInLock, uint256 amountRemoved);
  event onTransferLockOwnership(uint256 lockID, address lpToken, address oldOwner, address newOwner);
  event OnMigrate(uint256 lockID, address lpToken, address owner, uint256 amountRemainingInLock, uint256 amountMigrated, uint256 migrationOption);

  constructor(IUniFactory _uniswapFactory, ICountryList _countryList) {
    devaddr = payable(msg.sender);
    gFees.referralPercent = 250; // 25%
    gFees.ethFee = 1e18;
    gFees.secondaryTokenFee = 100e18;
    gFees.secondaryTokenDiscount = 200; // 20%
    gFees.liquidityFee = 10; // 1%
    gFees.referralHold = 10e18;
    gFees.referralDiscount = 100; // 10%
    uniswapFactory = _uniswapFactory;
    COUNTRY_LIST = _countryList;
  }
  
  function setDev(address payable _devaddr) public onlyOwner {
    devaddr = _devaddr;
  }
  
  /**
   * @notice set the migrator contract which allows locked lp tokens to be migrated to future AMM versions
   */
  function setMigrator(IMigrator _migrator) public onlyOwner {
    migrator = _migrator;
  }
  
  function setSecondaryFeeToken(address _secondaryFeeToken) public onlyOwner {
    gFees.secondaryFeeToken = IERCBurn(_secondaryFeeToken);
  }
  
  /**
   * @notice referrers need to hold the specified token and hold amount to be elegible for referral fees
   */
  function setReferralTokenAndHold(IERCBurn _referralToken, uint256 _hold) public onlyOwner {
    gFees.referralToken = _referralToken;
    gFees.referralHold = _hold;
  }
  
  function setFees(uint256 _referralPercent, uint256 _referralDiscount, uint256 _ethFee, uint256 _secondaryTokenFee, uint256 _secondaryTokenDiscount, uint256 _liquidityFee) public onlyOwner {
    gFees.referralPercent = _referralPercent;
    gFees.referralDiscount = _referralDiscount;
    gFees.ethFee = _ethFee;
    gFees.secondaryTokenFee = _secondaryTokenFee;
    gFees.secondaryTokenDiscount = _secondaryTokenDiscount;
    gFees.liquidityFee = _liquidityFee;
  }
  
  /**
   * @notice whitelisted accounts dont pay flatrate fees on locking
   */
  function whitelistFeeAccount(address _user, bool _add) public onlyOwner {
    if (_add) {
      feeWhitelist.add(_user);
    } else {
      feeWhitelist.remove(_user);
    }
  }

  /**
   * @notice Creates a new lock
   * @param _lpToken the univ2 token address
   * @param _amount amount of LP tokens to lock
   * @param _unlock_date the unix timestamp (in seconds) until unlock
   * @param _referral the referrer address if any or address(0) for none
   * @param _fee_in_eth fees can be paid in eth or in a secondary token such as UNCX with a discount on univ2 tokens
   * @param _withdrawer the user who can withdraw liquidity once the lock expires.
   * @param _countryCode the code of the country from which the lock user account / business is from
   */
  function lockLPToken (address _lpToken, uint256 _amount, uint256 _unlock_date, address payable _referral, bool _fee_in_eth, address payable _withdrawer, uint16 _countryCode) external payable nonReentrant {
    require(_unlock_date < 10000000000, 'TIMESTAMP INVALID'); // prevents errors when timestamp entered in milliseconds
    require(_amount > 0, 'INSUFFICIENT');
    require(COUNTRY_LIST.countryIsValid(_countryCode), 'COUNTRY');

    // TODO re-enable this check
    // ensure this pair is a univ2 pair by querying the factory
    IUniswapV2Pair lpair = IUniswapV2Pair(address(_lpToken));
    address factoryPairAddress = uniswapFactory.getPair(lpair.token0(), lpair.token1());
    require(factoryPairAddress == address(_lpToken), 'NOT UNIV2');

    TransferHelper.safeTransferFrom(_lpToken, address(msg.sender), address(this), _amount);
    
    if (_referral != address(0) && address(gFees.referralToken) != address(0)) {
      require(gFees.referralToken.balanceOf(_referral) >= gFees.referralHold, 'INADEQUATE BALANCE');
    }
    
    // flatrate fees
    if (!feeWhitelist.contains(msg.sender)) {
      if (_fee_in_eth) { // charge fee in eth
        uint256 ethFee = gFees.ethFee;
        if (_referral != address(0)) {
          ethFee = ethFee * (1000 - gFees.referralDiscount) / 1000;
        }
        require(msg.value == ethFee, 'FEE NOT MET');
        uint256 devFee = ethFee;
        if (ethFee != 0 && _referral != address(0)) { // referral fee
          uint256 referralFee = devFee * gFees.referralPercent / 1000;
          _referral.transfer(referralFee);
          devFee -= referralFee;
        }
        devaddr.transfer(devFee);
      } else { // charge fee in token
        uint256 burnFee = gFees.secondaryTokenFee;
        if (_referral != address(0)) {
          burnFee = burnFee * (1000 - gFees.referralDiscount) / 1000;
        }
        TransferHelper.safeTransferFrom(address(gFees.secondaryFeeToken), address(msg.sender), address(this), burnFee);
        if (gFees.referralPercent != 0 && _referral != address(0)) { // referral fee
          uint256 referralFee = burnFee * gFees.referralPercent / 1000;
          TransferHelper.safeApprove(address(gFees.secondaryFeeToken), _referral, referralFee);
          TransferHelper.safeTransfer(address(gFees.secondaryFeeToken), _referral, referralFee);
          burnFee -= referralFee;
        }
        gFees.secondaryFeeToken.burn(burnFee);
      }
    } else if (msg.value > 0){
      // refund eth if a whitelisted member sent it by mistake
      payable(msg.sender).transfer(msg.value);
    }
    
    // percent fee
    uint256 liquidityFee = _amount * gFees.liquidityFee / 1000;
    if (!_fee_in_eth && !feeWhitelist.contains(msg.sender)) { // fee discount for large lockers using secondary token
      liquidityFee = liquidityFee * (1000 - gFees.secondaryTokenDiscount) / 1000;
    }
    TransferHelper.safeTransfer(_lpToken, devaddr, liquidityFee);
    uint256 amountLocked = _amount - liquidityFee;

    TokenLock memory token_lock;
    token_lock.lpToken = _lpToken;
    token_lock.lockDate = block.timestamp;
    token_lock.amount = amountLocked;
    token_lock.initialAmount = amountLocked;
    token_lock.unlockDate = _unlock_date;
    token_lock.lockID = NONCE;
    token_lock.owner = _withdrawer;
    token_lock.countryCode = _countryCode;

    // record the lock for the univ2pair
    LOCKS[NONCE] = token_lock;
    lockedTokens.add(_lpToken);
    TOKEN_LOCKS[_lpToken].push(NONCE);

    // record the lock for the user
    UserInfo storage user = USERS[_withdrawer];
    user.lockedTokens.add(_lpToken);
    EnumerableSet.UintSet storage user_locks = user.locksForToken[_lpToken];
    user_locks.add(token_lock.lockID);

    NONCE ++;
    
    emit onNewLock(token_lock.lockID, _lpToken, _withdrawer, token_lock.amount, token_lock.lockDate, token_lock.unlockDate, token_lock.countryCode);
  }
  
  /**
   * @notice extend a lock with a new unlock date
   */
  function relock (uint256 _lockID, uint256 _unlock_date) external nonReentrant {
    require(_unlock_date < 10000000000, 'TIMESTAMP INVALID'); // prevents errors when timestamp entered in milliseconds
    TokenLock storage userLock = LOCKS[_lockID];
    require(userLock.owner == msg.sender, 'NOT OWNER');
    require(userLock.unlockDate < _unlock_date, 'UNLOCK BEFORE');
    
    uint256 liquidityFee = userLock.amount * gFees.liquidityFee / 1000;
    uint256 amountLocked = userLock.amount - liquidityFee;
    
    userLock.amount = amountLocked;
    userLock.unlockDate = _unlock_date;

    // send univ2 fee to dev address
    TransferHelper.safeTransfer(userLock.lpToken, devaddr, liquidityFee);
    emit onRelock(userLock.lockID, userLock.lpToken, msg.sender, userLock.amount, liquidityFee, userLock.unlockDate);
  }
  
  /**
   * @notice withdraw a specified amount from a lock
   */
  function withdraw (uint256 _lockID, uint256 _amount) external nonReentrant {
    require(_amount > 0, 'ZERO WITHDRAWL');
    TokenLock storage userLock = LOCKS[_lockID];
    require(userLock.owner == msg.sender, 'NOT OWNER');
    require(userLock.unlockDate < block.timestamp, 'NOT YET');
    userLock.amount -= _amount;

    // clean user storage
    if (userLock.amount == 0) {
      EnumerableSet.UintSet storage userLocks = USERS[msg.sender].locksForToken[userLock.lpToken];
      userLocks.remove(userLock.lockID);
      if (userLocks.length() == 0) {
        USERS[msg.sender].lockedTokens.remove(userLock.lpToken);
      }
    }
    
    TransferHelper.safeTransfer(userLock.lpToken, msg.sender, _amount);
    emit onWithdraw(userLock.lockID, userLock.lpToken, msg.sender, userLock.amount, _amount);
  }
  
  /**
   * @notice PLEASE BE AWARE THIS FUNCTION CONTAINS NO OWNER CHECK. ANYONE CAN LOCK THEIR LPS INTO SOMEONE ELSES
   * LOCK, BASICALLY GIVING THEM THEIR LP TOKENS.
   * The use here is a CONTRACT which is not the owner of a lock can increment locks periodically (for example with fees) on behalf of the owner.
   * This works well with taxing tokens.
   *
   * Increase the amount of tokens per a specific lock, this is preferable to creating a new lock,
   * less fees, and faster loading on our live block explorer.
   */
  function incrementLock (uint256 _lockID, uint256 _amount) external nonReentrant {
    require(_amount > 0, 'ZERO AMOUNT');
    TokenLock storage userLock = LOCKS[_lockID];
    // require(userLock.owner == msg.sender, 'NOT OWNER'); // disabled to allow contracts to lock on behalf of owners
    
    TransferHelper.safeTransferFrom(userLock.lpToken, address(msg.sender), address(this), _amount);
    
    // send univ2 fee to dev address
    uint256 liquidityFee = _amount * gFees.liquidityFee / 1000;
    TransferHelper.safeTransfer(userLock.lpToken, devaddr, liquidityFee);
    uint256 amountLocked = _amount - liquidityFee;
    
    userLock.amount += amountLocked;
    
    emit onIncrementLock(userLock.lockID, userLock.lpToken, userLock.owner, msg.sender, userLock.amount, amountLocked, liquidityFee);
  }
  
  /**
   * @notice split a lock into two seperate locks, useful when a lock is about to expire and youd like to relock a portion
   * and withdraw a smaller portion
   */
  function splitLock (uint256 _lockID, uint256 _amount) external payable nonReentrant {
    require(_amount > 0, 'ZERO AMOUNT');
    TokenLock storage userLock = LOCKS[_lockID];
    require(userLock.owner == msg.sender, 'NOT OWNER');
    
    require(msg.value == gFees.ethFee, 'FEE NOT MET');
    devaddr.transfer(gFees.ethFee);
    
    userLock.amount -= _amount;
    
    TokenLock memory token_lock;
    token_lock.lpToken = userLock.lpToken;
    token_lock.lockDate = userLock.lockDate;
    token_lock.amount = _amount;
    token_lock.initialAmount = _amount;
    token_lock.unlockDate = userLock.unlockDate;
    token_lock.lockID = NONCE;
    token_lock.owner = msg.sender;
    token_lock.countryCode = userLock.countryCode;

    // record the lock for the univ2pair
    TOKEN_LOCKS[userLock.lpToken].push(NONCE);
    LOCKS[NONCE] = token_lock;

    // record the lock for the user
    UserInfo storage user = USERS[msg.sender];
    EnumerableSet.UintSet storage user_locks = user.locksForToken[userLock.lpToken];
    user_locks.add(NONCE);
    NONCE ++;
    emit onSplitLock(userLock.lockID, userLock.lpToken, msg.sender, userLock.amount, _amount);
    emit onNewLock(token_lock.lockID, token_lock.lpToken, msg.sender, token_lock.amount, token_lock.lockDate, token_lock.unlockDate, token_lock.countryCode);
  }
  
  /**
   * @notice transfer a lock to a new owner, e.g. presale project -> project owner
   */
  function transferLockOwnership (uint256 _lockID, address payable _newOwner) external {
    require(msg.sender != _newOwner, 'OWNER');
    TokenLock storage transferredLock = LOCKS[_lockID];
    require(transferredLock.owner == msg.sender, 'NOT OWNER');
    
    // record the lock for the new Owner
    UserInfo storage user = USERS[_newOwner];
    user.lockedTokens.add(transferredLock.lpToken);
    EnumerableSet.UintSet storage user_locks = user.locksForToken[transferredLock.lpToken];
    user_locks.add(transferredLock.lockID);

    // remove the lock from the old owner
    EnumerableSet.UintSet storage userLocks = USERS[msg.sender].locksForToken[transferredLock.lpToken];
    userLocks.remove(transferredLock.lockID);
    if (userLocks.length() == 0) {
      USERS[msg.sender].lockedTokens.remove(transferredLock.lpToken);
    }
    
    transferredLock.owner = _newOwner;
    emit onTransferLockOwnership(_lockID, transferredLock.lpToken, msg.sender, _newOwner);
  }
  
  /**
   * @notice migrates liquidity to the next release of an AMM
   * @param _migration_option to be used as an AMM selector
   */
  function migrate (uint256 _lockID, uint256 _amount, uint256 _migration_option) external nonReentrant {
    require(address(migrator) != address(0), "NOT SET");
    require(_amount > 0, 'ZERO MIGRATION');
    
    TokenLock storage userLock = LOCKS[_lockID];
    require(userLock.owner == msg.sender, 'NOT OWNER');
    userLock.amount -= _amount;

    // clean user storage
    if (userLock.amount == 0) {
      EnumerableSet.UintSet storage userLocks = USERS[msg.sender].locksForToken[userLock.lpToken];
      userLocks.remove(userLock.lockID);
      if (userLocks.length() == 0) {
        USERS[msg.sender].lockedTokens.remove(userLock.lpToken);
      }
    }
    
    TransferHelper.safeApprove(userLock.lpToken, address(migrator), _amount);
    migrator.migrate(userLock.lpToken, _amount, userLock.unlockDate, msg.sender, userLock.countryCode, _migration_option);
    emit OnMigrate(_lockID, userLock.lpToken, msg.sender, userLock.amount, _amount, _migration_option);
  }
  
  function getNumLocksForToken (address _lpToken) external view returns (uint256) {
    return TOKEN_LOCKS[_lpToken].length;
  }
  
  function getNumLockedTokens () external view returns (uint256) {
    return lockedTokens.length();
  }
  
  function getLockedTokenAtIndex (uint256 _index) external view returns (address) {
    return lockedTokens.at(_index);
  }
  
  // user functions
  function getUserNumLockedTokens (address _user) external view returns (uint256) {
    UserInfo storage user = USERS[_user];
    return user.lockedTokens.length();
  }
  
  function getUserLockedTokenAtIndex (address _user, uint256 _index) external view returns (address) {
    UserInfo storage user = USERS[_user];
    return user.lockedTokens.at(_index);
  }
  
  function getUserNumLocksForToken (address _user, address _lpToken) external view returns (uint256) {
    UserInfo storage user = USERS[_user];
    return user.locksForToken[_lpToken].length();
  }
  
  function getUserLockForTokenAtIndex (address _user, address _lpToken, uint256 _index) external view 
  returns (TokenLock memory) {
    uint256 lockID = USERS[_user].locksForToken[_lpToken].at(_index);
    TokenLock storage tokenLock = LOCKS[lockID];
    return tokenLock;
  }
  
  // whitelist
  function getWhitelistedUsersLength () external view returns (uint256) {
    return feeWhitelist.length();
  }
  
  function getWhitelistedUserAtIndex (uint256 _index) external view returns (address) {
    return feeWhitelist.at(_index);
  }
  
  function getUserWhitelistStatus (address _user) external view returns (bool) {
    return feeWhitelist.contains(_user);
  }
}