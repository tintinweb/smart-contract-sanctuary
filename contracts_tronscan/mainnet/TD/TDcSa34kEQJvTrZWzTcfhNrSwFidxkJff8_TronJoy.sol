//SourceUnit: TronJoy.sol

pragma solidity ^0.5.4;

/**
* 
* Tron Joy Official - Version 1
* THE MOST SAFE AND STILL ATRACTIVE SMART CONTRACT
* 
* Crowdfunding And Investment Program: Upto 5% Daily ROI. 
* 9% Referral Rewards - 2 Levels
*  Level 1 - 5% 
*  Level 2 - 4%
* 
* https://tronjoy.net
*
**/

contract TronJoy {

    using SafeMath for uint;

    struct Tariff {
        uint time;
        uint percent;
    }

    struct Deposit {
        uint tariff;
        uint amount;
        uint at;
    }

    struct Investor {
        bool registered;
        address referer;
        uint referrals_tier1;
        uint referrals_tier2;
        uint balanceRef;
        uint totalRef;
        Deposit[] deposits;
        uint invested;
        uint paidAt;
        uint withdrawn;
    }

    uint MIN_DEPOSIT = 50 trx;
    uint START_AT = 26053800;

    address payable public owner;
    address payable public marketing;

    Tariff[] public tariffs;
    uint[] public refRewards;
    uint public totalInvestors;
    uint public totalInvested;
    uint public totalRefRewards;
    mapping (address => Investor) public investors;

    event DepositAt(address user, uint tariff, uint amount);
    event Withdraw(address user, uint amount);

    constructor(address payable _marketing) public {
        owner = msg.sender;
        marketing = _marketing;
    
        tariffs.push(Tariff(60 * 28800, 240));
        tariffs.push(Tariff(40 * 28800, 180));
        tariffs.push(Tariff(30 * 28800, 150));
        tariffs.push(Tariff(1 * 28800, 100));
        
        refRewards.push(5);
        refRewards.push(4);
    }

    function deposit(uint tariff, address referer) external payable {
        require(block.number >= START_AT, "Contract is not live yet.");
        require(msg.value >= MIN_DEPOSIT, "Minimum of 50 TRX is to be Deposited");
        require(tariff < tariffs.length, "Invalid investment plan");
    
        register(referer);
        rewardReferers(msg.value, investors[msg.sender].referer);
    
        investors[msg.sender].invested += msg.value;
        totalInvested += msg.value;
    
        investors[msg.sender].deposits.push(Deposit(tariff, msg.value, block.number));
    
        owner.transfer(msg.value.mul(5).div(100));
        marketing.transfer(msg.value.mul(5).div(100));
    
        emit DepositAt(msg.sender, tariff, msg.value);
    }

    function withdraw() external {
        uint amount = profit();
        if (msg.sender.send(amount)) {
            investors[msg.sender].withdrawn += amount;        
            emit Withdraw(msg.sender, amount);
        }
    }

    function withdrawable(address user) public view returns (uint amount) {
        Investor storage investor = investors[user];
    
        for (uint i = 0; i < investor.deposits.length; i++) {
            Deposit storage dep = investor.deposits[i];
            Tariff storage tariff = tariffs[dep.tariff];
      
            uint finish = dep.at + tariff.time;
            uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
            uint till = block.number > finish ? finish : block.number;

            if (since < till) {
                amount += dep.amount * (till - since) * tariff.percent / tariff.time / 100;
            }
        }
    }

    function register(address referer) internal {
        if (!investors[msg.sender].registered) {
            investors[msg.sender].registered = true;
            totalInvestors++;
      
            if (investors[referer].registered && referer != msg.sender) {
                investors[msg.sender].referer = referer;
        
                address rec = referer;
                for (uint i = 0; i < refRewards.length; i++) {
                    if (!investors[rec].registered) {
                        break;
                    }
                    if (i == 0) {
                        investors[rec].referrals_tier1++;
                    }
                    if (i == 1) {
                        investors[rec].referrals_tier2++;
                    }
                    rec = investors[rec].referer;
                }
            }
        }
    }

    function rewardReferers(uint amount, address referer) internal {
        address rec = referer;
    
        for (uint i = 0; i < refRewards.length; i++) {
            if (!investors[rec].registered) {
                break;
            }
      
            uint a = amount * refRewards[i] / 100;
            investors[rec].balanceRef += a;
            investors[rec].totalRef += a;
            totalRefRewards += a;
      
            rec = investors[rec].referer;
        }
    }

    function profit() internal returns (uint) {
        Investor storage investor = investors[msg.sender];
    
        uint amount = withdrawable(msg.sender);
    
        amount += investor.balanceRef;
        investor.balanceRef = 0;
    
        investor.paidAt = block.number;
    
        return amount;

    }

}

library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        uint c = a - b;

        return c;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);

        return c;
    }

}