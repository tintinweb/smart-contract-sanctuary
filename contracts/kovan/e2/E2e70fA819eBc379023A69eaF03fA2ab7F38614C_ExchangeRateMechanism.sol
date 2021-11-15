//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./ApeSwapInterfaces.sol";


contract ExchangeRateMechanism is Ownable {

    address public stabilizer;

    IERC20 public hepa;
    IUSDH public usdh;
    IERC20 public busd;

    IxHEPA public xhepa;
    IxHepaStaking public staking;
    address public devWallet;
    address public usdhTreasury;

    IApeRouter02 public apeRouter;
    IApePair public usdhBusdPair;
    IApePair public hepaBusdPair;

    bool public safetyMode;

    uint256 public usdhToTreasuryShare;
    uint256 public busdToSwapForHepaShare;
    uint256 public hepaToStakersPoolShare;
    uint256 public hepaToFeesPoolShare;
    uint256 public hepaToDevWalletShare;
    uint256 public busdForBuybackFromHepaShare;

    bool public stabilizing;

    modifier lockStabilize {
        require(!stabilizing, "Already stabilzing");
        stabilizing = true;
        _;
        stabilizing = false;
    }

    // CONSTRUCTOR

    constructor() Ownable() {}

    function initializeAddresses(
        address stabilizer_,
        IERC20 hepa_,
        IUSDH usdh_,
        IERC20 busd_,
        IxHEPA xhepa_,
        IxHepaStaking staking_,
        address devWallet_,
        address usdhTreasury_,
        IApeRouter02 apeRouter_,
        IApePair usdhBusdPair_,
        IApePair hepaBusdPair_
    ) external onlyOwner {
        stabilizer = stabilizer_;
        hepa = hepa_;
        usdh = usdh_;
        busd = busd_;
        xhepa = xhepa_;
        staking = staking_;
        devWallet = devWallet_;
        usdhTreasury = usdhTreasury_;
        apeRouter = apeRouter_;
        usdhBusdPair = usdhBusdPair_;
        hepaBusdPair = hepaBusdPair_;
    }

    function initializeShares(
        uint256 usdhToTreasuryShare_,
        uint256 busdToSwapForHepaShare_,
        uint256 hepaToStakersPoolShare_,
        uint256 hepaToFeesPoolShare_,
        uint256 hepaToDevWalletShare_,
        uint256 busdForBuybackFromHepaShare_
    ) external onlyOwner {
        usdhToTreasuryShare = usdhToTreasuryShare_;
        busdToSwapForHepaShare = busdToSwapForHepaShare_;
        hepaToStakersPoolShare = hepaToStakersPoolShare_;
        hepaToFeesPoolShare = hepaToFeesPoolShare_;
        hepaToDevWalletShare = hepaToDevWalletShare_;
        busdForBuybackFromHepaShare = busdForBuybackFromHepaShare_;
    }

    // PUBLIC FUNCTIONS

    function stabilizeExchangeRate() external lockStabilize {

        require(msg.sender == address(usdh) || msg.sender == stabilizer, "Only stabilizer and USDH can stabilize");

        _checkForSafetyMode();

        (uint256 reserveUsdh, uint256 reserveBusd) = _getReserves(
            usdhBusdPair,
            address(usdh)
        );
        if (reserveBusd > reserveUsdh) {
            _decreaseRate(reserveBusd - reserveUsdh);
        } else if (reserveBusd < reserveUsdh) {
            _increaseRate(reserveUsdh - reserveBusd);
        }
    }

    // OWNER FUNCTIONS

    function setDevWallet(address devWallet_) external onlyOwner {
        require(devWallet_ != address(0), "Dev wallet can't be zero address");
        devWallet = devWallet_;
    }

    function setUsdhToTreasuryShare(uint256 usdhToTreasuryShare_) external onlyOwner {
        require(usdhToTreasuryShare_ < 100, "usdhToTreasuryShare should be less than 100%");
        usdhToTreasuryShare = usdhToTreasuryShare_;
    }

    function setBusdToSwapForHepaShare(uint256 busdToSwapForHepaShare_) external onlyOwner {
        require(busdToSwapForHepaShare_ <= 100, "busdToSwapForHepaShare shouldn't be greater than 100%");
        busdToSwapForHepaShare = busdToSwapForHepaShare_;
    }

    function setHepaToStakersPoolShare(uint256 hepaToStakersPoolShare_) external onlyOwner {
        require(
            hepaToStakersPoolShare_ + hepaToFeesPoolShare + hepaToDevWalletShare <= 100,
            "Hepa shares sum shouldn't be greater than 100%"
        );
        hepaToStakersPoolShare = hepaToStakersPoolShare_;
    }

    function setHepaToFeesPoolShare(uint256 hepaToFeesPoolShare_) external onlyOwner {
        require(
            hepaToStakersPoolShare + hepaToFeesPoolShare_ + hepaToDevWalletShare <= 100,
            "Hepa shares sum shouldn't be greater than 100%"
        );
        hepaToFeesPoolShare = hepaToFeesPoolShare_;
    }

    function setHepaToDevWalletShare(uint256 hepaToDevWalletShare_) external onlyOwner {
        require(
            hepaToStakersPoolShare + hepaToFeesPoolShare + hepaToDevWalletShare_ <= 100,
            "Hepa shares sum shouldn't be greater than 100%"
        );
        hepaToDevWalletShare = hepaToDevWalletShare_;
    }

    function setBusdForBuybackFromHepaShare(uint256 busdForBuybackFromHepaShare_) external onlyOwner {
        require(busdForBuybackFromHepaShare_ <= 100, "busdForBuybackFromHepaShare shouldn't be greater than 100%");
        busdForBuybackFromHepaShare = busdForBuybackFromHepaShare_;
    }

    function setStabilizer(address stabilizer_) external onlyOwner {
        stabilizer = stabilizer_;
    }

    // PRIVATE FUNCTIONS 

    function _decreaseRate(uint256 reservesDiff) private {
        uint256 usdhToSwap = reservesDiff / 2;
        uint256 usdhToTreasury = usdhToSwap * usdhToTreasuryShare / (100 - usdhToTreasuryShare);
        usdh.mint(usdhToSwap + usdhToTreasury);
        usdh.transfer(usdhTreasury, usdhToTreasury);
        uint256 obtainedBusd = _swapTokens(address(usdh), address(busd), usdhToSwap);

        if (!safetyMode) {
            uint256 obtainedHepa = _swapTokens(
                address(busd),
                address(hepa),
                obtainedBusd * busdToSwapForHepaShare / 100
            );
 
            uint256 hepaToStakersPool = obtainedHepa * hepaToStakersPoolShare / 100;
            uint256 hepaToFeesPool = obtainedHepa * hepaToFeesPoolShare / 100;
            if (hepaToFeesPool + hepaToStakersPool > 0) {
                hepa.transfer(address(xhepa), hepaToFeesPool + hepaToStakersPool);
                xhepa.supplyToPools(hepaToFeesPool, hepaToStakersPool);
            }

            uint256 hepaToDevWallet = obtainedHepa * hepaToDevWalletShare / 100;
            if (hepaToDevWallet > 0) {
                hepa.transfer(devWallet, hepaToDevWallet);
            }

            uint256 hepaToStakingRewards = obtainedHepa - hepaToStakersPool - hepaToFeesPool - hepaToDevWallet;
            if (hepaToStakingRewards > 0) {
                hepa.transfer(address(staking), hepaToStakingRewards);
                staking.distribute(hepaToStakingRewards);
            }     
        }
    }

    function _increaseRate(uint256 reservesDiff) private {
        uint256 busdToSwap = reservesDiff * 500 / 998;

        uint256 busdFromHepa = busdToSwap * busdForBuybackFromHepaShare / 100;

        if (busdFromHepa > 0) {
            uint256 hepaToSwap = _getAmountIn(hepaBusdPair, address(busd), busdFromHepa);
            uint256 collectedHepa = xhepa.collectFromPools(hepaToSwap);
            if (collectedHepa > 0) {
                _swapTokens(address(hepa), address(busd), collectedHepa);
            }  
        }   

        uint256 availableBusd = Math.min(busdToSwap, busd.balanceOf(address(this)));
        if (availableBusd > 0) {
            uint256 obtainedUsdh = _swapTokens(address(busd), address(usdh), availableBusd);
            usdh.burn(obtainedUsdh);
        }
    }

    function _checkForSafetyMode() private {
        uint256 busdEquivalent = 0;
        uint256 totalPool = xhepa.totalPool();
        if (totalPool > 0) {
            busdEquivalent = _getAmountOut(hepaBusdPair, address(hepa), totalPool);
        }
        if (busdEquivalent + busd.balanceOf(address(this)) < usdh.totalSupply()) {
            safetyMode = true;
        }
    }

    function _swapTokens(address tokenA, address tokenB, uint256 amountIn) private returns (uint256) {
        uint256 initialBalance = IERC20(tokenB).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        IERC20(tokenA).approve(address(apeRouter), amountIn);
        apeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp
        );

        return IERC20(tokenB).balanceOf(address(this)) - initialBalance;
    }

    // APE FUNCTIONS

    function _getReserves(IApePair pair, address tokenA) private view returns (uint256, uint256) {
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        if (tokenA == pair.token0()) {
            return (reserve0, reserve1);
        } else {
            return (reserve1, reserve0);
        }
    }

    function _getAmountIn(IApePair pair, address tokenOut, uint256 amountOut) private view returns (uint256) {
        (uint256 reserveOut, uint256 reserveIn) = _getReserves(pair, tokenOut);
        require(amountOut > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 998;
        return (numerator / denominator) + 1;
    }

    function _getAmountOut(IApePair pair, address tokenIn, uint256 amountIn) private view returns (uint256) {
        (uint256 reserveIn, uint256 reserveOut) = _getReserves(pair, tokenIn);
        require(amountIn > 0, 'ApeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'ApeLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 998;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        return numerator / denominator;
    }
}

interface IxHEPA {
    function supplyToPools(uint256 feesSupply, uint256 stakersSupply) external;
    function collectFromPools(uint256 hepaAmount) external returns (uint256);
    function totalPool() external view returns(uint256);
}

interface IUSDH is IERC20 {
    function mint(uint256 amount) external;
    function burn(uint256 amount) external;
}

interface IxHepaStaking {
    function distribute(uint256 amount) external;
}

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.2;


interface IApeFactory {
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


interface IApePair {
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


interface IApeRouter01 {
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


interface IApeRouter02 is IApeRouter01 {
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
        return msg.data;
    }
}

