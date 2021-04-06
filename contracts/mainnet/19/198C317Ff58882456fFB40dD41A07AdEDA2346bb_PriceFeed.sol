// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

import "./interfaces/IPriceFeed.sol";
import "./interfaces/IUpgradable.sol";
import "./library/Ownable.sol";

contract PriceFeed is Ownable, IPriceFeed {

  string public feedName;
  mapping(uint256 => requestAnswer) public answers;
  uint256 currentId;
  IUpgradable private upgradable;

  constructor (IUpgradable _upgradable, string memory _feedName) public {
    feedName = _feedName;
    upgradable = _upgradable;
  }

  function updateFeedName (string memory _feedName) public {
    feedName = _feedName;
  }
  
  function getLatestAnswer () public override(IPriceFeed) returns (int256)
  {
    require(currentId > 0, "Contract is empty.");
    return answers[currentId - 1].priceAnswer;
  }

  function getLatestTimestamp() public override(IPriceFeed) returns (uint256)
  {
    require(currentId > 0, "Contract is empty.");
    return answers[currentId - 1].timestamp;
  }

  function getTimestamp(uint256 _id) public override(IPriceFeed) returns (uint256)
  {
    require(currentId > _id, "Id is not exist.");
    return answers[_id].timestamp;
  }

  function getAnswer(uint256 _id) public override(IPriceFeed) returns (int256)
  {
    require(currentId > _id, "Id is not exist.");
    return answers[_id].priceAnswer;
  }

  function addRequestAnswer(int256 _priceAnswer) public override(IPriceFeed)
  {
    require(msg.sender == upgradable.getOracleAddress(), "Sender is not oracle.");
    answers[currentId] = requestAnswer(
      currentId, block.timestamp, _priceAnswer
    );
    currentId ++;
  }
}

// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

interface IPriceFeed {

  struct requestAnswer {
      uint256 id;
      uint256 timestamp;
      int256 priceAnswer;
  }

  function getLatestAnswer() external returns (int256);
  function getLatestTimestamp() external returns (uint256);
  function getTimestamp(uint256 _id) external returns (uint256);
  function getAnswer(uint256 _id) external returns (int256);
  function addRequestAnswer(int256 _priceAnswer) external;
}

// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

interface IUpgradable {
  function getOracleAddress() external returns (address);
}

pragma solidity >=0.6.6;

contract Ownable {
    address public owner;

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
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
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