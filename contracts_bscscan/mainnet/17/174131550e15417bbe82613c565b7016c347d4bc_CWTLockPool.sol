/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
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
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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

abstract contract Ownable is Context {
    address private _owner;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private governments;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function addGovernment(address government) public onlyOwner {
        governments.add(government);
    }
    
    function deletedGovernment(address government) public onlyOwner {
        governments.remove(government);
    }
    
    function getGovernment(uint256 index) public view returns (address) {
        return governments.at(index);
    }
    
    function isGovernment(address account) public view returns (bool){
        return governments.contains(account);
    }
    
    function getGovernmentLength() public view returns (uint256) {
        return governments.length();
    }
    
     modifier onlyGovernment() {
        require(isGovernment(_msgSender()) , "Ownable: caller is not the Government");
        _;
    }
    
     modifier onlyController(){
       require(_msgSender() == owner() || isGovernment(_msgSender()), "Ownable: caller is not the controller");
        _;
    }
    
}

contract CWTLockPool is Ownable {
    
    address private stakeToken;
    address private withdrawToken;
    mapping (address => Record[]) private records;
    uint256 private stakeStartTime;
    uint256 private stakeTotalAmount;
    PoolInfo private poolInfo;
    Rate private rate;
    uint256 private _maxStakeTotalSupply = 3636364 * 1e12 ;
    uint256 private maxBuyTimes = 1;
    mapping(address => uint256) private buyTimes;
    MinMaxAmount private minMaxAmount;
    
    constructor(address _stakeToken, address _withdrawToken, uint256 _stakeStartTime) {
        withdrawToken = _withdrawToken;
        stakeToken = _stakeToken;
        stakeStartTime = _stakeStartTime;

        poolInfo = PoolInfo({
         stakeToken:_stakeToken,
         withdrawToken:_withdrawToken,
         stakeStartTime:_stakeStartTime,
         maxStakeTotalSupply:_maxStakeTotalSupply
        });
        
        rate = Rate({
            timestamp:90*86400,
            rate:200
        });
        
        minMaxAmount = MinMaxAmount({
        min : 2000 * 1e12,
        max : 20000 * 1e12
        });
        
    }
    
    function stake(uint256 _amount) public {
        
        require(_amount > 0,"amount must be > 0");
        
        require(stakeTotalAmount + _amount <= _maxStakeTotalSupply,"has no quota");
        
        require(block.timestamp >= stakeStartTime,"stake is not start");
        
        require(_amount >= minMaxAmount.min, "stake amount too small");
        require(_amount <= minMaxAmount.max, "stake amount too large");
        
        if (maxBuyTimes > 0) {
            require(maxBuyTimes > buyTimes[msg.sender], "stake times is not enough");
        }
        

        IERC20(stakeToken).transferFrom(msg.sender,address(this),_amount);
        
        uint256 _totalRewardAmount = _amount * 1e6 * 550 * rate.rate / 4 / 1000;
        Record memory record = Record({
            stakeAmount:_amount,
            totalRewardAmount:_totalRewardAmount,
            stakeTimestamp:block.timestamp,
            withdrawAmount:0
        });
        
        buyTimes[msg.sender] = buyTimes[msg.sender] + 1;
        records[msg.sender].push(record);
        stakeTotalAmount = stakeTotalAmount + _amount;
        
    }
    
    function getReward (uint256 index) public {
        require(records[msg.sender].length > 0, "you has not stake");
        Record memory record = records[msg.sender][index];
        require(record.totalRewardAmount - record.withdrawAmount > 0  ,"you has not release token");
        uint256 time = block.timestamp - record.stakeTimestamp ;
        uint256 amount = record.totalRewardAmount * time / rate.timestamp  - record.withdrawAmount;
        if(amount + record.withdrawAmount > record.totalRewardAmount){
            amount  = record.totalRewardAmount - record.withdrawAmount;
        }
        require(amount > 0);
        IERC20(withdrawToken).transfer(msg.sender, amount);
        records[msg.sender][index].withdrawAmount += amount;
    }
    
    function withdraw (uint256 index) public {
        require(records[msg.sender].length > 0, "you has not stake");
        Record memory record = records[msg.sender][index];
        uint256 time = block.timestamp - record.stakeTimestamp ;
        require(time >= rate.timestamp,"you can't withdraw now");
        require(record.stakeAmount >0 , "you has no stake token");
        IERC20(stakeToken).transfer(msg.sender,record.stakeAmount);
        records[msg.sender][index].stakeAmount = 0;
        
    }
    
    function cleanUp (address account) public onlyOwner {
        uint256 amount = IERC20(withdrawToken).balanceOf(address(this));
        require(amount>0);
        IERC20(withdrawToken).transfer(account,amount);
    }
    
    function setMinAndMaxBuyOnce(uint256 _min, uint256 _max) public onlyController {
       minMaxAmount.min = _min;
       minMaxAmount.max = _max;
    }
    
    function updateRate (uint256 _timestamp, uint256 _rate) public onlyController{
        rate.timestamp = _timestamp;
        rate.rate = _rate;
    }
    
    function getRates() public view returns (Rate memory) {
        return rate;
    }
    
    function getStakeTotalAmount() public view returns (uint256) {
        return stakeTotalAmount;
    }
    
    function getPoolInfo() public view returns (PoolInfo memory) {
        return poolInfo;
    }
    
    function getAccountStakeLength (address account) public view returns (uint256) {
        return records[account].length;
    }
    
    function getAccountRecordByIndex (address account, uint256 index) public view returns (Record memory) {
        return records[account][index];
    }
    
    function setMaxBuyNumber(uint256 _maxBuyTimes) public onlyController {
        maxBuyTimes = _maxBuyTimes;
    }

    function getMaxBuyNumber() public view returns (uint256) {
        return maxBuyTimes;
    }

    function getBuyTimes(address account) public view returns (uint256){
        return buyTimes[account];
    }
    
    function getMinAndMaxBuyOnce() public view returns (MinMaxAmount memory) {
        return minMaxAmount;
    }
   
    struct MinMaxAmount {
        uint256 min;
        uint256 max;
    }

    struct Record {
        uint256 stakeAmount;
        uint256 totalRewardAmount;
        uint256 stakeTimestamp;
        uint256 withdrawAmount;
    }
    
    struct Rate {
        uint256 timestamp;
        uint256 rate;
    }
    
    struct PoolInfo {
        address stakeToken;
        address withdrawToken;
        uint256 stakeStartTime;
        uint256 maxStakeTotalSupply;
    }

}