// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "../token/BEP20/IBEP20.sol";
import "../math/SafeMath.sol";
import "../interfaces/chainlink/AggregatorInterface.sol";
import "../interfaces/cream/CErc20Delegator.sol";
import "../interfaces/cream/ComptrollerInterface.sol";
import "../interfaces/pancakeswap/IPancakePair.sol";
import "../interfaces/pancakeswap/IPancakeFactory.sol";
import "../interfaces/pancakeswap/MasterChef.sol";
import "../interfaces/pancakeswap/IPancakeRouter02.sol";

/// @title High level system execution
/// @author Andrew FU
/// @dev All functions haven't finished unit test
library HighLevelSystem {    

    using SafeMath for uint256;

    // HighLevelSystem config
    struct HLSConfig {
        address token_oracle; // Address of Link oracle contract.
        address token_a_oracle; // Address of Link oracle contract.
        address token_b_oracle; // Address of Link oracle contract.
        address cake_oracle; // Address of Link oracle contract.
        address router; // Address of PancakeSwap router contract.
        address factory; // Address of PancakeSwap factory contract.
        address masterchef; // Address of PancakeSwap masterchef contract.
        address CAKE; // Address of ERC20 CAKE contract.
        address comptroller; // Address of cream comptroller contract.
    }
    
    // Position
    struct Position {
        uint256 pool_id;
        uint256 token_amount;
        uint256 token_a_amount;
        uint256 token_b_amount;
        uint256 lp_token_amount;
        uint256 crtoken_amount;
        uint256 supply_crtoken_amount;
        address token;
        address token_a;
        address token_b;
        address lp_token;
        address supply_crtoken;
        address borrowed_crtoken_a;
        address borrowed_crtoken_b;
        uint256 supply_funds_percentage;
        uint256 total_depts;
    }

    /// @param _position refer Position struct on the top.
    /// @dev Supplies 'amount' worth of tokens to cream.
    function _supplyCream(Position memory _position) private returns(Position memory) {
        uint256 supply_amount = IBEP20(_position.token).balanceOf(address(this)).mul(_position.supply_funds_percentage).div(100);
        
        require(CErc20Delegator(_position.supply_crtoken).mint(supply_amount) == 0, "Supply not work");

        // Update posititon amount data
        _position.token_amount = IBEP20(_position.token).balanceOf(address(this));
        _position.crtoken_amount = IBEP20(_position.supply_crtoken).balanceOf(address(this));
        _position.supply_crtoken_amount = supply_amount;

        return _position;
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Borrow the required tokens for a given position on CREAM.
    function _borrowCream(HLSConfig memory self, Position memory _position) private returns(Position memory) {
        uint256 token_value = _position.supply_crtoken_amount.mul(75).div(100);
        token_value = token_value.mul(375).div(1000);
        uint256 token_price = uint256(AggregatorInterface(self.token_oracle).latestAnswer());
        uint256 token_a_price = uint256(AggregatorInterface(self.token_a_oracle).latestAnswer()).mul(10**8);
        uint256 token_b_price = uint256(AggregatorInterface(self.token_b_oracle).latestAnswer()).mul(10**8);
        // Borrow token_a amount
        uint256 token_a_rate = token_a_price.div(token_price);
        uint256 token_a_borrow_amount = token_value.div(token_a_rate).mul(10**8);
        // Borrow token_b amount
        uint256 token_b_rate = token_b_price.div(token_price);
        uint256 token_b_borrow_amount = token_value.div(token_b_rate).mul(10**8);
        
        require(CErc20Delegator(_position.borrowed_crtoken_a).borrow(token_a_borrow_amount) == 0, "Borrow token a not work");
        require(CErc20Delegator(_position.borrowed_crtoken_b).borrow(token_b_borrow_amount) == 0, "Borrow token b not work");

        // Update posititon amount data
        _position.token_a_amount = IBEP20(_position.token_a).balanceOf(address(this));
        _position.token_b_amount = IBEP20(_position.token_b).balanceOf(address(this));

        return _position;
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _position refer Position struct on t he top.
    /// @dev Adds liquidity to a given pool.
    function _addLiquidity(HLSConfig memory self, Position memory _position) private returns (Position memory) {
        uint256 max_available_staking_a = IBEP20(_position.token_a).balanceOf(address(this));
        uint256 max_available_staking_b = IBEP20(_position.token_b).balanceOf(address(this));
        
        uint256 max_available_staking_a_slippage = max_available_staking_a.mul(98).div(100);
        uint256 max_available_staking_b_slippage = max_available_staking_b.mul(98).div(100);

        (uint256 reserves0, uint256 reserves1, ) = IPancakePair(_position.lp_token).getReserves();
        uint256 min_a_amnt = IPancakeRouter02(self.router).quote(max_available_staking_b_slippage, reserves1, reserves0);
        uint256 min_b_amnt = IPancakeRouter02(self.router).quote(max_available_staking_a_slippage, reserves0, reserves1);

        min_a_amnt = max_available_staking_a_slippage.min(min_a_amnt);
        min_b_amnt = max_available_staking_b_slippage.min(min_b_amnt);

        IPancakeRouter02(self.router).addLiquidity(_position.token_a, _position.token_b, max_available_staking_a, max_available_staking_b, min_a_amnt, min_b_amnt, address(this), block.timestamp);
        
        // Update posititon amount data
        _position.lp_token_amount = IBEP20(_position.lp_token).balanceOf(address(this));
        _position.token_a_amount = IBEP20(_position.token_a).balanceOf(address(this));
        _position.token_b_amount = IBEP20(_position.token_b).balanceOf(address(this));

        return _position;
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Stakes LP tokens into a farm.
    function _stake(HLSConfig memory self, Position memory _position) private returns (Position memory) {
        MasterChef(self.masterchef).deposit(_position.pool_id, IBEP20(_position.lp_token).balanceOf(address(this)));

        // Update posititon amount data
        _position.lp_token_amount = IBEP20(_position.lp_token).balanceOf(address(this));

        return _position;
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _position refer Position struct on the top.
    /// @param _type enter type.
    /// @dev Main entry function to borrow and enter a given position.
    function enterPosition(HLSConfig memory self, Position memory _position, uint256 _type) external returns (Position memory) {
        
        if (_type == 1) {
            // Supply position
            _position = _supplyCream(_position);
        }
        
        if (_type == 1 || _type == 2) {
            // Borrow
            _position = _borrowCream(self, _position);
        }
        
        if (_type == 1 || _type == 2 || _type == 3) {
            // Add liquidity
            _position = _addLiquidity(self, _position);

            // Stake
            _position = _stake(self, _position);
        }
        
        _position.total_depts = getTotalDebts(self, _position);

        return _position;
    }

    /// @param _position refer Position struct on the top.
    /// @dev Redeem amount worth of crtokens back.
    function _redeemCream(Position memory _position) private returns (Position memory) {
        uint256 redeem_amount = IBEP20(_position.supply_crtoken).balanceOf(address(this));
        redeem_amount = redeem_amount.mul(999999).div(1000000);
        require(CErc20Delegator(_position.supply_crtoken).redeem(redeem_amount) == 0, "Redeem not work");

        // Update posititon amount data
        _position.crtoken_amount = IBEP20(_position.supply_crtoken).balanceOf(address(this));
        _position.supply_crtoken_amount = 0;

        return _position;
    }

    /// @param _position refer Position struct on the top.
    /// @dev Repay the tokens borrowed from cream.
    function _repay(Position memory _position) private returns (Position memory) {
        // uint256 a_repay_amount = CErc20Delegator(_position.borrowed_crtoken_a).borrowBalanceStored(address(this));
        // uint256 b_repay_amount = CErc20Delegator(_position.borrowed_crtoken_b).borrowBalanceStored(address(this));
        uint256 a_repay_amount = IBEP20(_position.token_a).balanceOf(address(this));
        uint256 b_repay_amount = IBEP20(_position.token_b).balanceOf(address(this));

        require(CErc20Delegator(_position.borrowed_crtoken_a).repayBorrow(a_repay_amount) == 0, "Repay token a not work");
        require(CErc20Delegator(_position.borrowed_crtoken_b).repayBorrow(b_repay_amount) == 0, "Repay token b not work");

        // Update posititon amount data
        _position.token_a_amount = IBEP20(_position.token_a).balanceOf(address(this));
        _position.token_b_amount = IBEP20(_position.token_b).balanceOf(address(this));

        return _position;
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Removes liquidity from a given pool.
    function _removeLiquidity(HLSConfig memory self, Position memory _position) private returns (Position memory) {
        (uint256 reserve0, uint256 reserve1, uint256 blockTimestampLast) = IPancakePair(_position.lp_token).getReserves();
        uint256 total_supply = IPancakePair(_position.lp_token).totalSupply();
        uint256 token_a_amnt = reserve0.mul(_position.lp_token_amount).div(total_supply);
        uint256 token_b_amnt = reserve1.mul(_position.lp_token_amount).div(total_supply);

        IPancakeRouter02(self.router).removeLiquidity(_position.token_a, _position.token_b, _position.lp_token_amount, token_a_amnt, token_b_amnt, address(this), block.timestamp);

        // Update posititon amount data
        _position.lp_token_amount = IBEP20(_position.lp_token).balanceOf(address(this));
        _position.token_a_amount = IBEP20(_position.token_a).balanceOf(address(this));
        _position.token_b_amount = IBEP20(_position.token_b).balanceOf(address(this));

        return _position;
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Removes liquidity from a given farm.
    function _unstake(HLSConfig memory self, Position memory _position) private returns (Position memory) {
        (uint256 lp_amount, uint256 rewardDebt) = MasterChef(self.masterchef).userInfo(_position.pool_id, address(this));
        
        MasterChef(self.masterchef).withdraw(_position.pool_id, lp_amount);

        // Update posititon amount data
        _position.lp_token_amount = IBEP20(_position.lp_token).balanceOf(address(this));

        return _position;
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Main exit function to exit and repay a given position.
    function exitPosition(HLSConfig memory self, Position memory _position, uint256 _type) external returns (Position memory) {
        
        if (_type == 1 || _type == 2 || _type == 3) {
            // Unstake
            _position = _unstake(self, _position);
            
            // Unstake
            _position = _removeLiquidity(self, _position);
        }
        
        if (_type == 1 || _type == 2) {
            // Repay
            _position = _repay(_position);
        }
        
        if (_type == 1) {
            // Redeem
            _position = _redeemCream(_position);
        }

        _position.total_depts = getTotalDebts(self, _position);

        return _position;
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param token_a_amount amountIn of token a.
    /// @param token_b_amount amountIn of token b.
    /// @dev Get the price for two tokens, from LINK if possible, else => straight from router.
    function getChainLinkValues(HLSConfig memory self, uint256 token_a_amount, uint256 token_b_amount) private view returns (uint256, uint256) {
        
        // check if we can get data from chainlink
        uint256 token_price = uint256(AggregatorInterface(self.token_oracle).latestAnswer());
        uint256 token_a_price = uint256(AggregatorInterface(self.token_a_oracle).latestAnswer());
        uint256 token_b_price = uint256(AggregatorInterface(self.token_b_oracle).latestAnswer());

        return (token_a_amount.mul(token_a_price).div(token_price), token_b_amount.mul(token_b_price).div(token_price));
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param cake_amount amountIn of CAKE.
    /// @dev Get the price for two tokens, from LINK if possible, else => straight from router.
    function getCakeChainLinkValue(HLSConfig memory self, uint256 cake_amount) private view returns (uint256) {
        
        // check if we can get data from chainlink
        uint256 token_price;
        uint256 cake_price;
        if (self.token_oracle != address(0)  && self.cake_oracle != address(0)) {
            token_price = uint256(AggregatorInterface(self.token_oracle).latestAnswer());
            cake_price = uint256(AggregatorInterface(self.cake_oracle).latestAnswer());

            return cake_amount.mul(cake_price).div(token_price);
        }

        return 0;
    }

    /// @param _crtoken_a Cream token.
    /// @param _crtoken_b Cream token.
    /// @dev Returns a map of <crtoken_address, borrow_amount> of all the borrowed coins.
    function getTotalBorrowAmount(address _crtoken_a, address _crtoken_b) private view returns (uint256, uint256) {
        
        uint256 crtoken_a_borrow_amount = CErc20Delegator(_crtoken_a).borrowBalanceStored(address(this));
        uint256 crtoken_b_borrow_amount = CErc20Delegator(_crtoken_b).borrowBalanceStored(address(this));
        return (crtoken_a_borrow_amount, crtoken_b_borrow_amount);
    }
    
    /// @param _position refer Position struct on the top.
    /// @dev Return staked tokens.
    function getStakedTokens(Position memory _position) private view returns (uint256, uint256) {
        (uint256 reserve0, uint256 reserve1, uint256 blockTimestampLast) = IPancakePair(_position.lp_token).getReserves();
        uint256 total_supply = IPancakePair(_position.lp_token).totalSupply();
        uint256 token_a_amnt = reserve0.mul(_position.lp_token_amount).div(total_supply);
        uint256 token_b_amnt = reserve1.mul(_position.lp_token_amount).div(total_supply);
        return (token_a_amnt, token_b_amnt);
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Return total debts.
    function getTotalDebts(HLSConfig memory self, Position memory _position) public view returns (uint256) {
        // Cream borrowed amount
        (uint256 crtoken_a_debt, uint256 crtoken_b_debt) = getTotalBorrowAmount(_position.borrowed_crtoken_a, _position.borrowed_crtoken_b);
        // PancakeSwap pending cake amount(getTotalCakePendingRewards)
        uint256 pending_cake_amount = MasterChef(self.masterchef).pendingCake(_position.pool_id, address(this));
        // PancakeSwap staked amount
        (uint256 token_a_amount, uint256 token_b_amount) = getStakedTokens(_position);

        uint256 cream_total_supply = _position.supply_crtoken_amount;
        uint256 token_a_value;
        uint256 token_b_value;
        if (token_a_amount < crtoken_a_debt) {
            token_a_value = 0;
        }
        if (token_b_amount < crtoken_b_debt) {
            token_b_value = 0;
        }
        if (token_a_value != 0 && token_b_value != 0) {
            (token_a_value, token_b_value) = getChainLinkValues(self, token_a_amount.sub(crtoken_a_debt), token_b_amount.sub(crtoken_b_debt));
        }
        uint256 pending_cake_value = getCakeChainLinkValue(self, pending_cake_amount);
        
        return cream_total_supply.add(pending_cake_value).add(token_a_value).add(token_b_value);
    }

    /// @param _comptroller Cream comptroller.
    /// @param _crtokens Cream token.
    function enterMarkets(address _comptroller, address[] memory _crtokens) external {
        
        ComptrollerInterface(_comptroller).enterMarkets(_crtokens);
    }

    /// @param _comptroller Cream comptroller.
    /// @param _crtoken Cream token.
    function exitMarket(address _comptroller, address _crtoken) external {
        
        ComptrollerInterface(_comptroller).exitMarket(_crtoken);
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _path swap path.
    function autoCompound(HLSConfig memory self, address[] calldata _path) external {
        uint256 amountIn = IBEP20(self.CAKE).balanceOf(address(this));
        uint256 amountInSlippage = amountIn.mul(98).div(100);
        uint256[] memory amountOutMinArray = IPancakeRouter02(self.router).getAmountsOut(amountInSlippage, _path);
        uint256 amountOutMin = amountOutMinArray[amountOutMinArray.length];
        IPancakeRouter02(self.router).swapExactTokensForTokens(amountIn, amountOutMin, _path, address(this), block.timestamp);
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import './IPancakeRouter01.sol';

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface ComptrollerInterface {

    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);

    function exitMarket(address cToken) external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface CErc20Delegator {

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(
        address implementation_,
        bool allowResign,
        bytes memory becomeImplementationData
    ) external;

    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(uint256 mintAmount) external returns (uint256);

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of cTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint256 redeemTokens) external returns (uint256);

    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function borrow(uint256 borrowAmount) external returns (uint256);

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrow(uint256 repayAmount) external returns (uint256);

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool);

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint256);

    /**
     * @notice Get a snapshot of the account's balances, and the cached exchange rate
     * @dev This is used by comptroller to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return (possible error, token balance, borrow balance, exchange rate mantissa)
     */
    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @notice Returns the current per-block borrow interest rate for this cToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view returns (uint256);

    /**
     * @notice Returns the current per-block supply interest rate for this cToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view returns (uint256);

    /**
     * @notice Returns the current total borrows plus accrued interest
     * @return The total borrows with interest
     */
    function totalBorrowsCurrent() external returns (uint256);

    /**
     * @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance using the updated borrowIndex
     * @param account The address whose balance should be calculated after updating borrowIndex
     * @return The calculated balance
     */
    function borrowBalanceCurrent(address account) external returns (uint256);

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address account) external view returns (uint256);

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() external returns (uint256);

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() external view returns (uint256);

    /**
     * @notice Get cash balance of this cToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() external view returns (uint256);

    /**
     * @notice Applies accrued interest to total borrows and reserves.
     * @dev This calculates interest accrued from the last checkpointed block
     *      up to the current block and writes new checkpoint to storage.
     */
    function accrueInterest() external returns (uint256);

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Will fail unless called by another cToken during the process of liquidation.
     *  Its absolutely critical to use msg.sender as the borrowed cToken and not a parameter.
     * @param liquidator The account receiving seized collateral
     * @param borrower The account having collateral seized
     * @param seizeTokens The number of cTokens to seize
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);
    
    function interestRateModel() external view returns (address);
    
    function totalBorrows() external view returns (uint256);
    
    function totalReserves() external view returns (uint256);
    
    function decimals() external view returns (uint8);
    
    function reserveFactorMantissa() external view returns (uint256);

    function underlying() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);
  function decimals() external view returns (uint8);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}