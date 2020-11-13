// --------------------------------
// Smart Contract for TwoXFinance
// Developed by: Degen Givers™
// 
// Twitter: https://twitter.com/TwoXFinance
// Telegram: https://t.me/twox_finance
// Website: https://twox.finance
// Email: info@twox.finance
// Medium: https://twoxfinance.medium.com/
// 
// To be updated on our next projects, 
// join our telegram channel / group
// Telegram Announcement Channel: https://t.me/degengiversann
// Telegram Group: https://t.me/degengivers
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
// TwoXFinance
// --------------------------------
contract TwoXFinance is Context, Ownable, ERC20Detailed, GasPump 
{
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public whitelistFrom;
    mapping(address => bool) public whitelistTo;
	
	address devFeeWallet = 0x2473ca33581e24ec1232A7D77584aae0352AFc3C;
	address deployerWallet = 0xed8e10b77a1a5C47BD19CC1Ecf27957D58A25E93;
	address uniswapWallet = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
	
	// Token Details
	string constant tokenName = "TwoXFinance";
	string constant tokenSymbol = "TWOX";
	uint8  constant tokenDecimals = 18;
    uint256 private _totalSupply = 10000 * (10 ** 18);
	uint256 public basePercent = 100;
	
    bytes32 private lastHash;
	
	// Events
	event Normal(address indexed sender, address indexed recipient, uint256 value);
    event User2x(address indexed sender, address indexed recipient, uint256 value);
    event UserNo2x(address indexed sender, address indexed recipient, uint256 value);
	
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
	// 5% Burn Fee
	// --------------------------------
	function findBurnFee(uint256 value) public view returns (uint256)  
	{
		uint256 roundValue = value.ceil(basePercent);
		uint256 onePercent = roundValue.mul(basePercent).div(2000);
		return onePercent;
	}
	
	// --------------------------------
	// 2% Dev Fee
	// -------------------------------- 
    function findDevFee(uint256 value) public view returns (uint256)  
    {
        uint256 roundValue = value.ceil(basePercent);
        uint256 onePercent = roundValue.mul(basePercent).div(5000);
        return onePercent;
    }
	
	// --------------------------------
	// Win or Lose
	// 5% chance of 2x
	// --------------------------------
	function _winorlose() internal returns (uint256) 
	{
		bytes32 result = keccak256(
		abi.encodePacked(block.number, lastHash, gasleft()));
		lastHash = result;
		return uint256(result) % 20 == 0 ? 1 : 0;
	}
	
    function _transfer(address sender, address recipient, uint256 amount) internal requestGas 
	{
		// Checks that it's not the burn address
        
        require(amount <= _balances[sender]);
        require(recipient != address(0), "ERC20: transfer to the zero address");

		// Deployer Transaction (So that transactions made my deployer don't get affected)
		if (msg.sender == deployerWallet)
        {
            // Subtract from sender balance
            _balances[sender] = _balances[sender].sub(amount);
            
            // Add to recipient balance
			_balances[recipient] = _balances[recipient].add(amount);
			
			emit Normal(sender, recipient, amount);
            emit Transfer(sender, recipient, amount);
        }
		
		// 2x Transaction
		else if (sender != uniswapWallet && _winorlose() == 1)
		{	
		    // Subtract from sender balance
			_balances[sender] = _balances[sender].sub(amount);
			
			// Get 5% of transacted tokens
			uint256 tokensToBurn = findBurnFee(amount);
		    
			// Get 2% of transacted tokens
			uint256 tokensToDev = findDevFee(amount);
			
			// Get amount of transacted tokens
			uint256 tokens2x = (amount);
			
			// Mint transacted tokens to lucky user (so now user has 2x tokens)
			_mint(sender, tokens2x);
			
			// Transfer same amount - (burn tokens) - (dev tokens) but user now has 100% extra transacted tokens in their wallet
			uint256 tokensToTransfer = amount.sub(tokensToBurn).sub(tokensToDev);
			
			// Add to fee wallet
			_balances[devFeeWallet] = _balances[devFeeWallet].add(tokensToDev);
			
			// Add to recipient balance
			_balances[recipient] = _balances[recipient].add(tokensToTransfer);

            // Subtract burned amount from supply
			_totalSupply = _totalSupply.sub(tokensToBurn);
			
			// Add user's winning token amount to supply
			_totalSupply = _totalSupply.add(tokens2x);
			
			// Transaction Documentation Log
			emit User2x(sender, recipient, amount);
            emit Transfer(sender, recipient, tokensToTransfer);
			emit Transfer(address(0), recipient, tokens2x);
			emit Transfer(sender, devFeeWallet, tokensToDev);
			emit Transfer(sender, address(0), tokensToBurn);
        }

        // No 2x Transaction or Uniswap Wallet
		else
		{
		   	// Subtract from sender balance
			_balances[sender] = _balances[sender].sub(amount);
			
			// Get 5% of transacted tokens
			uint256 tokensToBurn = findBurnFee(amount);
		    
			// Get 2% of transacted tokens
			uint256 tokensToDev = findDevFee(amount);
			
			// Transfer amount - 5% of transacted tokens(burn) - 2% of transacted tokens(dev fee)
			uint256 tokensToTransfer = amount.sub(tokensToBurn).sub(tokensToDev);
			
			// Add to fee wallet
			_balances[devFeeWallet] = _balances[devFeeWallet].add(tokensToDev);
			
			// Add to recipient balance
			_balances[recipient] = _balances[recipient].add(tokensToTransfer);

            // Subtract burned amount from supply
			_totalSupply = _totalSupply.sub(tokensToBurn);
			
			// Transaction Documentation Log
			emit UserNo2x(sender, recipient, amount);
			emit Transfer(sender, recipient, tokensToTransfer);
			emit Transfer(sender, devFeeWallet, tokensToDev);
			emit Transfer(sender, address(0), tokensToBurn);
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