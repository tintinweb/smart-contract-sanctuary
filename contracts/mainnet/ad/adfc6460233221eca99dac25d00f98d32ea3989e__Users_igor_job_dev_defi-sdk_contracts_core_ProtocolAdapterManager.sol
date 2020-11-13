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

import { Ownable } from "./Ownable.sol";


/**
 * @title ProtocolAdapterRegistry part responsible for protocol adapters management.
 * @dev Base contract for ProtocolAdapterRegistry.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
abstract contract ProtocolAdapterManager is Ownable {

    // Protocol adapters' names
    bytes32[] internal _protocolAdapterNames;
    // Protocol adapter's name => protocol adapter's address
    mapping (bytes32 => address) internal _protocolAdapterAddress;
    // protocol adapter's name => protocol adapter's supported tokens
    mapping (bytes32 => address[]) internal _protocolAdapterSupportedTokens;

    /**
     * @notice Adds protocol adapters.
     * The function is callable only by the owner.
     * @param newProtocolAdapterNames Array of the new protocol adapters' names.
     * @param newProtocolAdapterAddresses Array of the new protocol adapters' addresses.
     * @param newSupportedTokens Array of the new protocol adapters' supported tokens.
     */
    function addProtocolAdapters(
        bytes32[] calldata newProtocolAdapterNames,
        address[] calldata newProtocolAdapterAddresses,
        address[][] calldata newSupportedTokens
    )
        external
        onlyOwner
    {
        uint256 length = newProtocolAdapterNames.length;
        require(length != 0, "PAM: empty[1]");
        require(length == newProtocolAdapterAddresses.length, "PAM: lengths differ[1]");
        require(length == newSupportedTokens.length, "PAM: lengths differ[2]");

        for (uint256 i = 0; i < length; i++) {
            addProtocolAdapter(
                newProtocolAdapterNames[i],
                newProtocolAdapterAddresses[i],
                newSupportedTokens[i]
            );
        }
    }

    /**
     * @notice Removes protocol adapters.
     * The function is callable only by the owner.
     * @param protocolAdapterNames Array of the protocol adapters' names.
     */
    function removeProtocolAdapters(
        bytes32[] calldata protocolAdapterNames
    )
        external
        onlyOwner
    {
        uint256 length = protocolAdapterNames.length;
        require(length != 0, "PAM: empty[2]");

        for (uint256 i = 0; i < length; i++) {
            removeProtocolAdapter(protocolAdapterNames[i]);
        }
    }

    /**
     * @notice Updates protocol adapters.
     * The function is callable only by the owner.
     * @param protocolAdapterNames Array of the protocol adapters' names.
     * @param newProtocolAdapterAddresses Array of the protocol adapters' new addresses.
     * @param newSupportedTokens Array of the protocol adapters' new supported tokens.
     */
    function updateProtocolAdapters(
        bytes32[] calldata protocolAdapterNames,
        address[] calldata newProtocolAdapterAddresses,
        address[][] calldata newSupportedTokens
    )
        external
        onlyOwner
    {
        uint256 length = protocolAdapterNames.length;
        require(length != 0, "PAM: empty[3]");
        require(length == newProtocolAdapterAddresses.length, "PAM: lengths differ[3]");
        require(length == newSupportedTokens.length, "PAM: lengths differ[4]");

        for (uint256 i = 0; i < length; i++) {
            updateProtocolAdapter(
                protocolAdapterNames[i],
                newProtocolAdapterAddresses[i],
                newSupportedTokens[i]
            );
        }
    }

    /**
     * @return Array of protocol adapters' names.
     */
    function getProtocolAdapterNames()
        external
        view
        returns (bytes32[] memory)
    {
        return _protocolAdapterNames;
    }

    /**
     * @param protocolAdapterName Name of the protocol adapter.
     * @return Address of protocol adapter.
     */
    function getProtocolAdapterAddress(
        bytes32 protocolAdapterName
    )
        external
        view
        returns (address)
    {
        return _protocolAdapterAddress[protocolAdapterName];
    }

    /**
     * @param protocolAdapterName Name of the protocol adapter.
     * @return Array of protocol adapter's supported tokens.
     */
    function getSupportedTokens(
        bytes32 protocolAdapterName
    )
        external
        view
        returns (address[] memory)
    {
        return _protocolAdapterSupportedTokens[protocolAdapterName];
    }

    /**
     * @notice Adds a protocol adapter.
     * @param newProtocolAdapterName New protocol adapter's protocolAdapterName.
     * @param newAddress New protocol adapter's address.
     * @param newSupportedTokens Array of the new protocol adapter's supported tokens.
     * Empty array is always allowed.
     */
    function addProtocolAdapter(
        bytes32 newProtocolAdapterName,
        address newAddress,
        address[] calldata newSupportedTokens
    )
        internal
    {
        require(newProtocolAdapterName != bytes32(0), "PAM: zero[1]");
        require(newAddress != address(0), "PAM: zero[2]");
        require(_protocolAdapterAddress[newProtocolAdapterName] == address(0), "PAM: exists");

        _protocolAdapterNames.push(newProtocolAdapterName);
        _protocolAdapterAddress[newProtocolAdapterName] = newAddress;
        _protocolAdapterSupportedTokens[newProtocolAdapterName] = newSupportedTokens;
    }

    /**
     * @notice Removes a protocol adapter.
     * @param protocolAdapterName Protocol adapter's protocolAdapterName.
     */
    function removeProtocolAdapter(
        bytes32 protocolAdapterName
    )
        internal
    {
        require(_protocolAdapterAddress[protocolAdapterName] != address(0), "PAM: does not exist[1]");

        uint256 length = _protocolAdapterNames.length;
        uint256 index = 0;
        while (_protocolAdapterNames[index] != protocolAdapterName) {
            index++;
        }

        if (index != length - 1) {
            _protocolAdapterNames[index] = _protocolAdapterNames[length - 1];
        }

        _protocolAdapterNames.pop();

        delete _protocolAdapterAddress[protocolAdapterName];
        delete _protocolAdapterSupportedTokens[protocolAdapterName];
    }

    /**
     * @notice Updates a protocol adapter.
     * @param protocolAdapterName Protocol adapter's protocolAdapterName.
     * @param newProtocolAdapterAddress Protocol adapter's new address.
     * @param newSupportedTokens Array of the protocol adapter's new supported tokens.
     * Empty array is always allowed.
     */
    function updateProtocolAdapter(
        bytes32 protocolAdapterName,
        address newProtocolAdapterAddress,
        address[] calldata newSupportedTokens
    )
        internal
    {
        address oldProtocolAdapterAddress = _protocolAdapterAddress[protocolAdapterName];
        require(oldProtocolAdapterAddress != address(0), "PAM: does not exist[2]");
        require(newProtocolAdapterAddress != address(0), "PAM: zero[3]");

        if (oldProtocolAdapterAddress == newProtocolAdapterAddress) {
            _protocolAdapterSupportedTokens[protocolAdapterName] = newSupportedTokens;
        } else {
            _protocolAdapterAddress[protocolAdapterName] = newProtocolAdapterAddress;
            _protocolAdapterSupportedTokens[protocolAdapterName] = newSupportedTokens;
        }
    }
}
