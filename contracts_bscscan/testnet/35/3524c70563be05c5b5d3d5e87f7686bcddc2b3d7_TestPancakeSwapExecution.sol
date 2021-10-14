/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

interface IPancakeFactory {
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

interface IPancakePair {
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

interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {
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

interface MasterChef {

    function poolLength() external view returns (uint256);

    function updateStakingPool() external;

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) external;

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

    // View function to see pending CAKEs on frontend.
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() external;


    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) external;

    // Deposit LP tokens to MasterChef for CAKE allocation.
    function deposit(uint256 _pid, uint256 _amount) external;

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external;

    // Stake CAKE tokens to MasterChef
    function enterStaking(uint256 _amount) external;

    // Withdraw CAKE tokens from STAKING.
    function leaveStaking(uint256 _amount) external;

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external;

    // Safe cake transfer function, just in case if rounding error causes pool to not have enough CAKEs.
    function safeCakeTransfer(address _to, uint256 _amount) external;

    // Update dev address by the previous dev.
    function dev(address _devaddr) external;
    
    function poolInfo(uint256) external view returns (address, uint256, uint256, uint256);
    
    function userInfo(uint256, address) external view returns (uint256, uint256);
}

/// @title PancakeSwap execution
/// @author Andrew FU
/// @dev All functions haven't finished unit test
library TestPancakeSwapExecution {
    
    // Addresss of PancakeSwap.
    struct PancakeSwapConfig {
        address router; // Address of PancakeSwap router contract.
        address factory; // Address of PancakeSwap factory contract.
        address masterchef; // Address of PancakeSwap masterchef contract.
    }
    
    // Info of each pool.
    struct PoolInfo {
        address lpToken;           // Address of LP token contract.
        uint allocPoint;       // How many allocation points assigned to this pool. CAKEs to distribute per block.
        uint lastRewardBlock;  // Last block number that CAKEs distribution occurs.
        uint accCakePerShare; // Accumulated CAKEs per share, times 1e12. See below.
    }
    
    function getBalanceBNB(address wallet_address, address BNB_address) public view returns (uint) {
        
        return IBEP20(BNB_address).balanceOf(wallet_address);
    }
    
    function getLPBalance(address lp_token) public view returns (uint) {
        
        return IPancakePair(lp_token).balanceOf(address(this));
    }
    
    /// @param lp_token_address PancakeSwap LPtoken address.
    /// @dev Gets the token0 and token1 addresses from LPtoken.
    /// @return token0, token1.
    function getLPTokenAddresses(address lp_token_address) public view returns (address, address) {
        
        return (IPancakePair(lp_token_address).token0(), IPancakePair(lp_token_address).token1());
    }
    
    /// @param lp_token_address PancakeSwap LPtoken address.
    /// @dev Gets the token0 and token1 symbol name from LPtoken.
    /// @return token0, token1.
    function getLPTokenSymbols(address lp_token_address) public view returns (string memory, string memory) {
        (address token0, address token1) = getLPTokenAddresses(lp_token_address);
        return (IBEP20(token0).symbol(), IBEP20(token1).symbol());
    }
    
    /// @param self config of PancakeSwap.
    /// @param pool_id Id of the PancakeSwap pool.
    /// @dev Gets pool info from the masterchef contract and stores results in an array.
    /// @return pooInfo.
    function getPoolInfo(PancakeSwapConfig memory self, uint pool_id) public view returns (address, uint256, uint256, uint256) {
        
        return MasterChef(self.masterchef).poolInfo(pool_id);
    }
    
    function getReserves(address lp_token_address) public view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) {
        
        return IPancakePair(lp_token_address).getReserves();
    }

    /// @param self config of PancakeSwap.
    /// @param token_a_addr BEP20 token address.
    /// @param token_b_addr BEP20 token address.
    /// @dev Returns the LP token address for the token pairs.
    /// @return pair address.
    function getPair(PancakeSwapConfig memory self, address token_a_addr, address token_b_addr) public view returns (address) {
        
        return IPancakeFactory(self.factory).getPair(token_a_addr, token_b_addr);
    }
    
    /// @dev Will line up our assumption with the contracts.
    function lineUpPairs(address token_a_address, address token_b_address, uint data_a, uint data_b, address lp_token_address) public view returns (uint, uint) {
        address contract_token_0_address = IPancakePair(lp_token_address).token0();
        address contract_token_1_address = IPancakePair(lp_token_address).token1();
        
        if (token_a_address == contract_token_0_address && token_b_address == contract_token_1_address) {
            return (data_a, data_b);
        } else if (token_b_address == contract_token_0_address && token_a_address == contract_token_1_address) {
            return (data_b, data_a);
        } else {
            revert("No this pair");
        }
    }
    
    /// @param lp_token_amnt The LP token amount.
    /// @param lp_token_addr address of the LP token.
    /// @dev Returns the amount of token0, token1s the specified number of LP token represents.
    function getLPConstituients(uint lp_token_amnt, address lp_token_addr) public view returns (uint, uint) {
        (uint reserve0, uint reserve1, uint blockTimestampLast) = IPancakePair(lp_token_addr).getReserves();
        uint total_supply = IPancakePair(lp_token_addr).totalSupply();
        
        uint token_a_amnt = SafeMath.div(SafeMath.mul(reserve0, lp_token_amnt), total_supply);
        uint token_b_amnt = SafeMath.div(SafeMath.mul(reserve1, lp_token_amnt), total_supply);
        return (token_a_amnt, token_b_amnt);
    }
    
    /// @param self config of PancakeSwap.
    function getPendingStakedCake(PancakeSwapConfig memory self, uint pool_id) public view returns (uint) {
        
        return MasterChef(self.masterchef).pendingCake(pool_id, address(this));
    }
    
    /// @param self config of PancakeSwap.
    /// @param token_addr address of the BEP20 token.
    /// @param token_amnt amount of token to add.
    /// @param eth_amnt amount of BNB to add.
    /// @dev Adds a pair of tokens into a liquidity pool.
    function addLiquidityETH(PancakeSwapConfig memory self, address token_addr, address eth_addr, uint token_amnt, uint eth_amnt) public returns (uint) {
        IBEP20(token_addr).approve(self.router, token_amnt);
        (uint reserves0, uint reserves1, uint blockTimestampLast) = IPancakePair(IPancakeFactory(self.factory).getPair(token_addr, eth_addr)).getReserves();
        
        uint min_token_amnt = IPancakeRouter02(self.router).quote(token_amnt, reserves0, reserves1);
        uint min_eth_amnt = IPancakeRouter02(self.router).quote(eth_amnt, reserves1, reserves0);
        (uint amountToken, uint amountETH, uint amountLP) = IPancakeRouter02(self.router).addLiquidityETH{value: eth_amnt}(token_addr, token_amnt, min_token_amnt, min_eth_amnt, address(this), block.timestamp);
        
        return amountLP;
    }
    
    /// @param self config of PancakeSwap.
    /// @param token_a_addr address of the BEP20 token.
    /// @param token_b_addr address of the BEP20 token.
    /// @param a_amnt amount of token a to add.
    /// @param b_amnt amount of token b to add.
    /// @dev Adds a pair of tokens into a liquidity pool.
    function addLiquidity(PancakeSwapConfig memory self, address token_a_addr, address token_b_addr, uint a_amnt, uint b_amnt) public returns (uint){
        
        IBEP20(token_a_addr).approve(self.router, a_amnt);
        IBEP20(token_b_addr).approve(self.router, b_amnt);
        address pair = IPancakeFactory(self.factory).getPair(token_a_addr, token_b_addr);
        (uint reserves0, uint reserves1, uint blockTimestampLast) = IPancakePair(pair).getReserves();
    
        uint min_a_amnt = IPancakeRouter02(self.router).quote(a_amnt, reserves0, reserves1);
        uint min_b_amnt = IPancakeRouter02(self.router).quote(b_amnt, reserves1, reserves0);
        (uint amountA, uint amountB, uint amountLP) = IPancakeRouter02(self.router).addLiquidity(token_a_addr, token_b_addr, a_amnt, b_amnt, min_a_amnt, min_b_amnt, address(this), block.timestamp);
        
        return amountLP;
    }
    
    /// @param self config of PancakeSwap.
    /// @param lp_contract_addr address of the BEP20 token.
    /// @param token_a_addr address of the BEP20 token.
    /// @param token_b_addr address of the BEP20 token.
    /// @param liquidity amount of LP tokens to be removed.
    /// @param a_amnt amount of token a to remove.
    /// @param b_amnt amount of token b to remove.
    /// @dev Removes a pair of tokens from a liquidity pool.
    function removeLiquidity(PancakeSwapConfig memory self, address lp_contract_addr, address token_a_addr, address token_b_addr, uint liquidity, uint a_amnt, uint b_amnt) public {
        
        IBEP20(lp_contract_addr).approve(self.router, liquidity);
        IPancakeRouter02(self.router).removeLiquidity(token_a_addr, token_b_addr, liquidity, a_amnt, b_amnt, address(this), block.timestamp);
    }
    
    /// @param self config of PancakeSwap.
    /// @param lp_contract_addr address of the BEP20 token.
    /// @param token_addr address of the BEP20 token.
    /// @param liquidity amount of LP tokens to be removed.
    /// @param a_amnt amount of token a to remove.
    /// @param b_amnt amount of BNB to remove.
    /// @dev Removes a pair of tokens from a liquidity pool.
    function removeLiquidityETH(PancakeSwapConfig memory self, address lp_contract_addr, address token_addr, uint liquidity, uint a_amnt, uint b_amnt) public {
        
        IBEP20(lp_contract_addr).approve(self.router, liquidity);
        IPancakeRouter02(self.router).removeLiquidityETH(token_addr, liquidity, a_amnt, b_amnt, address(this), block.timestamp);
    }
    
    /// @param self config of PancakeSwap.
    function getAmountsOut(PancakeSwapConfig memory self, address token_a_address, address token_b_address) public view returns (uint) {
        uint token_a_decimals = IBEP20(token_a_address).decimals();
        uint min_amountIn = SafeMath.mul(1, 10**token_a_decimals);
        address pair = IPancakeFactory(self.factory).getPair(token_a_address, token_b_address);
        (uint reserve0, uint reserve1, uint blockTimestampLast) = IPancakePair(pair).getReserves();
        uint price = IPancakeRouter02(self.router).getAmountOut(min_amountIn, reserve0, reserve1);
        
        return price;
    }
    
    /// @param lp_token_address address of the LP token.
    /// @dev Gets the current price for a pair.
    function getPairPrice(address lp_token_address) public view returns (uint) {
        (uint reserve0, uint reserve1, uint blockTimestampLast) = IPancakePair(lp_token_address).getReserves();
        return reserve0 + reserve1;
    }
    
    /// @param self config of PancakeSwap.
    /// @param pool_id Id of the PancakeSwap pool.
    /// @dev Gets the current number of LP tokens staked in the pool.
    function getStakedLP(PancakeSwapConfig memory self, uint pool_id) public view returns (uint) {
        (uint amount, uint rewardDebt) = MasterChef(self.masterchef).userInfo(pool_id, address(this));
        return amount;
    }

    /// @param self config of PancakeSwap.
    /// @param pool_id Id of the PancakeSwap pool.
    /// @dev Gets the pending CAKE amount for a partictular pool_id.
    function getPendingFarmRewards(PancakeSwapConfig memory self, uint pool_id) public view returns (uint) {
        
        return MasterChef(self.masterchef).pendingCake(pool_id, address(this));
    }
    
    /// @param self config of PancakeSwap.
    /// @param pool_id Id of the PancakeSwap pool.
    /// @param unstake_amount amount of LP tokens to unstake.
    /// @dev Removes 'unstake_amount' of LP tokens from 'pool_id'.
    function unstakeLP(PancakeSwapConfig memory self, uint pool_id, uint unstake_amount) public returns (bool) {
        MasterChef(self.masterchef).withdraw(pool_id, unstake_amount);
        return true;
    }
    
    /// @param self config of PancakeSwap.
    /// @param token_address address of BEP20 token.
    /// @param USDT_address address of USDT token.
    /// @dev Returns the USD price for a particular BEP20 token.
    function getTokenPriceUSD(PancakeSwapConfig memory self, address token_address, address USDT_address) public view returns (uint) {
        uint token_decimals = IBEP20(token_address).decimals();
        uint min_amountIn = SafeMath.mul(1, 10**token_decimals);
        address pair = IPancakeFactory(self.factory).getPair(token_address, USDT_address);
        (uint reserve0, uint reserve1, uint blockTimestampLast) = IPancakePair(pair).getReserves();
        uint price = IPancakeRouter02(self.router).getAmountOut(min_amountIn, reserve0, reserve1);
        return price;
    }
    
    /// @param self config of PancakeSwap.
    /// @param pool_id Id of the PancakeSwap pool.
    /// @param stake_amount amount of LP tokens to stake.
    /// @dev Gets pending reward for the user from the specific pool_id.
    function stakeLP(PancakeSwapConfig memory self, uint pool_id, uint stake_amount) public returns (bool) {
        MasterChef(self.masterchef).deposit(pool_id, stake_amount);
        return true;
    }
    
    /// @param token_addr address of BEP20 token.
    /// @param stake_contract_addr address of PancakeSwap masterchef.
    /// @param amount amount of CAKE tokens to stake.
    /// @dev Enables a syrup staking pool on PancakeSwap.
    function enablePool(address token_addr, address stake_contract_addr, uint amount) public returns (bool) {
        IBEP20(token_addr).approve(stake_contract_addr, amount);
        return true;
    }
    
    /// @param lp_token_address address of PancakeSwap LPtoken.
    /// @dev Enables a syrup staking pool on PancakeSwap.
    function enableFarm(address lp_token_address) public returns (bool) {
        IBEP20(lp_token_address).approve(0x73feaa1eE314F8c655E354234017bE2193C9E24E, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        return true;
    }
    
    /// @param self config of PancakeSwap.
    /// @param pool_id Id of the PancakeSwap pool.
    /// @dev Get the number of tokens staked into the pool.
    function getStakedPoolTokens(PancakeSwapConfig memory self, uint pool_id) public view returns (uint) {
        (uint amount, uint rewardDebt) = MasterChef(self.masterchef).userInfo(pool_id, address(this));
        return amount;
    }
    
    /// @param self config of PancakeSwap.
    /// @param pool_id Id of the PancakeSwap pool.
    /// @dev Gets pending reward for the syrup pool.
    function getPendingPoolRewards(PancakeSwapConfig memory self, uint pool_id) public view returns (uint) {
        
        return MasterChef(self.masterchef).pendingCake(pool_id, address(this));
    }
    
    /// @param self config of PancakeSwap.
    /// @param pool_id Id of the PancakeSwap pool.
    /// @param stake_amount amount of CAKE tokens to stake.
    /// @dev Adds 'stake_amount' of coins into the syrup pools.
    function stakePool(PancakeSwapConfig memory self, uint pool_id, uint stake_amount) public returns (bool) {
        MasterChef(self.masterchef).deposit(pool_id, stake_amount);
        return true;
    }
    
    /// @param self config of PancakeSwap.
    /// @param pool_id Id of the PancakeSwap pool.
    /// @param unstake_amount amount of CAKE tokens to unstake.
    /// @dev Removes 'unstake_amount' of coins into the syrup pools.
    function unstakePool(PancakeSwapConfig memory self, uint pool_id, uint unstake_amount) public returns (bool) {
        MasterChef(self.masterchef).withdraw(pool_id, unstake_amount);
        return true;
    }

    function splitTokensEvenly(uint token_a_bal, uint token_b_bal, uint pair_price, uint price_decimals) public pure returns (uint, uint) {
        uint temp = SafeMath.mul(1, 10**price_decimals);
        uint a_amount_required = SafeMath.div(SafeMath.mul(token_b_bal, temp), pair_price);
        uint b_amount_required = SafeMath.div(SafeMath.mul(token_a_bal, temp), pair_price);
        if (token_a_bal > a_amount_required) {
            return (a_amount_required, token_b_bal);
        } else if (token_b_bal > b_amount_required) {
            return (token_a_bal, b_amount_required);
        } else {
            return (0, 0);
        }
    }

    function getPairDecimals(address pair_address) public pure returns (uint) {
        
        return IPancakePair(pair_address).decimals();
    }
    
}