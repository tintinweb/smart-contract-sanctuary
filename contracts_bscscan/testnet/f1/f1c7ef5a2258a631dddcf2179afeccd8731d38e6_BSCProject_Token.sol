/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract BSCProject_Token {
	using SafeMath for uint256;
	
	IBEP20 public token;
	uint256 public INVEST_MIN_AMOUNT = 5e16;
	uint256 constant public BASE_PERCENT = 50;
	uint256[] public REFERRAL_PERCENTS = [50, 20, 10];
	uint256 constant public MARKETING_FEE = 10;
//	uint256 constant public PROJECT_FEE = 40;
//	uint256 constant public FUND_FEE=40;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days; //1 days

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint256 public startUNIX;

	address payable public marketingAddress;
//	address payable public fundAddress;
//	address payable public projectAddress;

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256 bonus;
		uint256 refs;
	}

	mapping (address => User) internal users;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable marketingAddr, uint256 startDate, IBEP20 tokenAddr) public {
		require(!isContract(marketingAddr));
		token = tokenAddr;
		marketingAddress = marketingAddr;
//		projectAddress = projectAddr;
//		fundAddress = fundAddr;
		startUNIX = startDate;
	}
	
	function FeePayout(uint256 msgValue) internal{
    
    token.transfer(marketingAddress, (msgValue.mul(MARKETING_FEE).div(PERCENTS_DIVIDER)));
//    token.safeTransfer(fundAddress, (msgValue.mul(FUND_FEE).div(PERCENTS_DIVIDER)));
//    token.safeTransfer(projectAddress, (msgValue.mul(PROJECT_FEE).div(PERCENTS_DIVIDER)));

    emit FeePayed(msg.sender,msgValue.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
    }

	function invest(address referrer, uint256 depAmount) public {
	    require(block.timestamp >= startUNIX ,"Not Launch");
		require(depAmount >= INVEST_MIN_AMOUNT);
		
		token.transferFrom(msg.sender, address(this), depAmount);
	    FeePayout(depAmount);

		User storage user = users[msg.sender];
		
		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}
		    
		}
		uint256 refsamount;
         if(user.referrer != address(0)){
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = depAmount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].refs = users[upline].refs.add(1);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else{
				    uint256 amount = depAmount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
				    refsamount = refsamount.add(amount);
				}
			}
			if (refsamount > 0){
			token.transfer(marketingAddress, (refsamount.div(3)));
//            token.safeTransfer(fundAddress, (refsamount.div(3)));
//            token.safeTransfer(projectAddress, (refsamount.div(3)));
			}
         }else{
		    uint256 refsbkp = 80;
		    uint256 amount = depAmount.mul(refsbkp).div(PERCENTS_DIVIDER);
            token.transfer(marketingAddress, (amount.div(3)));
//            token.safeTransfer(fundAddress, (amount.div(3)));
//            token.safeTransfer(projectAddress, (amount.div(3)));
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(depAmount, 0, block.timestamp));

		totalInvested = totalInvested.add(depAmount);
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, depAmount);

	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
					dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
		}

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			user.bonus = 0;
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = token.balanceOf(address(this));
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;
		
		token.transfer(payable(msg.sender), totalAmount);

		totalWithdrawn = totalWithdrawn.add(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);

	}
	
//	function updateStartUNIX(uint256 unixtime) public onlyOwner{
//	    startUNIX = unixtime;
	    
//	}
	
//	function updateFundAddress(address payable newAddress) public onlyOwner{
//	    fundAddress = newAddress;
	    
//	}
	
//	function updateMarketingAddress(address payable newAddress) public onlyOwner{
//	    marketingAddress = newAddress;
	    
//	}
	
//	function updateProjectAddress(address payable newAddress) public onlyOwner{
//	    projectAddress = newAddress;
	    
//	}

	function getContractBalance() public view returns (uint256) {
	    return token.balanceOf(address(this));
	}
	

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
					dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);

				/// no update of withdrawn because that is view function

			}

		}

		return totalDividends;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}
	
	function getUserReferralRefs(address userAddress) public view returns(uint256) {
		return users[userAddress].refs;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(2)) {
				return true;
			}
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
	    User storage user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}

		return amount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].withdrawn);
		}

		return amount;
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