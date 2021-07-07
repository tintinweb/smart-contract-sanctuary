pragma solidity ^0.8.0;

import "./TransferHelper.sol";
import './VestingMathLibrary.sol';
import './FullMath.sol';

import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

interface IMigrator {
    function migrate(address token, uint256 sharesDeposited, uint256 sharesWithdrawn, uint256 startEmission, uint256 endEmission, uint256 lockID, address owner, address condition, uint256 amountInTokens, uint256 option) external returns (bool);
}

interface IUnicryptAdmin {
    function userIsAdmin(address _user) external view returns (bool);
}

interface ITokenBlacklist {
    function checkToken(address _token) external view;
}

contract TokenVesting is Ownable, ReentrancyGuard {
  using EnumerableSet for EnumerableSet.AddressSet;

  struct UserInfo {
    EnumerableSet.AddressSet lockedTokens; // records all token addresses the user has locked
    mapping(address => uint256[]) locksForToken; // map erc20 address to lockId for that token
  }

  struct TokenLock {
    address tokenAddress; // The token address
    uint256 sharesDeposited; // the total amount of shares deposited
    uint256 sharesWithdrawn; // amount of shares withdrawn
    uint256 startEmission; // date token emission begins
    uint256 endEmission; // the date the tokens can be withdrawn
    uint256 lockID; // lock id per token lock
    address owner; // the owner who can edit or withdraw the lock
    address condition; // address(0) = no condition, otherwise the condition contract must implement IUnlockCondition
  }
  
  struct LockParams {
    address payable owner; // the user who can withdraw tokens once the lock expires.
    uint256 amount; // amount of tokens to lock
    uint256 startEmission; // 0 if lock type 1, else a unix timestamp
    uint256 endEmission; // the unlock date as a unix timestamp (in seconds)
    address condition; // address(0) = no condition, otherwise the condition must implement IUnlockCondition
  }

  EnumerableSet.AddressSet private TOKENS; // list of all unique tokens that have a lock
  mapping(uint256 => TokenLock) public LOCKS; // map lockID nonce to the lock
  uint256 public NONCE = 0; // incremental lock nonce counter, this is the unique ID for the next lock
  uint256 public MINIMUM_DEPOSIT = 100; // minimum divisibility per lock at time of locking
  
  mapping(address => uint256[]) private TOKEN_LOCKS; // map token address to array of lockIDs for that token
  mapping(address => UserInfo) private USERS;

  mapping(address => uint) public SHARES; // map token to number of shares per token, shares allow rebasing and deflationary tokens to compute correctly
  
  EnumerableSet.AddressSet private ZERO_FEE_WHITELIST; // Tokens that have been whitelisted to bypass all fees
  EnumerableSet.AddressSet private TOKEN_WHITELISTERS; // whitelisting contracts and users who can enable no fee for tokens.
  
  struct FeeStruct {
    uint256 tokenFee;
    uint256 freeLockingFee;
    address payable feeAddress;
    address freeLockingToken; // if this is address(0) then it is the gas token of the network (e.g ETH, BNB, Matic)
  }
  
  FeeStruct public FEES;
  
  IUnicryptAdmin UNCX_ADMINS;
  IMigrator public MIGRATOR;
  ITokenBlacklist public BLACKLIST; // prevent AMM tokens with a blacklisting contract

  event onLock(uint256 lockID, address token, address owner, uint256 amountInTokens, uint256 startEmission, uint256 endEmission);
  event onWithdraw(address lpToken, uint256 amountInTokens);
  event onRelock(uint256 lockID, uint256 unlockDate);
  event onTransferLock(uint256 lockIDFrom, uint256 lockIDto, address oldOwner, address newOwner);
  event onSplitLock(uint256 fromLockID, uint256 toLockID, uint256 amountInTokens);
  event onMigrate(uint256 lockID, uint256 amountInTokens);

  constructor (IUnicryptAdmin _uncxAdmins) {
    UNCX_ADMINS = _uncxAdmins;
    FEES.tokenFee = 35;
    FEES.feeAddress = payable(0xdE2E64AEbcA3b4165d0A7A954dC75Ff9d5b4B06e);
    FEES.freeLockingFee = 10e18;
  }
  
  function setMigrator(IMigrator _migrator) external onlyOwner {
    MIGRATOR = _migrator;
  }
  
  function setBlacklistContract(ITokenBlacklist _contract) external onlyOwner {
    BLACKLIST = _contract;
  }
  
  function setFees(uint256 _tokenFee, uint256 _freeLockingFee, address payable _feeAddress, address _freeLockingToken) external onlyOwner {
    FEES.tokenFee = _tokenFee;
    FEES.freeLockingFee = _freeLockingFee;
    FEES.feeAddress = _feeAddress;
    FEES.freeLockingToken = _freeLockingToken;
  }
  
  /**
   * @notice whitelisted accounts and contracts who can call the editZeroFeeWhitelist function
   */
  function adminSetWhitelister(address _user, bool _add) external onlyOwner {
    if (_add) {
      TOKEN_WHITELISTERS.add(_user);
    } else {
      TOKEN_WHITELISTERS.remove(_user);
    }
  }
  
  // Pay a once off fee to have free use of the lockers for the token
  function payForFreeTokenLocks (address _token) external payable {
      require(!ZERO_FEE_WHITELIST.contains(_token), 'PAID');
      // charge Fee
      if (FEES.freeLockingToken == address(0)) {
          require(msg.value == FEES.freeLockingFee, 'FEE NOT MET');
          FEES.feeAddress.transfer(FEES.freeLockingFee);
      } else {
          TransferHelper.safeTransferFrom(address(FEES.freeLockingToken), address(msg.sender), FEES.feeAddress, FEES.freeLockingFee);
      }
      ZERO_FEE_WHITELIST.add(_token);
  }
  
  // Callable by UNCX_ADMINS or whitelisted contracts (such as presale contracts)
  function editZeroFeeWhitelist (address _token, bool _add) external {
    require(UNCX_ADMINS.userIsAdmin(msg.sender) || TOKEN_WHITELISTERS.contains(msg.sender), 'ADMIN');
    if (_add) {
      ZERO_FEE_WHITELIST.add(_token);
    } else {
      ZERO_FEE_WHITELIST.remove(_token);
    }
  }

  /**
   * @notice Creates one or multiple locks for the specified token
   * @param _token the erc20 token address
   * @param _lock_params an array of locks with format: [LockParams[owner, amount, startEmission, endEmission, condition]]
   * owner: user or contract who can withdraw the tokens
   * amount: must be >= 100 units
   * startEmission = 0 : LockType 1
   * startEmission != 0 : LockType 2 (linear scaling lock)
   * use address(0) for no premature unlocking condition
   * Fails if startEmission is not less than EndEmission
   * Fails is amount < 100
   */
  function lock (address _token, LockParams[] calldata _lock_params) external nonReentrant {
    require(_lock_params.length > 0, 'NO PARAMS');
    if (address(BLACKLIST) != address(0)) {
        BLACKLIST.checkToken(_token);
    }
    uint256 totalAmount = 0;
    for (uint256 i = 0; i < _lock_params.length; i++) {
        totalAmount += _lock_params[i].amount;
    }

    uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
    TransferHelper.safeTransferFrom(_token, address(msg.sender), address(this), totalAmount);
    uint256 amountIn = IERC20(_token).balanceOf(address(this)) - balanceBefore;

    // Fees
    if (!ZERO_FEE_WHITELIST.contains(_token)) {
      uint256 lockFee = FullMath.mulDiv(amountIn, FEES.tokenFee, 10000);
      TransferHelper.safeTransfer(_token, FEES.feeAddress, lockFee);
      amountIn -= lockFee;
    }
    
    uint256 shares = 0;
    for (uint256 i = 0; i < _lock_params.length; i++) {
        LockParams memory lock_param = _lock_params[i];
        require(lock_param.startEmission < lock_param.endEmission, 'PERIOD');
        require(lock_param.endEmission < 1e10, 'TIMESTAMP INVALID'); // prevents errors when timestamp entered in milliseconds
        require(lock_param.amount >= MINIMUM_DEPOSIT, 'MIN DEPOSIT');
        uint256 amountInTokens = FullMath.mulDiv(lock_param.amount, amountIn, totalAmount);

        if (SHARES[_token] == 0) {
          shares = amountInTokens;
        } else {
          shares = FullMath.mulDiv(amountInTokens, SHARES[_token], balanceBefore == 0 ? 1 : balanceBefore);
        }
        require(shares > 0, 'SHARES');
        SHARES[_token] += shares;
        balanceBefore += amountInTokens;

        TokenLock memory token_lock;
        token_lock.tokenAddress = _token;
        token_lock.sharesDeposited = shares;
        token_lock.startEmission = lock_param.startEmission;
        token_lock.endEmission = lock_param.endEmission;
        token_lock.lockID = NONCE;
        token_lock.owner = lock_param.owner;
        if (lock_param.condition != address(0)) {
            // if the condition contract does not implement the interface and return a bool
            // the below line will fail and revert the tx as the conditional contract is invalid
            IUnlockCondition(lock_param.condition).unlockTokens();
            token_lock.condition = lock_param.condition;
        }
    
        // record the lock globally
        LOCKS[NONCE] = token_lock;
        TOKENS.add(_token);
        TOKEN_LOCKS[_token].push(NONCE);
    
        // record the lock for the user
        UserInfo storage user = USERS[lock_param.owner];
        user.lockedTokens.add(_token);
        user.locksForToken[_token].push(NONCE);
        
        NONCE ++;
        emit onLock(token_lock.lockID, _token, token_lock.owner, amountInTokens, token_lock.startEmission, token_lock.endEmission);
    }
  }
  
   /**
   * @notice withdraw a specified amount from a lock. _amount is the ideal amount to be withdrawn.
   * however, this amount might be slightly different in rebasing tokens due to the conversion to shares,
   * then back into an amount
   * @param _lockID the lockID of the lock to be withdrawn
   * @param _amount amount of tokens to withdraw
   */
  function withdraw (uint256 _lockID, uint256 _amount) external nonReentrant {
    TokenLock storage userLock = LOCKS[_lockID];
    require(userLock.owner == msg.sender, 'OWNER');
    // convert _amount to its representation in shares
    uint256 balance = IERC20(userLock.tokenAddress).balanceOf(address(this));
    uint256 shareDebit = FullMath.mulDiv(SHARES[userLock.tokenAddress], _amount, balance);
    // round _amount up to the nearest whole share if the amount of tokens specified does not translate to
    // at least 1 share.
    if (shareDebit == 0 && _amount > 0) {
      shareDebit ++;
    }
    require(shareDebit > 0, 'ZERO WITHDRAWL');
    uint256 withdrawableShares = getWithdrawableShares(userLock.lockID);
    // dust clearance block, as mulDiv rounds down leaving one share stuck, clear all shares for dust amounts
    if (shareDebit + 1 == withdrawableShares) {
      if (FullMath.mulDiv(SHARES[userLock.tokenAddress], balance / SHARES[userLock.tokenAddress], balance) == 0){
        shareDebit++;
      }
    }
    require(withdrawableShares >= shareDebit, 'AMOUNT');
    userLock.sharesWithdrawn += shareDebit;

    // now convert shares to the actual _amount it represents, this may differ slightly from the 
    // _amount supplied in this methods arguments.
    uint256 amountInTokens = FullMath.mulDiv(shareDebit, balance, SHARES[userLock.tokenAddress]);
    SHARES[userLock.tokenAddress] -= shareDebit;
    
    TransferHelper.safeTransfer(userLock.tokenAddress, msg.sender, amountInTokens);
    emit onWithdraw(userLock.tokenAddress, amountInTokens);
  }
  
  /**
   * @notice extend a lock with a new unlock date, if lock is Type 2 it extends the emission end date
   */
  function relock (uint256 _lockID, uint256 _unlock_date) external nonReentrant {
    require(_unlock_date < 1e10, 'TIME'); // prevents errors when timestamp entered in milliseconds
    TokenLock storage userLock = LOCKS[_lockID];
    require(userLock.owner == msg.sender, 'OWNER');
    require(userLock.endEmission < _unlock_date, 'END');
    // percent fee
    if (!ZERO_FEE_WHITELIST.contains(userLock.tokenAddress)) {
        uint256 remainingShares = userLock.sharesDeposited - userLock.sharesWithdrawn;
        uint256 feeInShares = FullMath.mulDiv(remainingShares, FEES.tokenFee, 10000);
        uint256 balance = IERC20(userLock.tokenAddress).balanceOf(address(this));
        uint256 feeInTokens = FullMath.mulDiv(feeInShares, balance, SHARES[userLock.tokenAddress] == 0 ? 1 : SHARES[userLock.tokenAddress]);
        TransferHelper.safeTransfer(userLock.tokenAddress, FEES.feeAddress, feeInTokens);
        userLock.sharesWithdrawn += feeInShares;
        SHARES[userLock.tokenAddress] -= feeInShares;
    }
    userLock.endEmission = _unlock_date;
    emit onRelock(_lockID, _unlock_date);
  }
  
  /**
   * @notice increase the amount of tokens per a specific lock, this is preferable to creating a new lock
   * Its possible to increase someone elses lock here it does not need to be your own, useful for contracts
   */
  function incrementLock (uint256 _lockID, uint256 _amount) external nonReentrant {
    TokenLock storage userLock = LOCKS[_lockID];
    require(_amount >= MINIMUM_DEPOSIT, 'MIN DEPOSIT');
    
    uint256 balanceBefore = IERC20(userLock.tokenAddress).balanceOf(address(this));
    TransferHelper.safeTransferFrom(userLock.tokenAddress, address(msg.sender), address(this), _amount);
    uint256 amountInTokens = IERC20(userLock.tokenAddress).balanceOf(address(this)) - balanceBefore;

    // percent fee
    if (!ZERO_FEE_WHITELIST.contains(userLock.tokenAddress)) {
        uint256 lockFee = FullMath.mulDiv(amountInTokens, FEES.tokenFee, 10000);
        TransferHelper.safeTransfer(userLock.tokenAddress, FEES.feeAddress, lockFee);
        amountInTokens -= lockFee;
    }
    uint256 shares;
    if (SHARES[userLock.tokenAddress] == 0) {
      shares = amountInTokens;
    } else {
      shares = FullMath.mulDiv(amountInTokens, SHARES[userLock.tokenAddress], balanceBefore);
    }
    require(shares > 0, 'SHARES');
    SHARES[userLock.tokenAddress] += shares;
    userLock.sharesDeposited += shares;
    emit onLock(userLock.lockID, userLock.tokenAddress, userLock.owner, amountInTokens, userLock.startEmission, userLock.endEmission);
  }
  
  /**
   * @notice transfer a lock to a new owner, e.g. presale project -> project owner
   * Please be aware this generates a new lock, and nulls the old lock, so a new ID is assigned to the new lock.
   */
  function transferLockOwnership (uint256 _lockID, address payable _newOwner) external nonReentrant {
    require(msg.sender != _newOwner, 'SELF');
    TokenLock storage transferredLock = LOCKS[_lockID];
    require(transferredLock.owner == msg.sender, 'OWNER');
    
    TokenLock memory token_lock;
    token_lock.tokenAddress = transferredLock.tokenAddress;
    token_lock.sharesDeposited = transferredLock.sharesDeposited;
    token_lock.sharesWithdrawn = transferredLock.sharesWithdrawn;
    token_lock.startEmission = transferredLock.startEmission;
    token_lock.endEmission = transferredLock.endEmission;
    token_lock.lockID = NONCE;
    token_lock.owner = _newOwner;
    token_lock.condition = transferredLock.condition;
    
    // record the lock globally
    LOCKS[NONCE] = token_lock;
    TOKEN_LOCKS[transferredLock.tokenAddress].push(NONCE);
    
    // record the lock for the new owner 
    UserInfo storage newOwner = USERS[_newOwner];
    newOwner.lockedTokens.add(transferredLock.tokenAddress);
    newOwner.locksForToken[transferredLock.tokenAddress].push(token_lock.lockID);
    NONCE ++;
    
    // zero the lock from the old owner
    transferredLock.sharesWithdrawn = transferredLock.sharesDeposited;
    emit onTransferLock(_lockID, token_lock.lockID, msg.sender, _newOwner);
  }
  
  /**
   * @notice split a lock into two seperate locks, useful when a lock is about to expire and youd like to relock a portion
   * and withdraw a smaller portion
   * Only works on lock type 1, this feature does not work with lock type 2
   * @param _amount the amount in tokens
   */
  function splitLock (uint256 _lockID, uint256 _amount) external nonReentrant {
    require(_amount > 0, 'ZERO AMOUNT');
    TokenLock storage userLock = LOCKS[_lockID];
    require(userLock.owner == msg.sender, 'OWNER');
    require(userLock.startEmission == 0, 'LOCK TYPE 2');

    // convert _amount to its representation in shares
    uint256 balance = IERC20(userLock.tokenAddress).balanceOf(address(this));
    uint256 amountInShares = FullMath.mulDiv(SHARES[userLock.tokenAddress], _amount, balance);

    require(userLock.sharesWithdrawn + amountInShares <= userLock.sharesDeposited);
    
    TokenLock memory token_lock;
    token_lock.tokenAddress = userLock.tokenAddress;
    token_lock.sharesDeposited = amountInShares;
    token_lock.endEmission = userLock.endEmission;
    token_lock.lockID = NONCE;
    token_lock.owner = msg.sender;
    token_lock.condition = userLock.condition;
    
    // debit previous lock
    userLock.sharesWithdrawn += amountInShares;
    
    // record the new lock globally
    LOCKS[NONCE] = token_lock;
    TOKEN_LOCKS[userLock.tokenAddress].push(NONCE);
    
    // record the new lock for the owner 
    USERS[msg.sender].locksForToken[userLock.tokenAddress].push(token_lock.lockID);
    NONCE ++;
    emit onSplitLock(_lockID, token_lock.lockID, _amount);
  }
  
  /**
   * @notice migrates to the next locker version, only callable by lock owners
   */
  function migrate (uint256 _lockID, uint256 _option) external nonReentrant {
    require(address(MIGRATOR) != address(0), "NOT SET");
    TokenLock storage userLock = LOCKS[_lockID];
    require(userLock.owner == msg.sender, 'OWNER');
    uint256 sharesAvailable = userLock.sharesDeposited - userLock.sharesWithdrawn;
    require(sharesAvailable > 0, 'AMOUNT');

    uint256 balance = IERC20(userLock.tokenAddress).balanceOf(address(this));
    uint256 amountInTokens = FullMath.mulDiv(sharesAvailable, balance, SHARES[userLock.tokenAddress]);
    
    TransferHelper.safeApprove(userLock.tokenAddress, address(MIGRATOR), amountInTokens);
    MIGRATOR.migrate(userLock.tokenAddress, userLock.sharesDeposited, userLock.sharesWithdrawn, userLock.startEmission,
    userLock.endEmission, userLock.lockID, userLock.owner, userLock.condition, amountInTokens, _option);
    
    userLock.sharesWithdrawn = userLock.sharesDeposited;
    SHARES[userLock.tokenAddress] -= sharesAvailable;
    emit onMigrate(_lockID, amountInTokens);
  }
  
  /**
   * @notice premature unlock conditions can be malicous (prevent withdrawls by failing to evalaute or return non bools)
   * or not give community enough insurance tokens will remain locked until the end date, in such a case, it can be revoked
   */
  function revokeCondition (uint256 _lockID) external nonReentrant {
    TokenLock storage userLock = LOCKS[_lockID];
    require(userLock.owner == msg.sender, 'OWNER');
    require(userLock.condition != address(0)); // already set to address(0)
    userLock.condition = address(0);
  }
  
  // test a condition on front end, added here for convenience in UI, returns unlockTokens() bool, or fails
  function testCondition (address condition) external view returns (bool) {
      return (IUnlockCondition(condition).unlockTokens());
  }
  
  // returns withdrawable share amount from the lock, taking into consideration start and end emission
  function getWithdrawableShares (uint256 _lockID) public view returns (uint256) {
    TokenLock storage userLock = LOCKS[_lockID];
    uint8 lockType = userLock.startEmission == 0 ? 1 : 2;
    uint256 amount = lockType == 1 ? userLock.sharesDeposited - userLock.sharesWithdrawn : userLock.sharesDeposited;
    uint256 withdrawable;
    withdrawable = VestingMathLibrary.getWithdrawableAmount (
      userLock.startEmission, 
      userLock.endEmission, 
      amount, 
      block.timestamp, 
      userLock.condition
    );
    if (lockType == 2) {
      withdrawable -= userLock.sharesWithdrawn;
    }
    return withdrawable;
  }
  
  // convenience function for UI, converts shares to the current amount in tokens
  function getWithdrawableTokens (uint256 _lockID) external view returns (uint256) {
    TokenLock storage userLock = LOCKS[_lockID];
    uint256 withdrawableShares = getWithdrawableShares(userLock.lockID);
    uint256 balance = IERC20(userLock.tokenAddress).balanceOf(address(this));
    uint256 amountTokens = FullMath.mulDiv(withdrawableShares, balance, SHARES[userLock.tokenAddress] == 0 ? 1 : SHARES[userLock.tokenAddress]);
    return amountTokens;
  }

  // For UI use
  function convertSharesToTokens (address _token, uint256 _shares) external view returns (uint256) {
    uint256 balance = IERC20(_token).balanceOf(address(this));
    return FullMath.mulDiv(_shares, balance, SHARES[_token]);
  }

  function convertTokensToShares (address _token, uint256 _tokens) external view returns (uint256) {
    uint256 balance = IERC20(_token).balanceOf(address(this));
    return FullMath.mulDiv(SHARES[_token], _tokens, balance);
  }
  
  // For use in UI, returns more useful lock Data than just querying LOCKS,
  // such as the real-time token amount representation of a locks shares
  function getLock (uint256 _lockID) external view returns (uint256, address, uint256, uint256, uint256, uint256, uint256, uint256, address, address) {
      TokenLock memory tokenLock = LOCKS[_lockID];

      uint256 balance = IERC20(tokenLock.tokenAddress).balanceOf(address(this));
      uint256 totalSharesOr1 = SHARES[tokenLock.tokenAddress] == 0 ? 1 : SHARES[tokenLock.tokenAddress];
      // tokens deposited and tokens withdrawn is provided for convenience in UI, with rebasing these amounts will change
      uint256 tokensDeposited = FullMath.mulDiv(tokenLock.sharesDeposited, balance, totalSharesOr1);
      uint256 tokensWithdrawn = FullMath.mulDiv(tokenLock.sharesWithdrawn, balance, totalSharesOr1);
      return (tokenLock.lockID, tokenLock.tokenAddress, tokensDeposited, tokensWithdrawn, tokenLock.sharesDeposited, tokenLock.sharesWithdrawn, tokenLock.startEmission, tokenLock.endEmission, 
      tokenLock.owner, tokenLock.condition);
  }
  
  function getNumLockedTokens () external view returns (uint256) {
    return TOKENS.length();
  }
  
  function getTokenAtIndex (uint256 _index) external view returns (address) {
    return TOKENS.at(_index);
  }
  
  function getTokenLocksLength (address _token) external view returns (uint256) {
    return TOKEN_LOCKS[_token].length;
  }
  
  function getTokenLockIDAtIndex (address _token, uint256 _index) external view returns (uint256) {
    return TOKEN_LOCKS[_token][_index];
  }
  
  // user functions
  function getUserLockedTokensLength (address _user) external view returns (uint256) {
    return USERS[_user].lockedTokens.length();
  }
  
  function getUserLockedTokenAtIndex (address _user, uint256 _index) external view returns (address) {
    return USERS[_user].lockedTokens.at(_index);
  }
  
  function getUserLocksForTokenLength (address _user, address _token) external view returns (uint256) {
    return USERS[_user].locksForToken[_token].length;
  }
  
  function getUserLockIDForTokenAtIndex (address _user, address _token, uint256 _index) external view returns (uint256) {
    return USERS[_user].locksForToken[_token][_index];
  }
  
  // no Fee Tokens
  function getZeroFeeTokensLength () external view returns (uint256) {
    return ZERO_FEE_WHITELIST.length();
  }
  
  function getZeroFeeTokenAtIndex (uint256 _index) external view returns (address) {
    return ZERO_FEE_WHITELIST.at(_index);
  }
  
  function tokenOnZeroFeeWhitelist (address _token) external view returns (bool) {
    return ZERO_FEE_WHITELIST.contains(_token);
  }
  
  // whitelist
  function getTokenWhitelisterLength () external view returns (uint256) {
    return TOKEN_WHITELISTERS.length();
  }
  
  function getTokenWhitelisterAtIndex (uint256 _index) external view returns (address) {
    return TOKEN_WHITELISTERS.at(_index);
  }
  
  function getTokenWhitelisterStatus (address _user) external view returns (bool) {
    return TOKEN_WHITELISTERS.contains(_user);
  }
}