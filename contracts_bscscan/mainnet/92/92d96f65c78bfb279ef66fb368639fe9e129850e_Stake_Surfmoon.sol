/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

// SPDX-License-Identifier: None

pragma solidity 0.6.12;

contract Stake_Surfmoon {
    using SafeMath for uint256;

    address Surfmoon = 0xc47f53c425d08f8457471538Ae641655814bEAe8;
    IBEP20 token;

    uint256 public constant INVEST_MIN_AMOUNT = 10 ether;
    uint256[] public REFERRAL_PERCENTS = [70, 30, 15, 10, 5];
    uint256 public constant DEV_FEE = 80;
    uint256 public constant BUY_BACK_FEE = 20;
    uint256 public constant PERCENT_STEP = 5;
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant TIME_STEP = 1 days;

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
      uint256[5] levels;
      uint256 bonus;
      uint256 totalBonus;
      uint256 withdrawn;
    }

    mapping(address => User) internal users;

    bool public started;
    address payable public ceo1;
    address payable public ceo2;
    address payable public buyBackWallet;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint8 plan, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus( address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);

    constructor() public {

      token = IBEP20(Surfmoon);
      ceo1 = msg.sender;
      ceo2 = 0x060e8f605f0E32eC123A118c19958F6858Cc7008;
      buyBackWallet = 0x4AEf3133b1bC2cF78f88552fDd75a1B146c9333a;

      plans.push(Plan(10000, 30));
      plans.push(Plan(40, 70));
      plans.push(Plan(60, 65));
      plans.push(Plan(90, 60));
    }

    function init() public {
      require(msg.sender == ceo1, "You can't do that");
      started = true;
    }

    function buyBack(uint256 _amount) public payable {
      token.transferFrom(msg.sender, address(this), _amount);
    }

    function invest( address referrer, uint8 plan, uint256 _amount) public payable {
      require(started, "Too early");
      require(plan < 4, "Invalid plan");
      require(_amount >= INVEST_MIN_AMOUNT, "Less than minimum amount");

      token.transferFrom(msg.sender, address(this), _amount);
      uint256 devFee = _amount.mul(DEV_FEE).div(PERCENTS_DIVIDER);
      uint256 devFee2 = devFee.div(2);
      uint256 buyBackFee = _amount.mul(BUY_BACK_FEE).div(PERCENTS_DIVIDER);

      token.transfer(ceo1, devFee2);
      token.transfer(ceo2, devFee.sub(devFee2));
      token.transfer(buyBackWallet, buyBackFee);

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

      if (user.deposits.length == 0) {
        user.checkpoint = block.timestamp;
        emit Newbie(msg.sender);
      }

      user.deposits.push(Deposit(plan, _amount, block.timestamp));
      totalInvested = totalInvested.add(_amount);
      emit NewDeposit(msg.sender, plan, _amount);
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
			  user.bonus = totalAmount.sub(contractBalance);
			  user.totalBonus = user.totalBonus.add(user.bonus);
			  totalAmount = contractBalance;
      }

      user.checkpoint = block.timestamp;
      user.withdrawn = user.withdrawn.add(totalAmount);
      token.transfer(msg.sender, totalAmount);
      emit Withdrawn(msg.sender, totalAmount);
    }

    function getContractBalance() public view returns (uint256) {
      return token.balanceOf(address(this));
    }

    function getPlanInfo(uint8 plan) public view returns (uint256 time, uint256 percent) {
      time = plans[plan].time;
      percent = plans[plan].percent;
    }

    function getUserDividends(address userAddress) public view returns (uint256) {
      User storage user = users[userAddress];
      uint256 totalAmount = 0;

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

    function getUserCheckpoint(address userAddress) public view returns (uint256) {
      return users[userAddress].checkpoint;
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
     return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint256 amount) {
      for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
        amount = amount.add(users[userAddress].deposits[i].amount);
      }
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns (uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
      User storage user = users[userAddress];

      plan = user.deposits[index].plan;
      percent = plans[plan].percent;
      amount = user.deposits[index].amount;
      start = user.deposits[index].start;
      finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(1 days));
    }

    function getSiteInfo() public view returns (uint256 _totalInvested, uint256 _totalBonus) {
      return (totalInvested, totalRefBonus);
    }

    function getUserInfo(address userAddress) public view returns (uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals) {
      return (getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress));
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

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}