// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

import "../libraries/SafeMath.sol";
import "../libraries/Ownable.sol";

interface IMainPool {
    function transferToPool(
        address _userAddress,
        address _creatorAddress,
        uint256 amount
    ) external;

    function transferTipToPool(
        address _userAddress,
        address _creatorAddress,
        uint256 amount
    ) external;
}

interface IOraclePrice {
    function getAmountsOut(uint256 _amountIn)
        external
        view
        returns (uint256[] memory amounts);
}

contract Permission is Ownable {
    mapping(address => bool) blacklist;

    event BanUser(address indexed _address);
    event UnbanUser(address indexed _address);

    modifier checkPermission() {
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
    constructor(address _poolAddress, address _oraclePriceAddress) public {
        poolAddress = _poolAddress;
        oraclePriceAddress = _oraclePriceAddress;
    }

    using SafeMath for uint256;
    uint256 private nextPlanId;
    address private poolAddress;
    address private oraclePriceAddress;

    struct Plan {
        address creator;
        uint256 amount;
        uint256 duration;
    }

    struct Subscript {
        uint256 start;
        uint256 nextPayment;
    }

    struct Subscripe {
        uint256 nextPayment;
        uint256 planId;
        address creator;
        bool isExpired;
    }

    mapping(uint256 => Plan) private plans;
    mapping(address => mapping(uint256 => Subscript)) private subscriptions;
    mapping(address => address[]) private subscribed;
    mapping(address => Subscripe[]) private subscribeList;
    mapping(address => address[]) private subscriber;
    mapping(address => address[]) private tipped;
    mapping(address => address[]) private tipList;
    mapping(address => uint256[]) private creatorPlans;

    mapping(address => bool) private creators;

    event PlanCreated(uint256 planId, uint256 amount, uint256 duration);
    event PlanUpdated(uint256 planId, uint256 amount, uint256 duration);
    event Subscribed(
        uint256 amount,
        uint256 idolAmount,
        uint256 planId,
        uint256 expiredOn
    );

    event Tipped(address creator, uint256 amount);

    function setOraclePriceAddres(address _oraclePriceAddress)
        external
        onlyOwner
    {
        oraclePriceAddress = _oraclePriceAddress;
    }

    function setPoolAddress(address _poolAddress) external onlyOwner {
        poolAddress = _poolAddress;
    }

    function createCreator() external {
        creators[msg.sender] = true;
    }

    function createPlan(uint256 amount, uint256 duration)
        external
        checkPermission
    {
        // validation
        require(checkIsCreator(msg.sender), "caller is not the creator");
        require(amount > 0, "amount needs to be > 0");
        require(duration > 0, "duration needs to be > 0");
        plans[nextPlanId] = Plan(msg.sender, amount, duration);

        // add plan to list
        creatorPlans[msg.sender].push(nextPlanId);

        emit PlanCreated(nextPlanId, amount, duration);
        nextPlanId = nextPlanId.add(1);
    }

    function updatePlan(
        uint256 planId,
        uint256 amount,
        uint256 duration
    ) external checkPermission {
        require(checkIsCreator(msg.sender), "caller is not the creator");
        require(amount > 0, "amount needs to be > 0");
        require(duration > 0, "duration needs to be > 0");
        plans[planId] = Plan(msg.sender, amount, duration);
        require(plans[planId].amount != 0, "plan not exist");
        emit PlanUpdated(planId, amount, duration);
    }

    function checkIsCreator(address _address)
        public
        view
        returns (bool isCreator)
    {
        isCreator = creators[_address];
    }

    function viewCreatorPlans(address _creatorAddress)
        public
        view
        checkPermission
        returns (uint256[] memory planIds)
    {
        return creatorPlans[_creatorAddress];
    }

    function viewSubscribed(address _userAddress)
        public
        view
        checkPermission
        returns (address[] memory addresses)
    {
        return subscribed[_userAddress];
    }

    function viewSubscribeList(address _userAddress)
        public
        view
        checkPermission
        returns (uint256[] memory planId, bool[] memory isExpired)
    {
        Subscripe[] memory subList = subscribeList[_userAddress];
        uint256[] memory planIds = new uint256[](subList.length);
        bool[] memory expireArr = new bool[](subList.length);

        for (uint256 i = 0; i < subList.length; i++) {
            Subscripe memory sub = subList[i];
            if (block.number > sub.nextPayment) {
                expireArr[i] = true;
            }
            planIds[i] = sub.planId;
        }
        return (planIds, expireArr);
    }

    function checkSubscriptionExpired(address _userAddress, uint256 planId)
        public
        view
        checkPermission
        returns (bool isExpired)
    {
        Subscripe[] memory subList = subscribeList[_userAddress];
        for (uint256 i = 0; i < subList.length; i++) {
            Subscripe memory sub = subList[i];
            if (planId == sub.planId) {
                return block.number > sub.nextPayment;
            }
        }
    }

    function checkPriceIdol(uint256 _BUSDAmount)
        public
        view
        checkPermission
        returns (uint256 idolAmount)
    {
        // get price from pancake, convert from BUSD to IDOL
        uint256[] memory pairAmount = IOraclePrice(oraclePriceAddress)
            .getAmountsOut(_BUSDAmount);
        return pairAmount[1];
    }

    function subscribe(uint256 planId) external checkPermission {
        Plan storage plan = plans[planId];
        require(plan.creator != address(0), "this plan does not exist");

        Subscript memory subscription = subscriptions[msg.sender][planId];

        // can sub to expired plan only
        if (subscription.start != 0) {
            require(
                block.number > subscription.nextPayment,
                "the plan is not expired yet"
            );
        }

        // get price from pancake
        uint256 idolAmount = checkPriceIdol(plan.amount);

        // call contract main pool to transfer
        IMainPool(poolAddress).transferToPool(
            msg.sender,
            plan.creator,
            idolAmount
        );

        // expired date
        uint256 nextPayment = block.number.add(plan.duration);

        emit Subscribed(plan.amount, idolAmount, planId, nextPayment);

        // add subscription plan to user
        subscription.start = block.number;
        subscription.nextPayment = nextPayment;
        subscriptions[msg.sender][planId] = subscription;

        // add subscription list
        subscribed[msg.sender].push(plan.creator);

        // add sub list with future isExpired
        subscribeList[msg.sender].push(
            Subscripe(nextPayment, planId, plan.creator, false)
        );

        // add followers
        subscriber[plan.creator].push(msg.sender);
    }

    function tip(address _creatorAddress, uint256 amount)
        external
        checkPermission
    {
        //TODO peach token

        // call contract main pool to transfer
        IMainPool(poolAddress).transferTipToPool(
            msg.sender,
            _creatorAddress,
            amount
        );

        // add tipped list
        tipped[msg.sender].push(_creatorAddress);

        // add who tip creator
        tipList[_creatorAddress].push(msg.sender);

        emit Tipped(_creatorAddress, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;
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
    return add(a, b, "SafeMath: addition overflow");
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
  function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, errorMessage);

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

pragma solidity ^0.5.16;

import "./Context.sol";

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
  constructor () internal {
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
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

pragma solidity 0.5.16;

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
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

