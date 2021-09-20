// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./TransferHelper.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IStaking {
  function distribute() external payable;
}

contract TokenVesting is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct UserInfo {
        EnumerableSet.AddressSet lockedTokens; // records all tokens the user has locked
        mapping(address => uint256[]) locksForToken; // map erc20 address to lock id for that token
    }

    struct TokenLock {
        uint256 lockDate; // the date the token was locked
        uint256 amount; // the amount of tokens still locked (initialAmount minus withdrawls)
        uint256 initialAmount; // the initial lock amount
        uint256 unlockDate; // the date the token can be withdrawn
        uint256 lockID; // lockID nonce per token
        address owner;
    }
  
    struct FeeStruct {
        uint256 stakingFee;
        uint256 liquidityFee;
    }

    mapping(address => UserInfo) private users;

    EnumerableSet.AddressSet private lockedTokens;
    mapping(address => TokenLock[]) public tokenLocks; //map token to all its locks
    
    FeeStruct public gFees;
    EnumerableSet.AddressSet private feeWhitelist;
    address payable devaddr;
    IStaking smartStaking;
    event onDeposit(address lpToken, address user, uint256 amount, uint256 lockDate, uint256 unlockDate);
    event onWithdraw(address lpToken, uint256 amount);

    constructor(IStaking _smartStaking) public {
        devaddr = msg.sender;
        gFees.stakingFee = 0;
        gFees.liquidityFee = 10; // 1%
        smartStaking = _smartStaking;
    }
    
    function setDev(address payable _devaddr) public onlyOwner {
        devaddr = _devaddr;
    }

    function setStaking(IStaking _newStaking) public onlyOwner {
        smartStaking = _newStaking;
    }
    
    function setFees(uint256 _stakingFee, uint256 _liquidityFee) public onlyOwner {
        gFees.stakingFee = _stakingFee;
        gFees.liquidityFee = _liquidityFee;
    }

    function whitelistFeeAccount(address _user, bool _add) public onlyOwner {
        if (_add) {
            feeWhitelist.add(_user);
        } else {
            feeWhitelist.remove(_user);
        }
    }

    /**
    * @notice Creates a new lock
    * @param _token the token address
    * @param _amount amount of tokens to lock
    * @param _unlock_date the unix timestamp (in seconds) until unlock
    * @param _withdrawer the user who can withdraw liquidity once the lock expires.
    * @param _no_of_vesting the number of time vesting will take place(_no_of_vesting = 2 means that half of the tokens will be available at the halfway through)
    */
    function lockToken (address _token, uint256 _amount, uint256 _unlock_date, address payable _withdrawer, uint256 _no_of_vesting) external payable nonReentrant {
        require(_unlock_date < 10000000000, 'TIMESTAMP INVALID'); // prevents errors when timestamp entered in milliseconds
        require(_amount > 0, 'INSUFFICIENT');
        require(_no_of_vesting <= 12, "Max number of vesting is 12");
        if (!feeWhitelist.contains(msg.sender)){
            uint256 stakingFee = gFees.stakingFee;
            require(msg.value == stakingFee, 'Fee not met!');
            smartStaking.distribute{value: stakingFee}();
        }

        TransferHelper.safeTransferFrom(_token, address(msg.sender), address(this), _amount);
        uint256 liquidityFee = _amount.mul(gFees.liquidityFee).div(1000);
        TransferHelper.safeTransfer(_token, devaddr, liquidityFee);

        uint256 amountLocked = _amount.sub(liquidityFee);
        uint256 amountPerVesting = amountLocked.div(_no_of_vesting);
        uint256 lockDate = block.timestamp;
        uint256 unlockPeriodPerVesting = (_unlock_date.sub(lockDate)).div(_no_of_vesting);
        for(uint256 i = 1; i <= _no_of_vesting; i++) {
            TokenLock memory token_lock;
            token_lock.lockDate = lockDate;
            token_lock.amount = amountPerVesting;
            token_lock.initialAmount = amountPerVesting;
            token_lock.unlockDate = lockDate.add(i.mul(unlockPeriodPerVesting));
            token_lock.lockID = tokenLocks[_token].length;
            token_lock.owner = _withdrawer;
            tokenLocks[_token].push(token_lock);

            UserInfo storage user = users[_withdrawer];
            user.lockedTokens.add(_token);
            uint256[] storage user_locks = user.locksForToken[_token];
            user_locks.push(token_lock.lockID);
        }

        // record the lock for the pair
        lockedTokens.add(_token);
        
        emit onDeposit(_token, msg.sender, _amount, lockDate, _unlock_date);
    }
    
    /**
    * @notice extend a lock with a new unlock date, _index and _lockID ensure the correct lock is changed
    * this prevents errors when a user performs multiple tx per block possibly with varying gas prices
    */
    function relock (address _token, uint256 _index, uint256 _lockID, uint256 _unlock_date) external nonReentrant {
        require(_unlock_date < 10000000000, 'TIMESTAMP INVALID'); // prevents errors when timestamp entered in milliseconds
        uint256 lockID = users[msg.sender].locksForToken[_token][_index];
        TokenLock storage userLock = tokenLocks[_token][lockID];
        require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
        require(userLock.unlockDate < _unlock_date, 'UNLOCK BEFORE');
        
        uint256 liquidityFee = userLock.amount.mul(gFees.liquidityFee).div(1000);
        uint256 amountLocked = userLock.amount.sub(liquidityFee);
        
        userLock.amount = amountLocked;
        userLock.unlockDate = _unlock_date;

        TransferHelper.safeTransfer(_token, devaddr, liquidityFee);
    }
    
    /**
    * @notice withdraw a specified amount from a lock. _index and _lockID ensure the correct lock is changed
    * this prevents errors when a user performs multiple tx per block possibly with varying gas prices
    */
    function withdraw (address _token, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
        require(_amount > 0, 'ZERO WITHDRAWAL');
        uint256 lockID = users[msg.sender].locksForToken[_token][_index];
        TokenLock storage userLock = tokenLocks[_token][lockID];
        require(lockID == _lockID && userLock.owner == msg.sender, 'Lock Mismatch!');
        require(userLock.unlockDate < block.timestamp, 'Cannot withdraw yet!');
        userLock.amount = userLock.amount.sub(_amount);
        
        if (userLock.amount == 0) {
            uint256[] storage userLocks = users[msg.sender].locksForToken[_token];
            userLocks[_index] = userLocks[userLocks.length-1];
            userLocks.pop();
            if (userLocks.length == 0) {
                users[msg.sender].lockedTokens.remove(_token);
            }
        }
        
        TransferHelper.safeTransfer(_token, msg.sender, _amount);
        emit onWithdraw(_token, _amount);
    }
    
    /**
    * @notice increase the amount of tokens per a specific lock, this is preferable to creating a new lock, less fees, and faster loading on our live block explorer
    */
    function incrementLock (address _token, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
        require(_amount > 0, 'ZERO AMOUNT');
        uint256 lockID = users[msg.sender].locksForToken[_token][_index];
        TokenLock storage userLock = tokenLocks[_token][lockID];
        require(lockID == _lockID && userLock.owner == msg.sender, 'Lock Mismatch!');
        
        TransferHelper.safeTransferFrom(_token, address(msg.sender), address(this), _amount);
        
        uint256 liquidityFee = _amount.mul(gFees.liquidityFee).div(1000);
        TransferHelper.safeTransfer(_token, devaddr, liquidityFee);

        uint256 amountLocked = _amount.sub(liquidityFee);
        
        userLock.amount = userLock.amount.add(amountLocked);
        
        emit onDeposit(_token, msg.sender, amountLocked, userLock.lockDate, userLock.unlockDate);
    }
    
    function getNumLocksForToken (address _token) external view returns (uint256) {
        return tokenLocks[_token].length;
    }
    
    function getNumLockedTokens () external view returns (uint256) {
        return lockedTokens.length();
    }
    
    function getLockedTokenAtIndex (uint256 _index) external view returns (address) {
        return lockedTokens.at(_index);
    }
    
    function getUserNumLockedTokens (address _user) external view returns (uint256) {
        UserInfo storage user = users[_user];
        return user.lockedTokens.length();
    }
    
    function getUserLockedTokenAtIndex (address _user, uint256 _index) external view returns (address) {
        UserInfo storage user = users[_user];
        return user.lockedTokens.at(_index);
    }
    
    function getUserNumLocksForToken (address _user, address _token) external view returns (uint256) {
        UserInfo storage user = users[_user];
        return user.locksForToken[_token].length;
    }
    
    function getUserLockForTokenAtIndex (address _user, address _token, uint256 _index) external view 
    returns (uint256, uint256, uint256, uint256, uint256, address) {
        uint256 lockID = users[_user].locksForToken[_token][_index];
        TokenLock storage tokenLock = tokenLocks[_token][lockID];
        return (tokenLock.lockDate, tokenLock.amount, tokenLock.initialAmount, tokenLock.unlockDate, tokenLock.lockID, tokenLock.owner);
    }

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