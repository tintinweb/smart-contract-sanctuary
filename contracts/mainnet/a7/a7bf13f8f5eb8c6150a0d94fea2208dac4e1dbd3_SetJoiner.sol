/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// SPDX-License-Identifier: GPL-3.0-or-later

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

interface IBasicIssuanceModule {
    function issue(
        address _setToken,
        uint256 _quantity,
        address _to
    ) external;
}

contract SetJoiner {
    address constant SET_TOKEN = 0x7b18913D945242A9c313573E6c99064cd940c6aF;

    IBasicIssuanceModule constant ISSUANCE_MODULE =
        IBasicIssuanceModule(0xd8EF3cACe8b4907117a45B0b125c68560532F94D);

    IERC20 constant TOKEN = IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);

    address constant TREASURY_MULTISIG =
        0xe94B5EEC1fA96CEecbD33EF5Baa8d00E4493F4f3;

    function execute() public {
        require(
            msg.sender == 0x189bC085565697509cFA34131521Dc7981BACDA0 ||
            msg.sender == 0x285b7EEa81a5B66B62e7276a24c1e0F83F7409c1 ||
            msg.sender == TREASURY_MULTISIG
        );

        uint256 balance = TOKEN.balanceOf(address(this));

        TOKEN.approve(address(ISSUANCE_MODULE), balance);

        ISSUANCE_MODULE.issue(SET_TOKEN, balance, TREASURY_MULTISIG);
    }

    function abort() public {
        require(msg.sender == 0x285b7EEa81a5B66B62e7276a24c1e0F83F7409c1);
        TOKEN.transfer(TREASURY_MULTISIG, TOKEN.balanceOf(address(this)));
    }
}