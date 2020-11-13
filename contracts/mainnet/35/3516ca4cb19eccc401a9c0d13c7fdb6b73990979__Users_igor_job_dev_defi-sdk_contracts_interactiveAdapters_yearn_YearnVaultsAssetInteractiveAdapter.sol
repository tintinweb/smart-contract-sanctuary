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
import { InteractiveAdapter } from "../InteractiveAdapter.sol";
import { ERC20ProtocolAdapter } from "../../adapters/ERC20ProtocolAdapter.sol";
import { YVault } from "../../interfaces/YVault.sol";


/**
 * @title Interactive adapter for Yearn Vaults.
 * @dev Implementation of InteractiveAdapter abstract contract.
 */
contract YearnVaultsAssetInteractiveAdapter is InteractiveAdapter, ERC20ProtocolAdapter {
    using SafeERC20 for ERC20;

    /**
     * @notice Deposits tokens to the Yearn Vault.
     * @param tokenAmounts Array with one element - TokenAmount struct with
     * underlying token address, underlying token amount to be deposited, and amount type.
     * @param data ABI-encoded additional parameters:
     *     - yVaultAddress - yVault address.
     * @return tokensToBeWithdrawn Array with ane element - yVault.
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
        require(tokenAmounts.length == 1, "YVAIA: should be 1 tokenAmount[1]");

        address yVaultAddress = abi.decode(data, (address));

        address token = tokenAmounts[0].token;
        uint256 amount = getAbsoluteAmountDeposit(tokenAmounts[0]);

        tokensToBeWithdrawn = new address[](1);
        tokensToBeWithdrawn[0] = yVaultAddress;

        ERC20(token).safeApprove(yVaultAddress, amount, "YVAIA");
        // solhint-disable-next-line no-empty-blocks
        try YVault(yVaultAddress).deposit(amount) {
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("YVAIA: deposit fail");
        }
    }

    /**
     * @notice Withdraws tokens from the Yearn Vault.
     * @param tokenAmounts Array with one element - TokenAmount struct with
     * yVault address, yVault amount to be redeemed, and amount type.
     * @return tokensToBeWithdrawn Array with one element - underlying token.
     * @dev Implementation of InteractiveAdapter function.
     */
    function withdraw(
        TokenAmount[] calldata tokenAmounts,
        bytes calldata
    )
        external
        payable
        override
        returns (address[] memory tokensToBeWithdrawn)
    {
        require(tokenAmounts.length == 1, "YVAIA: should be 1 tokenAmount[2]");

        address token = tokenAmounts[0].token;
        uint256 amount = getAbsoluteAmountWithdraw(tokenAmounts[0]);

        tokensToBeWithdrawn = new address[](1);
        tokensToBeWithdrawn[0] = YVault(token).token();

        // solhint-disable-next-line no-empty-blocks
        try YVault(token).withdraw(amount) {
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("YVAIA: withdraw fail");
        }
    }
}
