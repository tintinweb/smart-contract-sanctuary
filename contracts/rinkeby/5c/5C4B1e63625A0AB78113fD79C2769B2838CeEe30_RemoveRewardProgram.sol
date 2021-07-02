/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// SPDX-License-Identifier: GPL-3.0
// File: contracts/TrustedCaller.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity 0.8.4;

contract TrustedCaller {
    address public trustedCaller;

    constructor(address _trustedCaller) {
        trustedCaller = _trustedCaller;
    }

    modifier onlyTrustedCaller(address _caller) {
        require(_caller == trustedCaller, "CALLER_IS_FORBIDDEN");
        _;
    }
}

// File: contracts/RewardProgramsRegistry.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>


pragma solidity 0.8.4;

contract RewardProgramsRegistry {
    address[] public rewardPrograms;
    mapping(address => uint256) private rewardProgramIndices;

    address public evmScriptExecutor;

    constructor(address _evmScriptExecutor) {
        evmScriptExecutor = _evmScriptExecutor;
    }

    function addRewardProgram(address _rewardProgram) external {
        require(msg.sender == evmScriptExecutor, "FORBIDDEN");
        require(rewardProgramIndices[_rewardProgram] == 0, "REWARD_PROGRAM_ALREADY_ADDED");

        rewardPrograms.push(_rewardProgram);
        rewardProgramIndices[_rewardProgram] = rewardPrograms.length;
    }

    function removeRewardProgram(address _rewardProgram) external {
        require(msg.sender == evmScriptExecutor, "FORBIDDEN");
        require(rewardProgramIndices[_rewardProgram] > 0, "REWARD_PROGRAM_NOT_FOUND");

        uint256 index = rewardProgramIndices[_rewardProgram] - 1;
        uint256 lastIndex = rewardPrograms.length - 1;

        if (index != lastIndex) {
            address lastRewardProgram = rewardPrograms[lastIndex];
            rewardPrograms[index] = lastRewardProgram;
            rewardProgramIndices[lastRewardProgram] = index + 1;
        }

        rewardPrograms.pop();
        delete rewardProgramIndices[_rewardProgram];
    }

    function isRewardProgram(address _maybeRewardProgram) external view returns (bool) {
        return rewardProgramIndices[_maybeRewardProgram] > 0;
    }

    function getRewardPrograms() external view returns (address[] memory) {
        return rewardPrograms;
    }
}

// File: contracts/libraries/EVMScriptCreator.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity 0.8.4;

library EVMScriptCreator {
    bytes4 private constant SPEC_ID = hex"00000001";

    function createEVMScript(
        address _to,
        bytes4 _methodId,
        bytes memory _evmScriptCallData
    ) internal pure returns (bytes memory _commands) {
        return
            abi.encodePacked(
                SPEC_ID,
                _to,
                uint32(_evmScriptCallData.length) + 4,
                _methodId,
                _evmScriptCallData
            );
    }

    function createEVMScript(
        address _to,
        bytes4 _methodId,
        bytes[] memory _evmScriptCallData
    ) internal pure returns (bytes memory _evmScript) {
        for (uint256 i = 0; i < _evmScriptCallData.length; ++i) {
            _evmScript = bytes.concat(
                _evmScript,
                abi.encodePacked(
                    _to,
                    uint32(_evmScriptCallData[i].length) + 4,
                    _methodId,
                    _evmScriptCallData[i]
                )
            );
        }
        _evmScript = bytes.concat(SPEC_ID, _evmScript);
    }
}

// File: contracts/interfaces/IEVMScriptFactory.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity 0.8.4;

interface IEVMScriptFactory {
    function createEVMScript(address _creator, bytes memory _evmScriptCallData)
        external
        returns (bytes memory);
}

// File: contracts/EVMScriptFactories/RemoveRewardProgram.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity 0.8.4;





contract RemoveRewardProgram is TrustedCaller, IEVMScriptFactory {
    RewardProgramsRegistry public rewardProgramsRegistry;

    constructor(address _trustedCaller, address _rewardProgramsRegistry)
        TrustedCaller(_trustedCaller)
    {
        rewardProgramsRegistry = RewardProgramsRegistry(_rewardProgramsRegistry);
    }

    function createEVMScript(address _creator, bytes memory _evmScriptCallData)
        external
        view
        override
        onlyTrustedCaller(_creator)
        returns (bytes memory)
    {
        require(
            rewardProgramsRegistry.isRewardProgram(_decodeEVMScriptCallData(_evmScriptCallData)),
            "REWARD_PROGRAM_NOT_FOUND"
        );
        return
            EVMScriptCreator.createEVMScript(
                address(rewardProgramsRegistry),
                rewardProgramsRegistry.removeRewardProgram.selector,
                _evmScriptCallData
            );
    }

    function decodeEVMScriptCallData(bytes memory _evmScriptCallData)
        external
        pure
        returns (address)
    {
        return _decodeEVMScriptCallData(_evmScriptCallData);
    }

    function _decodeEVMScriptCallData(bytes memory _evmScriptCallData)
        internal
        pure
        returns (address)
    {
        return abi.decode(_evmScriptCallData, (address));
    }
}