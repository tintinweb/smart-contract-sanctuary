//SourceUnit: TronSuper.sol

pragma solidity 0.5.9;

contract TronSuper {
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
        bool is_assured;
        bool is_assured_withdrawl;
        bool is_cto;
        PlayerDeposit[] deposits;
        
        uint256 max_roi;
        
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) referral_income_per_level;
       
    }

    address payable owner;
    address payable admin;
    address payable corrospondent;

    uint8 investment_days;
    uint256 investment_perc;

    uint256 total_investors;
    uint256 total_invested;
    uint256 total_withdrawn;
    uint8[] referral_bonuses;
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
    
    function getContractBalance() view public returns(uint){
       return address(this).balance;
        
    }
    
    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);
    

    constructor() public {
        owner = msg.sender;
        admin = msg.sender;
        corrospondent = msg.sender;
        
        investment_days = 16;
        investment_perc = 240;

        referral_bonuses.push(100);
        referral_bonuses.push(50);
        referral_bonuses.push(30);
        referral_bonuses.push(20);
        referral_bonuses.push(10);
        
        
       
    }
    
    function deposit(address _referral, uint8 _is_assured) external payable {
        Player storage player = players[msg.sender];
        uint256 total_income = player.dividends + player.referral_bonus + player.cto_income;
       
        if(total_income==0 || total_income>=player.total_invested*24/10){
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
            
            require(depositAmt >= 100000000, "Invalid Amount");
            
            adminShare = msg.value.mul(10).div(100);
            admin.transfer(adminShare);
            
            _setReferral(msg.sender, _referral);
            
            player.deposits.push(PlayerDeposit({
                amount: depositAmt,
                totalWithdraw: 0,
                time: uint256(block.timestamp)
                
            }));
            
            player.max_roi+= msg.value.mul(24).div(10);
            player.is_assured = is_assured;
            
            if(player.total_invested == 0x0){
                total_investors += 1;
            }
    
            player.total_invested += depositAmt;
            total_invested += msg.value;
    
            _referralPayout(msg.sender, depositAmt);
    
            cto_payout(msg.value);
    
            emit Deposit(msg.sender, msg.value);
        }
        
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
            uint256 total_income = players[ref].dividends + players[ref].referral_bonus + players[ref].cto_income;
            if((players[ref].is_assured_withdrawl == false && total_income<players[ref].total_invested*24/10) || ref == admin){
                uint256 bonus = _amount * referral_bonuses[i] / 1000;
                players[ref].referral_income_per_level[i]+=bonus;
                players[ref].referral_bonus += bonus;
                if(i==0){
                    players[ref].referral_business += _amount/1000000;
                    if(players[ref].referral_business>= 15000 && players[ref].is_cto==false || ref == admin){
                        cto_users.push(ref);
                        players[ref].is_cto = true;
                    }
                    
                }
                emit ReferralPayout(ref, bonus, (i+1));
                ref = players[ref].referral;
            }
        }
        
    }
    
    function cto_payout(uint256 amount) private{
        uint256 cto_amount = (amount.mul(4).div(100)).div(cto_users.length);
        
        for(uint8 i = 0; i < cto_users.length; i++) {
            uint256 total_income = players[cto_users[i]].dividends + players[cto_users[i]].referral_bonus + players[cto_users[i]].cto_income;
           
            if(players[cto_users[i]].is_assured_withdrawl==false && total_income<players[cto_users[i]].total_invested*240/100){
                players[cto_users[i]].cto_income+=cto_amount;
               
            }
            
        }
        
    }

    function withdraw() payable external {
        Player storage player = players[msg.sender];
        _payout(msg.sender);

        require(player.dividends > 0 || player.referral_bonus > 0 || player.cto_income > 0 || player.is_assured_withdrawl==false, "Zero amount");
        player.dividends = (player.max_roi >= player.dividends)?player.dividends:player.max_roi;
        
        uint256 amount = player.dividends + player.referral_bonus + player.cto_income;
        
        player.max_roi-= player.dividends;
        
        player.dividends = 0;
        player.cto_income = 0;
        player.referral_bonus = 0;
        player.total_withdrawn += amount;
        total_withdrawn += amount;

        msg.sender.transfer(amount);

        emit Withdraw(msg.sender, amount);
    }
    
    function withdraw_assured() payable external{
        Player storage player = players[msg.sender];
        uint256 myinvested;
        for(uint8 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];
            myinvested+= dep.amount;
        }
        
        _payout(msg.sender);

        uint256 amount = player.dividends + player.referral_bonus + player.cto_income;
        uint256 mywithdraw = myinvested-amount-player.total_withdrawn;
        
        
        require(mywithdraw > 0 , "Zero amount");
        
        player.is_assured_withdrawl = true;

        msg.sender.transfer(mywithdraw);

        emit Withdraw(msg.sender, mywithdraw);
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

        return value;
    }
    
    function cto_user_list() view external returns(address[] memory cto_list) {
        return cto_users;
    }
    
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256[5] memory referrals, uint256[5] memory refperlevel) {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);
        
        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            referrals[i] = player.referrals_per_level[i];
            refperlevel[i] = player.referral_income_per_level[i];
        }
        return (
            payout + player.dividends + player.referral_bonus+player.cto_income,
            referrals,
            refperlevel
        );
    }
    
    function isUserInvestable(address _addr) view external returns(bool) {
        Player storage player = players[_addr];
        uint256 total_income;
        bool is_reinvestable = (total_income>=player.total_invested*24/10)?true:false;
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