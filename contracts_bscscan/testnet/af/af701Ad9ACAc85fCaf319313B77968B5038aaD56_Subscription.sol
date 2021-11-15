// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IMainPool {
    function transferToPool(
        address _userAddress,
        address _creatorAddress,
        address _tokenAddress,
        uint256 _amount
    ) external;

    function transferTipToPool(
        address _userAddress,
        address _creatorAddress,
        address _tokenAddress,
        uint256 _amount
    ) external;
}

interface IOraclePrice {
    function getAmountsOut(uint256 _amountIn)
        external
        view
        returns (uint256[] memory amounts);
    function getAmountsOut(uint256 _amountIn, address[] calldata _pairToken)
        external
        view
        returns (uint256[] memory amounts);
    function getPrice(string calldata ref1, string calldata ref2) 
        external
        view 
        returns (uint256 amount);
}

contract Permission is Ownable {
    mapping(address => bool) blacklist;

    event BanUser(address indexed _address);
    event UnbanUser(address indexed _address);

    modifier onlyAllow() {
        require(!blacklist[msg.sender], "User is banned");
        _;
    }

    function banUser(address _address) public onlyOwner {
        blacklist[_address] = true;
        emit BanUser(_address);
    }

    function unbanUser(address _address) public onlyOwner {
        delete blacklist[_address];
        emit UnbanUser(_address);
    }
}

contract Subscription is Ownable, Permission {
    
    constructor(address _poolAddress, address _oraclePriceAddress, address _BUSDAddress, address _IDOLAddress)
    {
        poolAddress = _poolAddress;
        oraclePriceAddress = _oraclePriceAddress;
        BUSDAddress = _BUSDAddress;
        IDOLAddress = _IDOLAddress;
    }

    using SafeMath for uint256;
    uint256 private nextPlanId;
    address private poolAddress;
    address private oraclePriceAddress;
    address private BUSDAddress;
    address private IDOLAddress;
    
    struct Subscript {
        uint256 start;
        uint256 nextPayment;
    }

    struct Plan {
        address creator;
        address tokenAddress;
        uint256 amount;
        uint256 duration;
    }
    
    mapping(uint256 => Plan) private plans;
    mapping(address => mapping(uint256 => Subscript)) private subscriptions;
    mapping(address => bool) private creators;

    event CreatorCreated(address creatorAddress);
    event PlanCreated(address tokenAddress, uint256 planId, uint256 amount, uint256 duration);
    event PlanUpdated(address tokenAddress, uint256 planId, uint256 amount, uint256 duration);
    event Subscribed(
        uint256 amount,
        uint256 idolAmount,
        uint256 planId,
        uint256 expiredOn
    );

    event Tipped(address creator, address tokenAddress, uint256 amount);

    function setOraclePriceAddres(address _oraclePriceAddress)
        external
        onlyOwner
    {
        oraclePriceAddress = _oraclePriceAddress;
    }

    function setPoolAddress(address _poolAddress) external onlyOwner {
        poolAddress = _poolAddress;
    }
    
    function setBUSDAddress(address _BUSDAddress) external onlyOwner {
        BUSDAddress = _BUSDAddress;
    }
    
    function setIDOLAddress(address _IDOLAddress) external onlyOwner {
        IDOLAddress = _IDOLAddress;
    }

    function createCreator() external {
        creators[msg.sender] = true;
        emit CreatorCreated(msg.sender);
    }

    function createPlan(address _tokenAddress, uint256 _amount, uint256 _duration)
        external
        onlyAllow
    {
        // validation
        require(checkIsCreator(msg.sender), "caller is not the creator");
        require(_amount > 0, "amount needs to be > 0");
        require(_duration > 0, "duration needs to be > 0");
        plans[nextPlanId] = Plan(msg.sender, _tokenAddress, _amount, _duration);

        emit PlanCreated(_tokenAddress, nextPlanId, _amount, _duration);
        nextPlanId = nextPlanId.add(1);
    }

    function updatePlan(
        address _tokenAddress,
        uint256 _planId,
        uint256 _amount,
        uint256 _duration
    ) external onlyAllow {
        require(checkIsCreator(msg.sender), "caller is not the creator");
        require(_amount > 0, "amount needs to be > 0");
        require(_duration > 0, "duration needs to be > 0");
        plans[_planId] = Plan(msg.sender, _tokenAddress, _amount, _duration);
        require(plans[_planId].amount != 0, "plan not exist");
        emit PlanUpdated(_tokenAddress, _planId, _amount, _duration);
    }

    function checkIsCreator(address _address)
        public
        view
        returns (bool isCreator)
    {
        isCreator = creators[_address];
    }
    
    function checkPrice(uint256 _BUSDAmount, address[] memory _pairToken)
        public
        view
        onlyAllow
        returns (uint256 amount)
    {
         // get price from pancake, convert from BUSD to TOKEN
        uint256[] memory pairAmount = IOraclePrice(oraclePriceAddress).getAmountsOut(_BUSDAmount, _pairToken);
        return pairAmount[1];
    }

    function subscribe(uint256 _planId) external onlyAllow {
        Plan storage plan = plans[_planId];
        require(plan.creator != address(0), "this plan does not exist");

        Subscript memory subscription = subscriptions[msg.sender][_planId];

        // can sub to expired plan only
        if (subscription.start != 0) {
            require(
                block.number > subscription.nextPayment,
                "the plan is not expired yet"
            );
        }
        
        // convert USD plan price to BUSD price
        uint256 ratio = IOraclePrice(oraclePriceAddress).getPrice("BUSD", "USD");
        uint256 BUSDAmount = plan.amount.mul(ratio).div(10 ** 18);
        uint256 amount = 0;

        if (plan.tokenAddress == BUSDAddress) {
            amount = BUSDAmount;
            // transfer BUSD to pool
        }
        else {
            // pay with other token or IDOL
            // convert BUSD price to token price
            address[] memory pairToken = new address[](2);
            pairToken[0] = BUSDAddress;
            pairToken[1] = plan.tokenAddress;
            amount = checkPrice(BUSDAmount, pairToken);
            // transfer token to pool
        }

        // call contract main pool to transfer
        IMainPool(poolAddress).transferToPool(
            msg.sender,
            plan.creator,
            plan.tokenAddress,
            amount
        );
        
        // expired date
        uint256 nextPayment = block.number.add(plan.duration);

        emit Subscribed(plan.amount, amount, _planId, nextPayment);

        // add subscription plan to user
        subscription.start = block.number;
        subscription.nextPayment = nextPayment;
        subscriptions[msg.sender][_planId] = subscription;
    }

    function tip(address _creatorAddress, address _tokenAddress, uint256 _amount)
        external
        onlyAllow
    {
        // call contract main pool to transfer
        IMainPool(poolAddress).transferTipToPool(
            msg.sender,
            _creatorAddress,
            _tokenAddress,
            _amount
        );
        emit Tipped(_creatorAddress, _tokenAddress,  _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

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

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

