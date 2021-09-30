// SPDX-License-Identifier: MIT

// Adapted from BoringBananasCo


import "./ERC721_flat.sol";

pragma solidity ^0.8.0;
pragma abicoder v2;

contract AniGirls is ERC721, Ownable, nonReentrant {
    
    string public ANIGIRLS_PROVENANCE = ""; // IPFS URL WILL BE ADDED WHEN ANIGIRLS ARE ALL SOLD OUT
    
    uint256 public aniPrice = 50000000000000000; // 0.05 ETH
	
	uint public constant maxAniGirlPurchase = 25;

    uint256 public constant MAX_ANIGIRLS = 5555;
		
    // Reserve AniGirls for team - Giveaways/Prizes etc
	uint public constant MAX_ANIRESERVE = 100;	// total team reserves allowed
    uint public aniReserve = MAX_ANIRESERVE;	// counter for team reserves remaining 
	

    bool public saleIsActive = false;

    constructor() ERC721("AniGirlsNFT", "ANIME") { }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
	
	function setAniGirlPrice(uint256 _aniPrice) public onlyOwner {
        aniPrice = _aniPrice;
    }
    
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        ANIGIRLS_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
	
    function reserveAniGirl(address _to, uint256 _reserveAmount) public onlyOwner {
        uint reserveMint = MAX_ANIRESERVE - aniReserve;
        require(_reserveAmount > 0 && _reserveAmount < aniReserve + 1, "Not enough reserve left for team");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, reserveMint + i);
        }
        aniReserve = aniReserve - _reserveAmount;
    }


    function mintAniGirl(uint numberOfTokens) public payable reentryLock {
        require(saleIsActive, "Sale must be active to mint token");
		require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(numberOfTokens > 0 && numberOfTokens < maxAniGirlPurchase + 1, "Can only mint 10 AniGirls at a time");
        require(totalSupply() + numberOfTokens < MAX_ANIGIRLS - aniReserve + 1, "Purchase would exceed max supply of AniGirls");
        require(msg.value >= aniPrice * numberOfTokens, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply() + aniReserve; // start minting after reserved tokenIds
            if (totalSupply() < MAX_ANIGIRLS) {
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