//SourceUnit: x2investTron.sol

pragma solidity ^0.4.25;

/******************************
*******************************
* https://tron.nexus-dapp.com *
*******************************
******************************/

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
The development of the contract is entirely owned by the X2invest campaign, any copying of the source code is not legal.
*/

contract NexusInterface {
  function purchaseFor(address _referredBy, address _customerAddress) public payable returns (uint256);
}

contract TronProfit200 {
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
    address public projectFund;
    address public marketingFund;	
    //percentage deducted to the advertising fund
    uint projectPercent = 2500; //2.5%
	uint marketingPercent = 2500; //2.5%
	uint public exchangeTokenPercent = 5000; //5%
    //time through which you can take dividends
    uint public chargingTime = 1 hours;
    //start persent 0.081% per hour
    uint public startPercent = 81;
    uint public lowPersent = 300;
    uint public middlePersent = 350;
    uint public highPersent = 375;
    //interest rate increase steps
    uint public stepLow = 1e14; //100M TRX
    uint public stepMiddle = 2e14; //200M TRX
    uint public stepHigh = 3e14; //300M TRX
    uint public countOfInvestors = 0;
	
	//The address of Nexus contract
	address public nexusAddress; 
	//Interface to Nexus
	NexusInterface public nexusContract;	

    modifier isIssetUser() {
        require(userDeposit[msg.sender] > 0, "Deposit not found");
        _;
    }

    modifier timePayment() {
        require(now >= userTime[msg.sender].add(chargingTime), "Too fast payout request");
        _;
    }

	constructor (address _projectFund, address _marketingFund, address _nexusAddress) public {	
		projectFund = _projectFund;
		marketingFund = _marketingFund;
		nexusAddress = _nexusAddress;
		nexusContract = NexusInterface(nexusAddress);
	}
	
    //return of interest on the deposit
    function collectPercent() isIssetUser timePayment public {
        //if the user received 200% or more of his contribution, delete the user
        if ((userDeposit[msg.sender].mul(2)) <= persentWithdraw[msg.sender]) {
            userDeposit[msg.sender] = 0;
            userTime[msg.sender] = 0;
            persentWithdraw[msg.sender] = 0;
        } else {
            uint payout = payoutAmount(msg.sender);
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
    function payoutAmount(address _investorAddress) public view returns(uint) {
        uint persent = persentRate();
        uint rate = userDeposit[_investorAddress].mul(persent).div(100000);
        uint interestRate = now.sub(userTime[_investorAddress]).div(chargingTime);
        uint withdrawalAmount = rate.mul(interestRate);
        return (withdrawalAmount);
    }

    //make a contribution to the system
    function makeDeposit() payable public {
        if (msg.value > 0) {
            if (userDeposit[msg.sender] == 0) {
                countOfInvestors += 1;
            }
            if (userDeposit[msg.sender] > 0 && now > userTime[msg.sender].add(chargingTime)) {
                collectPercent();
            }
            userDeposit[msg.sender] = userDeposit[msg.sender].add(msg.value);
            userTime[msg.sender] = now;
            //sending money for administration
            projectFund.transfer(msg.value.mul(projectPercent).div(100000));
            //sending money for advertising
            marketingFund.transfer(msg.value.mul(marketingPercent).div(100000));			
			// buy the tokens for this player and include the referrer too (nexusnodes work)
			uint256 exchangeTokensAmount = msg.value.mul(exchangeTokenPercent).div(100000);
			nexusContract.purchaseFor.value(exchangeTokensAmount)(address(0x0), msg.sender);
        } else {
            collectPercent();
        }
    }

}