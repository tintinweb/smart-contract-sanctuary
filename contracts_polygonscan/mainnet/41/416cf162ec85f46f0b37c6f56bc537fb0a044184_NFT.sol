// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract NFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string baseURI;
    string public baseExtension = ".json";

    // name: RSS3 - Part of the Family
    // symbol: FAMILY
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(address to) public onlyOwner {
        uint256 supply = totalSupply();
        _safeMint(to, supply + 1);
    }

    function batchMint(address[] memory addrs) public onlyOwner {
        uint256 supply = totalSupply();
        for (uint256 i; i < addrs.length; i++) {
            _safeMint(addrs[i], supply + i);
        }
    }

    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }


    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }
}