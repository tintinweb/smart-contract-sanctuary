/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

// "SPDX-License-Identifier: UNLICENSED"

pragma solidity 0.8.0;

contract Task {
    function trim(string[] calldata _strings)
        public
        pure
        returns (string memory)
    {
        require(_strings.length > 0, "Empty array");
        if (_strings.length == 1) {
            return _strings[0];
        } else {
            string memory holder = _strings[_strings.length - 1];
            for (uint256 i = 0; i < _strings.length - 1; i++) {
                holder = removeAndSend(
                    holder,
                    _strings[_strings.length - i - 2]
                );
            }
            return holder;
        }
    }

    function compareChar(string memory _string1, string memory _string2)
        internal
        pure
        returns (bool)
    {
        if (
            keccak256(abi.encodePacked(getChar(_string1, 0))) ==
            keccak256(abi.encodePacked(getChar(_string2, 1)))
        ) {
            return true;
        }
        return false;
    }

    function removeAndSend(string memory _string1, string memory _string2)
        internal
        pure
        returns (string memory)
    {
        (string memory result1, string memory result2) = (_string1, _string2);
        for (uint256 i = 0; i < bytes(_string1).length; i++) {
            if (bytes(result1).length != 0 && bytes(result2).length != 0) {
                if (compareChar(result1, result2)) {
                    result1 = removeChar(result1, 0);
                    result2 = removeChar(result2, 1);
                }
            } else {
                break;
            }
        }
        return (string(abi.encodePacked(result1, result2)));
    }

    function getChar(string memory _string, uint8 _num)
        internal
        pure
        returns (string memory)
    {
        require(_num == 0 || _num == 1, "Invalid char check");
        bytes memory _local = bytes(_string);
        bytes memory _char = new bytes(1);
        if (_num == 0) {
            _char[0] = _local[_local.length - 1];
        } else {
            _char[0] = _local[0];
        }
        return string(_char);
    }

    function removeChar(string memory _string, uint8 _char)
        internal
        pure
        returns (string memory)
    {
        require(_char == 0 || _char == 1, "Invalid trimming");
        bytes memory _local = bytes(_string);
        bytes memory _newString = new bytes(_local.length - 1);
        for (uint256 i = 0; i < _local.length - 1; i++) {
            _newString[i] = _local[i + _char];
        }
        return string(_newString);
    }
}