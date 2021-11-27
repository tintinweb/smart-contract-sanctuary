/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// SPDX-License-Identifier: Unlicensed

/**
 * @dev ALPHAKOMBAT TEAM
 * @author ALPHAKOMBAT TEAM <[email protected]>
 */
 pragma solidity ^0.8.10;
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

contract AlkomVault  {
    address public owner;
    uint256 public balance;
    
    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);
    
    constructor() {
        owner = msg.sender;
    }
    
    receive() payable external {
        balance += msg.value;
        emit TransferReceived(msg.sender, msg.value);
    }    
    
    // function withdraw(uint amount, address payable destAddr) public {
    //     //require(msg.sender == owner, "Only owner can withdraw funds"); 
    //     require(amount <= balance, "Insufficient funds");
        
    //     destAddr.transfer(amount);
    //     balance -= amount;
    //     emit TransferSent(msg.sender, destAddr, amount);
    // }
   
    function Deposit(address _token, uint256 amount) public {

         uint256 allowance = IERC20(_token).allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
    IERC20(_token).transferFrom(msg.sender, address(this), amount);
      emit TransferReceived(msg.sender, amount);
    }

    function Withdraw(address to, address _token, uint256 amount) public {
         uint256 erc20balance = IERC20(_token).balanceOf(address(this));
        require(amount <= erc20balance, "Low balance in vault");       
           IERC20(_token).transfer(to, amount);
        emit TransferSent(msg.sender, to, amount);

        }

    function getBalanceOfToken(address _token) public view returns (uint) {
    return IERC20(_token).balanceOf(address(this));
    }
   
}