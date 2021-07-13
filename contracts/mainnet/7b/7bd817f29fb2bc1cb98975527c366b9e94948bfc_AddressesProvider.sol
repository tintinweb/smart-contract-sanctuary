/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

pragma solidity 0.8.6;

contract AddressesProvider {
    struct AddressMetadata {
        address addr;
        string addressId;
        string addressTypeId;
        uint256 version;
        uint256 lastModified;
    }
    
    struct AddressMetadataParams {
        address addr;
        string addressId;
        string addressTypeId;
    }
    
    address public ownerAddress;
    mapping(uint256 => AddressMetadata) public addressMetadataById;
    mapping(string => bool) internal addressIdExists;
    mapping(string => uint256) public addressIdPosition;
    mapping(string => bool) internal addressTypeIdExists;
    uint256 addressesMetadataLength;

    constructor() {
        ownerAddress = msg.sender;
    }
    
    function setAddressMetadata(AddressMetadataParams memory addressMetadataParams) public {
        require(msg.sender == ownerAddress, "Caller is not owner");
        address addr = addressMetadataParams.addr;
        string memory addressId = addressMetadataParams.addressId;
        string memory addressTypeId = addressMetadataParams.addressTypeId;

        uint256 upsertPosition = addressesMetadataLength;
        uint256 version = 1;
        if (addressIdExists[addressId]) {
            upsertPosition = addressIdPosition[addressId];
            version = addressMetadataById[upsertPosition].version + 1;
        } else {
            addressIdExists[addressId] = true;
            addressIdPosition[addressId] = addressesMetadataLength;
            addressesMetadataLength++;
        }
        addressMetadataById[upsertPosition] = AddressMetadata({
           addr: addr,
           addressId: addressId,
           addressTypeId: addressTypeId,
           version: version,
           lastModified: block.timestamp
        });
        addressTypeIdExists[addressTypeId] = true;
        if (addressIdExists[addressId] == false) {
            addressesMetadataLength++;
        }
    }
    
    function setAddressesMetadata(AddressMetadataParams[] memory addressesMetadataParams) external {
        require(msg.sender == ownerAddress, "Caller is not owner");
        for (uint256 addressMetadataParamsIdx; addressMetadataParamsIdx < addressesMetadataParams.length; addressMetadataParamsIdx++) {
            AddressMetadataParams memory addressMetadataParams = addressesMetadataParams[addressMetadataParamsIdx];
            setAddressMetadata(addressMetadataParams);
        }
    }
    
    function addressesMetadata() external view returns (AddressMetadata[] memory) {
        AddressMetadata[] memory _addressesMetadata = new AddressMetadata[](addressesMetadataLength);
        for (uint256 addressMetadataIdx; addressMetadataIdx < addressesMetadataLength; addressMetadataIdx++) {
            AddressMetadata memory addressMetadata = addressMetadataById[addressMetadataIdx];
            _addressesMetadata[addressMetadataIdx] = addressMetadata;
        }
        return _addressesMetadata;
    }
    
    function addressMetadataByName(string memory addressId) external view returns (AddressMetadata memory) {
        for (uint256 addressMetadataIdx; addressMetadataIdx < addressesMetadataLength; addressMetadataIdx++) {
            AddressMetadata memory addressMetadata = addressMetadataById[addressMetadataIdx];
            if (stringsEqual(addressId, addressMetadata.addressId)) {
                return addressMetadata;
            }
        }
        return AddressMetadata({
            addr: address(0),
            addressId: "",
            addressTypeId: "",
            version: 0,
            lastModified: 0
        });
    }

    
    function addresses() external view returns (address[] memory) {
        address[] memory _addresses = new address[](addressesMetadataLength);
        for (uint256 addressMetadataIdx; addressMetadataIdx < addressesMetadataLength; addressMetadataIdx++) {
            AddressMetadata memory addressMetadata = addressMetadataById[addressMetadataIdx];
            _addresses[addressMetadataIdx] = addressMetadata.addr;
        }
        return _addresses;
    }
    
    function addressById(string memory addressId) external view returns (address) {
        for (uint256 addressMetadataIdx; addressMetadataIdx < addressesMetadataLength; addressMetadataIdx++) {
            AddressMetadata memory addressMetadata = addressMetadataById[addressMetadataIdx];
            if (stringsEqual(addressId, addressMetadata.addressId)) {
                return addressMetadata.addr;
            }
        }
        return address(0);
    }
    
    function addressesIds() external view returns (string[] memory) {
        string[] memory _addressesIds = new string[](addressesMetadataLength);
        for (uint256 addressMetadataIdx; addressMetadataIdx < addressesMetadataLength; addressMetadataIdx++) {
            AddressMetadata memory addressMetadata = addressMetadataById[addressMetadataIdx];
            _addressesIds[addressMetadataIdx] = addressMetadata.addressId;
        }
        return _addressesIds;
    }
    
    function addressesTypeIds() external view returns (string[] memory) {
        string[] memory _addressTypeIds = new string[](addressesMetadataLength);
        uint256 addressTypeIdsLength;
        for (uint256 addressMetadataIdx; addressMetadataIdx < addressesMetadataLength; addressMetadataIdx++) {
            AddressMetadata memory addressMetadata = addressMetadataById[addressMetadataIdx];
            string memory addressTypeId = addressMetadata.addressTypeId;
            // TODO: Implement using bloom filter instead..
            bool addressTypeIdFound;
            for (uint256 addressTypeIdIdx; addressTypeIdIdx < addressTypeIdsLength; addressTypeIdIdx++) {
                string memory currentAddressTypeId = _addressTypeIds[addressTypeIdIdx];
                if (stringsEqual(addressTypeId, currentAddressTypeId)) {
                    addressTypeIdFound = true;
                    break;
                }
            }
            if (!addressTypeIdFound) {
                _addressTypeIds[addressTypeIdsLength] = addressTypeId;
                addressTypeIdsLength++;
            }
        }
        bytes memory encodedTypeIds = abi.encode(_addressTypeIds);
        assembly {
            mstore(add(encodedTypeIds, 0x40), addressTypeIdsLength)
        }
        string[] memory filteredTypeIds =
            abi.decode(encodedTypeIds, (string[]));
        
        return filteredTypeIds;
    }

    /**
     * Check to see if two strings are exactly equal
     * @dev Only valid for strings up to 32 characters
     */    
    function stringsEqual(string memory input1, string memory input2) internal pure returns (bool) {
        bytes32 input1Bytes32;
        bytes32 input2Bytes32;
        assembly {
            input1Bytes32 := mload(add(input1, 32))
            input2Bytes32 := mload(add(input2, 32))
        }
        return input1Bytes32 == input2Bytes32;
    }

    /**
     * Allow storage slots to be manually updated
     */
    function updateSlot(bytes32 slot, bytes32 value) external {
        require(msg.sender == ownerAddress);
        assembly {
            sstore(slot, value)
        }
    }
}