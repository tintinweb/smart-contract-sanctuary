// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IERC20} from '../ERC20/IERC20.sol';
import {IAnyswapV4Token} from '../ERC20/IAnyswapV4Token.sol';

/**
 * @title  ARTHShares.
 * @author MahaDAO.
 */
interface IARTHX is IERC20, IAnyswapV4Token {
    function setTaxPercent(uint256 percent) external;

    function setOwner(address _ownerAddress) external;

    function setOracle(address newOracle) external;

    function setArthController(address _controller) external;

    function setTimelock(address newTimelock) external;

    function setARTHAddress(address arthContractAddress) external;

    function poolMint(address account, uint256 amount) external;

    function poolBurnFrom(address account, uint256 amount) external;

    function setTaxDestination(address _taxDestination) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from '../ERC20/IERC20.sol';
import {IIncentiveController} from './IIncentive.sol';
import {IAnyswapV4Token} from '../ERC20/IAnyswapV4Token.sol';

interface IARTH is IERC20, IAnyswapV4Token {
    function addPool(address pool) external;

    function removePool(address pool) external;

    function setGovernance(address _governance) external;

    function poolMint(address who, uint256 amount) external;

    function poolBurnFrom(address who, uint256 amount) external;

    function setIncentiveController(IIncentiveController _incentiveController)
        external;

    function genesisSupply() external view returns (uint256);

    function pools(address pool) external view returns (bool);

    function sendToPool(
        address sender,
        address poolAddress,
        uint256 amount
    ) external;

    function returnFromPool(
        address poolAddress,
        address receiver,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title incentive contract interface
/// @author Fei Protocol
/// @notice Called by FEI token contract when transferring with an incentivized address
/// @dev should be appointed as a Minter or Burner as needed
interface IIncentiveController {
    /// @notice apply incentives on transfer
    /// @param sender the sender address of the FEI
    /// @param receiver the receiver address of the FEI
    /// @param operator the operator (msg.sender) of the transfer
    /// @param amount the amount of FEI transferred
    function incentivize(
        address sender,
        address receiver,
        address operator,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IARTHPool {
    function repay(uint256 amount) external;

    function borrow(uint256 amount) external;

    function setStabilityFee(uint256 percent) external;

    function setBuyBackCollateralBuffer(uint256 percent) external;

    function setCollatGMUOracle(
        address _collateralGMUOracleAddress
    ) external;

    function toggleMinting() external;

    function toggleRedeeming() external;

    function toggleRecollateralize() external;

    function toggleBuyBack() external;

    function toggleCollateralPrice(uint256 newPrice) external;

    function setPoolParameters(
        uint256 newCeiling,
        uint256 newRedemptionDelay,
        uint256 newMintFee,
        uint256 newRedeemFee,
        uint256 newBuybackFee,
        uint256 newRecollateralizeFee
    ) external;

    function setTimelock(address newTimelock) external;

    function setOwner(address ownerAddress) external;

    function mint1t1ARTH(uint256 collateralAmount, uint256 ARTHOutMin)
        external
        returns (uint256);

    function mintAlgorithmicARTH(uint256 arthxAmountD18, uint256 arthOutMin)
        external
        returns (uint256);

    function mintFractionalARTH(
        uint256 collateralAmount,
        uint256 arthxAmount,
        uint256 ARTHOutMin
    ) external returns (uint256);

    function redeem1t1ARTH(uint256 arthAmount, uint256 collateralOutMin)
        external;

    function redeemFractionalARTH(
        uint256 arthAmount,
        uint256 arthxOutMin,
        uint256 collateralOutMin
    ) external;

    function redeemAlgorithmicARTH(uint256 arthAmounnt, uint256 arthxOutMin)
        external;

    function collectRedemption() external;

    function recollateralizeARTH(uint256 collateralAmount, uint256 arthxOutMin)
        external
        returns (uint256);

    function buyBackARTHX(uint256 arthxAmount, uint256 collateralOutMin)
        external;

    function getGlobalCR() external view returns (uint256);

    function mintingFee() external returns (uint256);

    function isWETHPool() external returns (bool);

    function redemptionFee() external returns (uint256);

    function buybackFee() external returns (uint256);

    function getRecollateralizationDiscount() external view returns (uint256);

    function recollatFee() external returns (uint256);

    function getCollateralGMUBalance() external view returns (uint256);

    function getAvailableExcessCollateralDV() external view returns (uint256);

    function getCollateralPrice() external view returns (uint256);

    function getARTHMAHAPrice() external view returns (uint256);

    function collateralPricePaused() external view returns (bool);

    function pausedPrice() external view returns (uint256);

    function collateralGMUOracleAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAnyswapV4Token {
    function approveAndCall(
        address spender,
        uint256 value,
        bytes calldata data
    ) external returns (bool);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool);

    function transferWithPermit(
        address target,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    function Swapin(
        bytes32 txhash,
        address account,
        uint256 amount
    ) external returns (bool);

    function Swapout(uint256 amount, address bindaddr) external returns (bool);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address target,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the number of decimals for token.
     */
    function decimals() external view returns (uint8);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from './IERC20.sol';

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISimpleOracle {
    function getPrice() external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IARTH} from '../Arth/IARTH.sol';
import {IARTHPool} from '../Arth/Pools/IARTHPool.sol';
import {IARTHX} from '../ARTHX/IARTHX.sol';
import {IERC20} from '../ERC20/IERC20.sol';
import {IWETH} from '../ERC20/IWETH.sol';
import {ISimpleOracle} from '../Oracle/ISimpleOracle.sol';
import {IBoostedStaking} from '../Staking/IBoostedStaking.sol';
import {IUniswapV2Router02} from '../Uniswap/Interfaces/IUniswapV2Router02.sol';

contract ArthPoolRouter {
    IARTH public arth;
    IARTHX public arthx;
    IWETH public weth;
    IUniswapV2Router02 public router;

    constructor(
        IARTHX _arthx,
        IARTH _arth,
        IWETH _weth,
        IUniswapV2Router02 _router
    ) {
        arth = _arth;
        arthx = _arthx;
        weth = _weth;
        router = _router;
    }

    function mint1t1ARTHAndStake(
        IARTHPool pool,
        IERC20 collateral,
        uint256 amount,
        uint256 arthOutMin,
        uint256 secs,
        IBoostedStaking stakingPool
    ) external {
        _mint1t1ARTHAndStake(
            pool,
            collateral,
            amount,
            arthOutMin,
            secs,
            stakingPool
        );
    }

    function mintAlgorithmicARTHAndStake(
        IARTHPool pool,
        uint256 arthxAmountD18,
        uint256 arthOutMin,
        uint256 secs,
        IBoostedStaking stakingPool
    ) external {
        _mintAlgorithmicARTHAndStake(
            pool,
            arthxAmountD18,
            arthOutMin,
            secs,
            stakingPool
        );
    }

    function mintFractionalARTHAndStake(
        IARTHPool pool,
        IERC20 collateral,
        uint256 amount,
        uint256 arthxAmount,
        uint256 arthOutMin,
        uint256 secs,
        IBoostedStaking stakingPool,
        bool swapWithUniswap,
        uint256 amountToSell
    ) external {
        _mintFractionalARTHAndStake(
            pool,
            collateral,
            amount,
            arthxAmount,
            arthOutMin,
            secs,
            stakingPool,
            swapWithUniswap,
            amountToSell
        );
    }

    function recollateralizeARTHAndStake(
        IARTHPool pool,
        IERC20 collateral,
        uint256 amount,
        uint256 arthxOutMin,
        uint256 secs,
        IBoostedStaking stakingPool
    ) external {
        _recollateralizeARTHAndStake(
            pool,
            collateral,
            amount,
            arthxOutMin,
            secs,
            stakingPool
        );
    }

    function recollateralizeARTHAndStakeWithETH(
        IARTHPool pool,
        uint256 arthxOutMin,
        uint256 secs,
        IBoostedStaking stakingPool
    ) external payable {
        weth.deposit{value: msg.value}();
        _recollateralizeARTHAndStake(
            pool,
            weth,
            msg.value,
            arthxOutMin,
            secs,
            stakingPool
        );
    }

    function mint1t1ARTHAndStakeWithETH(
        IARTHPool pool,
        uint256 arthOutMin,
        uint256 secs,
        IBoostedStaking stakingPool
    ) external payable {
        weth.deposit{value: msg.value}();
        _mint1t1ARTHAndStake(
            pool,
            weth,
            msg.value,
            arthOutMin,
            secs,
            stakingPool
        );
    }

    function mintFractionalARTHAndStakeWithETH(
        IARTHPool pool,
        uint256 arthxAmount,
        uint256 arthOutMin,
        uint256 secs,
        IBoostedStaking stakingPool,
        bool swapWithUniswap,
        uint256 amountToSell
    ) external payable {
        weth.deposit{value: msg.value}();
        _mintFractionalARTHAndStake(
            pool,
            weth,
            msg.value,
            arthxAmount,
            arthOutMin,
            secs,
            stakingPool,
            swapWithUniswap,
            amountToSell
        );
    }

    function _mint1t1ARTHAndStake(
        IARTHPool pool,
        IERC20 collateral,
        uint256 amount,
        uint256 arthOutMin,
        uint256 secs,
        IBoostedStaking stakingPool
    ) internal {
        collateral.transferFrom(msg.sender, address(this), amount);

        // mint arth with 100% colalteral
        uint256 arthOut = pool.mint1t1ARTH(amount, arthOutMin);
        arth.approve(address(stakingPool), uint256(arthOut));

        if (address(stakingPool) != address(0)) {
            if (secs != 0)
                stakingPool.stakeLockedFor(msg.sender, arthOut, secs);
            else stakingPool.stakeFor(msg.sender, arthOut);
        }
    }

    function _mintAlgorithmicARTHAndStake(
        IARTHPool pool,
        uint256 arthxAmountD18,
        uint256 arthOutMin,
        uint256 secs,
        IBoostedStaking stakingPool
    ) internal {
        arthx.transferFrom(msg.sender, address(this), arthxAmountD18);

        // mint arth with 100% ARTHX
        uint256 arthOut = pool.mintAlgorithmicARTH(arthxAmountD18, arthOutMin);
        arth.approve(address(stakingPool), uint256(arthOut));

        if (address(stakingPool) != address(0)) {
            if (secs != 0)
                stakingPool.stakeLockedFor(msg.sender, arthOut, secs);
            else stakingPool.stakeFor(msg.sender, arthOut);
        }
    }

    function _mintFractionalARTHAndStake(
        IARTHPool pool,
        IERC20 collateral,
        uint256 amount,
        uint256 arthxAmount,
        uint256 arthOutMin,
        uint256 secs,
        IBoostedStaking stakingPool,
        bool swapWithUniswap,
        uint256 amountToSell
    ) internal {
        collateral.transferFrom(msg.sender, address(this), amount);

        // if we should buyback from Uniswap or use the arthx from the user's wallet
        if (swapWithUniswap) {
            _swapForARTHX(collateral, amountToSell, arthxAmount);
        } else {
            arthx.transferFrom(msg.sender, address(this), arthxAmount);
        }

        // mint the ARTH with ARTHX + Collateral
        uint256 arthOut =
            pool.mintFractionalARTH(amount, arthxAmount, arthOutMin);
        arth.approve(address(stakingPool), uint256(arthOut));

        // stake if necessary
        if (address(stakingPool) != address(0)) {
            if (secs != 0)
                stakingPool.stakeLockedFor(msg.sender, arthOut, secs);
            else stakingPool.stakeFor(msg.sender, arthOut);
        }
    }

    function _recollateralizeARTHAndStake(
        IARTHPool pool,
        IERC20 collateral,
        uint256 amount,
        uint256 arthxOutMin,
        uint256 secs,
        IBoostedStaking stakingPool
    ) internal {
        collateral.transferFrom(msg.sender, address(this), amount);

        uint256 arthxOut = pool.recollateralizeARTH(amount, arthxOutMin);
        arthx.approve(address(stakingPool), uint256(arthxOut));

        if (address(stakingPool) != address(0)) {
            if (secs != 0)
                stakingPool.stakeLockedFor(msg.sender, arthxOut, secs);
            else stakingPool.stakeFor(msg.sender, arthxOut);
        }
    }

    function _swapForARTHX(
        IERC20 tokenToSell,
        uint256 amountToSell,
        uint256 minAmountToRecieve
    ) internal {
        address[] memory path = new address[](2);
        path[0] = address(tokenToSell);
        path[1] = address(arthx);

        tokenToSell.transferFrom(msg.sender, address(this), amountToSell);

        router.swapExactTokensForTokens(
            amountToSell,
            minAmountToRecieve,
            path,
            address(this),
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBoostedStaking {
    function stakeLockedFor(
        address who,
        uint256 amount,
        uint256 duration
    ) external;

    function stakeFor(address who, uint256 amount) external;

    function stakeLocked(uint256 amount, uint256 secs) external;

    function withdrawLocked(bytes32 kekId) external;

    function getReward() external;

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function factory() external view returns (address);

    function WETH() external view returns (address);

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

import './IUniswapV2Router01.sol';

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 100000
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