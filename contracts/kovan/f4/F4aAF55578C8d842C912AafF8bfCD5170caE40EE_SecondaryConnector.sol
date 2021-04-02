pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface PrimaryInterface {
    function transferToken(address dsa, address token, uint amt) external;
}

contract SecondaryConnector {
    address public immutable thisAddr;
    address public immutable target;

    constructor(address _target) {
        thisAddr = address(this);
        target = _target;
    }

    function getToken(address token, uint256 amt) external payable {
        PrimaryInterface(target).transferToken(address(this), token, amt);
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