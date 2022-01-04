// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./ICnM.sol";
import "./IHabitat.sol";
import "./ITraits.sol";
import "./IRandomizer.sol";

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
        generate(recipient, minted, seed, lastWriteAddress[tx.origin]);
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
    function generate(address recipient, uint256 tokenId, uint256 seed, LastWrite memory lw) internal returns (CatMouse memory t){
        t = selectTraits(seed);
        t.roll = 0;
        if (existingCombinations[structToHash(t)] == 0) {
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
        return generate(recipient, tokenId, randomizer.random(), lw);
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