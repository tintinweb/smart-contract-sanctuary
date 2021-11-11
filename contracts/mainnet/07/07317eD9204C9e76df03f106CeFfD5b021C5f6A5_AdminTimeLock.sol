// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "../utils/SecuredAddressLock.sol";
import "../interfaces/IAddressRegistry.sol";
import "../interfaces/IRevest.sol";
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
 * @title
 * @dev
 */
contract AdminTimeLock is SecuredAddressLock, ERC165  {

    string public metadataURI = "https://revest.mypinata.cloud/ipfs/QmR9uFVk9fqKwzQHe6dvD4MNDMisJxv16PikxxJNuR6US5";

    mapping (uint => AdminLock) public locks;

    struct AdminLock {
        uint endTime;
        address admin;
        bool unlocked;
    }

    constructor(address reg_) SecuredAddressLock(reg_) {}

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IAddressLock).interfaceId
            || interfaceId == type(IRegistryProvider).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function isUnlockable(uint, uint lockId) public view override returns (bool) {
        return locks[lockId].unlocked || block.timestamp > locks[lockId].endTime;
    }


    // Create the lock within that contract DURING minting
    function createLock(uint, uint lockId, bytes memory arguments) external override onlyRevestController {
        uint endTime;
        address admin;
        (endTime, admin) = abi.decode(arguments, (uint, address));

        // Check that we aren't creating a lock in the past
        require(block.timestamp < endTime, 'E002');

        AdminLock memory adminLock = AdminLock(endTime, admin, false);
        locks[lockId] = adminLock;
    }

    function updateLock(uint, uint lockId, bytes memory) external override {
        // For an admin lock, there are no arguments
        if(_msgSender() == locks[lockId].admin) {
           locks[lockId].unlocked = true;
        }
    }

    function needsUpdate() external pure override returns (bool) {
        return true;
    }

    // TODO: Now that we have changed this from being broken for splittable locks, how do we communicate the two-steps
    // That are now needed to unlock this lock?
    function getDisplayValues(uint, uint lockId) external view override returns (bytes memory) {
        uint endTime = locks[lockId].endTime;
        address admin = locks[lockId].admin;
        bool canUnlock = admin == _msgSender();
        return abi.encode(endTime, admin, canUnlock);
    }

    function setMetadata(string memory _metadataURI) external onlyOwner {
        metadataURI = _metadataURI;
    }

    function getMetadata() external view override returns (string memory) {
        return metadataURI;
    }

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "../interfaces/IAddressLock.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract SecuredAddressLock is IAddressLock, Ownable {

    IAddressRegistry public addressesProvider;

    constructor(address provider) Ownable() {
        addressesProvider = IAddressRegistry(provider);
    }

    function setAddressRegistry(address registry) external override onlyOwner {
        addressesProvider = IAddressRegistry(registry);
    }

    function getAddressRegistry() external view override returns (address) {
        return address(addressesProvider);
    }


    modifier onlyLockManager() {
        require(_msgSender() != address(0), "E004");
        require(_msgSender() == addressesProvider.getLockManager(), 'E074');
        _;
    }

    modifier onlyRevestController() {
        require(_msgSender() != address(0), "E004");
        require(_msgSender() == addressesProvider.getRevest(), "E017");
        _;
    }

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

/**
 * @title Provider interface for Revest FNFTs
 * @dev
 *
 */
interface IAddressRegistry {

    function initialize(
        address lock_manager_,
        address liquidity_,
        address revest_token_,
        address token_vault_,
        address revest_,
        address fnft_,
        address metadata_,
        address admin_,
        address rewards_
    ) external;

    function getAdmin() external view returns (address);

    function setAdmin(address admin) external;

    function getLockManager() external view returns (address);

    function setLockManager(address manager) external;

    function getTokenVault() external view returns (address);

    function setTokenVault(address vault) external;

    function getRevestFNFT() external view returns (address);

    function setRevestFNFT(address fnft) external;

    function getMetadataHandler() external view returns (address);

    function setMetadataHandler(address metadata) external;

    function getRevest() external view returns (address);

    function setRevest(address revest) external;

    function getDEX(uint index) external view returns (address);

    function setDex(address dex) external;

    function getRevestToken() external view returns (address);

    function setRevestToken(address token) external;

    function getRewardsHandler() external view returns(address);

    function setRewardsHandler(address esc) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLPs() external view returns (address);

    function setLPs(address liquidToken) external;

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

interface IRevest {
    event FNFTTimeLockMinted(
        address indexed asset,
        address indexed from,
        uint indexed fnftId,
        uint endTime,
        uint[] quantities,
        FNFTConfig fnftConfig
    );

    event FNFTValueLockMinted(
        address indexed primaryAsset,
        address indexed from,
        uint indexed fnftId,
        address compareTo,
        address oracleDispatch,
        uint[] quantities,
        FNFTConfig fnftConfig
    );

    event FNFTAddressLockMinted(
        address indexed asset,
        address indexed from,
        uint indexed fnftId,
        address trigger,
        uint[] quantities,
        FNFTConfig fnftConfig
    );

    event FNFTWithdrawn(
        address indexed from,
        uint indexed fnftId,
        uint indexed quantity
    );

    event FNFTSplit(
        address indexed from,
        uint[] indexed newFNFTId,
        uint[] indexed proportions,
        uint quantity
    );

    event FNFTUnlocked(
        address indexed from,
        uint indexed fnftId
    );

    event FNFTMaturityExtended(
        address indexed from,
        uint indexed fnftId,
        uint indexed newExtendedTime
    );

    event FNFTAddionalDeposited(
        address indexed from,
        uint indexed newFNFTId,
        uint indexed quantity,
        uint amount
    );

    struct FNFTConfig {
        address asset; // The token being stored
        address pipeToContract; // Indicates if FNFT will pipe to another contract
        uint depositAmount; // How many tokens
        uint depositMul; // Deposit multiplier
        uint split; // Number of splits remaining
        uint depositStopTime; //
        bool maturityExtension; // Maturity extensions remaining
        bool isMulti; //
        bool nontransferrable; // False by default (transferrable) //
    }

    // Refers to the global balance for an ERC20, encompassing possibly many FNFTs
    struct TokenTracker {
        uint lastBalance;
        uint lastMul;
    }

    enum LockType {
        DoesNotExist,
        TimeLock,
        ValueLock,
        AddressLock
    }

    struct LockParam {
        address addressLock;
        uint timeLockExpiry;
        LockType lockType;
        ValueLock valueLock;
    }

    struct Lock {
        address addressLock;
        LockType lockType;
        ValueLock valueLock;
        uint timeLockExpiry;
        uint creationTime;
        bool unlocked;
    }

    struct ValueLock {
        address asset;
        address compareTo;
        address oracle;
        uint unlockValue;
        bool unlockRisingEdge;
    }

    function mintTimeLock(
        uint endTime,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable returns (uint);

    function mintValueLock(
        address primaryAsset,
        address compareTo,
        uint unlockValue,
        bool unlockRisingEdge,
        address oracleDispatch,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable returns (uint);

    function mintAddressLock(
        address trigger,
        bytes memory arguments,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable returns (uint);

    function withdrawFNFT(uint tokenUID, uint quantity) external;

    function unlockFNFT(uint tokenUID) external;

    function splitFNFT(
        uint fnftId,
        uint[] memory proportions,
        uint quantity
    ) external returns (uint[] memory newFNFTIds);

    function depositAdditionalToFNFT(
        uint fnftId,
        uint amount,
        uint quantity
    ) external returns (uint);

    function setFlatWeiFee(uint wethFee) external;

    function setERC20Fee(uint erc20) external;

    function getFlatWeiFee() external returns (uint);

    function getERC20Fee() external returns (uint);


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

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRegistryProvider.sol";
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

/**
 * @title Provider interface for Revest FNFTs
 * @dev Address locks MUST be non-upgradeable to be considered for trusted status
 * @author Revest
 */
interface IAddressLock is IRegistryProvider, IERC165{

    /// Creates a lock to the specified lockID
    /// @param fnftId the fnftId to map this lock to. Not recommended for typical locks, as it will break on splitting
    /// @param lockId the lockId to map this lock to. Recommended uint for storing references to lock configurations
    /// @param arguments an abi.encode() bytes array. Allows frontend to encode and pass in an arbitrary set of parameters
    /// @dev creates a lock for the specified lockId. Will be called during the creation process for address locks when the address
    ///      of a contract implementing this interface is passed in as the "trigger" address for minting an address lock. The bytes
    ///      representing any parameters this lock requires are passed through to this method, where abi.decode must be call on them
    function createLock(uint fnftId, uint lockId, bytes memory arguments) external;

    /// Updates a lock at the specified lockId
    /// @param fnftId the fnftId that can map to a lock config stored in implementing contracts. Not recommended, as it will break on splitting
    /// @param lockId the lockId that maps to the lock config which should be updated. Recommended for retrieving references to lock configurations
    /// @param arguments an abi.encode() bytes array. Allows frontend to encode and pass in an arbitrary set of parameters
    /// @dev updates a lock for the specified lockId. Will be called by the frontend from the information section if an update is requested
    ///      can further accept and decode parameters to use in modifying the lock's config or triggering other actions
    ///      such as triggering an on-chain oracle to update
    function updateLock(uint fnftId, uint lockId, bytes memory arguments) external;

    /// Whether or not the lock can be unlocked
    /// @param fnftId the fnftId that can map to a lock config stored in implementing contracts. Not recommended, as it will break on splitting
    /// @param lockId the lockId that maps to the lock config which should be updated. Recommended for retrieving references to lock configurations
    /// @dev this method is called during the unlocking and withdrawal processes by the Revest contract - it is also used by the frontend
    ///      if this method is returning true and someone attempts to unlock or withdraw from an FNFT attached to the requested lock, the request will succeed
    /// @return whether or not this lock may be unlocked
    function isUnlockable(uint fnftId, uint lockId) external view returns (bool);

    /// Provides an encoded bytes arary that represents values this lock wants to display on the info screen
    /// Info to decode these values is provided in the metadata file
    /// @param fnftId the fnftId that can map to a lock config stored in implementing contracts. Not recommended, as it will break on splitting
    /// @param lockId the lockId that maps to the lock config which should be updated. Recommended for retrieving references to lock configurations
    /// @dev used by the frontend to fetch on-chain data on the state of any given lock
    /// @return a bytes array that represents the result of calling abi.encode on values which the developer wants to appear on the frontend
    function getDisplayValues(uint fnftId, uint lockId) external view returns (bytes memory);

    /// Maps to a URL, typically IPFS-based, that contains information on how to encode and decode paramters sent to and from this lock
    /// Please see additional documentation for JSON config info
    /// @dev this method will be called by the frontend only but is crucial to properly implement for proper minting and information workflows
    /// @return a URL to the JSON file containing this lock's metadata schema
    function getMetadata() external view returns (string memory);

    /// Whether or not this lock will need updates and should display the option for them
    /// @dev this will be called by the frontend to determine if update inputs and buttons should be displayed
    /// @return whether or not the locks created by this contract will need updates
    function needsUpdate() external view returns (bool);
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

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "../interfaces/IAddressRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILockManager.sol";
import "../interfaces/ITokenVault.sol";
import "../lib/uniswap/IUniswapV2Factory.sol";

interface IRegistryProvider {
    function setAddressRegistry(address revest) external;

    function getAddressRegistry() external view returns (address);
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

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRevest.sol";

interface ILockManager {

    function createLock(uint fnftId, IRevest.LockParam memory lock) external returns (uint);

    function getLock(uint lockId) external view returns (IRevest.Lock memory);

    function fnftIdToLockId(uint fnftId) external view returns (uint);

    function fnftIdToLock(uint fnftId) external view returns (IRevest.Lock memory);

    function pointFNFTToLock(uint fnftId, uint lockId) external;

    function lockTypes(uint tokenId) external view returns (IRevest.LockType);

    function unlockFNFT(uint fnftId, address sender) external returns (bool);

    function getLockMaturity(uint fnftId) external view returns (bool);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRevest.sol";

interface ITokenVault {

    function createFNFT(
        uint fnftId,
        IRevest.FNFTConfig memory fnftConfig,
        uint quantity,
        address from
    ) external;

    function withdrawToken(
        uint fnftId,
        uint quantity,
        address user
    ) external;

    function depositToken(
        uint fnftId,
        uint amount,
        uint quantity
    ) external;

    function cloneFNFTConfig(IRevest.FNFTConfig memory old) external returns (IRevest.FNFTConfig memory);

    function mapFNFTToToken(
        uint fnftId,
        IRevest.FNFTConfig memory fnftConfig
    ) external;

    function handleMultipleDeposits(
        uint fnftId,
        uint newFNFTId,
        uint amount
    ) external;

    function splitFNFT(
        uint fnftId,
        uint[] memory newFNFTIds,
        uint[] memory proportions,
        uint quantity
    ) external;

    function getFNFT(uint fnftId) external view returns (IRevest.FNFTConfig memory);
    function getFNFTCurrentValue(uint fnftId) external view returns (uint);
    function getNontransferable(uint fnftId) external view returns (bool);
    function getSplitsRemaining(uint fnftId) external view returns (uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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