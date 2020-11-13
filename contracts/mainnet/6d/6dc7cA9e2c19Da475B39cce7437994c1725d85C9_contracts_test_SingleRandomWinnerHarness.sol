pragma solidity >=0.6.0 <0.7.0;

import "../prize-strategy/single-random-winner/SingleRandomWinner.sol";

/* solium-disable security/no-block-members */
contract SingleRandomWinnerHarness is SingleRandomWinner {

  uint256 internal time;
  function setCurrentTime(uint256 _time) external {
    time = _time;
  }

  function _currentTime() internal override view returns (uint256) {
    return time;
  }

  function setRngRequest(uint32 requestId, uint32 lockBlock) external {
    rngRequest.id = requestId;
    rngRequest.lockBlock = lockBlock;
  }

}