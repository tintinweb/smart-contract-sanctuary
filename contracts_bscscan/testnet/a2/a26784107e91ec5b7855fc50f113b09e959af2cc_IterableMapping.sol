/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

/*

          ██          ██████████     ██████████    ███████████████
         ██ ██        ██             ██        ██         ██
        ██   ██       ██               ██                 ██
       ██     ██      ██████████         ██               ██           
      ████████████    ██                   ██             ██
     ██         ██    ██           ██        ██           ██
    ██           ██   ██████████     ██████████           ██       ██     ██     ██



Bringing developers, Investors, Business Partners and
Interest groups together, and Promoting trust,
Knowledge, Unity, and Enhanced
Relationship between Bridged
& De-Fi Communities.


The Aestherium Ecosystem Residents on 3 unwavering Foundations; Trust-Safety, 
Utility, and Sustainability, and will be powered by 6 major platforms which will 
also serve as a bridge to speed up blockchain technology adoption by reforming 
online stores and Businesses.

https://aestherium.net

https://twitter.com/aestherium_coin



*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


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

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }
    function div(int256 a, int256 b) internal pure returns (int256) {

        // PreventOverflowWhenDividing MIN_INT256 by -1

        require(b != -1 || a != MIN_INT256);

        // SolidityAlreadyThrowsWhenDividingBy 0...
        return a / b;
    }
    function sub(int256 a, int256 b) internal pure returns (int256) {

        int256 c = a - b;

        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }
    function add(int256 a, int256 b) internal pure returns (int256) {

        int256 c = a + b;

        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }
    function abs(int256 a) internal pure returns (int256) {

        require(a != MIN_INT256);

        return a < 0 ? -a : a;
    }
    function toUint256Safe(int256 a) internal pure returns (uint256) {

        require(a >= 0);

        return uint256(a);
    }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {

    int256 b = int256(a);

    require(b >= 0);

    return b;
  }
}

library IterableMapping {

    struct Map {

        address[] keys;

        mapping(address => uint) values;

        mapping(address => uint) indexOf;

        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {

        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {

        if(!map.inserted[key]) {

            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {

        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {

        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {

        if (map.inserted[key]) {

            map.values[key] = val;

        } else {
            map.inserted[key] = true;

            map.values[key] = val;

            map.indexOf[key] = map.keys.length;

            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
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



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
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

interface IUniswapV2Router01 {
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

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
interface IUniswapV2Pair {
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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
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
        _balances[account]=_balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account !=address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account]=_balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner !=address(0), "ERC20: approve from the zero address");
        require(spender !=address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender]=amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface DividendPayingTokenInterface {
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

interface DividendPayingTokenOptionalInterface {
  function withdrawableDividendOf(address _owner) external view returns(uint256);
  function withdrawnDividendOf(address _owner) external view returns(uint256);
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

///rewardToken...
/// @by RogerWu (https://github.com/roger-wu)...

///  refference to  https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code...
contract DividendPayingToken is ERC20, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  // Magnitude allows bnb distribution...RegardlessValue...
  
  //visit https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728 for information...
  uint256 constant internal magnitude=2**128;
  uint256 internal magnifiedDividendPerShare;
  uint256 public totalDividendsDistributed;

  //dividend Correction and calculation...
 
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

  // @send reward whenever bnb is paid to the contract...
  receive() external payable {
    distributeDividends();
  }

  // Transfer bnb to Aestherians as rewards...

  // zeroSupplyReverts...
  
  function distributeDividends() public override payable {
    require (totalSupply () > 0);
    if (msg.value > 0) {
      magnifiedDividendPerShare=magnifiedDividendPerShare.add((msg.value).mul(magnitude) / totalSupply());
      emit DividendsDistributed(msg.sender, msg.value);
      totalDividendsDistributed=totalDividendsDistributed.add(msg.value);
    }
  }
  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }
  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend=withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user]=withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      (bool success,)=user.call{value: _withdrawableDividend, gas: 3000}("");
      if(!success) {
        withdrawnDividends[user]=withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }
      return _withdrawableDividend;
    }
    return 0;
  }
  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }
  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);
    int256 _magCorrection=magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from]=magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to]=magnifiedDividendCorrections[to].sub(_magCorrection);
  }
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);
    magnifiedDividendCorrections[account]=magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);
    magnifiedDividendCorrections[account]=magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance=balanceOf(account);
    if(newBalance>currentBalance) {
      uint256 mintAmount=newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance<currentBalance) {
      uint256 burnAmount=currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}

contract Aestherium is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    string private _name="Aestherium";
    string private _symbol="AEST";
    uint8 private _decimals=18;

    AESTHERIUMDividendTracker public dividendTracker;
    
    bool public isTradingEnabled;
    uint256 private _tradingPausedTimestamp;
    // initialSupply is 500 Million...
    uint256 constant initialSupply=500000000 * (10**18);
     
    uint256 public maxWalletAmount=initialSupply * 250 / 10000;  // maximum wallet size is 2.5% initial Supply...
    
    uint256 public maxTxAmount=initialSupply * 25 / 10000; // maximum buy & sell tranx is 0.25% initial Supply...
    bool private _swapping;
    uint256 public minimumTokensBeforeSwap=125000 * (10**18); 
    uint256 public gasForProcessing=300000;
    uint256 private _liquidityTokensToSwap;
    uint256 private _mktnTokensToSwap;
    uint256 private _bbTokensToSwap;
    uint256 private _ecoCharityTokensToSwap;
    uint256 private _rewardsTokensToSwap;
    
    address public mktnWallet;
    address public liquidityWallet;
    address public bbWallet;
    address public ecoCharityWallet;
    
    struct CustomTaxPeriod {
        bytes23 periodName;
        uint8 blocksInPeriod;
        uint256 timeInPeriod;
        uint256 liquidityFeeOnBuy;
        uint256 liquidityFeeOnSell;
        uint256 mktnFeeOnBuy;
        uint256 mktnFeeOnSell;
        uint256 bbFeeOnBuy;
        uint256 bbFeeOnSell;
        uint256 ecoCharityFeeOnBuy;
        uint256 ecoCharityFeeOnSell;
        uint256 rewardsFeeOnBuy;
        uint256 rewardsFeeOnSell;
    }
    //LaunchTaxes...
    bool private _isLanched;
    uint256 private _launchStartTimestamp;
    uint256 private _launchBlockNumber;
    uint256 private _launchSellMaximum=initialSupply*25/10000; //launchMaxSell=0.25% ofSupply
    CustomTaxPeriod private _launch01=CustomTaxPeriod('launch01',3,0,10000,0,0,0,0,0,0,0,0,0);
    CustomTaxPeriod private _launch02=CustomTaxPeriod('launch02',0,3600,0,500,0,500,0,1500,0,0,0,1500);
    CustomTaxPeriod private _launch03=CustomTaxPeriod('launch03',0,82800,0,500,0,500,0,500,0,0,0,1000); 

    //TaxFeeDistribution...
    //onBuy
    uint256 public liquidityFeeOnBuy=300;
    uint256 public mktnFeeOnBuy=300;
    uint256 public rewardsFeeOnBuy=300;
    uint256 public ecoCharityFeeOnBuy=300;
    uint256 public bbFeeOnBuy=300;
    //onSell
    uint256 public liquidityFeeOnSell=300;
    uint256 public mktnFeeOnSell=400;
    uint256 public rewardsFeeOnSell=400;
    uint256 public ecoCharityFeeOnSell=300;
    uint256 public bbFeeOnSell=400;
   
    //ShieldFunctionsTax...
    uint256 private _shieldStartTimestamp;
    CustomTaxPeriod private _shield01=CustomTaxPeriod('shield01', 0,3600,0,0,100,750,0,750,0,0,0,750);
    CustomTaxPeriod private _shield02=CustomTaxPeriod('shield02', 0,3600,0,0,0,600,0,600,0,0,0,1200);
    CustomTaxPeriod private _shield03=CustomTaxPeriod('shield03', 0,3600,0,0,0,450,0,450,0,0,0,900);
    uint256 private _blacklistTimeLimit=43200;
    mapping (address=>bool) private _isExcludedFromFee;
    mapping (address=>bool) private _isExcludedFromMaxTransactionLimit;
    mapping (address=>bool) private _isExcludedFromMaxWalletLimit;
    mapping (address=>bool) private _isBlacklisted;
    mapping (address=>bool) public automatedMarketMakerPairs;
    mapping (address=>uint256) private _buyTimesInLaunch;
    event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
    event DividendTrackerChange(address indexed newAddress, address indexed oldAddress);
    event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFeesChange(address indexed account, bool isExcluded);
    event LiquidityWalletChange(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event MktnWalletChange(address indexed newMktnWallet, address indexed oldMktnWallet);
    event BbWalletChange(address indexed newBbWallet, address indexed oldBbWallet);
    event EcoCharityWalletChange(address indexed newEcoCharityWallet, address indexed oldEcoCharityWallet);
    event GasForProcessingChange(uint256 indexed newValue, uint256 indexed oldValue);
    event FeeOnSellChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType);
    event FeeOnBuyChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType);
    event CustomTaxPeriodChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType, bytes23 period);
    event BlacklistChange(address indexed reward, bool indexed status);
    event AestheriumShieldChange(bool indexed newValue, bool indexed oldValue);
    event MaxTransactionAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event MaxWalletAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
    event ExcludeFromMaxTransferChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
    event MinTokenAmountForDividendsChange(uint256 indexed newValue, uint256 indexed oldValue);
    event ExcludeFromDividendsChange(address indexed account, bool isExcluded);
    event DividendsSent(uint256 tokensSwapped);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived,uint256 tokensIntoLiqudity);
    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    constructor() ERC20("AESTHERIUM", "AEST") {
        liquidityWallet=address(0x3e25186F8144D0f3235a1F9974BE8B4f405b17B2);
    	mktnWallet=address(0x6B5033Df738135f24b588ed90deF2E89707eA7dB);
    	ecoCharityWallet=address(0x99535adD8570aa8D0796985FE2E36a5e06Fae586);
    	bbWallet=address(0x99535adD8570aa8D0796985FE2E36a5e06Fae586);
    	
    	dividendTracker=new AESTHERIUMDividendTracker();
    
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // Testnet
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // (Mainnet 0x10ED43C718714eb63d5aA57B78B54704E256024E)
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router=_uniswapV2Router;
        uniswapV2Pair=_uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        
        _isExcludedFromFee[owner()]=true;
        _isExcludedFromFee[address(this)]=true;
    
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(address(0x000000000000000000000000000000000000dEaD));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        _isExcludedFromMaxTransactionLimit[address(dividendTracker)]=true;
        _isExcludedFromMaxTransactionLimit[address(this)]=true;
        
        _isExcludedFromMaxWalletLimit[_uniswapV2Pair]=true;
        _isExcludedFromMaxWalletLimit[address(uniswapV2Router)]=true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[owner()]=true;
        
        _mint(owner(), initialSupply);
    }
    
    receive() external payable {}
    
    // Setters
    function _getNow() private view returns (uint256) {
        return block.timestamp;
    }
    function launch() public onlyOwner {
        _launchStartTimestamp=_getNow();
        _launchBlockNumber=block.number;
         isTradingEnabled=true;
        _isLanched=true;
    }
    function cancelLaunch() public onlyOwner {
        require(this.isInLaunch(), "AESTHERIUM: Launch is not set");
        _launchStartTimestamp=0;
        _launchBlockNumber=0;
    }
    function activateTrading() public onlyOwner {
        isTradingEnabled=true;
    }
    function deactivateTrading() public onlyOwner {
        isTradingEnabled=false;
        _tradingPausedTimestamp=_getNow();
    }
    function setAestheriumShield() public onlyOwner {
        require(!this.isInShield(), "AESTHERIUM: Shield is already set");
        require(isTradingEnabled, "AESTHERIUM: Trading must be enabled first");
        require(!this.isInLaunch(), "AESTHERIUM: Must not be in launch period");
        emit AestheriumShieldChange(true, false);
        _shieldStartTimestamp=_getNow();
    }
    function cancelAestheriumShield() public onlyOwner {
        require(this.isInShield(), "AESTHERIUM: Shield is not set");
        emit AestheriumShieldChange(false, true);
        _shieldStartTimestamp=0;
    }
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress !=address(dividendTracker), "AESTHERIUM: The dividend tracker already has that address");
        AESTHERIUMDividendTracker newDividendTracker = AESTHERIUMDividendTracker(payable(newAddress));
        require(newDividendTracker.owner()==address(this), "AESTHERIUM: The new dividend tracker must be owned by the AESTHERIUM token contract");
        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
        emit DividendTrackerChange(newAddress, address(dividendTracker));
        dividendTracker=newDividendTracker;
    }
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "AESTHERIUM: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }
        emit AutomatedMarketMakerPairChange(pair, value);
    }
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFee[account] != excluded, "AESTHERIUM: Account is already the value of 'excluded'");
        _isExcludedFromFee[account]=excluded;
        emit ExcludeFromFeesChange(account, excluded);
    }
    function excludeFromDividends(address account) public onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }
    function excludeFromMaxTransactionLimit(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromMaxTransactionLimit[account] !=excluded, "AESTHERIUM: Account is already the value of 'excluded'");
        _isExcludedFromMaxTransactionLimit[account]=excluded;
        emit ExcludeFromMaxTransferChange(account, excluded);
    }
    function excludeFromMaxWalletLimit(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromMaxWalletLimit[account] !=excluded, "AESTHERIUM: Account is already the value of 'excluded'");
        _isExcludedFromMaxWalletLimit[account]=excluded;
        emit ExcludeFromMaxWalletChange(account, excluded);
    }
    function blacklistAccount(address account) public onlyOwner {
        uint256 currentTimestamp=_getNow();
        require(!_isBlacklisted[account], "AESTHERIUM: Account is already blacklisted");
        if (_isLanched) {
            require(currentTimestamp.sub(_launchStartTimestamp) < _blacklistTimeLimit, "AESTHERIUM: Time to blacklist accounts has expired");
        }
        _isBlacklisted[account] = true;
        emit BlacklistChange(account, true);
    }
    function unBlacklistAccount(address account) public onlyOwner {
        require(_isBlacklisted[account], "AESTHERIUM: Account is not blacklisted");
        _isBlacklisted[account]=false;
        emit BlacklistChange(account, false);
    }
    function setLiquidityWallet(address newAddress) public onlyOwner {
        require(liquidityWallet != newAddress, "AESTHERIUM: The liquidityWallet is already that address");
        emit LiquidityWalletChange(newAddress, liquidityWallet);
        liquidityWallet = newAddress;
    }
    function setMktnWallet(address newAddress) public onlyOwner {
        require(mktnWallet !=newAddress, "AESTHERIUM: The mktnWallet is already that address");
        emit MktnWalletChange(newAddress, mktnWallet);
        mktnWallet = newAddress;
    }
    function setBbWallet(address newAddress) public onlyOwner {
        require(bbWallet != newAddress, "AESTHERIUM: The bbWallet is already that address");
        emit BbWalletChange(newAddress, bbWallet);
        bbWallet = newAddress;
    }
    function setEcoCharityWallet(address newAddress) public onlyOwner {
        require(ecoCharityWallet !=newAddress, "AESTHERIUM: The ecoCharityWallet is already that address");
        emit EcoCharityWalletChange(newAddress, ecoCharityWallet);
        ecoCharityWallet=newAddress;
    }
    function setLiquidityFeeOnBuy(uint256 newvalue) public onlyOwner {
        require(liquidityFeeOnBuy != newvalue, "AESTHERIUM: The liquidityFeeOnBuy is already that value");
        emit FeeOnBuyChange(newvalue, liquidityFeeOnBuy, "liquidityFeeOnBuy");
        liquidityFeeOnBuy = newvalue;
    }
    function setMktnFeeOnBuy(uint256 newvalue) public onlyOwner {
        require(mktnFeeOnBuy != newvalue, "AESTHERIUM: The mktnFeeOnBuy is already that value");
        emit FeeOnBuyChange(newvalue, mktnFeeOnBuy, "mktnFeeOnBuy");
        mktnFeeOnBuy=newvalue;
    }
    function setRewardFeeOnBuy(uint256 newvalue) public onlyOwner {
        require(rewardsFeeOnBuy !=newvalue, "AESTHERIUM: The rewardsFeeOnBuy is already that value");
        emit FeeOnBuyChange(newvalue, rewardsFeeOnBuy, "rewardsFeeOnBuy");
        rewardsFeeOnBuy=newvalue;
    }
    function setBbFeeOnBuy(uint256 newvalue) public onlyOwner {
        require(bbFeeOnBuy !=newvalue, "AESTHERIUM: The bbFeeOnBuy is already that value");
        emit FeeOnBuyChange(newvalue, bbFeeOnBuy, "bbFeeOnBuy");
        bbFeeOnBuy=newvalue;
    }
    function setEcoCharityFeeOnBuy(uint256 newvalue) public onlyOwner {
        require(ecoCharityFeeOnBuy !=newvalue, "AESTHERIUM: The ecoCharityFeeOnBuy is already that value");
        emit FeeOnBuyChange(newvalue, ecoCharityFeeOnBuy, "ecoCharityFeeOnBuy");
        ecoCharityFeeOnBuy=newvalue;
    }
    function setLiquidityFeeOnSell(uint256 newvalue) public onlyOwner {
        require(liquidityFeeOnSell !=newvalue, "AESTHERIUM: The liquidityFeeOnSell is already that value");
        emit FeeOnSellChange(newvalue, liquidityFeeOnSell, "liquidityFeeOnSell");
        liquidityFeeOnSell=newvalue;
    }
    function setMktnFeeOnSell(uint256 newvalue) public onlyOwner {
        require(mktnFeeOnSell !=newvalue, "AESTHERIUM: The mktnFeeOnSell is already that value");
        emit FeeOnSellChange(newvalue, mktnFeeOnSell, "mktnFeeOnSell");
        mktnFeeOnSell=newvalue;
    }
    function setRewardFeeOnSell(uint256 newvalue) public onlyOwner {
        require(rewardsFeeOnSell !=newvalue, "AESTHERIUM: The rewardsFeeOnSell is already that value");
        emit FeeOnSellChange(newvalue, rewardsFeeOnSell, "rewardsFeeOnSell");
        rewardsFeeOnSell = newvalue;
    }
    function setBbFeeOnSell(uint256 newvalue) public onlyOwner {
        require(bbFeeOnSell !=newvalue, "AESTHERIUM: The bbFeeOnSell is already that value");
        emit FeeOnSellChange(newvalue, bbFeeOnSell, "bbFeeOnSell");
        bbFeeOnSell = newvalue;
    }
    function setEcoCharityFeeOnSell(uint256 newvalue) public onlyOwner {
        require(ecoCharityFeeOnSell !=newvalue, "AESTHERIUM: The ecoCharityFeeOnSell is already that value");
        emit FeeOnSellChange(newvalue, ecoCharityFeeOnSell, "ecoCharityFeeOnSell");
        ecoCharityFeeOnSell=newvalue;
    }
    function setShield01BuyFees(uint256 _liquidityFeeOnBuy,uint256 _mktnFeeOnBuy,uint256 _bbFeeOnBuy,uint256 _ecoCharityFeeOnBuy,uint256 _rewardsFeeOnBuy) public onlyOwner {
        _setCustomBuyTaxPeriod(_shield01,_liquidityFeeOnBuy, _mktnFeeOnBuy,_bbFeeOnBuy,_ecoCharityFeeOnBuy,_rewardsFeeOnBuy);
    }
    function setShield01SellFees(uint256 _liquidityFeeOnSell,uint256 _mktnFeeOnSell,uint256 _bbFeeOnSell,uint256 _ecoCharityFeeOnSell,uint256 _rewardsFeeOnSell) public onlyOwner {
        _setCustomSellTaxPeriod(_shield01,_liquidityFeeOnSell, _mktnFeeOnSell,_bbFeeOnSell,_ecoCharityFeeOnSell,_rewardsFeeOnSell);
    }
    function setShield02BuyFees(uint256 _liquidityFeeOnBuy,uint256 _mktnFeeOnBuy,uint256 _bbFeeOnBuy,uint256 _ecoCharityFeeOnBuy,uint256 _rewardsFeeOnBuy) public onlyOwner {
        _setCustomBuyTaxPeriod(_shield02,_liquidityFeeOnBuy, _mktnFeeOnBuy,_bbFeeOnBuy,_ecoCharityFeeOnBuy,_rewardsFeeOnBuy);
    }
    function setShield02SellFees(uint256 _liquidityFeeOnSell,uint256 _mktnFeeOnSell,uint256 _bbFeeOnSell,uint256 _ecoCharityFeeOnSell,uint256 _rewardsFeeOnSell) public onlyOwner {
        _setCustomSellTaxPeriod(_shield02,_liquidityFeeOnSell, _mktnFeeOnSell,_bbFeeOnSell,_ecoCharityFeeOnSell,_rewardsFeeOnSell);
    }
    function setShield03BuyFees(uint256 _liquidityFeeOnBuy,uint256 _mktnFeeOnBuy,uint256 _bbFeeOnBuy,uint256 _ecoCharityFeeOnBuy,uint256 _rewardsFeeOnBuy) public onlyOwner {
        _setCustomBuyTaxPeriod(_shield03,_liquidityFeeOnBuy, _mktnFeeOnBuy,_bbFeeOnBuy,_ecoCharityFeeOnBuy,_rewardsFeeOnBuy);
    }
    function setShield03SellFees(uint256 _liquidityFeeOnSell,uint256 _mktnFeeOnSell,uint256 _bbFeeOnSell,uint256 _ecoCharityFeeOnSell,uint256 _rewardsFeeOnSell) public onlyOwner {
        _setCustomSellTaxPeriod(_shield03,_liquidityFeeOnSell, _mktnFeeOnSell,_bbFeeOnSell,_ecoCharityFeeOnSell,_rewardsFeeOnSell);
    }
    function setUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "AESTHERIUM: The router already has that address");
        emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
        uniswapV2Router=IUniswapV2Router02(newAddress);
    }
    function setGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >=150000 && newValue <=550000, "AESTHERIUM: gasForProcessing must be between 150,000 and 550,000");
        require(newValue !=gasForProcessing, "AESTHERIUM: Cannot update gasForProcessing to same value");
        emit GasForProcessingChange(newValue, gasForProcessing);
        gasForProcessing=newValue;
    }
    function setMaxTxAmount(uint256 newValue) public onlyOwner {
        require(newValue !=maxTxAmount, "AESTHERIUM: Cannot update maxTxAmount to same value");
        emit MaxTransactionAmountChange(newValue, maxTxAmount);
        maxTxAmount=newValue;
    }
    function setMaxWalletAmount(uint256 newValue) public onlyOwner {
        require(newValue !=maxWalletAmount, "AESTHERIUM: Cannot update maxWalletAmount to same value");
        emit MaxWalletAmountChange(newValue, maxWalletAmount);
        maxWalletAmount=newValue;
    }
    function setMinimumTokensBeforeSwap(uint256 newValue) public onlyOwner {
        require(newValue !=minimumTokensBeforeSwap, "AESTHERIUM: Cannot update minimumTokensBeforeSwap to same value");
        emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
        
        minimumTokensBeforeSwap=newValue;
    }
    function setMinimumTokenBalanceForDividends(uint256 newValue) public onlyOwner {
       
        dividendTracker.setTokenBalanceForDividends(newValue);
    }
    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }
    function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex)=dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }
    function claim() external {
		
        dividendTracker.processAccount(payable(msg.sender), false);
    }
    
    //Getters
    function isInShield() external view returns (bool) {
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _shieldStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        uint256 totalShieldTime = _shield01.timeInPeriod.add(_shield02.timeInPeriod).add(_shield03.timeInPeriod);
        uint256 timeSinceShield = currentTimestamp.sub(_shieldStartTimestamp);
        if(timeSinceShield < totalShieldTime) {
            return true;
        } else {
            return false;
        }
    }
    function isInLaunch() external view returns (bool) {
        
        uint256 currentTimestamp=!isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        
        uint256 timeSinceLaunch=currentTimestamp.sub(_launchStartTimestamp);
        
        uint256 blocksSinceLaunch=block.number.sub(_launchBlockNumber);
        
        uint256 totalLaunchTime=_launch01.timeInPeriod.add(_launch02.timeInPeriod).add(_launch03.timeInPeriod);
        
        if(_isLanched && (timeSinceLaunch < totalLaunchTime || blocksSinceLaunch < _launch01.blocksInPeriod )) {
            return true;

        } else {

            return false;
        }
    }
    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }
    function getTotalDividendsDistributed() external view returns (uint256) {
       
        return dividendTracker.totalDividendsDistributed();
    }
    function withdrawableDividendOf(address account) public view returns(uint256) {
    	
        return dividendTracker.withdrawableDividendOf(account);
  	}
	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		
        return dividendTracker.balanceOf(account);
	}
    function getAccountDividendsInfo(address account)
        
        external view returns (
            address,
           
            int256,
           
            int256,
           
            uint256,
           
            uint256,
          
            uint256,
           
            uint256,
           
            uint256) {
        
        return dividendTracker.getAccount(account);
    }
    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }
    function getNumberOfDividendAestherians() external view returns(uint256) {
        
        return dividendTracker.getNumberOfAestherians();
    }
    function getShield01BuyFees() external view returns (uint256, uint256, uint256,uint256, uint256){
        
        return (_shield01.liquidityFeeOnBuy,_shield01.mktnFeeOnBuy, _shield01.bbFeeOnBuy, _shield01.ecoCharityFeeOnBuy, _shield01.rewardsFeeOnBuy);
    }
    function getShield01SellFees() external view returns (uint256, uint256, uint256,uint256, uint256){
        return (_shield01.liquidityFeeOnSell,_shield01.mktnFeeOnSell, _shield01.bbFeeOnSell, _shield01.ecoCharityFeeOnSell, _shield01.rewardsFeeOnSell);
    }
    function getShield02BuyFees() external view returns (uint256, uint256, uint256,uint256, uint256){
       
        return (_shield02.liquidityFeeOnBuy,_shield02.mktnFeeOnBuy, _shield02.bbFeeOnBuy, _shield02.ecoCharityFeeOnBuy, _shield02.rewardsFeeOnBuy);
    }
    function getShield02SellFees() external view returns (uint256, uint256, uint256,uint256, uint256){
        
        return (_shield02.liquidityFeeOnSell,_shield02.mktnFeeOnSell, _shield02.bbFeeOnSell, _shield02.ecoCharityFeeOnSell, _shield02.rewardsFeeOnSell);
    }
    function getShield03BuyFees() external view returns (uint256, uint256, uint256,uint256, uint256){
       
        return (_shield03.liquidityFeeOnBuy,_shield03.mktnFeeOnBuy, _shield03.bbFeeOnBuy, _shield03.ecoCharityFeeOnBuy, _shield03.rewardsFeeOnBuy);
    }

    function getShield03SellFees() external view returns (uint256, uint256, uint256,uint256, uint256){
       
        return (_shield03.liquidityFeeOnSell,_shield03.mktnFeeOnSell, _shield03.bbFeeOnSell, _shield03.ecoCharityFeeOnSell, _shield03.rewardsFeeOnSell);
    }
    
    //Main
    function _transfer(

        address from,

        address to,

        uint256 amount

    ) internal override {

        require(from !=address(0), "ERC20: transfer from the zero address");

        require(to !=address(0), "ERC20: transfer to the zero address");

        if(amount==0) {

            super._transfer(from, to, 0);

            return;
        }
        
        bool isBuyFromLp=automatedMarketMakerPairs[from];
        bool isSelltoLp=automatedMarketMakerPairs[to];
        bool _isInLaunch=this.isInLaunch();
        
        uint256 currentTimestamp=!isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        
        if(from !=owner() && to !=owner()) {
            require(isTradingEnabled, "AESTHERIUM: Trading is currently disabled.");
            require(!_isBlacklisted[to], "AESTHERIUM: Account is blacklisted");
            require(!_isBlacklisted[from], "AESTHERIUM: Account is blacklisted");
            if (_isInLaunch && currentTimestamp.sub(_launchStartTimestamp) <=360 && isBuyFromLp) {
                require(currentTimestamp.sub(_buyTimesInLaunch[to]) > 120, "AESTHERIUM: Cannot buy more than once every 2 minutes in first 6 minutes after launch");
            }
            if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[from]) {
                require(amount <=maxTxAmount, "AESTHERIUM: Buy amount exceeds the maxTxBuyAmount.");
            }

            if (!_isExcludedFromMaxWalletLimit[to]) {
                require(balanceOf(to).add(amount) <=maxWalletAmount, "AESTHERIUM: Expected wallet amount exceeds the maxWalletAmount.");
            }
        }
        
        bool canSwap=balanceOf(address(this)) >=minimumTokensBeforeSwap;
        
        if (
            isTradingEnabled && 
            canSwap &&
            !_swapping &&
            !automatedMarketMakerPairs[from] &&
            from !=liquidityWallet && to !=liquidityWallet &&
            from !=mktnWallet && to !=mktnWallet &&
            from !=bbWallet && to !=bbWallet &&
            from !=ecoCharityWallet && to !=ecoCharityWallet
        ) {
            _swapping=true;
            _swapAndLiquify();
            _swapping=false;
        }
        
        bool takeFee=!_swapping && isTradingEnabled;
        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        if (takeFee) {
            (uint256 returnAmount, uint256 fee)=_getCurrentTotalFee(isBuyFromLp, amount);
            amount=returnAmount;
            super._transfer(from, address(this), fee);
        }
        
        if (_isInLaunch && currentTimestamp.sub(_launchStartTimestamp) <=360) {
            if (to !=owner() && isBuyFromLp  && currentTimestamp.sub(_buyTimesInLaunch[to]) > 120) {
                _buyTimesInLaunch[to]=currentTimestamp;
            }
        }
        
        super._transfer(from, to, amount);
        
        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        
        if(!_swapping) {
	    	uint256 gas=gasForProcessing;
	    	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	} 
	    	catch {}
        }
    }
    function _getCurrentTotalFee(bool isBuyFromLp, uint256 amount) internal returns (uint256 returnAmount, uint256 fee) {
        uint256 _liquidityFee=isBuyFromLp ? liquidityFeeOnBuy : liquidityFeeOnSell;
        uint256 _mktnFee=isBuyFromLp ? mktnFeeOnBuy : mktnFeeOnSell;
        uint256 _ecoCharityFee=isBuyFromLp ? ecoCharityFeeOnBuy : ecoCharityFeeOnSell;
        uint256 _bbFee=isBuyFromLp ? bbFeeOnBuy : bbFeeOnSell;
        uint256 _rewardsFee=isBuyFromLp ? rewardsFeeOnBuy : rewardsFeeOnSell;
        
        if (this.isInLaunch()) {
            bool _isInLaunch01Period=_isInLaunch01();
            bool _isInLaunch02Period=_isInLaunch02();
            if (isBuyFromLp) {
                _liquidityFee = _isInLaunch01Period ? _launch01.liquidityFeeOnBuy : _liquidityFee;
            }
            else {
                _liquidityFee = _isInLaunch01Period ? _liquidityFee : _isInLaunch02Period ? _launch02.liquidityFeeOnSell : _launch03.liquidityFeeOnSell;
                _mktnFee = _isInLaunch01Period ? _mktnFee : _isInLaunch02Period ? _launch02.mktnFeeOnSell : _launch03.mktnFeeOnSell;
                _bbFee = _isInLaunch01Period ? _bbFee : _isInLaunch02Period ? _launch02.bbFeeOnSell : _launch03.bbFeeOnSell;
                _rewardsFee = _isInLaunch01Period ? _rewardsFee : _isInLaunch02Period ? _launch02.rewardsFeeOnSell : _launch03.rewardsFeeOnSell;
            }
        }
        if (this.isInShield()) {
            if (_isInShield01()) {
                _liquidityFee = isBuyFromLp && _shield01.liquidityFeeOnBuy > 0 ? _shield01.liquidityFeeOnBuy : !isBuyFromLp && _shield01.liquidityFeeOnSell > 0 ? _shield01.liquidityFeeOnSell : _liquidityFee;
                _mktnFee = isBuyFromLp && _shield01.mktnFeeOnBuy > 0 ? _shield01.mktnFeeOnBuy : !isBuyFromLp && _shield01.mktnFeeOnSell > 0 ? _shield01.mktnFeeOnSell : _mktnFee;
                _bbFee = isBuyFromLp && _shield01.bbFeeOnBuy > 0 ? _shield01.bbFeeOnBuy : !isBuyFromLp && _shield01.bbFeeOnSell > 0 ? _shield01.bbFeeOnSell : _bbFee;
                _ecoCharityFee = isBuyFromLp && _shield01.ecoCharityFeeOnBuy > 0 ? _shield01.ecoCharityFeeOnBuy : !isBuyFromLp && _shield01.ecoCharityFeeOnSell > 0 ? _shield01.ecoCharityFeeOnSell : _ecoCharityFee;
                _rewardsFee = isBuyFromLp && _shield01.rewardsFeeOnBuy > 0 ? _shield01.rewardsFeeOnBuy : !isBuyFromLp && _shield01.rewardsFeeOnSell > 0 ? _shield01.rewardsFeeOnSell : _rewardsFee;
            }
            else if (_isInShield02()) {
                _liquidityFee=isBuyFromLp && _shield02.liquidityFeeOnBuy > 0 ? _shield02.liquidityFeeOnBuy : !isBuyFromLp && _shield02.liquidityFeeOnSell > 0 ? _shield02.liquidityFeeOnSell : _liquidityFee;
                _mktnFee=isBuyFromLp && _shield02.mktnFeeOnBuy > 0 ? _shield02.mktnFeeOnBuy : !isBuyFromLp && _shield02.mktnFeeOnSell > 0 ? _shield02.mktnFeeOnSell : _mktnFee;
                _bbFee=isBuyFromLp && _shield02.bbFeeOnBuy > 0 ? _shield02.bbFeeOnBuy : !isBuyFromLp && _shield02.bbFeeOnSell > 0 ? _shield02.bbFeeOnSell : _bbFee;
                _ecoCharityFee=isBuyFromLp && _shield02.ecoCharityFeeOnBuy > 0 ? _shield02.ecoCharityFeeOnBuy : !isBuyFromLp && _shield02.ecoCharityFeeOnSell > 0 ? _shield02.ecoCharityFeeOnSell : _ecoCharityFee;
                _rewardsFee=isBuyFromLp && _shield02.rewardsFeeOnBuy > 0 ? _shield02.rewardsFeeOnBuy : !isBuyFromLp && _shield02.rewardsFeeOnSell > 0 ? _shield02.rewardsFeeOnSell : _rewardsFee;
            }
            else {
                _liquidityFee = isBuyFromLp && _shield03.liquidityFeeOnBuy > 0 ? _shield03.liquidityFeeOnBuy : !isBuyFromLp && _shield03.liquidityFeeOnSell > 0 ? _shield03.liquidityFeeOnSell : _liquidityFee;
                _mktnFee = isBuyFromLp && _shield03.mktnFeeOnBuy > 0 ? _shield03.mktnFeeOnBuy : !isBuyFromLp && _shield03.mktnFeeOnSell > 0 ? _shield03.mktnFeeOnSell : _mktnFee;
                _bbFee = isBuyFromLp && _shield03.bbFeeOnBuy > 0 ? _shield03.bbFeeOnBuy : !isBuyFromLp && _shield03.bbFeeOnSell > 0 ? _shield03.bbFeeOnSell : _bbFee;
                _ecoCharityFee = isBuyFromLp && _shield03.ecoCharityFeeOnBuy > 0 ? _shield03.ecoCharityFeeOnBuy : !isBuyFromLp && _shield03.ecoCharityFeeOnSell > 0 ? _shield03.ecoCharityFeeOnSell : _ecoCharityFee;
                _rewardsFee = isBuyFromLp && _shield03.rewardsFeeOnBuy > 0 ? _shield03.rewardsFeeOnBuy : !isBuyFromLp && _shield03.rewardsFeeOnSell > 0 ? _shield03.rewardsFeeOnSell : _rewardsFee;
            }
        }
        
        uint256 _totalFee = _liquidityFee.add(_mktnFee).add(_ecoCharityFee).add(_bbFee).add(_rewardsFee);

        fee = amount.mul(_totalFee).div(10000);
    	returnAmount = amount.sub(fee);
    	_updateTokensToSwap(amount, _liquidityFee,_mktnFee, _bbFee, _ecoCharityFee, _rewardsFee);
    	return (returnAmount, fee);
    }
    function _updateTokensToSwap(uint256 amount, uint256 liquidityFee,uint256 mktnFee, uint256 bbFee, uint256 ecoCharityFee, uint256 rewardsFee) private {
        _liquidityTokensToSwap = _liquidityTokensToSwap.add(amount.mul(liquidityFee).div(10000));
    	_mktnTokensToSwap = _mktnTokensToSwap.add(amount.mul(mktnFee).div(10000));
    	_bbTokensToSwap = _bbTokensToSwap.add(amount.mul(bbFee).div(10000));
    	_ecoCharityTokensToSwap = _ecoCharityTokensToSwap.add(amount.mul(ecoCharityFee).div(10000));
    	_rewardsTokensToSwap = _rewardsTokensToSwap.add(amount.mul(rewardsFee).div(10000));
    }
    function _isInLaunch01() internal view returns(bool) {
        uint256 blocksSinceLaunch=block.number.sub(_launchBlockNumber);
        if(blocksSinceLaunch<_launch01.blocksInPeriod) {
            return true;
        } else {
            return false;
        }
    }

    function _isInLaunch02() internal view returns(bool) {
        uint256 currentTimestamp=!isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        uint256 blocksSinceLaunch=block.number.sub(_launchBlockNumber);
        uint256 timeSinceLaunch=currentTimestamp.sub(_launchStartTimestamp);
        if (timeSinceLaunch<_launch01.timeInPeriod && blocksSinceLaunch>_launch01.blocksInPeriod ) {
            return true;
        } else {
            return false;
        }
    }

    function _isInLaunch03() internal view returns(bool) {
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        uint256 timeSinceLaunch = currentTimestamp.sub(_launchStartTimestamp);
        uint256 blocksSinceLaunch = block.number.sub(_launchBlockNumber);
        uint256 timeInLaunch = _launch03.timeInPeriod.add(_launch02.timeInPeriod);
        if (timeSinceLaunch > _launch02.timeInPeriod && timeSinceLaunch < timeInLaunch && blocksSinceLaunch > _launch01.blocksInPeriod) {
            return true;
        } else {
            return false;
        }
    }
    function _isInShield01() internal view returns (bool) {
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _shieldStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        uint256 timeSinceShield = currentTimestamp.sub(_shieldStartTimestamp);
        if(timeSinceShield < _shield01.timeInPeriod) {
            return true;
        } else {
            return false;
        }
    }

    function _isInShield02() internal view returns (bool) {
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _shieldStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        uint256 timeSinceShield = currentTimestamp.sub(_shieldStartTimestamp);
        if(timeSinceShield > _shield01.timeInPeriod && timeSinceShield < _shield01.timeInPeriod.add(_shield02.timeInPeriod)) {
            return true;
        } else {
            return false;
        }
    }
    function _isInShield03() internal view returns (bool) {
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _shieldStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        uint256 timeSinceShield = currentTimestamp.sub(_shieldStartTimestamp);
        uint256 totalTimeInShield01 = _shield01.timeInPeriod.add(_shield02.timeInPeriod);
        uint256 totalTimeInShield02 = _shield01.timeInPeriod.add(_shield02.timeInPeriod).add(_shield03.timeInPeriod);
        if(timeSinceShield > totalTimeInShield01 && timeSinceShield < totalTimeInShield02) {
            return true;
        } else {
            return false;
        }
    }

    function _setCustomSellTaxPeriod(CustomTaxPeriod storage map,
        uint256 _liquidityFeeOnSell,
        uint256 _mktnFeeOnSell,
        uint256 _bbFeeOnSell,
        uint256 _ecoCharityFeeOnSell,
        uint256 _rewardsFeeOnSell
        ) private {
        if (map.liquidityFeeOnSell !=_liquidityFeeOnSell) {
            emit CustomTaxPeriodChange(_liquidityFeeOnSell, map.liquidityFeeOnSell, 'liquidityFeeOnSell', map.periodName);
            map.liquidityFeeOnSell = _liquidityFeeOnSell;
        }

        if (map.mktnFeeOnSell !=_mktnFeeOnSell) {
            emit CustomTaxPeriodChange(_mktnFeeOnSell, map.mktnFeeOnSell, 'mktnFeeOnSell', map.periodName);
            map.mktnFeeOnSell =_mktnFeeOnSell;
        }

        if (map.bbFeeOnSell !=_bbFeeOnSell) {
            emit CustomTaxPeriodChange(_bbFeeOnSell, map.bbFeeOnSell, 'bbFeeOnSell', map.periodName);
            map.bbFeeOnSell =_bbFeeOnSell;
        }

        if (map.ecoCharityFeeOnSell !=_ecoCharityFeeOnSell) {
            emit CustomTaxPeriodChange(_ecoCharityFeeOnSell, map.ecoCharityFeeOnSell, 'ecoCharityFeeOnSell', map.periodName);
            map.ecoCharityFeeOnSell =_ecoCharityFeeOnSell;
        }

        if (map.rewardsFeeOnSell != _rewardsFeeOnSell) {
            emit CustomTaxPeriodChange(_rewardsFeeOnSell, map.rewardsFeeOnSell, 'rewardsFeeOnSell', map.periodName);
            map.rewardsFeeOnSell = _rewardsFeeOnSell;
        }
    }
    function _setCustomBuyTaxPeriod(CustomTaxPeriod storage map,
        uint256 _liquidityFeeOnBuy,
        uint256 _mktnFeeOnBuy,
        uint256 _bbFeeOnBuy,
        uint256 _ecoCharityFeeOnBuy,
        uint256 _rewardsFeeOnBuy
        ) private {
        if (map.liquidityFeeOnBuy != _liquidityFeeOnBuy) {
            emit CustomTaxPeriodChange(_liquidityFeeOnBuy, map.liquidityFeeOnBuy, 'liquidityFeeOnBuy', map.periodName);
            map.liquidityFeeOnBuy = _liquidityFeeOnBuy;
        }

        if (map.mktnFeeOnBuy != _mktnFeeOnBuy) {
            emit CustomTaxPeriodChange(_mktnFeeOnBuy, map.mktnFeeOnBuy, 'mktnFeeOnBuy', map.periodName);
            map.mktnFeeOnBuy = _mktnFeeOnBuy;
        }

        if (map.bbFeeOnBuy !=_bbFeeOnBuy) {
            emit CustomTaxPeriodChange(_bbFeeOnBuy, map.bbFeeOnBuy, 'bbFeeOnBuy', map.periodName);
            map.bbFeeOnBuy=_bbFeeOnBuy;
        }

        if (map.ecoCharityFeeOnBuy !=_ecoCharityFeeOnBuy) {
            emit CustomTaxPeriodChange(_ecoCharityFeeOnBuy, map.ecoCharityFeeOnBuy, 'ecoCharityFeeOnBuy', map.periodName);
            map.ecoCharityFeeOnBuy=_ecoCharityFeeOnBuy;
        }

        if (map.rewardsFeeOnBuy !=_rewardsFeeOnBuy) {
            emit CustomTaxPeriodChange(_rewardsFeeOnBuy, map.rewardsFeeOnBuy, 'rewardsFeeOnBuy', map.periodName);
            map.rewardsFeeOnBuy=_rewardsFeeOnBuy;
        }
    }

    function _swapAndLiquify() private {
        uint256 contractBalance=balanceOf(address(this));
        uint256 totalTokensToSwap=_liquidityTokensToSwap.add(_mktnTokensToSwap).add(_ecoCharityTokensToSwap).add(_bbTokensToSwap).add(_rewardsTokensToSwap);
        
        //amount of liquidity*1/2 tokens...
        uint256 tokensInAestheriumForLiquidity=_liquidityTokensToSwap.div(2);
        uint256 amountToSwapForBNB=contractBalance.sub(tokensInAestheriumForLiquidity);
        
        // initialBNBbalance...
        uint256 initialBNBBalance=address(this).balance;
        // exchangeforBNB...
        _swapTokensForBNB(amountToSwapForBNB); 
        // GetTheBalance,minusWhatWeStartedWith...
        uint256 bnbBalance = address(this).balance.sub(initialBNBBalance);
        // DivvyUpTheBNBbasedOnAccruedTokensAs%ofTotalAccrued...
        uint256 bnbForMktn=bnbBalance.mul(_mktnTokensToSwap).div(totalTokensToSwap);
        uint256 bnbForBb=bnbBalance.mul(_bbTokensToSwap).div(totalTokensToSwap);
        uint256 bnbForEcoCharity=bnbBalance.mul(_ecoCharityTokensToSwap).div(totalTokensToSwap);
        uint256 bnbForRewards=bnbBalance.mul(_rewardsTokensToSwap).div(totalTokensToSwap);
        uint256 bnbForLiquidity=bnbBalance.sub(bnbForMktn).sub(bnbForBb).sub(bnbForEcoCharity).sub(bnbForRewards);
        
        _liquidityTokensToSwap=0;
        _mktnTokensToSwap=0;
        _ecoCharityTokensToSwap=0;
        _bbTokensToSwap=0;
        _rewardsTokensToSwap=0;
        
        payable(bbWallet).transfer(bnbForBb);
        payable(ecoCharityWallet).transfer(bnbForEcoCharity);
        payable(mktnWallet).transfer(bnbForMktn);
        
        _addLiquidity(tokensInAestheriumForLiquidity, bnbForLiquidity);
        emit SwapAndLiquify(amountToSwapForBNB, bnbForLiquidity, tokensInAestheriumForLiquidity);
        
        (bool success,)=address(dividendTracker).call{value: bnbForRewards}("");
        if(success) {

   	 		emit DividendsSent(bnbForRewards);
        }
    }
    function _swapTokensForBNB(uint256 tokenAmount) private {
        
        address[] memory path = new address[](2);
        
        path[0] = address(this);
       
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, //acceptAnyAmountOfBNB...
            path,
            address(this),
            block.timestamp
        );
    }
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
      
        _approve(address(this), address(uniswapV2Router), tokenAmount);
       
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
       
            tokenAmount,
            0, //slippageIsUnavoidable...
       
            0, //slippageIsUnavoidable...
            liquidityWallet,
            block.timestamp
        );
    }
}


contract AESTHERIUMDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private aestheriansMap;
    
    uint256 public lastProcessedIndex;
    mapping (address => bool) public excludedFromDividends;
   
    mapping (address => uint256) public lastClaimTimes;
   
    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("AESTHERIUM_Dividend_Tracker", "AESTHERIUM_Dividend_Tracker") {
    	claimWait = 3600;
        minimumTokenBalanceForDividends=25000 * (10**18); 
    }
    function _transfer(address, address, uint256) internal pure override {

        require(false, "AESTHERIUM_Dividend_Tracker: No transfers allowed");
    }
    function withdrawDividend() public pure override {

        require(false, "AESTHERIUM_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main AESTHERIUM contract.");
    }
    function excludeFromDividends(address account) external onlyOwner {

    	require(!excludedFromDividends[account]);

    	excludedFromDividends[account]=true;

    	_setBalance(account, 0);

    	aestheriansMap.remove(account);

    	emit ExcludeFromDividends(account);
    }
    function setTokenBalanceForDividends(uint256 newValue) external onlyOwner {

        require(minimumTokenBalanceForDividends !=newValue, "AESTHERIUM_Dividend_Tracker: minimumTokenBalanceForDividends already the value of 'newValue'.");
       
        minimumTokenBalanceForDividends=newValue;
    } 
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
       
        require(newClaimWait >=3600 && newClaimWait <=86400, "AESTHERIUM_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        
        require(newClaimWait !=claimWait, "AESTHERIUM_Dividend_Tracker: Cannot update claimWait to same value");
        
        emit ClaimWaitUpdated(newClaimWait, claimWait);
       
        claimWait=newClaimWait;
    }
    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }
    function getNumberOfAestherians() external view returns(uint256) {
       
        return aestheriansMap.keys.length;
    }
    function getAccount(address _account)
       
        public view returns (
           
            address account,
           
           int256 index,
           
            int256 iterationsUntilProcessed,
            
            uint256 withdrawableDividends,
           
            uint256 totalDividends,
            uint256 lastClaimTime,
           
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account=_account;

        index=aestheriansMap.getIndexOfKey(account);
        iterationsUntilProcessed=-1;
       
        if(index>=0) {
          
            if(uint256(index)>lastProcessedIndex) {
                iterationsUntilProcessed=index.sub(int256(lastProcessedIndex));
            }
           
            else {
                uint256 processesUntilEndOfArray=aestheriansMap.keys.length > lastProcessedIndex ? aestheriansMap.keys.length.sub(lastProcessedIndex) : 0;
                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }
        withdrawableDividends=withdrawableDividendOf(account);
        totalDividends=accumulativeDividendOf(account);

        lastClaimTime=lastClaimTimes[account];

        nextClaimTime=lastClaimTime>0 ? lastClaimTime.add(claimWait) : 0;
        secondsUntilAutoClaimAvailable=nextClaimTime>block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
    }
    function getAccountAtIndex(uint256 index)
        public view returns (

            address,
            int256,
            int256,
            uint256,

            uint256,
            uint256,

            uint256,
            uint256) {
    	if(index >=aestheriansMap.size()) {
           
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }
        address account=aestheriansMap.getKeyAtIndex(index);
       
        return getAccount(account);
    }
    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	
        if(lastClaimTime > block.timestamp)  {
    		return false;
    	}
    	return block.timestamp.sub(lastClaimTime) >=claimWait;
    }
    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	
        if(excludedFromDividends[account]) {
    		return;
    	}
    	
        if(newBalance >=minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		aestheriansMap.set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		aestheriansMap.remove(account);
    	}
    	processAccount(account, true);
    }
    function process(uint256 gas) public returns (uint256, uint256, uint256) {
    	
        uint256 numberOfAestherians=aestheriansMap.keys.length;
    	
        if(numberOfAestherians == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex=lastProcessedIndex;
    	uint256 gasUsed = 0;
    
    	uint256 gasLeft = gasleft();
    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfAestherians) {
    	
        	_lastProcessedIndex++;
    	
        	if(_lastProcessedIndex >=aestheriansMap.keys.length) {
    			_lastProcessedIndex=0;
    		}
    		address account=aestheriansMap.keys[_lastProcessedIndex];
    	
        	if(canAutoClaim(lastClaimTimes[account])) {
    	
        		if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}

    		iterations++;
    		uint256 newGasLeft=gasleft();
    	
        	if(gasLeft > newGasLeft) {
    			gasUsed=gasUsed.add(gasLeft.sub(newGasLeft));
    		}
    		gasLeft=newGasLeft;
    	}
    	lastProcessedIndex=_lastProcessedIndex;
    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount=_withdrawDividendOfUser(account);
    	
        if(amount > 0) {
    		lastClaimTimes[account]=block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}
    	return false;
    }
}