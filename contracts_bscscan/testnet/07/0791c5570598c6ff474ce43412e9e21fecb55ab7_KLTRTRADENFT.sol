/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

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

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
    function minterInfo(uint256 tokenId)
    external
    view
    returns (address minter);
    function royaltyInfo(uint256 tokenId)
    external
    view
    returns (uint256 user_royalty);
    
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

contract ERC721Holder is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;
    constructor () internal {
        _paused = false;
    }
    function paused() public view returns (bool) {
        return _paused;
    }
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

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
        uint256 _key;
        uint256 _value;
    }
    struct Map {
        MapEntry[] _entries;
        mapping(uint256 => uint256) _indexes;
    }
    function _set(
        Map storage map,
        uint256 key,
        uint256 value
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
    function _remove(Map storage map, uint256 key) private returns (bool) {
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
    function _contains(Map storage map, uint256 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }
    function _at(Map storage map, uint256 index) private view returns (uint256, uint256) {
        require(map._entries.length > index, 'EnumerableMap: index out of bounds');
        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }
    function _get(Map storage map, uint256 key) private view returns (uint256) {
        return _get(map, key, 'EnumerableMap: nonexistent key');
    }
    function _get(
        Map storage map,
        uint256 key,
        string memory errorMessage
    ) private view returns (uint256) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage);
        return map._entries[keyIndex - 1]._value;
    }
    struct UintToUintMap {
        Map _inner;
    }
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return _set(map._inner, key, value);
    }
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, key);
    }
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, key);
    }
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        return _at(map._inner, index);
    }
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return _get(map._inner, key);
    }
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return _get(map._inner, key, errorMessage);
    }
}

interface IBidNFT {
    function buyToken(uint256 _tokenId) external;
    function buyTokenTo(uint256 _tokenId, address _to) external;
    function setCurrentPrice(uint256 _tokenId, uint256 _price) external;
    function readyToSellToken(uint256 _tokenId, uint256 _price) external;
    function readyToSellTokenTo(uint256 _tokenId, uint256 _price, address _to) external;
    function cancelSellToken(uint256 _tokenId) external;
    function bidToken(uint256 _tokenId, uint256 _price) external;
    function updateBidPrice(uint256 _tokenId, uint256 _price) external;
    function sellTokenTo(uint256 _tokenId, address _to) external;
    function cancelBidToken(uint256 _tokenId) external;
}

contract KLTRTRADENFT is IBidNFT, ERC721Holder, Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using EnumerableSet for EnumerableSet.UintSet;
    struct AskEntry {
        uint256 tokenId;
        uint256 price;
    }
    struct BidEntry {
        address bidder;
        uint256 price;
    }
    struct UserBidEntry {
        uint256 tokenId;
        uint256 price;
    }
    IERC721 public nft;
    IERC20 public quoteErc20;
    address public feeAddr;
    uint256 public feePercent;
    
    // uint256 public royalty;
    // address public minter_address;
    // mapping(uint => royalty) royalinfo;
    
    EnumerableMap.UintToUintMap private _asksMap;
    mapping(uint256 => address) private _tokenSellers;
    mapping(address => EnumerableSet.UintSet) private _userSellingTokens;
    mapping(uint256 => BidEntry[]) private _tokenBids;
    mapping(address => EnumerableMap.UintToUintMap) private _userBids;
    event Trade(address indexed seller, address indexed buyer, uint256 indexed tokenId, uint256 price, uint256 fee);
    event Ask(address indexed seller, uint256 indexed tokenId, uint256 price);
    event CancelSellToken(address indexed seller, uint256 indexed tokenId);
    event FeeAddressTransferred(address indexed previousOwner, address indexed newOwner);
    event SetFeePercent(address indexed seller, uint256 oldFeePercent, uint256 newFeePercent);
    event Bid(address indexed bidder, uint256 indexed tokenId, uint256 price);
    event CancelBidToken(address indexed bidder, uint256 indexed tokenId);

    constructor(
        address _nftAddress,
        address _quoteErc20Address,
        address _feeAddr,
        uint256 _feePercent
    ) public {
        require(_nftAddress != address(0) && _nftAddress != address(this));
        require(_quoteErc20Address != address(0) && _quoteErc20Address != address(this));
        nft = IERC721(_nftAddress);
        quoteErc20 = IERC20(_quoteErc20Address);
        feeAddr = _feeAddr;
        feePercent = _feePercent;
        emit FeeAddressTransferred(address(0), feeAddr);
        emit SetFeePercent(_msgSender(), 0, feePercent);
    }
    function buyToken(uint256 _tokenId) public override whenNotPaused {
        buyTokenTo(_tokenId, _msgSender());
    }
    
    function buyTokenTo(uint256 _tokenId, address _to) public override whenNotPaused {
        require(_msgSender() != address(0) && _msgSender() != address(this), 'Wrong msg sender');
        require(_asksMap.contains(_tokenId), 'Token not in sell book');
        require(!_userBids[_msgSender()].contains(_tokenId), 'You must cancel your bid first');
        
        nft.safeTransferFrom(address(this), _to, _tokenId);
        uint256 price = _asksMap.get(_tokenId);
        uint256 feeAmount = price.mul(feePercent).div(100);
        uint256 royaltyAmount = price.mul(nft.royaltyInfo(_tokenId)).div(100);
        uint256 total_fees = feeAmount.add(royaltyAmount);
        if (feeAmount != 0) {
            quoteErc20.safeTransferFrom(_msgSender(), feeAddr, feeAmount);
            
        }
        quoteErc20.safeTransferFrom(_msgSender(), nft.minterInfo(_tokenId) , royaltyAmount);
        quoteErc20.safeTransferFrom(_msgSender(), _tokenSellers[_tokenId], price.sub(total_fees));
        _asksMap.remove(_tokenId);
        _userSellingTokens[_tokenSellers[_tokenId]].remove(_tokenId);
        emit Trade(_tokenSellers[_tokenId], _to, _tokenId, price, feeAmount);
        delete _tokenSellers[_tokenId];
    }
    
    function setCurrentPrice(uint256 _tokenId, uint256 _price) public override whenNotPaused {
        require(_userSellingTokens[_msgSender()].contains(_tokenId), 'Only Seller can update price');
        require(_price != 0, 'Price must be granter than zero');
        _asksMap.set(_tokenId, _price);
        emit Ask(_msgSender(), _tokenId, _price);
    }
    function readyToSellToken(uint256 _tokenId, uint256 _price) public override whenNotPaused {
        readyToSellTokenTo(_tokenId, _price, address(_msgSender()));
    }
    function readyToSellTokenTo(
        uint256 _tokenId,
        uint256 _price,
        address _to
    ) public override whenNotPaused {
        require(_msgSender() == nft.ownerOf(_tokenId), 'Only Token Owner can sell token');
        require(_price != 0, 'Price must be granter than zero');
        nft.safeTransferFrom(address(_msgSender()), address(this), _tokenId);
        _asksMap.set(_tokenId, _price);
        _tokenSellers[_tokenId] = _to;
        _userSellingTokens[_to].add(_tokenId);
        emit Ask(_to, _tokenId, _price);
    }
    function cancelSellToken(uint256 _tokenId) public override whenNotPaused {
        require(_userSellingTokens[_msgSender()].contains(_tokenId), 'Only Seller can cancel sell token');
        nft.safeTransferFrom(address(this), _msgSender(), _tokenId);
        _asksMap.remove(_tokenId);
        _userSellingTokens[_tokenSellers[_tokenId]].remove(_tokenId);
        delete _tokenSellers[_tokenId];
        emit CancelSellToken(_msgSender(), _tokenId);
    }
    function getAskLength() public view returns (uint256) {
        return _asksMap.length();
    }
    function getAsks() public view returns (AskEntry[] memory) {
        AskEntry[] memory asks = new AskEntry[](_asksMap.length());
        for (uint256 i = 0; i < _asksMap.length(); ++i) {
            (uint256 tokenId, uint256 price) = _asksMap.at(i);
            asks[i] = AskEntry({tokenId: tokenId, price: price});
        }
        return asks;
    }
    function getAsksDesc() public view returns (AskEntry[] memory) {
        AskEntry[] memory asks = new AskEntry[](_asksMap.length());
        if (_asksMap.length() > 0) {
            for (uint256 i = _asksMap.length() - 1; i > 0; --i) {
                (uint256 tokenId, uint256 price) = _asksMap.at(i);
                asks[_asksMap.length() - 1 - i] = AskEntry({tokenId: tokenId, price: price});
            }
            (uint256 tokenId, uint256 price) = _asksMap.at(0);
            asks[_asksMap.length() - 1] = AskEntry({tokenId: tokenId, price: price});
        }
        return asks;
    }
    function getAsksByPage(uint256 page, uint256 size) public view returns (AskEntry[] memory) {
        if (_asksMap.length() > 0) {
            uint256 from = page == 0 ? 0 : (page - 1) * size;
            uint256 to = Math.min((page == 0 ? 1 : page) * size, _asksMap.length());
            AskEntry[] memory asks = new AskEntry[]((to - from));
            for (uint256 i = 0; from < to; ++i) {
                (uint256 tokenId, uint256 price) = _asksMap.at(from);
                asks[i] = AskEntry({tokenId: tokenId, price: price});
                ++from;
            }
            return asks;
        } else {
            return new AskEntry[](0);
        }
    }
    function getAsksByPageDesc(uint256 page, uint256 size) public view returns (AskEntry[] memory) {
        if (_asksMap.length() > 0) {
            uint256 from = _asksMap.length() - 1 - (page == 0 ? 0 : (page - 1) * size);
            uint256 to = _asksMap.length() - 1 - Math.min((page == 0 ? 1 : page) * size - 1, _asksMap.length() - 1);
            uint256 resultSize = from - to + 1;
            AskEntry[] memory asks = new AskEntry[](resultSize);
            if (to == 0) {
                for (uint256 i = 0; from > to; ++i) {
                    (uint256 tokenId, uint256 price) = _asksMap.at(from);
                    asks[i] = AskEntry({tokenId: tokenId, price: price});
                    --from;
                }
                (uint256 tokenId, uint256 price) = _asksMap.at(0);
                asks[resultSize - 1] = AskEntry({tokenId: tokenId, price: price});
            } else {
                for (uint256 i = 0; from >= to; ++i) {
                    (uint256 tokenId, uint256 price) = _asksMap.at(from);
                    asks[i] = AskEntry({tokenId: tokenId, price: price});
                    --from;
                }
            }
            return asks;
        }
        return new AskEntry[](0);
    }
    function getAsksByUser(address user) public view returns (AskEntry[] memory) {
        AskEntry[] memory asks = new AskEntry[](_userSellingTokens[user].length());
        for (uint256 i = 0; i < _userSellingTokens[user].length(); ++i) {
            uint256 tokenId = _userSellingTokens[user].at(i);
            uint256 price = _asksMap.get(tokenId);
            asks[i] = AskEntry({tokenId: tokenId, price: price});
        }
        return asks;
    }
    function getAsksByUserDesc(address user) public view returns (AskEntry[] memory) {
        AskEntry[] memory asks = new AskEntry[](_userSellingTokens[user].length());
        if (_userSellingTokens[user].length() > 0) {
            for (uint256 i = _userSellingTokens[user].length() - 1; i > 0; --i) {
                uint256 tokenId = _userSellingTokens[user].at(i);
                uint256 price = _asksMap.get(tokenId);
                asks[_userSellingTokens[user].length() - 1 - i] = AskEntry({tokenId: tokenId, price: price});
            }
            uint256 tokenId = _userSellingTokens[user].at(0);
            uint256 price = _asksMap.get(tokenId);
            asks[_userSellingTokens[user].length() - 1] = AskEntry({tokenId: tokenId, price: price});
        }
        return asks;
    }
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }
    function transferFeeAddress(address _feeAddr) public {
        require(_msgSender() == feeAddr, 'FORBIDDEN');
        feeAddr = _feeAddr;
        emit FeeAddressTransferred(_msgSender(), feeAddr);
    }
    function setFeePercent(uint256 _feePercent) public onlyOwner {
        require(feePercent != _feePercent, 'Not need update');
        emit SetFeePercent(_msgSender(), feePercent, _feePercent);
        feePercent = _feePercent;
    }
    function bidToken(uint256 _tokenId, uint256 _price) public override whenNotPaused {
        require(_msgSender() != address(0) && _msgSender() != address(this), 'Wrong msg sender');
        require(_price != 0, 'Price must be granter than zero');
        require(_asksMap.contains(_tokenId), 'Token not in sell book');
        address _seller = _tokenSellers[_tokenId];
        address _to = address(_msgSender());
        require(_seller != _to, 'Owner cannot bid');
        require(!_userBids[_to].contains(_tokenId), 'Bidder already exists');
        quoteErc20.safeTransferFrom(address(_msgSender()), address(this), _price);
        _userBids[_to].set(_tokenId, _price);
        _tokenBids[_tokenId].push(BidEntry({bidder: _to, price: _price}));
        emit Bid(_msgSender(), _tokenId, _price);
    }
    function updateBidPrice(uint256 _tokenId, uint256 _price) public override whenNotPaused {
        require(_userBids[_msgSender()].contains(_tokenId), 'Only Bidder can update the bid price');
        require(_price != 0, 'Price must be granter than zero');
        address _to = address(_msgSender()); // find  bid and the index
        (BidEntry memory bidEntry, uint256 _index) = getBidByTokenIdAndAddress(_tokenId, _to);
        require(bidEntry.price != 0, 'Bidder does not exist');
        require(bidEntry.price != _price, 'The bid price cannot be the same');
        if (_price > bidEntry.price) {
            quoteErc20.safeTransferFrom(address(_msgSender()), address(this), _price - bidEntry.price);
        } else {
            quoteErc20.transfer(_to, bidEntry.price - _price);
        }
        _userBids[_to].set(_tokenId, _price);
        _tokenBids[_tokenId][_index] = BidEntry({bidder: _to, price: _price});
        emit Bid(_msgSender(), _tokenId, _price);
    }
    function getBidByTokenIdAndAddress(uint256 _tokenId, address _address)
        private
        view
        returns (BidEntry memory, uint256)
    {
        BidEntry[] memory bidEntries = _tokenBids[_tokenId];
        uint256 len = bidEntries.length;
        uint256 _index;
        BidEntry memory bidEntry;
        for (uint256 i = 0; i < len; i++) {
            if (_address == bidEntries[i].bidder) {
                _index = i;
                bidEntry = BidEntry({bidder: bidEntries[i].bidder, price: bidEntries[i].price});
                break;
            }
        }
        return (bidEntry, _index);
    }
    function delBidByTokenIdAndIndex(uint256 _tokenId, uint256 _index) private {
        _userBids[_tokenBids[_tokenId][_index].bidder].remove(_tokenId);
        uint256 len = _tokenBids[_tokenId].length;
        for (uint256 i = _index; i < len - 1; i++) {
            _tokenBids[_tokenId][i] = _tokenBids[_tokenId][i + 1];
        }
        _tokenBids[_tokenId].pop();
    }
    function sellTokenTo(uint256 _tokenId, address _to) public override whenNotPaused {
        require(_asksMap.contains(_tokenId), 'Token not in sell book');
        address _seller = _tokenSellers[_tokenId];
        address _owner = address(_msgSender());
        require(_seller == _owner, 'Only owner can sell token');
        (BidEntry memory bidEntry, uint256 _index) = getBidByTokenIdAndAddress(_tokenId, _to);
        require(bidEntry.price != 0, 'Bidder does not exist');
        nft.safeTransferFrom(address(this), _to, _tokenId);
        uint256 price = bidEntry.price;
        uint256 feeAmount = price.mul(feePercent).div(100);
        if (feeAmount != 0) {
            quoteErc20.transfer(feeAddr, feeAmount);
        }
        quoteErc20.transfer(_seller, price.sub(feeAmount));
        _asksMap.remove(_tokenId);
        _userSellingTokens[_tokenSellers[_tokenId]].remove(_tokenId);
        delBidByTokenIdAndIndex(_tokenId, _index);
        emit Trade(_tokenSellers[_tokenId], _to, _tokenId, price, feeAmount);
        delete _tokenSellers[_tokenId];
    }
    function cancelBidToken(uint256 _tokenId) public override whenNotPaused {
        require(_userBids[_msgSender()].contains(_tokenId), 'Only Bidder can cancel the bid');
        address _address = address(_msgSender());
        (BidEntry memory bidEntry, uint256 _index) = getBidByTokenIdAndAddress(_tokenId, _address);
        require(bidEntry.price != 0, 'Bidder does not exist');
        quoteErc20.transfer(_address, bidEntry.price);
        delBidByTokenIdAndIndex(_tokenId, _index);
        emit CancelBidToken(_msgSender(), _tokenId);
    }
    function getBidsLength(uint256 _tokenId) public view returns (uint256) {
        return _tokenBids[_tokenId].length;
    }
    function getBids(uint256 _tokenId) public view returns (BidEntry[] memory) {
        return _tokenBids[_tokenId];
    }
    function getUserBids(address user) public view returns (UserBidEntry[] memory) {
        uint256 len = _userBids[user].length();
        UserBidEntry[] memory bids = new UserBidEntry[](len);
        for (uint256 i = 0; i < len; i++) {
            (uint256 tokenId, uint256 price) = _userBids[user].at(i);
            bids[i] = UserBidEntry({tokenId: tokenId, price: price});
        }
        return bids;
    }
}