// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./interfaces/IERC20.sol";
import "./core/Runnable.sol";

contract AvatarArtStaking is Runnable{
    uint256 public _duration;
    uint256 public _annualProfit;
    
    address public _bnuTokenAddress;
    uint256 public _stopTime;
    
    //Store all BNU token amount that is staked in contract
    uint256 public _totalStakedAmount;
    uint256 public constant MULTIPLIER = 1000;
    uint256 public constant ONE_YEAR = 365 days;
    
    //Store all BNU token amount that is staked by user
    //Mapping LockStage index => user account => token amount
    mapping(address => uint256) public _userStakeds;
    
    //Store all earned BNU token amount that will be reward for user when he stakes
    //Mapping user account => token amount
    mapping(address => uint) public _userEarneds;
    
    //Store the last time user received reward
    //Mapping stage index => user account => time
    mapping(address => uint256) public _userLastEarnedTimes;
    
    //Store the last time user staked
    //Mapping stage index => user account => time
    mapping(address => uint) public _userLastStakingTimes;
    
    //List of staking users from staking LockStage
    //Mapping: _lockStages index => user address
    address[] public _stakingUsers;

    constructor(address bnuTokenAddress){
        _duration = 730 days;
        _bnuTokenAddress = bnuTokenAddress;
    }
    
    /**
     * @dev Get BNU token address
    */
    function getBnuTokenAddress() external view returns(address){
        return _bnuTokenAddress;
    }

    function getStopTime() external view returns(uint){
        return _stopTime;
    }
    
    /**
     * @dev Get user's BNU earned
     * It includes stored interest and pending interest
     */ 
    function getUserEarnedAmount(address account) external view returns(uint){
        uint256 earnedAmount = _userEarneds[account];
        
        //Calculate pending amount
        uint256 userStakedAmount = _userStakeds[account];
        if(userStakedAmount > 0){
            earnedAmount += _calculatePendingEarned(userStakedAmount, _getUserRewardPendingTime(account));
        }
        
        return earnedAmount;
    }
    
    function getUserLastEarnedTime(address account) external view returns(uint){
        return _getUserLastEarnedTime(account);
    }
    
    function getUserLastStakingTime(address account) external view returns(uint){
        return _getUserLastStakingTime(account);
    }
    
    function getUserRewardPendingTime(address account) external view returns(uint){
        return _getUserRewardPendingTime(account);
    }
    
    /**
     * @dev Get total BNU token amount staked by `account`
     */ 
    function getUserStakedAmount(address account) external view returns(uint){
        return _getUserStakedAmount(account);
    }
    
    /**
     * @dev Set BNU token address
    */
    function setBnuTokenAddress(address tokenAddress) external onlyOwner{
        require(tokenAddress != address(0), "Zero address");
        _bnuTokenAddress = tokenAddress;
    }
    
    /**
     * @dev Set APR
     * Before set APR with new value, contract should process to calculate all current users' profit 
     * to reset interest
    */
    function setAnnualProfit(uint256 annualProfit) external onlyOwner{
        for(uint256 userIndex = 0; userIndex < _stakingUsers.length; userIndex++){
            _calculateInterest(_stakingUsers[userIndex]);
        }
        _annualProfit = annualProfit;
    }
    
    /**
     * @dev See IAvatarArtStaking
     */ 
    function stake(address account, uint256 amount) external isRunning onlyOwner returns(bool){
        //CHECK REQUIREMENTS
        require(amount > 0, "Amount should be greater than zero");
        
        //Calculate interest and store with extra interest
        _calculateInterest(account);
        
        //Update user staked amount and contract staked amount
        _userStakeds[account] += amount;
        _totalStakedAmount += amount;
        
        if(!_isUserStaked(account))
            _stakingUsers.push(account);
        
        //Store the last time user staked
        if(_userLastStakingTimes[account] == 0)
            _userLastStakingTimes[account] = _now();
        
        //Emit events
        emit Staked(account, amount);
        
        return true;
    }
    
    /**
     * @dev Stop staking program
     */ 
    function stop() external onlyOwner{
        _isRunning = false;
        _stopTime = _now();

        IERC20 bnuTokenContract = IERC20(_bnuTokenAddress);
        if(bnuTokenContract.balanceOf(address(this)) > _totalStakedAmount)
            bnuTokenContract.transfer(_owner, bnuTokenContract.balanceOf(address(this)) - _totalStakedAmount);
        
        emit Stopped(_now());
    }
    
    /**
     * @dev Withdraw staked amount in lockStage by index and pay earned token
     * If withdraw amount = 0; only pay earned token
     */ 
    function withdraw(uint256 amount) external returns(bool){
        address account = _msgSender();
        if(amount > 0){
            require(amount <= _getUserStakedAmount(account), "Amount is invalid");
        }
        //Calculate interest and store with extra interest
        _calculateInterest(account);
        
        IERC20 bnuTokenContract = IERC20(_bnuTokenAddress);
        
        //Calculate to withdraw staked amount
        if(amount > 0){
            uint256 lastStakingTime = _getUserLastStakingTime(account);
            if(lastStakingTime + _duration < _now()){
                _userStakeds[account] -= amount;    //Do not need to check `amount` <= user staked
                _totalStakedAmount -= amount;
                
                require(bnuTokenContract.transfer(account, amount), "Can not pay staked amount for user");
            }
        }
        
        uint256 eanedAmount = _userEarneds[account];
        
        //Pay all interest
        if(eanedAmount > 0){
            //Make sure that user can withdraw all their staked amount
            if(bnuTokenContract.balanceOf(address(this)) - _totalStakedAmount >= eanedAmount){
                require(bnuTokenContract.transfer(account, eanedAmount), "Can not pay interest for user");
                _userEarneds[account] = 0;
            }
        }
        
        //Emit events 
        emit Withdrawn(account, amount);
        
        return true;
    }
    
    /**
     * @dev Calculate and update user pending interest
     */ 
    function _calculateInterest(address account) internal{
        uint256 userStakedAmount = _userStakeds[account];
        if(userStakedAmount > 0){
            uint256 earnedAmount = _calculatePendingEarned(userStakedAmount, _getUserRewardPendingTime(account));
            _userEarneds[account] += earnedAmount;
        }
        _userLastEarnedTimes[account] = _now();
    }
    
    /**
     * @dev Calculate interest for user from `lastStakingTime` to  `now`
     * based on user staked amount and annualProfit
     */ 
    function _calculatePendingEarned(uint256 userStakedAmount, uint256 pendingTime) internal view returns(uint){
        return userStakedAmount * pendingTime * _annualProfit / MULTIPLIER / ONE_YEAR / 100;
    }
    
    /**
     * @dev Check user has staked or not
     */
    function _isUserStaked(address account) internal view returns(bool){
        for(uint256 index = 0; index < _stakingUsers.length; index++){
            if(_stakingUsers[index] == account)
                return true;
        }
        
        return false;
    }
    
    function _getUserLastEarnedTime(address account) internal view returns(uint){
        return _userLastEarnedTimes[account];
    }
    
    function _getUserLastStakingTime(address account) internal view returns(uint){
        return _userLastStakingTimes[account];
    }
    
    function _getUserRewardPendingTime(address account) internal view returns(uint){
        if(!_isRunning && _stopTime > 0)
            return _stopTime - _getUserLastEarnedTime(account);
        return _now() - _getUserLastEarnedTime(account);
    }

    function _getUserStakedAmount(address account) internal view returns(uint){
        return _userStakeds[account];
    }
    
    event Staked(address account, uint256 amount);
    event Withdrawn(address account, uint256 amount);
    event Stopped(uint256 time);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Ownable.sol";

abstract contract Runnable is Ownable {
    
    modifier isRunning{
        require(_isRunning, "Contract is paused");
        _;
    }
    
    bool internal _isRunning;
    
    constructor(){
        _isRunning = true;
    }
    
    function toggleRunningStatus() external onlyOwner{
        _isRunning = !_isRunning;
    }

    function getRunningStatus() external view returns(bool){
        return _isRunning;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Context.sol";

abstract contract Ownable is Context {
    
    modifier onlyOwner{
        require(_msgSender() == _owner, "Forbidden");
        _;
    }
    
    address internal _owner;
    address internal _newRequestingOwner;
    
    constructor(){
        _owner = _msgSender();
    }
    
    function getOwner() external virtual view returns(address){
        return _owner;
    }
    
    function requestChangeOwner(address newOwner) external  onlyOwner{
        require(_owner != newOwner, "New owner is current owner");
        _newRequestingOwner = newOwner;
    }
    
    function approveToBeOwner() external{
        require(_newRequestingOwner != address(0), "Zero address");
        require(_msgSender() == _newRequestingOwner, "Forbidden");
        
        address oldOwner = _owner;
        _owner = _newRequestingOwner;
        
        emit OwnerChanged(oldOwner, _owner);
    }
    
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    
    function _now() internal view returns(uint){
        return block.timestamp;
    }
}