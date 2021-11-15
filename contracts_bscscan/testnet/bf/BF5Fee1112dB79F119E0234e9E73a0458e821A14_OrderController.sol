// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";


contract OrderController is Ownable {

    struct Order {
        uint256 id;
        uint256 amountA;
        uint256 amountB;
        uint256 amountLeftToFill;
        uint256 fees;
        address tokenA;
        address tokenB;
        address user;
        bool isCancelled;
    }

    uint256 internal _nonce;
    uint256 internal _fee;
    mapping(uint256 => Order) internal _orders;
    mapping(address => uint256) internal _feeBalances;
    mapping(address => uint256[]) internal _userOrderIds;
    uint256[] internal _orderIds;

    uint256 private constant TEN_THOUSAND = 10000;

    event OrderCreated(
        uint256 id,
        uint256 amountA,
        uint256 amountB,
        address tokenA,
        address tokenB,
        address user,
        bool isMarket
    );
    
    event OrderUpdated(
        uint256 id,
        uint256 amountA,
        uint256 amountB,
        uint256 amountLeftToFill,
        address tokenA,
        address tokenB,
        address user,
        bool isMarket,
        uint256 fee
    );

    event OrderCancelled(uint256 id);

    constructor(uint256 fee) {
        _fee = TEN_THOUSAND - fee;
        _nonce = 0;
    }

    function getOrderIdLength() external view returns(uint256) {
        return _orderIds.length;
    }

    function getOrderId(uint256 index) external view returns(uint256) {
        return _orderIds[index];
    }

    function getUserOrderIdsLength() external view returns(uint256) {
        return _userOrderIds[_msgSender()].length;
    }

    function getUserOrderIds(uint256 from, uint256 length) external view returns(uint256[] memory) {
        uint256[] memory userOrderIds = _userOrderIds[_msgSender()];
        if(_userOrderIds[_msgSender()].length > 1000) {
            uint256 cnt;
            uint256 limit = from + length >= userOrderIds.length ? userOrderIds.length : from + length;
            uint256[] memory paginatedArray = new uint256[](limit - from);
            for(uint256 i = from; i < limit; i++) {
                paginatedArray[cnt++] = userOrderIds[i];
            }
            return paginatedArray;
        }
        return userOrderIds;
    }

    function getOrderInfo(uint256 _id) external view returns(uint256, uint256, uint256, uint256, uint256, address, address, address, bool) {
        Order memory order = _orders[_id];
        return (
            order.id,
            order.amountA,
            order.amountB,
            order.amountLeftToFill,
            order.fees,
            order.tokenA,
            order.tokenB,
            order.user,
            order.isCancelled
        );
    }

     function getAccumulatedFeeBalance(address token) external view onlyOwner returns(uint256) {
        return _feeBalances[token];
    }


    function getFee() external view returns(uint256) {
        return TEN_THOUSAND - _fee;
    }

    function cancelOrder(uint256 id) external {
        Order storage order = _orders[id];
        require(_msgSender() == order.user, "OC: UNAUTHORIZED_ORDER_CANCELLATION");
        uint256 transferAmount = order.amountB * order.amountLeftToFill / order.amountA;
        TransferHelper.safeTransfer(order.tokenB, order.user, transferAmount);
        order.isCancelled = true;
        emit OrderCancelled(order.id);
    }

    function setFee(uint256 newFee) external onlyOwner {
        _fee = TEN_THOUSAND - newFee;
    }

    function withdrawFee(address token) external onlyOwner {
        TransferHelper.safeTransfer(token, _msgSender(), _feeBalances[token]);
        _feeBalances[token] = 0;
    }

    function matchOrders(
        uint256[] calldata matchedOrderIds,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        bool isMarket
        ) external {

        uint256 totalPayout;
        uint256 totalFee;
        uint256 id = _generateOrderId(tokenA, tokenB, amountA, amountB, _msgSender(), isMarket);
        Order storage newOrder = _orders[id];

        for (uint256 i = 0; i < matchedOrderIds.length; i++) {
            Order storage matchedOrder = _orders[matchedOrderIds[i]];
            uint256 matchedOrderAmountB = matchedOrder.amountB;
            uint256 matchedOrderAmountA = matchedOrder.amountA;
            uint256 matchedOrderAmountLeftToFill = matchedOrder.amountLeftToFill;

            if(newOrder.amountLeftToFill == 0) {
                break;
            }

            require(matchedOrder.tokenB == tokenA && matchedOrder.tokenA == tokenB, "OC: INCORRECT_TOKEN_MATCH");

            if (!isMarket) {
                require(amountA * matchedOrderAmountA <= amountB * matchedOrderAmountB, "OC: INCORRECT_PRICE_MATCH");
            }

            if (matchedOrderAmountLeftToFill == 0 || matchedOrder.isCancelled) {
                continue;
            }

            uint256 transferAmount;
            uint256 fee;

            if (newOrder.amountLeftToFill * matchedOrderAmountA >= matchedOrderAmountLeftToFill * matchedOrderAmountB) {
                fee = _getFee(matchedOrderAmountLeftToFill);

                assembly {
                    transferAmount := div(mul(matchedOrderAmountLeftToFill, matchedOrderAmountB), matchedOrderAmountA)
                    totalPayout := add(totalPayout, transferAmount)
                    // let newOrderAmountLeftToFill := sload(add(newOrder.slot, 0x3))
                    // sstore(newOrderAmountLeftToFill, sub(newOrderAmountLeftToFill, transferAmount))
                    // sstore(sload(add(matchedOrder.slot, 0x3)), 0)
                }

                TransferHelper.safeTransferFrom(tokenB, _msgSender(), matchedOrder.user, _getAmountSubFee(matchedOrderAmountLeftToFill));
                
                newOrder.amountLeftToFill -= transferAmount;
                matchedOrder.amountLeftToFill = 0;
                    
            } else {
                transferAmount = newOrder.amountLeftToFill * matchedOrderAmountA / matchedOrderAmountB;
                fee = _getFee(transferAmount);

                totalPayout += newOrder.amountLeftToFill;

                TransferHelper.safeTransferFrom(tokenB, _msgSender(), matchedOrder.user, _getAmountSubFee(transferAmount));

                newOrder.amountLeftToFill = 0;
                matchedOrder.amountLeftToFill -= transferAmount;
            }
            assembly { 
                totalFee := add(totalFee, fee)
            }
            matchedOrder.fees = matchedOrder.fees + fee;
            emit OrderUpdated(
                matchedOrder.id,
                matchedOrder.amountA,
                matchedOrder.amountB,
                matchedOrder.amountLeftToFill,
                matchedOrder.tokenA,
                matchedOrder.tokenB,
                matchedOrder.user,
                false,
                matchedOrder.fees
            );
        }

        if (newOrder.amountLeftToFill > 100 && !isMarket) {
            uint256 transferAmount = newOrder.amountLeftToFill * amountB / amountA;
            TransferHelper.safeTransferFrom(tokenB, _msgSender(), address(this), transferAmount);
        }
        TransferHelper.safeTransfer(tokenA, _msgSender(), _getAmountSubFee(totalPayout));
        TransferHelper.safeTransferFrom(tokenB, _msgSender(), address(this), totalFee);
        _feeBalances[tokenA] = _feeBalances[tokenA] + _getFee(totalPayout);
        _feeBalances[tokenB] = _feeBalances[tokenB] + totalFee;

        newOrder.fees = newOrder.fees + _getFee(totalPayout);
         emit OrderUpdated(
            id,
            newOrder.amountA,
            newOrder.amountB,
            newOrder.amountLeftToFill,
            newOrder.tokenA,
            newOrder.tokenB,
            newOrder.user,
            isMarket,
            newOrder.fees
        );
    }

    function createOrder(address tokenA, address tokenB, uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "OC: INSUFFICIENT_INPUT_AMOUNT");
        require(tokenA != address(0) && tokenB != address(0), "OC: ZERO_ADDRESS_PROVIDED");
        require(tokenA != tokenB, "OC: INCORRECT_PAIR_PROVIDED");
        _createOrder(tokenA, tokenB, amountA, amountB, _msgSender(), false);
    }

    function _getAmountSubFee(uint256 amount) private view returns(uint256 retAmount) {
        assembly { retAmount := div(mul(amount, sload(_fee.slot)), TEN_THOUSAND) }
    }
    
    function _getFee(uint256 amount) private view returns(uint256 retAmount) {
        uint256 amountSubFee = _getAmountSubFee(amount);
        assembly { retAmount := sub(amount, amountSubFee) }
    }

    function _generateOrderId(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        address user,
        bool isMarket
        ) private returns(uint256) {
        uint256 id = uint256(keccak256(abi.encodePacked(block.timestamp, user, _nonce)));
        _nonce++;
        _orders[id] = Order(id, amountA, amountB, amountA, 0, tokenA, tokenB, user, false);
        _orderIds.push(id);
        _userOrderIds[user].push(id);
        emit OrderCreated(id, amountA, amountB, tokenA, tokenB, user, isMarket);
        return id;
    }

    function _createOrder(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        address user,
        bool isMarket
        ) private {
        uint256 transferAmount = amountA * amountB / amountA;
        _generateOrderId(tokenA, tokenB, amountA, amountB, user, isMarket);
        TransferHelper.safeTransferFrom(tokenB, user, address(this), transferAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

