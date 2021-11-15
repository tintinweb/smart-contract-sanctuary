pragma solidity ^0.7.1;

library MockedProportionalLiquidity {
  function proportionalDeposit(uint256 _deposit, uint256[] memory amountsIn) external returns (uint256, uint256[] memory) {
    uint256 updatedDeposit = _deposit + 1;

    uint256[] memory deposits = new uint256[](2);
    deposits[0] = amountsIn[0] + 1;
    deposits[1] = amountsIn[1] + 2;

    return (updatedDeposit, deposits);
  }
}

