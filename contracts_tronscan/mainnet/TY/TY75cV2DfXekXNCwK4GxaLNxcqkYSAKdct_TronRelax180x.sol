//SourceUnit: TronRelax180x.sol

/*
TronRelax180x
*/

pragma solidity 0.5.9;

contract TronRelax180x {

    struct Tarif {
        uint8 life_days;
        uint256 percent;
    }
    
    struct DepositRef {
        address referred;
        uint8 tarif;
        uint256 amount;
        uint40 time;
    }

    struct Deposit {
        uint256 id;
        uint8 tarif;
        uint256 amount_ini;
        uint256 amount_end;
        uint256 amount_withdrawn;
        uint256 amount_ref;
        uint256 amount_low_ref;
        uint40 time;
        uint40 time_finish;
    }
    
    uint256 deposit_id = 0;
    
    mapping (uint256 => DepositRef[]) deposits_ref;
    mapping (uint256 => DepositRef[]) deposits_ref_low;
    mapping (address => DepositRef[]) pending_deposits_ref;
    mapping (address => DepositRef[]) pending_deposits_low_ref;
    uint8 public expiration_days_pending_deposits;

    struct Player {
        address upline;
        uint256 dividends;
        uint256 direct_bonus;
        uint256 match_bonus_hight;
        uint256 match_bonus_low;
        uint40  last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        Deposit[] deposits;
        uint256 deposits_count;
        mapping(uint8 => uint256) structure;
        bool allow_withdraw;
        uint40 time_last_deposit;
    }

    address payable public owner;
    uint40 public start_time;
    uint256 private _minutes_withdraw;

    /* extra percentage */
    uint256 private extra_factor_percentage;
    uint256 private amount_step_percentage;
    uint256 private limit_extra_percentage;

    uint256 public invested;
	uint256 public investors;
    uint256 public withdrawn;
    uint256 public direct_bonus;
    uint256 public match_bonus;
    uint256 private maintenance_fee;

    uint256 public soft_release;
    
    uint8[][] public ref_bonuses; 

    Tarif[] public tarifs;
    mapping(address => Player) public players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() public {
        owner = msg.sender;
        start_time = uint40(block.timestamp);
        _minutes_withdraw = 1440;
        maintenance_fee = 15;
        expiration_days_pending_deposits = 3;
        

        tarifs.push(Tarif(3, 180));
        tarifs.push(Tarif(4, 240));
        tarifs.push(Tarif(5, 300));
        
        ref_bonuses.push([10, 5]);
        ref_bonuses.push([5, 2]);
        ref_bonuses.push([2, 1]);

        extra_factor_percentage = 1;
        amount_step_percentage = 100000;
        limit_extra_percentage = 10;

        soft_release = 1607316302;
    }

    function _payout(address _addr) private {
        uint256 payout = payoutOfWithdraw(_addr);

        if(payout > 0) {
            players[_addr].last_payout = uint40(block.timestamp);
            players[_addr].dividends += payout;
        }
    }
  
    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        if(up == address(0)) {
            return;
        }
        
        for(uint8 level = 0; level < ref_bonuses.length; level++) {
            if(up == address(0)) break;
            
            Player storage player = players[up];

            uint256 amount_to_distribute = _amount * ref_bonuses[level][0] / 100;

            bool with_deposits = false;

            for (uint256 i = 0; i < player.deposits.length; i++) {

                if (amount_to_distribute <= 0) {
                    break;
                }

                Deposit memory dep = player.deposits[i];

                uint256 deposit_profit;
                uint256 diff_amount;
                
                if (dep.time_finish > uint40(block.timestamp)) {
                    deposit_profit = payoutOfDeposit( dep, player );
                    
                    if (deposit_profit + dep.amount_withdrawn < dep.amount_end) {
                        with_deposits = true;
                        diff_amount = dep.amount_end - (deposit_profit + dep.amount_withdrawn);
                        
                        if ( diff_amount <= amount_to_distribute ) {
                            player.deposits[i].amount_ref += diff_amount;
                            match_bonus += diff_amount;
                            player.total_match_bonus += diff_amount;
                            player.match_bonus_hight += diff_amount;
                            amount_to_distribute -= diff_amount;

                            deposits_ref[dep.id].push(DepositRef(_addr, ref_bonuses[level][0], diff_amount, uint40(block.timestamp)));
                        }
                        else {
                            player.deposits[i].amount_ref += amount_to_distribute;
                            match_bonus += amount_to_distribute;
                            player.total_match_bonus += amount_to_distribute;
                            player.match_bonus_hight += amount_to_distribute;

                            deposits_ref[dep.id].push(DepositRef(_addr, ref_bonuses[level][0], amount_to_distribute, uint40(block.timestamp)));

                            amount_to_distribute = 0;

                        }
                        
                    }
                }

            }

            if (amount_to_distribute > 0) {

                if (!with_deposits) {
                    if (up == owner) {
                        amount_to_distribute = _amount * ref_bonuses[level][0] / 100;
                        owner.transfer(amount_to_distribute);
                    }
                    else {
                        amount_to_distribute = _amount * ref_bonuses[level][1] / 100;
                        pending_deposits_low_ref[up].push(DepositRef(_addr, ref_bonuses[level][1], amount_to_distribute, uint40(block.timestamp)));
                        //player.match_bonus_low += amount_to_distribute;
                        player.total_match_bonus += amount_to_distribute;
                    }
                    

                }
                else {
                    if (up == owner) {
                        owner.transfer(amount_to_distribute);
                    }
                    else {
                        pending_deposits_ref[up].push(DepositRef(_addr, ref_bonuses[level][0], amount_to_distribute, uint40(block.timestamp)));
                        player.total_match_bonus += amount_to_distribute;
                    }
                }

                match_bonus += amount_to_distribute;

            }

            up = players[up].upline;
        }

    }

    function _setUpline(address _addr, address _upline) private {
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
    
    function deposit(uint8 _tarif, address _upline) external payable {
        require(uint256(block.timestamp) > soft_release, "Not launched");
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        require(msg.value >= 1e8, "Minimum investment is 100 trx");

        Player storage player = players[msg.sender];

        require(player.deposits.length < 100, "Max 100 deposits per address");

        _setUpline(msg.sender, _upline);

        uint256 payout = payoutOf(msg.sender);
        if (payout == 0) {
            player.time_last_deposit =  uint40(block.timestamp);
        }
        
        player.deposits.push(Deposit({
            id: ++deposit_id,
            tarif: _tarif,
            amount_ini: msg.value,
            amount_end: ( (msg.value * tarifs[_tarif].percent) / 100 ),
            amount_withdrawn: 0,
            amount_ref: 0,
            amount_low_ref: 0,
            time: uint40(block.timestamp),
            time_finish: uint40(block.timestamp) + uint40( tarifs[_tarif].life_days * 86400 )
        }));

        if (player.total_invested == 0) {
            investors++;
        }

        player.deposits_count++;
        player.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);
        distribute_amount_pending_referrals(msg.sender);
        
        owner.transfer((msg.value * 5) / 100);
        
        emit NewDeposit(msg.sender, msg.value, _tarif);
    }

    /*
    Distribuye en el último depósito los valores de los referidos pendientes
    */
    function distribute_amount_pending_referrals(address _addr) private {

        Player storage player = players[_addr];

        Deposit storage dep = player.deposits[player.deposits.length-1];

        bool procesa = false;

        DepositRef[] storage pending_deposits = pending_deposits_ref[_addr];
        DepositRef[] storage pending_deposits_low = pending_deposits_low_ref[_addr];

        if (pending_deposits.length == 0 && pending_deposits_low.length == 0) return;

        for (uint256 i = 0; i < pending_deposits.length; i++) {
            uint256 referral_amount = pending_deposits[i].amount;
            uint256 diff;

            if (pending_deposits[i].time + (expiration_days_pending_deposits * 86400) > uint40(block.timestamp)) {
                if ( dep.amount_ref + dep.amount_low_ref < dep.amount_end ) {
                    diff = dep.amount_end - (dep.amount_ref + dep.amount_low_ref);

                    if (diff > referral_amount) {
                        dep.amount_ref += referral_amount;
                        deposits_ref[dep.id].push( DepositRef(pending_deposits[i].referred, pending_deposits[i].tarif, referral_amount, pending_deposits[i].time) );
                        pending_deposits[i].amount = 0;
                        player.match_bonus_hight += referral_amount;
                    }
                    else {
                        dep.amount_ref += diff;
                        deposits_ref[dep.id].push( DepositRef(pending_deposits[i].referred, pending_deposits[i].tarif, diff, pending_deposits[i].time) );
                        pending_deposits[i].amount -= diff;
                        player.match_bonus_hight += diff;
                    }

                    procesa = true;
                }
                else {
                    break;
                }
            }
        }

        for (uint256 i = 0; i < pending_deposits_low.length; i++) {
            uint256 referral_amount = pending_deposits_low[i].amount;
            uint256 diff;

            if (pending_deposits_low[i].time + (expiration_days_pending_deposits * 86400) > uint40(block.timestamp)) {
                if ( dep.amount_ref + dep.amount_low_ref < dep.amount_end ) {
                    diff = dep.amount_end - (dep.amount_ref + dep.amount_low_ref);

                    if (diff > referral_amount) {
                        dep.amount_low_ref += referral_amount;
                        deposits_ref_low[dep.id].push( DepositRef(pending_deposits_low[i].referred, pending_deposits_low[i].tarif, referral_amount, pending_deposits_low[i].time) );
                        pending_deposits_low[i].amount = 0;
                        player.match_bonus_low += referral_amount;
                    }
                    else {
                        dep.amount_low_ref += diff;
                        deposits_ref_low[dep.id].push( DepositRef(pending_deposits_low[i].referred, pending_deposits_low[i].tarif, diff, pending_deposits_low[i].time) );
                        pending_deposits_low[i].amount -= diff;
                        player.match_bonus_low += diff;
                    }

                    procesa = true;
                }
                else {
                    break;
                }
            }

        }

        if (procesa) {
            clear_pending_deposit(_addr);
        }

    }

    /*
        Limpia los depósitos pendientes de referidos que hayan quedado en cero despúes de distribuírlos entre los depósitos del jugador.
    */
    function clear_pending_deposit(address _addr) private {
        

        for(uint8 level = 0; level < ref_bonuses.length; level++) {
            
            DepositRef[] memory _deposits_ref = pending_deposits_ref[_addr];

            uint256 id = 0;

            for (uint i = 0; i < _deposits_ref.length; i++){
                if (_deposits_ref[i].amount > 0) {
                    pending_deposits_ref[_addr][id++] = _deposits_ref[i];
                }
            }

            pending_deposits_ref[_addr].length = id;

            _deposits_ref = pending_deposits_low_ref[_addr];
            id = 0;

            for (uint i = 0; i < _deposits_ref.length; i++){
                if (_deposits_ref[i].amount > 0) {
                    pending_deposits_low_ref[_addr][id++] = _deposits_ref[i];
                }
            }

            pending_deposits_low_ref[_addr].length = id;
        }
    }
    
    function withdraw() external {
        Player storage player = players[msg.sender];

        uint40 last_withdraw = player.last_payout;
        
        if (last_withdraw == 0 && player.deposits_count > 0) {
            last_withdraw = player.deposits[0].time;
        }
        
        require( (last_withdraw + (_minutes_withdraw * 60) <= block.timestamp) || player.allow_withdraw, "It is not yet time to withdraw");

        _payout(msg.sender);

        require(player.dividends > 0, "Zero amount");

        uint256 amount = player.dividends;

        run_maintenance_fee(player.dividends);

        player.dividends = 0;
        player.direct_bonus = 0;
        player.match_bonus_hight = 0;
        player.match_bonus_low = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;

        msg.sender.transfer(amount);

        player.allow_withdraw = false;
        player.time_last_deposit = 0;
        
        emit Withdraw(msg.sender, amount);
    }

    function payoutOfDeposit(Deposit memory dep, Player storage player) view private returns(uint256 value) {

        Tarif memory tarif = tarifs[dep.tarif];
        uint256 value_profit;

        if (dep.amount_withdrawn < dep.amount_end) {
            uint40 time_end = dep.time + tarif.life_days * 86400;
            uint40 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);

            value_profit += dep.amount_ini * (to - from) * percent_profit(tarif.percent / tarif.life_days) / 86400000;
            // entre 86400 segundos
            // entre 100 porciento
            // Se divide entre 10 porque dentro de la funcion percent_profit se multiplica por 10 para poder devolver 1 decimal
            

            //value_profit -= dep.amount_withdrawn + deposits_ref[dep.id].amount + deposits_ref_low[dep.id].amount;
            //value_profit += dep.amount_ref + dep.amount_low_ref;

            if (value_profit + dep.amount_withdrawn + dep.amount_ref + dep.amount_low_ref >= dep.amount_end) {
                value_profit = dep.amount_end - dep.amount_withdrawn;
            }
            else {
                value_profit += dep.amount_ref + dep.amount_low_ref;
            }

            value += value_profit;
        }

        return value;
    }
    
    function payoutOf(address _addr) view private returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif memory tarif = tarifs[dep.tarif];
            uint256 value_profit;

            if (dep.amount_withdrawn < dep.amount_end) {
                uint40 time_end = dep.time + tarif.life_days * 86400;
                uint40 from = player.last_payout > dep.time ? player.last_payout : dep.time;
                uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);

                value_profit += dep.amount_ini * (to - from) * percent_profit(tarif.percent / tarif.life_days) / 86400000;
                //value_profit -= dep.amount_withdrawn + deposits_ref[dep.id].amount + deposits_ref_low[dep.id].amount;
                //value_profit += dep.amount_ref + dep.amount_low_ref;

                if (value_profit + dep.amount_withdrawn + dep.amount_ref + dep.amount_low_ref >= dep.amount_end) {
                    value_profit = dep.amount_end - dep.amount_withdrawn;
                }
                else {
                    value_profit += dep.amount_ref + dep.amount_low_ref;
                }

                value += value_profit;
            }
        }

        return value;
    }

    function payoutOfWithdraw(address _addr) private returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif memory tarif = tarifs[dep.tarif];
            uint256 value_profit;

            if (dep.amount_withdrawn < dep.amount_end) {
                uint40 time_end = dep.time + tarif.life_days * 86400;
                uint40 from = player.last_payout > dep.time ? player.last_payout : dep.time;
                uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);

                value_profit += dep.amount_ini * (to - from) * percent_profit(tarif.percent / tarif.life_days) / 86400000;
                //value_profit -= dep.amount_withdrawn + deposits_ref[dep.id].amount + deposits_ref_low[dep.id].amount;
                //value_profit += dep.amount_ref + dep.amount_low_ref;

                if (value_profit + dep.amount_withdrawn + dep.amount_ref + dep.amount_low_ref >= dep.amount_end) {
                    value_profit = dep.amount_end - dep.amount_withdrawn;
                }
                else {
                    value_profit += dep.amount_ref + dep.amount_low_ref;
                }

                dep.amount_withdrawn += value_profit;
                dep.amount_ref = 0;
                dep.amount_low_ref = 0;

                value += value_profit;
            }
        }

        return value;
    }

    function activeInvest(address _addr) external view onlyOwner returns(uint256) {
        return _activeInvest(_addr);
    }

    function activeInvest() external view returns(uint256) {
        return _activeInvest(msg.sender);
    }

    function _activeInvest(address _addr) private view returns(uint256) {
        Player storage player = players[_addr];
        uint256 value;

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit memory dep = player.deposits[i];
            Tarif memory tarif = tarifs[dep.tarif];

            uint40 time_end = dep.time + (tarif.life_days * 86400);
            uint40 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);

            if( from < to && (dep.amount_withdrawn + dep.amount_ref + dep.amount_low_ref) < dep.amount_end ) {
                value += dep.amount_ini;
            }

        }

        return value;
    }

    function run_maintenance_fee(uint256 val) private {
        uint256 amount_maintenance = (val * (maintenance_fee)) / 100;
        owner.transfer(amount_maintenance);
    }

    function getInvestmentsPlayer(uint256 index) view external returns (uint256 id, uint8 tarif, uint256 amount_ini,uint256 amount_withdrawn, uint256 amount_ref, uint256 amount_low_ref, uint40 time) {
        Player storage player = players[msg.sender];
        
        require(player.total_invested != 0, "No investments found");

        return (
            player.deposits[index].id,
            player.deposits[index].tarif,
            player.deposits[index].amount_ini,
            player.deposits[index].amount_withdrawn,
            player.deposits[index].amount_ref,
            player.deposits[index].amount_low_ref,
            player.deposits[index].time
        );

    }
    
    function getReferralsInvestmentPlayer(uint256 id) view external returns (address[] memory, uint8[] memory, uint256[] memory, uint40[] memory) {
        
        address[] memory referred;
        uint8[] memory tarif;
        uint256[] memory amount;
        uint40[] memory time;
        
        DepositRef[] memory refs = deposits_ref[id];
        
        for (uint256 i = 0; i < refs.length; i++) {
            referred[i] = refs[i].referred;
            tarif[i] = refs[i].tarif;
            amount[i] = refs[i].amount;
            time[i] = refs[i].time;
        }

        return (referred, tarif, amount, time);
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 active_invest, uint256 total_withdrawn, uint256 total_match_bonus, uint256[2] memory _match_bonus, uint256[3] memory structure, uint256 deposits_count, uint40 last_withdraw) {
        Player storage player = players[_addr];

        uint256 payout = payoutOf(_addr);
    
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        last_withdraw = player.last_payout;
        
        if (last_withdraw == 0 && player.deposits_count > 0) {
            last_withdraw = player.deposits[0].time;
        }

        if (player.time_last_deposit > 0) {
            last_withdraw = player.time_last_deposit;
        }
        
        return (
            payout,
            player.total_invested,
            _activeInvest(_addr),
            player.total_withdrawn,
            player.total_match_bonus,
            [player.match_bonus_hight, player.match_bonus_low],
            structure, player.deposits_count,
            last_withdraw
        );
        
    }

    function getDepositsPlayer(address _addr) external view returns (uint256[] memory id, uint8[] memory tarif, uint256[] memory amount_ini, uint256[] memory amount_withdrawn, uint256[] memory amount_ref, uint256[] memory amount_low_ref, uint40[] memory time) {

        Deposit[] memory deposits_player = players[_addr].deposits;
        
        id = new uint256[](deposits_player.length);
        tarif = new uint8[](deposits_player.length);
        amount_ini = new uint256[](deposits_player.length);
        amount_withdrawn = new uint256[](deposits_player.length);
        amount_ref = new uint256[](deposits_player.length);
        amount_low_ref = new uint256[](deposits_player.length);
        time = new uint40[](deposits_player.length);
        
        for (uint256 i = 0; i < deposits_player.length; i++) {
            id[i] = deposits_player[i].id;
            tarif[i] = deposits_player[i].tarif;
            amount_ini[i] = deposits_player[i].amount_ini;
            //amount_end[i] = deposits_player[i].amount_end;
            amount_withdrawn[i] = deposits_player[i].amount_withdrawn;
            amount_ref[i] = deposits_player[i].amount_ref;
            amount_low_ref[i] = deposits_player[i].amount_low_ref;
            time[i] = deposits_player[i].time;
            //time_finish[i] = deposits_player[i].time_finish;
        }

        return (id, tarif, amount_ini, amount_withdrawn, amount_ref, amount_low_ref, time);
    }

    function for_withdraw() view external returns (uint256) {
        
        address _addr = msg.sender;
        
        uint256 payout = payoutOf(_addr);

        return payout;
    }
    
    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _match_bonus, uint256 _investors, uint40 _start_time, uint256 balance) {
        uint256 _balance = address(this).balance;
        return (invested, withdrawn, match_bonus, investors, start_time, _balance);
    }

    function setMinutesWithdraw(uint256 _minutes) external onlyOwner {
        _minutes_withdraw = _minutes;
    }

    function last_payout() external view returns (uint40) {
        return players[msg.sender].last_payout;
    }

    function set_expiration_days_pending_deposits(uint8 _days) external onlyOwner {
        expiration_days_pending_deposits = _days;
    }

    function getPendingDepositsLowRef(address _addr) external view returns (address[] memory referred, uint8[] memory tarif, uint256[] memory amount, uint40[] memory time) {

        DepositRef[] memory pending = pending_deposits_low_ref[_addr];

        referred = new address[](pending.length);
        tarif = new uint8[](pending.length);
        amount = new uint256[](pending.length);
        time = new uint40[](pending.length);

        for (uint256 i = 0; i < pending.length; i++ ) {
            referred[i] = pending[i].referred;
            tarif[i] = pending[i].tarif;
            amount[i] = pending[i].amount;
            time[i] = pending[i].time;
        }

        return (referred, tarif, amount, time);
    }

    function getPendingDepositsRef(address _addr) external view returns (address[] memory referred, uint8[] memory tarif, uint256[] memory amount, uint40[] memory time) {

        DepositRef[] memory pending = pending_deposits_ref[_addr];

        referred = new address[](pending.length);
        tarif = new uint8[](pending.length);
        amount = new uint256[](pending.length);
        time = new uint40[](pending.length);

        for (uint256 i = 0; i < pending.length; i++ ) {
            referred[i] = pending[i].referred;
            tarif[i] = pending[i].tarif;
            amount[i] = pending[i].amount;
            time[i] = pending[i].time;
        }

        return (referred, tarif, amount, time);
    }

    function getDepositsRef(uint256 id) external view returns (address[] memory referred, uint8[] memory tarif, uint256[] memory amount, uint40[] memory time) {

        DepositRef[] memory deposits = deposits_ref[id];

        referred = new address[](deposits.length);
        tarif = new uint8[](deposits.length);
        amount = new uint256[](deposits.length);
        time = new uint40[](deposits.length);

        for (uint256 i = 0; i < deposits.length; i++ ) {
            referred[i] = deposits[i].referred;
            tarif[i] = deposits[i].tarif;
            amount[i] = deposits[i].amount;
            time[i] = deposits[i].time;
        }

        return (referred, tarif, amount, time);
    }

    function getDepositsRefLow(uint256 id) external view returns (address[] memory referred, uint8[] memory tarif, uint256[] memory amount, uint40[] memory time) {

        DepositRef[] memory deposits = deposits_ref_low[id];

        referred = new address[](deposits.length);
        tarif = new uint8[](deposits.length);
        amount = new uint256[](deposits.length);
        time = new uint40[](deposits.length);

        for (uint256 i = 0; i < deposits.length; i++ ) {
            referred[i] = deposits[i].referred;
            tarif[i] = deposits[i].tarif;
            amount[i] = deposits[i].amount;
            time[i] = deposits[i].time;
        }

        return (referred, tarif, amount, time);
    }

    function minutes_withdraw() external view returns (uint256) {
        Player memory player = players[msg.sender];

        return player.allow_withdraw ? 0 : _minutes_withdraw;
    }
    
    function percent_profit(uint256 tarif_base) private view returns (uint256) {

        uint256 extra_percent = (address(this).balance / 1000000) / amount_step_percentage;

        if (extra_percent > 0) {
            extra_percent = extra_percent * extra_factor_percentage;

            if (extra_percent > limit_extra_percentage) {
                if (limit_extra_percentage > 0) {
                    extra_percent = limit_extra_percentage;
                }
            }
        }

        return (tarif_base * 10) + extra_percent;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
}