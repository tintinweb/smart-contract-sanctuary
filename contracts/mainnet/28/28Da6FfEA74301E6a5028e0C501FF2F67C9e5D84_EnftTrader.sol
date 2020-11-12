// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: contracts/IETradingNFT.sol

pragma solidity 0.6.12;

interface IETradingNFT {
    function mint(address _to, uint256 _id, uint256 _quantity, bytes memory _data) external ;
	function totalSupply(uint256 _id) external view returns (uint256);
    function maxSupply(uint256 _id) external view returns (uint256);
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
}

// File: contracts/EnftTrader.sol

pragma solidity 0.6.12;



/**
 * @title EnftTrade
 */

contract EnftTrader {
    using SafeMath for uint256;
    // Enft token.
    IETradingNFT ETradingNFT;
    address payable public dev;

    // Info of each order.
    struct EnftOrderInfo {
        address payable owner; // owner
        uint256 price; // price 
        uint256 enftID; // enftID
        bool isOpen; // open order
    }

    // Info of each order list.
    EnftOrderInfo[] public orderList;

    uint256 private _currentOrderID = 0;

    event Order(uint256 indexed orderID, address indexed user, uint256 indexed wid, uint256 price);
    event Cancel(uint256 indexed orderID, address indexed user, uint256 indexed wid);
    event Buy(uint256 indexed orderID, address indexed user, uint256 indexed wid);

    constructor(
        IETradingNFT _ETradingNFT
    ) public {
        ETradingNFT = _ETradingNFT;
        dev = msg.sender;
        orderList.push(EnftOrderInfo({
            owner: address(0),
            price: 0,
            enftID: 0,
            isOpen: false
        }));
    }

    function withdrawFee() external {
        require(msg.sender == dev, "only dev");
        dev.transfer(address(this).balance);
    }

    function orderEnft(uint256 _enftID, uint256 _price) external {
        // transferFrom
        ETradingNFT.safeTransferFrom(msg.sender, address(this), _enftID, 1, "");

        orderList.push(EnftOrderInfo({
            owner: msg.sender,
            price: _price,
            enftID: _enftID,
            isOpen: true
        }));

        uint256 _id = _getNextOrderID();
        _incrementOrderId();

        emit Order(_id, msg.sender, _enftID, _price);

    }

    function cancel(uint256 orderID) external {
        EnftOrderInfo storage orderInfo = orderList[orderID];
        require(orderInfo.owner == msg.sender, "not your order");
        require(orderInfo.isOpen == true, "only open order can be cancel");

        orderInfo.isOpen = false;

        // transferFrom
        ETradingNFT.safeTransferFrom(address(this), msg.sender, orderInfo.enftID, 1, "");

        emit Cancel(orderID, msg.sender, orderInfo.enftID);

    }

    function buyEnft(uint256 orderID) external payable {
        EnftOrderInfo storage orderInfo = orderList[orderID];
        require(orderInfo.owner != address(0),"bad address");
        require(orderInfo.owner != msg.sender, "it is your order");
        require(orderInfo.isOpen == true, "only open order can buy");
        require(msg.value == orderInfo.price, "error price");

        // 3% fee
        uint256 sellerValue = msg.value.mul(97).div(100);
        orderInfo.isOpen = false;

        // transferFrom
        ETradingNFT.safeTransferFrom(address(this), msg.sender, orderInfo.enftID, 1, "");
        orderInfo.owner.transfer(sellerValue);
        emit Buy(orderID, msg.sender, orderInfo.enftID);
    }

	function _getNextOrderID() private view returns (uint256) {
		return _currentOrderID.add(1);
	}
	function _incrementOrderId() private {
		_currentOrderID++;
	}

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4){
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}