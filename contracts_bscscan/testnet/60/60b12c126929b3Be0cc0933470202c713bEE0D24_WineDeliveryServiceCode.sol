// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./interfaces/IWineManager.sol";
import "./interfaces/IWineFactory.sol";
import "./interfaces/IWinePool.sol";
import "./interfaces/IWinePoolFull.sol";
import "./interfaces/IWineDeliveryService.sol";
import "./vendors/access/ManagerLikeOwner.sol";
import "./vendors/security/ReentrancyGuardInitializable.sol";
import "./vendors/utils/ERC721OnlySelfInitHolder.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract WineDeliveryServiceCode is
    ManagerLikeOwner,
    Initializable,
    ReentrancyGuardInitializable,
    ERC721OnlySelfInitHolder,
    IWineDeliveryService
{

    function initialize(
        address manager_
    )
        override
        public
        initializer
    {
        _initializeManager(manager_);
        _initializeReentrancyGuard();
    }

//////////////////////////////////////// DeliverySettings

    // poolId => UnixTime(BeginOfDelivery)
    mapping(uint256 => uint256) public override getPoolDateBeginOfDelivery;

    modifier allowedDelivery(uint256 poolId) {
        require(getPoolDateBeginOfDelivery[poolId] != 0, "allowedDelivery: DateBeginOfDelivery not set yet");
        require(getPoolDateBeginOfDelivery[poolId] < block.timestamp, "allowedDelivery: not allowed yet");
        _;
    }

    function _editPoolDateBeginOfDelivery(
        uint256 poolId,
        uint256 dateBegin
    )
        override
        public
        onlyManager
    {
        require(IWineManager(manager()).getPoolAddress(poolId) != address(0), "editPoolDateBeginOfDelivery - poolIdNotExists");
        getPoolDateBeginOfDelivery[poolId] = dateBegin;
    }

//////////////////////////////////////// DeliveryTasks inner methods

//    address public publicKey; // todo all encrypt logic

    uint256 private availableDeliveryTaskId = 1;
    // poolId => tokenId => deliveryTaskId`s
    mapping(uint256 => mapping(uint256 => uint256[])) private deliveryTasksHistory;
    // deliveryTaskId => deliveryTask
    mapping(uint256 => DeliveryTask) private deliveryTasks;

    function _getLastDeliveryTaskId(uint256 poolId, uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        uint256 deliveryTasksHistoryLength = deliveryTasksHistory[poolId][tokenId].length;
        if (deliveryTasksHistoryLength == 0) {
            return 0;
        }
        return deliveryTasksHistoryLength - 1;
    }

    function _createDeliveryTask(
        uint256 poolId,
        uint256 tokenId,
        address tokenOwner,
        bool isInternal,
        string memory deliveryData
    )
        internal
        returns (uint256 deliveryTaskId)
    {
        availableDeliveryTaskId++;
        deliveryTaskId = availableDeliveryTaskId - 1;

        deliveryTasks[deliveryTaskId] = DeliveryTask({
            tokenOwner: tokenOwner,
            isInternal: isInternal,
            deliveryData: deliveryData,
            supportResponse: "",
            status: DeliveryTaskStatus.New
        });
        deliveryTasksHistory[poolId][tokenId].push(deliveryTaskId);
    }

    function _getDeliveryTask(
        uint256 deliveryTaskId
    )
        internal
        view
        returns (DeliveryTask memory)
    {
        DeliveryTask memory deliveryTask = deliveryTasks[deliveryTaskId];
        require(deliveryTask.tokenOwner != address(0), "showSingleDelivery: deliveryTask not exists");
        require(
            _msgSender() == manager() || (deliveryTask.isInternal == false && _msgSender() == deliveryTask.tokenOwner),
            "showSingleDelivery: Permission denied"
        );
        return deliveryTask;
    }

//////////////////////////////////////// DeliveryTasks view methods

    function showSingleDeliveryTask(
        uint256 deliveryTaskId
    )
        override
        public
        view
        returns (DeliveryTask memory)
    {
        return _getDeliveryTask(deliveryTaskId);
    }

    function showLastDeliveryTask(
        uint256 poolId,
        uint256 tokenId
    )
        override
        public
        view
        returns (DeliveryTask memory)
    {
        uint256 deliveryTaskId = _getLastDeliveryTaskId(poolId, tokenId);
        return _getDeliveryTask(deliveryTaskId);
    }

    function showFullHistory(
        uint256 poolId,
        uint256 tokenId
    )
        override
        public
        view
        onlyManager
    returns (uint256, DeliveryTask[] memory)
    {
        uint256 historyLength = deliveryTasksHistory[poolId][tokenId].length;
        DeliveryTask[] memory history = new DeliveryTask[](historyLength);

        for (uint256 i = 0; i < historyLength; i++) {
            history[i] = _getDeliveryTask(deliveryTasksHistory[poolId][tokenId][i]);
        }

        return(historyLength, history);
    }


//////////////////////////////////////// DeliveryTasks edit methods

    function requestDelivery(
        uint256 poolId,
        uint256 tokenId,
        string memory deliveryData
    )
        override
        public
        returns (uint256 deliveryTaskId)
    {
        IWinePoolFull pool = IWineManager(manager()).getPoolAsContract(poolId);

        address tokenOwner = _msgSender();
        pool.safeTransferFrom(tokenOwner, address(this), tokenId);

        deliveryTaskId = _createDeliveryTask(
            poolId,
            tokenId,
            tokenOwner,
            false,
            deliveryData
        );
    }

    function requestDeliveryForInternal(
        uint256 poolId,
        uint256 tokenId,
        string memory deliveryData
    )
        override
        public
        onlyManager
        returns (uint256 deliveryTaskId)
    {
        IWinePoolFull pool = IWineManager(manager()).getPoolAsContract(poolId);

        address tokenOwner = pool.internalOwnedTokens(tokenId);
        pool.transferInternalToOuter(tokenOwner, address(this), tokenId);

        deliveryTaskId = _createDeliveryTask(
            poolId,
            tokenId,
            tokenOwner,
            true,
            deliveryData
        );
    }

    function setSupportResponse(
        uint256 poolId,
        uint256 tokenId,
        string memory supportResponse
    )
        override
        public
        onlyManager nonReentrant
    {
        uint256 deliveryTaskId = _getLastDeliveryTaskId(poolId, tokenId);
        DeliveryTask storage deliveryTask = deliveryTasks[deliveryTaskId];
        require(deliveryTask.tokenOwner != address(0), "setSupportResponse: deliveryTask not exists");
        require(
            deliveryTask.status == DeliveryTaskStatus.New || deliveryTask.status == DeliveryTaskStatus.InProcess,
            "setSupportResponse: status not allowed"
        );
        deliveryTask.supportResponse = supportResponse;
        deliveryTask.status = DeliveryTaskStatus.InProcess;
    }

    function cancelDeliveryTask(
        uint256 poolId,
        uint256 tokenId,
        string memory supportResponse
    )
        override
        public
        onlyManager nonReentrant
    {
        uint256 deliveryTaskId = _getLastDeliveryTaskId(poolId, tokenId);
        DeliveryTask storage deliveryTask = deliveryTasks[deliveryTaskId];
        require(deliveryTask.tokenOwner != address(0), "showSingleDelivery: deliveryTask not exists");
        require(
            deliveryTask.status == DeliveryTaskStatus.New || deliveryTask.status == DeliveryTaskStatus.InProcess,
            "cancelDeliveryTask: status not allowed"
        );
        deliveryTask.supportResponse = supportResponse;
        deliveryTask.status = DeliveryTaskStatus.Canceled;

        IWinePoolFull pool = IWineManager(manager()).getPoolAsContract(poolId);
        if (deliveryTask.isInternal) {
            pool.transferOuterToInternal(address(this), deliveryTask.tokenOwner, tokenId);
        } else {
            pool.safeTransferFrom(address(this), deliveryTask.tokenOwner, tokenId);
        }
    }

    function finishDeliveryTask(
        uint256 poolId,
        uint256 tokenId,
        string memory supportResponse
    )
        override
        public
        onlyManager nonReentrant
    {
        uint256 deliveryTaskId = _getLastDeliveryTaskId(poolId, tokenId);
        DeliveryTask storage deliveryTask = deliveryTasks[deliveryTaskId];
        require(deliveryTask.tokenOwner != address(0), "showSingleDelivery: deliveryTask not exists");
        require(
            deliveryTask.status == DeliveryTaskStatus.InProcess,
            "finishDeliveryTask: status not allowed"
        );
        deliveryTask.supportResponse = supportResponse;
        deliveryTask.status = DeliveryTaskStatus.Executed;

        IWinePoolFull pool = IWineManager(manager()).getPoolAsContract(poolId);
        pool.burn(tokenId);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts only self initiated token transfers.
 */
abstract contract ERC721OnlySelfInitHolder is IERC721Receiver {

    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        if (operator == address(this)) {
            return this.onERC721Received.selector;
        }
        return bytes4(0);
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
abstract contract ReentrancyGuardInitializable {
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

    function _initializeReentrancyGuard()
        internal
    {
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

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an manager) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the manager account will be the one that deploys the contract. This
 * can later be changed with {transferManagership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyManager`, which can be applied to your functions to restrict their use to
 * the manager.
 */
contract ManagerLikeOwner is Context {
    address private _manager;

    event ManagershipTransferred(address indexed previousManager, address indexed newManager);

    /**
     * @dev Initializes the contract setting the deployer as the initial manager.
     */
    function _initializeManager(address manager_)
        internal
    {
        _transferManagership(manager_);
    }

    /**
     * @dev Returns the address of the current manager.
     */
    function manager()
        public view
        returns (address)
    {
        return _manager;
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(_manager == _msgSender(), "ManagerIsOwner: caller is not the manager");
        _;
    }

    /**
     * @dev Leaves the contract without manager. It will not be possible to call
     * `onlyManager` functions anymore. Can only be called by the current manager.
     *
     * NOTE: Renouncing managership will leave the contract without an manager,
     * thereby removing any functionality that is only available to the manager.
     */
    function renounceManagership()
        virtual
        public
        onlyManager
    {
        _beforeTransferManager(address(0));

        emit ManagershipTransferred(_manager, address(0));
        _manager = address(0);
    }

    /**
     * @dev Transfers managership of the contract to a new account (`newManager`).
     * Can only be called by the current manager.
     */
    function transferManagership(address newManager)
        virtual
        public
        onlyManager
    {
        _transferManagership(newManager);
    }

    function _transferManagership(address newManager)
        virtual
        internal
    {
        require(newManager != address(0), "ManagerIsOwner: new manager is the zero address");
        _beforeTransferManager(newManager);

        emit ManagershipTransferred(_manager, newManager);
        _manager = newManager;
    }

    /**
     * @dev Hook that is called before manger transfer. This includes initialize and renounce
     */
    function _beforeTransferManager(address newManager)
        virtual
        internal
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IWinePool.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";


interface IWinePoolFull is IERC165, IERC721, IERC721Metadata, IWinePool
{
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWinePool
{
//////////////////////////////////////// DescriptionFields

    function updateAllDescriptionFields(
        string memory wineName,
        string memory wineProductionCountry,
        string memory wineProductionRegion,
        string memory wineProductionYear,
        string memory wineProducerName,
        string memory wineBottleVolume,
        string memory linkToDocuments
    ) external;
    function editDescriptionField(bytes32 param, string memory value) external;

//////////////////////////////////////// System fields

    function getPoolId() external view returns (uint256);
    function getMaxTotalSupply() external view returns (uint256);
    function getWinePrice() external view returns (uint256);

    function editMaxTotalSupply(uint256 value) external;
    function editWinePrice(uint256 value) external;

//////////////////////////////////////// Pausable

    function pause() external;
    function unpause() external;

//////////////////////////////////////// Initialize

    function initialize(
        string memory name,
        string memory symbol,

        address manager,

        uint256 poolId,
        uint256 maxTotalSupply,
        uint256 winePrice
    ) external payable returns (bool);

//////////////////////////////////////// Disable

    function disabled() external view returns (bool);

    function disablePool() external;

//////////////////////////////////////// default methods

    function tokensCount() external view returns (uint256);

    function burn(uint256 tokenId) external;

    function mint(address to) external returns (uint256);

//////////////////////////////////////// internal users and tokens

    event InternalTransfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function internalUsersExists(address) external view returns (bool);
    function internalOwnedTokens(uint256) external view returns (address);

    function mintToInternalUser(address internalUser) external returns (uint256);

    function transferInternalToInternal(address internalFrom, address internalTo, uint256 tokenId) external;

    function transferOuterToInternal(address outerFrom, address internalTo, uint256 tokenId) external;

    function transferInternalToOuter(address internalFrom, address outerTo, uint256 tokenId) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineManagerPoolIntegration {

    function allowMint(address) external view returns (bool);
    function allowInternalTransfers(address) external view returns (bool);
    function allowBurn(address) external view returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineManagerMarketPlaceIntegration {

    function marketPlace() external view returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineManagerFirstSaleMarketIntegration {

    function firstSaleMarket() external view returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IWinePoolFull.sol";

interface IWineManagerFactoryIntegration {

    function factory() external view returns (address);

    function getPoolAddress(uint256 poolId) external view returns (address);

    function getPoolAsContract(uint256 poolId) external view returns (IWinePoolFull);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineManagerDeliveryServiceIntegration {

    function deliveryService() external view returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IWineManagerFactoryIntegration.sol";
import "./IWineManagerFirstSaleMarketIntegration.sol";
import "./IWineManagerMarketPlaceIntegration.sol";
import "./IWineManagerDeliveryServiceIntegration.sol";
import "./IWineManagerPoolIntegration.sol";

interface IWineManager is
    IWineManagerFactoryIntegration,
    IWineManagerFirstSaleMarketIntegration,
    IWineManagerMarketPlaceIntegration,
    IWineManagerDeliveryServiceIntegration,
    IWineManagerPoolIntegration
{

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineFactory {

    event WinePoolCreated(uint256 poolId, address winePool);

    function winePoolCode() external view returns (address);
    function baseUri() external view returns (string memory);
    function baseSymbol() external view returns (string memory);

    function initialize(
        address proxyAdmin_,
        address winePoolCode_,
        address manager_,
        string memory baseUri_,
        string memory baseSymbol_
    ) external;

    function getPool(uint256 poolId) external view returns (address);

    function allPoolsLength() external view returns (uint);

    function createWinePool(
        string memory name_,

        uint256 maxTotalSupply_,
        uint256 winePrice_
    ) external returns (address winePoolAddress);

    function disablePool(uint256 poolId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineDeliveryService {

    function initialize(
        address manager_
    ) external;

//////////////////////////////////////// DeliverySettings

    function getPoolDateBeginOfDelivery(uint256 poolId) external view returns (uint256);

    function _editPoolDateBeginOfDelivery(uint256 poolId, uint256 dateBegin) external;

//////////////////////////////////////// DeliveryTasks public methods

    enum DeliveryTaskStatus {
        New,
        Canceled,
        Executed,
        InProcess
    }

    struct DeliveryTask {
        address tokenOwner;
        bool isInternal;
        string deliveryData;
        string supportResponse;
        DeliveryTaskStatus status;
    }

    function requestDelivery(uint256 poolId, uint256 tokenId, string memory deliveryData) external returns (uint256 deliveryTaskId);

    function requestDeliveryForInternal(uint256 poolId, uint256 tokenId, string memory deliveryData) external returns (uint256 deliveryTaskId);

    function showSingleDeliveryTask(uint256 deliveryTaskId) external view returns (DeliveryTask memory);

    function showLastDeliveryTask(uint256 poolId, uint256 tokenId) external view returns (DeliveryTask memory);

    function showFullHistory(uint256 poolId, uint256 tokenId) external view returns (uint256, DeliveryTask[] memory);

    function setSupportResponse(uint256 poolId, uint256 tokenId, string memory supportResponse) external;

    function cancelDeliveryTask(uint256 poolId, uint256 tokenId, string memory supportResponse) external;

    function finishDeliveryTask(uint256 poolId, uint256 tokenId, string memory supportResponse) external;
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
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}