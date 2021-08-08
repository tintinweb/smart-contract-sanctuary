// contracts/Goons
// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract Goons is ERC721, Ownable {

    using SafeMath for uint256;

	uint public constant MAX_GOONS = 9696;
	uint public constant MAX_PRESALE = 1000;

    bool public hasSaleStarted = false;
	bool public hasPresaleStarted = false;

	string public GOONS_PROVENANCE = "";

	uint256 public constant goonsPrice = 69000000000000000;


    constructor(string memory baseURI) ERC721("Goons","GOONS")  {
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
    
	function mintGoon(uint256 numGoons) public payable {
		require(hasSaleStarted, "Sale has not started");
        require(totalSupply() < MAX_GOONS, "Sale has already ended");
        require(numGoons > 0 && numGoons <= 5, "You can mint from 1 to 5 Goons");
        require(totalSupply().add(numGoons) <= MAX_GOONS, "Exceeds MAX_GOONS");
        require(goonsPrice.mul(numGoons) <= msg.value, "Not enough Ether sent for this tx");

        for (uint i = 0; i < numGoons; i++) {
            uint mintIndex = totalSupply() + 1;
            _safeMint(msg.sender, mintIndex);
        }
    }

	function mintPresaleGoon(uint256 numGoons) public payable {
		require(hasPresaleStarted, "Presale has not started");
        require(totalSupply() < MAX_PRESALE, "Presale has already ended");
        require(numGoons > 0 && numGoons <= 5, "You can mint from 1 to 5 Goons");
        require(totalSupply().add(numGoons) <= MAX_PRESALE, "Exceeds MAX_PRESALE");
        require(goonsPrice.mul(numGoons) <= msg.value, "Not enough Ether sent for this tx");

        for (uint i = 0; i < numGoons; i++) {
            uint mintIndex = totalSupply() + 1;
            _safeMint(msg.sender, mintIndex);
        }
    }

	function mintGiveawayGoons(uint256 numGoons) public payable onlyOwner {
        require(totalSupply() < MAX_GOONS, "Max Goons supply reached");
        require(totalSupply().add(numGoons) <= MAX_GOONS, "Exceeds MAX_GOONS");

        for (uint i = 0; i < numGoons; i++) {
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

	function startPresale() public onlyOwner {
		hasPresaleStarted = true;
	}

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

	function pausePresale() public onlyOwner {
		hasPresaleStarted = false;
	}
	
	/*
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory _hash) public onlyOwner {
        GOONS_PROVENANCE = _hash;
    }
    
    function withdraw() public onlyOwner {
		uint balance = address(this).balance;
		msg.sender.transfer(balance);
    }

}