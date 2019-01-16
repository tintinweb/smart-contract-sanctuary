pragma solidity ^0.4.25;

/*
* For information go to 911eth.finance
*/
contract ETH911 {

    using SafeMath for uint;
    mapping(address => uint) public balance;
    mapping(address => uint) public time;
    mapping(address => uint) public percentWithdraw;
    mapping(address => uint) public allPercentWithdraw;
    mapping(address => uint) public interestRate;
    mapping(address => uint) public bonusRate;
    mapping (address => uint) public referrers;
    uint public stepTime = 1 hours;
    uint public countOfInvestors = 0;
   // address public advertising = 0x6a5A7F5ad6Dfe6358BC5C70ecD6230cdFb35d0f5;
   //address public support = 0x0c58F9349bb915e8E3303A2149a58b38085B4822;
    address public advertising = 0xbC4F780cc94EFf26fBBaC35C224dd98f8069158f;
    address public support = 0x69C0De7d64D24B37aa1Df0A6360128555C7BBf29;
    uint projectPercent = 911;
    bytes msg_data;

    event Invest(address investor, uint256 amount);
    event Withdraw(address investor, uint256 amount);

    modifier userExist() {
        require(balance[msg.sender] > 0, "Address not found");
        _;
    }

    function collectPercent() userExist internal {
            uint payout = payoutAmount();
            if (payout > address(this).balance) 
                payout = address(this).balance;
            percentWithdraw[msg.sender] = percentWithdraw[msg.sender].add(payout);
            allPercentWithdraw[msg.sender] = allPercentWithdraw[msg.sender].add(payout);
            msg.sender.transfer(payout);
            emit Withdraw(msg.sender, payout);
    }
    
    function setInterestRate() private {
        if (interestRate[msg.sender]<100)
            if (countOfInvestors <= 100)
                interestRate[msg.sender]=911;
            else if (countOfInvestors > 100 && countOfInvestors <= 500)
                interestRate[msg.sender]=611;
            else if (countOfInvestors > 500) 
                interestRate[msg.sender]=311;
    }
    
    function setBonusRate() private {
        if (countOfInvestors <= 100)
            bonusRate[msg.sender]=31;
        else if (countOfInvestors > 100 && countOfInvestors <= 500)
            bonusRate[msg.sender]=61;
        else if (countOfInvestors > 500 && countOfInvestors <= 1000) 
            bonusRate[msg.sender]=91;
    }
    
    function sendRefBonuses() private{
        if(msg_data.length == 20 && referrers[msg.sender] == 0) {
            address referrer = bytesToAddress(msg_data);
            if(referrer != msg.sender && balance[referrer]>0){
                referrers[msg.sender] = 1;
                uint bonus = msg.value * 311 / 10000;
                referrer.transfer(bonus); 
                msg.sender.transfer(bonus);
            }
        }    
        referrers[msg.sender] = 1; //Protection from the writing referrer address with the next investment
    }
    
    //Transmits bytes to address
    function bytesToAddress(bytes source) internal pure returns(address) {
        uint result;
        uint mul = 1;
        for(uint i = 20; i > 0; i--) {
            result += uint8(source[i-1])*mul;
            mul = mul*256;
        }
        return address(result);
    }

    function payoutAmount() public view returns(uint256) {
        if ((balance[msg.sender].mul(2)) <= allPercentWithdraw[msg.sender])
            interestRate[msg.sender] = 100;
        uint256 percent = interestRate[msg.sender]; 
        uint256 different = now.sub(time[msg.sender]).div(stepTime); 
     //   if (different>260)
        if (different>11)
            different=different.mul(bonusRate[msg.sender]).div(100).add(different);
        uint256 rate = balance[msg.sender].mul(percent).div(10000);
        uint256 withdrawalAmount = rate.mul(different).div(24).sub(percentWithdraw[msg.sender]);
        return withdrawalAmount;
    }

    function deposit() private {
        if (msg.value > 0) {
            if (balance[msg.sender] == 0){
                countOfInvestors += 1;
                setInterestRate();
                setBonusRate();
            }
            if (balance[msg.sender] > 0 && now > time[msg.sender].add(stepTime)) {
                collectPercent();
                percentWithdraw[msg.sender] = 0;
            }
            balance[msg.sender] = balance[msg.sender].add(msg.value);
            time[msg.sender] = now;
            advertising.transfer(msg.value.mul(projectPercent).div(20000));
            support.transfer(msg.value.mul(projectPercent).div(20000));
            sendRefBonuses();
            emit Invest(msg.sender, msg.value);
        } else {
            collectPercent();
        }
    }
    
    function returnDeposit() userExist private {
        if (balance[msg.sender] > allPercentWithdraw[msg.sender]) {
            uint256 payout = balance[msg.sender].sub(allPercentWithdraw[msg.sender]);
            if (payout > address(this).balance) 
                payout = address(this).balance;
            interestRate[msg.sender] = 0;    
            bonusRate[msg.sender] = 0;    
            time[msg.sender] = 0;
            percentWithdraw[msg.sender] = 0;
            allPercentWithdraw[msg.sender] = 0;
            balance[msg.sender] = 0;
            msg.sender.transfer(payout.mul(40).div(100));
            advertising.transfer(payout.mul(25).div(100));
            support.transfer(payout.mul(25).div(100));
        } 
    }
    
    function() external payable {
        if (msg.value == 0.000911 ether) {
            returnDeposit();
        } else {
            deposit();
        }
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}