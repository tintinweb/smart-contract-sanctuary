pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface AccountInterface {
    function cast(
        address[] calldata _targets,
        bytes[] calldata _datas
    ) external payable;
}

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

contract PrimaryConnector {
    address public immutable thisAddr;
    address public immutable target;

    constructor(address _target) {
        thisAddr = address(this);
        target = _target;
    }

    function transferToken(address dsa, address token, uint amt) external payable {
        TokenInterface(token).transfer(dsa, amt);
        // address[] memory targets = new address[](1);
        // targets[0] = target;

        // bytes[] memory calldatas = new bytes[](1);
        // calldatas[0] = abi.encodeWithSignature("getInfo(address[])", tokens);

        // AccountInterface(address(this)).cast(targets, calldatas);
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