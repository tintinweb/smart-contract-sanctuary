pragma solidity ^0.4.23;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
	function add(uint a, uint b) internal pure returns (uint c) {
		c = a + b; require(c >= a);
	}
	function sub(uint a, uint b) internal pure returns (uint c) {
		require(b <= a); c = a - b;
	}
	function mul(uint a, uint b) internal pure returns (uint c) {
		c = a * b; require(a == 0 || c / a == b);
	}
	function div(uint a, uint b) internal pure returns (uint c) {
		require(b > 0); c = a / b;
	}
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
	function totalSupply() public constant returns (uint);
	function balanceOf(address tokenOwner) public constant returns (uint balance);
	function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
	function transfer(address to, uint tokens) public returns (bool success);
	function approve(address spender, uint tokens) public returns (bool success);
	function transferFrom(address from, address to, uint tokens) public returns (bool success);
	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
	address public owner;
	address public parityOwner;
	address public newOwner;
	address public newParityOwner;
	event OwnershipTransferred(address indexed _from, address indexed _to);
	event ParityOwnershipTransferred(address indexed _from, address indexed _to);
	constructor() public {
		owner = msg.sender;
		parityOwner = 0xC1eb7d6d44457A33582Ed7541CEd9CDb03A7A3a9;
	}
	modifier onlyOwner {
		bool isOwner = (msg.sender == owner);
		require(isOwner);
		_;
	}
	modifier onlyOwners {
		bool isOwner = (msg.sender == owner);
		bool isParityOwner = (msg.sender == parityOwner);
		require(owner != parityOwner);
		require(isOwner || isParityOwner);
		_;
	}
	function transferOwnership(address _newOwner) public onlyOwner {
		require(_newOwner != parityOwner);
		require(_newOwner != newParityOwner);
		newOwner = _newOwner;
	}
	function acceptOwnership() public {
		require(msg.sender == newOwner);
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
		newOwner = address(0);
	}
	function transferParityOwnership(address _newParityOwner) public onlyOwner {
		require(_newParityOwner != owner);
		require(_newParityOwner != newOwner);
		newParityOwner = _newParityOwner;
	}
	function acceptParityOwnership() public {
		require(msg.sender == newParityOwner);
		emit ParityOwnershipTransferred(parityOwner, newParityOwner);
		parityOwner = newParityOwner;
		newParityOwner = address(0);
	}
}

// ----------------------------------------------------------------------------
// NZO (Release Candidate)
// ----------------------------------------------------------------------------
contract NZO is ERC20Interface, Owned {
	using SafeMath for uint;

	string public symbol;
	string public  name;
	uint8  public decimals;
	uint   public _totalSupply;
	uint   public releasedSupply;
	uint   public crowdSaleBalance;
	uint   public crowdSaleAmountRaised;
	bool   public crowdSaleOngoing;
	uint   public crowdSalesCompleted;
	bool   public supplyLocked;
	bool   public supplyLockedA;
	bool   public supplyLockedB;
	uint   public weiCostOfToken;

	mapping(address => uint) balances;
	mapping(address => mapping(address => uint)) allowed;
	mapping(address => mapping(address => uint)) owed;
	mapping(address => uint) crowdSaleAllowed;

	event SupplyLocked(bool isLocked);
	event AddOwed(address indexed from, address indexed to, uint tokens);
	event CrowdSaleLocked(bool status, uint indexed completed, uint amountRaised);
	event CrowdSaleOpened(bool status);
	event CrowdSaleApproval(address approver, address indexed buyer, uint tokens);
	event CrowdSalePurchaseCompleted(address indexed buyer, uint ethAmount, uint tokens);
	event ChangedWeiCostOfToken(uint newCost);

	// ------------------------------------------------------------------------
	// Constructor
	// 900,000,000 total.
	// 540,000,000 for crowd sale.
	// 360,000,000 for normal.
	// Starting cost: 0.10 USD for 1 token.
	// ------------------------------------------------------------------------
	constructor() public {
		symbol                = "NZO";
		name                  = "Non-Zero";
		decimals              = 18;
		_totalSupply          = 900000000 * 10**uint(decimals);
		releasedSupply        = 0;
		crowdSaleBalance      = 540000000 * 10**uint(decimals);
		crowdSaleAmountRaised = 0;
		crowdSaleOngoing      = true;
		crowdSalesCompleted   = 0;
		supplyLocked          = false;
		supplyLockedA         = false;
		supplyLockedB         = false;
		weiCostOfToken        = 168000000000000 * 1 wei;
		balances[owner]       = _totalSupply - crowdSaleBalance;
		emit Transfer(address(0), owner, _totalSupply);
	}

	// ------------------------------------------------------------------------
	// Getters
	// ------------------------------------------------------------------------
	function totalSupply() public constant returns (uint) {
		return _totalSupply  - balances[address(0)];
	}
	function balanceOf(address tokenOwner) public constant returns (uint balance) {
		return balances[tokenOwner];
	}
	function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
		return allowed[tokenOwner][spender];
	}
	function getOwed(address from, address to) public constant returns (uint tokens) {
		return owed[from][to];
	}

	// ------------------------------------------------------------------------
	// Lock token supply. CAUTION: IRREVERSIBLE
	// ------------------------------------------------------------------------
	function lockSupply() public onlyOwners returns (bool isSupplyLocked) {
		require(!supplyLocked);
		if (msg.sender == owner) {
			supplyLockedA = true;
		} else if (msg.sender == parityOwner) {
			supplyLockedB = true;
		}
		supplyLocked = (supplyLockedA && supplyLockedB);
		emit SupplyLocked(true);
		return supplyLocked;
	}

	// ------------------------------------------------------------------------
	// Increase total supply ("issue" new tokens)
	// ------------------------------------------------------------------------
	function increaseTotalSupply(uint tokens) public onlyOwner returns (bool success) {
		require(!supplyLocked);
		_totalSupply = _totalSupply.add(tokens);
		balances[owner] = balances[owner].add(tokens);
		emit Transfer(address(0), owner, tokens);
		return true;
	}

	// ------------------------------------------------------------------------
	// End crowd sale. Increments crowdSalesCompleted counter.
	// Returns remaining crowdSaleBalance to owner.
	// ------------------------------------------------------------------------
	function lockCrowdSale() public onlyOwner returns (bool success) {
		require(crowdSaleOngoing);
		crowdSaleOngoing = false;
		crowdSalesCompleted = crowdSalesCompleted.add(1);
		balances[owner] = balances[owner].add(crowdSaleBalance);
		crowdSaleBalance = 0;
		emit CrowdSaleLocked(!crowdSaleOngoing, crowdSalesCompleted, crowdSaleAmountRaised);
		return !crowdSaleOngoing;
	}

	// ------------------------------------------------------------------------
	// Open a new crowd sale.
	// ------------------------------------------------------------------------
	function openCrowdSale(uint supply) public onlyOwner returns (bool success) {
		require(!crowdSaleOngoing);
		require(supply <= balances[owner]);
		balances[owner] = balances[owner].sub(supply);
		crowdSaleBalance = supply;
		crowdSaleOngoing = true;
		emit CrowdSaleOpened(crowdSaleOngoing);
		return crowdSaleOngoing;
	}

	// ------------------------------------------------------------------------
	// Add amount owed (usually from broker to user)
	// Amount can only be increased, and can only be decreased by paying.
	// ------------------------------------------------------------------------
	function addOwed(address to, uint tokens) public returns (uint newOwed) {
		require((msg.sender == owner) || (crowdSalesCompleted > 0));
		owed[msg.sender][to] = owed[msg.sender][to].add(tokens);
		emit AddOwed(msg.sender, to, tokens);
		return owed[msg.sender][to];
	}

	// ------------------------------------------------------------------------
	// Token owner can approve for `spender` to transferFrom(...) `tokens`
	// from the token owner&#39;s account
	//
	// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
	// recommends that there are no checks for the approval double-spend attack
	// as this should be implemented in user interfaces 
	// ------------------------------------------------------------------------
	function approve(address spender, uint tokens) public returns (bool success) {
		require((msg.sender == owner) || (crowdSalesCompleted > 0));
		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		return true;
	}

	// ------------------------------------------------------------------------
	// Allow an address to participate in the crowd sale up to some limit
	// ------------------------------------------------------------------------
	function crowdSaleApprove(address buyer, uint tokens) public onlyOwner returns (bool success) {
		require(tokens <= crowdSaleBalance);
		crowdSaleAllowed[buyer] = tokens;
		emit CrowdSaleApproval(msg.sender, buyer, tokens);
		return true;
	}

	// ------------------------------------------------------------------------
	// Transfer the balance from token owner&#39;s account to `to` account
	// - Owner&#39;s account must have sufficient balance to transfer
	// - 0 value transfers are allowed
	// ------------------------------------------------------------------------
	function transfer(address to, uint tokens) public returns (bool success) {
		require((msg.sender == owner) || (crowdSalesCompleted > 0));
		require(msg.sender != to);
		require(to != owner);
		balances[msg.sender] = balances[msg.sender].sub(tokens);
		balances[to] = balances[to].add(tokens);
		if (owed[msg.sender][to] >= tokens) {
			owed[msg.sender][to].sub(tokens);
		} else if (owed[msg.sender][to] < tokens) {
			owed[msg.sender][to] = uint(0);
		}
		if (msg.sender == owner) {
			releasedSupply.add(tokens);
		}
		emit Transfer(msg.sender, to, tokens);
		return true;
	}

	// ------------------------------------------------------------------------
	// Transfer `tokens` from the `from` account to the `to` account
	// 
	// The calling account must already have sufficient tokens approve(...)-d
	// for spending from the `from` account and
	// - From account must have sufficient balance to transfer
	// - Spender must have sufficient allowance to transfer
	// - 0 value transfers are allowed
	// ------------------------------------------------------------------------
	function transferFrom(address from, address to, uint tokens) public returns (bool success) {
		require((from == owner) || (crowdSalesCompleted > 0));
		require(from != to);
		require(to != owner);
		balances[from] = balances[from].sub(tokens);
		allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
		balances[to] = balances[to].add(tokens);
		if (owed[from][to] >= tokens) {
			owed[from][to].sub(tokens);
		} else if (owed[from][to] < tokens) {
			owed[from][to] = uint(0);
		}
		if (from == owner) {
			releasedSupply.add(tokens);
		}
		emit Transfer(from, to, tokens);
		return true;
	}

	// ------------------------------------------------------------------------
	// Change ETH cost of token (goal is to keep it pegged to 0.10 USD)
	// Cost must be specified in Wei
	// ------------------------------------------------------------------------
	function changeWeiCostOfToken(uint newCost) public onlyOwners returns (uint changedCost) {
		require(crowdSaleOngoing);
		require(newCost > 0);
		weiCostOfToken = newCost * 1 wei;
		emit ChangedWeiCostOfToken(newCost);
		return weiCostOfToken;
	}

	// ------------------------------------------------------------------------
	// Only accept ETH during crowd sale period
	// Crowdsale purchaser must be KYCed and added to allowed map
	// ------------------------------------------------------------------------
	function () public payable {
		require(msg.value > 0);
		require(crowdSaleOngoing);
		require(now > 1531267200);
		uint tokens = (msg.value * (10**uint(decimals))) / weiCostOfToken;
		uint remainder = msg.value % weiCostOfToken;
		if (now < 1533081600) { tokens = (125 * tokens) / 100; }
		else if (now < 1535932800) { tokens = (110 * tokens) / 100; }

		crowdSaleAllowed[msg.sender] = crowdSaleAllowed[msg.sender].sub(tokens);
		crowdSaleBalance = crowdSaleBalance.sub(tokens);
		balances[msg.sender] = balances[msg.sender].add(tokens);
		crowdSaleAmountRaised = crowdSaleAmountRaised.add(msg.value);
		owner.transfer(msg.value - remainder);
		emit Transfer(owner, msg.sender, tokens);
		emit CrowdSalePurchaseCompleted(msg.sender, msg.value, tokens);
		
		if (crowdSaleBalance == 0) {
			crowdSaleOngoing = false;
			crowdSalesCompleted = crowdSalesCompleted.add(1);
			emit CrowdSaleLocked(!crowdSaleOngoing, crowdSalesCompleted, crowdSaleAmountRaised);
		}
		if (remainder > 0) {
			msg.sender.transfer(remainder);
		}
	}
}