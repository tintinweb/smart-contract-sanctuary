/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

// Version 1.22
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  /**
   * @dev remove an account's access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}


library SafeMath 
{

    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {

        if (a == 0) 
        {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library SafeMathInt 
{
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);


    function mul(int256 a, int256 b) internal pure returns (int256) 
    {
        int256 c = a * b;
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) 
    {
        require(b != -1 || a != MIN_INT256);
        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) 
    {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) 
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) 
    {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) 
    {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint 
{
  function toInt256Safe(uint256 a) internal pure returns (int256) 
  {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

abstract contract Context 
{
    function _msgSender() internal view virtual returns (address) 
    {
        return msg.sender;
    }

//    function _msgData() internal view virtual returns (bytes calldata) 
//    {
//        return msg.data;
//    }
}


contract Ownable is Context 
{
    using SafeMath for uint256;
    using Roles for Roles.Role;
    
    Roles.Role internal CEO;
    Roles.Role internal coreTeam;
    
    bool public ceoSign = false;
    bool public coreMemberSign = false;
    
    modifier onlyCEOandSign(){
        require(CEO.has(msg.sender) == true, 'Must have CEO role');
        require (coreMemberSign, "Must have Ceo and core member sign");
        ceoSign = false;
        coreMemberSign = false;
        _;
    }
    
    modifier CEOandCoreTeamAndSign(){
        require(coreTeam.has(msg.sender) == true || CEO.has(msg.sender) == true, 'Must have CEO or coreTeam role');
        require (ceoSign && coreMemberSign, "Must have Ceo and core member sign");
        ceoSign = false;
        coreMemberSign = false;
        _; 
    }
    
    modifier CEOandCoreTeam(){
        require(coreTeam.has(msg.sender) == true || CEO.has(msg.sender) == true, 'Must have CEO or coreTeam role');
        _; 
    }
    
    modifier onlyCEO(){
        require(CEO.has(msg.sender) == true, 'Must have CEO role');
        _;
    }
    
    modifier onlyCoreTeam(){
        require(coreTeam.has(msg.sender) == true, 'Must have coreTeam role');
        _; 
    }
    
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    
     // Inicializa el contrato estableciendo al implementador como propietario inicial.
    
    constructor() public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }


     // Devuelve la dirección del propietario actual.

    function owner() public view virtual returns (address) 
    {
        return _owner;
    }

    // Permite dejar el contrato sin dueño, lo renuncia en el caso que se decida desactivar el token.

    function renounceOwnership() public virtual onlyCEO() 
    {
        emit OwnershipTransferred(_owner, address(0));
        CEO.remove(_owner);
        _owner = address(0);
        
    }

    
    // Transfiere el contrato a una nueva persona, en el caso de ceder derechos a un tercero
    
    function transferOwnership(address newOwner) public virtual onlyCEO()
    {
        require(
            newOwner != address(0),
            "SGC: El nuevo propietario es la direccion 0."
        );
        emit OwnershipTransferred(_owner, newOwner);
        CEO.remove(_owner);
        CEO.add(newOwner);
        _owner = newOwner;
    }
}

library IterableMapping 
{
    struct Map 
    {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) 
    {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) 
    {
        if(!map.inserted[key]) 
        {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) 
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) 
    {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public 
    {
        if (map.inserted[key]) 
        {
            map.values[key] = val;
        } 
        else 
        {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public 
    {
        if (!map.inserted[key]) 
        {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];
        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];
        map.indexOf[lastKey] = index;
        delete map.indexOf[key];
        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

interface IUniswapV2Pair 
{
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

interface IUniswapV2Factory 
{
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 
{
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 
{
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IERC20 
{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 
{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata 
{
    using SafeMath for uint256;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    
    string internal _name; 
    string internal _symbol;
    uint8 internal _decimals; 
    uint256 internal _totalSupply;  

    constructor(string memory name_, string memory symbol_) public 
    {
        _name = name_;
        _symbol = symbol_;
    }
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) 
    {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) 
    {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) 
    {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) 
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) 
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) 
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) 
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) 
    {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) 
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual 
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual 
    {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual 
    {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual 
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface DividendPayingTokenInterface 
{

  function dividendOf(address _owner) external view returns(uint256);
  function distributeDividends() external payable;
  function withdrawDividend() external;

  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}

interface DividendPayingTokenOptionalInterface 
{
  function withdrawableDividendOf(address _owner) external view returns(uint256);
  function withdrawnDividendOf(address _owner) external view returns(uint256);
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}


contract DividendPayingToken is ERC20, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface 
{
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  uint256 constant internal magnitude = 2**128;
  uint256 internal magnifiedDividendPerShare;

  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor(string memory _name, string memory _symbol) public ERC20(_name, _symbol) 
  {

  }

  receive() external payable 
  {
    distributeDividends();
  }

  function distributeDividends() public override payable {
    require(totalSupply() > 0);

    if (msg.value > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (msg.value).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, msg.value);

      totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
    }
  }

  function withdrawDividend() public virtual override 
  {
    _withdrawDividendOfUser(msg.sender);
  }

  function _withdrawDividendOfUser(address payable user) internal returns (uint256) 
  {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) 
    {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      (bool success,) = user.call{value: _withdrawableDividend, gas: 3000}("");

      if(!success) 
      {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }

  function dividendOf(address _owner) public view override returns(uint256) 
  {
    return withdrawableDividendOf(_owner);
  }

  function withdrawableDividendOf(address _owner) public view override returns(uint256) 
  {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  function withdrawnDividendOf(address _owner) public view override returns(uint256) 
  {
    return withdrawnDividends[_owner];
  }

  function accumulativeDividendOf(address _owner) public view override returns(uint256) 
  {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }


  function _transfer(address from, address to, uint256 value) internal virtual override 
  {
    require(false);
    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }

  function _mint(address account, uint256 value) internal override 
  {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _burn(address account, uint256 value) internal override 
  {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal 
  {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) 
    {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } 
    else 
    if(newBalance < currentBalance) 
    {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}

// ----------------------------- Codigo de contrato  ----------------------------- 

contract SGCToken is ERC20, Ownable 
{
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;    
    
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address mcaddress = 0xE4E50e91A6E6e7c161277e27d6D476579C586920;
    address public swapContractAddr;

    DividendTracker public dividendTracker;
    RewardStaker public rewardStaker;
    
    // to change
    uint256 public maxSellTransactionAmount = 5 * 10 ** 12 * (10**9);
    uint256 public maxBuyTransactionAmount = 1 * 10 ** 15 * (10**9);
    //
    
    uint256 public swapTokensAtAmount = 2 * 10 ** 8 * (10**9);

    uint256 public BNBRewardsFee = 2;
    uint256 public liquidityFee = 4;
    uint256 public marketingFee = 2;
    uint256 public gameFee = 2;
    uint256 public burnFee = 1;
    
    uint256 public BNBRewardsFeeOnSell = 3;
    uint256 public liquidityFeeOnSell = 5;
    uint256 public marketingFeeOnSell = 3;
    uint256 public gameFeeOnSell = 3;
    uint256 public burnFeeOnSell = 1;
    
    bool public _bFeePaused = false;
    
    uint256 public liquidityAcummulated;
    uint256 public distributionAcummulated;
    
    //bool public ceoSign = false;
    //bool public coreMemberSign = false;
    mapping(address => bool) public _isCoreMember;

    mapping(address => uint256) public _sellLockTimeRefresh;
    mapping(address => uint256) public _sellLockFreqency;

    uint256 public sellFeeIncreaseFactor = 120; 
    uint256 public gasForProcessing = 300000;
    uint256 public tradingEnabledTimestamp;
    uint256 public deployTimeStamp;
    
    mapping(address => uint256) public _stakingStartTimeForAddress;
    mapping(address => uint256) public _recievedRewardForAddress;
    IterableMapping.Map private _holderMap;
    uint256 public _loopIndexRewardStakerCheck;

    mapping (address => bool) private _isExcludedFromFees;
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify( uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SendDividends( uint256 tokensSwapped, uint256 amount);
    event ProcessedDividendTracker(uint256 iterations, uint256 claims, uint256 lastProcessedIndex, bool indexed automatic, uint256 gas, address indexed processor);

    /* ############################################################### */
    /* ############################################################### */
                            /* to change */
                            
    address public marketingWallet = 0x188Ed70ed3928d26bB193413c0Fc242de7e18e90; 
    address public gameWallet = 0xF1020cB7716e620296De96bF35DF4320c5d62038; 
    
    // Miembros del Core team
    address CEOAddress = 0xCd4bA9C5Dc8875d4A2D318A081BBe50553A902d1;
    address coreTeamAddress1 = 0x10A04121Bc5a183C71b9FD4dc024422de9d09BfE; 
    address coreTeamAddress2 = 0x34931A227553a010FfDcd6baB7a75EBd5E9408d6; 
    address coreTeamAddress3 = 0x0d5925F9fd1A9e797Cd7F2fdF6B030EAa89F1260; 
    address coreTeamAddress4 = 0x18E6002108cf86EBB4b83De85e87Aa9eE3911dc6;

    /* ############################################################### */
    /* ############################################################### */

    constructor() public ERC20("My Super Token", "MST") 
    {
        _decimals = 9; 
        _totalSupply = 2 * 10 ** 15 * 10 ** 9; 
        
        CEO.add(msg.sender);
        coreTeam.add(coreTeamAddress1);
        coreTeam.add(coreTeamAddress2);
        coreTeam.add(coreTeamAddress3);
        coreTeam.add(coreTeamAddress4);
        
    	dividendTracker = new DividendTracker();
    	rewardStaker = new RewardStaker();
    	
//    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Main net !!!!!!!!!!!
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // Test net !!!!!!!!!!!
    	
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(address(_uniswapV2Pair));

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(mcaddress, true);
        excludeFromFees(CEOAddress, true);
        excludeFromFees(coreTeamAddress1, true);
        excludeFromFees(coreTeamAddress2, true);
        excludeFromFees(coreTeamAddress3, true);
        excludeFromFees(coreTeamAddress4, true);
        
        deployTimeStamp = block.timestamp;
        
        _balances[CEOAddress] = _totalSupply/100;
        _balances[coreTeamAddress1] = _totalSupply/100;
        _balances[coreTeamAddress2] = _totalSupply/100;
        _balances[coreTeamAddress3] = _totalSupply/100;
        _balances[coreTeamAddress4] = _totalSupply/100;
        _balances[msg.sender] += _totalSupply - (_totalSupply/100)*5; // Mandamos el valor de los balances al supply
        
        emit Transfer(address(0), CEOAddress, _balances[CEOAddress]); // Transferencia sin valores
        emit Transfer(address(0), coreTeamAddress1, _balances[coreTeamAddress1]); // Transferencia sin valores
        emit Transfer(address(0), coreTeamAddress2, _balances[coreTeamAddress2]); // Transferencia sin valores
        emit Transfer(address(0), coreTeamAddress3, _balances[coreTeamAddress3]); // Transferencia sin valores
        emit Transfer(address(0), coreTeamAddress4, _balances[coreTeamAddress4]); // Transferencia sin valores
        emit Transfer(address(0), _msgSender(), _balances[msg.sender]); // Transferencia sin valores
        
        //_mint(owner(), 2 * 10 ** 15 * (10**9)); 
    }

    //receive() external payable 
    //{
  	//}
  	
  	// Firma como CEO
    function signAsCEO() public virtual onlyCEO() {
        ceoSign = true;
    }
    
    // Firma como Miembro del CoreTeam
    function signAsCoreMember() public virtual onlyCoreTeam() {
        coreMemberSign = true;
    }

    function excludeFromFees(address account, bool excluded) public CEOandCoreTeam() 
    {
        require(_isExcludedFromFees[account] != excluded, " Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function updateGasForProcessing(uint256 newValue) public onlyCEOandSign() 
    {
        require(newValue >= 200000 && newValue <= 500000, " gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, " Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyCEOandSign() 
    {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) 
    {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) 
    {
        return dividendTracker.totalDividendsDistributed();
    }
    
    function getHoldTimeFromStakingStart(address addr) external view returns (int256) 
    {
        if (_stakingStartTimeForAddress[addr] == 0)
        {
            return 0;
        } 
        else 
        {
            return (int256)(block.timestamp - _stakingStartTimeForAddress[addr]) / (1 days);
        }
    }

    function isExcludedFromFees(address account) public view returns(bool) 
    {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) 
    {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) 
	{
		return dividendTracker.balanceOf(account);
	}

    function getAccountDividendsInfo(address account) external view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) 
    {
        return dividendTracker.getAccount(account);
    }

	function getAccountDividendsInfoAtIndex(uint256 index) external view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) 
    {
    	return dividendTracker.getAccountAtIndex(index);
    }

	function processDividendTracker(uint256 gas) external 
	{
	    require(gasleft() >= gas, "Out of gas, please increase gas limit and retry!");
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process{gas:gas}();
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external 
    {
		dividendTracker.processAccount(msg.sender, false);
    }
    
    function setMaxSellAmount(uint256 amount) public CEOandCoreTeamAndSign()
    {
        maxSellTransactionAmount = amount * 10 ** 9;
    }
    
    function setMaxBuyAmount(uint256 amount) public CEOandCoreTeamAndSign()
    {
        maxBuyTransactionAmount = amount * 10 ** 9;
    }
    
    function setSwapContractAddress (address addr) public CEOandCoreTeamAndSign()
    {
        swapContractAddr = addr;
        _isExcludedFromFees[addr] = true;
        dividendTracker.excludeFromDividends(addr);
    }
    
    function setBuyFee(uint256 _BNBRewardsFee, uint256 _liquidityFee, uint256 _marketingFee, uint256 _gameFee, uint256 _burnFee) public onlyCEOandSign() 
    {
        BNBRewardsFee = _BNBRewardsFee;
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        gameFee = _gameFee;
        burnFee = _burnFee;
    }
    
    function setSellFee(uint256 _BNBRewardsFeeOnSell, uint256 _liquidityFeeOnSell, uint256 _marketingFeeOnSell, uint256 _gameFeeOnSell, uint256 _burnFeeOnSell) public onlyCEOandSign() 
    {
        BNBRewardsFeeOnSell = _BNBRewardsFeeOnSell;
        liquidityFeeOnSell = _liquidityFeeOnSell;
        marketingFeeOnSell = _marketingFeeOnSell;
        gameFeeOnSell = _gameFeeOnSell;
        burnFeeOnSell = _burnFeeOnSell;
    }
    
    function deposit() public payable 
    {
        address(rewardStaker).call{value: msg.value}("");
    }
    
    function withdraw (address reciever) public onlyCEOandSign() 
    {
        rewardStaker.withdraw(reciever);
    }

    function getLastProcessedIndex() external view returns(uint256) 
    {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) 
    {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function getTradingIsEnabled() public view returns (bool) 
    {
        return tradingEnabledTimestamp != 0;
    }
    
    function pauseAllFee() external onlyCEOandSign() 
    {
        _bFeePaused = true;
    }
    
    function restoreAllFee() external onlyCEOandSign() 
    {
        _bFeePaused = false;
    }
    
    function getStakerCount() public view returns (uint256) 
    {
        return _holderMap.size();
    }
    
    function getStakerAddress(uint256 index) public view returns (address) 
    {
        return _holderMap.keys[index];
    } 

    function _transfer(address from, address to, uint256 amount) internal override 
    {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if(amount == 0) 
        {
            super._transfer(from, to, 0);
            return;
        }
        
        if (swapping)
        { 
            super._transfer(from, to, amount); 
            return; 
        }
        
        if (_bFeePaused)
        {
            super._transfer(from, to, amount); 
            return;  
        }

        bool tradingIsEnabled = getTradingIsEnabled();
        
        if (from == gameWallet || from == marketingWallet)
        {
            require (ceoSign && coreMemberSign, "Must have Ceo and core member sign to spend from Dev wallet!");
            ceoSign = false;
            coreMemberSign = false;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(tradingIsEnabled && canSwap && !swapping && from != uniswapV2Pair && from != owner() && to != owner()) 
        {
            swapping = true;
            swapAndLiquify(liquidityAcummulated);
            liquidityAcummulated = 0;
            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);
            distributionAcummulated = 0;
            swapping = false;
        }

        bool takeFee = !swapping;

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) 
        {
            takeFee = false;
        }

        if(takeFee) 
        {
            uint256 liquidityAmount;
            uint256 marketingAmount;
        	uint256 distributionAmount;
        	uint256 gameAmount;
        	uint256 burnAmount;
            if(to == uniswapV2Pair && tradingIsEnabled && !swapping) 
            {
                uint256 _amount = amount;
                if (deployTimeStamp + 30 days > block.timestamp)
                {
                    liquidityAmount = _amount.div(100).mul(6);
                    marketingAmount = _amount.div(100).mul(17);
                    distributionAmount = _amount.div(100).mul(4);
                    gameAmount = _amount.div(100).mul(5);
                    burnAmount = _amount.div(100).mul(1);
                } 
                else 
                if (deployTimeStamp + 30 days < block.timestamp && deployTimeStamp + 60 days > block.timestamp)
                {
                    liquidityAmount = _amount.div(100).mul(6);
                    marketingAmount = _amount.div(100).mul(17);
                    distributionAmount = _amount.div(100).mul(4);
                    gameAmount = _amount.div(100).mul(5);
                    burnAmount = _amount.div(100).mul(1);
                } 
                else 
                {
                    liquidityAmount = _amount.div(100).mul(liquidityFeeOnSell);
                    marketingAmount = _amount.div(100).mul(marketingFeeOnSell);
                    distributionAmount = _amount.div(100).mul(BNBRewardsFeeOnSell);
                    gameAmount = _amount.div(100).mul(gameFeeOnSell);
                    burnAmount = _amount.div(100).mul(burnFeeOnSell);
                }
            } 
            else if(from == uniswapV2Pair && tradingIsEnabled && !swapping)
            {
                liquidityAmount = amount.div(100).mul(liquidityFee);
                marketingAmount = amount.div(100).mul(marketingFee);
                distributionAmount = amount.div(100).mul(BNBRewardsFee);
                gameAmount = amount.div(100).mul(gameFee);
                burnAmount = amount.div(100).mul(burnFee);
            } 
            else {
                if (deployTimeStamp + 60 days > block.timestamp)
                {
                    liquidityAmount = amount.div(100).mul(5);
                    marketingAmount = amount.div(100).mul(17);
                    distributionAmount = amount.div(100).mul(3);
                    gameAmount = amount.div(100).mul(5);
                    burnAmount = amount.div(100).mul(0);
                }
            }
            
        	amount = amount.sub(liquidityAmount + marketingAmount + distributionAmount + gameAmount + burnAmount);
            super._transfer(from, address(this), liquidityAmount + distributionAmount);
            super._transfer(from, marketingWallet, marketingAmount);
            super._transfer(from, gameWallet, gameAmount);
            super._transfer(from, DEAD, burnAmount);
            liquidityAcummulated += liquidityAmount;
            distributionAcummulated += distributionAmount;
        }
                
        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) 
        {
	    	uint256 gas = gasForProcessing;
            require(gasleft() >= gas, "Out of gas, please increase gas limit and retry!");
	    	try dividendTracker.process{gas:gas}() returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) 
	    	{
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	} 
	    	catch {}
        }
        
        if (to != address(this) && to != DEAD && to != address(0) && to != uniswapV2Pair && to != address(uniswapV2Router) && to != swapContractAddr)
        {
            if (_holderMap.getIndexOfKey(to) == -1)
            {
                _holderMap.set(to, 0);
                _stakingStartTimeForAddress[to] = block.timestamp;
                _recievedRewardForAddress[to] = 0;
            }
        }
        
        if (_holderMap.getIndexOfKey(from) != -1)
        {
            _stakingStartTimeForAddress[from] = block.timestamp + 360 days;
            _recievedRewardForAddress[from] = 0;
        }
        
        if (_holderMap.size() > 0 && tradingIsEnabled)
        {
            uint256 gas = gasForProcessing;
            require(gasleft() >= gas, "Out of gas, please increase gas limit and retry!");
            uint256 indexLoop = 0;
            while(gasleft() > 100000)
            {
                if (_stakingStartTimeForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] + 90 days < block.timestamp && balanceOf(_holderMap.keys[_loopIndexRewardStakerCheck]) > 0)
                {
                    if (_recievedRewardForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] < 3)
                    {
                        if(rewardStaker.reward(_holderMap.keys[_loopIndexRewardStakerCheck], _getBNBbalanceFromToken(balanceOf(_holderMap.keys[_loopIndexRewardStakerCheck]).div(1000).mul(5))))
                        {
                            _recievedRewardForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] = 3;
                        }
                    }
                    if (_stakingStartTimeForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] + 180 days < block.timestamp)
                    {
                        if (_recievedRewardForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] < 6)
                        {
                            if(rewardStaker.reward(_holderMap.keys[_loopIndexRewardStakerCheck], _getBNBbalanceFromToken(balanceOf(_holderMap.keys[_loopIndexRewardStakerCheck]).div(1000).mul(15))))
                            {
                                _recievedRewardForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] = 6;
                            }
                        }
                        if (_stakingStartTimeForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] + 270 days < block.timestamp)
                        {
                            if (_recievedRewardForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] < 9)
                            {
                                if(rewardStaker.reward(_holderMap.keys[_loopIndexRewardStakerCheck], _getBNBbalanceFromToken(balanceOf(_holderMap.keys[_loopIndexRewardStakerCheck]).div(1000).mul(20))))
                                {
                                    _recievedRewardForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] = 9;
                                }
                            }
                            if (_stakingStartTimeForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] + 360 days < block.timestamp)
                            {
                                if (_recievedRewardForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] < 12)
                                {
                                    if(rewardStaker.reward(_holderMap.keys[_loopIndexRewardStakerCheck], _getBNBbalanceFromToken(balanceOf(_holderMap.keys[_loopIndexRewardStakerCheck]).div(1000).mul(30))))
                                    {
                                        _stakingStartTimeForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] = block.timestamp;
                                        _recievedRewardForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] = 0;
                                    }
                                }
                            }
                        }
                    }
                }
                _loopIndexRewardStakerCheck ++;
                indexLoop ++;
                if (_loopIndexRewardStakerCheck >= _holderMap.size()){ _loopIndexRewardStakerCheck = 0; }
                if (indexLoop >= _holderMap.size()) { break; }
            }
        }
        
    }
    
    function _getBNBbalanceFromToken(uint256 amount) private view returns(uint256) 
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        uint[] memory amounts = uniswapV2Router.getAmountsOut(amount, path);
        return amounts[1];
    }

    function swapAndLiquify(uint256 tokens) private 
    {

        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half); 
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private 
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private 
    {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, owner(), block.timestamp );
    }

    function swapAndSendDividends(uint256 tokens) private 
    {
        swapTokensForEth(tokens);
        uint256 dividends = address(this).balance;
        (bool success,) = address(dividendTracker).call{value: dividends}("");

        if(success) 
        {
   	 		emit SendDividends(tokens, dividends);
        }
    }
}

contract DividendTracker is DividendPayingToken, Ownable 
{
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;
    mapping (address => bool) public excludedFromDividends;
    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event gasLog(uint256 gas);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public DividendPayingToken("_Dividend_Tracker", "_Dividend_Tracker") 
    {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 10000 * (10**9);
    }

    function _transfer(address, address, uint256) internal override 
    {
        require(false, "_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override 
    {
        require(false, "_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main TIKI contract.");
    }

    function excludeFromDividends(address account) external onlyCEOandSign() 
    {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;
    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);
    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyCEOandSign() 
    {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) 
    {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) 
    {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account) public view returns (address account, int256 index, int256 iterationsUntilProcessed, uint256 withdrawableDividends, uint256 totalDividends, uint256 lastClaimTime, uint256 nextClaimTime, uint256 secondsUntilAutoClaimAvailable) 
    {
        account = _account;
        index = tokenHoldersMap.getIndexOfKey(account);
        iterationsUntilProcessed = -1;

        if(index >= 0) 
        {
            if(uint256(index) > lastProcessedIndex) 
            {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else 
            {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ? tokenHoldersMap.keys.length.sub(lastProcessedIndex) : 0;
                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
        lastClaimTime = lastClaimTimes[account];
        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
    }

    function getAccountAtIndex(uint256 index) public view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) 
    {
    	if(index >= tokenHoldersMap.size()) 
    	{
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) 
    {
    	if(lastClaimTime > block.timestamp)  
    	{
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyCEOandSign() 
    {
    	if(excludedFromDividends[account]) 
    	{
    		return;
    	}

    	if(newBalance >= minimumTokenBalanceForDividends) 
    	{
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else 
    	{
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}

    	processAccount(account, true);
    }
    
    

    function process() public returns (uint256, uint256, uint256) 
    {
        emit gasLog(gasleft());
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    	if(numberOfTokenHolders == 0) 
    	{
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = lastProcessedIndex;
    	uint256 iterations = 0;
    	uint256 claims = 0;

    while(gasleft() > 100000 && iterations < numberOfTokenHolders) 
    {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) 
    		{
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(canAutoClaim(lastClaimTimes[account]) && withdrawableDividendOf(account) > 0) 
    		{
    			if(processAccount(payable(account), true)) 
    			{
    				claims++;
    			}
    		}

    		iterations++;
    	}

    	lastProcessedIndex = _lastProcessedIndex;
        emit gasLog(gasleft());
    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyCEOandSign() returns (bool) 
    {
        uint256 amount = _withdrawDividendOfUser(account);

    	if(amount > 0) 
    	{
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }
}

contract RewardStaker is Ownable 
{
    event depositBNB (uint256 amount);
    event rewardBNB (address reciever, uint256 amount);
    event withdrawBNB (address reciever, uint256 amount);
    receive() external payable {deposit();}
    
    function deposit() public payable 
    {
        emit depositBNB(msg.value);
    }
    
    function withdraw (address reciever) public onlyCEOandSign() 
    {
        emit withdrawBNB(reciever, address(this).balance);
        reciever.call{value: address(this).balance, gas: 3000}("");
    }
    
    function reward(address reciever, uint256 amount) public onlyCEOandSign() returns (bool) 
    {
        if (address(this).balance > amount)
        {
            (bool success, ) = reciever.call{value: amount, gas: 3000}("");
            emit rewardBNB(reciever, amount);
            return success;
        } 
	    else 
	    {
            return false;
        }
    }
}