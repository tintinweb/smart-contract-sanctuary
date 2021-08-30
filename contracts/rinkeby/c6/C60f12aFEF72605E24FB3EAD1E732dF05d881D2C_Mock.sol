pragma solidity =0.8.6;

contract Mock { 
    
    function addUnitList() external view returns(uint256[] memory) {
        uint256[] memory list = new uint256[](10000);
        for (uint256 i = 0; i < 10000; i++) {
            list[i] = i;
        }
        return list;
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
  }
}