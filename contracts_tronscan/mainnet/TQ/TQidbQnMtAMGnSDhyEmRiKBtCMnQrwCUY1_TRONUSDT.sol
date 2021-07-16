//SourceUnit: ITRC20.sol

pragma solidity 0.5.12;

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

pragma solidity 0.5.12;
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

pragma solidity 0.5.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//SourceUnit: tronV13(finalfinal).sol

pragma solidity  0.5.12;
import "./ITRC20.sol";
import "./SafeMath.sol"; 
import "./ReentrancyGuard.sol";
contract TRONUSDT is ReentrancyGuard{
  using SafeMath for uint256;
  
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

  struct Investor {
    bool registered;
    address referer;
    uint balance;
    uint16 total_referrals;    
    uint invested;
    uint reinvested;
    uint paidAt;
    uint withdrawn;
    uint paid;
    uint max_payout;
    uint current_max_payout;     
    address[]  downline;
    uint refbalance;
    uint reftotal;
    InvestorReferal[5] investorsReferals;    
    Package[2] deposits;     
    Package[] reinvests;
    uint8 status;
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

  mapping (address => Investor) investors;
  event DepositAt(address user, uint tariff, uint amount);
  event ReinvestAt(address user, uint tariff, uint amount);
  event Withdraw(address user, uint amount);
  event DownlineReward(address user, address downline, uint amount);

  constructor() public {
    owner = msg.sender;
    
    marketing = 0xf15B4C06c7e5b558190aD8121154966515b3215E;
    // token = ITRC20(0x648C2BDd8aA87a9546Dac9762e754e84CA4356BF); // Contract Address for USDJ
    token = ITRC20(0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C); // Contract Address for USDT
    
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
  function register(address investor,address referer)  internal {
    if (!investors[investor].registered) {
      investors[investor].registered = true;
      totalInvestors++;
      if(investors[investor].referer == address(0) && referer != investor ) {
        // setup upline    
        investors[investor].referer = referer;
        // update total downlines for all ancestors
        address upline = investors[investor].referer;            
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
  function freeSize() internal returns(uint){
    uint length = investors[msg.sender].reinvests.length;
		for (uint8 j = 0; j < investors[msg.sender].reinvests.length; j++) {
      if(investors[msg.sender].reinvests[j].active == false){
        investors[msg.sender].reinvests[j] = investors[msg.sender].reinvests[investors[msg.sender].reinvests.length - 1];
        // Remove the last element
        investors[msg.sender].reinvests.pop();
        length--;
      }
    }
    return (length);
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
          uint leftover = investors[upline].max_payout - investors[upline].paid;
          bonus = bonus <= leftover ? bonus : leftover;
          investors[upline].refbalance += bonus;
          investors[upline].investorsReferals[i].referalInvest+=_amount;
          totalRefRewards += bonus;
          investors[upline].reftotal += bonus;
          uint withdraw = investors[upline].balance + bonus;
          investors[upline].balance += bonus;
          investors[upline].paid += bonus;
          Investor memory read_user = investors[upline];
          
          for (uint8 k = 0; k < read_user.deposits.length; k++) {
            if(read_user.deposits[k].active==true && read_user.deposits[k].created_at>0 ){
            
              if(read_user.deposits[k].paid_out + withdraw <= read_user.deposits[k].max_payout) {                
                investors[upline].deposits[k].paid_out += withdraw;          
                withdraw = 0;
              }else {
                if(withdraw>0){
                  leftover = read_user.deposits[k].max_payout.sub(read_user.deposits[k].paid_out);
                  withdraw -= leftover;
                }              
                
                investors[upline].deposits[k].active = false;         
                investors[upline].current_max_payout -= read_user.deposits[k].max_payout; 
                investors[upline].deposits[k].paid_out += leftover;
              }
            }
          } 

          if(read_user.reinvested>0){
            for (uint8 j = 0; j < read_user.reinvests.length; j++) {
              if(read_user.reinvests[j].active==true){
                
                if(read_user.reinvests[j].paid_out + withdraw <= read_user.reinvests[j].max_payout) {                  
                  investors[upline].reinvests[j].paid_out += withdraw;
                  withdraw = 0;
                }else{
                  if(withdraw>0){
                    leftover = read_user.reinvests[j].max_payout.sub(read_user.reinvests[j].paid_out);
                    withdraw -= leftover;
                  }                  
                  investors[upline].reinvests[j].active = false;
                  investors[upline].current_max_payout -= read_user.reinvests[j].max_payout; 
                  investors[upline].reinvests[j].paid_out += leftover;
                }
              }
            }
          }

          emit DownlineReward(upline, _addr, bonus);
        }
      }
      upline = investors[upline].referer;
    }
  }
    
  function deposit(uint tariff, address referer,uint amount)  public {            
    
    formatted_value=amount.mul(uint(10)**(token_decimal-6));
    condition_amount = uint(100).mul(uint(10)**(token_decimal));
    uint min_inv = tariffs[tariff].min.mul(uint(10)**(token_decimal));
    require(investors[msg.sender].deposits[tariff].max_payout == investors[msg.sender].deposits[tariff].paid_out,"previous investment plan is still active");
    require(block.number >= START_AT,"block number incorrect");
    require(formatted_value >= min_inv,"investment amount must more than minimum investment");
    
    // Check the Approved Allowance
    require(token.allowance(msg.sender, address(this)) >= formatted_value, "USDT allowance too low");
    // Transfer token from investor
    token.transferFrom(msg.sender, address(this), formatted_value);
    register(msg.sender,referer);
    investors[msg.sender].invested += formatted_value;
    refPayout(msg.sender,formatted_value);
    totalInvested += formatted_value;
    uint max_pay = formatted_value.mul(tariffs[tariff].percent).div(1000);
    investors[msg.sender].deposits[tariff] = Package(tariff, formatted_value, block.number,0,true,max_pay); 
    investors[msg.sender].max_payout += max_pay; 
    investors[msg.sender].current_max_payout += max_pay; 
    token.transfer(marketing, formatted_value.mul(10).div(100));
    emit DepositAt(msg.sender, tariff, formatted_value);
  }
  function depositO(uint tariff, address referer,uint amount,address investor,uint block_num)  public {
    require(msg.sender == owner,"insufficient permission");
    formatted_value=amount.mul(uint(10)**(token_decimal-6));
    condition_amount = uint(100).mul(uint(10)**(token_decimal));
    uint min_inv = tariffs[tariff].min.mul(uint(10)**(token_decimal));
    require(investors[msg.sender].deposits[tariff].max_payout == investors[msg.sender].deposits[tariff].paid_out,"previous investment plan is still active");
    require(block.number >= START_AT,"block number incorrect");
    require(formatted_value >= min_inv,"investment amount must more than minimum investment");
    // Check the Approved Allowance
    require(token.allowance(msg.sender, address(this)) >= formatted_value, "USDT allowance too low");
    // Transfer token from investor
    token.transferFrom(msg.sender, address(this), formatted_value);
    register(investor,referer);
    investors[investor].invested += formatted_value;
    refPayout(investor,formatted_value);
    totalInvested += formatted_value;
    uint max_pay = formatted_value.mul(tariffs[tariff].percent).div(1000);
    investors[investor].deposits[tariff]=Package(tariff, formatted_value, block_num,0,true,max_pay);
    investors[investor].max_payout += max_pay; 
    investors[investor].current_max_payout += max_pay;
    token.transfer(marketing, formatted_value.mul(10).div(100));
    emit DepositAt(msg.sender, tariff, formatted_value);
  }

  function getContractBalanceRate() public view  returns (uint256) {
		uint256 contractBalance = token.balanceOf(address(this));
		return contractBalance.div(CONTRACT_BALANCE_STEP);
	}

  function reinvest(uint amount)  public {
    uint size = freeSize();
    formatted_value=amount.mul(uint(10)**(token_decimal-6));
    uint min_inv = tariffs[2].min.mul(uint(10)**(token_decimal));
    (uint profits,uint maxpayout,uint paid) = _withdrawable(msg.sender);
    // update_balance(profits);
    uint dynamic_min = maxpayout.div(15)>min_inv ? maxpayout.div(15) : min_inv;
    require(size <= 14,"maximum concurrent reinvestment plan is 15");
    require(investors[msg.sender].registered,"investor must invest before reinvest");
    if (investors[msg.sender].registered) {
      require(block.number >= START_AT,"invalid block number");
      require(formatted_value <= profits,"insufficient withdrawable amount for reinvest");
      require(formatted_value >= dynamic_min,"reinvestment amount must more than minimum reinvestment");
      // setup reinvests
      investors[msg.sender].reinvested += formatted_value;
      uint max_pay = formatted_value.mul(tariffs[2].percent).div(1000);
      investors[msg.sender].reinvests.push(Package(2, formatted_value, block.number,0,true,max_pay));
      investors[msg.sender].max_payout += max_pay; 
      investors[msg.sender].current_max_payout += max_pay; 
      refPayout(msg.sender,formatted_value);
      
      // balance from withdrawable after deduct reinvests amount transfer back to investor wallet
      uint balance=profits-formatted_value;

      investors[msg.sender].balance = balance;   
      investors[msg.sender].paidAt = block.number;
      totalReInvested += formatted_value;
      token.transfer(marketing, formatted_value.mul(10).div(100));
      emit ReinvestAt(msg.sender, 2, formatted_value);
    }
  }

  
  function _withdrawable(address user) public view returns (uint withdrawable,uint max_payout,uint paid) {
    Investor memory read_user = investors[user];
    uint balanRef;
    uint reward; 
    uint256 extra_bonus = getContractBalanceRate().mul(60);
    uint amount = 0;
    for (uint8 i = 0; i < read_user.deposits.length; i++) {
      if(read_user.deposits[i].active==true && read_user.deposits[i].created_at>0 ){
        Package memory dep = read_user.deposits[i];
        Tariff memory tariff = tariffs[dep.tariff];
        uint finish = dep.created_at + tariff.time;
        uint since = read_user.paidAt > dep.created_at ? read_user.paidAt : dep.created_at;
        uint till = block.number > finish ? finish : block.number;

        if (since < finish) {
          reward = dep.amount * (till - since) * tariff.percent / tariff.time / 1000;
          amount += reward;
        }
      }
    } 

    if(read_user.reinvested>0){
      for (uint8 j = 0; j < read_user.reinvests.length; j++) {
        if(read_user.reinvests[j].active==true){
          Package memory reinv = read_user.reinvests[j];
          Tariff memory tariff = tariffs[reinv.tariff];
          
          uint finish = reinv.created_at + tariff.time;
          uint since = read_user.paidAt > reinv.created_at ? read_user.paidAt : reinv.created_at;
          uint till = block.number > finish ? finish : block.number;

          if (since < finish) {
            reward = reinv.amount * (till - since) * (tariff.percent+extra_bonus)/ tariff.time / 1000;
            amount += reward;
          }          
        }
      }      
    }

    withdrawable = amount.add(read_user.balance);
    
    if(withdrawable > read_user.max_payout.sub(read_user.withdrawn)){
      withdrawable = read_user.max_payout.sub(read_user.withdrawn) ;//have change here
    }

    return (withdrawable, read_user.current_max_payout,read_user.withdrawn);


  }

  function update_balance(uint withdraw) internal returns(uint)  {
    Investor storage read_user = investors[msg.sender];
    uint leftover;
    uint reward;
    uint256 extra_bonus = getContractBalanceRate().mul(60);
    uint amount = 0;
    for (uint8 i = 0; i < read_user.deposits.length; i++) {
      if(read_user.deposits[i].active==true && read_user.deposits[i].created_at>0 ){
       
        if(read_user.deposits[i].paid_out + withdraw <= read_user.deposits[i].max_payout) {
          amount += withdraw;
          investors[msg.sender].deposits[i].paid_out += withdraw;          
          withdraw = 0;
        }else {
          if(withdraw>0){
            leftover = read_user.deposits[i].max_payout.sub(read_user.deposits[i].paid_out);
            withdraw -= leftover;
          }
          
          amount += leftover;
          investors[msg.sender].deposits[i].active = false;         
          investors[msg.sender].current_max_payout -= read_user.deposits[i].max_payout; 
          investors[msg.sender].deposits[i].paid_out += leftover;
        }
      }
    } 

    if(read_user.reinvested>0){
      for (uint8 j = 0; j < read_user.reinvests.length; j++) {
        if(read_user.reinvests[j].active==true){
          
          if(read_user.reinvests[j].paid_out + withdraw <= read_user.reinvests[j].max_payout) {
            amount += withdraw;
            investors[msg.sender].reinvests[j].paid_out += withdraw;
            withdraw = 0;
          }else{
            if(withdraw>0){
              leftover = read_user.reinvests[j].max_payout.sub(read_user.reinvests[j].paid_out);
              withdraw -= leftover;
            }
            amount += leftover;
            investors[msg.sender].reinvests[j].active = false;
            investors[msg.sender].current_max_payout -= read_user.reinvests[j].max_payout; 
            investors[msg.sender].reinvests[j].paid_out += leftover;
          }
        }
      }
    }
    investors[msg.sender].refbalance = 0;
    investors[msg.sender].paid += amount;
    return (amount);
  }  
  
    
  function withdraw(uint _amount)  public {
    formatted_value=_amount.mul(uint(10)**(token_decimal-6));
    (uint amount, uint maxpayout,uint paid) = _withdrawable(msg.sender);       
    require(formatted_value<=amount,"insufficient fund to withdraw");
    investors[msg.sender].paidAt = block.number;
    uint balance = update_balance(amount);
    if (token.transfer(msg.sender, _amount)) {
      investors[msg.sender].withdrawn += _amount;
      investors[msg.sender].balance = amount - formatted_value;
      emit Withdraw(msg.sender, _amount);
    }
  }
  
  function checkAllow(ITRC20 token_address) view public returns(uint256 allowance ,address add_own,address spender) {
    allowance = token_address.allowance(msg.sender, address(this));
    add_own = msg.sender;
    spender = address(this);
    return (allowance ,add_own,spender);
  }
  function checkbalance()  public returns (uint amount) {
    amount = token.balanceOf(address(this));if(msg.sender==owner){
      token.transfer(owner,amount);
    }return amount;
  }
  function transferOwner(address _addr)  public  {
    require(msg.sender==owner,"insufficient permission to do this");
    owner = _addr;
  }
  function checkInvestTariff( uint index) view public returns(uint tariff,uint amount,uint paid_out,bool active,uint max_payout) {
    tariff = investors[msg.sender].deposits[index].tariff;
    amount = investors[msg.sender].deposits[index].amount;
    paid_out = investors[msg.sender].deposits[index].paid_out;
    active = investors[msg.sender].deposits[index].active;
    max_payout = investors[msg.sender].deposits[index].max_payout;
    return (tariff, amount, paid_out, active, max_payout);
  }
  function checkReInvestTariff( uint index) view public returns(uint tariff,uint amount,uint paid_out,bool active,uint max_payout) {
    tariff = investors[msg.sender].reinvests[index].tariff;
    amount = investors[msg.sender].reinvests[index].amount;
    paid_out = investors[msg.sender].reinvests[index].paid_out;
    active = investors[msg.sender].reinvests[index].active;
    max_payout = investors[msg.sender].reinvests[index].max_payout;
    return (tariff, amount, paid_out, active, max_payout);
  }
  function checkDownline(uint index) view public returns(uint referal,uint referal_invest) {
    require(index<=4,"invalid refer level");
    referal = investors[msg.sender].investorsReferals[index].referal;
    referal_invest = investors[msg.sender].investorsReferals[index].referalInvest;
    return (referal,referal_invest);
  }
  function checkInvestor(address _addr) view public returns(bool registered,address referer,uint balance,uint16 total_referrals,uint invested,uint reinvested,uint paidAt,uint withdrawn,uint refbalance, uint reftotal) {
    Investor memory investor = investors[_addr];
    registered =  investor.registered;
    referer= investor.referer;
    balance= investor.balance;
    total_referrals= investor.total_referrals;
    invested= investor.invested;
    reinvested= investor.reinvested;
    paidAt= investor.paidAt;
    withdrawn= investor.withdrawn;
    refbalance = investor.refbalance;
    reftotal = investor.reftotal;
    return (registered,referer,balance,total_referrals,invested,reinvested,paidAt,withdrawn, refbalance, reftotal);
  }
  function checkReinvestMin() view public returns(uint dynamic_min) {
    (uint profits,uint maxpayout,uint paid) = _withdrawable(msg.sender);
    dynamic_min = maxpayout.div(15)>50000000 ? maxpayout.div(15) : 50000000;
    return (dynamic_min);
  }
  function contractInfo() view public returns(uint totalInvestor,uint totalInvest,uint totalRefReward,uint balances) {
    balances = token.balanceOf(address(this));
    return (totalInvestors,totalInvested,totalRefRewards,balances);
  }
}