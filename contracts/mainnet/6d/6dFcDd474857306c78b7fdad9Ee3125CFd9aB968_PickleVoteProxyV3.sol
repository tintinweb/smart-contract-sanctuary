pragma solidity ^0.6.7;

interface Dill {
  function totalSupply() external view returns(uint256);
  function balanceOf(address) external view returns(uint256);
}

contract PickleVoteProxyV3 {
  // DILL contract
  Dill public constant dill = Dill(
    0xbBCf169eE191A1Ba7371F30A1C344bFC498b29Cf
  );

  function decimals() external pure returns (uint8) {
    return uint8(18);
  }

  function name() external pure returns (string memory) {
    return "PICKLEs In The Citadel V3";
  }

  function symbol() external pure returns (string memory) {
    return "PICKLE C";
  }

  function totalSupply() external view returns (uint256) {
    return dill.totalSupply();
  }

  function balanceOf(address _voter) external view returns (uint256) {
    return dill.balanceOf(_voter);
  }

  constructor() public {}
}

