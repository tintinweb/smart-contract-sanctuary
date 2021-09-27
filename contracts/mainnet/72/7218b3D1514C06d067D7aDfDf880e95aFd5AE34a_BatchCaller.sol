pragma solidity  >=0.7.3;
contract BatchCaller {
    function batchMint(address payable [] memory proxies) public payable {
        for(uint i = 0; i < proxies.length; i++) {
            proxies[i].call("");
        }
    }   
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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