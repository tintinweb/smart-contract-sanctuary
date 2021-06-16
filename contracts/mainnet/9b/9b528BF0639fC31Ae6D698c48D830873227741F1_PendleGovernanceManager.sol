// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

contract PendleGovernanceManager {
    address public governance;
    address public pendingGovernance;

    event GovernanceClaimed(address newGovernance, address previousGovernance);

    event TransferGovernancePending(address pendingGovernance);

    constructor(address _governance) {
        require(_governance != address(0), "ZERO_ADDRESS");
        governance = _governance;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "ONLY_GOVERNANCE");
        _;
    }

    /**
     * @dev Allows the pendingGovernance address to finalize the change governance process.
     */
    function claimGovernance() external {
        require(pendingGovernance == msg.sender, "WRONG_GOVERNANCE");
        emit GovernanceClaimed(pendingGovernance, governance);
        governance = pendingGovernance;
        pendingGovernance = address(0);
    }

    /**
     * @dev Allows the current governance to set the pendingGovernance address.
     * @param _governance The address to transfer ownership to.
     */
    function transferGovernance(address _governance) external onlyGovernance {
        require(_governance != address(0), "ZERO_ADDRESS");
        pendingGovernance = _governance;

        emit TransferGovernancePending(pendingGovernance);
    }
}

{
  "optimizer": {
    "enabled": true,
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