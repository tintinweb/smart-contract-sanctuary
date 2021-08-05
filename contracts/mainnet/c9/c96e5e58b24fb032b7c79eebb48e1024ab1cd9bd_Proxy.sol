pragma solidity 0.7.0;
interface I {
    function transfer(address r, uint256 a) external;
}
contract Proxy {
    address payable private b;
    constructor() {
        b = msg.sender;
    }
    function w(address c, address  t, uint256 a) external {
        require(b == msg.sender);
        I e = I(c);
        e.transfer(t, a);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {
    "": {}
  },
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