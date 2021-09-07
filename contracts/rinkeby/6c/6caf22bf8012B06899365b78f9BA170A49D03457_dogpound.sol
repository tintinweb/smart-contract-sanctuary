pragma solidity ^0.6.6;



interface iFeed {
    function feed (uint256) external ;
}

contract dogpound{
    
    function feed(address _addy, uint256 _tokenId) external {
        iFeed(_addy).feed(_tokenId);
    
    
    }
    
    
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
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