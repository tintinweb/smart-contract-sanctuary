//SourceUnit: OneTron.sol

pragma solidity ^0.5.9;

                                                                                                
 /* ██████╗ ███╗   ██╗███████╗    ████████╗██████╗  ██████╗ ███╗   ██╗
 * ██╔═══██╗████╗  ██║██╔════╝    ╚══██╔══╝██╔══██╗██╔═══██╗████╗  ██║
 * ██║   ██║██╔██╗ ██║█████╗         ██║   ██████╔╝██║   ██║██╔██╗ ██║
 * ██║   ██║██║╚██╗██║██╔══╝         ██║   ██╔══██╗██║   ██║██║╚██╗██║
 * ╚██████╔╝██║ ╚████║███████╗       ██║   ██║  ██║╚██████╔╝██║ ╚████║
 *  ╚═════╝ ╚═╝  ╚═══╝╚══════╝       ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
 *                                                                    
 *                                                                                             
 *  
 *   WE ARE THE BEST DAPP
 * 
 *   - BIG ROI
 *   - Easy Start
 *   - Transparent & Secured
 *   - Affiliate Program
 *   - Hold Bonus
 *   - Leader Bonus 
 *   - Bonus From the Fund
 *  
 * 
 *  Full Cycle Of ROI: 300%
 *  Daily ROI: 2+%
 *  
 * 
 *  AFFILIATE PROGRAM :
 *  - Payment regulation: immediately
 *  - 5 levels affiliate program: 7% - 3% - 2% - 2% - 1% 
 * 
 * 
 *  HOLD BONUS :
 *  Receive an additional + 0,1% to your account for every 24 hours of holding funds on the balance
 * 
 * 
 *  LEADER BONUS :
 *  For every 500,000 TRX contributed by your referrals, you will receive + 2% to your daily ROI
 *  
 *  
 *  BONUS FROM THE FUND:
 *  For every 1,000,000 TRX on SC balance - Absolutely Each user receives an additional + 0.1%
 * 
 * 
 *  CONNECT and LET'S WORK TOGETHER !!!
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

contract OneTron {
    using SafeMath for uint256;
    using Percent for Percent.percent;

    struct User {
        address sponsor;
        uint256 pending;
        uint256 pending_payout;
        uint256 bonus;
        uint256 deposited;
        uint256 turnover;
        uint256 withdrawn;
        uint256 withdrawn_payout;
        uint256 withdraw_date;
        uint256 leader_date;
        uint256 last_date;

        mapping(uint256 => uint256) referrals;
    }

    uint256 private ONE_DAY                     = 1 days;

    address payable private owner               = address(0x4160a4f6b548b0c9586771eda87cb2471342cb60eb);
    address payable private promote             = address(0x4143ef8b7a56353e365dbf3b2b7b4315abc87abeaa);

    Percent.percent private OWNER_FEE           = Percent.percent(5, 100);
    Percent.percent private PROMOTE_FEE         = Percent.percent(10, 100);
    Percent.percent private DAILY               = Percent.percent(2, 100);
    Percent.percent private MAX_PAYOUT          = Percent.percent(300, 100);
    Percent.percent[] private PERCENT_REFERRAL;

    Percent.percent private HOLD_BONUS          = Percent.percent(1, 1000);
    Percent.percent private LEADER_BONUS        = Percent.percent(2, 100);
    Percent.percent private FUND_BONUS          = Percent.percent(1, 1000);

    uint256 public MAX_HOLD_BONUS               = 20;

    mapping(address => User) public users;

    uint256 public max_balance;
    uint256 public total_deposited;
    uint256 public total_rewards;
    
    event Sponsor(address indexed addr, address indexed sponsor);
    event Deposit(address indexed addr, uint256 amount);
    event Payout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() public {  
        PERCENT_REFERRAL.push(Percent.percent(7, 100));
        PERCENT_REFERRAL.push(Percent.percent(3, 100));
        PERCENT_REFERRAL.push(Percent.percent(2, 100));
        PERCENT_REFERRAL.push(Percent.percent(2, 100));
        PERCENT_REFERRAL.push(Percent.percent(1, 1000));
    }

    function() payable external {
        _deposit(msg.sender, msg.value);
    }

    function _setSponsor(address _addr, address _sponsor) private {
        if(users[_addr].sponsor == address(0) && _sponsor != _addr && _addr != owner && (users[_sponsor].last_date > 0 || _sponsor == owner)) {
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

        uint256 pending = this.payoutOf(_addr);
        if(pending > 0) users[_addr].pending += pending;

        users[_addr].last_date = block.timestamp;
        users[_addr].deposited += _amount;
        total_deposited += _amount;

        _refPayout(_addr, _amount);
      
        (bool successOwnerFee, ) = owner.call.value(OWNER_FEE.mul(_amount))("");
        require(successOwnerFee, "Transfer failed.");

        (bool successPromoteFee, ) = promote.call.value(PROMOTE_FEE.mul(_amount))("");
        require(successPromoteFee, "Transfer failed.");

        emit Deposit(_addr, _amount);
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].sponsor;

        for(uint256 i = 0; i <= PERCENT_REFERRAL.length; i++) {
            if(up == address(0)) break;
            uint256 bonus = PERCENT_REFERRAL[i].mul(_amount);
            uint256 pending = leaderBonus(up);
            users[up].turnover += _amount;
            users[up].bonus += bonus;
            users[up].leader_date = block.timestamp;
            if (pending > 0) users[up].pending_payout += pending;
            total_rewards += bonus;
            emit Payout(up, _addr, bonus);
            up = users[up].sponsor;
        }
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
        
        users[msg.sender].pending = 0;
        users[msg.sender].pending_payout = 0;
        users[msg.sender].bonus = 0;
        users[msg.sender].last_date = block.timestamp;
        users[msg.sender].leader_date = block.timestamp;
        users[msg.sender].withdraw_date = block.timestamp;
        users[msg.sender].withdrawn_payout += payoutDividends;
        users[msg.sender].withdrawn += payout;
        
        
        (bool successWithdraw, ) = msg.sender.call.value(payout)("");
        require(successWithdraw, "Transfer failed.");

        emit Withdraw(msg.sender, payout);
    }
    
    function maxPayoutOf(uint256 _amount) view internal returns(uint256) {
        return MAX_PAYOUT.mul(_amount);
    }

    function payoutOf(address _addr) view external returns(uint256 payout) {
        uint256 max_payout = maxPayoutOf(users[_addr].deposited);
        if (users[_addr].withdrawn_payout >= max_payout) return 0;
        payout = (dailyBonus(_addr) + holdBonus(_addr) + fundBonus(_addr) + leaderBonus(_addr)) + users[_addr].pending + users[_addr].pending_payout;
        if (users[_addr].withdrawn_payout + payout >= max_payout) return max_payout - users[_addr].withdrawn_payout;
        return payout;
    }

    function dailyBonus(address _addr) internal view returns (uint256 percent) {
        if (users[_addr].last_date == 0) return 0;
        return DAILY.mul(users[_addr].deposited) * (block.timestamp - users[_addr].last_date) / ONE_DAY;
    }

    function getHoldBonus(address _addr) public view returns (uint256 percent) {
        if (users[_addr].last_date == 0) return 0;
        uint256 ldays = block.timestamp.sub(users[_addr].last_date).div(ONE_DAY);
        return ldays > MAX_HOLD_BONUS ? MAX_HOLD_BONUS : ldays;
    }

    function holdBonus(address _addr) internal view returns (uint256 percent) {
        if (users[_addr].last_date == 0) return 0;
        return HOLD_BONUS.mul(users[_addr].deposited) * getHoldBonus(_addr);
    }

    function getFundBonus() public view returns (uint256 percent) {
        return address(this).balance.div(1e12);
    }

    function fundBonus(address _addr) internal view returns (uint256 percent) {
        if (users[_addr].last_date == 0) return 0;
        uint256 count = getFundBonus();
        uint256 ldays = block.timestamp.sub(users[_addr].last_date).div(ONE_DAY);
        return FUND_BONUS.mul(users[_addr].deposited) * count * ldays;
    }

    function getLeaderBonus(address _addr) public view returns (uint256 percent) {
        return users[_addr].turnover.div(5e5 * 1e6);
    }

    function leaderBonus(address _addr) internal view returns (uint256 percent) {
        if (users[_addr].leader_date == 0) return 0;
        uint256 count = getLeaderBonus(_addr);
        uint256 ldays = block.timestamp.sub(users[_addr].leader_date).div(ONE_DAY);
        return LEADER_BONUS.mul(users[_addr].deposited) * count * ldays;
    }

    function referralsCount(address _addr, uint256 _level) external view returns (uint256 referrals) {
        return users[_addr].referrals[_level];
    }
}