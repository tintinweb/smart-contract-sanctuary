// contracts/RooCrew
// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract RooCrew is ERC721, Ownable {

    using SafeMath for uint256;

	uint public constant MAX_ROOS = 5000;

    bool public hasSaleStarted = false;

	string public ROO_PROVENANCE = "";

	uint256 public constant rooPrice = 50000000000000000;


    constructor(string memory baseURI) ERC721("RooCrew","ROO")  {
        setBaseURI(baseURI);
    }
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    
	function mintRoo(uint256 numRoos) public payable {
		require(hasSaleStarted, "Sale has not started");
        require(totalSupply() < MAX_ROOS, "Sale has already ended");
        require(numRoos > 0 && numRoos <= 10, "You can mint from 1 to 10 Roos");
        require(totalSupply().add(numRoos) <= MAX_ROOS, "Exceeds MAX_ROOS");
        require(rooPrice.mul(numRoos) <= msg.value, "Not enough Ether sent for this tx");

        for (uint i = 0; i < numRoos; i++) {
            uint mintIndex = totalSupply() + 1;
            _safeMint(msg.sender, mintIndex);
        }
    }

	function mintGiveawayRoos(uint256 numRoos) public payable onlyOwner {
        require(totalSupply() < MAX_ROOS, "Max Roos supply reached");
        require(totalSupply().add(numRoos) <= MAX_ROOS, "Exceeds MAX_ROOS");

        for (uint i = 0; i < numRoos; i++) {
            uint mintIndex = totalSupply() + 1;
            _safeMint(msg.sender, mintIndex);
        }
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

	function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }
	
	/*
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory _hash) public onlyOwner {
        ROO_PROVENANCE = _hash;
    }
    
    function withdraw() public onlyOwner {
		uint balance = address(this).balance;
		msg.sender.transfer(balance);
    }

}