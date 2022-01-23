/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

// String library from OpenZeppelin

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// -------------------------------
// CUSTOM CONTRACT
// -------------------------------

contract SyntheticPic {

    address payable public owner;
    string public contractUri;
    string public tokenUriPrefix;
    string public tokenUriSuffix;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor(string memory _contractUri, string memory _prefix, string memory _suffix) {
        owner = payable(msg.sender);
        contractUri = _contractUri;
        tokenUriPrefix = _prefix;
        tokenUriSuffix = _suffix;
    }

    function setContractUri(string memory _contractUri) public onlyOwner {
        contractUri = _contractUri;
    }

    function setPrefix(string memory _prefix) public onlyOwner {
        tokenUriPrefix = _prefix;
    }

    function setSuffix(string memory _suffix) public onlyOwner {
        tokenUriSuffix = _suffix;
    }

    function setOwner(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function withdraw() public {
        owner.transfer(address(this).balance);
    }

    function mint(address _to, uint256 _tokenId) public payable {
        emit Transfer(address(0), _to, _tokenId);
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        string memory strId = Strings.toString(_tokenId); // convert uint256 to a string
        return string(abi.encodePacked(tokenUriPrefix, strId, tokenUriSuffix));
    }
}