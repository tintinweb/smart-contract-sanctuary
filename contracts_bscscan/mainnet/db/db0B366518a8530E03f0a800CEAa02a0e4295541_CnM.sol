// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./interfaces/ICnM.sol";
import "./interfaces/IHabitat.sol";
import "./interfaces/ITraits.sol";
import "./interfaces/IRandomizer.sol";

contract CnM is ICnM, ERC721Enumerable, Ownable, Pausable {
    struct LastWrite {
        uint64 time;
        uint64 blockNum;
    }

    event TokenMinted(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event TestTokenMinted(address indexed owner, uint256 indexed tokenId);

    event CatMinted(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event CrazyCatLadyMinted(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event MouseMinted(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);

    event CatStolen(uint256 indexed tokenId, address indexed owner, address indexed previous, uint256 blockNum, uint256 timeStamp);
    event CrazyCatLadyStolen(uint256 indexed tokenId, address indexed owner, address indexed previous, uint256 blockNum, uint256 timeStamp);
    event MouseStolen(uint256 indexed tokenId, address indexed owner, address indexed previous, uint256 blockNum, uint256 timeStamp);

    event CatBurned(uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event CrazyCatLadyBurned(uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event MouseBurned(uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);

    event CatStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event CrazyCatLadyStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event MouseStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);

    event CatUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event CrazyCatLadyUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event MouseUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event RollChanged(address indexed owner, uint256 tokenId, uint8 roll);

    // max number of tokens that can be minted: 50,000 in production
    uint256 public maxTokens;
    // number of tokens that minted by ethereum - initial 10,000
    uint256 public PAID_TOKENS;
    // number of tokens have been minted so far
    uint16 public override minted;
    // mapping tokenId => token's traits
    mapping(uint256 => CatMouse) private tokenTraits;
    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;
    // Tracks the last block and timestamp that a caller has written to state.
    // Disallow some access to functions if they occur while a change is being written.
    mapping(address => LastWrite) private lastWriteAddress;
    mapping(uint256 => LastWrite) private lastWriteToken;

    // list of probabilities for each trait type
    // 0 - 12 are associated with Cats , 13 - 25 are Crazy Cat Lady, 26 - 38 are associated with Mice
    uint8[][39] public rarities;
    // list of aliases for Walker's Alias algorithm
    // 0 - 12 are associated with Cats , 13 - 25 are Crazy Cat Lady, 26 - 38 are associated with Mice
    uint8[][39] public aliases;

    // reference to the Habitat contract to allow transfers to it without any approval
    IHabitat public habitat;
    // reference to Traits
    ITraits public traits;
    // reference to Randomizer
    IRandomizer public randomizer;
    // mapping address => allowedToCallFunctions
    mapping(address => bool) private admins;


    constructor(uint256 _maxTokens) ERC721("Cat & Mouse game", "CnM") {
        updateMaxToken(_maxTokens);
        _pause();

        // A.J. Walker's Alias Algorithm


        // Cats

        // body
        rarities[0] = [80];
        aliases[0] = [4];
        // color
        rarities[1] = [150, 40, 240, 90, 115];
        aliases[1] = [0, 1, 2, 3, 4];
        // eyes
        rarities[2] = [255, 135, 60, 130, 190, 156, 250, 120, 60, 25, 190];
        aliases[2] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        // eyebrows
        rarities[3] = [221];
        aliases[3] = [1];
        // neck
        rarities[4] = [175];
        aliases[4] = [3];
        // glasses
        rarities[5] = [80];
        aliases[5] = [1];
        // hair
        rarities[6] = [255];
        aliases[6] = [0];
        // head
        rarities[7] = [243];
        aliases[7] = [1];
        // markings
        rarities[8] = [243, 189, 50];
        aliases[8] = [0, 1, 2];
        // mouth
        rarities[9] = [243, 124, 107];
        aliases[9] = [0, 1, 2];
        // nose
        rarities[10] = [243];
        aliases[10] = [1];
        // props
        rarities[11] = [243, 115, 178, 120, 36, 56, 78];
        aliases[11] = [0, 1, 2, 3, 4, 5, 6];
        // shirts
        rarities[12] = [243];
        aliases[12] = [1];


        // Crazy

        // body
        rarities[13] = [80, 40];
        aliases[13] = [0, 1];
        // color
        rarities[14] = [150];
        aliases[14] = [3];
        // eyes
        rarities[15] = [255, 135];
        aliases[15] = [0, 1];
        // eyebrows
        rarities[16] = [221, 100, 181];
        aliases[16] = [0, 1, 2];
        // neck
        rarities[17] = [175];
        aliases[17] = [3];
        // glasses
        rarities[18] = [80, 225, 220];
        aliases[18] = [0, 1, 2];
        // hair
        rarities[19] = [243, 189, 50, 30, 55, 180, 80, 90];
        aliases[19] = [0, 1, 2, 3, 4, 5, 6, 7];
        // head
        rarities[20] = [243];
        aliases[20] = [1];
        // markings
        rarities[21] = [243];
        aliases[21] = [1];
        // mouth
        rarities[22] = [243];
        aliases[22] = [1];
        // nose
        rarities[23] = [243];
        aliases[23] = [1];
        // props
        rarities[24] = [243];
        aliases[24] = [1];
        // shirts
        rarities[25] = [30, 222, 255];
        aliases[25] = [0, 1, 2];


        // Mice

        // body
        rarities[26] = [150, 40, 240, 90];
        aliases[26] = [0, 1, 2, 3];
        // color
        rarities[27] = [150, 241, 40, 240, 90, 115, 135, 40, 199, 100];
        aliases[27] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        // eyes
        rarities[28] = [135, 60, 130, 190, 156, 250, 120, 60, 25, 190];
        aliases[28] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        // eyebrows
        rarities[29] = [221];
        aliases[29] = [1];
        // neck
        rarities[30] = [175];
        aliases[30] = [3];
        // glasses
        rarities[31] = [80];
        aliases[31] = [1];
        // hair
        rarities[32] = [255];
        aliases[32] = [0];
        // head
        rarities[33] = [243, 189, 50, 30, 55, 180, 80, 90, 155];
        aliases[33] = [0, 1, 2, 3, 4, 5, 6, 7, 8];
        // markings
        rarities[34] = [24];
        aliases[34] = [1];
        // mouth
        rarities[35] = [90, 155, 30, 222, 255];
        aliases[35] = [0, 1, 2, 3, 4];
        // nose
        rarities[36] = [80, 255];
        aliases[36] = [0, 1];
        // props
        rarities[37] = [243];
        aliases[37] = [1];
        // shirts
        rarities[38] = [243];
        aliases[38] = [1];
    }
    /** CRITICAL TO SETUP / MODIFIERS */
    modifier requireContractsSet() {
        require(address(traits) != address(0) && address(habitat) != address(0) && address(randomizer) != address(0), "Contracts not set");
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
    function setContracts(address _traits, address _habitat, address _rand) external onlyOwner {
        traits = ITraits(_traits);
        habitat = IHabitat(_habitat);
        randomizer = IRandomizer(_rand);
    }

    function getTokenWriteBlock(uint256 tokenId) external view override returns (uint64) {
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
        if (tx.origin != recipient && recipient != address(habitat)) {
            // Stolen!
            if (tokenTraits[minted].isCat) {
                if (tokenTraits[minted].isCrazy) {
                    emit CrazyCatLadyStolen(minted, recipient, tx.origin, block.number, block.timestamp);
                } else {
                    emit CatStolen(minted, recipient, tx.origin, block.number, block.timestamp);
                }
            }
            else {
                emit MouseStolen(minted, recipient, tx.origin, block.number, block.timestamp);
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
    function generate(address recipient, uint256 tokenId, uint256 seed) internal returns (CatMouse memory t){
        t = selectTraits(seed);
        t.roll = 0;
        tokenTraits[tokenId] = t;
        existingCombinations[structToHash(t)] = tokenId;
        emit TokenMinted(recipient, tokenId, block.number, block.timestamp);
        emit TestTokenMinted(recipient, tokenId);
        if (t.isCat) {
            if (t.isCrazy) {
                emit CrazyCatLadyMinted(recipient, tokenId, block.number, block.timestamp);
            } else {
                emit CatMinted(recipient, tokenId, block.number, block.timestamp);
            }
        } else {
            emit MouseMinted(recipient, tokenId, block.number, block.timestamp);
        }
        return t;
    }

    /**
    * selects the species and all of its traits based on the seed value
    * @param seed a pseudorandom 256 bit number to derive traits from
    * @return t -  a struct of randomly selected traits
    */
    function selectTraits(uint256 seed) internal view returns (CatMouse memory t) {
        // Mouse & Cat percet is 90% & 10%
        t.isCat = uint16(seed & 0xFFFF) % 100 < 10;
        if (minted > PAID_TOKENS) {
            if (t.isCat) {
                // CrazyCats has 20% chance of cats to be minted
                t.isCrazy = (seed & 0xFFFF) % 10 < 2;
            } else {
                // CrazyCat is only true when it is cat
                t.isCrazy = false;
            }
        } else {
            // CrazyCat only minted after 10000 NFTs are minted
            t.isCrazy = false;
        }
        uint8 shift = t.isCat ? t.isCrazy ? 13 : 0 : 26;
        seed >>= 16;
        t.body = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
        seed >>= 16;
        t.color = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
        seed >>= 16;
        t.eyes = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
        seed >>= 16;
        t.eyebrows = selectTrait(uint16(seed & 0xFFFF), 3 + shift);
        seed >>= 16;
        t.neck = selectTrait(uint16(seed & 0xFFFF), 4 + shift);
        seed >>= 16;
        t.glasses = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
        seed >>= 16;
        t.hair = selectTrait(uint16(seed & 0xFFFF), 6 + shift);
        seed >>= 16;
        t.head = selectTrait(uint16(seed & 0xFFFF), 7 + shift);
        seed >>= 16;
        t.markings = selectTrait(uint16(seed & 0xFFFF), 8 + shift);
        seed >>= 16;
        t.mouth = selectTrait(uint16(seed & 0xFFFF), 9 + shift);
        seed >>= 16;
        t.nose = selectTrait(uint16(seed & 0xFFFF), 10 + shift);
        seed >>= 16;
        t.props = selectTrait(uint16(seed & 0xFFFF), 11 + shift);
        seed >>= 16;
        t.shirts = selectTrait(uint16(seed & 0xFFFF), 12 + shift);
        return t;
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
        /* // If a selected random trait probability is selected (biased coin) return that trait
         if (seed >> 8 < rarities[traitType][trait]) return trait;
         return aliases[traitType][trait];*/
        return aliases[traitType][trait];
    }
    /**
    * converts a struct to a 256 bit hash to check for uniqueness
    * @param s the struct to pack into a hash
    * @return the 256 bit hash of the struct
    */
    function structToHash(CatMouse memory s) internal pure returns (uint256) {
        return uint256(keccak256(
                abi.encodePacked(
                    s.body,
                    s.color,
                    s.eyes,
                    s.eyebrows,
                    s.neck,
                    s.glasses,
                    s.hair,
                    s.head,
                    s.markings,
                    s.mouth,
                    s.nose,
                    s.props,
                    s.shirts
                )
            ));
    }
    /**
    * Burn a token - any game logic should be handled before this function.
    */
    function burn(uint256 tokenId) external override whenNotPaused {
        require(admins[_msgSender()], "Only admins can call this");
        _burn(tokenId);
        minted -= 1;
        if (tokenTraits[tokenId].isCat) {
            if (tokenTraits[tokenId].isCrazy) {
                emit CrazyCatLadyBurned(tokenId, block.number, block.timestamp);
            } else {
                emit CatBurned(tokenId, block.number, block.timestamp);
            }
        } else {
            emit MouseBurned(tokenId, block.number, block.timestamp);
        }
    }
    /**
    * Set roll to the Mouse
    */
    /*    function setRoll(uint256 seed, uint256 tokenId, address addr) external override whenNotPaused {
            ICnM.CatMouse memory s = tokenTraits[tokenId];
            *//*
        * Odds to Roll:
        * Habitatless: Default
        * Shack: 70%
        * Ranch: 20%
        * Mansion: 10%
        *//*

        if ((seed & 0xFFFF) % 100 < 10) {
            s.roll = 3;
        } else if ((seed & 0xFFFF) % 100 < 30) {
            s.roll = 2;
        } else {
            s.roll = 1;
        }
    }*/

    function setRoll(uint256 tokenId, uint8 habitatType) external override whenNotPaused {
        require(admins[_msgSender()], "Only admins can call this");
        if (!tokenTraits[tokenId].isCat) {
            tokenTraits[tokenId].roll = habitatType;
            emit RollChanged(msg.sender, tokenId, habitatType);
        }
    }

    /**
    * emit cat stacked event
    * @param tokenId the ID of the token stacked
    */
    function emitCatStakedEvent(address owner, uint256 tokenId) external override whenNotPaused {
        emit CatStaked(owner, tokenId, block.number, block.timestamp);
    }

    /**
    * emit crazy cat stacked event
    * @param tokenId the ID of the token stacked
    */
    function emitCrazyCatStakedEvent(address owner, uint256 tokenId) external override whenNotPaused {
        emit CrazyCatLadyStaked(owner, tokenId, block.number, block.timestamp);
    }

    /**
    * emit mouse stacked event
    * @param tokenId the ID of the token stacked
    */
    function emitMouseStakedEvent(address owner, uint256 tokenId) external override whenNotPaused {
        emit MouseStaked(owner, tokenId, block.number, block.timestamp);
    }

    //----------------friedrich--------------
    /**
    * emit cat stacked event
    * @param tokenId the ID of the token stacked
    */
    function emitCatUnStakedEvent(address owner, uint256 tokenId) external override whenNotPaused {
        emit CatUnStaked(owner, tokenId, block.number, block.timestamp);
    }

    /**
    * emit crazy cat stacked event
    * @param tokenId the ID of the token stacked
    */
    function emitCrazyCatUnStakedEvent(address owner, uint256 tokenId) external override whenNotPaused {
        emit CrazyCatLadyUnStaked(owner, tokenId, block.number, block.timestamp);
    }

    /**
    * emit mouse stacked event
    * @param tokenId the ID of the token stacked
    */
    function emitMouseUnStakedEvent(address owner, uint256 tokenId) external override whenNotPaused {
        emit MouseUnStaked(owner, tokenId, block.number, block.timestamp);
    }
    //---------------------------------------------

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
        if (!admins[_msgSender()]) {
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        }
        _transfer(from, to, tokenId);
    }
    /**
    * checks if a token is a Cat/Mouse
    * @param tokenId the ID of the token to check
    * @return bool - whether or not a token is a Cat
    */
    function isCat(uint256 tokenId) external view override blockIfChangingToken(tokenId) returns (bool) {
        // Sneaky cats will be slain if they try to peep this after mint. Nice try.
        ICnM.CatMouse memory s = tokenTraits[tokenId];
        return s.isCat;
    }

    function isClaimable() external view override returns (bool) {
        return minted > PAID_TOKENS;
    }
    /**
    * checks if a token is a CrazyCatLady
    * @param tokenId the ID of the token to check
    * @return bool - whether or not a token is a CrazyCatLady
    */
    function isCrazyCatLady(uint256 tokenId) external view override blockIfChangingToken(tokenId) returns (bool) {
        // Sneaky cats will be slain if they try to peep this after mint. Nice try.
        ICnM.CatMouse memory s = tokenTraits[tokenId];
        return s.isCrazy;
    }

    /**
    * returns the value of Mouse NFT's roll
    * @param tokenId the ID of the token to check
    * @return uint8 - 0, 1, 2, 3
    */
    function getTokenRoll(uint256 tokenId) external view override returns (uint8) {
        ICnM.CatMouse memory s = tokenTraits[tokenId];
        return s.roll;
    }

    function getMaxTokens() external view override returns (uint256) {
        return maxTokens;
    }

    function getPaidTokens() external view override returns (uint256) {
        return PAID_TOKENS;
    }
    /** ADMIN */
    /**
    * updates the number of tokens for sale
    */
    function setPaidTokens(uint256 _paidTokens) external onlyOwner {
        PAID_TOKENS = uint16(_paidTokens);
    }
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

    function getTokenTraits(uint256 tokenId) external view override blockIfChangingAddress blockIfChangingToken(tokenId) returns (CatMouse memory) {
        return tokenTraits[tokenId];
    }

    function tokenURI(uint256 tokenId) public view override blockIfChangingAddress blockIfChangingToken(tokenId) returns (string memory) {
        require(_exists(tokenId), "Token ID does not exist");
        return traits.tokenURI(tokenId);
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

    function updateMaxToken(uint256 limit) public onlyOwner {
        maxTokens = limit;
        PAID_TOKENS = limit / 5;
    }
}

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IRandomizer {
    function commitId() external view returns (uint16);
    function getCommitRandom(uint16 id) external view returns (uint256);
    function random() external returns (uint256);
    function sRandom(uint256 tokenId) external returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface IHabitat {
  function addManyToStakingPool(address account, uint16[] calldata tokenIds) external;
  function addManyHouseToStakingPool(address account, uint16[] calldata tokenIds) external;
  function randomCatOwner(uint256 seed) external view returns (address);
  function randomCrazyCatOwner(uint256 seed) external view returns (address);
  function isOwner(uint256 tokenId, address owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ICnM is IERC721Enumerable {
    
    // Character NFT struct
    struct CatMouse {
        bool isCat; // true if cat
        bool isCrazy; // true if cat is CrazyCatLady, only check if isCat equals to true
        uint8 roll; //0 - habitatless, 1 - Shack, 2 - Ranch, 3 - Mansion

        uint8 body;
        uint8 color;
        uint8 eyes;
        uint8 eyebrows;
        uint8 neck;
        uint8 glasses;
        uint8 hair;
        uint8 head;
        uint8 markings;
        uint8 mouth;
        uint8 nose;
        uint8 props;
        uint8 shirts;
    }

    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function mint(address recipient, uint256 seed) external;
    // function setRoll(uint256 seed, uint256 tokenId, address addr) external;
    function setRoll(uint256 tokenId, uint8 habitatType) external;

    function emitCatStakedEvent(address owner,uint256 tokenId) external;
    function emitCrazyCatStakedEvent(address owner, uint256 tokenId) external;
    function emitMouseStakedEvent(address owner, uint256 tokenId) external;
    
    function emitCatUnStakedEvent(address owner, uint256 tokenId) external;
    function emitCrazyCatUnStakedEvent(address owner, uint256 tokenId) external;
    function emitMouseUnStakedEvent(address owner, uint256 tokenId) external;
    
    function burn(uint256 tokenId) external;
    function getPaidTokens() external view returns (uint256);
    function updateOriginAccess(uint16[] memory tokenIds) external;
    function isCat(uint256 tokenId) external view returns(bool);
    function isClaimable() external view returns(bool);
    function isCrazyCatLady(uint256 tokenId) external view returns(bool);
    function getTokenRoll(uint256 tokenId) external view returns(uint8);
    function getMaxTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (CatMouse memory);
    function minted() external view returns (uint16);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}