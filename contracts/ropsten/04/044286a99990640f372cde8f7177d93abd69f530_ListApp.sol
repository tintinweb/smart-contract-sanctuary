/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

pragma solidity ^0.4.24;

contract ListApp {
    /// Events
    event Add(address indexed _caller, string _value);
    event Remove(address indexed _caller, string _value);

    string constant PLACE_HOLDER = "____INVALID_PLACE_HOLER";

    /// Errors
    string constant ERROR_VALUE_NOT_PART_OF_THE_LIST =
        "ERROR_VALUE_NOT_PART_OF_THE_LIST";
    string constant ERROR_VALUE_PART_OF_THE_LIST =
        "ERROR_VALUE_PART_OF_THE_LIST";
    string constant ERROR_INVALID_INDEX = "ERROR_INVALID_INDEX";
    string constant ERROR_INVALID_VALUE = "ERROR_INVALID_VALUE";
    string constant ERROR_INVALID_TYPE = "ERROR_INVALID_TYPE";
    string constant ERROR_INVALID_ADDRESS = "ERROR_INVALID_ADDRESS";

    /// State
    string public name;
    string public symbol;
    string public listType;
    string[] public values;
    mapping(string => uint256) internal indexByValue;

    /// ACL
    bytes32 public constant ADD_ROLE = keccak256("ADD_ROLE");
    bytes32 public constant REMOVE_ROLE = keccak256("REMOVE_ROLE");

    /**
     * @dev Initialize contract
     * @notice Create a new list: `_symbol` (`_name`) with type: `_type`
     * @param _name The list's display name
     * @param _symbol The list's display symbol
     * @param _type The list's type
     */
    function initialize(
        string _name,
        string _symbol,
        string _type
    ) external {
        _requireValidType(_type);

        name = _name;
        symbol = _symbol;
        listType = _type;

        // Invalidate first position
        values.push(PLACE_HOLDER);
    }

    /**
     * @dev Add a value to the  list
     * @notice Add "`_value`" to the `self.symbol(): string` list. `self.getTypeHash(): bytes32 == 0x55d2d27e31c4cb7b29e0a26c4da29beed88162ab503267550adc2b08511eb9f1 ? 'Take a look: https://play.decentraland.org/?position=' + _value : ''`
     * @param _value String value to remove
     */
    function add(string _value) external {
        // Check if the value is part of the list
        require(indexByValue[_value] == 0, ERROR_VALUE_PART_OF_THE_LIST);
        // Check if the value is not the placeholder
        require(
            keccak256(_value) != keccak256(PLACE_HOLDER),
            ERROR_INVALID_VALUE
        );

        bytes32 typeHash = getTypeHash();

        if (_isStringType(typeHash)) {
            _add(_value);
        } else if (_isAddressType(typeHash)) {
            _addAddress(_value);
        } else {
            revert(ERROR_INVALID_TYPE);
        }
    }

    /**
     * @dev Remove a value from the list
     * @notice Remove "`_value`" from the `self.symbol(): string` list
     * @param _value String value to remove
     */
    function remove(string _value) external {
        require(indexByValue[_value] > 0, ERROR_VALUE_NOT_PART_OF_THE_LIST);

        // Values length
        uint256 lastValueIndex = size();

        // Index of the value to remove in the array
        uint256 removedIndex = indexByValue[_value];

        // Last value id
        string lastValue = values[lastValueIndex];

        // Override index of the removed value with the last one
        values[removedIndex] = lastValue;
        indexByValue[lastValue] = removedIndex;

        emit Remove(msg.sender, _value);

        // Clean storage
        values.length--;
        delete indexByValue[_value];
    }

    /**
     * @dev Get list's size
     * @return list's size
     */
    function size() public view returns (uint256) {
        return values.length - 1;
    }

    /**
     * @dev Get list's item
     * @param _index of the item
     * @return item at index
     */
    function get(uint256 _index) public view returns (string) {
        require(_index < values.length - 1, ERROR_INVALID_INDEX);

        return values[_index + 1];
    }

    function getTypeHash() public view returns (bytes32) {
        return keccak256(listType);
    }

    /**
     * @dev Add a value to the  list
     * @notice that will revert if the value is not a valid address
     * @param _value String value to remove
     */
    function _addAddress(string _value) internal {
        require(_toAddress(_value) != address(0), ERROR_INVALID_ADDRESS);
        _add(_value);
    }

    /**
     * @dev Add a value to the  list
     * @param _value String value to remove
     */
    function _add(string _value) internal {
        // Store the value to be looped
        uint256 index = values.push(_value);

        // Save mapping of the value within its position in the array
        indexByValue[_value] = index - 1;

        emit Add(msg.sender, _value);
    }

    function _requireValidType(string _type) internal {
        bytes32 typeHash = keccak256(_type);
        require(
            _isStringType(typeHash) || _isAddressType(typeHash),
            ERROR_INVALID_TYPE
        );
    }

    function _isStringType(bytes32 typeHash) internal pure returns (bool) {
        return
            typeHash == keccak256("COORDINATES") ||
            typeHash == keccak256("NAME");
    }

    function _isAddressType(bytes32 typeHash) internal pure returns (bool) {
        return typeHash == keccak256("ADDRESS");
    }

    function _toAddress(string memory account)
        internal
        pure
        returns (address accountAddress)
    {
        // convert the account argument from address to bytes.
        bytes memory accountBytes = bytes(account);

        // create a new fixed-size byte array for the ascii bytes of the address.
        bytes memory accountAddressBytes = new bytes(20);

        // declare variable types.
        uint8 b;
        uint8 nibble;
        uint8 asciiOffset;

        // only proceed if the provided string has a length of 40.
        if (accountBytes.length == 42) {
            if (accountBytes[0] != "0") return address(0);
            if (accountBytes[1] != "x") return address(0);
            for (uint256 i = 0; i < 40; i++) {
                // get the byte in question.
                b = uint8(accountBytes[i + 2]);

                // ensure that the byte is a valid ascii character (0-9, A-F, a-f)
                if (b < 48) return address(0);
                if (57 < b && b < 65) return address(0);
                if (70 < b && b < 97) return address(0);
                if (102 < b) return address(0); //bytes(hex"");

                // find the offset from ascii encoding to the nibble representation.
                if (b < 65) {
                    // 0-9
                    asciiOffset = 48;
                } else if (70 < b) {
                    // a-f
                    asciiOffset = 87;
                } else {
                    // A-F
                    asciiOffset = 55;
                }

                // store left nibble on even iterations, then store byte on odd ones.
                if (i % 2 == 0) {
                    nibble = b - asciiOffset;
                } else {
                    accountAddressBytes[(i - 1) / 2] = (
                        bytes1(16 * nibble + (b - asciiOffset))
                    );
                }
            }

            // pack up the fixed-size byte array and cast it to accountAddress.
            bytes memory packed = abi.encodePacked(accountAddressBytes);
            assembly {
                accountAddress := mload(add(packed, 20))
            }
        }
    }
}