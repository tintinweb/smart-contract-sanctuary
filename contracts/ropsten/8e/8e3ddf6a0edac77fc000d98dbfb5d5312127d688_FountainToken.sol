pragma solidity ^0.4.25;

library SafeMath {
	function mul (uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	function div (uint256 a, uint256 b) internal pure returns (uint256) {
		return a / b;
	}

	function sub (uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add (uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

contract ERCBasic {
	event Transfer(address indexed from, address indexed to, uint256 value);

	function totalSupply () public view returns (uint256);
	function balanceOf (address who) public view returns (uint256);
	function transfer (address to, uint256 value) public returns (bool);
}

contract ERC is ERCBasic {
	event Approval(address indexed owner, address indexed spender, uint256 value);

	function transferFrom (address from, address to, uint256 value) public returns (bool);
	function allowance (address owner, address spender) public view returns (uint256);
	function approve (address spender, uint256 value) public returns (bool);
}

contract Ownable {
	event OwnershipTransferred(address indexed oldone, address indexed newone);
	event FoundationOwnershipTransferred(address indexed oldFoundationOwner, address indexed newFoundationOwner);

	address internal owner;
	address internal foundationOwner;

	constructor () public {
		owner = msg.sender;
		foundationOwner = owner;
	}

	modifier onlyOwner () {
		require(msg.sender == owner);
		_;
	}

	modifier hasMintability () {
		require(msg.sender == owner || msg.sender == foundationOwner);
		_;
	}

	function transferOwnership (address newOwner) public returns (bool);
	
	function setFountainFoundationOwner (address foundation) public returns (bool);
}

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

	function pause () public onlyOwner {
		pauseFrom = now - 1;
		pauseTo = now + 30000 days;
		emit ContractPause();
	}

	function pause (uint256 from, uint256 to) public onlyOwner {
		require(to > from);
		pauseFrom = from;
		pauseTo = to;
		emit ContractPauseSchedule(from, to);
	}

	function resume () public onlyOwner {
		pauseFrom = now - 2;
		pauseTo = now - 1;
		emit ContractResume();
	}
}

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

	function startForge () public onlyOwner cannotForge returns (bool) {
		forge_running = true;
		emit ForgeStart();
		return true;
	}

	function stopForge () public onlyOwner canForge returns (bool) {
		forge_running = false;
		emit ForgeStop();
		return true;
	}
}

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

contract BasicToken is ERCBasic, Pausable {
	using SafeMath for uint256;

	mapping(address => uint256) public wallets;

	modifier canTransfer (address _from, address _to, uint256 amount) {
		require((_from != address(0)) && (_to != address(0)));
		require(_from != _to);
		require(amount > 0);
		_;
	}

	function balanceOf (address user) public view returns (uint256) {
		return wallets[user];
	}
}

contract DelegatableToken is ERC, BasicToken {
	using SafeMath for uint256;

	mapping(address => mapping(address => uint256)) public warrants;

	function allowance (address owner, address delegator) public view returns (uint256) {
		return warrants[owner][delegator];
	}

	function approve (address delegator, uint256 value) public whenRunning returns (bool) {
		if (delegator == msg.sender) return true;
		warrants[msg.sender][delegator] = value;
		emit Approval(msg.sender, delegator, value);
		return true;
	}

	function increaseApproval (address delegator, uint256 delta) public whenRunning returns (bool) {
		if (delegator == msg.sender) return true;
		uint256 value = warrants[msg.sender][delegator].add(delta);
		warrants[msg.sender][delegator] = value;
		emit Approval(msg.sender, delegator, value);
		return true;
	}

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

contract LockableProtocol is BasicToken {
	function invest (address investor, uint256 amount) public returns (bool);
	function getInvestedToken (address investor) public view returns (uint256);
	function getLockedToken (address investor) public view returns (uint256);
	function availableWallet (address user) public view returns (uint256) {
		return wallets[user].sub(getLockedToken(user));
	}
}

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

	function totalSupply () public view returns (uint256) {
		return token_created;
	}

	function totalFountainSupply() public view returns(uint256) {
		return token_foundation_created;
	}

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

	uint256 public releaseStart;
	uint256 public releaseDuration;
	bool public forceStopInvest;
	mapping(address => mapping(uint => LockBin)) public lockbins;

	modifier canInvest () {
		require(!forceStopInvest);
		_;
	}

	constructor (uint256 _initial, uint256 _cap, uint256 _fountainCap) public MintAndBurnToken(_initial, _cap, _fountainCap) {
		forceStopInvest = true;
	}

	function pauseInvest () public onlyOwner whenRunning returns (bool) {
		require(!forceStopInvest);
		forceStopInvest = true;
		emit InvestStop();
		return true;
	}

	function resumeInvest () public onlyOwner whenRunning returns (bool) {
		require(forceStopInvest);
		forceStopInvest = false;
		emit InvestStart();
		return true;
	}

	function setInvest (uint256 release_start, uint256 release_duration) public onlyOwner whenRunning returns (bool) {
		releaseStart = release_start;
		releaseDuration = release_duration;
		forceStopInvest = false;

		emit NewInvest(release_start, release_duration);
		return true;
	}

	function invest (address investor, uint256 amount) public onlyOwner whenRunning canInvest returns (bool) {
		require(investor != address(0));
		require(investor != owner);
		require(investor != foundationOwner);
		require(amount > 0);
		require(canMint(amount));

		mapping(uint => LockBin) locks = lockbins[investor];
		LockBin storage info = locks[0];
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

	function batchInvest (address[] investors, uint256 amount) public onlyOwner whenRunning canInvest returns (bool) {
		require(amount > 0);

		uint investorsLength = investors.length;
		uint investorsCount = 0;
		uint i;
		address r;
		for (i = 0; i < investorsLength; i ++) {
			r = investors[i];
			if (r == address(0) || r == owner || r == foundationOwner) continue;
			investorsCount ++;
		}
		require(investorsCount > 0);

		uint256 totalAmount = amount.mul(uint256(investorsCount));
		require(canMint(totalAmount));

		token_created = token_created.add(totalAmount);

		for (i = 0; i < investorsLength; i ++) {
			r = investors[i];
			if (r == address(0) || r == owner || r == foundationOwner) continue;

			mapping(uint => LockBin) locks = lockbins[r];
			LockBin storage info = locks[0];
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
			LockBin storage info = locks[0];
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

	function getInvestedToken (address investor) public view returns (uint256) {
		require(investor != address(0) && investor != owner && investor != foundationOwner);

		mapping(uint => LockBin) locks = lockbins[investor];
		uint256 balance = 0;
		uint l = locks[0].amount;
		for (uint i = 1; i <= l; i ++) {
			LockBin memory bin = locks[i];
			balance = balance.add(bin.amount);
		}
		return balance;
	}

	function getLockedToken (address investor) public view returns (uint256) {
		require(investor != address(0) && investor != owner && investor != foundationOwner);

		mapping(uint => LockBin) locks = lockbins[investor];
		uint256 balance = 0;
		uint256 d = 1;
		uint l = locks[0].amount;
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

	function canPay (address user, uint256 amount) internal view returns (bool) {
		uint256 balance = availableWallet(user);
		return amount <= balance;
	}

	function transfer (address target, uint256 value) public whenRunning canTransfer(msg.sender, target, value) returns (bool) {
		require(target != owner);
		require(canPay(msg.sender, value));

		wallets[msg.sender] = wallets[msg.sender].sub(value);
		wallets[target] = wallets[target].add(value);
		emit Transfer(msg.sender, target, value);
		return true;
	}


	function batchTransfer (address[] receivers, uint256 amount) public whenRunning returns (bool) {
		require(amount > 0);

		uint receiveLength = receivers.length;
		uint receiverCount = 0;
		uint i;
		address r;
		for (i = 0; i < receiveLength; i ++) {
			r = receivers[i];
			if (r == address(0) || r == owner) continue;
			receiverCount ++;
		}
		require(receiverCount > 0);

		uint256 totalAmount = amount.mul(uint256(receiverCount));
		require(canPay(msg.sender, totalAmount));

		wallets[msg.sender] -= totalAmount;
		for (i = 0; i < receiveLength; i++) {
			r = receivers[i];
			if (r == address(0) || r == owner) continue;
			wallets[r] = wallets[r].add(amount);
			emit Transfer(msg.sender, r, amount);
		}
		return true;
	}

	function batchTransfers (address[] receivers, uint256[] amounts) public whenRunning returns (bool) {
		uint receiveLength = receivers.length;
		require(receiveLength == amounts.length);

		uint receiverCount = 0;
		uint256 totalAmount = 0;
		uint i;
		address r;
		for (i = 0; i < receiveLength; i ++) {
			r = receivers[i];
			if (r == address(0) || r == owner) continue;
			receiverCount ++;
			totalAmount += amounts[i];
		}
		require(totalAmount > 0);
		require(canPay(msg.sender, totalAmount));

		wallets[msg.sender] -= totalAmount;
		uint256 amount;
		for (i = 0; i < receiveLength; i++) {
			r = receivers[i];
			if (r == address(0) || r == owner) continue;
			amount = amounts[i];
			if (amount == 0) continue;
			wallets[r] = wallets[r].add(amount);
			emit Transfer(msg.sender, r, amount);
		}
		return true;
	}

	function transferFrom (address from, address to, uint256 value) public whenRunning canTransfer(from, to, value) returns (bool) {
		require(from != owner);
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

	function batchTransferFrom (address from, address[] receivers, uint256 amount) public whenRunning returns (bool) {
		require(from != address(0) && from != owner);
		require(amount > 0);

		uint receiveLength = receivers.length;
		uint receiverCount = 0;
		uint i;
		address r;
		for (i = 0; i < receiveLength; i ++) {
			r = receivers[i];
			if (r == address(0) || r == owner) continue;
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
			if (r == address(0) || r == owner) continue;
			wallets[r] = wallets[r].add(amount);
			emit Transfer(from, r, amount);
		}
		return true;
	}

	function batchTransferFroms (address from, address[] receivers, uint256[] amounts) public whenRunning returns (bool) {
		require(from != address(0) && from != owner);

		uint receiveLength = receivers.length;
		require(receiveLength == amounts.length);

		uint receiverCount = 0;
		uint256 totalAmount = 0;
		uint i;
		address r;
		for (i = 0; i < receiveLength; i ++) {
			r = receivers[i];
			if (r == address(0) || r == owner) continue;
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
			if (r == address(0) || r == owner) continue;
			amount = amounts[i];
			if (amount == 0) continue;
			wallets[r] = wallets[r].add(amount);
			emit Transfer(from, r, amount);
		}
		return true;
	}
}

contract FountainToken is LockableToken {
	string  public constant name     = "Fountain";
	string  public constant symbol   = "FTN";
	uint8   public constant decimals = 18;

	uint256 private constant TOKEN_CAP     = 10000000000 * 10 ** uint256(decimals);
	uint256 private constant TOKEN_FOUNDATION_CAP = 300000000   * 10 ** uint256(decimals);
	uint256 private constant TOKEN_INITIAL = 0   * 10 ** uint256(decimals);

	constructor () public LockableToken(TOKEN_INITIAL, TOKEN_CAP, TOKEN_FOUNDATION_CAP) {
	}

	function suicide () public onlyOwner {
		selfdestruct(owner);
	}

	function transferOwnership (address newOwner) public onlyOwner returns (bool) {
		require(newOwner != address(0));
		require(newOwner != owner);
		require(newOwner != foundationOwner);
		require(wallets[owner] == 0);
		require(wallets[newOwner] == 0);

		address oldOwner = owner;
		owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
		
		return true;
	}
	
	function setFountainFoundationOwner (address newFoundationOwner) public onlyOwner returns (bool) {
		require(newFoundationOwner != address(0));
		require(newFoundationOwner != foundationOwner);
		require(newFoundationOwner != owner);
		require(wallets[newFoundationOwner] == 0);

		address oldFoundation = foundationOwner;
		foundationOwner = newFoundationOwner;

		emit FoundationOwnershipTransferred(oldFoundation, foundationOwner);

		uint256 all = wallets[oldFoundation];
		wallets[oldFoundation] -= all;
		wallets[newFoundationOwner] = all;
		emit Transfer(oldFoundation, newFoundationOwner, all);

		return true;
	}
	
}