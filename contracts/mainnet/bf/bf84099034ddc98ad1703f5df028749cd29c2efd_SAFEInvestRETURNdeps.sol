pragma solidity 0.4 .25;

/**
 * 
 *   ---About the Project  SAFEInvestRETURNdeps
 *  Absolutely honest contract without an owner, your money is safe and no one can take it away, nobody
 *  Unique project with the possibility of withdrawal of the deposit at any time
 *  The percentage of dynamic depending on the amount of ETH deposit
 *  To withdraw interest send 0 to the address of the contract
 *  To withdraw the deposit send 0.00000911 ETH to the address of the contract
 *  Recommended gas limit 200,000
 *  Interest payments are made every 30 minutes
 *  The maximum you can get 200 percent, after which the contract will remove your address from memory
 *  If you want to withdraw the deposit ahead of time it will be taken fee 15 percent of withdrawal amount
 * 
 * 
 * 
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
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
 The SAFEInvest rebuilding fork№1
*/
contract SAFEInvestRETURNdeps {
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
    address public projectFund = 0x8C267FF25c7311046a75cdd39759Bfc3A92BAf5A;
     //wallet for a advertising fund
    address public advertisFund =  0xcbAd8699654DC5E495C8E21F7411e57210b07d54;
    //percentage deducted to the advertising fund
    uint projectPercent = 2;
    //percent for a advertising foundation
    uint advertisPercent = 3;
     //time through which you can take dividends
    uint public chargingTime = 30 minutes;
    //start persent 0.10% per hour
    uint public startPercent =120;
    uint public lowPersent = 150;
    uint public middlePersent =180;
    uint public highPersent = 195;
    //interest rate increase steps
    uint public stepLow = 10 ether;
    uint public stepMiddle = 20 ether;
    uint public stepHigh = 30 ether;
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
            //sending money to advertis
            advertisFund.transfer(msg.value.mul(advertisPercent).div(100));
                   } else {
            collectPercent();
        }
    }

    //return of deposit balance
    function returnDeposit() isIssetUser private {
        //userDeposit-persentWithdraw-(userDeposit*15/100)
        uint withdrawalAmount = userDeposit[msg.sender].sub(persentWithdraw[msg.sender]).sub(userDeposit[msg.sender].mul(projectPercent).div(100));
        //check that the user&#39;s balance is greater than the interest paid
        require(userDeposit[msg.sender] > withdrawalAmount, &#39;You have already repaid your deposit&#39;);
        //delete user record
        userDeposit[msg.sender] = 0;
        userTime[msg.sender] = 0;
        persentWithdraw[msg.sender] = 0;
        msg.sender.transfer(withdrawalAmount);
    }

    function() external payable {
        //refund of remaining funds when transferring to a contract 0.00000911 ether
        if (msg.value == 0.00000911 ether) {
            returnDeposit();
        } else {
            makeDeposit();
        }
    }
}