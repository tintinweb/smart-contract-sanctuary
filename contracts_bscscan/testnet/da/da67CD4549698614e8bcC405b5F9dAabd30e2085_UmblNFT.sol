// contracts/UmblNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC165.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract UmblNFT is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {    
    using SafeMath for uint8;
    using SafeMath for uint256;
    using Strings for string;

    uint public constant MAX_MINT_TOKEN_COUNT = 100000;
    uint public constant MAX_CRATE_TOKEN_COUNT = 100;

    enum TokenFaction {
        NEVER_USED,
        SURVIVORS,
        SCIENTISTS,
        UNSPECIFIED
    }

    enum TokenStatus { 
        NEVER_USED,
        MINTED,
        PURCHASED, 
        EQUIPPED,
        STAKED 
    }

    enum TokenCategory {
        NEVER_USED,
        WEAPONS,
        ARMOR,
        ACCESORIES,
        VIRUSES_BACTERIA,
        PARASITES_FUNGUS,
        VIRUS_VARIANTS,
        BADGES
    }

    enum TokenRarity {
        NEVER_USED,
        COMMON,
        UNCOMMON,
        UNIQUE,
        RARE,
        EPIC,
        LEGENDARY,
        MYTHICAL,
        BRONZE,
        SILVER,
        GOLD,
        DIAMOND,
        BLACK_DIAMOND
    }

    // token data structure    
    struct UmblData {
        uint256 id;
        uint256 price;
        TokenStatus status;
        TokenFaction faction;
        TokenCategory category;
        TokenRarity rarity;
    }

    struct UmblCrate {
        uint256 id;         
        uint256 tokenCount;        
        uint256 price;
        TokenFaction faction;
        uint256 level;        
        TokenRarity[] rarities;     
        bool isDeleted;
    }

    // Flag for sale feature enable/disable
    bool public isEnabledSale = false;

    // map token id to umbl data
    mapping(uint256 => UmblData) public tokenUmblData;

    // map token id to umbl data
    mapping(uint256 => UmblCrate) public crateUmblData;

    // array for umbl crates
    // UmblCrate[] public crateUmblData;

    string private _baseTokenURI;

    uint public nextTokenId = 0;
    uint public nextCrateId = 0;

    // initialize contract while deployment with contract's token name and symbol
    constructor(string memory baseURI) ERC721("Umbl NFT", "UMBL") {
        setBaseURI(baseURI);
    }  

    /*
    * Get the tokens owned by _owner
    */
    function tokensOfOwner(address _owner) 
        external 
        view 
        returns(uint256[] memory) 
    {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
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

    // Mint multiple tokens
    function mintToken(uint256 _numTokens, uint256 _faction, uint256 _category, uint256 _rarity, uint256 _price) 
        public 
        onlyOwner 
        nonReentrant
    {
        require(_numTokens > 0 && _numTokens <= MAX_MINT_TOKEN_COUNT, "Must mint from 1 to 100000 NFTs");
        require(_category >= uint256(TokenCategory.WEAPONS) && _category <= uint256(TokenCategory.BADGES), "Token Category must be from WEAPONS to BADGES");
        require(_rarity >= uint256(TokenRarity.COMMON) && _rarity <= uint256(TokenRarity.BLACK_DIAMOND), "Token Rarity must be from COMMON to BLACK_DIAMOND");

        if(_category != uint256(TokenCategory.BADGES)) {
            require(_faction >= uint256(TokenFaction.SURVIVORS) && _faction <= uint256(TokenFaction.SCIENTISTS), "Token Faction must be from SURVIVORS to SCIENTISTS");
            require(_rarity >= uint256(TokenRarity.COMMON) && _rarity <= uint256(TokenRarity.MYTHICAL), "Normal Token Rarity musts be from COMMON to MYTHICAL");
        } else {
            require(_faction == uint256(TokenFaction.UNSPECIFIED), "Badge Token Faction must be UNSPECIFIED");
            require(_rarity >= uint256(TokenRarity.BRONZE) && _rarity <= uint256(TokenRarity.BLACK_DIAMOND), "Badge Token Rarity musts be from BRONZE to BLACK_DIAMOND");
        }

        if(_faction == uint256(TokenFaction.SURVIVORS)) {
            require(_category >= uint256(TokenCategory.WEAPONS) && _category <= uint256(TokenCategory.ACCESORIES), "SURVIVORS Token Category must be from WEAPONS to ACCESORIES");
        } else if(_faction == uint256(TokenFaction.SCIENTISTS)) {
            require(_category >= uint256(TokenCategory.VIRUSES_BACTERIA) && _category <= uint256(TokenCategory.VIRUS_VARIANTS), "SCIENTISTS Token Category must be from VIRUSES_BACTERIA to VIRUS_VARIANTS");
        }

        require(_price > 0, "Price must be greater than zero");

        // mint all of these tokens
        for(uint i=0; i<_numTokens; i++) {
            // increase next token ID
            nextTokenId++;

            // mint token
            _safeMint(owner(), nextTokenId);

            // create a new token struct and pass it new values
            UmblData memory newUmblData = UmblData(
                nextTokenId,
                _price,
                TokenStatus.MINTED,
                TokenFaction(_faction),
                TokenCategory(_category),
                TokenRarity(_rarity)
            );

            // add the token id and it's struct to all tokens mapping
            tokenUmblData[nextTokenId] = newUmblData;
        }
    }

    // Add crates
    function addCrate(uint256 _numTokens, uint256 _faction, uint256 _level, uint256[] memory _rarities, uint256 _price) 
        public
        onlyOwner
        nonReentrant
    {
        require(_numTokens > 0 && _numTokens <= MAX_CRATE_TOKEN_COUNT, "Must include from 1 to 100 tokens");
        require(_price > 0, "Price must be greater than zero");        
        require(_faction >= uint256(TokenFaction.SURVIVORS) && _faction <= uint256(TokenFaction.SCIENTISTS), "Token Faction must be from SURVIVORS to SCIENTISTS");
        require(_rarities.length > 0, "Must include at least one rarities");
        for(uint i=0; i<_rarities.length; i++)
            require(_rarities[i] >= uint256(TokenRarity.COMMON) && _rarities[i] <= uint256(TokenRarity.MYTHICAL), "Must rarity from COMMON to MYTHICAL");        
        
        // add a new crate struct and pass it new values
        nextCrateId++;

        UmblCrate memory newCrateData = UmblCrate(
            nextCrateId,
            _numTokens,
            _price,
            TokenFaction(_faction),
            _level,
            new TokenRarity[](0),            
            false            
        );

        // link the struct to all crates mapping
        crateUmblData[nextCrateId] = newCrateData;

        // add rarities to that mapping item
        for(uint i=0; i<_rarities.length; i++) {
            crateUmblData[nextCrateId].rarities.push(TokenRarity(_rarities[i]));
        }
    }

    function getCrateRarities(uint256 _index) 
        public 
        view 
        returns (uint256[] memory)
    {
        require(_index <= nextCrateId, "CrateId is not exist");

        uint256[] memory result = new uint256[](crateUmblData[_index].rarities.length);

        for(uint i=0; i<crateUmblData[_index].rarities.length; i++) {
            result[i] = uint256(crateUmblData[_index].rarities[i]);
        }

        return result;
    }

    // Enable token isEquipped flag, lock it on saleso that lock it on sale
    function setTokenStatus(uint256 _tokenId, uint256 _tokenStatus) 
        public payable
    {
        // require that token should exist
        require(_exists(_tokenId));

        // check current call is same with the token's owner
        require(ownerOf(_tokenId) == msg.sender);

        // get the token from all UmblData mapping and create a memory of it as defined
        UmblData memory umblData = tokenUmblData[_tokenId];

        // check tokenstatus value is on available range
        require(TokenStatus(_tokenStatus) >= TokenStatus.EQUIPPED && TokenStatus(_tokenStatus) <= TokenStatus.STAKED);

        // check current token status is not same with parameter        
        require(umblData.status != TokenStatus(_tokenStatus));

        // update the token's forSale to false
        umblData.status = TokenStatus(_tokenStatus);

        // set and update that token in the mapping
        tokenUmblData[_tokenId] = umblData;
    }

    // by a crate
    function buyCrate(uint256 _crateId)
        public payable
    {
        // check if the function caller is not an zero address account
        require(msg.sender != address(0));

        // check caller is not owner of the contract
        require(msg.sender != owner());

        // check _crateId
        require(_crateId <= nextCrateId, "CrateId is not exist");
        
        UmblCrate memory crateData = crateUmblData[_crateId];

        // price sent in to buy should be equal to or more than the crate's price
        require(msg.value >= crateData.price);

        // check available token count
        uint availableTokenCount = 0;
        for(uint i=0; i<crateData.rarities.length; i++) {
            for(uint j=1; j<=nextTokenId; j++) {   
                if(tokenUmblData[j].status == TokenStatus.MINTED && tokenUmblData[j].rarity == crateData.rarities[i] && tokenUmblData[j].faction == crateData.faction) {
                    availableTokenCount++;
                }
            }
        }

        require(availableTokenCount >= crateData.tokenCount, "There are no enough available tokens");

        uint[] memory availableTokens = new uint[](availableTokenCount);
        uint availableTokenId = 0;
        for(uint i=0; i<crateData.rarities.length; i++) {
            for(uint j=1; j<=nextTokenId; j++) {   
                if(tokenUmblData[j].status == TokenStatus.MINTED && tokenUmblData[j].rarity == crateData.rarities[i] && tokenUmblData[j].faction == crateData.faction) {
                    availableTokens[availableTokenId++] = j;
                }
            }
        }

        // Get random tokens for the crate
        uint[] memory selectedTokens = new uint[](crateData.tokenCount);
        uint selectedTokenId = 0;
        uint nonce = 1;

        for(uint i=0; i<crateData.tokenCount; i++) {
            while(true) {
                uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce++))) % availableTokenCount;
                bool existFlag = false;
                for(uint j=0; j<selectedTokenId; j++) {
                    if(!existFlag && randomNumber == selectedTokens[j]) {
                        existFlag = true;
                        break;
                    }
                }
                if(!existFlag) {
                    selectedTokens[selectedTokenId++] = randomNumber;
                    break;
                }
            }            
        }

        for(uint i=0; i<crateData.tokenCount; i++) {
            // get token id
            uint tokenId = availableTokens[selectedTokens[i]];

            // get owner address of the token
            address tokenOwner = ownerOf(tokenId);

            // transfer tokens to buyer
            _transfer(tokenOwner, msg.sender, tokenId);

            // update token status to purchased
            UmblData memory umblData = tokenUmblData[tokenId];

            // update the token's forSale to false
            umblData.status = TokenStatus.PURCHASED;

            // set and update that token in the mapping
            tokenUmblData[tokenId] = umblData;

        }

        address payable ownerAddress = payable(owner());

        // send price to the owner
        ownerAddress.transfer(msg.value);
    }

    // buy a token by passing in the token's id
    function buyToken(uint256 _tokenId)
        public payable
    {        
        require(isEnabledSale == true, "Marketplace feature is not enabled");

        // check if the function caller is not an zero address account
        require(msg.sender != address(0));

        // check if the token id of the token being bought exists or not
        require(_exists(_tokenId));

        // get the token's owner
        address tokenOwner = ownerOf(_tokenId);

        // token's owner should not be an zero address account
        require(tokenOwner != address(0));

        // the one who wants to buy the token should not be the token's owner
        require(tokenOwner != msg.sender);

        // get the token from all UmblData mapping and create a memory of it as defined
        UmblData memory umblData = tokenUmblData[_tokenId];

        // price sent in to buy should be equal to or more than the token's price
        require(msg.value >= umblData.price);

        // token should be for sale
        require(umblData.status == TokenStatus.PURCHASED);

        // transfer the token from owner to the caller of the function (buyer)
        _transfer(tokenOwner, msg.sender, _tokenId);

        // get owner of the token
        address payable sendTo = payable(tokenOwner);
        address payable tokenOwnerAddress = payable(owner());

        // get divided value of total token price
        uint256 _priceToOwner = msg.value / 10;
        uint256 _priceToSeller = msg.value - _priceToOwner;

        // send 10% token's worth of bnb to the owner
        tokenOwnerAddress.transfer(_priceToOwner);

        // send 90% token's worth of bnb to the owner
        sendTo.transfer(_priceToSeller);
    }

    // update token's price
    function changeTokenPrice(uint256 _tokenId, uint256 _newPrice)
        public payable
    {
        require(isEnabledSale == true, "Marketplace feature is not enabled");

        // require that token should exist
        require(_exists(_tokenId));

        // check the token's owner should be equal to the caller of the function
        require(ownerOf(_tokenId) == msg.sender);

        // get the token's struct from mapping and create a memory of it
        UmblData memory umblData = tokenUmblData[_tokenId];

        // update the token's price with new price
        umblData.price = _newPrice;

        // set and update the token in the mapping
        tokenUmblData[_tokenId] = umblData;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    } 

    function tokenURI(uint256 tokenId) 
        public 
        view 
        override(ERC721) 
        returns (string memory) 
    {
        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI)) : "";
    }      

    function _setBaseURI(string memory baseURI) 
        internal 
        virtual 
    {
        _baseTokenURI = baseURI;
    }

    // Administrative zone
    function setBaseURI(string memory baseURI) 
        public 
        onlyOwner 
    {
        _setBaseURI(baseURI);
    }

    function startMarketPlace() 
        public 
        onlyOwner 
    {
        isEnabledSale = true;
    }

    function pauseMarketPlace() 
        public 
        onlyOwner 
    {
        isEnabledSale = false;
    }

    function deleteCrate(uint256 _index) 
        public
        onlyOwner
    {
        require(_index <= nextCrateId);

        crateUmblData[_index].isDeleted = true;
    }
}