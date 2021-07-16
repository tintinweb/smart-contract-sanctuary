//SourceUnit: tabc_main_01_15_a.sol

pragma solidity ^0.5.5;

interface IERC20 {

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) external returns
    (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns
    (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256
    _value);
    event TransferFrom(address indexed _from, address indexed _to, uint256 _value);

    function burnFrom(address account, uint256 amount) external returns (bool success);

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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract T_abc {
    using SafeMath for uint256;


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

    address ABC_ADDR = 0x338D5e774639f18dd3C5Ff3A41052318D2cfF1Be;
    uint256 ABC_DECIMAL = 6;
    address payable outAddr = 0x65385d03CB70fE1E5355cAf1727312bb891a9862;
    address public owner = 0x9E4E7b2102D1A1C1e52D061B7b221E0fA37b2A74;


    mapping(address => User) userMap;
    address[]userArr;

    mapping(address => mapping(uint256 => uint256)) public userDayLimitMap;

    mapping(uint256 => uint256) dayHashMap;
    uint256 lastUpdateDay;
    uint256 totalHashAmount;


    uint256 TIME_BASE = 1608220800;
    uint256 ONE_DAY = 1 days;
    //
    uint256 ONE_TOKEN = 1 * 10 ** ABC_DECIMAL;
    uint256 ABC_START_PRICE = 5 * ONE_TOKEN;
    uint256 ABC_DAI_OUT_START = 7200 * ONE_TOKEN;
    uint256 ABC_DAI_OUT_END = 3600 * ONE_TOKEN;
    //
    uint256 ONE_HASH = 1 * 10 ** 6;

uint256 REGISTER_AMOUNT = 100 trx;
uint256 ONCE_TRX_AMOUNT = 50 trx;
uint256 EX_DAY_LIMIT = 5;


constructor(uint256 _baseTime, uint256 _oneDay) public {
TIME_BASE = _baseTime;
ONE_DAY = _oneDay;
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
}

modifier timeArrived(){
require(now >= TIME_BASE, "time not arrived");
_;
}

modifier checkAmount(){
_checkDayAmount();
_;
}

modifier onlyOwner(){
require(msg.sender == owner, "Ownable: caller is not the owner");
_;
}


function register(address _upAddr) public payable timeArrived checkAmount {
require(userMap[_upAddr].used, "invalid referrer");
require(!userMap[msg.sender].used, "exist");
require(msg.value == REGISTER_AMOUNT, "invalid amount");
//
outAddr.transfer(msg.value);
//
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


function _addTotalAndCheck(uint256 newAmount, uint256 dayIndex) internal {
totalHashAmount = totalHashAmount.add(newAmount);

dayHashMap[dayIndex] = totalHashAmount;
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


function trxBuy() public payable timeArrived checkAmount {
require(userMap[msg.sender].used, "not active");
require(msg.value >= ONCE_TRX_AMOUNT, "invalid amount");
require(msg.value.mod(ONCE_TRX_AMOUNT) == 0, "invalid amount");
uint dayIndex = getCurDayIndex();
uint256 newNum = msg.value.div(ONCE_TRX_AMOUNT);
require(userDayLimitMap[msg.sender][dayIndex] + newNum <= EX_DAY_LIMIT, "limit");
userDayLimitMap[msg.sender][dayIndex] += newNum;

outAddr.transfer(msg.value);

uint256 amount = ONE_HASH.mul(newNum);
userMap[msg.sender].amount = userMap[msg.sender].amount.add(amount);
emit TrxBuy(msg.sender, amount);
_checkUserDayAmountAndAdd(msg.sender, amount, dayIndex);

_addTotalAndCheck(amount, dayIndex);

exceDyBonus(msg.sender, amount, dayIndex);
}

function tokenBuy(uint256 _hashCount) public timeArrived checkAmount {
require(userMap[msg.sender].used, "not active");
require(_hashCount >= ONE_HASH, "one");
require(_hashCount.mod(ONE_HASH) == 0, "no decimal");

uint256 price = getAbcPrice();
uint256 hashNum = _hashCount.div(ONE_HASH);
uint256 orderAmount = price.mul(hashNum);
IERC20 abcToken = IERC20(ABC_ADDR);
uint256 abcBalance = abcToken.balanceOf(msg.sender);
require(abcBalance >= orderAmount, "not enough");

abcToken.burnFrom(msg.sender, orderAmount);

uint dayIndex = getCurDayIndex();
userMap[msg.sender].amount = userMap[msg.sender].amount.add(_hashCount);
emit TrxBuy(msg.sender, _hashCount);

_checkUserDayAmountAndAdd(msg.sender, _hashCount, dayIndex);

_addTotalAndCheck(_hashCount, dayIndex);

exceDyBonus(msg.sender, _hashCount, dayIndex);

}

function exceDyBonus(address _addr, uint256 _value, uint256 dayIndex) internal {
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
//
_checkUserDayAmountAndAdd(upAddr, bonus, dayIndex);
_addTotalAndCheck(bonus, dayIndex);
if (user.upAddr == address(0)) {
break;
}
upAddr = user.upAddr;
}
}

function withdrawABC() public timeArrived {
User storage user = userMap[msg.sender];
require(user.amount > 0, "invalid user");
(uint256 userLastIndex, uint256 dayIndex) = getUserDayIndex(msg.sender);
uint256 bonus = getBonus(msg.sender, dayIndex);
require(bonus > 0, "not enough");
safeTransfer(ABC_ADDR, msg.sender, bonus);

emit WithdrawBonus(msg.sender, userLastIndex, dayIndex - 1, bonus);

user.historyBonus = user.historyBonus.add(bonus);
user.checkPoint = getCurZeroTime();
user.checkTime = now;
}

function withdrawBonus(uint256 _dayCount) public timeArrived {
User storage user = userMap[msg.sender];
require(user.used, "invalid user");
(uint256 lastDay, uint256 curDay) = getUserDayIndex(msg.sender);
uint256 realCount = 0;

if (curDay.sub(lastDay) > _dayCount) {
realCount = lastDay.add(_dayCount);
} else {
realCount = curDay;
}

uint256 bonus = getReceivableBonus(msg.sender, lastDay, realCount);
require(bonus > 0, "not enough");
safeTransfer(ABC_ADDR, msg.sender, bonus);

emit WithdrawBonus(msg.sender, lastDay, realCount - 1, bonus);

user.historyBonus = user.historyBonus.add(bonus);

uint256 lastCheck = realCount.sub(lastDay).mul(ONE_DAY).add(user.checkPoint);
user.checkPoint = lastCheck;
user.checkTime = now;
}


function getAbcPrice() public view returns (uint256){
uint256 afterDays = getCurDayIndex();
if (afterDays >= 500) {
return ONE_TOKEN;
}
uint256 diff = ONE_TOKEN.mul(afterDays).mul(8).div(1000);
uint256 curPrice = ABC_START_PRICE.sub(diff);
if (curPrice < ONE_TOKEN) {
return ONE_TOKEN;
}
return curPrice;
}

function getAbcPriceByDay(uint256 dayIndex) public view returns (uint256){
if (dayIndex >= 500) {
return ONE_TOKEN;
}
uint256 diff = ONE_TOKEN.mul(dayIndex).mul(8).div(1000);
uint256 curPrice = ABC_START_PRICE.sub(diff);
if (curPrice < ONE_TOKEN) {
return ONE_TOKEN;
}
return curPrice;
}

function getDayOutAmount(uint256 passDays) public view returns (uint256, bool){
if (passDays >= 5000) {
return (0, true);

}
if (passDays == 4999) {
return (ABC_DAI_OUT_END / 2, true);
}
if (passDays >= 500) {
return (ABC_DAI_OUT_END, false);
}
uint256 diff = ONE_TOKEN.mul(passDays).mul(720).div(100);
uint256 curPrice = ABC_DAI_OUT_START.sub(diff);
if (curPrice < ABC_DAI_OUT_END) {
return (ABC_DAI_OUT_END, false);
}
return (curPrice, false);
}

function getPreDayOutAmount() public view returns (uint256, bool){
uint256 afterDays = getCurDayIndex();
return getDayOutAmount(afterDays);
}


function getLevelPercent(uint256 childCount) internal pure returns (uint256, uint256){
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

function getCurDayIndex() public view returns (uint256){
return now.sub(TIME_BASE).div(ONE_DAY);
}


function getDayIndex(uint256 _checkPoint) public view returns (uint256){
return _checkPoint.sub(TIME_BASE).div(ONE_DAY);
}

function getCurZeroTime() public view returns (uint256){
uint256 dayIndex = getCurDayIndex();
return TIME_BASE + dayIndex * ONE_DAY;
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

function _getDayBonus(address _addr, uint256 i) internal view returns (uint256){
(uint256 userAmount,,) = getUserSomeDayAmount(_addr, i, 0);
(uint256 totalAmount,) = getTotalHash(i);
(uint256 dayOutAmount,) = getDayOutAmount(i);
uint256 dayBonus = userAmount.mul(dayOutAmount).div(totalAmount);
return dayBonus;
}


function getUser(address _addr) public view returns (bool, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256){
User memory user = userMap[_addr];
uint256 dayIndex = getCurDayIndex();
uint256 dayHash = userDayLimitMap[_addr][dayIndex];
return (user.used, user.upAddr, user.amount, user.dyAmount, user.historyBonus, user.checkTime, user.checkPoint, user.childrenCount, dayHash);
}

function getChildrenList(address _addr, uint256 _startIndex, uint256 _endIndex) public view returns (address[]memory){
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


function getReceivableTotalBonus(address _addr) public view returns (uint256){
uint256 curDay = getCurDayIndex();
return getBonus(_addr, curDay);
}


function getReceivableBonus(address _addr, uint256 _startIndex, uint256 _endIndex) public view returns (uint256){
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



function getUserBonus(address _addr) public view returns (uint256, uint256){
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


function getUserDayIndex(address _addr) public view returns (uint256, uint256){
User memory user = userMap[_addr];
if (user.used) {
return (user.checkPoint.sub(TIME_BASE).div(ONE_DAY), now.sub(TIME_BASE).div(ONE_DAY));
}
return (0, now.sub(TIME_BASE).div(ONE_DAY));
}


function getSysInfo() public view returns (uint256, uint256, uint256, uint256, uint256, uint256){

uint256 curDay = getCurDayIndex();
(uint256 totalHash,) = getTotalHash(curDay);
uint256 curPrice = getAbcPriceByDay(curDay);
(uint256 curOutAmount,) = getDayOutAmount(curDay);
return (totalHash, curPrice, curOutAmount, curDay, TIME_BASE, userArr.length);
}



function getCheckDay(address _addr) public view returns (uint256, uint256){
User memory user = userMap[_addr];
return (user.checkPoint, (user.checkPoint - TIME_BASE) / ONE_DAY);
}

}