//SourceUnit: SC4TEST.sol

pragma solidity 0.5.9;

contract TronKing {
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

    struct TopCount {
        uint count;
        address addr;
    }
    mapping(uint8 => mapping(uint8 => TopCount)) public tops;

    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    address payable marketing;
    address payable development;
    address payable shareholder;
    address payable promotioncn;
    address payable promotionir;
	address payable promotionin;

    mapping(address => Player) public players;

    uint8[] public referral_bonuses;

    constructor(address payable _marketing, address payable _development, address payable _share, address payable _promocn, address payable _promoir, address payable _promoin) public {

        referral_bonuses.push(50);
        referral_bonuses.push(25);
        referral_bonuses.push(10);
        referral_bonuses.push(5);
        referral_bonuses.push(5);
        referral_bonuses.push(5);

        marketing = _marketing;
		development = _development;
		shareholder = _share;
		promotioncn = _promocn;
		promotionir = _promoir;
		promotionin = _promoin;
    }

    function deposit(address _referral) external payable {
        require(msg.value >= 1e7, "Zero amount");
        require(msg.value >= 100000000, "Minimum deposit: 100 TRX");
        Player storage pl = players[msg.sender];
        require(pl.deposits.length < 250, "Maximum 250 deposits per address");

        _setReferral(msg.sender, _referral);

        pl.deposits.push(PlayerDeposit({
            amount: msg.value,
            withdrawn: 0,
            timestamp: uint256(block.timestamp)
        }));

        if(pl.first_deposit == 0){
            pl.first_deposit = block.timestamp;
			total_investors += 1;		
        }

        elaborateTopX(1, msg.sender, (pl.total_invested + msg.value));

		pl.total_invested += msg.value;
        total_invested += msg.value;

        _referralPayout(msg.sender, msg.value);

        marketing.transfer(msg.value.div(50));
		development.transfer(msg.value.div(25));
		shareholder.transfer(msg.value.div(40));
		promotioncn.transfer(msg.value.div(200));
		promotionir.transfer(msg.value.div(200));
		promotionin.transfer(msg.value.div(200));

        emit Deposit(msg.sender, msg.value);
    }

    function _setReferral(address _addr, address _referral) private {
        if(players[_addr].referral == address(0)) {
            if(_referral == address(0) || _referral == msg.sender){ _referral = marketing; }
            players[_addr].referral = _referral;

            for(uint8 i = 0; i < referral_bonuses.length; i++) {
				if(_referral == address(0) || _referral == msg.sender) break;
				players[_referral].referrals_per_level[i]++;
                _referral = players[_referral].referral;
            }
        }
    }

    function _referralPayout(address _addr, uint256 _amount) private {
        address ref = players[_addr].referral;

        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            if(ref == address(0) || ref == msg.sender) break;

            uint256 bonus = _amount * referral_bonuses[i] / 1000;

            players[ref].referral_bonus += bonus;
            players[ref].total_referral_bonus += bonus;
            players[ref].payouts_per_level[i] += bonus;
			if(i == 0){ elaborateTopX(0, ref, players[ref].payouts_per_level[i]); }
            total_referral_bonus += bonus;

            ref = players[ref].referral;
        }
    }

    function withdraw() payable external {
        Player storage player = players[msg.sender];
		require(now.sub(player.last_withdraw) >= 43200, "allowed once every 12 hours");

        _payout(msg.sender);

        require(player.dividends > 0 || player.referral_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.referral_bonus;
		
        player.dividends = 0;
        player.referral_bonus = 0;
        player.total_withdrawn += amount;
        total_withdrawn += amount;
		
		msg.sender.transfer(amount);

        emit Withdraw(msg.sender, amount);	
		
		_WithdrawComm(msg.sender, amount);
    }
	
	function _WithdrawComm(address _addr, uint256 _amount) private {
        address ref = players[_addr].referral;

            uint256 bonus = _amount * 30 / 1000;

            players[ref].referral_bonus += bonus;
            players[ref].total_referral_bonus += bonus;
            players[ref].payouts_per_level[0] += bonus;
			elaborateTopX(0, ref, players[ref].payouts_per_level[0]);
            total_referral_bonus += bonus;

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

    function playerStats(address _adr) view external returns(uint16 _referral_bonus, uint16 _whale_bonus, uint16 _strong_hand_bonus, uint16 _top_ref_bonus, uint16 _top_whale_bonus, uint16 _roi, uint16 _basicroi){
        return(_referralBonus(_adr), _whaleBonus(_adr), _strongHandBonus(_adr), _topReferralBonus(_adr), _topWhaleBonus(_adr), _getPlayerRate(_adr), _getBasicRate());
    }

    function playerInfo(address _adr) view external returns(uint256 _total_invested, uint256 _total_withdrawn, uint256 _last_withdrawn, uint256 _referral_bonus, uint256 _roi_incomes, uint256 _available){
        Player memory pl = players[_adr];
        return(pl.total_invested, pl.total_withdrawn, pl.last_withdraw, pl.referral_bonus, (pl.dividends + this.payoutOf(_adr)), (pl.dividends + pl.referral_bonus + this.payoutOf(_adr)));
    }

    function playerReferrals(address _adr) view external returns(uint256[] memory ref_count, uint256[] memory ref_earnings, uint256 zero_comms, uint256 tot_comms){
        uint256[] memory _ref_count = new uint256[](6);
        uint256[] memory _ref_earnings = new uint256[](6);
		uint256 tot_comms;
		uint256 zero_comms;
        Player storage pl = players[_adr];

        for(uint8 i = 0; i < 6; i++){
            _ref_count[i] = pl.referrals_per_level[i];
            _ref_earnings[i] = pl.payouts_per_level[i];
			tot_comms += pl.payouts_per_level[i];
			if(i == 0){ zero_comms += pl.payouts_per_level[0].mul(20); }
        }

        return (_ref_count, _ref_earnings, zero_comms, tot_comms);
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

    function _referralBonus(address _adr) view private returns(uint16){
        Player storage pl = players[_adr];
        uint256 c = pl.payouts_per_level[0].mul(20);
        uint16 _bonus = 0;
        if(c >= 1000000000000){ _bonus = 150; }
        else if(c >= 200000000000){ _bonus = 75; }
        else if(c >= 50000000000){ _bonus = 50; }
        else if(c >= 10000000000){ _bonus = 30; }
        else if(c >= 2500000000){ _bonus = 20; }
        else if(c >= 500000000){ _bonus = 10; }
        return _bonus;
    }

    function _whaleBonus(address _adr) view private returns(uint16){
        Player storage pl = players[_adr];
        uint256 cur_investment = pl.total_invested;
        uint16 _bonus = 0;
        if(cur_investment >= 1000000000000){ _bonus = 150; }
        else if(cur_investment >= 200000000000){ _bonus = 75; }
        else if(cur_investment >= 50000000000){ _bonus = 50; }
        else if(cur_investment >= 10000000000){ _bonus = 30; }
        else if(cur_investment >= 2500000000){ _bonus = 20; }
		else if(cur_investment >= 500000000){ _bonus = 10; }
        return _bonus;
    }

    function _strongHandBonus(address _adr) view private returns(uint16){
        Player storage pl = players[_adr];
		uint16 sh;
		if(pl.last_withdraw == 0){ sh = uint16(((block.timestamp - pl.first_deposit)/86400)*15); }
		if(pl.last_withdraw != 0){ sh = uint16(((block.timestamp - pl.last_withdraw)/86400)*15); }
		if(sh > 300){ sh = 300; }
		if(pl.first_deposit == 0){ sh = 0; }
        return sh;
    }

    function _contractBonus() view private returns(uint16){
        uint16 cb = uint16(((address(this).balance/1000000)/100000)*3);
		if(cb > 300){ cb = 300; }
        return cb;
    }

    function _topReferralBonus(address _adr) view private returns(uint16){
        uint16 bonus = 0;
        for(uint8 i = 0; i < 10; i++){
            if(tops[0][i].addr == _adr){
                if(i == 0){ bonus = 300; }
                else if(i == 1){ bonus = 150; }
                else if(i == 2){ bonus = 100; }
				else if(i == 3){ bonus = 50; }
                else if(i == 4){ bonus = 50; }
				else if(i == 5){ bonus = 25; }
                else if(i == 6){ bonus = 25; }
                else { bonus = 10; }
            }
        }
        return bonus;
    }

    function _topWhaleBonus(address _adr) view private returns(uint16){
        uint16 bonus = 0;
        for(uint8 i = 0; i < 10; i++){
            if(tops[1][i].addr == _adr){
                if(i == 0){ bonus = 300; }
                else if(i == 1){ bonus = 150; }
                else if(i == 2){ bonus = 100; }
				else if(i == 3){ bonus = 50; }
                else if(i == 4){ bonus = 50; }
				else if(i == 5){ bonus = 25; }
                else if(i == 6){ bonus = 25; }
                else { bonus = 10; }
            }
        }
        return bonus;
    }

    function _getPlayerRate(address _adr) view private returns(uint16){
        return (100 + _contractBonus() + _strongHandBonus(_adr) + _whaleBonus(_adr) + _referralBonus(_adr) + _topReferralBonus(_adr) + _topWhaleBonus(_adr));
    }
	
	function _getBasicRate() view private returns(uint16){
        return (100 + _contractBonus());
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