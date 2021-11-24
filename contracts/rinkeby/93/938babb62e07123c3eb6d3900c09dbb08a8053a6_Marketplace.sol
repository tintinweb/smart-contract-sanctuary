// SPDX-License-Identifier: MIT

/**
       ###    ##    ## #### ##     ##    ###
      ## ##   ###   ##  ##  ###   ###   ## ##
     ##   ##  ####  ##  ##  #### ####  ##   ##
    ##     ## ## ## ##  ##  ## ### ## ##     ##
    ######### ##  ####  ##  ##     ## #########
    ##     ## ##   ###  ##  ##     ## ##     ##
    ##     ## ##    ## #### ##     ## ##     ##
*/

pragma solidity ^0.8.10;
import "ERC721EnumerableUpgradeable.sol";
import "OwnableUpgradeable.sol";
import "AccessControlEnumerableUpgradeable.sol";
import "StringsUpgradeable.sol";
import "PausableUpgradeable.sol";
interface IERC721 {
    function transfer(address, uint256) external returns (bool);
}

// https://github.com/MaxflowO2/ERC2981/blob/master/contracts/IERC2981.sol

interface IERC2981 {
    // ERC165 bytes to add to interface array - set in parent contract
    // implementing this standard
    //
    // bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    // bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    // _registerInterface(_INTERFACE_ID_ERC2981);

    // @notice Called with the sale price to determine how much royalty
    //  is owed and to whom.
    // @param _tokenId - the NFT asset queried for royalty information
    // @param _salePrice - the sale price of the NFT asset specified by _tokenId
    // @return receiver - address of who should be sent the royalty payment
    // @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

contract OpenSeaMetadata is OwnableUpgradeable {
    string openSeaContractURI;

    function setContractURI(string memory _newContractURI) external onlyOwner {
        openSeaContractURI = _newContractURI;
    }

    function contractURI() public view returns (string memory) {
        return openSeaContractURI;
    }
}

contract Helpers {
    // Calculate base * ratio / scale rounding down.
    // https://ethereum.stackexchange.com/a/79736
    // NOTE: As of solidity 0.8, SafeMath is no longer required
    function percentage(
        uint256 base,
        uint256 ratio,
        uint128 scale
    ) internal pure returns (uint256) {
        uint256 baseDiv = base / scale;
        uint256 baseMod = base % scale;
        uint256 ratioDiv = ratio / scale;
        uint256 ratioMod = ratio % scale;

        return
            (baseDiv * ratioDiv * scale) + (baseDiv * ratioMod) + (baseMod * ratioDiv) + ((baseMod * ratioMod) / scale);
    }
}

contract Marketplace is
    Helpers,
    OwnableUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721EnumerableUpgradeable,
    IERC2981,
    PausableUpgradeable,
    OpenSeaMetadata
{
    //
    // GAP
    // !! This can potentially be used in the future to add new base classes !!
    //

    uint256[50] private __gap;

    //
    // EVENTS
    //

    event Mint(address indexed _recipient, uint256 indexed _tokenId);
    event BridgeMint(address indexed _recipient, uint256 indexed _tokenId);

    //
    // STRUCTS
    //

    struct Project {
        string projectName;
        uint256 maxMintId;
        uint256 notBefore;
        uint256 expires;
        address payable royaltyReceiver;
        uint256 royaltyPercentage; // out of 1000
        string baseTokenMetadataURI;
        bool paused;
        uint256 nextMintId;
    }

    //
    // CONSTANTS
    //

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    uint256 private constant BILLION = 1000000000;
    uint128 private constant ROYALTY_SCALE = 1000;
    string private constant CONTRACT_PAUSED = "CONTRACT_PAUSED";
    string private constant INVALID_PROJECT_ID = "INVALID_PROJECT_ID";
    string private constant INVALID_ROYALTY_PERCENTAGE = "INVALID_ROYALTY_PERCENTAGE";
    string private constant INVALID_EXPIRES = "INVALID_EXPIRES";
    string private constant BURN_DENIED = "BURN_DENIED";

    //
    // STATE VARIABLES
    // !! When adding new state variables in upgrades, make sure to preserve the existing order and add new variables _last_ !!
    //

    uint256 public projectCount;
    mapping(uint256 => Project) projects;
    mapping(uint256 => bool) mintNonces;

    //
    // INITIALIZER FUNCTIONS
    //

    function initialize() public initializer {
        // Note: this is technically not recommended, but the alternative is simply not using multiple inheritance:
        //   https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/README.md
        // Since it seems like this is way better than re-implementing interfaces that already exist,
        //   confirm that all parent contracts are initialized _once_ and in the correct order here
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC721_init_unchained("Anima AR NFTs", "ANIMA");
        __ERC721Enumerable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, owner());

        projectCount = 0;
    }

    //
    // EXTERNAL FUNCTIONS
    //

    receive() external payable {}

    fallback() external {}

    function setPaused(bool _value) external onlyOwner {
        if (_value) {
            _pause();
        } else {
            _unpause();
        }
    }

    function createProject(
        uint128 projectId,
        string memory projectName,
        uint256 maxMintId,
        uint256 notBefore,
        uint256 expires,
        address payable royaltyReceiver,
        uint256 royaltyPercentage,
        string memory baseTokenMetadataURI,
        bool paused
    ) external whenNotPaused onlyRole(ADMIN_ROLE) {
        require(projectId == (projectCount + 1), INVALID_PROJECT_ID);
        require(royaltyPercentage <= ROYALTY_SCALE, INVALID_ROYALTY_PERCENTAGE);
        require(expires == 0 || expires > notBefore, INVALID_EXPIRES);
        Project memory project = Project({
            projectName: projectName,
            maxMintId: maxMintId,
            notBefore: notBefore,
            expires: expires,
            royaltyReceiver: royaltyReceiver,
            royaltyPercentage: royaltyPercentage,
            baseTokenMetadataURI: baseTokenMetadataURI,
            paused: paused,
            nextMintId: 1
        });

        projectCount += 1;
        projects[projectCount] = project;
    }

    function updateProject(
        uint128 projectId,
        string memory projectName,
        uint256 maxMintId,
        uint256 notBefore,
        uint256 expires,
        address payable royaltyReceiver,
        uint256 royaltyPercentage,
        string memory baseTokenMetadataURI,
        bool paused
    ) external whenNotPaused onlyRole(ADMIN_ROLE) {
        require(projectId <= projectCount, INVALID_PROJECT_ID);
        require(royaltyPercentage <= ROYALTY_SCALE, INVALID_ROYALTY_PERCENTAGE);
        require(expires == 0 || expires > notBefore, INVALID_EXPIRES);

        uint256 existingNextMintId = projects[projectId].nextMintId; // Maintain the mint count
        require(maxMintId >= (existingNextMintId - 1), "INVALID_MAX_MINT_ID");

        Project memory project = Project({
            projectName: projectName,
            nextMintId: existingNextMintId,
            maxMintId: maxMintId,
            notBefore: notBefore,
            expires: expires,
            royaltyReceiver: royaltyReceiver,
            royaltyPercentage: royaltyPercentage,
            baseTokenMetadataURI: baseTokenMetadataURI,
            paused: paused
        });

        projects[projectId] = project;
    }

    // Mint from ANIMA
    function mintAnima(
        uint256 _nonce,
        address _recipient,
        uint128 _projectId,
        uint256 _count
    ) public whenNotPaused onlyRole(MINTER_ROLE) {
        require(mintNonces[_nonce] != true, "DUPLICATE_NONCE");
        require(_count > 0, "INVALID_TOKEN_COUNT");
        require(_projectId <= projectCount, INVALID_PROJECT_ID);
        require(block.timestamp > projects[_projectId].notBefore, "PROJECT_NOT_ACTIVE");
        require(projects[_projectId].expires <= 0 || block.timestamp < projects[_projectId].expires, "PROJECT_EXPIRED");
        require(!projects[_projectId].paused, "PROJECT_PAUSED");

        mintNonces[_nonce] = true;

        for (uint256 i = 0; i < _count; i++) {
            require(projects[_projectId].maxMintId >= projects[_projectId].nextMintId, "MAX_MINTS");
            uint256 mintId = projects[_projectId].nextMintId;
            require(mintId > 0, "NO_MINT_ZERO");
            uint256 tokenId = (_projectId * BILLION) + mintId;
            _safeMint(_recipient, tokenId);
            projects[_projectId].nextMintId += 1;
            emit Mint(_recipient, tokenId);
        }
    }

    // Mint from Palm bridge
    function mint(
        address _recipient,
        uint256 _tokenId,
        string calldata
    ) external whenNotPaused onlyRole(BRIDGE_ROLE) {
        _safeMint(_recipient, _tokenId);
        emit Mint(_recipient, _tokenId);
    }

    function burn(uint256 _tokenId) public virtual whenNotPaused {
        require(msg.sender == ownerOf(_tokenId) || hasRole(BRIDGE_ROLE, msg.sender), BURN_DENIED);
        _burn(_tokenId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 projectId = _tokenId / BILLION;
        require(projectId <= projectCount, INVALID_PROJECT_ID);

        return (
            projects[projectId].royaltyReceiver,
            percentage(_salePrice, projects[projectId].royaltyPercentage, ROYALTY_SCALE)
        );
    }

    //
    // PUBLIC FUNCTIONS
    //

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return _interfaceId == type(IERC2981).interfaceId || super.supportsInterface(_interfaceId);
    }

    /**
     * @dev Returns a URI for a given token ID's metadata
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        uint256 projectId = _tokenId / BILLION;
        require(projectId <= projectCount, INVALID_PROJECT_ID);
        return
            string(abi.encodePacked(projects[projectId].baseTokenMetadataURI, StringsUpgradeable.toString(_tokenId)));
    }

    function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 balance = ERC721Upgradeable.balanceOf(_owner);
        uint256[] memory tokens = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokens[i] = ERC721EnumerableUpgradeable.tokenOfOwnerByIndex(_owner, i);
        }
        return tokens;
    }

    //
    // INTERNAL FUNCTIONS
    //

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
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            require(hasRole(MINTER_ROLE, msg.sender) || hasRole(BRIDGE_ROLE, msg.sender), "MINT_DENIED");
        }

        if (to == address(0)) {
            require(msg.sender == from || hasRole(BRIDGE_ROLE, msg.sender), BURN_DENIED);
        }
    }
}