// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface IHundoVIP {
    function isGoing() external view returns (bool);

    function isPublic() external view returns (bool);

    function START_BLOCK_TIMESTAMP() external view returns (uint256);

    function MAX_SUPPLY() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function updateIsGoing(bool) external;

    function updateIsPublic() external;
}

/// @custom:security-contact [email protected]
contract HundoVIPKeeper is KeeperCompatibleInterface {
    uint256 public lastTimestamp;
    IHundoVIP HUNDO_VIP;
    address public immutable KEEPERS_REGISTRY;

    constructor(address _hundoVIP, address _keepersRegistry) {
        lastTimestamp = block.timestamp;
        HUNDO_VIP = IHundoVIP(_hundoVIP);
        KEEPERS_REGISTRY = _keepersRegistry;
    }

    function checkIsGoing()
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (!HUNDO_VIP.isGoing()) {
            upkeepNeeded =
                block.timestamp >= HUNDO_VIP.START_BLOCK_TIMESTAMP() &&
                HUNDO_VIP.totalSupply() < HUNDO_VIP.MAX_SUPPLY();
            performData = abi.encodeWithSelector(
                HUNDO_VIP.updateIsGoing.selector,
                true
            );
        } else if (HUNDO_VIP.isGoing()) {
            upkeepNeeded = HUNDO_VIP.totalSupply() == HUNDO_VIP.MAX_SUPPLY();
            performData = abi.encodeWithSelector(
                HUNDO_VIP.updateIsGoing.selector,
                false
            );
        }
        return (upkeepNeeded, performData);
    }

    function checkIsPublic()
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded =
            block.timestamp >= HUNDO_VIP.START_BLOCK_TIMESTAMP() + 4 days &&
            !HUNDO_VIP.isPublic() &&
            HUNDO_VIP.isGoing();
        performData = abi.encodeWithSelector(
            HUNDO_VIP.updateIsPublic.selector,
            ""
        );
        return (upkeepNeeded, performData);
    }

    /* Chainlink Keepers */
    function checkUpkeep(
        bytes calldata checkData // defined when the Upkeep was registered
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (bool success, bytes memory returnedData) = address(this).staticcall(
            checkData
        );
        require(success);

        (upkeepNeeded, performData) = abi.decode(returnedData, (bool, bytes));
    }

    function performUpkeep(bytes calldata performData) external override {
        require(msg.sender == KEEPERS_REGISTRY, "Only Keeper");
        lastTimestamp = block.timestamp;
        (bool success, ) = address(HUNDO_VIP).call(performData);
        require(success);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}