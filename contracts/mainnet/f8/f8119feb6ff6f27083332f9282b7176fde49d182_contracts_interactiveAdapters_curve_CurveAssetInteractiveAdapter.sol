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

pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

import { ERC20 } from "../../shared/ERC20.sol";
import { SafeERC20 } from "../../shared/SafeERC20.sol";
import { TokenAmount } from "../../shared/Structs.sol";
import { ERC20ProtocolAdapter } from "../../adapters/ERC20ProtocolAdapter.sol";
import { CurveRegistry, PoolInfo } from "../../adapters/curve/CurveRegistry.sol";
import { InteractiveAdapter } from "../InteractiveAdapter.sol";
import { Stableswap } from "../../interfaces/Stableswap.sol";

/**
 * @dev Deposit contract interface.
 * Only the functions required for CurveAssetInteractiveAdapter contract are added.
 * The Deposit contract is available here
 * github.com/curvefi/curve-contract/blob/compounded/vyper/deposit.vy.
 */
/* solhint-disable func-name-mixedcase */
interface Deposit {
    function add_liquidity(uint256[2] calldata, uint256) external;

    function add_liquidity(uint256[3] calldata, uint256) external;

    function add_liquidity(uint256[4] calldata, uint256) external;

    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    ) external;
}

/* solhint-enable func-name-mixedcase */

/**
 * @title Interactive adapter for Curve protocol (liquidity).
 * @dev Implementation of CurveInteractiveAdapter abstract contract.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract CurveAssetInteractiveAdapter is InteractiveAdapter, ERC20ProtocolAdapter {
    using SafeERC20 for ERC20;

    address internal constant REGISTRY = 0x3fb5Cd4b0603C3D5828D3b5658B10C9CB81aa922;

    /**
     * @notice Deposits tokens to the Curve pool (pair).
     * @param tokenAmounts Array with one element - TokenAmount struct with
     * underlying token address, underlying token amount to be deposited, and amount type.
     * @param data ABI-encoded additional parameters:
     *     - crvToken - curve token address.
     * @return tokensToBeWithdrawn Array with tokens sent back.
     * @dev Implementation of InteractiveAdapter function.
     */
    function deposit(TokenAmount[] calldata tokenAmounts, bytes calldata data)
        external
        payable
        override
        returns (address[] memory tokensToBeWithdrawn)
    {
        require(tokenAmounts.length == 1, "CLIA: should be 1 tokenAmount[1]");

        address token = tokenAmounts[0].token;
        uint256 amount = getAbsoluteAmountDeposit(tokenAmounts[0]);

        (address crvToken, uint256 tokenIndex) = abi.decode(data, (address, uint256));
        tokensToBeWithdrawn = new address[](1);
        tokensToBeWithdrawn[0] = crvToken;

        PoolInfo memory poolInfo = CurveRegistry(REGISTRY).getPoolInfo(crvToken);
        uint256 totalCoins = poolInfo.totalCoins;
        address callee = poolInfo.deposit;

        uint256[] memory inputAmounts = new uint256[](totalCoins);
        for (uint256 i = 0; i < totalCoins; i++) {
            inputAmounts[i] = i == uint256(tokenIndex) ? amount : 0;
        }

        uint256 allowance = ERC20(token).allowance(address(this), callee);

        if (allowance < amount) {
            if (allowance > 0) {
                ERC20(token).safeApprove(callee, 0, "CLIA[1]");
            }
            ERC20(token).safeApprove(callee, type(uint256).max, "CLIA[2]");
        }

        if (totalCoins == 2) {
            // solhint-disable-next-line no-empty-blocks
            try Deposit(callee).add_liquidity([inputAmounts[0], inputAmounts[1]], 0)  {} catch {
                revert("CLIA: deposit fail[1]");
            }
        } else if (totalCoins == 3) {
            try
                Deposit(callee).add_liquidity(
                    [inputAmounts[0], inputAmounts[1], inputAmounts[2]],
                    0
                )
             // solhint-disable-next-line no-empty-blocks
            {

            } catch {
                revert("CLIA: deposit fail[2]");
            }
        } else if (totalCoins == 4) {
            try
                Deposit(callee).add_liquidity(
                    [inputAmounts[0], inputAmounts[1], inputAmounts[2], inputAmounts[3]],
                    0
                )
             // solhint-disable-next-line no-empty-blocks
            {

            } catch {
                revert("CLIA: deposit fail[3]");
            }
        }
    }

    /**
     * @notice Withdraws tokens from the Curve pool.
     * @param tokenAmounts Array with one element - TokenAmount struct with
     * Curve token address, Curve token amount to be redeemed, and amount type.
     * @param data ABI-encoded additional parameters:
     *     - toToken - destination token address (one of those used in pool).
     * @return tokensToBeWithdrawn Array with one element - destination token address.
     * @dev Implementation of InteractiveAdapter function.
     */
    function withdraw(TokenAmount[] calldata tokenAmounts, bytes calldata data)
        external
        payable
        override
        returns (address[] memory tokensToBeWithdrawn)
    {
        require(tokenAmounts.length == 1, "CLIA: should be 1 tokenAmount[2]");

        address token = tokenAmounts[0].token;
        uint256 amount = getAbsoluteAmountWithdraw(tokenAmounts[0]);
        (address toToken, int128 tokenIndex) = abi.decode(data, (address, int128));

        tokensToBeWithdrawn = new address[](1);
        tokensToBeWithdrawn[0] = toToken;

        PoolInfo memory poolInfo = CurveRegistry(REGISTRY).getPoolInfo(token);
        address callee = poolInfo.deposit;

        uint256 allowance = ERC20(token).allowance(address(this), callee);

        if (allowance < amount) {
            if (allowance > 0) {
                ERC20(token).safeApprove(callee, 0, "CLIA[3]");
            }
            ERC20(token).safeApprove(callee, type(uint256).max, "CLIA[4]");
        }

        // solhint-disable-next-line no-empty-blocks
        try Deposit(callee).remove_liquidity_one_coin(amount, tokenIndex, 0)  {} catch {
            revert("CLIA: withdraw fail");
        }
    }
}
