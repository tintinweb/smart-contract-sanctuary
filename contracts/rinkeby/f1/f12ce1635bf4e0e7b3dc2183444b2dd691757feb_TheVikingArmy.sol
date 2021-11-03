// SPDX-License-Identifier: MIT

// Adapted from BoringBananasCo
// Modified and updated to 0.8.0 by Gerardo Gomez
// The Viking Army art by Nathan Buford
// <3 The Gomez Family
// Special thanks to BoringBananasCo & Blockhead Devs for all the resources & assistance along the way!

import "./ERC721_flat.sol";

pragma solidity ^0.8.0;
pragma abicoder v2;

contract TheVikingArmy is ERC721, Ownable, nonReentrant {

    string public THEVIKINGARMY_PROVENANCE = ""; // IPFS URL WILL BE ADDED WHEN TheVikingArmy ARE ALL SOLD OUT
    
    uint256 public thevikingarmyPrice = 50000000000000000000; // 50 Matic .02 ETH

    uint public constant maxTheVikingArmyPurchase = 40;

    uint256 public constant MAX_THEVIKINGARMY = 12222;

    bool public saleIsActive = false;
    
    mapping(uint => string) public thevikingarmyNames;
    
    // Reserve Vikings for team - Giveaways/Prizes etc
	uint public constant MAX_THEVIKINGARMYRESERVE = 1200;	// total team reserves allowed
	
	event thevikingarmyNameChange(address _by, uint _tokenId, string _name);
	
    uint public VikingArmyReserve = MAX_THEVIKINGARMYRESERVE;	// counter for team reserves remaining 
    
    constructor() ERC721("The Viking Army", "VikingArmy") { }
    
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

	
	function setTheVikingArmyPrice(uint256 _thevikingarmyPrice) public onlyOwner {
        thevikingarmyPrice = _thevikingarmyPrice;
    }
	
     
    function changeThevikingarmyName(uint _tokenId, string memory _name) public {
        require(ownerOf(_tokenId) == msg.sender, "Hey, your wallet doesn't own this Viking!");
        require(sha256(bytes(_name)) != sha256(bytes(thevikingarmyNames[_tokenId])), "New name is same as the current one");
        thevikingarmyNames[_tokenId] = _name;
        
        emit thevikingarmyNameChange(msg.sender, _tokenId, _name);
        
    }
	
	function viewThevikingarmyName(uint _tokenId) public view returns( string memory ){
        require( _tokenId < totalSupply(), "Choose a Viking within range" );
        return thevikingarmyNames[_tokenId];
    }
	
	
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        THEVIKINGARMY_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }


    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    
    function reserveTheVikingArmy(address _to, uint256 _reserveAmount) public onlyOwner {        
        uint reserveMint = MAX_THEVIKINGARMYRESERVE - VikingArmyReserve; // Mint from beginning of tokenIds
        require(_reserveAmount > 0 && _reserveAmount < VikingArmyReserve + 1, "Not enough reserve left to fulfill amount");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, reserveMint + i);
        }
        VikingArmyReserve = VikingArmyReserve - _reserveAmount;
    }


    function mintTheVikingArmy(uint numberOfTokens) public payable reentryLock {
        require(saleIsActive, "Sale must be active to mint TheVikingArmy");
        require(numberOfTokens > 0 && numberOfTokens < maxTheVikingArmyPurchase + 1, "Can only mint 15 tokens at a time");
        require(totalSupply() + numberOfTokens < MAX_THEVIKINGARMY - VikingArmyReserve + 1, "Purchase would exceed max supply of TheVikingArmy");
        require(msg.value >= thevikingarmyPrice * numberOfTokens, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply() + VikingArmyReserve; // start minting after reserved tokenIds
            if (totalSupply() < MAX_THEVIKINGARMY) {
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