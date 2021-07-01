/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

pragma solidity 0.4 .25;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

/**
The development of the contract is entirely owned by the X2{re}start campaign, any copying of the source code is not legal.
*/
contract X2restart {
    //use of library of safe mathematical operations    
    using SafeMath
    for uint;
    // array containing information about beneficiaries
    mapping(address => uint) public userDeposit;
    //array containing information about the time of payment
    mapping(address => uint) public userTime;
    //array containing information on interest paid
    mapping(address => uint) public persentWithdraw;
    //fund fo transfer percent
    address public projectFund = 0xb615E5c6d21Ae628eA4490e2653b9aEb0a3902b5;
    //wallet for a charitable foundation
    address public charityFund = 0x206448E6C7D9833af63fFe2335cfF49D5f6d0dff;
    //percentage deducted to the advertising fund
    uint projectPercent = 8;
    //percent for a charitable foundation
    uint public charityPercent = 1;
    //time through which you can take dividends
    uint public chargingTime = 1 hours;
    //start persent 0.25% per hour
    uint public startPercent = 250;
    uint public lowPersent = 300;
    uint public middlePersent = 350;
    uint public highPersent = 375;
    //interest rate increase steps
    uint public stepLow = 1000 ether;
    uint public stepMiddle = 2500 ether;
    uint public stepHigh = 5000 ether;
    uint public countOfInvestors = 0;
    uint public countOfCharity = 0;

    modifier isIssetUser() {
        require(userDeposit[msg.sender] > 0, "Deposit not found");
        _;
    }

    modifier timePayment() {
        require(now >= userTime[msg.sender].add(chargingTime), "Too fast payout request");
        _;
    }

    //return of interest on the deposit
    function collectPercent() isIssetUser timePayment internal {
        //if the user received 200% or more of his contribution, delete the user
        if ((userDeposit[msg.sender].mul(2)) <= persentWithdraw[msg.sender]) {
            userDeposit[msg.sender] = 0;
            userTime[msg.sender] = 0;
            persentWithdraw[msg.sender] = 0;
        } else {
            uint payout = payoutAmount();
            userTime[msg.sender] = now;
            persentWithdraw[msg.sender] += payout;
            msg.sender.transfer(payout);
        }
    }

    //calculation of the current interest rate on the deposit
    function persentRate() public view returns(uint) {
        //get contract balance
        uint balance = address(this).balance;
        //calculate persent rate
        if (balance < stepLow) {
            return (startPercent);
        }
        if (balance >= stepLow && balance < stepMiddle) {
            return (lowPersent);
        }
        if (balance >= stepMiddle && balance < stepHigh) {
            return (middlePersent);
        }
        if (balance >= stepHigh) {
            return (highPersent);
        }
    }

    //refund of the amount available for withdrawal on deposit
    function payoutAmount() public view returns(uint) {
        uint persent = persentRate();
        uint rate = userDeposit[msg.sender].mul(persent).div(100000);
        uint interestRate = now.sub(userTime[msg.sender]).div(chargingTime);
        uint withdrawalAmount = rate.mul(interestRate);
        return (withdrawalAmount);
    }

    //make a contribution to the system
    function makeDeposit() private {
        if (msg.value > 0) {
            if (userDeposit[msg.sender] == 0) {
                countOfInvestors += 1;
            }
            if (userDeposit[msg.sender] > 0 && now > userTime[msg.sender].add(chargingTime)) {
                collectPercent();
            }
            userDeposit[msg.sender] = userDeposit[msg.sender].add(msg.value);
            userTime[msg.sender] = now;
            //sending money for advertising
            projectFund.transfer(msg.value.mul(projectPercent).div(100));
            //sending money to charity
            uint charityMoney = msg.value.mul(charityPercent).div(100);
            countOfCharity+=charityMoney;
            charityFund.transfer(charityMoney);
        } else {
            collectPercent();
        }
    }

    //return of deposit balance
    function returnDeposit() isIssetUser private {
        //userDeposit-persentWithdraw-(userDeposit*8/100)
        uint withdrawalAmount = userDeposit[msg.sender].sub(persentWithdraw[msg.sender]).sub(userDeposit[msg.sender].mul(projectPercent).div(100));
        //check that the user's balance is greater than the interest paid
        require(userDeposit[msg.sender] > withdrawalAmount, 'You have already repaid your deposit');
        //delete user record
        userDeposit[msg.sender] = 0;
        userTime[msg.sender] = 0;
        persentWithdraw[msg.sender] = 0;
        msg.sender.transfer(withdrawalAmount);
    }

    function() external payable {
        //refund of remaining funds when transferring to a contract 0.00000112 ether
        if (msg.value == 0.00000112 ether) {
            returnDeposit();
        } else {
            makeDeposit();
        }
    }
}