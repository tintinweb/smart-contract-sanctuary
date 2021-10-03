/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

// SPDX-License-Identifier: MIT
// Website : www.bnbjungle.com


pragma solidity ^0.5.10;

contract BNBJungle{
	using SafeMath for uint256;

    uint256 public BANNA_TO_HARVEST=2592000;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address payable public ceoAddress;
    address payable public ceoAddress2;
    
    address public owner;
    mapping (address => uint256) public bananaMonkeys;
    mapping (address => uint256) public claimedBananas;
    mapping (address => uint256) public lastReinvest;
    mapping (address => address) public referrals;
    uint256 public marketBananas;
    
    
    uint256 constant public INVEST_MIN_AMOUNT = 5e16; // 0.05 bnb
	uint256[] public REFERRAL_PERCENTS = [70, 30, 15, 10, 5];
	uint256 constant public PROJECT_FEE = 100;
	uint256 constant public PERCENT_STEP = 5;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	bool public paused = true;
	uint256 public totalInvested;
	uint256 public totalRefBonus;
	
	Plan[] internal plans;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

	struct Deposit {
        uint8 plan;
		uint256 amount;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[5] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 withdrawn;
	}
	
    address payable public commissionWallet;


	mapping (address => User) internal users;
	bool public started;

 
  	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	
  
  
  
    constructor(address payable wallet) public{
        ceoAddress=msg.sender;
        ceoAddress2=address(wallet);
        require(!isContract(wallet));
		commissionWallet = wallet;
        plans.push(Plan(10000, 20));
        plans.push(Plan(40, 40));
        plans.push(Plan(60, 35));
        plans.push(Plan(90, 30));
        owner = msg.sender;

    }
    
    
    	function planInvest(address referrer, uint8 plan) public payable {
       require(owner == msg.sender, "You cannot Start Function.");
        require(paused == false, "Contract Paused");		
        if (!started) {
			if (msg.sender == commissionWallet) {
				started = true;
			} else revert("Not started yet");
		}
		require(msg.value >= INVEST_MIN_AMOUNT);
        require(plan < 4, "Invalid plan");

		uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		commissionWallet.transfer(fee);
		emit FeePayed(msg.sender, fee);

		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(plan, msg.value, block.timestamp));

		totalInvested = totalInvested.add(msg.value);

		emit NewDeposit(msg.sender, plan, msg.value);
	}
	
	
	function planwithdraw() public payable{
	    require(owner == msg.sender, "You cannot Start Function.");
        require(paused == false, "Contract Paused");	
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			user.bonus = totalAmount.sub(contractBalance);
			user.totalBonus = user.totalBonus.add(user.bonus);
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;
		user.withdrawn = user.withdrawn.add(totalAmount);
 
		msg.sender.transfer(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);
	}
    

        function setPaused(bool _paused) public {
        require(msg.sender == owner, "You are not the owner");
        paused = _paused;
    }
    
    	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
	     require(owner == msg.sender, "You cannot Start Function.");
        require(paused == false, "Contract Paused");	
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
	     require(owner == msg.sender, "You cannot Start Function.");
        require(paused == false, "Contract Paused");	
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(1 days));
			if (user.checkpoint < finish) {
				uint256 share = user.deposits[i].amount.mul(plans[user.deposits[i].plan].percent).div(PERCENTS_DIVIDER);
				uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
				uint256 to = finish < block.timestamp ? finish : block.timestamp;
				if (from < to) {
					totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
				}
			}
		}

		return totalAmount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
	     require(owner == msg.sender, "You cannot Start Function.");
        require(paused == false, "Contract Paused");	
		return users[userAddress].withdrawn;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
	     require(owner == msg.sender, "You cannot Start Function.");
        require(paused == false, "Contract Paused");	
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
	     require(owner == msg.sender, "You cannot Start Function.");
        require(paused == false, "Contract Paused");	
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256[5] memory referralsPlan) {
	     require(owner == msg.sender, "You cannot Start Function.");
        require(paused == false, "Contract Paused");	
		return (users[userAddress].levels);
	}

	function getUserTotalReferrals(address userAddress) public view returns(uint256) {
	     require(owner == msg.sender, "You cannot Start Function.");
        require(paused == false, "Contract Paused");	
		return users[userAddress].levels[0]+users[userAddress].levels[1]+users[userAddress].levels[2]+users[userAddress].levels[3]+users[userAddress].levels[4];
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
	     require(owner == msg.sender, "You cannot Start Function.");
        require(paused == false, "Contract Paused");	
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
	     require(owner == msg.sender, "You cannot Start Function.");
        require(paused == false, "Contract Paused");	
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
	     require(owner == msg.sender, "You cannot Start Function.");
        require(paused == false, "Contract Paused");	
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
	     require(owner == msg.sender, "You cannot Start Function.");
        require(paused == false, "Contract Paused");	
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
	     require(owner == msg.sender, "You cannot Start Function.");
        require(paused == false, "Contract Paused");	
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
	     require(owner == msg.sender, "You cannot Start Function.");
        require(paused == false, "Contract Paused");	
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
	     require(owner == msg.sender, "You cannot Start Function.");
        require(paused == false, "Contract Paused");	
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = plans[plan].percent;
		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(1 days));
	}

	function getSiteInfo() public view returns(uint256 _totalInvested, uint256 _totalBonus) {
	     require(owner == msg.sender, "You cannot Start Function.");
        require(paused == false, "Contract Paused");	
		return(totalInvested, totalRefBonus);
	}

	function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals) {
	     require(owner == msg.sender, "You cannot Start Function.");
        require(paused == false, "Contract Paused");	
		return(getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress));
	}
	
	 function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    
    function sellBananas() public payable{
        require(initialized);
        uint256 hashBnb=getMyBananas();
        uint256 bannasvalue=calculateBananaSell(hashBnb);
        uint256 fee=devFee(bannasvalue);
        uint256 fee2=fee/2;
        claimedBananas[msg.sender]=0;
        lastReinvest[msg.sender]=now;
        marketBananas=SafeMath.add(marketBananas,hashBnb);
        ceoAddress.transfer(fee2);
        ceoAddress2.transfer(fee-fee2);
        msg.sender.transfer(SafeMath.sub(bannasvalue,fee));
    }
     function reInvestBananas(address ref) public{
        require(initialized);
        if(ref == msg.sender) {
            ref = address(0);
        }
        if(referrals[msg.sender]==address(0) && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 bananasused=getMyBananas();
        uint256 newMonkeys=SafeMath.div(bananasused,BANNA_TO_HARVEST);
        bananaMonkeys[msg.sender]=SafeMath.add(bananaMonkeys[msg.sender],newMonkeys);
        claimedBananas[msg.sender]=0;
        lastReinvest[msg.sender]=now;
        
        claimedBananas[referrals[msg.sender]]=SafeMath.add(claimedBananas[referrals[msg.sender]],SafeMath.div(bananasused,10));
        
        marketBananas=SafeMath.add(marketBananas,SafeMath.div(bananasused,5));
    }
    function buyMonkeys(address ref) public payable{
        require(initialized);
        uint256 bananasBought=calculateMonkeysBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        bananasBought=SafeMath.sub(bananasBought,devFee(bananasBought));
        uint256 fee=devFee(msg.value);
        uint256 fee2=fee/2;
        ceoAddress.transfer(fee2);
        ceoAddress2.transfer(fee-fee2);
        claimedBananas[msg.sender]=SafeMath.add(claimedBananas[msg.sender],bananasBought);
        reInvestBananas(ref);
    }
    
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateBananaSell(uint256 bananas) public view returns(uint256){
        return calculateTrade(bananas,marketBananas,address(this).balance);
    }
    function calculateMonkeysBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketBananas);
    }
    function calcuateMonkeysBuySimple(uint256 eth) public view returns(uint256){
        return calculateMonkeysBuy(eth,address(this).balance);
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
    function seedJungle() public payable{
        require(marketBananas==0);
        initialized=true;
        marketBananas=259200000000;
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMyMonkeys() public view returns(uint256){
        return bananaMonkeys[msg.sender];
    }
   
    function getMyBananas() public view returns(uint256){
        return SafeMath.add(claimedBananas[msg.sender],getBanansSinceLastReinvest(msg.sender));
    }
    function getBanansSinceLastReinvest(address adr) public view returns(uint256){
        uint256 secondsPassed=min(BANNA_TO_HARVEST,SafeMath.sub(now,lastReinvest[adr]));
        return SafeMath.mul(secondsPassed,bananaMonkeys[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}