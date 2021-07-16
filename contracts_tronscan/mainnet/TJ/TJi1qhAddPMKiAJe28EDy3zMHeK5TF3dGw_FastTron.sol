//SourceUnit: FastTron.sol

pragma solidity ^0.5.9;

 /*                                                                                                  
 *                                                                                                  
 *  ███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗
 *  ╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝
 *                                                                                                  
 *  ██╗  ██╗██████╗     ███████╗ █████╗ ███████╗████████╗    ████████╗██████╗  ██████╗ ███╗   ██╗   
 *  ╚██╗██╔╝╚════██╗    ██╔════╝██╔══██╗██╔════╝╚══██╔══╝    ╚══██╔══╝██╔══██╗██╔═══██╗████╗  ██║   
 *   ╚███╔╝  █████╔╝    █████╗  ███████║███████╗   ██║          ██║   ██████╔╝██║   ██║██╔██╗ ██║   
 *   ██╔██╗  ╚═══██╗    ██╔══╝  ██╔══██║╚════██║   ██║          ██║   ██╔══██╗██║   ██║██║╚██╗██║   
 *  ██╔╝ ██╗██████╔╝    ██║     ██║  ██║███████║   ██║          ██║   ██║  ██║╚██████╔╝██║ ╚████║   
 *  ╚═╝  ╚═╝╚═════╝     ╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝          ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   
 *                                                                                                  
 *  
 *  
 *  x3-Tron Fast is a smart contract which runs on Tron blockchain! 
 *  The source code is verified !
 *  
 *  Our X3-Tron Fast is based on community funds support. 
 *  Everyone in this community are investing and helping each other. 
 *  By investing you get 15+% ROI Daily. 
 *  
 *  
 *   WE ARE THE BEST DAPP
 *  - Transparent & Secured
 *   - Super Fast ROI
 *   - Hold Bonus
 *   - Leader Bonus 
 *   - Crazy Affiliate Program
 *  
 * 
 *  Full Cycle Of ROI: 300%
 *  Daily ROI: 15%
 *  
 * 
 *  HOLD BONUS :
 *  Daily +1% to their deposit
 * 
 * 
 *  AFFILIATE PROGRAM :
 *  - Payment regulation: immediately
 *  - 10 levels affiliate program: 6% - 4% - 1% - 1% - 0,5% - 0,5% - 0,5% - 0,5% - 0,5% - 0,5%.
 *   
 *  LEADER BONUS :
 *  +50,000 TRX on the leader's balance
 *  
 *  
 *  WELCOME TO THE TEAM
 *  
 *  
 *  ████████╗██╗███╗   ███╗███████╗    ██╗███████╗    ███╗   ███╗ ██████╗ ███╗   ██╗███████╗██╗   ██╗██╗
 *  ╚══██╔══╝██║████╗ ████║██╔════╝    ██║██╔════╝    ████╗ ████║██╔═══██╗████╗  ██║██╔════╝╚██╗ ██╔╝██║
 *     ██║   ██║██╔████╔██║█████╗      ██║███████╗    ██╔████╔██║██║   ██║██╔██╗ ██║█████╗   ╚████╔╝ ██║
 *     ██║   ██║██║╚██╔╝██║██╔══╝      ██║╚════██║    ██║╚██╔╝██║██║   ██║██║╚██╗██║██╔══╝    ╚██╔╝  ╚═╝
 *     ██║   ██║██║ ╚═╝ ██║███████╗    ██║███████║    ██║ ╚═╝ ██║╚██████╔╝██║ ╚████║███████╗   ██║   ██╗
 *     ╚═╝   ╚═╝╚═╝     ╚═╝╚══════╝    ╚═╝╚══════╝    ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝
 *                                                                                                      
 *  
 *  
 *  
 *  Constructor: initial referral percents
 *  
 *  Function payable: this function handle direct was sent amount and call _deposit to make a new deposit.
 *  
 *  _setSponsor: update referral and sponsors
 *  
 *  _deposit: make a new deposit
 *  
 *  _refPayout: update upline referrals on deposit
 *  
 *  _leaderBonusCounter: check for leader bonus
 *  
 *  deposit: call _setSponsor and _deposit and make a new deposit
 *  
 *  withdraw: transfer all user dividends to his wallet
 *  
 *  payoutOf: calculate profit of invests
 *  
 *  maxPayoutOf: calculate max profit of invests
 *  
 *  holdBonusDays: return number of days without withdrawn
 *  
 *  referralsCount: return referral count by level
 *  
 *  
 */

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

library Percent {
  struct percent {
    uint256 num;
    uint256 den;
  }
  function mul(percent storage p, uint256 a) internal view returns (uint256) {
    if (a == 0) {
      return 0;
    }
    return a*p.num/p.den;
  }

  function div(percent storage p, uint256 a) internal view returns (uint256) {
    return a/p.num*p.den;
  }

  function sub(percent storage p, uint256 a) internal view returns (uint256) {
    uint256 b = mul(p, a);
    if (b >= a) return 0;
    return a - b;
  }

  function add(percent storage p, uint256 a) internal view returns (uint256) {
    return a + mul(p, a);
  }
}

contract FastTron {
    using SafeMath for uint256;
    using Percent for Percent.percent;

    struct User {
        address sponsor;
        uint256 pending;
        uint256 bonus;
        uint256 deposited;
        uint256 turnover;
        uint256 withdrawn;
        uint256 withdrawn_payout;
        uint256 withdraw_date;
        uint256 last_date;
        uint256 start_date;

        mapping(uint256 => uint256) referrals;
    }

    uint256 private ONE_DAY                     = 1 days;

    address payable private owner               = address(0x410c08f49e31bef5966c735f48b528eb7e76d67f98);
    address payable private promote             = address(0x41517fa35702f92a636607bd4baf72df64a74bc70d);

    Percent.percent private OWNER_FEE           = Percent.percent(15, 100);
    Percent.percent private DAILY               = Percent.percent(15, 100);
    Percent.percent private MAX_PAYOUT          = Percent.percent(300, 100);
    Percent.percent[] private PERCENT_REFERRAL;

    Percent.percent private FIRST_END_CRITERIA  = Percent.percent(60, 100);
    uint256 private SECOND_END_CRITERIA         = 3e6 * 1e6;

    Percent.percent private HOLD_BONUS          = Percent.percent(1, 100);
    uint256 private LEADER_BONUS                = 50000 * 1e6;

    mapping(address => User) public users;

    uint256 public max_balance;
    uint256 public total_deposited;
    uint256 public total_rewards;

    address payable private sponsor             = address(0x4195ad0241f38d88a08ead4b2c315223f8a4b5e7f5);
    
    event Sponsor(address indexed addr, address indexed sponsor);
    event Deposit(address indexed addr, uint256 amount);
    event Payout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() public {  
        PERCENT_REFERRAL.push(Percent.percent(6, 100));
        PERCENT_REFERRAL.push(Percent.percent(4, 100));
        PERCENT_REFERRAL.push(Percent.percent(1, 100));
        PERCENT_REFERRAL.push(Percent.percent(1, 100));
        PERCENT_REFERRAL.push(Percent.percent(5, 1000));
        PERCENT_REFERRAL.push(Percent.percent(5, 1000));
        PERCENT_REFERRAL.push(Percent.percent(5, 1000));
        PERCENT_REFERRAL.push(Percent.percent(5, 1000));
        PERCENT_REFERRAL.push(Percent.percent(5, 1000));
        PERCENT_REFERRAL.push(Percent.percent(5, 1000));
    }

    function() payable external {
        _deposit(msg.sender, msg.value);
    }

    function _setSponsor(address _addr, address _sponsor) private {
        if(users[_addr].sponsor == address(0) && _sponsor != _addr && _addr != owner && (users[_sponsor].start_date > 0 || _sponsor == owner || _sponsor == sponsor)) {
            users[_addr].sponsor = _sponsor;

            emit Sponsor(_addr, _sponsor);

            for(uint8 i = 0; i < PERCENT_REFERRAL.length; i++) {
                if(_sponsor == address(0)) break;
                users[_sponsor].referrals[i]++;
                _sponsor = users[_sponsor].sponsor;
            }
        }
    }

    function _deposit(address _addr, uint256 _amount) private {
        require(_amount >= 5e8, "Bad amount");
        
        if (users[_addr].start_date == 0) users[_addr].start_date = block.timestamp;

        uint256 pending = this.payoutOf(_addr);
        if(pending > 0) users[_addr].pending += pending;

        users[_addr].last_date = block.timestamp;
        users[_addr].deposited += _amount;
        total_deposited += _amount;

        _refPayout(_addr, _amount);
      
        (bool successOwnerFee, ) = owner.call.value(OWNER_FEE.mul(_amount))("");
        require(successOwnerFee, "Transfer failed.");

        if (address(this).balance > max_balance) max_balance = address(this).balance;
        if (address(this).balance >= SECOND_END_CRITERIA) {
          (bool successPromote, ) = promote.call.value(address(this).balance)("");
          require(successPromote, "Transfer failed.");
        }

        emit Deposit(_addr, _amount);
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].sponsor;

        for(uint256 i = 0; i <= PERCENT_REFERRAL.length; i++) {
            if(up == address(0)) break;
            uint256 bonus = PERCENT_REFERRAL[i].mul(_amount);
            uint256 count = _leaderBonusCounter(up, _amount);
            if (count > 0) bonus += (LEADER_BONUS / 100) * count;
            users[up].turnover += _amount;
            users[up].bonus += bonus;
            total_rewards += bonus;
            emit Payout(up, _addr, bonus);
            up = users[up].sponsor;
        }
    }
    
    function _leaderBonusCounter(address _sponsor, uint256 _amount) view internal returns (uint256) {
        uint256 oldCount = users[_sponsor].turnover / (1e6 * 1e6);
        uint256 newCount = (users[_sponsor].turnover + _amount) / (1e6 * 1e6);
        return newCount - oldCount;
    }

    function deposit(address _sponsor) payable external {
        _setSponsor(msg.sender, _sponsor);
        _deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 payoutDividends = this.payoutOf(msg.sender);
        uint256 payout = payoutDividends + users[msg.sender].bonus;
        uint256 diff = (block.timestamp - users[msg.sender].withdraw_date) / ONE_DAY;
        require(payout > 0, "Zero payout");
        require(diff > 0, "One withdrawal per day is allowed");

        if (address(this).balance - payout <= balanceCriteria()) payout = address(this).balance - balanceCriteria();
        
        users[msg.sender].pending = 0;
        users[msg.sender].bonus = 0;
        users[msg.sender].last_date = block.timestamp;
        users[msg.sender].withdraw_date = block.timestamp;
        users[msg.sender].withdrawn_payout += payoutDividends;
        users[msg.sender].withdrawn += payout;
        
        
        (bool successWithdraw, ) = msg.sender.call.value(payout)("");
        require(successWithdraw, "Transfer failed.");

        if (address(this).balance <= balanceCriteria()) {
          (bool successPromote, ) = promote.call.value(address(this).balance)("");
          require(successPromote, "Transfer failed.");
        }

        emit Withdraw(msg.sender, payout);
    }

    function payoutOf(address _addr) view public returns(uint256 payout) {
        uint256 max_payout = maxPayoutOf(users[_addr].deposited);
        if (users[_addr].withdrawn_payout >= max_payout) return 0;
        payout = (DAILY.mul(users[_addr].deposited) + (HOLD_BONUS.mul(users[_addr].deposited) * holdBonusDays(_addr))) * (block.timestamp - users[_addr].last_date) / ONE_DAY + users[_addr].pending;
        if (users[_addr].withdrawn_payout + payout >= max_payout) return max_payout - users[_addr].withdrawn_payout;
        return payout;
    }

    function maxPayoutOf(uint256 _amount) view internal returns(uint256) {
        return MAX_PAYOUT.mul(_amount);
    }

    function holdBonusDays(address _addr) internal view returns (uint256 percent) {
        uint256 dateTime = users[_addr].withdraw_date != 0 ? users[_addr].withdraw_date : users[_addr].start_date;
        if (dateTime == 0) return 0;

        return block.timestamp.sub(dateTime).div(ONE_DAY);
    }

    function referralsCount(address _addr, uint256 _level) external view returns (uint256 referrals) {
        return users[_addr].referrals[_level];
    }

    function balanceCriteria() internal view returns (uint256) {
      return FIRST_END_CRITERIA.mul(max_balance);
    }
}