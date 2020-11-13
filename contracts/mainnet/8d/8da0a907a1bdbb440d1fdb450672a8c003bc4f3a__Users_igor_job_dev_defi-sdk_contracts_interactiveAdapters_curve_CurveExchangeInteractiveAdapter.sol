// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.7.1;
pragma experimental ABIEncoderV2;

import { ERC20 } from "../../shared/ERC20.sol";
import { SafeERC20 } from "../../shared/SafeERC20.sol";
import { TokenAmount } from "../../shared/Structs.sol";
import { CurveExchangeAdapter } from "../../adapters/curve/CurveExchangeAdapter.sol";
import { InteractiveAdapter } from "../InteractiveAdapter.sol";
import { Stableswap } from "../../interfaces/Stableswap.sol";


/**
 * @title Interactive adapter for Curve protocol (exchange).
 * @dev Implementation of CurveInteractiveAdapter abstract contract.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract CurveExchangeInteractiveAdapter is CurveExchangeAdapter, InteractiveAdapter  {
    using SafeERC20 for ERC20;

    /**
     * @notice Exchanges tokens using the given swap contract.
     * @param tokenAmounts Array with one element - TokenAmount struct with
     * "from" token address, "from" token amount to be deposited, and amount type.
     * @param data Token address to be exchanged to (ABI-encoded).
     * @param data ABI-encoded additional parameters:
     *     - toToken - destination token address (one of those used in swap).
     *     - swap - swap address.
     *     - i - input token index.
     *     - j - destination token index.this
     *     - useUnderlying - true if swap_underlying() function should be called,
     *                       else swap() function will be called.
     * @dev Implementation of InteractiveAdapter function.
     */
    function deposit(
        TokenAmount[] calldata tokenAmounts,
        bytes calldata data
    )
        external
        payable
        override
        returns (address[] memory tokensToBeWithdrawn)
    {
        require(tokenAmounts.length == 1, "CEIA: should be 1 token");

        address token = tokenAmounts[0].token;
        uint256 amount = getAbsoluteAmountDeposit(tokenAmounts[0]);

        (address toToken, address swap, int128 i, int128 j, bool useUnderlying) = abi.decode(
            data,
            (address, address, int128, int128, bool)
        );

        tokensToBeWithdrawn = new address[](1);
        tokensToBeWithdrawn[0] = toToken;

        uint256 allowance = ERC20(token).allowance(address(this), swap);
        if (allowance < amount) {
            if (allowance > 0) {
                ERC20(token).safeApprove(swap, 0, "CEIA[1]");
            }
            ERC20(token).safeApprove(swap, type(uint256).max, "CEIA[2]");
        }

        // solhint-disable-next-line no-empty-blocks
        if (useUnderlying) {
            try Stableswap(swap).exchange_underlying(i, j, amount, 0) {
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("CEIA: deposit fail[1]");
            }
        } else {
            try Stableswap(swap).exchange(i, j, amount, 0) {
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("CEIA: deposit fail[2]");
            }
        }
    }

    /**
     * @notice Withdraw functionality is not supported.
     * @dev Implementation of InteractiveAdapter function.
     */
    function withdraw(
        TokenAmount[] calldata,
        bytes calldata
    )
        external
        payable
        override
        returns (address[] memory)
    {
        revert("CEIA: no withdraw");
    }
}
