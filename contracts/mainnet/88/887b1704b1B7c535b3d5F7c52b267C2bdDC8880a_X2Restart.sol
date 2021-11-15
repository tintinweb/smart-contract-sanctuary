//SPDX-License-Identifier: Unlicense
pragma solidity 0.4.25;

import "./SafeMath.sol";

/**
The development of the contract is entirely owned by the X2{re}start campaign, any copying of the source code is not legal.
*/
contract X2Restart {
    //use of library of safe mathematical operations
    using SafeMath for uint256;
    // array containing information about beneficiaries
    mapping(address => uint256) public userDeposit;
    //array containing information about the time of payment
    mapping(address => uint256) public userTime;
    //array containing information on interest paid
    mapping(address => uint256) public persentWithdraw;
    //fund fo transfer percent
    address public projectFund = 0xb615E5c6d21Ae628eA4490e2653b9aEb0a3902b5;
    //wallet for a charitable foundation
    address public charityFund = 0x206448E6C7D9833af63fFe2335cfF49D5f6d0dff;
    //percentage deducted to the advertising fund
    uint256 projectPercent = 8;
    //percent for a charitable foundation
    uint256 public charityPercent = 1;
    //time through which you can take dividends
    uint256 public chargingTime = 1 hours;
    //start persent 0.25% per hour
    uint256 public startPercent = 250;
    uint256 public lowPersent = 300;
    uint256 public middlePersent = 350;
    uint256 public highPersent = 375;
    //interest rate increase steps
    uint256 public stepLow = 1000 ether;
    uint256 public stepMiddle = 2500 ether;
    uint256 public stepHigh = 5000 ether;
    uint256 public countOfInvestors = 0;
    uint256 public countOfCharity = 0;

    modifier isIssetUser() {
        require(userDeposit[msg.sender] > 0, "Deposit not found");
        _;
    }

    modifier timePayment() {
        require(
            now >= userTime[msg.sender].add(chargingTime),
            "Too fast payout request"
        );
        _;
    }

    //return of interest on the deposit
    function collectPercent() internal isIssetUser timePayment {
        address msgSender = msg.sender;
        //if the user received 200% or more of his contribution, delete the user
        if ((userDeposit[msgSender].mul(2)) <= persentWithdraw[msgSender]) {
            userDeposit[msgSender] = 0;
            userTime[msgSender] = 0;
            persentWithdraw[msgSender] = 0;
        } else {
            uint256 payout = payoutAmount();
            userTime[msgSender] = now;
            persentWithdraw[msgSender] += payout;
            msgSender.transfer(payout);
        }
    }

    //calculation of the current interest rate on the deposit
    function persentRate() public view returns (uint256) {
        //get contract balance
        uint256 balance = address(this).balance;
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
    function payoutAmount() public view returns (uint256) {
        uint256 persent = persentRate();
        uint256 rate = userDeposit[msg.sender].mul(persent).div(100000);
        uint256 interestRate = now.sub(userTime[msg.sender]).div(chargingTime);
        uint256 withdrawalAmount = rate.mul(interestRate);
        return (withdrawalAmount);
    }

    //make a contribution to the system
    function makeDeposit() private {
        address msgSender = msg.sender;
        uint256 msgValue = msg.value;
        if (msgValue > 0) {
            uint256 _userDeposit = userDeposit[msgSender];
            if (_userDeposit == 0) {
                countOfInvestors += 1;
            }
            if (
                _userDeposit > 0 && now > userTime[msgSender].add(chargingTime)
            ) {
                collectPercent();
            }
            userDeposit[msgSender] = _userDeposit.add(msgValue);
            userTime[msgSender] = now;
            //sending money for advertising
            projectFund.transfer(msgValue.mul(projectPercent).div(100));
            //sending money to charity
            uint256 charityMoney = msgValue.mul(charityPercent).div(100);
            countOfCharity += charityMoney;
            charityFund.transfer(charityMoney);
        } else {
            collectPercent();
        }
    }

    //return of deposit balance
    function returnDeposit() private isIssetUser {
        //userDeposit-persentWithdraw-(userDeposit*8/100)
        address msgSender = msg.sender;
        uint256 _withdrawalAmount = userDeposit[msgSender]
        .sub(persentWithdraw[msgSender])
        .sub(userDeposit[msgSender].mul(projectPercent).div(100))
        .sub(userDeposit[msgSender].mul(charityPercent).div(100));
        //check that the user's balance is greater than the interest paid
        require(
            userDeposit[msgSender] > _withdrawalAmount,
            "You have already repaid your deposit"
        );
        //delete user record
        userDeposit[msgSender] = 0;
        userTime[msgSender] = 0;
        persentWithdraw[msgSender] = 0;
        msgSender.transfer(_withdrawalAmount);
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

pragma solidity 0.4.25;

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

