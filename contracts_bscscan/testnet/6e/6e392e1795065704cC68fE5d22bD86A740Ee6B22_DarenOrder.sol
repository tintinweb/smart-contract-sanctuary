// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IDarenOrder.sol";
import "./DarenBonus.sol";

contract DarenOrder is IDarenOrder {
    using SafeMath for uint;

    string public standard = "Daren Order v1.0.0";
    string public version = "v1.0.0";
    uint private primaryKey = 0; // Order index

    address public usdtToken;   // The USDT token
    address public darenToken;  // The Daren token
    address public darenBonus;  // The DarenBonus contract

    // uint private totalFee = 0;
    // uint private availableFee = 0;
    uint public feeRatio = 500; // 5%
    address public feeTo;
    address public feeToSetter;

    uint constant dayInMilliseconds = 1000 * 60 * 60 * 24;

    mapping(uint => Order) public orderPKList;
    mapping(uint => Order) public orderIDList;
    
    uint public totalTransactionAmount;
    uint public allocRatioBase = 1000;  // 50% of fee
    uint public allocRatio = 2000;      // 50% of fee

    uint public orderExpireTime = 30;   // Exipre after 30 days
    uint public voteExpireTime = 7;     // Exipie after 7 days

    bool public allowHolderVote = false;
    uint public allowVoteFromAmount = 1000;

    // Vote: orderID => voter => bool
    mapping(uint => mapping(address => bool)) private orderVotedAddresses;
    mapping(uint => address[]) private orderVotedAddressList;
    mapping(address => bool) private candidates;

    constructor(address _darenBonus, address _darenToken, address _usdtToken) {
        require(_darenToken != address(0), 'darenToken should not be zero');
        require(_usdtToken != address(0), 'usdtToken should not be zero');
        require(_darenBonus != address(0), 'darenBonus should not be zero');

        feeToSetter = msg.sender;
        feeTo = msg.sender;

        darenBonus = _darenBonus;
        usdtToken = _usdtToken;
        darenToken = _darenToken;

        candidates[msg.sender] = true;
    }

    function createOrder(
        string memory _name,
        uint _orderID,
        uint _value,
        address _seller
    ) public payable override returns (uint pk) {
        require(_seller != msg.sender, "Can't purchase own services.");
        require(_orderID > 0, "Order ID invalid.");
        require(orderIDList[_orderID].pk <= 0, "Order ID already exist.");
        require(_value >= 5 * 10 ** ERC20(usdtToken).decimals(), "No free service.");

        ERC20(usdtToken).transferFrom(msg.sender, address(this), _value);

        primaryKey += 1;
        Order memory order = Order(
            primaryKey,
            _name,
            _orderID,
            _value,
            _seller,
            msg.sender,
            OrderStatus.Active,
            block.timestamp,
            OrderVotes(
                0, 0, VoteType.None, 0
            )
        );

        orderIDList[_orderID] = order;
        orderPKList[primaryKey] = order;
        emit OrderCreated(
            primaryKey,
            _orderID,
            _name,
            _value,
            msg.sender,
            _seller,
            block.timestamp
        );
        return order.pk;
    }

    function getStatusKeyByValue(OrderStatus _status) internal pure returns (string memory strStatus) {        
        if (OrderStatus.Active == _status) return "ACTIVE";
        if (OrderStatus.Submitted == _status) return "SUBMITTED";
        if (OrderStatus.Completed == _status) return "COMPLETED";
        if (OrderStatus.Withdrawn == _status) return "WITHDRAWN";

        // if (OrderStatus.Expired == _status) return "EXPIRED";

        // if (OrderStatus.WantRefund == _status) return "WANT_REFUND";
        if (OrderStatus.AgreeToRefund == _status) return "AGREE_TO_REFUND";
        if (OrderStatus.Refunded == _status) return "REFUNDED";

        if (OrderStatus.Voting == _status) return "VOTING";
        // if (OrderStatus.Voted == _status) return "VOTED";
        require(false, "Invalid status value");
    }

    function cmpstr(string memory s1, string memory s2) public pure returns(bool){
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function getStatusValueByKey(string memory _status) internal pure returns (OrderStatus orderStatus) {
        if (cmpstr("ACTIVE", _status)) return OrderStatus.Active;
        if (cmpstr("SUBMITTED", _status)) return OrderStatus.Submitted;
        if (cmpstr("COMPLETED", _status)) return OrderStatus.Completed;
        if (cmpstr("WITHDRAWN", _status)) return OrderStatus.Withdrawn;

        // if (cmpstr("EXPIRED", _status)) return OrderStatus.Expired;

        // if (cmpstr("WANT_REFUND", _status)) return OrderStatus.WantRefund;
        if (cmpstr("AGREE_TO_REFUND", _status)) return OrderStatus.AgreeToRefund;
        if (cmpstr("REFUNDED", _status)) return OrderStatus.Refunded;

        if (cmpstr("VOTING", _status)) return OrderStatus.Voting;
        // if (cmpstr("VOTED", _status)) return OrderStatus.Voted;
        require(false, "Invalid status key");
    }

    function getOrder(uint _orderID) public view override returns (
        uint pk,
        uint orderID,
        string memory name,
        uint value,
        address seller,
        address buyer,
        string memory status,
        uint createdAt,
        OrderVotes memory votes
    ) {
        require(_orderID > 0, "order ID should greater than 0.");
        Order memory order = orderIDList[_orderID];
        require(order.pk > 0, "order does not exist.");

        return (
            order.pk,
            order.orderID,
            order.name,
            order.value,
            order.seller,
            order.buyer,
            getStatusKeyByValue(order.status),
            order.createdAt,
            order.votes
        );
    }

    function getOrderByPK(uint _pk) public view override returns (
        uint pk,
        uint orderID,
        string memory name,
        uint value,
        address seller,
        address buyer,
        string memory status,
        uint createdAt,
        OrderVotes memory votes
    ) {
        require(_pk > 0, "order ID should greater than 0.");
        Order memory order = orderPKList[_pk];
        // require(order > 0, "order does not exist.");

        return (
            order.pk,
            order.orderID,
            order.name,
            order.value,
            order.seller,
            order.buyer,
            getStatusKeyByValue(order.status),
            order.createdAt,
            order.votes
        );
    }

    function updateOrder(uint _orderID, string memory _toStatusStr) public override {
        Order storage order = orderIDList[_orderID];
        OrderStatus _toStatus = getStatusValueByKey(_toStatusStr);
        require(order.status != OrderStatus.Completed, "Order have been completed.");
        require(order.status != OrderStatus.Withdrawn, "Order have been completed.");
        require(order.status != OrderStatus.AgreeToRefund, "Order have been agreed to refund.");
        require(order.status != OrderStatus.Refunded, "Order have been refunded.");
        require(order.status != OrderStatus.Voting, "Order is voting.");

        if (_toStatus == OrderStatus.Submitted) {
            require(order.status == OrderStatus.Active, "Only active orders can be submitted.");
            require(msg.sender == order.seller, "Only seller can submit the order.");

            order.status = OrderStatus.Submitted;
            emit OrderUpdated(order.pk, order.orderID, getStatusKeyByValue(order.status));
        } else if (_toStatus == OrderStatus.Completed) {
            require(order.status == OrderStatus.Submitted, "Only submitted orders can be done.");
            require(msg.sender == order.buyer, "Only buyer can confirm the order.");

            order.status = OrderStatus.Completed;
            emit OrderUpdated(order.pk, order.orderID, getStatusKeyByValue(order.status));
        } else if (_toStatus == OrderStatus.AgreeToRefund) {
            require(msg.sender == order.seller, "Only seller can agree to refund.");

            order.status = OrderStatus.AgreeToRefund;
            emit OrderUpdated(order.pk, order.orderID, getStatusKeyByValue(order.status));
        } else if (_toStatus == OrderStatus.Voting) {
            require(msg.sender == order.buyer, "Only buyer can request a vote.");
            order.votes.createdAt = block.timestamp;

            order.status = OrderStatus.Voting;
            emit OrderUpdated(order.pk, order.orderID, getStatusKeyByValue(order.status));
        }
    }

    function includeInCandidates(address _newCandidate) external {
        require(msg.sender == feeToSetter, "includeInCandidates: not permitted");
        candidates[_newCandidate] = true;
    }

    function excludeFromCandidates(address _newCandidate) external {
        require(msg.sender == feeToSetter, "excludeFromCandidates: not permitted");
        candidates[_newCandidate] = false;
    }

    function vote(uint _orderID, VoteType voteType) external {
        Order storage order = orderIDList[_orderID];
        require(voteType == VoteType.Buyer || voteType == VoteType.Seller, "Invalid vote type");
        require(order.status == OrderStatus.Voting, "Only voting order could be voted");
        require(candidates[msg.sender], "Only candidates could vote");
        uint currentTime = block.timestamp;
        require(currentTime < order.votes.createdAt + voteExpireTime * dayInMilliseconds, "vote expired");
        require(msg.sender != order.buyer && msg.sender != order.seller, "Traders could not vote");
        require(orderVotedAddresses[_orderID][msg.sender] != true, "You already voted");

        if (voteType == VoteType.Buyer) {
            orderVotedAddresses[_orderID][msg.sender] = true;
            orderVotedAddressList[_orderID].push(msg.sender);
            order.votes.buyer = order.votes.buyer.add(1);
            order.votes.lastVote = VoteType.Buyer;
            return;
        } else if (voteType == VoteType.Seller) {
            orderVotedAddresses[_orderID][msg.sender] = true;
            orderVotedAddressList[_orderID].push(msg.sender);
            order.votes.seller = order.votes.seller.add(1);
            order.votes.lastVote = VoteType.Seller;
            return;
        } else {
            require(false, "Invalid vote type");
        }
    }

    // Both buyer and seller could withdraw: 
    //  buyer withdraws ACCEPT_TO_REFUND order.
    //  seller withdraws COMPLETED order.
    function withdrawOrder(uint _orderID) external override {
        Order storage order = orderIDList[_orderID];
        ERC20 u = ERC20(usdtToken);
        DarenBonus db = DarenBonus(darenBonus);
        
        uint fee = order.value.mul(feeRatio).div(10000);
        uint finalValue = order.value.sub(fee);

        if (order.status == OrderStatus.Completed) {
            // order completed, seller withdraw the order.
            db.completeOrder(order.buyer, order.seller, order.value, fee);

            u.transfer(order.seller, finalValue);
            u.transfer(feeTo, fee);
            order.status = OrderStatus.Withdrawn;

            emit OrderWithdrawn(order.pk, _orderID, getStatusKeyByValue(OrderStatus.Withdrawn));
        } else if (order.status == OrderStatus.AgreeToRefund) {
            // seller agree to refund, buyer withdraw the order.
            u.transfer(order.buyer, order.value);
            order.status = OrderStatus.Refunded;

            emit OrderWithdrawn(order.pk, _orderID, getStatusKeyByValue(OrderStatus.Refunded));
        } else if (order.status == OrderStatus.Submitted) {
            // order expired and seller submitted, seller withdraw the order.
            require(block.timestamp > order.createdAt + orderExpireTime * dayInMilliseconds, "Submitted order didn't finished.");

            db.completeOrder(order.buyer, order.seller, order.value, fee);

            u.transfer(order.seller, finalValue);
            u.transfer(feeTo, fee);
            order.status = OrderStatus.Withdrawn;
            
            emit OrderWithdrawn(order.pk, _orderID, getStatusKeyByValue(OrderStatus.Withdrawn));
        } else if (order.status == OrderStatus.Active) {
            // active order expired and order in active, buyer withdraw the order.
            require(block.timestamp > order.createdAt + orderExpireTime * dayInMilliseconds, "Active order didn't finished.");
            u.transfer(order.buyer, order.value);
            order.status = OrderStatus.Refunded;
            
            emit OrderWithdrawn(order.pk, _orderID, getStatusKeyByValue(OrderStatus.Refunded));
        } else if (order.status == OrderStatus.Voting) {
            require(block.timestamp > order.votes.createdAt + voteExpireTime * dayInMilliseconds, "Voting didn't finished.");
            if (fee < ERC20(usdtToken).decimals() * 5) {
                fee = ERC20(usdtToken).decimals() * 5;
                finalValue = order.value.sub(fee);
            }

            if (order.votes.buyer > order.votes.seller) {
                require(msg.sender == order.buyer, "You didn't win the Vote. Buyer winned.");
            } else if (order.votes.seller > order.votes.buyer) {
                require(msg.sender == order.seller, "You didn't win the Vote. Seller winned.");
            } else {
                // TODO: ...
                // require(false, "Vote draw");
            }

            if (order.votes.buyer > order.votes.seller || (order.votes.buyer == order.votes.seller && order.votes.lastVote == VoteType.Seller)) {
                require(msg.sender == order.buyer, "You didn't win the Vote. Buyer winned.");

                u.transfer(order.buyer, finalValue);
                u.transfer(feeTo, fee);
                db.voteToCompleteOrder(orderVotedAddressList[order.orderID], order.buyer, order.seller, order.value, fee);
                order.status = OrderStatus.Refunded;
                
                emit OrderWithdrawn(order.pk, _orderID, getStatusKeyByValue(OrderStatus.Refunded));
            } else if (order.votes.seller > order.votes.buyer || (order.votes.buyer == order.votes.seller && order.votes.lastVote == VoteType.Buyer)) {
                require(msg.sender == order.seller, "You didn't win the Vote. Seller winned.");

                u.transfer(order.seller, finalValue);
                u.transfer(feeTo, fee);
                db.voteToCompleteOrder(orderVotedAddressList[order.orderID], order.buyer, order.seller, order.value, fee);
                order.status = OrderStatus.Withdrawn;
                
                emit OrderWithdrawn(order.pk, _orderID, getStatusKeyByValue(OrderStatus.Withdrawn));
            } else {
                require(false, "Vote EMPTY");
            }
        } else {
            require(false, "Invalid withdraw");
        }
        
        // totalFee = totalFee.add(fee);
        // availableFee = availableFee.add(fee);
        // order.value = order.value.sub(fee);

    }

    function getPK () external view returns (uint) {
        require(msg.sender == feeToSetter, 'getPK: FORBIDDEN');
        return primaryKey;
    }
    
    function setFeeTo(address payable _feeTo) external {
        require(msg.sender == feeToSetter, 'setFeeTo: FORBIDDEN');
        require(_feeTo != address(0), 'Should not be zero address');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'setFeeToSetter: FORBIDDEN');
        require(_feeToSetter != address(0), 'Should not be zero address');
        feeToSetter = _feeToSetter;
    }

    function setAllocRatio(uint _allocRatio) external {
        require(msg.sender == feeToSetter, 'setAllocRatio: FORBIDDEN');
        require(_allocRatio > 0, 'Alloc ratio should be positive');
        allocRatio = _allocRatio;
    }

    function setOrderExpireTime(uint _expireDay) external {
        require(msg.sender == feeToSetter, 'setOrderExpireTime: FORBIDDEN');
        require(_expireDay > 0, 'Expire days should be positive');
        orderExpireTime = _expireDay;
    }

    function setVoteExpireTime(uint _expireDay) external {
        require(msg.sender == feeToSetter, 'setVoteExpireTime: FORBIDDEN');
        require(_expireDay > 0, 'Expire days should be positive');
        voteExpireTime = _expireDay;
    }

    function setAllowHolderVote(uint _holdAmount) external {
        require(msg.sender == feeToSetter, 'setAllowHolderVote: FORBIDDEN');
        if (_holdAmount > 0) {
            allowHolderVote = true;
            allowVoteFromAmount = _holdAmount;
        } else {
            allowHolderVote = false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDarenOrder {
    enum OrderStatus {
        None,
        Active,     // 1
        Submitted,  // 2
        Completed,  // 3
        Withdrawn,  // 4
        
        Expired,        // 5

        // WantRefund,     // 6
        AgreeToRefund,    // 7 seller want to cancel the order
        RefuseRefund,   // 8 buyer failed the order
        Refunded,       // 9

        Voting,         // 10
        Voted           // 
    }

    enum VoteType {
        None,
        Buyer,
        Seller
    }

    struct OrderVotes {
        uint buyer;
        uint seller;
        VoteType lastVote;
        uint createdAt;
    }

    struct Order {
        // Primary Key from 1 ...
        uint pk;
        // Service name
        string name;
        // unique order ID
        uint orderID;

        // Value of this order in USD
        uint value;

        address seller;
        address buyer;

        OrderStatus status;
        uint createdAt;

        OrderVotes votes;
    }

    // Buyer could pay for service and create an order
    event OrderCreated(
        uint pk,
        uint orderID,
        string name,
        uint value,
        address buyer,
        address seller,
        uint createdAt
    );
    function createOrder(
        string memory _name,
        uint _orderID,
        uint _value,
        address _seller
    ) external payable returns (uint orderID);

    function getOrder(uint _orderID) external view returns (
        uint pk,
        uint orderID,
        string memory name,
        uint value,
        address seller,
        address buyer,
        string memory status,
        uint createdAt,
        OrderVotes memory votes
    );
    function getOrderByPK(uint _pk) external view returns (
        uint pk,
        uint orderID,
        string memory name,
        uint value,
        address seller,
        address buyer,
        string memory status,
        uint createdAt,
        OrderVotes memory votes
    );

    event OrderUpdated(uint pk, uint orderID, string status);
    function updateOrder(uint _orderID, string memory _toStatusStr) external;

    event OrderWithdrawn(uint pk, uint orderID, string status);
    function withdrawOrder(uint _orderID) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDarenBonus {
    function getCurrentReward() external view returns (uint);
    
    event OrderCompleted(address buyer, address seller, uint value, uint fee);
    function completeOrder(address _buyer, address _seller, uint _value, uint _fee) external;

    event RewardWithdrawn(address user, uint amount);
    function withdrawReward() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IDarenBonus.sol";

contract DarenBonus is IDarenBonus {
  using SafeMath for uint256;

  address public darenToken;
  address public setter;

  uint256 public totalTransactionAmount;
  uint256 public allocRatioBase = 1000; // 1 / 2
  uint256 public allocRatio = 2000;

  uint256 public usdtExchangeRate = 10**9; // 1:1
  uint256 public usdtExchangeRateBase = 10**9;

  // struct UserBonus {
  //     uint transactionAmount;
  //     uint rewardableAmount;
  //     uint blockNumber;
  // }

  mapping(address => uint256) public userBonus;
  mapping(address => uint256) public userTotalAmount;
  mapping(address => bool) public darenOrders; // whitelist

  constructor(address _darenToken) {
    darenToken = _darenToken;

    totalTransactionAmount = 0;
    // Reward ratio: allocRatioBase / allocRatio = 1000 / 2000 =
    // allocRatioBase = 1000;
    // allocRatio = 2000;

    darenOrders[msg.sender] = true;
  }

  function completeOrder(
    address _buyer,
    address _seller,
    uint256 _value,
    uint256 _fee
  ) external override {
    require(darenOrders[msg.sender], "Invalid daren order address.");

    uint256 bonusAmount = _fee.mul(allocRatioBase).div(allocRatio);
    uint256 finalAmount = bonusAmount.mul(usdtExchangeRateBase).div(
      usdtExchangeRate
    );

    userBonus[_buyer] = userBonus[_buyer].add(finalAmount);
    userBonus[_seller] = userBonus[_seller].add(finalAmount);
    userTotalAmount[_seller] = userTotalAmount[_seller].add(_value);
    totalTransactionAmount = totalTransactionAmount.add(_value);
    emit OrderCompleted(_buyer, _seller, _value, _fee);
  }

  function voteToCompleteOrder(
    address[] memory voters,
    address _buyer,
    address _seller,
    uint256 _value,
    uint256 _fee
  ) external {
    uint256 voterCount = voters.length;

    uint256 bonusAmount = _fee.div(voterCount);
    uint256 finalAmount = bonusAmount.mul(usdtExchangeRateBase).div(
      usdtExchangeRate
    );

    for (uint256 i = 0; i < voters.length; i++) {
      userBonus[voters[i]] = userBonus[voters[i]].add(finalAmount);
    }

    userTotalAmount[_seller] = userTotalAmount[_seller].add(_value);
    totalTransactionAmount = totalTransactionAmount.add(_value);
    emit OrderCompleted(_buyer, _seller, _value, _fee);
  }

  function getCurrentReward() external view override returns (uint256) {
    uint256 bonus = userBonus[msg.sender];
    return bonus;
  }

  function withdrawReward() external override {
    uint256 bonus = userBonus[msg.sender];
    ERC20 dt = ERC20(darenToken);
    require(dt.balanceOf(address(this)) > bonus, "Withdraw is unavailable now");
    
    uint256 reward = bonus;
    require(reward > 0, "You have no bonus.");
    if (reward > 0) {
      userBonus[msg.sender] = 0;
      dt.transfer(msg.sender, reward);
      emit RewardWithdrawn(msg.sender, reward);
    }
  }

  function setAllocRatio(uint256 _allocRatio) external {
    require(msg.sender == setter, "setAllocRatio: FORBIDDEN");
    allocRatio = _allocRatio;
  }

  function includeInDarenOrders(address _darenOrder) external {
    darenOrders[_darenOrder] = true;
  }

  function excludeFromDarenOrders(address _darenOrder) external {
    darenOrders[_darenOrder] = false;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}