//SourceUnit: TronCoinTest.sol

pragma solidity 0.5.12;
contract TronCoin {
	struct User {
		uint256 cycle;//第几次投资
		address upline;//推荐人地址
		uint256 referrals;//直推合作伙伴数量
		uint256 payouts;//已提币总数
		uint256 directBonus;//直推奖金
		uint256 poolBonus;//全球前四名最佳推荐人奖励
		uint256 matchBonus;//团队收益奖励
		uint256 depositAmount;///最近一次投资总额
		uint256 depositPayouts;///最近一次投资总额已出金金额
		uint40 depositTime;//最近一次投资时间
		uint256 totalDeposits;//投资总额
		uint256 totalPayouts;//出金总额
		uint256 totalStructure;//个人团队合作伙伴
	}
	address payable public owner;
	address payable public adminFee;//项目方收款地址
	mapping(address => User) public users;
	uint256[] public cycles;
	uint8[] public refBonuses; // 1 => 1%
	uint8[] public poolBonuses; // 1 => 1%
	uint40 public poolLastDraw = uint40(block.timestamp);
	uint256 public poolCycle;
	uint256 public poolBalance;
	mapping(uint256 => mapping(address => uint256)) public poolUsersRefsDepositsSum;
	mapping(uint8 => address) public poolTop;
	uint256 public totalUsers = 1;
	uint256 public totalDeposited;
	uint256 public totalWithdraw;
	
	event uplineEvent(address indexed addr, address indexed upline);
	event newDepositEvent(address indexed addr, uint256 amount);
	event directPayoutEvent(address indexed addr, address indexed from, uint256 amount);
	event matchPayoutEvent(address indexed addr, address indexed from, uint256 amount);
	event poolPayoutEvent(address indexed addr, uint256 amount);
	event withdrawEvent(address indexed addr, uint256 amount);
	event limitReachedEvent(address indexed addr, uint256 amount);
	event logEvent(string log);
	event logiEvent(uint256 i);
	constructor(address payable _owner, address payable _admin_fee) public {
		owner = _owner;
		adminFee = _admin_fee;
		refBonuses.push(30);
		refBonuses.push(10);
		refBonuses.push(10);
		refBonuses.push(10);
		refBonuses.push(10);
		refBonuses.push(8);
		refBonuses.push(8);
		refBonuses.push(8);
		refBonuses.push(8);
		refBonuses.push(8);
		refBonuses.push(5);
		refBonuses.push(5);
		refBonuses.push(5);
		refBonuses.push(5);
		refBonuses.push(5);
		poolBonuses.push(40);
		poolBonuses.push(30);
		poolBonuses.push(20);
		poolBonuses.push(10);
		cycles.push(1e11);
		cycles.push(3e11);
		cycles.push(9e11);
		cycles.push(2e12);
	}
	function() payable external {
		_deposit(msg.sender, msg.value);
	}
	function _setUpline(address _addr, address _upline) private {
		//emit logEvent("_setUpline");
		if (users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].depositTime > 0 || _upline == owner)) {
			users[_addr].upline = _upline;
			users[_upline].referrals++;
			emit uplineEvent(_addr, _upline);
			totalUsers++;
			for (uint8 i = 0; i < refBonuses.length; i++) {
				if (_upline == address(0)) break;
				users[_upline].totalStructure++;
				_upline = users[_upline].upline;
			}
		}
	}
	function _deposit(address _addr, uint256 _amount) private {
		require(users[_addr].upline != address(0) || _addr == owner, "No upline");
		//emit logEvent("_deposit");
		if (users[_addr].depositTime > 0) {
			users[_addr].cycle++;
			require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].depositAmount), "Deposit already exists");
			require(_amount >= users[_addr].depositAmount && _amount <= cycles[users[_addr].cycle > cycles.length - 1 ? cycles.length - 1 : users[_addr].cycle], "Bad amount");
		} else {
			require(_amount >= 1e8 && _amount <= cycles[0], "Bad amount");
		}
		users[_addr].payouts = 0;
		users[_addr].depositAmount = _amount;
		users[_addr].depositPayouts = 0;
		users[_addr].depositTime = uint40(block.timestamp);
		users[_addr].totalDeposits += _amount;
		totalDeposited += _amount;
		emit newDepositEvent(_addr, _amount);
		if (users[_addr].upline != address(0)) {
			users[users[_addr].upline].directBonus += _amount / 10;
			emit directPayoutEvent(users[_addr].upline, _addr, _amount / 10);
		}
		_pollDeposits(_addr, _amount);
		if (poolLastDraw + 1 days < block.timestamp) {
			_drawPool();
		}
		adminFee.transfer(_amount / 20);
	}
	function _pollDeposits(address _addr, uint256 _amount) private {
		poolBalance += _amount * 3 / 100;

		address upline = users[_addr].upline;
		if (upline == address(0)) return;
		poolUsersRefsDepositsSum[poolCycle][upline] += _amount;
		for (uint8 i = 0; i < poolBonuses.length; i++) {
			if (poolTop[i] == upline) break;
			if (poolTop[i] == address(0)) {
				poolTop[i] = upline;
				break;
			}
			if (poolUsersRefsDepositsSum[poolCycle][upline] > poolUsersRefsDepositsSum[poolCycle][poolTop[i]]) {
				for (uint8 j = i + 1; j < poolBonuses.length; j++) {
					if (poolTop[j] == upline) {
						for (uint8 k = j; k <= poolBonuses.length; k++) {
							poolTop[k] = poolTop[k + 1];
						}
						break;
					}
				}
				for (uint8 j = uint8(poolBonuses.length - 1); j > i; j--) {
					poolTop[j] = poolTop[j - 1];
				}
				poolTop[i] = upline;
				break;
			}
		}
	}
	function _refPayout(address _addr, uint256 _amount) private {
		address up = users[_addr].upline;
		for (uint8 i = 0; i < refBonuses.length; i++) {
			//emit logiEvent(i);
			if (up == address(0)) break;
			//emit logiEvent(users[up].referrals);
			if (users[up].referrals >= i + 1) {
				uint256 bonus = _amount * refBonuses[i] / 100;
				users[up].matchBonus += bonus;
				emit matchPayoutEvent(up, _addr, bonus);
			}
			up = users[up].upline;
		}
	}
	function _drawPool() private {
		poolLastDraw = uint40(block.timestamp);
		poolCycle++;
		uint256 draw_amount = poolBalance / 10;
		for (uint8 i = 0; i < poolBonuses.length; i++) {
			if (poolTop[i] == address(0)) break;
			uint256 win = draw_amount * poolBonuses[i] / 100;
			users[poolTop[i]].poolBonus += win;
			poolBalance -= win;
			emit poolPayoutEvent(poolTop[i], win);
		}
		for (uint8 i = 0; i < poolBonuses.length; i++) {
			poolTop[i] = address(0);
		}
	}

	function deposit(address _upline) payable external {
		_setUpline(msg.sender, _upline);
		_deposit(msg.sender, msg.value);
	}
	function withdraw() external {
		(uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
		require(users[msg.sender].payouts < max_payout, "Full payouts");
		// Deposit payout
		if (to_payout > 0) {
			if (users[msg.sender].payouts + to_payout > max_payout) {
				to_payout = max_payout - users[msg.sender].payouts;
			}
			users[msg.sender].depositPayouts += to_payout;
			users[msg.sender].payouts += to_payout;
			_refPayout(msg.sender, to_payout);
		}
		// Direct payout
		if (users[msg.sender].payouts < max_payout && users[msg.sender].directBonus > 0) {
			uint256 directBonus = users[msg.sender].directBonus;
			if (users[msg.sender].payouts + directBonus > max_payout) {
				directBonus = max_payout - users[msg.sender].payouts;
			}
			users[msg.sender].directBonus -= directBonus;
			users[msg.sender].payouts += directBonus;
			to_payout += directBonus;
		}
		// Pool payout
		if (users[msg.sender].payouts < max_payout && users[msg.sender].poolBonus > 0) {
			uint256 poolBonus = users[msg.sender].poolBonus;
			if (users[msg.sender].payouts + poolBonus > max_payout) {
				poolBonus = max_payout - users[msg.sender].payouts;
			}
			users[msg.sender].poolBonus -= poolBonus;
			users[msg.sender].payouts += poolBonus;
			to_payout += poolBonus;
		}
		// Match payout
		if (users[msg.sender].payouts < max_payout && users[msg.sender].matchBonus > 0) {
			uint256 matchBonus = users[msg.sender].matchBonus;
			if (users[msg.sender].payouts + matchBonus > max_payout) {
				matchBonus = max_payout - users[msg.sender].payouts;
			}
			users[msg.sender].matchBonus -= matchBonus;
			users[msg.sender].payouts += matchBonus;
			to_payout += matchBonus;
		}
		require(to_payout > 0, "Zero payout");
		users[msg.sender].totalPayouts += to_payout;
		totalWithdraw += to_payout;
		msg.sender.transfer(to_payout);
		emit withdrawEvent(msg.sender, to_payout);
		if (users[msg.sender].payouts >= max_payout) {
			emit limitReachedEvent(msg.sender, users[msg.sender].payouts);
		}
	}

	function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
		return _amount * 31 / 10;
	}
	function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
		max_payout = this.maxPayoutOf(users[_addr].depositAmount);
		if (users[_addr].depositPayouts < max_payout) {
			payout = (users[_addr].depositAmount * ((block.timestamp - users[_addr].depositTime) / 1 days) / 100) - users[_addr].depositPayouts;
			if (users[_addr].depositPayouts + payout > max_payout) {
				payout = max_payout - users[_addr].depositPayouts;
			}
		}
	}
	
	
	
//	Only external call
	function userInfo(address _addr) view external returns(address upline, uint40 depositTime, uint256 depositAmount, uint256 payouts, uint256 directBonus, uint256 poolBonus, uint256 matchBonus) {
		return (users[_addr].upline, users[_addr].depositTime, users[_addr].depositAmount, users[_addr].payouts, users[_addr].directBonus, users[_addr].poolBonus, users[_addr].matchBonus);
	}
	function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 totalDeposits, uint256 totalPayouts, uint256 totalStructure) {
		return (users[_addr].referrals, users[_addr].totalDeposits, users[_addr].totalPayouts, users[_addr].totalStructure);
	}
	function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
		return (totalUsers, totalDeposited, totalWithdraw, poolLastDraw, poolBalance, poolUsersRefsDepositsSum[poolCycle][poolTop[0]]);
	}
	function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
		for (uint8 i = 0; i < poolBonuses.length; i++) {
			if (poolTop[i] == address(0)) break;
			addrs[i] = poolTop[i];
			deps[i] = poolUsersRefsDepositsSum[poolCycle][poolTop[i]];
		}
	}
}