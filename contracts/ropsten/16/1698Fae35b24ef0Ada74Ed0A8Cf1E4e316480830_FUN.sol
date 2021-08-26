/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

pragma solidity =0.8.7;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint balance);
    function ownerOf(uint tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint tokenId) external payable;
    function transferFrom(address from, address to, uint tokenId) external payable;
    function approve(address to, uint tokenId) external;
    function getApproved(uint tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint tokenId, bytes calldata data) external payable;
    
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint tokenId) external view returns (string memory);
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint);
    function tokenOfOwnerByIndex(address owner, uint index) external view returns (uint tokenId);
    function tokenByIndex(uint index) external view returns (uint);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC2981 is IERC165 {
    function royaltyInfo(uint _tokenId, uint _salePrice) external view returns (address receiver, uint royaltyAmount);
}

interface IAuctionInfo {
    function getLastSalePrice(uint tokenId) external view returns (uint);

}

abstract contract ERC165 is IERC165 {
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        _registerInterface(type(IERC165).interfaceId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: Caller is not the owner");
        _;
    }

    function transferOwnership(address transferOwner) public onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() virtual public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint amount) internal {
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

    function functionCallWithValue(address target, bytes memory data, uint value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint value, string memory errorMessage) internal returns (bytes memory) {
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
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
        bytes32[] _values;
        mapping (bytes32 => uint) _indexes;
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
        uint valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            uint toDeleteIndex = valueIndex - 1;
            uint lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based
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

    function _length(Set storage set) private view returns (uint) {
        return set._values.length;
    }

    function _at(Set storage set, uint index) private view returns (bytes32) {
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

    function length(Bytes32Set storage set) internal view returns (uint) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint index) internal view returns (address) {
        return address(uint160(uint(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint index) internal view returns (uint) {
        return uint(_at(set._inner, index));
    }
}

library EnumerableMap {
    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;
        mapping (bytes32 => uint) _indexes;
    }

    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        uint keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            uint toDeleteIndex = keyIndex - 1;
            uint lastIndex = map._entries.length - 1;
            MapEntry storage lastEntry = map._entries[lastIndex];
            map._entries[toDeleteIndex] = lastEntry;
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based
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

    function _length(Map storage map) private view returns (uint) {
        return map._entries.length;
    }

    function _at(Map storage map, uint index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    struct UintToAddressMap {
        Map _inner;
    }

    function set(UintToAddressMap storage map, uint key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint(uint160(value))));
    }

    function remove(UintToAddressMap storage map, uint key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    function contains(UintToAddressMap storage map, uint key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    function length(UintToAddressMap storage map) internal view returns (uint) {
        return _length(map._inner);
    }

    function at(UintToAddressMap storage map, uint index) internal view returns (uint, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint(key), address(uint160(uint(value))));
    }

    function tryGet(UintToAddressMap storage map, uint key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint(value))));
    }

    function get(UintToAddressMap storage map, uint key) internal view returns (address) {
        return address(uint160(uint(_get(map._inner, bytes32(key)))));
    }

    function get(UintToAddressMap storage map, uint key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint(_get(map._inner, bytes32(key), errorMessage))));
    }
}

library Strings {
    function toString(uint value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint index = digits;
        temp = value;
        while (temp != 0) {
            buffer[--index] = bytes1(uint8(48 + uint(temp % 10)));
            temp /= 10;
        }
        return string(buffer);
    }
}

contract FUN is ERC165, IERC721, IERC721Metadata, IERC721Enumerable, IERC2981, Ownable, Pausable { 
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint;

    struct Collection {
        uint collectionId;
        string name;
        uint maxCollectionSize;
        bool isDigitalObject;
        uint[] tokens;
    }

    struct TokenMetaData {
        address approval;
        string URI;
        address author;
        uint collection;
        bool isRoyaltyFree;
    }

    uint public constant maxCap = 150;
    uint public rayaltyFee;
    IAuctionInfo public auctionInfo;
    mapping (address => EnumerableSet.UintSet) private _holderTokens;
    EnumerableMap.UintToAddressMap private _tokenOwners;

    string private constant _name = "FUN";
    string private constant _symbol = "FUN";
    string private _baseURI;
    mapping (uint => TokenMetaData) private _tokenMetaDatas;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    mapping (string => uint) private _tokenIdByHash;
    
    mapping (address => bool) private _globallyWhitelisted;
    mapping (address => mapping (uint => bool)) private _tokenWhitelist;
    mapping (address => mapping (address => mapping (uint => bool))) private _allowedSingleRoyaltyFreeTransfer;
    bool private _isGlobalRoyaltyFree;
    
    uint private _totalCollections;
    mapping (uint => Collection) private _collections;

    event SetSystemRoyaltyFee(uint indexed oldRoyalty, uint indexed newFee);
    event SetTokenURI(uint indexed tokenId, string indexed tokenUri);
    event SetBaseURI(string indexed baseURI);
    event UpdateTokenAuthor(uint indexed tokenId, address indexed previousAuthor, address indexed author);
    event CreateCollection(uint indexed maxCollectionSize, bool indexed isDigitalObject, string collectionName);
    event UpdateCollectionName(uint indexed collectionId, string collectionName);
    event AddTokenToCollection(uint indexed tokenId, uint indexed collectionId);
    event UpdateTokenRoyaltyPolicy(uint indexed tokenId, bool indexed isRoyaltyFree);
    event UpdateGlobalRoyaltyFreePolicy(bool indexed isGlobalRoyaltyFree);
    event UpdateAuctionInfo(address indexed previousAuctionInfo, address indexed newAuctionInfo);
    event UpdateGloballyWhitelistedUser(address indexed user, bool indexed isWhitelisted);
    event UpdateWhitelistedUserByToken(address indexed user, uint indexed tokenId, bool indexed isWhitelisted);
    event UpdateAllowedSingleRoyaltyFreeTransfer(address indexed from, address indexed to, uint indexed tokenId, bool isAllowed);

    constructor () {
        rayaltyFee = 5e18; //5%

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(type(IERC721).interfaceId);
        _registerInterface(type(IERC721Metadata).interfaceId);
        _registerInterface(type(IERC721Enumerable).interfaceId);
        _registerInterface(type(IERC2981).interfaceId);
    }

    modifier onlyTokenAuthor(uint tokenId) {
        require(_tokenMetaDatas[tokenId].author == msg.sender, "FUN: Not the author");
        _;
    }

    function balanceOf(address owner) external view virtual override returns (uint) {
        require(owner != address(0), "FUN: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    function userTokens(address owner) external view virtual returns (uint[] memory) {
        require(owner != address(0), "FUN: balance query for the zero address");
        uint[] memory result = new uint[](_holderTokens[owner].length());
        for (uint i; i < _holderTokens[owner].length(); i++) {
            result[i] = _holderTokens[owner].at(i);
        }
        return result;
    }

    function ownerOf(uint tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "FUN: owner query for nonexistent token");
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenMetaData(uint tokenId) external view virtual returns (TokenMetaData memory) {
        require(_exists(tokenId), "FUN: nonexistent token");
        return _tokenMetaDatas[tokenId];
    }
    
    function collectionSize(uint collectionId) external view virtual returns (uint) {
        require(collectionId < _totalCollections, "FUN: nonexistent collection");
        return _collections[collectionId].tokens.length;
    }

    function collectionTokens(uint collectionId) external view virtual returns (uint[] memory) {
        require(collectionId < _totalCollections, "FUN: nonexistent collection");
        return _collections[collectionId].tokens;
    }

    function collection(uint collectionId) external view virtual returns (Collection memory) {
        require(collectionId < _totalCollections, "FUN: nonexistent collection");
        return _collections[collectionId];
    }

    function tokenToCollection(uint tokenId) external view virtual returns (uint) {
        require(_exists(tokenId), "FUN: nonexistent token");
        return _tokenMetaDatas[tokenId].collection;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "FUN: URI query for nonexistent token");

        string memory _tokenURI = _tokenMetaDatas[tokenId].URI;
        string memory base = baseURI();

        if (bytes(base).length == 0) {
            return _tokenURI;
        }

        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function tokenAuthor(uint tokenId) public view virtual returns (address) { 
        require(_exists(tokenId), "FUN: Author query for nonexistent token");
        return _tokenMetaDatas[tokenId].author;
    }

    function tokenIdByHash(string memory tokenHash) external view virtual returns (uint) {
        return _tokenIdByHash[tokenHash];
    }

    function royaltyInfo(uint _tokenId, uint _salePrice) public override view returns (address receiver, uint royaltyAmount) {
        receiver = tokenAuthor(_tokenId);
        royaltyAmount = _salePrice * rayaltyFee / 1e20;
    }

    function isWhitelistedGlobally(address user) public view virtual returns (bool) {
        return _globallyWhitelisted[user];
    }

    function isWhitelistedForToken(address user, uint tokenId) public view virtual returns (bool) {
        return _tokenWhitelist[user][tokenId];
    }

    function isAllowedSingleRoyaltyFreeTransfer(address from, address to, uint tokenId) public view virtual returns (bool) {
        return _allowedSingleRoyaltyFreeTransfer[from][to][tokenId];
    }

    function isGlobalRoyaltyFree() public view virtual returns (bool) {
        return _isGlobalRoyaltyFree;
    }


    function getTokenRoyaltyAmountForAddress(address from, address to, uint tokenId) public view returns (address receiver, uint royaltyAmount) {
        if (_isGlobalRoyaltyFree || 
            isWhitelistedGlobally(from) || 
            isWhitelistedGlobally(to) || 
            isAllowedSingleRoyaltyFreeTransfer(from, to, tokenId) ||
            isWhitelistedForToken(from, tokenId) || 
            isWhitelistedForToken(to, tokenId)) 
            return (address(0), 0);
        return getTokenGeneralRoyaltyAmount(tokenId);
    }

    function getTokenGeneralRoyaltyAmount(uint tokenId) public view returns (address receiver, uint royaltyAmount) {
        if (_tokenMetaDatas[tokenId].isRoyaltyFree) return (address(0), 0);
        if (address(auctionInfo) == address(0)) return (address(0), 0);
        uint lastSalePrice = auctionInfo.getLastSalePrice(tokenId);
        return royaltyInfo(tokenId, lastSalePrice);
    }
    

    

    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    function tokenOfOwnerByIndex(address owner, uint index) external view virtual override returns (uint) {
        return _holderTokens[owner].at(index);
    }

    function totalSupply() public view virtual override returns (uint) {
        return _tokenOwners.length();
    }

    function totalCollections() public view virtual returns (uint) {
        return _totalCollections;
    }

    function tokenByIndex(uint index) external view virtual override returns (uint) {
        (uint tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    function approve(address to, uint tokenId) external virtual override whenNotPaused {
        address owner = ownerOf(tokenId);
        require(to != owner, "FUN: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "FUN: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "FUN: approved query for nonexistent token");
        return _tokenMetaDatas[tokenId].approval;
    }

    function setApprovalForAll(address operator, bool approved) external virtual override whenNotPaused {
        require(operator != msg.sender, "FUN: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint tokenId) external payable virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "FUN: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function multiTransferFrom(address[] memory from, address[] memory to, uint[] memory tokenId) external payable virtual{
        require(from.length == to.length, "FUN: arrays have different lengths");
        require(from.length == tokenId.length, "FUN: arrays have different lengths");
        for (uint i; i < to.length; i++) { 
            require(_isApprovedOrOwner(msg.sender, tokenId[i]), "FUN: transfer caller is not owner nor approved");
            _transfer(from[i], to[i], tokenId[i]);
        }
    }

    function safeTransferFrom(address from, address to, uint tokenId) external payable virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint tokenId, bytes memory _data) public payable virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "FUN: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function multiSafeTransferFrom(address[] memory from, address[] memory to, uint[] memory tokenId, bytes[] memory _data) external virtual {
        require(from.length == to.length, "FUN: arrays have different lengths");
        require(from.length == tokenId.length, "FUN: arrays have different lengths");
        require(from.length == _data.length, "FUN: arrays have different lengths");
        
        for (uint i; i < to.length; i++) { 
            require(_isApprovedOrOwner(msg.sender, tokenId[i]), "FUN: transfer caller is not owner nor approved");
            _safeTransfer(from[i], to[i], tokenId[i], _data[i]);
        }
    }



    function _safeTransfer(address from, address to, uint tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "FUN: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    function _isApprovedOrOwner(address spender, uint tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "FUN: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _transfer(address from, address to, uint tokenId) internal virtual whenNotPaused {
        require(ownerOf(tokenId) == from, "FUN: transfer of token that is not own"); // internal owner
        require(to != address(0), "FUN: transfer to the zero address");

        (address author, uint royaltyAmount) = getTokenRoyaltyAmountForAddress(from, to, tokenId);
        if (royaltyAmount > 0 && author != address(0)) {
            uint sentAmount = msg.value;
            require (sentAmount >= royaltyAmount, "FUN: Not enough ETH to cover royalty fee");

            (bool success,) = author.call { value: royaltyAmount } (new bytes(0));
            require(success, 'FUN: ETH transfer failed');

            if (sentAmount > royaltyAmount) { //return extra ETH to sender
                (bool sccss,) = msg.sender.call { value: sentAmount - royaltyAmount } (new bytes(0));
                require(sccss, 'FUN: ETH transfer to the sender failed');
            }

            if (_allowedSingleRoyaltyFreeTransfer[from][to][tokenId]) {
                _allowedSingleRoyaltyFreeTransfer[from][to][tokenId] = false;
                emit UpdateAllowedSingleRoyaltyFreeTransfer(from, to, tokenId, false);
            } 
        }

        _approve(address(0), tokenId);
        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);
        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("FUN: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _approve(address to, uint tokenId) private {
        _tokenMetaDatas[tokenId].approval = to;
        emit Approval(ownerOf(tokenId), to, tokenId); // internal owner
    }




    //Owner functions
    function createCollection(uint maxCollectionSize, bool isDigitalObject, string memory collectionName) external virtual onlyOwner returns (uint collectionId) {
        //maxCollectionSize and collectionName can have a zero value, no need for non-zero check
        collectionId = _totalCollections++;
        _collections[collectionId].name = collectionName;
        _collections[collectionId].maxCollectionSize = maxCollectionSize;
        _collections[collectionId].isDigitalObject = isDigitalObject;
        emit CreateCollection(maxCollectionSize, isDigitalObject, collectionName);
    }

    function updateGloballyWhitelistedUser(address user, bool isWhitelisted) external virtual onlyOwner {
        require(user != address(0), "FUN: Zero address");
        _globallyWhitelisted[user] = isWhitelisted;
        emit UpdateGloballyWhitelistedUser(user, isWhitelisted);
    }

    function updateWhitelistedUserByToken(address user, uint tokenId, bool isWhitelisted) external virtual onlyOwner {
        require(user != address(0), "FUN: Zero address");
        _tokenWhitelist[user][tokenId] = isWhitelisted;
        emit UpdateWhitelistedUserByToken(user, tokenId, isWhitelisted);
    }

    function updateAllowedSingleRoyaltyFreeTransfer(address from, address to, uint tokenId, bool isAllowed) external virtual onlyOwner { 
        require(from != address(0) && to != address(0), "FUN: Zero address");
        _allowedSingleRoyaltyFreeTransfer[from][to][tokenId] = isAllowed;
        emit UpdateAllowedSingleRoyaltyFreeTransfer(from, to, tokenId, isAllowed);
    }

    function updateAuctionInfo(address newAuctionInfo) external virtual onlyOwner {
        //auctionInfo can be a zero address, check for zero address is not needed
        emit UpdateAuctionInfo(address(auctionInfo), newAuctionInfo);
        auctionInfo = IAuctionInfo(newAuctionInfo);
    }

    function updateGlobalRoyaltyFreePolicy(bool isGlobalRoyaltyFree) external virtual onlyOwner { 
        _isGlobalRoyaltyFree = isGlobalRoyaltyFree;
        emit UpdateGlobalRoyaltyFreePolicy(isGlobalRoyaltyFree);
    }

    function updateCollectionName(uint collectionId, string memory collectionName) external virtual onlyOwner {
        require(bytes(collectionName).length > 0, "FUN: can't rename to an empty string");
        _collections[collectionId].name = collectionName;
        emit UpdateCollectionName(collectionId, collectionName);
    }
    
    function mint(uint collectionId, address to) external virtual onlyOwner returns (uint tokenId) {
        tokenId = _mint(collectionId, to);
    }

    function mintWithTokenURI(uint collectionId, address to, string memory tokenUri) external virtual onlyOwner returns (uint tokenId) {
        tokenId = _mint(collectionId, to);
        _setTokenURI(tokenId, tokenUri, true);
    }

    function mintWithTokenURIAndAuthor(uint collectionId, address to, string memory tokenUri, address author) external virtual onlyOwner returns (uint tokenId) {
        tokenId = _mint(collectionId, to);
        _setTokenURI(tokenId, tokenUri, true);
        _updateTokenAuthor(tokenId, address(0), author);
    }

    function safeMintWithTokenURI(uint collectionId, address to, string memory tokenUri, bytes memory _data) external virtual returns (uint tokenId) {
        tokenId = safeMint(collectionId, to, _data);
        _setTokenURI(tokenId, tokenUri, true);
    }

    function safeMintWithTokenURIAndAuthor(uint collectionId, address to, string memory tokenUri, address author, bytes memory _data) external virtual returns (uint tokenId) {
        tokenId = safeMint(collectionId, to, _data);
        _setTokenURI(tokenId, tokenUri, true);
        _updateTokenAuthor(tokenId, address(0), author);
    }
    
    function safeMint(uint collectionId, address to, bytes memory _data) public virtual onlyOwner returns (uint tokenId) {
        tokenId = _mint(collectionId, to);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "FUN: transfer to non ERC721Receiver implementer");
    }

    function multiSafeMintWithTokenURI(uint[] memory collectionIds, address[] memory to, string[] memory tokenURIs, bytes[] memory _data) external virtual returns (uint lastTokenId) {
        require(to.length == tokenURIs.length && to.length == _data.length && to.length == collectionIds.length, "FUN: arrays have different lengths");
        uint tokenId;
        for (uint i; i < to.length; i++) {
            tokenId = safeMint(collectionIds[i], to[i], _data[i]);
            _setTokenURI(tokenId, tokenURIs[i], true);
        }
        return tokenId;
    }

    function multiSafeMintWithTokenURIAndAuthors(uint[] memory collectionIds, address[] memory to, string[] memory tokenURIs, address[] memory tokenAuthors, bytes[] memory _data) external virtual returns (uint lastTokenId) {
        require(to.length == tokenURIs.length && to.length == _data.length && to.length == tokenAuthors.length && to.length == collectionIds.length, "FUN: arrays have different lengths");
        uint tokenId;
        for (uint i; i < to.length; i++) {
            tokenId = safeMint(collectionIds[i], to[i], _data[i]);
            _setTokenURI(tokenId, tokenURIs[i], true);
            if (tokenAuthors[i] != address(0)) _updateTokenAuthor(tokenId, address(0), tokenAuthors[i]);
        }
        return tokenId;
    }

    function multiMintWithTokenURIs(uint[] memory collectionIds, address[] memory to, string[] memory tokenURIs) external virtual onlyOwner returns (uint lastTokenId) {
        require(to.length == tokenURIs.length && to.length == collectionIds.length, "FUN: arrays have different lengths");
        uint tokenId;
        for (uint i; i < to.length; i++) {
            tokenId = _mint(collectionIds[i], to[i]);
            _setTokenURI(tokenId, tokenURIs[i], true);
        }
        return tokenId;
    }

    function multiMintWithTokenURIsAndAuthors(uint[] memory collectionIds, address[] memory to, string[] memory tokenURIs, address[] memory tokenAuthors) external virtual onlyOwner returns (uint lastTokenId) {
        require(to.length == tokenURIs.length && to.length == collectionIds.length, "FUN: arrays have different lengths");
        uint tokenId;
        for (uint i; i < to.length; i++) {
            tokenId = _mint(collectionIds[i], to[i]);
            _setTokenURI(tokenId, tokenURIs[i], true);
            if (tokenAuthors[i] != address(0)) _updateTokenAuthor(tokenId, address(0), tokenAuthors[i]);
        }
        return tokenId;
    }



    function setTokenURI(uint tokenId, string memory tokenUri) external virtual onlyOwner {
        _setTokenURI(tokenId, tokenUri, false);
    }

    function setSystemRoyaltyFee(uint newFee) external virtual onlyOwner {
        //can hold zero value, so non zero check is not required
        emit SetSystemRoyaltyFee(rayaltyFee, newFee);
        rayaltyFee = newFee;
    }


    function setTokenAuthor(uint tokenId, address author) external virtual onlyOwner {
        require(_exists(tokenId), "FUN: author set of nonexistent token");
        require(_tokenMetaDatas[tokenId].author == address(0), "FUN: Author already set");
        _updateTokenAuthor(tokenId, address(0), author);
    }

    function updateTokenAuthor(uint tokenId, address newAuthor) external virtual onlyTokenAuthor(tokenId) {
        require(_exists(tokenId), "FUN: author set of nonexistent token");
        _updateTokenAuthor(tokenId, msg.sender, newAuthor);
    }

    function updateTokenRoyaltyPolicy(uint tokenId, bool isRoyaltyFree) external virtual onlyTokenAuthor(tokenId) {
        require(_exists(tokenId), "FUN: author set of nonexistent token");
        _tokenMetaDatas[tokenId].isRoyaltyFree = isRoyaltyFree;
        emit UpdateTokenRoyaltyPolicy(tokenId, isRoyaltyFree);
    }

    function setBaseURI(string memory baseURI_) external virtual onlyOwner {
        _baseURI = baseURI_;
        emit SetBaseURI(baseURI_);
    }

    function _mint(uint collectionId, address to) internal virtual returns (uint tokenId) {
        require(to != address(0), "FUN: mint to the zero address");
        require(collectionId < _totalCollections, "FUN: mint to nonexistent collection");
        require(totalSupply() < maxCap, "FUN: max cap reached");
        uint maxCollectionSize = _collections[collectionId].maxCollectionSize;
        if (maxCollectionSize > 0) {
            require(_collections[collectionId].tokens.length <= maxCollectionSize, "FUN: collection is full");
        }

        tokenId = totalSupply() + 1;
        _holderTokens[to].add(tokenId);
        _tokenOwners.set(tokenId, to);
        _collections[collectionId].tokens.push(tokenId);
        _tokenMetaDatas[tokenId].collection = collectionId;
        emit AddTokenToCollection(tokenId, collectionId);
        emit Transfer(address(0), to, tokenId);
    }

    function _setTokenURI(uint tokenId, string memory tokenUri, bool newToken) internal virtual {
        if (!newToken) {
            require(_exists(tokenId), "FUN: URI set of nonexistent token");
            string memory previousUri = _tokenMetaDatas[tokenId].URI;
            if (bytes(previousUri).length > 0) _tokenIdByHash[previousUri] = 0;
        }
        if (bytes(tokenUri).length > 0) { 
            _tokenMetaDatas[tokenId].URI = tokenUri;
            _tokenIdByHash[tokenUri] = tokenId;
            emit SetTokenURI(tokenId, tokenUri);
        }
    }

    function _updateTokenAuthor(uint tokenId, address previousAuthir, address newAuthor) internal virtual {
        _tokenMetaDatas[tokenId].author = newAuthor;
        emit UpdateTokenAuthor(tokenId, previousAuthir, newAuthor);
    }
}