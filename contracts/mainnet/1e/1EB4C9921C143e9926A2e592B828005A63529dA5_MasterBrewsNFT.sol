// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./EnumerableMap.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721Enumerable {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => bool) private _tokenURISet;
    string internal _defaultURIContent = "";
    bool internal _metadataFixed = false;
    
    function _defaultURI() internal view virtual returns (string memory) {
        return _defaultURIContent;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        string memory defaultURI = _defaultURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        
        // If the default metadata URI is set, concatenate the baseURI and defaultURI (via abi.encodePacked).
        if (bytes(defaultURI).length > 0) {
            return string(abi.encodePacked(base, defaultURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        // Change: we enforce changing a token URI only once, after metadata is fixed
        if (_metadataFixed) {
          require(_tokenURISet[tokenId] == false, "ERC721URIStorage: URI already set for this token");
          _tokenURISet[tokenId] = true;
        }
        
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

contract MasterBrewsNFT is ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;
    
    event PackOpened(address indexed _owner, uint indexed _packNo, uint _cardNo, uint _giftNo, uint _count);
    
    // Consumer cards: 0-14999 (15000 items)
    // Distributor cards: 15000-15299 (300 items)
    // Master Brewer cards: 15300-15359 (60 items)
    // Free packs: 15360-16359 (1000 items)
    uint256 public constant MAX_NFT_SUPPLY = 16360;
    
    // 1000 packs set aside to be given as gifts => 8000 total 1-card packs
    uint256 public constant MAX_PACKS_1CARD = 7000;
    uint256 public constant MAX_PACKS_3CARD = 1500;
    uint256 public constant MAX_PACKS_5CARD = 500;
    
    uint256 public constant PACK_1CARD_PRICE = 0.08 ether;
    uint256 public constant PACK_3CARD_PRICE = 0.21 ether;
    uint256 public constant PACK_5CARD_PRICE = 0.33 ether;
    
    uint256 public _totalPacks1Card = 0;
    uint256 public _totalPacks3Card = 0;
    uint256 public _totalPacks5Card = 0;
    
    uint256 public constant FIRST_CONSUMERS = 0;
    uint256 public constant FIRST_DISTRIBUTORS = 15000;
    uint256 public constant FIRST_MASTER_BREWERS = 15300;
    uint256 public constant FIRST_FREE_PACKS = 15360;
    
    uint256 public constant MAX_CONSUMERS = 15000;
    uint256 public constant MAX_DISTRIBUTORS = 15300;
    uint256 public constant MAX_MASTER_BREWERS = 15360;
    uint256 public MAX_FREE_PACKS = 16360;
    
    uint256 public _mintIndexConsumers = 0;
    uint256 public _mintIndexDistributors = 15000;
    uint256 public _mintIndexMasterBrewers = 15300;
    uint256 public _mintIndexFreePacks = 15360;

    bool public isMetadataSet = false;
    bool public isDefaultUriSet = false;
    bool public isContractInitialized = false;

    string public baseURI = "";
    
    address public initialDisbursementAddress = address(this);
    modifier onlyDisbursement() {
        if (msg.sender != initialDisbursementAddress)
            revert("Only disbursement address can trigger this");
        _;
    }
    
    // Gift - PLS&TY NFT: 0-0 (1 item)
    // Gift - The Brewmaster: 1-16 (16 items)
    // Gift - Master Brewer: 17-76 (60 items)
    // Gift - Distributor: 77-376 (300 items)
    // Gift - FREE Pack: 377-776 (400 items)
    // Gift - Luchador NFT: 777-1776 (1000 items)
    uint256 public MAX_GIFT_PLSTY = 1;
    uint256 public MAX_GIFT_BREWMASTER = 17;
    uint256 public MAX_GIFT_MASTER_BREWER = 77;
    uint256 public MAX_GIFT_DISTRIBUTOR = 377;
    uint256 public MAX_GIFT_FREE_PACK = 777;
    uint256 public MAX_GIFT_LUCHADOR = 1777;
    
    uint256 public constant MAX_PACKS = 10000;
    uint256 public packsLeft = 10000;
    
    // 400 free packs set aside as pack bonuses
    // 124 free packs = 62 consumers x2 at time of snapshot
    // 40 free packs = 10 distributors x4 at time of snapshot
    // 10 free packs = 2 master brewers x5 at time of snapshot
    // rest of packs up to 1000 can be awarded manually by staff
    uint256 public constant MAX_PACKS_AWARDED_MANUALLY = 426;
    uint256 public packsAwardedManually = 0;
    
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory __name, string memory __symbol)
        ERC721(__name, __symbol)
    {}
    
    // Disbursement contract
    
    function setDisbursementContract(address disbursementContract) external onlyOwner {
      require(isContractInitialized == false, "Contract must be uninitialized during migration");
      
      initialDisbursementAddress = disbursementContract;
    }

    // Metadata handlers
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function setBaseUri(string memory _uri) external onlyOwner {
        if (_metadataFixed) {
          require(isMetadataSet == false, "Metadata is already set");
        }
        baseURI = _uri;
        
        // Once contract is initialized, metadata can only be set once
        if (isContractInitialized) {
          isMetadataSet = true;
        }
    }
    
    function setDefaultUri(string memory _uri) external onlyOwner {
        if (_metadataFixed) {
          require(isDefaultUriSet == false, "Default URI is already set");
        }
        _defaultURIContent = _uri;
        
        // Once contract is initialized, default URI can only be set once
        if (isContractInitialized) {
          isDefaultUriSet = true;
        }
    }
    
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }
    
    function setMetadataFixed() external onlyOwner {
        _metadataFixed = true;
    }
    
    // Contract initialization and asset migration from previous versions
    
    function initializeContract() external onlyOwner {
      require(isContractInitialized == false, "Contract is already initialized");
      isContractInitialized = true;
    }
    
    function initialMigrateConsumerCard(address minter, uint256 index) external onlyDisbursement {
      require(isContractInitialized == false, "Contract must be uninitialized during migration");
      require(index > 0, "Index must be 1-based");
      
      // Consumer receives 2x free pack
      tryMintFreePack(minter);
      tryMintFreePack(minter);
    }
    
    function initialMigrateDistributorCard(address minter, uint256 index) external onlyDisbursement {
      require(isContractInitialized == false, "Contract must be uninitialized during migration");
      require(index > 0, "Index must be 1-based");
      
      uint256 i = index.sub(1).add(FIRST_DISTRIBUTORS);
      
      require(i < MAX_DISTRIBUTORS, "Invalid card");
      require(!_exists(i), "Token already minted");
      _mint(minter, i);
      
      if (i+1 > _mintIndexDistributors) {
        _mintIndexDistributors = i.add(1);
      }
      
      // update gift bounds starting at Distributor
      MAX_GIFT_DISTRIBUTOR--;
      MAX_GIFT_FREE_PACK--;
      MAX_GIFT_LUCHADOR--;
      
      // Distributor receives 4x free pack
      tryMintFreePack(minter);
      tryMintFreePack(minter);
      tryMintFreePack(minter);
      tryMintFreePack(minter);
    }
    
    function initialMigrateMasterBrewerCard(address minter, uint256 index) external onlyDisbursement {
      require(isContractInitialized == false, "Contract must be uninitialized during migration");
      require(index > 0, "Index must be 1-based");
      
      uint256 i = index.sub(1).add(FIRST_MASTER_BREWERS);
      
      require(i < MAX_MASTER_BREWERS, "Invalid card");
      require(!_exists(i), "Token already minted");
      _mint(minter, i);
      
      if (i+1 > _mintIndexMasterBrewers) {
        _mintIndexMasterBrewers = i.add(1);
      }
      
      // update gift bounds starting at Master Brewer
      MAX_GIFT_MASTER_BREWER--;
      MAX_GIFT_DISTRIBUTOR--;
      MAX_GIFT_FREE_PACK--;
      MAX_GIFT_LUCHADOR--;
      
      // Master Brewer buyers also get a Brewmaster which must be subtracted from pack rewards
      MAX_GIFT_BREWMASTER--;
      MAX_GIFT_MASTER_BREWER--;
      MAX_GIFT_DISTRIBUTOR--;
      MAX_GIFT_FREE_PACK--;
      MAX_GIFT_LUCHADOR--;
      
      // Master Brewer receives 5x free pack
      tryMintFreePack(minter);
      tryMintFreePack(minter);
      tryMintFreePack(minter);
      tryMintFreePack(minter);
      tryMintFreePack(minter);
    }
    
    // Consumer, Distributor, and Master Brewer minting
            
    function mintConsumerCards(address minter, uint256 count) private returns (uint256) {
      require(_mintIndexConsumers.add(count) <= MAX_CONSUMERS, "No more Consumer cards available");
      require(count > 0, "Count can't be less than 1");
      require(count <= 5, "Count can't be bigger than 5");
      
      uint256 initialCard = _mintIndexConsumers;
      
      for (uint256 i = 0; i < count; i++) {
        require(!_exists(_mintIndexConsumers), "Token already minted");
        _mint(minter, _mintIndexConsumers);
        _mintIndexConsumers++;
      }
      
      return initialCard;
    }
    
    function openFreePack(uint256 tokenId) external returns (uint256) {
      require(isContractInitialized, "Contract is not initialized");
      require(_exists(tokenId), "Token doesn't exist");
      require(ownerOf(tokenId) == msg.sender, "Sender must own token");
      require(tokenId >= FIRST_FREE_PACKS && tokenId < MAX_FREE_PACKS, "Token must be a pack");
      
      uint256 packIndex = MAX_PACKS - packsLeft;
      uint256 cardNo = mintConsumerCards(msg.sender, 1);
      uint256 giftNo = getPackBonus(msg.sender);
      
      emit PackOpened(msg.sender, packIndex, cardNo, giftNo, 1);
      _burn(tokenId);
      return giftNo;
    }
    
    function awardFreePack(address minter) external onlyOwner returns (bool) {
      require(packsAwardedManually.add(1) <= MAX_PACKS_AWARDED_MANUALLY, "Can't award any more packs");
      
      packsAwardedManually++;
      return tryMintFreePack(minter);
    }
    
    function tryMintFreePack(address minter) private returns (bool) {
      // don't mint if index is out of bounds
      // this is not an error, since the mint may have been initiated by a random draw
      // and we still need to keep the pack rather than reverting the whole transaction
      if (_mintIndexFreePacks.add(1) > MAX_FREE_PACKS) { 
        return false;
      }
    
      require(!_exists(_mintIndexFreePacks), "Token already minted");
      
      _mint(minter, _mintIndexFreePacks);
      _mintIndexFreePacks = _mintIndexFreePacks.add(1);
      
      return true;
    }
    
    function tryMintDistributorCard(address minter) private returns (bool) {
      // don't mint if index is out of bounds
      // this is not an error, since the mint may have been initiated by a random draw
      // and we still need to keep the pack rather than reverting the whole transaction
      if (_mintIndexDistributors.add(1) > MAX_DISTRIBUTORS) { 
        return false;
      }
    
      require(!_exists(_mintIndexDistributors), "Token already minted");
      
      _mint(minter, _mintIndexDistributors);
      _mintIndexDistributors = _mintIndexDistributors.add(1);
      
      return true;
    }
    
    function tryMintMasterBrewerCard(address minter) private returns (bool) {
      // don't mint if index is out of bounds
      // this is not an error, since the mint may have been initiated by a random draw
      // and we still need to keep the pack rather than reverting the whole transaction
      if (_mintIndexMasterBrewers.add(1) > MAX_MASTER_BREWERS) { 
        return false;
      }
    
      require(!_exists(_mintIndexMasterBrewers), "Token already minted");
      
      _mint(minter, _mintIndexMasterBrewers);
      _mintIndexMasterBrewers = _mintIndexMasterBrewers.add(1);
      
      return true;
    }
    
    // Pack handling
    
    /**
     * @dev Generates a random number in range 0-[giftsLeft], and awards the gift to the caller
     */
    function getPackBonus(address caller) private returns (uint256) {
      require(packsLeft > 0, "Something went wrong");
      
      // 0-based random index between 1-[max number of packs]
      uint256 i = (uint256(keccak256(abi.encodePacked(caller, block.difficulty, block.timestamp, packsLeft))) % packsLeft);
      packsLeft--;
    
      if (i >= MAX_GIFT_LUCHADOR) {
        // no gift won;
        return 0;
      }
      
      // Assign gift according to algorithm
      if (i >= MAX_GIFT_FREE_PACK) {
        // Luchador NFT gift awarded manually
        MAX_GIFT_LUCHADOR--;
        return 1;
      } else if (i >= MAX_GIFT_DISTRIBUTOR) {
        // FREE 1-card Pack gift
        if (tryMintFreePack(caller)) {
          MAX_GIFT_FREE_PACK--;
          MAX_GIFT_LUCHADOR--;
          return 2;
        }
      } else if (i >= MAX_GIFT_MASTER_BREWER) {
        // Distributor gift
        if (tryMintDistributorCard(caller)) {
          MAX_GIFT_DISTRIBUTOR--;
          MAX_GIFT_FREE_PACK--;
          MAX_GIFT_LUCHADOR--;
          return 3;
        }
      } else if (i >= MAX_GIFT_BREWMASTER) {
        // Master Brewer gift
        if (tryMintMasterBrewerCard(caller)) {
          MAX_GIFT_MASTER_BREWER--;
          MAX_GIFT_DISTRIBUTOR--;
          MAX_GIFT_FREE_PACK--;
          MAX_GIFT_LUCHADOR--;
          return 4;
        }
      } else if (i >= MAX_GIFT_PLSTY) {
        // Brewmaster gift awarded manually
        MAX_GIFT_BREWMASTER--;
        MAX_GIFT_MASTER_BREWER--;
        MAX_GIFT_DISTRIBUTOR--;
        MAX_GIFT_FREE_PACK--;
        MAX_GIFT_LUCHADOR--;
        return 5;
      } else {
        // PLS&TY gift awarded manually
        MAX_GIFT_PLSTY--;
        MAX_GIFT_BREWMASTER--;
        MAX_GIFT_MASTER_BREWER--;
        MAX_GIFT_DISTRIBUTOR--;
        MAX_GIFT_FREE_PACK--;
        MAX_GIFT_LUCHADOR--;
        return 6;
      }
      
      // returns 0 if gift was assigned but all gifts were sold already
      return 0;
    }
    
    function buyPack1Card() external payable returns (uint256) {
      require(isContractInitialized, "Contract is not initialized");
      require(_totalPacks1Card < MAX_PACKS_1CARD, "No more 1-card packs available");
      require(msg.value == PACK_1CARD_PRICE, "Ether value sent is not correct");
      
      uint256 packIndex = MAX_PACKS - packsLeft;
      uint256 cardNo = mintConsumerCards(msg.sender, 1);
      uint256 giftNo = getPackBonus(msg.sender);
      _totalPacks1Card++;
      
      emit PackOpened(msg.sender, packIndex, cardNo, giftNo, 1);
      return giftNo;
    }
    
    function buyPack3Card() external payable returns (uint256) {
      require(isContractInitialized, "Contract is not initialized");
      require(_totalPacks3Card < MAX_PACKS_3CARD, "No more 3-card packs available");
      require(msg.value == PACK_3CARD_PRICE, "Ether value sent is not correct");
      
      uint256 packIndex = MAX_PACKS - packsLeft;
      uint256 cardNo = mintConsumerCards(msg.sender, 3);
      uint256 giftNo = getPackBonus(msg.sender);
      _totalPacks3Card++;
      
      emit PackOpened(msg.sender, packIndex, cardNo, giftNo, 3);
      return giftNo;
    }
    
    function buyPack5Card() external payable returns (uint256) {
      require(isContractInitialized, "Contract is not initialized");
      require(_totalPacks5Card < MAX_PACKS_5CARD, "No more 5-card packs available");
      require(msg.value == PACK_5CARD_PRICE, "Ether value sent is not correct");
      
      uint256 packIndex = MAX_PACKS - packsLeft;
      uint256 cardNo = mintConsumerCards(msg.sender, 5);
      uint256 giftNo = getPackBonus(msg.sender);
      _totalPacks5Card++;
      
      emit PackOpened(msg.sender, packIndex, cardNo, giftNo, 5);
      return giftNo;
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}