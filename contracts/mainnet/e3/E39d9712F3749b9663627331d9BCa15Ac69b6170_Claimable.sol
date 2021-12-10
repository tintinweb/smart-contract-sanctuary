/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: WTFPL

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



interface IAdapter {
    struct Call {
        address target;
        bytes callData;
    }

    function outputTokens(address inputToken) external view returns (address[] memory outputs);

    function encodeMigration(address _genericRouter, address _strategy, address _lp, uint256 _amount)
        external view returns (Call[] memory calls);

    function encodeWithdraw(address _lp, uint256 _amount) external view returns (Call[] memory calls);

    function buy(address _lp, address _exchange, uint256 _minAmountOut, uint256 _deadline) external payable;

    function getAmountOut(address _lp, address _exchange, uint256 _amountIn) external returns (uint256);

    function isWhitelisted(address _token) external view returns (bool);
}



interface ILiquidityMigration {
    function adapters(address _adapter) external view returns (bool);
    function hasStaked(address _account, address _lp) external view returns (bool);
}
















/**
 * _Available since v3.1._
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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


interface IRoot1155 is IERC1155 {
    function getMaxTokenID() external view returns(uint256);
    function burn(address account, uint256 id, uint256 value) external;
}



contract Claimable is Ownable, ERC1155Holder {
    enum State {
        Pending,
        Active,
        Closed
    }
    State private _state;

    uint256 public max;
    address public migration;
    address public collection;

    mapping (address => uint256) public index;
    mapping (address => mapping (uint256 => bool)) public claimed;

    event Claimed(address indexed account, uint256 protocol);
    event StateChange(uint8 changed);
    event Migration(address migration);
    event Collection(address collection);

    /**
    * @dev Require particular state
    */
    modifier onlyState(State state_) {
        require(state() == state_, "Claimable#onlyState: ONLY_STATE_ALLOWED");
        _;
    }

    /* assumption is enum ID will be the same as collection ID,
     * and no further collections will be added whilst active
    */
    constructor(address _migration, address _collection, uint256 _max, address[] memory _index){
        require(_max == _index.length, "Claimable#claim: incorrect max");
        collection = _collection;
        migration = _migration;
        max = _max;
        for (uint256 i = 0; i < _index.length; i++) {
            if (i > 0) {
                require(_index[i] != _index[0] && index[_index[i]] == 0,  "Claimable#constructor: duplicate adapter");
            }
            index[_index[i]] = i;
        }
    }

    /**
     * @notice claim NFT for staking LP
     * @param _lp address of lp
     * @param _adapter address of adapter
     */
    function claim(address _lp, address _adapter)
        public
        onlyState(State.Active)
    {
        require(_lp != address(0), "Claimable#claim: empty address");
        require(_adapter != address(0), "Claimable#claim: empty address");

        require(ILiquidityMigration(migration).adapters(_adapter), "Claimable#claim: not adapter");
        require(IAdapter(_adapter).isWhitelisted(_lp), "Claimable#claim: not associated");
        require(ILiquidityMigration(migration).hasStaked(msg.sender, _lp), "Claimable#claim: not staked");

        uint256 _index = index[_adapter];
        require(!claimed[msg.sender][_index], "Claimable#claim: already claimed");

        require(IERC1155(collection).balanceOf(address(this), _index) > 0, "Claimable#claim: no NFTs left");

        claimed[msg.sender][_index] = true;
        IERC1155(collection).safeTransferFrom(address(this), msg.sender, _index, 1, "");
        emit Claimed(msg.sender, _index);
    }

    /**
     * @notice you wanna be a masta good old boi?
     */
    function master()
        public
        onlyState(State.Active)
    {
        require(!claimed[msg.sender][max], "Claimable#master: claimed");
        for (uint256 i = 0; i < max; i++) {
            require(claimed[msg.sender][i], "Claimable#master: not all");
            require(IERC1155(collection).balanceOf(msg.sender, i) > 0, "Claimable#master: not holding");
        }
        claimed[msg.sender][max] = true;
        IERC1155(collection).safeTransferFrom(address(this), msg.sender, max, 1, "");
        emit Claimed(msg.sender, max);
    }

    /**
     * @notice claim all through range
     * @param _lp[] array of lp addresses
     * @param _adapter[] array of adapter addresses
     */

    function claimAll(address[] memory _lp, address[] memory _adapter)
        public
    {
        require(_lp.length <= max, "Claimable#claimAll: incorrect length");
        require(_lp.length == _adapter.length, "Claimable#claimAll: incorrect len");
        for (uint256 i = 0; i < _lp.length; i++) {
            claim(_lp[i], _adapter[i]);
        }
    }

    /**
     * @notice we wipe it, and burn all - should have got in already
     */
    function wipe(uint256 _start, uint256 _end)
        public
        onlyOwner
    {
        require(_start < _end, "Claimable#Wipe: range out");
        require(_end <= max, "Claimable#Wipe: out of bounds");
        for (uint256 start = _start; start <= _end; start++) {
            IRoot1155(collection).
            burn(
                address(this),
                start,
                IERC1155(collection).balanceOf(address(this), start)
            );
        }
    }

    /**
     * @notice emergency from deployer change state
     * @param state_ to change to
     */
    function stateChange(State state_)
        public
        onlyOwner
    {
        _stateChange(state_);
    }

    /**
     * @notice emergency from deployer change migration
     * @param _migration to change to
     */
    function updateMigration(address _migration)
        public
        onlyOwner
    {
        require(_migration != migration, "Claimable#UpdateMigration: exists");
        migration = _migration;
        emit Migration(migration);
    }

    /**
     * @notice emergency from deployer change migration
     * @param _collection to change to
     */
    function updateCollection(address _collection)
        public
        onlyOwner
    {
        require(_collection != collection, "Claimable#UpdateCollection: exists");
        collection = _collection;
        emit Collection(collection);
    }

    /**
     * @return current state.
     */
    function state() public view virtual returns (State) {
        return _state;
    }

    function _stateChange(State state_)
        private
    {
        require(_state != state_, "Claimable#changeState: current");
        _state = state_;
        emit StateChange(uint8(_state));
    }
}