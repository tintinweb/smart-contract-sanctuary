/**
 *Submitted for verification at BscScan.com on 2021-11-02
*/

pragma solidity ^0.6.0;


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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
   * @dev Returns the number of values on the set. O(1).
   */
    function _lengthMemory(Set memory set) private pure returns (uint256) {
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
    * @dev Returns the number of values on the set. O(1).
    */
    function lengthMemory(UintSet memory set) internal pure returns (uint256) {
        return _lengthMemory(set._inner);
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

    function atMemory(UintSet memory set, uint256 index) internal pure returns (uint256) {
        require(set._inner._values.length > index, "EnumerableSet: index out of bounds");
        return uint256(set._inner._values[index]);
    }
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function getTokenLevel(uint256 tokenId) external view returns (uint256);
}

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}


contract nftstore {
    using SafeMath for uint;
    using EnumerableSet for EnumerableSet.UintSet;

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) public returns (bytes4){
        require(tx.origin == _from, "illegal operation owner");
        return 0x150b7a02;
    }

    address payable recFeeAddress = 0xcCf5E8F7167B1a756dF23192152d15e523ba6677;//TODO change Fee address
    address ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 MAX_PRICE = 9e29;//900 billion,900000000000_000000000000000000//

    uint256 feePercent = 2;
    uint256 percent100 = 100;

    constructor () public {
        recFeeAddress = msg.sender;
    }

    uint8 status_valid = 1;
    uint8 status_cancel = 2;
    uint8 status_success = 3;


    struct Order {
        address seller;
        address nft;
        address currency;
        uint256 tokenId;
        uint256 price;
        uint256 duration;
        uint8 status;//1 valid,2 cancel,3 end
    }


    Order[] public orderList;
    mapping(address => EnumerableSet.UintSet) userOrderIdsMap;

    event AuctionCreated(string indexed type_, address indexed from, address indexed currency, uint256 tokenId, uint256 orderId, uint256 price, uint256 duration,address  _nft);
    event AuctionSuccessful(string indexed type_,address indexed from, uint256 orderId, uint256 duration,uint256 orderprice);
    event AuctionCancelled(string indexed type_,uint256 orderId, uint256 duration);

    function _owns(address _nft, address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (IERC721(_nft).ownerOf(_tokenId) == _claimant);
    }


    function sell(address _nft, uint256 _tokenId, address _currency, uint256 _price) public {
        require(_owns(_nft, msg.sender, _tokenId), "ownerOf");
        require(_price > 0, "price>0");
        require(_price.div(MAX_PRICE) == 0, "price limit");
        IERC721(_nft).safeTransferFrom(msg.sender, address(this), _tokenId);

        Order memory order = Order(msg.sender, _nft, _currency, _tokenId, _price, now, status_valid);
        uint orderId = orderList.length;
        userOrderIdsMap[msg.sender].add(orderId);
        orderList.push(order);

        emit AuctionCreated("sell",msg.sender, _currency, _tokenId, orderId,_price,now,_nft);
    }

    function cancel(uint256 _orderId) public {
        Order storage order = orderList[_orderId];
        require(msg.sender == order.seller, "owner");
        require(order.status == status_valid, "status 1");
        order.status = status_cancel;
        userOrderIdsMap[msg.sender].remove(_orderId);
        IERC721(order.nft).safeTransferFrom(address(this), msg.sender, order.tokenId);
        emit AuctionCancelled("cancel",_orderId,now);
    }

    function buy(uint256 _orderId) public payable {
        Order storage order = orderList[_orderId];
        require(order.status == status_valid, "status 1");
        order.status = status_success;
        uint256 orderprice=order.price;
        if (order.currency == ETH_ADDRESS) {
            require(msg.value == order.price, "msgValue");

            uint fee = order.price.mul(feePercent).div(percent100);

            payable(order.seller).transfer(order.price.sub(fee));
            recFeeAddress.transfer(fee);
        } else {
            uint fee = order.price.mul(feePercent).div(percent100);

            safeTransferFrom(order.currency, msg.sender, order.seller, order.price.sub(fee));
            safeTransferFrom(order.currency, msg.sender, recFeeAddress, fee);

        }
        userOrderIdsMap[order.seller].remove(_orderId);
        IERC721(order.nft).safeTransferFrom(address(this), msg.sender, order.tokenId);
        emit AuctionSuccessful("buy",msg.sender, _orderId,now,orderprice);
    }

    function getUser(address _addr) public view returns (uint256){
        return userOrderIdsMap[_addr].length();
    }
    function setFee(uint256 fee) public {
        require(msg.sender == 0xCC9755D2F0971DFD34F497bB44bEB9D0b96Ac600);
        require(fee > 0, "fee>0");
        feePercent = fee;
    }
    function getUserOrderIds(address _addr, uint256 startIndex, uint256 len) public view returns (uint256[] memory ids){

        uint orderLen = userOrderIdsMap[_addr].lengthMemory();
        uint256 max = startIndex.add(len);
        if (max > orderLen) {
            max = orderLen;
            len = orderLen.sub(startIndex);
        }
        if (len > 0) {
            ids = new uint256[](len);
            uint index;
            for (; startIndex < max; startIndex++) {
                uint oid = userOrderIdsMap[_addr].atMemory(startIndex);
                ids[index] = oid;
                index++;
            }
        }
    }


}