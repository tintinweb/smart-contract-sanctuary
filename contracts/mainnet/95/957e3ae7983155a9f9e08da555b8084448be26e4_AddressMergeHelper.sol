/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

contract AddressMergeHelper {
    function mergeAddresses(address[][] memory addressesSets)
        pure
        public
        returns (address[] memory)
    {
        bytes memory addressesPacked = new bytes(64);
        uint256 addressesSetsLength = addressesSets.length;
        assembly {
            mstore(add(addressesPacked, 0x20), 0x20)
        }
        uint256 totalNumberOfAddresses;
        for (
            uint256 addressesSetIdx = 0;
            addressesSetIdx < addressesSetsLength;
            addressesSetIdx++
        ) {
            address[] memory addressesSet = addressesSets[addressesSetIdx];
            uint256 addressesSetLength = addressesSet.length;
            totalNumberOfAddresses += addressesSetLength;
            for (
                uint256 addressIdx = 0;
                addressIdx < addressesSetLength;
                addressIdx++
            ) {
                address currentAddress = addressesSet[addressIdx];
                bytes memory spacer = new bytes(12);
                addressesPacked = abi.encodePacked(
                    addressesPacked,
                    spacer,
                    currentAddress
                );
            }
        }
        assembly {
            mstore(add(addressesPacked, 0x40), totalNumberOfAddresses)
        }
        address[] memory addressesMerged =
            abi.decode(addressesPacked, (address[]));
        return addressesMerged;
    }
}