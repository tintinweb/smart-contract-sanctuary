pragma solidity ^0.6.0;

contract LiquidityLock {

    IERC20 public uni;
    IERC20 public flap;
    uint256 public duration;
    uint256 public ratio;
    uint256 public totalLocked;
    address internal _owner;
    
    mapping(address => uint256) locked;
    mapping(address => uint256) time;

    event Locked (address indexed user, uint256 amount);
    event Unlocked (address indexed user, uint256 amount);

    constructor (IERC20 _uni, IERC20 _flap) public {
        uni = _uni;
        flap = _flap;
        duration = 1814400;
        ratio = 5000;
        _owner = msg.sender;
        
    }
    
    modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
    }
    
    function setRatio(uint256 flapsxuni) public onlyOwner {
        ratio = flapsxuni;
    }
    
    function lock(uint256 amount) public {
        
        uint256 flaps = amount*ratio;
        require(flaps <= flap.balanceOf(address(this)), "This contract has run out of flapp rewards, wait for replenishment or try a different contract");
        require(uni.transferFrom(msg.sender, address(this), amount), "You need to approve UNI tokens to be transferred to this contract before locking");
        locked[msg.sender] = locked[msg.sender] + amount;
        totalLocked = totalLocked + amount;
        time[msg.sender] = now;
        flap.transfer(msg.sender, flaps);
        emit Locked(msg.sender, amount);
    }

     function unlock() public {

        require(now >= time[msg.sender] + duration, "You can't unlock yet, wait for the lock to end");
        uint256 amount = locked[msg.sender];
        require(amount > 0, "You have no tokens to unlock");
        locked[msg.sender] = locked[msg.sender] - amount;
        totalLocked = totalLocked - amount;
        uni.transfer(msg.sender, amount);
        emit Unlocked(msg.sender, amount);
    }

    function getLockedAmount(address user) public view returns (uint256) {
        return locked[user];
    }

    function getUnlockTime(address user) public view returns (uint256) {
        return (time[user] + duration);
    }

    function getMyStatus() public view returns (uint256, uint256) {
        uint256 lockedAmount = getLockedAmount(msg.sender);
        uint256 unlockTime = getUnlockTime(msg.sender);
        return (lockedAmount, unlockTime);
    }

    function getTotalLocked() public view returns (uint256) {
        return totalLocked;
    }

    
}

// SPDX-License-Identifier: MIT

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