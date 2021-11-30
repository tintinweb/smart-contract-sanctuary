// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/utils/Counters.sol";
import "ERC721Enumerable.sol";
import "ReentrancyGuard.sol";
import "Ownable.sol";
import "Counters.sol";

contract KREWMembershipTicket is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    uint256 public price;
    uint256 public limit;
    string private constant IPFS_PNG = "QmXtH8RY8JxhFqHVzF1sz7xAVYZWRweEvtkWmunUz3mR5i";
    string private constant IPFS_ANIMATION = "QmXViqMJBzkCVH3kNRtShMyR3yeQmu77ZM2z3Bp9NqXsc2";

    event SetCreated(uint256, uint256);

    constructor() ERC721("KREW Membership Ticket", "KREW") {}

    function mint() public payable nonReentrant {
        require(msg.value >= price, "KREW: ETH Amount");
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < limit, "KREW: Max Tickets");
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    // Owner functions
    function createSet(uint256 _amount, uint256 _price) public onlyOwner {
        limit = limit + _amount;
        price = _price;
        emit SetCreated(_amount, _price);
    }

    function withdrawEther() public onlyOwner {
        (bool _sent,) = owner().call{value: address(this).balance}("");
        require(_sent, "KREW: Failed to withdraw Ether");
    }

    // View functions
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked("data:application/json;utf8,", '{"name":"', name(), ' #', tokenId.toString(), '","image": "ipfs://', IPFS_PNG, '","animation_url": "ipfs://', IPFS_ANIMATION, '"}'));
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