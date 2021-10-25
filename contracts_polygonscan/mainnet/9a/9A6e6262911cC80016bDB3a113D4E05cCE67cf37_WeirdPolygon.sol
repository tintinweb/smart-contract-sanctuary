// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../ScarceDynamicNFT.sol";
import "../../libraries/LibERC721JSONMetadata.sol";
import "../../libraries/LibSVGWeirdPolygon.sol";
import "../../utils/ContextMixin.sol";
import "../../metatx/NativeMetaTransaction.sol";

import "./IWeirdPolygon.sol";

// #######################################################################################################################################
// @@@  @@@  @@@  @@@@@@@@  @@@  @@@@@@@   @@@@@@@        @@@@@@@    @@@@@@   @@@       @@@ @@@   @@@@@@@@   @@@@@@   @@@  @@@   @@@@@@     #
// @@@  @@@  @@@  @@@@@@@@  @@@  @@@@@@@@  @@@@@@@@       @@@@@@@@  @@@@@@@@  @@@       @@@ @@@  @@@@@@@@@  @@@@@@@@  @@@@ @@@  @@@@@@@     #
// @@!  @@!  @@!  @@!       @@!  @@!  @@@  @@!  @@@       @@!  @@@  @@!  @@@  @@!       @@! [email protected]@  [email protected]@        @@!  @@@  @@[email protected][email protected]@@  [email protected]@         #
// [email protected]!  [email protected]!  [email protected]!  [email protected]!       [email protected]!  [email protected]!  @[email protected] [email protected]!  @[email protected] [email protected]!  @[email protected] [email protected]!  @[email protected] [email protected]!       [email protected]! @!!  [email protected]!        [email protected]!  @[email protected] [email protected][email protected][email protected]!  [email protected]!         #
// @!!  [email protected]  @[email protected]  @!!!:!    [email protected]  @[email protected][email protected]!   @[email protected] [email protected]!       @[email protected]@[email protected]!   @[email protected] [email protected]!  @!!        [email protected][email protected]!   [email protected]! @[email protected][email protected]  @[email protected] [email protected]!  @[email protected] [email protected]!  [email protected]@!!      #
// [email protected]!  !!!  [email protected]!  !!!!!:    !!!  [email protected][email protected]!    [email protected]!  !!!       [email protected]!!!    [email protected]!  !!!  !!!         @!!!   !!! [email protected]!!  [email protected]!  !!!  [email protected]!  !!!   [email protected]!!!     #
// !!:  !!:  !!:  !!:       !!:  !!: :!!   !!:  !!!       !!:       !!:  !!!  !!:         !!:    :!!   !!:  !!:  !!!  !!:  !!!       !:!    #
// :!:  :!:  :!:  :!:       :!:  :!:  !:!  :!:  !:!       :!:       :!:  !:!   :!:        :!:    :!:   !::  :!:  !:!  :!:  !:!      !:!     #
//  :::: :: :::    :: ::::   ::  ::   :::   :::: ::        ::       ::::: ::   :: ::::     ::     ::: ::::  ::::: ::   ::   ::  :::: ::     #
//   :: :  : :    : :: ::   :     :   : :  :: :  :         :         : :  :   : :: : :     :      :: :: :    : :  :   ::    :   :: : :      #
// #######################################################################################################################################

contract WeirdPolygon is
    ScarceDynamicNFT,
    IWeirdPolygon,
    NativeMetaTransaction,
    ContextMixin
{
    // MARK: - Mint settings

    // The minting price.
    uint256 public constant MINT_PRICE = 1.00 ether;
    // The initial mint limit.
    // This can be changed by the owner of the contract.
    // Upon a change, a `MaxSupplyChanged` event will be emitted. (cf ScarceDynamicNFT.sol)
    // Once ownership is revoked, the mint limit cannot be changed.
    uint256 public constant INITIAL_MINT_LIMIT = 1000;

    // MARK: - Settings

    // The default size of the canvas.
    uint256 public constant DEFAULT_SIZE = 1000;

    // Computing a Polygon is an expensive operation – so generations are limited.
    uint256 public constant MAX_GENERATION_SVG = 8;
    // The maximum possible number of layers at mint time.
    // Must be <= MAX_GENERATION
    uint256 public constant MAX_GENERATION_AT_MINT = 4;
    // The maximum difficulty.
    uint256 public constant MAX_DIFFICULTY = 8;

    uint256 private MATIC_MAINNET_CHAIN_ID = 137;
    uint256 private MATIC_MUMBAI_CHAIN_ID = 0x13881;

    // MARK: - Metadata

    // Metadata about a specific WeirdPolygon.
    struct Metadata {
        // The current generation of the WeirdPolygon.
        uint256 generation;
        // The random seed assigned at mint time.
        // We only compute a single truly random seed as
        // it can then be used as a base for other seeds.
        uint256 mintSeed;
        // The timestamp at which the token was minted.
        uint256 mintDate;
        // Base layers.
        // Could be a uint8.
        uint8 additionalBaseLayers;
        // The difficulty to evolve.
        uint8 difficulty;
        // The number of transfers done during the current generation.
        // When this value reaches 'difficulty', the value is reset and generation increased.
        uint8 currentGenerationTransfers;
        // The width of the stroke.
        uint8 strokeWidth;
        // The color of the width.
        LibColor.Color strokeColor;
        // The hash of the seeds that were used to generate the most recent SVG.
        // This is useful to prevent recomputing the image if it doesn't need to.
        uint256 previousHash;
        // The time at which a transfer occured.
        // Used to derive a seed, with `transferDifficulty` and `mintSeed`.
        // Does not contain the minting block information.
        uint256[] transferTime;
        // The difficulty of the block on which the transfer tx was
        // executed.
        // Used to derive a seed, with `transferTime` and `mintSeed`.
        // Does not contain the minting block information.
        uint256[] transferDifficulty;
    }
    mapping(uint256 => Metadata) private m_metadata;

    // MARK: - Lifecycle

    constructor(
        address vrfCoordinator,
        address linkToken,
        bytes32 linkKeyHash,
        uint256 linkFee
    )
        ScarceDynamicNFT(
            "WeirdPolygon",
            "WEIRDPOLY",
            INITIAL_MINT_LIMIT,
            vrfCoordinator,
            linkToken,
            linkKeyHash,
            linkFee
        )
    {
        _initializeEIP712(name());
    }

    // MARK: - Mint

    function mintToken() external payable returns (uint256) {
        if (msg.sender != owner()) {
            require(MINT_PRICE <= msg.value, "Value sent is not correct");
        }

        return _mintToken();
    }

    function _mintToken() internal virtual override returns (uint256 tokenId) {
        tokenId = super._mintToken();

        // Mint will be finalized after the random number has been generated.
        requestRandomNumber(tokenId);
    }

    function _mustFinishMint(uint256 tokenId, address tokenOwner)
        internal
        override
    {
        uint256 mintDate = block.timestamp;

        require(m_metadata[tokenId].generation == 0, "Already minted");

        _safeMint(tokenOwner, tokenId);
        emit TokenMinted(tokenId, tokenOwner, mintDate);
    }

    function _didGenerateRandomNumber(uint256 tokenId, uint256 randomNumber)
        internal
        virtual
        override
    {
        super._didGenerateRandomNumber(tokenId, randomNumber);

        m_metadata[tokenId].mintDate = block.timestamp;
        m_metadata[tokenId].mintSeed = randomNumber;
        m_metadata[tokenId].generation = 1;

        m_metadata[tokenId]
            .additionalBaseLayers = computeInitialAdditionalGeneration(
            randomNumber,
            0
        );
        m_metadata[tokenId].difficulty = uint8(
            (generatePseudoRandomWithSeed(randomNumber, 1) % MAX_DIFFICULTY) + 1
        );

        {
            bool shouldHaveStroke = (generatePseudoRandomWithSeed(
                randomNumber,
                2
            ) % 100) <= 5;
            if (shouldHaveStroke) {
                // Stroke is between 5 and 100
                m_metadata[tokenId].strokeWidth = uint8(
                    (generatePseudoRandomWithSeed(randomNumber, 3) % 95) + 5
                );

                bool shouldHaveWhiteStroke = (generatePseudoRandomWithSeed(
                    randomNumber,
                    4
                ) % 100) <= 25;
                if (shouldHaveWhiteStroke) {
                    m_metadata[tokenId].strokeColor = LibColor.NewColor(
                        0xff,
                        0xff,
                        0xff,
                        // Alpha is ignored by SVG.
                        0x00
                    );
                }
            }
        }
    }

    // MARK: - Evolution

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0) || to == address(0)) {
            // Don't evolve when the NFT is minted or burnt.
            return;
        }

        if (getChainID() == MATIC_MAINNET_CHAIN_ID) {
            if (from == to) {
                // Prevent self-transfers – only on Matic Mainnet.
                return;
            }
        }

        // Everytime the NFT is transferred to another account, it 'evolves'.
        m_metadata[tokenId].currentGenerationTransfers += 1;

        // Ready to evolve !
        if (
            m_metadata[tokenId].currentGenerationTransfers ==
            m_metadata[tokenId].difficulty
        ) {
            // Store those values as they'll be used to derive the associated seed.
            m_metadata[tokenId].transferTime.push(block.timestamp);
            m_metadata[tokenId].transferDifficulty.push(block.difficulty);
            m_metadata[tokenId].generation += 1;

            // And reset current transfer count.
            m_metadata[tokenId].currentGenerationTransfers = 0;

            // Refresh metadata and appearance
            computeAsset(tokenId);
        }
    }

    // MARK: - Image generation

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        hasBeenMintedOnly(tokenId)
        returns (string memory)
    {
        bytes memory attributes = abi.encodePacked(
            LibERC721JSONMetadata.makeAttributeNumberWithDisplayType(
                LibERC721JSONMetadata.AttributeDisplayType.NUMBER,
                "Mint Complexity",
                m_metadata[tokenId].additionalBaseLayers + 1
            ),
            ",",
            LibERC721JSONMetadata.makeAttributeNumberWithDisplayType(
                LibERC721JSONMetadata.AttributeDisplayType.NUMBER,
                "Difficulty",
                m_metadata[tokenId].difficulty
            ),
            ",",
            LibERC721JSONMetadata.makeAttributeNumberWithDisplayType(
                LibERC721JSONMetadata.AttributeDisplayType.NUMBER,
                "Transfers for Current Generation",
                m_metadata[tokenId].currentGenerationTransfers
            ),
            ",",
            LibERC721JSONMetadata.makeAttributeNumberWithDisplayType(
                LibERC721JSONMetadata.AttributeDisplayType.DATE,
                "Birthday",
                m_metadata[tokenId].mintDate
            ),
            ",",
            LibERC721JSONMetadata.makeAttributeNumber(
                "Generation",
                m_metadata[tokenId].generation
            ),
            ",",
            LibERC721JSONMetadata.makeAttributeNumber(
                "Stroke width",
                m_metadata[tokenId].strokeWidth
            )
        );

        if (m_metadata[tokenId].strokeWidth > 0) {
            if (m_metadata[tokenId].strokeColor.rawValue == 0x00) {
                attributes = abi.encodePacked(
                    attributes,
                    ",",
                    LibERC721JSONMetadata.makeValueStr("Black Stroke")
                );
            } else {
                attributes = abi.encodePacked(
                    attributes,
                    ",",
                    LibERC721JSONMetadata.makeValueStr("White Stroke")
                );
            }
        }

        return
            buildTokenURI(tokenId, createTokenTitle(tokenId), "", attributes);
    }

    /**
     * Generate the graphic art for the provided tokenId.
     */
    function computeAsset(uint256 tokenId)
        public
        virtual
        override
        hasBeenMintedOnly(tokenId)
    {
        uint256[] memory seeds = computeSeeds(tokenId);
        uint256 seedsHash = uint256(keccak256(abi.encodePacked(seeds)));

        if (seedsHash == m_metadata[tokenId].previousHash) {
            // Prevent re-computing the image if not needed.
            // This has the cost of computing the seeds multiple time, but it's
            // a far more light operation than computing the whole SVG.
            return;
        }

        // Update the seed and trigger the computation.
        m_metadata[tokenId].previousHash = seedsHash;
        super.computeAsset(tokenId);
    }

    /**
     * This is the part that generate the graphics.
     *
     * Must be implemented by child;
     */
    function generateSVG(uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bytes memory)
    {
        return
            LibSVGWeirdPolygon.GenerateSVG(
                DEFAULT_SIZE,
                computeSeeds(tokenId),
                m_metadata[tokenId].strokeWidth,
                m_metadata[tokenId].strokeColor
            );
    }

    // MARK: - Random & helper

    function computeSeeds(uint256 tokenId)
        private
        view
        returns (uint256[] memory)
    {
        Metadata storage cur = m_metadata[tokenId];

        require(
            cur.generation > 0 &&
                cur.generation - 1 == cur.transferDifficulty.length
        );
        uint256 wantedGenerations = cur.generation + cur.additionalBaseLayers;

        uint256 totalOfSeeds = wantedGenerations > MAX_GENERATION_SVG
            ? MAX_GENERATION_SVG
            : wantedGenerations;
        uint256 globalIndex = 0;
        uint256[] memory seeds = new uint256[](totalOfSeeds);

        seeds[globalIndex] = cur.mintSeed;
        globalIndex++;

        for (
            uint256 ndx = 0;
            globalIndex < totalOfSeeds && ndx < cur.additionalBaseLayers;
            ndx += 1
        ) {
            seeds[globalIndex] = deriveRandomNumber(cur.mintSeed, ndx);
            globalIndex++;
        }

        for (
            uint256 ndx = 0;
            globalIndex < totalOfSeeds && ndx < cur.transferDifficulty.length;
            ndx += 1
        ) {
            seeds[globalIndex] = uint256(
                // Derive a pseudo-random seed from the original truly random seed,
                // and block info at each transfer time.
                keccak256(
                    abi.encode(
                        cur.mintSeed,
                        cur.transferTime[ndx],
                        cur.transferDifficulty[ndx]
                    )
                )
            );
            globalIndex++;
        }

        return seeds;
    }

    function computeInitialAdditionalGeneration(uint256 seed, uint256 salt)
        private
        view
        returns (uint8)
    {
        uint256 initialLayerRandom = generatePseudoRandomWithSeed(seed, salt);
        uint256 initialLayerRandomMask = 0x0000000000000000000000000000000000000007ffffffffffffffff00000000;

        if (
            ((initialLayerRandom & initialLayerRandomMask) >> 32) >
            0xCAFEBABEDEADBEEF
        ) {
            return
                uint8(
                    deriveRandomNumber(initialLayerRandom, 20) %
                        MAX_GENERATION_AT_MINT
                );
        }

        return 0;
    }

    function createTokenTitle(uint256 tokenId)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("#", Strings.toString(tokenId)));
    }

    // MARK: - OpenSea
    // Documentation: https://docs.opensea.io/docs/polygon-basic-integration

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // if OpenSea's ERC721 Proxy Address is detected, auto-return true, on Polygon
        if (
            getChainID() == MATIC_MAINNET_CHAIN_ID &&
            _operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)
        ) {
            return true;
        }

        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        uint256 chainId = getChainID();
        if (
            chainId == MATIC_MAINNET_CHAIN_ID ||
            chainId == MATIC_MUMBAI_CHAIN_ID
        ) {
            return ContextMixin.msgSender();
        }

        return Context._msgSender();
    }

    function getChainID() private view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    // MARK: - Getters

    modifier hasBeenMintedOnly(uint256 tokenId) {
        require(
            m_metadata[tokenId].generation != 0,
            "Token hasn't been minted"
        );
        _;
    }

    function generationOf(uint256 tokenId)
        external
        view
        hasBeenMintedOnly(tokenId)
        returns (uint256)
    {
        return m_metadata[tokenId].generation;
    }

    function mintDateOf(uint256 tokenId)
        external
        view
        hasBeenMintedOnly(tokenId)
        returns (uint256)
    {
        return m_metadata[tokenId].mintDate;
    }

    function additionalBaseLayersOf(uint256 tokenId)
        external
        view
        hasBeenMintedOnly(tokenId)
        returns (uint256)
    {
        return m_metadata[tokenId].additionalBaseLayers;
    }

    function difficultyOf(uint256 tokenId)
        external
        view
        hasBeenMintedOnly(tokenId)
        returns (uint256)
    {
        return m_metadata[tokenId].difficulty;
    }

    function currentGenerationTransfersOf(uint256 tokenId)
        external
        view
        hasBeenMintedOnly(tokenId)
        returns (uint256)
    {
        return m_metadata[tokenId].currentGenerationTransfers;
    }

    function strokeWidthOf(uint256 tokenId)
        external
        view
        hasBeenMintedOnly(tokenId)
        returns (uint256)
    {
        return m_metadata[tokenId].strokeWidth;
    }

    function strokeColorOf(uint256 tokenId)
        external
        view
        hasBeenMintedOnly(tokenId)
        returns (uint32)
    {
        return m_metadata[tokenId].strokeColor.rawValue;
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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./DynamicSVGNFT.sol";
import "./IScarceDynamicNFT.sol";

abstract contract ScarceDynamicNFT is
    IScarceDynamicNFT,
    DynamicSVGNFT,
    Ownable
{
    // The maximum amount of tokens that can be created.
    uint256 private m_maxMintableTokens = 0;

    // We could use `totalSupply()` but because of ChainLink VRF
    // gas limitation, this could result in a same id produced twice – which won't happen with this.
    uint256 private m_tokenCurrentIndex = 0;

    // MARK: - Lifecycle

    constructor(
        string memory name,
        string memory symbol,
        uint256 maximumTokens,
        address vrfCoordinator,
        address linkToken,
        bytes32 linkKeyHash,
        uint256 linkFee
    )
        DynamicSVGNFT(
            name,
            symbol,
            vrfCoordinator,
            linkToken,
            linkKeyHash,
            linkFee
        )
    {
        _updateTokenLimit(maximumTokens);
    }

    // MARK: - Mint

    /**
     * Mint one NFT.
     */
    function _mintToken() internal virtual returns (uint256 tokenId) {
        require(
            m_tokenCurrentIndex + 1 <= m_maxMintableTokens,
            "Purchase would exceed max supply of NFTs"
        );

        tokenId = m_tokenCurrentIndex + 1;
        m_tokenCurrentIndex += 1;

        // The mint should be implemented by the children.
    }

    // MARK: - Update Limit

    function updateTokenLimit(uint256 newLimit) external onlyOwner {
        _updateTokenLimit(newLimit);
    }

    function _updateTokenLimit(uint256 newLimit) private {
        uint256 previous = m_maxMintableTokens;
        m_maxMintableTokens = newLimit;

        emit MaxSupplyChanged(previous, newLimit);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

import "./LibJSON.sol";

// A library to create a ERC721 Metadata JSON.
library LibERC721JSONMetadata {
    string private constant JSON_BASE64_URL_PREFIX =
        "data:application/json;base64,";

    string private constant FIELD_ATTR_DISPLAY_TYPE = "display_type";
    string private constant FIELD_ATTR_TRAIT_TYPE = "trait_type";
    string private constant FIELD_ATTR_VALUE = "value";

    enum AttributeDisplayType {
        NONE,
        DATE,
        NUMBER,
        BOOST_PERCENTAGE,
        BOOST_NUMBER
    }

    function createBase64EncodedURI(bytes memory data)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(JSON_BASE64_URL_PREFIX, Base64.encode(data))
            );
    }

    function createCollectionMetadata(
        string memory name,
        string memory description,
        string memory imageURI,
        string memory externalLink,
        uint256 sellerFeesBasePoints,
        address feeRecipient
    ) internal pure returns (bytes memory) {
        return
            LibJSON.wrapInDictionnary(
                abi.encodePacked(
                    LibJSON.makeFieldString("name", name, false),
                    LibJSON.makeFieldString("description", description, false),
                    LibJSON.makeFieldString("image", imageURI, false),
                    LibJSON.makeFieldString(
                        "external_link",
                        externalLink,
                        false
                    ),
                    LibJSON.makeFieldNumber(
                        "seller_fee_basis_points",
                        sellerFeesBasePoints,
                        false
                    ),
                    LibJSON.makeFieldString(
                        "fee_recipient",
                        Strings.toHexString(uint160(feeRecipient)),
                        true
                    )
                )
            );
    }

    function createMetadata(
        string memory name,
        string memory description,
        string memory imageURI,
        bytes memory attributesElements
    ) internal pure returns (bytes memory) {
        return
            LibJSON.wrapInDictionnary(
                abi.encodePacked(
                    LibJSON.makeFieldString("name", name, false),
                    LibJSON.makeFieldString("description", description, false),
                    LibJSON.makeFieldArray(
                        "attributes",
                        string(LibJSON.wrapInArray(attributesElements)),
                        false
                    ),
                    LibJSON.makeFieldString("image", imageURI, true)
                )
            );
    }

    function makeAttributeStr(string memory traitType, string memory value)
        internal
        pure
        returns (bytes memory)
    {
        return
            LibJSON.wrapInDictionnary(
                abi.encodePacked(
                    LibJSON.makeFieldString(
                        FIELD_ATTR_TRAIT_TYPE,
                        traitType,
                        false
                    ),
                    LibJSON.makeFieldString(FIELD_ATTR_VALUE, value, true)
                )
            );
    }

    function makeValueStr(string memory value)
        internal
        pure
        returns (bytes memory)
    {
        return
            LibJSON.wrapInDictionnary(
                LibJSON.makeFieldString(FIELD_ATTR_VALUE, value, true)
            );
    }

    function makeAttributeNumber(string memory traitType, uint256 value)
        internal
        pure
        returns (bytes memory)
    {
        return
            LibJSON.wrapInDictionnary(
                abi.encodePacked(
                    LibJSON.makeFieldString(
                        FIELD_ATTR_TRAIT_TYPE,
                        traitType,
                        false
                    ),
                    LibJSON.makeFieldNumber(FIELD_ATTR_VALUE, value, true)
                )
            );
    }

    function makeValueNumber(uint256 value)
        internal
        pure
        returns (bytes memory)
    {
        return
            LibJSON.wrapInDictionnary(
                LibJSON.makeFieldNumber(FIELD_ATTR_VALUE, value, true)
            );
    }

    function makeAttributeNumberWithDisplayType(
        AttributeDisplayType displayType,
        string memory traitType,
        uint256 value
    ) internal pure returns (bytes memory) {
        return
            LibJSON.wrapInDictionnary(
                abi.encodePacked(
                    LibJSON.makeFieldString(
                        FIELD_ATTR_DISPLAY_TYPE,
                        displayTypeString(displayType),
                        false
                    ),
                    LibJSON.makeFieldString(
                        FIELD_ATTR_TRAIT_TYPE,
                        traitType,
                        false
                    ),
                    LibJSON.makeFieldNumber(FIELD_ATTR_VALUE, value, true)
                )
            );
    }

    function displayTypeString(AttributeDisplayType value)
        private
        pure
        returns (string memory)
    {
        if (value == AttributeDisplayType.NUMBER) {
            return "number";
        } else if (value == AttributeDisplayType.DATE) {
            return "date";
        } else if (value == AttributeDisplayType.BOOST_PERCENTAGE) {
            return "boost_percentage";
        } else if (value == AttributeDisplayType.BOOST_NUMBER) {
            return "boost_number";
        }

        return "";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./LibSVG.sol";

// A library that implements SVG rendering for WeirdPolygon collection.
library LibSVGWeirdPolygon {
    function GenerateSVG(
        uint256 canvasSideSize,
        uint256[] memory seeds,
        uint8 strokeWidth,
        LibColor.Color storage strokeColor
    ) internal pure returns (bytes memory) {
        bytes memory svgContent = "";

        {
            LibSVG.Polygon[] memory polygons = generatePolygonPoints(
                canvasSideSize,
                seeds,
                strokeWidth,
                strokeColor
            );
            for (uint256 ndx = 0; ndx < polygons.length; ndx += 1) {
                bytes memory shapeResult = LibSVG.MakePolygon(polygons[ndx]);
                svgContent = abi.encodePacked(svgContent, shapeResult);
            }
        }

        return
            LibSVG.WrapAsSVG(
                svgContent,
                LibSVG.Size({
                    width: uint128(canvasSideSize),
                    height: uint128(canvasSideSize)
                })
            );
    }

    function generatePolygonPoints(
        uint256 canvasSideSize,
        uint256[] memory seeds,
        uint8 strokeWidth,
        LibColor.Color storage strokeColor
    ) private pure returns (LibSVG.Polygon[] memory) {
        uint256 drawingDimensions = seeds.length;
        LibSVG.Polygon[] memory polygons = new LibSVG.Polygon[](
            drawingDimensions * drawingDimensions
        );

        // We're generating a square.
        uint256 cellWidth = canvasSideSize / drawingDimensions;
        uint256 cellHeight = cellWidth;

        for (uint256 row = 0; row < drawingDimensions; row += 1) {
            for (uint256 col = 0; col < drawingDimensions; col += 1) {
                uint256 currentIndex = twoDimensionIndexToSingle(
                    row,
                    col,
                    drawingDimensions
                );

                // Build bottom right corner
                polygons[currentIndex].bottomRight = LibSVG.Position({
                    x: uint32((col + 1) * cellWidth),
                    y: uint32((row + 1) * cellHeight)
                });

                // Build top Right corner.
                if (row == 0) {
                    polygons[currentIndex].topRight = LibSVG.Position({
                        x: uint32((col + 1) * cellWidth),
                        y: 0
                    });
                } else {
                    polygons[currentIndex].topRight = polygons[
                        twoDimensionIndexToSingle(
                            row - 1,
                            col,
                            drawingDimensions
                        )
                    ].bottomRight;
                }

                // Build top & bottom Left corners.
                if (col == 0) {
                    if (row == 0) {
                        polygons[currentIndex].topLeft = LibSVG.Position({
                            x: 0,
                            y: 0
                        });
                    } else {
                        polygons[currentIndex].topLeft = polygons[
                            twoDimensionIndexToSingle(
                                row - 1,
                                0,
                                drawingDimensions
                            )
                        ].bottomLeft;
                    }

                    polygons[currentIndex].bottomLeft = LibSVG.Position({
                        x: 0,
                        y: uint32((row + 1) * cellHeight)
                    });
                } else {
                    uint256 previousElementIndex = twoDimensionIndexToSingle(
                        row,
                        col - 1,
                        drawingDimensions
                    );
                    polygons[currentIndex].topLeft = polygons[
                        previousElementIndex
                    ].topRight;
                    polygons[currentIndex].bottomLeft = polygons[
                        previousElementIndex
                    ].bottomRight;
                }

                // Generate a random color with alpha at 0% since it's ignored by SVG.
                polygons[currentIndex].fill.rawValue = uint32(
                    (uint256(keccak256(abi.encode(seeds[row], seeds[col]))) %
                        0xFFFFFFFF) & 0x00FFFFFF
                );
                polygons[currentIndex].stroke = LibSVG.Stroke({
                    width: strokeWidth,
                    color: strokeColor
                });

                // Apply jitter if needed

                if (col == 0) {
                    uint32 currentValue = polygons[currentIndex].bottomLeft.y;
                    int32 localJitter = jitter(
                        seeds[row],
                        seeds[col],
                        currentValue,
                        cellHeight
                    );

                    if (localJitter < 0) {
                        uint32 absJitter = uint32(localJitter * -1);

                        if (currentValue > absJitter) {
                            polygons[currentIndex].bottomLeft.y -= absJitter;
                        } else {
                            polygons[currentIndex].bottomLeft.y = 0;
                        }
                    } else {
                        polygons[currentIndex].bottomLeft.y += uint32(
                            localJitter
                        );
                    }
                }

                if (row == 0 && col < drawingDimensions - 1) {
                    uint32 currentValue = polygons[currentIndex].topRight.x;
                    int32 localJitter = jitter(
                        seeds[row],
                        seeds[col],
                        currentValue,
                        cellWidth
                    );

                    if (localJitter < 0) {
                        uint32 absJitter = uint32(localJitter * -1);

                        if (currentValue > absJitter) {
                            polygons[currentIndex].topRight.x -= absJitter;
                        } else {
                            polygons[currentIndex].topRight.x = 0;
                        }
                    } else {
                        polygons[currentIndex].topRight.x += uint32(
                            localJitter
                        );
                    }
                }

                if (row < drawingDimensions - 1) {
                    uint32 currentValue = polygons[currentIndex].bottomRight.y;
                    int32 localJitter = jitter(
                        seeds[row],
                        seeds[col],
                        currentValue,
                        cellHeight
                    );

                    if (localJitter < 0) {
                        uint32 absJitter = uint32(localJitter * -1);

                        if (currentValue > absJitter) {
                            polygons[currentIndex].bottomRight.y -= absJitter;
                        } else {
                            polygons[currentIndex].bottomRight.y = 0;
                        }
                    } else {
                        polygons[currentIndex].bottomRight.y += uint32(
                            localJitter
                        );
                    }
                }

                if (col < drawingDimensions - 1) {
                    uint32 currentValue = polygons[currentIndex].bottomRight.x;
                    int32 localJitter = jitter(
                        seeds[row],
                        seeds[col],
                        currentValue,
                        cellWidth
                    );

                    if (localJitter < 0) {
                        uint32 absJitter = uint32(localJitter * -1);

                        if (currentValue > absJitter) {
                            polygons[currentIndex].bottomRight.x -= absJitter;
                        } else {
                            polygons[currentIndex].bottomRight.x = 0;
                        }
                    } else {
                        polygons[currentIndex].bottomRight.x += uint32(
                            localJitter
                        );
                    }
                }
            }
        }

        return polygons;
    }

    // MARK: - Helpers

    function jitter(
        uint256 seedA,
        uint256 seedB,
        uint256 salt,
        uint256 dimension
    ) private pure returns (int32) {
        uint32 random = uint32(
            uint256(keccak256(abi.encode(seedA, seedB, salt))) % 100
        );
        int32 offsetSign = (int32(random) > 50) ? int32(1) : int32(-1);

        // At most 20% offset
        uint32 realSize = uint32(
            ((dimension * (100 + (random % 20))) / 100) - dimension
        );

        return int32(realSize) * offsetSign;
    }

    function twoDimensionIndexToSingle(
        uint256 x,
        uint256 y,
        uint256 height
    ) private pure returns (uint256) {
        return (x * height) + y;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * https://github.com/maticnetwork/pos-portal/blob/master/contracts/common/ContextMixin.sol
 * https://docs.opensea.io/docs/polygon-basic-integration
 */
abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }

        return sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
            )
        );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });
        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress] + 1;

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IWeirdPolygon {
    /**
     * Mint on token.
     */
    function mintToken() external payable returns (uint256);

    // MARK: - Getters

    /**
     * Returns the `generation` of a specific token.
     */
    function generationOf(uint256 tokenId) external view returns (uint256);

    /**
     * Returns the `mintDate` of a specific token.
     */
    function mintDateOf(uint256 tokenId) external view returns (uint256);

    /**
     * Returns the `additionalBaseLayers` of a specific token.
     */
    function additionalBaseLayersOf(uint256 tokenId)
        external
        view
        returns (uint256);

    /**
     * Returns the `difficulty` of a specific token.
     */
    function difficultyOf(uint256 tokenId) external view returns (uint256);

    /**
     * Returns the `currentGenerationTransfers` of a specific token.
     */
    function currentGenerationTransfersOf(uint256 tokenId)
        external
        view
        returns (uint256);

    /**
     * Returns the `strokeWidth` of a specific token.
     */
    function strokeWidthOf(uint256 tokenId) external view returns (uint256);

    /**
     * Returns the `strokeColor` of a specific token.
     * Colors are in the 0xAARRGGBB format.
     */
    function strokeColorOf(uint256 tokenId) external view returns (uint32);
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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "../libraries/LibSVG.sol";
import "../random/RandomConsumer.sol";
import "../opensea/SVGRepresentable.sol";

abstract contract DynamicSVGNFT is
    ERC721Enumerable,
    ERC721URIStorage,
    SVGRepresentable,
    RandomConsumer
{
    // MARK: - Events

    event TokenMinted(uint256 indexed tokenId, address owner, uint256 atDate);

    // MARK: - Lifecycle

    constructor(
        string memory name,
        string memory symbol,
        address vrfCoordinator,
        address linkToken,
        bytes32 linkKeyHash,
        uint256 linkFee
    )
        ERC721(name, symbol)
        RandomConsumer(vrfCoordinator, linkToken, linkKeyHash, linkFee)
    {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // MARK: - Image generation

    /**
     * Generate the graphic art for the provided tokenId.
     */
    function computeAsset(uint256 tokenId) public virtual override {
        require(tokenId > 0 && totalSupply() >= tokenId, "TOKEN_NOT_MINTED");
        require(!isRandomNumberGenerationPeding(tokenId), "LINK_WAIT_RESPONSE");

        super.computeAsset(tokenId);
    }

    // MARK: - ERC721 stuff

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IScarceDynamicNFT {
    event MaxSupplyChanged(uint256 previousLimit, uint256 newLimit);

    function updateTokenLimit(uint256 newLimit) external;
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

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./LibColor.sol";

library LibSVG {
    /**
     * Wraps the raw input of an SVG between <svg></svg> tags
     */
    function WrapAsSVG(bytes memory rawSvgContent, Size memory size)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(generateSvgHeader(size), rawSvgContent, "</svg>");
    }

    function generateSvgHeader(Size memory size)
        private
        pure
        returns (bytes memory)
    {
        string memory widthStr = Strings.toString(size.width);
        string memory heightStr = Strings.toString(size.height);

        return
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" ',
                attributeMakeWidthStr(widthStr),
                " ",
                attributeMakeHeightStr(heightStr),
                ' viewBox="0 0 ',
                widthStr,
                " ",
                heightStr,
                '">'
            );
    }

    // MARK: - <rect>

    /// Attributes of a <rect>
    struct Rect {
        Position pos;
        Size size;
        LibColor.Color fill;
    }

    function MakeRect(Rect memory params) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                "<rect ",
                sizeToAttributes(params.size),
                " ",
                positionToAttributes(params.pos),
                " ",
                attributeGenericValueBytes(
                    "fill",
                    LibColor.ColorToHexRepresentation(params.fill)
                ),
                " />"
            );
    }

    // MARK: - <polygon>

    // Attributes of a <polygon>
    struct Polygon {
        Position topLeft;
        Position topRight;
        Position bottomLeft;
        Position bottomRight;
        LibColor.Color fill;
        Stroke stroke;
    }

    function MakePolygon(Polygon memory params)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                '<polyline points="',
                abi.encodePacked(
                    positionToPointString(params.topLeft),
                    " ",
                    positionToPointString(params.topRight),
                    " ",
                    positionToPointString(params.bottomRight),
                    " ",
                    positionToPointString(params.bottomLeft)
                ),
                '" stroke-linejoin="round" stroke-linecap="round" ',
                attributeGenericValueBytes(
                    "fill",
                    LibColor.ColorToHexRepresentation(params.fill)
                ),
                " ",
                attributeGenericValueBytes(
                    "stroke",
                    LibColor.ColorToHexRepresentation(params.stroke.color)
                ),
                " ",
                attributeGenericValueStr(
                    "stroke-width",
                    Strings.toString(params.stroke.width)
                ),
                " />"
            );
    }

    // MARK: - Attributes

    function attributeMakeWidthStr(string memory value)
        private
        pure
        returns (bytes memory)
    {
        return attributeGenericValueStr("width", value);
    }

    function attributeMakeHeightStr(string memory value)
        private
        pure
        returns (bytes memory)
    {
        return attributeGenericValueStr("height", value);
    }

    function attributeMakeXStr(string memory value)
        private
        pure
        returns (bytes memory)
    {
        return attributeGenericValueStr("x", value);
    }

    function attributeMakeYStr(string memory value)
        private
        pure
        returns (bytes memory)
    {
        return attributeGenericValueStr("y", value);
    }

    function attributeGenericValueStr(
        string memory attributeName,
        string memory value
    ) private pure returns (bytes memory) {
        return abi.encodePacked(attributeName, '="', value, '"');
    }

    function attributeGenericValueBytes(
        string memory attributeName,
        bytes memory value
    ) private pure returns (bytes memory) {
        return abi.encodePacked(attributeName, '="', value, '"');
    }

    // MARK: - Utils

    // Represents a stroke.
    struct Stroke {
        uint32 width;
        LibColor.Color color;
    }

    // Represents a size.
    //
    // Solidity aligns on 256 bits, so we rely on uint128, eventhough
    // sizes are unlikely to be bigger than 32 bits.
    struct Size {
        uint128 width;
        uint128 height;
    }

    // Converts a Size to a string of consecutive arguments.
    // Such as 'width="xxx" height="xxx"'
    function sizeToAttributes(Size memory size)
        private
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                attributeMakeWidthStr(Strings.toString(size.width)),
                " ",
                attributeMakeHeightStr(Strings.toString(size.height))
            );
    }

    // Represents a 2D position.
    struct Position {
        uint32 x;
        uint32 y;
    }

    // Converts a Position to a string of consecutive arguments.
    // Such as 'x="xxx" y="xxx"'
    function positionToAttributes(Position memory pos)
        private
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                attributeMakeXStr(Strings.toString(pos.x)),
                " ",
                attributeMakeYStr(Strings.toString(pos.y))
            );
    }

    // Converts a Position to a string representation of a Point.
    // Such as 'x,y'
    function positionToPointString(Position memory pos)
        private
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                Strings.toString(pos.x),
                " ",
                Strings.toString(pos.y)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

// A contract that is able to request true random numbers from ChainLink.
abstract contract RandomConsumer is VRFConsumerBase {
    // A magic value used to determine whether or not a randomness request is pending.
    uint256 private constant RANDOM_NUMBER_PENDING = type(uint256).max;

    // Documentation available here: https://docs.chain.link/docs/get-a-random-number/

    // Public key against which randomness is generated
    bytes32 private m_link_keyHash;
    // Fee required to fulfill a VRF request
    uint256 private m_link_fee;

    // Maps a requestId to its requester.
    mapping(bytes32 => address) private m_requestIdToSender;
    // Maps a requestId to a specific token.
    mapping(bytes32 => uint256) private m_requestIdToTokenId;
    // Maps a token to a random value.
    // This is useful to determine if a request is pending or completed.
    mapping(uint256 => uint256) private m_tokenIdToRandomValue;

    // MARK: - Events

    event RequestRandomNumber(bytes32 indexed requestId, uint256 tokenId);
    event GeneratedRandomNumber(uint256 indexed tokenId, uint256 number);

    // MARK: - Lifecycle

    constructor(
        address vrfCoordinator,
        address linkToken,
        bytes32 linkKeyHash,
        uint256 linkFee
    ) VRFConsumerBase(vrfCoordinator, linkToken) {
        m_link_keyHash = linkKeyHash;
        m_link_fee = linkFee;
    }

    // MARK: - Randomness

    /**
     * Requests a random number from ChainLink VRF.
     *
     * This method requires the contract to have some ChainLink available.
     */
    function requestRandomNumber(uint256 tokenId) internal {
        require(LINK.balanceOf(address(this)) >= m_link_fee, "Not enough LINK");

        bytes32 requestId = requestRandomness(m_link_keyHash, m_link_fee);

        m_requestIdToSender[requestId] = msg.sender;
        m_requestIdToTokenId[requestId] = tokenId;
        m_tokenIdToRandomValue[tokenId] = RANDOM_NUMBER_PENDING;

        emit RequestRandomNumber(requestId, tokenId);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        address tokenOwner = m_requestIdToSender[requestId];
        uint256 tokenId = m_requestIdToTokenId[requestId];

        // Clean-up temporary mappings
        delete m_requestIdToSender[requestId];
        delete m_requestIdToTokenId[requestId];

        if (randomNumber == RANDOM_NUMBER_PENDING) {
            // Extremely unlikely, but still possible.
            // In that case, fallback to a pseudo-random value.
            randomNumber = generatePseudoRandomWithSeed(uint256(requestId), 0);
        }

        // Store the newly generated value
        m_tokenIdToRandomValue[tokenId] = randomNumber;

        // Complete Mint
        _mustFinishMint(tokenId, tokenOwner);

        _didGenerateRandomNumber(tokenId, randomNumber);
    }

    // MARK: - Hooks

    /**
     * Important: `fulfillRandomness` has a limit of 200k Gas.
     * As hooks are invoked from this method, they should be as lightweight
     * as possible.
     */

    /**
     * Invoked when a mint is required to be completed.
     */
    function _mustFinishMint(uint256 tokenId, address tokenOwner)
        internal
        virtual;

    /**
     * Invoked when a random number has been generated.
     * Overriders **must** re-apply `virtual` and call `super`.
     */
    function _didGenerateRandomNumber(uint256 tokenId, uint256 randomNumber)
        internal
        virtual
    {
        emit GeneratedRandomNumber(tokenId, randomNumber);
    }

    // MARK: - Utilities

    /**
     * Returns whether a number is currently being generated for the
     * provided tokenId.
     */
    function isRandomNumberGenerationPeding(uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return m_tokenIdToRandomValue[tokenId] == RANDOM_NUMBER_PENDING;
    }

    /**
     * Given a `seed`, generate `n` random numbers.
     */
    function expandRandomNumbers(uint256 seed, uint256 n)
        internal
        pure
        returns (uint256[] memory expandedValues)
    {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = deriveRandomNumber(seed, i);
        }
        return expandedValues;
    }

    /**
     * Given a `seed` and a `salt`, derives a new random number.
     */
    function deriveRandomNumber(uint256 seed, uint256 salt)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(seed, salt)));
    }

    /**
     * Generates a pseudo random value, based off a seed and salt.
     * To generate truly random numbers, use ChainLink VRF instead (`requestRandomNumber` method).
     */
    function generatePseudoRandomWithSeed(uint256 seed, uint256 salt)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encode(seed, salt, block.timestamp, block.difficulty)
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../libraries/LibSVG.sol";
import "../libraries/LibSVGBase64.sol";
import "./OpenSeaRepresentable.sol";

// A contract that can be rendered as an on-chain SVG.
abstract contract SVGRepresentable is OpenSeaRepresentable {
    // A mapping of tokenId to SVG.
    mapping(uint256 => bytes) private m_tokenIdToSVG;

    // MARK: - Events

    event DidRefreshAsset(uint256 indexed tokenId);

    // MARK: - Lifecycle

    constructor() {}

    // MARK: - Image generation

    /**
     * Refresh the SVG asset.
     * This method must be called from an external caller.
     *
     * Overriders must re-apply `virtual` and call `super`.
     */
    function computeAsset(uint256 tokenId) public virtual {
        m_tokenIdToSVG[tokenId] = LibSVGBase64.createBase64EncodedURI(
            generateSVG(tokenId)
        );

        emit DidRefreshAsset(tokenId);
    }

    function buildTokenURI(
        uint256 tokenId,
        string memory name,
        string memory description,
        bytes memory attributesElements
    ) internal view returns (string memory) {
        return
            formatTokenURI(
                name,
                description,
                string(m_tokenIdToSVG[tokenId]),
                attributesElements
            );
    }

    /**
     * This is the part that generate the graphics.
     */
    function generateSVG(uint256 tokenId)
        internal
        view
        virtual
        returns (bytes memory);
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
pragma solidity ^0.8.9;

// Color implementation
library LibColor {
    struct Color {
        // Stored as 0xAARRGGBB
        uint32 rawValue;
    }

    // Creates a new Color from its raw value.
    function NewColorFromRaw(uint256 raw) internal pure returns (Color memory) {
        return Color({rawValue: uint32(raw & uint256(0xFFFFFFFF))});
    }

    // Creates a new Color from RGB and Alpha components.
    function NewColor(
        uint8 red,
        uint8 green,
        uint8 blue,
        uint8 alpha
    ) internal pure returns (Color memory) {
        return
            NewColorFromRaw(
                (uint32(alpha) << 24) |
                    (uint32(red) << 16) |
                    (uint32(green) << 8) |
                    (uint32(blue))
            );
    }

    // Gets the Hex representation of the color.
    // The returned value is prefixed by a "#" (ready to be used in HTML-like components).
    function ColorToHexRepresentation(Color memory color)
        internal
        pure
        returns (bytes memory)
    {
        // Ignores 'alpha'.
        return
            abi.encodePacked("#", uint2htmlhexstr(color.rawValue & 0x00ffffff));
    }

    // MARK: - Helpers

    function uint2htmlhexstr(uint256 i) private pure returns (string memory) {
        if (i == 0) {
            return "000000";
        }

        uint256 j = i;
        uint256 length;

        while (j != 0) {
            length++;
            j = j >> 4;
        }

        uint256 mask = 15;
        // At most 6 bytes
        bytes memory bstr = new bytes(6);
        uint256 k = 6;

        while (i != 0) {
            uint256 curr = (i & mask);
            bstr[--k] = curr > 9
                ? bytes1(uint8(55 + curr))
                : bytes1(uint8(48 + curr)); // 55 = 65 - 10
            i = i >> 4;
        }

        while (k > 0) {
            bstr[--k] = "0";
        }

        return string(bstr);
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
pragma solidity ^0.8.9;

import "base64-sol/base64.sol";

// A contract that can be rendered as an on-chain SVG.
library LibSVGBase64 {
    string private constant SVG_BASE64_URL_PREFIX =
        "data:image/svg+xml;base64,";

    /**
     * Create a base64 encoded URI for a SVG.
     */
    function createBase64EncodedURI(bytes memory svg)
        internal
        pure
        returns (bytes memory)
    {
        string memory svgBase64Encoded = Base64.encode(abi.encodePacked(svg));
        return abi.encodePacked(SVG_BASE64_URL_PREFIX, svgBase64Encoded);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../libraries/LibERC721JSONMetadata.sol";

// A contract that is representable as a fully on-chain ERC721, displayable on OpenSea and other
// NFT market places.
//
// The ERC721 inheritence is **not** guaranteed via this contract.
abstract contract OpenSeaRepresentable {
    // MARK: - Lifecycle

    constructor() {}

    function formatTokenURI(
        string memory name,
        string memory description,
        string memory imageURI,
        bytes memory attributesElements
    ) internal pure returns (string memory) {
        return
            LibERC721JSONMetadata.createBase64EncodedURI(
                LibERC721JSONMetadata.createMetadata(
                    name,
                    description,
                    imageURI,
                    attributesElements
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

// A contract that can be rendered as an on-chain SVG.
library LibJSON {
    function wrapInDictionnary(bytes memory content)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked("{", content, "}");
    }

    function wrapInArray(bytes memory content)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked("[", content, "]");
    }

    function makeFieldArray(
        string memory field,
        string memory jsonArray,
        bool isLast
    ) internal pure returns (bytes memory) {
        if (isLast) {
            return abi.encodePacked('"', field, '":', jsonArray);
        }

        return abi.encodePacked('"', field, '":', jsonArray, ",");
    }

    function makeFieldString(
        string memory field,
        string memory value,
        bool isLast
    ) internal pure returns (bytes memory) {
        string memory endingStr = isLast ? '"' : '",';
        return abi.encodePacked('"', field, '":"', value, endingStr);
    }

    function makeFieldNumber(
        string memory field,
        uint256 value,
        bool isLast
    ) internal pure returns (bytes memory) {
        if (isLast) {
            return abi.encodePacked('"', field, '":', Strings.toString(value));
        }

        return abi.encodePacked('"', field, '":', Strings.toString(value), ",");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../utils/Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string public constant ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
            )
        );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(string memory name) internal initializer {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}