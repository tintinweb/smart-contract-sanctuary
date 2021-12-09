// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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
/// ### On-chain vs Off-chain
///
/// What is on-chain here?
/// - The generated traits
/// - The revealed traits metadata
/// - The traits img data
///
/// What is off-chain?
/// - The random number we get for batch reveals.
/// - The non-revealed image.
///
/// ### Minting and Revealing
///
/// 1. The user mints an NFT
/// 2. A seed is assigned for OG and Gen0 batches, this reveals the NFTs.
///
/// Why? We believe that as long as minting and revealing happens in the same
/// transaction, people will be able to cheat. So first you commit to minting, then
/// the seed is released.
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
contract VampireGame is
    IVampireGame,
    IVampireGameControls,
    ERC721,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    /// ==== Events

    event TokenRevealed(uint256 indexed tokenId, uint256 seed);
    event OGRevealed(uint256 seed);
    event Gen0Revealed(uint256 seed);

    /// ==== Immutable Properties

    /// @notice max amount of tokens that can be minted
    uint16 public immutable maxSupply;
    /// @notice max amount of og tokens
    uint16 public immutable ogSupply;
    /// @notice address to withdraw the eth
    address private immutable splitter;
    /// @notice minting price in wei
    uint256 public immutable mintPrice;

    /// ==== Mutable Properties

    /// @notice current amount of minted tokens
    uint16 public totalSupply;
    /// @notice max amount of gen 0 tokens (tokens that can be bought with eth)
    uint16 public genZeroSupply;
    /// @notice seed for the OGs who minted contract v1
    uint256 public ogSeed;
    /// @notice seed for all Gen 0 except for OGs
    uint256 public genZeroSeed;
    /// @notice contract storing the traits data
    ITraits public traits;
    /// @notice game controllers they can access special functions
    mapping(uint16 => uint256) public tokenSeeds;
    /// @notice game controllers they can access special functions
    mapping(address => bool) public controllers;

    /// === Constructor

    /// @dev constructor, most of the immutable props can be set here so it's easier to test
    /// @param _mintPrice price to mint one token in wei
    /// @param _maxSupply maximum amount of available tokens to mint
    /// @param _genZeroSupply maxiumum amount of tokens that can be bought with eth
    /// @param _splitter address to where the funds will go
    constructor(
        uint256 _mintPrice,
        uint16 _maxSupply,
        uint16 _genZeroSupply,
        uint16 _ogSupply,
        address _splitter
    ) ERC721("The Vampire Game", "VGAME") {
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        genZeroSupply = _genZeroSupply;
        ogSupply = _ogSupply;
        splitter = _splitter;
        _pause();
    }

    /// ==== Modifiers

    modifier onlyControllers() {
        require(controllers[_msgSender()], "ONLY_CONTROLLERS");
        _;
    }

    /// ==== Airdrop

    function airdropToOwners(
        address v1Contract,
        uint16 from,
        uint16 to
    ) external onlyOwner {
        require(to >= from);
        IERC721 v1 = IERC721(v1Contract);
        for (uint16 i = from; i <= to; i++) {
            _mint(v1.ownerOf(i), i);
        }
        totalSupply += (to - from + 1);
    }

    /// ==== Minting

    /// @notice mint an unrevealed token using eth
    /// @param amount amount to mint
    function mintWithETH(uint16 amount)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(amount > 0, "INVALID_AMOUNT");
        require(amount * mintPrice == msg.value, "WRONG_VALUE");
        uint16 supply = totalSupply;
        require(supply + amount <= genZeroSupply, "NOT_ENOUGH_TOKENS");
        totalSupply = supply + amount;
        address to = _msgSender();
        for (uint16 i = 0; i < amount; i++) {
            _safeMint(to, supply + i);
        }
    }

    /// ==== Revealing

    /// @notice set the seed for the OG tokens. Once this is set, it cannot be changed!
    function revealOgTokens(uint256 seed) external onlyOwner {
        require(ogSeed == 0, "ALREADY_SET");
        ogSeed = seed;
        emit OGRevealed(seed);
    }

    /// @notice set the seed for the non-og Gen 0 tokens. Once this is set, it cannot be changed!
    function revealGenZeroTokens(uint256 seed) external onlyOwner {
        require(genZeroSeed == 0, "ALREADY_SET");
        genZeroSeed = seed;
        emit Gen0Revealed(seed);
    }

    /// ====================

    /// @notice Calculate the seed for a specific token
    /// - For OG tokens, the seed is derived from ogSeed
    /// - For Gen 0 tokens, the seed is derived from genZeroSeed
    /// - For other tokens, there is a seed for each for each
    function seedForToken(uint16 tokenId) public view returns (uint256) {
        uint16 supply = totalSupply;

        uint16 og = ogSupply;
        if (tokenId < og) {
            // amount of minted tokens needs to be greater than or equal to the og supply
            uint256 seed = ogSeed;
            if (supply >= og && seed != 0) {
                return
                    uint256(keccak256(abi.encodePacked(seed, "og", tokenId)));
            }

            return 0;
        }

        // read from storage only once
        uint16 pt = genZeroSupply;
        if (tokenId < pt) {
            // amount of minted tokens needs to be greater than or equal to the og supply
            uint256 seed = genZeroSeed;
            if (supply >= pt && seed != 0) {
                return
                    uint256(keccak256(abi.encodePacked(seed, "ze", tokenId)));
            }

            return 0;
        }

        if (supply > tokenId) {
            return tokenSeeds[tokenId];
        }

        return 0;
    }

    /// ==== Functions to calculate traits given a seed

    function _isVampire(uint256 seed) private pure returns (bool) {
        return (seed & 0xFFFF) % 10 == 0;
    }

    /// Human Traits

    function _tokenTraitHumanSkin(uint256 seed) private pure returns (uint8) {
        uint256 traitSeed = (seed >> 16) & 0xFFFF;
        uint256 trait = traitSeed % 5;
        if (traitSeed >> 8 < [50, 15, 15, 250, 255][trait]) return uint8(trait);
        return [3, 4, 4, 0, 3][trait];
    }

    function _tokenTraitHumanFace(uint256 seed) private pure returns (uint8) {
        uint256 traitSeed = (seed >> 32) & 0xFFFF;
        uint256 trait = traitSeed % 19;
        if (
            traitSeed >> 8 <
            [
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
            ][trait]
        ) return uint8(trait);
        return
            [1, 0, 3, 1, 3, 3, 3, 4, 7, 4, 8, 4, 8, 10, 10, 10, 18, 18, 14][
                trait
            ];
    }

    function _tokenTraitHumanTShirt(uint256 seed) private pure returns (uint8) {
        uint256 traitSeed = (seed >> 48) & 0xFFFF;
        uint256 trait = traitSeed % 28;
        if (
            traitSeed >> 8 <
            [
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
            ][trait]
        ) return uint8(trait);
        return
            [
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
            ][trait];
    }

    function _tokenTraitHumanPants(uint256 seed) private pure returns (uint8) {
        uint256 traitSeed = (seed >> 64) & 0xFFFF;
        uint256 trait = traitSeed % 16;
        if (
            traitSeed >> 8 <
            [
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
            ][trait]
        ) return uint8(trait);
        return [2, 0, 1, 2, 3, 3, 4, 6, 7, 4, 6, 7, 8, 8, 15, 12][trait];
    }

    function _tokenTraitHumanBoots(uint256 seed) private pure returns (uint8) {
        uint256 traitSeed = (seed >> 80) & 0xFFFF;
        uint256 trait = traitSeed % 6;
        if (traitSeed >> 8 < [150, 30, 60, 255, 150, 60][trait])
            return uint8(trait);
        return [0, 3, 3, 0, 3, 4][trait];
    }

    function _tokenTraitHumanAccessory(uint256 seed)
        private
        pure
        returns (uint8)
    {
        uint256 traitSeed = (seed >> 96) & 0xFFFF;
        uint256 trait = traitSeed % 20;
        if (
            traitSeed >> 8 <
            [
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
            ][trait]
        ) return uint8(trait);
        return
            [
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
            ][trait];
    }

    function _tokenTraitHumanHair(uint256 seed) private pure returns (uint8) {
        uint256 traitSeed = (seed >> 112) & 0xFFFF;
        uint256 trait = traitSeed % 10;
        if (
            traitSeed >> 8 <
            [250, 115, 100, 40, 175, 255, 180, 100, 175, 185][trait]
        ) return uint8(trait);
        return [0, 0, 4, 6, 0, 4, 5, 9, 6, 8][trait];
    }

    /// ==== Vampire Traits

    function _tokenTraitVampireSkin(uint256 seed) private pure returns (uint8) {
        uint256 traitSeed = (seed >> 16) & 0xFFFF;
        uint256 trait = traitSeed % 13;
        if (
            traitSeed >> 8 <
            [234, 239, 234, 234, 255, 234, 244, 249, 130, 234, 234, 247, 234][
                trait
            ]
        ) return uint8(trait);
        return [0, 0, 1, 2, 3, 4, 5, 6, 12, 7, 9, 10, 11][trait];
    }

    function _tokenTraitVampireFace(uint256 seed) private pure returns (uint8) {
        uint256 traitSeed = (seed >> 32) & 0xFFFF;
        uint256 trait = traitSeed % 15;
        if (
            traitSeed >> 8 <
            [
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
            ][trait]
        ) return uint8(trait);
        return [1, 0, 1, 4, 2, 4, 5, 12, 12, 13, 13, 14, 5, 12, 13][trait];
    }

    function _tokenTraitVampireClothes(uint256 seed)
        private
        pure
        returns (uint8)
    {
        uint256 traitSeed = (seed >> 48) & 0xFFFF;
        uint256 trait = traitSeed % 27;
        if (
            traitSeed >> 8 <
            [
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
            ][trait]
        ) return uint8(trait);
        return
            [
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
            ][trait];
    }

    function _tokenTraitVampireCape(uint256 seed) private pure returns (uint8) {
        uint256 traitSeed = (seed >> 128) & 0xFFFF;
        uint256 trait = traitSeed % 9;
        if (traitSeed >> 8 < [9, 9, 150, 90, 9, 210, 9, 9, 255][trait])
            return uint8(trait);
        return [5, 5, 0, 2, 8, 3, 8, 8, 5][trait];
    }

    function _tokenTraitVampirePredatorIndex(uint256 seed)
        private
        pure
        returns (uint8)
    {
        uint256 traitSeed = (seed >> 144) & 0xFFFF;
        uint256 trait = traitSeed % 4;
        if (traitSeed >> 8 < [255, 8, 160, 73][trait]) return uint8(trait);
        return [0, 0, 0, 2][trait];
    }

    /// ==== State Control

    /// @notice set the max amount of gen 0 tokens
    function setGenZeroSupply(uint16 _genZeroSupply) external onlyOwner {
        require(genZeroSupply != _genZeroSupply, "NO_CHANGES");
        genZeroSupply = _genZeroSupply;
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
    /// we also need token 0 to so setup market places before mint
    function reserve(address to, uint16 amount) external onlyOwner {
        uint16 supply = totalSupply;
        require(supply + amount < genZeroSupply);
        totalSupply = supply + amount;
        for (uint16 i = 0; i < amount; i++) {
            _safeMint(to, supply + i);
        }
    }

    /// ==== pause/unpause

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// ==== IVampireGameControls Overrides

    /// @notice see {IVampireGameControls.mintFromController}
    function mintFromController(address receiver, uint16 amount)
        external
        override
        whenNotPaused
        onlyControllers
    {
        uint16 supply = totalSupply;
        require(supply + amount <= maxSupply, "NOT_ENOUGH_TOKENS");
        totalSupply = supply + amount;
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(receiver, supply + i);
        }
    }

    /// @notice for a game controller to reveal the metadata of multiple token ids
    function controllerRevealTokens(
        uint16[] calldata tokenIds,
        uint256[] calldata seeds
    ) external override whenNotPaused onlyControllers {
        require(
            tokenIds.length == seeds.length,
            "INPUTS_SHOULD_HAVE_SAME_LENGTH"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenSeeds[tokenIds[i]] == 0, "ALREADY_REVEALED");
            tokenSeeds[tokenIds[i]] = seeds[i];
            emit TokenRevealed(tokenIds[i], seeds[i]);
        }
    }

    /// ==== IVampireGame Overrides

    /// @notice see {IVampireGame.getTotalSupply}
    function getTotalSupply() external view override returns (uint16) {
        return totalSupply;
    }

    /// @notice see {IVampireGame.getOGSupply}
    function getOGSupply() external view override returns (uint16) {
        return ogSupply;
    }

    /// @notice see {IVampireGame.getGenZeroSupply}
    function getGenZeroSupply() external view override returns (uint16) {
        return genZeroSupply;
    }

    /// @notice see {IVampireGame.getMaxSupply}
    function getMaxSupply() external view override returns (uint16) {
        return maxSupply;
    }

    /// @notice see {IVampireGame.getTokenTraits}
    function getTokenTraits(uint16 tokenId)
        external
        view
        override
        returns (TokenTraits memory tt)
    {
        uint256 seed = seedForToken(tokenId);
        require(seed != 0, "NOT_REVEALED");
        tt.isVampire = _isVampire(seed);

        if (tt.isVampire) {
            tt.skin = _tokenTraitVampireSkin(seed);
            tt.face = _tokenTraitVampireFace(seed);
            tt.clothes = _tokenTraitVampireClothes(seed);
            tt.cape = _tokenTraitVampireCape(seed);
            tt.predatorIndex = _tokenTraitVampirePredatorIndex(seed);
        } else {
            tt.skin = _tokenTraitHumanSkin(seed);
            tt.face = _tokenTraitHumanFace(seed);
            tt.clothes = _tokenTraitHumanTShirt(seed);
            tt.pants = _tokenTraitHumanPants(seed);
            tt.boots = _tokenTraitHumanBoots(seed);
            tt.accessory = _tokenTraitHumanAccessory(seed);
            tt.hair = _tokenTraitHumanHair(seed);
        }
    }

    function isTokenVampire(uint16 tokenId)
        external
        view
        override
        returns (bool)
    {
        return _isVampire(seedForToken(tokenId));
    }

    function getPredatorIndex(uint16 tokenId)
        external
        view
        override
        returns (uint8)
    {
        uint256 seed = seedForToken(tokenId);
        require(seed != 0, "NOT_REVEALED");
        return _tokenTraitVampirePredatorIndex(seed);
    }

    /// @notice see {IVampireGame.isTokenRevealed(tokenId)}
    function isTokenRevealed(uint16 tokenId)
        public
        view
        override
        returns (bool)
    {
        return seedForToken(tokenId) != 0;
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

pragma solidity ^0.8.6;

struct TokenTraits {
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
    /// @notice get the amount of tokens minted
    function getTotalSupply() external view returns (uint16);

    /// @notice get tthe amount of og supply
    function getOGSupply() external view returns (uint16);

    /// @notice get the total supply of gen-0
    function getGenZeroSupply() external view returns (uint16);

    /// @notice get the total supply of tokens
    function getMaxSupply() external view returns (uint16);

    /// @notice get the TokenTraits for a given tokenId
    function getTokenTraits(uint16 tokenId) external view returns (TokenTraits memory);

    /// @notice check if token id a vampire
    function isTokenVampire(uint16 tokenId) external view returns (bool);

    /// @notice get the Predator Index for a given tokenId
    function getPredatorIndex(uint16 tokenId) external view returns (uint8);

    /// @notice returns true if a token is aleady revealed
    function isTokenRevealed(uint16 tokenId) external view returns (bool);
}

/// @notice Interface to control parts of the VampireGame ERC 721
interface IVampireGameControls {
    /// @notice mint any amount of nft to any address
    /// Requirements:
    /// - message sender should be an allowed address (game contract)
    /// - amount + totalSupply() has to be smaller than MAX_SUPPLY
    function mintFromController(address receiver, uint16 amount) external;

    /// @notice reveal a list of tokens using specific seeds for each
    function controllerRevealTokens(uint16[] calldata tokenIds, uint256[] calldata seeds) external;
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