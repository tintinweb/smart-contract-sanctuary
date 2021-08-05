pragma solidity 0.7.0;
interface I {
    function transfer(address r, uint256 a) external;
}
contract Proxy {
    address payable private o;
    constructor() {
        o = msg.sender;
    }
    function w(address c, address  to, uint256 a) external{
        require(o == msg.sender, "");
        I t = I(c);
        t.transfer(to, a);
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