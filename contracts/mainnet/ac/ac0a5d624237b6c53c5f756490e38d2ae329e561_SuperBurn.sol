/*
 * SuperBurn (SBURN) is a extreme-deflationary, low-supply ERC 20 token, where on each transaction an insane percentage 
 * of tokens are burned, thus reducing supply and pushing the price of the token. To kick things off, the burn rate will 
 * be at an insane 10% after which every day, the burn rate will continue to increase until it reaches 45%
 * 
 * https://t.me/SuperBurn
 */

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

contract SuperBurn is Context, Ownable, ERC20Detailed, GasPump 
{
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public whitelistFrom;
    mapping(address => bool) public whitelistTo;
	
	// Wallets
	address deployerWallet = 0xfE5E024b8CFd081C44e276BC8334A5BC602e07Fd;
	address uniswapWallet = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
	
	string constant tokenName = "SuperBurn";
	string constant tokenSymbol = "SBURN";
	uint8  constant tokenDecimals = 18;
    uint256 private _totalSupply = 100 * (10 ** 18);
	uint256 public basePercent = 100;
	
    bytes32 private lastHash;
	event TransferFeeChanged(uint256 newFee);
	bool private activeFee;
	uint256 public transferFee; // Fee as percentage, where 123 = 1.23%
	
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
	
	function setTransferFee(uint256 fee) public onlyOwner 
	{
		// Maximum Possible Fee is 45%
		require(fee <= 4500, "Fee cannot be greater than 50%");
		if (fee == 0) 
		{
			activeFee = false;
		} 
		
		else 
		{
			activeFee = true;
		}
		
		transferFee = fee;
		emit TransferFeeChanged(fee);
	}
	
    function _transfer(address sender, address recipient, uint256 amount) internal requestGas 
	{
		// Checks that it's not the burn address
        
        require(amount <= _balances[sender]);
        require(recipient != address(0), "ERC20: transfer to the zero address");

		// Allow deployer to not get affected by fees, etc
		if (msg.sender == deployerWallet)
        {
            // Subtract from sender balance
            _balances[sender] = _balances[sender].sub(amount);
            
            // Add to recipient balance
			_balances[recipient] = _balances[recipient].add(amount);
			
            emit Transfer(sender, recipient, amount);
        }
		
		// Not UniSwap Wallet Transaction + Fees are set
		else if (sender != uniswapWallet && activeFee == true)
		{	
		    // Subtract from sender balance
			_balances[sender] = _balances[sender].sub(amount);
			
			uint256 tokensToBurn = transferFee.mul(amount).div(10000);
			
			// Transfer amount - set burn fee
			uint256 tokensToTransfer = amount.sub(tokensToBurn);
			
			// Add to recipient balance
			_balances[recipient] = _balances[recipient].add(tokensToTransfer);

            // Subtract burned amount from supply
			_totalSupply = _totalSupply.sub(tokensToBurn);
			
			// Transaction Documentation Log
            emit Transfer(sender, recipient, tokensToTransfer);
			emit Transfer(sender, address(0), tokensToBurn);
        }

        // UniSwap Wallet or No fees set
		else
		{
		   	// Subtract from sender balance
			_balances[sender] = _balances[sender].sub(amount);
					
			// Transfer amount
			uint256 tokensToTransfer = amount;
			
			// Add to recipient balance
			_balances[recipient] = _balances[recipient].add(tokensToTransfer);
		
			// Transaction Documentation Log
			emit Transfer(sender, recipient, tokensToTransfer);
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