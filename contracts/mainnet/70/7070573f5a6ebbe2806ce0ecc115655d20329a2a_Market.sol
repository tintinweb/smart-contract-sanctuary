/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
interface IERC20Token {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
interface FeesContract {
    function calcByToken(address _seller, address _token, uint256 _amount) external view returns (uint256 fee);
    function calcByEth(address _seller, uint256 _amount) external view returns (uint256 fee);
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

    // UintToB32Map

    struct UintToB32Map {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToB32Map storage map, uint256 key, bytes32 value) internal returns (bool) {
        return _set(map._inner, bytes32(key), value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToB32Map storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToB32Map storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToB32Map storage map) internal view returns (uint256) {
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
    function at(UintToB32Map storage map, uint256 index) internal view returns (uint256, bytes32) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToB32Map storage map, uint256 key) internal view returns (bool, bytes32) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToB32Map storage map, uint256 key) internal view returns (bytes32) {
        return _get(map._inner, bytes32(key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToB32Map storage map, uint256 key, string memory errorMessage) internal view returns (bytes32) {
        return _get(map._inner, bytes32(key), errorMessage);
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
        mapping (bytes32 => uint256) _indexes;
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


contract Ownable {

    address private owner;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }


    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}

contract Market is Ownable {
    using EnumerableSet for EnumerableSet.Bytes32Set ;
    using EnumerableMap for EnumerableMap.UintToB32Map;
    
    struct Coin {
        address tokenAddress;
        string symbol;
        string name;
        bool active;
    }
    mapping (uint256 => Coin) public tradeCoins;
    
    struct Trade {
        uint256 indexedBy;
        address nftAddress;
        address seller;
        address buyer;
        uint256 assetId;
        uint256 start;
        uint256 end;
        uint256 stime;
        uint256 price;
        uint256 coinIndex;
        bool active; 
    }
    
    mapping (address => bool) public authorizedERC721;
    mapping (uint256 => bytes32) public tradeIndex;
    mapping (bytes32 => Trade) public trades;

    EnumerableMap.UintToB32Map private tradesMap;
    mapping (address => EnumerableSet.Bytes32Set) private userTrades;
    
    uint256 nextTrade;
    FeesContract feesContract;
    address payable walletAddress;
    
    constructor() {
        // include ETH as coin
        tradeCoins[1].tokenAddress = address(0x0);
        tradeCoins[1].symbol = "ETH";
        tradeCoins[1].name = "Ethereum";
        tradeCoins[1].active = true;
        
        // include POLC as coin
        tradeCoins[2].tokenAddress = 0xaA8330FB2B4D5D07ABFE7A72262752a8505C6B37;
        tradeCoins[2].symbol = "POLC";
        tradeCoins[2].name = "Polka City Token";
        tradeCoins[2].active = true;
        
        // POlka City NFT 3D
        authorizedERC721[0xB20217bf3d89667Fa15907971866acD6CcD570C8] = true;
        // POlka City NFT
        authorizedERC721[0x57E9a39aE8eC404C08f88740A9e6E306f50c937f] = true;
        
        walletAddress = payable(0xAD334543437EF71642Ee59285bAf2F4DAcBA613F);
        

    }
    
    function createTrade(address _nftAddress, uint256 _assetId, uint256 _price, uint256 _coinIndex, uint256 _end) public {
        require(authorizedERC721[_nftAddress] == true, "Unauthorized asset");
        require(tradeCoins[_coinIndex].active == true, "Invalid payment coin");
        require(_end == 0 || _end > block.timestamp, "Invalid end time");
        IERC721 nftContract = IERC721(_nftAddress);
        require(nftContract.ownerOf(_assetId) == msg.sender, "Only asset owner can sell");
        require(nftContract.isApprovedForAll(msg.sender, address(this)), "Market needs operator approval");
        insertTrade(_nftAddress, _assetId, _price, _coinIndex, _end);
    }
    
    function insertTrade(address _nftAddress, uint256 _assetId, uint256 _price, uint256 _coinIndex, uint256 _end) private {
        Trade memory trade = Trade(nextTrade, _nftAddress, msg.sender, address(0x0), _assetId, block.timestamp, _end, 0, _price, _coinIndex, true);
        bytes32 tradeHash = keccak256(abi.encode(_nftAddress, _assetId, nextTrade));
        tradeIndex[nextTrade] = tradeHash;
        trades[tradeHash] = trade;
        tradesMap.set(nextTrade, tradeHash);
        userTrades[msg.sender].add(tradeHash);
        nextTrade += 1;
    }
    
    function allTradesCount() public view returns (uint256 count) {
        return (nextTrade);
    }

    function tradesCount() public view returns (uint256 count) {
        return (tradesMap.length());
    }
    
    function _getTrade(bytes32 _tradeId) private view returns (uint256 indexedBy, address nftToken, address seller, address buyer, uint256 assetId, uint256 start, uint256 end, uint256 soldDate, uint256 price, uint256 coinIndex, bool active) {
        Trade memory _trade = trades[_tradeId];
        return (
        _trade.indexedBy,
        _trade.nftAddress,
        _trade.seller,
        _trade.buyer,
        _trade.assetId,
        _trade.start,
        _trade.end,
        _trade.stime,
        _trade.price,
        _trade.coinIndex,
        _trade.active
        );

    }

    function getTrade(bytes32 _tradeId) public view returns (uint256 indexedBy, address nftToken, address seller, address buyer, uint256 assetId, uint256 start, uint256 end, uint256 soldDate, uint256 price, uint256 coinIndex, bool active) {
        return _getTrade(_tradeId);
    }
    
    function getTradeByIndex(uint256 _index) public view returns (uint256 indexedBy, address nftToken, address seller, address buyer, uint256 assetId, uint256 start, uint256 end, uint256 soldDate, uint256 price, uint256 coinIndex, bool active) {
        (, bytes32 tradeId) = tradesMap.at(_index);
        return _getTrade(tradeId);
    }

    function parseBytes(bytes memory data) private pure returns (bytes32){
        bytes32 parsed;
        assembly {parsed := mload(add(data, 32))}
        return parsed;
    }
    
    function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public returns (bool success) {
        bytes32 _tradeId = parseBytes(_extraData);
        Trade memory trade = trades[_tradeId];
        require(tradeCoins[trade.coinIndex].tokenAddress == _token, "Invalid coin");
        require(trade.active == true, "Trade not available");
        require(_value == trade.price, "Invalid price");
        if (verifyTrade(_tradeId, trade.seller, trade.nftAddress, trade.assetId, trade.end)) {
            uint256 tradeFee = feesContract.calcByToken(trade.seller, tradeCoins[trade.coinIndex].tokenAddress , _value);
            IERC20Token erc20Token = IERC20Token(_token);  
            if (tradeFee > 0) {
                require(erc20Token.transferFrom(_from, trade.seller, (trade.price-tradeFee)), "ERC20 transfer fail");
                require(erc20Token.transferFrom(_from, walletAddress, (tradeFee)), "ERC20 transfer fail");
            } else {
                require(erc20Token.transferFrom(_from, trade.seller, (trade.price)), "ERC20 transfer fail");
            }
            executeTrade(_tradeId, _from, trade.seller, trade.nftAddress, trade.assetId);
            return (true);
        } else {
            return (false);
        }

    }
    
    function buyWithEth(bytes32 _tradeId) public payable returns (bool success) {
        Trade memory trade = trades[_tradeId];
        require(trade.coinIndex == 1, "Invalid coin");
        require(trade.active == true, "Trade not available");
        require(msg.value == trade.price, "Invalid price");
        if (verifyTrade(_tradeId, trade.seller, trade.nftAddress, trade.assetId, trade.end)) {
            uint256 tradeFee = feesContract.calcByEth(trade.seller, msg.value);
            if (tradeFee > 0) {
                walletAddress.transfer(msg.value);
            }
            payable(trade.seller).transfer(msg.value-tradeFee);
            executeTrade(_tradeId, msg.sender, trade.seller, trade.nftAddress, trade.assetId);
            return (true);
        } else {
            return (false);
        }

    }
    
    function executeTrade(bytes32 _tradeId, address _buyer, address _seller, address _contract, uint256 _assetId) private {
        IERC721 nftToken = IERC721(_contract);
        nftToken.safeTransferFrom(_seller, _buyer, _assetId);
        trades[_tradeId].buyer = _buyer;
        trades[_tradeId].active = false;
        trades[_tradeId].stime = block.timestamp;
        userTrades[_seller].remove(_tradeId);
        tradesMap.remove(trades[_tradeId].indexedBy);
    }
    
    function verifyTrade(bytes32 _tradeId, address _seller, address _contract, uint256 _assetId, uint256 _endTime) private returns (bool _valid) {
        IERC721 nftToken = IERC721(_contract);
        address assetOwner = nftToken.ownerOf(_assetId);
        if (assetOwner != _seller || (_endTime > 0 && _endTime < block.timestamp)) {
            trades[_tradeId].active = false;
            userTrades[_seller].remove(_tradeId);
            tradesMap.remove(trades[_tradeId].indexedBy);
            return false;
        } else {
            return true;
        }
    }

    function cancelTrade(bytes32 _tradeId) public returns (bool success) {
        Trade memory trade = trades[_tradeId];
        require(trade.seller == msg.sender, "Only asset seller can cancel the trade");
        trades[_tradeId].active = false;
        userTrades[trade.seller].remove(_tradeId);
        tradesMap.remove(trade.indexedBy);
        return true;
    }

    function adminCancelTrade(bytes32 _tradeId) public onlyOwner {
        Trade memory trade = trades[_tradeId];
        trades[_tradeId].active = false;
        userTrades[trade.seller].remove(_tradeId);
        tradesMap.remove(trade.indexedBy);
    }
    
    function tradesCountOf(address _from) public view returns (uint256 _count) {
        return (userTrades[_from].length());
    }
    
    function tradeOfByIndex(address _from, uint256 _index) public view returns (bytes32 _trade) {
        return (userTrades[_from].at(_index));
    }
    
    function addCoin(uint256 _coinIndex, address _tokenAddress, string memory _tokenSymbol, string memory _tokenName, bool _active) public onlyOwner {
        tradeCoins[_coinIndex].tokenAddress = _tokenAddress;
        tradeCoins[_coinIndex].symbol = _tokenSymbol;
        tradeCoins[_coinIndex].name = _tokenName;
        tradeCoins[_coinIndex].active = _active;
    }

    function autorizenft(address _nftAddress) public onlyOwner {
        authorizedERC721[_nftAddress] = true;
    }
    
    function deautorizenft(address _nftAddress) public onlyOwner {
        authorizedERC721[_nftAddress] = false;
    }
    
    function setFeesContract(address _contract) public onlyOwner {
        feesContract = FeesContract(_contract);
    }
    
    function setWallet(address _wallet) public onlyOwner {
        walletAddress = payable(_wallet);
    }
    
}