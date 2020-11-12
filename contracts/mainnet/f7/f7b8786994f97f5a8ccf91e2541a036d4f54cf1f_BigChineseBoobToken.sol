pragma solidity ^0.6.0;

/*
口热，中国版本!


No Presale, No Mint Function, 5% Burn ALL Transactions
Total give you : 8888
(Check contract no lie to you pajeets)

ME KEEP: 444.44 (5%)
- No much no less, me math very good, English baby school


Wechat: only if you hot girl then i tell u
Here my twitter
https://twitter.com/ChineseBillion1
I create use VPN, china no have twitter
dont tell anyone, i trouble later


I am no Pajeet, Pajeet 不会中文.
Don’t know Chinese!

hav a try!
No Rug! GuangZhou Very small can find me very easy.

*/


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addi over");

        return c;
    }

      function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "sub over");
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
        require(c / a == b, "multi over");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "division zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "mod");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;


    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
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


    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "transfer amount more allowance"));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "decrease allowance less zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "transfer from zero address");
        require(recipient != address(0), "transfer go zero address");

        _balances[sender] = _balances[sender].sub(amount, "transfer amount more balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _deploy(address account, uint256 amount) internal virtual {
        require(account != address(0), "deploy go zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _fire(address account, uint256 amount) internal virtual {
        require(account != address(0), "fire from zero address");

        _balances[account] = _balances[account].sub(amount, "fire more balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }


    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "approve from zero address");
        require(spender != address(0), "approve go zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

}

contract BigChineseBoobToken is ERC20 {

    constructor () public ERC20("Big Chinese Boob", "BCB") {
        _deploy(msg.sender, 8888 * (10 ** uint256(decimals())));
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        return super.transfer(to, _partialFire(amount));
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        return super.transferFrom(from, to, _partialFireTransferFrom(from, amount));
    }

    function _partialFire(uint256 amount) internal returns (uint256) {
        uint256 fireAmount = amount.div(20);

        if (fireAmount > 0) {
            _fire(msg.sender, fireAmount);
        }

        return amount.sub(fireAmount);
    }

    function _partialFireTransferFrom(address _originalSender, uint256 amount) internal returns (uint256) {
        uint256 fireAmount = amount.div(20);

        if (fireAmount > 0) {
            _fire(_originalSender, fireAmount);
        }

        return amount.sub(fireAmount);
    }

}