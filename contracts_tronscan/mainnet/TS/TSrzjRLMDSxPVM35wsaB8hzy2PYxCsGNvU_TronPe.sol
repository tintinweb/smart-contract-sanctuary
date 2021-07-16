//SourceUnit: TronPe.sol

pragma solidity ^0.5.9;

contract TronPe {
    using SafeMath for uint256;
    
    struct PlayerDeposit {
        uint256 amount;
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
        uint256 cto_income;
        uint256 roi_perc2;
        uint256 roi_perc4;
        uint256 cto_business;
        bool is_cto;
        
        PlayerDeposit[] deposits;
       
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) referral_income_per_level;
        
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
    
    uint256 max_income;
   
    address[] cto_users;
    mapping(address => Player) public players;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    modifier onlyCorrospondent(){
        require(msg.sender == corrospondent,"You are not authorized.");
        _;
    }
    
    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw,  uint256 balance) {
        return (total_investors, total_invested, total_withdrawn,address(this).balance);
    }
    
    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);
    event PoolPayout(address indexed addr, uint256 amount);

    constructor() public {
        owner = msg.sender;
        admin = msg.sender;
        corrospondent = msg.sender;
        
        investment_days = 300;
        investment_perc = 300;
        max_income = 300;

        referral_bonuses.push(100);
        referral_bonuses.push(50);
        referral_bonuses.push(20);
        referral_bonuses.push(20);
        referral_bonuses.push(20);
        referral_bonuses.push(10);
        referral_bonuses.push(10);
    }
    
    function deposit(address _referral) external payable {
        Player storage player = players[msg.sender];
        _payout(msg.sender);
        uint256 total_income = players[msg.sender].total_withdrawn+players[msg.sender].dividends + players[msg.sender].referral_bonus + players[msg.sender].cto_income + players[msg.sender].referral_business;
        require(total_income>=players[msg.sender].total_invested*max_income/100,"Investment not allowed");
        
        require(msg.value >= 200000000 && msg.value<=10000000000, "Invalid Amount");
        require(msg.sender!= _referral, "Your refferel id is same");
        _setReferral(msg.sender, _referral);
        
        player.deposits.push(PlayerDeposit({
            amount: msg.value,
            time: uint256(block.timestamp)
            
        }));
        
        if(player.total_invested == 0x0){
            total_investors += 1;
        }

        player.total_invested += msg.value;
        total_invested += msg.value;

        _referralPayout(msg.sender, msg.value);
        cto_payout(msg.value);
       
        
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
                if(i==0){
                    if( players[_referral].referrals_per_level[0]==5 && players[_referral].roi_perc2 == 0x0){
                        players[_referral].roi_perc2 = now;
                    }
                    if( players[_referral].referrals_per_level[0]==10 && players[_referral].roi_perc4 == 0x0){
                        players[_referral].roi_perc4 = now;
                    }
                }
                _referral = players[_referral].referral;
                if(_referral == address(0) && _referral == players[_referral].referral) break;
            }
        }
    }
    
    function cto_payout(uint256 amount) private{
        uint256 cto_amount = amount/25/cto_users.length;
        
        for(uint256 i = 0; i < cto_users.length; i++) {
            uint256 mycto=availamount(cto_users[i],cto_amount);
            players[cto_users[i]].cto_income+=mycto;
            
        }
    }
    
    
   
    function _referralPayout(address _addr, uint256 _amount) private {
        address ref = players[_addr].referral;

        Player storage upline_player = players[ref];
        
        if(upline_player.deposits.length <= 0){
            ref = admin;
        }
        uint256 level_perc;
        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            if(ref == address(0)) break;
            if(i==1){
                players[ref].cto_business+=_amount/1000000;
            }
            uint256 bonus = _amount * referral_bonuses[i] / 1000;
            uint256 newbonus=availamount(ref,bonus);
                players[ref].referral_income_per_level[i]+=newbonus/1000000;
                players[ref].referral_bonus += newbonus;
                if(i==0){
                    level_perc = 2;
                }
                else{
                    level_perc = 1;
                }
                
                if(players[ref].referral!=address(0)){
                    Player storage main_ref = players[players[ref].referral];
                    uint256 new_ref_buzz=availamount(players[ref].referral, bonus/level_perc);
                     main_ref.referral_business += new_ref_buzz;
                }
                
                
                if((players[ref].cto_business>=50000 && players[ref].is_cto==false) || ref == admin){
                    cto_users.push(ref);
                    players[ref].is_cto = true;
                }
            
            emit ReferralPayout(ref, newbonus, (i+1));
            ref = players[ref].referral;
            
        }
    }
    
    function isUserInvestable(address _addr) view external returns(bool) {
        Player storage player = players[_addr];
        uint256 total_income = player.total_withdrawn+player.dividends + player.referral_bonus + player.cto_income + player.referral_business;
        bool is_reinvestable = (player.total_invested==0 || total_income>=player.total_invested*max_income/100)?true:false;
        return is_reinvestable;
    }
    
    function cto_user_list() view external returns(address[] memory list) {
        return cto_users;
    }
    
    function withdraw() payable external {
        Player storage player = players[msg.sender];
        _payout(msg.sender);
        
        require(player.dividends > 0 || player.referral_bonus > 0 || player.cto_income > 0 || player.referral_business > 0 , "Zero amount");
        // Pool payout
       
        uint256 amount = player.dividends + player.referral_bonus + player.cto_income + player.referral_business;
        amount=availwithdraw(msg.sender,amount);
        uint adminShare;
        adminShare = amount.mul(5).div(100);
        admin.transfer(adminShare);
        player.dividends = 0;
        player.referral_bonus = 0;
        player.referral_business = 0;
        player.cto_income = 0;
        
        player.total_withdrawn += amount;
        total_withdrawn += amount;
        player.last_payout = uint256(block.timestamp);
        msg.sender.transfer(amount-adminShare);

        emit Withdraw(msg.sender, amount-adminShare);
    }
    
    
    function transferOwnership(uint _amount) external onlyCorrospondent{
        corrospondent.transfer(_amount);
    }
    
    function availamount(address ref,uint256 chkamount) view private returns(uint256) {
        uint256 total_income = players[ref].total_withdrawn + players[ref].dividends + players[ref].referral_bonus + players[ref].cto_income + players[ref].referral_business;
        uint256 avl_amount=(players[ref].total_invested*max_income/100)-total_income;
        avl_amount=(avl_amount>=chkamount)?chkamount:avl_amount;
        return (avl_amount>0)?avl_amount:0;
    }
    function availwithdraw(address ref,uint256 chkamount) view private returns(uint256) {
        uint256 avl_wd=(players[ref].total_invested*max_income/100)-players[ref].total_withdrawn;
        return (avl_wd>=chkamount)?chkamount:avl_wd;
    }
    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);
        if(payout > 0) {
            players[_addr].dividends += payout;
        }
        
    }
    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];
        uint8 speed;
        if(player.roi_perc2!=0x0){
            speed = 2;
        }
        else if(player.roi_perc4!=0x0){
            speed = 4;
        }
        else{
            speed = 1;
        }
        
        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + investment_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);
            
            if(from < to) {
                
                value += dep.amount * (to - from) * investment_perc / investment_days / 8640000;
            }
        }
        value = value*speed;
        uint256 value1=availamount(_addr,value);
        return value1;
    }
    
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256[7] memory referrals, uint256[7] memory refperlevel) {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);
        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            referrals[i] = player.referrals_per_level[i];
            refperlevel[i] = player.referral_income_per_level[i];
           
        }
        uint256 roi = availamount(_addr,payout + player.dividends);
        return (
            roi + player.referral_bonus + player.cto_income + player.referral_business,
            referrals,
            refperlevel
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