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


//SourceUnit: ITRC20.sol

pragma solidity ^0.6.0;

/**
 * @dev Interface of the TRC standard as defined in the EIP.
 */
interface ITRC20 {
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
     * @dev burn `burnAmount` tokens from `sender`
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function burn(uint256 burnAmount) external returns (bool);

    /**
     * @dev burn `burnAmount` tokens from `sender`
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function burnFrom(address from,uint256 burnAmount) external returns (bool);

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


//SourceUnit: PoolLogic.sol

pragma solidity =0.6.0;


import "./ITRC20.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./PoolStorage.sol";

contract PoolLogic is PoolStorage {

    using SafeMath for uint256;
    using TransferHelper for address;

    modifier checkAmount(){
        _checkDayAmount();
        _;
    }
    function register(address _upAddr) public virtual payable timeArrived checkAmount {
        updateHashIndex();
        require(userMap[_upAddr].used, "Logic:invalid referrer");
        require(!userMap[msg.sender].used, "Logic:exist");
        require(msg.value == REGISTER_AMOUNT, "Logic:invalid amount");
        outAddr.transfer(msg.value);
        userMap[_upAddr].childrenCount += 1;
        userMap[_upAddr].childrenAddrArr.push(msg.sender);
        userArr.push(msg.sender);
        User memory user = userMap[msg.sender];
        user.upAddr = _upAddr;
        user.amount = 1 * ONE_HASH;
        user.createTime = now;
        user.checkPoint = getCurZeroTime();
        user.checkTime = now;
        user.used = true;
        userMap[msg.sender] = user;
        emit Register(msg.sender, _upAddr, now);

        uint256 dayIndex = getCurDayIndex();

        _checkUserDayAmountAndAdd(msg.sender, user.amount, dayIndex);

        _addTotalAndCheck(user.amount, dayIndex);

        exceDyBonus(msg.sender, user.amount, dayIndex);
    }


    function _addTotalAndCheck(uint256 newAmount, uint256 dayIndex) internal virtual {
        totalHashAmount = totalHashAmount.add(newAmount);

        dayHashMap[dayIndex] = totalHashAmount;
    }


    function _checkDayAmount() internal virtual {

        uint256 dayIndex = getCurDayIndex();
        if (dayIndex > lastUpdateDay) {
            uint256 lastAmount = dayHashMap[lastUpdateDay];
            for (uint256 i = lastUpdateDay + 1; i <= dayIndex; i++) {
                dayHashMap[i] = lastAmount;
            }
            lastUpdateDay = dayIndex;
        }
    }


    function updateDayInfo() public virtual {
        _checkDayAmount();
    }

    function updateDayInfo2(uint256 count) public virtual {


        uint256 dayIndex = getCurDayIndex();
        uint256 temp = count + lastUpdateDay;
        if (temp < dayIndex) {
            dayIndex = temp;
        }
        if (dayIndex > lastUpdateDay) {
            uint256 lastAmount = dayHashMap[lastUpdateDay];
            for (uint256 i = lastUpdateDay + 1; i <= dayIndex; i++) {
                dayHashMap[i] = lastAmount;
            }
            lastUpdateDay = dayIndex;
        }
    }

    function _checkUserDayAmountAndAdd(address _addr, uint256 newAmount, uint256 dayIndex) internal virtual {
        User storage user = userMap[_addr];
        uint256 len = user.hashDayArr.length;
        if (len > 0) {
            uint256 userLastUpdateDay = user.hashDayArr[len - 1];
            if (dayIndex > userLastUpdateDay) {
                user.userHashMap[dayIndex] = user.userHashMap[userLastUpdateDay];
                user.hashDayArr.push(dayIndex);
            }
        } else {
            user.hashDayArr.push(dayIndex);
        }
        user.userHashMap[dayIndex] = newAmount.add(user.userHashMap[dayIndex]);
    }


    function trxBuy() public virtual payable timeArrived checkAmount  {
        updateHashIndex();
        uint256 _ONCE_TRX_AMOUNT = currentHash[currentHashIndex].currentCxchangeTRX;
        require(userMap[msg.sender].used, "Logic:not active");
        require(msg.value >= _ONCE_TRX_AMOUNT, "Logic:invalid amount");
        require(msg.value.mod(_ONCE_TRX_AMOUNT) == 0, "Logic:invalid amount");
        uint dayIndex = getCurDayIndex();
        uint256 newNum = msg.value.div(_ONCE_TRX_AMOUNT);
        require(userDayLimitMap[msg.sender][dayIndex] + newNum <= EX_DAY_LIMIT, "limit");
        require(isOverBudget(), "Logic:excess budget");
        userDayLimitMap[msg.sender][dayIndex] += newNum;

        outAddr.transfer(msg.value);

        uint256 amount = ONE_HASH.mul(newNum);
        userMap[msg.sender].amount = userMap[msg.sender].amount.add(amount);

        currentHash[currentHashIndex].currentRemainingLimit = currentHash[currentHashIndex].currentRemainingLimit.add(newNum);
        emit TrxBuy(msg.sender, amount);
        _checkUserDayAmountAndAdd(msg.sender, amount, dayIndex);

        _addTotalAndCheck(amount, dayIndex);

        exceDyBonus(msg.sender, amount, dayIndex);
    }

    function tokenBuy(uint256 _hashCount) public virtual timeArrived checkAmount {
        updateHashIndex();
        require(userMap[msg.sender].used, "Logic:not active");
        require(_hashCount >= ONE_HASH, "Logic:one");
        require(_hashCount.mod(ONE_HASH) == 0, "Logic:no decimal");
        uint256 price = getAbcPrice();
        uint256 hashNum = _hashCount.div(ONE_HASH);
        // require(isOverBudget(), "Logic:excess budget");
        uint256 orderAmount = price.mul(hashNum);
        ITRC20 abcToken = ITRC20(ABC_ADDR);
        uint256 abcBalance = abcToken.balanceOf(msg.sender);
        require(abcBalance >= orderAmount, "Logic:not enough");

        abcToken.burnFrom(msg.sender, orderAmount);

        uint dayIndex = getCurDayIndex();
        userMap[msg.sender].amount = userMap[msg.sender].amount.add(_hashCount);
        currentHash[currentHashIndex].currentRemainingLimit = currentHash[currentHashIndex].currentRemainingLimit.add(hashNum);
        emit TrxBuy(msg.sender, _hashCount);

        _checkUserDayAmountAndAdd(msg.sender, _hashCount, dayIndex);

        _addTotalAndCheck(_hashCount, dayIndex);

        exceDyBonus(msg.sender, _hashCount, dayIndex);


    }

    function exceDyBonus(address _addr, uint256 _value, uint256 dayIndex) internal virtual {
        address upAddr = userMap[_addr].upAddr;
        for (uint256 i = 0; i < 2; i++) {
            User storage user = userMap[upAddr];
            (uint256 p, uint256 b) = getLevelPercent(user.childrenCount);
            uint256 bonus = _value.mul(p).div(b);
            if (i == 1) {
                bonus = _value.mul(p).mul(50).div(b).div(100);
            }

            emit DyBonus(_addr, upAddr, _value, bonus);

            user.amount = user.amount.add(bonus);
            user.dyAmount = user.dyAmount.add(bonus);
            _checkUserDayAmountAndAdd(upAddr, bonus, dayIndex);
            _addTotalAndCheck(bonus, dayIndex);
            if (user.upAddr == address(0)) {
                break;
            }
            upAddr = user.upAddr;
        }
    }

    function withdrawABC() public virtual timeArrived {
        User storage user = userMap[msg.sender];
        require(user.amount > 0, "Logic:invalid user");
        (uint256 userLastIndex, uint256 dayIndex) = getUserDayIndex(msg.sender);
        uint256 bonus = getBonus(msg.sender, dayIndex);
        require(bonus > 0, "Logic:not enough");
        ABC_ADDR.safeTransfer(msg.sender, bonus);
        updateHashIndex();
        emit WithdrawBonus(msg.sender, userLastIndex, dayIndex - 1, bonus);

        user.historyBonus = user.historyBonus.add(bonus);
        user.checkPoint = getCurZeroTime();
        user.checkTime = now;
    }

    function withdrawBonus(uint256 _dayCount) public virtual timeArrived {
        updateHashIndex();
        User storage user = userMap[msg.sender];
        require(user.used, "Logic:invalid user");
        (uint256 lastDay, uint256 curDay) = getUserDayIndex(msg.sender);
        uint256 realCount = 0;

        if (curDay.sub(lastDay) > _dayCount) {
            realCount = lastDay.add(_dayCount);
        } else {
            realCount = curDay;
        }

        uint256 bonus = getReceivableBonus(msg.sender, lastDay, realCount);
        require(bonus > 0, "Logic:not enough");
        ABC_ADDR.safeTransfer(msg.sender, bonus);

        emit WithdrawBonus(msg.sender, lastDay, realCount - 1, bonus);

        user.historyBonus = user.historyBonus.add(bonus);

        uint256 lastCheck = realCount.sub(lastDay).mul(ONE_DAY).add(user.checkPoint);
        user.checkPoint = lastCheck;
        user.checkTime = now;
    }
    //The result is true if the current user does not exceed 5 and is not out of limit
    function isOverBudget() internal virtual view returns (bool){
        return currentHash[currentHashIndex].currentRemainingLimit <= currentHash[currentHashIndex].hashRateLimit
        && currentHash[currentHashIndex].endTime>=block.timestamp
        && currentHashIndex <= 72;
    }

    function updateHashIndex() public virtual {
        uint256 nextTime = currentHash[currentHashIndex].nextTime;
        if (block.timestamp >= nextTime) {
            currentHashIndex = getCurDayIndex().div(15);
            uint256 _currentCxchangeTRX = 100 trx;
            //trx
            if (currentHashIndex > 32) {
                _currentCxchangeTRX = 200 trx;
            }
            currentHash[currentHashIndex] = CurrentHash(2000, 0, _currentCxchangeTRX, nextTime.add(1 days),nextTime.add(15 days));
        }
    }


    function hashTokenEchangeHash() external virtual returns(bool){
        ITRC20 hashTokens = ITRC20(hashToken);
        uint256 balance = hashTokens.balanceOf(msg.sender);
        require(balance>0&&hashTokens.burnFrom(msg.sender,balance),"Logic: not sufficient funds");
        uint256 dayIndex = getCurDayIndex();
        userMap[msg.sender].amount = userMap[msg.sender].amount.add(balance);
        _checkUserDayAmountAndAdd(msg.sender, balance, dayIndex);
        _addTotalAndCheck(balance, dayIndex);
        return true;
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


//SourceUnit: TransferHelper.sol

pragma solidity =0.6.0;

library TransferHelper {

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4 id = bytes4(keccak256("transfer(address,uint256)"));
        // bool success = token.call(id, to, value);
        // require(success, 'TransferHelper: TRANSFER_FAILED');
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

        // bytes4 id = bytes4(keccak256("transferFrom(address,address,uint256)"));
        // bool success = token.call(id, from, to, value);
        // require(success, 'TransferHelper: TRANSFER_FROM_FAILED');
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}