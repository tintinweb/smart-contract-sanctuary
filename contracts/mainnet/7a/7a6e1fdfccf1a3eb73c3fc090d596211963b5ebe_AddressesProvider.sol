/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

pragma solidity 0.8.6;

contract AddressesProvider {
    struct AddressMetadata {
        address addr;
        string addressId;
    }
    
    address public ownerAddress;
    mapping(uint256 => AddressMetadata) public addressMetadataById;
    mapping(string => bool) internal addressIdExists;
    mapping(string => uint256) public addressIdPosition;
    uint256 addressesMetadataLength;

    constructor() {
        ownerAddress = msg.sender;
    }
    
    function setAddressMetadata(AddressMetadata memory addressMetadata) public {
        require(msg.sender == ownerAddress, "Caller is not owner");
        address addr = addressMetadata.addr;
        string memory addressId = addressMetadata.addressId;

        uint256 upsertPosition = addressesMetadataLength;
        if (addressIdExists[addressId]) {
            upsertPosition = addressIdPosition[addressId];
        } else {
            addressIdExists[addressId] = true;
            addressIdPosition[addressId] = addressesMetadataLength;
            addressesMetadataLength++;
        }
        addressMetadataById[upsertPosition] = AddressMetadata({
           addr: addr,
           addressId: addressId
        });
        if (addressIdExists[addressId] == false) {
            addressesMetadataLength++;
        }
    }
    
    function setAddressesMetadata(AddressMetadata[] memory _addressesMetadata) external {
        require(msg.sender == ownerAddress, "Caller is not owner");
        for (uint256 addressMetadataIdx; addressMetadataIdx < _addressesMetadata.length; addressMetadataIdx++) {
            AddressMetadata memory addressMetadataParams = _addressesMetadata[addressMetadataIdx];
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
    
    function addressMetadataId(string memory addressId) external view returns (AddressMetadata memory) {
        for (uint256 addressMetadataIdx; addressMetadataIdx < addressesMetadataLength; addressMetadataIdx++) {
            AddressMetadata memory addressMetadata = addressMetadataById[addressMetadataIdx];
            if (stringsEqual(addressId, addressMetadata.addressId)) {
                return addressMetadata;
            }
        }
        return AddressMetadata({
            addr: address(0),
            addressId: ""
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
    
    function addressesWhereIdStartsWith(string memory addressIdSubstring) external view returns (address[] memory) {
        address[] memory _addresses = new address[](addressesMetadataLength);
        uint256 addressesIdsLength;
        for (uint256 addressMetadataIdx; addressMetadataIdx < addressesMetadataLength; addressMetadataIdx++) {
            AddressMetadata memory addressMetadata = addressMetadataById[addressMetadataIdx];
            bool foundMatch = startsWith(addressMetadata.addressId, addressIdSubstring);
            if (foundMatch) {
                _addresses[addressesIdsLength] = addressMetadata.addr;
                addressesIdsLength++;
            }
        }
        bytes memory encodedAddresses = abi.encode(_addresses);
        assembly {
            mstore(add(encodedAddresses, 0x40), addressesIdsLength)
        }
        address[] memory filteredAddresses =
            abi.decode(encodedAddresses, (address[]));
        
        return filteredAddresses;
    }
    
    function addressesIds() external view returns (string[] memory) {
        string[] memory _addressesIds = new string[](addressesMetadataLength);
        for (uint256 addressMetadataIdx; addressMetadataIdx < addressesMetadataLength; addressMetadataIdx++) {
            AddressMetadata memory addressMetadata = addressMetadataById[addressMetadataIdx];
            _addressesIds[addressMetadataIdx] = addressMetadata.addressId;
        }
        return _addressesIds;
    }
    
    /**
     * Search for a needle in a haystack
     */
    function startsWith(string memory haystack, string memory needle) internal pure returns (bool) {
        return indexOf(needle, haystack) == 0;
    }

    /**
     * Case insensitive string search
     *
     * @param needle The string to search for
     * @param haystack The string to search in
     * @return Returns -1 if no match is found, otherwise returns the index of the match 
     */
    function indexOf(string memory needle, string memory haystack) internal pure returns (int256) {
        bytes memory _needle = bytes(needle);
        bytes memory _haystack = bytes(haystack);
        if (_haystack.length < _needle.length) {
            return -1;
        }
        bool _match;
        for (uint256 haystackIdx; haystackIdx < _haystack.length; haystackIdx++) {
            for (uint256 needleIdx; needleIdx < _needle.length; needleIdx++) {
                uint8 needleChar = uint8(_needle[needleIdx]);
                if (haystackIdx + needleIdx >= _haystack.length) {
                    return -1;
                }
                uint8 haystackChar = uint8(_haystack[haystackIdx + needleIdx]);
                if (needleChar == haystackChar) {
                    _match = true;
                    if (needleIdx == _needle.length - 1) {
                        return int(haystackIdx);
                    }
                } else {
                    _match = false;
                    break;
                }
            }
        }
        return -1;
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