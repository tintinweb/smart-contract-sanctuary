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

import { AmountType } from "../../shared/Structs.sol";
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

    address internal constant WETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;

    /**
     * @notice Wraps Ether in Wrapped Ether.
     * @param amounts Array with one element - ETH amount to be converted to WETH.
     * @param amountTypes Array with one element - amount type.
     * @return tokensToBeWithdrawn Array with one element - WETH address.
     * @dev Implementation of InteractiveAdapter function.
     */
    function deposit(
        address[] memory,
        uint256[] memory amounts,
        AmountType[] memory amountTypes,
        bytes memory
    )
        public
        payable
        override
        returns (address[] memory tokensToBeWithdrawn)
    {
        uint256 amount = getAbsoluteAmountDeposit(ETH, amounts[0], amountTypes[0]);

        tokensToBeWithdrawn = new address[](1);
        tokensToBeWithdrawn[0] = WETH;

        try WETH9(WETH).deposit{value: amount}() { // solhint-disable-line no-empty-blocks
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("WIA: deposit fail!");
        }
    }

    /**
     * @notice Unwraps Ether from Wrapped Ether.
     * @param amounts Array with one element - WETH amount to be converted to ETH.
     * @param amountTypes Array with one element - amount type.
     * @return tokensToBeWithdrawn Array with one element - 0xEeee...EEeE constant.
     * @dev Implementation of InteractiveAdapter function.
     */
    function withdraw(
        address[] memory,
        uint256[] memory amounts,
        AmountType[] memory amountTypes,
        bytes memory
    )
        public
        payable
        override
        returns (address[] memory tokensToBeWithdrawn)
    {
        uint256 amount = getAbsoluteAmountWithdraw(WETH, amounts[0], amountTypes[0]);

        tokensToBeWithdrawn = new address[](1);
        tokensToBeWithdrawn[0] = ETH;

        try WETH9(WETH).withdraw(amount) { // solhint-disable-line no-empty-blocks
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("WIA: withdraw fail!");
        }
    }
}
