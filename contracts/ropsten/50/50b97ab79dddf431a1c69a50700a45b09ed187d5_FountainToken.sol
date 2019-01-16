pragma solidity ^0.4.25;

/**
 * 使用安全计算法进行加减乘除运算
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
	/**
	 * @dev Multiplies two numbers, throws on overflow.
	 */
	function mul (uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	/**
	 * @dev Integer division of two numbers, truncating the quotient.
	 */
	function div (uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		// uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return a / b;
	}

	/**
	 * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
	 */
	function sub (uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	/**
	 * @dev Adds two numbers, throws on overflow.
	 */
	function add (uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

/**
 * 基础 ERC20 代币协议
 * event	Transfer(address, address, uint256)
 * function	totalSupply()
 * function	balanceOf(address)
 * function	transfer(address, uint256)
 */
contract ERCBasic {
	event Transfer(address indexed from, address indexed to, uint256 value);

	function totalSupply () public view returns (uint256);
	function balanceOf (address who) public view returns (uint256);
	function transfer (address to, uint256 value) public returns (bool);
}

/**
 * 可代理 ERC20 代币协议
 * @dev see https://github.com/ethereum/EIPs/issues/20
 * event	Approval(address, address, uint256)
 * function	transferFrom(address from, address to, uint256 value)
 * function	allowance(address, address)
 * function	approve(address, uint256)
 */
contract ERC is ERCBasic {
	event Approval(address indexed owner, address indexed spender, uint256 value);

	function transferFrom (address from, address to, uint256 value) public returns (bool);
	function allowance (address owner, address spender) public view returns (uint256);
	function approve (address spender, uint256 value) public returns (bool);
}

/**
 * 有所有人的合约
 * 所有权限管理都在这里定义
 * event	OwnershipTransferred(address, address)
 * event    	FoundationOwnershipTransferred(address, address)
 * modifier	onlyOwner()
 * function	transferOwnership(address)
 */
contract Ownable {
	event OwnershipTransferred(address indexed oldone, address indexed newone);
	event FoundationOwnershipTransferred(address indexed oldFoundationOwner, address indexed newFoundationOwner);

	address internal owner;
	address internal foundationOwner;

	constructor () public {
		owner = msg.sender;
		foundationOwner = owner;
	}

	/**
	 * 判断当前用户是否是合约所有人
	 */
	modifier onlyOwner () {
		require(msg.sender == owner);
		_;
	}

	modifier hasMintability () {
		require(msg.sender == owner || msg.sender == foundationOwner);
		_;
	}

	/**
	 * 转让合约所有权
	 * @param  newOwner 新所有人
	 */
	function transferOwnership (address newOwner) public returns (bool);
	
	/**
	 * 设置fountain 基金会管理员
	 *  @param  foundation 基金会管理员
	 */
	function setFountainFoundationOwner (address foundation) public returns (bool);
}

/**
 * 可暂停合约
 * event	ContractPause()
 * event	ContractResume()
 * event    ContractPauseSchedule(uint256, uint256)
 * modifier	whenRunning()
 * modifier	whenPaused()
 * function	pause()
 * function	resume()
 */
contract Pausable is Ownable {
	event ContractPause();
	event ContractResume();
	event ContractPauseSchedule(uint256 from, uint256 to);

	uint256 internal pauseFrom;
	uint256 internal pauseTo;

	modifier whenRunning () {
		require(now < pauseFrom || now > pauseTo);
		_;
	}

	modifier whenPaused () {
		require(now >= pauseFrom && now <= pauseTo);
		_;
	}

	/**
	 * 设置合约状态为暂停
	 * 只有合约所有人有权限
	 * 立即生效，默认30000天
	 */
	function pause () public onlyOwner {
		pauseFrom = now - 1;
		pauseTo = now + 30000 days;
		emit ContractPause();
	}

	/**
	 * 设置合约状态为暂停
	 * 只有合约所有人有权限
	 * 可设置预期暂停时间段
	 */
	function pause (uint256 from, uint256 to) public onlyOwner {
		require(to > from);
		pauseFrom = from;
		pauseTo = to;
		emit ContractPauseSchedule(from, to);
	}

	/**
	 * 设置合约状态为执行
	 * 只有合约所有人有权限
	 */
	function resume () public onlyOwner {
		pauseFrom = now - 2;
		pauseTo = now - 1;
		emit ContractResume();
	}
}

/**
 * 铸币厂
 * 上限设为0则表示不设上限
 * event	ForgeStart()
 * event	ForgeStop()
 * modifier	canForge()
 * modifier	cannotForge()
 * function	startForge()
 * function	stopForge()
 */
contract TokenForge is Ownable {
	event ForgeStart();
	event ForgeStop();

	bool public forge_running = true;

	modifier canForge () {
		require(forge_running);
		_;
	}

	modifier cannotForge () {
		require(!forge_running);
		_;
	}

	/**
	 * 开启铸币厂
	 * @return 是否开启成功
	 */
	function startForge () public onlyOwner cannotForge returns (bool) {
		forge_running = true;
		emit ForgeStart();
		return true;
	}

	/**
	 * 关闭铸币厂
	 * @return 是否开启成功
	 */
	function stopForge () public onlyOwner canForge returns (bool) {
		forge_running = false;
		emit ForgeStop();
		return true;
	}
}

/**
 * 有封顶的代币系统
 * 上限为0表示不设上限
 * function	changeCap(uint256)
 * function	canMint(uint256)
 */
contract CappedToken is Ownable {
	using SafeMath for uint256;

	uint256 public token_cap;
	uint256 public token_created;
	uint256 public token_foundation_cap;
	uint256 public token_foundation_created;


	constructor (uint256 _cap, uint256 _foundationCap) public {
		token_cap = _cap;
		token_foundation_cap = _foundationCap;
	}

	function changeCap (uint256 _cap) public onlyOwner returns (bool) {
		if (_cap < token_created && _cap > 0) return false;
		token_cap = _cap;
		return true;
	}

	function canMint (uint256 amount) public view returns (bool) {
		return (token_cap == 0) || (token_created.add(amount) <= token_cap);
	}
	
	function canMintFoundation(uint256 amount) internal view returns(bool) {
		return(token_foundation_created.add(amount) <= token_foundation_cap);
	}
}

/**
 * 基础代币实现
 * modifier	canTransfer(address, address, uint256)
 * function	balanceOf(address)
 */
contract BasicToken is ERCBasic, Pausable {
	using SafeMath for uint256;

	mapping(address => uint256) public wallets;

	modifier canTransfer (address _from, address _to, uint256 amount) {
		require((_from != address(0)) && (_to != address(0)));
		require(_from != _to);
		require(amount > 0);
		_;
	}

	/**
	 * 获取指定用户的总余额
	 * @param  user 指定用户地址
	 * @return      总余额
	 */
	function balanceOf (address user) public view returns (uint256) {
		return wallets[user];
	}
}

/**
 * 增加了授权代理机制的 ERC20 代币
 * function	allowance(address, address)
 * function	approve(address, uint256)
 * function	increaseApproval(address, uint256)
 * function	decreaseApproval(address, uint256)
 */
contract DelegatableToken is ERC, BasicToken {
	using SafeMath for uint256;

	mapping(address => mapping(address => uint256)) public warrants;

	/**
	 * 返回授权金额
	 * @param  owner     代币所有者地址
	 * @param  delegator 代币代理人地址
	 * @return           可用授权金额
	 */
	function allowance (address owner, address delegator) public view returns (uint256) {
		return warrants[owner][delegator];
	}

	/**
	 * 授权指定用户为代理人，以及可代理金额
	 * @param  delegator 代理人地址
	 * @param  value     授权金额
	 * @return           是否授权成功
	 */
	function approve (address delegator, uint256 value) public whenRunning returns (bool) {
		if (delegator == msg.sender) return true;
		warrants[msg.sender][delegator] = value;
		emit Approval(msg.sender, delegator, value);
		return true;
	}

	/**
	 * 为指定代理人增加可代理额度
	 * @param  delegator 代理人地址
	 * @param  delta     增加金额
	 * @return           是否授权成功
	 */
	function increaseApproval (address delegator, uint256 delta) public whenRunning returns (bool) {
		if (delegator == msg.sender) return true;
		uint256 value = warrants[msg.sender][delegator].add(delta);
		warrants[msg.sender][delegator] = value;
		emit Approval(msg.sender, delegator, value);
		return true;
	}

	/**
	 * 为指定代理人减少可代理额度
	 * @param  delegator 代理人地址
	 * @param  delta     增加金额
	 * @return           是否授权成功
	 */
	function decreaseApproval (address delegator, uint256 delta) public whenRunning returns (bool) {
		if (delegator == msg.sender) return true;
		uint256 value = warrants[msg.sender][delegator];
		if (value < delta) {
			value = 0;
		}
		else {
			value = value.sub(delta);
		}
		warrants[msg.sender][delegator] = value;
		emit Approval(msg.sender, delegator, value);
		return true;
	}
}

/**
 * 有锁仓代币协议
 * function availableWallet(address)
 */
contract LockableProtocol is BasicToken {
	function invest (address investor, uint256 amount) public returns (bool);
	function getInvestedToken (address investor) public view returns (uint256);
	function getLockedToken (address investor) public view returns (uint256);

	/**
	 * 返回指定用户账户中的可用资金总额
	 * @param  user 指定用户地址
	 * @return      可用资金总额
	 */
	function availableWallet (address user) public view returns (uint256) {
		return wallets[user].sub(getLockedToken(user));
	}
}

/**
 * 可创造和销毁的代币
 * event	Mint(address, uint256)
 * event	Burn(address, uint256)
 * function	totalSupply()
 * function	mint(address, uint256)
 * function	burn(uint256)
 */
contract MintAndBurnToken is TokenForge, CappedToken, LockableProtocol {
	using SafeMath for uint256;
	
	event Mint(address indexed user, uint256 amount);
	event Burn(address indexed user, uint256 amount);

	constructor (uint256 _initial, uint256 _cap, uint256 _fountainCap) public CappedToken(_cap, _fountainCap) {
		token_created = _initial;
		wallets[msg.sender] = _initial;

		emit Mint(msg.sender, _initial);
		emit Transfer(address(0), msg.sender, _initial);
	}

	/**
	 * 返回当前总币量
	 * ERC20 协议接口
	 * @return 当前总币量
	 */
	function totalSupply () public view returns (uint256) {
		return token_created;
	}
	
	/**
	 * 返回当前基金会总发行总币量
	 * @return 基金会当前总币量
	 */
	function totalFountainSupply() public view returns(uint256) {
		return token_foundation_created;
	}

	/**
	 * 为指定用户创造新代币
	 * 只有合约所有人有权限
	 * @param  target 目标账号
	 * @param  amount 创造代币量
	 * @return        是否铸币成功
	 */
	function mint (address target, uint256 amount) public hasMintability whenRunning canForge returns (bool) {
		require(target != owner && target != foundationOwner); // Owner和FoundationOwner不能成为mint的对象
		require(canMint(amount));

		if (msg.sender == foundationOwner) {
			require(canMintFoundation(amount));
			token_foundation_created = token_foundation_created.add(amount);
		}
		
		token_created = token_created.add(amount);
		wallets[target] = wallets[target].add(amount);

		emit Mint(target, amount);
		emit Transfer(address(0), target, amount);
		return true;
	}

	/**
	 * 当前用户销毁一定量的代币
	 * @param  amount 销毁代币量
	 * @return        是否销毁成功
	 */
	function burn (uint256 amount) public whenRunning canForge returns (bool) {
		uint256 balance = availableWallet(msg.sender);
		require(amount <= balance);

		token_created = token_created.sub(amount);
		wallets[msg.sender] -= amount;

		emit Burn(msg.sender, amount);
		emit Transfer(msg.sender, address(0), amount);

		return true;
	}
}

/**
 * 可锁仓代币
 * struct	LockBin
 * event	InvestStart()
 * event	InvestStop()
 * event	NewInvest(uint256, uint256, uint256, uint256)
 * modifier	canInvest()
 * function	pauseInvest()
 * function	resumeInvest()
 * function	setInvest(uint256, uint256, uint256, uint256)
 * function stopInvest()
 * function	invest(address, uint256)
 * function batchInvest(address[], uint256)
 * function batchInvests(address[], uint256[])
 * function	getInvestedToken(address)
 * function	getLockedToken(address)
 * function	getReleasedToken(address)
 * function	canPay(address, uint256)
 * function	transfer(address, uint256)
 * function batchTransfer(address[], uint256)
 * function batchTransfers(address[], uint256[])
 * function	transferFrom(address, address, uint256)
 * function batchTransferFrom(address, address[], uint256)
 * function batchTransferFroms(address, address[], uint256[])
 */
contract LockableToken is MintAndBurnToken, DelegatableToken {
	using SafeMath for uint256;

	struct LockBin {
		uint256 start;
		uint256 finish;
		uint256 duration;
		uint256 amount;
	}

	event InvestStart();
	event InvestStop();
	event NewInvest(uint256 release_start, uint256 release_duration);

	uint256 public releaseStart;    // 当前轮募资资金解冻开始时间
	uint256 public releaseDuration; // 当前轮募资解冻周期时长
	bool public forceStopInvest;
	mapping(address => mapping(uint => LockBin)) public lockbins;

	modifier canInvest () {
		require(!forceStopInvest);
		_;
	}

	constructor (uint256 _initial, uint256 _cap, uint256 _fountainCap) public MintAndBurnToken(_initial, _cap, _fountainCap) {
		forceStopInvest = true;
	}

	/**
	 * 暂停集资
	 * @return 返回是否暂停成功
	 */
	function pauseInvest () public onlyOwner whenRunning returns (bool) {
		require(!forceStopInvest);
		forceStopInvest = true;
		emit InvestStop();
		return true;
	}

	/**
	 * 继续集资
	 * @return 返回是否继续成功
	 */
	function resumeInvest () public onlyOwner whenRunning returns (bool) {
		require(forceStopInvest);
		forceStopInvest = false;
		emit InvestStart();
		return true;
	}

	/**
	 * 设置新的集资时间窗口
	 * @param release_start    解冻期结束时间点
	 * @param release_duration 解冻期结束时间点，秒为单位
	 * @return                 返回是否暂停成功
	 */
	function setInvest (uint256 release_start, uint256 release_duration) public onlyOwner whenRunning returns (bool) {
		releaseStart = release_start;
		releaseDuration = release_duration;
		forceStopInvest = false;

		emit NewInvest(release_start, release_duration);
		return true;
	}

	/**
	 * 管理员转账到投资人，并将转账金额锁仓
	 * @param investor 投资人地址
	 * @param amount   投资金额
	 * @return         是否购币成功
	 */
	function invest (address investor, uint256 amount) public onlyOwner whenRunning canInvest returns (bool) {
		require(investor != address(0));
		require(investor != owner); // 当前owner不能参与募资
		require(investor != foundationOwner); // 当前foundationOwner不能参与募资
		require(amount > 0);
		require(canMint(amount));

		mapping(uint => LockBin) locks = lockbins[investor];
		LockBin storage info = locks[0]; // 第一个数据永远是记录有多少条
		uint index = info.amount + 1;
		locks[index] = LockBin({
			start: releaseStart,
			finish: releaseStart + releaseDuration,
			duration: releaseDuration / (1 days),
			amount: amount
		});
		info.amount = index;

		token_created = token_created.add(amount);
		wallets[investor] = wallets[investor].add(amount);
		emit Mint(investor, amount);
		emit Transfer(address(0), investor, amount);

		return true;
	}

	/**
	 * 管理员批量转账到投资人，并将转账金额锁仓（所有投资人金额相同）
	 * @param investors 投资人地址
	 * @param amount    投资金额
	 * @return          是否购币成功
	 */
	function batchInvest (address[] investors, uint256 amount) public onlyOwner whenRunning canInvest returns (bool) {
		require(amount > 0);

		uint investorsLength = investors.length;
		uint investorsCount = 0;
		uint i;
		address r;
		for (i = 0; i < investorsLength; i ++) {
			r = investors[i];
			if (r == address(0) || r == owner || r == foundationOwner) continue; // 当前owner不能参与募资
			investorsCount ++;
		}
		require(investorsCount > 0);

		uint256 totalAmount = amount.mul(uint256(investorsCount));
		require(canMint(totalAmount));

		token_created = token_created.add(totalAmount);

		for (i = 0; i < investorsLength; i ++) {
			r = investors[i];
			if (r == address(0) || r == owner || r == foundationOwner) continue; // 当前owner不能参与募资

			mapping(uint => LockBin) locks = lockbins[r];
			LockBin storage info = locks[0]; // 第一个数据永远是记录有多少条
			uint index = info.amount + 1;
			locks[index] = LockBin({
				start: releaseStart,
				finish: releaseStart + releaseDuration,
				duration: releaseDuration / (1 days),
				amount: amount
			});
			info.amount = index;

			wallets[r] = wallets[r].add(amount);
			emit Mint(r, amount);
			emit Transfer(address(0), r, amount);
		}

		return true;
	}

	/**
	 * 管理员批量转账到投资人，并将转账金额锁仓（每个投资人金额不同）
	 * @param investors 投资人地址
	 * @param amounts   投资金额
	 * @return          是否购币成功
	 */
	function batchInvests (address[] investors, uint256[] amounts) public onlyOwner whenRunning canInvest returns (bool) {
		uint investorsLength = investors.length;
		require(investorsLength == amounts.length);

		uint investorsCount = 0;
		uint256 totalAmount = 0;
		uint i;
		address r;
		for (i = 0; i < investorsLength; i ++) {
			r = investors[i];
			if (r == address(0) || r == owner) continue;
			investorsCount ++;
			totalAmount += amounts[i];
		}
		require(totalAmount > 0);
		require(canMint(totalAmount));

		uint256 amount;
		token_created = token_created.add(totalAmount);
		for (i = 0; i < investorsLength; i ++) {
			r = investors[i];
			if (r == address(0) || r == owner) continue;
			amount = amounts[i];
			wallets[r] = wallets[r].add(amount);
			emit Mint(r, amount);
			emit Transfer(address(0), r, amount);

			mapping(uint => LockBin) locks = lockbins[r];
			LockBin storage info = locks[0]; // 第一个数据永远是记录有多少条
			uint index = info.amount + 1;
			locks[index] = LockBin({
				start: releaseStart,
				finish: releaseStart + releaseDuration,
				duration: releaseDuration / (1 days),
				amount: amount
			});
			info.amount = index;
		}

		return true;
	}

	/**
	 * 返回指定用户在集资池中的总资金
	 * @param  investor 指定用户地址
	 * @return          总集资金额
	 */
	function getInvestedToken (address investor) public view returns (uint256) {
		require(investor != address(0) && investor != owner && investor != foundationOwner);

		mapping(uint => LockBin) locks = lockbins[investor];
		uint256 balance = 0;
		uint l = locks[0].amount;
		// 第一条数据是记录总数，所以循环从第二条数据开始
		for (uint i = 1; i <= l; i ++) {
			LockBin memory bin = locks[i];
			balance = balance.add(bin.amount);
		}
		return balance;
	}

	/**
	 * 返回指定用户在集资池中锁仓的总金额
	 * @param  investor 指定用户地址
	 * @return          总锁仓资金
	 */
	function getLockedToken (address investor) public view returns (uint256) {
		require(investor != address(0) && investor != owner && investor != foundationOwner);

		mapping(uint => LockBin) locks = lockbins[investor];
		uint256 balance = 0;
		uint256 d = 1;
		uint l = locks[0].amount;
		// 第一条数据是记录总数，所以循环从第二条数据开始
		for (uint i = 1; i <= l; i ++) {
			LockBin memory bin = locks[i];
			if (now <= bin.start) {
				balance = balance.add(bin.amount);
			}
			else if (now < bin.finish) {
				d = (now - bin.start) / (1 days);
				balance = balance.add(bin.amount - bin.amount * d / bin.duration);
			}
		}
		return balance;
	}

	/**
	 * 判断指定用户是否能支付指定费用
	 * @param  user   用户地址
	 * @param  amount 金额
	 * @return        是否能支付
	 */
	function canPay (address user, uint256 amount) internal view returns (bool) {
		uint256 balance = availableWallet(user);
		return amount <= balance;
	}

	/**
	 * 代币转账
	 * @param  target 目标账户地址
	 * @param  value  转账金额
	 * @return        是否转账成功
	 */
	function transfer (address target, uint256 value) public whenRunning canTransfer(msg.sender, target, value) returns (bool) {
		require(target != owner); // owner不能成为转账目标
		require(canPay(msg.sender, value));

		wallets[msg.sender] = wallets[msg.sender].sub(value);
		wallets[target] = wallets[target].add(value);
		emit Transfer(msg.sender, target, value);
		return true;
	}

	/**
	 * 批量转账（所有人转账金额一致）
	 * @param receivers 收款人数组
	 * @param amount    每人转账金额
	 * @return          返回是否成功
	 */
	function batchTransfer (address[] receivers, uint256 amount) public whenRunning returns (bool) {
		require(amount > 0);

		uint receiveLength = receivers.length;
		uint receiverCount = 0;
		uint i;
		address r;
		for (i = 0; i < receiveLength; i ++) {
			r = receivers[i];
			if (r == address(0) || r == owner) continue; // 不能自己给自己转账，也不能给owner转账
			receiverCount ++;
		}
		require(receiverCount > 0);

		uint256 totalAmount = amount.mul(uint256(receiverCount));
		require(canPay(msg.sender, totalAmount));

		wallets[msg.sender] -= totalAmount;
		for (i = 0; i < receiveLength; i++) {
			r = receivers[i];
			if (r == address(0) || r == owner) continue; // 不能自己给自己转账，也不能给owner转账
			wallets[r] = wallets[r].add(amount);
			emit Transfer(msg.sender, r, amount);
		}
		return true;
	}

	/**
	 * 批量转账（不同人转账金额不同）
	 * @param receivers 收款人数组
	 * @param amounts   每人转账金额
	 * @return          返回是否成功
	 */
	function batchTransfers (address[] receivers, uint256[] amounts) public whenRunning returns (bool) {
		uint receiveLength = receivers.length;
		require(receiveLength == amounts.length);

		uint receiverCount = 0;
		uint256 totalAmount = 0;
		uint i;
		address r;
		for (i = 0; i < receiveLength; i ++) {
			r = receivers[i];
			if (r == address(0) || r == owner) continue; // 不能自己给自己转账，也不能给owner转账
			receiverCount ++;
			totalAmount += amounts[i];
		}
		require(totalAmount > 0);
		require(canPay(msg.sender, totalAmount));

		wallets[msg.sender] -= totalAmount;
		uint256 amount;
		for (i = 0; i < receiveLength; i++) {
			r = receivers[i];
			if (r == address(0) || r == owner) continue; // 不能自己给自己转账，也不能给owner转账
			amount = amounts[i];
			if (amount == 0) continue;
			wallets[r] = wallets[r].add(amount);
			emit Transfer(msg.sender, r, amount);
		}
		return true;
	}

	/**
	 * 有代理人进行转账
	 * @param  from  付账人地址
	 * @param  to    收账人地址
	 * @param  value 转账金额
	 * @return       转账是否成功
	 */
	function transferFrom (address from, address to, uint256 value) public whenRunning canTransfer(from, to, value) returns (bool) {
		require(from != owner); // owner不参与任何形式的交易
		require(to != owner);
		require(canPay(from, value));

		uint256 warrant;
		if (msg.sender != from) {
			warrant = warrants[from][msg.sender];
			require(value <= warrant);
			warrants[from][msg.sender] = warrant.sub(value);
		}

		wallets[from] = wallets[from].sub(value);
		wallets[to] = wallets[to].add(value);
		emit Transfer(from, to, value);
		return true;
	}

	/**
	 * 批量代理转账（所有人代理转账金额一致）
	 * @param from      转账人
	 * @param receivers 收款人数组
	 * @param amount    每人转账金额
	 * @return          返回是否成功
	 */
	function batchTransferFrom (address from, address[] receivers, uint256 amount) public whenRunning returns (bool) {
		require(from != address(0) && from != owner); // owner不参与任何形式的交易
		require(amount > 0);

		uint receiveLength = receivers.length;
		uint receiverCount = 0;
		uint i;
		address r;
		for (i = 0; i < receiveLength; i ++) {
			r = receivers[i];
			if (r == address(0) || r == owner) continue; // owner不参与任何形式的交易
			receiverCount ++;
		}
		require(receiverCount > 0);

		uint256 totalAmount = amount.mul(uint256(receiverCount));
		require(canPay(from, totalAmount));

		uint256 warrant;
		if (msg.sender != from) {
			warrant = warrants[from][msg.sender];
			require(totalAmount <= warrant);
			warrants[from][msg.sender] = warrant.sub(totalAmount);
		}

		wallets[from] -= totalAmount;
		for (i = 0; i < receiveLength; i++) {
			r = receivers[i];
			if (r == address(0) || r == owner) continue; // owner不参与任何形式的交易
			wallets[r] = wallets[r].add(amount);
			emit Transfer(from, r, amount);
		}
		return true;
	}

	/**
	 * 批量代理转账（不同人代理转账金额不同）
	 * @param from      转账人
	 * @param receivers 收款人数组
	 * @param amounts   每人转账金额
	 * @return          返回是否成功
	 */
	function batchTransferFroms (address from, address[] receivers, uint256[] amounts) public whenRunning returns (bool) {
		require(from != address(0) && from != owner); // owner不参与任何形式的交易

		uint receiveLength = receivers.length;
		require(receiveLength == amounts.length);

		uint receiverCount = 0;
		uint256 totalAmount = 0;
		uint i;
		address r;
		for (i = 0; i < receiveLength; i ++) {
			r = receivers[i];
			if (r == address(0) || r == owner) continue; // owner不参与任何形式的交易
			receiverCount ++;
			totalAmount += amounts[i];
		}
		require(totalAmount > 0);
		require(canPay(from, totalAmount));

		uint256 warrant;
		if (msg.sender != from) {
			warrant = warrants[from][msg.sender];
			require(totalAmount <= warrant);
			warrants[from][msg.sender] = warrant.sub(totalAmount);
		}

		wallets[from] -= totalAmount;
		uint256 amount;
		for (i = 0; i < receiveLength; i++) {
			r = receivers[i];
			if (r == address(0) || r == owner) continue; // owner不参与任何形式的交易
			amount = amounts[i];
			if (amount == 0) continue;
			wallets[r] = wallets[r].add(amount);
			emit Transfer(from, r, amount);
		}
		return true;
	}
}

/**
 * FTN 代币
 * function suicide ()
 * function transferOwnership (address)
 * function setFountainFoundation (address)
 */
contract FountainToken is LockableToken {
	string  public constant name     = "Ftest-181025";
	string  public constant symbol   = "Ftest-181025";
	uint8   public constant decimals = 18;

	uint256 private constant TOKEN_CAP     = 10000000000 * 10 ** uint256(decimals);
	uint256 private constant TOKEN_FOUNDATION_CAP = 300000000   * 10 ** uint256(decimals);
	uint256 private constant TOKEN_INITIAL = 0   * 10 ** uint256(decimals);

	constructor () public LockableToken(TOKEN_INITIAL, TOKEN_CAP, TOKEN_FOUNDATION_CAP) {
	}

	/**
	 * 销毁合约
	 */
	function suicide () public onlyOwner {
		selfdestruct(owner);
	}

	/**
	 * 转让合约所有权
	 * @param  newOwner 新所有人
	 */
	function transferOwnership (address newOwner) public onlyOwner returns (bool) {
		require(newOwner != address(0));
		require(newOwner != owner);
		require(newOwner != foundationOwner); // 也不能是FoundationOwner
		require(wallets[owner] == 0); // Owner不得有任何形式的资产
		require(wallets[newOwner] == 0); // 新Owner不得有任何形式的资产

		address oldOwner = owner;
		owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
		
		return true;
	}
	
	/**
	 * 设置fountain 基金会管理员
	 *  @param  newFoundationOwner 基金会管理员
	 */
	function setFountainFoundationOwner (address newFoundationOwner) public onlyOwner returns (bool) {
		require(newFoundationOwner != address(0));
		require(newFoundationOwner != foundationOwner);
		require(newFoundationOwner != owner); // 基金会管理员不能是合约管理员
		require(wallets[newFoundationOwner] == 0); // 新FoundationOwner不得有任何形式的资产

		address oldFoundation = foundationOwner;
		foundationOwner = newFoundationOwner;

		emit FoundationOwnershipTransferred(oldFoundation, foundationOwner);

		// 将OldFoundationOwner账号的所有资金转移给NewFoundationOwner
		uint256 all = wallets[oldFoundation];
		wallets[oldFoundation] -= all;
		wallets[newFoundationOwner] = all;
		emit Transfer(oldFoundation, newFoundationOwner, all);

		return true;
	}
	
}