// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

import "../SafeMath.sol";


interface IMainPool {
    function transferToPool (address _userAddress,address _creatorAddress, uint amount) external payable;
}
    
contract Subscription {
    
    using SafeMath for uint256;
    uint256 public nextPlanId;
    address private poolAddress;

    struct Plan {
        address creator;
        uint256 amount;
        uint256 frequency;
    }

    struct Subscription {
        uint256 start;
        uint256 nextPayment;
    }

    struct Subscripe {
        uint256 nextPayment;
        uint256 planId;
        address creator;
        bool isExpired;
    }

    //TODO what about address instead of id
    mapping(uint256 => Plan) public plans;
    mapping(address => mapping(uint256 => Subscription)) public subscriptions;
    mapping(address => address[]) public subscribed;
    mapping(address => Subscripe[]) public subscribeList;
    mapping(address => address[]) public subscriber;
    address[] public creators;
    address[] public users;

    event PlanCreated(address creator, uint256 planId, uint256 date);
    event PlanUpdated(address creator, uint256 planId, uint256 date);
    event SubscriptionCreated(address user, uint256 planId, uint256 date);
    event PaidSubscribe(
        address from,
        uint256 amount,
        uint256 planId,
        uint256 date
    );
    
    function setPoolAddress(address _poolAddress) external {
        poolAddress = _poolAddress;
    }

    function newCreator(address _creatorAddress) external {
        creators.push(_creatorAddress);
    }

    function newUser(address _userAddress) external {
        users.push(_userAddress);
    }

    function createPlan(uint256 amount, uint256 frequency) external {
        // check if creator
        require(amount > 0, "amount needs to be > 0");
        require(frequency > 0, "frequency needs to be > 0");
        plans[nextPlanId] = Plan(msg.sender, amount, frequency);
        emit PlanCreated(msg.sender, nextPlanId, block.timestamp);
        nextPlanId = nextPlanId.add(1);
    }
    
     function updatePlan(uint256 planId, uint256 amount, uint256 frequency) external {
        require(amount > 0, "amount needs to be > 0");
        require(frequency > 0, "frequency needs to be > 0");
        plans[planId] = Plan(msg.sender, amount, frequency);
        require(plans[planId].amount != 0, 'plan not exist');
        emit PlanUpdated(msg.sender, planId, block.timestamp);
    }

    function viewSubscribed(address _userAddress) public view returns (address[] memory addresses) {
        return subscribed[_userAddress];
    }
    
    function viewSubscribeList(address _userAddress) public view returns (uint256[] memory planId, bool[] memory isExpired) {
        Subscripe[] memory subList = subscribeList[_userAddress];
        uint256[] memory planIds = new uint[](subList.length);
        bool[] memory expireArr = new bool[](subList.length);
        
        for (uint i =0; i<subList.length; i++) {
            Subscripe memory sub = subList[i];
            if (block.timestamp > sub.nextPayment) {
               expireArr[i]=true;
            }
            planIds[i]= sub.planId;
        }
        return (planIds, expireArr);
    }

    function checkSubscriptionExpired(address _userAddress, uint256 planId) public view returns (bool isExpired) {
        Subscripe[] memory subList = subscribeList[_userAddress];
        for (uint256 i = 0; i < subList.length; i++) {
            Subscripe memory sub = subList[i];
            if (planId == sub.planId) {
                return block.timestamp > sub.nextPayment;
            }
        }
    }
    
    // FIXME what about subscriber that expired
    // function viewSubscriber(address _creatorAddress) public view returns (address[] memory addresses, bool[] memory isExpired) {
    //     for (uint256 i=0;i< subscriber[_creatorAddress].length;i++) {
    //         bool[] memory expiredList = new bool[]();
    //         address[] memory addresses = new address[]();
    //         address[] memory subs = subscriber[_creatorAddress];
            
    //         for (uint256 j=0; j<subs.length; j++) {
    //             address memory userAddress = subscribeList[subs[j]];
    //             if (block.timestamp > subs[j].nextPayment) {
    //                 expiredList[j] = true;    
    //             }
    //         }
    //         return (subscriber[_creatorAddress], expiredList);
    //     }
    // }

    function subscribe(uint256 planId) external {
        Plan storage plan = plans[planId];
        require(plan.creator != address(0), "this plan does not exist");
        
        Subscription memory subscription = subscriptions[msg.sender][planId];
        
        // can sub to expired plan only
        if (subscription.start != 0 ) {
            require(block.timestamp > subscription.nextPayment,'the plan is not expired yet'); 
        }

        // call contract main pool to transfer
        IMainPool(poolAddress).transferToPool( msg.sender, plan.creator,  plan.amount);
        emit PaidSubscribe(
            msg.sender,
            plan.amount,
            planId,
            block.timestamp
        );

        // expired date
        uint256 nextPayment = block.timestamp.add(plan.frequency);

        // add subscription plan to user
        subscription.start = block.timestamp;
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

        emit SubscriptionCreated(msg.sender, planId, block.timestamp);
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

