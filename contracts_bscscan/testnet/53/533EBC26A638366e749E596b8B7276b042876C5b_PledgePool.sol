// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@uniswap/lib/contracts/libraries/FixedPoint.sol";
import "@uniswap/lib/contracts/libraries/FullMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "@uniswap/lib/contracts/libraries/BitMath.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
// import "@openzeppelin/contracts/utils/math/Math.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Relations} from "./Relations.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import '../utils/SafeMath.sol';
import '../utils/TransferHelper.sol';

    struct PledgeRecord {
        uint256 createTime;
        uint256 amount;
    }

    enum RoundState {
        None,
        OnPledge,
        OnWithdraw,
        OnRedeem
    }

    struct Deposited {
        PledgeRecord[] records;
        RoundState state;
        uint256 totalStaked;
        uint256 totalReward;
        uint256 rid;
        uint256 roundStartTime;
        uint256 roundEndTime;
        FixedPoint.uq112x112 secondApy;
    }

    struct RoundInfo {
        uint256 rid;
        FixedPoint.uq112x112 apy;
        uint256 startTime;
        uint256 endTime;
        uint256 totalShareCapital;
    }

    struct AwardPerSecond {
        uint256 endTime;
        FixedPoint.uq112x112 award;
    }


contract PledgePool is Ownable {
    using FixedPoint for *;
    using SafeMath for uint256;


    /**
     * 
     * 
     ***/
    address public stackToken;
    address public rewardToken;


    Relations public relations;

    mapping(uint256 => mapping(address => Deposited)) public depositedOf;

    mapping(uint256 => uint256) internal _roundTotalShareCapitalOf;

    mapping(uint256 => uint256) internal _roundTotalRewardOf;


    uint256 public _remainingReward;

    uint256 public releaseTime;

    // 
    bool checkCanPledgeFlag = false;
    uint256 public minRemainingReward = 0;

    // reward = (stack * ratioOfStackAndRewardMul)/ratioOfStackAndRewardDiv
    uint256 public ratioOfStackAndRewardMul = 1;
    uint256 public ratioOfStackAndRewardDiv = 1;

    event RatioChange(uint256 RatioOfStackAndRewardMul, uint256 RatioOfStackAndRewardDiv);


    constructor(address _stackToken, address _rewardToken, Relations rls_) {
        // releaseTime = (block.timestamp / 1 days) * 1 days + 1 days;
        releaseTime = block.timestamp.div(1 days).mul(1 days).add(1 days);
        relations = rls_;
        stackToken = _stackToken;
        rewardToken = _rewardToken;
    }

    // add reward
    function addRemainingReward(uint256 _rewardBalance) public {
        TransferHelper.safeTransferFrom(rewardToken, msg.sender, address(this), _rewardBalance);
        _remainingReward = _remainingReward.add(_rewardBalance);
    }

    function setMinRemainingReward(uint256 _minBalance) external onlyOwner {
        minRemainingReward = _minBalance;
    }

    modifier checkCanPledge(){

        if (checkCanPledgeFlag) {
            require(_remainingReward > minRemainingReward, "_RemainingReward not enough");
            _;
        } else {
            _;
        }
    }

    function setCheckCanPledgeFlag(bool flag) public onlyOwner {
        checkCanPledgeFlag = flag;
    }


    /// 轮次信息查询
    function _roundInformationOf(uint256 time)
    internal
    view
    returns (RoundInfo memory info)
    {
        // <= 7 das
        // if (time < releaseTime + 7 days) {
        if (time < releaseTime.add(7 days)) {
            return
            RoundInfo({
            rid : 1,
            apy : FixedPoint
            .encode(1 ether)
            .divuq(FixedPoint.encode(100 ether))
            .muluq(FixedPoint.encode(365)),
            startTime : releaseTime,
            endTime : releaseTime.add(7 days),
            totalShareCapital : _roundTotalShareCapitalOf[1]
            });
        }
        // <= 14 days = 7 + 7
        // else if (time < releaseTime + 14 days) {
        else if (time < releaseTime.add(14 days)) {
            return
            RoundInfo({
            rid : 2,
            apy : FixedPoint
            .encode(1 ether)
            .divuq(FixedPoint.encode(150 ether))
            .muluq(FixedPoint.encode(365)),

            // startTime: releaseTime + 7 days,
            startTime : releaseTime.add(7 days),
            // endTime: releaseTime + 14 days,
            endTime : releaseTime.add(14 days),
            totalShareCapital : _roundTotalShareCapitalOf[2]

            });
        }
        // <= 29 days = 7 + 7 + 15
        // else if (time < releaseTime + 29 days) {
        else if (time < releaseTime.add(29 days)) {
            return
            RoundInfo({
            rid : 3,
            apy : FixedPoint
            .encode(1 ether)
            .divuq(FixedPoint.encode(200 ether))
            .muluq(FixedPoint.encode(365)),

            // startTime: releaseTime + 14 days,
            startTime : releaseTime.add(14 days),
            // endTime: releaseTime + 29 days,
            endTime : releaseTime.add(29 days),
            totalShareCapital : _roundTotalShareCapitalOf[3]
            });
        }
        // >= 30 days
        else {
            // uint256 round4StartTime = releaseTime + 29 days;
            uint256 round4StartTime = releaseTime.add(29 days);
            // uint256 diffMonth = (time - round4StartTime) / 30 days;
            uint256 diffMonth = time.sub(round4StartTime).div(30 days);
            return
            RoundInfo({
            // rid: 4 + diffMonth,
            rid : diffMonth.add(4),
            apy : FixedPoint
            .encode(1 ether)
            .divuq(
                FixedPoint.encode(
                // uint112(300 ether + diffMonth * 100 ether)
                    uint112(diffMonth.mul(100 ether).add(300 ether))
                )
            )
            .muluq(FixedPoint.encode(365)),
            // startTime: releaseTime + 29 days + diffMonth * 30 days,
            // endTime: releaseTime + 29 days + (diffMonth + 1) * 30 days,
            // totalShareCapital: _roundTotalShareCapitalOf[4 + diffMonth]

            // startTime: releaseTime.add(29 days).add(diffMonth).mul(30 days),
            // endTime: releaseTime.add(29 days).add(diffMonth.add(1).mul(30 days)),
            // totalShareCapital: _roundTotalShareCapitalOf[diffMonth.add(4)]

            //fix
            startTime : releaseTime.add(29 days).add((diffMonth).mul(30 days)),
            endTime : releaseTime.add(29 days).add(diffMonth.add(1).mul(30 days)),
            totalShareCapital : _roundTotalShareCapitalOf[diffMonth.add(4)]
            });
        }
    }


    function _doPledge(address sender, uint256 lpAmount) checkCanPledge internal {
        RoundInfo memory rinfo = _roundInformationOf(block.timestamp);

        require(
            block.timestamp > rinfo.startTime &&
            block.timestamp < rinfo.endTime,
            "TimeIsNotUp"
        );

        require(lpAmount > 0, "Provide Liquidity Is Zero");

        Deposited storage dep = depositedOf[rinfo.rid][sender];

        // 本轮次首次投入，写入基本数据
        if (dep.state == RoundState.None) {
            dep.totalReward = 0;
            dep.state = RoundState.OnPledge;
            dep.rid = rinfo.rid;
            dep.secondApy = rinfo.apy.divuq(FixedPoint.encode(uint112(365 days)));
            dep.roundStartTime = rinfo.startTime;
            dep.roundEndTime = rinfo.endTime;
        }
        require(dep.state == RoundState.OnPledge || dep.state == RoundState.OnRedeem, "StatusError");
        dep.state = RoundState.OnPledge;

        dep.totalStaked = dep.totalStaked.add(lpAmount);
        dep.records.push(
            PledgeRecord({createTime : block.timestamp, amount : lpAmount})
        );
        //fix

        // _roundTotalShareCapitalOf[rinfo.rid] += lpAmount;
        _roundTotalShareCapitalOf[rinfo.rid] = _roundTotalShareCapitalOf[rinfo.rid].add(lpAmount);
    }


    /// 领取指定rid轮次的收益
    function _doWithdraw(address sender, uint256 rid)
    internal
    view
    returns (uint256 total, uint256 stackTotal)
    {
        Deposited storage dep = depositedOf[rid][sender];
        // OnPledge下可以结算
        require(dep.state == RoundState.OnPledge, "StatusError");

        PledgeRecord[] storage records = depositedOf[rid][sender].records;
        if (records.length == 0) {
            return (0, 0);
        }

        for (uint256 i = 0; i < records.length; i = i.add(1)) {
            uint256 endTime = block.timestamp > dep.roundEndTime ? dep.roundEndTime : block.timestamp;
            total = total.add(_calculation(
                    records[i].createTime,
                    endTime,
                    FixedPoint.encode(uint112(records[i].amount)).muluq(dep.secondApy).decode()
                ));
            stackTotal = stackTotal.add(records[i].amount);
        }
        total = stackToReward(total);
    }

    event EmergencyWithdraw(
        address indexed owner,
        uint256 indexed rid,
        uint256 totalStacking
    );

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _rid) public returns (uint256 totalStacking) {
        Deposited storage dep = depositedOf[_rid][msg.sender];
        require(dep.state == RoundState.OnPledge, "StatusError");

        PledgeRecord[] storage records = depositedOf[_rid][msg.sender].records;
        if (records.length == 0) {
            return 0;
        }

        for (uint256 i = 0; i < records.length; i = i.add(1)) {
            totalStacking = totalStacking.add(records[i].amount);
        }

        delete depositedOf[_rid][msg.sender];
        TransferHelper.safeTransfer(address(stackToken), msg.sender, totalStacking);

        //fix
        _roundTotalShareCapitalOf[_rid] = _roundTotalShareCapitalOf[_rid].sub(totalStacking);
        emit EmergencyWithdraw(msg.sender, _rid, totalStacking);
    }

    /**
     * @notice set StackToken address
     */
    function setStackAddress(address _address) external onlyOwner {
        stackToken = _address;
    }

    /**
     * @notice set Reward token Address    
     */
    function setRewardAddress(address _address) external onlyOwner {
        require(rewardToken != _address, "address not the  same");
        rewardToken = _address;
        _remainingReward = 0;
    }


    /**
     * @notice 根据参考时间获取轮次信息
     *
     * @param time 时间
     *
     * @return rid 轮次下标
     * @return apy 年利率参考值
     * @return startTime 当轮到开始时间
     * @return endTime 当轮到结束时间
     * @return totalShareCapital 当前轮次已投入的生效的LP总量
     */
    function roundInfomationOf(uint256 time)
    external
    view
    returns (
        uint256 rid,
        uint256 apy,
        uint256 startTime,
        uint256 endTime,
        uint256 totalShareCapital
    )
    {
        RoundInfo memory info = _roundInformationOf(time);

        return (
        info.rid,
        info.apy.muluq(FixedPoint.encode(10000)).decode(),
        info.startTime,
        info.endTime,
        info.totalShareCapital
        );
    }

    /**
     * @notice 当前已生效的LP总量（即时时间）
     *
     * @return total 生效的总量
     */
    function currentTotalShareCapital()
    public
    view
    returns (uint256 total)
    {
        return
        _roundTotalShareCapitalOf[_roundInformationOf(block.timestamp).rid];
    }

    /**
     * @notice 质押LP
     *
     * 调用需要先授权，approve
     *
     * @param stackAmount 质押数量
     */
    function doPledge(uint256 stackAmount) external {
        // require(swapPair.transferFrom(msg.sender, address(this), lpAmount));
        _doPledge(msg.sender, stackAmount);
        TransferHelper.safeTransferFrom(address(stackToken), msg.sender, address(this), stackAmount);

    }

    function _sendOtherReward(address sender, uint256 award) internal returns (uint256 otherReward){
        address parent = relations.parentOf(sender);
        address grand = relations.parentOf(parent);

        if (parent != address(0) && parent != relations.rootAddress()) {
            // check rewardToken enough

            transferRewardToken(parent, award.mul(0.1e12).div(1e12));
            otherReward = otherReward.add(award.mul(0.1e12).div(1e12));
            if (grand != address(0) && grand != relations.rootAddress()) {
                // tokenMSD.transfer(grand, (award * 0.02e12) / 1e12);
                transferRewardToken(grand, award.mul(0.02e12).div(1e12));
                otherReward = otherReward.add(award.mul(0.02e12).div(1e12));
            }
        }
    }

    function transferRewardToken(address send, uint256 award) internal {
        require(_remainingReward > award, "remaining token not enough ,please call pm or use emergencyWithdraw!!");
        _remainingReward.sub(award);
        TransferHelper.safeTransfer((rewardToken), send, award);
    }
    /**
     * @notice Extract the benefits of the rounds that have been participated in
     *
     * Extract the income of the participating rounds, and you can specify 
     * whether to automatically reinvest it in the current effective rounds.
     *
     * @param rid Rounds ID 
     * @param rePledge true: After receiving, the LP will be automatically put into the current effective round，
     * false: Without automatic re investment, 
     * LP will return to the current account
     *
     * @return total Number of awards received
     * @return stackedAmount Pledged LP
     */
    function doWithdraw(uint256 rid, bool rePledge)
    external
    returns (uint256 total, uint256 stackedAmount)
    {
        // The settlement method can be used when the
        // current round expires, otherwise the redemption process can only be followed


        require(
            block.timestamp > depositedOf[rid][msg.sender].roundEndTime,
            "CanNotWithdraw"
        );

        (total, stackedAmount) = _doWithdraw(msg.sender, rid);
        transferRewardToken(msg.sender, total);
        depositedOf[rid][msg.sender].state = RoundState.OnWithdraw;
        uint256 otherReward = _sendOtherReward(msg.sender, total);
        _roundTotalRewardOf[rid] = _roundTotalRewardOf[rid].add(total).add(otherReward);
        depositedOf[rid][msg.sender].totalReward = depositedOf[rid][msg.sender].totalReward.add(total);
        depositedOf[rid][msg.sender].totalStaked = depositedOf[rid][msg.sender].totalStaked.sub(stackedAmount);
        _roundTotalShareCapitalOf[rid] = _roundTotalShareCapitalOf[rid].sub(stackedAmount);

        // Automatic re switching
        if (rePledge) {
            _doPledge(msg.sender, stackedAmount);
        } else {

            TransferHelper.safeTransfer(stackToken, msg.sender, stackedAmount);

        }
    }

    /**
     * @notice Redemption of LP participating in pledge in current round (reward halved)
     *
     * Only the current round can be called. If it is not in the current period, it means that the participation has expired and the withdraw operation can be carried out.
     *
     * @return awardTotal Should be rewarded
     * @return awardHalf Actual reward
     * @return stackedAmount Total LP redeemed
     */
    function doRedeem()
    external
    returns (
        uint256 awardTotal,
        uint256 awardHalf,
        uint256 stackedAmount
    )
    {
        RoundInfo memory rinfo = _roundInformationOf(block.timestamp);

        Deposited storage dep = depositedOf[rinfo.rid][msg.sender];
        // OnPledge下可以结算
        // 当前轮次到期可使用结算方法，否则只能走赎回流程
        require(block.timestamp < dep.roundEndTime, "CanNotRedeem");
        require(dep.state == RoundState.OnPledge, "StatusError");

        /// 计算到当前赎回的收益总和，由于处是提前赎回，扣除一半
        (awardTotal, stackedAmount) = _doWithdraw(msg.sender, rinfo.rid);
        // awatdHalf = awardTotal / 2;
        awardHalf = awardTotal.div(2);
        transferRewardToken(msg.sender, awardHalf);
        dep.state = RoundState.OnRedeem;

        uint256 otherReward = _sendOtherReward(msg.sender, awardHalf);
        _roundTotalRewardOf[rinfo.rid] = _roundTotalRewardOf[rinfo.rid].add(awardHalf).add(otherReward);

        /// LP转回
        TransferHelper.safeTransfer(address(stackToken), msg.sender, stackedAmount);

        _roundTotalShareCapitalOf[rinfo.rid] = _roundTotalShareCapitalOf[rinfo.rid].sub(stackedAmount);
        // 清空数据
        delete depositedOf[rinfo.rid][msg.sender].records;
        depositedOf[rinfo.rid][msg.sender].totalStaked = depositedOf[rinfo.rid][msg.sender].totalStaked.sub(stackedAmount);
        depositedOf[rinfo.rid][msg.sender].totalReward = depositedOf[rinfo.rid][msg.sender].totalReward.add(awardHalf);

    }

    /**
     * @notice 当前轮次下 全网的每秒收益
     *
     * 可以求去当前现实时间后的任意时间内的收益数量,参考值，可以用于显示
     *
     * @return awardSec 当前全网每秒奖励数量
     */
    function currentRoundAwardSec(uint256 time)
    external
    view
    returns (uint256 awardSec)
    {
        RoundInfo memory info = _roundInformationOf(time);

        return (
        FixedPoint
        .encode(uint112(info.totalShareCapital))
        .muluq(info.apy)
        .divuq(FixedPoint.encode(uint112(365 days)))
        .decode()
        );
    }


    function stackToReward(uint256 _stackTokenBalance) public view returns (uint256){
        return _stackTokenBalance.mul(ratioOfStackAndRewardMul).div(ratioOfStackAndRewardDiv);
    }

    function setRatioOfStackAndReward(uint256 _mul, uint256 _div) external onlyOwner {
        ratioOfStackAndRewardMul = _mul;
        ratioOfStackAndRewardDiv = _div;
        emit RatioChange(ratioOfStackAndRewardMul, ratioOfStackAndRewardDiv);
    }

    function _calculation(
        uint256 start,
        uint256 end,
        uint256 SHARES
    ) internal pure returns (uint256) {
        require(start <= end, "start > end");
        return end.sub(start).mul(SHARES);

    }


    /**
     * @notice 计算股权份额持续时间内的收益总量
     *
     * @dev 根据锚点计算在指定的时间段内，所持有的SHARES（份额数量），可获取的秒收益总量
     *
     * @param start 开始时间 $timestamp
     * @param end 结束时间 $timestamp
     * @param SHARES 份额，此份额的单位是awardPerSecondOfTimeRange中定义的
     *
     * @return 收益总量
     */
    function calculation(
        uint256 start,
        uint256 end,
        uint256 SHARES
    ) public view returns (uint256) {
        require(start >= releaseTime, "start < releaseTime");
        require(start <= end, "start > end");
        AwardPerSecond[] memory awards = awardPerSecondOfTimeRange(start, end);
        uint256 rewardTotal = 0;

        for (uint256 index = 0; index < awards.length; index = index.add(1)) {
            end = awards[index].endTime;
            rewardTotal = rewardTotal.add(FixedPoint.
            encode(uint112(end.sub(start))).
            muluq(awards[index].award).
            muluq(FixedPoint.encode(uint112(SHARES))).
            decode());
            start = end;
        }
        return stackToReward(rewardTotal);
    }


    function awardPerSecondOfTimeRange(uint256 beginTime, uint256 endTime)
    public
    view
    returns (AwardPerSecond[] memory result)
    {
        // 预先计算最大可能包含的信息个数
        // uint256 lenMax = (endTime - releaseTime) / 30 days + 4;
        uint256 lenMax = endTime.sub(releaseTime).div(30 days).add(4);
        result = new AwardPerSecond[](lenMax);

        uint256 apyStartTime = beginTime;
        uint256 seek = 0;
        do {
            RoundInfo memory rinfo = _roundInformationOf(apyStartTime);

            FixedPoint.uq112x112 memory award = (rinfo.apy).divuq(FixedPoint.encode(365 days));

            result[seek] = AwardPerSecond({
            endTime : rinfo.endTime < endTime ? rinfo.endTime : endTime,
            award : award
            });

            apyStartTime = rinfo.endTime;

            // seek++;
            seek = seek.add(1);
        }
        while (apyStartTime < endTime);

        assembly {
            mstore(result, seek)
        }
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import '../utils/SafeMath.sol';

contract Relations {
    using SafeMath for uint256;

    // 根地址
    address public rootAddress;

    // 地址总数
    uint256 public totalAddresses;

    // 上级检索
    mapping(address => address) public parentOf;

    // 深度记录
    mapping(address => uint256) public depthOf;

    // 下级检索-直推
    mapping(address => address[]) internal _childrenMapping;

    constructor() {
        rootAddress = address(0xdead);
        parentOf[rootAddress] = address(0xdeaddead);
    }

    // 获取指定地址的祖先结点链
    function getForefathers(address owner, uint256 depth)
        external
        view
        returns (address[] memory)
    {
        address[] memory forefathers = new address[](depth);

        for (
            (address parent, uint256 i) = (parentOf[owner], 0);
            i < depth && parent != address(0) && parent != rootAddress;
            (i = i.add(1), parent = parentOf[parent])
        ) {
            forefathers[i] = parent;
        }

        return forefathers;
    }

    // 获取推荐列表
    function childrenOf(address owner)
        external
        view
        returns (address[] memory)
    {
        return _childrenMapping[owner];
    }

    // 绑定推荐人并且生产自己短码同时设置昵称
    function makeRelation(address parent) external {
        require(parentOf[msg.sender] == address(0), "AlreadyBinded");
        require(parent != msg.sender, "CannotBindYourSelf");
        require(parentOf[parent] != address(0x0), "ParentNoRelation");

        // 累加数量
        totalAddresses = totalAddresses.add(1);

        // 上级检索
        parentOf[msg.sender] = parent;

        // 深度记录
        depthOf[msg.sender] = depthOf[parent].add(1);

        _childrenMapping[parent].push(msg.sender);
    }
}

// SPDX-License-Identifier: CC-BY-4.0
pragma solidity >=0.4.0;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, 'FullMath: FULLDIV_OVERFLOW');
        return fullDiv(l, h, d);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.4.0;

import './FullMath.sol';
import './Babylonian.sol';
import './BitMath.sol';

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 public constant RESOLUTION = 112;
    uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000; // 2**224
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, 'FixedPoint::mul: overflow');
        return uq144x112(z);
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(uq112x112 memory self, int256 y) internal pure returns (int256) {
        uint256 z = FullMath.mulDiv(self._x, uint256(y < 0 ? -y : y), Q112);
        require(z < 2**255, 'FixedPoint::muli: overflow');
        return y < 0 ? -int256(z) : int256(z);
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        if (self._x == 0 || other._x == 0) {
            return uq112x112(0);
        }
        uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
        uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
        uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
        uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

        // partial products
        uint224 upper = uint224(upper_self) * upper_other; // * 2^0
        uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
        uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
        uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

        // so the bit shift does not overflow
        require(upper <= uint112(-1), 'FixedPoint::muluq: upper overflow');

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) + uppers_lowero + uppero_lowers + (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= uint224(-1), 'FixedPoint::muluq: sum overflow');

        return uq112x112(uint224(sum));
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        require(other._x > 0, 'FixedPoint::divuq: division by zero');
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= uint144(-1)) {
            uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
            require(value <= uint224(-1), 'FixedPoint::divuq: overflow');
            return uq112x112(uint224(value));
        }

        uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= uint224(-1), 'FixedPoint::divuq: overflow');
        return uq112x112(uint224(result));
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // can be lossy
    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint::reciprocal: reciprocal of zero');
        require(self._x != 1, 'FixedPoint::reciprocal: overflow');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        if (self._x <= uint144(-1)) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

library BitMath {
    // returns the 0 indexed position of the most significant bit of the input x
    // s.t. x >= 2**msb and x < 2**(msb+1)
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::mostSignificantBit: zero');

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    // returns the 0 indexed position of the least significant bit of the input x
    // s.t. (x & 2**lsb) != 0 and (x & (2**(lsb) - 1)) == 0)
    // i.e. the bit at the index is set and the mask of all lower bits is 0
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::leastSignificantBit: zero');

        r = 255;
        if (x & uint128(-1) > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & uint64(-1) > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & uint32(-1) > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & uint16(-1) > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & uint8(-1) > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

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
}