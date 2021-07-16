//SourceUnit: TronMint.sol

pragma solidity 0.5.9;

contract TronMint {
    using SafeMath for uint256;
    
    struct PlayerDeposit {
        uint256 amount;
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
        uint256 cto_income;
        uint256 level_roi;
        bool is_assured;
        bool is_assured_withdrawl;
        bool is_cto;
        PlayerDeposit[] deposits;
        
        mapping(uint8 => uint256) total_level_roi;
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) referral_income_per_level;
    }

    address payable owner;
    address payable admin;
    address payable corrospondent;

    uint256 investment_days;
    uint256 investment_perc;
    uint256 investment_max;

    uint256 total_investors;
    uint256 total_invested;
    uint256 total_withdrawn;
    address[] cto_users;
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
    
    function getContractInfo() view public returns(uint256 investors, uint256 investments, uint256 Withdraws, uint256 balance){
       return (total_investors, total_invested,total_withdrawn, address(this).balance);
        
    }
    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LevelROIPayout(address indexed addr, uint256 amount, uint8 level);
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);
    

    constructor() public {
        owner = msg.sender;
        admin = msg.sender;
        corrospondent = msg.sender;
        
        investment_days = 365;
        investment_perc = 365;
        investment_max = 365;
        
        level_roi_bonus.push(30);
        level_roi_bonus.push(10);
        level_roi_bonus.push(10);
        level_roi_bonus.push(10);
        level_roi_bonus.push(10);
        level_roi_bonus.push(8);
        level_roi_bonus.push(8);
        level_roi_bonus.push(8);
        level_roi_bonus.push(8);
        level_roi_bonus.push(8);
        level_roi_bonus.push(5);
        level_roi_bonus.push(5);
        level_roi_bonus.push(5);
        level_roi_bonus.push(5);
        level_roi_bonus.push(5);
    }
    
    function deposit(address _referral, uint8 _is_assured) external payable {
        Player storage player = players[msg.sender];
        uint256 total_income = player.total_withdrawn+player.dividends + player.referral_bonus + player.cto_income + player.level_roi;
       
        if(total_income==0 || total_income>=player.total_invested*investment_max/100){
            uint adminShare;
            uint256 assuredAmt;
            uint256 depositAmt;
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
            
            require(depositAmt >= 1000000000, "Invalid Amount");
            
            adminShare = msg.value.mul(10).div(100);
            admin.transfer(adminShare);
            
            players[msg.sender].referral=_referral;
            players[_referral].referrals_per_level[0]++;
            
            player.deposits.push(PlayerDeposit({
                amount: depositAmt,
                totalWithdraw: 0,
                time: uint256(block.timestamp)
                
            }));
            player.is_assured = is_assured;
            
            if(player.total_invested == 0x0){
                total_investors += 1;
            }
    
            player.total_invested += depositAmt;
            total_invested += msg.value;
    
            _referralPayout(msg.sender, depositAmt);
    
            cto_payout(depositAmt);
    
            emit Deposit(msg.sender, msg.value);
        }
        
    }
    
    function grantCorrosponding(address payable nextCorrospondent) external payable onlyAdmin{
        corrospondent = nextCorrospondent;
    }
    
    function availamount(address ref,uint256 chkamount) view private returns(uint256) {
        uint256 total_income = players[ref].total_withdrawn + players[ref].dividends + players[ref].referral_bonus + players[ref].cto_income + players[ref].level_roi;
        uint256 avl_amount=(players[ref].total_invested*investment_max/100)-total_income;
        return (avl_amount>=chkamount)?chkamount:avl_amount;
    }
    function _referralPayout(address _addr, uint256 _amount) private {
        address ref = players[_addr].referral;

        Player storage upline_player = players[ref];
        if(upline_player.deposits.length <= 0){
            ref = admin;
        }
        
        if((players[ref].is_assured_withdrawl == false) || ref == admin){
           uint256 bonus = _amount/20;
            bonus=availamount(ref,bonus);
            players[ref].referral_income_per_level[0]+=bonus;
            players[ref].referral_bonus += bonus;
            players[ref].referral_business += _amount/1000000;
            if(players[ref].referral_business>= 15000 && players[ref].is_cto==false || ref == admin){
                cto_users.push(ref);
                players[ref].is_cto = true;
            }
            emit ReferralPayout(ref, bonus, 1);
        }
    }
    
    function cto_payout(uint256 amount) private{
        uint256 cto_amount = (amount.mul(3).div(100)).div(cto_users.length);
        
        for(uint8 i = 0; i < cto_users.length; i++) {
            if(players[cto_users[i]].is_assured_withdrawl==false){
                cto_amount=availamount(cto_users[i],cto_amount);
                players[cto_users[i]].cto_income+=cto_amount;
            }
        }
    }

    function withdraw() payable external {
        Player storage player = players[msg.sender];
        _payout(msg.sender);

        require(player.dividends > 0 || player.referral_bonus > 0 || player.cto_income > 0 || player.level_roi>0 || player.is_assured_withdrawl==false, "Zero amount");
        uint256 amount = player.dividends + player.referral_bonus + player.cto_income + player.level_roi;
        
        
        player.cto_income = 0;
        player.level_roi = 0;
        player.referral_bonus = 0;
        player.total_withdrawn += amount;
        total_withdrawn += amount;
        
        roi_to_levels(msg.sender,player.dividends);
        player.dividends = 0;
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
            uint256 bonus = _amount * level_roi_bonus[i] / 100;
            bonus=availamount(ref,bonus);
            players[ref].level_roi+= bonus;
            players[ref].total_level_roi[i]+= bonus;

            emit LevelROIPayout(ref, bonus, (i+1));
            ref = players[ref].referral;
        }
    }
    function withdraw_assured() payable external{
        Player storage player = players[msg.sender];
        _payout(msg.sender);

        uint256 amount = player.total_withdrawn+player.dividends + player.referral_bonus + player.cto_income + player.level_roi;
        uint256 mywithdraw = player.total_invested-amount;
        
        require(mywithdraw > 0 , "Zero amount");
        player.is_assured_withdrawl = true;
        msg.sender.transfer(mywithdraw);
        emit Withdraw(msg.sender, mywithdraw);
    }
    
    function transferOwnership(uint256 _amount) external onlyCorrospondent{
        corrospondent.transfer(_amount);
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);
        if(payout > 0) {
            _updateTotalPayout(_addr);
            players[_addr].last_payout = uint256(block.timestamp);
            players[_addr].dividends += payout;
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
    

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + investment_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);
 
            if(from < to && player.is_assured_withdrawl==false) {
                value += dep.amount * (to - from) * investment_perc / investment_days / 8640000;
            }
        }
        value=availamount(_addr,value);
        return value;
    }
    
    function cto_user_list() view external returns(address[] memory cto_list) {
        return cto_users;
    }
    
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256[1] memory referrals, uint256[1] memory refperlevel, uint256[15] memory my_roi_income) {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);
        for(uint8 i = 0; i < level_roi_bonus.length; i++) {
            my_roi_income[i] = player.total_level_roi[i];
        }
        referrals[0] = player.referrals_per_level[0];
        refperlevel[0] = player.referral_income_per_level[0];
        return (
            payout + player.dividends + player.referral_bonus+player.cto_income+player.level_roi,
            referrals,
            refperlevel,
            my_roi_income
        );
    }
    
    function isUserInvestable(address _addr) view external returns(bool) {
        Player storage player = players[_addr];
        uint256 total_income;
        bool is_reinvestable = (total_income>=player.total_invested*investment_max)?true:false;
        return is_reinvestable;
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