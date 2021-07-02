/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// SPDX-License-Identifier: GPL-3.0
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

// File: contracts/EVMScriptFactories/IncreaseNodeOperatorStakingLimit.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity 0.8.4;



interface NodeOperatorsRegistry {
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

contract IncreaseNodeOperatorStakingLimit is IEVMScriptFactory {
    struct NodeOperatorData {
        uint256 id;
        bool active;
        address rewardAddress;
        uint256 stakingLimit;
        uint256 totalSigningKeys;
    }

    string private constant ERROR_NODE_OPERATOR_DISABLED = "NODE_OPERATOR_DISABLED";
    string private constant ERROR_CALLER_IS_NOT_NODE_OPERATOR = "CALLER_IS_NOT_NODE_OPERATOR";
    string private constant ERROR_STAKING_LIMIT_TOO_LOW = "STAKING_LIMIT_TOO_LOW";
    string private constant ERROR_NOT_ENOUGH_SIGNING_KEYS = "NOT_ENOUGH_SIGNING_KEYS";

    NodeOperatorsRegistry public nodeOperatorsRegistry;

    constructor(address _nodeOperatorsRegistry) {
        nodeOperatorsRegistry = NodeOperatorsRegistry(_nodeOperatorsRegistry);
    }

    function createEVMScript(address _creator, bytes memory _motionData)
        external
        view
        override
        returns (bytes memory)
    {
        _validateMotionData(_creator, _motionData);
        return
            EVMScriptCreator.createEVMScript(
                address(nodeOperatorsRegistry),
                nodeOperatorsRegistry.setNodeOperatorStakingLimit.selector,
                _motionData
            );
    }

    function _validateMotionData(address _creator, bytes memory _motionData) private view {
        (uint256 _nodeOperatorId, uint256 _stakingLimit) = _decodeMotionData(_motionData);
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

    function _decodeMotionData(bytes memory _motionData)
        public
        pure
        returns (uint256 _nodeOperatorId, uint256 _stakingLimit)
    {
        (_nodeOperatorId, _stakingLimit) = abi.decode(_motionData, (uint256, uint256));
    }
}