/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

// File: contracts/interface/PoolOwnersInterface.sol

pragma solidity ^0.4.23;

contract PoolOwnersInterface {

    bool public distributionActive;

    function sendOwnership(address _receiver, uint256 _amount) public;
    function sendOwnershipFrom(address _owner, address _receiver, uint256 _amount) public;
    function getOwnerTokens(address _owner) public view returns (uint);
    function getOwnerPercentage(address _owner) public view returns (uint);

}

// File: contracts/std/ERC20Basic.sol

pragma solidity ^0.4.2;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/std/ERC20.sol

pragma solidity ^0.4.2;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/std/SafeMath.sol

pragma solidity ^0.4.2;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/std/Ownable.sol

pragma solidity ^0.4.2;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Sender not authorised");
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/lib/ItMap.sol

pragma solidity ^0.4.3;

/**
    @title ItMap, a solidity iterable map
    @dev Credit to: https://gist.github.com/ethers/7e6d443818cbc9ad2c38efa7c0f363d1
 */
library itmap {
    struct entry {
        // Equal to the index of the key of this item in keys, plus 1.
        uint keyIndex;
        uint value;
    }

    struct itmap {
        mapping(uint => entry) data;
        uint[] keys;
    }

    function insert(itmap storage self, uint key, uint value) internal returns (bool replaced) {
        entry storage e = self.data[key];
        e.value = value;
        if (e.keyIndex > 0) {
            return true;
        } else {
            e.keyIndex = ++self.keys.length;
            self.keys[e.keyIndex - 1] = key;
            return false;
        }
    }

    function remove(itmap storage self, uint key) internal returns (bool success) {
        entry storage e = self.data[key];

        if (e.keyIndex == 0) {
            return false;
        }

        if (e.keyIndex < self.keys.length) {
            // Move an existing element into the vacated key slot.
            self.data[self.keys[self.keys.length - 1]].keyIndex = e.keyIndex;
            self.keys[e.keyIndex - 1] = self.keys[self.keys.length - 1];
        }

        self.keys.length -= 1;
        delete self.data[key];
        return true;
    }

    function contains(itmap storage self, uint key) internal view returns (bool exists) {
        return self.data[key].keyIndex > 0;
    }

    function size(itmap storage self) internal view returns (uint) {
        return self.keys.length;
    }

    function get(itmap storage self, uint key) internal view returns (uint) {
        return self.data[key].value;
    }

    function getKey(itmap storage self, uint idx) internal view returns (uint) {
        return self.keys[idx];
    }
}

// File: contracts/OwnersExchange.sol

pragma solidity ^0.4.23;






/**
    @title OwnersExchange
    @dev Allow for trustless exchange of LP owners tokens
 */
contract OwnersExchange is Ownable {

    using SafeMath for uint;
    using itmap for itmap.itmap;

    enum ORDER_TYPE {
        NULL, BUY, SELL
    }
    uint public orderCount;
    uint public fee;
    uint public lockedFees;
    uint public totalFees;
    mapping(uint => uint) public feeBalances;
    address[] public addressRegistry; 
    mapping(address => uint) public addressIndex;

    itmap.itmap orderBook;

    PoolOwnersInterface public poolOwners;
    ERC20 public feeToken;

    event NewOrder(ORDER_TYPE indexed orderType, address indexed sender, uint price, uint amount);
    event OrderRemoved(ORDER_TYPE indexed orderType, address indexed sender, uint price, uint amount);
    event OrderFilled(ORDER_TYPE indexed orderType, address indexed sender, address receiver, uint price, uint amount);

    /**
        @dev Initialise the contract
        @param _poolOwners Set the address of the PoolOwners contract used in this DEX
     */
    constructor(address _poolOwners, address _feeToken) public {
        require(_poolOwners != address(0), "_poolOwners needs to be set");
        poolOwners = PoolOwnersInterface(_poolOwners);
        feeToken = ERC20(_feeToken);
        addressRegistry.push(address(0));
        orderCount = 1;
    }

    /**
        @dev Register an address to a uint allowing packing in orders
        @param _address The address to register
     */
    function addressRegister(address _address) private returns (uint) {
        if (addressIndex[_address] != 0) {
            return addressIndex[_address];
        } else {
            require(addressRegistry.length < 1 << 32, "Registered addresses hit maximum");
            addressIndex[_address] = addressRegistry.length;
            addressRegistry.push(_address);
            return addressRegistry.length - 1;
        }
    }

    /**
        @dev ERC677 Reciever for fee token transfer (Always expected to be LINK)
        @param _sender The address of the sender of the token
        @param _value The amount of token received
        @param _data Extra data, not needed in this use-case
     */
    function onTokenTransfer(address _sender, uint256 _value, bytes _data) public {
        require(msg.sender == address(feeToken), "Sender needs to be the fee token");
        uint index = addressRegister(_sender);
        feeBalances[index] = feeBalances[index].add(_value);
        totalFees = totalFees.add(_value);
    }

    /**
        @dev Allow users to withdraw any tokens used for fees
        @param _value The amount wanting to be withdrawn
     */
    function withdrawFeeToken(uint256 _value) public {
        uint index = addressRegister(msg.sender);
        require(feeBalances[index] >= _value, "You're withdrawing more than your balance");
        feeBalances[index] = feeBalances[index].sub(_value);
        totalFees = totalFees.sub(_value);
        if (feeBalances[index] == 0) {
            delete feeBalances[index];
        }
        feeToken.transfer(msg.sender, _value);
    }

    /**
        @dev Set the fee percentage
        @param _fee The percentage of fees to be taken in LINK
     */
    function setFee(uint _fee) public onlyOwner {
        require(_fee <= 500 finney, "Fees can't be more than 50%");
        fee = _fee;
    }

    /**
        @dev Returns the fee cost based on a price & amount
        @param _price The price of the order
        @param _amount The amount requested
     */
    function feeForOrder(uint _price, uint _amount) public view returns (uint) {
        return _price
            .mul(_amount)
            .div(1 ether)
            .mul(fee)
            .div(1 ether);
    }

    /**
        @dev Returns the ETH cost of an order
        @param _price The price of the order
        @param _amount The amount requested
     */
    function costOfOrder(uint _price, uint _amount) public pure returns (uint) {
        return _price.mul(_amount).div(1 ether);
    }

    /**
        @dev Create a new sell order
        @param _price The price of the order per 1 ether of token
        @param _amount The amount of tokens being sent
     */
    function addSellOrder(uint _price, uint _amount) public {
        require(is111bit(_price) && is111bit(_amount), "Price or amount exceeds 111 bits");

        require(_price > 0, "Price needs to be greater than 0");
        require(_amount > 0, "Amount needs to be greater than 0");

        uint orderFee = feeForOrder(_price, _amount);
        uint index = addressRegister(msg.sender);
        if (orderFee > 0) {
            require(feeBalances[index] >= orderFee, "You do not have enough deposited for fees");
            feeBalances[index] = feeBalances[index].sub(orderFee);
        }
        poolOwners.sendOwnershipFrom(msg.sender, this, _amount);

        require(
            !orderBook.insert(orderCount, (((uint(ORDER_TYPE.SELL) << 32 | index) << 111 | _price) << 111) | _amount), 
            "Map replacement detected"
        );
        orderCount += 1;
    
        emit NewOrder(ORDER_TYPE.SELL, msg.sender, _price, _amount);
    }

    /**
        @dev Add a new buy order, ETH sent needs to equal: (price * amount) / 18
        @param _price The price of the buy order per 1 ether of LP token
        @param _amount The amount of tokens wanting to be purchased
     */
    function addBuyOrder(uint _price, uint _amount) public payable {
        require(is111bit(_price) && is111bit(_amount), "Price or amount exceeds 111 bits");

        require(_price > 0, "Price needs to be greater than 0");
        require(_amount > 0, "Amount needs to be greater than 0");

        uint orderFee = feeForOrder(_price, _amount);
        uint index = addressRegister(msg.sender);
        if (orderFee > 0) {
            require(feeBalances[index] >= orderFee, "You do not have enough deposited for fees");
            feeBalances[index] = feeBalances[index].sub(orderFee);
        }

        uint cost = _price.mul(_amount).div(1 ether);
        require(_price.mul(_amount) == cost.mul(1 ether), "The price and amount of this order is too small");
        require(msg.value == cost, "ETH sent needs to equal the cost");

        require(
            !orderBook.insert(orderCount, (((uint(ORDER_TYPE.BUY) << 32 | index) << 111 | _price) << 111) | _amount), 
            "Map replacement detected"
        );
        orderCount += 1;
    
        emit NewOrder(ORDER_TYPE.BUY, msg.sender, _price, _amount);
    }

    /**
        @dev Remove a buy order and refund ETH back to the sender
        @param _key The key of the order in the book
     */
    function removeBuyOrder(uint _key) public {
        uint order = orderBook.get(_key);
        ORDER_TYPE orderType = ORDER_TYPE(order >> 254);
        require(orderType == ORDER_TYPE.BUY, "This is not a buy order");
        uint index = addressIndex[msg.sender];
        require(index == (order << 2) >> 224, "You are not the sender of this order");

        uint price = (order << 34) >> 145;
        uint amount = (order << 145) >> 145;
        require(orderBook.remove(_key), "Map remove failed");

        uint orderFee = feeForOrder(price, amount);
        if (orderFee > 0) {
            feeBalances[index] = feeBalances[index].add(orderFee);
        }

        uint cost = price.mul(amount).div(1 ether);
        msg.sender.transfer(cost);

        emit OrderRemoved(orderType, msg.sender, price, amount);
    }

    /**
        @dev Remove a sell order and refund the LP tokens back to the sender
        @param _key The key of the order in the book
     */
    function removeSellOrder(uint _key) public {
        uint order = orderBook.get(_key);
        ORDER_TYPE orderType = ORDER_TYPE(order >> 254);
        require(orderType == ORDER_TYPE.SELL, "This is not a sell order");
        uint index = addressIndex[msg.sender];
        require(index == (order << 2) >> 224, "You are not the sender of this order");

        uint price = (order << 34) >> 145;
        uint amount = (order << 145) >> 145;
        require(orderBook.remove(_key), "Map remove failed");

        uint orderFee = feeForOrder(price, amount);
        if (orderFee > 0) {
            feeBalances[index] = feeBalances[index].add(orderFee);
        }

        poolOwners.sendOwnership(msg.sender, amount);

        emit OrderRemoved(orderType, msg.sender, price, amount);
    }

    /**
        @dev Fill a sell order in the order book
        @dev Orders have to be filled in whole amounts
        @param _key Key of the order as per orderbook
     */
    function fillSellOrder(uint _key) public payable {
        uint order = orderBook.get(_key);
        ORDER_TYPE orderType = ORDER_TYPE(order >> 254);
        require(orderType == ORDER_TYPE.SELL, "This is not a sell order");
        uint index = addressRegister(msg.sender);
        require(index != (order << 2) >> 224, "You cannot fill your own order");

        uint price = (order << 34) >> 145;
        uint amount = (order << 145) >> 145;

        uint orderFee = feeForOrder(price, amount);
        require(feeBalances[index] >= orderFee, "You do not have enough deposited fees to fill this order");

        uint cost = price.mul(amount).div(1 ether);
        require(msg.value == cost, "ETH sent needs to equal the cost");

        require(orderBook.remove(_key), "Map remove failed");

        addressRegistry[(order << 2) >> 224].transfer(msg.value);
        poolOwners.sendOwnership(msg.sender, amount);

        if (orderFee > 0) {
            feeBalances[index] = feeBalances[index].sub(orderFee);
            uint totalFee = orderFee.mul(2);
            totalFees = totalFees.sub(totalFee);
            feeToken.transfer(poolOwners, totalFee);
        }

        emit OrderFilled(orderType, addressRegistry[(order << 2) >> 224], msg.sender, price, amount);
    }

    /**
        @dev Fill a buy order in the order book
        @dev Orders have to be filled in whole amounts
        @param _key Key of the order, which is the buyers address
     */
    function fillBuyOrder(uint _key) public {
        uint order = orderBook.get(_key);
        ORDER_TYPE orderType = ORDER_TYPE(order >> 254);
        require(orderType == ORDER_TYPE.BUY, "This is not a buy order");
        uint index = addressRegister(msg.sender);
        require(index != (order << 2) >> 224, "You cannot fill your own order");

        uint price = (order << 34) >> 145;
        uint amount = (order << 145) >> 145;

        uint orderFee = feeForOrder(price, amount);
        require(feeBalances[index] >= orderFee, "You do not have enough deposited fees to fill this order");

        uint cost = price.mul(amount).div(1 ether);
        
        require(orderBook.remove(_key), "Map remove failed");

        msg.sender.transfer(cost);
        poolOwners.sendOwnershipFrom(msg.sender, addressRegistry[(order << 2) >> 224], amount);

        if (orderFee > 0) {
            feeBalances[index] = feeBalances[index].sub(orderFee);
            uint totalFee = orderFee.mul(2);
            totalFees = totalFees.sub(totalFee);
            feeToken.transfer(poolOwners, totalFee);
        }

        emit OrderFilled(orderType, addressRegistry[(order << 2) >> 224], msg.sender, price, amount);
    }

    /**
        @dev Send any fee token earned via PoolOwners distribution back to be re-distributed
     */
    function withdrawDistributedToPoolOwners() public {
        uint balance = feeToken.balanceOf(this).sub(totalFees);
        require(balance > 0, "There is no distributed fee token balance in the contract");
        feeToken.transfer(poolOwners, balance);
    }

    /**
        @dev Get a single order by its key
        @param _key The key of the order as per the book
     */
    function getOrder(uint _key) public view returns (ORDER_TYPE, address, uint, uint) {
        uint order = orderBook.get(_key);
        return (
            ORDER_TYPE(order >> 254), 
            addressRegistry[(order << 2) >> 224], 
            (order << 34) >> 145, 
            (order << 145) >> 145
        );
    }

    /**
        @dev Get a batch of 10 orders by a given array of keys
        @dev ID's has to be equal or less than 10 in length, or an empty response is given
        @param _start The starting index in the order book to return from
     */
    function getOrders(uint _start) public view returns (
        uint[10] keys,
        address[10] addresses, 
        ORDER_TYPE[10] orderTypes, 
        uint[10] prices, 
        uint[10] amounts
    ) {
        for (uint i = 0; i < 10; i++) {
            if (orderBook.size() == _start + i) {
                break;
            }
            uint key = orderBook.getKey(_start + i);
            keys[i] = key;
            uint order = orderBook.get(key);
            addresses[i] = addressRegistry[(order << 2) >> 224];
            orderTypes[i] = ORDER_TYPE(order >> 254);
            prices[i] = (order << 34) >> 145;
            amounts[i] = (order << 145) >> 145;
        }
        return (keys, addresses, orderTypes, prices, amounts);
    }

    /**
        @dev Get an orderbook key from the orderbook index
        @param _i The index to fetch the key for
     */
    function getOrderBookKey(uint _i) public view returns (uint key) {
        if (_i < orderBook.size()) {
            key = orderBook.getKey(_i);
        } else {
            key = 0;
        }
        return key;
    }

    /**
        @dev Get orderbook keys in batches of 10
        @param _start The start of the index for the batch
     */
    function getOrderBookKeys(uint _start) public view returns (uint[10] keys) {
        for (uint i = 0; i < 10; i++) {
            if (i + _start < orderBook.size()) {
                keys[i] = orderBook.getKey(_start + i);
            } else {
                keys[i] = 0;
            }
        }
        return keys;
    }

    /**
        @dev Get the orderbook size to allow for batch fetching of keys
     */
    function getOrderBookSize() public view returns (uint) {
        return orderBook.size();
    }

    /**
        @dev Verify that the number being passed fits into 111 bits for packing
        @param _val The value to check
     */
    function is111bit(uint _val) private pure returns (bool) {
        return (_val < 1 << 111);
    }

}