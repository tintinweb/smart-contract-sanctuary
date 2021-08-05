/**
 *Submitted for verification at Etherscan.io on 2020-12-11
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-09
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity ^0.7.5;


///@title Simple ownable ether fund
///@author iBerGroup
contract EtherFund {
    // Use this lib for simple overflow control
    using SafeMath for uint256;
    
    ////////////////////////////////////
    // State variables               ///
    ////////////////////////////////////
    address public owner; // Fund owner - can use transferFrom
    
    /// @dev Funders balance records are stored in this mapping
    /// @dev The compiler automatically creates getter functions 
    /// @dev for all public state variables. So you can use
    /// @dev `balanceOf(address)` call for get any funder balance
    mapping(address => uint256) public balanceOf; 
    
    ////////////////////////////////////
    // Events   (for use in frontend) //
    ////////////////////////////////////
    event Deposit(address founder, uint256 amount);
    event Withdraw(address funder, uint256 amount);
    
    /// @dev Execute once at deploy time
    constructor ()  {
        // Owner is deploer address
        owner = msg.sender;
    }
    
    /// @dev Solidity special way receiver ether
    /// @dev see https://docs.soliditylang.org/en/v0.7.4/contracts.html?highlight=receive%20ether#receive-ether-function
    receive () external payable {
        _deposit(msg.sender, msg.value);
    }
    
    /// @notice Use this function to deposit your ether in fund;
    /// @dev same behavior as receive()
    function deposit() external payable {
        _deposit(msg.sender, msg.value);
    }
    
    /// @notice Use this function for withdraw your funds
    function withdraw(uint256 _amount) external returns (bool success) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount, "Withdraw amount exceeds balance!");
        payable(address(msg.sender)).transfer(_amount);
        emit Withdraw(msg.sender, _amount);
        return true;
    }
    
    /// @notice Simple transfer caller(!!!) amount to recipient inside fund
    function transfer(address _recipient, uint256 _amount) external returns (bool success) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    } 
    
    /// @dev Same as transfer but can change any funder balance. For fund owner only!!!
    function transferFrom(address _sender, address _recipient, uint256 _amount) external {
        require(msg.sender == owner, "Only fund owner can do this!");
        _transfer(_sender, _recipient, _amount);
    }
    
    /// @dev internal low level function for deposit funds
    function _deposit(address _funder, uint256 _amount) internal {
        balanceOf[_funder] = balanceOf[_funder].add(_amount);
        emit Deposit(_funder, _amount);
    }
    

    /// @dev internal low level function for transfer functionality with 
    /// @dev balance control
    function _transfer(address _sender, address _recipient, uint256 _amount) internal  {
        require(_sender != address(0), "Transfer from the zero address");
        require(_recipient != address(0), "Transfer to the zero address");

        balanceOf[_sender] = balanceOf[_sender].sub(_amount, "Transfer amount exceeds balance");
        balanceOf[_recipient] = balanceOf[_recipient].add(_amount);
    }
    
    /// @dev Returns smart contract balance
    function getFundBalance() public view returns (uint256 fund) {
        return address(this).balance;
    }
       
    
}