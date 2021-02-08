/**
 *Submitted for verification at Etherscan.io on 2021-02-08
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-22
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyGovernance`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _governance;
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event GovernanceshipTransferred(
        address indexed previousGovernance,
        address indexed newGovernance
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _governance = msgSender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
        emit GovernanceshipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function governance() public view returns (address) {
        return _governance;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGovernance() {
        require(
            _governance == _msgSender(),
            "Ownable: caller is not the owner"
        );
        _;
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyGovernance` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyGovernance {
        emit OwnershipTransferred(_governance, address(0));
        _governance = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newGovernance)
        public
        virtual
        onlyGovernance
    {
        require(
            newGovernance != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_governance, newGovernance);
        _governance = newGovernance;
    }
}

contract Dice is Context, Ownable {
    using SafeMath for uint256;

    uint256 private _totalAmount;

    mapping(address => uint256) private _userBalanceList;

    constructor() {
        _totalAmount = 0;
    }

    /**
     * @dev Get Balance of User
     */
    function balanceOfPlayer(address userAddress)
        external
        view
        returns (uint256)
    {
        return _userBalanceList[userAddress];
    }

    /**
     * @dev Get Total Balance
     */
    function getTotalBalance() external view returns (uint256) {
        return _totalAmount;
    }

    /**
     * @dev receive event
     */
    receive() external payable {
        deposit();
    }

    /**
     * @dev Receive ETH from player and update his balance on DiceContract
     */
    function deposit() public payable {
        address userAddress = _msgSender();
        uint256 depositAmouont = msg.value;

        // Update Player's Balance
        _userBalanceList[userAddress] = _userBalanceList[userAddress].add(
            depositAmouont
        );
        
        // Update Total amount
        _totalAmount = _totalAmount.add(depositAmouont);
    }

    /**
     * @dev Withdraw User Balance to user account, only Governance call it
     */
    function userWithdraw(address withdrawAddress, uint256 amount)
        public
        payable
        onlyGovernance
    {
        require(
            _totalAmount >= amount,
            "User Balance should be more than withdraw amount."
        );

        // Send ETH From Contract to User Address
        (bool sent, ) = withdrawAddress.call{value: amount}("");
        require(sent, "Failed to Withdraw User.");

        // Update Total Balance
        _totalAmount = _totalAmount.sub(amount);
    }

    /**
     * @dev Withdraw admin Balance to admin account, only Governance call it
     */
    function adminWithdraw(address adminAddress, uint256 amount)
        public
        payable
        onlyGovernance
    {
        require(
            _totalAmount >= amount,
            "User Balance should be more than withdraw amount."
        );

        // Send ETH From Contract to Admin Address
        (bool sent, ) = adminAddress.call{value: amount}("");
        require(sent, "Failed to Withdraw User.");

        // Update Total Balance
        _totalAmount = _totalAmount.sub(amount);
    }

    /**
     * @dev EmergencyWithdraw when need to update contract and then will restore it
     */
    function emergencyWithdraw() public payable onlyGovernance {
        require(_totalAmount > 0, "Can't send over total ETH amount.");

        uint256 amount = _totalAmount;
        address governanceAddress = governance();

        // Send ETH From Contract to Governance Address
        (bool sent, ) = governanceAddress.call{value: amount}("");
        require(sent, "Failed to Withdraw Governance");

        // Update Total Balance
        _totalAmount = 0;
    }
}