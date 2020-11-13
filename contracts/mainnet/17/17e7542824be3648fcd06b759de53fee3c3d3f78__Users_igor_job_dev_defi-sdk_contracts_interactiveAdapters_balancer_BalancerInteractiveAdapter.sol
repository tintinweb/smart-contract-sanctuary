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
import { ERC20ProtocolAdapter } from "../../adapters/ERC20ProtocolAdapter.sol";
import { InteractiveAdapter } from "../InteractiveAdapter.sol";
import { BPool } from "../../interfaces/BPool.sol";


/**
 * @title Interactive adapter for Balancer (liquidity).
 * @dev Implementation of InteractiveAdapter abstract contract.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract BalancerInteractiveAdapter is InteractiveAdapter, ERC20ProtocolAdapter {
    using SafeERC20 for ERC20;

    /**
     * @notice Deposits tokens to the Balancer pool.
     * @param tokenAmounts Array with one element - TokenAmount struct with
     * token address, token amount to be deposited, and amount type.
     * @param data ABI-encoded additional parameters:
     *     - poolAddress - pool address.
     * @return tokensToBeWithdrawn Array with one element - pool address.
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
        require(tokenAmounts.length == 1, "BIA: should be 1 tokenAmount[1]");

        address poolAddress = abi.decode(data, (address));

        tokensToBeWithdrawn = new address[](1);
        tokensToBeWithdrawn[0] = poolAddress;

        address token = tokenAmounts[0].token;
        uint256 amount = getAbsoluteAmountDeposit(tokenAmounts[0]);
        ERC20(token).safeApprove(poolAddress, amount, "BIA");

        try BPool(poolAddress).joinswapExternAmountIn(
            token,
            amount,
            0
        ) {} catch Error(string memory reason) { // solhint-disable-line no-empty-blocks
            revert(reason);
        } catch {
            revert("BIA: deposit fail");
        }
    }

    /**
     * @notice Withdraws tokens from the Balancer pool.
     * @param tokenAmounts Array with one element - TokenAmount struct with
     * Balancer token address, Balancer token amount to be redeemed, and amount type.
     * @param data ABI-encoded additional parameters:
     *     - toTokenAddress - destination token address.
     * @return tokensToBeWithdrawn Array with one element - destination token address.
     * @dev Implementation of InteractiveAdapter function.
     */
    function withdraw(
        TokenAmount[] calldata tokenAmounts,
        bytes calldata data
    )
        external
        payable
        override
        returns (address[] memory tokensToBeWithdrawn)
    {
        require(tokenAmounts.length == 1, "BIA: should be 1 tokenAmount[2]");

        address toTokenAddress = abi.decode(data, (address));

        tokensToBeWithdrawn = new address[](1);
        tokensToBeWithdrawn[0] = toTokenAddress;

        address token = tokenAmounts[0].token;
        uint256 amount = getAbsoluteAmountWithdraw(tokenAmounts[0]);

        try BPool(token).exitswapPoolAmountIn(
            toTokenAddress,
            amount,
            0
        ) {} catch Error(string memory reason) { // solhint-disable-line no-empty-blocks
            revert(reason);
        } catch {
            revert("BIA: withdraw fail");
        }
    }
}
