// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

import "./ERC1155.sol";

contract Artifya is ERC1155 {
    uint256[] public tokenId;
    mapping(address => uint256[]) public tokenCollection;
    string _uri = "https://n-bhasin.github.io/erc1155/";

    constructor() public ERC1155(_uri) {}

    function createTokens(uint256 _tokenId, uint256 _initialSupply)
        external
        returns (uint256)
    {
        tokenId.push(_tokenId);
        tokenCollection[msg.sender].push(_tokenId);
        _mint(msg.sender, _tokenId, _initialSupply, "");
        uri(_tokenId);
        return _tokenId;
    }

    function createTokensInBatch(
        address _to,
        uint256[] calldata _tokenId,
        uint256[] calldata _initialSupply
    ) external {
        _mintBatch(_to, _tokenId, _initialSupply, "");
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return string(abi.encodePacked(_uri, _uint2str(_id), ".json"));
    }

    function _uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 ii = _i;
        uint256 len;

        // Get number of bytes
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;

        // Get each individual ASCII
        while (ii != 0) {
            bstr[k--] = bytes1(uint8(48 + (ii % 10)));
            ii /= 10;
        }

        // Convert to string
        return string(bstr);
    }
}