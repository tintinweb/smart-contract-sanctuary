//SourceUnit: TRSToken.sol.sol

pragma solidity 0.5.12;

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

contract Governance {

    address public governance;

    constructor() public {
        governance = tx.origin;
    }

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == governance, "not governance");
        _;
    }

    function setGovernance(address _governance)  public  onlyGovernance
    {
        require(_governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(governance, _governance);
        governance = _governance;
    }

}

contract TRSToken is Governance, ERC20Detailed {

    using SafeMath for uint256;
    event eveSetRate(uint256 burn_rate, uint256 reward_rate);
    event eveRewardPool(address rewardPool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    mapping (address => bool) public _minters;
    uint256 internal _totalSupply;
    mapping(address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;
    uint256 public  _maxSupply = 0;
    bool public _openTransfer = true;
    uint256 public constant _maxGovernValueRate = 2000;
    uint256 public constant _minGovernValueRate = 0;
    uint256 public constant _rateBase = 10000; 
    uint256 public  _burnRate = 250;       
    uint256 public  _rewardRate = 250;   
    uint256 public _totalBurnToken = 0;
    uint256 public _totalRewardToken = 0;
    address public _rewardPool = 0x6666666666666666666666666666666666666666;
    address public _burnPool = 0x6666666666666666666666666666666666666666;
    constructor () public ERC20Detailed("trs.so", "TRS", 18) {
        _maxSupply = 10000000 * (10**18);
    }

    function approve(address spender, uint256 amount) external 
    returns (bool) 
    {
        require(msg.sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) external view 
    returns (uint256) 
    {
        return _allowances[owner][spender];
    }

    function balanceOf(address owner) external  view 
    returns (uint256) 
    {
        return _balances[owner];
    }

    function totalSupply() external view 
    returns (uint256) 
    {
        return _totalSupply;
    }

    function mint(address account, uint256 amount) external 
    {
        require(account != address(0), "ERC20: mint to the zero address");
        require(_minters[msg.sender], "!minter");
        uint256 curMintSupply = _totalSupply.add(_totalBurnToken);
        uint256 newMintSupply = curMintSupply.add(amount);
        require( newMintSupply <= _maxSupply,"supply is max!");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Mint(address(0), account, amount);
        emit Transfer(address(0), account, amount);
    }

    function addMinter(address _minter) public onlyGovernance 
    {
        _minters[_minter] = true;
    }
    
    function removeMinter(address _minter) public onlyGovernance 
    {
        _minters[_minter] = false;
    }

    function() external payable {
        revert();
    }

    function setRate(uint256 burn_rate, uint256 reward_rate) public 
        onlyGovernance 
    {
        require(_maxGovernValueRate >= burn_rate && burn_rate >= _minGovernValueRate,"invalid burn rate");
        require(_maxGovernValueRate >= reward_rate && reward_rate >= _minGovernValueRate,"invalid reward rate");
        _burnRate = burn_rate;
        _rewardRate = reward_rate;
        emit eveSetRate(burn_rate, reward_rate);
    }

    function setRewardPool(address rewardPool) public 
        onlyGovernance 
    {
        require(rewardPool != address(0x0));
        _rewardPool = rewardPool;
        emit eveRewardPool(_rewardPool);
    }

   function transfer(address to, uint256 value) external 
   returns (bool)  
   {
        return _transfer(msg.sender,to,value);
    }

    function transferFrom(address from, address to, uint256 value) external 
    returns (bool) 
    {
        uint256 allow = _allowances[from][msg.sender];
        _allowances[from][msg.sender] = allow.sub(value);
        return _transfer(from,to,value);
    }

    function _transfer(address from, address to, uint256 value) internal 
    returns (bool) 
    {
        require(_openTransfer || from == governance, "transfer closed");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 sendAmount = value;
        uint256 burnFee = (value.mul(_burnRate)).div(_rateBase);
        if (burnFee > 0) {
            _balances[_burnPool] = _balances[_burnPool].add(burnFee);
            _totalSupply = _totalSupply.sub(burnFee);
            sendAmount = sendAmount.sub(burnFee);
            _totalBurnToken = _totalBurnToken.add(burnFee);
            emit Transfer(from, _burnPool, burnFee);
        }
        uint256 rewardFee = (value.mul(_rewardRate)).div(_rateBase);
        if (rewardFee > 0) {
            _balances[_rewardPool] = _balances[_rewardPool].add(rewardFee);
            sendAmount = sendAmount.sub(rewardFee);
            _totalRewardToken = _totalRewardToken.add(rewardFee);
            emit Transfer(from, _rewardPool, rewardFee);
        }
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(sendAmount);
        emit Transfer(from, to, sendAmount);
        return true;
    }
}