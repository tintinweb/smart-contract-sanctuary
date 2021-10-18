/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


contract Airdropper {
    //send the same amount of tokens to a bunch of addresses
    function airdropTokens(address token, address[] calldata targets, uint256 amount) external {
        //check that send will not fail for lack of funds / allowance
        uint256 totalToSend = targets.length * amount;
        uint256 userBalance = IERC20(token).balanceOf(msg.sender);
        uint256 userAllowance = IERC20(token).allowance(msg.sender, address(this));
        require(totalToSend <= userAllowance, "Airdropper: insufficient allowance. check that you have approved this contract to transfer tokens");
        require(totalToSend <= userBalance, "Airdropper: insufficient token funds in wallet");

        //perform sends
        for(uint256 j = 0; j < targets.length; j++) {
            IERC20(token).transferFrom(msg.sender, targets[j], amount);
        }
    }   

    //send different amounts of tokens to various addresses, e.g. targets[5] receives amounts[5] tokens
    function multisendTokens(address token, address[] calldata targets, uint256[] calldata amounts) external {
        //sanity check on inputs
        require(targets.length == amounts.length, "Airdropper: input length mismatch");

        //check that send will not fail for lack of funds / allowance
        uint256 totalToSend = 0;
        uint256 userBalance = IERC20(token).balanceOf(msg.sender);
        uint256 userAllowance = IERC20(token).allowance(msg.sender, address(this));
        for(uint256 i = 0; i < amounts.length; i++) {
            totalToSend += amounts[i];
        }
        require(totalToSend <= userAllowance, "Airdropper: insufficient allowance. check that you have approved this contract to transfer tokens");
        require(totalToSend <= userBalance, "Airdropper: insufficient token funds in wallet");

        //perform sends
        for(uint256 j = 0; j < amounts.length; j++) {
            IERC20(token).transferFrom(msg.sender, targets[j], amounts[j]);
        }
    }

    //same as multisendTokens, but also has argument 'totalAmount', which must match the total amount to send
    function multisendTokensWithSanityCheck(address token, address[] calldata targets, uint256[] calldata amounts, uint256 totalAmount) external {
        //sanity check on inputs
        require(targets.length == amounts.length, "Airdropper: input length mismatch");

        //check that send will not fail for lack of funds / allowance
        uint256 totalToSend = 0;
        uint256 userBalance = IERC20(token).balanceOf(msg.sender);
        uint256 userAllowance = IERC20(token).allowance(msg.sender, address(this));
        for(uint256 i = 0; i < amounts.length; i++) {
            totalToSend += amounts[i];
        }
        require(totalToSend <= userAllowance, "Airdropper: insufficient allowance. check that you have approved this contract to transfer tokens");
        require(totalToSend <= userBalance, "Airdropper: insufficient token funds in wallet");
        require(totalToSend == totalAmount, "Airdropper: totalAmount does not match sum of amounts array");

        //perform sends
        for(uint256 j = 0; j < amounts.length; j++) {
            IERC20(token).transferFrom(msg.sender, targets[j], amounts[j]);
        }
    }

    //similar to multisendTokensWithSanityCheck, but inputs are in whole number of tokens (not wei!)
    function wholeTokenInputMultisendTokensWithSanityCheck(
        address token, address[] calldata targets, uint256[] calldata amounts, uint256 totalAmount) external {
        //sanity check on inputs
        require(targets.length == amounts.length, "Airdropper: input length mismatch");

        //check that send will not fail for lack of funds / allowance
        uint256 totalToSend = 0;
        uint256 userBalance = IERC20(token).balanceOf(msg.sender);
        uint256 userAllowance = IERC20(token).allowance(msg.sender, address(this));
        uint256 decimals = IERC20Metadata(token).decimals();
        uint256 multiplier = (10 ** decimals);
        for(uint256 i = 0; i < amounts.length; i++) {
            totalToSend += amounts[i];
        }
        require(totalToSend <= userAllowance, "Airdropper: insufficient allowance. check that you have approved this contract to transfer tokens");
        require(totalToSend <= userBalance, "Airdropper: insufficient token funds in wallet");
        require(totalToSend == totalAmount, "Airdropper: totalAmount does not match sum of amounts array");

        //perform sends
        for(uint256 j = 0; j < amounts.length; j++) {
            IERC20(token).transferFrom(msg.sender, targets[j], (amounts[j] * multiplier));
        }
    }
}