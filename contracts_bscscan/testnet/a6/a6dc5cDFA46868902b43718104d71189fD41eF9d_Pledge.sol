/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

pragma solidity ^0.5.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

library SafeMath {


    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}


library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

contract Pledge{
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    //read
    address  owner;

    address unconfirmedOnwer;

    uint256 airDropAcmount;

    IERC20 qua;

    Counters.Counter private _tokenIdTracker;

    uint256  public three_months = 1 minutes;


    constructor(address quaAddress) public{
        owner = msg.sender;
        qua = IERC20(quaAddress);
    }

    struct Order {
        address user;
        uint256 balance;
        uint256 createTime;
        uint256 threeMonthsAfter;
        uint256 hundredth;
        uint256 expirationTime;
        uint256 confirmAmount;
    }

    mapping(uint256 => Order) public orders;

    mapping(address => OrderList )  userOrders;

    struct OrderList{
        uint256 [] orderList;
    }

    struct User{
        uint256 totalBalnaces;
        uint256 totalConfirmAmount;
        uint256 totalReleaseBalance;
    }

    mapping(address => User ) public users;

    function releaseBalance(uint256 orderId) public view returns(uint256){
        Order memory order = orders[orderId];
        if(order.user==address(0)){
            return 0;
        }
        if(block.timestamp<order.threeMonthsAfter){
            return 0;
        }
        if(block.timestamp>order.expirationTime){
            return order.balance;
        }
        if(block.timestamp>order.threeMonthsAfter){
            return ((block.timestamp.sub(order.threeMonthsAfter)).mul(order.hundredth)).add(order.balance.div(2));
        }
    }


    function admin() public view returns(address){
        return owner;
    }

    function unconfirmedAdmin() public view returns(address){
        return unconfirmedOnwer;
    }

    function getUserOrderList(address account) public view returns(uint256  [] memory){
        return userOrders[account].orderList;
    }

    //write
    function updateAdmin(address newAdmin)external {
        require(admin() == msg.sender,"No permission ");
        unconfirmedOnwer = newAdmin;
    }

    function confirmAdmin() external {
        require(unconfirmedAdmin() == msg.sender,"No permission ");
        owner = unconfirmedOnwer;
        unconfirmedOnwer = address(0);
    }


    function pledgeToken(uint256 pledgeBalance) external {
        require(qua.transferFrom(msg.sender ,address(this),pledgeBalance));
        _tokenIdTracker.increment();
        uint256 orderId = _tokenIdTracker.current();
        uint256 timestamps  = block.timestamp;
        orders[orderId].threeMonthsAfter = timestamps.add(three_months);
        orders[orderId].expirationTime = timestamps.add(three_months).add( 100 minutes);
        orders[orderId].hundredth = pledgeBalance.div(2).div(100 minutes);
        orders[orderId].user= msg.sender;
        orders[orderId].balance = pledgeBalance;
        orders[orderId].createTime = timestamps;
        userOrders[msg.sender].orderList.push(orderId);
        users[msg.sender].totalBalnaces = users[msg.sender].totalBalnaces.add(pledgeBalance);
        users[msg.sender].totalReleaseBalance = users[msg.sender].totalBalnaces.sub(users[msg.sender].totalConfirmAmount);
    }
    function receiveAward(uint256 orderId,uint256 balanceReceive) public{
        Order storage order  = orders[orderId];
        uint256 orderReceiveAward = releaseBalance(orderId);
        if(orderReceiveAward==0){
            return ;
        }

        require(order.confirmAmount<order.balance);
        uint256 balance = orderReceiveAward.sub(order.confirmAmount);
        if(balanceReceive>balance){
            return ;
        }
        require(qua.transfer(order.user,balance));
        order.confirmAmount = orderReceiveAward;
        users[ order.user].totalConfirmAmount = users[ order.user].totalConfirmAmount.add(orderReceiveAward);
        users[ order.user].totalReleaseBalance = users[ order.user].totalReleaseBalance.sub(orderReceiveAward);
    }


}