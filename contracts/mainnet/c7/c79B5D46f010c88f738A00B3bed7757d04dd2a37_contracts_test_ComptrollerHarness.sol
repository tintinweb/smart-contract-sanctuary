pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "../comptroller/Comptroller.sol";

/* solium-disable security/no-block-members */
contract ComptrollerHarness is Comptroller {

  uint256 internal time;

  function setCurrentTime(uint256 _time) external {
    time = _time;
  }

  function _currentTime() internal override view returns (uint256) {
    return time;
  }

}