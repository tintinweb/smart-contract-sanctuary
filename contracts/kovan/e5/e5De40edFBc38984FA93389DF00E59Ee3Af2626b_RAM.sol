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

    string public PROVENANCE = "";
    uint256 public constant _maxTokens = 10;
    uint256 public constant _price = 0.0001 ether;
    uint public constant _maxPurchaseOnce = 10;
    uint public constant _OwnerMint = 1;
    bool public saleIsActive = false;

    string private _baseURIextended;


    constructor(string memory baseURI) ERC721("RAM Token", "RAM")  {
    }

    // CHANGED: needed to resolve conflicting fns in ERC721 and ERC721Enumerable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // CHANGED: needed to resolve conflicting fns in ERC721 and ERC721Enumerable
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // CHANGED: added to account for changes in openzeppelin versions
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    // CHANGED: added to account for changes in openzeppelin versions
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserveTokens() public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < _OwnerMint; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }


    function mintRAM(uint256 num) public payable {
        uint256 supply = totalSupply();

        require(saleIsActive, "Sale paused" );
        require(num > 0, "You cannot mint 0 RAMs.");
        require(num <= _maxPurchaseOnce, "You can adopt a max of 10 RAM" );
        require(totalSupply() + num <= _maxTokens, "Exceeds max RAM supply" );
        require(msg.value >= _price * num, "Ether sent is not correct" );

        for(uint256 i; i < num; i++){
            _safeMint(msg.sender, supply + i );
        }
    }

    /*
    * @dev Set provenance once calculated
    */
    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
}