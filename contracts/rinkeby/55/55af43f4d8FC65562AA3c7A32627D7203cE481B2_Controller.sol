// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IStakingV2Controller.sol";
import "./IRewardController.sol";

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Controller {

    uint256 number;
    IUniswapV2Router02 router;
    IStakingV2Controller stakingController;
    IRewardController rewardsController;

    address DAI    = 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa;
    address INSUR  = 0xDe26469D4334059983CCC61251532C76CF5fBbB7;
    address WETH   = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address USDC   = 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b;
    address ETH    = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(){
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        rewardsController = IRewardController(0xEbDfc8626CC75eaF20ebA207c354b3FF564d86Be);
        stakingController = IStakingV2Controller(rewardsController.stakingController());
    }

    function depositToController(address _token, uint _amount) public {
        uint balance = IERC20(_token).balanceOf(msg.sender);
        balance = balance +0;
        require(balance >= _amount,"Insufficient amount");
        IERC20(_token).approve(address(this),_amount);
        IERC20(_token).transferFrom(msg.sender,address(this),_amount);
    }

    function approveController(address asset, uint256 amount) payable public {
        IERC20(asset).approve(address(this),amount);
        IERC20(asset).approve(address(stakingController),amount);
    }

    function transfreToController(address asset, uint256 amount) external {
         IERC20(asset).transferFrom(msg.sender,address(this),amount);
    }
    
    function stake(address _stakingAsset, uint amount) payable external {
            if (_stakingAsset == ETH) {
                stakingController.stakeTokens{value : amount}
                (amount,address(_stakingAsset));
            }else{
                 stakingController.stakeTokens(amount,_stakingAsset);
            }
    }

    function getMinStakeAmtPT(address token) public view returns(uint256 amount){
            amount = stakingController.minStakeAmtPT(token);
    }

    function getRewardsInfo() public  returns(uint256 vestingRewards, uint256 vestingReward){
        (vestingRewards,  vestingReward) = rewardsController.getRewardInfo();
    }

    function howManyTokenAinB(address tokenA, address tokenB, uint256 amount) 
        external view returns (uint amountA, uint amountB, uint liquidity) {

        address[] memory pairs = new address[](3);
        pairs[0] = tokenB;
        pairs[1] = WETH;
        pairs[2] = tokenA;

        uint256[] memory amounts = router.getAmountsOut(amount, pairs);

        amountA = amounts[0];
        amountB = amounts[1];
        amount = amounts[2];
        return ( amountA,  amountB,  liquidity) ;
        //return amounts[amounts.length - 1];
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

// solhint-disable-next-line no-empty-blocks
interface IRewardController {
    function insur() external returns (address);

    function stakingController() external returns (address);

    function vestingDuration() external returns (uint256);

    function vestingVestingAmountPerAccount(address _account) external returns (uint256);

    function vestingStartBlockPerAccount(address _account) external returns (uint256);

    function vestingEndBlockPerAccount(address _account) external returns (uint256);

    function vestingWithdrawableAmountPerAccount(address _account) external returns (uint256);

    function vestingWithdrawedAmountPerAccount(address _account) external returns (uint256);

    function unlockReward(
        address[] memory _tokenList,
        bool _bBuyCoverUnlockedAmt,
        bool _bClaimUnlockedAmt,
        bool _bReferralUnlockedAmt
    ) external;

    function getRewardInfo() external returns (uint256, uint256);

    function withdrawReward(uint256 _amount) external;
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.7.4;

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