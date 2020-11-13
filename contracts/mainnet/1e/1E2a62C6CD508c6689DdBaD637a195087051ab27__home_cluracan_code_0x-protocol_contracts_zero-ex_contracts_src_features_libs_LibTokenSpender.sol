/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../errors/LibSpenderRichErrors.sol";
import "../ITokenSpenderFeature.sol";

library LibTokenSpender {
    using LibRichErrorsV06 for bytes;

    // Mask of the lower 20 bytes of a bytes32.
    uint256 constant private ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    /// @dev Transfers ERC20 tokens from `owner` to `to`.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function spendERC20Tokens(
        IERC20TokenV06 token,
        address owner,
        address to,
        uint256 amount
    )
        internal
    {
        bool success;
        bytes memory revertData;

        require(address(token) != address(this), "LibTokenSpender/CANNOT_INVOKE_SELF");

        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transferFrom(address,address,uint256)
            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), amount)

            success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x64, 0, 0)

            let rdsize := returndatasize()

            returndatacopy(add(ptr, 0x20), 0, rdsize) // reuse memory

            // Check for ERC20 success. ERC20 tokens should return a boolean,
            // but some don't. We accept 0-length return data as success, or at
            // least 32 bytes that starts with a 32-byte boolean true.
            success := and(
                success,                             // call itself succeeded
                or(
                    iszero(rdsize),                  // no return data, or
                    and(
                        iszero(lt(rdsize, 32)),      // at least 32 bytes
                        eq(mload(add(ptr, 0x20)), 1) // starts with uint256(1)
                    )
                )
            )

            if iszero(success) {
                // revertData is a bytes, so length-prefixed data
                mstore(ptr, rdsize)
                revertData := ptr

                // update free memory pointer (ptr + 32-byte length + return data)
                mstore(0x40, add(add(ptr, 0x20), rdsize))
            }
        }

        if (!success) {
            // Try the old AllowanceTarget.
            try ITokenSpenderFeature(address(this))._spendERC20Tokens(
                    token,
                    owner,
                    to,
                    amount
                ) {
            } catch {
                // Bubble up the first error message. (In general, the fallback to the
                // allowance target is opportunistic. We ignore the specific error
                // message if it fails.)
                LibSpenderRichErrors.SpenderERC20TransferFromFailedError(
                    address(token),
                    owner,
                    to,
                    amount,
                    revertData
                ).rrevert();
            }
        }
    }

    /// @dev Gets the maximum amount of an ERC20 token `token` that can be
    ///      pulled from `owner` by this address.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @return amount The amount of tokens that can be pulled.
    function getSpendableERC20BalanceOf(
        IERC20TokenV06 token,
        address owner
    )
        internal
        view
        returns (uint256)
    {
        return LibSafeMathV06.min256(
            token.allowance(owner, address(this)),
            token.balanceOf(owner)
        );
    }
}
