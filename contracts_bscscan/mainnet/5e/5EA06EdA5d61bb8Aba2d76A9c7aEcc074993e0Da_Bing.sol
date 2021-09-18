/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    function mint(address _to, uint256 _amount) external returns(bool);
    function burn(address _customer,uint256 _amount) external;
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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

interface IBing{
    function getUserInfo(address _customer)external view returns(address _recommend,uint8 level,address[] memory _members);
    function updateMyLevel(address _customer,uint8 _level,uint8 _sign,uint256 _amount)external;
    function out(address _customer) external;
    function mappingBing(address _customer,uint8 _level,address _recommend)external;
}

interface IFarmUsdt{
    function updateRecommendAmount(address _customer,uint256 _amount)external;
    function getUserInfo(address _customer)external view returns(uint256 _usdt,uint256 _recoUsdt,uint256 _recoPower,uint256 _debt);
    //function userIncome(address _user) external view returns(uint256 income);
    //function mappingInfo(address _customer,uint256 _stake,uint256 _recoUsdt,uint256 _power,uint256 _debt) external;
}

interface IFarmLPtoken{
    function updateRecommendUp(address _customer,uint256 _amount) external;
    function updateRecommendDown(address _customer,uint256 _amount) external;
}

contract Bing is IBing{
    using SafeMath for uint256;
    struct User{
        address recommend;
        uint8   level;
        address[] members;
    }
    mapping(address=>User) userInfo;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _permitList;
    address manager;

    constructor(){
        manager = msg.sender;
    }
    
    function addPermitList(address pool) public returns(bool){
        require(msg.sender==manager,"UCN:No permit");
        require(pool != address(0), "SwapMining: token is the zero address");
        return EnumerableSet.add(_permitList, pool);
    }

    function isPermitList(address pool) internal view returns (bool) {
        return EnumerableSet.contains(_permitList, pool);
    }
    function mappingBing(address _customer,uint8 _level,address _recommend)public override {
        require(isPermitList(msg.sender) == true,"UCN:No permission");
        User storage user = userInfo[_customer];
        user.recommend = _recommend;
        user.level = _level;
        User storage reco = userInfo[_recommend];
        reco.members.push(_customer);
    }
    
    function setLevel(address _customer,uint8 _level,address _recommend) public{
        require(msg.sender==manager,"UCN:No permit");
        User storage user = userInfo[_customer];
        user.level = _level;
        user.recommend = _recommend;
    }

    function getUserInfo(address _customer)public override view returns(address _recommend,uint8 _level,address[] memory _members){
        User storage user = userInfo[_customer];
        _recommend = user.recommend;
        _level = user.level;
        _members = user.members;
    }

    function getUserRecommend(address _customer) public view returns(address _reco){
        User storage user = userInfo[_customer];
        _reco = user.recommend;
    }

    function out(address _customer) public override {
        require(isPermitList(msg.sender) == true,"UCN:No permission");
        User storage user = userInfo[_customer];
        user.level = 0;
    }

    function updateMyLevel(address _customer,uint8 _level,uint8 _sign,uint256 _amount) public override {
        require(isPermitList(msg.sender) == true,"UCN:No permission");
        User storage user = userInfo[_customer];
        if(_sign==2){
            user.level = _level;
        }
        address _one = user.recommend;
        updateOne(_one,_sign, _amount);
        if(getUserRecommend(_one)!=address(0)){
            address _two = getUserRecommend(_one);
            updateTwo(_two,_sign, _amount);
            if(getUserRecommend(_two)!=address(0)){
                address _three = getUserRecommend(_two);
                updateThree(_three,_sign, _amount);
                if(getUserRecommend(_three)!=address(0)){
                    address _four = getUserRecommend(_three);
                    updateFour(_four,_sign, _amount);
                    if(getUserRecommend(_four)!=address(0)){
                        address _five = getUserRecommend(_four);
                        updateFive(_five,_sign, _amount);
                        if(getUserRecommend(_five)!=address(0)){
                            address _six = getUserRecommend(_five);
                            updateSix(_six,_sign, _amount);
                            if(getUserRecommend(_six)!=address(0)){
                                address _seven = getUserRecommend(_six);
                                updateSeven(_seven,_sign, _amount);
                                if(getUserRecommend(_seven)!=address(0)){
                                    address _eight = getUserRecommend(_seven);
                                    updateEight_Twenty(_eight, _sign,_amount);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function updateOne(address _one,uint8 _sign,uint256 _amount) internal{
        User storage user = userInfo[_one];
        if(user.level==0){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_one,_amount.mul(10).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_one,_amount.mul(10).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_one, _amount.mul(10).div(100));
            }
        }
        if(user.level==1){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_one,_amount.mul(15).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_one,_amount.mul(15).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_one, _amount.mul(15).div(100));
            }
        }
        if(user.level==2){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_one,_amount.mul(16).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_one,_amount.mul(16).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_one, _amount.mul(16).div(100));
            }
        }
        if(user.level==3){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_one,_amount.mul(17).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_one,_amount.mul(17).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_one, _amount.mul(17).div(100));
            }
        }
        if(user.level==4){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_one,_amount.mul(18).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_one,_amount.mul(18).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_one, _amount.mul(18).div(100));
            }
        }
        if(user.level==5){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_one,_amount.mul(20).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_one,_amount.mul(20).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_one, _amount.mul(20).div(100));
            }
        }
        if(user.level==6){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_one,_amount.mul(22).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_one,_amount.mul(22).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_one, _amount.mul(22).div(100));
            }
        }
        if(user.level==7){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_one,_amount.mul(25).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_one,_amount.mul(25).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_one, _amount.mul(25).div(100));
            }
        }
        
    }

    function updateTwo(address _two,uint8 _sign,uint256 _amount) internal{
        User storage user = userInfo[_two];
        if(user.level==1){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_two,_amount.mul(10).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_two,_amount.mul(10).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_two, _amount.mul(10).div(100));
            }
        }
        if(user.level==2){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_two,_amount.mul(11).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_two,_amount.mul(11).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_two, _amount.mul(11).div(100));
            }
        }
        if(user.level==3){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_two,_amount.mul(12).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_two,_amount.mul(12).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_two, _amount.mul(12).div(100));
            }
        }
        if(user.level==4){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_two,_amount.mul(13).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_two,_amount.mul(13).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_two, _amount.mul(13).div(100));
            }
        }
        if(user.level==5){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_two,_amount.mul(14).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_two,_amount.mul(14).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_two, _amount.mul(14).div(100));
            }
        }
        if(user.level==6){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_two,_amount.mul(16).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_two,_amount.mul(16).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_two, _amount.mul(16).div(100));
            }
        }
        if(user.level==7){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_two,_amount.mul(18).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_two,_amount.mul(18).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_two, _amount.mul(18).div(100));
            }
        }
        
    }

    function updateThree(address _three,uint8 _sign,uint256 _amount) internal{
        User storage user = userInfo[_three];
        if(user.level==2){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_three,_amount.mul(9).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_three,_amount.mul(9).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_three, _amount.mul(9).div(100));
            }
        }
        if(user.level==3){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_three,_amount.mul(10).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_three,_amount.mul(10).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_three, _amount.mul(10).div(100));
            }
        }
        if(user.level==4){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_three,_amount.mul(11).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_three,_amount.mul(11).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_three, _amount.mul(11).div(100));
            }
        }
        if(user.level==5){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_three,_amount.mul(12).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_three,_amount.mul(12).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_three, _amount.mul(12).div(100));
            }
        }
        if(user.level==6){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_three,_amount.mul(14).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_three,_amount.mul(14).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_three, _amount.mul(14).div(100));
            }
        }
        if(user.level==7){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_three,_amount.mul(16).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_three,_amount.mul(16).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_three, _amount.mul(16).div(100));
            }
        }
        
    }

    function updateFour(address _four,uint8 _sign,uint256 _amount) internal{
        User storage user = userInfo[_four];
        if(user.level==2){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_four,_amount.mul(7).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_four,_amount.mul(7).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_four, _amount.mul(7).div(100));
            }
        }
        if(user.level==3){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_four,_amount.mul(8).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_four,_amount.mul(8).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_four, _amount.mul(8).div(100));
            }
        }
        if(user.level==4){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_four,_amount.mul(9).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_four,_amount.mul(9).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_four, _amount.mul(9).div(100));
            }
        }
        if(user.level==5){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_four,_amount.mul(10).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_four,_amount.mul(10).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_four, _amount.mul(10).div(100));
            }
        }
        if(user.level==6){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_four,_amount.mul(12).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_four,_amount.mul(12).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_four, _amount.mul(12).div(100));
            }
        }
        if(user.level==7){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_four,_amount.mul(14).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_four,_amount.mul(14).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_four, _amount.mul(14).div(100));
            }
        }
        
    }

    function updateFive(address _five,uint8 _sign,uint256 _amount) internal{
        User storage user = userInfo[_five];
        if(user.level>=3){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_five,_amount.mul(7).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_five,_amount.mul(7).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_five, _amount.mul(7).div(100));
            }
        }
        
    }

    function updateSix(address _six,uint8 _sign,uint256 _amount) internal{
        User storage user = userInfo[_six];
        if(user.level>=3){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_six,_amount.mul(3).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_six,_amount.mul(3).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_six, _amount.mul(3).div(100));
            }
        }
        
    }

    function updateSeven(address _seven,uint8 _sign,uint256 _amount) internal{
        User storage user = userInfo[_seven];
        if(user.level>3){
            if(_sign==0){
                IFarmLPtoken(msg.sender).updateRecommendUp(_seven,_amount.mul(2).div(100));
            }else if(_sign==1){
                IFarmLPtoken(msg.sender).updateRecommendDown(_seven,_amount.mul(2).div(100));
            }else{
                IFarmUsdt(msg.sender).updateRecommendAmount(_seven, _amount.mul(2).div(100));
            }
        }
        
    }

    function updateEight_Twenty(address _eight,uint8 _sign,uint256 _amount) internal{
        User storage user = userInfo[_eight];
        address _loop = user.recommend;
        //0-8 1-9 2-10 3-11 4-12 5-13 6-14 7-15 8-16 9-17 10-18 11-19 12-20
        for(uint i=0;i<13;i++){
            User storage loop = userInfo[_loop];
            if(loop.level>3 && i<1){
                    if(_sign==0){
                        IFarmLPtoken(msg.sender).updateRecommendUp(_loop,_amount.mul(1).div(100));
                        _loop = loop.recommend;
                    }else if(_sign==1){
                        IFarmLPtoken(msg.sender).updateRecommendDown(_loop,_amount.mul(1).div(100));
                        _loop = loop.recommend;
                    }else{
                        IFarmUsdt(msg.sender).updateRecommendAmount(_loop, _amount.mul(1).div(100));
                        _loop = loop.recommend;
                    }
                }else if(loop.level>4 && i<5){
                    if(_sign==0){
                        IFarmLPtoken(msg.sender).updateRecommendUp(_loop,_amount.mul(1).div(100));
                        _loop = loop.recommend;
                    }else if(_sign==1){
                        IFarmLPtoken(msg.sender).updateRecommendDown(_loop,_amount.mul(1).div(100));
                        _loop = loop.recommend;
                    }else{
                        IFarmUsdt(msg.sender).updateRecommendAmount(_loop, _amount.mul(1).div(100));
                        _loop = loop.recommend;
                    }
                }else if(loop.level>5 && i<9){
                    if(_sign==0){
                        IFarmLPtoken(msg.sender).updateRecommendUp(_loop,_amount.mul(1).div(100));
                        _loop = loop.recommend;
                    }else if(_sign==1){
                        IFarmLPtoken(msg.sender).updateRecommendDown(_loop,_amount.mul(1).div(100));
                        _loop = loop.recommend;
                    }else{
                        IFarmUsdt(msg.sender).updateRecommendAmount(_loop, _amount.mul(1).div(100));
                        _loop = loop.recommend;
                    }
                }else if(loop.level>=7 && i<13){
                    if(_sign==0){
                        IFarmLPtoken(msg.sender).updateRecommendUp(_loop,_amount.mul(1).div(100));
                        _loop = loop.recommend;
                    }else if(_sign==1){
                        IFarmLPtoken(msg.sender).updateRecommendDown(_loop,_amount.mul(1).div(100));
                        _loop = loop.recommend;
                    }else{
                        IFarmUsdt(msg.sender).updateRecommendAmount(_loop, _amount.mul(1).div(100));
                        _loop = loop.recommend;
                    }
                }else{
                    _loop = loop.recommend;
                }
        }
    }
}