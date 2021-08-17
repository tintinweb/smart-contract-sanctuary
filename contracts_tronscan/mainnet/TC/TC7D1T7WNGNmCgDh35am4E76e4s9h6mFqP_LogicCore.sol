//SourceUnit: IERC20.sol

pragma solidity 0.5.17;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


//SourceUnit: IPDUserData.sol

pragma solidity 0.5.17;

interface IPDUserData {
    function register(address user, address inviter) external returns (bool);

    function updateUserPower(address user,uint256 personal,uint256 teamPower) external returns(bool);

    function updateUserPledge(address user,uint256 amount30,uint256 amount90,uint256 timestamp) external returns(bool);

    function updateFinance(address user,uint256 withdraw,uint256 lastWithdrawTime,uint256 frozen,uint256 pool) external returns(bool);

    function updateUserLastSettleTime(address user,uint256 settleTime) external returns(bool);

    function updateUserLastMonthSettleData(address user, uint256 teamPower,uint256 times) external returns (bool);

    function updateNetPower(uint256 computerPower,uint256 teamPower) external returns(bool);

    function getNetPower() external view returns(uint256 computerPower,uint256 teamPower) ;

    function getUserLastMonthSettleData(address user) external view returns( uint256 teamPower,uint256 times);

    function getUserInviter(address user) external view returns(address);

    function getUserTeamMembers(address user) external view returns(address[] memory);

    function getRegisterTime(address user) external view returns(uint256);

    function getUserPower(address user) external view returns(uint256 personal, uint256 team);

    function getUserPledge(address user) external view returns(uint256 pledge30, uint256 pledge90, uint256 pledgeTime);

    function getUserFinance(address user) external view returns(uint256 withdraw,uint256 lastWithdrawTime,uint256 frozen,uint256 pool);

    function getUserLastSettleTime(address user) external view returns(uint256);
}


//SourceUnit: LogicCore.sol

pragma solidity 0.5.17;

import "./IPDUserData.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract LogicCore is Ownable {
    using SafeMath for uint256;
    IPDUserData private userData;

    bool public pause;

    mapping(address => bool) frozenUserMap;

    uint256 private DAYS_30 = 30 * 24 * 60 * 60;

    uint256 private DAYS_90 = 90 * 24 * 60 * 60;
    uint256 private ONE_DAY = 24 * 60;
    IERC20 private SEED;

    IERC20 private LP_SEED;

    MinuteMitData[] public MIN_DATA;

    NetPowerChange[] private netChangeArray;

    //seed
    uint256[] private MINUTE_MIT = [
    74201, 68493, 62785, 58980, 55175, 51369, 31201, 31201, 31201, 31201, 31201, 31201, 31201, 31201, 31201, 31201, 31201, 31201, 31201, 31201];

    address private TEAM_ACCOUNT;

    struct MinuteMitData {
        uint256 amount;
        uint256 start;
        uint256 end;
    }

    struct NetPowerChange {
        uint256 personal;
        uint256 team;
        uint256 timestamp;
    }


    constructor() public {
        //正式用户数据
        //        userData = IPDUserData(address(0xC901C5D7635101C03852Bf389498D12ea5bfFdF8));
        //TFzq1rGxRkPMWHy4wW417LLuKdPHMAviAf
        userData = IPDUserData(address(0x41421f3bbc3cfb5a7d0a20bec6c1d826a8ec32d583));
        SEED = IERC20(address(0x41fabd4d928f706b2bca58a7cfafd2e70031ec2c30));
        LP_SEED = IERC20(address(0x41f19d864404bed21219293cbf6f84e1b06a3403df));

        //shasta测试网
//        userData = IPDUserData(address(0x41dc3dce804e99e76c848767b3c31207f9798d8e41));
//        SEED = IERC20(address(0x41b3a30bcbd7aaac9a7a68aa6ac23662e99125befa));
//        LP_SEED = IERC20(address(0x41b3b96476b9f0829766443021ed018d6f9930420c));
        TEAM_ACCOUNT = address(0x41dac6e3c155aab1e4d92ee0e97815876f122ce7f7);
        //初始化每分钟产量
        initMinuteMit();
    }

    //测试的时候才用  这个是为了在测试的时候回收币
    function testGetTRC20() public onlyOwner returns (bool){
        uint256 amount = SEED.balanceOf(address(this));
        if (amount > 0) {
            SEED.transfer(msg.sender, amount);
        }
        amount = LP_SEED.balanceOf(address(this));
        if (amount > 0) {
            LP_SEED.transfer(msg.sender, amount);
        }
        return true;
    }

    function updateTeamAccount(address addr) public onlyOwner returns (bool){
        TEAM_ACCOUNT = addr;
        return true;
    }

    function updateUserDataContract(address addr) public onlyOwner returns (bool){
        userData = IPDUserData(addr);
        return true;
    }

    function initMinuteMit() internal {

        uint256 YEAR = 360 * 24 * 60 * 60;
        uint256 times = now;
        for (uint256 i = 0; i < MINUTE_MIT.length; i++) {
            MinuteMitData memory conf;
            conf.amount = MINUTE_MIT[i];
            conf.start = times.add(i.mul(YEAR));
            conf.end = conf.start.add(YEAR);
            MIN_DATA.push(conf);
        }
        MinuteMitData memory conf;
        conf.amount = 0;
        uint256 index = MINUTE_MIT.length;
        conf.start = times.add(index.mul(YEAR));
        conf.end = 0xFFFFFFFFFFFFFFFF;
        MIN_DATA.push(conf);
    }

    function getCurrentMinuteMit() public view returns (uint256){
        uint256 n = now;
        for (uint256 i = 0; i < MIN_DATA.length; i++) {
            MinuteMitData memory conf = MIN_DATA[i];
            if (conf.start <= n && conf.end > now) {
                return conf.amount;
            }
        }
        return 0;
    }

    modifier canRun(){
        require((!pause) && !(frozenUserMap[msg.sender]));
        _;
    }

    function setPause(bool value) public onlyOwner returns (bool){
        pause = value;
        return true;
    }

    function frozenAddress(address user) public onlyOwner returns (bool){
        frozenUserMap[user] = true;
        return true;
    }

    function register(address inviter) public canRun returns (bool){
        return userData.register(msg.sender, inviter);
    }

    function isRegister(address user) public view returns (bool){
        return userData.getRegisterTime(user) > 0;
    }

    function pledge(uint8 pledgeType, uint256 amount) public canRun returns (bool){
        require(pledgeType != 0 && pledgeType <= uint8(2), "pledge type error");
        LP_SEED.transferFrom(msg.sender, address(this), amount);
        uint256 pledge30;
        uint256 pledge90;
        uint256 pledgeTime;
        (pledge30, pledge90, pledgeTime) = userData.getUserPledge(msg.sender);
        if (pledgeType == 1) {
            pledge30 = pledge30.add(amount);
        } else {
            pledge90 = pledge90.add(amount);
        }
        pledgeTime = now;
        userData.updateUserPledge(msg.sender, pledge30, pledge90, pledgeTime);
        _onTriggerPledge(msg.sender, pledge30.add(pledge90));
        return true;
    }

    function _onTriggerPledge(address user, uint256 totalPledge) internal {
        //团队结算
        address addr = user;
        while (true) {
            _settleUser(addr);
            address inviter = userData.getUserInviter(addr);
            if (inviter == addr || inviter == address(0x0)) {
                break;
            }
            addr = inviter;
        }
        uint256 personal;
        uint256 team;
        (personal, team) = userData.getUserPower(user);
        //个人算力变化
        uint256 newPower = totalPledge.div(1000000);
        userData.updateUserPower(user, newPower, team);
        uint256 preAdd = newPower.sub(personal);
        uint256 sum = preAdd;
        //团队算力变化
        address inviter = userData.getUserInviter(user);
        uint256 count = 0;
        if (inviter != address(0x0)) {
            while (true) {
                (personal, team) = userData.getUserPower(inviter);
                userData.updateUserPower(inviter, personal, team.add(sum));
                sum = sum.add(preAdd);
                count = count.add(1);
                address nInviter = userData.getUserInviter(inviter);
                if (nInviter == address(0x0) || nInviter == inviter) {
                    break;
                }
                inviter = nInviter;
            }
        }
        sum = preAdd.mul(count);
        uint256 netTeamPower;
        uint256 netComputerPower;
        (netComputerPower, netTeamPower) = userData.getNetPower();
        netTeamPower = netTeamPower.add(sum);
        netComputerPower = netComputerPower.add(preAdd);
        userData.updateNetPower(netComputerPower, netTeamPower);
        NetPowerChange memory ch;
        ch.personal = netComputerPower;
        ch.team = netTeamPower;
        ch.timestamp = now;
        netChangeArray.push(ch);
    }

    function getUserInviter(address user) public view returns (address){
        return userData.getUserInviter(user);
    }

    function _checkNeedSettle(address user) internal view returns (bool){
        uint256 temp30;
        uint256 temp90;
        uint256 timestamp;
        (temp30, temp90, timestamp) = userData.getUserPledge(user);
        uint256 sum = temp90.add(temp30);

        uint256 netTeamPower;
        uint256 netComputerPower;
        (netComputerPower, netTeamPower) = userData.getNetPower();
        if (sum < 1000000 || netTeamPower <= 0 || netComputerPower <= 0) {
            return false;
        }
        return true;
    }

    function _settleUser(address user) internal {
        //静态收益 + 动态收益
        if (!_checkNeedSettle(user)) {
            userData.updateUserLastSettleTime(user, now);
            return;
        }
        uint256 staticMit;
        uint256 dynMit;
        uint256 temp;
        (staticMit, dynMit, temp) = _calcUserMitData(user);
        uint256 _withdraw;
        uint256 lastWithdrawTime;
        uint256 temp2;
        (_withdraw, lastWithdrawTime, temp2, temp) = userData.getUserFinance(user);
        _withdraw = _withdraw.add(staticMit).add(dynMit);
        userData.updateFinance(user, _withdraw, lastWithdrawTime, 0, 0);
        userData.updateUserLastSettleTime(user, now);
        //        uint256 personal;
        //        uint256 team;
        //        (personal, team) = userData.getUserPower(user);
        //        uint256 times = userData.getUserLastSettleTime(user);
        //        uint256 minute = now.sub(times).div(60);
        //        if (minute <= 0) {
        //            userData.updateUserLastSettleTime(user, now);
        //            return;
        //        }
        //        uint256 _withdraw;
        //        uint256 lastWithdrawTime;
        //        uint256 temp2;
        //        uint256 temp;
        //        uint256 frozen;
        //        (_withdraw, lastWithdrawTime, frozen, temp) = userData.getUserFinance(user);
        //
        //        //计算动态收益
        //        uint256 teamPower;
        //
        //        (teamPower, temp) = _getUserLastMonthSettleData(user);
        //        //计算静态收益
        //        temp = personal.mul(minute).mul(300000);
        //        uint256 netComputerPower;
        //        (netComputerPower, temp2) = userData.getNetPower();
        //
        //        temp2 = temp.div(netComputerPower).div(1000000);
        //
        //        temp = teamPower.mul(11000).div(10000);
        //        if (team < temp) {
        //            //计算业绩是否足够
        //            temp = 7000;
        //        } else {
        //            temp = 10000;
        //        }
        //        temp = team.mul(temp).mul(minute).mul(700000);
        //        uint256 dynGet = temp.div(netComputerPower).div(10000).div(1000000);
        //        _withdraw = _withdraw.add(temp2).add(dynGet);
        //        userData.updateFinance(user, _withdraw, lastWithdrawTime, frozen, 0);
        //        userData.updateUserLastSettleTime(user, now);
    }

    function _getUserLastMonthSettleData(address user) internal view returns (uint256 power, uint256 sTime){
        (power, sTime) = userData.getUserLastMonthSettleData(user);
    }

    //提现
    function withdraw(uint256 amount) public returns (bool){
        _settleUser(msg.sender);
        uint256 _withdraw;
        uint256 lastWithdrawTime;
        uint256 frozen;
        uint256 pool;
        (_withdraw, lastWithdrawTime, frozen, pool) = userData.getUserFinance(msg.sender);
        _withdraw = _withdraw.sub(amount);
        SEED.transfer(msg.sender, amount);
        userData.updateFinance(msg.sender, _withdraw, now, frozen, pool);
        return true;
    }

    //赎回
    function getBack(uint256 amount) public returns (bool){
        uint256 pledge30;
        uint256 pledge90;
        uint256 pledgeTime;
        (pledge30, pledge90, pledgeTime) = userData.getUserPledge(msg.sender);
        require(pledge30.add(pledge90) >= amount, "amount error");
        uint256 get30 = pledge30;
        uint256 get90;
        if (pledge30 >= amount) {
            //赎回30天的
            get30 = amount;
            pledge30 = pledge30.sub(amount);
        }
        if (get30 < amount) {
            get90 = amount.sub(get30);
            pledge90 = pledge90.sub(get90);
        }
        uint256 sendAmount = 0;
        uint256 teamGain = 0;
        if (get30 > 0) {
            uint256 rate = 8500;
            if (now > pledgeTime.add(DAYS_30)) {
                rate = 9500;
            }
            sendAmount = get30.mul(rate).div(10000);
            teamGain = get30.sub(sendAmount);
        }

        if (get90 > 0) {
            uint256 rate = 8500;
            if (now > pledgeTime.add(DAYS_90)) {
                rate = 9500;
            }
            sendAmount = sendAmount.add(get90.mul(rate).div(10000));
            teamGain = teamGain.add(get90.sub(sendAmount));
        }
        if (sendAmount > 0) {
            LP_SEED.transfer(msg.sender, sendAmount);
        }
        if (teamGain > 0) {
            LP_SEED.transfer(TEAM_ACCOUNT, teamGain);
        }
        userData.updateUserPledge(msg.sender, pledge30, pledge90, pledgeTime);
        _onTriggerGetBack(msg.sender, pledge30.add(pledge90));
        return true;
    }

    function _onTriggerGetBack(address user, uint256 totalPledge) internal {
        //团队结算
        address addr = user;
        while (true) {
            _settleUser(addr);
            address inviter = userData.getUserInviter(addr);
            if (inviter == addr || inviter == address(0x0)) {
                break;
            }
        }
        uint256 personal;
        uint256 team;
        (personal, team) = userData.getUserPower(user);
        //个人算力变化
        uint256 newPower = totalPledge.div(1000000);
        userData.updateUserPower(user, newPower, team);
        uint256 preSub = personal.sub(newPower);
        uint256 sum = preSub;
        //团队算力变化
        address inviter = userData.getUserInviter(user);
        uint256 count = 0;
        if (inviter != address(0x0)) {
            while (true) {
                (personal, team) = userData.getUserPower(inviter);
                userData.updateUserPower(inviter, personal, team.sub(sum));
                sum = sum.add(preSub);
                count = count.add(1);
                address nInviter = userData.getUserInviter(inviter);
                if (nInviter == address(0x0) || nInviter == inviter) {
                    break;
                }
            }
        }
        uint256 netTeamPower;
        uint256 netComputerPower;
        (netComputerPower, netTeamPower) = userData.getNetPower();

        sum = preSub.mul(count);
        netTeamPower = netTeamPower.sub(sum);
        netComputerPower = netComputerPower.sub(preSub);
        userData.updateNetPower(netComputerPower, netTeamPower);
        NetPowerChange memory ch;
        ch.personal = netComputerPower;
        ch.team = netTeamPower;
        ch.timestamp = now;
        netChangeArray.push(ch);
    }

    //获取全网信息
    function getWholeNetComputerPower() public view returns (uint256 personal, uint256 team){
        (personal, team) = userData.getNetPower();
    }

    //获取个人信息
    function getUserInfo(address user) public view returns (uint256 personal, uint256 team, uint256 canWithdraw, uint256 pool, uint256 dayMit){
        (personal, team) = userData.getUserPower(user);
        uint256 temp1;
        (canWithdraw, temp1, dayMit, pool) = userData.getUserFinance(user);
        (temp1, pool, dayMit) = _calcUserMitData(user);
        canWithdraw = canWithdraw.add(temp1).add(pool);
        pool = 0;
    }

    function _calcUserMitData(address user) internal view returns (uint256 staticMit, uint256 dynMit, uint256 dayMit){
        uint256[] memory pledgeData = new uint[](3);
        uint256[] memory power = new uint256[](2);
        uint256[] memory netPower = new uint256[](2);
        (netPower[0], netPower[1]) = userData.getNetPower();
        if (netPower[0] <= 0 && netPower[1] <= 0) {
            staticMit = 0;
            dynMit = 0;
            dynMit = 0;
            return (0, 0, 0);
        }
        (pledgeData[0], pledgeData[1], pledgeData[2]) = userData.getUserPledge(user);
        if (pledgeData[0] <= 0 && pledgeData[1] <= 0) {
            staticMit = 0;
            dynMit = 0;
            dynMit = 0;
            return (0, 0, 0);
        }

        (power[0], power[1]) = userData.getUserPower(user);
        pledgeData[2] = userData.getUserLastSettleTime(user);
        uint256 minute = now.sub(pledgeData[2]);
        //多少分钟
        minute = minute.div(60);

        uint256 minuteMit = getCurrentMinuteMit();
        //静态占40% 30天占其中的30%
        uint256 staticWanPercent = power[0].mul(1000000).div(netPower[0]);
        uint256 percent30 = pledgeData[0].mul(1000000).div(pledgeData[0].add(pledgeData[1]));
        uint256 percent90 = uint256(1000000).sub(percent30);
        dayMit = staticWanPercent.mul(minuteMit).mul(40).mul(ONE_DAY).div(100);

        staticWanPercent = staticWanPercent.mul(minuteMit).mul(minute);
        percent30 = percent30.mul(staticWanPercent).mul(12).div(100).div(1000000).div(1000000);
        percent90 = percent90.mul(staticWanPercent).mul(28).div(100).div(1000000).div(1000000);
        staticMit = percent30.add(percent90);


        dynMit = 0;
        //动态占60% 30天占其中的30%
        if (netPower[1] > 0) {
            staticWanPercent = power[1].mul(1000000).div(netPower[1]);
            percent30 = staticWanPercent.mul(minuteMit).mul(ONE_DAY).mul(60).div(100);
            dayMit = dayMit.add(percent30);

            percent30 = pledgeData[1].mul(1000000).div(pledgeData[0].add(pledgeData[1]));
            percent90 = uint256(1000000).sub(percent30);
            staticWanPercent = staticWanPercent.mul(minuteMit).mul(minute);
            percent30 = percent30.mul(staticWanPercent).mul(18).div(100).div(1000000).div(1000000);
            percent90 = percent90.mul(staticWanPercent).mul(42).div(100).div(1000000).div(1000000);
            dynMit = percent30.add(percent90);
        }

        dayMit = dayMit.div(1000000).div(1000000);
    }


}


//SourceUnit: Ownable.sol

pragma solidity 0.5.17;
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


//SourceUnit: SafeMath.sol

pragma solidity 0.5.17;

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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}