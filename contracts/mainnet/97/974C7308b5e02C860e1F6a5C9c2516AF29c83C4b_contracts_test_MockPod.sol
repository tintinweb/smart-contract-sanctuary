pragma solidity ^0.6.12;

import "./ERC777Mintable.sol";
import "../external/PodInterface.sol";

contract MockPod is ERC777Mintable, PodInterface {
  uint256 public value;

  function setValue(uint256 _value) external {
    value = _value;
  }

  function tokenToCollateralValue(uint256) external override view returns (uint256) {
    return value;
  }

  function balanceOfUnderlying(address) external override view returns (uint256) {
    return 0;
  }
}
