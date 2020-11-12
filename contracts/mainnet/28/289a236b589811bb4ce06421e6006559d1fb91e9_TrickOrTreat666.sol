// --------------------------------
// Smart Contract for tot666.finance
// Twitter: https://twitter.com/tot666finance
// Telegram: https://t.me/tot666finance
// Website: https://tot666.finance
// Email: contact@tot666.finance
// Medium: https://tot666finance.medium.com/tot-finance-6b389add27e9
// --------------------------------

pragma solidity ^0.5.17;

contract Context
{
    constructor() internal {}

    function _msgSender() internal view returns (address payable) 
	{
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) 
	{
        this;
        return msg.data;
    }
}

contract Ownable is Context 
{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal 
	{
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) 
	{
        return _owner;
    }

    modifier onlyOwner() 
	{
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) 
	{
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner 
	{
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner 
	{
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal 
	{
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// --------------------------------
// Safe Math Library
// Added ceiling function
// --------------------------------
library SafeMath 
{
    function add(uint256 a, uint256 b) internal pure returns (uint256) 
	{
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
		
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
	{
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
	{
        require(b <= a, errorMessage);
        uint256 c = a - b;
		
        return c;
    }

	// Gas Optimization
    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
	{
        if (a == 0) 
		{
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) 
	{
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
	{
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) 
	{
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
	{
        require(b != 0, errorMessage);
        return a % b;
    }
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) 
	{
		uint256 c = add(a,m);
		uint256 d = sub(c,1);
		return mul(div(d,m),m);
	}
}

interface IERC20 
{
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
		
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Detailed is IERC20 
{
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals) public 
	{
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns (string memory) 
	{
        return _name;
    }

    function symbol() public view returns (string memory) 
	{
        return _symbol;
    }

    function decimals() public view returns (uint8) 
	{
        return _decimals;
    }
}

// --------------------------------
// Ensure enough gas
// --------------------------------
contract GasPump 
{
    bytes32 private stub;
    uint256 private constant target = 10000;

    modifier requestGas() 
	{
        if (tx.gasprice == 0 || gasleft() > block.gaslimit) 
		{
            _;
            uint256 startgas = gasleft();
            while (startgas - gasleft() < target) 
			{
                // Burn gas
                stub = keccak256(abi.encodePacked(stub));
            }
        } 
		
		else 
		{
            _;
        }
    }
}

// --------------------------------
// TrickOrTreat666Finance
// --------------------------------
contract TrickOrTreat666 is Context, Ownable, ERC20Detailed, GasPump 
{
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public whitelistFrom;
    mapping(address => bool) public whitelistTo;
	
	// Token Details
	string constant tokenName = "TOTFinance";
	string constant tokenSymbol = "TOT";
	uint8  constant tokenDecimals = 18;
    uint256 private _totalSupply = 666 * (10 ** 18);
	
	// For %
	uint256 public basePercent = 100;
	uint256 public basePercentTop = 2;
	uint256 public basePercentBot = 3;
	uint256 public basePercentEnd = 100;
	
    bytes32 private lastHash;
	
	// Whitelist
    event WhitelistFrom(address _addr, bool _whitelisted);
    event WhitelistTo(address _addr, bool _whitelisted);
	
	// Events
	event Normal(address indexed sender, address indexed recipient, uint256 value);
    event Trick(address indexed sender, address indexed recipient, uint256 value);
    event Treat(address indexed sender, address indexed recipient, uint256 value);
	
	constructor() public ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) 
	{
		_mint(msg.sender, _totalSupply);
	}

    function totalSupply() public view returns (uint256) 
	{
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) 
	{
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) 
	{
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) 
	{
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient,uint256 amount) public returns (bool) 
    {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(_msgSender(), spender,
		_allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function burn(uint256 amount) public 
	{
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public 
	{
        _burnFrom(account, amount);
    }
	
	// --------------------------------
	// 66.6% Trick/Treat on each transaction
	// --------------------------------
	function findOnePercent(uint256 value) public view returns (uint256)  
	{
		uint256 roundValue = value.ceil(basePercent);
		uint256 onePercent = roundValue.mul(basePercent).mul(basePercentTop).div(basePercentBot).div(basePercentEnd);
		return onePercent;
	}

    function setWhitelistedTo(address _addr, bool _whitelisted)
        external
        onlyOwner
    {
        emit WhitelistTo(_addr, _whitelisted);
        whitelistTo[_addr] = _whitelisted;
    }

    function setWhitelistedFrom(address _addr, bool _whitelisted)
        external
        onlyOwner
    {
        emit WhitelistFrom(_addr, _whitelisted);
        whitelistFrom[_addr] = _whitelisted;
    }

    function _isWhitelisted(address _from, address _to)
        internal
        view
        returns (bool)
    {
        return whitelistFrom[_from] || whitelistTo[_to];
    }
	
	// --------------------------------
	// 50% Trick/Treat Chance
	// --------------------------------
	function _trickortreat() internal returns (uint256) 
	{
		bytes32 result = keccak256(
		abi.encodePacked(block.number, lastHash, gasleft()));
		lastHash = result;
		return uint256(result) % 2 == 0 ? 1 : 0;
	}
	
	// Triggers on every transfer
    function _transfer(address sender, address recipient, uint256 amount) internal requestGas 
	{
		// Gets balance of sender, makes sure value being sent is <= their balance
		//require(amount <= _balances[sender]);
		//require(amount <= _allowances[sender][_msgSender()]);

		// Checks that it's not the burn address
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

		// Deployer Transaction (So that transactions made my deployer don't get tricked / treated)
        if (_isWhitelisted(sender, recipient))
        {
            // Subtract from sender balance
            _balances[sender] = _balances[sender].sub(amount);
            
            // Add to recipient balance
			_balances[recipient] = _balances[recipient].add(amount);
			
			emit Normal(sender, recipient, amount);
            emit Transfer(sender, recipient, amount);
        }
		
		// Trick Transaction
		else if (!_isWhitelisted(sender, recipient) && _trickortreat() == 1) 
		{	    
		    // Subtract from sender balance
			_balances[sender] = _balances[sender].sub(amount);
		    
			// Get 66.6% of transacted tokens
			uint256 tokensToBurn = findOnePercent(amount);
			
			// Transfer amount - 66.6% of transacted tokens
			uint256 tokensToTransfer = amount.sub(tokensToBurn);
			
			// Add to recipient balance
			_balances[recipient] = _balances[recipient].add(tokensToTransfer);

            // Subtract burn amount from supply
			_totalSupply = _totalSupply.sub(tokensToBurn);

			emit Trick(sender, recipient, amount);
			emit Transfer(sender, recipient, tokensToTransfer);
			emit Transfer(sender, address(0), tokensToBurn);
        }

        // Treat transaction
		else 
		{
		   	// Subtract from sender balance
			_balances[sender] = _balances[sender].sub(amount);
		    
			// Get 66.6% of transacted tokens
			uint256 tokensToTreat = findOnePercent(amount);
			
			// Mint 66.6% of tokens to lucky user
			_mint(sender, tokensToTreat);
			
			// Transfer same amount but user now has 66% extra tokens in their wallet
			uint256 tokensToTransfer = amount;
			
			// Add to recipient balance
			_balances[recipient] = _balances[recipient].add(tokensToTransfer);
			
			// Add treat amount to supply
			_totalSupply = _totalSupply.add(tokensToTreat);
			
			emit Treat(sender, recipient, amount);
			emit Transfer(address(0), recipient, tokensToTreat);
			emit Transfer(sender, recipient, amount);
		}
    }

    function _mint(address account, uint256 amount) internal 
	{	
		require(amount != 0);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal 
	{
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal 
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal 
	{
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}