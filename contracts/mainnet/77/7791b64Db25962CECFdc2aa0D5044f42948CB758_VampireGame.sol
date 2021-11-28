// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

import "./allowlist/AllowList.sol";
import "./traits/TokenTraits.sol";
import "./traits/ITraits.sol";
import "./IVampireGame.sol";

/// @title The Vampire Game NFT contract
///
/// Note: The original Wolf Game's contract was used as insipiration, and a
/// few parts of the contract were taken directly, in particular the trait selection
/// and rarity using Walker's Alias method, and using a separate `Traits` contract
/// for getting the tokenURI.
///
/// Some info about how this contract works:
///
/// ### Allow-list
///
/// Using a merkle-tree based allow-list that caps the amount of nfts a wallet
/// can mint. This increases a bit the gas cost to mint on **presale**, but we
/// compensate this by paying half of the minting price when we reveal the NFTs.
///
/// ### On-chain vs Off-chain
///
/// What is on-chain here?
/// - The generated traits
/// - The revealed traits metadata
/// - The traits img data
///
/// What is off-chain?
/// - The random number we get for batch reveals. We use a neutral, trusted third party 
///   that is widely known in the community: Chainlink VRF.
/// - The non-revealed traits metadata (before your nft is revealed).
///
/// ### Minting and Revealing
///
/// 1. The user mints an NFT
/// 2. After a few mints, we request a random number to Chainlink VRF
/// 3. We use this random number to reveal the batch of NFTs that were minted
///    before we got the seed.
///
/// Why? We believe that as long as minting and revealing happens in the same 
/// transaction, people will be able to cheat.
///
/// ### Traits
///
/// The traits are all stored on-chain in another contract "Traits" similar to Wolf Game.
///
/// ### Game Controllers
///
/// For us to be able to expand on this game, future "game controller" contracts will be
/// able to freely call `mint` functions, and `transferFrom`, the logic to safeguard
/// those functions will be delegated to those contracts.
///
/// Unfortunatelly, to be able to expand, and to not fall into traps like Wolf Game did,
/// we had to leave a few things open that requires our users to _trust us_ for now. We
/// hope to make this trustless some day.
///
contract VampireGame is
    IVampireGame,
    IVampireGameControls,
    ERC721Enumerable,
    AllowList,
    Ownable,
    ReentrancyGuard,
    VRFConsumerBase
{
    /// @notice used to find seeds for token ids
    using Arrays for uint256[];

    /// ==== Immutable
    // Most of the immutable variables are initiated in the constructor
    // to make it easier to test

    /// @notice minting price in wei
    uint256 public immutable MINT_PRICE;
    /// @notice max amount of tokens that can be minted
    uint256 public immutable MAX_SUPPLY;
    /// @notice max mints per address
    uint256 public immutable MAX_PER_ADDRESS;
    /// @notice max mints per address in presale
    uint256 public immutable MAX_PER_ADDRESS_PRESALE;
    /// @notice price in $LINK to make VRF requests
    uint256 public LINK_VRF_PRICE;
    /// @notice number of tokens that can be bought with ether
    uint256 public PAID_TOKENS;
    /// @notice size of the batch that will be revealed by a single 
    uint256 public SEED_BATCH_SIZE;
    /// @notice random numbers generated from Chainlink VRF.
    uint256[] public seeds;
    /// @notice array of tokenIds in ascending order that matches the length of the `seeds` array.
    /// @dev using this to set which seeds are for which token, for example if let's say
    /// the array has the values [100, 1000], then tokens from 0~99 will use seed[0] and
    /// tokens from 100~999 will use seed[1].
    uint256[] public seedTokenBoundaries;
    /// @notice mapping from tokenId to tokenTraits
    mapping(uint256 => TokenTraits) public tokenTraits;
    /// @notice mapping from token hash to tokenId to prevent duplicated traits
    mapping(uint256 => uint256) public existingCombinations;
    /// @notice mapping from address to amount of tokens minted
    mapping(address => uint8) public amountMintedByAddress;
    /// @notice game controllers they can access special functions
    mapping(address => bool) public controllers;
    /// @notice chainlink key hash
    bytes32 public immutable KEY_HASH;
    /// @notice LINK token
    IERC20 public immutable LINK_TOKEN;
    /// @notice contract storing the traits data
    ITraits public traits;
    /// @notice address to withdraw the eth
    address private immutable splitter;
    /// @notice controls if mintWithEthPresale is paused
    bool public mintWithEthPresalePaused = true;
    /// @notice controls if mintWithEth is paused
    bool public mintWithEthPaused = true;
    /// @notice controls if mintFromController is paused
    bool public mintFromControllerPaused = true;
    /// @notice controls if token reveal is paused
    bool public revealPaused = true;
    /// @notice list of probabilities for each trait type  0 - 9 are associated with Sheep, 10 - 18 are associated with Wolves
    /// @dev won't mutate but can't make it immutable
    uint8[][18] public RARITIES;
    /// @notice list of aliases for Walker's Alias algorithm 0 - 9 are associated with Sheep, 10 - 18 are associated with Wolves
    /// @dev won't mutate but can't make it immutable
    uint8[][18] public ALIASES;

    /// === Constructor

    /// @dev constructor, most of the immutable props can be set here so it's easier to test
    /// @param _LINK_KEY_HASH Chainlink's VRF Key Hash
    /// @param _LINK_ADDRESS Chainlink's LINK contract address
    /// @param _LINK_VRF_COORDINATOR_ADDRESS Chainlink's coordinator contract address
    /// @param _LINK_VRF_PRICE Price in $LINK to request a random number from Chainlink VRF
    /// @param _MINT_PRICE price to mint one token in wei
    /// @param _MAX_SUPPLY maximum amount of available tokens to mint
    /// @param _MAX_PER_ADDRESS maximum amount of tokens one address can mint
    /// @param _MAX_PER_ADDRESS_PRESALE maximum amount of tokens one address can mint
    /// @param _SEED_BATCH_SIZE amount of tokens revealed by one seed
    /// @param _PAID_TOKENS maxiumum amount of tokens that can be bought with eth
    /// @param _splitter address to where the funds will go
    constructor(
        bytes32 _LINK_KEY_HASH,
        address _LINK_ADDRESS,
        address _LINK_VRF_COORDINATOR_ADDRESS,
        uint256 _LINK_VRF_PRICE,
        uint256 _MINT_PRICE,
        uint256 _MAX_SUPPLY,
        uint256 _MAX_PER_ADDRESS,
        uint256 _MAX_PER_ADDRESS_PRESALE,
        uint256 _SEED_BATCH_SIZE,
        uint256 _PAID_TOKENS,
        address _splitter
    )
        VRFConsumerBase(_LINK_VRF_COORDINATOR_ADDRESS, _LINK_ADDRESS)
        ERC721("The Vampire Game", "VGAME")
    {
        LINK_TOKEN = IERC20(_LINK_ADDRESS);
        KEY_HASH = _LINK_KEY_HASH;
        LINK_VRF_PRICE = _LINK_VRF_PRICE;
        MINT_PRICE = _MINT_PRICE;
        MAX_SUPPLY = _MAX_SUPPLY;
        MAX_PER_ADDRESS = _MAX_PER_ADDRESS;
        MAX_PER_ADDRESS_PRESALE = _MAX_PER_ADDRESS_PRESALE;
        SEED_BATCH_SIZE = _SEED_BATCH_SIZE;
        PAID_TOKENS = _PAID_TOKENS;
        splitter = _splitter;

        // Humans
        // Skin
        RARITIES[0] = [50, 15, 15, 250, 255];
        ALIASES[0] = [3, 4, 4, 0, 3];
        // Face
        RARITIES[1] = [
            133,
            189,
            57,
            255,
            243,
            133,
            114,
            135,
            168,
            38,
            222,
            57,
            95,
            57,
            152,
            114,
            57,
            133,
            189
        ];
        ALIASES[1] = [
            1,
            0,
            3,
            1,
            3,
            3,
            3,
            4,
            7,
            4,
            8,
            4,
            8,
            10,
            10,
            10,
            18,
            18,
            14
        ];
        // T-Shirt
        RARITIES[2] = [
            181,
            224,
            147,
            236,
            220,
            168,
            160,
            84,
            173,
            224,
            221,
            254,
            140,
            252,
            224,
            250,
            100,
            207,
            84,
            252,
            196,
            140,
            228,
            140,
            255,
            183,
            241,
            140
        ];
        ALIASES[2] = [
            1,
            0,
            3,
            1,
            3,
            3,
            4,
            11,
            11,
            4,
            9,
            10,
            13,
            11,
            13,
            14,
            15,
            15,
            20,
            17,
            19,
            24,
            20,
            24,
            22,
            26,
            24,
            26
        ];
        // Pants
        RARITIES[3] = [
            126,
            171,
            225,
            240,
            227,
            112,
            255,
            240,
            217,
            80,
            64,
            160,
            228,
            80,
            64,
            167
        ];
        ALIASES[3] = [2, 0, 1, 2, 3, 3, 4, 6, 7, 4, 6, 7, 8, 8, 15, 12];
        // Boots
        RARITIES[4] = [150, 30, 60, 255, 150, 60];
        ALIASES[4] = [0, 3, 3, 0, 3, 4];
        // Accessory
        RARITIES[5] = [
            210,
            135,
            80,
            245,
            235,
            110,
            80,
            100,
            190,
            100,
            255,
            160,
            215,
            80,
            100,
            185,
            250,
            240,
            240,
            100
        ];
        ALIASES[5] = [
            0,
            0,
            3,
            0,
            3,
            4,
            10,
            12,
            4,
            16,
            8,
            16,
            10,
            17,
            18,
            12,
            15,
            16,
            17,
            18
        ];
        // Hair
        RARITIES[6] = [250, 115, 100, 40, 175, 255, 180, 100, 175, 185];
        ALIASES[6] = [0, 0, 4, 6, 0, 4, 5, 9, 6, 8];
        // Cape
        RARITIES[7] = [255];
        ALIASES[7] = [0];
        // predatorIndex
        RARITIES[8] = [255];
        ALIASES[8] = [0];

        // Vampires
        // Skin
        RARITIES[9] = [
            234,
            239,
            234,
            234,
            255,
            234,
            244,
            249,
            130,
            234,
            234,
            247,
            234
        ];
        ALIASES[9] = [0, 0, 1, 2, 3, 4, 5, 6, 12, 7, 9, 10, 11];
        // Face
        RARITIES[10] = [
            45,
            255,
            165,
            60,
            195,
            195,
            45,
            120,
            75,
            75,
            105,
            120,
            255,
            180,
            150
        ];
        ALIASES[10] = [1, 0, 1, 4, 2, 4, 5, 12, 12, 13, 13, 14, 5, 12, 13];
        // Clothes
        RARITIES[11] = [
            147,
            180,
            246,
            201,
            210,
            252,
            219,
            189,
            195,
            156,
            177,
            171,
            165,
            225,
            135,
            135,
            186,
            135,
            150,
            243,
            135,
            255,
            231,
            141,
            183,
            150,
            135
        ];
        ALIASES[11] = [
            2,
            2,
            0,
            2,
            3,
            4,
            5,
            6,
            7,
            3,
            3,
            4,
            4,
            8,
            5,
            6,
            13,
            13,
            19,
            16,
            19,
            19,
            21,
            21,
            21,
            21,
            22
        ];
        // Pants
        RARITIES[12] = [255];
        ALIASES[12] = [0];
        // Boots
        RARITIES[13] = [255];
        ALIASES[13] = [0];
        // Accessory
        RARITIES[14] = [255];
        ALIASES[14] = [0];
        // Hair
        RARITIES[15] = [255];
        ALIASES[15] = [0];
        // Cape
        RARITIES[16] = [9, 9, 150, 90, 9, 210, 9, 9, 255];
        ALIASES[16] = [5, 5, 0, 2, 8, 3, 8, 8, 5];
        // predatorIndex
        RARITIES[17] = [255, 8, 160, 73];
        ALIASES[17] = [0, 0, 0, 2];
    }

    /// ==== Modifiers

    modifier onlyControllers() {
        require(controllers[_msgSender()], "ONLY_CONTROLLERS");
        _;
    }

    /// ==== Minting

    /// @notice mint an unrevealed token using eth
    /// @param amount amount to mint
    function mintWithETH(uint8 amount) external payable nonReentrant {
        require(!mintWithEthPaused, "MINT_WITH_ETH_PAUSED");
        uint8 addressMintedSoFar = amountMintedByAddress[_msgSender()];
        require(
            addressMintedSoFar + amount <= MAX_PER_ADDRESS,
            "MAX_TOKEN_PER_WALLET"
        );
        require(totalSupply() + amount <= PAID_TOKENS, "NOT_ENOUGH_TOKENS");
        require(amount > 0, "INVALID_AMOUNT");
        require(amount * MINT_PRICE == msg.value, "WRONG_VALUE");
        amountMintedByAddress[_msgSender()] = addressMintedSoFar + amount;
        _mintMany(_msgSender(), amount);
    }

    /// @notice mint an unrevealed token using eth
    /// @param amount amount to mint
    function mintWithETHPresale(uint8 amount, bytes32[] calldata proof)
        external
        payable
        nonReentrant
    {
        require(!mintWithEthPresalePaused, "PRESALE_PAUSED");
        require(isAddressInAllowList(_msgSender(), proof), "NOT_IN_ALLOWLIST");
        uint8 addressMintedSoFar = amountMintedByAddress[_msgSender()];
        require(
            addressMintedSoFar + amount <= MAX_PER_ADDRESS_PRESALE,
            "MAX_TOKEN_PER_WALLET"
        );
        require(totalSupply() + amount <= PAID_TOKENS, "NOT_ENOUGH_TOKENS");
        require(amount > 0, "INVALID_AMOUNT");
        require(amount * MINT_PRICE == msg.value, "WRONG_VALUE");
        amountMintedByAddress[_msgSender()] = addressMintedSoFar + amount;
        _mintMany(_msgSender(), amount);
    }

    /// @dev mint any amount of tokens to an address
    /// common logic to many functions, the function calling
    /// this should do the guard checks
    function _mintMany(address to, uint8 amount) private {
        uint256 supply = totalSupply();
        for (uint8 i = 0; i < amount; i++) {
            uint256 tokenId = supply + i;
            _safeMint(to, tokenId);
            if ((tokenId + 1) % SEED_BATCH_SIZE == 0) {
                requestRandomness(KEY_HASH, LINK_VRF_PRICE);
            }
        }
    }

    /// ==== Revealing

    /// @notice reveal the metadata of multiple of tokenIds.
    /// @dev admin check if this won't fail
    function revealGenZeroTokens(uint256[] calldata tokenIds)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(canRevealToken(tokenId), "CANT_REVEAL");

            // Find seed index in the seedTokenBoundaries array
            uint256 seedIndex = seedTokenBoundaries.findUpperBound(tokenId);
            uint256 seed = uint256(keccak256(abi.encode(seeds[seedIndex], tokenId)));

            _revealToken(tokenId, seed);
        }
    }

    /// @dev returns true if a token can be revealed.
    /// Conditions for a token to be revealed:
    /// - Was not revealed yet
    /// - There is a seed that was added after the was already minted
    function canRevealToken(uint256 tokenId)
        private
        view
        returns (bool)
    {
        // Token already revealed
        if (tokenTraits[tokenId].exists) {
            return false;
        }

        // No seeds
        if (seedTokenBoundaries.length == 0) {
            return false;
        }

        // If the last element of the seedTokenBoundaries array is greater
        // than the tokenId it means that there is a seed available for that
        // token so the token can be revealed
        return seedTokenBoundaries[seedTokenBoundaries.length - 1] > tokenId;
    }

    /// @dev reveal one token given an id and a seed
    function _revealToken(uint256 tokenId, uint256 seed) private {
        (
            TokenTraits memory tt,
            uint256 ttHash
        ) = _generateNonDuplicatedTokenTraits(tokenId, seed);
        tokenTraits[tokenId] = tt;
        existingCombinations[ttHash] = tokenId;
    }

    /// @dev recursive function to generate a TokenTraits without colliding
    /// with other previously generated traits. It uses a seed from
    /// Chainlink VRF and if there is a collision, it keeps re-hashing the
    /// seed with the tokenId until it finds a unique set of traits.
    /// @param tokenId the id of the token to generate the traits for
    /// @param seed a value derived from a randomly generated value
    /// @return tt a TokenTraits struct
    function _generateNonDuplicatedTokenTraits(uint256 tokenId, uint256 seed)
        private
        returns (TokenTraits memory tt, uint256 ttHash)
    {
        // generate traits from seed
        tt = selectTraits(seed);

        // hash to check if the token is unique
        ttHash = structToHash(tt);
        if (existingCombinations[ttHash] == 0) {
            tokenTraits[tokenId] = tt;
            existingCombinations[ttHash] = tokenId;
            return (tt, ttHash);
        }

        // If it's here, then the generated traits collided with another
        // set of traits. Hopefully this won't happen.

        // generates a new seed combining the current seed and the tokenId
        uint256 newSeed = uint256(keccak256(abi.encode(seed, tokenId)));

        // recursive call D:
        return _generateNonDuplicatedTokenTraits(tokenId, newSeed);
    }

    /// @dev select traits based on the seed value.
    /// @param seed a uint256 to derive traits from
    /// @return tt the TokenTraits
    function selectTraits(uint256 seed)
        private
        view
        returns (TokenTraits memory tt)
    {
        tt.exists = true;
        tt.isVampire = (seed & 0xFFFF) % 10 == 0;
        uint8 shift = tt.isVampire ? 9 : 0;
        seed >>= 16;
        tt.skin = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
        seed >>= 16;
        tt.face = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
        seed >>= 16;
        tt.clothes = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
        seed >>= 16;
        tt.pants = selectTrait(uint16(seed & 0xFFFF), 3 + shift);
        seed >>= 16;
        tt.boots = selectTrait(uint16(seed & 0xFFFF), 4 + shift);
        seed >>= 16;
        tt.accessory = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
        seed >>= 16;
        tt.hair = selectTrait(uint16(seed & 0xFFFF), 6 + shift);
        seed >>= 16;
        tt.cape = selectTrait(uint16(seed & 0xFFFF), 7 + shift);
        seed >>= 16;
        tt.predatorIndex = selectTrait(uint16(seed & 0xFFFF), 8 + shift);
    }

    /// @dev select a trait from the traitType
    /// @param seed a uint256 number to get the trait value from
    /// @param traitType the trait type
    function selectTrait(uint16 seed, uint8 traitType)
        private
        view
        returns (uint8)
    {
        uint8 trait = uint8(seed) % uint8(RARITIES[traitType].length);
        if (seed >> 8 < RARITIES[traitType][trait]) return trait;
        return ALIASES[traitType][trait];
    }

    /// @dev hash a TokenTraits struct
    /// @param tt the TokenTraits struct
    /// @return the uint256 hash
    function structToHash(TokenTraits memory tt)
        private
        pure
        returns (uint256)
    {
        return
            uint256(
                bytes32(
                    abi.encodePacked(
                        tt.isVampire,
                        tt.skin,
                        tt.face,
                        tt.clothes,
                        tt.pants,
                        tt.boots,
                        tt.accessory,
                        tt.hair,
                        tt.cape,
                        tt.predatorIndex
                    )
                )
            );
    }

    /// ==== State Control

    /// @notice set the new merkle tree root for allow-list
    function setMerkleTreeRoot(bytes32 newMerkleTreeRoot) external onlyOwner {
        _setMerkleTreeRoot(newMerkleTreeRoot);
    }

    /// @notice set the max amount of gen 0 tokens
    function setPaidTokens(uint256 _PAID_TOKENS) external onlyOwner {
        require(PAID_TOKENS != _PAID_TOKENS, "NO_CHANGES");
        PAID_TOKENS = _PAID_TOKENS;
    }

    /// @notice pause/unpause mintWithEthPresale function
    function setMintWithEthPresalePaused(bool paused) external onlyOwner {
        require(paused != mintWithEthPresalePaused, "NO_CHANGES");
        mintWithEthPresalePaused = paused;
    }

    /// @notice pause/unpause mintWithEth function
    function setMintWithEthPaused(bool paused) external onlyOwner {
        require(paused != mintWithEthPaused, "NO_CHANGES");
        mintWithEthPaused = paused;
    }

    /// @notice pause/unpause mintFromController function
    function setMintFromControllerPaused(bool paused) external onlyOwner {
        require(paused != mintFromControllerPaused, "NO_CHANGES");
        mintFromControllerPaused = paused;
    }

    /// @notice pause/unpause token reveal functions
    function setRevealPaused(bool paused) external onlyOwner {
        require(paused != revealPaused, "NO_CHANGES");
        revealPaused = paused;
    }

    /// @notice set the contract for the traits rendering
    /// @param _traits the contract address
    function setTraits(address _traits) external onlyOwner {
        traits = ITraits(_traits);
    }

    /// @notice add controller authority to an address
    /// @param _controller address to the game controller
    function addController(address _controller) external onlyOwner {
        controllers[_controller] = true;
    }

    /// @notice remove controller authority from an address
    /// @param _controller address to the game controller
    function removeController(address _controller) external onlyOwner {
        controllers[_controller] = false;
    }

    /// ==== Withdraw

    /// @notice withdraw the ether from the contract
    function withdraw() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        // solhint-disable-next-line avoid-low-level-calls
        (bool sent, ) = splitter.call{value: contractBalance}("");
        require(sent, "FAILED_TO_WITHDRAW");
    }

    /// @notice withdraw ERC20 tokens from the contract
    /// people always randomly transfer ERC20 tokens to the
    /// @param erc20TokenAddress the ERC20 token address
    /// @param recipient who will get the tokens
    /// @param amount how many tokens
    function withdrawERC20(
        address erc20TokenAddress,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        IERC20 erc20Contract = IERC20(erc20TokenAddress);
        bool sent = erc20Contract.transfer(recipient, amount);
        require(sent, "ERC20_WITHDRAW_FAILED");
    }

    /// @notice reserve some tokens for the team. Can only reserve gen 0 tokens
    /// we also need token 0 to so ssetup market places befor mint
    function reserve(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount < PAID_TOKENS);
        uint256 supply = totalSupply();
        for (uint8 i = 0; i < amount; i++) {
            uint256 tokenId = supply + i;
            _safeMint(to, tokenId);
        }
    }

    /// @notice delete all entries in the seeds and seedTokenBoundaries arrays
    /// just in case something weird happens
    function cleanSeeds() external onlyOwner {
        require(seeds.length > 0, "NO_SEEDS");
        for (uint256 i = 0; i < seeds.length; i++) {
            delete seeds[i];
            delete seedTokenBoundaries[i];
        }
    }

    /// @notice set the price for requesting a random number to Chainlink VRF
    /// Note that the base link token has 18 zeroes.
    function setVRFPrice(uint256 _LINK_VRF_PRICE) external onlyOwner {
        require(_LINK_VRF_PRICE != LINK_VRF_PRICE, "NO_CHANGES");
        LINK_VRF_PRICE = _LINK_VRF_PRICE;
    }

    /// @notice owner request reveal seed, just in case something goes wrong
    function requestRevealSeed() external onlyOwner {
        requestRandomness(KEY_HASH, LINK_VRF_PRICE);
    }

    /// ==== IVampireGameControls Overrides

    /// @notice see {IVampireGameControls.mintFromController(receiver, amount)}
    function mintFromController(address receiver, uint256 amount)
        external
        override
    {
        require(!mintFromControllerPaused, "MINT_FROM_CONTROLLER_PAUSED");
        require(controllers[_msgSender()], "NOT_AUTHORIZED");
        require(totalSupply() + amount <= MAX_SUPPLY, "NOT_ENOUGH_TOKENS");
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = totalSupply();
            _safeMint(receiver, tokenId);
        }
    }

    /// @notice for a game controller to reveal the metadata of multiple token ids
    function controllerRevealTokens(
        uint256[] calldata tokenIds,
        uint256[] calldata _seeds
    ) external override onlyControllers {
        require(!revealPaused, "REVEAL_PAUSED");
        require(
            tokenIds.length == seeds.length,
            "INPUTS_SHOULD_HAVE_SAME_LENGTH"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _revealToken(tokenIds[i], _seeds[i]);
        }
    }

    /// ==== IVampireGame Overrides

    /// @notice see {IVampireGame.getGenZeroSupply()}
    function getGenZeroSupply() external view override returns (uint256) {
        return PAID_TOKENS;
    }

    /// @notice see {IVampireGame.getMaxSupply()}
    function getMaxSupply() external view override returns (uint256) {
        return MAX_SUPPLY;
    }

    /// @notice see {IVampireGame.getTokenTraits(tokenId)}
    function getTokenTraits(uint256 tokenId)
        external
        view
        override
        returns (TokenTraits memory)
    {
        return tokenTraits[tokenId];
    }

    /// @notice see {IVampireGame.isTokenRevealed(tokenId)}
    function isTokenRevealed(uint256 tokenId)
        public
        view
        override
        returns (bool)
    {
        return tokenTraits[tokenId].exists;
    }

    /// ==== ERC721 Overrides

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // Hardcode approval of game controllers
        if (!controllers[_msgSender()])
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );
        _transfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return traits.tokenURI(tokenId);
    }

    /// ==== Chainlink VRF Overrides

    /// @notice Fulfills randomness from Chainlink VRF
    /// @param requestId returned id of VRF request
    /// @param randomness random number from VRF
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint256 minted = totalSupply();

        // the amount of tokens minted has to be greater than the latest recorded
        // seed boundary, otherwise it means that there is already a seed for tokens
        // up to the current amount of tokens
        if (
            seedTokenBoundaries.length == 0 ||
            minted > seedTokenBoundaries[seedTokenBoundaries.length - 1]
        ) {
            seeds.push(randomness);
            seedTokenBoundaries.push(minted);
        }
        // Otherwise we discard the number. I'm hoping this doesn't happen though :D
        // More info: I'm hoping that this won't happen bevause we'll only ask for seeds
        // on spaced enough intervals, but not guaranteeing it in the contract
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title AllowList
/// @notice Adds simple merkle-tree based allow-list functionality to a contract.
contract AllowList {
    /// @notice stores the Merkle Tree root.
    bytes32 internal _merkleTreeRoot;

    /// @notice Sets the new merkle tree root
    /// @param newMerkleTreeRoot the new root of the merkle tree
    function _setMerkleTreeRoot(bytes32 newMerkleTreeRoot) internal {
        require(_merkleTreeRoot != newMerkleTreeRoot, "NO_CHANGES");
        _merkleTreeRoot = newMerkleTreeRoot;
    }

    /// @notice test if an address is part of the merkle tree
    /// @param _address the address to verify
    /// @param proof array of other hashes for proof calculation
    /// @return true if the address is part of the merkle tree
    function isAddressInAllowList(address _address, bytes32[] calldata proof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(proof, _merkleTreeRoot, leaf);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

struct TokenTraits {
    /// @dev every initialised token should have this as true
    /// this is just used to check agains a non-initialized struct
    bool exists;
    bool isVampire;
    // Shared Traits
    uint8 skin;
    uint8 face;
    uint8 clothes;
    // Human-only Traits
    uint8 pants;
    uint8 boots;
    uint8 accessory;
    uint8 hair;
    // Vampire-only Traits
    uint8 cape;
    uint8 predatorIndex;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./traits/TokenTraits.sol";

/// @notice Interface to interact with the VampireGame contract
interface IVampireGame {
    /// @notice get the total supply of gen-0
    function getGenZeroSupply() external view returns (uint256);

    /// @notice get the total supply of tokens
    function getMaxSupply() external view returns (uint256);

    /// @notice get the TokenTraits for a given tokenId
    function getTokenTraits(uint256 tokenId) external view returns (TokenTraits memory);

    /// @notice returns true if a token is aleady revealed
    function isTokenRevealed(uint256 tokenId) external view returns (bool);
}

/// @notice Interface to control parts of the VampireGame ERC 721
interface IVampireGameControls {
    /// @notice mint any amount of nft to any address
    /// Requirements:
    /// - message sender should be an allowed address (game contract)
    /// - amount + totalSupply() has to be smaller than MAX_SUPPLY
    function mintFromController(address receiver, uint256 amount) external;

    /// @notice reveal a list of tokens using specific seeds for each
    function controllerRevealTokens(uint256[] calldata tokenIds, uint256[] calldata _seeds) external;
}

// SPDX-License-Identifier: MIT

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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}