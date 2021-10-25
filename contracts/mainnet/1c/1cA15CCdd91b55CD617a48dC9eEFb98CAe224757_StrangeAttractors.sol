// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

import "./solvers/IAttractorSolver.sol";
import "./renderers/ISvgRenderer.sol";
import "./utils/BaseOpenSea.sol";
import "./utils/ERC2981SinglePercentual.sol";
import "./utils/SignedSlotRestrictable.sol";
import "./utils/ColorMixer.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @notice Fully on-chain interactive NFT project performing numerical
 * simulations of chaotic, multi-dimensional _systems.
 * @dev This contract implements tokenonmics of the project, conforming to the
 * ERC721 and ERC2981 standard.
 * @author David Huber (@cxkoda)
 */
contract StrangeAttractors is
    BaseOpenSea,
    SignedSlotRestrictable,
    ERC2981SinglePercentual,
    ERC721Enumerable,
    Ownable,
    PullPayment
{
    /**
     * @notice Maximum number of editions per system.
     */
    uint8 private constant MAX_PER_SYSTEM = 128;

    /**
     * @notice Max number that the contract owner can mint in a specific system.
     * @dev The contract assumes that the owner mints the first pieces.
     */
    uint8 private constant OWNER_ALLOCATION = 2;

    /**
     * @notice Mint price
     */
    uint256 public constant MINT_PRICE = (35 ether) / 100;

    /**
     * @notice Contains the configuration of a given _systems in the collection.
     */
    struct AttractorSystem {
        string description;
        uint8 numLeftForMint;
        bool locked;
        ISvgRenderer renderer;
        uint8 defaultRenderSize;
        uint32[] defaultColorAnchors;
        IAttractorSolver solver;
        SolverParameters solverParameters;
    }

    /**
     * @notice Systems in the collection.
     * @dev Convention: The first system is the fullset system.
     */
    AttractorSystem[] private _systems;

    /**
     * @notice Token configuration
     */
    struct Token {
        uint8 systemId;
        bool usedForFullsetToken;
        bool useDefaultColors;
        bool useDefaultProjection;
        uint8 renderSize;
        uint256 randomSeed;
        ProjectionParameters projectionParameters;
        uint32[] colorAnchors;
    }

    /**
     * @notice All existing _tokens
     * @dev Maps tokenId => token configuration
     */
    mapping(uint256 => Token) private _tokens;

    // -------------------------------------------------------------------------
    //
    //  Collection setup
    //
    // -------------------------------------------------------------------------

    /**
     * @notice Contract constructor
     * @dev Sets the owner as default 10% royalty receiver.
     */
    constructor(
        string memory name,
        string memory symbol,
        address slotSigner,
        address openSeaProxyRegistry
    ) ERC721(name, symbol) {
        if (openSeaProxyRegistry != address(0)) {
            _setOpenSeaRegistry(openSeaProxyRegistry);
        }
        _setRoyaltyReceiver(owner());
        _setRoyaltyPercentage(1000);
        _setSlotSigner(slotSigner);
    }

    /**
     * @notice Adds a new attractor system to the collection
     * @dev This is used to set up the collection after contract deployment.
     * If `systemId` is a valid ID, the corresponding, existing system will
     * be overwritten. Otherwise a new system will be added.
     * Further system modification is prevented if the system is locked.
     * Both adding and modifying were merged in this single method to avoid
     * hitting the contract size limit.
     */
    function newAttractorSystem(
        string calldata description,
        address solver,
        SolverParameters calldata solverParameters,
        address renderer,
        uint32[] calldata defaultColorAnchors,
        uint8 defaultRenderSize,
        uint256 systemId
    ) external onlyOwner {
        AttractorSystem memory system = AttractorSystem({
            numLeftForMint: MAX_PER_SYSTEM,
            description: description,
            locked: false,
            solver: IAttractorSolver(solver),
            solverParameters: solverParameters,
            renderer: ISvgRenderer(renderer),
            defaultColorAnchors: defaultColorAnchors,
            defaultRenderSize: defaultRenderSize
        });
        if (systemId < _systems.length) {
            require(!_systems[systemId].locked, "System locked");
            system.numLeftForMint = _systems[systemId].numLeftForMint;
            _systems[systemId] = system;
        } else {
            _systems.push(system);
        }
    }

    /**
     * @notice Locks a system against further modifications.
     */
    function lockSystem(uint8 systemId) external onlyOwner {
        _systems[systemId].locked = true;
    }

    // -------------------------------------------------------------------------
    //
    //  Minting
    //
    // -------------------------------------------------------------------------

    function setSlotSigner(address signer) external onlyOwner {
        _setSlotSigner(signer);
    }

    /**
     * @notice Enable or disable the slot restriction for minting.
     */
    function setSlotRestriction(bool enabled) external onlyOwner {
        _setSlotRestriction(enabled);
    }

    /**
     * @notice Interface to mint the remaining owner allocated pieces.
     * @dev This has to be executed before anyone else has minted.
     */
    function safeMintOwner() external onlyOwner {
        bool mintedSomething = false;
        for (uint8 systemId = 1; systemId < _systems.length; systemId++) {
            for (
                ;
                MAX_PER_SYSTEM - _systems[systemId].numLeftForMint <
                OWNER_ALLOCATION;

            ) {
                _safeMintInAttractor(systemId);
                mintedSomething = true;
            }
        }

        // To get some feedback if there are no pieces left for the owner.
        require(mintedSomething, "Owner allocation exhausted.");
    }

    /**
     * @notice Mint interface for regular users.
     * @dev Mints one edition piece from a randomly selected system. The
     * The probability to mint a given system is proportional to the available
     * editions.
     */
    function safeMintRegularToken(uint256 nonce, bytes calldata signature)
        external
        payable
    {
        require(msg.value == MINT_PRICE, "Invalid payment.");
        _consumeSlotIfEnabled(_msgSender(), nonce, signature);
        _asyncTransfer(owner(), msg.value);

        // Check how many _tokens there are left in total.
        uint256 numAvailableTokens = 0;
        for (uint8 idx = 1; idx < _systems.length; ++idx) {
            numAvailableTokens += _systems[idx].numLeftForMint;
        }

        if (numAvailableTokens > 0) {
            // Draw a pseudo-random number in [0, numAvailableTokens) that
            // determines which system to mint.
            uint256 rand = _random(numAvailableTokens) % numAvailableTokens;

            // Check in which bracket `rand` is and mint an edition of the
            // corresponding system
            for (uint8 idx = 1; idx < _systems.length; ++idx) {
                if (rand < _systems[idx].numLeftForMint) {
                    _safeMintInAttractor(idx);
                    return;
                } else {
                    rand -= _systems[idx].numLeftForMint;
                }
            }
        }

        revert("All _systems sold out");
    }

    /**
     * @notice Interface to mint a special token for fullset holders.
     * @dev The sender needs to supply one unused token of every regular
     * system.
     */
    function safeMintFullsetToken(uint256[4] calldata tokenIds)
        external
        onlyApprovedOrOwner(tokenIds[0])
        onlyApprovedOrOwner(tokenIds[1])
        onlyApprovedOrOwner(tokenIds[2])
        onlyApprovedOrOwner(tokenIds[3])
    {
        require(isFullsetMintEnabled, "Fullset mint is disabled.");

        bool[4] memory containsSystem = [false, false, false, false];
        for (uint256 idx = 0; idx < 4; ++idx) {
            // Check if already used
            require(
                !_tokens[tokenIds[idx]].usedForFullsetToken,
                "Token already used."
            );

            // Set an ok flag if a given system was found
            containsSystem[_getTokenSystemId(tokenIds[idx]) - 1] = true;

            // Mark as used
            _tokens[tokenIds[idx]].usedForFullsetToken = true;
        }

        // Check if all _systems are present
        require(
            containsSystem[0] &&
                containsSystem[1] &&
                containsSystem[2] &&
                containsSystem[3],
            "Tokens of each system required"
        );

        uint256 tokenId = _safeMintInAttractor(0);

        // Although we technically  don't need to set this flag onr the fullset
        // system, let's set it anyways to display the correct value in
        // `tokenURI`.
        _tokens[tokenId].usedForFullsetToken = true;
    }

    /**
     * @notice Flag for enabling fullset token minting.
     */
    bool public isFullsetMintEnabled = false;

    /**
     * @notice Toggles the ability to mint fullset _tokens.
     */
    function enableFullsetMint(bool enable) external onlyOwner {
        isFullsetMintEnabled = enable;
    }

    /**
     * @dev Mints the next token in the system.
     */
    function _safeMintInAttractor(uint8 systemId)
        internal
        returns (uint256 tokenId)
    {
        require(systemId < _systems.length, "Mint in non-existent system.");
        require(
            _systems[systemId].numLeftForMint > 0,
            "System capacity exhausted"
        );

        tokenId =
            (systemId * _tokenIdSystemMultiplier) +
            (MAX_PER_SYSTEM - _systems[systemId].numLeftForMint);

        _tokens[tokenId] = Token({
            systemId: systemId,
            randomSeed: _random(tokenId),
            projectionParameters: ProjectionParameters(
                new int256[](0),
                new int256[](0),
                new int256[](0)
            ),
            colorAnchors: new uint32[](0),
            usedForFullsetToken: false,
            useDefaultColors: true,
            useDefaultProjection: true,
            renderSize: _systems[systemId].defaultRenderSize
        });
        _systems[systemId].numLeftForMint--;

        _safeMint(_msgSender(), tokenId);
    }

    /**
     * @notice Defines the system prefix in the `tokenId`.
     * @dev Convention: The `tokenId` will be given by
     * `edition + _tokenIdSystemMultiplier * systemId`
     */
    uint256 private constant _tokenIdSystemMultiplier = 1e3;

    /**
     * @notice Retrieves the `systemId` from a given `tokenId`.
     */
    function _getTokenSystemId(uint256 tokenId) internal pure returns (uint8) {
        return uint8(tokenId / _tokenIdSystemMultiplier);
    }

    /**
     * @notice Retrieves the `edition` from a given `tokenId`.
     */
    function _getTokenEdition(uint256 tokenId) internal pure returns (uint8) {
        return uint8(tokenId % _tokenIdSystemMultiplier);
    }

    /**
     * @notice Draw a pseudo-random number.
     * @dev Although the drawing can be manipulated with this implementation,
     * it is sufficiently fair for the given purpose.
     * Multiple evaluations on the same block with the same `modSeed` from the
     * same sender will yield the same random numbers.
     */
    function _random(uint256 modSeed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, _msgSender(), modSeed)
                )
            );
    }

    /**
     * @notice Re-draw a _tokens `randomSeed`.
     * @dev This is implemented as a last resort if a _tokens `randomSeed`
     * produces starting values that do not converge to the attractor.
     * Although this never happened while testing, you never know for sure
     * with random numbers.
     */
    function rerollTokenRandomSeed(uint256 tokenId) external onlyOwner {
        _tokens[tokenId].randomSeed = _random(_tokens[tokenId].randomSeed);
    }

    // -------------------------------------------------------------------------
    //
    //  Rendering
    //
    // -------------------------------------------------------------------------

    /**
     * @notice Assembles the name of a token
     * @dev Composed of the system name provided by the solver and the tokens
     * edition number. The returned string has been escapted for usage in
     * data-uris.
     */
    function getTokenName(uint256 tokenId) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _systems[_getTokenSystemId(tokenId)].solver.getSystemType(),
                    // " #",
                    " %23", // Uri encoded
                    Strings.toString(_getTokenEdition(tokenId))
                )
            );
    }

    /**
     * @notice Renders a given token with externally supplied parameters.
     * @return The svg string.
     */
    function renderWithConfig(
        uint256 tokenId,
        ProjectionParameters memory projectionParameters,
        uint32[] memory colorAnchors,
        uint8 renderSize
    ) public view returns (string memory) {
        AttractorSystem storage system = _systems[_getTokenSystemId(tokenId)];

        return
            system.renderer.render(
                system.solver.computeSolution(
                    system.solverParameters,
                    system.solver.getRandomStartingPoint(
                        _tokens[tokenId].randomSeed
                    ),
                    projectionParameters
                ),
                ColorMixer.getColormap(colorAnchors),
                renderSize
            );
    }

    /**
     * @notice Returns the `ProjectionParameters` for a given token.
     * @dev Checks if default settings are used and computes them if needed.
     */
    function getProjectionParameters(uint256 tokenId)
        public
        view
        returns (ProjectionParameters memory)
    {
        if (_tokens[tokenId].useDefaultProjection) {
            return
                _systems[_getTokenSystemId(tokenId)]
                    .solver
                    .getDefaultProjectionParameters(_getTokenEdition(tokenId));
        } else {
            return _tokens[tokenId].projectionParameters;
        }
    }

    /**
     * @notice Returns the `colormap` for a given token.
     * @dev Checks if default settings are used and retrieves them if needed.
     */
    function getColorAnchors(uint256 tokenId)
        public
        view
        returns (uint32[] memory colormap)
    {
        if (_tokens[tokenId].useDefaultColors) {
            return _systems[_getTokenSystemId(tokenId)].defaultColorAnchors;
        } else {
            return _tokens[tokenId].colorAnchors;
        }
    }

    /**
     * @notice Returns data URI of token metadata.
     * @dev The output conforms to the Opensea attributes metadata standard.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        AttractorSystem storage system = _systems[_getTokenSystemId(tokenId)];

        bytes memory data = abi.encodePacked(
            'data:application/json,{"name":"',
            getTokenName(tokenId),
            '",',
            '"description":"',
            system.description,
            '","attributes":[{"trait_type": "System","value":"',
            system.solver.getSystemType(),
            '"},{"trait_type": "Random Seed", "value":"',
            Strings.toHexString(_tokens[tokenId].randomSeed)
        );

        if (isFullsetMintEnabled) {
            data = abi.encodePacked(
                data,
                '"},{"trait_type": "Dimensions", "value":"',
                Strings.toString(system.solver.getDimensionality()),
                '"},{"trait_type": "Completed", "value":"',
                _tokens[tokenId].usedForFullsetToken ? "Yes" : "No"
            );
        }

        return
            string(
                abi.encodePacked(
                    data,
                    '"}],"image":"data:image/svg+xml,',
                    renderWithConfig(
                        tokenId,
                        getProjectionParameters(tokenId),
                        getColorAnchors(tokenId),
                        _tokens[tokenId].renderSize
                    ),
                    '"}'
                )
            );
    }

    // -------------------------------------------------------------------------
    //
    //  Token interaction
    //
    // -------------------------------------------------------------------------

    /**
     * @notice Set the projection parameters for a given token.
     */
    function setProjectionParameters(
        uint256 tokenId,
        ProjectionParameters calldata projectionParameters
    ) external onlyApprovedOrOwner(tokenId) {
        require(
            _systems[_getTokenSystemId(tokenId)]
                .solver
                .isValidProjectionParameters(projectionParameters),
            "Invalid projection parameters"
        );

        _tokens[tokenId].projectionParameters = projectionParameters;
        _tokens[tokenId].useDefaultProjection = false;
    }

    /**
     * @notice Set or reset the color anchors for a given token.
     * @dev To revert to the _systems default, `colorAnchors` has to be empty.
     * On own method for resetting was omitted to remain below the contract size
     * limit.
     * See `ColorMixer` for more details on the color system.
     */
    function setColorAnchors(uint256 tokenId, uint32[] calldata colorAnchors)
        external
        onlyApprovedOrOwner(tokenId)
    {
        // Lets restrict this to something sensible.
        require(
            colorAnchors.length > 0 && colorAnchors.length <= 64,
            "Invalid amount of color anchors."
        );
        _tokens[tokenId].colorAnchors = colorAnchors;
        _tokens[tokenId].useDefaultColors = false;
    }

    /**
     * @notice Set the rendersize for a given token.
     */
    function setRenderSize(uint256 tokenId, uint8 renderSize)
        external
        onlyApprovedOrOwner(tokenId)
    {
        _tokens[tokenId].renderSize = renderSize;
    }

    /**
     * @notice Reset various rendering parameters for a given token.
     * @dev Setting the individual flag to true resets the associated parameters.
     */
    function resetRenderParameters(
        uint256 tokenId,
        bool resetProjectionParameters,
        bool resetColorAnchors,
        bool resetRenderSize
    ) external onlyApprovedOrOwner(tokenId) {
        if (resetProjectionParameters) {
            _tokens[tokenId].useDefaultProjection = true;
        }
        if (resetColorAnchors) {
            _tokens[tokenId].useDefaultColors = true;
        }
        if (resetRenderSize) {
            _tokens[tokenId].renderSize = _systems[_getTokenSystemId(tokenId)]
                .defaultRenderSize;
        }
    }

    // -------------------------------------------------------------------------
    //
    //  External getters, metadata and steering
    //
    // -------------------------------------------------------------------------

    /**
     * @notice Retrieve a system with a given ID.
     * @dev This was necessay because for some reason the default public getter
     * does not return `defaultColorAnchors` correctly.
     */
    function systems(uint8 systemId)
        external
        view
        returns (AttractorSystem memory)
    {
        return _systems[systemId];
    }

    /**
     * @notice Retrieve a token with a given ID.
     * @dev This was necessay because for some reason the default public getter
     * does not return `colorAnchors` correctly.
     */
    function tokens(uint256 tokenId) external view returns (Token memory) {
        return _tokens[tokenId];
    }

    /**
     * @dev Sets the royalty percentage (in units of 0.01%)
     */
    function setRoyaltyPercentage(uint256 percentage) external onlyOwner {
        _setRoyaltyPercentage(percentage);
    }

    /**
     * @dev Sets the address to receive the royalties
     */
    function setRoyaltyReceiver(address receiver) external onlyOwner {
        _setRoyaltyReceiver(receiver);
    }

    // -------------------------------------------------------------------------
    //
    //  Internal stuff
    //
    // -------------------------------------------------------------------------

    /**
     * @dev Approves the opensea proxy for token transfers.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return
            super.isApprovedForAll(owner, operator) ||
            isOwnersOpenSeaProxy(owner, operator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Neither owner nor approved for this token"
        );
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

import "./AttractorSolution.sol";

/**
 * @notice Parameters going to the numerical ODE solver.
 * @param numberOfIterations Total number of iterations.
 * @param dt Timestep increment in each iteration
 * @param skip Amount of iterations between storing two points.
 * @dev `numberOfIterations` has to be dividable without rest by `skip`.
 */
struct SolverParameters {
    uint256 numberOfIterations;
    uint256 dt;
    uint8 skip;
}

/**
 * @notice Parameters going to the projection routines.
 * @dev The lengths of all fields have to match the dimensionality of the
 * considered system.
 * @param axis1 First projection axis (horizontal image coordinate)
 * @param axis2 Second projection axis (vertical image coordinate)
 * @param offset Offset applied before projecting.
 */
struct ProjectionParameters {
    int256[] axis1;
    int256[] axis2;
    int256[] offset;
}

/**
 * @notice Starting point for the numerical simulation
 * @dev The length of the starting point has to match the dimensionality of the
 * considered system.
 * I agree, this struct looks kinda dumb, but I really like speaking types.
 * So as long as we don't have typedefs for non-elementary types, we are stuck
 * with this cruelty.
 */
struct StartingPoint {
    int256[] startingPoint;
}

/**
 * @notice Interface for simulators of chaotic systems.
 * @dev Implementations of this interface will contain the mathematical
 * description of the underlying differential equations, deal with its numerical
 * solution and the 2D projection of the results.
 * Implementations will internally use fixed-point numbers with a precision of
 * 96 bits by convention.
 * @author David Huber (@cxkoda)
 */
interface IAttractorSolver {
    /**
     * @notice Simulates the evolution of a chaotic system.
     * @dev This is the core piece of this class that performs everything
     * at once. All relevant algorithm for the evaluation of the ODEs
     * the numerical scheme, the projection and storage are contained within
     * this method for performance reasons.
     * @return An `AttractorSolution` containing already projected 2D points
     * and tangents to them.
     */
    function computeSolution(
        SolverParameters calldata,
        StartingPoint calldata,
        ProjectionParameters calldata
    ) external pure returns (AttractorSolution memory);

    /**
     * @notice Generates a random starting point for the system.
     */
    function getRandomStartingPoint(uint256 randomSeed)
        external
        view
        returns (StartingPoint memory);

    /**
     * @notice Generates the default projection for a given edition of the
     * system.
     */
    function getDefaultProjectionParameters(uint256 editionId)
        external
        view
        returns (ProjectionParameters memory);

    /**
     * @notice Returns the type/name of the dynamical system.
     */
    function getSystemType() external pure returns (string memory);

    /**
     * @notice Returns the dimensionality of the dynamical system (number of
     * ODEs).
     */
    function getDimensionality() external pure returns (uint8);

    /**
     * @notice Returns the precision of the internally used fixed-point numbers.
     * @dev The solvers operate on fixed-point numbers with a given PRECISION,
     * i.e. the amount of bits reserved for decimal places.
     * By convention, this method will return 96 throughout the project.
     */
    function getFixedPointPrecision() external pure returns (uint8);

    /**
     * @notice Checks if given `ProjectionParameters` are valid`
     */
    function isValidProjectionParameters(ProjectionParameters memory)
        external
        pure
        returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

import "../solvers/AttractorSolution.sol";

/**
 * @notice Renders a solution of an attractor simulation as SVG
 * @author David Huber (@cxkoda)
 */
interface ISvgRenderer {
    /**
     * @notice Renders a list of 2D points and tangents as svg
     * @param solution List of 16-bit fixed-point points and tangents. 
     * See `AttractorSolution`.
     * @param colormap 256 8-bit RGB colors. Leaving this in memory for easier
     * access in assembly later.
     * @param markerSize A modifier for marker sizes (e.g. stroke width, 
     * point size)
     * @return The generated svg string. The viewport covers the area 
     * [-64, 64] x [-64, 64] by convention.
     */
    function render(
        AttractorSolution calldata solution,
        bytes memory colormap,
        uint8 markerSize
    ) external pure returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://gist.github.com/dievardump/483eb43bc6ed30b14f01e01842e3339b/

/// @title OpenSea contract helper that defines a few things
/// @author Simon Fremaux (@dievardump)
/// @dev This is a contract used to add OpenSea's support for gas-less trading
///      by checking if operator is owner's proxy
contract BaseOpenSea {
    string private _contractURI;
    ProxyRegistry private _proxyRegistry;

    /// @notice Returns the contract URI function. Used on OpenSea to get details
    ///         about a contract (owner, royalties etc...)
    ///         See documentation: https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Helper for OpenSea gas-less trading
    /// @dev Allows to check if `operator` is owner's OpenSea proxy
    /// @param owner the owner we check for
    /// @param operator the operator (proxy) we check for
    function isOwnersOpenSeaProxy(address owner, address operator)
        public
        view
        returns (bool)
    {
        ProxyRegistry proxyRegistry = _proxyRegistry;
        return
            // we have a proxy registry address
            address(proxyRegistry) != address(0) &&
            // current operator is owner's proxy address
            address(proxyRegistry.proxies(owner)) == operator;
    }

    /// @dev Internal function to set the _contractURI
    /// @param contractURI_ the new contract uri
    function _setContractURI(string memory contractURI_) internal {
        _contractURI = contractURI_;
    }

    /// @dev Internal function to set the _proxyRegistry
    /// @param proxyRegistryAddress the new proxy registry address
    function _setOpenSeaRegistry(address proxyRegistryAddress) internal {
        _proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: MIT
// Copyright 2021 David Huber (@cxkoda)

pragma solidity >=0.8.0 <0.9.0;

import "./ERC2981.sol";

/**
 * @notice ERC2981 royalty info implementation for a single beneficiary
 * receving a percentage of sales prices.
 * @author David Huber (@cxkoda)
 */
contract ERC2981SinglePercentual is ERC2981 {
    /**
     * @dev The royalty percentage (in units of 0.01%)
     */
    uint256 _percentage;

    /**
     * @dev The address to receive the royalties
     */
    address _receiver;

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        royaltyAmount = (salePrice / 10000) * _percentage;
        receiver = _receiver;
    }

    /**
     * @dev Sets the royalty percentage (in units of 0.01%)
     */
    function _setRoyaltyPercentage(uint256 percentage_) internal {
        _percentage = percentage_;
    }

    /**
     * @dev Sets the address to receive the royalties
     */
    function _setRoyaltyReceiver(address receiver_) internal {
        _receiver = receiver_;
    }
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @notice Impements consumable slots that can be used to restrict e.g. minting.
 * @dev Intended as parent class for consumer contracts.
 * The slot allocation is based on signing associated messages off-chain, which
 * contain the grantee, the signer and a nonce. The contract checks whether the
 * slot is still valid and invalidates it after consumption.
 * @author David Huber (@cxkoda)
 */
contract SignedSlotRestrictable {
    // this is because minting is secured with a Signature
    using ECDSA for bytes32;

    /**
     * @dev Flag for whether the restriction should be enforced or not.
     */
    bool private _isSlotRestricted = true;

    /**
     * @dev List of already used/consumed slot messages
     */
    mapping(bytes32 => bool) private _usedMessages;

    /**
     * @dev The address that signes the slot messages.
     */
    address private _signer;

    /**
     * @notice Checks if the restriction if active
     */
    function isSlotRestricted() public view returns (bool) {
        return _isSlotRestricted;
    }

    /**
     * @notice Actives/Disactivates the restriction
     */
    function _setSlotRestriction(bool enable) internal {
        _isSlotRestricted = enable;
    }

    /**
     * @notice Changes the signing address.
     * @dev Changing the signer renders not yet consumed slots unconsumable.
     */
    function _setSlotSigner(address signer_) internal {
        _signer = signer_;
    }

    /**
     * @notice Helper that creates the message that signer needs to sign to
     * approve the slot.
     */
    function createSlotMessage(address grantee, uint256 nonce)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(grantee, nonce, _signer, address(this)));
    }

    /**
     * @notice Checks if a given slot is still valid.
     */
    function isValidSlot(
        address grantee,
        uint256 nonce,
        bytes memory signature
    ) external view returns (bool) {
        bytes32 message = createSlotMessage(grantee, nonce);
        return ((!_usedMessages[message]) &&
            (message.toEthSignedMessageHash().recover(signature) == _signer));
    }

    /**
     * @notice Consumes a slot for a given user if the restriction is enabled.
     * @dev Intended to be called before the action to be restricted.
     * Validates the signature and checks if the slot was already used before.
     */
    function _consumeSlotIfEnabled(
        address grantee,
        uint256 nonce,
        bytes memory signature
    ) internal {
        if (_isSlotRestricted) {
            bytes32 message = createSlotMessage(grantee, nonce);
            require(!_usedMessages[message], "Slot already used");
            require(
                message.toEthSignedMessageHash().recover(signature) == _signer,
                "Invalid slot signature"
            );
            _usedMessages[message] = true;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice Interpolation between ColorAnchors to generate a colormap.
 * @dev A color anchor is encoded composed of four uint8 numbers in the order
 * `colorAnchor = | red | green | blue | position |`. Every `uint32` typed 
 * variable in the following code will correspond to such anchors, while 
 * `uint24`s correspond to rgb colors.
 * @author David Huber (@cxkoda)
 */
library ColorMixer {
    /**
     * @dev The internal fixed-point accuracy
     */
    uint8 private constant PRECISION = 32;
    uint256 private constant ONE = 2**32;

    /**
     * @notice Interpolate linearily between two colors.
     * @param fraction Fixed-point number in [0,1] giving the relative
     * contribution of `left` (0) and `right` (1).
     * The interpolation follows the equation 
     * `color = fraction * right + (1 - fraction) * left`.
     */
    function interpolate(
        uint24 left,
        uint24 right,
        uint256 fraction
    ) internal pure returns (uint24 color) {
        assembly {
            color := shr(
                PRECISION,
                add(
                    mul(fraction, and(shr(16, right), 0xff)),
                    mul(sub(ONE, fraction), and(shr(16, left), 0xff))
                )
            )
            color := add(
                shl(8, color),
                shr(
                    PRECISION,
                    add(
                        mul(fraction, and(shr(8, right), 0xff)),
                        mul(sub(ONE, fraction), and(shr(8, left), 0xff))
                    )
                )
            )
            color := add(
                shl(8, color),
                shr(
                    PRECISION,
                    add(
                        mul(fraction, and(right, 0xff)),
                        mul(sub(ONE, fraction), and(left, 0xff))
                    )
                )
            )
        }
    }

    /**
     * @notice Generate a colormap from a list of anchors.
     * @dev Anchors have to be sorted by position.
     */
    function getColormap(uint32[] calldata anchors)
        external
        pure
        returns (bytes memory colormap)
    {
        require(anchors.length > 0);
        colormap = new bytes(768);
        uint256 offset = 0;
        // Left extrapolation (below the leftmost anchor)
        {
            uint32 anchor = anchors[0];
            uint8 anchorPos = uint8(anchor & 0xff);
            for (uint32 position = 0; position < anchorPos; position++) {
                colormap[offset++] = bytes1(uint8((anchor >> 24) & 0xff));
                colormap[offset++] = bytes1(uint8((anchor >> 16) & 0xff));
                colormap[offset++] = bytes1(uint8((anchor >> 8) & 0xff));
            }
        }
        // Interpolation
        if (anchors.length > 1) {
            for (uint256 idx = 0; idx < anchors.length - 1; idx++) {
                uint32 left = anchors[idx];
                uint32 right = anchors[idx + 1];
                uint8 leftPosition = uint8(left & 0xff);
                uint8 rightPosition = uint8(right & 0xff);

                if (leftPosition == rightPosition) {
                    continue;
                }
                
                uint256 rangeInv = ONE / (rightPosition - leftPosition);
                for (
                    uint256 position = leftPosition;
                    position < rightPosition;
                    position++
                ) {
                    uint256 fraction = (position - leftPosition) * rangeInv;
                    uint32 interpolated = interpolate(
                        uint24(left >> 8),
                        uint24(right >> 8),
                        fraction
                    );
                    colormap[offset++] = bytes1(
                        uint8((interpolated >> 16) & 0xff)
                    );
                    colormap[offset++] = bytes1(
                        uint8((interpolated >> 8) & 0xff)
                    );
                    colormap[offset++] = bytes1(uint8(interpolated & 0xff));
                }
            }
        }
        // Right extrapolation (above the rightmost anchor)
        {
            uint32 anchor = anchors[anchors.length - 1];
            uint8 anchorPos = uint8(anchor & 0xff);
            for (uint256 position = anchorPos; position < 256; position++) {
                colormap[offset++] = bytes1(uint8((anchor >> 24) & 0xff));
                colormap[offset++] = bytes1(uint8((anchor >> 16) & 0xff));
                colormap[offset++] = bytes1(uint8((anchor >> 8) & 0xff));
            }
        }
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

import "../utils/escrow/Escrow.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPayment {
    Escrow private immutable _escrow;

    constructor() {
        _escrow = new Escrow();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{value: amount}(dest);
    }
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

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice The data struct that will be passed from the solver to the renderer.
 * @dev `points` and `tangents` both contain pairs of 16-bit fixed-point numbers
 * with a PRECISION of 6 in row-major order.`dt` is given in the fixed-point
 * respresentation used by the solvers and corresponds to the time step between 
 * the datapoints.
 */
struct AttractorSolution {
    bytes points;
    bytes tangents;
    uint256 dt;
}

// SPDX-License-Identifier: MIT
// Copyright 2021 David Huber (@cxkoda)

pragma solidity >=0.8.0 <0.9.0;

import "./IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @notice ERC2981 royalty info base contract
 * @dev Implements `supportsInterface`
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 * @author Taken from https://eips.ethereum.org/EIPS/eip-2981
 */
interface IERC2981 is IERC165 {
    /**
     * @notice Called with the sale price to determine how much royalty
     * is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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

import "../../access/Ownable.sol";
import "../Address.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract Escrow is Ownable {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
    }
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