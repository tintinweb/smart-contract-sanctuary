/// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./interfaces/IAliumGaming1155.sol";
import "./interfaces/INFTRewardPool.sol";

/**
 * @title NFTRewardPool - Special NFT reward pool for SHP alium users and
 *      gamers.
 */
contract NFTRewardPool is
    INFTRewardPool,
    Ownable,
    IERC1155Receiver,
    ERC1155Holder
{
    struct Reward {
        uint256 tokenId;
        uint256 amount;
    }

    struct InputReward {
        Reward[] rewards;
    }

    bool public status;

    IAliumGaming1155 public rewardToken;
    address public shp;

    bool public initialized;

    mapping(uint256 => Reward[]) internal _rewards;
    // pool id -> withdraw position -> counter
    mapping(address => mapping(uint256 => uint256)) internal _logs;
    // account -> tokenId -> amount
    mapping(address => mapping(uint256 => uint256)) internal _balances;

    event Logged(address, uint256);
    event ErrorLog(bytes);
    event Initialized();
    event RewardUpdated(uint256 poolId);

    /**
     * @dev Initialize contract.
     *
     * Permission: Owner
     */
    function initialize(IAliumGaming1155 _rewardToken, address _shp)
        external
        onlyOwner
    {
        require(!initialized, "Reward pool: initialized");
        require(address(_rewardToken) != address(0), "Reward zero address");
        require(_shp != address(0), "SHP zero address");

        require(
            ERC165Checker.supportsERC165(address(_rewardToken)),
            "ERC165 unsupported token"
        );
        require(
            ERC165Checker.supportsInterface(
                address(_rewardToken),
                type(IAliumGaming1155).interfaceId
            ),
            "ERC1155 unsupported token"
        );

        rewardToken = _rewardToken;
        shp = _shp;
        initialized = true;
        emit Initialized();
    }

    /**
     * @dev Write to log `_caller` and `_withdrawPosition`.
     *
     * Permission: SHP
     */
    function log(address _caller, uint256 _withdrawPosition)
        external
        override
        onlySHP
    {
        require(_caller != address(0), "Log zero address");

        _logs[_caller][_withdrawPosition] += 1;
        emit Logged(_caller, _withdrawPosition);
    }

    /**
     * @dev Claim available reward.
     */
    function claim() external {
        Reward memory reward;
        uint256[101] memory _userLogs = getLogs(msg.sender);
        for (uint256 i; i <= 100; i++) {
            if (_userLogs[i] != 0) {
                // clear log data
                delete _logs[msg.sender][i];
                uint256 ll = _rewards[i].length;
                for (uint256 ii; ii < ll; ii++) {
                    reward = _rewards[i][ii];
                    rewardToken.mint(
                        address(this),
                        reward.tokenId,
                        reward.amount,
                        ""
                    );
                    try
                        rewardToken.safeTransferFrom(
                            address(this),
                            msg.sender,
                            reward.tokenId,
                            reward.amount,
                            ""
                        )
                    {
                        //
                    } catch (bytes memory error) {
                        _balances[msg.sender][reward.tokenId] += reward.amount;
                        emit ErrorLog(error);
                    }
                }
            }
        }
    }

    /**
     * @dev Withdraw available tokens by `_tokenId`.
     */
    function withdraw(uint256 _tokenId) external {
        _withdraw(
            msg.sender,
            msg.sender,
            _tokenId,
            _balances[msg.sender][_tokenId]
        );
    }

    /**
     * @dev Withdraw to account `_to` amount `_tokenAmount` tokens with `_tokenId`.
     */
    function withdrawTo(
        address _to,
        uint256 _tokenId,
        uint256 _tokenAmount
    ) external {
        _withdraw(msg.sender, _to, _tokenId, _tokenAmount);
    }

    /**
     * @dev Returns `_account` balance by `_tokenId`.
     */
    function getBalance(address _account, uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        return _balances[_account][_tokenId];
    }

    /**
     * @dev Returns `_account` log by `_withdrawPosition`.
     */
    function getLog(address _account, uint256 _withdrawPosition)
        external
        view
        returns (uint256 res)
    {
        res = _logs[_account][_withdrawPosition];
    }

    /**
     * @dev Returns reward by `_withdrawPosition`.
     */
    function getReward(uint256 _withdrawPosition)
        external
        view
        returns (Reward[] memory)
    {
        return _rewards[_withdrawPosition];
    }

    /**
     * @dev Set `_rewardsList` for current `_withdrawPosition`.
     *
     * Permission: owner
     *
     * @notice Reward will be overwritten
     */
    function setReward(uint256 _position, Reward[] memory _rewardsList)
        external
        onlyOwner
    {
        uint256 l = _rewardsList.length;
        uint256 i = 0;
        delete _rewards[_position];
        for (i; i < l; i++) {
            require(_rewardsList[i].amount != 0, "Zero reward amount");

            _rewards[_position].push(_rewardsList[i]);
        }

        emit RewardUpdated(_position);
    }

    /**
     * @dev Set `_rewardsLists` for selected `_positions`.
     *
     * Permission: owner
     *
     * @notice Reward will be overwritten
     */
    function setRewards(
        uint256[] memory _positions,
        InputReward[] memory _rewardsLists
    ) external onlyOwner {
        uint256 l = _positions.length;

        require(l == _rewardsLists.length, "Incorrect length input data");

        uint256 i;
        uint256 ll;
        for (i; i < l; i++) {
            if (_positions[i] > 100 || _positions[i] == 0) {
                require(false, "Wrong position index set");
            }
        }

        i = 0;
        for (i; i < l; i++) {
            if (_rewards[_positions[i]].length != 0) {
                delete _rewards[_positions[i]];
            }

            ll = _rewardsLists[i].rewards.length;
            for (uint256 ii; ii < ll; ii++) {
                _rewards[_positions[i]].push(_rewardsLists[i].rewards[ii]);
            }

            emit RewardUpdated(_positions[i]);
        }
    }

    /**
     * @dev Returns `_account` logs.
     */
    function getLogs(address _account)
        public
        view
        returns (uint256[101] memory res)
    {
        uint256 l = 100;
        uint256 i = 1;
        for (i; i <= l; i++) {
            res[i] = _logs[_account][i];
        }
    }

    function _withdraw(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _tokenAmount
    ) private {
        require(
            _from != address(0) &&
            _to != address(0),
            "Transfer to or from zero address"
        );

        uint256 balance = _balances[_from][_tokenId];

        require(balance > 0, "Withdraw empty balance");
        require(_tokenAmount >= balance, "Not enough token balance");

        _balances[_from][_tokenId] -= _tokenAmount;
        rewardToken.safeTransferFrom(address(this), _to, _tokenId, balance, "");
    }

    modifier onlySHP() {
        require(msg.sender == shp, "Only SHP contract");
        _;
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

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165(account).supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IAliumGaming1155 is IERC1155 {
    function mint(
        address to,
        uint256 tokenId,
        uint256 tokenAmount,
        bytes memory data
    ) external;

    function burn(uint256 tokenId, uint256 tokenAmount) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function burnBatch(uint256[] memory ids, uint256[] memory amounts) external;
}

/// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface INFTRewardPool {
    function log(address _caller, uint256 _withdrawPosition) external;
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

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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