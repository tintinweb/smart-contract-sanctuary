/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

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


// Root file: contracts/MySwap.sol

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MySwap {
    IERC20 public swapToken;
    IERC20 public eth;
    uint256 public ratio;

    constructor(IERC20 _eth, IERC20 _swapToken) {
        eth = _eth;
        swapToken = _swapToken;
    }

    function addLiquidity(uint256 _addedLiquidity, uint256 maxTokens) public{
        require(_addedLiquidity > 0, "Cant add 0 liquidity");
        uint swapTokenBalance = swapToken.balanceOf(address(this));
        uint ethBalance = eth.balanceOf(address(this));
        uint addedTokens = maxTokens;

        if(swapTokenBalance > 0){
            addedTokens = swapTokenBalance / ethBalance * _addedLiquidity;
        } else {
            addedTokens = maxTokens;
        }

        require(maxTokens >= addedTokens,"Max tokens is less than required for pool");

        eth.transferFrom(msg.sender,address(this),_addedLiquidity);
        swapToken.transferFrom(msg.sender, address(this), addedTokens);
    }

    function sellEth(uint ethAmount) public{
        uint swapTokenBalance = swapToken.balanceOf(address(this));
        uint ethBalance = eth.balanceOf(address(this));

        require(swapTokenBalance > 0,"No liquidity");

        uint boughTokens = (swapTokenBalance * ethAmount) / (ethBalance + ethAmount);
        eth.transferFrom(msg.sender, address(this), ethAmount);
        swapToken.transfer(msg.sender, boughTokens);
    }

    function buyEth(uint ethAmount) public {
        uint swapTokenBalance = swapToken.balanceOf(address(this));
        uint ethBalance = eth.balanceOf(address(this));
        require(ethAmount > 0);
        require(ethBalance > ethAmount, "Not enough eth in exchange");

        uint soldTokens = (swapTokenBalance * ethBalance) / (ethBalance - ethAmount);
        eth.transfer(msg.sender, ethAmount);
        swapToken.transferFrom(msg.sender, address(this), soldTokens);
    }

    function sellTokens(uint tokenAmount) public {
        uint swapTokenBalance = swapToken.balanceOf(address(this));
        uint ethBalance = eth.balanceOf(address(this));

        require(ethBalance > 0,"No liquidity");
        require(tokenAmount > 0);
        uint boughtEth = (ethBalance * tokenAmount) / (swapTokenBalance + tokenAmount);
        eth.transfer(msg.sender, boughtEth);
        swapToken.transferFrom(msg.sender, address(this), tokenAmount);
    }

    function buyTokens(uint tokenAmount) public{
        uint swapTokenBalance = swapToken.balanceOf(address(this));
        uint ethBalance = eth.balanceOf(address(this));

        require(swapTokenBalance >= tokenAmount, "Not enough tokens in exchange");

        uint soldEth = (ethBalance * swapTokenBalance) / (swapTokenBalance - tokenAmount);
        swapToken.transfer(msg.sender, tokenAmount);
        eth.transferFrom(msg.sender, address(this), soldEth);
    }

}