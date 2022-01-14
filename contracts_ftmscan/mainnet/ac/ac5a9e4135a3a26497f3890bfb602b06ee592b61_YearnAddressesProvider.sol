// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./Strings.sol";

contract YearnAddressesProvider is Ownable {
    mapping(uint256 => address) addressMap;
    mapping(uint256 => string) addressIdMap;
    uint256 addressesLength;

    struct AddressMetadata {
        string addrId;
        address addr;
    }

    function setAddress(AddressMetadata memory addressMetadata)
        public
        onlyOwner
    {
        string memory addressId = addressMetadata.addrId;
        address addr = addressMetadata.addr;
        uint256 upsertPosition = addressesLength;
        int256 addressPosition = addressPositionById(addressId);
        if (addressPosition >= 0) {
            upsertPosition = uint256(addressPosition);
        } else {
            addressIdMap[upsertPosition] = addressId;
            addressesLength++;
        }
        addressMap[upsertPosition] = addr;
    }

    function setAddresses(AddressMetadata[] memory _addressesMetadata)
        public
        onlyOwner
    {
        for (
            uint256 addressMetadataIdx;
            addressMetadataIdx < _addressesMetadata.length;
            addressMetadataIdx++
        ) {
            AddressMetadata memory addressMetadata = _addressesMetadata[
                addressMetadataIdx
            ];
            setAddress(addressMetadata);
        }
    }

    function addressPositionById(string memory addressId)
        public
        view
        returns (int256)
    {
        for (uint256 addressIdx; addressIdx < addressesLength; addressIdx++) {
            string memory currentAddressId = addressIdMap[addressIdx];
            if (Strings.stringsEqual(addressId, currentAddressId)) {
                return int256(addressIdx);
            }
        }
        return -1;
    }

    function addressById(string memory addressId)
        external
        view
        returns (address)
    {
        return addressMap[uint256(addressPositionById(addressId))];
    }

    function addresses() external view returns (address[] memory) {
        address[] memory _addresses = new address[](addressesLength);
        for (uint256 addressIdx; addressIdx < addressesLength; addressIdx++) {
            _addresses[addressIdx] = addressMap[addressIdx];
        }
        return _addresses;
    }

    function addressesIds() external view returns (string[] memory) {
        string[] memory _addressesIds = new string[](addressesLength);
        for (uint256 addressIdx; addressIdx < addressesLength; addressIdx++) {
            _addressesIds[addressIdx] = addressIdMap[addressIdx];
        }
        return _addressesIds;
    }

    function addressesMetadata()
        external
        view
        returns (AddressMetadata[] memory)
    {
        AddressMetadata[] memory _addressesMetadata = new AddressMetadata[](
            addressesLength
        );
        for (uint256 addressIdx; addressIdx < addressesLength; addressIdx++) {
            _addressesMetadata[addressIdx] = AddressMetadata({
                addrId: addressIdMap[addressIdx],
                addr: addressMap[addressIdx]
            });
        }
        return _addressesMetadata;
    }

    function addressesMetadataByIdStartsWith(string memory addressIdSubstring)
        external
        view
        returns (AddressMetadata[] memory)
    {
        AddressMetadata[] memory _addressesMetadata = new AddressMetadata[](
            addressesLength
        );
        uint256 _addressesLength;
        for (uint256 addressIdx; addressIdx < addressesLength; addressIdx++) {
            string memory addressId = addressIdMap[addressIdx];
            bool foundMatch = Strings.stringStartsWith(
                addressId,
                addressIdSubstring
            );
            if (foundMatch) {
                _addressesMetadata[_addressesLength] = AddressMetadata({
                    addrId: addressIdMap[addressIdx],
                    addr: addressMap[addressIdx]
                });
                _addressesLength++;
            }
        }
        bytes memory encodedAddresses = abi.encode(_addressesMetadata);
        assembly {
            mstore(add(encodedAddresses, 0x40), _addressesLength)
        }
        AddressMetadata[] memory filteredAddresses = abi.decode(
            encodedAddresses,
            (AddressMetadata[])
        );
        return filteredAddresses;
    }
}