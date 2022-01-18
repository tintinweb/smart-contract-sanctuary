/**
 *Submitted for verification at polygonscan.com on 2022-01-18
*/

pragma solidity =0.6.10;
pragma experimental ABIEncoderV2;

/**
 * SPDX-License-Identifier: UNLICENSED
 */
interface CalleeInterface {
    /**
     * Allows users to send this contract arbitrary data.
     * @param _sender The msg.sender to Controller
     * @param _data Arbitrary data given by the sender
     */
    function callFunction(address payable _sender, bytes memory _data) external;
}

interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

/**
 * 
 */
/**
 * @title PermitCallee
 * @author Opyn Team
 * @dev Contract for executing permit signature
 */
contract PermitCallee is CalleeInterface {
    function callFunction(address payable _sender, bytes memory _data) external override {
        (
            address token,
            address owner,
            address spender,
            uint256 amount,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) = abi.decode(_data, (address, address, address, uint256, uint256, uint8, bytes32, bytes32));

        IERC20PermitUpgradeable(token).permit(owner, spender, amount, deadline, v, r, s);
    }
}