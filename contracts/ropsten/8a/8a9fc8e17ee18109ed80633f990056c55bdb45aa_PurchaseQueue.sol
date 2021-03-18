/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

// File: contracts/@openzeppelin/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: contracts/PurchaseQueue.sol

pragma solidity >=0.6.0 <0.7.0;


//申购动作，排队用
struct PurchaseAction
{
    address user;
    uint256 amount;
    uint256 timestamp;
}


struct QueueStruct {
    PurchaseAction[200] data;
    uint256 front;
    uint256 rear;
}


library Queue
{
    using SafeMath for uint256;

    // Queue length
    function length(QueueStruct storage q) view internal returns (uint256) {
        return q.rear - q.front;
    }

    // push
    function push(QueueStruct storage q, PurchaseAction memory data) internal
    {
        if ((q.rear + 1) % q.data.length == q.front)
            pop(q,0); // throw first;
        q.data[q.rear] = data;
        q.rear = (q.rear + 1) % q.data.length;
    }

    // pop (amount==0 表示整个最近一个排队项)
    //如果amount大于最近 的一个排队项，则pop此排队项。否则只部分pop此排队项（相当于改为剩余的数量，此排队项还是队列头）
    function pop(QueueStruct storage q,uint256 amount) internal returns (PurchaseAction memory )
    {
        require (q.rear != q.front,"Failed to pop from empty queue");
        PurchaseAction storage action = q.data[q.front];
        if (amount==0 || action.amount<=amount){
            PurchaseAction memory userAction=q.data[q.front];
            delete q.data[q.front];
            q.front = (q.front + 1) % q.data.length;
            return userAction;
        }else{ //amount 不足以pop队列头的action
            action.amount=action.amount.sub(amount);
            return PurchaseAction(action.user,amount,action.timestamp);
        }
    }

    function header(QueueStruct storage q) internal view returns(PurchaseAction memory){
        require (q.rear != q.front,"Failed to get header from empty queue");
        return q.data[q.front];
    }
}


contract PurchaseQueue
{
    using SafeMath for uint256;
    using Queue for QueueStruct;
    QueueStruct requests;
    mapping(address/*user*/=>uint256) _cancelledAmount;

    mapping(address=>uint256) userAmount;

    constructor(uint256 maxCount) public {
        //requests.data=new PurchaseAction[](maxCount);
    }

    function addRequest(address actionUser,uint256 actionAmount,uint256 actionTimestamp) public{
        requests.push(PurchaseAction(actionUser,actionAmount,actionTimestamp));
        userAmount[actionUser] = userAmount[actionUser].add(actionAmount);
    }

    //pop 出来的项的amount可能小于amount（需要外部loop处理）。
    //如果amount大于当前的项的amount，将只修改当前项的amount为剩余的值，不做真正的pop动作。看上去就像把当前项劈开为两个，而pop了前面的一个。
    function popRequest(uint256 amount) public returns (address actionUser,uint256 actionAmount,uint256 actionTimestamp) {
        require(requests.length()>0,"Empty queue");
        PurchaseAction memory action =requests.pop(amount);
        for (;_cancelledAmount[action.user]!=0;){//有预撤销记录
            if (action.amount>_cancelledAmount[action.user]){//当前项有剩余，修改当前项的amount并返回
                action.amount=action.amount.sub(_cancelledAmount[action.user]);
                _cancelledAmount[action.user]=0;
                break;
            }else{//skip 完整的当前项
                _cancelledAmount[action.user]=_cancelledAmount[action.user].sub(action.amount);
                action =requests.pop(amount);
            }
        }

        userAmount[actionUser] = userAmount[action.user].sub(action.amount);
        return (action.user,action.amount,action.timestamp);
    }

    function queueLength() view public returns (uint256) {
        return requests.length();
    }

    function getActionAmount(address user) view public returns(uint256){
        return userAmount[user];
    }

    function cancelRequest(address actionUser,uint256 actionAmount) public{
        require(userAmount[actionUser]>=actionAmount,"Not enough amount to cancel lineup");
        userAmount[actionUser]=userAmount[actionUser].sub(actionAmount);
        _cancelledAmount[actionUser]=_cancelledAmount[actionUser].add(actionAmount);  //先记录，避免loop查找。pop时候skip已经取消的item。
    }
}