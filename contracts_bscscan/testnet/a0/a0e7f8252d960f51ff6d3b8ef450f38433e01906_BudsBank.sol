/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

pragma solidity ^0.8.6;
//SPDX-License-Identifier: GNU General Public License v3.0

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

    address Buds;
    address payable goodBudsWallet;
    address payable smokeOutWallet;
    
    uint initialTime;
    
    bool[] monthlyDonationStatus; //log of donation status of each month since initialTime

    event Deposit (address sender, uint amount, uint balance, uint time);
    event Donation (address wallet, uint amount, uint balance, uint time); 
    
    constructor (address budsAddress, address goodBudsWalletAddress, address smokeOutWalletAddress) {

        require(budsAddress != address(0));
        require(goodBudsWalletAddress != address(0));
        require(smokeOutWalletAddress != address(0));
    
        //setting initialTime as time of contract creation
        initialTime = block.timestamp;
        Buds = budsAddress;
        goodBudsWallet = payable(goodBudsWalletAddress);
        smokeOutWallet = payable(smokeOutWalletAddress);
    }
    
    //a function that allows people to deposit to this contract
    function deposit(address token, uint amount) public payable {
        
        require(token == Buds, "Sorry, those tokens aren't accepted here");
        
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        
        uint newBalance = IERC20(Buds).balanceOf(address(this)); 
        
        emit Deposit(msg.sender, amount, newBalance, block.timestamp);
    }

    function donate() public {
            
        uint timeSinceInitialTime = block.timestamp - initialTime;
        uint currentMonth = timeSinceInitialTime/ 60 seconds;
        
        require(monthlyDonationStatus[currentMonth] == false, "This month's donation has already completed");
        
        IERC20(Buds).transferFrom(address(this), goodBudsWallet, 4200);
        IERC20(Buds).transferFrom(address(this), smokeOutWallet, 4200);
        
        monthlyDonationStatus[currentMonth] = true;
        
        uint newBalance = IERC20(Buds).balanceOf(address(this)); 
        
        emit Donation(goodBudsWallet, 4200, newBalance, block.timestamp);
        emit Donation(smokeOutWallet, 4200, newBalance, block.timestamp);
    }
}