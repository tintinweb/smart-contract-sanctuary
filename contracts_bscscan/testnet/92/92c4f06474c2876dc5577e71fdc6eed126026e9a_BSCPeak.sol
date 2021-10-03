/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

pragma solidity 0.5.9;

contract BSCPeak {
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
        uint256 total_referral_bonus;
		uint256 total_ref_invested;
        uint256 growth_bonus;
        uint256 cash_back;
        PlayerDeposit[] deposits;
        mapping(uint8 => uint256) referrals_per_level;
    }

    address payable owner;
    address payable addr1;
    address payable addr2;
    address payable addr3;
    address payable addr4;

    uint8 investment_days;
    uint256 investment_perc;
    uint256 donation_perc;

    uint256 total_investors;
    uint256 total_invested;
    uint256 total_withdrawn;
    uint256 total_referral_bonus;

    uint256[][] public referral_bonuses = [
		[20, 2, 1],
		[24, 4, 2],
		[30, 6, 3]
	];

    mapping(address => Player) public players;
    address[] all_players;

    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);

    uint256[] growth_limit = [5,4,3,2,1];

    constructor(address payable _addr1, address payable _addr2, address payable _addr3, address payable _addr4) public {
        require(_addr1 != address(0) && _addr2 != address(0) && _addr3 != address(0) && _addr4 != address(0));

        owner = msg.sender;
        addr1 = _addr1;
        addr2 = _addr2;
        addr3 = _addr3;
        addr4 = _addr4;

        donation_perc = 50;     // 50% from withdrawal amount will be donated to the contract

        investment_days = 250;  // 250  Total Days
        investment_perc = 250;  // 250% Total ROI
    }

    function() external payable {
        if (msg.value > 0) {
            deposit(_bytesToAddress(bytes(msg.data)));
        } else {
            withdraw();
        }
    }

    function deposit(address _referral) public payable {
        require(msg.value >= 1e17, "Minimal deposit: 0.1 BNB");
        Player storage player = players[msg.sender];
        require(player.deposits.length < 20000, "Max 20000 deposits per address");

        _updateGrowth();

        _setReferral(msg.sender, _referral);

        player.deposits.push(PlayerDeposit({
            amount: msg.value,
            totalWithdraw: 0,
            time: block.timestamp
        }));

        if(player.total_invested == 0x0){
            total_investors += 1;
            all_players.push(msg.sender);
        }

        player.total_invested += msg.value;

        cashBack(msg.sender, msg.value);

        total_invested += msg.value;

        _referralPayout(msg.sender, msg.value);

        owner.transfer(msg.value.mul(15).div(100));
        addr1.transfer(6e15); // 0.006 bnb
        addr2.transfer(2e15); // 0.002 bnb
        addr3.transfer(2e15); // 0.002 bnb
        addr4.transfer(3e15); // 0.003 bnb

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

            for(uint8 i = 0; i < 3; i++) {
                players[_referral].referrals_per_level[i]++;
                _referral = players[_referral].referral;
                if(_referral == address(0)) break;
            }
        }
    }

    function _referralPayout(address _addr, uint256 _amount) private {
         address ref = players[_addr].referral;

        Player storage upline_player = players[ref];

        if (upline_player.deposits.length <= 0){
            ref = addr1;
        }

        for(uint8 i = 0; i < 3; i++) {
            if(ref == address(0)) break;

            uint256 percent = getUserReferralPercent(ref, i);

            uint256 bonus = _amount.mul(percent).div(100);

            players[ref].referral_bonus += bonus;
            players[ref].total_referral_bonus += bonus;
            players[ref].total_ref_invested += _amount;
            total_referral_bonus += bonus;

            emit ReferralPayout(ref, bonus, (i+1));
            ref = players[ref].referral;
        }
    }

    function withdraw() payable public {
        Player storage player = players[msg.sender];

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
                player.deposits[i].totalWithdraw += dep.amount * (to - from) * investment_perc / investment_days / 8640000;  // 100 Days
            }
        }
    }

    function getUserReferralPercent(address userAddress, uint256 level) public view returns (uint256) {
		Player memory player = players[userAddress];

		if (player.total_ref_invested >= 3000000e18) { // 3 000 000 bnb
			return referral_bonuses[2][level];
		} else if (player.total_ref_invested >= 10000000e18) { // 1 000 000 bnb
			return referral_bonuses[1][level];
		} else {
			return referral_bonuses[0][level];
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

    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_referral_bonus, uint256 invested, uint256 withdrawn, uint256 referral_bonus, uint256 total_ref_invested, uint256[8] memory referrals, uint256 _last_withdrawal, uint256 cash_back,uint256 growth) {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);


        uint256 growth_percentage = investment_perc.div(investment_days) + this.growthtOf();

        for(uint8 i = 0; i < 3; i++) {
            referrals[i] = player.referrals_per_level[i];
        }
        return (
            payout + player.dividends + player.referral_bonus,
            player.referral_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_referral_bonus,
            player.total_ref_invested,
            referrals,
            player.last_payout,
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

    function _bytesToAddress(bytes memory _source) internal pure returns(address parsedreferrer) {
        assembly {
            parsedreferrer := mload(add(_source,0x14))
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