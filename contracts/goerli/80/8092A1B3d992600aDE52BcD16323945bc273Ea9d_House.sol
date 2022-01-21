// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./IHouse.sol";
import "./IHabitat.sol";
import "./IHouseTraits.sol";
import "./IRandomizer.sol";

contract House is IHouse, ERC721Enumerable, Ownable, Pausable {

    struct LastWrite {
        uint64 time;
        uint64 blockNum;
    }

    event TokenMinted(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event TestTokenMinted(address indexed owner, uint256 indexed tokenId);

    event ShackMinted(address indexed owner,uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event RanchMinted(address indexed owner,uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event MansionMinted(address indexed owner,uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);

    event ShackStolen(address indexed owner, address indexed previous, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event RanchStolen(address indexed owner, address  indexed previous, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event MansionStolen(address indexed owner, address  indexed previous, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);

    event ShackBurned(uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event RanchBurned(uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event MansionBurned(uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);

    event ShackStaked(address indexed owner,uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event RanchStaked(address indexed owner,uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event MansionStaked(address indexed owner,uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);

    event ShackUnStaked(address indexed owner,uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event RanchUnStaked(address indexed owner,uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event MansionUnStaked(address indexed owner,uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);

    // max number of tokens that can be minted: 10,000 in production
    uint256 public maxTokens;

    // number of tokens have been minted so far
    uint16 public override minted;

    // mapping tokenId => token's traits
    mapping(uint256 => HouseStruct) private tokenTraits;

    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;

    // Tracks the last block and timestamp that a caller has written to state.
    // Disallow some access to functions if they occur while a change is being written.
    mapping(address => LastWrite) private lastWriteAddress;
    mapping(uint256 => LastWrite) private lastWriteToken;


    // list of probabilities for each trait type
    // 0 is associated with Shack, 1 is associated with Ranch, 2 is associated with Mansion
    uint8[][3] public rarities;


    // list of aliases for Walker's Alias algorithm
    // 0 is associated with Shack, 1 is associated with Ranch, 2 is associated with Mansion
    uint8[][3] public aliases;

    // reference to the Habitat contract to allow transfers to it without any approval
    IHabitat public habitat;
    // reference to House Traits
    IHouseTraits public houseTraits;
    // reference to Randomizer
    IRandomizer public randomizer;
    

    // mapping address => allowedToCallFunctions
    mapping(address => bool) private admins;


    constructor(uint256 _maxTokens) ERC721("HouseNFT", "House") {
        maxTokens = _maxTokens;


        // A.J. Walker's Alias Algorithm


        // Shack

        // body
        rarities[0] = [80];
        aliases[0] = [0];



        // Ranch

        // body
        rarities[1] = [100];
        aliases[1] = [0];





        // Mansion
        rarities[2] = [100];
        aliases[2] = [0];
    }


    /** CRITICAL TO SETUP / MODIFIERS */

    modifier requireContractsSet() {
        require(address(houseTraits) != address(0) && address(habitat) != address(0) && address(randomizer) != address(0), "Contracts not set");
        _;
    }

    modifier blockIfChangingAddress() {
        // frens can always call whenever they want :)
        require(admins[_msgSender()] || lastWriteAddress[tx.origin].blockNum < block.number, "hmmmm what doing?");
        _;
    }

    modifier blockIfChangingToken(uint256 tokenId) {
        // frens can always call whenever they want :)
        require(admins[_msgSender()] || lastWriteToken[tokenId].blockNum < block.number, "hmmmm what doing?");
        _;
    }

    function setContracts(address _houseTraits, address _habitat, address _rand) external onlyOwner {
        houseTraits = IHouseTraits(_houseTraits);
        habitat = IHabitat(_habitat);
        randomizer = IRandomizer(_rand);
    }

    function getTokenWriteBlock(uint256 tokenId) external view override returns(uint64) {
        require(admins[_msgSender()], "Only admins can call this");
        return lastWriteToken[tokenId].blockNum;
    }


    /** 
    * Mint a token - any payment / game logic should be handled in the game contract. 
    * This will just generate random traits and mint a token to a designated address.
    */
    function mint(address recipient, uint256 seed) external override whenNotPaused {
        require(admins[_msgSender()], "Only admins can call this");
        require(minted + 1 <= maxTokens, "All tokens minted");
        minted++;
        generate(recipient, minted, seed);
        if(tx.origin != recipient && recipient != address(habitat)) {
            // Stolen!
            if(tokenTraits[minted].roll == 0) {
                emit ShackStolen(recipient, tx.origin, minted, block.number, block.timestamp);
            } else if(tokenTraits[minted].roll == 1) {
                emit RanchStolen(recipient, tx.origin, minted, block.number, block.timestamp);
            } else {
                emit MansionStolen(recipient, tx.origin, minted, block.number, block.timestamp);
            }
        }
        _safeMint(recipient, minted);
    }

     /**
    * generates traits for a specific token, checking to make sure it's unique
    * @param tokenId the id of the token to generate traits for
    * @param seed a pseudorandom 256 bit number to derive traits from
    * @return t - a struct of traits for the given token ID
    */
    function generate(address recipient, uint256 tokenId, uint256 seed) public returns (HouseStruct memory t) {
        t = selectTraits(seed);
        tokenTraits[tokenId] = t;
        emit TokenMinted(recipient, tokenId, block.number, block.timestamp);
        emit TestTokenMinted(recipient, tokenId);
        if(t.roll == 0) {
            emit ShackMinted(recipient, tokenId, block.number, block.timestamp);
        } else if(t.roll == 1) {
            emit RanchMinted(recipient, tokenId, block.number, block.timestamp);
        } else {
            emit MansionMinted(recipient, tokenId, block.number, block.timestamp);
        }
        return t;
    }

    /**
    * selects the species and all of its traits based on the seed value
    * @param seed a pseudorandom 256 bit number to derive traits from
    * @return t -  a struct of randomly selected traits
    */
    function selectTraits(uint256 seed) internal view returns (HouseStruct memory t) {    
        // Shack & Ranch & Mansion percet is 70% & 25% & 5%

        if (uint16(seed & 0xFFFF) % 100 < 5) {
            t.roll = 2;
        } else if(uint16(seed & 0xFFFF) % 100 < 30) {
            t.roll = 1;
        } else {
            t.roll = 0;
        }

        uint8 shift = 0;
        if (t.roll == 0) {
            shift = 0;
        } else if (t.roll == 1) {
            shift = 1;
        } else {
            shift = 2;
        }
        seed >>= 16;
        t.body = selectTrait(uint16(seed & 0xFFFF), 0 + shift);

    }

    /**
    * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
    * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
    * probability & alias tables are generated off-chain beforehand
    * @param seed portion of the 256 bit seed to remove trait correlation
    * @param traitType the trait type to select a trait for 
    * @return the ID of the randomly selected trait
    */
    function selectTrait(uint16 seed, uint8 traitType) internal view returns (uint8) {
        uint8 trait = uint8(seed) % uint8(rarities[traitType].length);
        return aliases[traitType][trait];
    }


    /**
    * converts a struct to a 256 bit hash to check for uniqueness
    * @param s the struct to pack into a hash
    * @return the 256 bit hash of the struct
    */
    function structToHash(HouseStruct memory s) internal pure returns (uint256) {
        return uint256(keccak256(
            abi.encodePacked(
                s.roll,
                s.body)
        ));
    }

    /** 
    * Burn a token - any game logic should be handled before this function.
    */
    function burn(uint256 tokenId) external override whenNotPaused {
        require(admins[_msgSender()], "Only admins can call this");
        _burn(tokenId);
        minted -= 1;
        if(tokenTraits[tokenId].roll == 2) {
            emit MansionBurned(tokenId, block.number, block.timestamp);
        } else if (tokenTraits[tokenId].roll == 1) {
            emit RanchBurned(tokenId, block.number, block.timestamp);
        } else {
            emit ShackBurned(tokenId, block.number, block.timestamp);
        }
    }



    function updateOriginAccess(uint16[] memory tokenIds) external override {
        require(admins[_msgSender()], "Only admins can call this");
        uint64 blockNum = uint64(block.number);
        uint64 time = uint64(block.timestamp);
        lastWriteAddress[tx.origin] = LastWrite(time, blockNum);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            lastWriteToken[tokenIds[i]] = LastWrite(time, blockNum);
        }
    }


    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) blockIfChangingToken(tokenId) {
        // allow admin contracts to be send without approval
        if(!admins[_msgSender()]) {
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        }
        _transfer(from, to, tokenId);
    }


    /**
    * checks if a token is a Shack
    * @param tokenId the ID of the token to check
    * @return bool - whether or not a token is a Shack
    */
    function isShack(uint256 tokenId) external view override blockIfChangingToken(tokenId) returns (bool) {
        // Sneaky cats will be slain if they try to peep this after mint. Nice try.
        IHouse.HouseStruct memory s = tokenTraits[tokenId];
        return s.roll == 0;
    }


    /**
    * checks if a token is a Ranch
    * @param tokenId the ID of the token to check
    * @return bool - whether or not a token is a Ranch
    */
    function isRanch(uint256 tokenId) external view override blockIfChangingToken(tokenId) returns (bool) {
        // Sneaky cats will be slain if they try to peep this after mint. Nice try.
        IHouse.HouseStruct memory s = tokenTraits[tokenId];
        return s.roll == 1;
    }


    /**
    * checks if a token is a Mansion
    * @param tokenId the ID of the token to check
    * @return bool - whether or not a token is a Mansion
    */
    function isMansion(uint256 tokenId) external view override blockIfChangingToken(tokenId) returns (bool) {
        // Sneaky cats will be slain if they try to peep this after mint. Nice try.
        IHouse.HouseStruct memory s = tokenTraits[tokenId];
        return s.roll == 2;
    }


    function getMaxTokens() external view override returns (uint256) {
        return maxTokens;
    }


    /** ADMIN */


    
    /**
    * enables owner to pause / unpause minting
    */
    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /**
    * enables an address to mint / burn
    * @param addr the address to enable
    */
    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;
    }


    /**
    * disables an address from minting / burning
    * @param addr the address to disbale
    */
    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }

    /** Traits */

    function getTokenTraits(uint256 tokenId) external view override blockIfChangingAddress blockIfChangingToken(tokenId) returns (HouseStruct memory) {
        return tokenTraits[tokenId];
    }

    function tokenURI(uint256 tokenId) public view override blockIfChangingAddress blockIfChangingToken(tokenId) returns (string memory) {
        require(_exists(tokenId), "Token ID does not exist");
        return houseTraits.tokenURI(tokenId);
    }



    /** OVERRIDES FOR SAFETY */

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override(ERC721Enumerable, IERC721Enumerable) blockIfChangingAddress returns (uint256) {
        // Y U checking on this address in the same block it's being modified... hmmmm
        require(admins[_msgSender()] || lastWriteAddress[owner].blockNum < block.number, "hmmmm what doing?");
        uint256 tokenId = super.tokenOfOwnerByIndex(owner, index);
        require(admins[_msgSender()] || lastWriteToken[tokenId].blockNum < block.number, "hmmmm what doing?");
        return tokenId;
    }


    function balanceOf(address owner) public view virtual override(ERC721, IERC721) blockIfChangingAddress returns (uint256) {
        // Y U checking on this address in the same block it's being modified... hmmmm
        require(admins[_msgSender()] || lastWriteAddress[owner].blockNum < block.number, "hmmmm what doing?");
        return super.balanceOf(owner);
    }


    function ownerOf(uint256 tokenId) public view virtual override(ERC721, IERC721) blockIfChangingAddress blockIfChangingToken(tokenId) returns (address) {
        address addr = super.ownerOf(tokenId);
        // Y U checking on this address in the same block it's being modified... hmmmm
        require(admins[_msgSender()] || lastWriteAddress[addr].blockNum < block.number, "hmmmm what doing?");
        return addr;
    }


    function tokenByIndex(uint256 index) public view virtual override(ERC721Enumerable, IERC721Enumerable) returns (uint256) {
        uint256 tokenId = super.tokenByIndex(index);
        // NICE TRY TOAD DRAGON
        require(admins[_msgSender()] || lastWriteToken[tokenId].blockNum < block.number, "hmmmm what doing?");
        return tokenId;
    }

    function approve(address to, uint256 tokenId) public virtual override(ERC721, IERC721) blockIfChangingToken(tokenId) {
        super.approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override(ERC721, IERC721) blockIfChangingToken(tokenId) returns (address) {
        return super.getApproved(tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721, IERC721) blockIfChangingAddress {
        super.setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override(ERC721, IERC721) blockIfChangingAddress returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) blockIfChangingToken(tokenId) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override(ERC721, IERC721) blockIfChangingToken(tokenId) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    //----------friedrich-----------
    /**
    * Event
    * @param tokenId the ID of the token stacked
    */
    function emitShackStakedEvent(address owner, uint256 tokenId) external override whenNotPaused {
        emit ShackStaked(owner, tokenId, block.number, block.timestamp);
    }
    
    /**
    * Event
    * @param tokenId the ID of the token stacked
    */
    function emitRanchStakedEvent(address owner, uint256 tokenId) external override whenNotPaused {
        emit RanchStaked(owner, tokenId, block.number, block.timestamp);
    }
  
    /**
    * Event
    * @param tokenId the ID of the token stacked
    */
    function emitMansionStakedEvent(address owner, uint256 tokenId) external override whenNotPaused {
        emit MansionStaked(owner, tokenId, block.number, block.timestamp);
    }

    /**
    * Event
    * @param tokenId the ID of the token stacked
    */
    function emitShackUnStakedEvent(address owner, uint256 tokenId) external override whenNotPaused {
        emit ShackUnStaked(owner, tokenId, block.number, block.timestamp);
    }
    
    /**
    * Event
    * @param tokenId the ID of the token stacked
    */
    function emitRanchUnStakedEvent(address owner, uint256 tokenId) external override whenNotPaused {
        emit RanchUnStaked(owner, tokenId, block.number, block.timestamp);
    }
  
    /**
    * Event
    * @param tokenId the ID of the token stacked
    */
    function emitMansionUnStakedEvent(address owner, uint256 tokenId) external override whenNotPaused {
        emit MansionUnStaked(owner, tokenId, block.number, block.timestamp);
    }
}