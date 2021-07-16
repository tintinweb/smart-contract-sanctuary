//SourceUnit: etvStaking.sol

pragma solidity ^0.5.10;

interface IERC20 {

    function balanceOf(address _owner) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) external returns
    (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function allowance(address _owner, address _spender) external view returns
    (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256
    _value);
    event TransferFrom(address indexed _from, address indexed _to, uint256 _value);

    function burnFrom(address account, uint256 amount) external returns (bool);

}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract etvStaking {
    using SafeMath for uint256;

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }


    event WithdrawBonus(address indexed _from, uint256 _startIndex, uint256 _endIndex, uint256 _bonus);
    event Stake(address indexed _from, uint256 _amount);

    uint256 public ONE_DAY = 60 * 60 * 4;//4H
    uint256 public tokenDecimal = 8;
    uint256 public ddd = 10 ** tokenDecimal;
    uint256 public totalOut = 420000 * (10 ** tokenDecimal);
    uint256 public firstOut = 271295235 * (10 ** (tokenDecimal - 4));//27129.5235
    uint256 public START_TIME = 1624550400;//6.25
    mapping(address => uint256) userStakeMap;


    address inTokenAddr = 0x1e727908BCAbc888BdeEE3D7c6C1bA828a28E0CC;
    address outTokenAddr = 0xbadA2C95D64b2876CFCe1D9aC8803aB99295f250;


    struct RewardLog {
        uint256 dayCount;
        uint256 amount;
        uint256 createTime;
    }

    struct User {
        uint256 totalInAmount;
        uint256 historyBonus;
        uint256 checkPoint;
        uint256 checkTime;
        uint256 stakeCount;
        uint8 valid;
        uint256[] orderIdList;
        uint256[] hashDayArr;
        mapping(uint256 => uint256) userHashMap;
        RewardLog[] rewardArr;
    }

    struct Order {
        uint256 amount;
        uint256 createTime;
    }


    mapping(address => User) public userMap;
    address[]public userArr;

    Order[] public orderArr;


    mapping(uint256 => uint256) public dayHashMap;
    uint256 public lastUpdateDay;
    uint256 public totalHashAmount;
    uint256 public totalRewardAmount;
    mapping(uint256 => uint256) public monthOutMap; 
    constructor() public {
        _initMonthOut();
    }

    function _initMonthOut() internal {
        uint temp = totalOut;
        uint cur = firstOut;
        for (uint256 i = 0; i < 29; i++) {
            monthOutMap[i] = cur;
            if (i == 28) {
                monthOutMap[i] = temp;
            } else {
                temp = temp.sub(cur);
                cur = cur.mul(95).div(100);
            }
        }
    }

    modifier timeArrived(){
        require(now >= START_TIME, "time not arrived");
        _;
    }

    modifier checkAmount(){
        _checkDayAmount();
        _;
    }


    function stake(uint256 amount) public timeArrived checkAmount {
        IERC20 inToken = IERC20(inTokenAddr);
        require(inToken.balanceOf(msg.sender) >= amount, "not enough");
        safeTransferFrom(inTokenAddr, msg.sender, address(this), amount);
        //
        User storage user = userMap[msg.sender];
        if (user.valid == 0) {
            user.valid = 1;
            uint256 zeroTime = getCurZeroTime();
            user.checkTime = now;
            user.checkPoint = zeroTime;
            userArr.push(msg.sender);
        }
        user.totalInAmount = user.totalInAmount.add(amount);
        //
        uint dayIndex = getCurDayIndex();

        _checkUserDayAmountAndAdd(msg.sender, amount, dayIndex);
        _addTotalAndCheck(amount, dayIndex);
        user.orderIdList.push(orderArr.length);
        Order memory order = Order(amount, now);
        orderArr.push(order);
        emit Stake(msg.sender, amount);
    }

    function withdrawBonus(uint256 _dayCount) public timeArrived {
        User storage user = userMap[msg.sender];
        require(user.valid == 1, "invalid user");
        (uint256 lastDay, uint256 curDay) = getUserDayIndex(msg.sender);
        uint256 realCount = 0;

        if (curDay.sub(lastDay) > _dayCount) {
            realCount = lastDay.add(_dayCount);
        } else {
            realCount = curDay;
        }

        uint256 bonus = getReceivableBonus(msg.sender, lastDay, realCount);
        require(bonus > 0, "not enough");
        safeTransfer(outTokenAddr, msg.sender, bonus);

        emit WithdrawBonus(msg.sender, lastDay, realCount - 1, bonus);

        user.historyBonus = user.historyBonus.add(bonus);

        uint256 lastCheck = realCount.sub(lastDay).mul(ONE_DAY).add(user.checkPoint);
        user.checkPoint = lastCheck;
        user.checkTime = now;

        RewardLog memory rlog = RewardLog(realCount.sub(lastDay), bonus, now);
        user.rewardArr.push(rlog);

        totalRewardAmount = totalRewardAmount.add(bonus);

    }


    function _checkDayAmount() internal {

        uint256 dayIndex = getCurDayIndex();
        if (dayIndex > lastUpdateDay) {
            uint256 lastAmount = dayHashMap[lastUpdateDay];
            for (uint256 i = lastUpdateDay + 1; i <= dayIndex; i++) {

                dayHashMap[i] = lastAmount;
            }
            lastUpdateDay = dayIndex;
        }
    }

    function updateDayInfo() public {
        _checkDayAmount();
    }

    function updateDayInfo2(uint256 count) public {

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

    function _addTotalAndCheck(uint256 newAmount, uint256 dayIndex) internal {
        totalHashAmount = totalHashAmount.add(newAmount);

        dayHashMap[dayIndex] = totalHashAmount;
    }

    function _checkUserDayAmountAndAdd(address _addr, uint256 newAmount, uint256 dayIndex) internal {
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

    function getReceivableBonus(address _addr, uint256 _startIndex, uint256 _endIndex) public view returns (uint256){
        require(_endIndex > _startIndex, "illegal need e>s");
        User memory user = userMap[_addr];
        if (user.valid == 0) {
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

    function getCurDayIndex() public view returns (uint256){
        return now.sub(START_TIME).div(ONE_DAY);
    }

    function getDayIndex(uint256 _checkPoint) public view returns (uint256){
        return _checkPoint.sub(START_TIME).div(ONE_DAY);
    }

    function getCurZeroTime() public view returns (uint256){
        uint256 dayIndex = getCurDayIndex();
        return START_TIME + dayIndex * ONE_DAY;
    }

    function getTotalHash(uint256 dayIndex) public view returns (uint256, uint256){
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

    function getBonus(address _addr, uint256 dayIndex) public view returns (uint256){
        User memory user = userMap[_addr];
        if (user.valid == 0) {
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

    function _getDayBonus(address _addr, uint256 i) internal view returns (uint256){
        (uint256 userAmount,,) = getUserSomeDayAmount(_addr, i, 0);
        (uint256 totalAmount,) = getTotalHash(i);
        (uint256 dayOutAmount,) = getDayOutAmount(i);
        uint256 dayBonus = userAmount.mul(dayOutAmount).div(totalAmount);
        return dayBonus;
    }

    function getUser(address _addr) public view returns (uint8, uint256, uint256, uint256, uint256, uint256, uint256){
        User memory user = userMap[_addr];
        return (user.valid, user.totalInAmount, user.historyBonus, user.checkTime, user.checkPoint, user.orderIdList.length, user.rewardArr.length);
    }

    function getUserDayIndex(address _addr) public view returns (uint256, uint256){
        User memory user = userMap[_addr];
        if (user.valid == 1) {
            return (user.checkPoint.sub(START_TIME).div(ONE_DAY), now.sub(START_TIME).div(ONE_DAY));
        }
        return (0, now.sub(START_TIME).div(ONE_DAY));
    }

    function getDayOutAmount(uint256 passDays) public view returns (uint256, bool){

        if (passDays >= 5220) {

            return (0, true);

        }

        uint256 month = passDays.div(6).div(30);
        uint256 monthOut = monthOutMap[month];
        return (monthOut.div(30).div(6), false);
    }


    function getSysInfo() public view returns (uint256, uint256, uint256, uint256, uint256, uint256){

        uint256 curDay = getCurDayIndex();
        (uint256 totalHash,) = getTotalHash(curDay);
        (uint256 curOutAmount,) = getDayOutAmount(curDay);
        return (totalHash, curOutAmount, curDay, START_TIME, userArr.length, totalRewardAmount);
    }


    function getCheckDay(address _addr) public view returns (uint256, uint256){
        User memory user = userMap[_addr];
        return (user.checkPoint, (user.checkPoint - START_TIME) / ONE_DAY);
    }

    function getUserOrder(address _addr, uint256 _startIndex, uint256 _endIndex) public view returns (uint256[] memory amountArr, uint256[] memory timeArr){
        User memory user = userMap[_addr];
        if (_endIndex > _startIndex && _startIndex < user.orderIdList.length) {
            if (_endIndex > user.orderIdList.length) {
                _endIndex = user.orderIdList.length;
            }
            uint len = _endIndex.sub(_startIndex);
            amountArr = new uint256[](len);
            timeArr = new uint256[](len);
            uint index;
            for (uint i = _startIndex; i < _endIndex; i++) {
                Order memory od = orderArr[user.orderIdList[i]];
                amountArr[index] = od.amount;
                timeArr[index] = od.createTime;
                index++;
            }
        }

    }

    function getUserRewardList(address _addr, uint256 _startIndex, uint256 _endIndex) public view returns (uint256[] memory amountArr, uint256[] memory timeArr, uint256[] memory dayArr){
        User memory user = userMap[_addr];
        if (_endIndex > _startIndex && _startIndex < user.rewardArr.length) {
            if (_endIndex > user.rewardArr.length) {
                _endIndex = user.rewardArr.length;
            }
            uint len = _endIndex.sub(_startIndex);
            amountArr = new uint256[](len);
            timeArr = new uint256[](len);
            dayArr = new uint256[](len);
            uint index;
            for (uint i = _startIndex; i < _endIndex; i++) {
                RewardLog memory od = user.rewardArr[i];
                amountArr[index] = od.amount;
                timeArr[index] = od.createTime;
                dayArr[index] = od.dayCount;
                index++;
            }
        }

    }


}