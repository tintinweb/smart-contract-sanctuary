// Copyright © 2021 Moon Bear Finance Ltd. All Rights Reserved.
// SPDX-License-Identifier: GPL-3.0
//

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IMBFStaking.sol";

contract Swap is Ownable, ReentrancyGuard {
    IERC20 public mbf;
    IERC20 public busd;
    IUniswapV2Router02 public swapRouter;
    IMBFStaking public staking;

    // constants
    uint256 private constant BASE_POINT = 10000;

    uint256 public minTokensToSwap;

    uint256 public totalBuyFee;
    uint256 public buyFeeStablePercent;
    uint256 public totalSellFee;
    uint256 public sellFeeStablePercent;

    address public stableWallet;

    constructor(
        IERC20 _mbf,
        IERC20 _busd,
        address _stableWallet,
        IUniswapV2Router02 _router,
        IMBFStaking _staking
    ) {
        mbf = _mbf;
        busd = _busd;
        stableWallet = _stableWallet;
        swapRouter = _router;
        staking = _staking;
        buyFeeStablePercent = 7500;
        sellFeeStablePercent = 6667;

        busd.approve(address(this), type(uint256).max);
        mbf.approve(address(staking), type(uint256).max);
        busd.approve(address(staking), type(uint256).max);
        mbf.approve(address(swapRouter), type(uint256).max);
        busd.approve(address(swapRouter), type(uint256).max);
    }

    function setMinimumTokensToSwap(uint256 _minTokensToSwap) external onlyOwner {
        minTokensToSwap = _minTokensToSwap;
    }

    function chargeWithBuyFee(uint256 _buyFeeAmount) external {
        require(_buyFeeAmount > 0, "_buyFeeAmount <= 0");
        require(mbf.transferFrom(msg.sender, address(this), _buyFeeAmount), "Token transfer failed");

        totalBuyFee += _buyFeeAmount;
    }

    function chargeWithSellFee(uint256 _sellFeeAmount) external {
        require(_sellFeeAmount > 0, "_sellFeeAmount <= 0");
        require(mbf.transferFrom(msg.sender, address(this), _sellFeeAmount), "Token transfer failed");

        totalSellFee += _sellFeeAmount;
    }

    function swapAndLiquify() external onlyOwner {
        uint256 contractTokenBalance = mbf.balanceOf(address(this));
        require(contractTokenBalance >= minTokensToSwap, "Not enough tokens to swap");

        uint256 stableSwapBalance = (totalBuyFee * buyFeeStablePercent) + (totalSellFee * sellFeeStablePercent);

        _swapTokensForUSD(stableSwapBalance / BASE_POINT);

        uint256 totalBUSDBalance = busd.balanceOf(address(this));

        // 4% -> staking rewards
        // 11% -> total stable rewards
        uint256 stableBUSDForStakingRewards = (totalBUSDBalance * 4 * BASE_POINT) / (11 * BASE_POINT);

        require(
            busd.transferFrom(address(this), stableWallet, totalBUSDBalance - stableBUSDForStakingRewards),
            "BUSD transfer failed"
        );

        uint256 amountLeftSell = totalSellFee * (BASE_POINT - sellFeeStablePercent); // totalSellFee * (100% - sellFeePercent)
        uint256 amountLeftBuy = totalBuyFee * (BASE_POINT - buyFeeStablePercent); // totalSellFee * (100% - sellFeePercent)

        // 4000 = total non stable sell %
        // 1% for liquidity
        uint256 bnbSwapBalance = ((amountLeftSell * 1000) / 4000);

        amountLeftSell -= bnbSwapBalance;

        uint256 halfOfLiquidityTokens = bnbSwapBalance / 2 / BASE_POINT;

        uint256 ethBefore = address(this).balance;
        // Swap tokens for BNB
        _swapTokensForEth(halfOfLiquidityTokens);
        uint256 ethSwapped = address(this).balance - ethBefore;

        // Add liquidity to our BNB pair
        _addLiquidityEth(halfOfLiquidityTokens, ethSwapped);

        // Send to staking rewards
        // Sent 3% of sell TX to tokenRewards and 1% of buy
        uint256 tokenRewards = (amountLeftSell + amountLeftBuy) / BASE_POINT;

        staking.chargeStableReward(stableBUSDForStakingRewards);
        staking.chargeMbfReward(tokenRewards);
    }

    /**
     * Internal functions
     */
    function _totalFees() internal view returns (uint256) {
        return totalBuyFee + totalSellFee;
    }

    function _swapTokensForEth(uint256 _tokenAmount) internal {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(mbf);
        path[1] = swapRouter.WETH();

        // make the swap
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, // accept any amount of bnb
            path,
            address(this),
            block.timestamp
        );
    }

    function _swapTokensForUSD(uint256 _tokenAmount) internal {
        // generate the uniswap pair path of token -> bnb -> busd
        address[] memory path = new address[](3);
        path[0] = address(mbf);
        path[1] = swapRouter.WETH();
        path[2] = address(busd);

        // make the swap
        swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, // accept any amount of busd
            path,
            address(this), // send to contract so we can split it up
            block.timestamp
        );
    }

    function _addLiquidityEth(uint256 _tokenAmount, uint256 _ethAmount) internal {
        // add the liquidity
        swapRouter.addLiquidityETH{ value: _ethAmount }(
            address(mbf),
            _tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    // to recieve BNB from swapping
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

// Copyright © 2021 Moon Bear Finance Ltd. All Rights Reserved.
// SPDX-License-Identifier: GPL-3.0
//
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░
// ░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░
// ░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░
// ░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░
// ░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓███▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░
// ░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█████▓████▓▒▒▒▒▒▒▒▒▒▒░░░░▒▒▒▒▒░░░░░░
// ░░░░░░▒▒▒▒▒▒░░░░░▒▒▒▒▒▒▒▓███████████▓▓▒▒▒▒▒▒▒░░░░░▒▒▒▒▒░░░░░
// ░░░░░▒▒▒▒▒▒▒░░░░░▒▒▒▒▒▒▒▒▒█████████████▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░
// ░░░░▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒▓▓▓███████████████▓▒▒▒▒▒▒░▒▒▒▒▒▒░░░░
// ░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓████████████████████▓▒▒▒▒▒▒▒▒▒▒▒▒░░░░
// ░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓████████████████████████▒▒▒▒▒▒▒▒▒▒▒▒░░░░
// ░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▓██████████████████████████▒▒▒▒▒▒▒▒▒▒▒▒░░░░
// ░░░░▒▒▒▒▒▒▒▒▒▒▒▒▓███████████████████████████▒▒▒▒▒▒▒▒▒▒▒▒░░░░
// ░░░░▒▒▒░░░░▒▒▒▒▒████████████████████████████▒▒▒▒▒▒▒▒▒▒▒▒░░░░
// ░░░░░▒▒▒▒▒▒▒▒▒▒▒████████████████████████████▒▒▒▒▒▒▒▒▒▒▒░░░░░
// ░░░░░▒▒▒▒▒▒▒▒▒▒▒█████████▓▓█████████▓▓▓█████▒▒▒▒▒▒▒▒▒▒▒░░░░░
// ░░░░░░▒▒▒▒▒▒▒▒▒▒██████▓▒▒▒▒▓█████▓▓▒▒▒▓█████▒▒▒▒▒▒▒▒▒▒░░░░░░
// ░░░░░░░▒▒▒▒▒▒▒▒▒██████▓▓▓▓▓██████▓▓▓▓▓▓█████▒▒▒▒▒▒▒▒▒░░░░░░░
// ░░░░░░░░░▒▓▓▓██████████████████████████████████▓▓▓▒▒░░░░░░░░
// ░░░░░░░░░░▓██████████████████████████████████████▓░░░░░░░░░░
// ░░░░░░░░░░░▒▓██████████████████████████████████▓▒░░░░░░░░░░░
// ░░░░░░░░░░░░░░▒▓████████████████████████████▓▒░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░▒▒▓▓████████████████████▓▓▒▒░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░▒▒▓▓▓▓██████▓▓▓▓▒▒░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

pragma solidity ^0.8.0;

interface IMBFStaking {
    function chargeStableReward(uint256 _amount) external;

    function chargeMbfReward(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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