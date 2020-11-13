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

import { TokenAmount } from "../../shared/Structs.sol";
import { WethAdapter } from "../../adapters/weth/WethAdapter.sol";
import { InteractiveAdapter } from "../InteractiveAdapter.sol";


/**
 * @dev WETH9 contract interface.
 * Only the functions required for WethInteractiveAdapter contract are added.
 * The WETH9 contract is available here
 * github.com/0xProject/0x-monorepo/blob/development/contracts/erc20/contracts/src/WETH9.sol.
 */
interface WETH9 {
    function deposit() external payable;
    function withdraw(uint256) external;
}


/**
 * @title Interactive adapter for Wrapped Ether.
 * @dev Implementation of InteractiveAdapter abstract contract.
 */
contract WethInteractiveAdapter is InteractiveAdapter, WethAdapter {

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /**
     * @notice Wraps Ether in Wrapped Ether.
     * @param tokenAmounts Array with one element - TokenAmount struct with
     * ETH address (0xEeee...EEeE), ETH amount to be deposited, and amount type.
     * @return tokensToBeWithdrawn Array with one element - WETH token address.
     * @dev Implementation of InteractiveAdapter function.
     */
    function deposit(
        TokenAmount[] memory tokenAmounts,
        bytes memory
    )
        public
        payable
        override
        returns (address[] memory tokensToBeWithdrawn)
    {
        require(tokenAmounts.length == 1, "WIA: should be 1 tokenAmount");
        require(tokenAmounts[0].token == ETH, "WIA: should be ETH");

        uint256 amount = getAbsoluteAmountDeposit(tokenAmounts[0]);

        tokensToBeWithdrawn = new address[](1);
        tokensToBeWithdrawn[0] = WETH;

        try WETH9(WETH).deposit{value: amount}() { // solhint-disable-line no-empty-blocks
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("WIA: deposit fail");
        }
    }

    /**
     * @notice Unwraps Ether from Wrapped Ether.
     * @param tokenAmounts Array with one element - TokenAmount struct with
     * WETH token address, WETH token amount to be redeemed, and amount type.
     * @return tokensToBeWithdrawn Array with one element - ETH address (0xEeee...EEeE).
     * @dev Implementation of InteractiveAdapter function.
     */
    function withdraw(
        TokenAmount[] memory tokenAmounts,
        bytes memory
    )
        public
        payable
        override
        returns (address[] memory tokensToBeWithdrawn)
    {
        require(tokenAmounts.length == 1, "WIA: should be 1 tokenAmount");
        require(tokenAmounts[0].token == WETH, "WIA: should be WETH");

        uint256 amount = getAbsoluteAmountWithdraw(tokenAmounts[0]);

        tokensToBeWithdrawn = new address[](1);
        tokensToBeWithdrawn[0] = ETH;

        try WETH9(WETH).withdraw(amount) { // solhint-disable-line no-empty-blocks
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("WIA: withdraw fail");
        }
    }
}
