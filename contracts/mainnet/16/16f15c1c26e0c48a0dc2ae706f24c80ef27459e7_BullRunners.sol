// contracts/BullRunners
// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract BullRunners is ERC721, Ownable {

    using SafeMath for uint256;

	uint public constant MAX_BULLS = 1001;

    bool public hasSaleStarted = false;

	string public BULLS_PROVENANCE = "";

	uint256 public constant bullsPrice = 25000000000000000;


    constructor(string memory baseURI) ERC721("Bull Runners","BULLRUN")  {
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
    
	function mintBull(uint256 numBulls) public payable {
		require(hasSaleStarted, "Sale has not started");
        require(totalSupply() < MAX_BULLS, "Sale has already ended");
        require(numBulls > 0 && numBulls <= 20, "You can mint from 1 to 20 Bulls");
        require(totalSupply().add(numBulls) <= MAX_BULLS, "Exceeds MAX_BULLS");
        require(bullsPrice.mul(numBulls) <= msg.value, "Not enough Ether sent for this tx");

        for (uint i = 0; i < numBulls; i++) {
            uint mintIndex = totalSupply() + 1;
            _safeMint(msg.sender, mintIndex);
        }
    }

	function mintGiveawayBulls(uint256 numBulls) public payable onlyOwner {
        require(totalSupply() < MAX_BULLS, "Max Bulls supply reached");
        require(totalSupply().add(numBulls) <= MAX_BULLS, "Exceeds MAX_BULLS");

        for (uint i = 0; i < numBulls; i++) {
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
        BULLS_PROVENANCE = _hash;
    }
    
    function withdraw() public onlyOwner {
		uint balance = address(this).balance;
		msg.sender.transfer(balance);
    }

}