/**
 *Submitted for verification at Etherscan.io on 2021-07-20
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



/**
 * Dollar-Cost Averaging Pool Contract over Uniswap V2
 * 
 * Allows users to join a pool of other users, where the pool is set to a specific interval,
 * end date, and reward. A user is bound to the pool for as long as the pool exists.
 *
 * The conversion function totals the users' desired token amounts and swaps them over Uniswap.
 * Here's where the incentivization comes in: the caller of the conversion function receives 
 * a set pool reward. Therefore, there is monetary gain in calling the function and performing 
 * the conversion at the correct interval as soon as it is becomes available.
 * 
 * For the sake of simplicity, a user cannot withdraw any ETH for as long as the user is in
 * the pool. This is to ensure that the user has enough ETH to pay their portion of any
 * pool rewards, and to swap on every possible conversion at every interval, which is useful
 * as an invariant when implementing the conversion function. Similarly, a user cannot update
 * the amount of ETH they would like to spend on each interval (although it would be possible
 * to allow by checking to see if there is enough ETH deposited). Furthermore, a user can only 
 * be subscribed to one pool on the contract at a time.
 * 
 * If executeConversion() notices no more conversions are possible, it will clean up and 
 * remove all users from the pool. Otherwise, deleteDCAPool() will need to be called to
 * free all users from an expired pool.
 *
 * For simplicity, a user withdraws the total amount of their ETH or ERC20 on withdrawEth()
 * and withdrawERC20().
 * 
 * All of the public-facing functions involving users operate solely on msg.sender as the user.
 * 
 * The general flow may look like the following:
 *   1. addDCAPool() - Create a new pool
 *   2. createUser() - Create a new user
 *   3. depositEth() - Deposit ETH into the user
 *   4. addUserToDCAPool() - Add user to the created pool
 *   5. executeConversion() - Execute the conversion for the pool
 */
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
        require(reward > 0, "DCA: pool must have non-zero reward");
        require(interval > 0, "DCA: pool must have non-zero interval");
        pools[nextPoolId] = DCAPool(0, interval, reward, endDate, new address[](0));
        emit AddedDCAPool(nextPoolId, interval, reward, endDate);
        ++nextPoolId;
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
        _updateUser(msg.sender, ethToSpendInIntervals);
    }

    function depositEth() public payable {
        require(_userExists(msg.sender), "DCA: user must be created");
        users[msg.sender].balanceETH += msg.value;
        emit DepositedETH(msg.sender, users[msg.sender].balanceETH);
    }

    function withdrawEth() public {
        UserData memory user = users[msg.sender];
        require(!user.isInPool, "DCA: user must not be in pool");
        require(user.balanceETH != 0, "DCA: user must have an ETH balance");
        users[msg.sender].balanceETH = 0;
        payable(msg.sender).transfer(user.balanceETH);
        emit WithdrewETH(msg.sender, user.balanceETH);
    }

    function withdrawERC20() public {
        uint256 balance = users[msg.sender].balanceERC20;
        require(balance != 0, "DCA: user must have ERC20 balance");
        users[msg.sender].balanceERC20 = 0;
        erc20.transfer(msg.sender, balance);
        emit WithdrewERC20(msg.sender, balance);
    }
    
    function addUserToDCAPool(uint256 poolId) public {
        DCAPool memory pool = pools[poolId];
        address user = msg.sender;
        require(_poolExists(pool), "DCA: pool must exist");
        require(!_poolFinished(pool), "DCA: pool must not have finished");
        require(!users[user].isInPool, "DCA: user must not be in pool");
        require(_hasEnoughBalForPool(user, pool), "DCA: user must have enough balance for the pool");
        _addUserToDCAPool(user, poolId);
    }

    /**
     * Executes a conversion for the pool at poolId, if the timing is correct (after the
     * interval passes since the latest date of conversion, which is 0 when the pool is
     * new and thus has not started).
     *
     * The caller of this function will receive the pool reward specified in the pool for
     * performing the execution.
     * 
     * If no more conversions are possible past this point, the pool will be deleted,
     * freeing the users up to withdraw their ETH balances and removing the pool from
     * storage.
     */
    function executeConversion(uint256 poolId) public {
        DCAPool memory pool = pools[poolId];
        require(_poolExists(pool), "DCA: pool must exist");
        require(pool.latestConversionDate + pool.interval < block.timestamp, "DCA: conversion must take place after the interval is up");
        require(!_poolFinished(pool), "DCA: pool must not have finished");

        uint256 totalEthToSpend = _sumPoolUsersEthToSpend(pool);
        
        //Avoid re-entry by setting state
        pools[poolId].latestConversionDate = block.timestamp;

        //Buy ERC20 over Uniswap with pooled ETH
        uint256[] memory purchasedAmounts = _uniswapExactETHForTokens(totalEthToSpend);

        //Update user balances
        _updateUserBalances(pool, purchasedAmounts);

        //Delete pool if needed, i.e., if no more conversions are possible past now
        if(block.timestamp + pool.interval > pool.endDate) {
            _deleteDCAPool(poolId);
        }

        //Finally, reward the caller for their kind call
        payable(msg.sender).transfer(pool.reward);
        emit ExecutedConversion(msg.sender, purchasedAmounts[0], purchasedAmounts[1], pool.reward);
    }

    /**
     * Deletes the pool at poolId, as long as the pool has finished. 
     */
    function deleteDCAPool(uint256 poolId) public {
        DCAPool memory pool = pools[poolId];
        require(_poolExists(pool), "DCA: pool must exist");
        require(_poolFinished(pool), "DCA: pool must have finished");
        _deleteDCAPool(poolId);
    }

    function _createUser(address user, uint256 ethToSpendInIntervals) internal {
        users[user] = UserData(0, 0, ethToSpendInIntervals, false);
        emit CreatedUser(user, ethToSpendInIntervals);
    }
    
    function _updateUser(address user, uint256 ethToSpendInIntervals) internal {
        users[user].ethToSpendInIntervals = ethToSpendInIntervals;
        emit UpdatedUser(user, ethToSpendInIntervals);
    }

    /**
     * Adds user to the pool at poolId.
     */
    function _addUserToDCAPool(address user, uint256 poolId) internal {
        pools[poolId].users.push(user);
        users[user].isInPool = true;
        emit AddedUserToDCAPool(user, poolId);
    }

    /**
     * Updates user balances according to pool and the details of the Uniswap market sell.
     * The purchasedAmounts array must contain the input ETH followed by the output ERC20.
     * 
     * On implementation:
     *
     * Integer division is used to determine the slice of pool reward each user owes, 
     * which can cause accuracy loss as the numbers round towards 0. Thankfully, we can
     * obtain the residual value though modulo, which is guaranteed to be `a - (n * q)`
     * where `q = a / n`. The possible residuals fall within the range [0, n), where n
     * is the number of users in the pool. However, we will only be entering the first
     * loop for [1, n), meaning that the function spreads the payment evenly even in the
     * case of no residual.
     * 
     * This eliminates any potential error, alongside any ETH "dust" that might emerge
     * from inaccuracies in integer division.
     */
    function _updateUserBalances(DCAPool memory pool, uint256[] memory purchasedAmounts) internal {
        uint256 userRewardPayment = pool.reward / pool.users.length;
        uint256 residual = pool.reward % pool.users.length;
        uint256 i = 0;
        for(; i < pool.users.length && residual != 0; ++i) {
            users[pool.users[i]].balanceETH -= users[pool.users[i]].ethToSpendInIntervals + userRewardPayment + 1;
            users[pool.users[i]].balanceERC20 += _calculateERC20Purchased(users[pool.users[i]].ethToSpendInIntervals, purchasedAmounts);
            --residual;
        }

        for(; i < pool.users.length; ++i) {
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
     * around `2^165 * 10^-18`, or 4.67 * 10^31 in decimal in supply, excluding typical 18 decimals.
     *
     * It should be noted that this integer division will cause ERC20 "dust" to accumulate within
     * the smart contract, which, although not perfect, is not a practical problem.
     */
    function _calculateERC20Purchased(uint256 ethSpent, uint256[] memory purchasedAmounts) internal pure returns (uint256) {
        return (ethSpent * purchasedAmounts[1]) / purchasedAmounts[0];
    }

    /**
     * Returns the total ETH users will spend on conversion within the pool passed.
     */
    function _sumPoolUsersEthToSpend(DCAPool memory pool) internal view returns (uint256) {
        uint256 total = 0;
        for(uint256 i = 0; i < pool.users.length; ++i) {
            total += users[pool.users[i]].ethToSpendInIntervals;
        }
        return total;
    }

    function _deleteDCAPool(uint256 poolId) internal {
        address[] memory memUsers = pools[poolId].users;
        for(uint256 i = 0; i < memUsers.length; ++i) {
            _removeUserFromDCAPool(memUsers[i]);
        }
        delete pools[poolId];
        emit DeletedDCAPool(poolId);
    }

    function _removeUserFromDCAPool(address user) internal {
        users[user].isInPool = false;
    }

    /**
     * Returns true if the user exists, and false otherwise.
     * 
     * On implementation:
     * 
     * Because users[user].ethToSpendInIntervals must *never* be 0 while the user
     * exists, we can use this invariant to double as a check for the user's existence.
     */
    function _userExists(address user) internal view returns (bool) {
        return users[user].ethToSpendInIntervals != 0;
    }

    /**
     * Returns true if the user has enough ETH balance to join the pool, and false otherwise.
     */
    function _hasEnoughBalForPool(address user, DCAPool memory pool) internal view returns (bool) {
        return users[user].balanceETH >= _totalDCAPoolNewUserSpendings(user, pool);
    }

    /**
     * Returns the total amount of ETH the user will spend as a member of the pool passed.
     * Reward calculations thus take into account the user as an additional member sharing
     * a portion of reward payment.
     */
    function _totalDCAPoolNewUserSpendings(address user, DCAPool memory pool) internal view returns (uint256) {
        uint256 conversions = _calculateConversionsLeft(pool);
        //Calculate user reward needed
        uint256 userRewardNeeded = pool.reward / (pool.users.length + 1);
        return (users[user].ethToSpendInIntervals + userRewardNeeded) * conversions;
    }

    /**
     * Calculates the number of conversions left within a pool. If the pool is still new,
     * or the current block timestamp is greater than the earliest valid date from the
     * latest conversion date - 1, the current block timestamp is used as the left end of the range 
     * to calculate the number of conversions that may occur in the pool's future.
     * 
     * Otherwise, the earliest valid date from the latest conversion date - 1 is used for the
     * left end of the range to calculate the number of conversions.
     * 
     * NOTE: This function will provide an invalid result *if* the pool is finished. (In other
     * words, if p.endDate < block.timestamp).
     * 
     * Please ensure that the pool is not over before calling this function, or the result
     * of the function will be invalid.
     */
    function _calculateConversionsLeft(DCAPool memory p) internal view returns (uint256 conversions) {
        return !_poolStarted(p) || block.timestamp > p.latestConversionDate + p.interval - 1
            ? _calculateNumIntervalsInRange(block.timestamp, p.endDate, p.interval)
            : _calculateNumIntervalsInRange(p.latestConversionDate + p.interval - 1, p.endDate, p.interval);
    }

    /**
     * Calculates the number of intervals of n between (a, b], where b > a.
     * The result of the function is undefined if b <= a.
     */
    function _calculateNumIntervalsInRange(uint256 a, uint256 b, uint256 n) internal pure returns (uint256) {
        return (b - a) / n;
    }

    /**
     * Returns true if the pool has started, and false otherwise.
     * 
     * On implementation:
     * 
     * Because pool.latestConversionDate will always be non-zero after the first conversion, 
     * (thus having started) we can use this invariant to double as a check for the pool's status.
     */
    function _poolStarted(DCAPool memory pool) internal pure returns (bool) {
        return pool.latestConversionDate != 0;
    }

    /**
     * Returns true if the pool exists, and false otherwise.
     * 
     * On implementation:
     * 
     * Because pool.interval must *never* be 0 in a valid created pool, we can use 
     * this invariant to double as a check for the pool's existence.
     */
    function _poolExists(DCAPool memory pool) internal pure returns (bool) {
        return pool.interval != 0;
    }
    
    /**
     * Returns true if the pool is finished (i.e. has expired).
     *
     * On implementation:
     *
     * The end date in inclusively a date in the range of valid dates on which a conversion
     * can be performed: therefore, the < operator is selected very deliberately.
     */ 
    function _poolFinished(DCAPool memory pool) internal view returns (bool) {
        return pool.endDate < block.timestamp;
    }

    /**
     * Performs a swap over Uniswap V2, swapping ethAmount ETH for the ERC20 set in the contract.
     * Returns an array representing the amount of ETH input in the first element, for the amount
     * of the ERC20 obtained in the second element.
     */
    function _uniswapExactETHForTokens(uint256 ethAmount) internal returns (uint256[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH(); 
        path[1] = ERC20_ADDRESS;

        //Get minimum amount
        uint256[] memory minAmts = uniswapRouter.getAmountsOut(ethAmount, path);

        //Perform the swap
        return uniswapRouter.swapExactETHForTokens{value: ethAmount}(minAmts[1], path, address(this), block.timestamp);
    }

    event AddedDCAPool(uint256 indexed poolId, uint256 interval, uint256 reward, uint256 endDate);
    event CreatedUser(address indexed user, uint256 ethToSpendInIntervals);
    event UpdatedUser(address indexed user, uint256 ethToSpendInIntervals);
    event DepositedETH(address indexed user, uint256 newBalance);
    event WithdrewETH(address indexed user, uint256 amount);
    event WithdrewERC20(address indexed user, uint256 amount);
    event AddedUserToDCAPool(address indexed user, uint256 amount);
    event ExecutedConversion(address indexed caller, uint256 spentETH, uint256 purchasedERC20,
                            uint256 reward);
    event DeletedDCAPool(uint256 indexed poolId);

}