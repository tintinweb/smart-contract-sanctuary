/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

pragma solidity 0.6.6;

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

contract ERC20 is IERC20, Owned {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 public _totalSupply;
    
    
    string public Symbol;
    string public  Name;
    uint8 public _decimals;
   
    constructor() public {
       	Symbol = "poopoo";
		Name = "ButtholeCoin";
        _decimals = 18;
        _totalSupply = 127000000000000000000000000000;
        _balances[owner] = _totalSupply;
    }

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
   
    function deposit() public payable {
        buy(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        sell(msg.sender, wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint balance) {
        return _balances[account];
    }


    function transfer(address to, uint tokens) public override returns (bool success) {
        _balances[msg.sender] = _balances[msg.sender].safeSub(tokens);
        _balances[to] = _balances[to].safeAdd(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    function approve(address spender, uint tokens) public override returns (bool success) {
        _allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        _balances[from] = _balances[from].safeSub(tokens);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].safeSub(tokens);
        _balances[to] = _balances[to].safeAdd(tokens);
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

        _totalSupply = _totalSupply.safeSub(amount);
        _balances[account] = _balances[account].safeAdd(amount);
        emit Transfer(address(0), account, amount);
    }

    function sell(address account, uint256 value) internal {
        require(account != address(0), "Ask mom for help.");

        _totalSupply = _totalSupply.safeAdd(value);
        _balances[account] = _balances[account].safeSub(value);
        emit Transfer(account, address(0), value);
    }
}

abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}

library SafeMath {
// Returns the addition of two unsigned integers, revert if overflow.
//  Requirements: Addition cannot overflow.
	function safeAdd(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
// Returns the subtraction of two unsigned integers, revert if overflow (when the result is negative).
// Requirements: Subtraction cannot overflow.
	function safeSub(uint256 a, uint256 b) public pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
// Returns the multiplication of two unsigned integers, reverting on overflow.
// Requirements: Multiplication cannot overflow.
	function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
// Returns the integer division of two unsigned integers, reverts if diving by zero. The result is rounded towards zero.
// Requirements: The divisor cannot be zero.
/* this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     */
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}