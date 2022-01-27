/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-26
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: contracts/staking.sol



pragma solidity ^0.8.7;




contract AvaxStake is ReentrancyGuard {
    using SafeMath for uint256;
    // variables
    // rxg erc20 token held by the activator address
    IERC20 public token;
    // address of the AVAX wallet
    address public owner; // owner of the contract
    address private activator; // address of the activator
    uint256 public avaxPrice;
    uint256 public totalStakers;
    uint256 public maxPayout;
    uint256 public totalStaked;
    address[] public stakers;
    // make an array of uint256s to store the multiplier for 1000 days
    uint256[] public payChart = new uint256[](1000);
    struct Stake {
        address staker;
        uint256 amount;
        uint256 timestamp;
        uint256 currentDay;
        uint256 earnings;
    }
    // mapping
    mapping(address => Stake) public stakes;
    // events
    event StakeCreated(address indexed _staker, uint256 _amount);
    // modifiers
    modifier onlyStaker() {
        require(
            msg.sender == stakes[msg.sender].staker,
            "Only stakers can call this function"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyActivator() {
        require(
            msg.sender == activator,
            "Only activator can call this function"
        );
        _;
    }

    // constructor
    constructor(address _rewardToken) {
        token = IERC20(_rewardToken);
        maxPayout = 72000 ether;
        owner = msg.sender;
        activator = msg.sender;
        totalStaked = 0;
        totalStakers = 0;
    }

    // functions
    function stake() external payable nonReentrant {
        Stake memory newstake;
        newstake.staker = msg.sender;
        newstake.amount = msg.value;
        totalStaked += msg.value;
        newstake.timestamp = block.timestamp;
        newstake.currentDay = 0;
        stakes[msg.sender] = newstake;
        stakers.push(msg.sender);
        totalStakers++;
        emit StakeCreated(msg.sender, msg.value);
    }

    function unstake() external onlyStaker {
        require(stakes[msg.sender].amount > 0, "You can't unstake 0 AVAX");
        require(
            stakes[msg.sender].earnings >= 0,
            "You can't claim RXG with negative earnings"
        );
        // return the stakers staked amount
        address payable _to = payable(msg.sender);
        bool sent = _to.send(stakes[msg.sender].amount);
        require(sent, "Failed to send AVAX to the staker");
        // send the stakers earnings to the staker
        require(
            token.allowance(activator, address(this)) >=
                stakes[msg.sender].earnings,
            "Contract doesn't have enough allowance to send earnings"
        );
        bool success = token.transferFrom(
            activator,
            msg.sender,
            stakes[msg.sender].earnings
        );
        require(success, "Failed to send RXG to the staker");
        totalStaked -= stakes[msg.sender].amount;
        stakes[msg.sender].amount = 0;
        stakes[msg.sender].staker = address(0);
        stakes[msg.sender].timestamp = 0;
        stakes[msg.sender].currentDay = 0;
        stakes[msg.sender].earnings = 0;
        for (uint256 i = 0; i < stakers.length; i++) {
            if (stakers[i] == msg.sender) {
                delete stakers[i];
            } else {
                continue;
            }
        }
        totalStakers--;
    }

    function claimRXG(uint256 _amount) external onlyStaker {
        // make sure activator has approved the contract to spend the rxg
        require(stakes[msg.sender].earnings > _amount);
        require(
            token.allowance(activator, address(this)) >=
                stakes[msg.sender].earnings,
            "Contract doesn't have enough allowance to send earnings"
        );
        bool success = token.transferFrom(
            activator,
            payable(msg.sender),
            _amount
        );
        require(success, "Failed to send RXG to the staker");
        stakes[msg.sender].earnings -= _amount;
    }

    function setActivator(address _activator) external onlyOwner {
        activator = _activator;
    }

    function setPaychart(uint256[] memory _payChart) external onlyOwner {
        for (uint256 i = 0; i < _payChart.length; i++) {
            payChart.push(_payChart[i]);
        }
    }

    function clearPaychart() external onlyOwner {
        payChart = new uint256[](1000);
    }

    function getStake(address _owner) public view returns (Stake memory) {
        require(stakes[_owner].amount > 0, "Stake does not exist");
        Stake memory _userstake = stakes[_owner];
        return _userstake;
    }

    function autoEmissions(address _staker) internal {
        //in wei
        maxPayout = (totalStaked / 100) * 10; // 10% of totalStaked
        uint256 multiplier = payChart[stakes[_staker].currentDay];
        uint256 payout;
        uint256 userStaked = stakes[_staker].amount;
        if (userStaked > maxPayout) {
            payout = (maxPayout / 1000) * multiplier; // reward based on max payout
            payout = (payout / 72) * 1000; // convert to RXG
        } else {
            payout = (userStaked / 1000) * multiplier; // reward based on user staked amount
            payout = (payout / 72) * 1000; // convert to RXG
        }
        stakes[_staker].currentDay++;
        stakes[_staker].earnings += payout;
    }

    // run automatically every day by our site
    function activate() public onlyActivator {
        uint256 time = block.timestamp;
        for (uint256 i = 0; i < stakers.length; i++) {
            if (time >= stakes[stakers[i]].timestamp + 86400) { // 86400 seconds in a day
                stakes[stakers[i]].timestamp = time;
                autoEmissions(stakers[i]);
            } else {
                continue;
            }
        }
    }

    // function to return an array of all the stakers addresses
    function getStakers() internal view returns (address[] storage) {
        return stakers;
    }

    function getPayChart() internal view returns (uint256[] memory) {
        return payChart;
    }
}