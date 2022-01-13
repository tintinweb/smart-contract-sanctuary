pragma solidity >= 0.7.4;
pragma experimental ABIEncoderV2;

import "https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IStakersPoolV2.sol";
import "./interfaces/IStakingV2Controller.sol";
import "./interfaces/SafeMathUpgradeable.sol";

import "./IERC20.sol";

contract InsuraceDebug {
    using SafeMathUpgradeable for uint256;

    IUniswapV2Router02 public _uniswapRouter;
    IStakersPoolV2 public _stakersPool;
    IStakingV2Controller public _stakingController;
    
    uint256 constant PRECISION_5_DEC = 10**5;
    uint256 constant SECONDS_IN_THE_YEAR = 365 * 24 * 60 * 60;
    uint256 constant PRECISION_5_PERCENTAGE_100 = 100 * PRECISION_5_DEC;

    address _wethToken;
    address _insurToken;


    function __InsuraceDebug_init(
        address _routerAddress,
        address _stakersPoolAddress,
        address _stakingControllerAddress,
        address _insurTokenAddress,
        address _wethTokenAddress
    )external {
        _uniswapRouter = IUniswapV2Router02(_routerAddress);
        _stakersPool = IStakersPoolV2(_stakersPoolAddress);
        _stakingController = IStakingV2Controller(_stakingControllerAddress);
        _insurToken =_insurTokenAddress;
        _wethToken = _wethTokenAddress;
    }

    function apy(address stakingAsset, address swapRewardsVia) public view returns 
    (
        uint256 _apy,
        uint256 _poolTVLInRewardsAsset,
        uint256 _stakingDecimals,
        uint256 _insurInOneStaking,
        uint256 _poolTVLInStakingAsset,
        uint256 _rewardsPerYear) {
       
        address lpToken = _stakingController.tokenToLPTokenMap(stakingAsset);

        // R-sub-all : The total reward for all mining pools (in INSUR)
        uint256 _rewardsPB = _stakersPool.rewardPerBlock();
        // W = The weight of the mining pool
        uint256 _poolWeight = _stakersPool.poolWeightPT(lpToken);
        // W-sub-all = The sum of the weights of all mining pools
        uint256 _totalPoolWeight = _stakersPool.totalPoolWeight();

        uint256 _rewardsPerBlockPerPool =  _poolWeight.mul(_rewardsPB).div(_totalPoolWeight);
    

        uint256 _blocksYear = SECONDS_IN_THE_YEAR.div(15);
         _rewardsPerYear = _rewardsPerBlockPerPool.mul(_blocksYear);

        _poolTVLInStakingAsset = _stakersPool.getStakedAmountPT(stakingAsset);
       
        _stakingDecimals = IERC20(stakingAsset).decimals();
        _insurInOneStaking = _howManyTokensAinB(
            _insurToken,
            stakingAsset,
            swapRewardsVia,
            1 * 10**_stakingDecimals
        );
         _poolTVLInRewardsAsset = _poolTVLInStakingAsset.mul(_insurInOneStaking);

        //_poolTVLInRewardsAsset = _poolTVLInRewardsAsset.div(_stakingDecimals);

        _apy = _rewardsPerYear.mul(PRECISION_5_PERCENTAGE_100);//.div(_poolTVLInRewardsAsset);
    }


    function _howManyTokensAinB(
        address tokenA,
        address tokenB,
        address via,
        uint256 amount
    ) internal view  returns (uint256) {
        if (amount < 10 * 10**6) {
            //10 mWei
            return 0;
        }

        address[] memory pairs = new address[](3);
        pairs[0] = tokenB;
        if (via == address(0)) {
            pairs[1] = _wethToken;
        } else {
            pairs[1] = via;
        }
        pairs[2] = tokenA;

        uint256[] memory amounts = _uniswapRouter.getAmountsOut(amount, pairs);

        return amounts[amounts.length - 1];
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.7.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    
    function decimals() external view returns (uint256);
    
    // get symbol
    function symbol() external view returns (string memory);

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

library SafeMathUpgradeable {
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

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface IStakingV2Controller {
    function stakeTokens(uint256 _amount, address _token) external payable;

    // _token => _lpToken
    function tokenToLPTokenMap(address _token) external view returns (address);

    function proposeUnstake(uint256 _amount, address _token) external;

    function withdrawTokens(uint256 _amount, address _token) external;

    function showRewardsFromPools(address[] memory _tokenList) external view returns (uint256);

    function minStakeAmtPT(address _token) external view returns (uint256);

    function minUnstakeAmtPT(address _token) external view returns (uint256);

    function maxUnstakeAmtPT(address _token) external view returns (uint256);

    function totalStakedCapPT(address _token) external view returns (uint256);

    function withdrawFeePT(address _token) external view returns (uint256);

    function G_WITHDRAW_FEE_BASE() external view returns (uint256);

    function unstakeLockBlkPT(address _token) external view returns (uint256);

    function perAccountCapPT(address _token) external view returns (uint256);

    function stakersPoolV2() external view returns (address);
}

/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface IStakersPoolV2 {
    function addStkAmount(address _token, uint256 _amount) external payable;

    function rewardPerBlock() external view returns (uint256 _rewardPB);

    function totalPoolWeight() external view returns (uint256 _totalPoolWeight);

    function stakedAmountPT(address _token) external view returns (uint256);

    function poolWeightPT(address _token) external view returns (uint256 _poolWeight);

    function stkRewardsPerAPerLPT(address _lpToken, address _account)
        external
        view
        returns (uint256 _stkRewards);

    function harvestedRewardsPerAPerLPT(address _lpToken, address _account)
        external
        view
        returns (uint256 _harvestedRewards);

    function withdrawTokens(
        address payable _to,
        uint256 _amount,
        address _token,
        address _feePool,
        uint256 _fee
    ) external;

    function reCalcPoolPT(address _lpToken) external;

    function settlePendingRewards(address _account, address _lpToken) external;

    function harvestRewards(
        address _account,
        address _lpToken,
        address _to
    ) external returns (uint256);

    function getPoolRewardPerLPToken(address _lpToken) external view returns (uint256);

    function getStakedAmountPT(address _token) external view returns (uint256);

    function showPendingRewards(address _account, address _lpToken)
        external
        view
        returns (uint256);

    function showHarvestRewards(address _account, address _lpToken)
        external
        view
        returns (uint256);

    function claimPayout(
        address _fromToken,
        address _paymentToken,
        uint256 _settleAmtPT,
        address _claimToSettlementPool,
        uint256 _claimId,
        uint256 _fromRate,
        uint256 _toRate
    ) external;
}

pragma solidity >=0.7.4;

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