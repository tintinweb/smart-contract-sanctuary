/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

/*
    {DISCRIPTION}
        BNBMagic - Community Experimental yield farm on Binance Smart Chain.

    {USAGE}
      1) Connect any supported wallet
      2) Choose one of the tariff plans, enter the BNB amount (0.01 BNB minimum) using our website "Stake" button
      3) Wait for your earnings
      4) Withdraw earnings any time using our website "Withdraw" button

    {CONDITION}
        - Minimal deposit 0.01 BNB, no maximal limit
        - Total income: based on your plan [2% to 5% daily]
        - Earning every second, withdraw any time

    {DISTREBUTION}
       - 90% Platform main balance, using for participants payouts, affiliate program bonuses
       - 10% Advertising and promotion expenses, Support work, technical functioning, administration fee

    {INFO}
    The principal deposit cannot be withdrawn, the only return users can get are daily dividends and referral rewards. 
    Payments is possible only if contract balance have enough BNB. Please analyze the transaction history and balance of the smart contract 
    before investing. High risk - high profit, DYOR
 */

 pragma solidity 0.5.10;

contract BNBMagic{
    using SafeMath for uint256;

    uint256 constant public MIN_AMOUNT = 1e16; //0.01BNB
    uint256 constant public ADMINISTRATION_FEE = 100;
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public TIME_STEP = 1 days;
    address payable public commissionWallet;
    
    mapping (address => User) internal users;

    uint256 totalInvested;

    struct Deposit {
        uint8 plan;
        uint256 amount;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        uint256[5] levels;
        uint256 bonus;
        uint256 totalBonus;
        uint256 withdrawn;
    }
    Plan[] internal plans;
    struct Plan {
        uint256 time;
        uint256 percent;
    }

    //EVENTS
    event Newbie(address user);
    event NewDeposit(address indexed user, uint8 plan, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);

    constructor(address payable creatorAddress) public{
        commissionWallet = creatorAddress;

        plans.push(Plan(10000, 20)); //2% Daily unlimited runtime
        plans.push(Plan(25, 50));  // 5% for 25 days
        plans.push(Plan(40, 40));  //4% for 40 days
        plans.push(Plan(60, 35)); //3,5% for 60 day
        plans.push(Plan(100, 30)); //3% for 100 days
    }

    function invest(uint8 plan) public payable {
        require(msg.value >= MIN_AMOUNT);
        require(plan < 5, "Invalid plan");

        uint256 fee = msg.value.mul(ADMINISTRATION_FEE).div(PERCENTS_DIVIDER);
        commissionWallet.transfer(fee);
        emit FeePayed(msg.sender, fee);

        User storage user = users[msg.sender];
        if(user.deposits.length == 0){
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }
        user.deposits.push(Deposit(plan, msg.value, block.timestamp));
        totalInvested = totalInvested.add(msg.value);
        emit NewDeposit(msg.sender, plan, msg.value);
    }

    function withdraw() public {
        User storage user = users[msg.sender];
        uint256 totalAmount = getUserDividends(msg.sender);

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = address(this).balance;
        if(contractBalance < totalAmount){
            user.bonus = totalAmount.sub(contractBalance);
            user.totalBonus = user.totalBonus.add(user.bonus);
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;
        user.withdrawn = user.withdrawn.add(totalAmount);

        msg.sender.transfer(totalAmount);
        emit Withdrawn(msg.sender, totalAmount);
    }

    function getUserDividends(address userAdress) public view returns (uint256){
        User storage user = users[userAdress];
        uint256 totalAmount;
        for(uint256 i = 0; i < user.deposits.length; i++){
            uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(1 days));
            if(user.checkpoint < finish){
                uint256 share = user.deposits[i].amount.mul(plans[user.deposits[i].plan].percent).div(PERCENTS_DIVIDER);
                uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
                uint256 to = finish < block.timestamp ? finish : block.timestamp;
                if(from < to){
                    totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
                }
            }
        }
        return totalAmount;
    }

    function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

    function getUserTotalWithdrawn(address user) public view returns (uint256){
        return users[user].withdrawn;
    }

    function getUserCheckpoint(address user) public view returns (uint256){
        return users[user].checkpoint;
    }

    function getUserDownlineCount(address user) public view returns(uint256[5] memory referrals) {
		return (users[user].levels);
	}

    function getUserAvailable(address user) public view returns(uint256) {
		return getUserDividends(user);
	}

	function getUserAmountOfDeposits(address user) public view returns(uint256) {
		return users[user].deposits.length;
	}

	function getUserTotalDeposits(address user) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[user].deposits.length; i++) {
			amount = amount.add(users[user].deposits[i].amount);
		}
	}

    function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = plans[plan].percent;
		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(1 days));
	}

    function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalWithdrawn){
		return(getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress));
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

	function getSiteInfo() public view returns(uint256 _totalInvested) {
		return(totalInvested);
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