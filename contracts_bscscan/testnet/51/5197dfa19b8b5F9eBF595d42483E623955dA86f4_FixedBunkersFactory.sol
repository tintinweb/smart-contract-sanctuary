// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./FixedBunker.sol";
import "./utils/BasicContract.sol";

/// @title FixedBunkersFactory
/// @author Andrew FU
contract FixedBunkersFactory {
    
    address private _owner;
    uint256 private BunkerId;
    uint256 public BunkersLength;
    mapping (uint256 => address) public IdToBunker;

    constructor() {
    	_owner = msg.sender;
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == _owner, "Only Owner can call this function");
        require(newOwner != address(0), 'New owner is the zero address');
        _owner = newOwner;
    }

    function createBunker (uint256[1] memory _uints, address[6] memory _addrs, string memory _name, string memory _symbol, uint8 _decimals) external returns(uint256, address) {
        require(msg.sender == _owner, "Only Owner can call this function");
        BunkerId++;
        BunkersLength++;
        FixedBunker newBunker = new FixedBunker();
        newBunker.initialize(_uints, _addrs, _name, _symbol, _decimals);
        IdToBunker[BunkerId] = address(newBunker);
        return (BunkerId, address(newBunker));
    }

    function delBunker (uint256[] memory _ids) external returns(bool) {
        require(msg.sender == _owner, "Only Owner can call this function");
        BunkersLength = BunkersLength - _ids.length;
        for (uint i = 0; i < _ids.length; i++) {
            delete IdToBunker[_ids[i]];
        }
        return true;
    }

    function setTagBunkers (uint256[] memory _ids, bool _tag) external returns(bool) {
        require(msg.sender == _owner, "Only Owner can call this function");
        for (uint i = 0; i < _ids.length; i++) {
            FixedBunker bunker = FixedBunker(IdToBunker[_ids[i]]);
            bunker.setTag(_tag);
        }
        return true;
    }

    function setConfigBunker (uint256 _id, address[4] memory _config, address _dofin, uint256 _deposit_limit) external returns(bool) {
        require(msg.sender == _owner, "Only Owner can call this function");
        FixedBunker bunker = FixedBunker(IdToBunker[_id]);
        bunker.setConfig(_config, _dofin, _deposit_limit);
        return true;
    }

    function rebalanceBunker (uint256[] memory _ids) external returns(bool) {
        require(msg.sender == _owner, "Only Owner can call this function");
        for (uint i = 0; i < _ids.length; i++) {
            FixedBunker bunker = FixedBunker(IdToBunker[_ids[i]]);
            bunker.rebalance();
        }
        return true;
    }

    function rebalanceWithRepayBunker (uint256[] memory _ids) external returns(bool) {
        require(msg.sender == _owner, "Only Owner can call this function");
        for (uint i = 0; i < _ids.length; i++) {
            FixedBunker bunker = FixedBunker(IdToBunker[_ids[i]]);
            bunker.rebalanceWithRepay();
        }
        return true;
    }

    function enterBunker (uint256[] memory _ids, uint256[] memory _types) external returns(bool) {
        require(msg.sender == _owner, "Only Owner can call this function");
        require(_ids.length == _types.length, "Two length different");
        for (uint i = 0; i < _ids.length; i++) {
            FixedBunker bunker = FixedBunker(IdToBunker[_ids[i]]);
            bunker.enter(_types[i]);
        }
        return true;
    }

    function exitBunker (uint256[] memory _ids, uint256[] memory _types) external returns(bool) {
        require(msg.sender == _owner, "Only Owner can call this function");
        require(_ids.length == _types.length, "Two length different");
        for (uint i = 0; i < _ids.length; i++) {
            FixedBunker bunker = FixedBunker(IdToBunker[_ids[i]]);
            bunker.exit(_types[i]);
        }
        return true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "../math/SafeMath.sol";

/// @title ProofToken
/// @author Andrew FU
/// @dev All functions haven't finished unit test
contract ProofToken {
    
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 internal totalSupply_;
    
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    
    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) internal allowed;

    function initializeToken(string memory _name, string memory _symbol, uint8 _decimals) internal {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
    
    function totalSupply() public view returns (uint256) {
        
        return totalSupply_;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        
        return allowed[owner][spender];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    function mint(address account, uint256 amount) internal returns (bool) {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply_ += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);

        return true;
    }
    
    function burn(address account, uint256 amount) internal returns (bool) {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            balances[account] = accountBalance - amount;
        }
        totalSupply_ -= amount;
        emit Transfer(account, address(0), amount);

        return true;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "../token/BEP20/IBEP20.sol";
import "../access/Ownable.sol";

contract BasicContract is Ownable {
    
    event IntLog(string message, uint val);
    event StrLog(string message, string val);
    event AddrLog(string message, address val);
    
    function checkBalance(address _token, address _address) external view returns (uint) {
        return IBEP20(_token).balanceOf(_address);
    }
    
    function checkAllowance(address _token, address _owner, address _spender) external view returns (uint) {
        return IBEP20(_token).allowance(_owner, _spender);
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

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
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
    /// @param _position refer Position struct on t he top.
    /// @dev Adds liquidity to a given pool.
    function _addLiquidityBoosted(HLSConfig memory self, Position memory _position) private returns (Position memory) {
        uint256 max_available_staking_a = IBEP20(_position.token_a).balanceOf(address(this)).mul(_position.supply_funds_percentage).div(100);
        uint256 max_available_staking_b = IBEP20(_position.token_b).balanceOf(address(this)).mul(_position.supply_funds_percentage).div(100);
        
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

    /// @param self refer HLSConfig struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Main entry function to stake and enter a given position.
    function enterPositionBoosted(HLSConfig memory self, Position memory _position) external returns (Position memory) {
        // Add liquidity
        _position = _addLiquidityBoosted(self, _position);
        // Stake
        _position = _stake(self, _position);
        
        _position.total_depts = getTotalDebtsBoosted(self, _position);

        return _position;
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _position refer Position struct on the top.
    /// @param _type enter type.
    /// @dev Main entry function to borrow and enter a given position.
    function enterPositionFixed(HLSConfig memory self, Position memory _position, uint256 _type) external returns (Position memory) { 
        if (_type == 1) {
            // Supply position
            _position = _supplyCream(_position);
        }
        
        if (_type == 1 || _type == 2) {
            // Borrow
            _position = _borrowCream(self, _position);
        }
        
        _position.total_depts = getTotalDebtsFixed(self, _position);

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
    /// @param _position refer Position struct on the top.
    /// @dev Main exit function to exit and unstake a given position.
    function exitPositionBoosted(HLSConfig memory self, Position memory _position) external returns (Position memory) {
        // Unstake
        _position = _unstake(self, _position);
        // Unstake
        _position = _removeLiquidity(self, _position);

        _position.total_depts = getTotalDebtsBoosted(self, _position);

        return _position;
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Main exit function to exit and repay a given position.
    function exitPositionFixed(HLSConfig memory self, Position memory _position, uint256 _type) external returns (Position memory) {        
        if (_type == 1 || _type == 2) {
            // Repay
            _position = _repay(_position);
        }
        
        if (_type == 1) {
            // Redeem
            _position = _redeemCream(_position);
        }

        _position.total_depts = getTotalDebtsFixed(self, _position);

        return _position;
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param token_a_amount amountIn of token a.
    /// @param token_b_amount amountIn of token b.
    /// @dev Get the price for two tokens, from LINK if possible, else => straight from router.
    function getChainLinkValues(HLSConfig memory self, uint256 token_a_amount, uint256 token_b_amount) public view returns (uint256, uint256) {
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
    /// @dev Returns total amount that bunker borrowed.
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
    /// @dev Return total debts for charged bunker.
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

    /// @param self refer HLSConfig struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Return total debts for boosted bunker.
    function getTotalDebtsBoosted(HLSConfig memory self, Position memory _position) public view returns (uint256) {
        // PancakeSwap pending cake amount(getTotalCakePendingRewards)
        uint256 pending_cake_amount = MasterChef(self.masterchef).pendingCake(_position.pool_id, address(this));
        // PancakeSwap staked amount
        (uint256 token_a_amount, uint256 token_b_amount) = getStakedTokens(_position);

        (uint256 token_a_value, uint256 token_b_value) = getChainLinkValues(self, token_a_amount, token_b_amount);
        uint256 pending_cake_value = getCakeChainLinkValue(self, pending_cake_amount);
        
        return pending_cake_value.add(token_a_value).add(token_b_value);
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _position refer Position struct on the top.
    /// @dev Return total debts for fixed bunker.
    function getTotalDebtsFixed(HLSConfig memory self, Position memory _position) public view returns (uint256) {
        // Cream borrowed amount
        (uint256 crtoken_a_debt, uint256 crtoken_b_debt) = getTotalBorrowAmount(_position.borrowed_crtoken_a, _position.borrowed_crtoken_b);

        uint256 cream_total_supply = _position.supply_crtoken_amount;
        uint256 token_a_value;
        uint256 token_b_value;
        if (crtoken_a_debt != 0 && crtoken_b_debt != 0) {
            (token_a_value, token_b_value) = getChainLinkValues(self, crtoken_a_debt, crtoken_b_debt);
        }
        
        return cream_total_supply.add(token_a_value).add(token_b_value);
    }

    /// @param _position refer Position struct on the top.
    /// @param _token_a_amount amount of token a.
    /// @param _token_b_amount amount of token b.
    /// @dev Return updated token a, token b amount and value.
    function getUpdatedAmount(HLSConfig memory self, Position memory _position, uint256 _token_a_amount, uint256 _token_b_amount) external view returns (uint256, uint256, uint256) {
        (uint256 reserve0, uint256 reserve1, uint256 blockTimestampLast) = IPancakePair(_position.lp_token).getReserves();
        if (_token_a_amount == 0) {
            _token_b_amount = IPancakeRouter02(self.router).quote(_token_a_amount, reserve0, reserve1);
        } else if (_token_b_amount == 0) {
            _token_a_amount = IPancakeRouter02(self.router).quote(_token_b_amount, reserve1, reserve0);
        }

        (uint256 token_a_value, uint256 token_b_value) = getChainLinkValues(self, _token_a_amount, _token_b_amount);
        
        return (_token_a_amount, _token_b_amount, token_a_value.add(token_b_value));
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _value token value need to split.
    /// @dev Return total debts for boosted bunker.
    function getValeSplit(HLSConfig memory self, uint256 _value) public view returns (uint256, uint256) {
        // check if we can get data from chainlink
        uint256 token_price = uint256(AggregatorInterface(self.token_oracle).latestAnswer());
        uint256 token_a_price = uint256(AggregatorInterface(self.token_a_oracle).latestAnswer());
        uint256 token_b_price = uint256(AggregatorInterface(self.token_b_oracle).latestAnswer());
        uint256 value_a = _value.div(2);
        uint256 value_b = _value.sub(value_a);

        return (value_a.mul(token_price).div(token_a_price), value_b.mul(token_price).div(token_b_price));
    }

    /// @param _comptroller Cream comptroller.
    /// @param _crtokens Cream token.
    /// @dev Need to enter market first then borrow.
    function enterMarkets(address _comptroller, address[] memory _crtokens) external {
        
        ComptrollerInterface(_comptroller).enterMarkets(_crtokens);
    }

    /// @param _comptroller Cream comptroller.
    /// @param _crtoken Cream token.
    /// @dev Exit market to stop bunker borrow on Cream.
    function exitMarket(address _comptroller, address _crtoken) external {
        
        ComptrollerInterface(_comptroller).exitMarket(_crtoken);
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _path swap path.
    /// @dev Auto swap reward back to bunker.
    function autoCompound(HLSConfig memory self, address[] calldata _path) external {
        uint256 amountIn = IBEP20(self.CAKE).balanceOf(address(this));
        uint256 amountInSlippage = amountIn.mul(98).div(100);
        uint256[] memory amountOutMinArray = IPancakeRouter02(self.router).getAmountsOut(amountInSlippage, _path);
        uint256 amountOutMin = amountOutMinArray[amountOutMinArray.length - 1];
        IPancakeRouter02(self.router).swapExactTokensForTokens(amountIn, amountOutMin, _path, address(this), block.timestamp);
    }

    /// @param self refer HLSConfig struct on the top.
    /// @param _token_a_path swap path.
    /// @param _token_b_path swap path.
    /// @dev Auto swap reward back to bunker.
    function autoCompoundBoosted(HLSConfig memory self, address[] calldata _token_a_path, address[] calldata _token_b_path) external {
        uint256 cake_value = getCakeChainLinkValue(self, IBEP20(self.CAKE).balanceOf(address(this)));
        (uint256 token_a_value, uint256 token_b_value) = getValeSplit(self, cake_value);

        uint256 amountIn = token_a_value;
        uint256 amountInSlippage = amountIn.mul(98).div(100);
        uint256[] memory amountOutMinAArray = IPancakeRouter02(self.router).getAmountsOut(amountInSlippage, _token_a_path);
        uint256 amountOutMin = amountOutMinAArray[amountOutMinAArray.length - 1];
        IPancakeRouter02(self.router).swapExactTokensForTokens(amountIn, amountOutMin, _token_a_path, address(this), block.timestamp);

        amountIn = token_b_value;
        amountInSlippage = amountIn.mul(98).div(100);
        uint256[] memory amountOutMinBArray = IPancakeRouter02(self.router).getAmountsOut(amountInSlippage, _token_b_path);
        amountOutMin = amountOutMinBArray[amountOutMinBArray.length - 1];
        IPancakeRouter02(self.router).swapExactTokensForTokens(amountIn, amountOutMin, _token_b_path, address(this), block.timestamp);
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import '../GSN/Context.sol';

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        // Unit test need to comment this line.
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        // require(_owner != address(0), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() public {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./token/BEP20/IBEP20.sol";
import "./math/SafeMath.sol";
import "./utils/BasicContract.sol";
import "./utils/ProofToken.sol";
import { HighLevelSystem } from "./libs/HighLevelSystem.sol";

/// @title FixedBunker
/// @author Andrew FU
contract FixedBunker is ProofToken {

    struct User {
        uint256 depositPtokenAmount;
        uint256 depositTokenAmount;
        uint256 depositBlockTimestamp;
    }

    HighLevelSystem.HLSConfig private HLSConfig;
    HighLevelSystem.Position private position;
    
    using SafeMath for uint256;
    uint256 constant private MAX_INT_EXPONENTIATION = 2**256 - 1;

    uint256 private deposit_limit;
    uint256 private temp_free_funds;
    bool public TAG = false;
    address private dofin;
    address private factory;

    mapping (address => User) private users;

    function initialize(uint256[1] memory _uints, address[6] memory _addrs, string memory _name, string memory _symbol, uint8 _decimals) external {
        if (factory != address(0)) {
            require(msg.sender == factory, "Only factory can call this function");
        }
        position = HighLevelSystem.Position({
            pool_id: 0,
            token_amount: 0,
            token_a_amount: 0,
            token_b_amount: 0,
            lp_token_amount: 0,
            crtoken_amount: 0,
            supply_crtoken_amount: 0,
            token: _addrs[0],
            token_a: _addrs[1],
            token_b: _addrs[2],
            lp_token: address(0),
            supply_crtoken: _addrs[3],
            borrowed_crtoken_a: _addrs[4],
            borrowed_crtoken_b: _addrs[5],
            supply_funds_percentage: _uints[0],
            total_depts: 0
        });
        initializeToken(_name, _symbol, _decimals);
    }

    modifier checkTag() {
        require(TAG == true, 'TAG ERROR.');
        _;
    }
    
    function setConfig(address[4] memory _config, address _dofin, uint256 _deposit_limit) external {
        require(msg.sender == factory, "Only factory can call this function");
        HLSConfig.token_oracle = _config[0];
        HLSConfig.token_a_oracle = _config[1];
        HLSConfig.token_b_oracle = _config[2];
        HLSConfig.comptroller = _config[3];

        dofin = _dofin;
        deposit_limit = _deposit_limit;

        // Approve for Cream borrow 
        IBEP20(position.token).approve(position.supply_crtoken, MAX_INT_EXPONENTIATION);
        // Approve for Cream repay
        IBEP20(position.token_a).approve(position.borrowed_crtoken_a, MAX_INT_EXPONENTIATION);
        IBEP20(position.token_b).approve(position.borrowed_crtoken_b, MAX_INT_EXPONENTIATION);
        // Approve for Cream redeem
        IBEP20(position.supply_crtoken).approve(position.supply_crtoken, MAX_INT_EXPONENTIATION);

        // Set Tag
        setTag(true);
    }

    function setTag(bool _tag) public {
        require(msg.sender == factory, "Only factory can call this function");
        TAG = _tag;
        if (_tag == true) {
            address[] memory crtokens = new address[] (3);
            crtokens[0] = address(0x0000000000000000000000000000000000000020);
            crtokens[1] = address(0x0000000000000000000000000000000000000001);
            crtokens[2] = position.supply_crtoken;
            HighLevelSystem.enterMarkets(HLSConfig.comptroller, crtokens);
        } else {
            HighLevelSystem.exitMarket(HLSConfig.comptroller, position.supply_crtoken);
        }
    }
    
    function getPosition() external view returns(HighLevelSystem.Position memory) {
        
        return position;
    }

    function getUser(address _account) external view returns (User memory) {
        
        return users[_account];
    }
    
    function rebalanceWithRepay() external checkTag {
        require(msg.sender == factory, "Only factory can call this function");
        position = HighLevelSystem.exitPositionFixed(HLSConfig, position, 2);
        position = HighLevelSystem.enterPositionFixed(HLSConfig, position, 2);
        temp_free_funds = IBEP20(position.token).balanceOf(address(this));
    }
    
    function rebalance() external checkTag  {
        require(msg.sender == factory, "Only factory can call this function");
        position = HighLevelSystem.exitPositionFixed(HLSConfig, position, 1);
        position = HighLevelSystem.enterPositionFixed(HLSConfig, position, 1);
        temp_free_funds = IBEP20(position.token).balanceOf(address(this));
    }
    
    function checkAddNewFunds() external checkTag view returns (uint256) {
        uint256 free_funds = IBEP20(position.token).balanceOf(address(this));
        if (free_funds > temp_free_funds) {
            if (position.token_a_amount == 0 && position.token_b_amount == 0) {
                // Need to enter
                return 1;
            } else {
                // Need to rebalance
                return 2;
            }
        }
        return 0;
    }
    
    function enter(uint256 _type) external checkTag {
        require(msg.sender == factory, "Only factory can call this function");
        position = HighLevelSystem.enterPositionFixed(HLSConfig, position, _type);
        temp_free_funds = IBEP20(position.token).balanceOf(address(this));
    }

    function exit(uint256 _type) external checkTag {
        require(msg.sender == factory, "Only factory can call this function");
        position = HighLevelSystem.exitPositionFixed(HLSConfig, position, _type);
    }

    function getTotalAssets() public view returns (uint256) {
        // Free funds amount
        uint256 freeFunds = IBEP20(position.token).balanceOf(address(this));
        // Total Debts amount from Cream, PancakeSwap
        uint256 totalDebts = HighLevelSystem.getTotalDebtsFixed(HLSConfig, position);
        
        return freeFunds.add(totalDebts);
    }

    function getDepositAmountOut(uint256 _deposit_amount) public view returns (uint256) {
        uint256 totalAssets = IBEP20(position.token).balanceOf(address(this)).add(position.total_depts);
        uint256 shares;
        if (totalSupply_ > 0) {
            shares = _deposit_amount.mul(totalSupply_).div(totalAssets);
        } else {
            shares = _deposit_amount;
        }
        return shares;
    }
    
    function deposit(uint256 _deposit_amount) external checkTag returns (bool) {
        require(_deposit_amount <= deposit_limit.mul(10**IBEP20(position.token).decimals()), "Deposit too much!");
        require(_deposit_amount > 0, "Deposit amount must bigger than 0.");
        
        // Calculation of pToken amount need to mint
        uint256 shares = getDepositAmountOut(_deposit_amount);
        
        // Record user deposit amount
        users[msg.sender] = User({
            depositPtokenAmount: shares,
            depositTokenAmount: _deposit_amount,
            depositBlockTimestamp: block.timestamp
        });

        // Mint pToken and transfer Token to cashbox
        mint(msg.sender, shares);
        IBEP20(position.token).transferFrom(msg.sender, address(this), _deposit_amount);
        
        return true;
    }
    
    function getWithdrawAmount() external view returns (uint256) {
        uint256 totalAssets = getTotalAssets();
        uint256 withdraw_amount = balanceOf(msg.sender);
        uint256 value = withdraw_amount.mul(totalAssets).div(totalSupply_);
        User memory user = users[msg.sender];
        if (withdraw_amount > user.depositPtokenAmount) {
            return 0;
        }
        uint256 dofin_value;
        uint256 user_value;
        if (value > user.depositTokenAmount) {
            dofin_value = value.sub(user.depositTokenAmount).mul(20).div(100);
            user_value = value.sub(dofin_value);
        } else {
            user_value = value;
        }
        
        return user_value;
    }
    
    function withdraw() external checkTag returns (bool) {
        uint256 withdraw_amount = balanceOf(msg.sender);
        uint256 totalAssets = getTotalAssets();
        uint256 value = withdraw_amount.mul(totalAssets).div(totalSupply_);
        User memory user = users[msg.sender];
        bool need_rebalance = false;
        require(withdraw_amount <= user.depositPtokenAmount, "Proof token amount incorrect");
        require(block.timestamp > user.depositBlockTimestamp, "Deposit and withdraw in same block");
        // If no enough amount of free funds can transfer will trigger exit position
        if (value > IBEP20(position.token).balanceOf(address(this))) {
            HighLevelSystem.exitPositionFixed(HLSConfig, position, 1);
            totalAssets = IBEP20(position.token).balanceOf(address(this));
            value = withdraw_amount.mul(totalAssets).div(totalSupply_);
            need_rebalance = true;
        }
        // Will charge 20% fees
        burn(msg.sender, withdraw_amount);
        uint256 dofin_value;
        uint256 user_value;
        if (value > user.depositTokenAmount) {
            dofin_value = value.sub(user.depositTokenAmount).mul(20).div(100);
            user_value = value.sub(dofin_value);
        } else {
            user_value = value;
        }
        // Modify user state data
        user.depositPtokenAmount = 0;
        user.depositTokenAmount = 0;
        user.depositBlockTimestamp = 0;
        users[msg.sender] = user;
        IBEP20(position.token).transferFrom(address(this), dofin, dofin_value);
        IBEP20(position.token).transferFrom(address(this), msg.sender, user_value);
        // Enter position again
        if (need_rebalance == true) {
            HighLevelSystem.enterPositionFixed(HLSConfig, position, 1);
            temp_free_funds = IBEP20(position.token).balanceOf(address(this));
        }
        
        return true;
    }
    
}