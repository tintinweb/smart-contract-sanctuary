/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

// SPDX-License-Identifier: MIT License

pragma solidity >=0.8.0;

struct Tarif {
  uint16 life_days;
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

contract BNBUltimate {
    address public owner;
	
    uint256 public total_invested_alltime;
    uint256 public invested;
    uint256 public withdrawn;
    uint256 public match_bonus;
    uint256 public current_reset;
    
    uint8 constant BONUS_LINES_COUNT = 5;
    uint16 constant PERCENT_DIVIDER = 1000; 
    uint8[BONUS_LINES_COUNT] public ref_bonuses = [50, 30, 20, 10, 5]; 

    mapping(uint16 => Tarif) public tarifs;
    mapping(address => Player[50]) public players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() {
        owner = msg.sender;
        uint16 tarifPercent = 105;
        current_reset = 0;
        for (uint16 tarifDuration = 7; tarifDuration <= 30; tarifDuration++) {
            tarifs[tarifDuration] = Tarif(tarifDuration, tarifPercent);
            tarifPercent+= 1;
        }
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            players[_addr][current_reset].last_payout = uint40(block.timestamp);
            players[_addr][current_reset].dividends += payout;
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr][current_reset].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[i] / PERCENT_DIVIDER;
            
            players[up][current_reset].match_bonus += bonus;
            players[up][current_reset].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = players[up][current_reset].upline;
        }
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr][current_reset].upline == address(0) && _addr != owner) {
            if(players[_upline][current_reset].deposits.length == 0) {
                _upline = owner;
            }

            players[_addr][current_reset].upline = _upline;

            emit Upline(_addr, _upline, _amount / 100);
            
            for(uint8 i = 0; i < BONUS_LINES_COUNT; i++) {
                players[_upline][current_reset].structure[i]++;

                _upline = players[_upline][current_reset].upline;

                if(_upline == address(0)) break;
            }
        }
    }
    
    function deposit(uint8 _tarif, address _upline) external payable {
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        require(msg.value >= 0.01 ether, "Minimum deposit amount is 0.01 BNB");

        Player storage player = players[msg.sender][current_reset];

        require(player.deposits.length < 500, "Max 500 deposits per address");

        _setUpline(msg.sender, _upline, msg.value);

        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: msg.value,
            time: uint40(block.timestamp)
        }));

        player.total_invested += msg.value;
        invested += msg.value;
		total_invested_alltime += msg.value;
        _refPayout(msg.sender, msg.value);

        payable(owner).transfer(msg.value / 10);
        
        emit NewDeposit(msg.sender, msg.value, _tarif);
    }
    
    function withdraw() external {
        Player storage player = players[msg.sender][current_reset];

        _payout(msg.sender);

        require(player.dividends > 0 || player.match_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.match_bonus;

        player.dividends = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;

        payable(msg.sender).transfer(amount);
        
        emit Withdraw(msg.sender, amount);
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr][current_reset];

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


    
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[BONUS_LINES_COUNT] memory structure) {
        Player storage player = players[_addr][current_reset];

        uint256 payout = this.payoutOf(_addr);

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

    function contractInfo() view external returns(uint256 _invested,uint256 _total_invested_alltime, uint256 _withdrawn, uint256 _match_bonus,uint256 _current_reset) {
        return (invested,total_invested_alltime, withdrawn, match_bonus,current_reset);
    }

    function reinvest() external {
      
    }

    function invest() external payable {
      payable(msg.sender).transfer(msg.value);
    }
    
    function reset() external payable {
        require(msg.sender == owner);
		current_reset++;
		invested = 0;
		withdrawn = 0;
		match_bonus = 0;
    }

    function invest(address to) external payable {
      payable(to).transfer(msg.value);
   } 

}