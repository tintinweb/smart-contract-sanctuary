// SPDX-License-Identifier: MIТ

pragma solidity 0.6.12;

/**
* @dev Interface of the ERC20 standard as defined in the EIP.
*/
interface IBEP20 {
    function mint(address _to, uint256 _amount) external;
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
        require(c >= a, "SafeMath: addition overflow");

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
        return sub(a, b, "SafeMath: subtraction overflow");
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
        return div(a, b, "SafeMath: division by zero");
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
        return mod(a, b, "SafeMath: modulo by zero");
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
                set._indexes[lastvalue] = valueIndex;
                // Replace lastvalue's index to valueIndex
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

contract SignData {
    bytes32 public DOMAIN_SEPARATOR;
    string public NAME;
    bytes32 public DEPOSIT_HASH;
    bytes32 public WITHDRAW_HASH;
    mapping(address => uint) public nonces;


    function initData() internal {
        NAME = "KawaiiFarmingEvent";
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(NAME)),
                keccak256(bytes('1')),
                chainId,
                this
            )
        );


        DEPOSIT_HASH = keccak256("Data(uint256 pid,address sender,uint256 nonce)");
        WITHDRAW_HASH = keccak256("Data(uint256 pid,address sender,uint256 nonce)");
    }

    function verify(bytes32 data, address sender, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                data
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == sender, "Invalid nonce");
    }
}

interface IBEP1155 {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
}


contract KawaiiFarmingEvent is SignData {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    IBEP20 public rewardToken;
    IBEP1155 public kawaiiCore;
    //rewardPerNFT tree/animal/field
    uint256[] public poolInfo;
    uint256[] public poolTotalSupply;
    // pid=> account=> numNFT
    mapping(uint256 => mapping(address => uint256)) public userInfo;
    // user=> pid=> nftId
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public userDataNFT;
    mapping(uint256 => EnumerableSet.UintSet) internal idOfPids;
    uint256 public startBlock;
    uint256 public endBlock;
    bool public initialized;
    address public owner;

    event Deposit(address indexed _caller, uint256 indexed _pid, uint256[] _ids, uint256[] _amounts, uint256 userAmount);
    event Withdraw(address indexed _caller, uint256 indexed _pid, uint256[] _ids, uint256[] _amounts, uint256 reward);

    function init(IBEP20 _rewardToken, uint256 _startBlock, uint256 _endBlock, IBEP1155 _kawaiiCore) public {
        require(initialized == false);
        initData();
        rewardToken = _rewardToken;
        startBlock = _startBlock;
        endBlock = _endBlock;
        kawaiiCore = _kawaiiCore;
        owner = msg.sender;
        initialized = true;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "!caller must owner");
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function setKawaiiCore(IBEP1155 _kawaiCore) public onlyOwner {
        kawaiiCore = _kawaiCore;
    }

    function setRewardToken(IBEP20 _rewardToken) public onlyOwner {
        rewardToken = _rewardToken;
    }

    function addIdOfPid(uint256 _pid, uint256[] calldata _ids) external onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            idOfPids[_pid].add(_ids[i]);
        }
    }

    function removeIdOfPid(uint256 _pid, uint256[] calldata _ids) external onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            idOfPids[_pid].remove(_ids[i]);
        }
    }

    function add(uint256 _rewardPerNFT, uint256[] calldata ids) public onlyOwner {
        poolInfo.push(_rewardPerNFT);
        poolTotalSupply.push(0);
        uint256 pid = poolInfo.length.sub(1);
        for (uint256 i = 0; i < ids.length; i++) {
            idOfPids[pid].add(ids[i]);
        }
    }

    function set(uint256 _pid, uint256 _rewardPerShare) public onlyOwner {
        poolInfo[_pid] = _rewardPerShare;
    }

    function getIdOfPid(uint256 _pid, uint256 index) external view returns (uint256){
        return idOfPids[_pid].at(index);
    }

    function getLenIdOfPid(uint256 _pid) external view returns (uint256){
        return idOfPids[_pid].length();
    }

    function setBlock(uint256 _startBlock, uint256 _endBlock) external {
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    function depositPermit(address sender, uint256 _pid, uint256[] calldata _ids, uint256[] calldata _amounts, uint8 v, bytes32 r, bytes32 s) public {
        verify(keccak256(abi.encode(DEPOSIT_HASH, _pid, sender, nonces[sender]++)), sender, v, r, s);
        _deposit(sender, _pid, _ids, _amounts);
    }

    function deposit(uint256 _pid, uint256[] memory _ids, uint256[] memory _amounts) external {
        _deposit(msg.sender, _pid, _ids, _amounts);
    }


    function _deposit(address _caller, uint256 _pid, uint256[] memory _ids, uint256[] memory _amounts) internal {
        require(block.number < startBlock, "to old");
        require(_ids.length == _amounts.length, "input invalid");
        uint256 total;
        for (uint256 i = 0; i < _ids.length; i++) {
            require(idOfPids[_pid].contains(_ids[i]), "pid not support id");
            total = total.add(_amounts[i]);
            userDataNFT[_caller][_pid][_ids[i]] = userDataNFT[_caller][_pid][_ids[i]].add(_amounts[i]);
            kawaiiCore.safeTransferFrom(_caller, address(this), _ids[i], _amounts[i], "0x");
        }
        if (total > 0) {
            poolTotalSupply[_pid] = poolTotalSupply[_pid].add(total);
            userInfo[_pid][_caller] = userInfo[_pid][_caller].add(total);
        }
        emit Deposit(_caller, _pid, _ids, _amounts, userInfo[_pid][_caller]);
    }

    function withdrawPermit(address sender, uint256 _pid, uint256[] calldata _ids, uint256[] calldata _amounts, uint8 v, bytes32 r, bytes32 s) external {
        verify(keccak256(abi.encode(WITHDRAW_HASH, _pid, sender, nonces[sender]++)), sender, v, r, s);
        _withdraw(sender, _pid, _ids, _amounts);
    }

    function withdraw(uint256 _pid, uint256[] calldata _ids, uint256[] calldata _amounts) external {
        _withdraw(msg.sender, _pid, _ids, _amounts);
    }

    function _withdraw(address _caller, uint256 _pid, uint256[] memory _ids, uint256[] memory _amounts) internal {
        require(block.number >= endBlock, "Too Early");
        uint256 total;
        for (uint256 i = 0; i < _ids.length; i++) {
            userDataNFT[_caller][_pid][_ids[i]] = userDataNFT[_caller][_pid][_ids[i]].sub(_amounts[i], "amounts exceed deposited");
            total = total.add(_amounts[i]);
            kawaiiCore.safeTransferFrom(address(this), _caller, _ids[i], _amounts[i], "0x");
        }
        poolTotalSupply[_pid] = poolTotalSupply[_pid].sub(total);
        uint256 reward = total.mul(poolInfo[_pid]);
        rewardToken.mint(_caller, reward);
        userInfo[_pid][_caller] = userInfo[_pid][_caller].sub(total);
        emit Withdraw(_caller, _pid, _ids, _amounts, reward);
    }

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns (bytes4){
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns (bytes4){
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

}

