pragma solidity 0.7.6;

import ".././IPOH.sol";

contract TestPOH is IPOH {

    mapping(address => bool) private isHumanRegistered;
    uint private deployment = block.timestamp;

    function setHuman(address _human, bool _isRegistered) external {
        isHumanRegistered[_human] = _isRegistered;
    }

    function isRegistered(address _human) external view override returns(bool) {
        return isHumanRegistered[_human] && block.timestamp >= deployment;
    }
}

pragma solidity 0.7.6;

interface IPOH {
    function isRegistered(address _submissionID) external view returns (bool);
}

{
  "optimizer": {
    "enabled": true,
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
  "libraries": {}
}