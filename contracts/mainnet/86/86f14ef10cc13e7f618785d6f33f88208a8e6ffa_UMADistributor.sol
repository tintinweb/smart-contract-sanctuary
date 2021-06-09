/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

pragma solidity ^0.5.15;

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

contract UMADistributor {
    IERC20 private constant TOKEN =
        IERC20(0x04Fa0d235C4abf4BcF4787aF4CF447DE572eF828);

    function execute() external {
        TOKEN.transfer(
            0x06d8aeB52f99F8542429dF3009ed26535c22d5aa,
            59409927761111062
        );
        TOKEN.transfer(
            0xdD395050aC923466D3Fa97D41739a4ab6b49E9F5,
            1764644915175027145008
        );
        TOKEN.transfer(
            0xB3f21996B59Ff2f1cD0fabbDf9Bc756e8F93FeC9,
            14923617427200748311
        );
        TOKEN.transfer(
            0x4565Ee03a020dAA77c5EfB25F6DD32e28d653c27,
            3088359380352128540
        );
        TOKEN.transfer(
            0x974678F5aFF73Bf7b5a157883840D752D01f1973,
            19619011703886621840
        );
        TOKEN.transfer(
            0x653d63E4F2D7112a19f5Eb993890a3F27b48aDa5,
            177886548891729038231
        );
        TOKEN.transfer(
            0xB1AdceddB2941033a090dD166a462fe1c2029484,
            611857705796827697909
        );
        TOKEN.transfer(
            0xc7777C1a0Cf7E22c51b44f7CeD65CF2A6b06dc5C,
            782519844448176889
        );
        TOKEN.transfer(
            0x8CC7355a5c07207ef6ee188F7b74757b6bAb7DAc,
            3116886535036429824
        );
        selfdestruct(address(0x0));
    }
}