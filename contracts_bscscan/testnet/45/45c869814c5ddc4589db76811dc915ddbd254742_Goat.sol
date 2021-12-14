// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./IGoat.sol";
import "./IBarn.sol";
import "./ITraits.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ECDSA.sol";
import "./ERC721Enumerable.sol";
import "./EGG.sol";

contract Goat is IGoat, ERC721Enumerable, Ownable, Pausable {
    using ECDSA for bytes32;

    struct LastWrite {
        uint64 time;
        uint64 blockNum;
    }
    struct Whitelist {
        uint hasMinted;
    }
    
    event TortoiseStolen(address owner, uint256 tokenId, uint256 value);
    event GoatStolen(address owner, uint256 tokenId, uint256 value);

    uint256 public totalTortoiseMinted;
    uint256 public totalGoatMinted;
    uint256 public totalTortoiseStolen;
    uint256 public totalGoatStolen;

    // mint price
    uint256 public MINT_PRICE = .042069 ether;
    // max number of tokens that can be minted - 50000 in production
    uint256 public MAX_TOKENS;
    // number of tokens that can be claimed for free - 20% of MAX_TOKENS
    uint256 public PAID_TOKENS;
    // number of tokens have been minted so far
    uint16 public minted;

    // list of probabilities for each trait type
    // 0 - 9 are associated with Tortoise, 10 - 18 are associated with Goats
    uint8[][20] public rarities;
    // list of aliases for Walker's Alias algorithm
    // 0 - 9 are associated with Tortoise, 10 - 18 are associated with Goats
    uint8[][20] public aliases;

    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => GoatTortoise) public tokenTraits;
    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;
    // Tracks the last block and timestamp that a caller has written to state.
    // Disallow some access to functions if they occur while a change is being written.
    mapping(address => LastWrite) private lastWrite;
    // address => User
    mapping(address => Whitelist) public whitelist;
    // address => allowedToCallFunctions
    mapping(address => bool) private admins;

    // reference to the ProtectedIsland for choosing random Goat thieves
    IProtectedIsland public protectedIsland;
    // reference to $EGG for burning on mint
    EGG public egg;
    // reference to Traits
    ITraits public traits;

    // boolean => checks if the earlyAccessMintSale is open or closed 
    bool public earlyAccessMintSale = false;
    // boolean => checks if the publicMintSale is open or closed
    bool public publicMintSale = false;

    // bytes32 -> DomainSeparator
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 -> PRESALE_TYPEHASH
    bytes32 public constant PRESALE_TYPEHASH = keccak256("EarlyAccess(address buyer,uint256 maxCount)");
    
    // address -> whitelist signer 
    address public whitelistSigner;
    

    /** 
    * instantiates contract and rarity tables
    */
    constructor(address _egg, address _traits, uint256 _maxTokens, address _whitelistSigner) ERC721("Enchanted Game", 'EGAME') { 
        egg = EGG(_egg);
        traits = ITraits(_traits);
        MAX_TOKENS = _maxTokens;
        PAID_TOKENS = _maxTokens / 5;
        whitelistSigner = _whitelistSigner;
        

        // I know this looks weird but it saves users gas by making lookup O(1)
        // A.J. Walker's Alias Algorithm
        // Goat
        // Fur
        rarities[0] = [128, 77, 77, 128, 153, 128, 128, 128, 128, 128, 230, 255, 230, 230, 255, 77, 153, 153, 204, 128];
        aliases[0] = [14, 0, 10, 10, 10, 10, 11, 11, 11, 11, 14, 11, 14, 14, 14, 12, 12, 13, 13, 13];
        // Skin
        rarities[1] = [255];
        aliases[1] = [0];
        // Ears
        rarities[2] =  [216, 230, 230, 207, 172, 46, 255, 172, 92];
        aliases[2] = [6, 0, 0, 0, 0, 0, 6, 0, 6];
        // Eyes
        rarities[3] = [255, 128, 255, 191, 255, 128, 191, 255, 128, 128];
        aliases[3] = [0, 0, 2, 0, 4, 0, 0, 7, 0, 7];
        // shell
        rarities[4] = [255];
        aliases[4] = [0];
        // face
        rarities[5] = [255];
        aliases[5] = [0];
        // neck
        rarities[6] = [179, 217, 140, 204, 77, 191, 128, 255, 115, 153];
        aliases[6] = [7, 0, 0, 7, 0, 3, 3, 7, 3, 3];
        // feet
        rarities[7] = [255, 255, 255, 255, 191, 255, 128, 128, 64, 64];
        aliases[7] = [0, 1, 2, 3, 5, 5, 0, 4, 4, 5];
        // fertilityIndex
        rarities[8] = [102, 204, 153, 255];
        aliases[8] = [2, 3, 3, 3];
        // Accessory
        rarities[9] = [255];
        aliases[9] = [0];

        // Tortoise
        // Fur
        rarities[10] = [255];
        aliases[10] = [0];
        // Skin
        rarities[11] =  [227, 227, 255, 255, 255, 170, 170, 227, 255, 227, 227, 227, 198, 198, 198, 227, 255, 198, 198, 142];
        aliases[11] =  [8, 0, 2, 3, 4, 0, 12, 0, 8, 0, 0, 0, 15, 0, 0, 16, 16, 0, 0, 6];
        // Ears
        rarities[12] =  [255];
        aliases[12] = [0];
        // Eyes
        rarities[13] = [255];
        aliases[13] = [0];
        // shell
        rarities[14] = [255, 113, 57, 255, 142, 227, 227, 113, 57, 28, 227, 142, 170, 255, 113, 113, 170, 255, 142, 227];
        aliases[14] = [0, 12, 13, 3, 16, 17, 0, 1, 1, 2, 3, 3, 17, 13, 3, 4, 17, 17, 5, 12];
        // face
        rarities[15] = [99, 241, 71, 71, 255, 170, 142, 142, 255, 255];
        aliases[15] = [9, 9, 0, 1, 4, 4, 4, 4, 8, 9];
        // neck
        rarities[16] = [255];
        aliases[16] = [0];
        // feet
        rarities[17] = [227, 170, 255, 142, 142, 198, 227, 255, 142, 142];
        aliases[17] = [2, 5, 2, 0, 0, 6, 7, 7, 0, 1];
        // fertilityIndex
        rarities[18] = [57, 170, 142, 255];
        aliases[18] = [2, 3, 3, 3];
        // Accessory
        rarities[19] = [198, 227, 255, 227, 255, 255, 227, 255, 255, 198];
        aliases[19] = [1, 4, 2, 5, 4, 5, 2, 7, 8, 3];
        
        // Early Access stuff
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("ECC")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /** CRITICAL TO SETUP / MODIFIERS */

    modifier disallowIfStateIsChanging() {
        // frens can always call whenever they want :)
        require(admins[_msgSender()] || lastWrite[tx.origin].blockNum < block.number, "hmmmm what doing?");
        _;
    }

    /** 
    * Mint
    */
    function _mint(uint256 amount, bool stake) internal {
        require(tx.origin == _msgSender(), "Only EOA");
        require(minted + amount <= MAX_TOKENS, "All tokens minted");
        require(amount > 0 && amount <= 10, "Invalid mint amount");
        if (minted < PAID_TOKENS) {
            require(minted + amount <= PAID_TOKENS, "All tokens on-sale already sold");
            require(amount * MINT_PRICE == msg.value, "Invalid payment amount");
        } else {
            require(msg.value == 0);
        }

        uint256 totalEggCost = 0;

        uint16[] memory tokenIds = stake ? new uint16[](amount) : new uint16[](0);
        uint256 seed;
        for (uint i = 0; i < amount; i++) {
            minted++;
            seed = random(minted, lastWrite[tx.origin].time, lastWrite[tx.origin].blockNum);
            generate(minted, seed, lastWrite[tx.origin]);
            address recipient = selectRecipient(seed);
            if (!stake || recipient != _msgSender()) {
                _safeMint(recipient, minted);
                // check if the recipient is the sender
                if (recipient != _msgSender()) {
                    // token is stolen!
                    if (tokenTraits[minted].isTortoise) {
                        totalTortoiseStolen += 1;
                        emit TortoiseStolen(_msgSender(), minted, block.timestamp);
                    } else {
                        totalGoatStolen += 1;
                        emit GoatStolen(_msgSender(), minted, block.timestamp);
                    }
                }
            } else {
                _safeMint(address(protectedIsland), minted);
                tokenIds[i] = minted;
            }
            // check token traits for tortoise or goat and increase mint amount
            totalEggCost += mintCost(minted);
        }
        
        if (totalEggCost > 0) egg.burn(_msgSender(), totalEggCost);
        if (stake) protectedIsland.addManyToProtectedIslandAndPack(_msgSender(), tokenIds);

        // update lastWrite for sender
        updateOriginAccess();
    }

    /** 
    * mint a token - 90% Tortoise, 10% Goats
    * The first 20% are free to claim, the remaining cost $EGG
    */
    function publicMint(uint256 _amount, bool _stake) external payable whenNotPaused {
        require(publicMintSale, "Public sale is not active");
        _mint(_amount, _stake);
    }

    /** 
    * mint a token - 90% Tortoise, 10% Goats
    * The first 20% are free to claim, the remaining cost $EGG
    */
    function earlyAccessMint(uint256 _amount, uint256 maxCount, bytes memory signature, bool _stake) external payable whenNotPaused {
        require(earlyAccessMintSale, "Early access is not active");

        // Verify EIP-712 signature
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(PRESALE_TYPEHASH, msg.sender, maxCount))));
        address recoveredAddress = digest.recover(signature);
        // Is the signature the same as the whitelist signer if yes? your able to mint.
        require(recoveredAddress != address(0) && recoveredAddress == address(whitelistSigner), "Invalid signature");
        require((whitelist[msg.sender].hasMinted + _amount) <= maxCount, "Early Access max count exceeded");
        whitelist[msg.sender].hasMinted += _amount;
        
        _mint(_amount, _stake);
    }

 
    

    /** 
    * the first 20% are paid in ETH
    * the next 20% are 20000 $EGG
    * the next 40% are 40000 $EGG
    * the final 20% are 80000 $EGG
    * @param tokenId the ID to check the cost of to mint
    * @return the cost of the given token ID
    */
    function mintCost(uint256 tokenId) public view returns (uint256) {
        if (tokenId <= PAID_TOKENS) return 0;
        if (tokenId <= MAX_TOKENS * 2 / 5) return 20000 ether;
        if (tokenId <= MAX_TOKENS * 4 / 5) return 40000 ether;
        return 80000 ether;
    }

    /** 
    * Updates `lastWrite`
    */
    function updateOriginAccess() internal {
        lastWrite[tx.origin].blockNum = uint64(block.number);
        lastWrite[tx.origin].time = uint64(block.number);
    }

    function transferFrom(
    address from,
    address to,
    uint256 tokenId
    ) public virtual override {
        // Hardcode the ProtectedIsland's approval so that users don't have to waste gas approving
        if (_msgSender() != address(protectedIsland))
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /** INTERNAL */

    /**
    * generates traits for a specific token, checking to make sure it's unique
    * @param tokenId the id of the token to generate traits for
    * @param seed a pseudorandom 256 bit number to derive traits from
    * @return t - a struct of traits for the given token ID
    */
    function generate(uint256 tokenId, uint256 seed, LastWrite memory lw) internal returns (GoatTortoise memory t) {
        t = selectTraits(seed);
        if (existingCombinations[structToHash(t)] == 0) {
            tokenTraits[tokenId] = t;
            existingCombinations[structToHash(t)] = tokenId;
            if (t.isTortoise) {
                totalTortoiseMinted += 1;
            } else {
                totalGoatMinted += 1;
            }
            return t;
        }
        return generate(tokenId, random(seed, lw.time, lw.blockNum), lw);
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
        if (seed >> 8 < rarities[traitType][trait]) return trait;
        return aliases[traitType][trait];
    }

    /**
    * the first 20% (ETH purchases) go to the minter
    * the remaining 80% have a 10% chance to be given to a random staked Goat
    * @param seed a random value to select a recipient from
    * @return the address of the recipient (either the minter or the Goat thief's owner)
    */
    function selectRecipient(uint256 seed) internal view returns (address) {
        if (minted <= PAID_TOKENS || ((seed >> 245) % 10) != 0) return _msgSender(); // top 10 bits haven't been used
        address thief = protectedIsland.randomGoatOwner(seed >> 144); // 144 bits reserved for trait selection
        if (thief == address(0x0)) return _msgSender();
        return thief;
    }

    /**
    * selects the species and all of its traits based on the seed value
    * @param seed a pseudorandom 256 bit number to derive traits from
    * @return t -  a struct of randomly selected traits
    */
    function selectTraits(uint256 seed) internal view returns (GoatTortoise memory t) {    
        t.isTortoise = (seed & 0xFFFF) % 10 != 0;
        uint8 shift = t.isTortoise ? 10 : 0;

        seed >>= 16;
        t.fur = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
        seed >>= 16;
        t.skin = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
        seed >>= 16;
        t.ears = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
        seed >>= 16;
        t.eyes = selectTrait(uint16(seed & 0xFFFF), 3 + shift);
        seed >>= 16;
        t.shell = selectTrait(uint16(seed & 0xFFFF), 4 + shift);
        seed >>= 16;
        t.face = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
        seed >>= 16;
        t.neck = selectTrait(uint16(seed & 0xFFFF), 6 + shift);
        seed >>= 16;
        t.feet = selectTrait(uint16(seed & 0xFFFF), 7 + shift);
        seed >>= 16;
        t.fertilityIndex = selectTrait(uint16(seed & 0xFFFF), 8 + shift);
        seed >>= 16;
        t.accessory = selectTrait(uint16(seed & 0xFFFF), 9 + shift);
    }

    /**
    * converts a struct to a 256 bit hash to check for uniqueness
    * @param s the struct to pack into a hash
    * @return the 256 bit hash of the struct
    */
    function structToHash(GoatTortoise memory s) internal pure returns (uint256) {
        return uint256(bytes32(
            abi.encodePacked(
                s.isTortoise,
                s.fur,
                s.skin,
                s.ears,
                s.eyes,
                s.shell,
                s.face,
                s.neck,
                s.feet,
                s.accessory,
                s.fertilityIndex
            )
        ));
    }

    /**
    * generates a pseudorandom number for picking traits. Uses point in time randomization to prevent abuse.
    */
    function random(uint256 seed, uint64 timestamp, uint64 blockNumber) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(blockNumber > 1 ? blockNumber - 2 : blockNumber),// Different block than WnDGame to ensure if needing to re-randomize that it goes down a different path
            timestamp,
            seed
        )));
    }

    function getTokenTraits(uint256 tokenId) external view override returns (GoatTortoise memory) {
        return tokenTraits[tokenId];
    }

    function getPaidTokens() external view override returns (uint256) {
        return PAID_TOKENS;
    }

    /// @notice Returns a list of all Goat IDs assigned to an address.
    /// @param _owner The owner whose Goats we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. First, it's fairly
    ///  expensive (it walks the entire Owner's array looking for Goat(s) & Tortoise(s) belonging to owner),
    ///  but it also returns a dynamic array, which is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        require(admins[_msgSender()] || lastWrite[_owner].blockNum < block.number, "hmmmm what doing?");
        
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalSupply = totalSupply();
            uint256 resultIndex = 0;

            // We count on the fact that all goats have IDs starting at 1 and increasing
            // sequentially up to the totalGoats count.
            uint256 tokenId;
            for (tokenId = 1; tokenId <= totalSupply; tokenId++) {
                if (ownerOf(tokenId) == _owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /**
    * allows owner to withdraw funds from minting
    */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
    * called after deployment so that the contract can get random Goat thieves
    * @param _protectedIsland the address of the ProtectedIsland
    */
    function setProtectedIsland(address _protectedIsland) external onlyOwner {
        protectedIsland = IProtectedIsland(_protectedIsland);
    }

    

    /**
    * updates the number of tokens for sale
    */
    function setPaidTokens(uint256 _paidTokens) external onlyOwner {
        PAID_TOKENS = _paidTokens;
    }

    /**
    * Updates the mint price
    */
    function setMintPrice(uint256 _mintPriceInWei) external onlyOwner {
        MINT_PRICE = _mintPriceInWei;
    }

    /**
    * Updates the max tokens;
    */
    function setMaxTokens(uint256 _maxTokens) external onlyOwner {
        MAX_TOKENS = _maxTokens;
    }
    
    /**
    * updates the sales of the earlyAccess and the public sale
    */
    function setSales(bool _earlyAccessMintSale, bool _publicMintSale) external onlyOwner {
        earlyAccessMintSale = _earlyAccessMintSale;
        publicMintSale = _publicMintSale;
    }

    /**
    * updates the sales of the earlyAccess and the public sale
    */
    function setWhitelistSigner(address _whitelistSigner) external onlyOwner {
        whitelistSigner = _whitelistSigner;
    }

    /**
    * enables owner to pause / unpause minting
    */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return traits.tokenURI(tokenId);
    }

    /** OVERRIDES FOR SAFETY */

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override(ERC721Enumerable) disallowIfStateIsChanging returns (uint256) {
        // Y U checking on this address in the same block it's being modified... hmmmm
        require(admins[_msgSender()] || lastWrite[owner].blockNum < block.number, "hmmmm what doing?");
        return super.tokenOfOwnerByIndex(owner, index);
    }

    function balanceOf(address owner) public view virtual override(ERC721) disallowIfStateIsChanging returns (uint256) {
        // Y U checking on this address in the same block it's being modified... hmmmm
        require(admins[_msgSender()] || lastWrite[owner].blockNum < block.number, "hmmmm what doing?");
        return super.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) public view virtual override(ERC721) disallowIfStateIsChanging returns (address) {
        address addr = super.ownerOf(tokenId);
        // Y U checking on this address in the same block it's being modified... hmmmm
        require(admins[_msgSender()] || lastWrite[addr].blockNum < block.number, "hmmmm what doing?");
        return addr;
    }
}