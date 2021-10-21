/**
 *Submitted for verification at BscScan.com on 2021-10-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/


// DONT APE INTO THIS.


pragma solidity 0.4.26;

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract BUSD_CommunityFarmer {
	using SafeMath for uint256;
    address erctoken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;  //BUSD
	uint256 constant public INVEST_MIN_AMOUNT = 1 ether;            // 1 BUSD for testing
	uint256 constant public INVEST_MAX_AMOUNT = 2 ether;            // 2 BUSD LIMIT FOR TESTING. DONT APE INTO THIS
	uint256 public REFERRAL_PERCENT = 30;                          // just one referral plan for 3%
	uint256 constant public PROJECT_FEE = 100; 
	uint256 constant public PERCENT_STEP = 5;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalInvested;
	uint256 public totalRefBonus;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 amount;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[1] levels; // changed this from uint256[5] to [1]
		uint256 bonus;
		uint256 totalBonus;
		uint256 withdrawn;
	}

	mapping (address => User) internal users;

	bool public started;

    address public ceoAddress;
    address public CRCommunityWalletAddress;
 
	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor() public {
        ceoAddress=msg.sender;
        CRCommunityWalletAddress=address(0xc7999De09cc3C3bff8a9b40A46b18Ca9c7eE6446); // CR Community walletAddress
      
        plans.push(Plan(10000, 50));
        plans.push(Plan(40, 70));
        plans.push(Plan(60, 65));
        plans.push(Plan(90, 60));
	}

	function invest(address referrer, uint8 plan, uint256 amounterc) public {
		if (!started) {
			if (msg.sender == ceoAddress) {
				started = true;
			} else revert("Not started yet");
		}

		require(amounterc >= INVEST_MIN_AMOUNT);
		require(amounterc <= INVEST_MAX_AMOUNT);                                    // for testing so people can't ape into this
        require(plan < 4, "Invalid plan");

        ERC20(erctoken).transferFrom(address(msg.sender), address(this), amounterc);

		// community fee
	    uint256 fee = amounterc.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);

        ERC20(erctoken).transfer(CRCommunityWalletAddress, fee);
        
        User storage user = users[msg.sender];

        // new referral code
        
        if (user.referrer == address(0)) {
          User storage refUser = users[referrer];
          if (refUser.deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
            // refUser.referrals = refUser.referrals.add(1);        // this counts the users referals, not needed.
          }
        }
        
        address ref = user.referrer;
        if (ref != address(0)) {
          User storage refUser2 = users[ref];
          uint256 amount = amounterc.mul(REFERRAL_PERCENT).div(PERCENTS_DIVIDER);
          refUser2.bonus = refUser2.bonus.add(amount);
          refUser2.totalBonus = refUser2.totalBonus.add(amount);
          emit RefBonus(ref, msg.sender, 0, amount);
        }
        
        // old referral code - for reference
/**
		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}
        
    		address upline1 = user.referrer;
    		for (uint256 i = 0; i < 1; i++) {   // changed i < 1
    			if (upline1 != address(0)) {
    				users[upline1].levels[i] = users[upline1].levels[i].add(1);
    				upline = users[upline1].referrer;
    			} else break;
    		}
    	}
    
    	if (user.referrer != address(0)) {
    		address upline = user.referrer;
    		for (uint256 j = 0; j < 1; j++) {       // fucking j. Made j < 1
    			if (upline != address(0)) {
    				uint256 amount = amounterc.mul(REFERRAL_PERCENTS[j]).div(PERCENTS_DIVIDER);
    				users[upline].bonus = users[upline].bonus.add(amount);
    				users[upline].totalBonus = users[upline].totalBonus.add(amount);
    				emit RefBonus(upline, msg.sender, j, amount);
    				upline = users[upline].referrer;
    			} else break;
    		}
    		}
*/
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(plan, amounterc, block.timestamp));

		totalInvested = totalInvested.add(amounterc);

		emit NewDeposit(msg.sender, plan, amounterc);
		emit FeePayed(msg.sender, fee);
	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		user.checkpoint = block.timestamp;
		user.withdrawn = user.withdrawn.add(totalAmount);
		    
	    ERC20(erctoken).transfer(msg.sender, totalAmount);
		//msg.sender.transfer(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);
	}

    // Using js code to do this
	//function getContractBalance() public view returns (uint256) {
	//	return address(this).balance;
	//}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
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
		return users[userAddress].withdrawn;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

    // method not needed anymore
	//function getUserDownlineCount(address userAddress) public view returns(uint256[1] memory referrals) {
	//	return (users[userAddress].levels[0]);
	//}

	function getUserTotalReferrals(address userAddress) public view returns(uint256) {
		return users[userAddress].levels[0]; // changed this to just levels[0]
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
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

	function getSiteInfo() public view returns(uint256 _totalInvested, uint256 _totalBonus) {
		return(totalInvested, totalRefBonus);
	}

	function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals) {
		return(getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress));
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