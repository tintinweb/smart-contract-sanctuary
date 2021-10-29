// SPDX-License-Identifier: MIT

// Adapted from BoringBananasCo
// Modified and updated to 0.8.0 by Gerardo Gomez
// Pumpkins by Elijah
// <3 The Gomez Family
// Special thanks to BoringBananasCo & Blockhead Devs for all the resources & assistance along the way!

import "./ERC721_flat.sol";

pragma solidity ^0.8.0;
pragma abicoder v2;

contract Pumpkins is ERC721, Ownable, nonReentrant {

    string public PUMPKINS_PROVENANCE = ""; // IPFS URL WILL BE ADDED WHEN PUMPKINS ARE ALL SOLD OUT
    
    uint256 public pumpkinsPrice = 5000000000000000000; // 5 MATIC POLYGON .0025 ETH 

    uint public constant maxPumpkinsPurchase = 40;

    uint256 public constant MAX_PUMPKINS = 3100;

    bool public saleIsActive = false;
    
    mapping(uint => string) public pumpkinsNames;
    
    // Reserve Pumpkins for team - Giveaways/Prizes etc
	uint public constant MAX_PUMPKINSRESERVE = 310;	// total team reserves allowed
	
	event pumpkinsNameChange(address _by, uint _tokenId, string _name);
	
    uint public PumpkinsReserve = MAX_PUMPKINSRESERVE;	// counter for team reserves remaining 
    
    constructor() ERC721("Pumpkins", "Pumpkins") { }
    
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

	
	function setPumpkinsPrice(uint256 _pumpkinsPrice) public onlyOwner {
        pumpkinsPrice = _pumpkinsPrice;
    }
	
     
    function changePumpkinsName(uint _tokenId, string memory _name) public {
        require(ownerOf(_tokenId) == msg.sender, "Hey, your wallet doesn't own this Pumpkin!");
        require(sha256(bytes(_name)) != sha256(bytes(pumpkinsNames[_tokenId])), "New name is same as the current one");
        pumpkinsNames[_tokenId] = _name;
        
        emit pumpkinsNameChange(msg.sender, _tokenId, _name);
        
    }
	
	function viewPumpkinsName(uint _tokenId) public view returns( string memory ){
        require( _tokenId < totalSupply(), "Choose a Pumpkin within range" );
        return pumpkinsNames[_tokenId];
    }
	
	
	
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PUMPKINS_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }


    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    
    function reservePumpkins(address _to, uint256 _reserveAmount) public onlyOwner {        
        uint reserveMint = MAX_PUMPKINSRESERVE - PumpkinsReserve; // Mint from beginning of tokenIds
        require(_reserveAmount > 0 && _reserveAmount < PumpkinsReserve + 1, "Not enough reserve left to fulfill amount");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, reserveMint + i);
        }
        PumpkinsReserve = PumpkinsReserve - _reserveAmount;
    }


    function mintPumpkins(uint numberOfTokens) public payable reentryLock {
        require(saleIsActive, "Sale must be active to mint Pumpkins");
        require(numberOfTokens > 0 && numberOfTokens < maxPumpkinsPurchase + 1, "Can only mint 15 tokens at a time");
        require(totalSupply() + numberOfTokens < MAX_PUMPKINS - PumpkinsReserve + 1, "Purchase would exceed max supply of Pumpkins");
        require(msg.value >= pumpkinsPrice * numberOfTokens, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply() + PumpkinsReserve; // start minting after reserved tokenIds
            if (totalSupply() < MAX_PUMPKINS) {
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