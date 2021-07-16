//SourceUnit: krios-messages.sol

pragma solidity 0.5.10;
pragma experimental ABIEncoderV2;


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
    require(msg.sender == owner);
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

contract KriosMessages is Ownable {
    using SafeMath for uint;
    
    mapping (string => uint) public id_to_index;
    mapping (uint => string) public index_to_id;
    mapping (uint => string) public index_to_message;
    
    uint public lastIndex = 1;
    
    function storeMessage(string memory id, string memory message) public onlyOwner returns (bool success) {
        if (id_to_index[id] > 0) return (true);
        
        id_to_index[id] = lastIndex;
        index_to_id[lastIndex] = id;
        index_to_message[lastIndex] = message;
        lastIndex = lastIndex.add(1);
        return true;
    }
    
    function storeMessages(string[] memory ids, string[] memory messages) public onlyOwner returns(bool success) {
        require(ids.length == messages.length, "Invalid input provided");
        for (uint i = 0; i < ids.length; i++) {
            require(storeMessage(ids[i], messages[i]), "Could not store message");
        }
        return true;
    }
    
    function getMessage(string memory id) public view returns (string memory message) {
        return index_to_message[id_to_index[id]];
    }
    
    function getMessages(uint startIndex, uint endIndex) public view returns (string[] memory messages) {
        require(endIndex > startIndex && startIndex >= 1, "Invalid indexes passed to function");
        uint length = endIndex.sub(startIndex);
        string[] memory _messages = new string[](length);
        for (uint i = 0; i < length; i++) {
            _messages[i] = index_to_message[startIndex.add(i)];
        }
        return (_messages);
    }
}