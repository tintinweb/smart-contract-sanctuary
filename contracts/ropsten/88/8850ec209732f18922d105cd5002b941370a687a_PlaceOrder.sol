/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: contracts/PlaceOrder.sol


pragma solidity >=0.7.0 <0.9.0;


contract PlaceOrder {
    
    address payable private amazonWallet;
    IERC20 public daiAddress;
    mapping (address => bool) private amazonCustomers;
    
    event Purchase(address buyer, uint256 amount, uint256 date);
    
    constructor(address payable _amazonWallet, address _daiAddress) {
        amazonWallet = _amazonWallet;
        daiAddress = IERC20(_daiAddress);
    }

    function placeOrderDai(uint256 _amount) external payable {
        require(_amount > 0);
        daiAddress.transferFrom(msg.sender, amazonWallet, _amount);
        amazonCustomers[msg.sender] = true;
        emit Purchase(msg.sender, _amount, block.timestamp);
    }

    function placeOrderEther(uint256 _amount) external payable {
        require(_amount > 0);
        require(msg.sender.balance > _amount);
        (bool success, ) = amazonWallet.call{value: _amount}("");
        require(success, "Failed to purchase!");
        amazonCustomers[msg.sender] = true;
        emit Purchase(msg.sender, _amount, block.timestamp);
    }
    
    /**
    * you can use this method to place an order directly from the contract.
    * 
    * @param _asin : the identifier of the item you want to purchase
    * @param _deliveryOption : 1 for standard delivery, 2 for same day delivery
    * @param _amount : the total cost of the item + delivery 
    * 
    */
    
    function placeOrder(bytes memory _asin, uint256 _deliveryOption, uint256 _amount) external payable {
        require(_amount > 0);
        require(msg.sender.balance > _amount);
        require(_asin.length != 0);
        require(_deliveryOption == 1 || _deliveryOption == 2);
        // checking if _amount is correct else returns Ether to the customer 
        (bool success, ) = amazonWallet.call{value: _amount}("");
        require(success, "Failed to purchase!");
        amazonCustomers[msg.sender] = true;
        emit Purchase(msg.sender, _amount, block.timestamp);
    }
    
    function areYouAnAmazonCustomer(address _addr) external view returns (bool) {
        return amazonCustomers[_addr];
    }
    
}