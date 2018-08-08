pragma solidity ^0.4.15;

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
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title Stoppable
 * @dev Base contract which allows children to implement a permanent stop mechanism.
 */
contract Stoppable is Ownable {
  event Stop();  

  bool public stopped = false;

  /**
   * @dev Modifier to make a function callable only when the contract is not stopped.
   */
  modifier whenNotStopped() {
    require(!stopped);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is stopped.
   */
  modifier whenStopped() {
    require(stopped);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function stop() onlyOwner whenNotStopped public {
    stopped = true;
    Stop();
  }
}

contract SpaceRegistry is Stoppable {
    
    event Add();
    mapping(uint => uint) spaces;

    function addSpace(uint spaceId, uint userHash, bytes orderData) 
        onlyOwner whenNotStopped {

        require(spaceId > 0);
        require(userHash > 0);
        require(orderData.length > 0);
        require(spaces[spaceId] == 0);
        spaces[spaceId] = userHash;
        Add();
    }

    function addSpaces(uint[] spaceIds, uint[] userHashes, bytes orderData)
        onlyOwner whenNotStopped {

        var count = spaceIds.length;
        require(count > 0);
        require(userHashes.length == count);
        require(orderData.length > 0);

        for (uint i = 0; i < count; i++) {
            var spaceId = spaceIds[i];
            var userHash = userHashes[i];
            require(spaceId > 0);
            require(userHash > 0);
            require(spaces[spaceId] == 0);
            spaces[spaceId] = userHash;
        }

        Add();
    }

    function getSpaceById(uint spaceId) 
        external constant returns (uint userHash) {

        require(spaceId > 0);
        return spaces[spaceId];
    }

    function isSpaceExist(uint spaceId) 
        external constant returns (bool) {
            
        require(spaceId > 0);
        return spaces[spaceId] > 0;
    }
}