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

// File: contracts/interfaces/IFinance.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity 0.8.4;

interface IFinance {
    function newImmediatePayment(
        address _token,
        address _receiver,
        uint256 _amount,
        string memory _reference
    ) external;
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

// File: contracts/EVMScriptFactories/TopUpRewardPrograms.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity 0.8.4;






contract TopUpRewardPrograms is TrustedCaller, IEVMScriptFactory {
    constructor(
        address _trustedCaller,
        address _rewardProgramsRegistry,
        address _finance,
        address _rewardToken
    ) TrustedCaller(_trustedCaller) {
        finance = IFinance(_finance);
        rewardToken = _rewardToken;
        rewardProgramsRegistry = RewardProgramsRegistry(_rewardProgramsRegistry);
    }

    RewardProgramsRegistry public rewardProgramsRegistry;

    IFinance public finance;
    address public rewardToken;

    function createEVMScript(address _creator, bytes memory _evmScriptCallData)
        external
        view
        override
        onlyTrustedCaller(_creator)
        returns (bytes memory)
    {
        (address[] memory rewardPrograms, uint256[] memory amounts) =
            _decodeEVMScriptCallData(_evmScriptCallData);

        _validateMotionData(rewardPrograms, amounts);

        bytes[] memory evmScriptsCalldata = new bytes[](rewardPrograms.length);
        for (uint256 i = 0; i < rewardPrograms.length; ++i) {
            evmScriptsCalldata[i] = abi.encode(
                rewardToken,
                rewardPrograms[i],
                amounts[i],
                "Reward program top up"
            );
        }
        return
            EVMScriptCreator.createEVMScript(
                address(finance),
                finance.newImmediatePayment.selector,
                evmScriptsCalldata
            );
    }

    function _validateMotionData(address[] memory _rewardPrograms, uint256[] memory _amounts)
        private
        view
    {
        require(_rewardPrograms.length == _amounts.length, "LENGTH_MISMATCH");
        require(_rewardPrograms.length > 0, "EMPTY_DATA");
        for (uint256 i = 0; i < _rewardPrograms.length; ++i) {
            require(_amounts[i] > 0, "ZERO_AMOUNT");
            require(
                rewardProgramsRegistry.isRewardProgram(_rewardPrograms[i]),
                "REWARD_PROGRAM_NOT_ALLOWED"
            );
        }
    }

    function decodeEVMScriptCallData(bytes memory _evmScriptCallData)
        external
        pure
        returns (address[] memory rewardPrograms, uint256[] memory amounts)
    {
        return _decodeEVMScriptCallData(_evmScriptCallData);
    }

    function _decodeEVMScriptCallData(bytes memory _evmScriptCallData)
        internal
        pure
        returns (address[] memory rewardPrograms, uint256[] memory amounts)
    {
        return abi.decode(_evmScriptCallData, (address[], uint256[]));
    }
}