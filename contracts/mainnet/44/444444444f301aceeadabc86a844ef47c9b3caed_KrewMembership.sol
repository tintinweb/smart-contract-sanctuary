// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "ERC721Enumerable.sol";
import "ReentrancyGuard.sol";
import "Ownable.sol";
import "Counters.sol";

contract KrewMembership is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    mapping (address => bool) whitelist;
    bool public whitelistEnabled;
    uint256 public price;
    uint256 public limit;
    string private constant IPFS_PNG = "QmXtH8RY8JxhFqHVzF1sz7xAVYZWRweEvtkWmunUz3mR5i";
    string private constant IPFS_ANIMATION = "QmVW2ZhK7fivBUJoGK5CZLTYGLVbeotHM1hVKdsoL4NCR1";
    string private constant DESCRIPTION = "This pass entitles the holder to ongoing benefits provided by Krew Studios and grants exclusive access to Krew Studios projects.";

    constructor() ERC721("Krew Studios Members Only Pass", "KREW") {}

    function mint() public payable nonReentrant {
        require(msg.value >= price, "KREW: ETH Amount");
        require(!whitelistEnabled || whitelist[msg.sender], "KREW: Whitelist");
        if (whitelistEnabled && whitelist[msg.sender]) {
            whitelist[msg.sender] = false;
        }
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < limit, "KREW: Max Tickets");
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    // Owner functions
    function setWhitelist(address[] calldata addresses, bool whitelistStatus) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = whitelistStatus;
        }
    }

    function toggleWhitelist() public onlyOwner {
        whitelistEnabled = whitelistEnabled ? false : true;
    }

    function setLimit(uint256 _newLimit) public onlyOwner {
        require(_newLimit >= totalSupply(), "KREW: Cannot be lower than totalSupply");
        limit = _newLimit;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function withdrawEther() public onlyOwner {
        (bool _sent,) = owner().call{value: address(this).balance}("");
        require(_sent, "KREW: Failed to withdraw Ether");
    }

    // View functions
    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(
            'data:application/json;utf8,{"name":"',
            name(),
            " #",
            tokenId.toString(),
            '", "description": "',
            DESCRIPTION,
            '", "image": "ipfs://',
            IPFS_PNG,
            '","animation_url": "ipfs://',
            IPFS_ANIMATION,
            '"}'
        ));
    }

    function amountMintable() public view returns (uint256) {
        return limit - _tokenIdCounter.current();
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}