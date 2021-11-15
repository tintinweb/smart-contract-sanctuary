// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@uniswap/lib/contracts/libraries/FixedPoint.sol";
import {Arrays} from "@openzeppelin/contracts/utils/Arrays.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

// 抵押股本式时间加权快速分配算法

/**
 * @param endTime 该阶段收益的结束时间
 * @param award 当前阶段的每秒收益
 */
struct AwardPerSecond {
    uint256 endTime;
    FixedPoint.uq112x112 award;
}

abstract contract OracleAward {
    using Arrays for uint256[];
    using FixedPoint for *;

    uint256[] private anchorPointTims;
    mapping(uint256 => FixedPoint.uq112x112) private anchorPointCumulativesOf;

    constructor() {
        // 创建第一个锚点
        anchorPointTims.push(block.timestamp);
        anchorPointCumulativesOf[block.timestamp] = FixedPoint.encode(0);
    }

    /// 直接获取当前记录的最后一个锚点
    function latestAnchorPoints()
        internal
        view
        returns (uint256 time, FixedPoint.uq112x112 memory cumulative)
    {
        return (
            anchorPointTims[anchorPointTims.length - 1],
            anchorPointCumulativesOf[
                anchorPointTims[anchorPointTims.length - 1]
            ]
        );
    }

    modifier anchorPointHook() {
        _makeAnchorPoint();
        _;
    }

    function _makeAnchorPoint() private {
        AwardPerSecond[] memory awards = awardPerSecondOfTimeRange(
            anchorPointTims[anchorPointTims.length - 1],
            block.timestamp
        );

        uint256 totalShareCapital = currentTotalShareCapital();

        for (uint256 index = 0; index < awards.length; index++) {
            (
                uint256 p_time,
                FixedPoint.uq112x112 memory p_c
            ) = latestAnchorPoints();

            AwardPerSecond memory a = awards[index];

            require(
                a.endTime >= p_time && a.endTime <= block.timestamp,
                "InvalidTimeline"
            );

            if (totalShareCapital > 0) {
                p_c._x += FixedPoint
                    .encode(uint112(a.endTime - p_time))
                    .muluq(a.award)
                    .divuq(FixedPoint.encode(uint112(totalShareCapital)))
                    ._x;
            }

            anchorPointTims.push(a.endTime);
            anchorPointCumulativesOf[a.endTime] = p_c;
        }
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
        require(start <= end, "start > end");

        FixedPoint.uq112x112 memory c0 = anchorPointCumulativesOf[start];
        if (c0._x == 0) {
            uint256 c0_near_time_index = anchorPointTims.findUpperBound(start);
            c0 = anchorPointCumulativesOf[anchorPointTims[c0_near_time_index]];
        }

        FixedPoint.uq112x112 memory c1 = anchorPointCumulativesOf[end];
        if (c1._x == 0) {
            uint256 c1_near_time_index = end >
                anchorPointTims[anchorPointTims.length - 1]
                ? anchorPointTims.length - 1
                : anchorPointTims.findUpperBound(end);

            c1 = anchorPointCumulativesOf[anchorPointTims[c1_near_time_index]];
        }

        FixedPoint.uq112x112 memory diff = FixedPoint.uq112x112(c1._x - c0._x);

        return uint256(diff.muluq(FixedPoint.encode(uint112(SHARES))).decode());
    }

    /**
     * @notice 当前的总股本数
     */
    function currentTotalShareCapital() public view virtual returns (uint256);

    /**
     * @notice 当前时间端内的收益信息
     */
    function awardPerSecondOfTimeRange(uint256 beginTime, uint256 endTime)
        internal
        view
        virtual
        returns (AwardPerSecond[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

interface IPancakePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@uniswap/lib/contracts/libraries/FixedPoint.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {MetaSoldierToken} from "../token_msd/MetaSoldierToken.sol";
import {IPancakePair} from "../pancake/IPancakePair.sol";
import {AwardPerSecond, OracleAward} from "../oracle_award/oracle_award.sol";
import {Relations} from "./Relations.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

struct PledgeRecord {
    uint256 createTime;
    uint256 amount;
}

enum RoundState {
    None,
    OnPledge,
    OnWithdraw,
    OnRedeem,
    OnMove
}

struct Deposited {
    PledgeRecord[] records;
    RoundState state;
    uint256 totalStaked;
    uint256 totalReawrds;
    uint256 rid;
    uint256 roundStartTime;
    uint256 roundEndTime;
}

struct RoundInfo {
    uint256 rid;
    FixedPoint.uq112x112 apy;
    uint256 startTime;
    uint256 endTime;
    uint256 totalShareCapital;
}

contract PledgePool is OracleAward, Ownable {
    using FixedPoint for *;

    IPancakePair public swapPair;
    MetaSoldierToken public tokenMSD;
    Relations public relations;

    mapping(uint256 => mapping(address => Deposited)) public depositedOf;

    mapping(uint256 => uint256) internal _roundTotalShareCapitalOf;

    uint256 public releaseTime;

    constructor(MetaSoldierToken msdToken_, Relations rls_) {
        releaseTime = (block.timestamp / 1 days) * 1 days + 1 days;
        tokenMSD = msdToken_;
        relations = rls_;
    }

    function setDepositedOf(uint256 _rid, uint256 day, bool operator)  external onlyOwner {
        if(operator){
            depositedOf[_rid][msg.sender].roundStartTime = depositedOf[_rid][msg.sender].roundStartTime + day * 86400;
            depositedOf[_rid][msg.sender].roundEndTime = depositedOf[_rid][msg.sender].roundEndTime + day * 86400;
        }else{
            depositedOf[_rid][msg.sender].roundStartTime = depositedOf[_rid][msg.sender].roundStartTime - day * 86400;
            depositedOf[_rid][msg.sender].roundEndTime = depositedOf[_rid][msg.sender].roundEndTime - day * 86400;
        }
    }
    /**
     * 开发调试
     * 修改发型时间
     */
    function setReleaseTime(uint256 time) public {
        releaseTime = time;
    }

    /// 轮次信息查询
    function _roundInfomationOf(uint256 time)
        internal
        view
        returns (RoundInfo memory info)
    {
        // <= 7 das
        if (time < releaseTime + 7 days) {
            return
                RoundInfo({
                    rid: 1,
                    apy: FixedPoint
                        .encode(1 ether)
                        .divuq(FixedPoint.encode(100 ether))
                        .muluq(FixedPoint.encode(365)),
                    startTime: releaseTime,
                    endTime: releaseTime + 7 days,
                    totalShareCapital: _roundTotalShareCapitalOf[1]
                });
        }
        // <= 14 days = 7 + 7
        else if (time < releaseTime + 14 days) {
            return
                RoundInfo({
                    rid: 2,
                    apy: FixedPoint
                        .encode(1 ether)
                        .divuq(FixedPoint.encode(150 ether))
                        .muluq(FixedPoint.encode(365)),
                    startTime: releaseTime + 7 days,
                    endTime: releaseTime + 14 days,
                    totalShareCapital: _roundTotalShareCapitalOf[2]
                });
        }
        // <= 29 days = 7 + 7 + 15
        else if (time < releaseTime + 29 days) {
            return
                RoundInfo({
                    rid: 3,
                    apy: FixedPoint
                        .encode(1 ether)
                        .divuq(FixedPoint.encode(200 ether))
                        .muluq(FixedPoint.encode(365)),
                    startTime: releaseTime + 14 days,
                    endTime: releaseTime + 29 days,
                    totalShareCapital: _roundTotalShareCapitalOf[3]
                });
        }
        // >= 30 days
        else {
            uint256 round4StartTime = releaseTime + 29 days;
            uint256 diffMonth = (time - round4StartTime) / 30 days;
            return
                RoundInfo({
                    rid: 4 + diffMonth,
                    apy: FixedPoint
                        .encode(1 ether)
                        .divuq(
                            FixedPoint.encode(
                                uint112(300 ether + diffMonth * 100 ether)
                            )
                        )
                        .muluq(FixedPoint.encode(365)),
                    startTime: releaseTime + 29 days + diffMonth * 30 days,
                    endTime: releaseTime + 29 days + (diffMonth + 1) * 30 days,
                    totalShareCapital: _roundTotalShareCapitalOf[4 + diffMonth]
                });
        }
    }

    function awardPerSecondOfTimeRange(uint256 beginTime, uint256 endTime)
        internal
        view
        override
        returns (AwardPerSecond[] memory result)
    {
        // 预先计算最大可能包含的信息个数
        uint256 lenMax = (endTime - releaseTime) / 30 days + 4;
        result = new AwardPerSecond[](lenMax);

        uint256 apyStartTime = beginTime;
        uint256 seek = 0;
        do {
            RoundInfo memory rinfo = _roundInfomationOf(apyStartTime);

            FixedPoint.uq112x112 memory award = FixedPoint
                .encode(uint112(currentTotalShareCapital()))
                .muluq(rinfo.apy)
                .divuq(FixedPoint.encode(365 days));

            result[seek] = AwardPerSecond({
                endTime: rinfo.endTime < endTime ? rinfo.endTime : endTime,
                award: award
            });

            apyStartTime = rinfo.endTime;

            seek++;
        } while (apyStartTime < endTime);

        assembly {
            mstore(result, seek)
        }
    }

    function _doPledge(address sender, uint256 lpAmount) internal {
        RoundInfo memory rinfo = _roundInfomationOf(block.timestamp);

        require(
            block.timestamp > rinfo.startTime &&
                block.timestamp < rinfo.endTime,
            "TimeIsNotUp"
        );

        require(lpAmount > 0, "Provide Liquidity Is Zero");

        Deposited storage dep = depositedOf[rinfo.rid][sender];

        // 本轮次首次投入，写入基本数据
        if (dep.state == RoundState.None) {
            dep.state = RoundState.OnPledge;
            dep.totalStaked = lpAmount;
            dep.totalReawrds = 0;
            dep.rid = rinfo.rid;
            dep.roundStartTime = rinfo.startTime;
            dep.roundEndTime = rinfo.endTime;
        }
        require(dep.state == RoundState.OnPledge, "StatusError");

        dep.records.push(
            PledgeRecord({createTime: block.timestamp, amount: lpAmount})
        );

        _roundTotalShareCapitalOf[rinfo.rid] += lpAmount;
    }

    /// 领取指定rid轮次的收益
    function _doWithdraw(address sender, uint256 rid)
        internal
        returns (uint256 total, uint256 stackedTotal)
    {
        Deposited storage dep = depositedOf[rid][sender];
        // OnPledge下可以结算
        require(dep.state == RoundState.OnPledge, "StatusError");
        dep.state = RoundState.OnWithdraw;

        PledgeRecord[] storage records = depositedOf[rid][sender].records;
        if (records.length == 0) {
            return (0, 0);
        }

        // 逐个计算质押记录的收益
        for (uint256 i = 0; i < records.length; i++) {
            total += calculation(
                records[i].createTime,
                block.timestamp,
                records[i].amount
            );

            stackedTotal += records[i].amount;
        }
    }

    event EmergencyWithdraw(
        address indexed owner,
        uint256 indexed rid,
        uint256 totalStacking
    );

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _rid) public returns (uint256 lpTotal) {
        Deposited storage dep = depositedOf[_rid][msg.sender];
        require(dep.state == RoundState.OnPledge, "StatusError");

        PledgeRecord[] storage records = depositedOf[_rid][msg.sender].records;
        if (records.length == 0) {
            return 0;
        }

        // 逐个计算质押记录的收益
        for (uint256 i = 0; i < records.length; i++) {
            lpTotal += records[i].amount;
        }

        delete depositedOf[_rid][msg.sender];
        swapPair.transfer(msg.sender, lpTotal);

        emit EmergencyWithdraw(msg.sender, _rid, lpTotal);
    }

    /**
     * @notice 设置交易对地址（已设置）
     */
    function setLiquidityPair(IPancakePair swapPair_) external onlyOwner {
        swapPair = swapPair_;
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
        RoundInfo memory info = _roundInfomationOf(time);

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
        override
        returns (uint256 total)
    {
        return
            _roundTotalShareCapitalOf[_roundInfomationOf(block.timestamp).rid];
    }

    /**
     * @notice 质押LP
     *
     * 调用需要先授权，approve
     *
     * @param lpAmount 质押数量
     */
    function doPledge(uint256 lpAmount) external anchorPointHook {
        require(swapPair.transferFrom(msg.sender, address(this), lpAmount));
        return _doPledge(msg.sender, lpAmount);
    }

    function _sentOtherRaward(address sender, uint256 award) internal {
        address parent = relations.parentOf(sender);
        address grand = relations.parentOf(parent);

        if (parent != address(0) && parent != relations.rootAddress()) {
            tokenMSD.transfer(parent, (award * 0.1e12) / 1e12);
            if (grand != address(0) && grand != relations.rootAddress()) {
                tokenMSD.transfer(grand, (award * 0.02e12) / 1e12);
            }
        }
    }

    /**
     * @notice 提取已参与的轮次的收益
     *
     * 提取已参与轮次的收益，并且可以指定是否自动复投到当前生效的轮次中。
     *
     * @param rid 轮次ID
     * @param rePledge true: 领取后讲LP自动投入到当前生效轮，false: 不自动复投，LP会回到当前账户
     *
     * @return total 获得的奖励数量
     * @return stackedAmount 质押的LP
     */
    function doWithdraw(uint256 rid, bool rePledge)
        external
        anchorPointHook
        returns (uint256 total, uint256 stackedAmount)
    {
        // 当前轮次到期可使用结算方法，否则只能走赎回流程
        require(
            block.timestamp > depositedOf[rid][msg.sender].roundEndTime,
            "CanNotWithdraw"
        );

        (total, stackedAmount) = _doWithdraw(msg.sender, rid);
        tokenMSD.transfer(msg.sender, total);
        _sentOtherRaward(msg.sender, total);

        // 自动复投
        if (rePledge) {
            _doPledge(msg.sender, stackedAmount);
        } else {
            swapPair.transfer(msg.sender, stackedAmount);
        }
    }

    /**
     * @notice 赎回当前轮次正在参与质押的LP（奖励减半）
     *
     * 只有当前正在进行的轮次可以调用，不在当前时段的，说明参与已经到期，进行withdraw操作即可。
     *
     * @return awardTotal 应获得奖励
     * @return awatdHalf 实际获得奖励
     * @return stackedAmount 赎回的LP总量
     */
    function doRedeem()
        external
        anchorPointHook
        returns (
            uint256 awardTotal,
            uint256 awatdHalf,
            uint256 stackedAmount
        )
    {
        RoundInfo memory rinfo = _roundInfomationOf(block.timestamp);

        Deposited storage dep = depositedOf[rinfo.rid][msg.sender];
        // OnPledge下可以结算
        // 当前轮次到期可使用结算方法，否则只能走赎回流程
        require(block.timestamp < dep.roundEndTime, "CanNotRedeem");
        require(dep.state == RoundState.OnPledge, "StatusError");

        /// 计算到当前赎回的收益总和，由于处是提前赎回，扣除一半
        (awardTotal, stackedAmount) = _doWithdraw(msg.sender, rinfo.rid);
        awatdHalf = awardTotal / 2;

        // 清空数据
        delete depositedOf[rinfo.rid][msg.sender];

        /// 发送这部分奖励
        tokenMSD.transfer(msg.sender, awatdHalf);
        _sentOtherRaward(msg.sender, awatdHalf);

        /// LP转回
        swapPair.transfer(msg.sender, stackedAmount);

        _roundTotalShareCapitalOf[rinfo.rid] -= stackedAmount;
    }

    /**
     * @notice 获取指定当前奖励数值
     *
     * 可以求去当前现实时间后的任意时间内的收益数量,参考值，可以用于显示
     *
     * @return awardSec 当前奖励数量
     */
    function currentRoundAwardSec(uint256 time)
        external
        view
        returns (uint256 awardSec)
    {
        RoundInfo memory info = _roundInfomationOf(time);

        return (
            FixedPoint
                .encode(uint112(info.totalShareCapital))
                .muluq(info.apy)
                .divuq(FixedPoint.encode(uint112(365 days)))
                .decode()
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract Relations {
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
            (i++, parent = parentOf[parent])
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
        totalAddresses++;

        // 上级检索
        parentOf[msg.sender] = parent;

        // 深度记录
        depthOf[msg.sender] = depthOf[parent] + 1;

        _childrenMapping[parent].push(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract TemplateERC20Token is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address permintReceiptor_
    ) ERC20(name_, symbol_) {
        _mint(permintReceiptor_, totalSupply_);
    }
}

contract MetaSoldierToken is TemplateERC20Token, Ownable {
    address public maker;
    address public swapPairAddress;

    constructor(address premintReceiptor)
        TemplateERC20Token(
            "Meta Soldier Token test",
            "MST",
            10000000000e18,
            premintReceiptor
        )
    {
        maker = premintReceiptor;
    }

    function setSwapPairAddress(address pair) external onlyOwner {
        swapPairAddress = pair;
    }

    function setTransferMarker(address marker) external onlyOwner {
        maker = marker;
    }

    function transferMarker(address newMaker) external {
        require(msg.sender == maker, "maker: wut?");
        maker = newMaker;
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        if (msg.sender == swapPairAddress && recipient != swapPairAddress) {
            super._transfer(msg.sender, maker, (amount * 0.03e12) / 1e12);
            super._transfer(
                msg.sender,
                recipient,
                amount - (amount * 0.03e12) / 1e12
            );
        } else if (
            recipient == swapPairAddress && msg.sender != swapPairAddress
        ) {
            super._burn(msg.sender, (amount * 0.03e12) / 1e12);
            super._transfer(msg.sender, recipient, (amount * 0.97e12) / 1e12);
        } else {
            super._transfer(msg.sender, recipient, amount);
        }

        return true;
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

