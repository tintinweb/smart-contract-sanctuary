/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

pragma solidity 0.6.12;


interface IReferral {

    function addReferrer(address _user, address _referrer) external;

    function addRewards(address _user, string memory _type, uint256 _total) external;

    function getRewards(address _user, string memory _type) external view returns (uint256);

    function getReferrer(address _user) external view returns (address);

    function getReferralsCount(address _referrer) external view returns (uint256);

}

abstract contract OwnerRole {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor () public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

abstract contract OperatorRole {
    mapping(address => bool) private operators;

    event OperatorAdded(address indexed _operator);
    event OperatorRemoved(address indexed _operator);

    constructor () public {
        addOperator(msg.sender);
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Operatable: caller is not the operator");
        _;
    }

    function isOperator(address _minter) external view virtual returns (bool) {
        return operators[_minter];
    }

    function addOperator(address _operator) public virtual {
        operators[_operator] = true;
        emit OperatorAdded(_operator);
    }

    function removeOperator(address _operator) public virtual {
        operators[_operator] = false;
        emit OperatorRemoved(_operator);
    }
}

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

// SPDX-License-Identifier: MIT
contract ErosReferral is IReferral, OwnerRole, OperatorRole {
    using SafeMath for uint256;

    mapping(address => address) private users;
    mapping(address => mapping(string => uint256)) private rewards;
    mapping(address => uint256) private referralsCount;

    event ReferrerAdded(address indexed _user, address indexed _referrer);
    event RewardsAdded(address indexed _user, string indexed _type, uint256 _total);

    function addReferrer(address _user, address _referrer) external override onlyOperator {
        require(_user != address(0), "Referral: _user is zero address");
        require(_referrer != address(0), "Referral: _referrer is zero address");
        require(_user != _referrer, "Referral: _user is equal _referrer");
        require(users[_user] == address(0), "Referral: _referrer exists");

        users[_user] = _referrer;
        referralsCount[_referrer] = referralsCount[_referrer].add(1);

        emit ReferrerAdded(_user, _referrer);
    }

    function addRewards(address _user, string memory _type, uint256 _total) external override onlyOperator {
        require(_user != address(0), "Referral: _user is zero address");
        require(_total > 0, "Referral: _total below zero");

        rewards[_user][_type] = rewards[_user][_type].add(_total);

        emit RewardsAdded(_user, _type, _total);
    }

    function getRewards(address _user, string memory _type) external override view returns (uint256) {
        return rewards[_user][_type];
    }

    function getReferrer(address _user) external override view returns (address) {
        return users[_user];
    }

    function getReferralsCount(address _referrer) external override view returns (uint256) {
        return referralsCount[_referrer];
    }

    function addOperator(address _operator) public onlyOwner override(OperatorRole) {
        super.addOperator(_operator);
    }

    function removeOperator(address _operator) public onlyOwner override(OperatorRole) {
        super.removeOperator(_operator);
    }

}