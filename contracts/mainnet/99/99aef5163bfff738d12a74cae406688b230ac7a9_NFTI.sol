/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private  _owner;

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult( bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
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

library EnumerableMap {
    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;
        mapping(bytes32 => uint256) _indexes;
    }

    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
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
        require(keyIndex != 0, errorMessage);
        return map._entries[keyIndex - 1]._value;
    }

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

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint256 burnQuantity) external returns (bool);
    function mintTokens(address account, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract NFTI is IERC721, IERC721Metadata, IERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(uint256 => uint256) _expandedTokens;
    mapping(address => EnumerableSet.UintSet) private _holderTokens;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(address => uint256) _privateTokens;

    EnumerableMap.UintToAddressMap private _tokenOwners;

    address private _ISETAddress;

    uint256 private _expandedTokensSupply = 0;
    uint256 private _seed = 679;

    /*
        Magic numbers(we hard code constants for save gas)
        SALE_SUPPLY = 1294;
        SALE_SUPPLY_PER_PERSON = 10;
        EXPAND_SUPPLY = 1287;
        EXPAND_SUPPLY_PER_PERSON = 11;
        GIFT_SUPPLY = 20;
        BUY_NFTS_ONCE = 10;
        EXPAND_COST = 100;
        BURN_COST = 35;
        BUY_COST = 50;
        
        FIRST_PRICE = 100000000000000000; // 0.1 ETH
        SECOND_PRICE = 300000000000000000; // 0.3 ETH
        THIRD_PRICE = 500000000000000000; // 0.5 ETH
        FOURTH_PRICE = 700000000000000000; // 0.7 ETH
        FIFTH_PRICE = 1000000000000000000; // 1 ETH
        SIXTH_PRICE = 4000000000000000000; // 4 ETH
        
        FIRST_PRICE_LINE = 50; // 0.1 ETH
        SECOND_PRICE_LINE = 390; // 0.3 ETH
        THIRD_PRICE_LINE = 1090; // 0.5 ETH
        FOURTH_PRICE_LINE = 1240; // 1 ETH
        FIFTH_PRICE_LINE = 1280; // 4 ETH
        SIXTH_PRICE_LINE = 1284; // 0 ETH
        
    */


    uint256 private _finish_reveal_time = 1616868000;
    uint256 private _start_sold_time = 1616263200;
    uint256 private _start_presale_time = 1616259600;


    modifier paused() {
        require(block.timestamp > _start_presale_time);
        _;
    }

    /*
        (Count left part size and multiply to left price) plus (Count right part size and multiply to right price) 
    */
    function getNftPrice(uint256 numberOfNfts) public view returns (uint256) {
        require(totalSold() < 1294, "Sale has already ended");
        
        if(totalSold() >= 1284) {
            return uint256(0).mul(numberOfNfts);
        } else if(totalSold() >= 1280) {
            return uint256(4000000000000000000).mul(min(totalSold().add(numberOfNfts), 1284).sub(totalSold())).add(
                uint256(0).mul(totalSold().add(numberOfNfts) >= 1284 ? totalSold().add(numberOfNfts).sub(1284) : 0));
        } else if(totalSold() >= 1240) {
            return uint256(1000000000000000000).mul(min(totalSold().add(numberOfNfts), 1280).sub(totalSold())).add(
                uint256(4000000000000000000).mul(totalSold().add(numberOfNfts) >= 1280 ? totalSold().add(numberOfNfts).sub(1280) : 0));
        } else if(totalSold() >= 1090) {
            return uint256(700000000000000000).mul(min(totalSold().add(numberOfNfts), 1240).sub(totalSold())).add(
                uint256(1000000000000000000).mul(totalSold().add(numberOfNfts) >= 1240 ? totalSold().add(numberOfNfts).sub(1240) : 0));
        } else if(totalSold() >= 390) {
            return uint256(500000000000000000).mul(min(totalSold().add(numberOfNfts), 1090).sub(totalSold())).add( 
                uint256(700000000000000000).mul(totalSold().add(numberOfNfts) >= 1090 ? totalSold().add(numberOfNfts).sub(1090) : 0));
        } else if(totalSold() >= 50) {
            return uint256(300000000000000000).mul(min(totalSold().add(numberOfNfts), 390).sub(totalSold())).add(
                uint256(500000000000000000).mul(totalSold().add(numberOfNfts) >= 390 ? totalSold().add(numberOfNfts).sub(390) : 0));
        } else {
            return uint256(100000000000000000).mul(min(totalSold().add(numberOfNfts), 50).sub(totalSold())).add( 
                uint256(300000000000000000).mul(totalSold().add(numberOfNfts) >= 50 ? totalSold().add(numberOfNfts).sub(50) : 0));
        }
    
    }

    constructor(address ISETAddress) {
        _ISETAddress = ISETAddress;
    }

    /*
        People who help us
    */
    function setGiftAddress(address[] memory customers) public onlyOwner {
        require(customers.length == 10, "Length must be 10");
        for (uint256 i = 0; i < 10; ++i) {
            _privateTokens[customers[i]] = 1294 + 1309 + i + 1;
        }
    }

    /*
        People who wins in contest
    */
    function setAirdropAddress(address[] memory customers) public onlyOwner {
        require(customers.length == 10, "Length must be 10");
        for (uint256 i = 0; i < 10; ++i) {
            _privateTokens[customers[i]] = 1294 + 1309 + 10 + i + 1;
        }
    }

    function name() public pure override returns (string memory) {
        return "NFT Idols";
    }

    function symbol() public pure override returns (string memory) {
        return "NFTI";
    }

    function isAdressInPreSale(address customer) public pure returns (bool) {
        return customer == address(0x5ad0734530568E5C80036fd814A8B50ac0A3EB4F) ||
               customer == address(0xb3aAb295861Ffd41071337A4Bf2a8357b4b6a353) ||
               customer == address(0x2993E1D02b11377f44455AEdc618C705acbb0591) ||
               customer == address(0xc04B87e282D5dC43D0e6605D574867E7cea7e25d) ||
               customer == address(0x2a0F818DCA7109a11Ae7C1bb1266Bddd4C1194a7) ||
               customer == address(0xf3453f0a63f72BEE573449d446895C805920A4b1) ||
               customer == address(0x443b29e221b54f7bE8C0805859f57028CFF0A1CA) ||
               customer == address(0xa5126a1D3A39beB4679e9BF20ebeA12E8006ADEa) ||
               customer == address(0x337ec021aCE842e3D2c76931921942d10945d5ba) ||
               customer == address(0xf601b1c1Dce139469E4969938c1ce9D58e30bdB9);
    }

    function baseURI() public pure returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmQd2BcnhEYYcZjwH5MDa4ArzTBc5uaumBe1uwfwgQnK6z/";
    }

    function totalSupply() public pure virtual override returns (uint256) {
        return 1294 + 1309 + 20;
    }

    function getISETAddress() public view returns (address) {
        return _ISETAddress;
    }

    function startingIndex() public view returns (uint256) {
        return _seed;
    }

    function startSoldIime() public view returns (uint256) {
        return _start_sold_time;
    }

    function isRevealEnd() public view returns (bool) {
        return block.timestamp > _finish_reveal_time || totalSold() == 1294;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    function _getTokenURI(uint256 tokenId) internal view returns (uint256) {
        return tokenId <= 1294 ? (tokenId + _seed) % 1294 + 1 : tokenId;
    }

    function withdraw(uint256 amount) onlyOwner external {
        msg.sender.transfer(amount);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!isRevealEnd()) {
            return string(abi.encodePacked(baseURI(), "0"));
        }
    
        return string(abi.encodePacked(baseURI(), _getTokenURI(tokenId).toString()));
    }

    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function totalSold() public view returns (uint256) {
        return _tokenOwners.length().sub(_expandedTokensSupply);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == 0x01ffc9a7 || interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f || interfaceId == 0x780e9d63;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;

        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function getRevealTime() public view returns (uint256) {
        return _finish_reveal_time;
    }

    function isPreSaleNow() public view returns (bool) {
        return block.timestamp < _start_sold_time && block.timestamp >= _start_presale_time;
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
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        _holderTokens[to].add(tokenId);
        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        _approve(address(0), tokenId);
        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);
        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool)    {
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
        return (retval == 0x150b7a02);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;

        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    // 11 bit (first chank current state) | 11 bit (how much was taken from first chank) | 11 bit (zero chank current state) | 11 bit (how much was taken from zero chank)
    uint256 private _bitarray;
    uint256 private constant _ZERO_PRIME = 13;
    uint256 private constant _FIRST_PRIME = 1273;

    function _getWasTaken(uint256 chankId) internal view returns (uint256) {
        return (_bitarray >> (22 * chankId)) & ((1 << 11) - 1);
    }

    function _getCurrentState(uint256 chankId) internal view returns (uint256) {
        return ((_bitarray >> (22 * chankId)) >> 11) & ((1 << 11) - 1);
    }

    function _addWasTaken(uint256 chankId, uint256 bitarray) pure internal returns (uint256) {
        return bitarray + (1 << (22 * chankId));
    }

    function _setCurrentState(uint256 chankId, uint256 value, uint256 bitarray) pure internal returns (uint256) {
        bitarray &= ((1 << 44) - 1) - (((1 << 11) - 1) << (11 + 22 * chankId));
        bitarray |= value << (11 + 22 * chankId);
        return bitarray;
    }

    function _getChankSize() internal pure returns (uint256) {
        return 1294 / 2;
    }

    /*
        We have two chanks(even and odd) id sale. Randomly choose chank. Next number = last token id + prime number
    */
    function _getNewRandomTokenId() internal returns (uint256) {
        uint256 random_chank = (block.number + block.timestamp) % 2;
        
        if (_getWasTaken(random_chank) == _getChankSize()) {
            random_chank = random_chank == 0 ? 1 : 0;
        }

        uint256 current_state = _getCurrentState(random_chank);
        uint256 bitarray = _addWasTaken(random_chank, _bitarray);
        bitarray = _setCurrentState(random_chank, (current_state + (1 - random_chank) * _ZERO_PRIME + random_chank * _FIRST_PRIME) % _getChankSize(), bitarray);

        _bitarray = bitarray;

        uint256 result = (current_state + 1) * 2 - random_chank;

        return result;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function buyItem(uint256 numberOfNfts) public payable paused {
        require(_tokenOwners.length() < 1294, "Sale has already ended");
        require(numberOfNfts > 0, "numberOfNfts can't be 0");
        require(numberOfNfts <= 10, "You may not buy more than 10 NFTs at once");
        require(!isPreSaleNow() || isPreSaleNow() && balanceOf(_msgSender()).add(numberOfNfts) <= 10 && isAdressInPreSale(_msgSender()), "");
        require(_tokenOwners.length().add(numberOfNfts) <= 1294, "Exceeds Sale Supply!");
        require(msg.value == getNftPrice(numberOfNfts), string(abi.encodePacked("Need to send exactly the matching ether: ", getNftPrice(numberOfNfts).toString())));

        for (uint256 i = 0; i < numberOfNfts; ++i) {
            _safeMint(_msgSender(), _getNewRandomTokenId());
        }
        
        if (!isRevealEnd()) {
            _seed += block.number + block.timestamp;
        }

        IERC20(_ISETAddress).mintTokens(_msgSender(), numberOfNfts * 50);
    }

    function burn(uint256 tokenId) public {
        require(_msgSender() == _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token"), "You are not owner of token");
        require(ownerOf(tokenId) == _msgSender(), "ERC721: transfer of token that is not own");

        _approve(address(0), tokenId);
        _holderTokens[_msgSender()].remove(tokenId);
        _holderTokens[address(0)].add(tokenId);
        _tokenOwners.set(tokenId, address(0));

        emit Transfer(_msgSender(), address(0), tokenId);

        IERC20(_ISETAddress).mintTokens(_msgSender(), 35);
    }

    function expandToken(uint256 tokenId) public returns (uint256) {
        require(isRevealEnd(), "Reveal is not ended");
        require(_msgSender() == ownerOf(tokenId), string(abi.encodePacked("You are not owner ", tokenId.toString())));
        
        uint256 tokenURI = _getTokenURI(tokenId);

        require(tokenURI <= 10 * 119 || tokenURI > 1294 && tokenURI <= 1294 + 1309, "This cards not expandeble");
        require(IERC20(_ISETAddress).balanceOf(_msgSender()) >= 100, "Not enought ERC20 tokens");
        
        uint256 idGroup = tokenURI <= 1294 ? tokenURI.add(10 - 1).div(10) : (tokenURI - 1294).add(11 - 1).div(11);
        require(_expandedTokens[idGroup] < 11, "Upgradable tokens are ended");

        uint256 startingGroupTokenId = 1294 + 1 + (idGroup - 1) * 11;
        uint256 relativeStart = (block.number + block.timestamp) % 11;
        uint256 expandedTokenId = 0;
        for (uint256 offset = 0; offset < 11; ++offset) {
            expandedTokenId = startingGroupTokenId + ((relativeStart + offset) % 11);
            if (!_exists(expandedTokenId)) {
                IERC20(_ISETAddress).transferFrom(_msgSender(), address(this), 100);
                IERC20(_ISETAddress).burn(100);
                _safeMint(_msgSender(), expandedTokenId);
                _expandedTokens[idGroup]++;
                _expandedTokensSupply++;
                return expandedTokenId;
            }
        }
        return 0;
    }

     function claim() public returns (uint256) {
        require(_privateTokens[_msgSender()] != 0, "You don't have private tokens");
        require(!_exists(_privateTokens[_msgSender()]), "You gift is already minted");

        _safeMint(_msgSender(), _privateTokens[_msgSender()]);

        return _privateTokens[_msgSender()];
    }
}