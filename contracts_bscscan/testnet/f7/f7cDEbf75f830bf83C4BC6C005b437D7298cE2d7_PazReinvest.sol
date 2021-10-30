// SPDX-License-Identifier: MIT

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
import './ISwapRouter.sol';
interface IPazDividendTracker {
  function BUSD (  ) external view returns ( address );
  function MIN_BALANCE_AUTO_DIVIDENDS (  ) external view returns ( uint256 );
  function MIN_BALANCE_DIVIDENDS (  ) external view returns ( uint256 );
  function MIN_CLAIM_INTERVAL (  ) external view returns ( uint256 );
  function MIN_DIVIDEND_DISTRIBUTION (  ) external view returns ( uint256 );
  function accumulativeDividendOf ( address _owner ) external view returns ( uint256 );
  function allowCustomTokens (  ) external view returns ( bool );
  function allowance ( address owner, address spender ) external view returns ( uint256 );
  function allowedRouters ( address ) external view returns ( bool );
  function allowedTokens ( address ) external view returns ( bool );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address account ) external view returns ( uint256 );
  function decimals (  ) external view returns ( uint8 );
  function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
  function depositBusd ( uint256 amount ) external;
  function distributeDividends ( uint256 amount ) external;
  function dividendOf ( address _owner ) external view returns ( uint256 );
  function dividendsPaused (  ) external view returns ( bool );
  function excludedFromDividends ( address ) external view returns ( bool );
  function getAccount ( address _account ) external view returns ( address account, int256 index, int256 iterationsUntilProcessed, uint256 withdrawableDividends, uint256 totalDividends, uint256 lastClaimTime, uint256 nextClaimTime, uint256 secondsUntilAutoClaimAvailable );
  function getAccountAtIndex ( uint256 index ) external view returns ( address, int256, int256, uint256, uint256, uint256, uint256, uint256 );
  function getAllowedTokens ( address token ) external view returns ( bool );
  function getLastProcessedIndex (  ) external view returns ( uint256 );
  function getNumberOfTokenHolders (  ) external view returns ( uint256 );
  function getRouter ( address token ) external view returns ( ISwapRouter _router );
  function getUserActualRewardToken ( address user ) external view returns ( address );
  function getUserRewardToken ( address account ) external view returns ( address );
  function getUserSwappedBusd ( address user ) external view returns ( uint256 );
  function getUserTaxFreeReinvestAmount ( address user ) external view returns ( uint256 );
  function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
  function isExcludedFromDividends ( address account ) external view returns ( bool );
  function lastProcessedIndex (  ) external view returns ( uint256 );
  function name (  ) external view returns ( string calldata );
  function owner (  ) external view returns ( address );
  function paz (  ) external view returns ( address );
  function process ( uint256 gas ) external returns ( uint256, uint256, uint256 );
  function processAccount ( address account, bool automatic ) external returns ( bool );
  function recoverTokens ( address _token, address _to ) external returns ( bool _sent );
  function renounceOwnership (  ) external;
  function router (  ) external view returns ( address );
  function setAllowCustomTokens ( bool allow ) external;
  function setAllowedRouter ( address routerAddress, bool allow ) external;
  function setAllowedTokens ( address token, bool allow ) external;
  function setBalance ( address account, uint256 newBalance ) external;
  function setDividendsPaused ( bool isPaused ) external;
  function setExcludedFromDividends ( address account, bool excluded ) external;
  function setMinBalanceAutoDividends ( uint256 minBalanceAutoDividends ) external;
  function setMinBalanceDividends ( uint256 minBalanceDividends ) external;
  function setMinClaimInterval ( uint256 minClaimInterval ) external;
  function setMinDividendDistribution ( uint256 minDividendDistribution ) external;
  function setTokenRouter ( address token, address routerAddress ) external;
  function setUserRewardToken ( address account, address token ) external;
  function setUserSwappedBusd ( address user, uint256 amount ) external;
  function sweep (  ) external;
  function symbol (  ) external view returns ( string calldata);
  function tokenRouter ( address ) external view returns ( address );
  function tokenToUserCount ( address ) external view returns ( uint256 );
  function totalDividendsDistributed (  ) external view returns ( uint256 );
  function totalSupply (  ) external view returns ( uint256 );
  function transfer ( address recipient, uint256 amount ) external returns ( bool );
  function transferFrom ( address sender, address recipient, uint256 amount ) external returns ( bool );
  function transferOwnership ( address newOwner ) external;
  function updateRouter ( address newAddress ) external;
  function userLastClaimTime ( address ) external view returns ( uint256 );
  function userRewardToken ( address ) external view returns ( address );
  function userSwappedBusd ( address ) external view returns ( uint256 );
  function withdrawDividend (  ) external pure;
  function withdrawableDividendOf ( address _owner ) external view returns ( uint256 );
  function withdrawnDividendOf ( address _owner ) external view returns ( uint256 );
}

// SPDX-License-Identifier: MIT

interface ISwapPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
    external
    view
    returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
    external
    returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

interface ISwapRouter is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

import "./Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/ISwapRouter.sol";
import "../interfaces/ISwapPair.sol";
import "../interfaces/IBEP20.sol";
import "../interfaces/IPazDividendTracker.sol";
import "../lib/Ownable.sol";

contract PazReinvest is Ownable {

    address public BUSD;
    address public WBNB;
    address public TRACKER;

    IPazDividendTracker tracker;

    mapping(address => uint) public userSwappedBusd;
    mapping(address => uint) public tokenToBusdSwapped;
    mapping(address => uint) public userReinvestCredit;

    bool public TAX_FREE_SWAP_ENABLED = true;
    uint public EXTRA_BUSD_AMOUNT = 100 * (10**18);

    constructor(address trackerAddress) {
        TRACKER = trackerAddress;
        tracker = IPazDividendTracker(TRACKER);
        BUSD = tracker.BUSD();
        WBNB = ISwapRouter(tracker.router()).WETH();
    }

    function taxFreeReinvest(address token, uint busdAmount) external {
        require(TAX_FREE_SWAP_ENABLED, "PazReinvest: Tax Free swap is disabled");
        require(tracker.allowedTokens(token) ,"PazReinvest: Token not allowed");
        require(tracker.balanceOf(msg.sender) >= tracker.MIN_BALANCE_DIVIDENDS(), "PazReinvest: must hold enough pazzive");
        uint256 eligibleAmount = getUserEligibleBusdAmount(msg.sender);
        require(busdAmount <= eligibleAmount, "Paz: amount is too high");
        require(IBEP20(BUSD).transferFrom(msg.sender, address(this), busdAmount), "PazReinvest: Transfer BUSD failed");

        ISwapRouter router = tracker.getRouter(token);
        IBEP20(BUSD).approve(address(router), busdAmount);

        address[] memory path = new address[](3);
        path[0] = BUSD;
        path[1] = WBNB;
        path[2] = token;

        // no slippage needed as there is high liquidity for BUSD/BNB liquidity and all fuzion tokens have tax
        uint[] memory amounts = router.swapExactTokensForTokens(busdAmount, 0, path, address(this), block.timestamp);

        userSwappedBusd[msg.sender] += busdAmount;
        tokenToBusdSwapped[token] += busdAmount;
        require(IBEP20(token).transfer(msg.sender, amounts[2]), "PazReinvest: Transfer to user failed");
    }

    function getUserEligibleBusdAmount(address user) public view returns (uint256 eligibleBusdAmount) {
        uint256 totalAmount = tracker.accumulativeDividendOf(user) + EXTRA_BUSD_AMOUNT + userReinvestCredit[user];
        eligibleBusdAmount = userSwappedBusd[user] > totalAmount ? 0 : totalAmount - userSwappedBusd[user];
    }


    function setExtraBusdAmount(uint amount) external onlyOwner {
        EXTRA_BUSD_AMOUNT = amount;
    }

    function setUserReinvestCredit(address account, uint amount) external onlyOwner {
        userReinvestCredit[account] = amount;
    }

    function setUserSwappedBusd(address account, uint amount) external onlyOwner {
        userSwappedBusd[account] = amount;
    }

    function setTokenToBusdSwapped(address account, uint amount) external onlyOwner {
        tokenToBusdSwapped[account] = amount;
    }

    function setBusd(address busd_) external onlyOwner {
        BUSD = busd_;
    }

    function setWBNB(address wbnb_) external onlyOwner {
        WBNB = wbnb_;
    }

    function setTaxFreeSwapEnabled(bool enabled_) external onlyOwner {
        TAX_FREE_SWAP_ENABLED = enabled_;
    }

    function setTracker(address tracker_) external onlyOwner {
        TRACKER = tracker_;
        tracker = IPazDividendTracker(tracker_);
    }

    function setBusdApprovalToMax(address router_) external onlyOwner {
        IBEP20(BUSD).approve(router_, ~uint(0));
    }

    function retrieveTokens(address token) external onlyOwner {
        require(IBEP20(token).transfer(msg.sender, IBEP20(token).balanceOf(address(this))), "PazReinvest: Transfer failed");
    }

    function retrieveBnb() external onlyOwner {
        (bool success,) = payable(msg.sender).call{ value: address(this).balance }("");
        require(success, "PazReinvest: Failed to retrieve BNB");
    }

}