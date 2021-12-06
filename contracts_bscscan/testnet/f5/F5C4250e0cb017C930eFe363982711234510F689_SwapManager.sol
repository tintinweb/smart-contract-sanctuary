// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Router/interfaces/IRouterManager.sol";
import "./ISwapManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Abstract contract, part of OMNIA token contract.
 * @dev Declares & configures variables used for swaps.
 */
contract SwapManager is ISwapManager, Ownable {
    IRouterManager public _router;
    uint16 public maxSlippage = 1000; // Max slippage on swaps: from 0.1% to 1%

    constructor(address routerManager_) {
        _router = IRouterManager(routerManager_);
    }

    /**
     * @dev Updates `maxSlippage` to apply during swaps.
     *
     * Requirements:
     * - only the owner can update it
     * - `slippage` must be between 0.1% (1000) and 1% (100)
     */
    function setMaxSlippage(uint16 slippage) external onlyOwner {
        if (slippage > 1000) revert("slip > 1000");
        if (slippage < 100) revert("slip < 100");
        maxSlippage = slippage;
    }

    /**
     * @inheritdoc ISwapManager
     *
     */
    function calculateSplippageOn(uint256 amount)
        public
        view
        override
        returns (uint256)
    {
        return amount - (amount / maxSlippage);
    }

    /**
     * @inheritdoc ISwapManager
     *
     */
    function pathAndMaxOut(
        address omnia,
        address bep20Token_,
        uint256 omniaAmount_
    ) public view override returns (uint256 maxOut, address[] memory path) {
        // Generate pair for Omnia -> WBNB
        uint8 pathLength = bep20Token_ != _router.pancakeswapV2Router().WETH()
            ? 3
            : 2;

        path = new address[](pathLength);
        path[0] = address(omnia);
        path[1] = _router.pancakeswapV2Router().WETH();
        // create 2nd path if bep20Token_ is not WBNB
        if (bep20Token_ != _router.pancakeswapV2Router().WETH())
            path[2] = bep20Token_;

        uint256[] memory amounts = _router.pancakeswapV2Router().getAmountsOut(
            omniaAmount_,
            path
        );
        maxOut = amounts[amounts.length - 1];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IPancakeRouter02.sol";

/**
 * @dev Interface to be used in {BEP20Swap}, {SwapManager} and {SwapToBNB}.
 */
interface IRouterManager {
    function initialize(
        address omnia_,
        address router_,
        address rewards_
    ) external;

    function updateRewardsContract(address rewards_) external;

    /**
     * @dev Given PancakeSwapRouter address will create OMNIA-WBNB LP and
     *      and update `pancakeswapV2Router()` and `pancakeswapV2Router()`
     *      returns.
     *
     *      👉 On updates after deployment 🚨
     *      ⚠⚠ DONT FORGET to EXCLUDE new PAIR AND ROUTER manually ⚠⚠
     *
     * @param routerAddress new address of PancakeSwapRouter to use.
     */
    function setPancakeSwapRouter(address routerAddress) external;

    /**
     * @return IPancakeRouter02
     *         interface of PancakeSWapRouter contract.
     */
    function pancakeswapV2Router() external view returns (IPancakeRouter02);

    /**
     * @return IUniswapV2Pair
     *         interface of OMNIA-BNB LP contract.
     */
    function pancakeswapV2Pair() external view returns (IUniswapV2Pair);

    /**
     * @param sender_ address that sends tokens in a transfer.
     * @param recipient_ address that receives tokens in a transfer.
     *
     * @return bool
     *         is selling or not.
     */
    function isSelling(address sender_, address recipient_)
        external
        view
        returns (bool);

    /**
     * @return bool
     *         is `account_` nor PCS router nor pair.
     */
    function isNotRouterNorPair(address account_) external view returns (bool);

    /**
     * @param sender_ address that sends tokens in a transfer.
     * @param recipient_ address that receives tokens in a transfer.
     *
     * @return bool
     *         is the transfer not sell nor a purchase.
     */
    function isNotSellingAndNotPurchasing(address sender_, address recipient_)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface to be used in {BEP20Swap} and {SwapToBNB}.
 */
interface ISwapManager {
    /**
     * @dev Calculates the exact amount to be received after slippage has been applied.
     *
     * @param amount amount of some token to be swapped
     * @return uint256
     *         amount after slippage has been applied.
     */
    function calculateSplippageOn(uint256 amount)
        external
        view
        returns (uint256);

    /**
     * @notice Swaps OMNIA for BNB, using `_pancakeswapV2Router.WETH()` as `bep20Token_`.
     * @dev Gets the path to swap OMNIA to chosen token & calculates maximum
     *      amount to receive in selected token.
     *
     * @param bep20Token_ coin to swap from OMNIA.
     * @param omniaAmount_ amount of OMNIA to swap into `bep20Token_`.
     *
     * @return maxOut
     *         maximum amount of `bep20Token_` to be received.
     * @return path
     *         path for OMNIA > `bep20Token_` swap.
     *
     */
    function pathAndMaxOut(
        address omnia,
        address bep20Token_,
        uint256 omniaAmount_
    ) external view returns (uint256 maxOut, address[] memory path);
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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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

pragma solidity ^0.8.0;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
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

pragma solidity ^0.8.0;

interface IPancakeRouter01 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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