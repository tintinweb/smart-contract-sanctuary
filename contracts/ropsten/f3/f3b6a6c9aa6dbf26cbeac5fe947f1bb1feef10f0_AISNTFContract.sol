// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721FullCode.sol";
import "./Counters.sol";

contract AISNTFContract is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter _tokenIds;

    mapping(uint256 => string) _tokenURIs;

    struct RenderToken {
        uint256 id;
        string url;
    }

    constructor() ERC721("AIS NTF", "AIS") {}

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId));
        string memory _tokenURI = _tokenURIs[tokenId];
        return _tokenURI;
    }

    function getAllTokens() public view returns (RenderToken[] memory) {
        uint256 latestId = _tokenIds.current();
        uint256 counter = 0;

        RenderToken[] memory res = new RenderToken[](latestId);
        for (uint256 i = 0; i < latestId; i++) {
            if (_exists(counter)) {
                string memory uri = tokenURI(counter);
                res[counter] = RenderToken(counter, uri);
            }
            counter++;
        }
        return res;
    }

    function mint(address recipient, string memory uri)
        public
        returns (uint256)
    {
        uint256 newId = _tokenIds.current();
        require(!_exists(newId));
        _mint(recipient, newId);

        _setTokenURI(newId, uri);
        _tokenIds.increment();
        return newId;
    }
}