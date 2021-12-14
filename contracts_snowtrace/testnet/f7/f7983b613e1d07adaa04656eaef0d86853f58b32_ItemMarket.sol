/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-14
*/

// File: @openzeppelin/contracts/utils/Counters.sol



pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol



pragma solidity ^0.8.0;


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

// File: ItemMarket.sol


pragma solidity ^0.8.0;




interface IWAVAX {
    function withdraw(uint wad) external;
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function deposit() external payable;
}

contract ItemMarket is Ownable {

    IERC1155 public itemContract;
    IWAVAX immutable public wavax = IWAVAX(0x6CBF7Ea459b0a8A80614Dd6a184926E1D1285A7f);

    using Counters for Counters.Counter;
    Counters.Counter public orderIdCounter;

    mapping (uint256 => Order[]) public orders;

    struct Order {
        uint128 pricePerItem;
        uint32 quantity;    
        uint32 deadline;    //will break in 2106
        uint32 id;
        bool isBid;         //true for bid, false for ask

        address caller;
    }

    constructor(address _itemContract) {
        itemContract = IERC1155(_itemContract);
    }

    //TODO: support fixing overfilling

    function fillOrder(Order memory _order, uint256 _itemId, uint32 _orderIndex, uint32 _quantity) payable external {
        require(_quantity > 0, "Must fill more than 0");

        Order memory order = orders[_itemId][_orderIndex];
        require(ordersMatch(_order, order), "Invalid order");

        require(order.quantity >= _quantity, "Order would be over-filled");
        require(order.deadline >= block.timestamp, "Order deadline passed");

        //reverts on overflow
        uint256 totalPaid = order.pricePerItem * _quantity;

        address buyer = order.caller;  //the one with $
        address seller = msg.sender; //the one with item

        if (order.isBid) {
            //optional - gas benefit only if this isnt being checked on frontend
            require(wavax.allowance(buyer, address(this)) >= totalPaid, "WAVAX allowance too small");
            require(wavax.balanceOf(buyer) >= totalPaid, "WAVAX balance too small");
        } else {
            require(msg.value == totalPaid, "Value not correct");
            buyer = msg.sender;
            seller = order.caller;
        }

        require(itemContract.balanceOf(seller, _itemId) >= _quantity, "Seller cannot fill order");
        require(itemContract.isApprovedForAll(seller, address(this)), "Market needs Item allowance");

        //if we aren't deleting the order remove quantity sold
        if (order.quantity == _quantity) {
            removeOrder(_itemId, _orderIndex);
        } else {
            orders[_itemId][_orderIndex].quantity -= _quantity;
        }

        if (order.isBid) {
            //TODO: potentially find any asks by order caller and adjust

            //Get WAVAX from bidder
            wavax.transferFrom(order.caller, address(this), totalPaid);
            //Convert to AVAX
            wavax.withdraw(totalPaid);
            
        }

        //Transfer item(s) from seller to buyer
        itemContract.safeTransferFrom(seller, buyer, _itemId, _quantity, "");
        //Payout AVAX for the items
        payable(seller).transfer(totalPaid);

    }

    function addOrder(uint256 _itemId, uint128 _pricePerItem, uint32 _quantity, uint32 _deadline, bool _isBid) external returns(Order memory) {

        if (_isBid) {
            uint256 paid = _pricePerItem*_quantity;
            require(wavax.balanceOf(msg.sender) >= paid, "Doesn't have wavax quantity");
            require(wavax.allowance(msg.sender, address(this)) >= paid, "WAVAX allowance too small");
        } else {
            require(itemContract.balanceOf(msg.sender, _itemId) >= _quantity, "Doesn't have item quantity");
            require(itemContract.isApprovedForAll(msg.sender, address(this)), "Market needs Item allowance");
        }

        //inc order id's so we have unique ids always
        orderIdCounter.increment();

        uint32 _orderId = uint32(orderIdCounter.current());

        Order memory order;
        order.pricePerItem = _pricePerItem;
        order.quantity = _quantity;
        order.deadline = _deadline;
        order.caller = msg.sender;
        order.id = _orderId;
        order.isBid = _isBid;

        orders[_itemId].push(order);
        
        return order;
    }

    function cancelOrder(Order memory _order, uint256 _itemId, uint256 _orderIndex) public {
        Order memory _foundOrder = orders[_itemId][_orderIndex];

        require(ordersMatch(_order, _foundOrder), "Invalid order");
        require(_foundOrder.caller == msg.sender, "Not order owner");

        removeOrder(_itemId, _orderIndex);
    }

    function getOrder(uint256 _itemId, uint32 _orderId) external view returns(uint, Order memory) {
        require(_orderId != 0, "Invalid order");
        Order[] memory _orders = orders[_itemId];
        uint256 len = orders[_itemId].length;

        for (uint i=0; i<len; i++) {
            Order memory _order = _orders[i];
            if (_order.id == _orderId) return (i, _order);
        }

        revert("Order not found");
    }

    function getOrders(uint256 _itemId) external view returns(Order[] memory) {
        return orders[_itemId];
    }

    function removeOrder(uint256 _itemId, uint256 _index) internal {
        uint256 len = orders[_itemId].length;
        require(_index < len, "Invalid index");
        // Move the last element into the place to delete
        orders[_itemId][_index] = orders[_itemId][len - 1];
        // Remove the last element
        orders[_itemId].pop();
    }

    function ordersMatch(Order memory one, Order memory two) internal pure returns(bool) {
        return one.pricePerItem == two.pricePerItem && one.quantity == two.quantity && one.deadline == two.deadline && one.caller == two.caller && one.id == two.id && one.isBid == two.isBid;
    }

    receive() external payable {}
    fallback() external payable {}

}