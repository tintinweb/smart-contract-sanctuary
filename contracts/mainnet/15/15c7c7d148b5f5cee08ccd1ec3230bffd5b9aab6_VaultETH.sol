pragma solidity ^0.5.15;

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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface WETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);
}

interface Controller {
    function withdraw(address, uint) external;
    function balanceOf(address) external view returns (uint);
    function earn(address, uint) external;
    function rewards() external view returns (address);
}

contract VaultETH {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IERC20 public token;
    IERC20 public YFToken; // YF合约地址

    uint public min = 9500;
    uint public constant max = 10000;

    uint public earnLowerlimit; // 池内空余资金到这个值就自动earn

    address public governance;
    address public controller;

    struct Player {
          uint256 stake;     // 质押总数
          uint256 payout;    // 支出
          uint256 total_out; // 已经领取的分红
    }
    mapping(address => Player) public player_; // (player => data) player data

    struct Global {
          uint256 total_stake;        // 总质押总数
          uint256 total_out;          // 总分红金额
          uint256 earnings_per_share; // 每股分红
    }
    mapping(uint256 => Global) public global_; // (global => data) global data
    mapping (address => uint256) public deposittime;
    uint256 constant internal magnitude = 10**40; // 10的40次方

    address constant public yf = address(0x96F9632b25f874769969ff91219fCCb6ceDf26D2);

    string public getName;

    constructor (address _token) public {
        token = IERC20(_token);
        getName = string(abi.encodePacked("yf:Vault:", ERC20Detailed(_token).name()));

        YFToken = IERC20(yf);
        governance = tx.origin;
        controller = 0xcC8d36211374a08fC61d74ed2E48e22b922C9D7C;
    }

    function balance() public view returns (uint) {
        return token.balanceOf(address(this))
               .add(Controller(controller).balanceOf(address(token)));
    }

    function setMin(uint _min) external {
        require(msg.sender == governance, "!governance");
        min = _min;
    }

    // 设置治理地址，必须验证原来治理地址的签名
    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    // 设置目标token
    function setToken(address _token) public {
        require(msg.sender == governance, "!governance");
        token = IERC20(_token);
    }

    // 设置控制器地址，必须验证治理地址的签名
    function setController(address _controller) public {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    function setEarnLowerlimit(uint256 _earnLowerlimit) public{
        require(msg.sender == governance, "!governance");
        earnLowerlimit = _earnLowerlimit;
    }

    // Custom logic in here for how much the vault allows to be borrowed
    // Sets minimum required on-hand to keep small withdrawals cheap
    function available() public view returns (uint) {
        return token.balanceOf(address(this)).mul(min).div(max);
    }

    // 抵押代币给Strategy合约进行理财，代币路径如下 vault->controller->strategy
    function earn() public {
        uint _bal = available(); // 获取最小需要转给机枪池进行获取收益的代币个数
        token.safeTransfer(controller, _bal); // 转账给控制合约
        Controller(controller).earn(address(token), _bal); // 抵押代币给Strategy合约进行理财
    }

    // 存款 可以追加存款
    function deposit(uint amount) external {
        // uint _before = token.balanceOf(address(this));
        // uint amount = msg.value;
        // WETH(address(token)).deposit.value(amount)();
        // uint _after = token.balanceOf(address(this));
        // amount = _after.sub(_before); // Additional check for deflationary tokens

        WETH(address(token)).deposit.value(amount)(); //Convert ETH into the WETH
        // 增加该用户的存款总数
        player_[msg.sender].stake = player_[msg.sender].stake.add(amount);
        // 如果每股分红为0
        if (global_[0].earnings_per_share != 0) {
            player_[msg.sender].payout = player_[msg.sender].payout.add(
                global_[0].earnings_per_share.mul(amount).sub(1).div(magnitude).add(1) // (((earnings_per_share*amount)-1)/magnitude)+1
            );
        }
        // 增加全局已抵押的总量
        global_[0].total_stake = global_[0].total_stake.add(amount);
        // 如果当前池子合约中已经抵押的数量大于自动赚取收益的值时，自动将合约中的代币去第三方平台抵押
        if (token.balanceOf(address(this)) > earnLowerlimit){
            earn();
        }
        // 更新用户抵押时间
        deposittime[msg.sender] = now;
    }

    // No rebalance implementation for lower fees and faster swaps
    // 取款
    function withdraw(uint amount) external {
        claim(); // 首先获取当前未领取的收益
        require(amount <= player_[msg.sender].stake, "!balance");
        uint r = amount;

        // Check balance
        uint b = token.balanceOf(address(this));
        if (b < r) { // 如果vault合约中代币余额小于用户取款的余额，则需要去Strategy合约取款获得对应的代币
            uint _withdraw = r.sub(b);
            Controller(controller).withdraw(address(token), _withdraw); // 取款
            uint _after = token.balanceOf(address(this));
            uint _diff = _after.sub(b);
            if (_diff < _withdraw) { // 策略器有可能会返回的代币变多，所以需要更新vault合约中的余额
                r = b.add(_diff);
            }
        }
        // 更新用户的已提取余额并且更新全局的每股收益
        player_[msg.sender].payout = player_[msg.sender].payout.sub(
              global_[0].earnings_per_share.mul(amount).div(magnitude)
        );
        // 更新全局存款量和用户存款量
        player_[msg.sender].stake = player_[msg.sender].stake.sub(amount);
        global_[0].total_stake = global_[0].total_stake.sub(amount);

        // 转账给用户取款的代币
        WETH(address(token)).withdraw(r);
        address(msg.sender).transfer(r);
    }

    // Strategy.harvest 触发分红（）
    function make_profit(uint256 amount) public {
        require(amount > 0, "not 0");
        YFToken.safeTransferFrom(msg.sender, address(this), amount); // 挖矿收益存入当前合约（已扣除10%的手续费，90%的利润存进来）
        global_[0].earnings_per_share = global_[0].earnings_per_share.add(
            amount.mul(magnitude).div(global_[0].total_stake)
        );
        // 增加总分红金额
        global_[0].total_out = global_[0].total_out.add(amount);
    }

    // 用户可领取的分红
    function cal_out(address user) public view returns (uint256) {
        uint256 _cal = global_[0].earnings_per_share.mul(player_[user].stake).div(magnitude);
        if (_cal < player_[user].payout) {
            return 0;
        } else {
            return _cal.sub(player_[user].payout);
        }
    }

    // 某个用户在路上的分红（也就是分红还没有从挖矿合约领取.只能看到，无法领取，等harvest触发后就可以领取了）
    function cal_out_pending(uint256 _pendingBalance,address user) public view returns (uint256) {
        uint256 _earnings_per_share = global_[0].earnings_per_share.add(
            _pendingBalance.mul(magnitude).div(global_[0].total_stake)
        );
  
        uint256 _cal = _earnings_per_share.mul(player_[user].stake).div(magnitude);
        _cal = _cal.sub(cal_out(user));
        if (_cal < player_[user].payout) {
            return 0;
        } else {
            return _cal.sub(player_[user].payout);
        }
    }

    // 用户领取分红
    function claim() public {
        uint256 out = cal_out(msg.sender);
        player_[msg.sender].payout = global_[0].earnings_per_share.mul(player_[msg.sender].stake).div(magnitude);
        player_[msg.sender].total_out = player_[msg.sender].total_out.add(out);

        if (out > 0) {
            uint256 _depositTime = now - deposittime[msg.sender];
            if (_depositTime < 1 days) { // deposit in 24h
                uint256 actually_out = _depositTime.mul(out).mul(1e18).div(1 days).div(1e18);
                uint256 to_team = out.sub(actually_out);
                YFToken.safeTransfer(Controller(controller).rewards(), to_team);
                out = actually_out;
            }
            YFToken.safeTransfer(msg.sender, out);
        }
    }
}