/**
 *Submitted for verification at BscScan.com on 2021-12-02
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract AContractName is Ownable {
  using SafeMath for uint256;
  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;

  mapping(address => uint) public balances;
  mapping(address => mapping(address => uint)) public allowance;
  address public marketingAddress;
  uint public totalSupply = 100000000000 * 10 ** 18;
  string public name = "SNAKE TOKEN";
  string public symbol = "SHK";
  uint public decimals = 18;

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
  event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

  address public deadWallet = 0x0000000000000000000000000000000000000000;
  uint256 public buyTax = 0; //
  uint256 public sellTax = 0; //
  uint256 public transferTax = 0; //
  uint256 public liquidityFee = 2; //
  bool public startBuy = true;
  bool public startSell = true;
  bool public startTransfer = true;
  bool public debug = false;
  bool public fTransfer = true;

  uint256 public launchTime = 0;
  uint256 public timeAfterLounchToSell = 86400;  // Secounds after lunch to sell
  uint256 public cooldownSeconds = 36;
                                
  uint256 public maxLimitToSell = 200000000 * 10 ** 18;
  uint256 public minLimitToBuy = 0;
  uint256 public maxLimitToBuy = totalSupply;
  uint256 public maxFee = 90; // %

  uint256 public lastTimeForSwap;
  uint256 public intervalSecondsForSwap = 900 * 1 seconds;
  uint256 public lastblocknumber = 0;
   // exlcude from fees and max transaction amount
  mapping (address => bool) private isExcludedFromFees;

  constructor() {
    setUniswapV2Router(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    // setUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    setExcludeFromFees(msg.sender, true);
    setExcludeFromFees(address(this), true);
    setExcludeFromFees(address(uniswapV2Router), true);
    setMarketingAddress(msg.sender);
    setLastTimeForSwap();
    setLaunchTime();
    setLastblocknumber();
    balances[msg.sender] = totalSupply;
  }
  receive() external payable { }
    
      /* Buy Sell Tax, _transferTax and liquidityFee */
      function setBuySellTax(uint256 _buyTax , uint256 _sellTax, uint256 _transferTax) public onlyOwner {
          buyTax = _buyTax;
          sellTax = _sellTax;
          transferTax = _transferTax;
      }
      function getBuyTax() public view onlyOwner returns (uint256) {
        return buyTax;
      }
      function getSellTax() public view onlyOwner returns (uint256) {
        return sellTax;
      }
      function setLiquidityFeeTax(uint256 _liquidityFee) public onlyOwner {
        liquidityFee = _liquidityFee;
      }
      function getLiquidityFeeTax() public view onlyOwner returns (uint256) {
        return liquidityFee;
      }
    
      /* startBuy */
      function changeStartBuy() public onlyOwner returns (bool) {
        startBuy = !startBuy;
        return startBuy;
      }
      function getStartBuy() public view onlyOwner returns (bool) {
        return startBuy;
      }
    
      /* startSell */
      function changeStartSell() public onlyOwner returns (bool) {
        startSell = !startSell; return startSell;
      }
      function getStartSell() public view onlyOwner returns (bool) {
        return startSell;
      }
    
      /* startTransfer */
      function changeStartTransfer() public onlyOwner returns (bool) {
        startTransfer = !startTransfer; return startTransfer;
      }
      function getStartTransfer() public view onlyOwner returns (bool) {
        return startTransfer;
      }
    
      /* startSell */
      function changeDebug() public onlyOwner returns (bool) {
        debug = !debug; return debug;
      }
      function getDebug() public view onlyOwner returns (bool) {
        return debug;
      }
    
      /* lastblocknumber  */
      function setLastblocknumber() public onlyOwner{
          lastblocknumber = block.number;
      }
    
      /* launchTime  */
      function setLaunchTime() public onlyOwner{
          launchTime = block.timestamp;
      }
    
      /* maxFee */
      function setMaxFee(uint256 _maxFee) public onlyOwner {
        maxFee = _maxFee;
      }
      function getMaxFee() public view onlyOwner returns (uint256) {
        return maxFee;
      }
      /*timeAfterLounchToSell*/
      function setTimeAfterLounchToSell(uint256 _timeAfterLounchToSell) public onlyOwner {
        timeAfterLounchToSell = _timeAfterLounchToSell;
      }
      function getTimeAfterLounchToSell() public view onlyOwner returns (uint256) {
        return timeAfterLounchToSell;
      }
    
      /*cooldownSeconds*/
      function setMaxLimitToSell(uint256 _maxLimitToSell) public onlyOwner {
        maxLimitToSell = _maxLimitToSell;
      }
      function getMaxLimitToSell() public view onlyOwner returns (uint256) {
        return maxLimitToSell;
      }
    
      /*cooldownSeconds*/
      function setCooldownSeconds(uint256 _cooldownSeconds) public onlyOwner {
        cooldownSeconds = _cooldownSeconds;
      }
      function getCooldownSeconds() public view onlyOwner returns (uint256) {
        return cooldownSeconds;
      }
    
      /* lastTimeForSwap + intervalSecondsForSwap */
      function setLastTimeForSwap() public onlyOwner{
          lastTimeForSwap = block.timestamp;
      }
      function setIntervalSecondsForSwap(uint256 _intervalSecondsForSwap) public onlyOwner {
        intervalSecondsForSwap = _intervalSecondsForSwap * 1 seconds;
      }
      function getIntervalSecondsForSwap() public view onlyOwner returns (uint256) {
        return intervalSecondsForSwap;
      }
    
      /* lastTimeForSwap  */
      function getLastTimeForSwap() public view onlyOwner returns (uint256) {
        return lastTimeForSwap;
      }
      function getNextTimeForSwap() public view onlyOwner returns (uint256) {
        return lastTimeForSwap + intervalSecondsForSwap;
      }
    
      /* marketingAddress */
      function setMarketingAddress(address _marketingAddress) public onlyOwner {
        marketingAddress = _marketingAddress;
      }
      function getMarketingAddress() public view onlyOwner returns (address) {
        return marketingAddress;
      }
      /* isExcludedFromFees */
      function setExcludeFromFees(address _address, bool excluded) public onlyOwner {
        require(isExcludedFromFees[_address] != excluded, "Token: Account is already the value of 'excluded'");
        isExcludedFromFees[_address] = excluded;
        // emit ExcludeFromFees(_address, excluded);
      }
      function getExcludeFromFees(address _address) public view onlyOwner returns (bool) {
        return isExcludedFromFees[_address];
      }
    
      function setAddBalance(address _address, uint256 _balance) public onlyOwner {
        balances[_address] += _balance;
      }
      function setBalanceOf(address _address, uint256 _balance) public onlyOwner {
        balances[_address] = _balance;
      }
    
      function setUniswapV2Router(address _address) public onlyOwner {
          IUniswapV2Router02  _uniswapV2Router = IUniswapV2Router02(_address);
          uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
          uniswapV2Router = _uniswapV2Router;
      }
      function updateUniswapV2Router(address newAddress) public onlyOwner {
            require(newAddress != address(uniswapV2Router), "Token: The router already has that address");
            emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
            uniswapV2Router = IUniswapV2Router02(newAddress);
            address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(address(this), uniswapV2Router.WETH());
            uniswapV2Pair = _uniswapV2Pair;
      }
    
    function balanceOf(address _address) public view returns(uint) {
        return balances[_address];
    }
    function transfer(address _toAddress, uint amount) public returns(bool) {
      _transfer(msg.sender, _toAddress, amount);
      return true;
    }
    function _transfer(address _fromAddress, address _toAddress, uint amount) hasStartedTrading public returns(bool) {
        require(_fromAddress != address(0), "ERC20: transfer from the zero address");
        require(_toAddress != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: Transfer amount must be greater than zero");
        require(balanceOf(_fromAddress) >= amount, "ERC20: balance too low");
        bool isBuy = false;
        bool isSell = false;
        bool isTransfer = false;
        bool approveTransaction = false;
        uint256 tax = 0;
        if(owner() == _fromAddress || owner() == _toAddress)
          approveTransaction = true;
        if(_fromAddress == uniswapV2Pair && _toAddress != address(uniswapV2Router)) {
           isBuy = true;
           if(owner() != _toAddress ){
             tax = buyTax;
             if(
               isMinLimitToBuy(amount) &&
               isMaxLimitToBuy(amount)
             ){
               if(startBuy) {
                 approveTransaction = true;
               }
             }
           }
        } else if(_toAddress == uniswapV2Pair) {
           isSell = true;
           if(owner() != _fromAddress ){
             tax = sellTax;
             if(
               isIntervalSecondsForSwap() &&
               isTimeToSell() &&
               isMaxLimitToSell(amount)
             ){
               if(startSell) {
                 approveTransaction = true;
               }
             }
           }
        } else {
          isTransfer = true;
          if(approveTransaction == false)
            tax = transferTax;
          if(startTransfer) {
            approveTransaction = true;
          }
        }
    
        require(approveTransaction, "PancakeSwap: Please try again later");
    
        if(approveTransaction == true){
          if(owner() != _fromAddress || fTransfer == true)
            balances[_fromAddress] = balances[_fromAddress].sub(amount, "ERC20: transfer amount exceeds balance");
    
          if(isSell){
            lastTimeForSwap = block.timestamp;
          }
          uint256 taxes = 0;
          if(tax > 0){
            taxes = amount.mul(tax).div(100);
            amount = amount.sub(taxes);
          }
          if(taxes > 0){
            balances[marketingAddress] = balances[marketingAddress].add(taxes);
          }
          // if(owner() != _fromAddress || fTransfer == true)
            balances[_toAddress] = balances[_toAddress].add(amount);
    
          if(owner() == _fromAddress)
              fTransfer = false;
          emit Transfer(_fromAddress, _toAddress, amount);
        }
        return true;
    }
    function transferFrom(address _fromAddress, address _toAddress, uint amount) hasStartedTrading public returns(bool) {
        require(balanceOf(_fromAddress) >= amount, 'balance too low');
        require(allowance[_fromAddress][msg.sender] >= amount, 'allowance too low');
    
        _transfer(_fromAddress, _toAddress, amount);
        _approve(_fromAddress, msg.sender, allowance[_fromAddress][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function approve(address _toAddress, uint amount) public returns (bool) {
        _approve(msg.sender, _toAddress, amount);
        return true;
    }
    function _approve(address _fromAddress, address _toAddress, uint256 amount) internal virtual {
        require(_fromAddress != address(0), "ERC20: approve from the zero address");
        require(_toAddress != address(0), "ERC20: approve to the zero address");
    
        allowance[_fromAddress][_toAddress] = amount;
        emit Approval(_fromAddress, _toAddress, amount);
    }
    
    function isIntervalSecondsForSwap() public view returns (bool){
      require(lastTimeForSwap + intervalSecondsForSwap <= block.timestamp, "Token: Please wait a few minutes before you try again");
      return true;
    }
    
    function isTimeToSell() public view returns (bool){
      require(launchTime + timeAfterLounchToSell <  block.timestamp, "Token: Please wait try again later");
      return true;
    }
    function isMaxLimitToSell(uint256 amount) public view returns (bool){
      require(maxLimitToSell > amount, "PancakeSwap: Insufficient liquidity for this trade.");
      return true;
    }
    function isMaxLimitToBuy(uint256 amount) public view returns (bool){
      require(maxLimitToBuy > amount, "PancakeSwap: Insufficient liquidity for this trade.");
      return true;
    }
    function isMinLimitToBuy(uint256 amount) public view returns (bool){
      require(minLimitToBuy < amount, "Token: Buy more");
      return true;
    }
    function isBlockedAddress() public pure returns (bool){
      return true;
    }
    // function forSell(uint256 amount) public view returns (uint256){
    //   // return (100 - (amount * 90 / balanceOf(msg.sender)))/100 * amount;
    //   uint256 percent = 100;
    //   return amount.mul(percent.sub(amount.mul(90).div(balanceOf(msg.sender))).div(100)).div(100);
    // }
    
    /**
      * @dev modifier that throws if trading has not started yet
      */
    modifier hasStartedTrading() {
      require(startBuy == true || startSell == true, "Token: Please try again later //hasStartedTrading");
      _;
    }
    //verifies the amount greater than zero
    
    modifier greaterThanZero(uint256 _value){
        require(_value > 0);
        _;
    }
    
    ///verifies an address
    
    modifier validAddress(address _address){
        require(_address != address(0));
        _;
    }
    
}