/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}


interface IERC721Enumerable is IERC721 {

    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}


interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

abstract contract ERC165 is IERC165 {

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
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


library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }


    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }


    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


library EnumerableSet {

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

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

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }


    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }


    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }


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


    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }


    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

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


    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
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

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}


library EnumerableMap {

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
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

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
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

        if (keyIndex != 0) { // Equivalent to contains(map, key)
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
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

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
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
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
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
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


    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }


    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Mapping from owner to list of owned token IDs
    mapping (address => uint256[]) internal ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) internal ownedTokensIndex;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Array with all token ids, used for enumeration
    uint256[] internal allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) internal allTokensIndex;


    // Base URI
    string private _baseURI;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }


    modifier onlyOwnerOf(uint256 _tokenId) {
      require(ownerOf(_tokenId) == msg.sender);
      _;
    }

    modifier canTransfer(uint256 _tokenId) {
      require(_isApprovedOrOwner(msg.sender, _tokenId));
      _;
    }
    
    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    function addTokenTo(address _to, uint256 _tokenId) internal {
        uint256 length = ownedTokens[_to].length;
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
    }

    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];

        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;

        ownedTokens[_from].pop();
        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
    }
    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId) internal virtual {
        _transfer(from, to, tokenId);
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }


    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _mint(to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        allTokensIndex[tokenId] = allTokens.length;
        allTokens.push(tokenId);

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        addTokenTo(to, tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }


    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        removeTokenFrom(owner, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }


    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        removeTokenFrom(from, tokenId);
        addTokenTo(to, tokenId);
        
        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }


    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function mint(address _to, uint256 _amount) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function getTotalSupply() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract WARNFTCOINS is Ownable, ERC721 {
    using Strings for string;
    using Strings for uint256;
    using SafeMath for uint256;

    constructor () ERC721("WAR NFT COINS" ,"WARNFTCOINS"){}

    struct Characters {
        uint id;
        string ipfsHash;
        address publisher;
        string name;
        uint power;
        uint amountFight;
    }

    struct Enemies {
        uint id;
        string ipfsHash;
        string name;
        uint power;
        uint256 reward;
    }

    IERC20 public addressPaymentToken = IERC20(0x1ba67b7Fe081f15A98a8aBeBD18fbb3fD98CcAca);

    uint128 public feeToOwner = 3;
 
    uint public initFight = 40;
    uint public addFightAmount = 30;
    uint public limitWithdraw = 10 days;

    bool public disable = false;
    string public baseExtension = ".json";
    bool public timeLess = false;

    uint256 public priceCharacter = 2000000000000000000000;

    mapping (address => uint256) public playerReward;
    mapping (address => uint) public depositedTokens;
    mapping(address => uint) usersEpoch;

    Characters[] public characters;
    Enemies[] public enemies;

    mapping (string => uint256) ipfsHashToTokenId;

    mapping (address => uint256) internal publishedTokensCount;
    mapping (address => uint256[]) internal publishedTokens;

    mapping(address => mapping (uint256 => uint256)) internal publishedTokensIndex;

    struct SellingItem {
        address seller;
        uint256 price;
        string ipfsHash;
        string name;
        uint power;
        uint amountFight;
    }

    mapping (uint256 => SellingItem) public tokenIdToSellingItem;

    uint256 public levelChar1 = 20000000000000000000000;
    uint256 public levelChar2 = 21000000000000000000000;
    uint256 public levelChar3 = 22000000000000000000000;
    uint256 public levelChar4 = 23000000000000000000000;
    uint256 public levelChar5 = 24000000000000000000000;
    uint256 public levelChar6 = 25000000000000000000000;
    uint256 public levelChar7 = 26000000000000000000000;
    uint256 public levelChar8 = 27000000000000000000000;
    uint256 public levelChar9 = 28000000000000000000000;
    uint256 public levelChar10 = 29000000000000000000000;
    uint256 public levelCharMaster = 30000000000000000000000;

    uint256 public powerChar1 = 250000000000000000000;
    uint256 public powerChar2 = 250000000000000000000; 
    uint256 public powerChar3 = 300000000000000000000; 
    uint256 public powerChar4 = 300000000000000000000;
    uint256 public powerChar5 = 350000000000000000000;
    uint256 public powerChar6 = 350000000000000000000;
    uint256 public powerChar7 = 400000000000000000000;
    uint256 public powerChar8 = 450000000000000000000;
    uint256 public powerChar9 = 500000000000000000000;
    uint256 public powerChar10 = 600000000000000000000;
    uint256 public powerCharMaster = 700000000000000000000;


    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    function withdrawToken(uint256 _amount) public onlyOwner {
        require(addressPaymentToken.transfer(msg.sender, _amount), "Transfer error.");
    }

    function validateTimeWithdraw(uint _value) internal view returns (bool) {
        if(_value == 0) {
          return false;
        }
        uint256 nowT = _value.add(limitWithdraw);
        uint256 dateNow = block.timestamp;

        if(nowT <= dateNow){
          return false;
        }
        return true;
    }

    function nextWithdraw(address _address) public view returns (uint256) {
        uint256 nowT = usersEpoch[_address].add(limitWithdraw);
        return nowT;
    }

    function setTimeWithdraw(uint256 _value) public onlyOwner {
        limitWithdraw = _value;
    }

    function setTimeLess(bool _value) public onlyOwner {
        timeLess = _value;
    }

    function setDisable(bool _value) public onlyOwner {
        disable = _value;
    }

    function setLevelsAdd(
      uint256 _levelChar1, 
      uint256 _levelChar2, 
      uint256 _levelChar3, 
      uint256 _levelChar4, 
      uint256 _levelChar5, 
      uint256 _levelChar6, 
      uint256 _levelChar7, 
      uint256 _levelChar8,
      uint256 _levelChar9,
      uint256 _levelChar10,
      uint256 _levelCharMaster
    ) public onlyOwner {
        levelChar1 = _levelChar1;
        levelChar2 = _levelChar2;
        levelChar3 = _levelChar3;
        levelChar4 = _levelChar4;
        levelChar5 = _levelChar5;
        levelChar6 = _levelChar6;
        levelChar7 = _levelChar7;
        levelChar8 = _levelChar8;
        levelChar9 = _levelChar9;
        levelChar10 = _levelChar10;
        levelCharMaster = _levelCharMaster;
    }

    function setPowerAdd(
      uint256 _powerChar1, 
      uint256 _powerChar2, 
      uint256 _powerChar3, 
      uint256 _powerChar4, 
      uint256 _powerChar5, 
      uint256 _powerChar6, 
      uint256 _powerChar7, 
      uint256 _powerChar8,
      uint256 _powerChar9,
      uint256 _powerChar10,
      uint256 _powerCharMaster
      ) public onlyOwner {
        powerChar1 = _powerChar1;
        powerChar2 = _powerChar2;
        powerChar3 = _powerChar3;
        powerChar4 = _powerChar4;
        powerChar5 = _powerChar5;
        powerChar6 = _powerChar6;
        powerChar7 = _powerChar7;
        powerChar8 = _powerChar8;
        powerChar8 = _powerChar9;
        powerChar8 = _powerChar10;
        powerCharMaster = _powerCharMaster;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );
        
        string memory currentBaseURI = baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function setEnemyReward(uint256 _value, uint256 _enemyId) public onlyOwner {
        enemies[_enemyId].reward = _value;
    }

    function setAddressPaymentToken(address _addressPaymentToken) public onlyOwner {
        addressPaymentToken = IERC20(_addressPaymentToken);
    }

    function setInitFight(uint _value) public onlyOwner {
        initFight = _value;
    }

    function setAddFightAmount(uint _value) public onlyOwner {
        addFightAmount = _value;
    }

    function setPriceCharacter(uint256 _priceCharacter) public onlyOwner {
        priceCharacter = _priceCharacter;
    }

    function setBaseExtension(string memory _value) public onlyOwner {
        baseExtension = _value;
    }

    function setBaseURI(string memory _value) public onlyOwner {
        _setBaseURI(_value);
    }

    function getIpfsHashToTokenId(string memory _string) public view returns (uint256){
        return ipfsHashToTokenId[_string];
    }

    function getOwnedTokens(address _owner) public view returns (uint256[] memory) {
        return ownedTokens[_owner];
    }

    function getAllTokens() public view returns (uint256[] memory) {
        return allTokens;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function publishedCountOf(address _publisher) public view returns (uint256) {
        return publishedTokensCount[_publisher];
    }

    function publishedTokenOfOwnerByIndex(address _publisher, uint256 _index) public view returns (uint256) {
        require(_index < publishedCountOf(_publisher));
        return publishedTokens[_publisher][_index];
    }

    function getPublishedTokens(address _publisher) public view returns (uint256[] memory) {
        return publishedTokens[_publisher];
    }


    function mintCharacter() public {
        require(!disable, "Game disabled");

        require(addressPaymentToken.transferFrom(msg.sender, address(this), priceCharacter), "Transfer for mint error.");

        Characters memory _digitalNFT = Characters({
            id: 0,
            ipfsHash: "", 
            publisher: msg.sender, 
            name: "War Coin",
            power: 1,
            amountFight: initFight
        });

        characters.push(_digitalNFT);

        uint256 newCharactersNFTId = characters.length - 1;
        characters[newCharactersNFTId].id = newCharactersNFTId;
        string memory baseURI = baseURI();
        string memory hashMetadata = string(abi.encodePacked(baseURI, newCharactersNFTId.toString() , baseExtension));
        characters[newCharactersNFTId].ipfsHash = hashMetadata;
        ipfsHashToTokenId[hashMetadata] = newCharactersNFTId;
        _mint(msg.sender, newCharactersNFTId);

        publishedTokensCount[msg.sender]++;
        uint256 length = publishedTokens[msg.sender].length;
        publishedTokens[msg.sender].push(newCharactersNFTId);
        publishedTokensIndex[msg.sender][newCharactersNFTId] = length;    
    }

    function createEnemy(string memory _ipfsHash, string memory _name, uint _power, uint256 _reward) public onlyOwner {
        Enemies memory _enemy = Enemies({
            id: enemies.length, 
            ipfsHash: _ipfsHash, 
            name: _name,
            power: _power,
            reward: _reward
        });

        enemies.push(_enemy);
    }

    function addNFTSellingItem(uint256 _tokenId, uint256 _price) public onlyOwnerOf(_tokenId) {
        require(tokenIdToSellingItem[_tokenId].seller == address(0));
        SellingItem memory _sellingItem = SellingItem(
            msg.sender, 
            uint256(_price), 
            characters[_tokenId].ipfsHash, 
            characters[_tokenId].name,
            characters[_tokenId].power,
            characters[_tokenId].amountFight
        );
        tokenIdToSellingItem[_tokenId] = _sellingItem;
        approve(address(this), _tokenId);
        safeTransferFrom(msg.sender, address(this), _tokenId);
    }

    function cancelNFTSellingItem(uint256 _tokenId) public {
        require(tokenIdToSellingItem[_tokenId].seller == msg.sender);
        this.safeTransferFrom(address(this), tokenIdToSellingItem[_tokenId].seller, _tokenId);
        delete tokenIdToSellingItem[_tokenId];
    }

    function purchaseCharacter(uint256 _tokenId, uint256 _amount) public {
        uint256 priceItemEther = tokenIdToSellingItem[_tokenId].price;
        address sellerAddress = tokenIdToSellingItem[_tokenId].seller;

        require(sellerAddress != address(0));
        require(sellerAddress != msg.sender);
        require(priceItemEther == _amount);

        uint256 feeToOwnerItem = priceItemEther.mul(feeToOwner).div(100);
        uint256 priceItemEtherFee = priceItemEther.sub(feeToOwnerItem);

        require(addressPaymentToken.transferFrom(msg.sender, sellerAddress, priceItemEtherFee), "Transfer error.");
        require(addressPaymentToken.transferFrom(msg.sender, address(this), feeToOwnerItem), "Transfer error.");

        SellingItem memory sellingItem = tokenIdToSellingItem[_tokenId];

        if (sellingItem.price > 0) {
            require(addressPaymentToken.transfer(characters[_tokenId].publisher, sellingItem.price), "Transfer error.");
        }

        delete tokenIdToSellingItem[_tokenId];
        this.safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    function addPower(uint256 _tokenId) public onlyOwnerOf(_tokenId) returns (bool){
        uint powerC = characters[_tokenId].power;

        if(powerC == 1){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), levelChar1), "Transfer error.");
            characters[_tokenId].power = 2;
            return true;
        }

        if(powerC == 2){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), levelChar2), "Transfer error.");
            characters[_tokenId].power = 3;
            return true;
        }

        if(powerC == 3){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), levelChar3), "Transfer error.");
            characters[_tokenId].power = 4;
            return true;
        }

        if(powerC == 4){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), levelChar4), "Transfer error.");
            characters[_tokenId].power = 5;
            return true;
        }

        if(powerC == 5){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), levelChar5), "Transfer error.");
            characters[_tokenId].power = 6;
            return true;
        }

        if(powerC == 6){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), levelChar6), "Transfer error.");
            characters[_tokenId].power = 7;
            return true;
        }

        if(powerC== 7){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), levelChar7), "Transfer error.");
            characters[_tokenId].power = 8;
            return true;
        }

        if(powerC == 8){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), levelChar8), "Transfer error.");
            characters[_tokenId].power = 9;
            return true;
        }

        if(powerC == 9){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), levelChar9), "Transfer error.");
            characters[_tokenId].power = 10;
            return true;
        }

        if(powerC == 10){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), levelChar10), "Transfer error.");
            characters[_tokenId].power = 11;
            return true;
        }

        if(powerC >= 11){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), levelCharMaster), "Transfer error.");
            characters[_tokenId].power = characters[_tokenId].power.add(100);
            return true;
        }

        return false;
    }

    function addFight(uint256 _tokenId) public onlyOwnerOf(_tokenId) returns (bool){
        uint powerC = characters[_tokenId].power;

        if(powerC == 1){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), powerChar1), "Transfer error.");
            characters[_tokenId].amountFight = characters[_tokenId].amountFight + addFightAmount;
            return true;
        }

        if(powerC == 2){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), powerChar2), "Transfer error.");
            characters[_tokenId].amountFight = characters[_tokenId].amountFight + addFightAmount;
            return true;
        }

        if(powerC== 3){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), powerChar3), "Transfer error.");
            characters[_tokenId].amountFight = characters[_tokenId].amountFight + addFightAmount;
            return true;
        }

        if(powerC == 4){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), powerChar4), "Transfer error.");
            characters[_tokenId].amountFight = characters[_tokenId].amountFight + addFightAmount;
            return true;
        }

        if(powerC == 5){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), powerChar5), "Transfer error.");
            characters[_tokenId].amountFight = characters[_tokenId].amountFight + addFightAmount;
            return true;           
        }

        if(powerC == 6){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), powerChar6), "Transfer error.");
            characters[_tokenId].amountFight = characters[_tokenId].amountFight + addFightAmount;
            return true;
        }

        if(powerC == 7){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), powerChar7), "Transfer error.");
            characters[_tokenId].amountFight = characters[_tokenId].amountFight + addFightAmount;
            return true;
        }

        if(powerC == 8){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), powerChar8), "Transfer error.");
            characters[_tokenId].amountFight = characters[_tokenId].amountFight + addFightAmount;
            return true;
        }

        if(powerC == 9){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), powerChar9), "Transfer error.");
            characters[_tokenId].amountFight = characters[_tokenId].amountFight + addFightAmount;
            return true;
        }

        if(powerC == 10){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), powerChar10), "Transfer error.");
            characters[_tokenId].amountFight = characters[_tokenId].amountFight + addFightAmount;
            return true;
        }

        if(powerC >= 11){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), powerCharMaster), "Transfer error.");
            characters[_tokenId].amountFight = characters[_tokenId].amountFight + addFightAmount;
            return true;
        }

        return false;
    }

    function fight(uint256 _tokenId, uint _enemyId) public onlyOwnerOf(_tokenId) returns (string memory) {
        string memory msgReturn = "Lost!";
        uint amountFight;

        amountFight = characters[_tokenId].amountFight;

        require(amountFight >= 1, "Amount of fight exceeded.");
        require(characters[_tokenId].power >= enemies[_enemyId].power, "Weak character.");

        if(characters[_tokenId].power >= enemies[_enemyId].power) {

            playerReward[msg.sender] += enemies[_enemyId].reward;

            characters[_tokenId].amountFight = characters[_tokenId].amountFight -1;

            msgReturn = "win";
            return msgReturn;
        }

        return msgReturn;
    }

    function withdrawReward() public {
        require(!disable, "Game disabled");
        if(!timeLess){
            if(validateTimeWithdraw(usersEpoch[msg.sender])) { revert(); }
        }
        if(playerReward[msg.sender] == 0) { revert(); }

        usersEpoch[msg.sender] = block.timestamp;

        require(addressPaymentToken.transfer(msg.sender, playerReward[msg.sender]), "Transfer reward error.");

        playerReward[msg.sender] = 0;
    }

}