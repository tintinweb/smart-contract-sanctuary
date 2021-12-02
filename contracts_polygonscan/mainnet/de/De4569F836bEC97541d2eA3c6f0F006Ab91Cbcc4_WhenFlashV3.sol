// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract WhenFlashV3 {
    uint256 private _number = 0;
    uint256 private _firstNumber;
    uint256 private _secondNumber;

    mapping (address => mapping (address => bool)) private _connectedSouls;
    mapping (address => address[]) private _connectedTo;
    uint256 public soulChainLength = 0;

    constructor(uint256 firstNumber_, uint256 secondNumber_) {
        _firstNumber = firstNumber_; 
        _secondNumber = secondNumber_;
    }

    function whenFlash() public view returns (string memory) {
        require(_number > 0, "Gate is not openned you need 3 chain length");

        uint256 hourBitIndex = 7 * 6;
        uint256 minBitIndex = 12 * 6;
        uint256 minBitIndex2 = 21 * 6;
        
        uint256 hour = (_number >> hourBitIndex) & 31;
        uint256 min = (_number >> minBitIndex) & 31;
        uint256 min2 = (_number >> minBitIndex2) & 31;

        string[] memory value = new string[](6);
        value[0] = toString(hour);
        value[1] = ":";
        value[2] = toString(min);
        value[3] = toString(min2);
        value[4] = " GMT";

        return string(abi.encodePacked(value[0], value[1], value[2], value[3], value[4]));
    }

    function connectToAnotherSoul(address anotherSoul) public {
        require(anotherSoul != msg.sender, "It shoudn't be your soul");
        
        if (_connectedSouls[anotherSoul][msg.sender] == true && _connectedSouls[msg.sender][anotherSoul] == false) {
            soulChainLength += 1;
        }

        if (soulChainLength > 2) {
            openGate();
        }

        _connectedTo[msg.sender].push(anotherSoul);
        _connectedSouls[msg.sender][anotherSoul] = true;
    }

    function openGate() private {
        _number = _firstNumber * 2 + _secondNumber;
    }

    function riddel() public pure returns (string memory) {
        return 'To open the gate you need to connect 3 pairs of souls together?';
    }

    function connectedTo(address anotherSoul) public view returns (address[] memory) {
        return _connectedTo[anotherSoul];
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}