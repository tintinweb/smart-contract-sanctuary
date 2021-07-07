/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

library Strings {

    function toString(uint256 value) internal pure returns (string memory) {
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}


pragma solidity >=0.6.0 <0.8.0;

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


pragma solidity >=0.6.0 <0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity >=0.6.0 <0.8.0;

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

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

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
        return _add(set._inner, bytes32(uint256(value)));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }


    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }


    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}


pragma solidity >=0.6.0 <0.8.0;

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

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)


            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;


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

    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity >=0.6.2 <0.8.0;

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


pragma solidity >=0.6.0 <0.8.0;

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


pragma solidity >=0.6.0 <0.8.0;

abstract contract ERC165 is IERC165 {

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}


pragma solidity >=0.6.2 <0.8.0;

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

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


pragma solidity >=0.6.0 <0.8.0;

interface IERC721Receiver {

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


pragma solidity >=0.6.2 <0.8.0;

interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}


pragma solidity >=0.6.2 <0.8.0;

interface IERC721Enumerable is IERC721 {

    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}


pragma solidity >=0.6.0 <0.8.0;

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
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

    // Base URI
    string private _baseURI;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

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
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}


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
        require(c >= a, "addition overflow");

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
        return sub(a, b, "subtraction overflow");
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
        require(c / a == b, "multiplication overflow");

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
        return div(a, b, "division by zero");
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
        return mod(a, b, "modulo by zero");
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
}

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

}



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract LUCKINU is Context, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    // The TOKEN!
    IERC20 public token;
    
    uint256 public _taxFee = 5;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _liquidityFee = 3;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _potFee = 2;
    uint256 private _previousPotFee = _potFee;

    uint256 public _potFeeExtra = 5;
    uint256 private _previousPotFeeExtra = _potFeeExtra;


    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool inSwap;
    
    struct GameSettings {
        uint256 maxTxAmount; // maximum number of tokens in one transfer
        uint256 tokenSwapThreshold; // number of tokens needed in contract to swap and sell
        uint256 minimumBuyForPotEligibility; //minimum buy to be eligible to win share of the pot
        uint256 tokensToAddOneSecond; //number of tokens that will add one second to the timer
        uint256 maxTimeLeft; //maximum number of seconds the timer can be
        uint256 potFeeExtraTimeLeftThreshold; //if timer is under this value, the potFeeExtra is used
        uint256 eliglblePlayers; //number of players eligible for winning share of the pot
        uint256 potPayoutPercent; // what percent of the pot is paid out, vs. carried over to next round
        uint256 lastBuyerPayoutPercent; //what percent of the paid-out-pot is paid to absolute last 
        uint256 marketingWalletPercent; // what percent for sending marketwallet
        uint256 liquidityPercent; // what percent for sending liquidity
    }

    GameSettings public gameSettings;

    bool public gameIsActive = false;

    uint256 private roundNumber;

    uint256 private timeLeftAtLastBuy;
    uint256 private lastBuyBlock;

    uint256 private potTokens;

    address private gameSettingsUpdaterAddress;

    address private presaleContractAddress;
    address public marketingWallet;

    mapping (uint256 => Buyer[]) buyersByRound;

    modifier onlyGameSettingsUpdater() {
        require(_msgSender() == gameSettingsUpdaterAddress, "caller != game settings updater");
        _;
    }

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event GameSettingsUpdated(
        uint256 maxTxAmount,
        uint256 tokenSwapThreshold,
        uint256 minimumBuyForPotEligibility,
        uint256 tokensToAddOneSecond,
        uint256 maxTimeLeft,
        uint256 potFeeExtraTimeLeftThreshold,
        uint256 eliglblePlayers,
        uint256 potPayoutPercent,
        uint256 lastBuyerPayoutPercent,
        uint256 marketingWalletPercent,
        uint256 liquidityPercent
    );

    event GameSettingsUpdaterUpdated(
        address oldGameSettingsUpdater,
        address newGameSettingsUpdater
    );


    event RoundStarted(
        uint256 number,
        uint256 potValue
    );

    event Buy(
        bool indexed isEligible,
        address indexed buyer,
        uint256 amount,
        uint256 timeLeftBefore,
        uint256 timeLeftAfter,
        uint256 blockTime,
        uint256 blockNumber
    );
    
    event RoundPayout(
        uint256 indexed roundNumber,
        address indexed buyer,
        uint256 amount,
        bool success
    );

    event RoundEnded(
        uint256 number,
        address[] winners,
        uint256[] winnerAmountsRound
    );
    
    enum TransferType {
        Normal,
        Buy,
        Sell,
        RemoveLiquidity
    }

    struct Buyer {
        address buyer;
        uint256 amount;
        uint256 timeLeftBefore;
        uint256 timeLeftAfter;
        uint256 blockTime;
        uint256 blockNumber;
    }



    constructor (IERC20 _token, IUniswapV2Router02 _router, address _pair) public {
        gameSettings = GameSettings(
            1000000 * 10**9, //maxTxAmount is 1 million tokens
            200000 * 10**9, //tokenSwapThreshold is 200000 tokens
            100000 * 10**9, //minimumBuyForPotEligibility is 100000 tokens
            1000 * 10**9, //tokensToAddOneSecond is 1000 tokens
            300, //maxTimeLeft is 6 hours
            600, //potFeeExtraTimeLeftThreshold is 10 minutes
            5, //eliglblePlayers is 5
            60, //potPayoutPercent is 60%
            0, //lastBuyerPayoutPerent is 43% of the 70%, which is ~30% overall
            10, //marketingWalletPercent
            5 //liquidityPercent
        );
        token = _token;
        gameSettingsUpdaterAddress = _msgSender();
        marketingWallet = _msgSender();

        uniswapV2Pair = _pair;

        // set the rest of the contract variables
        uniswapV2Router = _router;
    }

    // for any non-zero value it updates the game settings to that value
    function updateGameSettings(
        uint256 maxTxAmount,
        uint256 tokenSwapThreshold,
        uint256 minimumBuyForPotEligibility,
        uint256 tokensToAddOneSecond,
        uint256 maxTimeLeft,
        uint256 potFeeExtraTimeLeftThreshold,
        uint256 eliglblePlayers,
        uint256 potPayoutPercent,
        uint256 lastBuyerPayoutPercent,
        uint256 marketingWalletPercent,
        uint256 liquidityPercent
    )
        public
        onlyGameSettingsUpdater {

        if(maxTxAmount > 0)  {
            require(maxTxAmount >= 1000000 * 10**9 && maxTxAmount <= 10000000 * 10**9);
            gameSettings.maxTxAmount = maxTxAmount;
        }
        if(tokenSwapThreshold > 0)  {
            require(tokenSwapThreshold >= 100000 * 10**9 && tokenSwapThreshold <= 1000000 * 10**9);
            gameSettings.tokenSwapThreshold = tokenSwapThreshold;
        }
        if(minimumBuyForPotEligibility > 0)  {
            require(minimumBuyForPotEligibility >= 100 * 10**9 && minimumBuyForPotEligibility <= 100000 * 10**9);
            gameSettings.minimumBuyForPotEligibility = minimumBuyForPotEligibility;
        }
        if(tokensToAddOneSecond > 0)  {
            require(tokensToAddOneSecond >= 100 * 10**9 && tokensToAddOneSecond <= 10000 * 10**9);
            gameSettings.tokensToAddOneSecond = tokensToAddOneSecond;
        }
        if(maxTimeLeft > 0)  {
            require(maxTimeLeft >= 60 && maxTimeLeft <= 86400);
            gameSettings.maxTimeLeft = maxTimeLeft;
        }
        if(potFeeExtraTimeLeftThreshold > 0)  {
            require(potFeeExtraTimeLeftThreshold >= 60 && potFeeExtraTimeLeftThreshold <= 3600);
            gameSettings.potFeeExtraTimeLeftThreshold = potFeeExtraTimeLeftThreshold;
        }
        if(eliglblePlayers > 0)  {
            require(eliglblePlayers >= 3 && eliglblePlayers <= 15);
            gameSettings.eliglblePlayers = eliglblePlayers;
        }
        if(potPayoutPercent > 0)  {
            require(potPayoutPercent >= 30 && potPayoutPercent <= 99);
            gameSettings.potPayoutPercent = potPayoutPercent;
        }
        if(lastBuyerPayoutPercent > 0)  {
            require(lastBuyerPayoutPercent >= 0 && lastBuyerPayoutPercent <= 60);
            gameSettings.lastBuyerPayoutPercent = lastBuyerPayoutPercent;
        }

        emit GameSettingsUpdated(
            maxTxAmount,
            tokenSwapThreshold,
            minimumBuyForPotEligibility,
            tokensToAddOneSecond,
            maxTimeLeft,
            potFeeExtraTimeLeftThreshold,
            eliglblePlayers,
            potPayoutPercent,
            lastBuyerPayoutPercent,
            marketingWalletPercent,
            liquidityPercent
        );
    }

    function renounceGameSettingsUpdater() public virtual onlyGameSettingsUpdater {
        emit GameSettingsUpdaterUpdated(gameSettingsUpdaterAddress, address(0));
        gameSettingsUpdaterAddress = address(0);
    }

    function setPresaleContractAddress(address _address) public onlyOwner {
        require(presaleContractAddress == address(0));
        presaleContractAddress = _address;
    }

    function setMarketingWallet(address _address) public {
        require(marketingWallet == _msgSender());
        marketingWallet = _address;
    }
    
    function startGame() public onlyOwner {
        require(!gameIsActive);

        // start on round 1
        roundNumber = roundNumber.add(1);

        timeLeftAtLastBuy = gameSettings.maxTimeLeft;
        lastBuyBlock = block.number;

        gameIsActive = true;

        emit RoundStarted(
            roundNumber,
            potValue()
        );
    }
    

    function buy(uint256 amount) public {
        require(amount>=gameSettings.minimumBuyForPotEligibility);
        address buyer = _msgSender();

        int256 oldTimeLeft = timeLeft();

        if(oldTimeLeft < 0) {
            return;
        }

        token.safeTransferFrom(buyer, address(this), amount);

        int256 newTimeLeft = oldTimeLeft + int256(amount / gameSettings.tokensToAddOneSecond);

        bool isEligible = buyer != address(uniswapV2Router) &&
               amount >= gameSettings.minimumBuyForPotEligibility;

        if(isEligible) {
            Buyer memory newBuyer = Buyer(
                buyer,
                amount,
                uint256(oldTimeLeft),
                uint256(newTimeLeft),
                block.timestamp,
                block.number
            );

            Buyer[] storage buyers = buyersByRound[roundNumber];

            bool added = false;

            // check if buyer would have a 2nd entry in last 7, and remove old one
            for(int256 i = int256(buyers.length) - 1;
                i >= 0 && i > int256(buyers.length) - int256(gameSettings.eliglblePlayers);
                i--) {
                Buyer storage existingBuyer = buyers[uint256(i)];

                if(existingBuyer.buyer == buyer) {
                    // shift all buyers after back one, and put new buyer at end of array
                    for(uint256 j = uint256(i).add(1); j < buyers.length; j = j.add(1)) {
                        buyers[j.sub(1)] = buyers[j];
                    }

                    buyers[buyers.length.sub(1)] = newBuyer;
                    added = true;
                    
                    break;
                }
            }

            if(!added) {
                buyers.push(newBuyer); 
            }
        }

        if(newTimeLeft < 0) {
            newTimeLeft = 0;
        }
        else if(newTimeLeft > int256(gameSettings.maxTimeLeft)) {
            newTimeLeft = int256(gameSettings.maxTimeLeft);
        }

        timeLeftAtLastBuy = uint256(newTimeLeft);
        lastBuyBlock = block.number;
        
        swapTokensForEth(amount);

        emit Buy(
            isEligible,
            buyer,
            amount,
            uint256(oldTimeLeft),
            uint256(newTimeLeft),
            block.timestamp,
            block.number
        );
    }

    function swapTokensForEth(uint256 tokenAmount) public {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = uniswapV2Router.WETH();

        token.approve(address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp.add(300)
        );
    }

    function getETH() public view returns(address){        
        return uniswapV2Router.WETH();
    }
    
    function getSwapInfo() public view returns(address)
    {
        return address(token);
    }
    
    function getRouterInfo() public view returns(address)
    {
        return address(uniswapV2Router);
    }

    function deposit(uint256 tokenAmount) public {
        token.approve(address(uniswapV2Router), tokenAmount);
        token.safeTransferFrom(_msgSender(), address(this), tokenAmount);
    }

    function approve(uint256 tokenAmount) public {
        token.approve(address(uniswapV2Router), tokenAmount);
    }

    function potValue() public view returns (uint256) {
        return address(this).balance.mul(gameSettings.potPayoutPercent).div(100);
    }

    function marketingValue() public view returns (uint256) {
        return address(this).balance.mul(gameSettings.marketingWalletPercent).div(100);
    }

    function liquidityValue() public view returns (uint256) {
        return address(this).balance.mul(gameSettings.liquidityPercent).div(100);
    }

    function timeLeft() public view returns (int256) {
        if(!gameIsActive) {
            return 0;
        }

        uint256 blocksSinceLastBuy = block.number.sub(lastBuyBlock);

        return int256(timeLeftAtLastBuy) - int256(blocksSinceLastBuy.mul(3));
    }

    function currentPotFee() public view returns (uint256) {
        if(timeLeft() < int256(gameSettings.potFeeExtraTimeLeftThreshold)) {
            return _potFeeExtra;
        }
        return _potFee;
    }

    function completeRoundWhenNoTimeLeft() public {
        int256 secondsLeft = timeLeft();

        if(secondsLeft >= 0) {
            return;
        }

        (address[] memory buyers, uint256[] memory payoutAmounts) = _getPayoutAmounts();
        
        uint256 marketingAmount = marketingValue();
        uint256 liquidityAmount = liquidityValue();

        uint256 lastRoundNumber = roundNumber;

        roundNumber = roundNumber.add(1);

        timeLeftAtLastBuy = gameSettings.maxTimeLeft;
        lastBuyBlock = block.number;

        for(uint256 i = 0; i < buyers.length; i = i.add(1)) {
            uint256 amount = payoutAmounts[i];

            if(amount > 0) {
                (bool success, ) = buyers[i].call { value: amount, gas: 5000 }("");

                emit RoundPayout(
                    lastRoundNumber,
                    buyers[i],
                    amount,
                    success
                ); 
            }
        }
        
        marketingWallet.call { value: marketingAmount, gas: 5000 }("");
        uniswapV2Pair.call { value: liquidityAmount, gas: 5000 }("");

        emit RoundEnded(
            lastRoundNumber,
            buyers,
            payoutAmounts
        );


        emit RoundStarted(
            roundNumber,
            potValue()
        );
    }

    function _getPayoutAmounts()
        internal
        view
        returns (address[] memory buyers,
                 uint256[] memory payoutAmounts) {

        buyers = new address[](gameSettings.eliglblePlayers);
        payoutAmounts = new uint256[](gameSettings.eliglblePlayers);

        Buyer[] storage roundBuyers = buyersByRound[roundNumber];

        if(roundBuyers.length > 0) {
            uint256 totalPayout = potValue();

            uint256 lastBuyerPayout = totalPayout.mul(gameSettings.lastBuyerPayoutPercent).div(100);

            uint256 payoutLeft = totalPayout.sub(lastBuyerPayout);


            uint256 numberOfWinners = roundBuyers.length > gameSettings.eliglblePlayers ? gameSettings.eliglblePlayers : roundBuyers.length;

            uint256 amountLeft;

            for(int256 i = int256(roundBuyers.length) - 1; i >= int256(roundBuyers.length) - int256(numberOfWinners); i--) {
                amountLeft = amountLeft.add(roundBuyers[uint256(i)].amount);
            }

            uint256 returnIndex = 0;

            for(int256 i = int256(roundBuyers.length) - 1; i >= int256(roundBuyers.length) - int256(numberOfWinners); i--) {

                uint256 amount = roundBuyers[uint256(i)].amount;

                uint256 payout = 0;

                if(amountLeft > 0) {
                    payout = payoutLeft.mul(amount).div(amountLeft);
                }

                amountLeft = amountLeft.sub(amount);
                payoutLeft = payoutLeft.sub(payout);

                buyers[returnIndex] = roundBuyers[uint256(i)].buyer;
                payoutAmounts[returnIndex] = payout;

                if(returnIndex == 0) {
                    payoutAmounts[0] = payoutAmounts[0].add(lastBuyerPayout);
                }

                returnIndex = returnIndex.add(1);
            }
        }
    }

    function gameStats()
        external
        view
        returns (uint256 currentRoundNumber,
                 int256 currentTimeLeft,
                 uint256 currentPotValue,
                 uint256 currentTimeLeftAtLastBuy,
                 uint256 currentLastBuyBlock,
                 uint256 currentBlockTime,
                 uint256 currentBlockNumber,
                 address[] memory lastBuyerAddress,
                 uint256[] memory lastBuyerData) {
        currentRoundNumber = roundNumber;
        currentTimeLeft = timeLeft();
        currentPotValue = potValue();
        currentTimeLeftAtLastBuy = timeLeftAtLastBuy;
        currentLastBuyBlock = lastBuyBlock;
        currentBlockTime = block.timestamp;
        currentBlockNumber = block.number;

        lastBuyerAddress = new address[](gameSettings.eliglblePlayers);
        lastBuyerData = new uint256[](gameSettings.eliglblePlayers.mul(6));

        Buyer[] storage buyers = buyersByRound[roundNumber];

        uint256 iteration = 0;

        (, uint256[] memory payoutAmounts) = _getPayoutAmounts();

        for(int256 i = int256(buyers.length) - 1; i >= 0; i--) {

            Buyer storage buyer = buyers[uint256(i)];

            lastBuyerAddress[iteration] = buyer.buyer;
            lastBuyerData[iteration.mul(6).add(0)] = buyer.amount;
            lastBuyerData[iteration.mul(6).add(1)] = buyer.timeLeftBefore;
            lastBuyerData[iteration.mul(6).add(2)] = buyer.timeLeftAfter;
            lastBuyerData[iteration.mul(6).add(3)] = buyer.blockTime;
            lastBuyerData[iteration.mul(6).add(4)] = buyer.blockNumber;
            lastBuyerData[iteration.mul(6).add(5)] = payoutAmounts[iteration];

            iteration = iteration.add(1);

            if(iteration == gameSettings.eliglblePlayers) {
                break;
            }
        }
    }
}