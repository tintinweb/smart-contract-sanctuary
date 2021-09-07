pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title PriorityQueue
 * @dev A priority queue implementation.
 */
contract PriorityQueue is Ownable {
    using SafeMath for uint256;

    uint256[] heapList;
    uint256 public currentSize;

    constructor() public {
        heapList = [0];
    }

    /**
  * @dev Inserts an element into the priority queue.
  * @param _priority Priority to insert.
  * @param _value Some additional value.
  */
    function insert(uint256 _priority, uint256 _value) public onlyOwner {
        uint256 element = (_priority << 128) | _value;
        heapList.push(element);
        currentSize = currentSize.add(1);
        _percUp(currentSize);
    }

    /**
  * @dev Returns the top element of the heap.
  * @return The smallest element in the priority queue.
  */
    function getMin() public view returns (uint256, uint256) {
        return _splitElement(heapList[1]);
    }

    /**
  * @dev Deletes the top element of the heap and shifts everything up.
  * @return The smallest element in the priorty queue.
  */
    function delMin() public onlyOwner returns (uint256, uint256) {
        uint256 retVal = heapList[1];
        heapList[1] = heapList[currentSize];
        delete heapList[currentSize];
        currentSize = currentSize.sub(1);
        _percDown(1);
        heapList.length = heapList.length.sub(1);
        return _splitElement(retVal);
    }

    /**
  * @dev Determines the minimum child of a given node in the tree.
  * @param _index Index of the node in the tree.
  * @return The smallest child node.
  */
    function _minChild(uint256 _index) private view returns (uint256) {
        if (_index.mul(2).add(1) > currentSize) {
            return _index.mul(2);
        } else {
            if (heapList[_index.mul(2)] < heapList[_index.mul(2).add(1)]) {
                return _index.mul(2);
            } else {
                return _index.mul(2).add(1);
            }
        }
    }

    /**
   * @dev Bubbles the element at some index up.
   */
    function _percUp(uint256 _index) private {
        uint256 index = _index;
        uint256 j = index;
        uint256 newVal = heapList[index];

        while (newVal < heapList[index.div(2)]) {
            heapList[index] = heapList[index.div(2)];
            index = index.div(2);
        }

        if (index != j) {
            heapList[index] = newVal;
        }
    }

    /**
   * @dev Bubbles the element at some index down.
   */
    function _percDown(uint256 _index) private {
        uint256 index = _index;
        uint256 j = index;
        uint256 newVal = heapList[index];
        uint256 mc = _minChild(index);
        while (mc <= currentSize && newVal > heapList[mc]) {
            heapList[index] = heapList[mc];
            index = mc;
            mc = _minChild(index);
        }

        if (index != j) {
            heapList[index] = newVal;
        }
    }

    /**
   * @dev Split an element into its priority and value.
   * @param _element Element to decode.
   * @return A tuple containing the priority and value.
   */
    function _splitElement(uint256 _element)
        private
        pure
        returns (uint256, uint256)
    {
        uint256 priority = _element >> 128;
        uint256 value = uint256(uint128(_element));
        return (priority, value);
    }
}

pragma solidity ^0.5.2;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

pragma solidity ^0.5.2;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
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