// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "../utils/Ownable.sol";
import "../utils/ContractKeys.sol";

/**
 * @title  NftTypeRegistry
 * @author NFTfi
 * @dev Registry for NFT Types supported by NFTfi.
 * Each NFT type is associated with the address of an NFT wrapper contract.
 */
contract NftTypeRegistry is Ownable {
    /* ******* */
    /* STORAGE */
    /* ******* */

    mapping(bytes32 => address) private nftTypes;

    /* ****** */
    /* EVENTS */
    /* ****** */

    /**
     * @notice This event is fired whenever the admins register a ntf type.
     *
     * @param nftType - Nft type represented by keccak256('nft type').
     * @param nftWrapper - Address of the wrapper contract.
     */
    event TypeUpdated(bytes32 indexed nftType, address indexed nftWrapper);

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    /**
     * @notice Sets the admin of the contract.
     * Initializes the wrappers contract addresses for the given batch of NFT Types.
     *
     * @param _admin - Initial admin of this contract.
     * @param _nftTypes - The nft types, e.g. "ERC721", or "ERC1155".
     * @param _nftWrappers - The addresses of the wrapper contract that implements INftWrapper behaviour for dealing
     */
    constructor(
        address _admin,
        string[] memory _nftTypes,
        address[] memory _nftWrappers
    ) Ownable(_admin) {
        _setNftTypes(_nftTypes, _nftWrappers);
    }

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    /**
     * @notice Set or update the wrapper contract address for the given NFT Type.
     * Set address(0) for a nft type for un-register such type.
     *
     * @param _nftType - The nft type, e.g. "ERC721", or "ERC1155".
     * @param _nftWrapper - The address of the wrapper contract that implements INftWrapper behaviour for dealing with
     * NFTs.
     */
    function setNftType(string memory _nftType, address _nftWrapper) external onlyOwner {
        _setNftType(_nftType, _nftWrapper);
    }

    /**
     * @notice Batch set or update the wrappers contract address for the given batch of NFT Types.
     * Set address(0) for a nft type for un-register such type.
     *
     * @param _nftTypes - The nft types, e.g. "ERC721", or "ERC1155".
     * @param _nftWrappers - The addresses of the wrapper contract that implements INftWrapper behaviour for dealing
     * with NFTs.
     */
    function setNftTypes(string[] memory _nftTypes, address[] memory _nftWrappers) external onlyOwner {
        _setNftTypes(_nftTypes, _nftWrappers);
    }

    /**
     * @notice This function can be called by anyone to get the contract address that implements the given nft type.
     *
     * @param  _nftType - The nft type, e.g. bytes32("ERC721"), or bytes32("ERC1155").
     */
    function getNftTypeWrapper(bytes32 _nftType) external view returns (address) {
        return nftTypes[_nftType];
    }

    /**
     * @notice Set or update the wrapper contract address for the given NFT Type.
     * Set address(0) for a nft type for un-register such type.
     *
     * @param _nftType - The nft type, e.g. "ERC721", or "ERC1155".
     * @param _nftWrapper - The address of the wrapper contract that implements INftWrapper behaviour for dealing with
     * NFTs.
     */
    function _setNftType(string memory _nftType, address _nftWrapper) internal {
        require(bytes(_nftType).length != 0, "nftType is empty");
        bytes32 nftTypeKey = ContractKeys.getIdFromStringKey(_nftType);

        nftTypes[nftTypeKey] = _nftWrapper;

        emit TypeUpdated(nftTypeKey, _nftWrapper);
    }

    /**
     * @notice Batch set or update the wrappers contract address for the given batch of NFT Types.
     * Set address(0) for a nft type for un-register such type.
     *
     * @param _nftTypes - The nft types, e.g. keccak256("ERC721"), or keccak256("ERC1155").
     * @param _nftWrappers - The addresses of the wrapper contract that implements INftWrapper behaviour for dealing
     * with NFTs.
     */
    function _setNftTypes(string[] memory _nftTypes, address[] memory _nftWrappers) internal {
        require(_nftTypes.length == _nftWrappers.length, "setNftTypes function information arity mismatch");

        for (uint256 i = 0; i < _nftWrappers.length; i++) {
            _setNftType(_nftTypes[i], _nftWrappers[i]);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";

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
 *
 * Modified version from openzeppelin/contracts/access/Ownable.sol that allows to
 * initialize the owner using a parameter in the constructor
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address _initialOwner) {
        _setOwner(_initialOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(_newOwner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Sets the owner.
     */
    function _setOwner(address _newOwner) private {
        address oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

/**
 * @title ContractKeys
 * @author NFTfi
 * @dev Common library for contract keys
 */
library ContractKeys {
    bytes32 public constant PERMITTED_ERC20S = bytes32("PERMITTED_ERC20S");
    bytes32 public constant PERMITTED_NFTS = bytes32("PERMITTED_NFTS");
    bytes32 public constant PERMITTED_PARTNERS = bytes32("PERMITTED_PARTNERS");
    bytes32 public constant NFT_TYPE_REGISTRY = bytes32("NFT_TYPE_REGISTRY");
    bytes32 public constant LOAN_REGISTRY = bytes32("LOAN_REGISTRY");
    bytes32 public constant PERMITTED_SNFT_RECEIVER = bytes32("PERMITTED_SNFT_RECEIVER");
    bytes32 public constant PERMITTED_BUNDLE_ERC20S = bytes32("PERMITTED_BUNDLE_ERC20S");
    bytes32 public constant PERMITTED_AIRDROPS = bytes32("PERMITTED_AIRDROPS");
    bytes32 public constant AIRDROP_RECEIVER = bytes32("AIRDROP_RECEIVER");
    bytes32 public constant AIRDROP_FACTORY = bytes32("AIRDROP_FACTORY");
    bytes32 public constant AIRDROP_FLASH_LOAN = bytes32("AIRDROP_FLASH_LOAN");
    bytes32 public constant NFTFI_BUNDLER = bytes32("NFTFI_BUNDLER");

    string public constant AIRDROP_WRAPPER_STRING = "AirdropWrapper";

    /**
     * @notice Returns the bytes32 representation of a string
     * @param _key the string key
     * @return id bytes32 representation
     */
    function getIdFromStringKey(string memory _key) external pure returns (bytes32 id) {
        require(bytes(_key).length <= 32, "invalid key");

        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := mload(add(_key, 32))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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