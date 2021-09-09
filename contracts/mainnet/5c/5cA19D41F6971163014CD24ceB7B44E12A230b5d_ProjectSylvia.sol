// SPDX-License-Identifier: MIT

// Adapted from BoringBananasCo
// Modified and updated to 0.8.0 by @Danny_One_
// Project Sylvia art by @kakigaijin
// <3 VeVefam
// Special thanks to BoringBananasCo & Blockhead Devs for all the resources & assistance along the way!

import "./ERC721_flat.sol";

pragma solidity ^0.8.0;
pragma abicoder v2;

contract ProjectSylvia is ERC721, Ownable, nonReentrant {

    string public SYLVIA_PROVENANCE = ""; // IPFS URL WILL BE ADDED WHEN SYLVIAS ARE ALL SOLD OUT
    
    uint256 public sylPrice = 20000000000000000; // 0.02 ETH

    uint public constant maxSylviaPurchase = 15;

    uint256 public constant MAX_SYLVIAS = 8888;

    bool public saleIsActive = false;
    
    // mapping(uint => string) public sylviaNames;
    
    // Reserve SYL for team - Giveaways/Prizes etc
	uint public constant MAX_SYLRESERVE = 100;	// total team reserves allowed
    uint public sylReserve = MAX_SYLRESERVE;	// counter for team reserves remaining 
    
    constructor() ERC721("Project Sylvia", "SYL") { }
    
    // withraw to project wallet
    function withdraw(uint256 _amount, address payable _owner) public onlyOwner {
        require(_owner == owner());
        require(_amount < address(this).balance + 1);
        _owner.transfer(_amount);
    }
    
    // withdraw to team
	function teamWithdraw(address payable _team1, address payable _team2) public onlyOwner {
        uint balance1 = address(this).balance / 2;
		uint balance2 = address(this).balance - balance1;
		_team1.transfer(balance1);
		_team2.transfer(balance2);
    }

	
	function setSylviaPrice(uint256 _sylPrice) public onlyOwner {
        sylPrice = _sylPrice;
    }
	
	
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        SYLVIA_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }


    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    
    function reserveSylvias(address _to, uint256 _reserveAmount) public onlyOwner {        
        uint reserveMint = MAX_SYLRESERVE - sylReserve; // Mint from beginning of tokenIds
        require(_reserveAmount > 0 && _reserveAmount < sylReserve + 1, "Not enough reserve left to fulfill amount");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, reserveMint + i);
        }
        sylReserve = sylReserve - _reserveAmount;
    }


    function mintSylvia(uint numberOfTokens) public payable reentryLock {
        require(saleIsActive, "Sale must be active to mint Sylvia");
        require(numberOfTokens > 0 && numberOfTokens < maxSylviaPurchase + 1, "Can only mint 10 tokens at a time");
        require(totalSupply() + numberOfTokens < MAX_SYLVIAS - sylReserve + 1, "Purchase would exceed max supply of Sylvia");
        require(msg.value >= sylPrice * numberOfTokens, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply() + sylReserve; // start minting after reserved tokenIds
            if (totalSupply() < MAX_SYLVIAS) {
                _safeMint(msg.sender, mintIndex);
            }
        }

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
	
    
}