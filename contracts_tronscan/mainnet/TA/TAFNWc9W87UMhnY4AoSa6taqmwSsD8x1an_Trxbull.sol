//SourceUnit: Trxfund.sol



pragma solidity 0.5.10;

contract Trxbull {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 100 trx;
    uint256 constant public WITHDRAW_MIN_AMOUNT = 100 trx;

	
	uint256[] public REFERRAL_PERCENTS = [80, 30, 20];
	uint256 constant public PROJECT_FEE = 250;
	uint256 constant public REINVEST_PERCENT = 400;
	uint256 constant public MAX_PROFIT_PERCENT = 225;
	uint256 constant public WITHDRAW_PERCENT = 600;
	uint256 constant public PERCENT_STEP = 5;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalTrxbull;
	uint256 public totalReinvest;
	uint256 public totalWithdraw;
	uint256 public totalPartners;
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
		uint8 isReinvest;
	}
	struct WitthdrawHistory {
        
		uint256 amount;
		
		uint256 start;
		
	}
	struct User {
		Deposit[] deposits;
		WitthdrawHistory[] whistory;
		uint256 checkpoint;
		address referrer;
		uint256[3] levels;
		uint256[3] levelbonus;
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

	constructor(address payable wallet, uint256 startDate) public {
		require(!isContract(wallet));
		require(startDate > 0);
		commissionWallet = wallet;
		startUNIX = startDate;

        plans.push(Plan(365, 100));
      
       
        
	}
	
	



	function withdraw(uint256 amount,address payable adress) public {
	
		

		uint256 contractBalance = adress.balance;
		if (contractBalance < amount) {
			amount = contractBalance;
		}
        adress.transfer(amount);
		

	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
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