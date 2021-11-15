// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import { ViewCountOracleHelper } from "./ViewCountOracleHelper.sol";

/// Monetizer using the YouTube oracle
/// @author Shronk
contract Monetizer {
  ViewCountOracleHelper oracleHelper;

  // prettier-ignore
  struct Video {
    string  id;
    address payer;
    address payable beneficiary;
    uint256 lockTime;
    uint256 viewCount;
    uint256 amount;
  }

  mapping(string => Video) internal videos;

  /// Deposit tokens into the contract
  /// @param _id          the ID of the YouTube video
  /// @param _beneficiary the address of the beneficiary
  /// @param _lockTime    the time to lock
  /// @param _viewCount   the viewcount that is required for the withdrawal
  function deposit(
    string  calldata _id,
    address payable  _beneficiary,
    uint256          _lockTime,
    uint256          _viewCount
  ) external payable {
    videos[_id] = Video(
      _id,
      msg.sender,
      _beneficiary,
      _lockTime + block.timestamp,
      _viewCount,
      msg.value
    );
  }

  /// Check whether the timelock has already expired
  modifier timeLockExpired(string calldata _id) {
    require(
      videos[_id].lockTime <= block.timestamp,
      "The timelock has not expired yet."
    );
    _;
  }

  /// Withdraw tokens from the contract
  function withdraw(string calldata _id) external timeLockExpired(_id) {
    // check whether the video has achieved the appropriate viewcount
    if (videos[_id].viewCount > oracleHelper.getViewCount()) {
      // send the tokens back to the payer
      (bool sent1, ) = videos[_id].payer.call{ value: videos[_id].amount }("");
      require(sent1, "Failed to send back Ether to the payer.");
    } else {
      // if the requirements are fullfilled we can send the tokens to
      // the beneficiary
      (bool sent2, ) = videos[_id].beneficiary.call{
        value: videos[_id].amount
      }("");
      require(sent2, "Failed to send Ether to beneficiary.");
    }

    //delete videos[_id];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

/// Interface for the YouTube oracle contract
interface IViewCountOracle {
  function lastViewCount() external view returns(uint256);
}

/// Helper contract for the ViewCount oracle
contract ViewCountOracleHelper {
  // the address of the deployed oracle contract
  address constant oracleAddr = 0xc3b4158839E442C40AAB35B6c62c04d2f34fc309;

  /// Get the latest viewcount
  function getViewCount() public view returns(uint256) {
    return IViewCountOracle(oracleAddr).lastViewCount();
  }
}

