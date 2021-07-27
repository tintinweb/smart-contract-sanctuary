/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

// SPDX-License-Identifier: MIT 

contract Ownable {
    address public owner;
    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}
pragma solidity 0.8.3;
contract earnUSDT is Ownable{
	using SafeMath for uint256;
	using SafeBEP20 for IBEP20;

    IBEP20 public token;
	uint256 constant public INVEST_MIN_AMOUNT = 3 ether; // 3 BUSD
	uint256[] internal REFERRAL_PERCENTS = [50e2, 30e2, 20e2];
	uint256[] internal AUCTION_PERCENTS = [27, 12, 6, 3, 1];
	uint256 constant public PROJECT_FEE = 20e2;
	uint256 constant public FUND_FEE = 30e2;
	uint256 constant public MARKETING_FEE = 50e2;
	uint256 constant public PERCENT_STEP = 4e2;
	uint256 constant public PERCENTS_DIVIDER = 1000e2;
	uint256 constant public DECREASE_DAY_STEP = 0.25 days; //0.25 days
    uint256 constant internal AUCTION_MIN_AMOUNT = 0.2 ether; //0.2 CAKE
    uint256 constant internal AUCTION_BONUS = 5;
    uint256 constant internal REF_STEP = 10; // 10 Refs level 
    uint256 constant internal TIME_STEP = 1 days; //1 days
    uint256 constant internal AUCTION_STEP = 20 minutes; // 20 MINUTES
    
	uint256 public totalStaked;
	uint256 public totalRefBonus;
	
	uint256 public startUNIX;
	address payable public marketingAddress;
    address payable public projectAddress;
    address payable public fundAddress;
	
    uint32 internal auctionST = uint32(block.timestamp);
    uint256 internal auctionET = (uint256(auctionST).add(AUCTION_STEP));
    uint256 internal auctionP;
    uint256 internal auctionLP;
    uint256 internal auctionB;
    uint256 internal auctionH;
    uint256 internal auctionPS;
    uint256 internal auctionC;

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
		bool force;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[3] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 apft;
        uint256 aparticipation;
        uint256 wprofits;
	}
	
    mapping(uint256 => mapping(address => uint256)) internal auds;
    mapping(uint256 => address) internal at;
    mapping(uint256 => address) internal alt;
	mapping (address => User) internal users;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	event AuctionPayout(address indexed user, uint256 amt);

	constructor(address payable marketingAddr,address payable fundAddr,uint256 startDate, IBEP20 tokenAddr) {
        require(!isContract(marketingAddr), "!marketingAddr");
		require(startDate > 0);
		token = tokenAddr;
		marketingAddress = marketingAddr;
		fundAddress = fundAddr;
        projectAddress = payable(msg.sender);
		startUNIX = startDate;

        plans.push(Plan(100, 37e2));
        plans.push(Plan(45, 47e2));
        plans.push(Plan(25, 57e2));
	}
    
    function FeePayout(uint256 amt) internal{
    uint256 mktFee = amt.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
    uint256 fundFee = amt.mul(FUND_FEE).div(PERCENTS_DIVIDER);
    uint256 prjFee = amt.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
    token.safeTransfer(marketingAddress, mktFee);
    token.safeTransfer(fundAddress, fundFee);
    token.safeTransfer(projectAddress, prjFee);
    emit FeePayed(msg.sender, mktFee.add(prjFee));
    }
  

	function invest(address referrer, uint8 plan , uint256 depAmount) public {
	    require(block.timestamp >= startUNIX ,"Not Launch");
		require(depAmount >= INVEST_MIN_AMOUNT);
        require(plan < 3, "Invalid plan");
        
        token.safeTransferFrom(msg.sender, address(this), depAmount);

		FeePayout(depAmount);

		User storage user = users[msg.sender];
		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}else{
			    user.referrer = projectAddress;
			}
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					if (users[upline].referrer == address(0)){
			        users[upline].referrer = projectAddress;
			        }
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = depAmount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
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
		
        (uint256 percent, uint256 profit, , uint256 finish) = getResult(plan, depAmount);
        user.deposits.push(Deposit(plan, percent, depAmount, profit, block.timestamp, finish, true));
		totalStaked = totalStaked.add(depAmount);
		emit NewDeposit(msg.sender, plan, percent, depAmount, profit, block.timestamp, finish);
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
        uint256 contractBalance = token.balanceOf(address(this));
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        user.checkpoint = block.timestamp;
        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                if (user.deposits[i].plan < 3) {
                    user.deposits[i].force = false;
                } else if (block.timestamp > user.deposits[i].finish) {
                    user.deposits[i].force = false;
                }
            }
        }
        user.wprofits = (user.wprofits).add(totalAmount);
        token.safeTransfer(payable(msg.sender), totalAmount);
        
        emit Withdrawn(msg.sender, totalAmount);
    }
	
    function Buyticket(uint256 depAmount) external {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        uint256 MinLimit = getticketcost();
        require(depAmount == MinLimit, "Check value ticket");
        token.safeTransferFrom(msg.sender, address(this), depAmount);
        User storage user = users[msg.sender];
        require(users[msg.sender].deposits.length > 0,"Deps first");
    if (auctionET < block.timestamp) {
            resetpools();
    }
    if (auctionH < depAmount){
            auctionH = depAmount;
        }
    if (auctionET.sub(3 minutes) < block.timestamp) {
            auctionET = (uint256(auctionET).add(3 minutes));
    }
    auctionP = auctionP.add(depAmount);
    if (msg.sender != address(0)) {
           address up = msg.sender;
           auds[auctionC][up] = depAmount;
        for(uint256 i = 0; i < 5; i++) {
                if(at[i] == address(0)) {
                at[i] = up;
                break;
            }
            if(auds[auctionC][up] > auds[auctionC][at[i]]) {
                for(uint256 j = uint256(5 - 1); j > i; j--) {
                    at[j] = at[j - 1];
                }
               at[i] = up;
                break;
            }
        }
        auctionPS++;
    }
    user.aparticipation++;
}
    
    function resetpools() public {
    if (auctionET < block.timestamp) {
        if (auctionPS > 0){
            uint256 da = auctionP;
            if (auctionB > 0){
            uint256 PBM = auctionB.mul(4).div(100);    
            da = da.add(PBM);
            auctionB = auctionB.sub(PBM);
            }
            auctionB = auctionB.add(auctionP.mul(12).div(100));
            FeePayout (auctionP);
            auctionLP = da;
            for(uint256 i = 0; i < 5; i++) {
            if(at[i] != address(0)){
            uint256 win = auctionLP.mul(AUCTION_PERCENTS[i]).div(100);
            token.safeTransfer(payable(address(uint160(at[i]))), win);
            users[at[i]].apft = (users[at[i]].apft).add(win);
            da = da.sub(win);
            emit AuctionPayout(at[i], win);
            }
        }
        da = da.sub(auctionLP.mul(39).div(100));
        if (da > 0) {
                uint256 residual = da;
                auctionB = auctionB.add(da);
                da = da.sub(residual);
            }
        for(uint256 i = 0; i < 5; i++) {
            alt[i] = at[i];
            if(at[i] != address(0)){
            at[i] = address(0);
            }
        }
        auctionP = 0;
        auctionH = 0;
        auctionPS = 0;  
        }
        auctionST = uint32(block.timestamp);
        auctionET = (uint256(auctionST).add(AUCTION_STEP));
        auctionC++;
    }
    }

   //Ticket cost 
    function getDticket() internal view returns (uint256) {
        uint256 lmt;
        
        if (auctionPS == 0) {
            lmt = AUCTION_MIN_AMOUNT;
        } else if (auctionPS >= 1) {
            lmt = auctionH.add(AUCTION_MIN_AMOUNT);
        }
        return lmt;
    }

    function getticketcost() public view returns (uint256) {
        uint256 lmt;
    if (auctionET < block.timestamp){
        lmt = AUCTION_MIN_AMOUNT;
    } else {
        lmt = getDticket();
        }
        return lmt;
    }
    
    function getUserAuctionStats(address uAds) public view returns ( uint256, uint256) {
        User storage user = users[uAds];
        return (user.aparticipation, user.apft);
    }

	function getContractBalance() public view returns (uint256) {
		return token.balanceOf(address(this));
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getPercent(uint8 plan) public view returns (uint256) {
	    uint256 userAuctionRate = getUserAuctionRate(msg.sender);
	    uint256 userRefRate = getUserRefRate(msg.sender);
		if (block.timestamp > startUNIX) {
			return plans[plan].percent.add(PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP)).add(userAuctionRate).add(userRefRate);
		} else {
			return plans[plan].percent;
		}
    }
	
	function getResult(uint8 plan, uint256 deposit) public view returns ( uint256 percent, uint256 profit, uint256 current, uint256 finish){
        percent = getPercent(plan);
        if (plan < 3) {
            profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
        } else if (plan < 6) {
            for (uint256 i = 0; i < plans[plan].time; i++) {
                profit = profit.add((deposit.add(profit)).mul(percent).div(PERCENTS_DIVIDER));
            }
        }
        current = block.timestamp;
        finish = current.add(getDecreaseDays(plans[plan].time));
    }
	
	function getUserDividends(address userAddress) public view returns (uint256){
        User memory user = users[userAddress];

        uint256 totalAmount;
        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                if (user.deposits[i].plan < 3) {
                    uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
                    uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
                    uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
                    if (from < to) {
                        uint256 planTime = plans[user.deposits[i].plan].time.mul(TIME_STEP);
                        uint256 redress = planTime.div(getDecreaseDays(plans[user.deposits[i].plan].time));
                        totalAmount = totalAmount.add(share.mul(to.sub(from)).mul(redress).div(TIME_STEP));
                    }
                } else if (block.timestamp > user.deposits[i].finish) {
                    totalAmount = totalAmount.add(user.deposits[i].profit);
                }
            }
        }
        return totalAmount;
    }
	
	function getDecreaseDays(uint256 planTime) public view returns (uint256) {
	    uint256 None = planTime.mul(TIME_STEP);
        if (block.timestamp > startUNIX){
        uint256 limitDays = TIME_STEP.mul(4);
        uint256 pastDays = block.timestamp.sub(startUNIX).div(TIME_STEP);
        uint256 decreaseDays = pastDays.mul(DECREASE_DAY_STEP);
        if (decreaseDays > limitDays){
        decreaseDays = limitDays;
        }
        uint256 minimumDays = planTime.mul(TIME_STEP).sub(decreaseDays);
        return minimumDays;  
      }
      else{
          return None;
      }
    }
    
    function getUserRefRate(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];
        uint256 refsbonus = user.levels[0];
        uint256 RMultiplier = (refsbonus.div(REF_STEP)).mul(100);
            return RMultiplier;
    }
    
    function getUserAuctionRate(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];
        uint256 auctionparticipations = user.aparticipation;
        uint256 AMultiplier = AUCTION_BONUS.mul(auctionparticipations);
            return AMultiplier;
    }

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2]);
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
	
	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].wprofits;
	}
	
	function getUserDepositInfo(address userAddress, uint256 index) public view returns (uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish, bool force){
        User memory user = users[userAddress];
        require(index < user.deposits.length, "Invalid index");

        plan = user.deposits[index].plan;
        percent = user.deposits[index].percent;
        amount = user.deposits[index].amount;
        profit = user.deposits[index].profit;
        start = user.deposits[index].start;
        finish = user.deposits[index].finish;
        force = user.deposits[index].force;
    }
	
	function getpoolAuctInfo() public view returns (address[] memory, address[] memory, uint256[] memory, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        address[] memory addr = new address[](5);
        address[] memory addrs = new address[](5);
        uint256[] memory deps = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            addr[i] = address(alt[i]);
            addrs[i] = address(at[i]);
            deps[i] = uint256(auds[auctionC][at[i]]);
        }
        return (addr, addrs, deps, auctionST, auctionET, auctionB, auctionP, auctionPS , auctionLP, getticketcost(), auctionC);
    }
    
    function setDeveloperAccount(address payable _newDeveloperAccount) public onlyOwner {
        require(_newDeveloperAccount != address(0));
        projectAddress = _newDeveloperAccount;
    }
    
    function setMarketingAccount(address payable _newMarketingAccount) public onlyOwner {
        require(_newMarketingAccount != address(0));
        marketingAddress = _newMarketingAccount;
    }
    
    function setFundAccount(address payable _newFundAccount) public onlyOwner {
        require(_newFundAccount != address(0));
        fundAddress = _newFundAccount;
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

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeBEP20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
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