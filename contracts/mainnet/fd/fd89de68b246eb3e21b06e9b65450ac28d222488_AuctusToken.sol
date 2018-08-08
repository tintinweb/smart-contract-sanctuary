pragma solidity ^0.4.21;


library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(a <= c);
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(a >= b);
		return a - b;
	}
}


contract EthereumStandards {
	/* Implements ERC 20 standard */
	uint256 public totalSupply;

	function balanceOf(address who) public constant returns (uint256);
	function allowance(address owner, address spender) public constant returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	function transferFrom(address from, address to, uint256 value) public returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	/* Added support for the ERC 223 */
	function transfer(address to, uint256 value, bytes data) public returns (bool);
	function transfer(address to, uint256 value, bytes data, string custom_fallback) public returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);
}


contract ContractReceiver {
	function tokenFallback(address from, uint256 value, bytes data) public;
}


contract AuctusToken is EthereumStandards {
	using SafeMath for uint256;
	
	string constant public name = "Auctus Token";
	string constant public symbol = "AUC";
	uint8 constant public decimals = 18;
	uint256 public totalSupply;

	mapping(address => uint256) public balances;
	mapping(address => mapping(address => uint256)) public allowed;

	address public contractOwner;
	address public tokenSaleContract;
	address public preSaleDistributionContract;
	bool public tokenSaleIsFinished;

	event Burn(address indexed from, uint256 value);

	modifier onlyOwner() {
		require(contractOwner == msg.sender);
		_;
	}

	function AuctusToken() public {
		contractOwner = msg.sender;
		tokenSaleContract = address(0);
		tokenSaleIsFinished = false;
	}

	function balanceOf(address who) public constant returns (uint256) {
		return balances[who];
	}

	function allowance(address owner, address spender) public constant returns (uint256) {
		return allowed[owner][spender];
	}

	function approve(address spender, uint256 value) public returns (bool) {
		allowed[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, value);
		return true;
	}

	function increaseApproval(address spender, uint256 value) public returns (bool) {
		allowed[msg.sender][spender] = allowed[msg.sender][spender].add(value);
		emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
		return true;
	}

	function decreaseApproval(address spender, uint256 value) public returns (bool) {
		uint256 currentValue = allowed[msg.sender][spender];
		if (value > currentValue) {
			allowed[msg.sender][spender] = 0;
		} else {
			allowed[msg.sender][spender] = currentValue.sub(value);
		}
		emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
		return true;
	}

	function transferFrom(address from, address to, uint256 value) public returns (bool) {
		allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
		internalTransfer(from, to, value);
		emit Transfer(from, to, value);
		return true;
	}

	function transfer(address to, uint256 value) public returns (bool) {
		internalTransfer(msg.sender, to, value);
		emit Transfer(msg.sender, to, value);
		return true;
	}

	function transfer(address to, uint256 value, bytes data) public returns (bool) {
		internalTransfer(msg.sender, to, value);
		if (isContract(to)) {
			callTokenFallback(to, msg.sender, value, data);
		}
		emit Transfer(msg.sender, to, value, data);
		return true;
	}

	function transfer(address to, uint256 value, bytes data, string custom_fallback) public returns (bool) {
		internalTransfer(msg.sender, to, value);
		if (isContract(to)) {
			assert(to.call.value(0)(bytes4(keccak256(custom_fallback)), msg.sender, value, data));
		} 
		emit Transfer(msg.sender, to, value, data);
		return true;
	}

	function burn(uint256 value) public returns (bool) {
		internalBurn(msg.sender, value);
		return true;
	}

	function burnFrom(address from, uint256 value) public returns (bool) {
		allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
		internalBurn(from, value);
		return true;
	}

	function transferOwnership(address newOwner) onlyOwner public {
		require(newOwner != address(0));
		contractOwner = newOwner;
	}

	function setTokenSale(address tokenSale, address preSaleDistribution, uint256 maximumSupply) onlyOwner public {
		require(tokenSaleContract == address(0));
		preSaleDistributionContract = preSaleDistribution;
		tokenSaleContract = tokenSale;
		totalSupply = maximumSupply;
		balances[tokenSale] = maximumSupply;
		bytes memory empty;
		callTokenFallback(tokenSale, 0x0, maximumSupply, empty);
		emit Transfer(0x0, tokenSale, maximumSupply);
	}

	function setTokenSaleFinished() public {
		require(msg.sender == tokenSaleContract);
		tokenSaleIsFinished = true;
	}

	function isContract(address _address) private constant returns (bool) {
		uint256 length;
		assembly {
			length := extcodesize(_address)
		}
		return (length > 0);
	}

	function internalTransfer(address from, address to, uint256 value) private {
		require(canTransfer(from));
		balances[from] = balances[from].sub(value);
		balances[to] = balances[to].add(value);
	}

	function internalBurn(address from, uint256 value) private {
		balances[from] = balances[from].sub(value);
		totalSupply = totalSupply.sub(value);
		emit Burn(from, value);
	}

	function callTokenFallback(address to, address from, uint256 value, bytes data) private {
		ContractReceiver(to).tokenFallback(from, value, data);
	}

	function canTransfer(address from) private view returns (bool) {
		return (tokenSaleIsFinished || from == tokenSaleContract || from == preSaleDistributionContract);
	}
}