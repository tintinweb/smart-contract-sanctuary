/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity ^0.5.1;
contract ERC20 {
    function decimals() external view returns (uint8);
    
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

contract ButAndSell{
    ERC20 token;
    uint256 public price = 100;
    // uint256 public price = 100000000000000;
    constructor() public {
         token = ERC20(0x13681B1F6F93977F62389E0a2b1E84BA24d78fbc); // old niox token
    }
    
     function purchaseTokens(uint256 numberOfTokens) public payable {
        require(msg.value == numberOfTokens * price);

        uint256 scaledAmount = numberOfTokens *
            (uint256(10) ** token.decimals());

        require(token.balanceOf(address(this)) >= scaledAmount);

        require(token.transfer(msg.sender, scaledAmount));
    }
    
    function sellTokens(uint256 numberOfTokens) public payable {
        require(address(this).balance >= numberOfTokens * price);

        // uint256 scaledAmount = numberOfTokens *
        //     (uint256(10) ** token.decimals());

        require(token.balanceOf(msg.sender) >= numberOfTokens);

        require(token.transferFrom(msg.sender,address(this), numberOfTokens));
    }
}