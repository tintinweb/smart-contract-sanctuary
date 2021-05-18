// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "./interfaces/IPoolMulti.sol";
import "./interfaces/IPoolSingle.sol";

contract PoolsInitializer {
    IPoolMulti[] public poolsMulti;
    IPoolSingle[] public poolsSingle;

    constructor(address[] memory _poolsMulti, address[] memory _poolsSingle) {
        for (uint256 i = 0; i < _poolsMulti.length; i++) {
            poolsMulti.push(IPoolMulti(_poolsMulti[i]));
        }

        for (uint256 i = 0; i < _poolsSingle.length; i++) {
            poolsSingle.push(IPoolSingle(_poolsSingle[i]));
        }
    }

    function pullAll() public {
        for (uint256 i = 0; i < poolsMulti.length; i++) {
            poolsMulti[i].pullRewardFromSource_allTokens();
        }

        for (uint256 i = 0; i < poolsSingle.length; i++) {
            poolsSingle[i].pullRewardFromSource();
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

interface IPoolMulti {
    function pullRewardFromSource_allTokens() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

interface IPoolSingle {
    function pullRewardFromSource() external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 9999
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