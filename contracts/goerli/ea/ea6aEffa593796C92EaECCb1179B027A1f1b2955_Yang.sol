// SPDX-License-Identifier: GPL3

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract Master is Context, IERC20, Ownable, Pausable {

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  uint256 private _totalSupply;
  string private _name;
  string private _symbol;

  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;

    _mint(address(this), 10**18 * 100000000000000);

    routerUni = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    lpPairUni = IUniswapV2Pair(IUniswapV2Factory(routerUni.factory()).createPair(address(this), routerUni.WETH()));
    _approve(address(this), address(routerUni), _totalSupply);
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
    return _balances[account] + _vaultBalance[account];
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
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    _approve(_msgSender(), spender, currentAllowance - subtractedValue);

    return true;
  }
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);
  }
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    _balances[account] = accountBalance - amount;
    _totalSupply -= amount;

    emit Transfer(account, address(0), amount);
  }
  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
    require(!paused(), "ERC20Pausable: token transfer while paused");
  }

  //----------------------------------------------------------------------------------------------------

  uint256 public feePercentage = 100;
  uint256 public lpHolderAmount = 1;
  uint256 public lpHolderFee = 5000;
  uint256 public burnPercentage = 4000;
  uint256 public vaultPercentage = 1000;
  address public burnAddress = address(0x000000000000000000000000000000000000dEaD);
  address public oppositeAddress = address(0);
  address[] public buybackPath;

  IUniswapV2Router02 public routerUni;
  IUniswapV2Pair public lpPairUni;

  mapping (address => bool) private _isExcluded;

  uint256 public vault;
  uint256 public _blocksPerAP = 1000;
  address[] private _allocPointAddresses;
  mapping (address => uint256) private _allocPoints;
  mapping (address => uint256) private _vaultBalance;

  event Buyback(uint256 inputAmount, uint256 outputAmount);
  event BuybackFailed(uint256 inputAmount, string msg);
  event Burn(uint256 amount);
  event OppositeAddressChanged(address _address);
  event FeePercentageChanged(uint256 newPercentage);
  event LPHolderAmountChanged(uint256 newPercentage);
  event LPHolderFeeChanged(uint256 newPercentage);
  event BurnPercentageChanged(uint256 newPercentage);

  /**
  * @dev Sets the value for {lpHolderAmount}
  */
  function setLPHolderAmount(uint256 _lpHolderAmount) public onlyOwner {
    require(msg.sender == owner(), "setLPHolderAmount: FORBIDDEN");
    require(_lpHolderAmount > 0, "setLPHolderAmount: lpHolderAmount can't be 0");
    lpHolderAmount = _lpHolderAmount;
    emit LPHolderAmountChanged(lpHolderAmount);
  }

  /**
  * @dev Sets the value for {lpHolderFee}
  */
  function setLPHolderFee(uint256 _lpHolderFee) public onlyOwner {
    require(msg.sender == owner(), "setLPHolderFee: FORBIDDEN");
    require(_lpHolderFee < 10000, "setLPHolderFee: fee can't be >=100%");
    require(_lpHolderFee > 0, "setLPHolderFee: fee can't be 0%");
    lpHolderFee = _lpHolderFee;
    emit LPHolderFeeChanged(lpHolderFee);
  }

  /**
  * @dev Sets the value for {feePercentage}
   */
  function setFeePercentage(uint256 _feePercentage) public onlyOwner {
    require(msg.sender == owner(), "setFeePercentage: FORBIDDEN");
    require(_feePercentage < 10000, "setFeePercentage: fee can't be >=100%");
    require(_feePercentage > 0, "setFeePercentage: fee can't be 0%");
    feePercentage = _feePercentage;
    emit FeePercentageChanged(feePercentage);
  }

  /**
  * @dev Sets the value for {burnPercentage}
  */
  function setBurnPercentage(uint256 _burnPercentage) public onlyOwner {
    require(msg.sender == owner(), "setBurnPercentage: FORBIDDEN");
    require(_burnPercentage <= 10000, "setBurnPercentage: burnPercentage can't be >100%");
    burnPercentage = _burnPercentage;
    emit BurnPercentageChanged(burnPercentage);
  }

  /**
  * @dev Sets the value for {oppositeAddress}
  */
  function setOppositeAddress(address _address) public onlyOwner {
    require(msg.sender == owner(), "setOppositeAddress: FORBIDDEN");
    require(_address != address(0), "setOppositeAddress: address can't be the zero address");
    oppositeAddress = _address;
    buybackPath = [address(this), routerUni.WETH(), oppositeAddress];
    emit OppositeAddressChanged(oppositeAddress);
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

  function addLiquidity() public payable onlyOwner {
    routerUni.addLiquidityETH{value: msg.value}(address(this), _totalSupply, _totalSupply, msg.value, burnAddress, block.timestamp + 1200);
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "_transfer: transfer from the zero address");
    require(recipient != address(0), "_transfer: transfer to the zero address");
    require(amount > 0, "_transfer: transfer amount must be greater than zero");
    require(_balances[sender] >= amount, "_transfer: transfer amount exceeds balance");

    if (feePercentage == 0 ||
        sender == address(this) ||
          _isExcluded[sender] ||
            recipient == address(0) ||
              sender == address(routerUni) ||
                recipient == address(routerUni) ||
                  sender == address(lpPairUni) ||
                    recipient == address(lpPairUni)) {
      _transferExcluded(sender, recipient, amount);
    if (recipient == burnAddress) {
      emit Burn(amount);
    }
    } else if (lpPairUni.balanceOf(sender) >= lpHolderAmount) {
      _transferStandard(sender, recipient, amount, feePercentage * lpHolderFee / 10000);
    } else {
      _transferStandard(sender, recipient, amount, feePercentage);
    }
  }

  function _transferStandard(address sender, address recipient, uint256 amount, uint256 _fee) private {
    require(sender != address(0), "_transferStandard: transfer from the zero address");
    uint256 fee = amount * _fee / 10000;
    uint256 burn = fee * burnPercentage / 10000;
    uint256 vaultA = fee * vaultPercentage / 10000;
    uint256 buyback = fee - burn;
    _transferExcluded(sender, recipient, amount - fee);
    _transferExcluded(sender, burnAddress, burn);
    vault += vaultA;
    _transferExcluded(sender, address(this), vaultA);
    emit Burn(burn);
    if (buyback > 0 && !_buyback(sender, buyback)) {
      _transferExcluded(address(this), burnAddress, buyback);
      emit Burn(buyback);
    }
  }

  function _transferExcluded(address sender, address recipient, uint256 amount) private {
    require(sender != address(0), "_transferExcluded: transfer from the zero address");
    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "_transferExcluded: transfer amount exceeds balance");
    _balances[sender] = senderBalance - amount;
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);

    if (sender != address(this) &&
        !_isExcluded[sender] &&
          sender != address(routerUni) &&
            sender != address(lpPairUni)) {
      if (_balances[sender] > 0) {
        _allocPoints[sender] = block.number;
        bool exists = false;
        for (uint256 i = 0; i < _allocPointAddresses.length; i++) {
          if (_allocPointAddresses[i] == sender) {
            exists = true;
            break;
          }
        }
        if (!exists) {
          _allocPointAddresses.push(sender);
        }
      } else {
        _allocPoints[sender] = 0;
        for (uint256 i = 0; i < _allocPointAddresses.length; i++) {
          if (_allocPointAddresses[i] == sender) {
            _allocPointAddresses[i] = _allocPointAddresses[_allocPointAddresses.length - 1];
            _allocPointAddresses.pop();
            break;
          }
        }
      }
    }

    if (recipient != address(this) &&
        !_isExcluded[recipient] &&
          recipient != address(routerUni) &&
            recipient != address(lpPairUni)) {
      if (_balances[recipient] > 0) {
        if (_allocPoints[recipient] == 0) {
          _allocPoints[recipient] = block.number;
          _allocPointAddresses.push(recipient);
        }
      }
    }
    _reflectVaultBalance(vault);
  }

  function _buyback(address sender, uint256 amount) private returns (bool) {
    if (_balances[address(this)] < amount) {
      emit BuybackFailed(amount, "buyback amount exceeds balance");
      return false;
    }
    if (oppositeAddress == address(0)) {
      emit BuybackFailed(amount, "oppositeAddress can't be the zero address");
      return false;
    }

    _transferExcluded(sender, address(this), amount);
    _approve(address(this), address(routerUni), amount);
    try routerUni.swapExactTokensForTokens(amount, 1, buybackPath, burnAddress, block.timestamp + 1200) returns (uint[] memory amounts) {
      emit Buyback(amount, amounts[amounts.length - 1]);
      return true;
    } catch Error(string memory error) {
      emit BuybackFailed(amount, error);
      return false;
    } catch {
      emit BuybackFailed(amount, "UNISWAP_ROUTER_ERROR");
      return false;
    }
  }

  function burned() public view returns (uint256) {
    return _balances[burnAddress];
  }

  function allocPoints(address account) public view returns (uint256) {
    return ((block.number - _allocPoints[account]) * (_balances[account] / 10**18)) / 1000 ;
  }

  function totalAllocPoints() public view returns (uint256) {
    uint256 tap;
    for (uint256 i = 0; i < _allocPointAddresses.length; i++) {
      tap += allocPoints(_allocPointAddresses[i]);
    }
    return tap;
  }

  function _getAllocRewards(address account, uint256 amount) private view returns (uint256) {
    uint256 tap = totalAllocPoints();
    uint256 ap = allocPoints(account) / tap * 10000;
    return amount * ap / 10000;
  }

  function _reflectVaultBalance(uint256 amount) private {
    for (uint256 i = 0; i < _allocPointAddresses.length; i++) {
      _vaultBalance[_allocPointAddresses[i]] += _getAllocRewards(_allocPointAddresses[i], amount);
    }
  }

  function _balanceOfWithRewards(address account) private view returns (uint256) {

  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Master.sol";

contract Yang is Master('Yang', 'YANG') {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity >=0.5.0;

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}