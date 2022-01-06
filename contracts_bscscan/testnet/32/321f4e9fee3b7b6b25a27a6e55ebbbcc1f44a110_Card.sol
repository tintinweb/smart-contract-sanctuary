/**
 *Submitted for verification at BscScan.com on 2022-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

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

        if (valueIndex != 0) {// Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1;
            // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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
}

library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {// Equivalent to !contains(map, key)
            map._entries.push(MapEntry({_key : key, _value : value}));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {// Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1;
            // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage);
        // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value;
        // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

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

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function decimals() external view returns (uint256);
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}


contract Card is IERC721Receiver {
    using SafeMath for uint256;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Material {
        uint64 crystal;
        uint64 gene;
        uint64 boom;
        uint64 life;
    }

    struct SaleOrder {
        uint8 mType;
        uint64 num;
        uint128 index;
        uint256 price;
    }

    struct DayRest {
        uint16 times;
        uint64 point;
        uint256 amount;
    }

    bytes32 public constant UPDATE_TOKEN_URI_ROLE = keccak256('UPDATE_TOKEN_URI_ROLE');
    bytes32 public constant PAUSED_ROLE = keccak256('PAUSED_ROLE');
    uint256 public nextTokenId = 1;
    uint256 public lottery;
    uint256 public price;
    uint256 public ticket = 300000000;
    uint256 public lifePrice = 150;
    uint256 private day;
    uint256 public long = 600;

    address private first;
    address private owner;

    IERC20 private usdt;
    IERC20 private nftf;
    IERC721Enumerable private nft;
    EnumerableMap.UintToAddressMap private _asksMap;

    mapping(uint256 => uint8) _idLevel;
    mapping(uint256 => uint256) _tokenLife;
    mapping(uint256 => bool) _tokenRest;
    mapping(uint256 => bool) _tokenUsed;
    mapping(uint256 => uint256) _tokenRestDay;
    mapping(uint256 => uint256) _startRestTime;
    mapping(uint256 => uint256) _lifeTimes;
    mapping(uint256 => mapping(uint256 => DayRest)) _tokenDayInfo;

    mapping(address => bool) _play;
    mapping(address => uint256) _rewards;
    mapping(address => uint256) _userBox;
    mapping(address => address) _superUser;
    mapping(address => Material) _materials;

    mapping(address => EnumerableSet.UintSet) private _userSellingOrders;
    SaleOrder[] _orders;

    event RestTake(uint256 tokenId, uint16 times);
    event BuyMaterial(uint256 price, uint8 mType);

    constructor(
        address _first,
        address _usdt,
        address _nftf,
        address _nft
    ) public {
        first = _first;
        usdt = IERC20(_usdt);
        nftf = IERC20(_nftf);
        nft = IERC721Enumerable(_nft);
        price = 200 * 10 ** usdt.decimals();
        owner = msg.sender;
    }

    modifier onlyActivate() {
        require(first == msg.sender || _superUser[msg.sender] != address(0), "Not activate");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do this");
        _;
    }

    // 是否激活
    function isActivate(address account) public view returns (bool){
        return _superUser[account] != address(0) || account == first;
    }

    // 激活
    function activate(address superAddress) public {
        require(isActivate(superAddress), "Super address not activate");
        _superUser[msg.sender] = superAddress;
    }

    // 用户的材料
    function materialOf(address account) public view returns (Material memory){
        return _materials[account];
    }

    // 用户的盲盒
    function boxOf(address account) public view returns (uint256){
        return _userBox[account];
    }

    // 等级
    function levelOf(uint256 tokenId) public view returns (uint8){
        return _idLevel[tokenId];
    }

    // 上次的续命时间
    function tokenLifeOf(uint256 tokenId) public view returns (uint256){
        return _tokenLife[tokenId];
    }

    // 使用续命丹的次数
    function lifeTimesOf(uint256 tokenId) public view returns (uint256){
        return _lifeTimes[tokenId];
    }

    // 是否在匹配中
    function playOf(address account) public view returns (bool){
        return _play[account];
    }

    // 购买盲盒
    function buyBox() public onlyActivate {
        uint256 balance = nft.balanceOf(address(this));
        require(balance > 0, "Not enough box");
        require(_userBox[msg.sender] == 0, "Already have box");
        uint256 totalReward = _rewardCal(msg.sender);
        uint256 tempLottery = price.mul(5).div(100);
        usdt.transferFrom(msg.sender, first, price.sub(totalReward).sub(tempLottery));
        usdt.transferFrom(msg.sender, address(this), totalReward.add(tempLottery));
        lottery = lottery.add(tempLottery);
        _rewardSuper(msg.sender);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = nft.tokenOfOwnerByIndex(address(this), i);
            if (_tokenUsed[tokenId] == false) {
                _userBox[msg.sender] = tokenId;
                _tokenUsed[tokenId] = true;
                break;
            }
        }
    }

    // 打开盲盒
    function openBox() public onlyActivate {
        require(_userBox[msg.sender] != 0, "Have no box");
        nft.transferFrom(address(this), msg.sender, _userBox[msg.sender]);
        _tokenLife[_userBox[msg.sender]] = block.timestamp;
        _userBox[msg.sender] = 0;
    }

    // 水晶合成
    function mix(uint64 num) public onlyActivate {
        require(num > 0, "Not zero");
        num = num / 10 * 10;
        require(_materials[msg.sender].crystal >= num, "Not enough crystal");
        _materials[msg.sender].crystal -= num;
        _materials[msg.sender].gene += num / 10;
    }

    // 材料挂售
    function readyToSell(uint8 mType, uint64 num, uint128 _price) public onlyActivate {
        require(mType <= 3 && mType >= 1, "Wrong type");
        uint128 balance;
        if (mType == 1) {
            balance = _materials[msg.sender].crystal;
            require(balance >= num, "Balance not enough");
            _materials[msg.sender].crystal -= num;
        } else if (mType == 2) {
            balance = _materials[msg.sender].gene;
            require(balance >= num, "Balance not enough");
            _materials[msg.sender].gene -= num;
        } else {
            balance = _materials[msg.sender].boom;
            require(balance >= num, "Balance not enough");
            _materials[msg.sender].boom -= num;
        }
        _asksMap.set(_orders.length, msg.sender);
        _userSellingOrders[msg.sender].add(_orders.length);
        _orders.push(SaleOrder(mType, num, uint128(_orders.length), _price));
    }

    // 取消挂售
    function cancelSell(uint256 orderIndex) public onlyActivate {
        require(orderIndex < _orders.length, "Index error");
        require(_userSellingOrders[msg.sender].contains(orderIndex), "Only Seller can cancel sell");
        _asksMap.remove(orderIndex);
        _userSellingOrders[msg.sender].remove(orderIndex);
        SaleOrder memory order = _orders[orderIndex];
        if (order.mType == 1) {
            _materials[msg.sender].crystal += order.num;
        } else if (order.mType == 2) {
            _materials[msg.sender].gene += order.num;
        } else {
            _materials[msg.sender].boom += order.num;
        }
    }

    // 订单的卖家
    function orderSellerOf(uint256 orderIndex) public view returns (address){
        return _asksMap.get(orderIndex);
    }

    // 购买材料
    function buyMaterial(uint256 orderIndex) public onlyActivate {
        require(_asksMap.contains(orderIndex), "Order not on sale");
        SaleOrder memory order = _orders[orderIndex];
        address seller = _asksMap.get(orderIndex);
        uint256 fee = order.price.mul(10).div(100);
        uint256 get = order.price.sub(fee);
        nftf.transferFrom(msg.sender, address(this), fee);
        nftf.transferFrom(msg.sender, seller, get);
        if (order.mType == 1) {
            _materials[msg.sender].crystal += order.num;
        } else if (order.mType == 2) {
            _materials[msg.sender].gene += order.num;
        } else {
            _materials[msg.sender].boom += order.num;
        }
        _asksMap.remove(orderIndex);
        _userSellingOrders[seller].remove(orderIndex);
        emit BuyMaterial(order.price / order.num, order.mType);
    }

    // 获取所有挂卖单
    function getAllOrder() public view returns (SaleOrder[] memory){
        SaleOrder[] memory so = new SaleOrder[](_asksMap.length());
        for (uint256 i = 0; i < _asksMap.length(); ++i) {
            (uint256 orderIndex,) = _asksMap.at(i);
            so[i] = _orders[orderIndex];
        }
        return so;
    }

    // 获取用户的挂卖单
    function getOrderByUser(address user) public view returns (SaleOrder[] memory) {
        SaleOrder[] memory so = new SaleOrder[](_userSellingOrders[user].length());
        for (uint256 i = 0; i < _userSellingOrders[user].length(); ++i) {
            uint256 orderIndex = _userSellingOrders[user].at(i);
            so[i] = _orders[orderIndex];
        }
        return so;
    }

    // 推荐奖励数量
    function rewardOf(address account) public view returns (uint256){
        return _rewards[account];
    }

    // 领取推荐奖励
    function rewardTake() public onlyActivate {
        require(_rewards[msg.sender] > 0, "No reward");
        usdt.transfer(msg.sender, _rewards[msg.sender]);
        _rewards[msg.sender] = 0;
    }

    // 基因改造
    function geneChange(uint256 tokenId, bool boom) public onlyActivate {
        require(nft.ownerOf(tokenId) == msg.sender, "Token not belong to you");
        require(_materials[msg.sender].gene > 0, "Crystal not enough");
        if (boom) {
            require(_materials[msg.sender].boom > 0, "Boom not enough");
        }
        _materials[msg.sender].gene -= 1;
        if (boom) {
            _materials[msg.sender].boom--;
        }
    }

    // 参与游戏,匹配
    function play(uint256[] memory tokenIds) public onlyActivate {
        require(tokenIds.length == 3, "Must select 3 token");
        require(nft.balanceOf(msg.sender) >= 3, "Not enough tokens");
        require(_play[msg.sender] == false, "Playing");
        if (tokenIds[0] == tokenIds[1] || tokenIds[1] == tokenIds[2] || tokenIds[0] == tokenIds[2]) {
            revert("Repeat select");
        }
        if (nft.ownerOf(tokenIds[0]) != msg.sender || nft.ownerOf(tokenIds[1]) != msg.sender || nft.ownerOf(tokenIds[2]) != msg.sender) {
            revert("Token not belong to you");
        }
        if (_tokenRest[tokenIds[0]] || _tokenRest[tokenIds[1]] || _tokenRest[tokenIds[2]]) {
            revert("Token rested");
        }
        //        if (_tokenLife[tokenIds[0]] == 0 || _tokenLife[tokenIds[1]] == 0 || _tokenLife[tokenIds[2]] == 0) {
        //            revert("Life not enough");
        //        }
        nftf.transferFrom(msg.sender, address(this), ticket * 10 ** nftf.decimals());
        _play[msg.sender] = true;
    }


    // 购买续命丹
    function buyLife(uint64 num) public onlyActivate {
        usdt.transferFrom(msg.sender, first, lifePrice * num * 10 ** usdt.decimals());
        _materials[msg.sender].life += num;
    }

    // 使用续命丹
    function useLife(uint256 tokenId) public onlyActivate {
        require(nft.ownerOf(tokenId) == msg.sender, "Token not belong to you");
        require(_materials[msg.sender].life > 0, "Life not enough");
        _tokenLife[tokenId] = block.timestamp;
        _materials[msg.sender].life--;
        _lifeTimes[tokenId] += 1;
    }

    // 查看今日的上次投喂时间
    function lastRestTime(uint256 tokenId) public view returns (uint64){
        return _tokenDayInfo[tokenId][day].point;
    }

    // 查看今日的投喂次数
    function restTimes(uint256 tokenId) public view returns (uint16){
        return _tokenDayInfo[tokenId][day].times;
    }

    // 查看英雄是否在修养中
    function restStatus(uint256 tokenId) public view returns (bool){
        return _tokenRest[tokenId];
    }

    // 起始投喂时间
    function restStartOf(uint256 tokenId) public view returns (uint256){
        return _startRestTime[tokenId];
    }

    // 投喂
    function rest(uint256 tokenId) public onlyActivate {
        require(nft.ownerOf(tokenId) == msg.sender, "Token not belong to you");
        require(block.timestamp.sub(_tokenLife[tokenId]) < 45 * 86400, "Please remain token life");
        require(block.timestamp % 3600 >= 0 && block.timestamp % 3600 <= long, "Wrong time");
        DayRest memory info = _tokenDayInfo[tokenId][day];
        if (info.times != 0) {
            require(block.timestamp - info.point <= 3900, "Must rest continuous");
        }
        nftf.transferFrom(msg.sender, address(this), 10 * 10 ** 8 * 10 ** nftf.decimals());
        _tokenDayInfo[tokenId][day].times++;
        _tokenDayInfo[tokenId][day].point = uint64(block.timestamp);
        _tokenDayInfo[tokenId][day].amount += 92 * 10 ** 7 * 10 ** nftf.decimals();
        if (_tokenRest[tokenId] == false) {
            _tokenRest[tokenId] = true;
            _tokenRestDay[tokenId] = day;
            _startRestTime[tokenId] = block.timestamp;
        }
    }

    // 查询锁定的金额
    function restAmount(uint256 tokenId) public view returns (uint256, uint16){
        if (!_tokenRest[tokenId]) {
            return (0, 0);
        }
        uint256 balance;
        uint256 total;
        uint16 totalTimes;
        uint256 startDay = _tokenRestDay[tokenId];
        for (; startDay <= day; startDay++) {
            balance = balance.add(_tokenDayInfo[tokenId][startDay].amount);
            total = _dayRate(tokenId, startDay, total);
            totalTimes += _tokenDayInfo[tokenId][startDay].times;
        }
        uint256 dura = day.sub(_tokenRestDay[tokenId]);
        uint256 rate;
        if (dura <= 10) {
            rate = 20;
        } else if (dura >= 11 && dura <= 14) {
            rate = 10;
        }
        uint256 subIncome = total.sub(balance).mul(rate).div(100);
        total = total.sub(subIncome);
        return (total, totalTimes);
    }


    // 提取休养生息的nftf
    function restTake(uint256 tokenId) public onlyActivate {
        require(nft.ownerOf(tokenId) == msg.sender, "Token not belong to you");
        (uint256 amount,uint16 times) = restAmount(tokenId);
        require(amount > 0, "Amount must great than zero");
        nftf.transfer(msg.sender, amount);
        _tokenRest[tokenId] = false;
        _tokenRestDay[tokenId] = day;
        _tokenDayInfo[tokenId][day].amount = 0;
        _tokenDayInfo[tokenId][day].times = 0;
        _tokenDayInfo[tokenId][day].point = 0;
        emit RestTake(tokenId, times);
    }

    // 游戏结算
    function settle(address winner, address loser) public onlyOwner {
        nftf.transfer(winner, ticket.mul(2).mul(92).div(100).mul(7).div(10) * 10 ** nftf.decimals());
        nftf.transfer(loser, ticket.mul(2).mul(92).div(100).mul(3).div(10) * 10 ** nftf.decimals());
        _play[winner] = false;
        _play[loser] = false;
    }

    // 掉落水晶
    function addCrystal(address account, uint64 num) public onlyOwner {
        _materials[account].crystal += num;
    }

    // 掉落防爆卡
    function addBoom(address account, uint64 num) public onlyOwner {
        _materials[account].boom += num;
    }

    // 乐透大奖
    function prizes(address[] memory top5, uint8[] memory index) public onlyOwner {
        require(top5.length == 5, "Top5 must eq 5");
        uint8 sum = 0;
        for (uint i = 0; i < index.length; i++) {
            sum = index[i] + sum;
        }
        uint256 use;
        for (uint i = 0; i < 4; i++) {
            usdt.transfer(top5[i], (lottery * index[i]) / sum);
            use = use.add((lottery * index[i]) / sum);
        }
        usdt.transfer(top5[4], lottery.sub(use));
        lottery = 0;
    }

    // 同步等级
    function syncLevel(uint256 tokenId, uint8 level) public onlyOwner {
        require(level != 0, "Can't set level to zero");
        require(_tokenLife[tokenId] > 0, "Wrong token id");
        _idLevel[tokenId] = level;
    }

    // 天数增长
    function addDay() public onlyOwner {
        day = day + 1;
    }

    // 修改门票价格
    function setTicket(uint256 _ticket) public onlyOwner {
        ticket = _ticket;
    }

    // 修改续命丹的价格
    function setLifePrice(uint256 _price) public onlyOwner {
        lifePrice = _price;
    }

    // 设置盲盒价格
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setLong(uint256 _long) public onlyOwner {
        long = _long;
    }

    function _dayRate(uint256 tokenId, uint256 _day, uint256 _lastAmount) private view returns (uint256){
        uint8 level = _idLevel[tokenId];
        DayRest memory dr = _tokenDayInfo[tokenId][_day];
        uint8 rate;
        if (dr.times <= 0) {
            return _lastAmount;
        }
        if (dr.times >= 1 && dr.times <= 3) {
            rate = 10;
        } else if (dr.times >= 4 && dr.times <= 6) {
            rate = 20;
        } else if (dr.times >= 7 && dr.times <= 10) {
            rate = 30;
        } else if (dr.times >= 11 && dr.times <= 15) {
            rate = 50;
        } else if (dr.times >= 16 && dr.times <= 23) {
            rate = 70;
        } else {
            rate = 80;
        }
        return _lastAmount.add(dr.amount).mul(rate + level * 5).div(1000);
    }

    function _rewardCal(address account) private view returns (uint256){
        uint8 i;
        address _sup = _superUser[account];
        uint256 _totalRe;
        uint8[10] memory rates = [10, 4, 3, 2, 1, 1, 1, 1, 1, 1];
        while (i < 10 && _sup != address(0)) {
            if (nft.balanceOf(_sup) >= 3) {
                _totalRe = _totalRe.add(price.mul(rates[i]).div(100));
            }
            i++;
            _sup = _superUser[_sup];
        }
        return _totalRe;
    }

    function _rewardSuper(address account) private {
        uint8 i;
        address _sup = _superUser[account];
        uint8[10] memory rates = [10, 4, 3, 2, 1, 1, 1, 1, 1, 1];
        while (i < 10 && _sup != address(0)) {
            if (nft.balanceOf(_sup) >= 3) {
                _rewards[_sup] = _rewards[_sup].add(price.mul(rates[i]).div(100));
            }
            i++;
            _sup = _superUser[_sup];
        }
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}