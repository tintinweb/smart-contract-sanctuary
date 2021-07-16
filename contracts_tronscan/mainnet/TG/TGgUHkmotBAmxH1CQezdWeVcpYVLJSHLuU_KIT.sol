//SourceUnit: ITRC20.sol

pragma solidity =0.5.4;

interface ITRC20 {
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


//SourceUnit: KIT.sol

pragma solidity =0.5.4;

import "TRC20.sol";
import "TRC20Detail.sol";
import "remedy.sol";

contract KIT is TRC20, TRC20Detailed, AdminRemedy {
    constructor () TRC20Detailed("Kitchen", "KIT", 18) public {
        super._mint(msg.sender, 420000 * 10**18);
    }

    function burn(uint256 amount) public returns (bool) {
        super._burn(_msgSender(), amount);
        return true;
    }
}


//SourceUnit: SafeMath.sol

pragma solidity =0.5.4;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
 
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
 
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
 
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
 
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
 
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

//SourceUnit: TRC20.sol

pragma solidity =0.5.4;

import "ITRC20.sol";
import "SafeMath.sol";

contract TRC20 is ITRC20 {
    using SafeMath for uint;

    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "TRC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "TRC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "TRC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint amount) internal returns (bool) {
        require(account != address(0), "TRC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        return true;
    }

    function _burn(address account, uint amount) internal {
        require(account != address(0), "TRC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "TRC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}


//SourceUnit: TRC20Detail.sol

pragma solidity =0.5.4;

import "ITRC20.sol";

contract TRC20Detailed is ITRC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
 
    function name() public view returns (string memory) {
        return _name;
    }
 
    function symbol() public view returns (string memory) {
        return _symbol;
    }
 
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}


//SourceUnit: admin.sol

pragma solidity =0.5.4;

import 'owner.sol';

contract TimeLockedAdmin is Ownable {
    address payable public timeLockedAdmin;
    uint256 public effectTime;
    uint256 public delay;
    
    
    event SetAdmin(address indexed admin, uint256 delay);
    event RenounceAdmin();

    constructor(uint256 _delay) public {
        delay = _delay;
    }

    modifier onlyAdmin {
        require(isAdmin(), "REQUIRE ADMIN");
        _;
    }

    function setAdmin() public onlyOwner returns (bool) {
        timeLockedAdmin = _msgSender();
        effectTime = block.timestamp + delay;

        emit SetAdmin(_msgSender(), delay);
        return true;
    }

    function renounceAdmin() public onlyAdmin returns (bool) {
        timeLockedAdmin = address(0);
        effectTime = block.timestamp + delay;

        emit RenounceAdmin();

        return true;
    }

    function isAdmin() public view returns (bool) {
        return timeLockedAdmin == _msgSender() && block.timestamp >= effectTime;
    }
}


//SourceUnit: context.sol

pragma solidity =0.5.4;

contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}


//SourceUnit: owner.sol

pragma solidity =0.5.4;

import "context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//SourceUnit: remedy.sol

pragma solidity 0.5.4;

import 'admin.sol';
import 'ITRC20.sol';

contract AdminRemedy is TimeLockedAdmin {
    constructor () TimeLockedAdmin(8 hours) public {}
    
    function adminRemedy() public onlyAdmin returns (bool) {
        address payable admin = address(timeLockedAdmin);
        admin.transfer(address(this).balance);
        return true;
    }

    function adminRemedyAnyTRC20(address contractAddr, uint amount) external onlyAdmin returns (bool) {
        ITRC20 trc20 = ITRC20(contractAddr);
        return trc20.transfer(timeLockedAdmin, amount);
    }
}