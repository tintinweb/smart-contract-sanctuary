// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";

import "./RNGInterface.sol";

contract RNGBlockhash is RNGInterface, Ownable {
  using SafeMath for uint256;
  using SafeCast for uint256;

  /// @dev A counter for the number of requests made used for request ids
  uint32 internal requestCount;

  /// @dev A list of random numbers from past requests mapped by request id
  mapping(uint32 => uint256) internal randomNumbers;

  /// @dev A list of blocks to be locked at based on past requests mapped by request id
  mapping(uint32 => uint32) internal requestLockBlock;

  /// @notice Public constructor
  constructor() public { }

  /// @notice Gets the last request id used by the RNG service
  /// @return requestId The last request id used in the last request
  function getLastRequestId() external override view returns (uint32 requestId) {
    return requestCount;
  }

  /// @notice Gets the Fee for making a Request against an RNG service
  /// @return feeToken The address of the token that is used to pay fees
  /// @return requestFee The fee required to be paid to make a request
  function getRequestFee() external override view returns (address feeToken, uint256 requestFee) {
    return (address(0), 0);
  }

  /// @notice Sends a request for a random number to the 3rd-party service
  /// @dev Some services will complete the request immediately, others may have a time-delay
  /// @dev Some services require payment in the form of a token, such as $LINK for Chainlink VRF
  /// @return requestId The ID of the request used to get the results of the RNG service
  /// @return lockBlock The block number at which the RNG service will start generating time-delayed randomness.  The calling contract
  /// should "lock" all activity until the result is available via the `requestId`
  function requestRandomNumber() external virtual override returns (uint32 requestId, uint32 lockBlock) {
    requestId = _getNextRequestId();
    lockBlock = uint32(block.number);

    requestLockBlock[requestId] = lockBlock;

    emit RandomNumberRequested(requestId, msg.sender);
  }

  /// @notice Checks if the request for randomness from the 3rd-party service has completed
  /// @dev For time-delayed requests, this function is used to check/confirm completion
  /// @param requestId The ID of the request used to get the results of the RNG service
  /// @return isCompleted True if the request has completed and a random number is available, false otherwise
  function isRequestComplete(uint32 requestId) external virtual override view returns (bool isCompleted) {
    return _isRequestComplete(requestId);
  }

  /// @notice Gets the random number produced by the 3rd-party service
  /// @param requestId The ID of the request used to get the results of the RNG service
  /// @return randomNum The random number
  function randomNumber(uint32 requestId) external virtual override returns (uint256 randomNum) {
    require(_isRequestComplete(requestId), "RNGBlockhash/request-incomplete");

    if (randomNumbers[requestId] == 0) {
      _storeResult(requestId, _getSeed());
    }

    return randomNumbers[requestId];
  }

  /// @dev Checks if the request for randomness from the 3rd-party service has completed
  /// @param requestId The ID of the request used to get the results of the RNG service
  /// @return True if the request has completed and a random number is available, false otherwise
  function _isRequestComplete(uint32 requestId) internal view returns (bool) {
    return block.number > (requestLockBlock[requestId] + 1);
  }

  /// @dev Gets the next consecutive request ID to be used
  /// @return requestId The ID to be used for the next request
  function _getNextRequestId() internal returns (uint32 requestId) {
    requestCount = uint256(requestCount).add(1).toUint32();
    requestId = requestCount;
  }

  /// @dev Gets a seed for a random number from the latest available blockhash
  /// @return seed The seed to be used for generating a random number
  function _getSeed() internal virtual view returns (uint256 seed) {
    return uint256(blockhash(block.number - 1));
  }

  /// @dev Stores the latest random number by request ID and logs the event
  /// @param requestId The ID of the request to store the random number
  /// @param result The random number for the request ID
  function _storeResult(uint32 requestId, uint256 result) internal {
    // Store random value
    randomNumbers[requestId] = result;

    emit RandomNumberCompleted(requestId, result);
  }
}
