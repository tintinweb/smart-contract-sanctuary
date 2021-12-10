/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}
contract CicadaIdoConfig is Ownable {

    uint256 public constant RATIO_PRECISION = 10**6;
    address public constant KoltAddr = 0x7Ab299E79DE0F2A9596A97b08654d1AC3262Af95;
    address public constant UsdtAddr = 0xefE9931AD6ed649B25845C87F6F21Fe2A02543E5;

    //Whitelist list collection
     EnumerableSet.AddressSet private Whitelist;

    //Total sale,KOLT
    uint256 public SellTotal;
    //Maximum of single user(USDT);
    uint256 public SingleBuyHighest;
    //Minimum of single buy(USDT);
    uint256 public SingleBuyLowest;
    //Ido start time
    uint256 public IdoStartTs;
    //Ido end time
    uint256 public IdoEndTs;
    //Whitelist end time
    uint256 public WhitelistEndTs;
    //Purchase price:1000000(1USDT:1KOLT);100000(0.1USDT:1KOLT);10000(0.01USDT:1KOLT)
    uint256 public BuySinglePrice;

    //The first release ratio 
    //50% is expressed as: 50 * RATIO_PRECISION / 100
    uint256 public FirstReleaseRatio;

    constructor() {
        SellTotal = 10**6;
        SingleBuyHighest = 10**4;
        SingleBuyLowest = 10**3;
        IdoStartTs = block.timestamp;
        IdoEndTs = block.timestamp + 90*60;
        WhitelistEndTs = block.timestamp + 150*60;
        BuySinglePrice = 1 * RATIO_PRECISION;  //1:1
        FirstReleaseRatio = 50 * RATIO_PRECISION / 100; //50%
    }

    function addWhitelist(address[] memory _Addrs) external onlyOwner {
        uint256 length = _Addrs.length;
        bool _contain;
        for(uint256 i = 0; i < length; ++i) {
            _contain = EnumerableSet.contains(Whitelist,_Addrs[i]);
            if(!_contain) {
                EnumerableSet.add(Whitelist,_Addrs[i]);
            }
        }
    }

    function delWhitelist(address[] memory _Addrs) external onlyOwner {
        uint256 length = _Addrs.length;
        bool _contain;
        for(uint256 i = 0; i < length; ++i) {
            _contain = EnumerableSet.contains(Whitelist,_Addrs[i]);
            if(_contain) {
                EnumerableSet.remove(Whitelist,_Addrs[i]);
            }
        }
    }

    function getWhitelist() external view returns(address[] memory) {
        uint256 length = EnumerableSet.length(Whitelist);
        address[] memory addrs =  new address[](length);
        addrs = EnumerableSet.values(Whitelist);
        return addrs;
    }

    function isWhitelistUser(address _addr) public view returns(bool){
        return EnumerableSet.contains(Whitelist, _addr);
    }

    function getAllConfig() external view returns(uint256 _selltotal,
        uint256 _buyhighest,
        uint256 _buylowest,
        uint256 _starttime,
        uint256 _endtime,
        uint256 _whiteEndTime,
        uint256 _price,
        uint256 _Ratio) {
        return (SellTotal, SingleBuyHighest,
                SingleBuyLowest, IdoStartTs,
                IdoEndTs, WhitelistEndTs,
                BuySinglePrice, FirstReleaseRatio);
    }

    function getKoltAmount(uint256 _usdt) public
        view returns(uint256) {
        uint256 _kolt = (_usdt * RATIO_PRECISION) / BuySinglePrice;
        return _kolt / RATIO_PRECISION;
    }

    function getReleaseFirst(uint256 _kolt) public
        view returns(uint256 _ReleaseKolt) {
        _ReleaseKolt =  _kolt * FirstReleaseRatio / RATIO_PRECISION;
    }
}
contract CicadaIdo is CicadaIdoConfig{

    //userAddr => amount(KOLT)
    mapping(address => uint256) public BuyTotalAmount;
    //collection of all participating IDO users
    EnumerableSet.AddressSet private AllIdoUser;
    //balance of SellTotal;

    function BuyKolt(uint256 _usdt) external {

        require(isWithinIdoTs() == true,"Ido not start or end");
        require(isMoreSingleBuyLowest(_usdt) == true, "Less than min amount");
        require(isWithinSingleBuyHighest(msg.sender, _usdt)
            == true, "More than max amount");
        require(SellTotal > 0, "Kolt Sold out");
        require(SellTotal > getKoltAmount(_usdt),"Insufficient stock");

        uint256 _koltAmount;
        uint256 _ReleaseKolt;

        if(isWhiteTs()){
            require(isWhitelistUser(msg.sender) == true, "not Whitelist User");
            TransferHelper.safeTransferFrom(
                UsdtAddr, msg.sender, address(this), _usdt);
            _koltAmount = getKoltAmount(_usdt);
            _ReleaseKolt = getReleaseFirst(_koltAmount);
            TransferHelper.safeTransfer(KoltAddr,msg.sender,_ReleaseKolt);
        } else {
            TransferHelper.safeTransferFrom(
                UsdtAddr, msg.sender, address(this), _usdt);
            _koltAmount = getKoltAmount(_usdt);
            _ReleaseKolt = getReleaseFirst(_koltAmount);
            TransferHelper.safeTransfer(KoltAddr,msg.sender,_ReleaseKolt);
        }

        if(!EnumerableSet.contains(AllIdoUser,msg.sender)) {
            EnumerableSet.add(AllIdoUser,msg.sender);
        }
        SellTotal -= _koltAmount;
        BuyTotalAmount[msg.sender] += (_koltAmount - _ReleaseKolt);
    }

    function isWhiteTs() public view returns (bool) {
        uint256 nowtime = block.timestamp;
        return (WhitelistEndTs - nowtime > 0? true:false);
    }

    function isWithinIdoTs() public view returns (bool) {
        uint256 nowtime = block.timestamp;
        bool _Within;
        if ((nowtime - IdoEndTs < 0 ) &&
            (nowtime - IdoStartTs > 0)) {
                _Within = true;
            } else {
                _Within = false;
            }
        return _Within;
    }

    function isMoreSingleBuyLowest(uint256 _amount) public view returns (bool) {
        return (_amount - SingleBuyLowest > 0? true:false);
    }

    function isWithinSingleBuyHighest(address _addr, uint256 _amount) public
        view returns (bool) {
        uint256 total = BuyTotalAmount[_addr] + _amount;
        return (SingleBuyHighest - total > 0? true:false);
    }

    function getAllUserBalance() external
        view returns(address[] memory,uint256[] memory){

        uint256 length = EnumerableSet.length(AllIdoUser);
        address[] memory addrs = new address[](length);
        uint256[] memory amounts = new uint[](length);
        addrs = EnumerableSet.values(AllIdoUser);
        for(uint256 i = 0; i < length; ++i) {
            amounts[i] = BuyTotalAmount[addrs[i]];
        }
        return (addrs,amounts);
    }

    //Proportion accuracy: 10**6; 1000000 means release 100%;
    //100000 means release 10%, 10000 means release 1%
    //this method Maybe over gas
    function koltRelease(uint256 _ReleaseRatio) external onlyOwner {
        require(0 < _ReleaseRatio && _ReleaseRatio <= 10**6,"ReleaseRatio err");
        uint256 length = EnumerableSet.length(AllIdoUser);
        uint256 releseAmount;
        address userAddr;
        for(uint256 i = 0; i < length; ++i) {
           userAddr = EnumerableSet.at(AllIdoUser,i);
           if(BuyTotalAmount[userAddr] != 0) {
                releseAmount = BuyTotalAmount[userAddr] *
                    _ReleaseRatio / RATIO_PRECISION;
                TransferHelper.safeTransfer(KoltAddr, userAddr, releseAmount);
                BuyTotalAmount[userAddr] -= releseAmount;
            }
        }
    }

    function koltRelease(address[] memory _addrs, uint256 _ReleaseRatio)
        external onlyOwner {

        require(0 < _ReleaseRatio && _ReleaseRatio <= 10**6,"ReleaseRatio err");
        uint256 length = _addrs.length;
        uint256 releseAmount;
        address userAddr;
        for(uint256 i = 0; i < length; ++i) {
            if(EnumerableSet.contains(AllIdoUser, _addrs[i])) {
                userAddr = _addrs[i];
                if(BuyTotalAmount[userAddr] != 0) {
                releseAmount = BuyTotalAmount[userAddr] *
                    _ReleaseRatio / RATIO_PRECISION;
                TransferHelper.safeTransfer(KoltAddr, userAddr, releseAmount);
                BuyTotalAmount[userAddr] -= releseAmount;
                }
            }
        }
    }

    function usdtWithdraw(address _to, uint256 _amount) external onlyOwner {
        TransferHelper.safeTransfer(UsdtAddr, _to, _amount);
    }

    //In case there is kolt that cannot be taken away
    function koltResidueWithdraw(address _to, uint256 _amount) external onlyOwner {
        TransferHelper.safeTransfer(KoltAddr, _to, _amount);
    }
}