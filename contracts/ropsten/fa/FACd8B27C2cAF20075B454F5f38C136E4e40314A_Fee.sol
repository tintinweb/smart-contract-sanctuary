// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Fee {
    
    function fee(uint256 amount) public pure returns (uint256 _fee){
        _fee = (20  * amount) / 100;
    }
    
    function feeComplex(uint256 rate, uint256 amount, uint256 pastDays) public pure returns(uint256 _fee) {
        uint256 value = (rate * amount) / (100 * 10 **18);
        _fee = value * pastDays;
    }
    
    function _porcentage(uint256 rate, uint256 amount) public pure returns(uint256 porcentage) {
        uint256 value = (rate * amount) / (100 * 10 **18);
        porcentage = value;
    }
    
    function compare(uint256 a, uint256 b) public pure returns(bool) {
        require(a <= b, "Se paso el interes" );
        return true;
        
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