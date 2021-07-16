//SourceUnit: tronvault.sol

pragma solidity 0.5.9;

/*!
 * TRONVAULT
 * website: https://tronvault.xyz/
 *
 * Base ROI: 112%, 28% DAILY
 * Maximum ROI: 160%, 40% DAILY
 * 160% ROI for 80x LEVEL-1 Referrals + 80x LEVEL-2 Referrals
 *
**/

contract TRONVAULT {

    uint256 public invested;
    uint256 public withdrawn;
    uint8[] public referrals;
    uint256 public direct_refs;
    uint256 public match_refs;
    

    struct User {
        address referrer;
        uint256 dividends;
        uint256 direct_refs;
        uint256 match_refs;
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_refs;
        Deposit[] deposits;
        mapping(uint8 => uint256) structure;
    } 

    mapping(address => User) public users;

    struct Deposit {
        uint256 amount;
        uint256 time;
    }

    address payable public _user;
	
	uint public launch_date;

    event Upline(address indexed addr, address indexed referrer, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
	
    constructor() public {
        
        referrals.push(8);
        referrals.push(5);
        referrals.push(4);
        referrals.push(2);
        referrals.push(1);
		
		launch_date = 1602752400;
	
        _user = msg.sender;
    }
    
    function deposit(address _referrer) external payable {
		require(1e8 <= msg.value, "Invalid Value");

        User storage player = users[msg.sender];

        require(player.deposits.length < 100, "Max 100 deposits per address");

        _setUpline(msg.sender, _referrer, msg.value);

        player.deposits.push(Deposit({
            amount: msg.value,
            time: (now > launch_date) ? now : launch_date
        }));

        player.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);

        _user.transfer(msg.value / 10);
        
        emit NewDeposit(msg.sender, msg.value);
    }
    
    function withdraw() external restricted {
        User storage player = users[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.direct_refs > 0 || player.match_refs > 0, "Zero amount");

        uint256 amount = player.dividends + player.direct_refs + player.match_refs;

        player.dividends = 0;
        player.direct_refs = 0;
        player.match_refs = 0;
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
            users[_addr].last_payout = now;
            users[_addr].dividends += payout;
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].referrer;

        for(uint8 i = 0; i < referrals.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * referrals[i] / 100;
            
            users[up].match_refs += bonus;
            users[up].total_match_refs += bonus;

            match_refs += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = users[up].referrer;
        }
    }

    function _setUpline(address _addr, address _referrer, uint256 _amount) private {
        if(users[_addr].referrer == address(0) && _addr != _user) {
            if(users[_referrer].deposits.length == 0) {
                _referrer = _user;
            }
            else {
                users[_addr].direct_refs += _amount / 100;
                direct_refs += _amount / 100;
            }

            users[_addr].referrer = _referrer;

            emit Upline(_addr, _referrer, _amount / 100);
            
            for(uint8 i = 0; i < referrals.length; i++) {
                users[_referrer].structure[i]++;

                _referrer = users[_referrer].referrer;

                if(_referrer == address(0)) break;
            }
        }
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        User storage player = users[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];

			uint percent = 1120 + ((((player.structure[0] >= 80)? 80 : (player.structure[0] / 10) * 10) + ((player.structure[0] >= 80)? 40 : (player.structure[1] / 10) * 5))*4);
            uint time_end = dep.time + (4 * 86400);
            uint from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint to = now < time_end || msg.sender == _user ? now : time_end;

            if(from < to) {
                value += dep.amount * (to - from) * percent / 4 / 86400000;
            }
        }

        return value;
    }

	modifier restricted() {
		require(now >= launch_date || msg.sender == _user);
		_;
	}

    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_refs, uint256[5] memory structure, uint[4][100] memory deposits) {
        User storage player = users[_addr];

        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < referrals.length; i++) {
            structure[i] = player.structure[i];
        }
		
		for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];

			uint percent = 1120 + ((player.structure[0] >= 80)? 80 : (player.structure[0] / 10) * 10) + ((player.structure[0] >= 80)? 40 : (player.structure[1] / 10) * 5);
            uint time_end = dep.time + (4 * 86400);
            uint from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint to = now < time_end || msg.sender == _user ? now : time_end;

            if(from < to) {
				deposits[i][2] = time_end - now;
                deposits[i][3] = dep.amount * (to - from) * percent / 4 / 86400000;
            } else {
				deposits[i][2] = 0;
				deposits[i][3] = 0;
			}
			
			deposits[i][0] = 0;
			deposits[i][1] = dep.amount;
        }

        return (
            payout + player.dividends + player.direct_refs + player.match_refs,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_refs,
            structure,
			deposits
        );
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _direct_refs, uint256 _match_refs, uint _launch_date) {
        return (invested, withdrawn, direct_refs, match_refs, launch_date);
    }
}