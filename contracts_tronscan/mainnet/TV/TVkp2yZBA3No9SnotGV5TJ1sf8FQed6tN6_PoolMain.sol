//SourceUnit: Address.sol

// SPDX-License-Identifier: MIT

pragma solidity =0.6.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call.value(value)(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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


//SourceUnit: PoolMain.sol


pragma solidity =0.6.0;

import "./PoolStorage.sol";
import "./Address.sol";
import "./Proxy.sol";

contract PoolMain is PoolStorage, Proxy {

    address public pendingAdmin;

    event Upgraded(address indexed newImplementation);
    event NewPendingAdmin(address indexed oldPendingAdmin, address indexed newPendingAdmin);
    event NewAdmin(address indexed oldAdmin, address indexed newAdmin);

    constructor(address _trc20,address _hashToken,uint256 _baseTime) public {
        hashToken = _hashToken;
        owner = msg.sender;
        ABC_ADDR = _trc20;
        outAddr = msg.sender;
        TIME_BASE = _baseTime;
        ONE_DAY = 1 days;
        // lastUpdateDay = block.timestamp;
        //init user
        User memory user = userMap[owner];
        user.createTime = now;
        if (now > TIME_BASE) {
            user.checkPoint = getCurZeroTime();
        } else {
            user.checkPoint = TIME_BASE;
        }
        user.checkTime = now;
        user.used = true;
        userMap[owner] = user;
        userArr.push(owner);
        currentHashIndex = 1;
        currentHash[currentHashIndex] = CurrentHash(2000, 0, 100 trx, block.timestamp.add(1 days), block.timestamp.add(15 days));
    }
    /**
    * @dev Returns the current implementation address.
    */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    function implementation() external view virtual returns (address){
        return _implementation();
    }

    function upgradeTo(address newImplementation) external virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");
        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "Pending admin You are not ");
        address oldAdmin = owner;
        owner = pendingAdmin;
        pendingAdmin = address(0);
        emit NewPendingAdmin(owner, pendingAdmin);
        emit NewAdmin(oldAdmin, owner);
    }

    function setPendingAdmin(address _newAdmin) external virtual onlyOwner {
        address oldPendingAdmin = pendingAdmin;
        pendingAdmin = _newAdmin;
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }
}


//SourceUnit: PoolStorage.sol

pragma solidity =0.6.0;

import "./SafeMath.sol";

contract PoolStorage {
    using SafeMath for uint256;
    event Register(address indexed _from, address indexed _up, uint256 _rTime);
    event WithdrawBonus(address indexed _from, uint256 _startIndex, uint256 _endIndex, uint256 _bonus);
    event TrxBuy(address indexed _from, uint256 _amount);
    event TokenBuy(address indexed _from, uint256 _amount);
    event DyBonus(address indexed _from, address indexed _up, uint256 _amount, uint256 _bonus);


    struct User {
        address upAddr;
        uint256 amount;
        uint256 dyAmount;
        uint256 createTime;
        bool used;
        uint256 bonus;
        uint256 historyBonus;
        uint256 checkPoint;
        uint256 checkTime;
        uint256 childrenCount;
        mapping(uint256 => uint256) userHashMap;
        uint256[] hashDayArr;
        address[] childrenAddrArr;
    }

    address public ABC_ADDR;
    uint256 public constant ABC_DECIMAL = 6;
    address payable outAddr;
    address public owner;

    mapping(address => User) public userMap;
    address[]userArr;

    mapping(address => mapping(uint256 => uint256)) public userDayLimitMap;

    mapping(uint256 => uint256) dayHashMap;
    uint256 lastUpdateDay;
    uint256 totalHashAmount;


    uint256 public  TIME_BASE;
    uint256 public  ONE_DAY;
    uint256 public constant ONE_TOKEN = 1 * 10 ** ABC_DECIMAL;
    uint256 public constant ABC_START_PRICE = 5 * ONE_TOKEN;
    uint256 public constant ABC_DAI_OUT_START = 7200 * ONE_TOKEN;
    uint256 public constant ABC_DAI_OUT_END = 3600 * ONE_TOKEN;
    uint256 public constant ONE_HASH = 1 * 10 ** 6;

    uint256 public constant  REGISTER_AMOUNT = 100 trx;
    uint256 public  ONCE_TRX_AMOUNT = 100 trx;
    uint256 public constant EX_DAY_LIMIT = 5;
    //This is the current period
    struct CurrentHash {
        uint256 hashRateLimit;
        uint256 currentRemainingLimit;
        uint256 currentCxchangeTRX;
        uint256 endTime;
        uint256 nextTime;
    }

    mapping(uint256 => CurrentHash) public currentHash;
    //number of periods
    uint256 public currentHashIndex;
    address public hashToken;
    modifier timeArrived(){
        require(now >= TIME_BASE, "PoolStorage:time not arrived");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "PoolStorage: caller is not the owner");
        _;
    }

    function getAbcPrice() public virtual view returns (uint256){
        uint256 afterDays = getCurDayIndex();
        if (afterDays >= 1000) {
            return ONE_TOKEN;
        }
        uint256 diff = ONE_TOKEN.mul(afterDays).mul(4).div(1000);
        uint256 curPrice = ABC_START_PRICE.sub(diff);
        if (curPrice < ONE_TOKEN) {
            return ONE_TOKEN;
        }
        return curPrice;
    }

    function getAbcPriceByDay(uint256 dayIndex) public virtual pure returns (uint256){
        if (dayIndex >= 1000) {
            return ONE_TOKEN;
        }
        uint256 diff = ONE_TOKEN.mul(dayIndex).mul(4).div(1000);
        uint256 curPrice = ABC_START_PRICE.sub(diff);
        if (curPrice < ONE_TOKEN) {
            return ONE_TOKEN;
        }
        return curPrice;
    }

    function getDayOutAmount(uint256 passDays) public virtual pure returns (uint256, bool){
        if (passDays >= 5000) {
            return (0, true);

        }
        if (passDays == 4999) {
            return (ABC_DAI_OUT_END / 2, true);
        }
        if (passDays >= 1000) {
            return (ABC_DAI_OUT_END, false);
        }
        uint256 diff = ONE_TOKEN.mul(passDays).mul(720).div(100);
        uint256 curPrice = ABC_DAI_OUT_START.sub(diff);
        if (curPrice < ABC_DAI_OUT_END) {
            return (ABC_DAI_OUT_END, false);
        }
        return (curPrice, false);
    }

    function getPreDayOutAmount() public virtual view returns (uint256, bool){
        uint256 afterDays = getCurDayIndex();
        return getDayOutAmount(afterDays);
    }

    function getLevelPercent(uint256 childCount) internal virtual pure returns (uint256, uint256){
        if (childCount >= 5) {
            return (5, 100);
        }
        if (childCount >= 3) {
            return (3, 100);
        }
        if (childCount >= 1) {
            return (1, 100);
        }
        return (0, 100);
    }

    function getCurDayIndex() public virtual view returns (uint256){
        return now.sub(TIME_BASE).div(ONE_DAY);
    }

    function getDayIndex(uint256 _checkPoint) public virtual view returns (uint256){
        return _checkPoint.sub(TIME_BASE).div(ONE_DAY);
    }

    function getCurZeroTime() public virtual view returns (uint256){
        uint256 dayIndex = getCurDayIndex();
        return TIME_BASE + dayIndex * ONE_DAY;
    }

    function getTotalHash(uint256 dayIndex) public virtual view returns (uint256, uint256){
        for (uint256 i = dayIndex; i >= 0;) {
            uint256 dayHash = dayHashMap[i];
            if (dayHash > 0) {
                return (dayHash, i);
            }
            if (i > 0) {
                i --;
            } else {
                return (dayHash, 0);
            }
        }
        return (0, 0);
    }

    function getBonus(address _addr, uint256 dayIndex) public virtual view returns (uint256){
        User memory user = userMap[_addr];
        if (!user.used) {
            return 0;
        }
        uint lastDayIndex = getDayIndex(user.checkPoint);
        if (lastDayIndex >= dayIndex) {
            return 0;
        }
        uint256 totalBonus = 0;
        uint256 userHashIndex = 0;
        for (uint256 i = lastDayIndex; i < dayIndex; i++) {
            (uint256 userAmount,, uint256 userHashIndexTemp) = getUserSomeDayAmount(_addr, i, userHashIndex);
            (uint256 totalAmount,) = getTotalHash(i);
            (uint256 dayOutAmount,) = getDayOutAmount(i);

            uint256 dayBonus = userAmount.mul(dayOutAmount).div(totalAmount);
            totalBonus = totalBonus.add(dayBonus);
            userHashIndex = userHashIndexTemp;
        }
        return totalBonus;
    }

    function _getDayBonus(address _addr, uint256 i) internal virtual view returns (uint256){
        (uint256 userAmount,,) = getUserSomeDayAmount(_addr, i, 0);
        (uint256 totalAmount,) = getTotalHash(i);
        (uint256 dayOutAmount,) = getDayOutAmount(i);
        uint256 dayBonus = userAmount.mul(dayOutAmount).div(totalAmount);
        return dayBonus;
    }

    // what?
    function getUser(address _addr) public virtual view returns (bool, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256){
        User memory user = userMap[_addr];
        uint256 dayIndex = getCurDayIndex();
        uint256 dayHash = userDayLimitMap[_addr][dayIndex];
        return (user.used, user.upAddr, user.amount, user.dyAmount, user.historyBonus, user.checkTime, user.checkPoint, user.childrenCount, dayHash);
    }
    //Gets a list of child objects
    function getChildrenList(address _addr, uint256 _startIndex, uint256 _endIndex) public virtual view returns (address[]memory){
        require(_endIndex > _startIndex, "illegal need e>s");
        User memory user = userMap[_addr];
        require(_endIndex <= user.childrenCount, "illegal, out of bounds");
        uint256 len = _endIndex.sub(_startIndex);
        address[] memory arr = new address[](len);
        uint256 index = 0;
        for (uint256 i = _startIndex; i < _endIndex; i++) {
            arr[index] = user.childrenAddrArr[i];
            index++;
        }
        return arr;
    }


    function getReceivableTotalBonus(address _addr) public virtual view returns (uint256){
        uint256 curDay = getCurDayIndex();
        return getBonus(_addr, curDay);
    }


    function getReceivableBonus(address _addr, uint256 _startIndex, uint256 _endIndex) public virtual view returns (uint256){
        require(_endIndex > _startIndex, "illegal need e>s");
        User memory user = userMap[_addr];
        if (!user.used) {
            return 0;
        }
        uint256 totalBonus = 0;
        uint256 userHashIndex = 0;
        for (uint256 i = _startIndex; i < _endIndex; i++) {
            (uint256 userAmount,, uint256 userHashIndexTemp) = getUserSomeDayAmount(_addr, i, userHashIndex);
            (uint256 totalAmount,) = getTotalHash(i);
            (uint256 dayOutAmount,) = getDayOutAmount(i);
            uint256 dayBonus = userAmount.mul(dayOutAmount).div(totalAmount);
            totalBonus = totalBonus.add(dayBonus);
            userHashIndex = userHashIndexTemp;
        }
        return totalBonus;
    }


    function getUserBonus(address _addr) public virtual view returns (uint256, uint256){
        User memory user = userMap[_addr];
        if (!user.used) {
            return (0, 0);
        }
        uint256 curDay = getCurDayIndex();
        uint256 curEstimateBonus = _getDayBonus(_addr, curDay);
        uint256 preBonus = 0;
        if (curDay != 0) {
            preBonus = _getDayBonus(_addr, curDay - 1);
        }
        return (preBonus, curEstimateBonus);
    }


    function getUserDayIndex(address _addr) public virtual view returns (uint256, uint256){
        User memory user = userMap[_addr];
        if (user.used) {
            if (user.checkPoint > TIME_BASE) {
                return (user.checkPoint.sub(TIME_BASE).div(ONE_DAY), now.sub(TIME_BASE).div(ONE_DAY));
            } else {
                return (0, now.sub(TIME_BASE).div(ONE_DAY));
            }
        }
        return (0, now.sub(TIME_BASE).div(ONE_DAY));
    }


    function getSysInfo() public virtual view returns (uint256, uint256, uint256, uint256, uint256, uint256){

        uint256 curDay = getCurDayIndex();
        (uint256 totalHash,) = getTotalHash(curDay);
        uint256 curPrice = getAbcPriceByDay(curDay);
        (uint256 curOutAmount,) = getDayOutAmount(curDay);
        return (totalHash, curPrice, curOutAmount, curDay, TIME_BASE, userArr.length);
    }


    function getCheckDay(address _addr) public virtual view returns (uint256, uint256){
        User memory user = userMap[_addr];
        return (user.checkPoint, (user.checkPoint - TIME_BASE) / ONE_DAY);
    }

    function getUserSomeDayAmount(address _addr, uint256 dayIndex, uint256 userHashIndex) public view returns (uint256, uint256, uint256){
        User memory user = userMap[_addr];
        uint256 len = user.hashDayArr.length;
        if (len == 0) {
            return (0, 0, 0);
        }
        uint256 lastIndex = user.hashDayArr[0];
        uint256 userHashArrLastIndex = 0;
        for (uint256 i = userHashIndex; i < len; i++) {
            uint256 day = user.hashDayArr[i];
            if (day > dayIndex) {
                break;
            }
            lastIndex = day;
            userHashArrLastIndex = i;
        }

        return (userMap[_addr].userHashMap[lastIndex], lastIndex, userHashArrLastIndex);
    }
}

//SourceUnit: Proxy.sol

// SPDX-License-Identifier: MIT

pragma solidity =0.6.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
        // Copy msg.data. We take full control of memory in this inline assembly
        // block because it will not return to Solidity code. We overwrite the
        // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

        // Call the implementation.
        // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

        // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
//        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}


//SourceUnit: SafeMath.sol

pragma solidity ^0.6.0;

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