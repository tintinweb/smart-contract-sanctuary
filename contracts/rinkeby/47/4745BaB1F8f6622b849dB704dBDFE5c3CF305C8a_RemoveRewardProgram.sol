/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

// SPDX-License-Identifier: GPL-3.0
// File: contracts/TrustedCaller.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity ^0.8.4;

/// @author psirex
/// @notice A helper contract contains logic to validate that only a trusted caller has access to certain methods.
/// @dev Trusted caller set once on deployment and can't be changed.
contract TrustedCaller {
    address public immutable trustedCaller;

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

pragma solidity ^0.8.4;


/// @author psirex
/// @title Registry of allowed reward programs
/// @notice Stores list of addresses with reward programs
contract RewardProgramsRegistry is TrustedCaller {
    // -------------
    // EVENTS
    // -------------
    event RewardProgramAdded(address indexed _rewardProgram);
    event RewardProgramRemoved(address indexed _rewardProgram);

    // -------------
    // ERRORS
    // -------------
    string private constant ERROR_REWARD_PROGRAM_ALREADY_ADDED = "REWARD_PROGRAM_ALREADY_ADDED";
    string private constant ERROR_REWARD_PROGRAM_NOT_FOUND = "REWARD_PROGRAM_NOT_FOUND";

    // -------------
    // VARIABLES
    // -------------

    /// @dev List of allowed reward program addresses
    address[] public rewardPrograms;

    // Position of the reward program in the `rewardPrograms` array,
    // plus 1 because index 0 means a value is not in the set.
    mapping(address => uint256) private rewardProgramIndices;

    // -------------
    // CONSTRUCTOR
    // -------------

    constructor(address _trustedCaller) TrustedCaller(_trustedCaller) {}

    // -------------
    // EXTERNAL METHODS
    // -------------

    /// @notice Adds address to list of allowed reward programs
    function addRewardProgram(address _rewardProgram) external onlyTrustedCaller(msg.sender) {
        require(rewardProgramIndices[_rewardProgram] == 0, ERROR_REWARD_PROGRAM_ALREADY_ADDED);

        rewardPrograms.push(_rewardProgram);
        rewardProgramIndices[_rewardProgram] = rewardPrograms.length;
        emit RewardProgramAdded(_rewardProgram);
    }

    /// @notice Removes address from list of allowed reward programs
    /// @dev To delete a reward program from the rewardPrograms array in O(1), we swap the element to delete with the last one in
    /// the array, and then remove the last element (sometimes called as 'swap and pop').
    function removeRewardProgram(address _rewardProgram) external onlyTrustedCaller(msg.sender) {
        uint256 index = _gerRewardProgramIndex(_rewardProgram);
        uint256 lastIndex = rewardPrograms.length - 1;

        if (index != lastIndex) {
            address lastRewardProgram = rewardPrograms[lastIndex];
            rewardPrograms[index] = lastRewardProgram;
            rewardProgramIndices[lastRewardProgram] = index + 1;
        }

        rewardPrograms.pop();
        delete rewardProgramIndices[_rewardProgram];
        emit RewardProgramRemoved(_rewardProgram);
    }

    /// @notice Returns if passed address are listed as reward program in the registry
    function isRewardProgram(address _maybeRewardProgram) external view returns (bool) {
        return rewardProgramIndices[_maybeRewardProgram] > 0;
    }

    /// @notice Returns current list of reward programs
    function getRewardPrograms() external view returns (address[] memory) {
        return rewardPrograms;
    }

    // ------------------
    // PRIVATE METHODS
    // ------------------

    function _gerRewardProgramIndex(address _evmScriptFactory)
        private
        view
        returns (uint256 _index)
    {
        _index = rewardProgramIndices[_evmScriptFactory];
        require(_index > 0, ERROR_REWARD_PROGRAM_NOT_FOUND);
        _index -= 1;
    }
}

// File: contracts/libraries/EVMScriptCreator.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity ^0.8.4;

/// @author psirex
/// @notice Contains methods for convenient creation
/// of EVMScripts in EVMScript factories contracts
library EVMScriptCreator {
    // Id of default CallsScript Aragon's executor.
    bytes4 private constant SPEC_ID = hex"00000001";

    /// @notice Encodes one method call as EVMScript
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

    /// @notice Encodes multiple calls of the same method on one contract as EVMScript
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

pragma solidity ^0.8.4;

interface IEVMScriptFactory {
    function createEVMScript(address _creator, bytes memory _evmScriptCallData)
        external
        returns (bytes memory);
}

// File: contracts/EVMScriptFactories/RemoveRewardProgram.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity ^0.8.4;





/// @author psirex
/// @notice Creates EVMScript to remove reward program from RewardProgramsRegistry
contract RemoveRewardProgram is TrustedCaller, IEVMScriptFactory {
    // -------------
    // ERRORS
    // -------------
    string private constant ERROR_REWARD_PROGRAM_NOT_FOUND = "REWARD_PROGRAM_NOT_FOUND";

    // -------------
    // VARIABLES
    // -------------

    /// @notice Address of RewardsProgramsRegistry
    RewardProgramsRegistry public immutable rewardProgramsRegistry;

    // -------------
    // CONSTRUCTOR
    // -------------

    constructor(address _trustedCaller, address _rewardProgramsRegistry)
        TrustedCaller(_trustedCaller)
    {
        rewardProgramsRegistry = RewardProgramsRegistry(_rewardProgramsRegistry);
    }

    // -------------
    // EXTERNAL METHODS
    // -------------

    /// @notice Creates EVMScript to remove reward program from RewardProgramsRegistry
    /// @param _creator Address who creates EVMScript
    /// @param _evmScriptCallData Encoded tuple: (address _rewardProgram)
    function createEVMScript(address _creator, bytes memory _evmScriptCallData)
        external
        view
        override
        onlyTrustedCaller(_creator)
        returns (bytes memory)
    {
        require(
            rewardProgramsRegistry.isRewardProgram(_decodeEVMScriptCallData(_evmScriptCallData)),
            ERROR_REWARD_PROGRAM_NOT_FOUND
        );
        return
            EVMScriptCreator.createEVMScript(
                address(rewardProgramsRegistry),
                rewardProgramsRegistry.removeRewardProgram.selector,
                _evmScriptCallData
            );
    }

    /// @notice Decodes call data used by createEVMScript method
    /// @param _evmScriptCallData Encoded tuple: (address _rewardProgram)
    /// @return _rewardProgram Address of new reward program
    function decodeEVMScriptCallData(bytes memory _evmScriptCallData)
        external
        pure
        returns (address _rewardProgram)
    {
        return _decodeEVMScriptCallData(_evmScriptCallData);
    }

    // ------------------
    // PRIVATE METHODS
    // ------------------

    function _decodeEVMScriptCallData(bytes memory _evmScriptCallData)
        private
        pure
        returns (address)
    {
        return abi.decode(_evmScriptCallData, (address));
    }
}