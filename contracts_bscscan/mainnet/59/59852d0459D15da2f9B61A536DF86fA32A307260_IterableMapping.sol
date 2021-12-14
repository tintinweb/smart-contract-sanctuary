/**
 *Submitted for verification at BscScan.com on 2021-12-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
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

    constructor(string memory name_, string memory symbol_) public {
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

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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

/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendPayingToken is ERC20, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;
  uint256 internal magnifiedDividendPerShare;
  uint256 public totalDividendsDistributed;

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  constructor(string memory _name, string memory _symbol) public ERC20(_name, _symbol) {}

  /// @dev Distributes dividends whenever ether is paid to this contract.
  receive() external payable {
    distributeDividends();
  }

  /// @notice Distributes ether to token holders as dividends.
  /// @dev It reverts if the total supply of tokens is 0.
  /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
  /// About undistributed ether:
  ///   In each distribution, there is a small amount of ether not distributed,
  ///     the magnified amount of which is
  ///     `(msg.value * magnitude) % totalSupply()`.
  ///   With a well-chosen `magnitude`, the amount of undistributed ether
  ///     (de-magnified) in a distribution can be less than 1 wei.
  ///   We can actually keep track of the undistributed ether in a distribution
  ///     and try to distribute it in the next distribution,
  ///     but keeping track of such data on-chain costs much more than
  ///     the saved ether, so we don't do that.
  function distributeDividends() public override payable {
    require(totalSupply() > 0);
    if (msg.value > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add((msg.value).mul(magnitude) / totalSupply());
      emit DividendsDistributed(msg.sender, msg.value);
      totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
    }
  }
  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }
  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      (bool success,) = user.call{value: _withdrawableDividend, gas: 3000}("");
      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
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
    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);
    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}

contract EverGain is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    string private _name = "EverGain";
    string private _symbol = "EGN";
    uint8 private _decimals = 18;

    EverGainDividendTracker public dividendTracker;
    
    bool public isTradingEnabled;
    uint256 private _tradingPausedTimestamp;
    // initialSupply is 100 billion
    uint256 constant initialSupply = 100000000000 * (10**18);
    // max wallet is 2% of initialSupply 
    uint256 public maxWalletAmount = initialSupply * 200 / 10000;  
    // max buy and sell tx is 0.2% of initialSupply
    uint256 public maxTxAmount = initialSupply * 20 / 10000; //200_000_000 
    bool private _swapping;
    uint256 public minimumTokensBeforeSwap = 25000000 * (10**18); 
    uint256 public gasForProcessing = 300000;
    uint256 private _liquidityTokensToSwap;
    uint256 private _marketingTokensToSwap;
    uint256 private _buyBackTokensToSwap;
    uint256 private _developmentTokensToSwap;
    uint256 private _holdersTokensToSwap;
    
    address public marketingWallet;
    address public liquidityWallet;
    address public buyBackWallet;
    address public developmentWallet;
    
    struct CustomTaxPeriod {
        bytes23 periodName;
        uint8 blocksInPeriod;
        uint256 timeInPeriod;
        uint256 liquidityFeeOnBuy;
        uint256 liquidityFeeOnSell;
        uint256 marketingFeeOnBuy;
        uint256 marketingFeeOnSell;
        uint256 buyBackFeeOnBuy;
        uint256 buyBackFeeOnSell;
        uint256 developmentFeeOnBuy;
        uint256 developmentFeeOnSell;
        uint256 holdersFeeOnBuy;
        uint256 holdersFeeOnSell;
    }
    // Launch taxes
    bool private _isLanched;
    uint256 private _launchStartTimestamp;
    uint256 private _launchBlockNumber;
    uint256 private _launchSellMaximum =  initialSupply * 20 / 10000;
    CustomTaxPeriod private _launch1 = CustomTaxPeriod('launch1',3,0,10000,0,0,0,0,0,0,0,0,0);
    CustomTaxPeriod private _launch2 = CustomTaxPeriod('launch2',0,3600,100,500,400,500,0,1000,100,500,0,1500);
    CustomTaxPeriod private _launch3 = CustomTaxPeriod('launch3',0,82800,100,400,400,500,0,500,100,300,0,800);

    // Base taxes
    uint256 public liquidityFeeOnBuy = 100;
    uint256 public marketingFeeOnBuy = 300;
    uint256 public holdersFeeOnBuy = 300;
    uint256 public developmentFeeOnBuy = 100;
    uint256 public buyBackFeeOnBuy = 300;

    uint256 public liquidityFeeOnSell = 200;
    uint256 public marketingFeeOnSell = 300;
    uint256 public holdersFeeOnSell = 300;
    uint256 public developmentFeeOnSell = 100;
    uint256 public buyBackFeeOnSell = 300;
   
    // Gain taxes
    uint256 private _gainStartTimestamp;
    CustomTaxPeriod private _gain1 = CustomTaxPeriod('gain1', 0,3600,0,0,100,750,0,750,0,750,0,750);
    CustomTaxPeriod private _gain2 = CustomTaxPeriod('gain2', 0,3600,0,0,0,600,0,600,0,0,0,1200);
    CustomTaxPeriod private _gain3 = CustomTaxPeriod('gain3', 0,3600,0,0,0,450,0,450,0,0,0,900);
    
    uint256 private _blacklistTimeLimit = 21600;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromMaxTransactionLimit;
    mapping (address => bool) private _isExcludedFromMaxWalletLimit;
    mapping (address => bool) private _isBlacklisted;
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => uint256) private _buyTimesInLaunch;

    event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
    event DividendTrackerChange(address indexed newAddress, address indexed oldAddress);
    event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFeesChange(address indexed account, bool isExcluded);
    event LiquidityWalletChange(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event MarketingWalletChange(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    event BuyBackWalletChange(address indexed newBuyBackWallet, address indexed oldBuyBackWallet);
    event DevelopmentWalletChange(address indexed newDevelopmentWallet, address indexed oldDevelopmentWallet);
    event GasForProcessingChange(uint256 indexed newValue, uint256 indexed oldValue);
    event FeeOnSellChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType);
    event FeeOnBuyChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType);
    event CustomTaxPeriodChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType, bytes23 period);
    event BlacklistChange(address indexed holder, bool indexed status);
    event EverGainChange(bool indexed newValue, bool indexed oldValue);
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

    constructor() public ERC20("EverGain", "EverGain") {
        liquidityWallet = address(0x8bbBe00C4bCeD64A018FBA7278f46830F42131d7);
    	marketingWallet = address(0xbe85129abBdE9EC03f0d23B97971320689e0678d);
    	developmentWallet = address(0x013de38C8f7b30f7971F76bB98C3737a2413bB18);
    	buyBackWallet = address(0xEf5da9D5911eDade0a599eBF8133FCbdf216FB08);
    	
    	dividendTracker = new EverGainDividendTracker();
    
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // Testnet
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Mainnet
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
    
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(address(0x000000000000000000000000000000000000dEaD));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        _isExcludedFromMaxTransactionLimit[address(dividendTracker)] = true;
        _isExcludedFromMaxTransactionLimit[address(this)] = true;
        
        _isExcludedFromMaxWalletLimit[_uniswapV2Pair] = true;
        _isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[owner()] = true;
        
        _mint(owner(), initialSupply);
    }
    
    receive() external payable {}
    
    // Setters
    function _getNow() private view returns (uint256) {
        return block.timestamp;
    }
    function launch() public onlyOwner {
        _launchStartTimestamp = _getNow();
        _launchBlockNumber = block.number;
         isTradingEnabled = true;
        _isLanched = true;
    }
    function cancelLaunch() public onlyOwner {
        require(this.isInLaunch(), "EverGain: Launch is not set");
        _launchStartTimestamp = 0;
        _launchBlockNumber = 0;
    }
    function activateTrading() public onlyOwner {
        isTradingEnabled = true;
    }
    function deactivateTrading() public onlyOwner {
        isTradingEnabled = false;
        _tradingPausedTimestamp = _getNow();
    }
    function setEverGain() public onlyOwner {
        require(!this.isInGain(), "EverGain: Gain is already set");
        require(isTradingEnabled, "EverGain: Trading must be enabled first");
        require(!this.isInLaunch(), "EverGain: Must not be in launch period");
        emit EverGainChange(true, false);
        _gainStartTimestamp = _getNow();
    }
    function cancelEverGain() public onlyOwner {
        require(this.isInGain(), "EverGain: Gain is not set");
        emit EverGainChange(false, true);
        _gainStartTimestamp = 0;
    }
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "EverGain: The dividend tracker already has that address");
        EverGainDividendTracker newDividendTracker = EverGainDividendTracker(payable(newAddress));
        require(newDividendTracker.owner() == address(this), "EverGain: The new dividend tracker must be owned by the EverGain token contract");
        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
        emit DividendTrackerChange(newAddress, address(dividendTracker));
        dividendTracker = newDividendTracker;
    }
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "EverGain: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }
        emit AutomatedMarketMakerPairChange(pair, value);
    }
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFee[account] != excluded, "EverGain: Account is already the value of 'excluded'");
        _isExcludedFromFee[account] = excluded;
        emit ExcludeFromFeesChange(account, excluded);
    }
    function excludeFromDividends(address account) public onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }
    function excludeFromMaxTransactionLimit(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromMaxTransactionLimit[account] != excluded, "EverGain: Account is already the value of 'excluded'");
        _isExcludedFromMaxTransactionLimit[account] = excluded;
        emit ExcludeFromMaxTransferChange(account, excluded);
    }
    function excludeFromMaxWalletLimit(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromMaxWalletLimit[account] != excluded, "EverGain: Account is already the value of 'excluded'");
        _isExcludedFromMaxWalletLimit[account] = excluded;
        emit ExcludeFromMaxWalletChange(account, excluded);
    }
    function blacklistAccount(address account) public onlyOwner {
        uint256 currentTimestamp = _getNow();
        require(!_isBlacklisted[account], "EverGain: Account is already blacklisted");
        if (_isLanched) {
            require(currentTimestamp.sub(_launchStartTimestamp) < _blacklistTimeLimit, "EverGain: Time to blacklist accounts has expired");
        }
        _isBlacklisted[account] = true;
        emit BlacklistChange(account, true);
    }
    function unBlacklistAccount(address account) public onlyOwner {
        require(_isBlacklisted[account], "EverGain: Account is not blacklisted");
        _isBlacklisted[account] = false;
        emit BlacklistChange(account, false);
    }
    function setLiquidityWallet(address newAddress) public onlyOwner {
        require(liquidityWallet != newAddress, "EverGain: The liquidityWallet is already that address");
        emit LiquidityWalletChange(newAddress, liquidityWallet);
        liquidityWallet = newAddress;
    }
    function setMarketingWallet(address newAddress) public onlyOwner {
        require(marketingWallet != newAddress, "EverGain: The marketingWallet is already that address");
        emit MarketingWalletChange(newAddress, marketingWallet);
        marketingWallet = newAddress;
    }
    function setBuyBackWallet(address newAddress) public onlyOwner {
        require(buyBackWallet != newAddress, "EverGain: The buyBackWallet is already that address");
        emit BuyBackWalletChange(newAddress, buyBackWallet);
        buyBackWallet = newAddress;
    }
    function setDevelopmentWallet(address newAddress) public onlyOwner {
        require(developmentWallet != newAddress, "EverGain: The developmentWallet is already that address");
        emit DevelopmentWalletChange(newAddress, developmentWallet);
        developmentWallet = newAddress;
    }
    function setLiquidityFeeOnBuy(uint256 newvalue) public onlyOwner {
        require(liquidityFeeOnBuy != newvalue, "EverGain: The liquidityFeeOnBuy is already that value");
        emit FeeOnBuyChange(newvalue, liquidityFeeOnBuy, "liquidityFeeOnBuy");
        liquidityFeeOnBuy = newvalue;
    }
    function setMarketingFeeOnBuy(uint256 newvalue) public onlyOwner {
        require(marketingFeeOnBuy != newvalue, "EverGain: The marketingFeeOnBuy is already that value");
        emit FeeOnBuyChange(newvalue, marketingFeeOnBuy, "marketingFeeOnBuy");
        marketingFeeOnBuy = newvalue;
    }
    function setHolderFeeOnBuy(uint256 newvalue) public onlyOwner {
        require(holdersFeeOnBuy != newvalue, "EverGain: The holdersFeeOnBuy is already that value");
        emit FeeOnBuyChange(newvalue, holdersFeeOnBuy, "holdersFeeOnBuy");
        holdersFeeOnBuy = newvalue;
    }
    function setBuyBackFeeOnBuy(uint256 newvalue) public onlyOwner {
        require(buyBackFeeOnBuy != newvalue, "EverGain: The buyBackFeeOnBuy is already that value");
        emit FeeOnBuyChange(newvalue, buyBackFeeOnBuy, "buyBackFeeOnBuy");
        buyBackFeeOnBuy = newvalue;
    }
    function setDevelopmentFeeOnBuy(uint256 newvalue) public onlyOwner {
        require(developmentFeeOnBuy != newvalue, "EverGain: The developmentFeeOnBuy is already that value");
        emit FeeOnBuyChange(newvalue, developmentFeeOnBuy, "developmentFeeOnBuy");
        developmentFeeOnBuy = newvalue;
    }
    function setLiquidityFeeOnSell(uint256 newvalue) public onlyOwner {
        require(liquidityFeeOnSell != newvalue, "EverGain: The liquidityFeeOnSell is already that value");
        emit FeeOnSellChange(newvalue, liquidityFeeOnSell, "liquidityFeeOnSell");
        liquidityFeeOnSell = newvalue;
    }
    function setMarketingFeeOnSell(uint256 newvalue) public onlyOwner {
        require(marketingFeeOnSell != newvalue, "EverGain: The marketingFeeOnSell is already that value");
        emit FeeOnSellChange(newvalue, marketingFeeOnSell, "marketingFeeOnSell");
        marketingFeeOnSell = newvalue;
    }
    function setHolderFeeOnSell(uint256 newvalue) public onlyOwner {
        require(holdersFeeOnSell != newvalue, "EverGain: The holdersFeeOnSell is already that value");
        emit FeeOnSellChange(newvalue, holdersFeeOnSell, "holdersFeeOnSell");
        holdersFeeOnSell = newvalue;
    }
    function setBuyBackFeeOnSell(uint256 newvalue) public onlyOwner {
        require(buyBackFeeOnSell != newvalue, "EverGain: The buyBackFeeOnSell is already that value");
        emit FeeOnSellChange(newvalue, buyBackFeeOnSell, "buyBackFeeOnSell");
        buyBackFeeOnSell = newvalue;
    }
    function setDevelopmentFeeOnSell(uint256 newvalue) public onlyOwner {
        require(developmentFeeOnSell != newvalue, "EverGain: The developmentFeeOnSell is already that value");
        emit FeeOnSellChange(newvalue, developmentFeeOnSell, "developmentFeeOnSell");
        developmentFeeOnSell = newvalue;
    }
    function setGain1BuyFees(uint256 _liquidityFeeOnBuy,uint256 _marketingFeeOnBuy,uint256 _buyBackFeeOnBuy,uint256 _developmentFeeOnBuy,uint256 _holdersFeeOnBuy) public onlyOwner {
        _setCustomBuyTaxPeriod(_gain1,_liquidityFeeOnBuy, _marketingFeeOnBuy,_buyBackFeeOnBuy,_developmentFeeOnBuy,_holdersFeeOnBuy);
    }
    function setGain1SellFees(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell,uint256 _buyBackFeeOnSell,uint256 _developmentFeeOnSell,uint256 _holdersFeeOnSell) public onlyOwner {
        _setCustomSellTaxPeriod(_gain1,_liquidityFeeOnSell, _marketingFeeOnSell,_buyBackFeeOnSell,_developmentFeeOnSell,_holdersFeeOnSell);
    }
    function setGain2BuyFees(uint256 _liquidityFeeOnBuy,uint256 _marketingFeeOnBuy,uint256 _buyBackFeeOnBuy,uint256 _developmentFeeOnBuy,uint256 _holdersFeeOnBuy) public onlyOwner {
        _setCustomBuyTaxPeriod(_gain2,_liquidityFeeOnBuy, _marketingFeeOnBuy,_buyBackFeeOnBuy,_developmentFeeOnBuy,_holdersFeeOnBuy);
    }
    function setGain2SellFees(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell,uint256 _buyBackFeeOnSell,uint256 _developmentFeeOnSell,uint256 _holdersFeeOnSell) public onlyOwner {
        _setCustomSellTaxPeriod(_gain2,_liquidityFeeOnSell, _marketingFeeOnSell,_buyBackFeeOnSell,_developmentFeeOnSell,_holdersFeeOnSell);
    }
    function setGain3BuyFees(uint256 _liquidityFeeOnBuy,uint256 _marketingFeeOnBuy,uint256 _buyBackFeeOnBuy,uint256 _developmentFeeOnBuy,uint256 _holdersFeeOnBuy) public onlyOwner {
        _setCustomBuyTaxPeriod(_gain3,_liquidityFeeOnBuy, _marketingFeeOnBuy,_buyBackFeeOnBuy,_developmentFeeOnBuy,_holdersFeeOnBuy);
    }
    function setGain3SellFees(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell,uint256 _buyBackFeeOnSell,uint256 _developmentFeeOnSell,uint256 _holdersFeeOnSell) public onlyOwner {
        _setCustomSellTaxPeriod(_gain3,_liquidityFeeOnSell, _marketingFeeOnSell,_buyBackFeeOnSell,_developmentFeeOnSell,_holdersFeeOnSell);
    }
    function setUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "EverGain: The router already has that address");
        emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }
    function setGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "EverGain: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "EverGain: Cannot update gasForProcessing to same value");
        emit GasForProcessingChange(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }
    function setMaxTxAmount(uint256 newValue) public onlyOwner {
        require(newValue != maxTxAmount, "EverGain: Cannot update maxTxAmount to same value");
        emit MaxTransactionAmountChange(newValue, maxTxAmount);
        maxTxAmount = newValue;
    }
    function setMaxWalletAmount(uint256 newValue) public onlyOwner {
        require(newValue != maxWalletAmount, "EverGain: Cannot update maxWalletAmount to same value");
        emit MaxWalletAmountChange(newValue, maxWalletAmount);
        maxWalletAmount = newValue;
    }
    function setMinimumTokensBeforeSwap(uint256 newValue) public onlyOwner {
        require(newValue != minimumTokensBeforeSwap, "EverGain: Cannot update minimumTokensBeforeSwap to same value");
        emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
        minimumTokensBeforeSwap = newValue;
    }
    function setMinimumTokenBalanceForDividends(uint256 newValue) public onlyOwner {
        dividendTracker.setTokenBalanceForDividends(newValue);
    }
    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }
    function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }
    function claim() external {
		dividendTracker.processAccount(payable(msg.sender), false);
    }
    
    // Getters
    function isInGain() external view returns (bool) {
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _gainStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        uint256 totalGainTime = _gain1.timeInPeriod.add(_gain2.timeInPeriod).add(_gain3.timeInPeriod);
        uint256 timeSinceGain = currentTimestamp.sub(_gainStartTimestamp);
        if(timeSinceGain < totalGainTime) {
            return true;
        } else {
            return false;
        }
    }
    function isInLaunch() external view returns (bool) {
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        uint256 timeSinceLaunch = currentTimestamp.sub(_launchStartTimestamp);
        uint256 blocksSinceLaunch = block.number.sub(_launchBlockNumber);
        uint256 totalLaunchTime =  _launch1.timeInPeriod.add(_launch2.timeInPeriod).add(_launch3.timeInPeriod);
        
        if(_isLanched && (timeSinceLaunch < totalLaunchTime || blocksSinceLaunch < _launch1.blocksInPeriod )) {
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
    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
    function getGain1BuyFees() external view returns (uint256, uint256, uint256,uint256, uint256){
        return (_gain1.liquidityFeeOnBuy,_gain1.marketingFeeOnBuy, _gain1.buyBackFeeOnBuy, _gain1.developmentFeeOnBuy, _gain1.holdersFeeOnBuy);
    }
    function getGain1SellFees() external view returns (uint256, uint256, uint256,uint256, uint256){
        return (_gain1.liquidityFeeOnSell,_gain1.marketingFeeOnSell, _gain1.buyBackFeeOnSell, _gain1.developmentFeeOnSell, _gain1.holdersFeeOnSell);
    }
    function getGain2BuyFees() external view returns (uint256, uint256, uint256,uint256, uint256){
        return (_gain2.liquidityFeeOnBuy,_gain2.marketingFeeOnBuy, _gain2.buyBackFeeOnBuy, _gain2.developmentFeeOnBuy, _gain2.holdersFeeOnBuy);
    }
    function getGain2SellFees() external view returns (uint256, uint256, uint256,uint256, uint256){
        return (_gain2.liquidityFeeOnSell,_gain2.marketingFeeOnSell, _gain2.buyBackFeeOnSell, _gain2.developmentFeeOnSell, _gain2.holdersFeeOnSell);
    }
    function getGain3BuyFees() external view returns (uint256, uint256, uint256,uint256, uint256){
        return (_gain3.liquidityFeeOnBuy,_gain3.marketingFeeOnBuy, _gain3.buyBackFeeOnBuy, _gain3.developmentFeeOnBuy, _gain3.holdersFeeOnBuy);
    }
    function getGain3SellFees() external view returns (uint256, uint256, uint256,uint256, uint256){
        return (_gain3.liquidityFeeOnSell,_gain3.marketingFeeOnSell, _gain3.buyBackFeeOnSell, _gain3.developmentFeeOnSell, _gain3.holdersFeeOnSell);
    }
    
    // Main
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        bool isBuyFromLp = automatedMarketMakerPairs[from];
        bool isSelltoLp = automatedMarketMakerPairs[to];
        bool _isInLaunch = this.isInLaunch();
        
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        
        if(from != owner() && to != owner()) {
            require(isTradingEnabled, "EverGain: Trading is currently disabled.");
            require(!_isBlacklisted[to], "EverGain: Account is blacklisted");
            require(!_isBlacklisted[from], "EverGain: Account is blacklisted");
            if (_isInLaunch && currentTimestamp.sub(_launchStartTimestamp) <= 300 && isBuyFromLp) {
                require(currentTimestamp.sub(_buyTimesInLaunch[to]) > 60, "EverGain: Cannot buy more than once per min in first 5min of launch");
            }
            if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[from]) {
                require(amount <= maxTxAmount, "EverGain: Buy amount exceeds the maxTxBuyAmount.");
            }
            if (!_isExcludedFromMaxWalletLimit[to]) {
                require(balanceOf(to).add(amount) <= maxWalletAmount, "EverGain: Expected wallet amount exceeds the maxWalletAmount.");
            }
        }
        
        bool canSwap = balanceOf(address(this)) >= minimumTokensBeforeSwap;
        
        if (
            isTradingEnabled && 
            canSwap &&
            !_swapping &&
            !automatedMarketMakerPairs[from] &&
            from != liquidityWallet && to != liquidityWallet &&
            from != marketingWallet && to != marketingWallet &&
            from != buyBackWallet && to != buyBackWallet &&
            from != developmentWallet && to != developmentWallet
        ) {
            _swapping = true;
            _swapAndLiquify();
            _swapping = false;
        }
        
        bool takeFee = !_swapping && isTradingEnabled;
        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        if (takeFee) {
            (uint256 returnAmount, uint256 fee) = _getCurrentTotalFee(isBuyFromLp, amount);
            amount = returnAmount;
            super._transfer(from, address(this), fee);
        }
        
        if (_isInLaunch && currentTimestamp.sub(_launchStartTimestamp) <= 300) {
            if (to != owner() && isBuyFromLp  && currentTimestamp.sub(_buyTimesInLaunch[to]) > 60) {
                _buyTimesInLaunch[to] = currentTimestamp;
            }
        }
        
        super._transfer(from, to, amount);
        
        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        
        if(!_swapping) {
	    	uint256 gas = gasForProcessing;
	    	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	} 
	    	catch {}
        }
    }
    function _getCurrentTotalFee(bool isBuyFromLp, uint256 amount) internal returns (uint256 returnAmount, uint256 fee) {
        uint256 _liquidityFee = isBuyFromLp ? liquidityFeeOnBuy : liquidityFeeOnSell;
        uint256 _marketingFee = isBuyFromLp ? marketingFeeOnBuy : marketingFeeOnSell;
        uint256 _developmentFee = isBuyFromLp ? developmentFeeOnBuy : developmentFeeOnSell;
        uint256 _buyBackFee = isBuyFromLp ? buyBackFeeOnBuy : buyBackFeeOnSell;
        uint256 _holdersFee = isBuyFromLp ? holdersFeeOnBuy : holdersFeeOnSell;
        
        if (this.isInLaunch()) {
            bool _isInLaunch1Period = _isInLaunch1();
            bool _isInLaunch2Period = _isInLaunch2();
           
            if (isBuyFromLp) {
                _liquidityFee = _isInLaunch1Period ? _launch1.liquidityFeeOnBuy : _liquidityFee;
            }
            else {
                _liquidityFee = _isInLaunch1Period ? _liquidityFee : _isInLaunch2Period ? _launch2.liquidityFeeOnSell : _launch3.liquidityFeeOnSell;
                _marketingFee = _isInLaunch1Period ? _marketingFee : _isInLaunch2Period ? _launch2.marketingFeeOnSell : _launch3.marketingFeeOnSell;
                _buyBackFee = _isInLaunch1Period ? _buyBackFee : _isInLaunch2Period ? _launch2.buyBackFeeOnSell : _launch3.buyBackFeeOnSell;
                _holdersFee = _isInLaunch1Period ? _holdersFee : _isInLaunch2Period ? _launch2.holdersFeeOnSell : _launch3.holdersFeeOnSell;
            }
        }
        if (this.isInGain()) {
            if (_isInGain1()) {
                _liquidityFee = isBuyFromLp && _gain1.liquidityFeeOnBuy > 0 ? _gain1.liquidityFeeOnBuy : !isBuyFromLp && _gain1.liquidityFeeOnSell > 0 ? _gain1.liquidityFeeOnSell : _liquidityFee;
                _marketingFee = isBuyFromLp && _gain1.marketingFeeOnBuy > 0 ? _gain1.marketingFeeOnBuy : !isBuyFromLp && _gain1.marketingFeeOnSell > 0 ? _gain1.marketingFeeOnSell : _marketingFee;
                _buyBackFee = isBuyFromLp && _gain1.buyBackFeeOnBuy > 0 ? _gain1.buyBackFeeOnBuy : !isBuyFromLp && _gain1.buyBackFeeOnSell > 0 ? _gain1.buyBackFeeOnSell : _buyBackFee;
                _developmentFee = isBuyFromLp && _gain1.developmentFeeOnBuy > 0 ? _gain1.developmentFeeOnBuy : !isBuyFromLp && _gain1.developmentFeeOnSell > 0 ? _gain1.developmentFeeOnSell : _developmentFee;
                _holdersFee = isBuyFromLp && _gain1.holdersFeeOnBuy > 0 ? _gain1.holdersFeeOnBuy : !isBuyFromLp && _gain1.holdersFeeOnSell > 0 ? _gain1.holdersFeeOnSell : _holdersFee;
            }
            else if (_isInGain2()) {
                _liquidityFee = isBuyFromLp && _gain2.liquidityFeeOnBuy > 0 ? _gain2.liquidityFeeOnBuy : !isBuyFromLp && _gain2.liquidityFeeOnSell > 0 ? _gain2.liquidityFeeOnSell : _liquidityFee;
                _marketingFee = isBuyFromLp && _gain2.marketingFeeOnBuy > 0 ? _gain2.marketingFeeOnBuy : !isBuyFromLp && _gain2.marketingFeeOnSell > 0 ? _gain2.marketingFeeOnSell : _marketingFee;
                _buyBackFee = isBuyFromLp && _gain2.buyBackFeeOnBuy > 0 ? _gain2.buyBackFeeOnBuy : !isBuyFromLp && _gain2.buyBackFeeOnSell > 0 ? _gain2.buyBackFeeOnSell : _buyBackFee;
                _developmentFee = isBuyFromLp && _gain2.developmentFeeOnBuy > 0 ? _gain2.developmentFeeOnBuy : !isBuyFromLp && _gain2.developmentFeeOnSell > 0 ? _gain2.developmentFeeOnSell : _developmentFee;
                _holdersFee = isBuyFromLp && _gain2.holdersFeeOnBuy > 0 ? _gain2.holdersFeeOnBuy : !isBuyFromLp && _gain2.holdersFeeOnSell > 0 ? _gain2.holdersFeeOnSell : _holdersFee;
            }
            else {
                _liquidityFee = isBuyFromLp && _gain3.liquidityFeeOnBuy > 0 ? _gain3.liquidityFeeOnBuy : !isBuyFromLp && _gain3.liquidityFeeOnSell > 0 ? _gain3.liquidityFeeOnSell : _liquidityFee;
                _marketingFee = isBuyFromLp && _gain3.marketingFeeOnBuy > 0 ? _gain3.marketingFeeOnBuy : !isBuyFromLp && _gain3.marketingFeeOnSell > 0 ? _gain3.marketingFeeOnSell : _marketingFee;
                _buyBackFee = isBuyFromLp && _gain3.buyBackFeeOnBuy > 0 ? _gain3.buyBackFeeOnBuy : !isBuyFromLp && _gain3.buyBackFeeOnSell > 0 ? _gain3.buyBackFeeOnSell : _buyBackFee;
                _developmentFee = isBuyFromLp && _gain3.developmentFeeOnBuy > 0 ? _gain3.developmentFeeOnBuy : !isBuyFromLp && _gain3.developmentFeeOnSell > 0 ? _gain3.developmentFeeOnSell : _developmentFee;
                _holdersFee = isBuyFromLp && _gain3.holdersFeeOnBuy > 0 ? _gain3.holdersFeeOnBuy : !isBuyFromLp && _gain3.holdersFeeOnSell > 0 ? _gain3.holdersFeeOnSell : _holdersFee;
            }
        }
        
        uint256 _totalFee = _liquidityFee.add(_marketingFee).add(_developmentFee).add(_buyBackFee).add(_holdersFee);

        fee = amount.mul(_totalFee).div(10000);
    	returnAmount = amount.sub(fee);
    	_updateTokensToSwap(amount, _liquidityFee,_marketingFee, _buyBackFee, _developmentFee, _holdersFee);
    	return (returnAmount, fee);
    }
    function _updateTokensToSwap(uint256 amount, uint256 liquidityFee,uint256 marketingFee, uint256 buyBackFee, uint256 developmentFee, uint256 holdersFee) private {
        _liquidityTokensToSwap = _liquidityTokensToSwap.add(amount.mul(liquidityFee).div(10000));
    	_marketingTokensToSwap = _marketingTokensToSwap.add(amount.mul(marketingFee).div(10000));
    	_buyBackTokensToSwap = _buyBackTokensToSwap.add(amount.mul(buyBackFee).div(10000));
    	_developmentTokensToSwap = _developmentTokensToSwap.add(amount.mul(developmentFee).div(10000));
    	_holdersTokensToSwap = _holdersTokensToSwap.add(amount.mul(holdersFee).div(10000));
    }
    function _isInLaunch1() internal view returns(bool) {
        uint256 blocksSinceLaunch = block.number.sub(_launchBlockNumber);
        if(blocksSinceLaunch < _launch1.blocksInPeriod) {
            return true;
        } else {
            return false;
        }
    }
    function _isInLaunch2() internal view returns(bool) {
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        uint256 blocksSinceLaunch = block.number.sub(_launchBlockNumber);
        uint256 timeSinceLaunch = currentTimestamp.sub(_launchStartTimestamp);
        if (timeSinceLaunch < _launch1.timeInPeriod && blocksSinceLaunch > _launch1.blocksInPeriod ) {
            return true;
        } else {
            return false;
        }
    }
    function _isInLaunch3() internal view returns(bool) {
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        uint256 timeSinceLaunch = currentTimestamp.sub(_launchStartTimestamp);
        uint256 blocksSinceLaunch = block.number.sub(_launchBlockNumber);
        uint256 timeInLaunch = _launch3.timeInPeriod.add(_launch2.timeInPeriod);
        if (timeSinceLaunch > _launch2.timeInPeriod && timeSinceLaunch < timeInLaunch && blocksSinceLaunch > _launch1.blocksInPeriod) {
            return true;
        } else {
            return false;
        }
    }
    function _isInGain1() internal view returns (bool) {
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _gainStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        uint256 timeSinceGain = currentTimestamp.sub(_gainStartTimestamp);
        if(timeSinceGain < _gain1.timeInPeriod) {
            return true;
        } else {
            return false;
        }
    }
    function _isInGain2() internal view returns (bool) {
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _gainStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        uint256 timeSinceGain = currentTimestamp.sub(_gainStartTimestamp);
        if(timeSinceGain > _gain1.timeInPeriod && timeSinceGain < _gain1.timeInPeriod.add(_gain2.timeInPeriod)) {
            return true;
        } else {
            return false;
        }
    }
    function _isInGain3() internal view returns (bool) {
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _gainStartTimestamp  ? _tradingPausedTimestamp : _getNow();
        uint256 timeSinceGain = currentTimestamp.sub(_gainStartTimestamp);
        uint256 totalTimeInGain1 = _gain1.timeInPeriod.add(_gain2.timeInPeriod);
        uint256 totalTimeInGain2 = _gain1.timeInPeriod.add(_gain2.timeInPeriod).add(_gain3.timeInPeriod);
        if(timeSinceGain > totalTimeInGain1 && timeSinceGain < totalTimeInGain2) {
            return true;
        } else {
            return false;
        }
    }
    function _setCustomSellTaxPeriod(CustomTaxPeriod storage map,
        uint256 _liquidityFeeOnSell,
        uint256 _marketingFeeOnSell,
        uint256 _buyBackFeeOnSell,
        uint256 _developmentFeeOnSell,
        uint256 _holdersFeeOnSell
        ) private {
        if (map.liquidityFeeOnSell != _liquidityFeeOnSell) {
            emit CustomTaxPeriodChange(_liquidityFeeOnSell, map.liquidityFeeOnSell, 'liquidityFeeOnSell', map.periodName);
            map.liquidityFeeOnSell = _liquidityFeeOnSell;
        }
        if (map.marketingFeeOnSell != _marketingFeeOnSell) {
            emit CustomTaxPeriodChange(_marketingFeeOnSell, map.marketingFeeOnSell, 'marketingFeeOnSell', map.periodName);
            map.marketingFeeOnSell = _marketingFeeOnSell;
        }
        if (map.buyBackFeeOnSell != _buyBackFeeOnSell) {
            emit CustomTaxPeriodChange(_buyBackFeeOnSell, map.buyBackFeeOnSell, 'buyBackFeeOnSell', map.periodName);
            map.buyBackFeeOnSell = _buyBackFeeOnSell;
        }
        if (map.developmentFeeOnSell != _developmentFeeOnSell) {
            emit CustomTaxPeriodChange(_developmentFeeOnSell, map.developmentFeeOnSell, 'developmentFeeOnSell', map.periodName);
            map.developmentFeeOnSell = _developmentFeeOnSell;
        }
        if (map.holdersFeeOnSell != _holdersFeeOnSell) {
            emit CustomTaxPeriodChange(_holdersFeeOnSell, map.holdersFeeOnSell, 'holdersFeeOnSell', map.periodName);
            map.holdersFeeOnSell = _holdersFeeOnSell;
        }
    }
    function _setCustomBuyTaxPeriod(CustomTaxPeriod storage map,
        uint256 _liquidityFeeOnBuy,
        uint256 _marketingFeeOnBuy,
        uint256 _buyBackFeeOnBuy,
        uint256 _developmentFeeOnBuy,
        uint256 _holdersFeeOnBuy
        ) private {
        if (map.liquidityFeeOnBuy != _liquidityFeeOnBuy) {
            emit CustomTaxPeriodChange(_liquidityFeeOnBuy, map.liquidityFeeOnBuy, 'liquidityFeeOnBuy', map.periodName);
            map.liquidityFeeOnBuy = _liquidityFeeOnBuy;
        }
        if (map.marketingFeeOnBuy != _marketingFeeOnBuy) {
            emit CustomTaxPeriodChange(_marketingFeeOnBuy, map.marketingFeeOnBuy, 'marketingFeeOnBuy', map.periodName);
            map.marketingFeeOnBuy = _marketingFeeOnBuy;
        }
        if (map.buyBackFeeOnBuy != _buyBackFeeOnBuy) {
            emit CustomTaxPeriodChange(_buyBackFeeOnBuy, map.buyBackFeeOnBuy, 'buyBackFeeOnBuy', map.periodName);
            map.buyBackFeeOnBuy = _buyBackFeeOnBuy;
        }
        if (map.developmentFeeOnBuy != _developmentFeeOnBuy) {
            emit CustomTaxPeriodChange(_developmentFeeOnBuy, map.developmentFeeOnBuy, 'developmentFeeOnBuy', map.periodName);
            map.developmentFeeOnBuy = _developmentFeeOnBuy;
        }
        if (map.holdersFeeOnBuy != _holdersFeeOnBuy) {
            emit CustomTaxPeriodChange(_holdersFeeOnBuy, map.holdersFeeOnBuy, 'holdersFeeOnBuy', map.periodName);
            map.holdersFeeOnBuy = _holdersFeeOnBuy;
        }
    }
    function _swapAndLiquify() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _liquidityTokensToSwap.add(_marketingTokensToSwap).add(_developmentTokensToSwap).add(_buyBackTokensToSwap).add(_holdersTokensToSwap);
        
        // Halve the amount of liquidity tokens
        uint256 tokensInEverGainForLiquidity = _liquidityTokensToSwap.div(2);
        uint256 amountToSwapForBNB = contractBalance.sub(tokensInEverGainForLiquidity);
        
        // initial BNB balance
        uint256 initialBNBBalance = address(this).balance;
        // Swap the EverGain for BNB
        _swapTokensForBNB(amountToSwapForBNB); 
        // Get the balance, minus what we started with
        uint256 bnbBalance = address(this).balance.sub(initialBNBBalance);
        // Divvy up the BNB based on accrued tokens as % of total accrued
        uint256 bnbForMarketing = bnbBalance.mul(_marketingTokensToSwap).div(totalTokensToSwap);
        uint256 bnbForBuyBack = bnbBalance.mul(_buyBackTokensToSwap).div(totalTokensToSwap);
        uint256 bnbForDevelopment = bnbBalance.mul(_developmentTokensToSwap).div(totalTokensToSwap);
        uint256 bnbForHolders = bnbBalance.mul(_holdersTokensToSwap).div(totalTokensToSwap);
        uint256 bnbForLiquidity = bnbBalance.sub(bnbForMarketing).sub(bnbForBuyBack).sub(bnbForDevelopment).sub(bnbForHolders);
        
        _liquidityTokensToSwap = 0;
        _marketingTokensToSwap = 0;
        _developmentTokensToSwap = 0;
        _buyBackTokensToSwap = 0;
        _holdersTokensToSwap = 0;
        
        payable(buyBackWallet).transfer(bnbForBuyBack);
        payable(developmentWallet).transfer(bnbForDevelopment);
        payable(marketingWallet).transfer(bnbForMarketing);
        
        _addLiquidity(tokensInEverGainForLiquidity, bnbForLiquidity);
        emit SwapAndLiquify(amountToSwapForBNB, bnbForLiquidity, tokensInEverGainForLiquidity);
        
        (bool success,) = address(dividendTracker).call{value: bnbForHolders}("");
        if(success) {
   	 		emit DividendsSent(bnbForHolders);
        }
    }
    function _swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
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
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }
}


contract EverGainDividendTracker is DividendPayingToken, Ownable {
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
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public DividendPayingToken("EverGain_Dividend_Tracker", "EverGain_Dividend_Tracker") {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 5000000 * (10**18); 
    }
    function _transfer(address, address, uint256) internal override {
        require(false, "EverGain_Dividend_Tracker: No transfers allowed");
    }
    function withdrawDividend() public override {
        require(false, "EverGain_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main EverGain contract.");
    }
    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;
    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);
    	emit ExcludeFromDividends(account);
    }
    function setTokenBalanceForDividends(uint256 newValue) external onlyOwner {
        require(minimumTokenBalanceForDividends != newValue, "EverGain_Dividend_Tracker: minimumTokenBalanceForDividends already the value of 'newValue'.");
        minimumTokenBalanceForDividends = newValue;
    } 
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "EverGain_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "EverGain_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }
    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }
    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
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
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);
        iterationsUntilProcessed = -1;
        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
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
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }
        address account = tokenHoldersMap.getKeyAtIndex(index);
        return getAccount(account);
    }
    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}
    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }
    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}
    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}
    	processAccount(account, true);
    }
    function process(uint256 gas) public returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;
    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = lastProcessedIndex;
    	uint256 gasUsed = 0;
    	uint256 gasLeft = gasleft();
    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;
    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}
    		address account = tokenHoldersMap.keys[_lastProcessedIndex];
    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}

    		iterations++;
    		uint256 newGasLeft = gasleft();
    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}
    		gasLeft = newGasLeft;
    	}
    	lastProcessedIndex = _lastProcessedIndex;
    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);
    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}
    	return false;
    }
}