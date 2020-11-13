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

import { AdapterBalance, AbsoluteTokenAmount } from "../shared/Structs.sol";
import { ERC20 } from "../shared/ERC20.sol";
import { Ownable } from "./Ownable.sol";
import { ProtocolAdapterManager } from "./ProtocolAdapterManager.sol";
import { ProtocolAdapter } from "../adapters/ProtocolAdapter.sol";


/**
 * @title Registry for protocol adapters.
 * @notice getBalances() function implements the main functionality.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract ProtocolAdapterRegistry is Ownable, ProtocolAdapterManager {

    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @param account Address of the account.
     * @return AdapterBalance array by the given account.
     * @notice Zero values are filtered out!
     */
    function getBalances(
        address account
    )
        external
        view
        returns (AdapterBalance[] memory)
    {
        // Get balances for all the adapters
        AdapterBalance[] memory adapterBalances = getAdapterBalances(
            _protocolAdapterNames,
            account
        );

        // Declare temp variable and counters
        AbsoluteTokenAmount[] memory currentAbsoluteTokenAmounts;
        AbsoluteTokenAmount[] memory nonZeroAbsoluteTokenAmounts;
        uint256 nonZeroAdaptersCounter;
        uint256[] memory nonZeroTokensCounters;
        uint256 adapterBalancesLength;
        uint256 currentAbsoluteTokenAmountsLength;

        // Reset counters
        nonZeroTokensCounters = new uint256[](adapterBalances.length);
        nonZeroAdaptersCounter = 0;
        adapterBalancesLength = adapterBalances.length;

        // Iterate over all the adapters' balances
        for (uint256 i = 0; i < adapterBalancesLength; i++) {
            // Fill temp variable
            currentAbsoluteTokenAmounts = adapterBalances[i].absoluteTokenAmounts;

            // Reset counter
            nonZeroTokensCounters[i] = 0;
            currentAbsoluteTokenAmountsLength = currentAbsoluteTokenAmounts.length;

            // Increment if token balance is positive
            for (uint256 j = 0; j < currentAbsoluteTokenAmountsLength; j++) {
                if (currentAbsoluteTokenAmounts[j].amount > 0) {
                    nonZeroTokensCounters[i]++;
                }
            }

            // Increment if at least one positive token balance
            if (nonZeroTokensCounters[i] > 0) {
                nonZeroAdaptersCounter++;
            }
        }

        // Declare resulting variable
        AdapterBalance[] memory nonZeroAdapterBalances;

        // Reset resulting variable and counter
        nonZeroAdapterBalances = new AdapterBalance[](nonZeroAdaptersCounter);
        nonZeroAdaptersCounter = 0;

        // Iterate over all the adapters' balances
        for (uint256 i = 0; i < adapterBalancesLength; i++) {
            // Skip if no positive token balances
            if (nonZeroTokensCounters[i] == 0) {
                continue;
            }

            // Fill temp variable
            currentAbsoluteTokenAmounts = adapterBalances[i].absoluteTokenAmounts;

            // Reset temp variable and counter
            nonZeroAbsoluteTokenAmounts = new AbsoluteTokenAmount[](nonZeroTokensCounters[i]);
            nonZeroTokensCounters[i] = 0;
            currentAbsoluteTokenAmountsLength = currentAbsoluteTokenAmounts.length;

            for (uint256 j = 0; j < currentAbsoluteTokenAmountsLength; j++) {
                // Skip if balance is not positive
                if (currentAbsoluteTokenAmounts[j].amount == 0) {
                    continue;
                }

                // Else fill temp variable
                nonZeroAbsoluteTokenAmounts[nonZeroTokensCounters[i]] = currentAbsoluteTokenAmounts[j];

                // Increment counter
                nonZeroTokensCounters[i]++;
            }

            // Fill resulting variable
            nonZeroAdapterBalances[nonZeroAdaptersCounter] = AdapterBalance({
                protocolAdapterName: adapterBalances[i].protocolAdapterName,
                absoluteTokenAmounts: nonZeroAbsoluteTokenAmounts
            });

            // Increment counter
            nonZeroAdaptersCounter++;
        }

        return nonZeroAdapterBalances;
    }

    /**
     * @param protocolAdapterNames Array of the protocol adapters' names.
     * @param account Address of the account.
     * @return AdapterBalance array by the given parameters.
     */
    function getAdapterBalances(
        bytes32[] memory protocolAdapterNames,
        address account
    )
        public
        view
        returns (AdapterBalance[] memory)
    {
        uint256 length = protocolAdapterNames.length;
        AdapterBalance[] memory adapterBalances = new AdapterBalance[](length);

        for (uint256 i = 0; i < length; i++) {
            adapterBalances[i] = getAdapterBalance(
                protocolAdapterNames[i],
                _protocolAdapterSupportedTokens[protocolAdapterNames[i]],
                account
            );
        }

        return adapterBalances;
    }

    /**
     * @param protocolAdapterName Protocol adapter's Name.
     * @param tokens Array of tokens' addresses.
     * @param account Address of the account.
     * @return AdapterBalance array by the given parameters.
     */
    function getAdapterBalance(
        bytes32 protocolAdapterName,
        address[] memory tokens,
        address account
    )
        public
        view
        returns (AdapterBalance memory)
    {
        address adapter = _protocolAdapterAddress[protocolAdapterName];
        require(adapter != address(0), "AR: bad protocolAdapterName");

        uint256 length = tokens.length;
        AbsoluteTokenAmount[] memory absoluteTokenAmounts = new AbsoluteTokenAmount[](tokens.length);

        for (uint256 i = 0; i < length; i++) {
            try ProtocolAdapter(adapter).getBalance(
                tokens[i],
                account
            ) returns (uint256 amount) {
                absoluteTokenAmounts[i] = AbsoluteTokenAmount({
                    token: tokens[i],
                    amount: amount
                });
            } catch {
                absoluteTokenAmounts[i] = AbsoluteTokenAmount({
                    token: tokens[i],
                    amount: 0
                });
            }
        }

        return AdapterBalance({
            protocolAdapterName: protocolAdapterName,
            absoluteTokenAmounts: absoluteTokenAmounts
        });
    }
}
