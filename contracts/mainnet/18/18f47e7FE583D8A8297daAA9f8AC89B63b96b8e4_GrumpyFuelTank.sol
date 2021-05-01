/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
interface IFuelTank {
  function openNozzle() external;
  function addTokens(address user, uint amount) external;
}
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


contract GrumpyFuelTank is Context, Ownable, IFuelTank {
  IUniswapV2Router02 uniswapRouter;

  address uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address public grumpyAddress;
  address public meowDAOAddress;

  mapping (address => uint) public reclaimableBalances;
  uint public liquidityBalance;

  uint public reclaimGuaranteeTime;
  uint public reclaimStartTime;

  constructor (address _grumpyAddress) {
    grumpyAddress = _grumpyAddress;
    uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
  }

  function addMeowDAOaddress(address _meowDAOAddress) public onlyOwner {
    require(meowDAOAddress == address(0));
    meowDAOAddress = _meowDAOAddress;
  }

  bool public nozzleOpen = false;
  function openNozzle() external override {
    require(!nozzleOpen, "AlreadyOpen");
    require(meowDAOAddress != address(0), "MeowDAONotInitialized");
    require(msg.sender == meowDAOAddress, "MustBeMeowDao");

    reclaimStartTime = block.timestamp + (86400 * 2);
    reclaimGuaranteeTime = block.timestamp + (86400 * 9);

    nozzleOpen = true;
  }

  function addTokens(address user, uint amount) external override {
    require(meowDAOAddress != address(0), "MeowDAONotInitialized");
    require(msg.sender == meowDAOAddress, "MustBeMeowDao");
    require(!nozzleOpen, "MustBePhase1");

    require(amount > 100, "amountTooSmall"); 

    uint granule = amount / 100;
    uint reclaimable = granule * 72;
    uint fuel = granule * 25;

    liquidityBalance += fuel;
    reclaimableBalances[user] = reclaimableBalances[user] + reclaimable;
  }

  function reclaimGrumpies() public {
    require(nozzleOpen, "Phase1");
    require(block.timestamp >= reclaimStartTime, "Phase2");
    address sender = msg.sender;
    require(reclaimableBalances[sender] > 0, "BalanceEmpty");

    IERC20(grumpyAddress).transfer(sender, reclaimableBalances[sender]);
    reclaimableBalances[sender] = 0;
  }

  function sellGrumpy(uint256 amount, uint256 amountOutMin) public onlyOwner {
    require(nozzleOpen);
    if (block.timestamp < reclaimGuaranteeTime) {
      require(amount <= liquidityBalance, "NotEnoughFuel");
      liquidityBalance -= amount;
    }

    IERC20 grumpy = IERC20(grumpyAddress);
    require(grumpy.approve(uniswapRouterAddress, amount), "Could not approve grumpy transfer");

    address[] memory path = new address[](2);
    path[0] = grumpyAddress;
    path[1] = uniswapRouter.WETH();
    uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, amountOutMin, path, address(this), block.timestamp);
  }

  function provideLockedLiquidity(
        uint amountWETHDesired, uint amountMEOWDesired,
        uint amountWETHMin, uint amountMEOWMin,
        uint deadline) public onlyOwner {

    require(nozzleOpen);
    require(meowDAOAddress != address(0));

    address wethAddress = uniswapRouter.WETH();

    require(IERC20(wethAddress).approve(uniswapRouterAddress, amountWETHDesired),
      "Could not approve WETH transfer");

    require(IERC20(meowDAOAddress).approve(uniswapRouterAddress, amountMEOWDesired),
      "Could not approve MEOW transfer");

    uniswapRouter.addLiquidity(
      uniswapRouter.WETH(),
      meowDAOAddress,
      amountWETHDesired,
      amountMEOWDesired,
      amountWETHMin,
      amountMEOWMin,
      address(0x000000000000000000000000000000000000dEaD),
      deadline); 
  }
}