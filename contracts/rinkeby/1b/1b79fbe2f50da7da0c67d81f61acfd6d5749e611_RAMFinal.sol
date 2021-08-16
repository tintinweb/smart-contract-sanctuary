// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

/**
 * @title RAM FINAL contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract RAMFinal is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant maxTokens = 10000;
    uint256 public constant price = 0.06 ether;
    uint256 public constant maxPurchaseOnce = 20;

    uint256 public constant airDropReserveNum = 10;
    bool public saleIsActive;

    string private _baseTokenURI = "ipfs://QmPLkCJPxnskTucMamBhnTnpCBhk3BkKmhNYuRBBL2vUPN/";
    string private _baseContractURI = "ipfs://QmPLkCJPxnskTucMamBhnTnpCBhk3BkKmhNYuRBBL2vUPN/contract";


    constructor() ERC721("RAMFinal", "RAF")  {
        saleIsActive = false;
        setBaseURI(_baseTokenURI);
        setContractURI(_baseContractURI);
    }

    /*
    * @dev Reserve limited number of tokens for gifts
    */
    function reserveTokens() public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < airDropReserveNum; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function mint(uint256 num) public payable {
        uint256 supply = totalSupply();
        require(saleIsActive, "Sale is not active");
        require(num > 0, "Minting 0");
        require(num <= maxPurchaseOnce, "Max of 20 is allowed");
        require(supply + num <= maxTokens, "Passing max supply");
        require(msg.value >= price * num, "Ether sent is not correct");

        for(uint256 i; i < num; i++){
            _safeMint(msg.sender, supply + i );
        }
    }

    /*
    * @dev To directly gift
    */
    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }
    }

    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /*
    * @dev openSea contract metadata
    */
    function setContractURI(string memory contURI) public onlyOwner {
		_baseContractURI = contURI;
	}

    function contractURI() public view returns (string memory) {
		return _baseContractURI;
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
}