/**
 *Submitted for verification at Etherscan.io on 2020-12-20
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity 0.6.12;


contract timeLockAnrx {
    
    struct timeLockAnrxInfo {
        uint256 lockTime;
        uint256 unlockTime;
        uint256 lockAmount;
    }
    
    mapping(address => timeLockAnrxInfo) private lockTokens;
    
    IERC20 private anrToken;
    
    constructor(address tokenAddress) public{
        anrToken = IERC20(tokenAddress);
    }
    
    function deposit(uint256 amount) external returns(bool){
        anrToken.transferFrom(msg.sender,address(this),amount);
        
        timeLockAnrxInfo memory newStake = timeLockAnrxInfo({
           lockTime:now,
           unlockTime: now + 31363200,
           lockAmount:amount
        });
        
        lockTokens[msg.sender] = newStake;
        
        return true;
    }
    
    function withdrawTokens()external returns(bool){
        require(now>lockTokens[msg.sender].unlockTime,"Function Not Yet Available. Tokens are locked until December 18th, 2021.");
        uint256 amount = lockTokens[msg.sender].lockAmount;
        anrToken.transfer(msg.sender, amount);
        return true;
    }
    
    function getTimeLockInfo(address userAddress)external view returns(uint256,uint256,uint256){
        uint256 lockedTime = lockTokens[userAddress].lockTime;
        uint256 unlockedTime = lockTokens[userAddress].unlockTime;
        uint256 lockedAmount = lockTokens[userAddress].lockAmount;
        return(lockedTime, unlockedTime, lockedAmount);
    }
}