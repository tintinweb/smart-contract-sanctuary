pragma solidity 0.4.24;

import "./openzeppelin/Ownable.sol";

contract NodeRegistry is Ownable {

    address[] public nodes;

    function getNodesCount() public view returns(uint256) {
        return nodes.length;
    }

    function findNode(address node) public view returns(uint256) {
        for (uint256 i = 0; i < nodes.length; i++) {
            if (nodes[i] == node) return i;
        }
        return nodes.length;
    }

    function addNode(address node) public onlyOwner returns(uint256 nodesLen) {
        uint256 i = findNode(node);
        require(i == nodes.length, "The node already exists");
        return nodes.push(node);
    }

    function removeNode(address node) public onlyOwner {
        uint256 i = findNode(node);
        require(i != nodes.length, "No such a node");

        // Remove a node (the order of elements in nodes array will be changed)
        nodes[i] = nodes[nodes.length - 1];
        nodes.length--;
    }
}

pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner(), "Not owner");
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  // function renounceOwnership() public onlyOwner {
  //   emit OwnershipTransferred(_owner, address(0));
  //   _owner = address(0);
  // }

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
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "constantinople",
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}