//SourceUnit: ERC20.sol

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMath.sol";
contract ERC20 is IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances; 
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 public coinPool;
    uint256 public endPool;
    uint256 private _totalSupply;
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function burn(uint256 amount) public returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 fee = amount.mul(5).div(100);
        coinPool = coinPool.add(fee.mul(2).div(5));
        endPool = endPool.add(fee.mul(1).div(5));
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount.sub(fee));
        emit Transfer(sender, recipient, amount);
    }
    function _give(address sender, address recipient, uint256 amount) internal {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

//SourceUnit: ERC20Detailed.sol

pragma solidity ^0.5.0;
import "./IERC20.sol";
contract ERC20Detailed is IERC20 {
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

//SourceUnit: IERC20.sol

pragma solidity ^0.5.0;

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


//SourceUnit: SafeMath.sol

pragma solidity ^0.5.0;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


//SourceUnit: Token.sol

pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./SafeMath.sol";
contract Token is ERC20, ERC20Detailed {
    using SafeMath for uint256;
    string _tokenName = "TronStar";
    string _symbol = "TS";
    address payable _owner;
    address payable _admin;
    uint256 _nonce = 0;
    uint256[5] play_trx = [1000, 2000, 3000, 4000, 5000];
    uint256[5] play_token = [5, 10, 15, 20, 25];
    mapping(address => User) public systemUserList;
    address[] addressList;
    uint256 systemUserCount;
    constructor() public ERC20Detailed(_tokenName, _symbol, 6) {
        _mint(msg.sender, 100000000 * 1e6);

        _owner = msg.sender; 
        _admin = msg.sender; 
    }
    struct User {
        address own;
        address shareParent;
        uint256 lev;
    }
    function play(uint256 _token_balance,address _share_address) public payable{
        burn(_token_balance);
        uint _trx_balance = msg.value;
        emit PlayEv(msg.sender,_share_address, _trx_balance,_token_balance, _nonce++); 
    }
    function _reg(
        address _own,
        address _share_address
    ) internal {
        if (systemUserCount == 0) {
            _share_address == address(0x0);
        } else {
            require(
                systemUserList[_share_address].own == _share_address,
                "share address error"
            );
        }
        systemUserList[_own].own = msg.sender;
        systemUserList[_own].shareParent = _share_address;
        systemUserCount++;
    }
    function withdraw_trx(address payable _own, uint256 _balance_sun) public isAdmin {
        require(address(this).balance >= _balance_sun);
        _own.transfer(_balance_sun);
        emit WithdrawEv(_own, _balance_sun,0, _nonce++);
    }
    function withdraw_token(address _own, uint256 _balance_sun) public isAdmin {
        require(balanceOf(address(this)) >= _balance_sun);
        transfer(_own, _balance_sun);
        emit WithdrawEv(_own, _balance_sun,1, _nonce++);
    }
    function app_withdraw(uint256 _balance_sun, uint8 _type) public {
        emit AppWithdrawTrxEv(msg.sender, _balance_sun, _type, _nonce++);
    }
    function open_duck_box() public {
        emit OpenDuckBoxEv(msg.sender, _nonce++);
    }
    function exchange_duck_box(uint8 _type) public {
        emit ExchangeDuckBoxEv(msg.sender,_type,_nonce++);
    }
    function recharge(uint256 _balance_sun) public {
        address _own = msg.sender;
        require(balanceOf(_own) >= _balance_sun, "amount error");
        transfer(address(this), _balance_sun);
        emit RechargeEv(_own, _balance_sun, _nonce++);
    }
    function burn_token(uint256 _balance_sun) public {
        burn(_balance_sun);
        emit BurnEv(msg.sender, _balance_sun, _nonce++);
    }
    function setEndPool() public isAdmin{
        uint256 oEndPool = endPool; 
        endPool = 0;
        emit PoolEv(oEndPool,1,_nonce++);
    }
    function setCoinPool() public isAdmin{
        uint256 oCoinPool = coinPool; 
        coinPool = 0;
        emit PoolEv(oCoinPool,0,_nonce++);
    }
    function giveBalance(address _to,uint256 _balance_sun,uint256 _id) public {
        transfer(_to, _balance_sun);
        emit GiveEv(_to,_balance_sun,_id,_nonce++);
    }
    function set_admin(address payable _own) public isOwn {
        _admin = _own;
    }
    function own_balance(address _own) public view returns (uint256) {
        return _own.balance;
    }
    function kill() public {
        selfdestruct(_owner);
    }
    modifier isOwn() {
        require(msg.sender == _owner);
        _;
    }
    modifier isAdmin() {
        require(msg.sender == _admin);
        _;
    }
    event PlayEv(address own,address _share_address, uint256 _trx_balance, uint256 _token_balance, uint256 _nonce);
    event WithdrawEv(address own, uint256 _balance, uint8 _type,uint256 _nonce);
    event AppWithdrawTrxEv(
        address own,
        uint256 _balance,
        uint8 _type,
        uint256 _nonce
    );
    event OpenDuckBoxEv(address own, uint256 _nonce);
    event ExchangeDuckBoxEv(address own, uint8 _type,uint256 _nonce);
    event RechargeEv(address own, uint256 _balance, uint256 _nonce);
    event BurnEv(address own, uint256 _balance, uint256 _nonce);
    event PoolEv(uint256 _balance,uint8 _type, uint256 _nonce);
    event GiveEv(address _to,uint256 _balance_sun,uint256 _id,uint256 _nonce);
}