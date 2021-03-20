/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

contract MyFi is IERC20 {
    
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint public decimals;
    uint private total_supply;
    uint private max_total_supply;
    address public founder;
    mapping(address => uint) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => mapping (address => bool)) private _is_approved;
    
    /*
     * NOTE: Modifier only owner is allowed to send function
    */
    modifier onlyFounder() {
        require(msg.sender == founder);
        _;
    }

    /*
     * NOTE: Construct run when owner deploy token
     * Set max total supply 80k token. Owner can't mint/generate more token more than 8k.
     * Set token name.
     * Set token symbol.
     * Set token decimals.
     * Set total supply as initial supply.
     * Set founder.
     * Add all initial token to founder.
    */
    constructor(uint256 _initial_supply) {
        uint256 _max_total_supply = 80000;
        name = "My Finance";
        symbol = "MYFI";
        decimals = 18;
        total_supply = _initial_supply.mul(1000000000000000000);
        max_total_supply = _max_total_supply.mul(1000000000000000000);
        founder = msg.sender;
        balances[founder] = total_supply;
    }
    
    /*
     * NOTE: Address approving contract
     * Allowed if sender is found.
     * Allowed if recipient is found.
     * Set sender and recipient approved.
     * Set sender and recipient amount.
    */
    function _approve(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(recipient != address(0), "ERC20: approve to the zero address");

        _is_approved[sender][recipient] = true;
        _allowances[sender][recipient] = amount;
        emit Approval(sender, recipient, amount);
    }
    
    /*
     * NOTE: User transfer token
     * Allowed if sender is found.
     * Allowed if recipient is found.
     * Subtract sender balance by amount.
     * Add recipient balance by amount.
    */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /*
     * NOTE: Show total supply
    */
    function totalSupply() override public view returns(uint) {
        return total_supply;
    }

    /*
     * NOTE: Show max total supply
    */
    function maxTotalSupply() public view returns(uint) {
        return max_total_supply;
    }

    /*
     * NOTE: Show token balance by address
    */
    function balanceOf(address account) override public view returns (uint balance) {
        return balances[account];
    }
    
    /*
     * NOTE: Show allowed token amount to interact with other contract
    */
    function allowance(address _account, address _contract) override public view returns (uint256) {
        return _allowances[_account][_contract];
    }
    
    /*
     * NOTE: Show if other contract is approved
    */
    function isApproved(address _account, address _contract) public view returns (bool) {
        return _is_approved[_account][_contract];
    }

    /*
     * NOTE: Set new founder
     * Current founder is able to change ownership to new wallet address.
    */
    function changeOwnership(address _account) public {
        founder = _account;
    }
    
    /*
     * NOTE: Approve other contract to use token.
    */
    function approve(address _contract, uint _amount) override public returns (bool) {
        _approve(msg.sender, _contract, _amount);
        return true;
    }

    /*
     * NOTE: Transfer some amount of token to other address
     * Allowed if balance address is larger or equal to amount to transfer.
     * Allowed if amount to transfer is not 0.
    */
    function transfer(address recipient, uint amount) override public returns (bool) {
        require(balances[msg.sender] >= amount && amount > 0);
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    /*
     * NOTE: Transfer some amount of token from one address to another address
    */
    function transferFrom(address _from, address _to, uint _amount) override public returns (bool) {
        _transfer(_from, _to, _amount);
        _approve(_from, msg.sender, _allowances[_from][msg.sender].sub(_amount));
        return true;
    }
    
    /*
     * NOTE: Generate some amount of token to address
     * Allowed if only founder use this function.
     * Allowed if total supply plus with amount to generate is still smaller or equal to max total supply.
     * Add total supply with amount to generate.
     * Add address balance with amount to generate.
    */
    function mint(address to, uint256 amount) public onlyFounder {
        require(total_supply.add(amount) < max_total_supply);
        total_supply = total_supply.add(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(msg.sender, to, amount);
    }
}