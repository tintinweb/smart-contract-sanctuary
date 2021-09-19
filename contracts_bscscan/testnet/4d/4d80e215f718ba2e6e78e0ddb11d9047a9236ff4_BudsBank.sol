/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

pragma solidity ^0.8.6;
//SPDX-License-Identifier: MIT

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

contract BudsBank {

    address buds;
    address goodBudsWallet;
    address smokeOutWallet;

    uint lastDonationTime;
    
    event Deposit (address sender, uint amount, uint balance, uint time);
    event Donation (address wallet, uint amount, uint balance, uint time); 
    
    constructor (address budsAddress, address goodBudsWalletAddress, address smokeOutWalletAddress) {

        require(budsAddress != address(0));
        require(goodBudsWalletAddress != address(0));
        require(smokeOutWalletAddress != address(0));
        
        lastDonationTime = block.timestamp;

        buds = budsAddress;
        goodBudsWallet = goodBudsWalletAddress;
        smokeOutWallet = smokeOutWalletAddress;
    }
    
    function deposit(uint amount) public payable {
        
        IERC20(buds).transferFrom(msg.sender, address(this), amount);
        
        uint newBalance = IERC20(buds).balanceOf(address(this)); 
        
        emit Deposit(msg.sender, amount, newBalance, block.timestamp);
    }

    
       function donate() public {

        require(30 seconds < block.timestamp - lastDonationTime, "This month's donation has already completed");
        
        IERC20(buds).transfer(goodBudsWallet, 4200000000000);
        IERC20(buds).transfer(smokeOutWallet, 4200000000000);
        
        lastDonationTime = block.timestamp;
        
        uint newBalance = IERC20(buds).balanceOf(address(this)); 
        
        emit Donation(goodBudsWallet, 4200000000000, newBalance, block.timestamp);
        emit Donation(smokeOutWallet, 4200000000000, newBalance, block.timestamp);
    }
    
}