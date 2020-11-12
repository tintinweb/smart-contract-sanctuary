/* SPDX-License-Identifier: MIT */
pragma solidity ^0.7.0;

import "./Erc20.sol";
import "./Erc20PermitInterface.sol";

/**
 * @title Erc20Permit
 * @author Paul Razvan Berg
 * @notice Extension of Erc20 that allows token holders to use their tokens
 * without sending any transactions by setting the allowance with a signature
 * using the `permit` method, and then spend them via `transferFrom`.
 * @dev See https://eips.ethereum.org/EIPS/eip-2612.
 */
contract Erc20Permit is
    Erc20PermitInterface, /* one dependency */
    Erc20 /* three dependencies */
{
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) Erc20(name_, symbol_, decimals_) {
        uint256 chainId;
        /* solhint-disable-next-line no-inline-assembly */
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * assuming the latter's signed approval.
     *
     * IMPORTANT: The same issues Erc20 `approve` has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the Eip712-formatted function arguments.
     * - The signature must use `owner`'s current nonce.
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner != address(0x00), "ERR_ERC20_PERMIT_OWNER_ZERO_ADDRESS");
        require(spender != address(0x00), "ERR_ERC20_PERMIT_SPENDER_ZERO_ADDRESS");
        require(deadline >= block.timestamp, "ERR_ERC20_PERMIT_EXPIRED");

        /* It's safe to use the "+" operator here because the nonce cannot realistically overflow, ever. */
        bytes32 hashStruct = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));
        address recoveredOwner = ecrecover(digest, v, r, s);

        require(recoveredOwner != address(0x00), "ERR_ERC20_PERMIT_RECOVERED_OWNER_ZERO_ADDRESS");
        require(recoveredOwner == owner, "ERR_ERC20_PERMIT_INVALID_SIGNATURE");

        approveInternal(owner, spender, amount);
    }
}
