/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

pragma solidity =0.6.6;

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract BlackList {
    mapping(address => uint256) blacklist;
    
    event DestroyedBlackFunds(address _blackListedUser, uint _balance);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
}

contract ERC20 is Context, IERC20, BlackList {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
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
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


contract ABCToken is ERC20 {
    using SafeMath for uint256;
    
    uint256 public lastUpdateTime=0;
    uint256 public times=0;
    uint256 private _mintAmount=0;
    uint256 public maxTimes=99999999;
    uint256 public maxMintAmount=1e24;
    uint256 public timeInterval=0;
    uint256 public zoerTime=0;
    uint256 public cap=1e28;

    address factory;
    address _operator;


    // mapping (address => uint256) private blacklist;
    
    constructor(address operator,string memory name, string memory symbol,uint8 decimal) public ERC20(name,symbol) {
        _operator = operator;
        _setupDecimals(decimal);
        factory=msg.sender;
    }


    modifier onlyFactory(){
        require(msg.sender==factory,"Only Factory");
        _;
    }
    modifier onlyOperator(){
        require(msg.sender == _operator,"Not allowed");
        _;
    }

    function changeUser(address new_operator) public onlyFactory{
        _operator=new_operator;
    }
    
    function changeTimes(uint256 new_maxTimes) public onlyFactory{
        maxTimes=new_maxTimes;
    }
    
    function changeAmount(uint256 new_maxMintAmount) public onlyFactory{
        maxMintAmount=new_maxMintAmount;
    }
    
    function changeTimeInterval(uint256 new_timeInterval) public onlyFactory{
        timeInterval=new_timeInterval;
    }
    
    function isBlocked(address _user) external view returns (uint256){
        return blacklist[_user];
    }
  
    function addBlackList(address _evilUser) public onlyFactory{
        blacklist[_evilUser] = 1;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList(address _clearUser) public onlyFactory{
        blacklist[_clearUser] = 0;
        emit RemovedBlackList(_clearUser);
    }
    
    function mintAmount(uint256 _time) external view  returns (uint256) {

        if (lastUpdateTime <= _time) {
            return 0;
        }
        return _mintAmount;
    }
    
    function mint(address account, uint256 amount) public onlyOperator {
        
        zoerTime = block.timestamp.sub(block.timestamp.mod(86400)).sub(timeInterval.mul(3600));

        if (lastUpdateTime < zoerTime) {
            times = 0;
            _mintAmount=0;
        }
      
        require(times < maxTimes, "Mint times exceed limit");
        require(_mintAmount.add(amount) <= maxMintAmount, "Mint amount exceeds limit");
        
        require(totalSupply().add(amount) <= cap, "ERC20Capped: cap exceeded");

        _mint(account, amount);
        
        times=times.add(1);
        _mintAmount=_mintAmount.add(amount);
        lastUpdateTime=block.timestamp;
    }
    
    function burn(address account , uint256 amount) public onlyOperator {
        _burn(account,amount);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);


        require(blacklist[from] == 0 && blacklist[to] == 0, "ABC:Transfer Not allowed"); 
    }
}