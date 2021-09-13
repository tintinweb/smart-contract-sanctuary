pragma solidity ^0.8.0;
import "./ChildContract.sol";

contract ParentContract {

  address owner;
  ChildContract public child;

  function Parent() public {
    owner = msg.sender;
  }

  function createChild() public {
    ChildContract child = new ChildContract();
  }
}

pragma solidity ^0.8.0;

contract ChildContract {
  address owner;

  function Child() public {
    owner = msg.sender;
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
  "libraries": {}
}