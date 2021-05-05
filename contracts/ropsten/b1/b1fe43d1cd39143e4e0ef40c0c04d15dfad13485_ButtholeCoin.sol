/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity ^0.6.6;

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

interface IERC20 {
    
//  Returns the amount of tokens in existence.
	function totalSupply() external view returns (uint256);
// Returns the amount of tokens owned by `account`.
	function balanceOf(address account) external view returns (uint256);
// Returns a boolean value indicating whether the operation succeeded.
//  Triggers Transfer event.
	function transfer(address recipient, uint256 amount) external returns (bool);
// Value changes when approve or transferFrom are triggered
	function allowance(address owner, address spender) external view returns (uint256);
// Returns a boolean value indicating whether the operation succeeded.
	function approve(address spender, uint256 amount) external returns (bool);
//  Returns a boolean value indicating whether the operation succeeded.
// Triggers a Transfer event.
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
// Triggered when `value` tokens are moved ('from ')one account ('to') another.
// `value` may be zero.
    event Transfer(address indexed from, address indexed recipient, uint256 value);
// Triggered when the allowance of a `spender` for an `owner` is set by a call to {approve}. `value` = new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) public _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 public _totalSupply;

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint balance) {
        return _balances[account];
    }


    function transfer(address to, uint tokens) public override returns (bool success) {
        _balances[msg.sender].safeSub(tokens);
        _balances[to].safeAdd(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    function approve(address spender, uint tokens) public override returns (bool success) {
        _allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        _balances[from].safeSub(tokens);
        _allowed[from][msg.sender].safeSub(tokens);
        _balances[to].safeAdd(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return _allowed[tokenOwner][spender];
    }


    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        _allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
    
    function buy(address account, uint256 amount) internal {
        require(account != address(0), "Ask mom for help.");
        assert(_totalSupply <=127000000000000000000000000000);

        _totalSupply.safeSub(amount);
        _balances[account].safeAdd(amount);
        emit Transfer(address(0), account, amount);
    }

    function sell(address account, uint256 value) internal {
        require(account != address(0), "Ask mom for help.");

        _totalSupply.safeAdd(value);
        _balances[account].safeSub(value);
        emit Transfer(account, address(0), value);
    }
}

contract ButtholeCoin is ERC20, Owned {
    string public _symbol;
    string public  _name;
    uint8 public _decimals;
    
    constructor() public {
        _symbol = "poopoo";
		_name = "ButtholeCoin";
        _decimals = 18;
        _totalSupply = 127000000000000000000000000000;
        _balances[owner] = _totalSupply;
    }
    
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
   
    function Buy(uint256) external payable {
        buy(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function Sell(uint256 wad) public {
        sell(msg.sender, wad);
        emit Withdrawal(msg.sender, wad);
    }
}

abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}

pragma solidity ^0.6.6;

library SafeMath {
	function safeAdd(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
	function safeSub(uint256 a, uint256 b) public pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
}