/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// File: openzeppelin-solidity\contracts\token\ERC20\IERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: contracts\exchange.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract Exchange {
    IERC20 tokenA;
    IERC20 tokenB;
    uint256 public exchangeRate;
    address public owner;

    constructor(address tokeAAddress_, address tokenBAddress_, uint256 exchangeRate_) {
        tokenA = IERC20(tokeAAddress_);
        tokenB = IERC20(tokenBAddress_);
        exchangeRate = exchangeRate_;
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    function swaptokenAfortokenB(uint256 _amount) public {
        // we first check to see if this contract have enough amount of tokenB be to give user for their tokenA
        uint256 thisContractTokenBBalance = tokenB.balanceOf(address(this));
        require(thisContractTokenBBalance >= (_amount * exchangeRate), "No enough tokenB to swap for this amount of tokeA");

        //this will only work if user have enough amount of tokenA and has granted this contract enough allowance to complete the swap
        tokenA.transferFrom(msg.sender, address(this), _amount);
        //transfering tokenB to user using the exchange rate
        tokenB.transfer(msg.sender, _amount * exchangeRate);
    }

    function changeExchangeRate(uint256 _newRate) public onlyOwner {
        exchangeRate = _newRate;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}