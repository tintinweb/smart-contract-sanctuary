// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {IResolver} from "./interfaces/IResolver.sol";
import {IPokeMe} from "./interfaces/IPokeMe.sol";

interface IilkRegistry {
    function list() external view returns (bytes32[] memory);

    function count() external view returns (uint256);
}

interface IJug {
    struct Ilk {
        uint256 duty;
        uint256 rho;
    }

    function drip(bytes32 ilk) external returns (uint256 rate);

    function ilks(bytes32 ilk) external view returns (Ilk memory);
}

contract JugResolver is IResolver {
    IilkRegistry public immutable ilkRegistry;
    IJug public immutable jug;

    constructor(address _ilkRegistry, address _jug) {
        ilkRegistry = IilkRegistry(_ilkRegistry);
        jug = IJug(_jug);
    }

    function checker()
        external
        view
        override
        returns (bool canExec, bytes memory execPayload)
    {
        bytes32[] memory ilks = ilkRegistry.list();

        for (uint256 x; x < ilks.length; x++) {
            bytes32 ilk = ilks[x];

            uint256 rho = jug.ilks(ilk).rho;

            // solhint-disable not-rely-on-time
            if (block.timestamp >= rho + 1 hours) {
                execPayload = abi.encodeWithSelector(IJug.drip.selector, ilk);

                return (true, execPayload);
            }
        }
        return (false, bytes("Drip not required for ilks yet"));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IPokeMe {
    function createTask(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external returns (bytes32);

    function cancelTask(bytes32 _taskId) external;

    function getTaskId(
        address _taskCreator,
        address _execAddress,
        bytes4 _selector,
        bool _useTaskTreasuryFunds,
        address _feeToken,
        bytes32 _resolverHash
    ) external pure returns (bytes32);

    function getResolverHash(
        address _resolverAddress,
        bytes memory _resolverData
    ) external pure returns (bytes32);

    function createTaskNoPrepayment(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData,
        address _feeToken
    ) external returns (bytes32 task);

    function taskTreasury() external view returns (address);

    function gelato() external view returns (address payable);

    function getFeeDetails() external view returns (uint256, address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IResolver {
    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload);
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}