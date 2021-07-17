/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

// SPDX-License-Identifier: MIT 
 
 /*  The innovative way to obtain a long lasting and passive income, through the use of the most popular Token on the binance smart chain.
 *   Invest your CAKE and earn daily dividends through our long term investment platform.
 *   
 *   | USAGE INSTRUCTIONS |
 *
 *   - Connect your Metamask to the binance smart chain (see help: https://academy.binance.com/en/articles/connecting-metamask-to-binance-smart-chain )
 *   - Head over to our website at cakefunds.app
 *   - Enter the amount of CAKE you would like to invest into our investment pool (0.5 CAKE minimum) using the "Invest CAKE" button
 *   - Earn a minimum of 1% daily return on your investment, for a minimum of 300% total return.
 *   - Claim your CAKE rewards every 24 hours, using the "Claim" button (There are no restrictions on the minimum amount of CAKE you can claim)
 *   - You can also Compound your CAKE every 24 hours, using the "Compound" button. This will increase your daily and total return.
 *
 *   | INVESTMENT CONDITIONS |
 *
 *   - There is a minimum requirement of 0.5 CAKE in order to make an investment
 *   - There are no restrictions on the maximum amount of CAKE you can invest
 *   - Total income: This starts up to 1.5% daily and 450% total
 *   - Earnings are calculated every moment, claim or compound every day.
 *
 *   | AFFILIATE PROGRAM |
 *
 *   - 3-level referral commission: 5% - 2.5% - 0.5%
 *
 *   | INVESTMENT FUNDS DISTRIBUTION |
 *
 *   - 91% Platform main balance, participants payouts
 *   - 6% Support work, technical functioning, administration fee - this applies to all investments. 
 *   - 3% Marketing support.
 *
 *   | COMPOUND FUNDS DISTRIBUTION |
 *
 *   - 97% Platform main balance, participants payouts
 *   - 3%% Support work, technical functioning, administration fee - this applies to all compounds.
 *
 *   | WITHDRAW |
 *
 *   - 6% Support work, technical functioning, administration fee.
 *   - 94% to user balance
 *
 *   | CONTACT |
 *
 *   - Visit our official website: https://caketrust.com
 */

pragma solidity 0.8.3;

contract Ownable {
    address public owner;
    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract TrustTest is Ownable{
    using SafeMath for uint256;

    IBEP20 public MikeToken;
    uint256 constant public INVEST_MIN_AMOUNT = 10000 ether; 
    uint256 constant public INVEST_MAX_AMOUNT = 200000 ether;
    uint256 constant public WITHDRAW_MIN_AMOUNT = 0.5 ether;
    uint256[] internal REFERRAL_PERCENTS = [50, 25, 5];
    uint256 constant public DEPOSIT_WITHDRAW_FEE = 60; // 6% Fee for each invest/withdraw
    uint256 constant public MARKETING_FEE = 30; // 3% Fee for marketing each invest
    uint256 constant public COMPOUND_FEE = 30; // 6% Fee for compound
    uint256 constant public PERCENTS_DIVIDER = 1000;
    
    uint256 public totalStaked;
    uint256 public totalRefBonus;
    uint256 public totalWithdrawn;
    
    address payable public marketingAddress = payable(0xba2dd16E7Ce34a0860B02a3B8D16E37a54a48633);

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
        address referrer;
        uint256[3] levels;
        uint256 bonus;
        uint256 totalBonus;
        uint256 wprofits;
    }
    
    mapping (address => User) internal users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);

    constructor() {
        MikeToken = IBEP20(0xBE452CDb55eC452aB5F51a1B026104beCAB7Abc1);

        plans.push(Plan(300, 10));
        plans.push(Plan(300, 12));
        plans.push(Plan(300, 15));
    }
    
    function feePayout(uint256 amt) internal{
        MikeToken.transfer(marketingAddress, amt);
        emit FeePayed(msg.sender, amt);
    }
    
    function invest(address referrer, uint256 depAmount) public {
        require(depAmount >= INVEST_MIN_AMOUNT,"Check minimum investing amount");
        require(depAmount <= INVEST_MAX_AMOUNT,"Check maximum investing amount");
        uint8 plan  = 0;
        if(depAmount < 10 ether){
            plan = 0;
        }else if(depAmount >= 10 ether &&  depAmount < 10000 ether){
            plan = 1;
        }else {
            plan = 2;
        }

        MikeToken.transferFrom(msg.sender, address(this), depAmount);

        //Pay admin & marketing fee
        uint256 investFee = depAmount.mul(DEPOSIT_WITHDRAW_FEE.add(MARKETING_FEE)).div(PERCENTS_DIVIDER);
        feePayout(investFee);

        uint256 realDepAmount = depAmount.sub(investFee);

        User storage user = users[msg.sender];
        if (user.referrer == address(0)) {
            if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }
            
            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    users[upline].levels[i] = users[upline].levels[i].add(1);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    uint256 amount = realDepAmount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    users[upline].bonus = users[upline].bonus.add(amount);
                    users[upline].totalBonus = users[upline].totalBonus.add(amount);
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.deposits.length == 0) {
            user.checkpoint = getDateFromTimeStamp(block.timestamp);
            emit Newbie(msg.sender);
        }
        
        (uint256 percent, uint256 profit, , uint256 finish) = getResult(plan, realDepAmount);
        user.deposits.push(Deposit(plan, percent, realDepAmount, profit, getDateFromTimeStamp(block.timestamp), finish));
        totalStaked = totalStaked.add(realDepAmount);
        emit NewDeposit(msg.sender, plan, percent, realDepAmount, profit, block.timestamp, finish);
    }
    
    function withdraw() public {
        User storage user = users[msg.sender];
        
        //only once a day
        require(getDateFromTimeStamp(block.timestamp) > users[msg.sender].checkpoint , "You can only withdraw once a day");
        uint256 totalAmount = getUserDividends(msg.sender);
        if (user.bonus > 0) {
            totalAmount = totalAmount.add(user.bonus);
            user.bonus = 0;
        }
        require(totalAmount > 0, "User has no dividends");
        require(totalAmount >= WITHDRAW_MIN_AMOUNT, "Please check minimum withdrawal amount");
        uint256 contractBalance = MikeToken.balanceOf(address(this));
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        require(totalAmount >= WITHDRAW_MIN_AMOUNT, "Please check contract balance");

        uint256 withdrawFee = totalAmount.mul(DEPOSIT_WITHDRAW_FEE).div(PERCENTS_DIVIDER);
        feePayout(withdrawFee);

        uint256 withdrawAmount = totalAmount.sub(withdrawFee);
        
        user.checkpoint = getDateFromTimeStamp(block.timestamp);
        
        user.wprofits = (user.wprofits).add(withdrawAmount);
        MikeToken.transfer(payable(msg.sender), withdrawAmount);
        
        totalWithdrawn = (totalWithdrawn.add(withdrawAmount));
        emit Withdrawn(msg.sender, withdrawAmount);
    }
    
    function compound() public {
        User storage user = users[msg.sender];
        
        //only once a day
        require(getDateFromTimeStamp(block.timestamp) > users[msg.sender].checkpoint , "You can only compound once a day");
        uint256 totalAmount = getUserDividends(msg.sender);
        if (user.bonus > 0) {
            totalAmount = totalAmount.add(user.bonus);
            user.bonus = 0;
        }
        require(totalAmount > 0, "User has no dividends");
        require(totalAmount >= WITHDRAW_MIN_AMOUNT, "Please check minimum compounding amount");

        uint8 plan  = 0;
        if(totalAmount < 10 ether){
            plan = 0;
        }else if(totalAmount >= 10 ether &&  totalAmount < 10000 ether){
            plan = 1;
        }else {
            plan = 2;
        }

        uint256 contractBalance = MikeToken.balanceOf(address(this));
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        require(totalAmount >= WITHDRAW_MIN_AMOUNT, "Please check contract balance");

        user.checkpoint = getDateFromTimeStamp(block.timestamp);

        uint256 compoundFee = totalAmount.mul(COMPOUND_FEE).div(PERCENTS_DIVIDER);
        feePayout(compoundFee);
        uint256 compoundAmount = totalAmount.sub(compoundFee);

        (uint256 percent, uint256 profit, , uint256 finish) = getResult(plan, compoundAmount);
        user.deposits.push(Deposit(plan, percent, compoundAmount, profit, getDateFromTimeStamp(block.timestamp), finish));
        totalStaked = totalStaked.add(compoundAmount);
        emit NewDeposit(msg.sender, plan, percent, compoundAmount, profit, block.timestamp, finish);
    }

    function getContractBalance() public view returns (uint256) {
        return MikeToken.balanceOf(address(this));
    }

    function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
        require(plan < 3, "Invalid plan");
        time = plans[plan].time;
        percent = plans[plan].percent;
    }

    function getPercent(uint8 plan) public view returns (uint256) {
        require(plan < 3, "Invalid plan");
        return plans[plan].percent;
    }
    
    function getResult(uint8 plan, uint256 deposit) public view returns ( uint256 percent, uint256 profit, uint256 current, uint256 finish){
        require(plan < 3, "Invalid plan");
        percent = getPercent(plan);
        profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
        current = getDateFromTimeStamp(block.timestamp);
        finish = current.add(plans[plan].time);
    }
    
    function getUserDividends(address userAddress) public view returns (uint256){
        User memory user = users[userAddress];

        uint256 totalAmount;
        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
                uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
                uint256 to = user.deposits[i].finish < getDateFromTimeStamp(block.timestamp) ? user.deposits[i].finish : getDateFromTimeStamp(block.timestamp);
                if (from < to) {
                    totalAmount = totalAmount.add(share.mul(to.sub(from)));
                }
            }
        }
        return totalAmount;
    }
    
    function getUserCheckpoint(address userAddress) public view returns(uint256) {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress) public view returns(address) {
        return users[userAddress].referrer;
    }

    function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
        return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2]);
    }

    function getUserReferralBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].bonus;
    }

    function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].totalBonus;
    }

    function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
        return users[userAddress].totalBonus.sub(users[userAddress].bonus);
    }

    function getUserAvailable(address userAddress) public view returns(uint256) {
        return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
    }
    

    function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            amount = amount.add(users[userAddress].deposits[i].amount);
        }
    }
    
    function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
        return users[userAddress].wprofits;
    }
    
    function getUserDepositInfo(address userAddress, uint256 index) public view returns (uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish){
        User memory user = users[userAddress];
        require(index < user.deposits.length, "Invalid index");

        plan = user.deposits[index].plan;
        percent = user.deposits[index].percent;
        amount = user.deposits[index].amount;
        profit = user.deposits[index].profit;
        start = user.deposits[index].start;
        finish = user.deposits[index].finish;
    }
    
    function setMarketingAccount(address payable _newMarketingAccount) public onlyOwner {
        require(_newMarketingAccount != address(0));
        marketingAddress = _newMarketingAccount;
    }

    function getDateFromTimeStamp(uint256 time) internal pure returns (uint256){
        uint256 dateNo = time.div(24*60*60);
        return dateNo;
    }
    
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
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