// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

/**
 * @title RAM contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract RAM is ERC721, ERC721Enumerable, Ownable {

    using Strings for uint256;

    uint256 public constant maxTokens = 10;
    uint256 public constant price = 0.0001 ether;
    uint public constant maxPurchaseOnce = 10;

    uint public constant ownerReserve = 1;
    bool public saleIsActive = false;

    string public PROVENANCE = "";
    string private _baseURIextended;

    constructor(string memory baseURI) ERC721("Ram Token", "RAM")  {
    }

    /*
    * @dev Needed below functions to resolve conflicting fns in ERC721 and ERC721Enumerable
    */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /*
    * @dev Added for new changes in OpenZeppelin contracts
    */
    function setBaseURI(string memory baseURI) external onlyOwner() {
        _baseURIextended = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /*
    * @dev Set provenance once calculated
    */
    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function reserveTokens() public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < ownerReserve; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function mintRAM(uint256 num) public payable {
        uint256 supply = totalSupply();
        require(saleIsActive, "Sale paused" );
        require(num > 0, "You cannot mint 0 RAMs.");
        require(num <= maxPurchaseOnce, "You can adopt a max of 10 RAM" );
        require(supply + num <= maxTokens, "Exceeds max RAM supply" );
        require(msg.value >= price * num, "Ether sent is not correct" );

        for(uint256 i; i < num; i++){
            _safeMint(msg.sender, supply + i );
        }
    }

    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}