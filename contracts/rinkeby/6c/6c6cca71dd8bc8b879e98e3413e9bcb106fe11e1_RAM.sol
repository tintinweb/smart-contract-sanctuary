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
    uint public constant maxPurchaseOnce = 20;

    uint public constant ownerReserveAmount = 1;
    bool public saleIsActive = false;

    string public PROVENANCE = "";
    string private _baseTokenURI="ipfs://QmTP3mc9YwBMhXAfMEGXxdQrrhrWmQsfgj8ETYhRp5Mowc/";
    string public _baseContractURI="ipfs://QmNjh6z7Rnq5M7r9U2ZoHvHjaboRUQeYTFc4C5G27R9Yg2/contract";

    constructor() ERC721("Ram Token", "RAM")  {
        setBaseURI(_baseTokenURI);
        setContractURI(_baseContractURI);

        // Reserve first token for showcase, gift, and airdrop
        reserveTokens();
    }

    /*
    * @dev Needed below function to resolve conflicting fns in ERC721 and ERC721Enumerable
    */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /*
    * @dev Needed below function to resolve conflicting fns in ERC721 and ERC721Enumerable
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /*
    * @dev Set provenance once calculated
    */
    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    /*
    * @dev Reserve limited number of tokens for showcase, gift, and airdrop
    */
    function reserveTokens() public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < ownerReserveAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function mintRAM(uint256 num) public payable {
        uint256 supply = totalSupply();
        require(saleIsActive, "Sale is not active" );
        require(num > 0, "You cannot mint 0 tokens");
        require(num <= maxPurchaseOnce, "You can buy a max of 20 RAM" );
        require(supply + num <= maxTokens, "Passing max RAM supply" );
        require(msg.value >= price * num, "Ether sent is not correct" );

        for(uint256 i; i < num; i++){
            _safeMint(msg.sender, supply + i );
        }
    }

    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /*
    * @dev openSea contract metadata
    */
    function setContractURI(string memory newContractURI) public onlyOwner {
		_baseContractURI = newContractURI;
	}

    function contractURI() public view returns (string memory) {
		return _baseContractURI;
	}
}