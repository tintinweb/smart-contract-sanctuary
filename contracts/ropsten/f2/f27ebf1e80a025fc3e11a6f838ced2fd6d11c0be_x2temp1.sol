pragma solidity ^0.4.25;

/**
 *  x2temp1 contract
 *
 *	PERCENTS: 	 
 * 		0.21% - 0.29% per hour (5.0% - 7.0% per day)
 *
 *  	Contract balance          		Percent per day
 *       	 < 1000                   	~5.0%		(0.208% per hour)
 *    	1000 - 1500                 	~5.5%		(0.229% per hour)
 *    	1500 - 2000                 	~6.0%		(0.250% per hour)
 *    	2000 - 2500                 	~6.5%		(0.271% per hour)
 *      	>= 2500                   	~7.0%		(0.292% per hour)
 *
 *	ADVERTISING: 5%
 *
 * 	SERVICE: 2%
 *
 *  MAXIMUM RETURN IS BOUNDED BY X2.
 *
 *	REFERRERS:
 *		3% of your deposit - bonus for referrer
 *		2% cashback if referrer is specified
 *
 *  INSTRUCTIONS:
 *
 *  TO INVEST: send ETH to contract address
 *  TO WITHDRAW INTEREST: send 0 ETH to contract address
 *  TO REINVEST AND WITHDRAW INTEREST: send ETH to contract address
 *
 */
 
 /**
 *	До возврата вложенных инвестиций
 *	50 					- +4.0%						(0.167% per hour)
 *	51-100				- +3.5%						(0.146% per hour)
 *	101-150				- +3.0%						(0.125% per hour)
 *	151-200				- +2.5%						(0.104% per hour)
 *	201-250				- +2.0%						(0.083% per hour)
 *	> 250				- +0.0%						(0.000% per hour)
 *	
 *
 */
 
 
 
 
 
contract x2temp1 {
    
	// For safe math operations
    using SafeMath for uint;
	
	// Investor structure
	struct Investor
    {
        uint deposit;						// Total user investment
		uint datetime;						// Datetime last payment
		uint paid;							// Interest paid to Investor
		uint bonus;							// Bonus rate
        address referrer;					// Referrer address
    }

    // Array of investors
    mapping(address => Investor) public investors;

    // Fund to transfer percent for advertising
    address private constant ADDRESS_ADV = 0xCcf71Cb20d462C9d2BA7974204354857DeeE7d7C;
    // Fund to transfer percent for service
    address private constant ADDRESS_SERV = 0x08AEffB3B764431720c93888171caBB7906F945d;
	
	// Percent for a advertising foundation
    uint private constant PERCENT_ADV_FUND = 5000;
	// Percent for a service foundation
    uint private constant PERCENT_SERV_FUND = 2000;
	
	// Peferral cashback percent
	uint private constant REFERRAL_CASHBACK = 2000;
	// Peferrer bonus percent
	uint private constant REFERRER_BONUS = 3000;
    
	// Time through which you can take dividends
    uint private constant DIVIDENDS_TIME = 10 minutes;		// 1 hours
    // All percent should be divided by this
    uint private constant PERCENT_DIVIDER = 100000;
	
	// Users ranges for bonus rate
	uint private constant RANGE_1 = 1;						// 100
	uint private constant RANGE_2 = 2;						// 200
	uint private constant RANGE_3 = 3;						// 300
	uint private constant RANGE_4 = 4;						// 400
	uint private constant RANGE_5 = 5;						// 500
	
	uint private constant BONUS_1 = 167;
	uint private constant BONUS_2 = 146;
	uint private constant BONUS_3 = 125;
	uint private constant BONUS_4 = 104;
	uint private constant BONUS_5 = 83;
	

    uint public investors_count = 0;
	uint public transaction_count = 0;
	uint public last_payment_date = 0;
	uint public paid_by_fund = 0;

    modifier isIssetUser() {
        require(investors[msg.sender].deposit > 0, "Deposit not found");
        _;
    }

    modifier timePayment() {
        require(now >= investors[msg.sender].datetime.add(DIVIDENDS_TIME), "Too fast payout request");
        _;
    }

	// Entry point
	function() external payable {

		processDeposit();

    }
	
	
	// Start process
	function processDeposit() private {
        
		if (msg.value > 0) {
			
			if (investors[msg.sender].deposit == 0) {
                
				// Increase investors count
				investors_count += 1;
				investors[msg.sender].bonus = getBonusPercentRate();
				
				// For Referrers bonus & Referrals cashback
				address referrer = bytesToAddress(msg.data);
				if (investors[referrer].deposit > 0 && referrer != msg.sender && investors[msg.sender].referrer == 0x0) {
					_payoutReferr(msg.sender, referrer);
				}
								
            }
			
			if (investors[msg.sender].deposit > 0 && now >= investors[msg.sender].datetime.add(DIVIDENDS_TIME)) {
                processPayout();
            }

			investors[msg.sender].deposit += msg.value;
            investors[msg.sender].datetime = now;
			transaction_count += 1;
		} else {
            processPayout();
        }
		
    }
	
	// For Referrers bonus & Referrals cashback
	function _payoutReferr(address referral, address referrer) private {
		investors[referral].referrer = referrer;
		uint r_cashback = msg.value.mul(REFERRAL_CASHBACK).div(PERCENT_DIVIDER);
		uint r_bonus = msg.value.mul(REFERRER_BONUS).div(PERCENT_DIVIDER);
		referral.transfer(r_cashback);
		referrer.transfer(r_bonus);
	}
	
    // Return of interest on the deposit
    function processPayout() isIssetUser timePayment internal {
        if (investors[msg.sender].deposit.mul(2) <= investors[msg.sender].paid) {
            _delete(msg.sender);
		} else {
            uint payout = getTotalInterestAmount(msg.sender);
            _payout(msg.sender, payout);
        }
    }
	
	// Calculation total amount to transfer
    function getTotalInterestAmount(address addr) public view returns(uint) {
		
		uint balance_percent = getBalancePercentRate();
		uint amount_per_period = investors[addr].deposit.mul(balance_percent + investors[addr].bonus).div(PERCENT_DIVIDER);
		uint period_count = now.sub(investors[addr].datetime).div(DIVIDENDS_TIME);
		uint total_amount = amount_per_period.mul(period_count);
		
		// Subtract the extra bonus amount
		total_amount = subtractAmount(addr, amount_per_period, period_count, total_amount);
		
		return total_amount;
    }
	
	// Subtract the extra bonus amount
	function subtractAmount(address addr, uint amount_per_period, uint period_count, uint total_amount) public view returns(uint) {
		
		if (investors[addr].paid.add(total_amount) > investors[addr].deposit && investors[addr].bonus > 0) {
			
			uint delta_amount = investors[addr].deposit - investors[addr].paid;
			uint delta_period = delta_amount.div(amount_per_period);
			
			uint subtract_period = period_count - delta_period;
			uint subtract_amount_per_period = investors[addr].deposit.mul(investors[addr].bonus).div(PERCENT_DIVIDER);
			uint subtract_amount = subtract_amount_per_period.mul(subtract_period);
			
			total_amount -= subtract_amount;
			
		}
		
		return total_amount;
	}
	
	// Calculation transfer amounts for every address
    function _payout(address addr, uint amount) private {
		
		// If the amount of payments exceeded the deposit
		if (investors[addr].paid.add(amount) > investors[addr].deposit && investors[addr].bonus > 0) {
			investors[addr].bonus = 0;
		}

        // To Investor (w/o tax)
        uint investor_amount = amount.mul(PERCENT_DIVIDER - PERCENT_ADV_FUND - PERCENT_SERV_FUND).div(PERCENT_DIVIDER);
        investors[addr].paid += investor_amount;
        investors[addr].datetime = now;
        
		// To Advertising
        uint adv_amount = amount.mul(PERCENT_ADV_FUND).div(PERCENT_DIVIDER);
        
		// To Service
        uint serv_amount = amount.mul(PERCENT_SERV_FUND).div(PERCENT_DIVIDER);

        paid_by_fund += amount;
		last_payment_date = now;
		
		// Send money
        ADDRESS_ADV.transfer(adv_amount);
        ADDRESS_SERV.transfer(serv_amount);
        addr.transfer(investor_amount);
		
    }
	
    // Calculation of the current interest rate on the deposit
    function getBalancePercentRate() public view returns(uint) {
        
		// Current contract balance
        uint balance = getBalance();

        //calculate percent rate
        if (balance < 1000 ether) {
            return 208;
        }
        if (balance < 1500 ether) {
            return 229;
        }
		if (balance < 2000 ether) {
            return 250;
        }
		if (balance < 2500 ether) {
            return 271;
        }

        return 292;
    }
	
	// Calculation of the current interest rate on the deposit
    function getBonusPercentRate() public view returns(uint) {
        
		if (investors_count <= RANGE_1) {
			return BONUS_1;
		}
		if (investors_count <= RANGE_2) {
			return BONUS_2;
		}
		if (investors_count <= RANGE_3) {
			return BONUS_3;
		}
		if (investors_count <= RANGE_4) {
			return BONUS_4;
		}
		if (investors_count <= RANGE_5) {
			return BONUS_5;
		}
		
		return 0;
    }
	
	// Return current contract balance
    function getBalance() public view returns(uint) {
        uint balance = address(this).balance;
		return balance;
	}
	
    // Reset Investor data
    function _delete(address addr) private {
        investors[addr].deposit = 0;
		investors[addr].datetime = 0;
		investors[addr].paid = 0;
		investors[addr].bonus = 0;
    }
	
	function bytesToAddress(bytes bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
	
}

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