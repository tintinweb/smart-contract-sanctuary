//SourceUnit: Address.sol

pragma solidity 0.5.8;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        // 空字符串hash值
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        //内联编译（inline assembly）语言，是用一种非常底层的方式来访问EVM
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


//SourceUnit: LiquidityStake.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./SafeERC20.sol";

contract Moho {
    function getInviteAddress(address account) public view returns (address);

    function userMohoPledgedCountOf(address mohoPledgeAddress) public view returns (uint256);

    function getFirstLuckDrawAddress() public view returns (address);
}

contract LiquidityStake is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // set decimal six trc20
    uint256 private decimals = 6;
    // this year stake info
    uint256 private yearStakeNo1 = 4000000 * 10 ** decimals;
    uint256 private yearStakeNo2 = 3500000 * 10 ** decimals;
    uint256 private yearStakeNo3 = 3000000 * 10 ** decimals;
    uint256 private yearStakeNo4 = 2500000 * 10 ** decimals;
    uint256 private yearStakeNo5 = 2000000 * 10 ** decimals;
    //    uint256 private top10NewTodayTime = 1627574400;
    // Return 0 Successfully
    uint256 private resultData;

    mapping(address => address) public inviteAddress;
    bool public liquidityStakeSwitchState = false;
    uint256 public liquidityStakeStartTime;
    uint256 public joinStakeCount;
    uint256 public totalHashrate;
    uint256 public totalJoinStakeLP;
    mapping(address => uint256) public joinStakeLP;
    mapping(address => bool) public isJoinStake;
    mapping(address => uint256) public nowHashrate;
    mapping(address => uint256) public yesterday;
    mapping(address => DynamicTime) public dynamicTimes;

    mapping(address => uint256) public accountStakeCount;
    mapping(address => mapping(uint256 => AccountStakeOrder)) public accountStakeOrders;

    struct DynamicTime {
        uint256 topNewToday;
        uint256 newTodayTime;
    }


    struct AccountStakeOrder {
        uint256 index;
        bool isExist;
        uint256 joinStakeTime;
        uint256 exitStakeTime;
        uint256 amount;
    }

    // Related address information
    ERC20 public lpTokenContract;//justswap rea-trx-lp
    ERC20 public reaTokenContract;
    Moho public mohoContract;

    // The weights of top 10 are (first place) 25%, (second place) 20%, (third place) 15%, (fourth place) 10%. The remaining average.
    mapping(address => uint256) public isInTop10;
    mapping(uint256 => HashrateTopOrder) public hashrateTopOrders;

    struct HashrateTopOrder {
        address account;
        uint256 hashrate;
    }

    uint256 public top10StatisticsTime;
    uint256 public top10UnwithdrawnEarnings;
    uint256 public preRechargeReaBalance;//Number of recharging rea
    mapping(address => uint256) public nowTop10ReaEarnings;

    constructor(address _lpTokenContract, address _reaTokenContract) public {
        lpTokenContract = ERC20(_lpTokenContract);
        reaTokenContract = ERC20(_reaTokenContract);
    }

    // Add event log
    event JoinStake(address indexed account, uint256 amount);
    event GetSedimentRea(address indexed account, address indexed to, uint256 amount);
    event BindingInvitation(address indexed account, address indexed invitation);
    event AddHashrate(address indexed account, address indexed invitation, uint256 amount, uint256 hashrate, uint256 level);
    event SubHashrate(address indexed account, address indexed invitation, uint256 amount, uint256 hashrate, uint256 level);
    event ExitStake(address indexed account, uint256 amount);
    event DynamicTimes(address indexed account, uint256 amount, uint256 level);
    event Yesterday(address indexed account, uint256 amount);
    event WithdrawStakeEarnings(address indexed account, uint256 stakeEarningsAmount);
    event WeeklyIncomeStatisticsTop10(address indexed account, uint256 thisReaNum, uint256 nodeNowCount, uint256 callType);
    event UserUnwithdrawnEarnings(address indexed account, uint256 thisReaNum, uint256 ranking, uint256 userUnwithdrawnEarnings);
    event Top10WithdrawREA(address indexed account, uint256 nowTop10ReaEarnings);
    event FunctionRechargeRea(address indexed account, uint256 num);

    // create Moho Contract
    function createMohoContract(address _mohoContract) public onlyOwner returns (string memory result) {
        mohoContract = Moho(_mohoContract);
        return "createMohoContract success";
        // return result
    }

    // Obtain the Box contract invitation relationship
    function getMohoInviteAddress(address user) public view returns (address) {
        return mohoContract.getInviteAddress(user);
    }

    // Get the inviter's address
    function getInviteAddressOf(address account) public view returns (address) {
        return inviteAddress[account];
    }

    // Number of recharging rea
    function functionRechargeRea(uint256 amount) public returns (string memory result) {
        // Determine whether the contract REA balance is sufficient
        require(reaTokenContract.balanceOf(address(msg.sender)) >= amount, "-> reaTokenContract: Insufficient balance of REA TOKEN available to contract.");
        // Transfer the user REA to the contract
        reaTokenContract.safeTransferFrom(address(msg.sender), address(this), amount);

        preRechargeReaBalance += amount;
        emit FunctionRechargeRea(msg.sender, amount);
        // set log
        return "functionRechargeRea success";
        // return result
    }

    // Node withdrawal last week's earnings REA
    function top10WithdrawREA() public returns (string memory result) {
        // Enable statistics or not
        uint256 nowTime = block.timestamp;
        uint256 diff = nowTime.sub(top10StatisticsTime);
        if (diff > 86400) {// The user calls
            uint256 countDay = diff.div(86400);
            // Determine whether the contract REA balance is sufficient
            uint256 thisReaNum = reaTokenContract.balanceOf(address(this)).sub(top10UnwithdrawnEarnings).sub(preRechargeReaBalance);
            if (thisReaNum > 0) {
                uint256 nodeNowCount = joinStakeCount;
                if (joinStakeCount >= 10) {
                    nodeNowCount = 10;
                }
                uint256 userUnwithdrawnEarnings;
                for (uint256 i = 1; i <= nodeNowCount; i++) {
                    if (i == 1) {
                        userUnwithdrawnEarnings = thisReaNum.mul(25).div(100);
                    } else if (i == 2) {
                        userUnwithdrawnEarnings = thisReaNum.mul(20).div(100);
                    } else if (i == 3) {
                        userUnwithdrawnEarnings = thisReaNum.mul(15).div(100);
                    } else if (i == 4) {
                        userUnwithdrawnEarnings = thisReaNum.mul(10).div(100);
                    } else {
                        userUnwithdrawnEarnings = thisReaNum.mul(30).div(100).div(nodeNowCount.sub(4));
                        // he remaining average. 30%
                    }
                    nowTop10ReaEarnings[hashrateTopOrders[i].account] += userUnwithdrawnEarnings;
                    top10UnwithdrawnEarnings += userUnwithdrawnEarnings;
                    emit UserUnwithdrawnEarnings(hashrateTopOrders[i].account, thisReaNum, i, userUnwithdrawnEarnings);
                }
                emit WeeklyIncomeStatisticsTop10(msg.sender, thisReaNum, nodeNowCount, uint256(1));

                uint256 addTime = countDay.mul(86400);
                top10StatisticsTime += addTime;
                // Wave field statistics time accumulation
            }
        }

        // Withdrawal REA
        uint256 accountTop10ReaEarnings = nowTop10ReaEarnings[msg.sender];
        require(accountTop10ReaEarnings > uint256(0), "-> accountTop10ReaEarnings: The revenue of the address withdrawable node is 0.");
        require(reaTokenContract.balanceOf(address(this)) > accountTop10ReaEarnings, "-> accountTop10ReaEarnings: The contract REA is insufficient.");
        reaTokenContract.safeTransfer(msg.sender, accountTop10ReaEarnings);
        // Transfer usdt to destination address
        nowTop10ReaEarnings[msg.sender] = uint256(0);
        top10UnwithdrawnEarnings -= accountTop10ReaEarnings;
        emit Top10WithdrawREA(msg.sender, accountTop10ReaEarnings);

        return "top10WithdrawREA success";
        // return result
    }

    // Start one cycle settlement REA
    function enableStatisticsOtherCallREA() public returns (string memory result) {
        // Enable statistics or not
        uint256 nowTime = block.timestamp;
        uint256 diff = nowTime.sub(top10StatisticsTime);
        require(diff >= 86400, "-> diff: Cycle time has not reached an epoch.");

        uint256 countDay = diff.div(86400);
        // Determine whether the contract REA balance is sufficient
        uint256 thisReaNum = reaTokenContract.balanceOf(address(this)).sub(top10UnwithdrawnEarnings).sub(preRechargeReaBalance);
        require(thisReaNum > uint256(0), "-> thisReaNum: Insufficient balance of REA available to contract.");

        uint256 nodeNowCount = joinStakeCount;
        if (joinStakeCount >= 10) {
            nodeNowCount = 10;
        }
        uint256 userUnwithdrawnEarnings;
        for (uint256 i = 1; i <= nodeNowCount; i++) {
            if (i == 1) {
                userUnwithdrawnEarnings = thisReaNum.mul(25).div(100);
            } else if (i == 2) {
                userUnwithdrawnEarnings = thisReaNum.mul(20).div(100);
            } else if (i == 3) {
                userUnwithdrawnEarnings = thisReaNum.mul(15).div(100);
            } else if (i == 4) {
                userUnwithdrawnEarnings = thisReaNum.mul(10).div(100);
            } else {
                userUnwithdrawnEarnings = thisReaNum.mul(30).div(100).div(nodeNowCount.sub(4));
                // he remaining average. 30%
            }
            nowTop10ReaEarnings[hashrateTopOrders[i].account] += userUnwithdrawnEarnings;
            top10UnwithdrawnEarnings += userUnwithdrawnEarnings;
            emit UserUnwithdrawnEarnings(hashrateTopOrders[i].account, thisReaNum, i, userUnwithdrawnEarnings);
        }
        emit WeeklyIncomeStatisticsTop10(msg.sender, thisReaNum, nodeNowCount, uint256(1));

        uint256 addTime = countDay.mul(86400);
        top10StatisticsTime += addTime;
        // Wave field statistics time accumulation

        return "enableStatisticsOtherCallREA success";
        // return result
    }

    // The weights of top 10 are (first place) 25%, (second place) 20%, (third place) 15%, (fourth place) 10%. The remaining average.
    function updateHashrateTop10(uint256 changeType, address inviteAddress) private returns (uint256) {
        // not math 11 ; 1=add,2=sub
        if (joinStakeLP[inviteAddress] == 0) {
            return 0;
        }

        uint256 updateCount = joinStakeCount;
        uint256 finalForce = joinStakeLP[inviteAddress] + dynamicTimes[inviteAddress].topNewToday;
        if (joinStakeCount > 10) {
            updateCount = 10;
            if (changeType == 1) {
                //                if (nowHashrate[msg.sender] <= hashrateTopOrders[10].hashrate) {
                if (finalForce <= hashrateTopOrders[10].hashrate) {
                    return 0;
                    // add nowHashrate < 10
                }
            }
        }

        // when = add
        uint256 changeNo = updateCount;
        if (changeType == 1 && isInTop10[inviteAddress] == 0) {// 增加算力，此地址不在top10变动；
            for (uint256 j = changeNo; j >= 1; j--) {
                //                if (nowHashrate[msg.sender] > hashrateTopOrders[j].hashrate) {
                if (finalForce > hashrateTopOrders[j].hashrate) {
                    changeNo = j;
                    hashrateTopOrders[j + 1].hashrate = hashrateTopOrders[j].hashrate;
                    hashrateTopOrders[j + 1].account = hashrateTopOrders[j].account;
                    isInTop10[hashrateTopOrders[j + 1].account] = j + 1;
                    if (j + 1 > 10) {
                        isInTop10[hashrateTopOrders[j + 1].account] = 0;
                    }
                }
            }
        } else if (changeType == 1 && isInTop10[inviteAddress] != 0) {// 增加算力，此地址在top10变动；
            changeNo = isInTop10[inviteAddress];
            for (uint256 j = changeNo; j > 1; j--) {
                //                if (nowHashrate[msg.sender] > hashrateTopOrders[j - 1].hashrate) {
                if (finalForce > hashrateTopOrders[j - 1].hashrate) {
                    changeNo = j - 1;
                    hashrateTopOrders[j].hashrate = hashrateTopOrders[j - 1].hashrate;
                    hashrateTopOrders[j].account = hashrateTopOrders[j - 1].account;
                    isInTop10[hashrateTopOrders[j].account] = j;
                }
            }
        } else if (changeType == 2 && isInTop10[inviteAddress] != 0) {// 减少算力，此地址不在top10无需变动；在top10则调整排行榜。
            changeNo = isInTop10[inviteAddress];
            for (uint256 j = changeNo; j <= updateCount; j++) {
                //                if (nowHashrate[msg.sender] < hashrateTopOrders[j + 1].hashrate) {
                if (finalForce < hashrateTopOrders[j + 1].hashrate) {
                    changeNo = j + 1;
                    hashrateTopOrders[j].hashrate = hashrateTopOrders[j + 1].hashrate;
                    hashrateTopOrders[j].account = hashrateTopOrders[j + 1].account;
                    isInTop10[hashrateTopOrders[j].account] = j;
                } else {
                    j = updateCount + 1;
                    // end
                }
            }
        }
        hashrateTopOrders[changeNo].hashrate = nowHashrate[inviteAddress];
        hashrateTopOrders[changeNo].account = inviteAddress;
        isInTop10[inviteAddress] = changeNo;

        return 0;
    }


    // Withdraw Stake earnings
    function withdrawStakeEarnings() public returns (string memory result) {
        // Data validation
        require(isJoinStake[msg.sender] == true, "-> isJoinStake: This site is not currently involved in mobile mining.");
        require(joinStakeLP[msg.sender] > uint256(0), "-> joinStakeLP: The address participating LP is 0.");

        uint256 stakeEarningsAmount = uint256(0);
        // Define the initial value of revenue
        if (accountStakeCount[msg.sender] > 0) {
            // Earned income
            uint256 nowTime = block.timestamp;
            uint256 stakeStartDiff = nowTime.sub(liquidityStakeStartTime);
            uint256 yearsNo = stakeStartDiff.div(86400).div(365);
            // 1years = 60*60*24*365
            uint256 yearsRewardBase;
            if (yearsNo <= 0) {
                yearsRewardBase = yearStakeNo1.div(365);
            } else if (yearsNo <= 1) {
                yearsRewardBase = yearStakeNo2.div(365);
            } else if (yearsNo <= 2) {
                yearsRewardBase = yearStakeNo3.div(365);
            } else if (yearsNo <= 3) {
                yearsRewardBase = yearStakeNo4.div(365);
            } else {
                yearsRewardBase = yearStakeNo5.div(365);
            }

            uint256 diff = uint256(0);
            uint256 countDay = uint256(0);
            uint256 bl = uint256(0);
            uint256 gainSinglePledge = uint256(0);
            for (uint256 i = 1; i <= accountStakeCount[msg.sender]; i++) {
                diff = nowTime.sub(accountStakeOrders[msg.sender][i].exitStakeTime);
                if (diff > 86400) {
                    countDay = diff.div(86400);
                    bl = yearsRewardBase.mul(1000000000000000).div(totalJoinStakeLP).mul(86400).div(86400).mul(countDay);
                    // Add 1 quadrillion to the calculation
                    gainSinglePledge = accountStakeOrders[msg.sender][i].amount.mul(bl);
                    // 600S = 1day
                    stakeEarningsAmount += gainSinglePledge.div(1000000000000000);
                    // Sub 1 quadrillion to the calculation
                }
                accountStakeOrders[msg.sender][i].exitStakeTime += countDay.mul(86400);
                // Update the order withdrawal timestamp
            }
        }

        // Return address REA
        require(reaTokenContract.balanceOf(address(this)) >= stakeEarningsAmount, "-> reaTokenContract: Insufficient balance of REA TOKEN available to contract.");
        reaTokenContract.safeTransfer(address(msg.sender), stakeEarningsAmount);

        preRechargeReaBalance -= stakeEarningsAmount;
        // Reduce the number of reAs in pre-recharge

        emit WithdrawStakeEarnings(msg.sender, stakeEarningsAmount);
        return "withdrawStakeEarnings success";
        // return result
    }

    // Get Stake earnings
    function stakeEarningsOf(address joinStakeAddress) public view returns (uint256) {
        uint256 stakeEarningsAmount = uint256(0);
        // Define the initial value of revenue

        if (accountStakeCount[joinStakeAddress] > 0) {
            // Earned income
            uint256 nowTime = block.timestamp;
            uint256 stakeStartDiff = nowTime.sub(liquidityStakeStartTime);
            uint256 yearsNo = stakeStartDiff.div(31536000);
            // 1years = 60*60*24*365
            uint256 yearsRewardBase;

            if (yearsNo <= 0) {
                yearsRewardBase = yearStakeNo1.div(365);
            } else if (yearsNo <= 1) {
                yearsRewardBase = yearStakeNo2.div(365);
            } else if (yearsNo <= 2) {
                yearsRewardBase = yearStakeNo3.div(365);
            } else if (yearsNo <= 3) {
                yearsRewardBase = yearStakeNo4.div(365);
            } else {
                yearsRewardBase = yearStakeNo5.div(365);
            }

            uint256 diff = uint256(0);
            uint256 countDay = uint256(0);
            uint256 bl = uint256(0);
            uint256 gainSinglePledge = uint256(0);
            for (uint256 i = 1; i <= accountStakeCount[joinStakeAddress]; i++) {
                diff = nowTime.sub(accountStakeOrders[joinStakeAddress][i].exitStakeTime);
                if (diff > 86400) {
                    countDay = diff.div(86400);
                    bl = yearsRewardBase.mul(1000000000000000).div(totalJoinStakeLP).mul(86400).div(86400).mul(countDay);
                    // Add 1 quadrillion to the calculation
                    gainSinglePledge = accountStakeOrders[joinStakeAddress][i].amount.mul(bl);
                    // 600S = 1day
                    stakeEarningsAmount += gainSinglePledge.div(1000000000000000);
                    // Sub 1 quadrillion to the calculation
                }
            }
        }
        return stakeEarningsAmount;
    }

    // Exit Stake + Get Stake earnings
    function exitStake() public returns (string memory result) {
        // Data validation
        require(isJoinStake[msg.sender] == true, "-> isJoinStake: This site is not currently involved in mobile mining.");
        require(joinStakeLP[msg.sender] > uint256(0), "-> joinStakeLP: The address participating LP is 0.");

        withdrawStakeEarnings();

        // Logical processing
        uint256 amount = joinStakeLP[msg.sender];
        uint256 nowTime = block.timestamp;
        joinStakeCount -= uint256(1);
        isJoinStake[msg.sender] = false;
        joinStakeLP[msg.sender] = uint256(0);
        totalJoinStakeLP -= amount;

        // Dynamic new computing power = 20% new performance of the first generation + 10% new performance of the second generation.
        nowHashrate[msg.sender] -= amount;
        emit SubHashrate(msg.sender, msg.sender, amount, amount, uint256(0));

        address inviteAddress1 = inviteAddress[msg.sender];
        if (inviteAddress1 != address(0)) {
            nowHashrate[inviteAddress1] -= amount.mul(20).div(100);
            totalHashrate -= amount.mul(20).div(100);
            emit SubHashrate(msg.sender, inviteAddress1, amount, amount.mul(20).div(100), uint256(1));

            address inviteAddress2 = inviteAddress[inviteAddress1];
            if (inviteAddress2 != address(0)) {
                nowHashrate[inviteAddress2] -= amount.mul(10).div(100);
                totalHashrate -= amount.mul(10).div(100);
                emit SubHashrate(msg.sender, inviteAddress2, amount, amount.mul(10).div(100), uint256(2));
            }
        }

        // orders
        for (uint256 i = 1; i <= accountStakeCount[msg.sender]; i++) {
            accountStakeOrders[msg.sender][i].isExist = false;
            //            if(nowTime-accountStakeOrders[msg.sender][i].joinStakeTime>=84600){
            if (nowTime - accountStakeOrders[msg.sender][i].joinStakeTime < 600) {
                if (inviteAddress1 != address(0)) {
                    dynamicTimes[inviteAddress1].topNewToday -= amount.mul(20).div(100);
                    updateHashrateTop10(uint256(2), inviteAddress1);

                    emit DynamicTimes(inviteAddress1, amount.mul(20).div(100), uint256(2));
                    address inviteAddress2 = inviteAddress[inviteAddress1];
                    if (inviteAddress2 != address(0)) {
                        dynamicTimes[inviteAddress2].topNewToday -= amount.mul(10).div(100);
                        updateHashrateTop10(uint256(2), inviteAddress2);

                        emit DynamicTimes(inviteAddress2, amount.mul(10).div(100), uint256(2));
                    }
                }

            }
            accountStakeOrders[msg.sender][i].exitStakeTime = block.timestamp;
        }
        accountStakeCount[msg.sender] = uint256(0);

        // Return address LP
        lpTokenContract.safeTransfer(address(msg.sender), amount);

        // set log
        emit ExitStake(msg.sender, amount);

        updateHashrateTop10(uint256(2), msg.sender);
        return "exitStake success";
        // return result
    }

    // Use lp(REA-TRX) join stake get rea.
    function joinStake(uint256 amount) public returns (uint256 resultData) {
        // Data validation
        require(liquidityStakeSwitchState, "-> liquidityStakeSwitchState: Liquidity Stake has not started yet.");
        require(lpTokenContract.balanceOf(msg.sender) >= amount, "-> lpTokenContract: The LP balance of the join Liquidity was not reached.");
        require(inviteAddress[msg.sender] != address(0), "-> inviteAddress: Please bind the invite address first.");

        // Logical processing
        if (isJoinStake[msg.sender] == false) {
            joinStakeCount += uint256(1);
            // add count = not join
            isJoinStake[msg.sender] = true;
        }


        setTopNewToday();
        // Dynamic new computing power = 20% new performance of the first generation + 10% new performance of the second generation.
        nowHashrate[msg.sender] += amount;
        emit AddHashrate(msg.sender, msg.sender, amount, amount, uint256(0));

        address inviteAddress1 = inviteAddress[msg.sender];
        if (inviteAddress1 != address(0)) {
            setDynamicTimes(inviteAddress1);
            nowHashrate[inviteAddress1] += amount.mul(20).div(100);
            dynamicTimes[inviteAddress1].topNewToday += amount.mul(20).div(100);
            totalHashrate += amount.mul(20).div(100);
            updateHashrateTop10(uint256(1), inviteAddress1);

            emit DynamicTimes(inviteAddress1, amount.mul(20).div(100), uint256(1));
            emit AddHashrate(msg.sender, inviteAddress1, amount, amount.mul(20).div(100), uint256(1));

            address inviteAddress2 = inviteAddress[inviteAddress1];
            if (inviteAddress2 != address(0)) {
                setDynamicTimes(inviteAddress2);
                nowHashrate[inviteAddress2] += amount.mul(10).div(100);
                dynamicTimes[inviteAddress2].topNewToday += amount.mul(10).div(100);
                totalHashrate += amount.mul(10).div(100);
                updateHashrateTop10(uint256(1), inviteAddress2);

                emit DynamicTimes(inviteAddress2, amount.mul(20).div(100), uint256(1));
                emit AddHashrate(msg.sender, inviteAddress2, amount, amount.mul(10).div(100), uint256(2));
            }
        }
        joinStakeLP[msg.sender] += amount;
        totalJoinStakeLP += amount;
        // orders
        accountStakeCount[msg.sender] += uint256(1);
        accountStakeOrders[msg.sender][accountStakeCount[msg.sender]] = AccountStakeOrder(accountStakeCount[msg.sender], true, block.timestamp, block.timestamp, amount);

        // Transfer the user LP to the contract
        lpTokenContract.safeTransferFrom(address(msg.sender), address(this), amount);

        // set log
        emit JoinStake(msg.sender, amount);

        updateHashrateTop10(uint256(1), msg.sender);
        return resultData;
    }

    // Rea precipitated in the contract was extracted
    function getSedimentRea(address to, uint256 amount) public onlyOwner returns (string memory result) {
        require(reaTokenContract.balanceOf(address(this)) >= amount, "-> reaTokenContract: Insufficient balance of REA TOKEN available to contract.");
        // Determine whether the contract REA balance is sufficient
        reaTokenContract.safeTransfer(to, amount);
        // Transfer rea to destination address
        preRechargeReaBalance -= amount;
        // Reduce the number of reAs in pre-recharge
        emit GetSedimentRea(msg.sender, to, amount);
        // set log
        return "getSedimentRea success";
        // return result
    }

    // Get user MohoPledged Count
    function isJoinStakeOf(address user) public view returns (bool) {
        return isJoinStake[user];
    }

    // While using the magic box to confirm the referral relationship, bind the invitation relationship in the flow mining.
    function bindInvitation(address invitation) public returns (string memory result) {
        if (inviteAddress[msg.sender] == address(0)) {
            address myInvitation;
            if (mohoContract.getInviteAddress(msg.sender) != address(0)) {
                myInvitation = mohoContract.getInviteAddress(msg.sender);
            } else {
                require(msg.sender != invitation, "-> invitation: Invitation address cannot be for oneself.");
                if (invitation != mohoContract.getFirstLuckDrawAddress()) {
                    require(mohoContract.userMohoPledgedCountOf(invitation) >= 1 || isJoinStake[invitation] == true, "The invitational address has no promotion authority");
                }
                myInvitation = invitation;
            }
            inviteAddress[msg.sender] = myInvitation;
            // Write invitation relationship
            emit BindingInvitation(msg.sender, myInvitation);
            // set log
            return "bindInvitation success";
        }
        return "error -> inviteAddress is exist";
        // return result
    }

    // Set the node switch state and update the node liquidity Stake start time
    function setLiquidityStakeSwitchState(bool _liquidityStakeSwitchState) public onlyOwner {
        liquidityStakeSwitchState = _liquidityStakeSwitchState;
        if (liquidityStakeStartTime == 0) {
            liquidityStakeStartTime = block.timestamp;
            // update liquidityStakeStartTime
            top10StatisticsTime = 1629216000;
        }
    }
    // Change the address dynamic income of TOP10 to 0
    function setTopNewToday() public {
        uint256 nodeNowCount = joinStakeCount;
        if (joinStakeCount >= 10) {
            nodeNowCount = 10;
        }
        for (uint256 i = 1; i <= nodeNowCount; i++) {
            setDynamicTimes(hashrateTopOrders[i].account);
        }

    }
    // Change the dynamic income of the recommender's address to 0
    function setDynamicTimes(address invitation) private {
        uint256 countDay = 0;
        uint256 nowTime = block.timestamp;

        uint256 _time = 86400;
        if (dynamicTimes[invitation].newTodayTime < 1629216000) {
            dynamicTimes[invitation].newTodayTime = 1629216000;
        }

        uint256 diff = nowTime.sub(dynamicTimes[invitation].newTodayTime);

        if (diff >= _time) {
            countDay = diff.div(_time);
            dynamicTimes[invitation].newTodayTime += countDay.mul(_time);
            if(countDay > uint256(1)){
                dynamicTimes[invitation].topNewToday = uint256(0);
            }

            yesterday[invitation] = dynamicTimes[invitation].topNewToday + joinStakeLP[invitation];
            dynamicTimes[invitation].topNewToday = uint256(0);


            emit Yesterday(invitation, yesterday[invitation]);
            emit DynamicTimes(invitation, uint256(0), uint256(3));
        }

    }

    function getYesterday(address invitation) public view returns (uint256){
        return yesterday[invitation];
    }

    function getTopNewToday(address invitation) public view returns (uint256){
        return dynamicTimes[invitation].topNewToday;
    }

}


//SourceUnit: SafeERC20.sol

pragma solidity 0.5.8;

import "./Address.sol";
import "./SafeMath.sol";

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),"SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(ERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        //if (returndata.length > 0) {
          //  require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        //}
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


//SourceUnit: SafeMath.sol

pragma solidity 0.5.8;

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