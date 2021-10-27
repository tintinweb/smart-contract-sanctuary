// SPDX-License-Identifier: MIT

// Adapted from BoringBananasCo
// Modified and updated to 0.8.0 by Gerardo Gomez
// The Viking Army art by Nathan Buford
// <3 The Gomez Family
// Special thanks to BoringBananasCo & Blockhead Devs for all the resources & assistance along the way!

import "./ERC721_flat.sol";

pragma solidity ^0.8.0;
pragma abicoder v2;

contract UpsidePunks is ERC721, Ownable, nonReentrant {

    string public UPSIDEPUNKS_PROVENANCE = ""; // IPFS URL WILL BE ADDED WHEN UPSIDE PUNKS ARE ALL SOLD OUT
    
    uint256 public upsidepunksPrice = 40000000000000000; // 0.04 ETH

    uint public constant maxUpsidePunksPurchase = 15;

    uint256 public constant MAX_UPSIDEPUNKS = 12222;

    bool public saleIsActive = false;
    
    // mapping(uint => string) public upsidepunksNames;
    
    // Reserve UpsidePunks for team - Giveaways/Prizes etc
	uint public constant MAX_UPSIDEPUNKSRESERVE = 244;	// total team reserves allowed
    uint public UpsidePunksReserve = MAX_UPSIDEPUNKSRESERVE;	// counter for team reserves remaining 
    
    constructor() ERC721("Upside Punks", "UPUNKS") { }
    
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

	
	function setUpsidePunksPrice(uint256 _upsidepunksPrice) public onlyOwner {
        upsidepunksPrice = _upsidepunksPrice;
    }
	
	
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        UPSIDEPUNKS_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }


    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    
    function reserveUpsidePunks(address _to, uint256 _reserveAmount) public onlyOwner {        
        uint reserveMint = MAX_UPSIDEPUNKSRESERVE - UpsidePunksReserve; // Mint from beginning of tokenIds
        require(_reserveAmount > 0 && _reserveAmount < UpsidePunksReserve + 1, "Not enough reserve left to fulfill amount");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, reserveMint + i);
        }
        UpsidePunksReserve = UpsidePunksReserve - _reserveAmount;
    }


    function mintUpsidePunks(uint numberOfTokens) public payable reentryLock {
        require(saleIsActive, "Sale must be active to mint UpsidePunks");
        require(numberOfTokens > 0 && numberOfTokens < maxUpsidePunksPurchase + 1, "Can only mint 15 tokens at a time");
        require(totalSupply() + numberOfTokens < MAX_UPSIDEPUNKS - UpsidePunksReserve + 1, "Purchase would exceed max supply of UpsidePunks");
        require(msg.value >= upsidepunksPrice * numberOfTokens, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply() + UpsidePunksReserve; // start minting after reserved tokenIds
            if (totalSupply() < MAX_UPSIDEPUNKS) {
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