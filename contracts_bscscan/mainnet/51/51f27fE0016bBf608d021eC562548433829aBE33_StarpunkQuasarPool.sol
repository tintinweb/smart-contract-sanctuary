//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IStarpunkReward is IERC1155 {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

interface ILockPool {
    function validWhitelist(address _stakeholder, uint256 _requireTier)
        external
        view
        returns (bool);
}

contract StarpunkQuasarPool is Ownable {
    event RewardDistributed(
        address indexed to,
        uint256 indexed tokenId,
        uint256 amount
    );
    uint256 public constant QUASAR = 88888888;

    uint256[] public tiers;
    mapping(uint256 => uint256) public tierRewards;
    mapping(address => uint256) public lastClaimDates;
    mapping(address => uint256) public claimedRewards;
    uint256 public waitPeriod = 259200;
    bool public paused;
    IStarpunkReward public rewardAsset;
    ILockPool public lockPool;

    function setRewardAsset(address _rewardAsset) external onlyOwner {
        rewardAsset = IStarpunkReward(_rewardAsset);
    }

    function setLockPool(address _lockPool) external onlyOwner {
        lockPool = ILockPool(_lockPool);
    }

    function setTierRewards(
        uint256[] calldata _tiers,
        uint256[] calldata _rewards
    ) external onlyOwner {
        for (uint256 i = 0; i < _tiers.length; i++) {
            tierRewards[_tiers[i]] = _rewards[i];
            tiers.push(_tiers[i]);
        }
    }

    function setWaitPeriod(uint256 _waitPeriod) external onlyOwner {
        waitPeriod = _waitPeriod;
    }

    function pauseQuasarRewardPool() external onlyOwner {
        paused = true;
    }

    function unpauseQuasarRewardPool() external onlyOwner {
        paused = false;
    }

    function claimRewards() external {
        require(
            !paused,
            "StarpunkQuasarPool: this reward pool is paused now"
        );
        address userAddress = _msgSender();
        uint256 currentTier = getCurrentTier(userAddress);
        require(
            currentTier > 0,
            "StarpunkQuasarPool: invalid level to join the reward pool"
        );

        require(
            lastClaimDates[userAddress] == 0 ||
                block.timestamp - waitPeriod >= lastClaimDates[userAddress],
            "StarpunkQuasarPool: please wait for the next reward period to claim"
        );

        lastClaimDates[userAddress] = block.timestamp;
        claimedRewards[userAddress] += tierRewards[currentTier];

        rewardAsset.mint(userAddress, QUASAR, tierRewards[currentTier], "");

        emit RewardDistributed(userAddress, QUASAR, tierRewards[currentTier]);
    }

    function getCurrentTier(address _userAddress)
        internal
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < tiers.length; i++) {
            if (lockPool.validWhitelist(_userAddress, tiers[i])) {
                return tiers[i];
            }
        }

        return 0;
    }

    function rewardInformation(address _userAddress)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 currentTier = getCurrentTier(_userAddress);
        if (currentTier == 0) {
            return (0, 0, 0, 0);
        }

        uint256 nextClaimDate = block.timestamp - waitPeriod >
            lastClaimDates[_userAddress]
            ? block.timestamp
            : lastClaimDates[_userAddress] + waitPeriod;

        return (
            currentTier,
            tierRewards[currentTier],
            claimedRewards[_userAddress],
            nextClaimDate
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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