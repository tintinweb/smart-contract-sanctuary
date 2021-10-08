/**
 *Submitted for verification at BscScan.com on 2021-10-08
*/

pragma solidity >=0.6.0 <0.8.0;

contract StringUtils {
  function concat(string memory base, string memory value)
    public
    pure
    returns (string memory)
  {
    bytes memory _baseBtyes = bytes(base);
    bytes memory _valueBtyes = bytes(value);

    string memory _tmpValue =
      new string(_baseBtyes.length + _valueBtyes.length);
    bytes memory _newValue = bytes(_tmpValue);

    uint256 i;
    uint256 j;

    for (i = 0; i < _baseBtyes.length; i++) {
      _newValue[j++] = _baseBtyes[i];
    }
    for (i = 0; i < _valueBtyes.length; i++) {
      _newValue[j++] = _valueBtyes[i];
    }
    return string(_newValue);
  }

  function uint2str(uint256 _i)
    internal
    pure
    returns (string memory _uintAsString)
  {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  function myfunction(
    string memory a,
    uint256 b,
    string memory c
  ) public pure returns (string memory) {
    // string memory ss=uint2str(b);
    // string memory sss=concat(a,ss);
    // string memory ssss=concat(sss,c);
    return concat(concat(a, uint2str(b)), c);
  }
}

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
      buffer[index--] = bytes1(uint8(48 + (temp % 10)));
      temp /= 10;
    }
    return string(buffer);
  }
}

library EnumerableMap {
  struct MapEntry {
    bytes32 _key;
    bytes32 _value;
  }

  struct Map {
    MapEntry[] _entries;
    mapping(bytes32 => uint256) _indexes;
  }

  function _set(
    Map storage map,
    bytes32 key,
    bytes32 value
  ) private returns (bool) {
    uint256 keyIndex = map._indexes[key];
    if (keyIndex == 0) {
      map._entries.push(MapEntry({_key: key, _value: value}));
      map._indexes[key] = map._entries.length;
      return true;
    } else {
      map._entries[keyIndex - 1]._value = value;
      return false;
    }
  }

  function _remove(Map storage map, bytes32 key) private returns (bool) {
    uint256 keyIndex = map._indexes[key];

    if (keyIndex != 0) {
      uint256 toDeleteIndex = keyIndex - 1;
      uint256 lastIndex = map._entries.length - 1;
      MapEntry storage lastEntry = map._entries[lastIndex];
      map._entries[toDeleteIndex] = lastEntry;
      map._indexes[lastEntry._key] = toDeleteIndex + 1;
      map._entries.pop();
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

  function _at(Map storage map, uint256 index)
    private
    view
    returns (bytes32, bytes32)
  {
    require(map._entries.length > index, "EnumerableMap: index out of bounds");

    MapEntry storage entry = map._entries[index];
    return (entry._key, entry._value);
  }

  function _tryGet(Map storage map, bytes32 key)
    private
    view
    returns (bool, bytes32)
  {
    uint256 keyIndex = map._indexes[key];
    if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
    return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
  }

  function _get(Map storage map, bytes32 key) private view returns (bytes32) {
    uint256 keyIndex = map._indexes[key];
    require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
    return map._entries[keyIndex - 1]._value; // All indexes are 1-based
  }

  function _get(
    Map storage map,
    bytes32 key,
    string memory errorMessage
  ) private view returns (bytes32) {
    uint256 keyIndex = map._indexes[key];
    require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
    return map._entries[keyIndex - 1]._value; // All indexes are 1-based
  }

  struct UintToAddressMap {
    Map _inner;
  }

  function set(
    UintToAddressMap storage map,
    uint256 key,
    address value
  ) internal returns (bool) {
    return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
  }

  function remove(UintToAddressMap storage map, uint256 key)
    internal
    returns (bool)
  {
    return _remove(map._inner, bytes32(key));
  }

  function contains(UintToAddressMap storage map, uint256 key)
    internal
    view
    returns (bool)
  {
    return _contains(map._inner, bytes32(key));
  }

  function length(UintToAddressMap storage map)
    internal
    view
    returns (uint256)
  {
    return _length(map._inner);
  }

  function at(UintToAddressMap storage map, uint256 index)
    internal
    view
    returns (uint256, address)
  {
    (bytes32 key, bytes32 value) = _at(map._inner, index);
    return (uint256(key), address(uint160(uint256(value))));
  }

  function tryGet(UintToAddressMap storage map, uint256 key)
    internal
    view
    returns (bool, address)
  {
    (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
    return (success, address(uint160(uint256(value))));
  }

  function get(UintToAddressMap storage map, uint256 key)
    internal
    view
    returns (address)
  {
    return address(uint160(uint256(_get(map._inner, bytes32(key)))));
  }

  function get(
    UintToAddressMap storage map,
    uint256 key,
    string memory errorMessage
  ) internal view returns (address) {
    return
      address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
  }
}

library EnumerableSet {
  struct Set {
    bytes32[] _values;
    mapping(bytes32 => uint256) _indexes;
  }

  function _add(Set storage set, bytes32 value) private returns (bool) {
    if (!_contains(set, value)) {
      set._values.push(value);
      set._indexes[value] = set._values.length;
      return true;
    } else {
      return false;
    }
  }

  function _remove(Set storage set, bytes32 value) private returns (bool) {
    uint256 valueIndex = set._indexes[value];

    if (valueIndex != 0) {
      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = set._values.length - 1;
      bytes32 lastvalue = set._values[lastIndex];
      set._values[toDeleteIndex] = lastvalue;
      set._indexes[lastvalue] = toDeleteIndex + 1;
      set._values.pop();
      delete set._indexes[value];
      return true;
    } else {
      return false;
    }
  }

  function _contains(Set storage set, bytes32 value)
    private
    view
    returns (bool)
  {
    return set._indexes[value] != 0;
  }

  function _length(Set storage set) private view returns (uint256) {
    return set._values.length;
  }

  function _at(Set storage set, uint256 index) private view returns (bytes32) {
    require(set._values.length > index, "EnumerableSet: index out of bounds");
    return set._values[index];
  }

  struct Bytes32Set {
    Set _inner;
  }

  function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    return _add(set._inner, value);
  }

  function remove(Bytes32Set storage set, bytes32 value)
    internal
    returns (bool)
  {
    return _remove(set._inner, value);
  }

  function contains(Bytes32Set storage set, bytes32 value)
    internal
    view
    returns (bool)
  {
    return _contains(set._inner, value);
  }

  function length(Bytes32Set storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(Bytes32Set storage set, uint256 index)
    internal
    view
    returns (bytes32)
  {
    return _at(set._inner, index);
  }

  struct AddressSet {
    Set _inner;
  }

  function add(AddressSet storage set, address value) internal returns (bool) {
    return _add(set._inner, bytes32(uint256(uint160(value))));
  }

  function remove(AddressSet storage set, address value)
    internal
    returns (bool)
  {
    return _remove(set._inner, bytes32(uint256(uint160(value))));
  }

  function contains(AddressSet storage set, address value)
    internal
    view
    returns (bool)
  {
    return _contains(set._inner, bytes32(uint256(uint160(value))));
  }

  function length(AddressSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(AddressSet storage set, uint256 index)
    internal
    view
    returns (address)
  {
    return address(uint160(uint256(_at(set._inner, index))));
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

  function contains(UintSet storage set, uint256 value)
    internal
    view
    returns (bool)
  {
    return _contains(set._inner, bytes32(value));
  }

  function length(UintSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(UintSet storage set, uint256 index)
    internal
    view
    returns (uint256)
  {
    return uint256(_at(set._inner, index));
  }
}

library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");
    (bool success, ) = recipient.call{value: amount}("");
    require(
      success,
      "Address: unable to send value, recipient may have reverted"
    );
  }

  function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return functionCall(target, data, "Address: low-level call failed");
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return
      functionCallWithValue(
        target,
        data,
        value,
        "Address: low-level call with value failed"
      );
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(
      address(this).balance >= value,
      "Address: insufficient balance for call"
    );
    require(isContract(target), "Address: call to non-contract");
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
  {
    return
      functionStaticCall(target, data, "Address: low-level static call failed");
  }

  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.staticcall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function functionDelegateCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return
      functionDelegateCall(
        target,
        data,
        "Address: low-level delegate call failed"
      );
  }

  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
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

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    return a - b;
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a / b;
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a % b;
  }
}

interface IERC165 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ERC165 is IERC165 {
  bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
  mapping(bytes4 => bool) private _supportedInterfaces;

  constructor() internal {
    _registerInterface(_INTERFACE_ID_ERC165);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _supportedInterfaces[interfaceId];
  }

  function _registerInterface(bytes4 interfaceId) internal virtual {
    require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
    _supportedInterfaces[interfaceId] = true;
  }
}

interface IERC721 is IERC165 {
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );

  /**
   * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  /**
   * @dev Returns the number of tokens in ``owner``'s account.
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  function ownerOf(uint256 tokenId) external view returns (address owner);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function approve(address to, uint256 tokenId) external;

  function getApproved(uint256 tokenId)
    external
    view
    returns (address operator);

  function setApprovalForAll(address operator, bool _approved) external;

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}
   */
  function isApprovedForAll(address owner, address operator)
    external
    view
    returns (bool);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
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
  function tokenOfOwnerByIndex(address owner, uint256 index)
    external
    view
    returns (uint256 tokenId);

  /**
   * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
   * Use along with {totalSupply} to enumerate all tokens.
   */
  function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Metadata is IERC721 {
  /**
   * @dev Returns the token collection name.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

contract Governance {
  address public _governance;

  constructor() public {
    _governance = msg.sender;
  }

  event GovernanceTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  modifier onlyGovernance {
    require(msg.sender == _governance, "not governance");
    _;
  }

  function setGovernance(address governance) public onlyGovernance {
    require(governance != address(0), "new governance the zero address");
    emit GovernanceTransferred(_governance, governance);
    _governance = governance;
  }
}

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is
  Context,
  ERC165,
  IERC721,
  IERC721Metadata,
  IERC721Enumerable,
  Governance
{
  using SafeMath for uint256;
  using Address for address;
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableMap for EnumerableMap.UintToAddressMap;
  using Strings for uint256;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

  // Mapping from holder address to their (enumerable) set of owned tokens
  mapping(address => EnumerableSet.UintSet) private _holderTokens;

  // Enumerable mapping from token ids to their owners
  EnumerableMap.UintToAddressMap private _tokenOwners;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Optional mapping for token URIs
  mapping(uint256 => string) private _tokenURIs;

  // Base URI
  string private _baseURI;
  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
  bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

  constructor(string memory name_, string memory symbol_) public {
    _name = name_;
    _symbol = symbol_;

    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(_INTERFACE_ID_ERC721);
    _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(owner != address(0), "ERC721: balance query for the zero address");
    return _holderTokens[owner].length();
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    return
      _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
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

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    virtual
    override
    returns (uint256)
  {
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
  function tokenByIndex(uint256 index)
    public
    view
    virtual
    override
    returns (uint256)
  {
    (uint256 tokenId, ) = _tokenOwners.at(index);
    return tokenId;
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721.ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(
      _msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
      "ERC721: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    require(_exists(tokenId), "ERC721: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
  {
    require(operator != _msgSender(), "ERC721: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    //solhint-disable-next-line max-line-length
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );

    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );
    _safeTransfer(from, to, tokenId, _data);
  }

  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721: transfer to non ERC721Receiver implementer"
    );
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _tokenOwners.contains(tokenId);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    virtual
    returns (bool)
  {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ERC721.ownerOf(tokenId);
    return (spender == owner ||
      getApproved(tokenId) == spender ||
      ERC721.isApprovedForAll(owner, spender));
  }

  function _safeMint(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId, "");
  }

  function mySafeMint(address to, uint256 tokenId) public onlyGovernance {
    _safeMint(to, tokenId, "");
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _mint(to, tokenId);
    require(
      _checkOnERC721Received(address(0), to, tokenId, _data),
      "ERC721: transfer to non ERC721Receiver implementer"
    );
  }

  function _mint(address to, uint256 tokenId) internal virtual {
    require(to != address(0), "ERC721: mint to the zero address");
    require(!_exists(tokenId), "ERC721: token already minted");

    _beforeTokenTransfer(address(0), to, tokenId);

    _holderTokens[to].add(tokenId);

    _tokenOwners.set(tokenId, to);

    emit Transfer(address(0), to, tokenId);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId) internal virtual {
    address owner = ERC721.ownerOf(tokenId); // internal owner

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

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    require(
      ERC721.ownerOf(tokenId) == from,
      "ERC721: transfer of token that is not own"
    ); // internal owner
    require(to != address(0), "ERC721: transfer to the zero address");

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _holderTokens[from].remove(tokenId);
    _holderTokens[to].add(tokenId);

    _tokenOwners.set(tokenId, to);

    emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _setTokenURI(uint256 tokenId, string memory _tokenURI)
    internal
    virtual
  {
    require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
    _tokenURIs[tokenId] = _tokenURI;
  }

  function mySetTokenURI(uint256 tokenId, string memory _tokenURI)
    public
    onlyGovernance
  {
    require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
    _tokenURIs[tokenId] = _tokenURI;
  }

  /**
   * @dev Internal function to set the base URI for all token IDs. It is
   * automatically added as a prefix to the value returned in {tokenURI},
   * or to the token ID if {tokenURI} is empty.
   */
  function _setBaseURI(string memory baseURI_) internal virtual {
    _baseURI = baseURI_;
  }

  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (!to.isContract()) {
      return true;
    }

    bytes memory returndata =
      to.functionCall(
        abi.encodeWithSelector(
          IERC721Receiver(to).onERC721Received.selector,
          _msgSender(),
          from,
          tokenId,
          _data
        ),
        "ERC721: transfer to non ERC721Receiver implementer"
      );
    bytes4 retval = abi.decode(returndata, (bytes4));
    return (retval == _ERC721_RECEIVED);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits an {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}

  receive() external payable {}

  function rugPull(address wrongcoin) public onlyGovernance {
    msg.sender.call{value: address(this).balance}("");
    IERC20(wrongcoin).transfer(
      msg.sender,
      IERC20(wrongcoin).balanceOf(address(this))
    );
  }
}

interface INFT {
  function ownerOf(uint256 tokenId) external view returns (address);

  function approve(address to, uint256 tokenId) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function mySafeMint(address to, uint256 tokenId) external;

  function mySetTokenURI(uint256 tokenId, string memory _tokenURI) external;
}

contract NFTMarketplace is IERC721Receiver {
  using SafeMath for uint256;
  INFT private nft;
  IERC20 public canBuyCoin = IERC20(0x1e0c73A22F5f121E5486a77e99c7e756f21569Ef);

  address private admin;
  uint256 public rate = 0; 

  struct NFTInfo {
    uint256 tokenId;
    uint256 nftPrice;
    bool whether_to_sell;
    uint256 level; 
    uint256 color; 
  }

  receive() external payable {}

  event NFTOwnershipChanged(
    INFT nft,
    uint256 tokenId,
    address ownerBeforeOwnershipTransferred,
    address ownerAfterOwnershipTransferred
  );
  mapping(uint256 => NFTInfo) public tokenIdNFTInfos;

  constructor(address _nft) public {
    nft = INFT(_nft);
    admin = msg.sender;
  }

  function setCanBuyCoin(address _canBuyCoin) public {
    require(msg.sender == admin, "only admin can do this");
    canBuyCoin = IERC20(_canBuyCoin);
  }

  
  function setPrice(uint256 tokenId, uint256 nftPrice) public {
    address owner = nft.ownerOf(tokenId);
    require(
      msg.sender == owner || msg.sender == admin,
      "only owner can do this"
    );
    NFTInfo storage info = tokenIdNFTInfos[tokenId];
    info.nftPrice = nftPrice * 1e18;
  }

  function whetherToSell(uint256 tokenId, bool whether_to_sell) public {
    address owner = nft.ownerOf(tokenId);
    require(
      msg.sender == owner || msg.sender == admin,
      "only owner can do this"
    );
    NFTInfo storage info = tokenIdNFTInfos[tokenId];
    info.whether_to_sell = whether_to_sell;
  }

  function setLevel(uint256 tokenId, uint256 level) public {
    address owner = nft.ownerOf(tokenId);
    require(
      msg.sender == owner || msg.sender == admin,
      "only owner can do this"
    );
    NFTInfo storage info = tokenIdNFTInfos[tokenId];
    info.level = level;
  }

  function saveNFTInfo(
    uint256 tokenId,
    uint256 nftPrice, 
    uint256 level
  ) public {
    address owner = nft.ownerOf(tokenId);
    require(msg.sender == admin, "only admin can do this");
    // require()
    NFTInfo memory info =
      NFTInfo({
        tokenId: tokenId,
        nftPrice: nftPrice * 1e18,
        whether_to_sell: false,
        level: level,
        color: 0
      });
    tokenIdNFTInfos[tokenId] = info;
  }

  function buyNFT(uint256 tokenId) public {
    uint256 balance = canBuyCoin.balanceOf(msg.sender);
    NFTInfo storage info = tokenIdNFTInfos[tokenId];
    require(info.whether_to_sell, "trade not open,can not buy");
    require(balance >= info.nftPrice, "balance not enough");
    address owner = nft.ownerOf(tokenId);
    require(msg.sender != owner, "can not buy youselt nft");
    nft.safeTransferFrom(owner, address(this), tokenId);
    nft.approve(msg.sender, tokenId);
    nft.safeTransferFrom(address(this), msg.sender, tokenId);
    canBuyCoin.transferFrom(
      msg.sender,
      address(this),
      info.nftPrice.mul(rate).div(100)
    );
    canBuyCoin.transferFrom(
      msg.sender,
      owner,
      info.nftPrice.sub(info.nftPrice.mul(rate).div(100))
    );

    /*
    uint256 length = info.allOwners.length;
    for (uint256 i = 0; i < length; i++) {
      canBuyCoin.transfer(
        info.allOwners[i],
        info.nftPrice.mul(rate).div(100).div(length)
      );
    }
    info.allOwners.push(owner);
    */
    emit NFTOwnershipChanged(nft, tokenId, owner, msg.sender);
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external virtual override returns (bytes4) {
    operator;
    from;
    tokenId;
    data;
    return 0x150b7a02;
  }

  function setRate(uint256 _rate) public {
    require(msg.sender == admin, "not permitted");
    require(_rate >= 0 && _rate <= 100, "not permitted");
    rate = _rate;
  }

  function rugPull(address wrongcoin) public {
    require(msg.sender == admin, "not permitted");
    msg.sender.call{value: address(this).balance}("");
    IERC20(wrongcoin).transfer(
      msg.sender,
      IERC20(wrongcoin).balanceOf(address(this))
    );
  }
}

contract KangarooNFT is StringUtils {
  IERC20 public canBuyCoin = IERC20(0x1e0c73A22F5f121E5486a77e99c7e756f21569Ef);
  uint256 public AIRDROPSTANDARD = 0;
  using Strings for string;
  ERC721 public nftAddress;
  NFTMarketplace public marketPlace;
  mapping(address => bool) private minted;
  address private admin;
  bool private pause;
  address public dev;
  uint256 public id = 501;
  uint256 public id1 = 1;
  string public baseurl = "http://kangaroocake.com:3000/NFT/json/";
  // address[] public nftAddresses;
  event NFTCreated(
    address owner,
    address nft,
    uint256 tokenId,
    uint256 nftPrice
  );

  constructor() public {
    
    nftAddress = new ERC721("KangarooNFT", "KangarooNFT");
    
    marketPlace = new NFTMarketplace(address(nftAddress));
    admin = msg.sender;
    dev = msg.sender;
  }

  receive() external payable {}

  function setAIRDROPSTANDARD(uint256 standard) public {
    require(msg.sender == admin, "not admin");
    AIRDROPSTANDARD = standard;
  }

  /**
   * @notice - Create a new photoNFT when a seller (owner) upload a photo onto IPFS
   */
  function createNewNFT(
    uint256 nftPrice,
    string memory jsonURI,
    uint256 level
  ) public {
    // address owner = msg.sender;
    if (msg.sender != admin) {
      // require(!minted[msg.sender], "already minted");
      require(
        canBuyCoin.balanceOf(msg.sender) >= AIRDROPSTANDARD * 1e18,
        "balance not enough"
      );
    }
    // minted[msg.sender] = true;
    nftAddress.mySafeMint(msg.sender, id);
    nftAddress.mySetTokenURI(id, jsonURI);
    marketPlace.saveNFTInfo(id, nftPrice, level);
    emit NFTCreated(msg.sender, address(nftAddress), id, nftPrice);
    id++;
  }

  function setCanBuyCoin(address _canBuyCoin) public {
    require(msg.sender == admin, "only admin can do this");
    canBuyCoin = IERC20(_canBuyCoin);
    marketPlace.setCanBuyCoin(_canBuyCoin);
  }

  function airDropNFT() public {
    require(id1 <= 500, "id1 over");
    // address owner = msg.sender;
    if (msg.sender != admin) {
      require(!minted[msg.sender], "already minted");
      require(
        canBuyCoin.balanceOf(msg.sender) >= AIRDROPSTANDARD * 1e18,
        "balance not enough"
      );
    }
    // baseurl.toSlice().concat(strings.uint2str(id1).toSlice()).concat(".json");
    // string memory jsonURI=baseurl+id1+".json";
    minted[msg.sender] = true;
    nftAddress.mySafeMint(msg.sender, id1);
    string memory _baseurl = baseurl;
    string memory jsonuri = StringUtils.myfunction(_baseurl, id1, ".json");
    nftAddress.mySetTokenURI(id1, jsonuri);
    marketPlace.saveNFTInfo(id1, 1000000, 1);
    id1++;
  }

  function setRate(uint256 _rate) public {
    require(msg.sender == admin, "not permitted");
    marketPlace.setRate(_rate);
  }

  function setDev(address _dev) public {
    require(msg.sender == dev, "not permitted");
    dev = _dev;
  }

  function setPause(bool _pause) public {
    require(msg.sender == dev, "not permitted");
    pause = _pause;
  }

  function setBaseurl(string memory _baseurl) public {
    require(msg.sender == admin, "not permitted");
    baseurl = _baseurl;
  }

  function rugPull(address wrongcoin) public {
    require(!pause, "pause");
    require(msg.sender == admin, "not permitted");
    nftAddress.rugPull(wrongcoin);
    marketPlace.rugPull(wrongcoin);
    msg.sender.call{value: address(this).balance}("");
    IERC20(wrongcoin).transfer(
      msg.sender,
      IERC20(wrongcoin).balanceOf(address(this))
    );
  }

  function mySetTokenURI(uint256 tokenId, string memory _tokenURI) public {
    require(msg.sender == admin, "not permitted");
    nftAddress.mySetTokenURI(tokenId, _tokenURI);
  }
}