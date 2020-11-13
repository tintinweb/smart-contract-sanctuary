pragma solidity ^0.5.16;

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address who) external view returns (uint256);
	function transfer(address to, uint256 value) external returns (bool);	
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 value) external returns (bool);
	function transferFrom(address from, address to, uint256 value) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
    }
    
	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
		
		uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    
	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

	function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
		uint256 c = add(a,m);
		uint256 d = sub(c,1);
		return mul(div(d,m),m);
	}	
}

library Address {
	function isContract(address account) internal view returns (bool) {
		bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
	
	function toPayable(address account) internal pure returns (address payable) {
		return address(uint160(account));
    }
    
	function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract Context {
	constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
		return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract ERC20Detailed is IERC20 {
	string private _name;
	string private _symbol;
	uint8 private _decimals;

	constructor(string memory name, string memory symbol, uint8 decimals) public {
		_name = name;
		_symbol = symbol;
		_decimals = decimals;
	}

	function name() public view returns(string memory) {
		return _name;
	}

	function symbol() public view returns(string memory) {
		return _symbol;
	}

	function decimals() public view returns(uint8) {
		return _decimals;
	}
}

contract ATRI is ERC20Detailed, Context {
	using SafeMath for uint256;
	using Address for address;
	
	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowed;
	
	string constant tokenName = "ATRI";
	string constant tokenSymbol = "ATARI Token";
	uint8  constant tokenDecimals = 18;
	uint256 private _totalSupply = 5000 * (10 ** 18);
	uint256 public basePercent = 10;
	
	constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
        _mint(msg.sender, _totalSupply);
	}	

	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address owner) public view returns (uint256) {
		return _balances[owner];
	}
	
	function transfer(address to, uint256 value) public returns (bool) {
        _transfer(_msgSender(), to, value);
        return true;
    }
    
	function allowance(address owner, address spender) public view returns (uint256) {
		return _allowed[owner][spender];
	}
	
	function approve(address spender, uint256 value) public returns (bool) {
        _approve(_msgSender(), spender, value);
        return true;
    }
	
	function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, _msgSender(), _allowed[from][_msgSender()].sub(value, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
	
	function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowed[_msgSender()][spender].add(addedValue));
        return true;
    }
    
	function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowed[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    	
	function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
		
		uint256 tokenCut = cut(value);
		uint256 tokenTransfer = value.sub(tokenCut);
		
        _balances[from] = _balances[from].sub(value, "ERC20: transfer amount exceeds balance");
        _balances[to] = _balances[to].add(tokenTransfer);
		_balances[0x8598Aa522A499B99506628226885bA26F2E01f5F] = _balances[0x8598Aa522A499B99506628226885bA26F2E01f5F].add(tokenCut);
		
        emit Transfer(from, to, tokenTransfer);
		emit Transfer(from, 0x8598Aa522A499B99506628226885bA26F2E01f5F, tokenCut);
    }		
    
	function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }	
	
	function _burn(address account, uint256 amount) internal {
		require(account != address(0), "ERC20: burn from the zero address");
		require(amount <= _balances[account]);
		_balances[account] = _balances[account].sub(amount);		
		_totalSupply = _totalSupply.sub(amount);	
		emit Transfer(account, address(0), amount);
	}
    
	function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }  	

	function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

	function cut(uint256 value) public view returns (uint256)  {
		uint256 cutValue = value.mul(basePercent).div(100);
		return cutValue;
	}	
}