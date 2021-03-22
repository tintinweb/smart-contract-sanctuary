// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
//import "pancakeswap-peripheral/contracts/interfaces/IPancakeRouter02.sol";
//import "@BakeryProject/bakery-swap-periphery/contracts/interfaces/IBakerySwapRouter.sol";
//import "@BakeryProject/bakery-swap-core/contracts/interfaces/IBakerySwapFactory.sol";

contract ERC20Fee is Context, IERC20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  uint256 private _totalSupply;
  string private _name;
  string private _symbol;

  constructor(string memory name, string memory symbol) public {
    _name = name;
    _symbol = symbol;
    _mint(_msgSender(), 100000000000000000000000000000000);
  }
  function name() public view virtual returns (string memory) {
    return _name;
  }
  function symbol() public view virtual returns (string memory) {
    return _symbol;
  }
  function decimals() public view virtual returns (uint8) {
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
  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    _approve(sender, _msgSender(), currentAllowance - amount);

    return true;
  }
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));

    return true;
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

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    _balances[account] = accountBalance.sub(amount);
    _totalSupply = _totalSupply.sub(amount);

    emit Transfer(account, address(0), amount);
  }
  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

  //----------------------------------------------------------------------------------------------------

  uint256 public feePercentage = 1;
  uint256 public burnPercentage = 50;
  address public burnAddress = address(0x000000000000000000000000000000000000dEaD);
  address public routerAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  address public factoryAddress = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
  address public lpAddress = address(0);
  address public wethAddress = address(0);
  address public oppositeAddress = address(0);
  address[] public buybackPath;

  mapping (address => bool) private _isExcluded;

  event Buyback(address buybackToken, uint256 inputAmount);
  event BuybackFailed(address buybackToken, uint256 inputAmount);
  event Burn(uint256 amount);
  event BurnAddressChanged(address _address);
  event RouterAddressChanged(address _address);
  event WETHAddressChanged(address _address);
  event FactoryAddressChanged(address _address);
  event LPAddressChanged(address _address);
  event OppositeAddressChanged(address _address);
  event FeePercentageChanged(uint256 newPercentage);
  event BurnPercentageChanged(uint256 newPercentage);

  event Log(string msg);

  /**
   * @dev Sets the value for {feePercentage}
   */
  function setFeePercentage(uint256 _feePercentage) public onlyOwner {
    require(msg.sender == owner(), "setFeePercentage: FORBIDDEN");
    require(_feePercentage < 100, "setFeePercentage: fee can't be >=100%");
    feePercentage = _feePercentage;
    emit FeePercentageChanged(feePercentage);
  }

  /**
   * @dev Sets the value for {burnPercentage}
   */
  function setBurnPercentage(uint256 _burnPercentage) public onlyOwner {
    require(msg.sender == owner(), "setBurnPercentage: FORBIDDEN");
    require(_burnPercentage <= 100, "setBurnPercentage: burn can't be >100%");
    burnPercentage = _burnPercentage;
    emit BurnPercentageChanged(burnPercentage);
  }

  /**
   * @dev Sets the value for {burnAddress}
   */
  function setBurnAddress(address _address) public onlyOwner {
    require(msg.sender == owner(), "setBurnAddress: FORBIDDEN");
    require(_address != address(0), "setBurnAddress: address can't be the zero address");
    burnAddress = _address;
    emit BurnAddressChanged(burnAddress);
  }

  /**
   * @dev Sets the value for {routerAddress}
   */
  function setRouterAddress(address _address) public onlyOwner {
    require(msg.sender == owner(), "setRouterAddress: FORBIDDEN");
    require(_address != address(0), "setRouterAddress: address can't be the zero address");
    routerAddress = _address;
    buybackPath = [address(this), wethAddress, oppositeAddress];
    emit RouterAddressChanged(routerAddress);
  }

  /**
   * @dev Sets the value for {wethAddress}
   */
  function setWETHAddress(address _address) public onlyOwner {
    require(msg.sender == owner(), "setWETHAddress: FORBIDDEN");
    require(_address != address(0), "setWETHAddress: address can't be the zero address");
    wethAddress = _address;
    buybackPath = [address(this), wethAddress, oppositeAddress];
    emit WETHAddressChanged(wethAddress);
  }

  /**
   * @dev Sets the value for {oppositeAddress}
   */
  function setOppositeAddress(address _address) public onlyOwner {
    require(msg.sender == owner(), "setOppositeAddress: FORBIDDEN");
    require(_address != address(0), "setOppositeAddress: address can't be the zero address");
    oppositeAddress = _address;
    buybackPath = [address(this), wethAddress, oppositeAddress];
    emit OppositeAddressChanged(oppositeAddress);
  }

  /**
   * @dev Sets the value for {factoryAddress}
   */
  function setFactoryAddress(address _address) public onlyOwner {
    require(msg.sender == owner(), "setOppositeAddress: FORBIDDEN");
    require(_address != address(0), "setOppositeAddress: address can't be the zero address");
    factoryAddress = _address;
    emit FactoryAddressChanged(factoryAddress);
  }

  /**
   * @dev Sets the value for {lpAddress}
   */
  function setLPAddress(address _address) public onlyOwner {
    require(msg.sender == owner(), "setOppositeAddress: FORBIDDEN");
    require(_address != address(0), "setOppositeAddress: address can't be the zero address");
    lpAddress = _address;
    emit LPAddressChanged(lpAddress);
  }

  function _getPair() private returns (address) {
    require(wethAddress == address(0), "getPair: wethAddress can't be the zero address");
    require(factoryAddress == address(0), "getPair: factoryAddress can't be the zero address");
    IUniswapV2Factory factory = IUniswapV2Factory(factoryAddress);
    return factory.getPair(address(this), wethAddress);
  }

  function isExcluded(address account) public view returns (bool) {
    return _isExcluded[account];
  }

  function excludeAccount(address _address) external onlyOwner {
    require(msg.sender == owner(), "excludeAccount: FORBIDDEN");
    require(!_isExcluded[_address], "excludeAccount: account is already excluded");
    _isExcluded[_address] = true;
  }

  function includeAccount(address _address) external onlyOwner {
    require(msg.sender == owner(), "includeAccount: FORBIDDEN");
    require(_isExcluded[_address], "includeAccount: account is not excluded");
    _isExcluded[_address] = false;
  }

  /*function triggerBuyback(uint256 amount) public onlyOwner {
    require(msg.sender == owner(), "triggerBuyback: FORBIDDEN");
    require(oppositeAddress == address(0), "triggerBuyback: oppositeAddress can't be the zero address")
    require(wethAddress == address(0), "triggerBuyback: wethAddress can't be the zero address")
    require(routerAddress == address(0), "triggerBuyback: routerAddress can't be the zero address")
    require(factoryAddress == address(0), "triggerBuyback: factoryAddress can't be the zero address")
    require(lpAddress == address(0), "triggerBuyback: lpAddress can't be the zero address")
    require(_buyback(amount), "triggerBuyback: buyback failed");
  }


  function triggerBuyback() public onlyOwner {
    triggerBuyback(_balances[address(this)]);
  }*/

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "_transfer: transfer from the zero address");
    require(recipient != address(0), "_transfer: transfer to the zero address");
    require(amount > 0, "_transfer: transfer amount must be greater than zero");
    require(_balances[sender] >= amount, "_transfer: transfer amount exceeds balance");
    if (feePercentage == 0 ||
        _isExcluded[sender] ||
          recipient == burnAddress ||
            sender == routerAddress ||
              recipient == routerAddress ||
                sender == lpAddress ||
                  recipient == lpAddress
       ) {
         emit Log("do _transferExcluded");
         _transferExcluded(sender, recipient, amount);
         if (recipient == burnAddress) {
           emit Burn(amount);
         }
       } else {
         emit Log("do _transferStandard");
         _transferStandard(sender, recipient, amount);
       }
  }

  function _transferStandard(address sender, address recipient, uint256 amount) private {
    uint256 fee = amount.mul(feePercentage).div(100);
    uint256 burn = fee.mul(burnPercentage).div(100);
    uint256 buyback = fee.sub(burn, "_transferStandard: fee exeeds amount");
    _transferExcluded(sender, recipient, amount.sub(fee, "_transferStandard: fee exeeds amount"));
    _transferExcluded(sender, burnAddress, burn);
    emit Burn(burn);
    if (buyback > 0 && !_triggerBuyback(sender, buyback)) {
      _transferExcluded(address(this), burnAddress, buyback);
      emit Burn(burn);
    }
  }

  function _transferExcluded(address sender, address recipient, uint256 amount) private {
    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, "_transferExcluded: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _triggerBuyback(address sender, uint256 amount) private returns (bool success) {
    if (oppositeAddress == address(0) ||
        wethAddress == address(0) ||
          routerAddress == address(0) ||
            factoryAddress == address(0) ||
              lpAddress == address(0)
       ) {
         emit BuybackFailed(oppositeAddress, amount);
         return false;
       }

       _transferExcluded(sender, address(this), amount);
       return _buyback(amount);
  }

  function _buyback(uint256 amount) private returns (bool success) {
    require(_balances[address(this)] >= amount, "_buyback: buyback amount exceeds balance");
    IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
    emit Log("try router.swapExactTokensForTokens");
    try router.swapExactTokensForTokens(amount, 0, buybackPath, burnAddress, block.timestamp + 150) {
      emit Buyback(oppositeAddress, amount);
      return true;
    } catch {
      emit BuybackFailed(oppositeAddress, amount);
      return false;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ERC20Fee.sol";

contract Yang is ERC20Fee('Yang', 'YANG') {}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity >=0.5.0;

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

pragma solidity >=0.6.2;

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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