// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./chainlink/KeeperCompatible.sol";

contract Counter is KeeperCompatibleInterface, KeeperBase {
    /**
     * Public counter variable
     */
    uint256 public counter;

    /**
     * Use an interval in seconds and a timestamp to slow execution of Upkeep
     */
    uint256 public immutable interval;
    uint256 public lastTimeStamp;

    constructor(uint256 updateInterval) {
        interval = updateInterval;
        lastTimeStamp = block.timestamp;

        counter = 0;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        override
        cannotExecute
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        uint256 nonce = 100;
        performData = abi.encode(nonce);
    }

    function performUpkeep(bytes calldata performData) external override {
        lastTimeStamp = block.timestamp;
        uint256 nonce = abi.decode(performData, (uint256));
        counter = counter + nonce;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./KeeperBase.sol";
import "./KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract KeeperBase {
    error OnlySimulatedBackend();

    /**
     * @notice method that allows it to be simulated via eth_call by checking that
     * the sender is the zero address.
     */
    function preventExecution() internal view {
        if (tx.origin != address(0)) {
            revert OnlySimulatedBackend();
        }
    }

    /**
     * @notice modifier that allows it to be simulated via eth_call by checking
     * that the sender is the zero address.
     */
    modifier cannotExecute() {
        preventExecution();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface KeeperCompatibleInterface {
    /**
     * @notice method that is simulated by the keepers to see if any work actually
     * needs to be performed. This method does does not actually need to be
     * executable, and since it is only ever simulated it can consume lots of gas.
     * @dev To ensure that it is never called, you may want to add the
     * cannotExecute modifier from KeeperBase to your implementation of this
     * method.
     * @param checkData specified in the upkeep registration so it is always the
     * same for a registered upkeep. This can easilly be broken down into specific
     * arguments using `abi.decode`, so multiple upkeeps can be registered on the
     * same contract and easily differentiated by the contract.
     * @return upkeepNeeded boolean to indicate whether the keeper should call
     * performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with, if
     * upkeep is needed. If you would like to encode data to decode later, try
     * `abi.encode`.
     */
    function checkUpkeep(bytes calldata checkData)
        external
        returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice method that is actually executed by the keepers, via the registry.
     * The data returned by the checkUpkeep simulation will be passed into
     * this method to actually be executed.
     * @dev The input to this method should not be trusted, and the caller of the
     * method should not even be restricted to any single registry. Anyone should
     * be able call it, and the input should be validated, there is no guarantee
     * that the data passed in is the performData returned from checkUpkeep. This
     * could happen due to malicious keepers, racing keepers, or simply a state
     * change while the performUpkeep transaction is waiting for confirmation.
     * Always validate the data passed in.
     * @param performData is the data which was passed back from the checkData
     * simulation. If it is encoded, it can easily be decoded into other types by
     * calling `abi.decode`. This data should not be trusted, and should be
     * validated against the contract's current state.
     */
    function performUpkeep(bytes calldata performData) external;
}