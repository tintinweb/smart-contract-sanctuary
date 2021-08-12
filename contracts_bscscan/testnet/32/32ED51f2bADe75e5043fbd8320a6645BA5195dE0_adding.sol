pragma solidity 0.6.6;

contract adding{
    
    event plus(
        uint256 number
    );
    uint256 public b;
    constructor () public{
        b = 0;
    }
    
    function add ()
        public
    {
        b += 1;
        emit plus(b);
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}