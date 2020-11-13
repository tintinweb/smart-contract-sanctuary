pragma solidity >=0.6.0 <0.7.0;

import "@pooltogether/pooltogether-rng-contracts/contracts/RNGInterface.sol";

contract RNGServiceMock is RNGInterface {

  uint256 internal random;
  address internal feeToken;
  uint256 internal requestFee;

  function getLastRequestId() external override view returns (uint32 requestId) {
    return 1;
  }

  function setRequestFee(address _feeToken, uint256 _requestFee) external {
    feeToken = _feeToken;
    requestFee = _requestFee;
  }

  /// @return _feeToken
  /// @return _requestFee
  function getRequestFee() external override view returns (address _feeToken, uint256 _requestFee) {
    return (feeToken, requestFee);
  }

  function setRandomNumber(uint256 _random) external {
    random = _random;
  }

  function requestRandomNumber() external override returns (uint32, uint32) {
    return (1, 1);
  }

  function isRequestComplete(uint32) external override view returns (bool) {
    return true;
  }

  function randomNumber(uint32) external override returns (uint256) {
    return random;
  }
}