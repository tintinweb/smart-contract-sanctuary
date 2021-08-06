// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/// @title A survey contract
/// @author Dhruvin
/// @notice Initializes the survey
contract TrustedSurvey{

    /// @notice address of the survey owner
    address public owner;

    /// @notice contract address of the survey factory
    address public factory;

    /// @notice Logs when survey contract is created
    /// @param owner The address of the survey creator
    /// @param surveyReward Reward set for the survey participant
    event SurveyInitialized(address indexed owner, uint256 indexed surveyReward);

    /// @notice Creates the survey contract
    /// @dev The reward value should be greater than zero
    constructor(address _owner) payable {
        require(msg.value > 0, "Survey: amount greter than zero");
        factory = msg.sender;
        owner = _owner;
        emit SurveyInitialized(owner, msg.value);
    }
}

{
  "optimizer": {
    "enabled": false,
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
  "libraries": {}
}