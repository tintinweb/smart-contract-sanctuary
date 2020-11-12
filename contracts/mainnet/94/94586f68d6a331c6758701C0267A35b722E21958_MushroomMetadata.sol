// Dependency file: @openzeppelin/contracts-ethereum-package/contracts/introspection/IERC165.sol

// pragma solidity ^0.6.0;

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


// Dependency file: @openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721.sol

// pragma solidity ^0.6.2;

// import "@openzeppelin/contracts-ethereum-package/contracts/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


// Dependency file: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol

// pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


// Dependency file: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

// pragma solidity ^0.6.0;
// import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}


// Dependency file: @openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol

// pragma solidity ^0.6.0;

// import "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";
// import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

    }


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}


// Dependency file: contracts/MushroomLib.sol

// pragma solidity ^0.6.0;

library MushroomLib {
    struct MushroomData {
        uint256 species;
        uint256 strength;
        uint256 lifespan;
    }

    struct MushroomType {
        uint256 id;
        uint256 strength;
        uint256 minLifespan;
        uint256 maxLifespan;
        uint256 minted;
        uint256 cap;
    }
}


// Dependency file: contracts/metadata/resolvers/MetadataResolver.sol

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// import "contracts/MushroomLib.sol";

abstract contract MetadataResolver {
    using MushroomLib for MushroomLib.MushroomData;
    using MushroomLib for MushroomLib.MushroomType;

    function getMushroomData(uint256 index, bytes calldata data) external virtual view returns (MushroomLib.MushroomData memory);
    function setMushroomLifespan(uint256 index, uint256 lifespan, bytes calldata data) external virtual;
    function isBurnable(uint256 index) external view virtual returns (bool);
}


// Root file: contracts/metadata/MushroomMetadata.sol

// import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";

// import "contracts/metadata/resolvers/MetadataResolver.sol";
// import "contracts/MushroomLib.sol";

contract MushroomMetadata is OwnableUpgradeSafe {
    using MushroomLib for MushroomLib.MushroomData;
    using MushroomLib for MushroomLib.MushroomType;

    mapping(address => address) public metadataResolvers;

    event ResolverSet(address nft, address resolver);

    modifier onlyWithMetadataResolver(address nftContract) {
        require(metadataResolvers[nftContract] != address(0), "MetadataRegistry: No resolver set for nft");
        _;
    }

    function hasMetadataResolver(address nftContract) external view returns (bool) {
        return metadataResolvers[nftContract] != address(0);
    }

    function getMetadataResolver(address nftContract) external view returns (address) {
        return metadataResolvers[nftContract];
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function getMushroomData(
        address nftContract,
        uint256 nftIndex,
        bytes calldata data
    ) external view onlyWithMetadataResolver(nftContract) returns (MushroomLib.MushroomData memory) {
        MetadataResolver resolver = MetadataResolver(metadataResolvers[nftContract]);
        MushroomLib.MushroomData memory mushroomData = resolver.getMushroomData(nftIndex, data);
        return mushroomData;
    }

    function isBurnable(
        address nftContract,
        uint256 nftIndex
    ) external view onlyWithMetadataResolver(nftContract) returns (bool) {
        MetadataResolver resolver = MetadataResolver(metadataResolvers[nftContract]);
        return resolver.isBurnable(nftIndex);
    }

    function setMushroomLifespan(
        address nftContract,
        uint256 nftIndex,
        uint256 lifespan,
        bytes calldata data
    ) external onlyWithMetadataResolver(nftContract) {
        MetadataResolver resolver = MetadataResolver(metadataResolvers[nftContract]);
        resolver.setMushroomLifespan(nftIndex, lifespan, data);
    }

    function setResolver(address nftContract, address resolver) public onlyOwner {
        metadataResolvers[nftContract] = resolver;

        emit ResolverSet(nftContract, resolver);
    }
}