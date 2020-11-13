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

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import { ERC20 } from "../../shared/ERC20.sol";
import { SafeERC20 } from "../../shared/SafeERC20.sol";
import { TokenAmount } from "../../shared/Structs.sol";
import { CurveAssetAdapter } from "../../adapters/curve/CurveAssetAdapter.sol";
import { CurveInteractiveAdapter } from "./CurveInteractiveAdapter.sol";


/**
 * @dev Stableswap contract interface.
 * Only the functions required for CurveAssetInteractiveAdapter contract are added.
 * The Stableswap contract is available here
 * github.com/curvefi/curve-contract/blob/compounded/vyper/stableswap.vy.
 */
/* solhint-disable func-name-mixedcase */
interface Stableswap {
    function underlying_coins(int128) external view returns (address);
}
/* solhint-enable func-name-mixedcase */


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
    function remove_liquidity_one_coin(uint256, int128, uint256, bool) external;
}
/* solhint-enable func-name-mixedcase */


/**
 * @title Interactive adapter for Curve protocol (liquidity).
 * @dev Implementation of CurveInteractiveAdapter abstract contract.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract CurveAssetInteractiveAdapter is CurveInteractiveAdapter, CurveAssetAdapter {
    using SafeERC20 for ERC20;

    /**
     * @notice Deposits tokens to the Curve pool (pair).
     * @param tokenAmounts Array with one element - TokenAmount struct with
     * underlying token address, underlying token amount to be deposited, and amount type.
     * @param data ABI-encoded additional parameters:
     *     - crvToken - curve token address.
     * @return tokensToBeWithdrawn Array with tokens sent back.
     * @dev Implementation of InteractiveAdapter function.
     */
    function deposit(
        TokenAmount[] memory tokenAmounts,
        bytes memory data
    )
        public
        payable
        override
        returns (address[] memory tokensToBeWithdrawn)
    {
        require(tokenAmounts.length == 1, "CLIA: should be 1 tokenAmount[1]");

        address token = tokenAmounts[0].token;
        uint256 amount = getAbsoluteAmountDeposit(tokenAmounts[0]);

        address crvToken = abi.decode(data, (address));
        tokensToBeWithdrawn = new address[](1);
        tokensToBeWithdrawn[0] = crvToken;

        int128 tokenIndex = getTokenIndex(token);
        require(
            Stableswap(getSwap(crvToken)).underlying_coins(tokenIndex) == token,
            "CLIA: bad crvToken/token"
        );

        uint256 totalCoins = getTotalCoins(crvToken);
        uint256[] memory inputAmounts = new uint256[](totalCoins);
        for (uint256 i = 0; i < totalCoins; i++) {
            inputAmounts[i] = i == uint256(tokenIndex) ? amount : 0;
        }

        address callee = getDeposit(crvToken);

        ERC20(token).safeApprove(
            callee,
            amount,
            "CLIA[1]"
        );

        if (totalCoins == 2) {
            try Deposit(callee).add_liquidity(
                [inputAmounts[0], inputAmounts[1]],
                0
            ) { // solhint-disable-line no-empty-blocks
            } catch {
                revert("CLIA: deposit fail[1]");
            }
        } else if (totalCoins == 3) {
            try Deposit(callee).add_liquidity(
                [inputAmounts[0], inputAmounts[1], inputAmounts[2]],
                0
            ) { // solhint-disable-line no-empty-blocks
            } catch {
                revert("CLIA: deposit fail[2]");
            }
        } else if (totalCoins == 4) {
            try Deposit(callee).add_liquidity(
                [inputAmounts[0], inputAmounts[1], inputAmounts[2], inputAmounts[3]],
                0
            ) { // solhint-disable-line no-empty-blocks
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
    function withdraw(
        TokenAmount[] memory tokenAmounts,
        bytes memory data
    )
        public
        payable
        override
        returns (address[] memory tokensToBeWithdrawn)
    {
        require(tokenAmounts.length == 1, "CLIA: should be 1 tokenAmount[2]");
        
        address token = tokenAmounts[0].token;
        uint256 amount = getAbsoluteAmountWithdraw(tokenAmounts[0]);
        address toToken = abi.decode(data, (address));
        tokensToBeWithdrawn = new address[](1);
        tokensToBeWithdrawn[0] = toToken;

        int128 tokenIndex = getTokenIndex(toToken);
        require(
            Stableswap(getSwap(token)).underlying_coins(tokenIndex) == toToken,
            "CLIA: bad toToken/token"
        );

        address callee = getDeposit(token);

        ERC20(token).safeApprove(
            callee,
            amount,
            "CLIA[2]"
        );

        try Deposit(callee).remove_liquidity_one_coin(
            amount,
            tokenIndex,
            0,
            true
        ) { // solhint-disable-line no-empty-blocks
        } catch {
            revert("CLIA: withdraw fail");
        }
    }
}
