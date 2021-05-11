/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

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
    constructor () {
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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

interface INFTcontract is IERC1155{
        
    function getAdminOfNFT(uint id) external view returns (address); 
    function getEndTimestamp(uint id) external view returns (uint) ;
    function getSecondaryFee(uint id) external view returns (uint) ;
}
contract NFTMarketplace is Ownable{
    INFTcontract public NFTcontract;
    constructor (address NFTaddr){
        NFTcontract = INFTcontract(NFTaddr);
    }
    function setNFTcontract(address addr) public onlyOwner{
        NFTcontract = INFTcontract(addr);
    }
    struct Order{
        uint64 ethPrice;
        uint64 id;
        uint64 amount;
        bool isBuy;
        address trader;
    }
    Order[] public orders;
    mapping (address => mapping(uint => uint)) public listed;
    function createOrder(uint64 ethPrice, uint64 id, uint64 amount, bool isBuy) public payable{
        if (!isBuy){
            require (listed[msg.sender][id] + amount <= IERC1155(NFTcontract).balanceOf(msg.sender, id), "Not enough NFTs owned");
            listed[msg.sender][id]+=amount;
        }
        require (NFTcontract.getEndTimestamp(id) > block.timestamp, "Ticket expired");
        Order memory newOrder;
        newOrder.ethPrice = ethPrice;
        newOrder.id = id;
        newOrder.amount = amount;
        newOrder.isBuy = isBuy;
        newOrder.trader = msg.sender;
        if (isBuy){
            require (msg.value == ethPrice);
        }
        orders.push(newOrder);
    }
    function matchOrder(uint index, uint64 amount) public payable{
        Order storage order = orders[index];
        require(order.amount >= amount, "Trade amt too high");
        require (order.trader != address(0), "Order doesn't exist");
        require (NFTcontract.getEndTimestamp(order.id) > block.timestamp, "Ticket expired");
        if (order.isBuy){
            order.isBuy = false;
            uint fee = order.ethPrice * NFTcontract.getSecondaryFee(order.id)/100;
            payable(msg.sender).transfer(order.ethPrice - fee);
            payable(NFTcontract.getAdminOfNFT(order.id)).transfer(fee);
            order.amount -= amount;
            NFTcontract.safeTransferFrom(msg.sender, order.trader, order.id, amount, "");
        }
        else
        {
            require(msg.value == order.ethPrice, "Not enough ETH");
            uint fee = order.ethPrice * NFTcontract.getSecondaryFee(order.id)/100;
            payable(order.trader).transfer(order.ethPrice - fee);
            payable(NFTcontract.getAdminOfNFT(order.id)).transfer(fee);
            order.amount -= amount;
            listed[msg.sender][order.id] -= amount;
            NFTcontract.safeTransferFrom(msg.sender, order.trader, order.id, amount, "");
        }
        if (order.amount == 0){
            order.ethPrice = 0;
            order.id = 0;
            order.amount = 0;
            order.trader = address(0);
            order.isBuy = false;
        }
    }
    function cancelOrder(uint index) public payable{
        Order storage order = orders[index];
        require (order.trader == msg.sender);
        if (order.isBuy){
            order.isBuy = false;
            payable(msg.sender).transfer(order.ethPrice);
        }
        else{
            order.isBuy = false;
            listed[msg.sender][order.id] -= order.amount;
        }
        order.ethPrice = 0;
        order.id = 0;
        order.amount = 0;
        order.trader = address(0);
        
    }
}