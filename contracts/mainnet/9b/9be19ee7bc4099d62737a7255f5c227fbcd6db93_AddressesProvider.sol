/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

pragma solidity 0.8.6;

contract AddressesProvider {
    address public ownerAddress;    
    mapping(uint256 => address) addressMap;
    mapping(uint256 => string) addressIdMap;
    uint256 addressesLength;

    constructor() {
        ownerAddress = msg.sender;
    }
    
    struct AddressMetadata {
        string addrId;
        address addr;
    }
    
    function setAddress(AddressMetadata memory addressMetadata) public {
        require(msg.sender == ownerAddress, "Caller is not owner");
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
    
    function setAddresses(AddressMetadata[] memory _addressesMetadata) public {
        require(msg.sender == ownerAddress, "Caller is not owner");
        for (uint256 addressMetadataIdx; addressMetadataIdx < _addressesMetadata.length; addressMetadataIdx++) {
            AddressMetadata memory addressMetadata = _addressesMetadata[addressMetadataIdx];
            setAddress(addressMetadata);
        }
    }
    
    function addressPositionById(string memory addressId) public view returns (int) {
        for (uint256 addressIdx; addressIdx < addressesLength; addressIdx++) {
            string memory currentAddressId = addressIdMap[addressIdx];
            if (stringsEqual(addressId, currentAddressId)) {
                return int256(addressIdx);
            }
        }
        return -1;
    }
        
    function addressById(string memory addressId) external view returns (address) {
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

    function addressesMetadata() external view returns (AddressMetadata[] memory) {
        AddressMetadata[] memory _addressesMetadata = new AddressMetadata[](addressesLength);
        for (uint256 addressIdx; addressIdx < addressesLength; addressIdx++) {
            _addressesMetadata[addressIdx] = AddressMetadata({
                addrId: addressIdMap[addressIdx],
                addr: addressMap[addressIdx]
            });
        }
        return _addressesMetadata;
    }

    function addressesMetadataByIdStartsWith(string memory addressIdSubstring) external view returns (AddressMetadata[] memory) {
        AddressMetadata[] memory _addressesMetadata = new AddressMetadata[](addressesLength);
        uint256 _addressesLength;
        for (uint256 addressIdx; addressIdx < addressesLength; addressIdx++) {
            string memory addressId = addressIdMap[addressIdx];
            bool foundMatch = startsWith(addressId, addressIdSubstring);
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
        AddressMetadata[] memory filteredAddresses =
            abi.decode(encodedAddresses, (AddressMetadata[]));
        return filteredAddresses;
    }
    
    /**
     * Allow storage slots to be manually updated by owner
     */
    function updateSlot(bytes32 slot, bytes32 value) external {
        require(msg.sender == ownerAddress, "Caller is not owner");
        assembly {
            sstore(slot, value)
        }
    }

    /***********
     * Utilities
     ***********/
    
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
}