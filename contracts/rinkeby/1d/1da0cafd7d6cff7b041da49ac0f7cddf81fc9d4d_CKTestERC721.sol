/**
 *Submitted for verification at Etherscan.io on 2021-12-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
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

pragma solidity >=0.6.0 <0.8.0;

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

abstract contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    mapping(bytes4 => bool) private _supportedInterfaces;
    constructor () {
        _registerInterface(_INTERFACE_ID_ERC165);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

pragma solidity >=0.6.0 <0.8.0;

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
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
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
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

pragma solidity >=0.6.0 <0.8.0;

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
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
    struct AddressSet {
        Set _inner;
    }
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }
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
        MapEntry[] _entries;
        mapping (bytes32 => uint256) _indexes;
    }
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) { 
            map._entries.push(MapEntry({ _key: key, _value: value }));
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
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); 
        return (true, map._entries[keyIndex - 1]._value);
    }
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); 
        return map._entries[keyIndex - 1]._value; 
    }
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); 
        return map._entries[keyIndex - 1]._value; 
    }
    struct UintToAddressMap {
        Map _inner;
    }
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
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
        return (uint256(key), address(uint160(uint256(value))));
    }
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
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
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    mapping (address => EnumerableSet.UintSet) private _holderTokens;
    EnumerableMap.UintToAddressMap private _tokenOwners;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    string private _name;
    string private _symbol;
    mapping (uint256 => string) private _tokenURIs;
    string private _baseURI;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return string(abi.encodePacked(base, tokenId.toString()));
    }
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _tokenOwners.length();
    }
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
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
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
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
        address owner = ERC721.ownerOf(tokenId); // internal owner
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
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

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

abstract contract Ownable is Context {
    address private _owner;
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
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface TOKEN20 is IERC20 {
    function mint(address to, uint256 amount) external;
    function burnBurner(address from, uint256 amount) external;
}

contract CKTestERC721 is ERC721, Ownable {

    using Strings for uint256;
    using SafeMath for uint256;

    // Sale
    uint8 private SALE_STATE;
    uint256 private SALE_SUPPLY = 1000;
    uint256 private SALE_MINT = 20;
    uint256 private SALE_PRICE = 0.04 ether;
    
    // Presale
    uint256 private PRESALE_MINT = 4;
    uint256 private PRESALE_PRICE  = 0.02 ether;
    address private WHITELIST_SIGNER = 0x39ab1683F6548AaF0456F1e0dBe8B5C3320F7723;
    mapping(address => uint256) public tokensClaimed;

    // promotion
    bool private PROMOTION_ACTIVE;
    uint256 private PROMOTION_BUY;
    uint256 private PROMOTION_GET;  

    // ERC20
    TOKEN20 public REWARD_TOKEN;
    struct RewardsBalance {
        uint256 balance;
        uint256 dividend;
        uint256 lastTimestamp;
    }
    mapping(uint => RewardsBalance) private rewards;
    uint256 constant private RewardsDividendRate = 1440;
    uint256 constant private RewardsInitialIssuance = 1000;
    uint256 public REWARD_UPGRAD_PRICE = 600 ether;
    event rewardsClaimed(address indexed user, uint256 reward);
    event dividendUptated(uint256 indexed index, uint256 dividend);

    // signature
    mapping(uint256 => bool) private _tokenSignatures;
    event Signed(uint256 indexed index, bool signature);
    uint256 public SIGNATURE_PRICE = 900 ether;
    string signedBaseURI;

    // Team
    address private artistAddress = 0xf69f8619c672df45191959a0fF9C06C1536107c4;

    constructor() ERC721("CKT", "CK") {
        string memory _baseURI = "ipfs://QmeCbrj382SwUYxz5ctNd5aK2UojJTdJ65yPRScxTKxYxT/";
        _setBaseURI(_baseURI);
        giveaway(msg.sender, 1);
        giveaway(artistAddress, 1);
    }

    function tokensOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    // State
    function onlyState(uint8 _state) internal view {
		require(SALE_STATE >= _state, "Not Allowed");
	}

    function setSaleState(uint8 _state) external onlyOwner {
		SALE_STATE = _state;
	}
    
    /*
    * =====================================
    * Giveway
    * =====================================
    */
    function giveaway(address _to, uint256 _numberOfTokens) public  {
        require(msg.sender == owner() || msg.sender == address(artistAddress), "Not team!");
        require(_to != address(0), "Invalid address");
        require(totalSupply().add(_numberOfTokens) <= SALE_SUPPLY, "Purchase would exceed max supply");
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < _numberOfTokens; i++) {
            _safeMint(_to, supply + i);
            initializeRewardsBalance(supply + i);
        }
    }
    
    function giveaway(address[] calldata _addresses, uint256[] calldata _numberOfTokens) external onlyOwner {
        require(_addresses.length == _numberOfTokens.length, "Not team!");
        for (uint256 i = 0; i < _addresses.length; i++){
            giveaway(_addresses[i], _numberOfTokens[i]);
        }
    }

    // Promotion
    function togglePromotion() external onlyOwner {
        PROMOTION_ACTIVE = !PROMOTION_ACTIVE;
    }

    function setPromotion(uint256 _buy, uint256 _get) external onlyOwner {
        require(_buy <= _get, "Invalid promotion");
        PROMOTION_BUY = _buy;
        PROMOTION_GET = _get;
    }

    function promotionCalcul(uint256 _numberOfTokens) public view returns (uint256) {
        uint256 numberOfTokens = _numberOfTokens;
        if(PROMOTION_GET != PROMOTION_BUY && PROMOTION_ACTIVE){
            numberOfTokens = ((PROMOTION_GET - PROMOTION_BUY) * (_numberOfTokens / (PROMOTION_GET - 1))) + _numberOfTokens;
        }
        return numberOfTokens;
    }

    //PreSale
    function setPresalePrice(uint256 _price) external onlyOwner {
        PRESALE_PRICE = _price;
    }

    function setMaxPresaleMint(uint256 _limit) public onlyOwner() {
        PRESALE_MINT = _limit;
    }

    function mintPresale(uint256 _numberOfTokens, bytes memory _signature) public payable {
        onlyState(1);
        require(isWhitelisted(msg.sender, _signature), "Not whitelisted");
        uint256 ownerMintedCount = tokensClaimed[msg.sender];
        require(ownerMintedCount + _numberOfTokens <= PRESALE_MINT, "Max mint exceeded");
        require(totalSupply().add(promotionCalcul(_numberOfTokens)) <= SALE_SUPPLY, "Purchase would exceed max supply");
        require(PRESALE_PRICE.mul(_numberOfTokens) <= msg.value, "Ether value sent is not correct");
        for(uint256 i = 0; i < promotionCalcul(_numberOfTokens); i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            initializeRewardsBalance(mintIndex);
            tokensClaimed[msg.sender]++;
        }
    }

    // whitelist
    function isWhitelisted(address _address, bytes memory _signature) public view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(_address));
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == WHITELIST_SIGNER;
    }

    function setSigner(address _signer) public onlyOwner {
        require(_signer != address(0), "Invalid address");
        WHITELIST_SIGNER = _signer;
    }

    function getEthSignedMessageHash(bytes32 _messageHash) private pure returns (bytes32){
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) private pure returns (address){
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v){
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    // Public Sale
    function setSaletPrice(uint256 _price) external onlyOwner {
        SALE_PRICE = _price;
    }

    function setMaxSaleMint(uint256 _limit) external onlyOwner {
        SALE_MINT = _limit;
    }

    function mint(uint256 _numberOfTokens) external payable {
        onlyState(2);
        require(_numberOfTokens > 0 && _numberOfTokens <= SALE_MINT, "Invalid amount to mint per once");
        require(totalSupply().add(promotionCalcul(_numberOfTokens)) <= SALE_SUPPLY, "Purchase would exceed max supply");
        require(SALE_PRICE.mul(_numberOfTokens) <= msg.value, "Ether value sent is not correct");
        for(uint256 i = 0; i < promotionCalcul(_numberOfTokens); i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            initializeRewardsBalance(mintIndex);
        }
    }
    
    // Withdraw
    function withdraw() public payable{
        require(msg.sender == owner() || msg.sender == address(artistAddress), "Not team!");
        uint256 balance = address(this).balance;
        require(balance > 0, 'Insufficient balance');
        uint256 artistBalance = balance.mul(50).div(100);
        uint256 devBalance = balance.sub(artistBalance);
        (bool withdrawArtist, ) = payable(artistAddress).call{value: artistBalance}("");
        (bool withdrawDev, ) = payable(owner()).call{value: devBalance}("");
        require(withdrawArtist && withdrawDev);
    }

    function withdrawTokens(IERC20 _token) external onlyOwner {
        require(address(_token) != address(0));
        _token.transfer(owner(), _token.balanceOf(address(this)));
    }

    /*
    * =====================================
    * ERC20 Tokens
    * =====================================
    */

    // set ERC20 address
    function setRewardToken(address _newToken) public onlyOwner {
        require(_newToken != address(0), "Invalid address.");
        REWARD_TOKEN = TOKEN20(_newToken);
    }

    // show dividend balance
    function getRewardsBalance(uint _id) public view returns (uint256) {
        require(rewards[_id].dividend >= RewardsDividendRate, "Not been minted yet");
        RewardsBalance storage rewardsBalance = rewards[_id];
        return rewardsBalance.balance.add(rewardsBalance.dividend.mul(block.timestamp.sub(rewardsBalance.lastTimestamp)).div(86400)); // 1 day.
    }

    // show total dividends
    function getTotalRewardsBalance(address _address) public view returns (uint256) {
        require(_address != address(0), "Invalid address");
        uint256[] memory tokenIds = tokensOfOwner(_address);
        require(tokenIds.length > 0, "This address does not have a token");
        uint256 totalBalance = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            uint id = tokenIds[i];
            uint amount =  getRewardsBalance(id);
            totalBalance = totalBalance.add(amount);
        }
        return totalBalance;
    }

    // claim dividend
    function claimRewards(uint _id) public returns (uint256) {
        require(REWARD_TOKEN != TOKEN20(0), "Reward token is not defined");
        require(rewards[_id].dividend >= RewardsDividendRate, "Not been minted yet");
        require(msg.sender == ownerOf(_id), "You do not own the ID specified");
        uint256 totalSpent = 0;
        uint256 amount = getRewardsBalance(_id);
        RewardsBalance storage rewardsBalance = rewards[_id];
        rewardsBalance.balance = getRewardsBalance(_id).sub(amount);
        rewardsBalance.lastTimestamp = block.timestamp;
        totalSpent = totalSpent.add(amount);
        if (totalSpent > 0) {
            totalSpent = totalSpent * (10 ** 18);
            REWARD_TOKEN.mint(ownerOf(_id), totalSpent);
            emit rewardsClaimed(ownerOf(_id), totalSpent);
        }
        return totalSpent;
    }

    // claim total dividends
    function claimAllRewards(address _address) public returns (uint256) {
        require(REWARD_TOKEN != TOKEN20(0), "Reward token is not defined");
        require(_address != address(0), "Invalid address");
        require(msg.sender == address(_address), "You do not own the address specified");
        uint256[] memory tokenIds = tokensOfOwner(_address);
        require(tokenIds.length > 0, "This address does not have a token");
        uint256 totalSpent = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            uint id = tokenIds[i];
            uint amount =  getRewardsBalance(id);
            RewardsBalance storage rewardsBalance = rewards[id];
            rewardsBalance.balance = getRewardsBalance(id).sub(amount);
            rewardsBalance.lastTimestamp = block.timestamp;
            totalSpent = totalSpent.add(amount);
        }
        if (totalSpent > 0) {
            totalSpent = totalSpent * (10 ** 18);
            REWARD_TOKEN.mint(_address, totalSpent);
            emit rewardsClaimed(_address, totalSpent);
        }
        return totalSpent;
    }

    /*
    * =====================================
    * Dividend
    * =====================================
    */
    // upgrad dividend price
    function setRewardsUpgradPrice(uint256 _upgradPrice) external onlyOwner {
        REWARD_UPGRAD_PRICE = _upgradPrice;
    }

    function initializeRewardsBalance(uint _id) private {
        rewards[_id] = RewardsBalance(RewardsInitialIssuance, RewardsDividendRate, block.timestamp);
    }

    // show dividend level
    function getRewardDividend(uint _id) public view returns (uint256) {
        require(rewards[_id].dividend >= RewardsDividendRate, "Not been minted yet");
        return rewards[_id].dividend;
    }

    // upgrad dividend (admin free)
    function setRewardDividend(uint _id, uint256 _amount) public  {
        require(REWARD_TOKEN != TOKEN20(0), "Reward token is not defined");
        require(rewards[_id].dividend >= RewardsDividendRate, "Not been minted yet");
        if (msg.sender != owner()) {
            require(msg.sender == ownerOf(_id), "You do not own the ID specified");
            uint256 tokenAmount = _amount.mul(REWARD_UPGRAD_PRICE);
            REWARD_TOKEN.burnBurner(msg.sender, tokenAmount);
        }    
        RewardsBalance storage rewardsBalance = rewards[_id];
        rewardsBalance.balance = getRewardsBalance(_id);
        rewardsBalance.lastTimestamp = block.timestamp;
        rewardsBalance.dividend = rewardsBalance.dividend.add(_amount);     
        emit dividendUptated(_id, rewardsBalance.dividend);   
    }
    
    // upgrad dividend bulk
    function bulkRewardDividend(uint[] calldata _ids, uint256 _amount) external {
        for (uint256 i = 0; i < _ids.length; i++){
            setRewardDividend(_ids[i], _amount);
        }
    }
    
    /*
    * =====================================
    * Signed
    * =====================================
    */

    // check if signed
    function isSigned(uint256 _id) public view returns (bool) {
        return _tokenSignatures[_id];
    }

    // signed token (admin free)
    function setSignature(uint256 _id) public {
        require(REWARD_TOKEN != TOKEN20(0), "Reward token is not defined");
        require(bytes(signedBaseURI).length != 0, "signedBaseURI is not found");
        if (isSigned(_id) == false){
            if (msg.sender != owner()) {
                address owner = ownerOf(_id);
                require(msg.sender == owner, "You do not own the ID specified");
                REWARD_TOKEN.burnBurner(msg.sender, SIGNATURE_PRICE);
            }
            _tokenSignatures[_id] = true;
        }
        emit Signed(_id, isSigned(_id));
    }

    // signed token bulk
    function bulkSignature(uint256[] calldata _ids) external {
        for (uint256 i = 0; i < _ids.length; i++){
            setSignature(_ids[i]);
        }
    }

    // signed token price
    function setSignaturePrice(uint256 _price) external onlyOwner {
        SIGNATURE_PRICE = _price;
    }
    
    // set baseURI signed
    function setSignedBaseURI(string memory _signedBaseURI) external onlyOwner {
        signedBaseURI = _signedBaseURI;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        _setBaseURI(_baseURI);
    }

    // update if transfert
	modifier resetSignature(uint256 _id) {
		if (isSigned(_id)){
            _tokenSignatures[_id] = false;
		}
		_;
	}

    function transferFrom(address from, address to, uint256 tokenId) public override resetSignature(tokenId){
		ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override resetSignature(tokenId) {
        ERC721.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override resetSignature(tokenId) {
		ERC721.safeTransferFrom(from, to, tokenId, _data);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if( isSigned(tokenId) ){
            string memory currentSignedBaseURI = signedBaseURI;
            return bytes(currentSignedBaseURI).length > 0 ? string(abi.encodePacked(currentSignedBaseURI, tokenId.toString())) : "";
        }
        string memory currentBaseURI = baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
    }

    /*
    * =====================================
    * Comunauty chest
    * =====================================
    */
    // set address
    /*
    * =====================================
    * States
    * =====================================
    */
    function saleState() external view returns (uint8, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
            SALE_STATE,
            PRESALE_PRICE,
            PRESALE_MINT,
            SALE_PRICE,
            SALE_MINT,
            SALE_SUPPLY,
            totalSupply()
            );
    }

    function promotionState() external view returns (bool, uint256, uint256 ) {
        return (
            PROMOTION_ACTIVE,
            PROMOTION_BUY,
            PROMOTION_GET
            );
    }

}