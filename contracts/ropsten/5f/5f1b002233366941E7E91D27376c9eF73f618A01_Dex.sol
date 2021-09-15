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

import "./OrderBook.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Dex is Ownable {
    IERC20Metadata public token1;
    IERC20Metadata public token2;
    
    uint256 public priceOneToken1;
    uint256 public priceOneToken2;
    
    OrderBook public orderBookToken1;
    OrderBook public orderBookToken2;
    
    uint256 public createdAt;
    
    event Swapped(IERC20Metadata fromToken, IERC20Metadata toToken, uint256 amountOfTokenFrom, address user);

    constructor(IERC20Metadata _token1, uint256 _numToken1, IERC20Metadata _token2, uint256 _numToken2){
        require(_numToken1 > 0);
        require(_numToken2 > 0);
        
        token1 = _token1;
        token2 = _token2;
        
        priceOneToken1 = (_numToken2*10**token1.decimals())/_numToken1;
        priceOneToken2 = (_numToken1*10**token2.decimals())/_numToken2;
        
        createdAt = block.timestamp;
        
        orderBookToken1 = new OrderBook(address(token1));
        orderBookToken2 = new OrderBook(address(token2));
    }

    function swap1to2(uint256 numberOfTokens) public {
        uint256 amount = (numberOfTokens*priceOneToken2)/(10**token2.decimals());
        uint256 remaningAmount = amount;
        require(token1.allowance(msg.sender,address(this)) >= amount);
        
        bool canSwap = orderBookToken2.canSwap();
        uint256 numberOfTokenReceive = 0;
        
        if (canSwap) {
            uint256 len = orderBookToken2.popOrder(numberOfTokens);
            uint256 indexId = 1;
            uint256 volume;
            address customer;
                
            while (indexId < len) {
                (volume, customer) = orderBookToken2.lastOrder(indexId);
                uint256 valuePay = (volume*priceOneToken2)/(10**token2.decimals());
                token1.transferFrom(msg.sender, customer, valuePay);
                
                remaningAmount = remaningAmount - valuePay;
                numberOfTokenReceive = numberOfTokenReceive+volume;
                indexId = indexId+1;
            }
        }  
        if (remaningAmount > 0) {
            token1.transferFrom(msg.sender, address(this), remaningAmount);
            orderBookToken1.insert(amount,remaningAmount,msg.sender);
        }
        
        if (numberOfTokenReceive > 0){
            require(token2.transfer(msg.sender, numberOfTokenReceive));
        }
        
        emit Swapped(token1, token2, numberOfTokens, msg.sender);
    }
    
    function swap2to1(uint256 numberOfTokens) public {
        uint256 amount = (numberOfTokens*priceOneToken1)/(10**token1.decimals());
        uint256 remaningAmount = amount;
        require(token2.allowance(msg.sender,address(this)) >= amount);
        
        bool canSwap = orderBookToken1.canSwap();
        uint256 numberOfTokenReceive = 0;
        
        if (canSwap) {
            uint256 len = orderBookToken1.popOrder(numberOfTokens);
            uint256 indexId = 1;
            uint256 volume;
            address customer;
                
            while (indexId < len) {
                (volume, customer) = orderBookToken1.lastOrder(indexId);
                uint256 valuePay = (volume*priceOneToken1)/(10**token1.decimals());
                token2.transferFrom(msg.sender, customer, valuePay);
                
                remaningAmount = remaningAmount - valuePay;
                numberOfTokenReceive = numberOfTokenReceive+volume;
                indexId = indexId+1;
            }
        }  
        if (remaningAmount > 0) {
            token2.transferFrom(msg.sender, address(this), remaningAmount);
            orderBookToken2.insert(amount,remaningAmount,msg.sender);
        }
        if (numberOfTokenReceive > 0){
            require(token1.transfer(msg.sender, numberOfTokenReceive));
        }
        
        emit Swapped(token2, token1, numberOfTokens, msg.sender);
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