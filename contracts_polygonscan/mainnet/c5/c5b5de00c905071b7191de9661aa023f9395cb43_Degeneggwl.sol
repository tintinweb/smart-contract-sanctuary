// SPDX-License-Identifier: MIT

// Modified and updated to 0.8.0 by Degenerate Eggs
// Degenerate Eggs Club by Degenerate Eggs
// We gonna moon Degens!
// Special thanks to the NFT Community, Life is good when you work for yourself...

import "./ERC721_flat.sol";

pragma solidity ^0.8.0;
pragma abicoder v2;

contract Degeneggwl is ERC721, Ownable, nonReentrant {

    string public Degeneggwl_PROVENANCE = ""; // IPFS URL WILL BE ADDED WHEN DEGENEGGWL ARE ALL SOLD OUT
    
    uint256 public DegeneggwlPrice = 10000000000000000000; // 10 Matic 

    uint public constant maxDegeneggwlPurchase = 1000;

    uint256 public constant MAX_Degeneggwl = 1000;

    bool public saleIsActive = false;
    
    // mapping(uint => string) public DegeneggwlNames;
    
    // Reserve Degeneggwl for team - Giveaways/Prizes etc
	uint public constant MAX_DegeneggwlRESERVE = 0;	// total team reserves allowed
    uint public DegeneggwlReserve = MAX_DegeneggwlRESERVE;	// counter for team reserves remaining 
    
    constructor() ERC721("Degeneggwl", "EGGWL") { }
    
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

	
	function setDegeneggwlPrice(uint256 _DegeneggwlPrice) public onlyOwner {
        DegeneggwlPrice = _DegeneggwlPrice;
    }
	
	
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        Degeneggwl_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }


    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    
    function reserveDegeneggwl(address _to, uint256 _reserveAmount) public onlyOwner {        
        uint reserveMint = MAX_DegeneggwlRESERVE - DegeneggwlReserve; // Mint from beginning of tokenIds
        require(_reserveAmount > 0 && _reserveAmount < DegeneggwlReserve + 1, "Not enough reserve left to fulfill amount");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, reserveMint + i);
        }
        DegeneggwlReserve = DegeneggwlReserve - _reserveAmount;
    }


    function mintDegeneggwl(uint numberOfTokens) public payable reentryLock {
        require(saleIsActive, "Sale must be active to mint Degeneggwl");
        require(numberOfTokens > 0 && numberOfTokens < maxDegeneggwlPurchase + 1, "Can only mint 1000 tokens at a time");
        require(totalSupply() + numberOfTokens < MAX_Degeneggwl - DegeneggwlReserve + 1, "Purchase would exceed max supply of Degeneggwl");
        require(msg.value >= DegeneggwlPrice * numberOfTokens, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply() + DegeneggwlReserve; // start minting after reserved tokenIds
            if (totalSupply() < MAX_Degeneggwl) {
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