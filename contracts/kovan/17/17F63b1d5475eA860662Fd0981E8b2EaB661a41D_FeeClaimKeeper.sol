/*
    Copyright 2021 Index Cooperative

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;

import { IStreamingFeeSplitExtension } from "../interfaces/IStreamingFeeSplitExtension.sol";

contract FeeClaimKeeper {

    mapping(address => uint256) public lastUpkeeps;

    function checkUpkeep(bytes calldata _checkData) external view returns (bool upkeepNeeded, bytes memory performData) {

        (address streamingFeeExtension, uint256 delay) = abi.decode(_checkData, (address, uint256));

        upkeepNeeded = block.timestamp > lastUpkeeps[streamingFeeExtension] + delay;
        performData = abi.encode(streamingFeeExtension);
    }

    function performUpkeep(bytes calldata _performData) external {

        address streamingFeeExtension = abi.decode(_performData, (address));

        lastUpkeeps[streamingFeeExtension] = block.timestamp;
        IStreamingFeeSplitExtension(streamingFeeExtension).accrueFeesAndDistribute();
    }
}

/*
    Copyright 2021 IndexCooperative

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;

interface IStreamingFeeSplitExtension {
    function accrueFeesAndDistribute() external;
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}