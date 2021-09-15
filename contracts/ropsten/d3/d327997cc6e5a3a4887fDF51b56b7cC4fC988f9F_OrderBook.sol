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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract OrderBook is Ownable {
    uint256[] public queue;
    uint256 public indexId;
    Response[] public lastOrder;
    address public tokenInQueue;
    
    struct Order {
        uint256 amount;
        uint256 remaningAmount;
        address customer;
        uint256 createdAt;
    }
    
    struct Response {
        uint256 amount;
        address customer;
    }
    
    mapping(address => uint256[]) userOrderId;
    mapping(uint256 => Order) userOrderBook;
    
    constructor(address _tokenInQueue) {
        require(_tokenInQueue == address(_tokenInQueue),"Invalid address");
        
        queue = [0];
        lastOrder.push(Response(0,0x0000000000000000000000000000000000000000));
        tokenInQueue = _tokenInQueue;
        indexId = 1;
    }

    function insert(uint256 _amount, uint256 _remaningAmount, address _customer) public onlyOwner() {
        queue.push();
        
        uint256 _index = queue.length-1;
        while(_index > 1) {
            queue[_index] = queue[_index-1];
            _index = _index-1;
        }
        
        userOrderBook[indexId] = Order(_amount,_remaningAmount,_customer,block.timestamp);
        userOrderId[_customer].push(indexId);
        queue[1] = indexId;
        
        indexId = indexId + 1;
    }
    
    function popOrder(uint256 _amount) public onlyOwner() returns (uint) {
        while (lastOrder.length > 1) {
            lastOrder.pop();
        }
        
        uint256 totalAmount = 0;
        uint256 tempRemaningAmount = 0;
        Order memory order;
        uint256 orderId;

        while(totalAmount < _amount && queue.length > 1) {
            orderId = queue[queue.length-1];
            queue.pop();
            
            order = userOrderBook[orderId];
            
            lastOrder.push(Response(order.remaningAmount, order.customer));
            totalAmount = totalAmount + order.remaningAmount;
            tempRemaningAmount = order.remaningAmount;
            
            order.remaningAmount = 0;
            userOrderBook[orderId] = order;
        }
        
        if (totalAmount > _amount) {
            totalAmount = totalAmount - tempRemaningAmount;
            lastOrder.pop();
            
            lastOrder.push(Response(_amount-totalAmount,order.customer));
            
            order.remaningAmount = tempRemaningAmount-(_amount-totalAmount);
            queue.push(orderId);
            userOrderBook[orderId] = order;
        }
        
        return lastOrder.length;
    }
    
    function canSwap() public view returns (bool) {
        if (queue.length > 1){ 
            return true;
        }
        return false;
    }
    
    function getOrderIdByUser(address _address) public view returns (uint256[] memory) {
        return userOrderId[_address];
    }

    function getOrderById(uint256 _id) public view returns (Order memory) {
        return userOrderBook[_id];
    }

    function getIndexId() public view returns (uint256) {
        return indexId;
    }
    
    function getLengthOrderBook() public view returns (uint256) {
        return queue.length-1;
    }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}