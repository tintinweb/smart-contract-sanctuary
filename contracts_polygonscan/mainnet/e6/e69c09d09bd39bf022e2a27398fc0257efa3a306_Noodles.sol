// SPDX-License-Identifier: MIT

// Adapted from BoringBananasCo
// Modified and updated to 0.8.0 by Gerardo Gomez
// Noodles Art by Gerardo Gomez
// <3 The Gomez Family
// Special thanks to NOUNDLES Fam for inspiring me to create this Noundles/Doodles Derivitive 

import "./ERC721_flat.sol";

pragma solidity ^0.8.0;
pragma abicoder v2;

contract Noodles is ERC721, Ownable, nonReentrant {

    string public Noodles_PROVENANCE = ""; // IPFS URL WILL BE ADDED WHEN NOODLES ARE ALL SOLD OUT
    
    uint256 public NoodlesPrice = 5000000000000000000; // 5 Matic = About .001 ETH BOIS!

    uint public constant maxNoodlesPurchase = 100;

    uint256 public constant MAX_Noodles = 8888;

    bool public saleIsActive = false;
    
    // mapping(uint => string) public NoodlesNames;
    
    // Reserve Noodles for team - Giveaways/Prizes etc
	uint public constant MAX_NoodlesRESERVE = 200;	// total team reserves allowed
    uint public NoodlesReserve = MAX_NoodlesRESERVE;	// counter for team reserves remaining 
    
    constructor() ERC721("Noodles", "NOODS") { }
    
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

	
	function setNoodlesPrice(uint256 _NoodlesPrice) public onlyOwner {
        NoodlesPrice = _NoodlesPrice;
    }
	
	
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        Noodles_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }


    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    
    function reserveNoodles(address _to, uint256 _reserveAmount) public onlyOwner {        
        uint reserveMint = MAX_NoodlesRESERVE - NoodlesReserve; // Mint from beginning of tokenIds
        require(_reserveAmount > 0 && _reserveAmount < NoodlesReserve + 1, "Not enough reserve left to fulfill amount");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, reserveMint + i);
        }
        NoodlesReserve = NoodlesReserve - _reserveAmount;
    }


    function mintNoodles(uint numberOfTokens) public payable reentryLock {
        require(saleIsActive, "Sale must be active to mint Noodles");
        require(numberOfTokens > 0 && numberOfTokens < maxNoodlesPurchase + 1, "Can only mint 100 tokens at a time");
        require(totalSupply() + numberOfTokens < MAX_Noodles - NoodlesReserve + 1, "Purchase would exceed max supply of Noodles");
        require(msg.value >= NoodlesPrice * numberOfTokens, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply() + NoodlesReserve; // start minting after reserved tokenIds
            if (totalSupply() < MAX_Noodles) {
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