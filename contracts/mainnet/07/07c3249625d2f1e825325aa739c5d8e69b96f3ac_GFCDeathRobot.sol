// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";

import "./Ownable.sol";

contract GFCDeathRobot is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string private _tokenBaseURI = '';

    constructor(string memory name, string memory symbol) ERC721(name, symbol){}

    function tokensOfOwner(address _owner)external view returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 i; i < tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    /*
     * Only the owner can do these things
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _tokenBaseURI = _newBaseURI;
    }

    function airdrop(address[] calldata to) public onlyOwner {
        uint256 supply = totalSupply();
        for(uint256 i = 0; i < to.length; i++) {
            //Ensure tokenId starts with 1
            supply += 1;
            _safeMint(to[i], supply);
        }
    }
}