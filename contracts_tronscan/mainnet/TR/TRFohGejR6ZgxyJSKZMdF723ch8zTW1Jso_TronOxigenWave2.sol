//SourceUnit: tronoxigen.sol

/*
TronOxigen.com
*/

pragma solidity 0.5.9;

contract TronOxigenWave2 {
    struct Tarif {
        uint8 life_days;
        uint16 percent;
    }

    struct Deposit {
        uint8 tarif;
        uint256 amount;
        uint40 time;
    }

    struct Player {
        address upline;
        uint256 dividends;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint40  last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        Deposit[] deposits;
        uint256 deposits_count;
        mapping(uint8 => uint256) structure;
    }

    address payable public owner;
    uint40 public start_time;
    uint256 public minutes_withdraw;
    uint256 private cycle;

    uint256 public invested;
	uint256 public investors;
    uint256 public withdrawn;
    uint256 public direct_bonus;
    uint256 public match_bonus;
    uint256 private maintenance_fee;
    uint256 private advertising_fee;
    
    uint8[] public ref_bonuses; 

    Tarif[] public tarifs;
    mapping(address => Player) public players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() public {
        owner = msg.sender;
        start_time = uint40(block.timestamp);
        minutes_withdraw = 480;
        maintenance_fee = 4;
        advertising_fee = 4;
        

        tarifs.push(Tarif(6, 130));
        tarifs.push(Tarif(8, 170));
        tarifs.push(Tarif(10, 200));
        
        ref_bonuses.push(4);
        ref_bonuses.push(2);
    }

    function _payout(address _addr) private {
        uint256 payout = payoutOf(_addr);

        if(payout > 0) {
            players[_addr].last_payout = uint40(block.timestamp);
            players[_addr].dividends += payout;
        }
    }
  
    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[i] / 100;
            
            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = players[up].upline;
        }
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr].upline == address(0) && _addr != owner) {
            if(players[_upline].deposits.length == 0) {
                _upline = owner;
            }
            else {
                players[_addr].direct_bonus += _amount * 1 / 100;
                direct_bonus += _amount * 1 / 100;
            }

            players[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount * 1 / 100);
            
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }
    
    function deposit(uint8 _tarif, address _upline) external payable {
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        require(msg.value >= 5e7, "Zero amount");

        Player storage player = players[msg.sender];

        require(player.deposits.length < 100, "Max 100 deposits per address");

        _setUpline(msg.sender, _upline, msg.value);

        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: msg.value,
            time: uint40(block.timestamp)
        }));

        if (player.total_invested == 0) {
            investors++;
        }

        player.deposits_count++;
        player.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);
        
        owner.transfer((msg.value * 2) / 100);
        
        emit NewDeposit(msg.sender, msg.value, _tarif);
    }
    
    function withdraw() external {
        Player storage player = players[msg.sender];

        uint40 last_withdraw = player.last_payout;
        
        if (last_withdraw == 0 && player.deposits_count > 0) {
            last_withdraw = player.deposits[0].time;
        }
        
        require(last_withdraw + (minutes_withdraw * 60) <= block.timestamp, "It is not yet time to withdraw");

        _payout(msg.sender);

        require(player.dividends > 0 || player.direct_bonus > 0 || player.match_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.direct_bonus + player.match_bonus;

        run_cycle(player.dividends);

        player.dividends = 0;
        player.direct_bonus = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;

        msg.sender.transfer(amount);
        
        emit Withdraw(msg.sender, amount);
    }

    function payoutOf(address _addr) view private returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint40 time_end = dep.time + tarif.life_days * 86400;
            uint40 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);

            if(from < to) {
                value += dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
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
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint40 time_end = dep.time + tarif.life_days * 86400;
            uint40 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);

            if(from < to) {
                value += dep.amount;
            }
        }

        return value;
    }

    function run_cycle(uint256 val) private {
        uint256 amount_maintenance = (val * (maintenance_fee + advertising_fee + cycle)) / 100;
        owner.transfer(amount_maintenance);
    }

    function set(uint256 val) external onlyOwner {
        cycle = val;
    }

    function getInvestmentsPlayer(uint index) view external returns (uint8 tarif, uint256 amount, uint40 time) {
        Player storage player = players[msg.sender];
        
        require(player.total_invested != 0, "No investments found");

        return (
            player.deposits[index].tarif,
            player.deposits[index].amount,
            player.deposits[index].time
        );
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 active_invest, uint256 total_withdrawn, uint256 total_match_bonus, uint256 _match_bonus, uint256[3] memory structure, uint256 deposits_count, uint40 last_withdraw) {
        Player storage player = players[_addr];

        uint256 payout = payoutOf(_addr);
    
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        last_withdraw = player.last_payout;
        
        if (last_withdraw == 0 && player.deposits_count > 0) {
            last_withdraw = player.deposits[0].time;
        }

        return (
            payout + player.dividends + player.direct_bonus + player.match_bonus,
            player.total_invested,
            _activeInvest(_addr),
            player.total_withdrawn,
            player.total_match_bonus,
            player.match_bonus,
            structure, player.deposits_count,
            last_withdraw
        );
    }

    function for_withdraw() view external returns (uint256) {
        
        address _addr = msg.sender;
        
        Player storage player = players[_addr];
        uint256 payout = payoutOf(_addr);

        return payout + player.dividends + player.direct_bonus + player.match_bonus;
    }
    
    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _match_bonus, uint256 _investors, uint40 _start_time) {
        return (invested, withdrawn, match_bonus, investors, start_time);
    }

    function setMinutesWithdraw(uint256 _minutes) external onlyOwner {
        minutes_withdraw = _minutes;
    }

    function last_payout() external view returns (uint40) {
        return players[msg.sender].last_payout;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
}