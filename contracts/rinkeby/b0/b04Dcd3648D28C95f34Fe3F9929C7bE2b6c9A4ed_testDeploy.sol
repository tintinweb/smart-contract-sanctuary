// SPDX-License-Identifier: MIT

// Test


import "./ERC721.sol";

pragma solidity ^0.7.0;
pragma abicoder v2;

contract testDeploy is ERC721, Ownable {
    
    using SafeMath for uint256;

    string public PROVENANCE = ""; // IPFS URL WILL BE ADDED WHEN ANIGIRLS ARE ALL SOLD OUT
    
    
	// ************************* TEST VALUES ONLY *************************
	// ************************* RESET BEFORE DEPLOY **********************
	uint256 public Price = 1000000000000000; // 0.001 ETH TEST

    uint public constant maxPurchase = 20; // TEST

    uint256 public constant MAX_AMOUNT = 50; // TEST

	// ************************* TEST VALUES ONLY **************************
	
	
    bool public saleIsActive = false;
    
    constructor() ERC721("JustTesting", "JT") { }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }
	
	function setPrice(uint256 _Price) public onlyOwner {
        Price = _Price;
    }
    
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    
    
}