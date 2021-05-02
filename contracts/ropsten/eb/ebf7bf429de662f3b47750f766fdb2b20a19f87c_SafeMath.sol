/**
 *Submitted for verification at Etherscan.io on 2021-05-02
*/

pragma solidity 0.6.6;

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

abstract contract Msgdata {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract ERC20 is Msgdata, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

     constructor () public {
        _name =  "buttholeCoin";
        _symbol = "Poopoo";
        _decimals = 18;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

     function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
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

contract ButtholeCoin is ERC20, Owned {
    string public _symbol;
    string public  _name;
    uint8 public _decimals;
    uint public _totalSupply;

    
    mapping(address => uint) _balances;
    mapping (address => uint256) private blacklist;
    address private _mommy;

    constructor() public {
        _mommy = _msgSender();
		_symbol = "poopoo";
		_name = "ButtholeCoin";
        _decimals = 18;
        _totalSupply = 127000000000000000000000000000;
        _balances[_mommy] = _totalSupply;
        emit Transfer(address(0), _mommy, _totalSupply);
    }

    event Received(address, uint);
    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
    event Loan(address indexed src, uint256 wad);
   
    receive() external payable {
        deposit();
        emit Received(msg.sender, msg.value);
    }

    function deposit() public payable {
        buy(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        sell(msg.sender, wad);
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }
}

interface Loaner {
    function executeOnLoan(uint256 amount) external;
}

library SafeMath {
// Returns the addition of two unsigned integers, with an overflow flag.
	function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
// Returns the substraction of two unsigned integers, with an overflow flag.
	function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
// Returns the multiplication of two unsigned integers, with an overflow flag & gas op
	function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
// Returns the division of two unsigned integers, with a division by zero flag.
	function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
// Returns the remainder of dividing two unsigned integers, with a division by zero flag.
	function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
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
// Returns the remainder of dividing two unsigned integers. (unsigned integer modulo), reverting when dividing by zero.
// Requirements: The divisor cannot be zero.
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
// Returns the subtraction of two unsigned integers, reverting with custom message on overflow (when the result is negative).
// Requirements: Subtraction cannot overflow.
/* WARNING
	 * This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
// Returns the integer division of two unsigned integers, reverting with custom message on division by zero. The result is rounded towards zero.
// Requirements: The divisor cannot be zero.
/* WARNING
	 * This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
// Returns the remainder of dividing two unsigned integers. (unsigned integer modulo), reverting with custom message when dividing by zero.
// Requirements: The divisor cannot be zero.
/* WARNING
     * This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}