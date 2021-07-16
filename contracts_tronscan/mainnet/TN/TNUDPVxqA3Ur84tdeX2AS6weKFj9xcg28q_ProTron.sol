//SourceUnit: ProTron.sol

pragma solidity 0.5.10;

contract ProTron {

	using SafeMath for *;

	struct Deposit {
		
		uint256 deposit_amount;
		
		uint256 max_payout;
		uint256 current_payout;
		
		uint256 daily_payout;
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

		mapping(uint => Deposit) deposits;
	}

	address payable public owner;
	address payable public ensurance;

	mapping(address => User) public users;

	uint public pool_last_cycle_time = now;

	uint256 public pool_cycle;
	uint256 public pool_balance;

	uint256 public total_users;
	uint256 public total_deposited;
	uint256 public total_withdraw;

	uint256 public current_cycle_user_id;

	uint256 public users_chunk_size = 5;

	uint256[] public partnership_line_percents;

	address[] public users_addresses;
	
	event Upline(address indexed addr, address indexed upline);
	event NewDeposit(address indexed addr, uint256 amount);
	event PartnershipBonus(address indexed addr, address indexed from, uint256 amount);
	event DepositPayout(address indexed addr, uint256 amount);
	event PartnershipPayout(address indexed addr, address indexed from, uint256 amount, uint256 line);
	event Withdraw(address indexed addr, uint256 amount);

	modifier onlyOwner() {
		require(msg.sender == owner, "Only owner");
		_;
	}

	constructor(address payable _owner, address payable _ensurance, uint _pool_last_cycle_time, uint256 _pool_cycle, uint256 _pool_balance, uint256 _total_deposited, uint256 _total_withdraw ) public {
		owner = _owner;
		ensurance = _ensurance;

		pool_last_cycle_time = _pool_last_cycle_time;
		pool_cycle = _pool_cycle;
		pool_balance = _pool_balance;
		total_deposited = _total_deposited;
		total_withdraw = _total_withdraw;

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

	function() payable external {}

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

		uint _deposit_index = 0;	
		uint256 _daily_payout = 0;	
		uint256 _max_payout = _amount * 4;	

		if (_amount >= 100 trx && _amount <= 100000 trx) {
			
			_daily_payout = _amount.div(100);
			
		} else if (_amount >= 100001 trx && _amount <= 200000 trx) {
			
			_daily_payout = _amount.mul(11).div(1000);

			_deposit_index = 1;
		
		} else if (_amount >= 200001 trx && _amount <= 300000 trx) {
			
			_daily_payout = _amount.mul(12).div(1000);

			_deposit_index = 2;

		} else if (_amount >= 300001 trx && _amount <= 400000 trx) {
			
			_daily_payout = _amount.mul(13).div(1000);

			_deposit_index = 3;
		
		} else if (_amount >= 400001 trx && _amount <= 500000 trx) {
			
			_daily_payout = _amount.mul(14).div(1000);

			_deposit_index = 4;
		
		} else if (_amount >= 500001 trx) {
			
			_daily_payout = _amount.mul(15).div(1000);

			_deposit_index = 5;
		
		}

		users[_addr].deposits[_deposit_index].deposit_amount += _amount;
		users[_addr].deposits[_deposit_index].max_payout += _max_payout;
		users[_addr].deposits[_deposit_index].daily_payout += _daily_payout;

		
		users[_addr].total_deposits += _amount;
		users[_addr].max_payout += _max_payout;

		if (users[_addr].upline != address(0)) {
			users[users[_addr].upline].first_line_deposits += _amount;

			_update_partnership_enabled_level(users[_addr].upline);

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

		if(pool_last_cycle_time + 1 days < now) {
			_process_cycle(0);
		}

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

		if(pool_last_cycle_time + 1 days < now) {
			_process_cycle(0);
		}
	}

	function _update_partnership_enabled_level(address _addr) private {
		if (users[_addr].first_line_deposits > 0 trx && users[_addr].first_line_deposits < 10000 trx && users[_addr].partnership_enabled_level != 0) {
		
			users[_addr].partnership_enabled_level = 0;

		} else if (users[_addr].first_line_deposits >= 10000 trx && users[_addr].first_line_deposits < 20000 trx && users[_addr].partnership_enabled_level != 1) {
		
			users[_addr].partnership_enabled_level = 1;
			
		} else if (users[_addr].first_line_deposits  >= 20000 trx && users[_addr].first_line_deposits  < 30000 trx && users[_addr].partnership_enabled_level != 2) {
			
			users[_addr].partnership_enabled_level = 2;
		
		} else if (users[_addr].first_line_deposits  >= 30000 trx && users[_addr].first_line_deposits  < 50000 trx && users[_addr].partnership_enabled_level != 3) {
			
			users[_addr].partnership_enabled_level = 3;
		
		} else if (users[_addr].first_line_deposits  >= 50000 trx && users[_addr].first_line_deposits  < 80000 trx && users[_addr].partnership_enabled_level != 4) {
			
			users[_addr].partnership_enabled_level = 4;
		
		} else if (users[_addr].first_line_deposits  >= 80000 trx && users[_addr].first_line_deposits  < 110 trx && users[_addr].partnership_enabled_level != 5) {
			
			users[_addr].partnership_enabled_level = 5;
		
		} else if (users[_addr].first_line_deposits  >= 100000 trx && users[_addr].first_line_deposits  < 150000 trx && users[_addr].partnership_enabled_level != 6) {
			
			users[_addr].partnership_enabled_level = 6;
		
		} else if (users[_addr].first_line_deposits  >= 150000 trx && users[_addr].first_line_deposits  < 200000 trx && users[_addr].partnership_enabled_level != 7) {
			
			users[_addr].partnership_enabled_level = 7;
		
		} else if (users[_addr].first_line_deposits  >= 200000 trx && users[_addr].first_line_deposits  < 250000 trx && users[_addr].partnership_enabled_level != 8) {
			
			users[_addr].partnership_enabled_level = 8;
		
		} else if (users[_addr].first_line_deposits  >= 250000 trx && users[_addr].first_line_deposits  < 300000 trx && users[_addr].partnership_enabled_level != 9) {
			
			users[_addr].partnership_enabled_level = 9;
		
		} else if (users[_addr].first_line_deposits  >= 300000 trx && users[_addr].first_line_deposits  < 350000 trx && users[_addr].partnership_enabled_level != 10) {
			
			users[_addr].partnership_enabled_level = 10;
		
		} else if (users[_addr].first_line_deposits  >= 350000 trx && users[_addr].first_line_deposits  < 400000 trx && users[_addr].partnership_enabled_level != 11) {
			
			users[_addr].partnership_enabled_level = 11;
		
		} else if (users[_addr].first_line_deposits  >= 400000 trx && users[_addr].first_line_deposits  < 450000 trx && users[_addr].partnership_enabled_level != 12) {
			
			users[_addr].partnership_enabled_level = 12;
		
		} else if (users[_addr].first_line_deposits  >= 450000 trx && users[_addr].first_line_deposits  < 500000 trx && users[_addr].partnership_enabled_level != 13) {
			
			users[_addr].partnership_enabled_level = 13;
		
		} else if (users[_addr].first_line_deposits  >= 500000 trx && users[_addr].first_line_deposits  < 550000 trx && users[_addr].partnership_enabled_level != 14) {
			
			users[_addr].partnership_enabled_level = 14;
		
		} else if (users[_addr].first_line_deposits  >= 550000 trx && users[_addr].first_line_deposits  < 600000 trx && users[_addr].partnership_enabled_level != 15) {
			
			users[_addr].partnership_enabled_level = 15;
		
		} else if (users[_addr].first_line_deposits  >= 600000 trx && users[_addr].partnership_enabled_level != 16) {
			
			users[_addr].partnership_enabled_level = 16;
		
		}
	}

	function _protron_bonus(address _addr, uint256 _trx_amount) external onlyOwner { 

		require(users[_addr].max_payout > 0, "Inactive user");

		users[_addr].balance += _trx_amount * 1 trx; 

	}

	function _set_users_chunk_size(uint256 _users_chunk_size) external onlyOwner { 

		users_chunk_size = _users_chunk_size; 

	}

	function _process_cycle_external(uint256 _users_chunk_size) external {

		if(pool_last_cycle_time + 1 days < now) {

			_process_cycle(_users_chunk_size);

		}
		
	}

	function _partnership_payout_for_user(address _addr, uint256 _amount) private {
		address _upline = users[_addr].upline;

		for(uint8 i = 0; i < partnership_line_percents.length; i++) {
			if(_upline == address(0)) break;
			
			if(users[_upline].partnership_enabled_level >= i) {

				if ( users[_upline].current_payout < users[_upline].max_payout ) {

					uint256 _partnership_payout_amount = _amount * partnership_line_percents[i] / 100;
				
					if ( (users[_upline].current_payout + _partnership_payout_amount) > users[_upline].max_payout ) {

						_partnership_payout_amount = users[_upline].max_payout - users[_upline].current_payout;

					}

					users[_upline].current_payout += _partnership_payout_amount;
					users[_upline].balance += _partnership_payout_amount;

					emit PartnershipPayout(_upline, _addr, _partnership_payout_amount, i+1);

				}
			}

			_upline = users[_upline].upline;
		}
	}

	function _process_cycle_for_user(address _addr) private {

		if (users[_addr].current_payout < users[_addr].max_payout) {

			uint256 _current_daily_payout = 0;

			for(uint256 j = 0; j <= 5; j++) {

				if (users[_addr].deposits[j].current_payout < users[_addr].deposits[j].max_payout) {

					uint256 _current_deposit_payout = users[_addr].deposits[j].daily_payout;

					if ( (users[_addr].deposits[j].current_payout + _current_deposit_payout) > users[_addr].deposits[j].max_payout ) {

						_current_deposit_payout = users[_addr].deposits[j].max_payout - users[_addr].deposits[j].current_payout;

					}

					users[_addr].deposits[j].current_payout += _current_deposit_payout;
					
					_current_daily_payout += _current_deposit_payout;


				}

			}

			if (_current_daily_payout > 0) {

				if ( (users[_addr].current_payout + _current_daily_payout) > users[_addr].max_payout ) {

					_current_daily_payout = users[_addr].max_payout - users[_addr].current_payout;

				}

				users[_addr].current_payout += _current_daily_payout;
				users[_addr].balance += _current_daily_payout;

				emit DepositPayout(_addr, _current_daily_payout);

				_partnership_payout_for_user(_addr, _current_daily_payout);

			}

		}
	}


	function _process_cycle(uint256 _users_chunk_size) private {

		uint256 _current_users_chunk_size = users_chunk_size;

		if (_users_chunk_size > 0) {
			_current_users_chunk_size = _users_chunk_size;
		}

		uint256 _end_user_index = current_cycle_user_id + _current_users_chunk_size;

		if (_end_user_index > users_addresses.length) {
			_end_user_index = users_addresses.length;
		}
		
		for(uint256 i = current_cycle_user_id; i < _end_user_index; i++) {
			_process_cycle_for_user(users_addresses[i]);
		}

		current_cycle_user_id = _end_user_index;

		if (current_cycle_user_id >= users_addresses.length - 1) {
			pool_last_cycle_time = now;
			pool_cycle++;
			current_cycle_user_id = 0;
		}

	}

	function _transfer_user(address _addr, address _upline, bool _is_upline_set, uint256 _total_deposits, uint256 _max_payout, uint256 _current_payout, uint256 _balance,  uint256 _total_withdraw, uint256 _referrals_count,  uint256 _first_line_deposits,  uint256 _partnership_enabled_level) external onlyOwner { 
		total_users++;

		users_addresses.push(_addr);

		users[_addr].upline = _upline;
		users[_addr].is_upline_set = _is_upline_set;
		users[_addr].total_deposits = _total_deposits;
		users[_addr].max_payout = _max_payout;
		users[_addr].current_payout = _current_payout;
		users[_addr].balance = _balance;
		users[_addr].total_withdraw = _total_withdraw;
		users[_addr].referrals_count = _referrals_count;
		users[_addr].first_line_deposits = _first_line_deposits;
		users[_addr].partnership_enabled_level = _partnership_enabled_level;
	}

	function _transfer_deposit(address _addr, uint _deposit_index, uint256 _deposit_amount, uint256 _max_payout, uint256 _current_payout, uint256 _daily_payout) external onlyOwner { 
		
		users[_addr].deposits[_deposit_index].deposit_amount += _deposit_amount;
		users[_addr].deposits[_deposit_index].max_payout += _max_payout;
		users[_addr].deposits[_deposit_index].daily_payout += _daily_payout;

		users[_addr].deposits[_deposit_index].current_payout += _current_payout;
	}


	function get_user_info(address _addr) view external returns(address _upline, bool _is_upline_set, uint256 _total_deposits, uint256 _max_payout, uint256 _current_payout, uint256 _balance,  uint256 _total_withdraw) {
		return ( users[_addr].upline, users[_addr].is_upline_set, users[_addr].total_deposits, users[_addr].max_payout, users[_addr].current_payout, users[_addr].balance, users[_addr].total_withdraw);
	}

	function get_user_partnership_info(address _addr) view external returns(address _upline, bool _is_upline_set, uint256 _referrals_count,  uint256 _first_line_deposits,  uint256 _partnership_enabled_level) {
		return ( users[_addr].upline, users[_addr].is_upline_set, users[_addr].referrals_count, users[_addr].first_line_deposits, users[_addr].partnership_enabled_level );
	}

	function get_user_deposit_info(address _addr, uint256 _index) view external returns( uint256 _deposit_amount, uint256 _max_payout, uint256 _current_payout, uint256 _daily_payout) {

		return (users[_addr].deposits[_index].deposit_amount, users[_addr].deposits[_index].max_payout, users[_addr].deposits[_index].current_payout, users[_addr].deposits[_index].daily_payout );
	}
	
	function get_contract_info() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 _pool_cycle, uint _pool_last_cycle_time, uint256 _pool_balance, uint256 _pool_balance_blockchain) {
		return (total_users, total_deposited, total_withdraw, pool_cycle, pool_last_cycle_time, pool_balance, address(this).balance);
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