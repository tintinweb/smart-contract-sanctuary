// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;

import './ERC721.sol';
import './Ownable.sol';
import './SafeERC20.sol';

contract SamuraiDoge is ERC721, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    string public SAMURAI_PROVENANCE = "";

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    uint256 public samuraidogePrice;

    uint public maxSamuraiPurchase;

    uint256 public MAX_DOGES;

    bool public saleIsActive = false;

    bool public preSaleIsActive = false;

    bool public freeSaleIsActive = false;

    bool public primarySaleIsActive = false;

    uint256 public REVEAL_TIMESTAMP;
    
    mapping(uint => string) public avatarNames;

    uint256 freeMintCycle = 399;
    uint256 preMintCycle = 1399;
    uint256 primaryMintCycle = 5399;
    
    ERC20 public token;
    uint public totalCharacters;
    struct Character {
        bool activated;
        string name;
        uint16 gender;
        address ref;
        uint invitedCount;
    }
    mapping(address => Character) public characters;
    
    constructor(string memory name, string memory symbol, uint256 maxNftSupply, uint256 saleStart, ERC20 token_) ERC721(name, symbol) {
        MAX_DOGES = maxNftSupply;
        REVEAL_TIMESTAMP = saleStart + (86400 * 9);
        token = token_;
        characters[msg.sender].activated = true;
    }
    
    function addCharacter(string memory name, uint16 gender, address ref) external {
        Character storage referrer = characters[ref];
        require(referrer.activated, "Referrer is not activated");
        Character storage character = characters[msg.sender];
        character.name = name;
        character.gender = gender;
        if (! character.activated) {
            character.activated = true;
            character.ref = ref;
            referrer.invitedCount = referrer.invitedCount.add(1);
            totalCharacters = totalCharacters.add(1);
        }
    }

    function setAvatarName(uint256 _index , string memory _avatarName) public {
        require(ownerOf(_index) == msg.sender);
        avatarNames[_index] = _avatarName;
    }

    function freeMintSamurai() public {
        Character storage character = characters[msg.sender];
        require(character.activated, "Character is not activated");
        require(character.invitedCount >= 2, "The number of invitations must be greater than or equal to 2");
        require(freeSaleIsActive, "Sale must be active to mint Samurai Doge");
        require(totalSupply() <= freeMintCycle);

        uint mintIndex = totalSupply();
        if (totalSupply() <= freeMintCycle) {
            _safeMint(msg.sender, mintIndex);
        }

    }

    function preMintSamurai(uint numberOfTokens) public {
        require(preSaleIsActive, "Sale must be active to mint Samurai Doge");
        require(maxSamuraiPurchase > 0);
        require(totalSupply() <= preMintCycle);
        require(numberOfTokens <= maxSamuraiPurchase, "Can only mint 5 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_DOGES, "Purchase would exceed max supply of Samurai Doges");
        
        uint totalPrice = samuraidogePrice.mul(numberOfTokens);
        require(token.balanceOf(msg.sender) >= totalPrice, "Token balance is insufficient");
        token.safeTransferFrom(msg.sender, address(this), totalPrice);
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() <= preMintCycle) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        if (startingIndexBlock == 0 && (totalSupply() == MAX_DOGES)) {
            startingIndexBlock = block.number;
        }
    }

    function primaryMintSamurai(uint numberOfTokens) public {
        require(primarySaleIsActive, "Sale must be active to mint Samurai Doges");
        require(maxSamuraiPurchase > 0);
        require(numberOfTokens <= maxSamuraiPurchase, "Can only mint 5 tokens at a time");
        require(totalSupply() <= primaryMintCycle);
        require(totalSupply().add(numberOfTokens) <= MAX_DOGES, "Purchase would exceed max supply of Samurai Doges");
        
        uint totalPrice = samuraidogePrice.mul(numberOfTokens);
        require(token.balanceOf(msg.sender) >= totalPrice, "Token balance is insufficient");
        token.safeTransferFrom(msg.sender, address(this), totalPrice);

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() <= primaryMintCycle) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        if (startingIndexBlock == 0 && (totalSupply() == MAX_DOGES)) {
            startingIndexBlock = block.number;
        }
    }

    function postMintSamurai(uint numberOfTokens) public {
        require(saleIsActive, "Sale must be active to mint Samurai Doges");
        require(maxSamuraiPurchase > 0);
        require(numberOfTokens <= maxSamuraiPurchase, "Can only mint 5 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_DOGES, "Purchase would exceed max supply of Samurai Doges");
        
        uint totalPrice = samuraidogePrice.mul(numberOfTokens);
        require(token.balanceOf(msg.sender) >= totalPrice, "Token balance is insufficient");
        token.safeTransferFrom(msg.sender, address(this), totalPrice);

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_DOGES) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        if (startingIndexBlock == 0 && (totalSupply() == MAX_DOGES)) {
            startingIndexBlock = block.number;
        }
    }

    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_DOGES;
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_DOGES;
        }
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    
    
    //*************************** onlyOwner ********************************
    
    function addAvatar(uint256 _index , string memory _avatarName) public payable onlyOwner {
        avatarNames[_index] = _avatarName;
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function reserveSamurai() public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < 200; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
        REVEAL_TIMESTAMP = revealTimeStamp;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        SAMURAI_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }


    function flipFreeSaleState() public onlyOwner {
        freeSaleIsActive = !freeSaleIsActive;
    }

    function flipPreSaleState(uint256 price, uint256 _maxMint) public onlyOwner {
        samuraidogePrice = price;
        setMaxperTransaction(_maxMint);
        preSaleIsActive = !preSaleIsActive;
    }

    function flipPrimarySaleState(uint256 price, uint256 _maxMint) public onlyOwner {
        samuraidogePrice = price;
        setMaxperTransaction(_maxMint);
        primarySaleIsActive = !primarySaleIsActive;
    }

    function flipFinalSaleState(uint256 price, uint256 _maxMint) public onlyOwner {
        samuraidogePrice = price;
        setMaxperTransaction(_maxMint);
        saleIsActive = !saleIsActive;
    }
    
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        startingIndexBlock = block.number;
    }
    
    function collectToken(address _addr, uint _amount) external onlyOwner {
        require(_addr != address(0), "Address is null");
        token.transfer(_addr, _amount);
    }
    
    
    
    //*************************** internal ********************************
    
    function setMaxperTransaction(uint256 _maxNFTPerTransaction) internal onlyOwner {
        maxSamuraiPurchase = _maxNFTPerTransaction;
    }
}