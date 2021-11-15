// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

contract NftProfileHelper {
    address public owner;
    string public _allowedChar;

    constructor() {
        owner = msg.sender;
        _allowedChar = "abcdefghijklmnopqrstuvwxyz1234567890_";
    }

    modifier onlyOwner {
        require(msg.sender == owner, "!owner");
        _;
    }

    function bytesStringLength(string memory _string) private pure returns (uint256) {
        return bytes(_string).length;
    }

    function correctLength(string memory _string) private pure returns (bool) {
        return bytesStringLength(_string) > 0 && bytesStringLength(_string) <= 60;
    }

    function allowedBytes() private view returns (bytes memory) {
        return bytes(_allowedChar);
    }

    /**
     @notice checks for a valid URI with length and allowed characters
     @param _name string for a given URI
     @return true if valid
    */
    function _validURI(string memory _name) external view returns (bool) {
        require(correctLength(_name), "invalid length");
        uint256 allowedChars = 0;
        bytes memory byteString = bytes(_name);
        bytes memory allowed = allowedBytes();
        for (uint256 i = 0; i < byteString.length; i++) {
           for (uint256 j = 0; j < allowed.length; j++) {
              if (byteString[i] == allowed[j]) allowedChars++;
           }
        }
        if (allowedChars < byteString.length) return false;
        return true;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function changeAllowedChar(string memory _new) external onlyOwner {
        _allowedChar = _new;
    }
}

