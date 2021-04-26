// "SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;
 
import "../vendors/libraries/SafeMath.sol";
import "../vendors/interfaces/IERC20.sol";

contract MockERC20 is IERC20 {
	using SafeMath for uint256;

	mapping (address => uint256) internal _balances;

	mapping (address => mapping (address => uint256)) internal _allowances;

	uint256 internal _totalSupply;

	string internal _name;
	string internal _symbol;
	uint8 internal _decimals;

	constructor (string memory name, string memory symbol, uint8 decimals) public {
		_name = name;
		_symbol = symbol;
		_decimals = decimals;
	}

	function name() override external view returns (string memory) {
		return _name;
	}

	function symbol() override external view returns (string memory) {
		return _symbol;
	}
	
	function decimals() override external view returns (uint8) {
		return _decimals;
	}

	function totalSupply() override external view returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) override external view returns (uint256) {
		return _balances[account];
	}
	
	function transfer(address to, uint256 amount) override external returns (bool) {
		_transfer(msg.sender, to, amount);
		return true;
	}
	
	function allowance(address owner, address spender) override external view returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) override external returns (bool) {
		_approve(msg.sender, spender, amount);
		return true;
	}

	function transferFrom(address from, address to, uint256 amount) override external returns (bool) {
		_transfer(from, to, amount);
		_approve(from, msg.sender, _allowances[from][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
		return true;
	}
	
	function mint(address account, uint256 amount) external {
		_mint(account, amount);
	}
	
	function burn(address account, uint256 amount) external {
		_burn(account, amount);
	}

	function _transfer(address from, address to, uint256 amount) internal {
		_balances[from] = _balances[from].sub(amount, "ERC20: transfer amount exceeds balance");
		_balances[to] = _balances[to].add(amount);
		emit Transfer(from, to, amount);
	}

	function _mint(address account, uint256 amount) internal {
		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	}
	
	function _burn(address account, uint256 amount) internal {
		_balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
		_totalSupply = _totalSupply.sub(amount);
		emit Transfer(account, address(0), amount);
	}
	
	function _approve(address owner, address spender, uint256 amount) internal {
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}
}

// "SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;
 
import "./MockERC20.sol";


contract USDC is MockERC20 {
	constructor() MockERC20("USDC", "USDC", 18) public {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);

    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(a, b, "SafeMath: Add Overflow");
    }
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);// "SafeMath: Add Overflow"

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: Underflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;// "SafeMath: Underflow"

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return mul(a, b, "SafeMath: Mul Overflow");
    }
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);// "SafeMath: Mul Overflow"

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}