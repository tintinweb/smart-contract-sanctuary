pragma solidity ^0.5.16;

interface ICurvePool {
    function get_virtual_price() external view returns (uint256);
}

interface Feed {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (uint);
}

contract CurveFeed is Feed {

    ICurvePool public pool;
    uint8 public constant decimals = 18;

    constructor (ICurvePool _pool) public {
        pool = _pool;
    }

    function latestAnswer() public view returns (uint) {
        return pool.get_virtual_price();
    }
}

{
  "optimizer": {
    "enabled": true,
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