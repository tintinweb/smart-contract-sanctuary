pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface AccountInterface {
    function cast(
        address[] calldata _targets,
        bytes[] calldata _datas
    ) external payable;
}

contract PrimaryConnector {
    event Info(address indexed msgSender, address indexed thisAddr);

    function sendInfo(address target) external payable {
        address[] memory tokens = new address[](2);
        tokens[0] = address(this);
        tokens[1] = msg.sender;

        address[] memory targets = new address[](1);
        targets[0] = target;

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("getInfo(address[])", tokens);

        AccountInterface(address(this)).cast(targets, calldatas);

        emit Info(msg.sender, address(this));
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