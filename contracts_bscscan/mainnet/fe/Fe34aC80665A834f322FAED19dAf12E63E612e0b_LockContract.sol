/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;


interface IERC20 {

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


contract LockContract {
    
    uint256 public unlockDate;
    address public adminAddress;
    
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Only admin can call this method");
        _;
    }
    
    constructor(uint32 _numberOfDays) {
        require(_numberOfDays < 100, 'Lock for no more than 100 days');
        adminAddress = msg.sender;
        unlockDate = block.timestamp + _numberOfDays * 1 days;
     }
    
    function extendLockTime(uint32 _additionalLockHours) onlyAdmin public {
         unlockDate += _additionalLockHours * 1 hours;
    }
    
    function depositTokens(uint256 _amount, address _tokenAddress) external payable {
        require(_amount > 0, 'token amount is Zero');
        require(IERC20(_tokenAddress).approve(address(this), _amount), 'Approve tokens failed');
        require(IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount), 'Deposit tokens failed');
    }
    
    function withdrawTokens(uint256 _amount, address _tokenAddress) onlyAdmin external {
        require(block.timestamp >= unlockDate, "Unlock date is not yet");
        IERC20(_tokenAddress).transfer(adminAddress, _amount);
    }
}