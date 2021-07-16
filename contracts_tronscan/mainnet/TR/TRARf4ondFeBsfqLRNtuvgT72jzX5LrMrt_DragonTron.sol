//SourceUnit: DragonTron.sol

pragma solidity ^0.5.9;

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

contract DragonTron {
    using SafeMath for uint256;

    struct ReferralBonus {
        uint256 minimal;
        uint256 percent;
    }

    struct Leader {
        address user;
        uint256 amount;
    }

    struct User {
        address sponsor;
        uint256[] referrals;
        uint256 referral_bonus_level;
        uint256 pending;
        uint256 line_bonus;
        uint256 bonus;
        uint256 deposited;
        mapping (uint256 => uint256) deposited_by_week;
        uint256 withdrawn;
        uint256 withdrawn_payout;
        uint256 withdraw_date;
        uint256 last_date;
        uint256 start_date;
    }

    address payable public owner = address(0x4138096e26305ae517de2405882994dbbc7d8f2c6f);
    address payable public leader = address(0x41cdcaead073a5f9f5dc9228198899e12a2305aa1c);
    address payable public sponsor = address(0x41027249413181c77ad85079f636278a7c1d13c0c4);

    uint256 private owner_fee = 110;
    uint256 private leader_fee = 30;
    uint256 private sponsor_fee = 10;

    uint256 private sponsor_percent = 10;

    uint256 private ONE_DAY = 1 days;
    uint256 private CYCLE = 200 days;
    uint256 private DAILY = 120;

    uint256 private max_hold_bonus = 8;
    uint256 private max_fund_bonus = 10;
    uint256 private max_people_bonus = 20;

    uint256 private hold_multiplier = 10;
    uint256 private fund_multiplier = 10;
    uint256 private people_multiplier = 5;
    
    uint256 private leaderboardLength = 5;
    uint256 public start_time;

    mapping(address => User) private users;
    mapping(uint256 => mapping(uint256 => Leader)) public leaderboard;

    ReferralBonus[] private ref_bonuses;

    uint256 public total_users;
    uint256 public total_deposited;
    uint256 public total_rewards;

    event Sponsor(address indexed addr, address indexed sponsor);
    event Deposit(address indexed addr, uint256 amount);
    event Payout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() public {
        start_time = block.timestamp;
        
        ref_bonuses.push(ReferralBonus(100 * 1e6, 250));
        ref_bonuses.push(ReferralBonus(201 * 1e6, 200));
        ref_bonuses.push(ReferralBonus(301 * 1e6, 150));
        ref_bonuses.push(ReferralBonus(401 * 1e6, 100));
        ref_bonuses.push(ReferralBonus(501 * 1e6, 50));
        ref_bonuses.push(ReferralBonus(1001 * 1e6, 50));
        ref_bonuses.push(ReferralBonus(2001 * 1e6, 25));
        ref_bonuses.push(ReferralBonus(3001 * 1e6, 10));
        ref_bonuses.push(ReferralBonus(3001 * 1e6, 10));
        ref_bonuses.push(ReferralBonus(4001 * 1e6, 25));
        ref_bonuses.push(ReferralBonus(5001 * 1e6, 50));
        ref_bonuses.push(ReferralBonus(6001 * 1e6, 50));
        ref_bonuses.push(ReferralBonus(7001 * 1e6, 100));
        ref_bonuses.push(ReferralBonus(8001 * 1e6, 150));
        ref_bonuses.push(ReferralBonus(9001 * 1e6, 200));
        ref_bonuses.push(ReferralBonus(10001 * 1e6, 250));
    }

    function() payable external {
        _initUser(msg.sender);
        _deposit(msg.sender, msg.value);
    }

    function _initUser(address _addr) private {
        if (users[_addr].start_date == 0) {
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                users[_addr].referrals.push(0);
            }
        }
    }

    function _setSponsor(address _addr, address _sponsor) private {
        if(users[_addr].sponsor == address(0) && _sponsor != _addr && _addr != owner && (users[_sponsor].start_date > 0 || _sponsor == owner)) {
            users[_addr].sponsor = _sponsor;

            emit Sponsor(_addr, _sponsor);

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_sponsor == address(0)) break;
                users[_sponsor].referrals[i]++;
                _sponsor = users[_sponsor].sponsor;
            }
        }
    }

    function _deposit(address _addr, uint256 _amount) private {
        require(_amount >= 1e8, "Bad amount");
        
        if (users[_addr].start_date == 0) {
            users[_addr].start_date = block.timestamp;
            total_users++;
        }

        uint256 pending = this.payoutOf(_addr);
        if(pending > 0) users[_addr].pending += pending;

        users[_addr].last_date = block.timestamp;
        users[_addr].deposited += _amount;
        total_deposited += _amount;

        while (
            users[_addr].referral_bonus_level < ref_bonuses.length - 1 && 
            users[_addr].deposited >= ref_bonuses[users[_addr].referral_bonus_level + 1].minimal
        ) users[_addr].referral_bonus_level++;

        if (users[_addr].sponsor != address(0)) {
            users[users[_addr].sponsor].line_bonus += _amount * sponsor_percent / 100;
            total_rewards += _amount * sponsor_percent / 100;
            _addLeader(users[_addr].sponsor, _amount);
        }

        uint256 owner_percentage = _amount.mul(owner_fee).div(1000);
        owner.transfer(owner_percentage);

        uint256 leader_percentage = _amount.mul(leader_fee).div(1000);
        leader.transfer(leader_percentage);

        uint256 sponsor_percentage = _amount.mul(sponsor_fee).div(1000);
        sponsor.transfer(sponsor_percentage);
                
        emit Deposit(_addr, _amount);
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].sponsor;

        for(uint256 i = 0; i <= ref_bonuses.length; i++) {
            if(up == address(0)) break;
            if(users[up].referral_bonus_level >= i && !this.isEnded(up)) {
                uint256 bonus = _amount.mul(ref_bonuses[i].percent).div(1000);
                users[up].bonus += bonus;
                total_rewards += bonus;
                emit Payout(up, _addr, bonus);
            }
            up = users[up].sponsor;
        }
    }
    
    function _addLeader(address _addr, uint256 _amount) private returns (bool) {
        uint256 week = _currentWeek();
        users[_addr].deposited_by_week[week] += _amount;
        if (leaderboard[week][leaderboardLength-1].amount >= users[_addr].deposited_by_week[week]) return false;
        for (uint i=0; i<leaderboardLength; i++) {
            if (leaderboard[week][i].amount < users[_addr].deposited_by_week[week]) {
                if (leaderboard[week][i].user != _addr) {
                    Leader memory currentUser = leaderboard[week][i];
                    for (uint j=i+1; j<leaderboardLength+1; j++) {
                        Leader memory nextUser = leaderboard[week][j];
                        leaderboard[week][j] = currentUser;
                        currentUser = nextUser;
                        if (nextUser.user == _addr) break;
                    }
                }
                leaderboard[week][i] = Leader({
                    user: _addr,
                    amount: users[_addr].deposited_by_week[week]
                });
                delete leaderboard[week][leaderboardLength];
                return true;
            }
        }
    }

    function deposit(address _sponsor) payable external {
        _initUser(msg.sender);
        _setSponsor(msg.sender, _sponsor);
        _deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 payout = this.payoutOf(msg.sender);
        uint256 payoutAll = payout + users[msg.sender].bonus + users[msg.sender].line_bonus;
        uint256 diff = (block.timestamp - users[msg.sender].withdraw_date) / ONE_DAY;
        require(payoutAll > 0, "Zero payout");
        require(diff > 0, "One withdrawal per day is allowed");

        users[msg.sender].pending = 0;
        users[msg.sender].bonus = 0;
        users[msg.sender].last_date = block.timestamp;
        users[msg.sender].withdraw_date = block.timestamp;
        users[msg.sender].withdrawn_payout += payout;
        users[msg.sender].withdrawn += payoutAll;

        _refPayout(msg.sender, payoutAll);
        msg.sender.transfer(payoutAll);
        emit Withdraw(msg.sender, payoutAll);
    }

    function isEnded(address _addr) view external returns(bool) {
        uint256 max_payout = this.maxPayoutOf(users[_addr].deposited);
        if (users[_addr].withdrawn_payout >= max_payout) return true;
        uint256 payout = users[_addr].deposited * (DAILY + holdBonus(_addr) + fundBonus() + peopleBonus()) * (block.timestamp - users[_addr].last_date) / 10000 / ONE_DAY + users[_addr].pending;
        if (users[_addr].withdrawn_payout + payout >= max_payout) return true;
        return false;
    }

    function payoutOf(address _addr) view external returns(uint256 payout) {
        uint256 max_payout = this.maxPayoutOf(users[_addr].deposited);
        if (users[_addr].withdrawn_payout >= max_payout) return 0;
        payout = users[_addr].deposited * (DAILY + holdBonus(_addr) + fundBonus() + peopleBonus()) * (block.timestamp - users[_addr].last_date) / 10000 / ONE_DAY + users[_addr].pending;
        if (users[_addr].withdrawn_payout + payout >= max_payout) return max_payout - users[_addr].withdrawn_payout;
        return payout;
    }

    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 24 / 10;
    }

    function holdBonus(address _addr) public view returns (uint256 percent) {
        if (users[_addr].last_date == 0) return 0;

        uint256 ldays = block.timestamp.sub(users[_addr].last_date).div(ONE_DAY);
        ldays = ldays > max_hold_bonus ? max_hold_bonus : ldays;
        return hold_multiplier * ldays;
    }

    function fundBonus() public view returns (uint256 percent) {
        uint256 lholds = address(this).balance.div(1e12);
        lholds = lholds > max_fund_bonus ? max_fund_bonus : lholds;
        return fund_multiplier * lholds;
    }

    function peopleBonus() public view returns (uint256 percent) {
        uint256 lpeople = total_users.div(100);
        lpeople = lpeople > max_people_bonus ? max_people_bonus : lpeople;
        return people_multiplier * lpeople;
    }

    function referralsCount(address _addr, uint256 _level) external view returns (uint256 referrals) {
        return users[_addr].referrals[_level];
    }
    
    function _currentWeek() public view returns (uint256 week) {
        return (block.timestamp - start_time) / ONE_DAY / 7;
    }

    function infoUser(address _addr) public view returns (uint256 invested, uint256 profit, uint256 bonus, uint256 line_bonus, uint256 withdrawn, uint256 level) {
        return (
            users[_addr].deposited,
            this.payoutOf(_addr),
            users[_addr].bonus,
            users[_addr].line_bonus,
            users[_addr].withdrawn,
            users[_addr].referral_bonus_level
        );
    }

    function getLeader(uint256 _week, uint256 _place) public view returns (address user, uint256 amount) {
        return (
            leaderboard[_week][_place].user,
            leaderboard[_week][_place].amount
        );
    }
}