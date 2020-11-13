// Sources flattened with buidler v1.4.3 https://buidler.dev

// File @openzeppelin/contracts/GSN/Context.sol@v3.1.0

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v3.1.0

pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
}


// File @openzeppelin/contracts/utils/Pausable.sol@v3.1.0

pragma solidity ^0.6.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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


// File @openzeppelin/contracts/math/SafeMath.sol@v3.1.0

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File @openzeppelin/contracts/introspection/IERC165.sol@v3.1.0

pragma solidity ^0.6.0;

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


// File @openzeppelin/contracts/introspection/ERC165.sol@v3.1.0

pragma solidity ^0.6.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155/IERC1155TokenReceiver.sol@v5.0.0

pragma solidity 0.6.8;

/**
 * @title ERC-1155 Multi Token Standard, token receiver
 * @dev See https://eips.ethereum.org/EIPS/eip-1155
 * Interface for any contract that wants to support transfers from ERC1155 asset contracts.
 * Note: The ERC-165 identifier for this interface is 0x4e2312e0.
 */
interface IERC1155TokenReceiver {

    /**
     * @notice Handle the receipt of a single ERC1155 token type.
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
     * This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
     * This function MUST revert if it rejects the transfer.
     * Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
     * @param operator  The address which initiated the transfer (i.e. msg.sender)
     * @param from      The address which previously owned the token
     * @param id        The ID of the token being transferred
     * @param value     The amount of tokens being transferred
     * @param data      Additional data with no specified format
     * @return bytes4   `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @notice Handle the receipt of multiple ERC1155 token types.
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
     * This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
     * This function MUST revert if it rejects the transfer(s).
     * Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
     * @param operator  The address which initiated the batch transfer (i.e. msg.sender)
     * @param from      The address which previously owned the token
     * @param ids       An array containing ids of each token being transferred (order and length must match _values array)
     * @param values    An array containing amounts of each token being transferred (order and length must match _ids array)
     * @param data      Additional data with no specified format
     * @return          `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155/ERC1155TokenReceiver.sol@v5.0.0

pragma solidity 0.6.8;



abstract contract ERC1155TokenReceiver is IERC1155TokenReceiver, ERC165 {

    // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant _ERC1155_RECEIVED = 0xf23a6e61;

    // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    bytes4 internal constant _ERC1155_BATCH_RECEIVED = 0xbc197c81;

    bytes4 internal constant _ERC1155_REJECTED = 0xffffffff;

    constructor() internal {
        _registerInterface(type(IERC1155TokenReceiver).interfaceId);
    }
}


// File @animoca/f1dt-ethereum-contracts/contracts/token/ERC1155721/NFTRepairCentre.sol@v0.4.0

pragma solidity ^0.6.8;





/**
 * @title NFTRepairCentre
 * This contract is used to manage F1 Delta Time defective tokens. Defective tokens are NFTs which were created with an incorrect id.
 * As the core metadata attributes are encoded in the token id, tokens with an incorrect id may not be usable some in ecosystem contracts.
 *
 * This contract has two missions:
 * - Publish a public list of defective tokens (through `repairList`) that ecosystem contracts relying on core metadata attributes can consult as a blacklist,
 * - Let the owners of the defective tokens swap them for replacement tokens. Defective tokens are sent to the `tokensGraveyard` when replaced.
 *
 * The owners of defective tokens who want to use them in these ecosystem contracts will have to repair them first,
 * but will be compensated for their trouble with `revvCompensation` REVVs for each repaired token.
 */
contract NFTRepairCentre is ERC1155TokenReceiver, Ownable, Pausable {
    using SafeMath for uint256;

    event TokensToRepairAdded(uint256[] defectiveTokens, uint256[] replacementTokens);
    event RepairedSingle(uint256 defectiveToken, uint256 replacementToken);
    event RepairedBatch(uint256[] defectiveTokens, uint256[] replacementTokens);

    IDeltaTimeInventory inventoryContract;
    address tokensGraveyard;
    IREVV revvContract;
    uint256 revvCompensation;

    mapping(uint256 => uint256) repairList;

    /**
     * Constructor.
     * @dev Reverts if one of the argument addresses is zero.
     * @param inventoryContract_ the address of the DeltaTimeInventoryContract.
     * @param tokensGraveyard_ the address of the tokens graveyard.
     * @param revvContract_ the address of the REVV contract.
     * @param revvCompensation_ the amount of REVV to compensate for each token replacement.
     */
    constructor(
        address inventoryContract_,
        address tokensGraveyard_,
        address revvContract_,
        uint256 revvCompensation_
    ) public {
        require(
            inventoryContract_ != address(0) && tokensGraveyard_ != address(0) && revvContract_ != address(0),
            "RepairCentre: zero address"
        );
        inventoryContract = IDeltaTimeInventory(inventoryContract_);
        tokensGraveyard = tokensGraveyard_;
        revvContract = IREVV(revvContract_);
        revvCompensation = revvCompensation_;
    }

    /*                                             Public Admin Functions                                             */

    /**
     * @notice Adds tokens to the repair list and transfers the necessary amount of REVV for the compensations to the contract.
     * @dev Reverts if not called by the owner.
     * @dev Reverts if `defectiveTokens` and `replacementTokens` have inconsistent lengths.
     * @dev Reverts if the REVV transfer fails.
     * @dev Emits a TokensToRepairAdded event.
     * @param defectiveTokens the list of defective tokens.
     * @param replacementTokens the list of replacement tokens.
     */
    function addTokensToRepair(uint256[] calldata defectiveTokens, uint256[] calldata replacementTokens)
        external
        onlyOwner
    {
        uint256 length = defectiveTokens.length;
        require(length != 0 && length == replacementTokens.length, "RepairCentre: wrong lengths");
        for (uint256 i = 0; i < length; ++i) {
            repairList[defectiveTokens[i]] = replacementTokens[i];
        }
        revvContract.transferFrom(msg.sender, address(this), revvCompensation.mul(length));
        emit TokensToRepairAdded(defectiveTokens, replacementTokens);
    }

    /**
     * Removes this contract as minter for the inventory contract
     * @dev Reverts if the sender is not the contract owner.
     */
    function renounceMinter() external onlyOwner {
        inventoryContract.renounceMinter();
    }

    /**
     * Pauses the repair operations.
     * @dev Reverts if the sender is not the contract owner.
     * @dev Reverts if the contract is paused already.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * Unpauses the repair operations.
     * @dev Reverts if the sender is not the contract owner.
     * @dev Reverts if the contract is not paused.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /*                                             ERC1155TokenReceiver                                             */

    /**
     * @notice ERC1155 single transfer receiver which repairs a single token and removes it from the repair list.
     * @dev This contract must have been given a minter role for the inventory prior to caslling this function.
     * @dev Reverts if the transfer was not operated through `inventoryContract`.
     * @dev Reverts if `id` is not in the repair list.
     * @dev Reverts if the defective token transfer to the graveyard fails.
     * @dev Reverts if the replacement token minting to the owner fails.
     * @dev Reverts if the REVV compensation transfer fails.
     * @dev Emits an ERC1155 TransferSingle event for the defective token transfer to the graveyard.
     * @dev Emits an ERC1155 TransferSingle event for the replacement token minting to the owner.
     * @dev Emits an ERC20 Transfer event for the REVV compensation transfer.
     * @dev Emits a RepairedSingle event.
     * @param /operator the address which initiated the transfer (i.e. msg.sender).
     * @param from the address which previously owned the token.
     * @param defectiveToken the id of the token to repair.
     * @param /value the amount of tokens being transferred.
     * @param /data additional data with no specified format.
     * @return bytes4 `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address, /*operator*/
        address from,
        uint256 defectiveToken,
        uint256, /*value*/
        bytes calldata /*data*/
    ) external virtual override whenNotPaused returns (bytes4) {
        require(msg.sender == address(inventoryContract), "RepairCentre: wrong inventory");

        uint256 replacementToken = repairList[defectiveToken];
        require(replacementToken != 0, "RepairCentre: token not defective");
        delete repairList[defectiveToken];

        inventoryContract.safeTransferFrom(address(this), tokensGraveyard, defectiveToken, 1, bytes(""));

        try inventoryContract.mintNonFungible(from, replacementToken, bytes32(""), true)  {} catch {
            inventoryContract.mintNonFungible(from, replacementToken, bytes32(""), false);
        }
        revvContract.transfer(from, revvCompensation);

        emit RepairedSingle(defectiveToken, replacementToken);

        return _ERC1155_RECEIVED;
    }

    /**
     * @notice ERC1155 batch transfer receiver which repairs a batch of tokens and removes them from the repair list.
     * @dev This contract must have been given a minter role for the inventory prior to caslling this function.
     * @dev Reverts if `ids` is an empty array.
     * @dev Reverts if the transfer was not operated through `inventoryContract`.
     * @dev Reverts if `ids` contains an id not in the repair list.
     * @dev Reverts if the defective tokens transfer to the graveyard fails.
     * @dev Reverts if the replacement tokens minting to the owner fails.
     * @dev Reverts if the REVV compensation transfer fails.
     * @dev Emits an ERC1155 TransferBatch event for the defective tokens transfer to the graveyard.
     * @dev Emits an ERC1155 TransferBatch event for the replacement tokens minting to the owner.
     * @dev Emits an ERC20 Transfer event for the REVV compensation transfer.
     * @dev Emits a RepairedBatch event.
     * @param /operator the address which initiated the batch transfer (i.e. msg.sender).
     * @param from the address which previously owned the token.
     * @param defectiveTokens an array containing the ids of the defective tokens to repair.
     * @param values an array containing amounts of each token being transferred (order and length must match _ids array).
     * @param /data additional data with no specified format.
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(
        address, /*operator*/
        address from,
        uint256[] calldata defectiveTokens,
        uint256[] calldata values,
        bytes calldata /*data*/
    ) external virtual override whenNotPaused returns (bytes4) {
        require(msg.sender == address(inventoryContract), "RepairCentre: wrong inventory");

        uint256 length = defectiveTokens.length;
        require(length != 0, "RepairCentre: empty array");

        address[] memory recipients = new address[](length);
        uint256[] memory replacementTokens = new uint256[](length);
        bytes32[] memory uris = new bytes32[](length);
        for (uint256 i = 0; i < length; ++i) {
            uint256 defectiveToken = defectiveTokens[i];
            uint256 replacementToken = repairList[defectiveToken];
            require(replacementToken != 0, "RepairCentre: token not defective");
            delete repairList[defectiveToken];
            recipients[i] = from;
            replacementTokens[i] = replacementToken;
        }

        inventoryContract.safeBatchTransferFrom(address(this), tokensGraveyard, defectiveTokens, values, bytes(""));

        try inventoryContract.batchMint(recipients, replacementTokens, uris, values, true)  {} catch {
            inventoryContract.batchMint(recipients, replacementTokens, uris, values, false);
        }

        revvContract.transfer(from, revvCompensation.mul(length));

        emit RepairedBatch(defectiveTokens, replacementTokens);

        return _ERC1155_BATCH_RECEIVED;
    }

    /*                                             Other Public Functions                                             */

    /**
     * @notice Verifies whether a list of tokens contains a defective token.
     * This function can be used by contracts having logic based on NFTs core attributes, in which case the repair list is a blacklist.
     * @param tokens an array containing the token ids to verify.
     * @return true if the array contains a defective token, false otherwise.
     */
    function containsDefectiveToken(uint256[] calldata tokens) external view returns(bool) {
        for (uint256 i = 0; i < tokens.length; ++i) {
            if (repairList[tokens[i]] != 0) {
                return true;
            }
        } 
        return false;
    }
}

interface IDeltaTimeInventory {
    /**
     * @notice Transfers `value` amount of an `id` from  `from` to `to`  (with safety call).
     * @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
     * MUST revert if `to` is the zero address.
     * MUST revert if balance of holder for token `id` is lower than the `value` sent.
     * MUST revert on any other error.
     * MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
     * After the above conditions are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     * @param from    Source address
     * @param to      Target address
     * @param id      ID of the token type
     * @param value   Transfer amount
     * @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to`
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    /**
     * @notice Transfers `values` amount(s) of `ids` from the `from` address to the `to` address specified (with safety call).
     * @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
     * MUST revert if `to` is the zero address.
     * MUST revert if length of `ids` is not the same as length of `values`.
     * MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids` is lower than the respective amount(s) in `values` sent to the recipient.
     * MUST revert on any other error.
     * MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
     * Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
     * After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     * @param from    Source address
     * @param to      Target address
     * @param ids     IDs of each token type (order and length must match _values array)
     * @param values  Transfer amounts per token type (order and length must match _ids array)
     * @param data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to`
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    /**
     * @dev Public function to mint a batch of new tokens
     * Reverts if some the given token IDs already exist
     * @param to address[] List of addresses that will own the minted tokens
     * @param ids uint256[] List of ids of the tokens to be minted
     * @param uris bytes32[] Concatenated metadata URIs of nfts to be minted
     * @param values uint256[] List of quantities of ft to be minted
     */
    function batchMint(
        address[] calldata to,
        uint256[] calldata ids,
        bytes32[] calldata uris,
        uint256[] calldata values,
        bool safe
    ) external;

    /**
     * @dev Public function to mint one non fungible token id
     * Reverts if the given token ID is not non fungible token id
     * @param to address recipient that will own the minted tokens
     * @param tokenId uint256 ID of the token to be minted
     * @param byteUri bytes32 Concatenated metadata URI of nft to be minted
     */
    function mintNonFungible(
        address to,
        uint256 tokenId,
        bytes32 byteUri,
        bool safe
    ) external;

    /**
     * Removes the minter role for the message sender
     */
    function renounceMinter() external;
}

interface IREVV {
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
}