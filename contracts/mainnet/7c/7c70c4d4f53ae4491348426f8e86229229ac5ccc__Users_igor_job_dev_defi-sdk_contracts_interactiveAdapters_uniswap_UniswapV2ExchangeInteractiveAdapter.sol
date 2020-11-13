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
import { TokenAmount, AmountType } from "../../shared/Structs.sol";
import { UniswapExchangeAdapter } from "../../adapters/uniswap/UniswapExchangeAdapter.sol";
import { InteractiveAdapter } from "../InteractiveAdapter.sol";


/**
 * @dev UniswapV2Router01 contract interface.
 * Only the functions required for UniswapV2ExchangeInteractiveAdapter contract are added.
 * The UniswapV2Router01 contract is available here
 * github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/UniswapV2Router01.sol.
 */
interface UniswapV2Router01 {
    function swapExactTokensForTokens(
        uint,
        uint,
        address[] calldata,
        address,
        uint
    ) external returns (uint[] memory);
    function swapTokensForExactTokens(
        uint,
        uint,
        address[] calldata,
        address,
        uint
    ) external returns (uint[] memory);
}

/**
 * @title Interactive adapter for Uniswap V2 protocol (exchange).
 * @dev Implementation of InteractiveAdapter abstract contract.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract UniswapV2ExchangeInteractiveAdapter is InteractiveAdapter, UniswapExchangeAdapter {
    using SafeERC20 for ERC20;

    address internal constant ROUTER = 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a;

    /**
     * @notice Exchange tokens using Uniswap pool.
     * @param tokenAmounts Array with one element - TokenAmount struct with
     * "from" token address, "from" token amount, and amount type.
     * @param data Uniswap exchange path starting from tokens[0] (ABI-encoded).
     * @return tokensToBeWithdrawn Array with one element - token address to be exchanged to.
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
        require(tokenAmounts.length == 1, "UEIA: should be 1 tokenAmount");

        address[] memory path = abi.decode(data, (address[]));
        address token = tokenAmounts[0].token;
        require(token == path[0], "UEIA: bad path[0]");
        uint256 amount = getAbsoluteAmountDeposit(tokenAmounts[0]);

        tokensToBeWithdrawn = new address[](1);
        tokensToBeWithdrawn[0] = path[path.length - 1];

        ERC20(token).safeApprove(ROUTER, amount, "UEIA[1]");

        try UniswapV2Router01(ROUTER).swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            now
        ) returns (uint256[] memory) { // solhint-disable-line no-empty-blocks
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("UEIA: deposit fail");
        }
    }

    /**
     * @notice Exchange tokens using Uniswap pool.
     * @param tokenAmounts Array with one element - TokenAmount struct with
     * "to" token address, "to" token amount, and amount type (must be absolute).
     * @param data Uniswap exchange path ending with tokens[0] (ABI-encoded).
     * @return tokensToBeWithdrawn Array with one element - token address to be changed to.
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
        require(tokenAmounts.length == 1, "UEIA: should be 1 tokenAmount");
        require(tokenAmounts[0].amountType == AmountType.Absolute, "UEIA: bad type");

        address[] memory path = abi.decode(data, (address[]));
        address token = tokenAmounts[0].token;
        require(token == path[path.length - 1], "UEIA: bad path[path.length - 1]");
        uint256 amount = tokenAmounts[0].amount;

        tokensToBeWithdrawn = new address[](1);
        tokensToBeWithdrawn[0] = token;

        ERC20(path[0]).safeApprove(ROUTER, ERC20(path[0]).balanceOf(address(this)), "UEIA[2]");

        try UniswapV2Router01(ROUTER).swapTokensForExactTokens(
            amount,
            type(uint256).max,
            path,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            now
        ) returns (uint256[] memory) { //solhint-disable-line no-empty-blocks
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("UEIA: withdraw fail");
        }

        ERC20(path[0]).safeApprove(ROUTER, 0, "UEIA[3]");
    }
}
