/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

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

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint tokenId) external view returns (address owner);

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
    function safeTransferFrom(address from, address to, uint tokenId) external;

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
    function transferFrom(address from, address to, uint tokenId) external;

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
    function approve(address to, uint tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint tokenId) external view returns (address operator);

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
    function safeTransferFrom(address from, address to, uint tokenId, bytes calldata data) external;
}

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
    function onERC721Received(address operator, address from, uint tokenId, bytes calldata data) external returns (bytes4);
}

interface IEpicHeroNFT is IERC721{
    function getHero(uint heroId) external view returns (uint8 level, uint8 rarity);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

library Counters {
    struct Counter {
        uint _value; // default: 0
    }
    function current(Counter storage counter) internal view returns (uint) {
        return counter._value;
    }
    function increment(Counter storage counter) internal {
    unchecked {
        counter._value += 1;
    }
    }
    function decrement(Counter storage counter) internal {
        uint value = counter._value;
        require(value > 0, "Counter: decrement overflow");
    unchecked {
        counter._value = value - 1;
    }
    }
}

library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

abstract contract ReentrancyGuard {
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

    constructor() {
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

abstract contract Auth {
    address owner;
    mapping (address => bool) private authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender)); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender)); _;
    }

    function authorize(address adr) public authorized {
        authorizations[adr] = true;
        emit Authorized(adr);
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
        emit Unauthorized(adr);
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
    event Authorized(address adr);
    event Unauthorized(address adr);
}

contract Marketplace is IERC721Receiver, Auth , ReentrancyGuard{
    using SafeMath for uint256;

    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    Counters.Counter private _tradeCounter;
    EnumerableSet.UintSet private openTrades;

    enum TradeStatus {
        Open, Closed, Cancelled
    }

    struct Trade {
        uint24 id;
        uint24 tokenId;
        TradeStatus status; // 8 bits
        uint200 tokenPrice; // 256 bits total
        address poster;
        address buyer;
    }

    Trade[] trades;
    mapping(uint24 => mapping(address => uint200)) public heroesWithOffers;

    mapping(uint8 => uint200) public minPriceAtRarity;
    uint8 public minRarity = 3;

    uint public tradeFee = 500;
    uint public wbnbReflectRewardsFee = 500;
    uint public swapTokensAtAmount = 100000 * 10 ** 18;

    address public wbnbReflectToken = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public wbnbReflectTracker = 0x09eAf2a4bcE29796EE380Aae6a3D23B817Ad67EB;

    address public feeWallet = 0xb7497Bb4dEC6b4Be62f77dBdEb90F4E179d8fcFe;
    address public tokenAddress = 0x580dE58c1BD593A43DaDcF0A739d504621817c05;
    address public nftAddress = 0xafDcB0eCaD1c8Cb22893dCA7D6c510dBFDa3BBeC;

    IERC20 private token;
    IEpicHeroNFT private nftContract;
    IDEXRouter public dexRouter;

    constructor() Auth(msg.sender) {
        token = IERC20(tokenAddress);
        nftContract = IEpicHeroNFT(nftAddress);

        dexRouter = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        setMinPriceAtRarity(0, 5000 * 10 ** 18);
        setMinPriceAtRarity(1, 10000 * 10 ** 18);
        setMinPriceAtRarity(2, 20000 * 10 ** 18);
        setMinPriceAtRarity(3, 40000 * 10 ** 18);
        setMinPriceAtRarity(4, 80000 * 10 ** 18);
        setMinPriceAtRarity(5, 160000 * 10 ** 18);
        setMinPriceAtRarity(6, 320000 * 10 ** 18);
        setMinPriceAtRarity(7, 640000 * 10 ** 18);
    }

    function getTrade(uint tradeId) external view returns (Trade memory) {
        return trades[tradeId];
    }

    function getAllTrades() external view returns (Trade[] memory) {
        return trades;
    }

    /**
     * Can fail if passing callstack limits. Use getOpenTradesSlice() if needed.
     */
    function getOpenTrades() external view returns (Trade[] memory) {
        Trade[] memory _openTrades = new Trade[](openTrades.length());
        for (uint i = 0; i < openTrades.length(); i++) {
            _openTrades[i] = trades[openTrades.at(i)];
        }
        return _openTrades;
    }

    function getOpenTradesSlice(uint start, uint end) external view returns (Trade[] memory) {
        Trade[] memory _openTrades = new Trade[](openTrades.length());
        for (uint i = start; i < end; i++) {
            _openTrades[i] = trades[openTrades.at(i)];
        }
        return _openTrades;
    }

    function getOpenTradesLength() external view returns (uint) {
        return openTrades.length();
    }

    function getTradeCount() public view returns (uint) {
        return _tradeCounter.current();
    }

    function openTrade(uint24 tokenId, uint200 price) external {
        (, uint8 rarity) = nftContract.getHero(tokenId);
        uint200 minPrice = minPriceAtRarity[rarity];

        require(rarity >= minRarity, "!minRarity");
        require(price >= minPrice,"!minPrice");

        uint24 id = uint24(_tradeCounter.current());
        _tradeCounter.increment();
        openTrades.add(id);

        trades.push(Trade({
        id: id,
        poster: msg.sender,
        tokenId: tokenId,
        tokenPrice: price,
        status: TradeStatus.Open,
        buyer: address(0)
        }));

        assert(trades.length == _tradeCounter.current());

        nftContract.safeTransferFrom(msg.sender, address(this), tokenId);

        emit TradeOpened(id, msg.sender, tokenId, price);
    }

    function executeTrade(uint tradeId) external nonReentrant {
        Trade memory trade = trades[tradeId];
        require(trade.status == TradeStatus.Open, "Trade status must be open.");

        trades[tradeId].status = TradeStatus.Closed;
        trades[tradeId].buyer = msg.sender;
        openTrades.remove(tradeId);

        require(token.transferFrom(msg.sender, address(this), trade.tokenPrice), "Fee transfer failed.");

        _commitTrade(trade.tokenId, trade.poster, msg.sender, trade.tokenPrice);

        emit TradeClosed(tradeId, trade.poster, msg.sender, trade.tokenId, trade.tokenPrice);
    }

    function cancelTrade(uint tradeId) external nonReentrant{
        Trade memory trade = trades[tradeId];
        require(msg.sender == trade.poster, "Only the poster of a trade can cancel it.");
        require(trade.status == TradeStatus.Open, "The trade has to be open to be cancelled.");

        trades[tradeId].status = TradeStatus.Cancelled;
        openTrades.remove(tradeId);

        nftContract.safeTransferFrom(address(this), trade.poster, trade.tokenId);

        emit TradeCancelled(tradeId, trade.poster, trade.tokenId, trade.tokenPrice);
    }

    function _commitTrade(uint tokenId, address seller, address buyer, uint200 price) internal {
        uint totalFee = (price * (tradeFee + wbnbReflectRewardsFee)) / 10000;

        require(token.transfer(seller, price - totalFee), "Token transfer failed.");

        nftContract.safeTransferFrom(seller, buyer, tokenId);

        if (tradeFee + wbnbReflectRewardsFee > 0) {
            uint256 contractTokenBalance = token.balanceOf(address(this));

            if(contractTokenBalance >= swapTokensAtAmount){
                uint tokenFee = (contractTokenBalance * tradeFee) / (tradeFee + wbnbReflectRewardsFee);

                if (tokenFee > 0) {
                    require(token.transfer(feeWallet, tokenFee), "Fee transfer failed.");
                }

                uint rewardFee = contractTokenBalance - tokenFee;

                if (rewardFee > 0) {
                    _swapAndSendWbnbReflects(rewardFee);
                }
            }
        }
    }

    function openOffer(uint24 tokenId, uint200 offerValue) external nonReentrant {
        (, uint8 rarity) = nftContract.getHero(tokenId);
        uint200 minPrice = minPriceAtRarity[rarity];

        require(rarity >= minRarity, "!minRarity");
        require(offerValue >= minPrice,"!minPrice");

        address buyer = msg.sender;
        address seller = nftContract.ownerOf(tokenId);

        uint currentOffer = heroesWithOffers[tokenId][buyer];
        bool needRefund = offerValue < currentOffer;
        uint requiredValue = needRefund ? 0 : offerValue - currentOffer;

        require(buyer != seller, "Owner cannot offer");
        require(offerValue != currentOffer, "Same offer");

        if(requiredValue > 0){
            require(token.transferFrom(buyer, address(this), requiredValue), "Offer transfer failed.");
        }

        if (needRefund) {
            uint returnedValue = currentOffer - offerValue;

            require(token.transfer(buyer, returnedValue), "Return transfer failed.");
        }

        heroesWithOffers[tokenId][buyer] = offerValue;

        emit OfferOpened(tokenId, seller, buyer, offerValue);
    }

    function takeOffer(uint24 tokenId, address buyer) external nonReentrant {
        require(nftContract.ownerOf(tokenId) == msg.sender, "!Owner");

        uint200 offeredValue = heroesWithOffers[tokenId][buyer];
        address seller = msg.sender;

        require(buyer != seller, "Cannot buy your own Hero");

        heroesWithOffers[tokenId][buyer] = 0;

        _commitTrade(tokenId, seller, buyer, offeredValue);

        emit OfferTaken(tokenId, seller, buyer, offeredValue);
    }

    function cancelOffer(uint24 tokenId) external nonReentrant {
        address sender = msg.sender;
        uint offerValue = heroesWithOffers[tokenId][sender];

        require(offerValue > 0, "No offer found");

        heroesWithOffers[tokenId][sender] = 0;

        require(token.transfer(sender, offerValue), "Return transfer failed.");

        emit OfferCanceled(tokenId, sender);
    }

    function setTradeFee(uint newFee) public onlyOwner {
        require(newFee < 10000, "Invalid newFee");
        tradeFee = newFee;
    }

    function setMinRarity(uint8 rarity) public onlyOwner {
        minRarity = rarity;
    }

    function setMinPriceAtRarity(uint8 rarity, uint200 minPrice) public onlyOwner{
        minPriceAtRarity[ rarity ] = minPrice;
    }

    function setSwapTokensAtAmount(uint256 _swapAmount) external onlyOwner {
        swapTokensAtAmount = _swapAmount;
    }

    function setWbnbReflectToken(address _newContract) public onlyOwner {
        wbnbReflectToken = _newContract;
    }

    function setWbnbReflectTracker(address _newContract) public onlyOwner {
        wbnbReflectTracker = _newContract;
    }

    function setWbnbReflectRewardsFee(uint256 newFee) external onlyOwner {
        require(newFee < 10000, "Invalid newFee");
        wbnbReflectRewardsFee = newFee;
    }

    function setDexRouter(address newAddress) external onlyOwner {
        dexRouter = IDEXRouter(newAddress);
    }

    function retrieveTokens(address _token, uint amount) external onlyOwner {
        uint balance = IERC20(_token).balanceOf(address(this));

        if(amount > balance){
            amount = balance;
        }

        require(IERC20(_token).transfer(msg.sender, amount), "Transfer failed");
    }

    function retrieveBNB(uint amount) external onlyOwner{
        uint balance = address(this).balance;

        if(amount > balance){
            amount = balance;
        }

        (bool success,) = payable(msg.sender).call{ value: amount }("");
        require(success, "Failed");
    }

    /**
     * Emergency function, breaks marketplace state
     */
    function emergencyReturnNfts() external authorized {
        for (uint i = 0; i < openTrades.length(); i++) {
            Trade memory trade = trades[openTrades.at(i)];
            if (trade.status == TradeStatus.Open) {
                nftContract.safeTransferFrom(address(this), trade.poster, trade.tokenId);
            }
        }
    }

    function onERC721Received(address, address, uint, bytes calldata) public pure override returns (bytes4) {
        return 0x150b7a02;
    }

    function _swapTokensForDividendToken(uint256 _tokenAmount, address _recipient, address _dividendAddress) private {
        address[] memory path;

        if(dexRouter.WETH() == _dividendAddress){
            path = new address[](2);
            path[0] = tokenAddress;
            path[1] = _dividendAddress;
        }else{
            path = new address[](3);
            path[0] = tokenAddress;
            path[1] = dexRouter.WETH();
            path[2] = _dividendAddress;
        }

        token.approve(address(dexRouter), _tokenAmount);

        dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            _recipient,
            block.timestamp.add(300)
        );
    }

    function _swapAndSendWbnbReflects(uint256 tokens) private {
        uint256 beforeAmount = IERC20(wbnbReflectToken).balanceOf(address(wbnbReflectTracker));

        _swapTokensForDividendToken(tokens, address(wbnbReflectTracker), wbnbReflectToken);

        uint256 wbnbDividends = IERC20(wbnbReflectToken).balanceOf(address(wbnbReflectTracker)).sub(beforeAmount);

        if(wbnbDividends > 0){
            emit SendWbnbDividends(wbnbDividends);
        }
    }

    event TradeOpened(uint tradeId, address indexed seller, uint indexed tokenId, uint price);
    event TradeClosed(uint tradeId, address indexed seller, address indexed buyer, uint indexed tokenId, uint price);
    event TradeCancelled(uint tradeId, address indexed seller, uint indexed tokenId, uint price);
    event SendWbnbDividends(uint256 amount);

    event OfferOpened(uint indexed tokenId, address seller, address buyer, uint price);
    event OfferTaken(uint indexed tokenId, address seller, address buyer, uint price);
    event OfferCanceled(uint indexed tokenId, address sender);
}