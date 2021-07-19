/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/DCA.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;



contract DCA {
    
    address public constant UNISWAP_V2_ROUTER_02_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public uniswapRouter;
    address public immutable ERC20_ADDRESS;
    IERC20 public immutable erc20;

    struct DCAPool {
        uint256 latestConversionDate;
        uint256 interval;
        uint256 reward;
        uint256 endDate;
        address[] users;
    }

    struct UserData {
        uint256 balanceETH;
        uint256 balanceERC20;
        uint256 ethToSpendInIntervals;
        bool isInPool;
    }

    //Mapping of pools
    mapping(uint256 => DCAPool) public pools;
    uint256 public nextPoolId;
    //Users to data
    mapping(address => UserData) public users;

    constructor(address erc20Address) {
        uniswapRouter = IUniswapV2Router02(UNISWAP_V2_ROUTER_02_ADDRESS);
        ERC20_ADDRESS = erc20Address;
        erc20 = IERC20(erc20Address);
        nextPoolId = 0;
    }

    function addDCAPool(uint256 interval, uint256 reward, uint256 endDate) public {
        require(block.timestamp < endDate, "DCA: endDate must be in future");
        pools[nextPoolId++] = DCAPool(0, interval, reward, endDate, new address[](0));
    }

    function createUser(uint256 ethToSpendInIntervals) public {
        require(!_userExists(msg.sender), "DCA: user must not be created");
        require(ethToSpendInIntervals != 0, "DCA: ethToSpendInIntervals must not be 0");
        _createUser(msg.sender, ethToSpendInIntervals);
    }

    function updateUser(uint256 ethToSpendInIntervals) public {
        require(_userExists(msg.sender), "DCA: user must be created");
        require(users[msg.sender].isInPool, "DCA: user must not be in pool");
        require(ethToSpendInIntervals != 0, "DCA: ethToSpendInIntervals must not be 0");
        users[msg.sender].ethToSpendInIntervals = ethToSpendInIntervals;
    }

    function depositEth() public payable {
        require(_userExists(msg.sender), "DCA: user must be created");
        users[msg.sender].balanceETH += msg.value;
    }

    function withdrawEth() public {
        UserData memory user = users[msg.sender];
        require(!user.isInPool, "DCA: user must not be in pool");
        require(user.balanceETH != 0, "DCA: user must have an ETH balance");
        users[msg.sender].balanceETH = 0;
        payable(msg.sender).transfer(user.balanceETH);
    }

    function withdrawERC20() public {
        uint256 balance = users[msg.sender].balanceERC20;
        require(balance != 0, "DCA: user must have ERC20 balance");
        users[msg.sender].balanceERC20 = 0;
        erc20.transfer(msg.sender, balance);
    }
    
    function addUserToDCAPool(address user, uint256 poolId) public {
        //User must not be in pool, user must have enough ETH
        require(!users[user].isInPool, "DCA: user must not be in pool");
        require(_hasEnoughBalForPool(user, poolId), "DCA: user must have enough balance for the pool");
        //Add to pool
        pools[poolId].users.push(user);

        //Ensure invariant of being in the pool
        users[user].isInPool = true;
    }

    function executeConversion(uint256 poolId) public {
        DCAPool memory pool = pools[poolId];
        require(pool.latestConversionDate + pool.interval <= block.timestamp, "DCA: conversion must take place after the interval is up");

        uint256 totalEthToSpend = _sumPoolUsersEthToSpend(pool);
        
        //Avoid re-entry by setting state
        pools[poolId].latestConversionDate = block.timestamp;

        //Buy ERC20 over Uniswap with pooled ETH
        uint256[] memory purchasedAmounts = _uniswapExactETHForTokens(totalEthToSpend);

        //Update user balances
        _updateUserBalances(pool, purchasedAmounts);

        //Delete pool if needed
        if(block.timestamp + pool.interval > pool.endDate) {
            _deleteDCAPool(poolId);
        }

        //Finally, reward the caller for their kind call
        payable(msg.sender).transfer(pool.reward);
    }

    function _updateUserBalances(DCAPool memory pool, uint256[] memory purchasedAmounts) internal {
        //purchasedAmounts: [ETH, ERC20]
        uint256 userRewardPayment = pool.reward / pool.users.length;
        for(uint256 i = 0; i < pool.users.length; ++i) {
            users[pool.users[i]].balanceETH -= users[pool.users[i]].ethToSpendInIntervals + userRewardPayment;
            users[pool.users[i]].balanceERC20 += _calculateERC20Purchased(users[pool.users[i]].ethToSpendInIntervals, purchasedAmounts);
        }
    }

    /**
     * Using the total amount of ETH spent (purchasedAmounts[0]) and the total amount of ERC20
     * purchased (purchasedAmounts[1]), use the ETH spent by the user to calculate the ERC20 
     * purchased by the user. 
     * 
     * Note that this calculation assumes that total amount of ERC20 purchased, and the amount 
     * of ETH spent by the user, each generally fits within uint128, not exceeding 2^128-1. 
     * Otherwise, the multiplication may overflow and throw.
     * 
     * This function should ideally never cause this kind of overflow trouble given the 
     * unrealistically high number of Ether needed for the amount spent to cause a problem: 
     * the current supply of ETH, rounded upwards, is 117,000,000.
     * 
     * If we extrapolate from the 72,000,000 ETH since genesis, we can estimate 7.5 million ETH
     * mined a year. Naively assuming the rate is linear, we can calculate that 8.67 * 10^26 wei
     * will exist in 100 years, `Math.ceil(log2(8.67 * 10^26))`, or 90 bits, will be required to
     * store the total number of ETH in existence. 
     * 
     * An ERC20 token will have to require over 165 bits to truly cause an issue: 
     * around `2^165 * 10^-18`, or 4.67 * 10^31 in decimal in supply, assuming 18 decimals.
     */
    function _calculateERC20Purchased(uint256 ethSpent, uint256[] memory purchasedAmounts) internal pure returns (uint256) {
        return (ethSpent * purchasedAmounts[1]) / purchasedAmounts[0];
    }

    function _sumPoolUsersEthToSpend(DCAPool memory pool) internal view returns (uint256) {
        uint256 total = 0;
        for(uint256 i = 0; i < pool.users.length; ++i) {
            total += users[pool.users[i]].ethToSpendInIntervals;
        }
        return total;
    }

    function _createUser(address user, uint256 ethToSpendInIntervals) internal {
        users[user] = UserData(0, 0, ethToSpendInIntervals, false);
    }

    function _deleteDCAPool(uint256 poolId) internal {
        address[] memory memUsers = pools[poolId].users;
        for(uint256 i = 0; i < memUsers.length; ++i) {
            _removeUserFromDCAPool(memUsers[i]);
        }
        delete pools[poolId];
    }

    function _removeUserFromDCAPool(address user) internal {
        users[user].isInPool = false;
    }

    function _userExists(address user) internal view returns (bool) {
        //Because ethToSpendInIntervals must NEVER be 0 while the user exists,
        //we can double this as an invariant to check if the user exists
        return users[user].ethToSpendInIntervals != 0;
    }

    function _hasEnoughBalForPool(address user, uint256 poolId) internal view returns (bool) {
        return users[user].balanceETH >= _totalDCAPoolNewUserSpendings(user, poolId);
    }

    function _totalDCAPoolNewUserSpendings(address user, uint256 poolId) internal view returns (uint256) {
        DCAPool memory pool = pools[poolId];
        uint256 conversions = _calculateConversionsLeft(pool);
        //Calculate user reward needed
        uint256 userRewardNeeded = pool.reward / (pool.users.length + 1);
        return (users[user].ethToSpendInIntervals + userRewardNeeded) * conversions;
    }

    /**
     * Calculates the number of conversions between the range 
     * (latestConversionDate, pool.endDate] which is equivalent to the range
     * [latestConversionDate + interval, pool.endDate].
     * 
     * Simply put: the number of intervals of n between (a, b], where:
     *    a is pool.latestConversionDate
     *    b is pool.endDate
     *    n is pool.interval
     */
    function _calculateConversionsLeft(DCAPool memory pool) internal pure returns (uint256 conversions) {
        return (pool.endDate - pool.latestConversionDate) / pool.interval;
    }

    function _uniswapExactETHForTokens(uint256 ethAmount) internal returns (uint256[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH(); 
        path[1] = ERC20_ADDRESS;

        //Get minimum amount
        uint256[] memory minAmts = uniswapRouter.getAmountsOut(ethAmount, path);

        //Perform the swap
        return uniswapRouter.swapExactETHForTokens(minAmts[1], path, address(this), block.timestamp);
    }


}