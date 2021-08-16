// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./TransferHelper.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IPancakeswapV2Router02.sol";
import "./IPancakeswapV2Pair.sol";
import "./IERC20.sol";
import "./IPancakeswapV2Factory.sol";

// Lock for Pancake Swap V2.
contract PancakeV2Locker is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IPancakeswapV2Factory public pancakeswapFactory;

    struct UserInfo {
        // List of locked tokens by the user.
        EnumerableSet.AddressSet lockedTokens;
        // ERC20/BEP20 token address to lockId.
        mapping(address => uint256[]) locksForToken;
    }

    struct TokenLock {
        // Locked since, timestamp in seconds.
        uint256 lockDate;
        // Amount of tokens locked.
        uint256 amount;
        // Initial amount of tokens locked.
        uint256 initialAmount;
        // Date from which tokens can be withdrawn.
        uint256 unlockDate;
        // ID of the lock for a pancake pair.
        uint256 lockID;
        // Owner of the lock.
        address owner;
    }

    mapping(address => UserInfo) private users;
    EnumerableSet.AddressSet private lockedTokens;
    // PCS V2 Pair to all its existing locks.
    mapping(address => TokenLock[]) public tokenLocks;

    uint256 private _bnbFee;
    EnumerableSet.AddressSet private feeWhitelist;
    address payable devaddr;

    event onDeposit(address lpToken, address user, uint256 amount, uint256 lockDate, uint256 unlockDate);
    event onWithdraw(address lpToken, uint256 amount);

    constructor() {
        devaddr = payable(msg.sender);
        IPancakeswapV2Router02 _pcsV2Router = IPancakeswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pancakeswapFactory = IPancakeswapV2Factory(_pcsV2Router.factory());
        _bnbFee = 100000000000000000; // 0.1 BNB
    }
  
    function setLockerOwner(address payable _devaddr) public onlyOwner {
        devaddr = _devaddr;
    }

    function setFee(uint256 bnbFee) public onlyOwner {
        _bnbFee = bnbFee;
    }

    /**
     * @dev Witelisted accounts do not pay fees on locking.
     */
    function whitelistFeeAccount(address _user, bool _add) public onlyOwner {
        if (_add) {
            feeWhitelist.add(_user);
        } else {
            feeWhitelist.remove(_user);
        }
    }

    /**
     * @dev Creates a new lock.
     * @param _lpToken the pcs v2 token address.
     * @param _amount amount of LP tokens to lock.
     * @param _unlockDate the unix timestamp in seconds until unlock.
     * @param _withdrawer the user who can withdraw liquidity once the lock expires.
     */
    function lockLPToken(address _lpToken, uint256 _amount, uint256 _unlockDate, address payable _withdrawer) external payable nonReentrant {
        require(_unlockDate < 10000000000, "Timestamp invalid. Remember to use seconds rather than ms.");
        require(_amount > 0, "The amount to lock must be bigger than 0.");

        // Make sure the pair exists before proceeding.
        IPancakeswapV2Pair lpair = IPancakeswapV2Pair(address(_lpToken));
        address factoryPairAddress = pancakeswapFactory.getPair(lpair.token0(), lpair.token1());
        require(factoryPairAddress == address(_lpToken), "This is not a Pancakeswap V2 pair.");

        TransferHelper.safeTransferFrom(_lpToken, address(msg.sender), address(this), _amount);

        // flatrate fees
        if (!feeWhitelist.contains(msg.sender)) {
            require(msg.value == _bnbFee, "Invalid fee quantity sent.");
            devaddr.transfer(_bnbFee);
        } else if (msg.value > 0) {
            // Refund BNB to whitelisted members that sent any BNB anyway.
            payable(msg.sender).transfer(msg.value);
        }

        // Create the initial token lock.
        TokenLock memory tokenLock;
        tokenLock.lockDate = block.timestamp;
        tokenLock.amount = _amount;
        tokenLock.initialAmount = _amount;
        tokenLock.unlockDate = _unlockDate;
        tokenLock.lockID = tokenLocks[_lpToken].length;
        tokenLock.owner = _withdrawer;

        // Record the lock for the Pancake Swap V2 pair.
        tokenLocks[_lpToken].push(tokenLock);
        lockedTokens.add(_lpToken);

        // Record the lock for the user.
        UserInfo storage user = users[_withdrawer];
        user.lockedTokens.add(_lpToken);
        uint256[] storage user_locks = user.locksForToken[_lpToken];
        user_locks.push(tokenLock.lockID);

        emit onDeposit(_lpToken, msg.sender, tokenLock.amount, tokenLock.lockDate, tokenLock.unlockDate);
    }

    /**
     * @dev Withdraws a lock.
     */
    function withdraw(address _lpToken, uint256 _index, uint256 _lockID) external nonReentrant {
        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage userLock = tokenLocks[_lpToken][lockID];
        require(lockID == _lockID && userLock.owner == msg.sender, "Wrong lock!");
        require(userLock.unlockDate < block.timestamp, "This lock is still in place.");
        uint256 _amount = userLock.amount;
        userLock.amount = 0;

        // Clean up storage.
        uint256[] storage userLocks = users[msg.sender].locksForToken[_lpToken];
        userLocks[_index] = userLocks[userLocks.length-1];
        userLocks.pop();
        if (userLocks.length == 0) {
            users[msg.sender].lockedTokens.remove(_lpToken);
        }
        
        TransferHelper.safeTransfer(_lpToken, msg.sender, _amount);
        emit onWithdraw(_lpToken, _amount);
    }
  
    function getNumLocksForToken(address _lpToken) external view returns (uint256) {
        return tokenLocks[_lpToken].length;
    }
  
    function getNumLockedTokens() external view returns (uint256) {
        return lockedTokens.length();
    }
    
    function getLockedTokenAtIndex(uint256 _index) external view returns (address) {
        return lockedTokens.at(_index);
    }

    function getUserNumLockedTokens(address _user) external view returns (uint256) {
        UserInfo storage user = users[_user];
        return user.lockedTokens.length();
    }

    function getUserLockedTokenAtIndex(address _user, uint256 _index) external view returns (address) {
        UserInfo storage user = users[_user];
        return user.lockedTokens.at(_index);
    }
    
    function getUserNumLocksForToken(address _user, address _lpToken) external view returns (uint256) {
        UserInfo storage user = users[_user];
        return user.locksForToken[_lpToken].length;
    }
    
    function getUserLockForTokenAtIndex(address _user, address _lpToken, uint256 _index) external view 
    returns (uint256, uint256, uint256, uint256, uint256, address) {
        uint256 lockID = users[_user].locksForToken[_lpToken][_index];
        TokenLock storage tokenLock = tokenLocks[_lpToken][lockID];
        return (tokenLock.lockDate, tokenLock.amount, tokenLock.initialAmount, tokenLock.unlockDate, tokenLock.lockID, tokenLock.owner);
    }

    function getWhitelistedUsersLength() external view returns (uint256) {
        return feeWhitelist.length();
    }

    function getWhitelistedUserAtIndex(uint256 _index) external view returns (address) {
        return feeWhitelist.at(_index);
    }

    function getUserWhitelistStatus(address _user) external view returns (bool) {
        return feeWhitelist.contains(_user);
    }
}