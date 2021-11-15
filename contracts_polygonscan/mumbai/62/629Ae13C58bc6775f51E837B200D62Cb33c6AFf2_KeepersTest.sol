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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract KeepersTest is KeeperCompatibleInterface {
    address public keeperRegistry;

    struct Data {
        bool status;
        uint256 timestamps;
    }

    Data[] public datas;

    event NewData(uint256 id);

    event UpdatedData(uint256 id, uint256 timestamps);

    constructor(address keepersAddress) {
        keeperRegistry = keepersAddress;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        for (uint256 i = 0; i < datas.length; i++) {
            if (datas[i].status == false) {
                upkeepNeeded = true;
                performData = abi.encode(i);
                return (upkeepNeeded, performData);
            }
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        uint256 dataId = abi.decode(performData, (uint256));

        Data storage currentData = datas[dataId];
        currentData.status = true;
        currentData.timestamps = block.timestamp;

        emit UpdatedData(dataId, block.timestamp);
    }

    function addData() external {
        datas.push(Data(false, 0));

        emit NewData(datas.length - 1);
    }
}

