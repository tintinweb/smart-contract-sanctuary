/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

// SPDX-License-Identifier: GPL-3.0
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

/// @author psirex
/// @notice Interface which every EVMScript factory used in EasyTrack contract has to implement
interface IEVMScriptFactory {
    function createEVMScript(address _creator, bytes memory _evmScriptCallData)
        external
        returns (bytes memory);
}

// File: contracts/EVMScriptFactories/IncreaseNodeOperatorStakingLimit.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity ^0.8.4;



interface INodeOperatorsRegistry {
    function getNodeOperator(uint256 _id, bool _fullInfo)
        external
        view
        returns (
            bool active,
            string memory name,
            address rewardAddress,
            uint64 stakingLimit,
            uint64 stoppedValidators,
            uint64 totalSigningKeys,
            uint64 usedSigningKeys
        );

    function setNodeOperatorStakingLimit(uint256 _id, uint64 _stakingLimit) external;
}

/// @author psirex
/// @notice Creates EVMScript to increase staking limit for node operator
contract IncreaseNodeOperatorStakingLimit is IEVMScriptFactory {
    struct NodeOperatorData {
        uint256 id;
        bool active;
        address rewardAddress;
        uint256 stakingLimit;
        uint256 totalSigningKeys;
    }

    // -------------
    // ERRORS
    // -------------

    string private constant ERROR_NODE_OPERATOR_DISABLED = "NODE_OPERATOR_DISABLED";
    string private constant ERROR_CALLER_IS_NOT_NODE_OPERATOR = "CALLER_IS_NOT_NODE_OPERATOR";
    string private constant ERROR_STAKING_LIMIT_TOO_LOW = "STAKING_LIMIT_TOO_LOW";
    string private constant ERROR_NOT_ENOUGH_SIGNING_KEYS = "NOT_ENOUGH_SIGNING_KEYS";

    // -------------
    // VARIABLES
    // -------------

    /// @notice Address of NodeOperatorsRegistry contract
    INodeOperatorsRegistry public immutable nodeOperatorsRegistry;

    // -------------
    // CONSTRUCTOR
    // -------------

    constructor(address _nodeOperatorsRegistry) {
        nodeOperatorsRegistry = INodeOperatorsRegistry(_nodeOperatorsRegistry);
    }

    // -------------
    // EXTERNAL METHODS
    // -------------

    /// @notice Creates EVMScript to increase staking limit for node operator
    /// @param _creator Address who creates EVMScript
    /// @param _evmScriptCallData Encoded tuple: (uint256 _nodeOperatorId, uint256 _stakingLimit) where
    /// _nodeOperatorId - id of node operator in NodeOperatorsRegistry
    /// _stakingLimit - new staking limit
    function createEVMScript(address _creator, bytes memory _evmScriptCallData)
        external
        view
        override
        returns (bytes memory)
    {
        _validateCreatorAndEVMScriptCallData(_creator, _evmScriptCallData);
        return
            EVMScriptCreator.createEVMScript(
                address(nodeOperatorsRegistry),
                nodeOperatorsRegistry.setNodeOperatorStakingLimit.selector,
                _evmScriptCallData
            );
    }

    /// @notice Decodes call data used by createEVMScript method
    /// @param _evmScriptCallData Encoded tuple: (uint256 _nodeOperatorId, uint256 _stakingLimit) where
    /// _nodeOperatorId - id of node operator in NodeOperatorsRegistry
    /// _stakingLimit - new staking limit
    /// @return _nodeOperatorId Id of node operator in NodeOperatorsRegistry
    /// @return _stakingLimit New staking limit
    function decodeEVMScriptCallData(bytes memory _evmScriptCallData)
        external
        pure
        returns (uint256 _nodeOperatorId, uint256 _stakingLimit)
    {
        return _decodeEVMScriptCallData(_evmScriptCallData);
    }

    // ------------------
    // PRIVATE METHODS
    // ------------------

    function _decodeEVMScriptCallData(bytes memory _evmScriptCallData)
        private
        pure
        returns (uint256 _nodeOperatorId, uint256 _stakingLimit)
    {
        (_nodeOperatorId, _stakingLimit) = abi.decode(_evmScriptCallData, (uint256, uint256));
    }

    function _validateCreatorAndEVMScriptCallData(address _creator, bytes memory _evmScriptCallData)
        private
        view
    {
        (uint256 _nodeOperatorId, uint256 _stakingLimit) =
            _decodeEVMScriptCallData(_evmScriptCallData);
        NodeOperatorData memory nodeOperatorData = _getNodeOperatorData(_nodeOperatorId);
        require(nodeOperatorData.rewardAddress == _creator, ERROR_CALLER_IS_NOT_NODE_OPERATOR);
        require(nodeOperatorData.active, ERROR_NODE_OPERATOR_DISABLED);
        require(nodeOperatorData.stakingLimit < _stakingLimit, ERROR_STAKING_LIMIT_TOO_LOW);
        require(nodeOperatorData.totalSigningKeys >= _stakingLimit, ERROR_NOT_ENOUGH_SIGNING_KEYS);
    }

    function _getNodeOperatorData(uint256 _nodeOperatorId)
        private
        view
        returns (NodeOperatorData memory _nodeOperatorData)
    {
        (bool active, , address rewardAddress, uint64 stakingLimit, , uint64 totalSigningKeys, ) =
            nodeOperatorsRegistry.getNodeOperator(_nodeOperatorId, false);

        _nodeOperatorData.id = _nodeOperatorId;
        _nodeOperatorData.active = active;
        _nodeOperatorData.rewardAddress = rewardAddress;
        _nodeOperatorData.stakingLimit = stakingLimit;
        _nodeOperatorData.totalSigningKeys = totalSigningKeys;
    }
}