pragma solidity 0.8.0;

import "./ownable.sol";

contract PerseusLink is Ownable {
    struct Link {
        uint32 block;
        uint256 hash;
    }

    uint32 currentId;
    mapping (uint32 => Link) internal idToLink;

    constructor(){
        currentId = 0;    
    }

    function link(uint32 _block, uint256 _hash) external onlyOwner {
        idToLink[currentId].block = _block;
        idToLink[currentId].hash = _hash;
        currentId = currentId + 1;
    }

    function getLinkBlock(uint32 _id) external view returns (uint32) {
        require(_id < currentId, "LINK_DO_NOT_EXISTS");
        return idToLink[_id].block;
    }

    function getLinkHash(uint32 _id) external view returns (uint256) {
        require(_id < currentId, "LINK_DO_NOT_EXISTS");
        return idToLink[_id].hash;
    }

    function getLinksNumber() external view returns (uint32) {
        return currentId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code at:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */
contract Ownable
{

  /**
   * @dev Error constants.
   */
  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  /**
   * @dev Current owner address.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    public
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}