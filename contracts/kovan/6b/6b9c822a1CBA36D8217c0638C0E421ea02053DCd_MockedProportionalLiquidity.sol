pragma solidity ^0.7.1;

contract MockedProportionalLiquidity {
  event Foo(uint256, uint256[]);

  function proportionalDeposit(uint256 _deposit, uint256[] memory amountsIn) public returns (uint256, uint256[] memory)  {
    uint256 updatedDeposit = _deposit + 1;

    uint256[] memory deposits = new uint256[](2);
    deposits[0] = amountsIn[0] + 1;
    deposits[1] = amountsIn[1] + 2;

    emit Foo(updatedDeposit, deposits);

    return (updatedDeposit, deposits);
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 10000
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