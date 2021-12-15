// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OpCommon.sol";

import {ConnectorCenterInterface} from "../connector/interface/IConnectorCenter.sol";

struct Spell {
    string name;
    bytes data;
}

contract OpCast is OpCommon {
    
    address public immutable connectorCenter;

    event SetConnectorCenter(address indexed connectorCenter);

    event LogCast(
        address indexed sender,
        uint256 value,
        string targetsName,
        address target,
        string eventName,
        bytes eventParam
    );

    constructor(address _connectorCenter) {
        connectorCenter = _connectorCenter;
    }


    function cast(Spell[] calldata spells) external payable {
        require(_auth[msg.sender], "CHFRY: Permission Denied");
        _cast(spells);
    }

    function _cast(Spell[] memory _spells) internal {
        uint256 _length = _spells.length;
        string memory eventName;
        bytes memory eventParam;
        for (uint256 i = 0; i < _length; i++) {
            (bool isOk, address _target) = ConnectorCenterInterface(
                connectorCenter
            ).getConnector(_spells[i].name);
            require(isOk, "CHFRY: Connector not fund");
            bytes memory response = spell(_target, _spells[i].data);
            (eventName, eventParam) = decodeEvent(response);
            emit LogCast(
                msg.sender,
                msg.value,
                _spells[i].name,
                _target,
                eventName,
                eventParam
            );
        }
    }

    function decodeEvent(bytes memory response)
        internal
        pure
        returns (string memory _eventCode, bytes memory _eventParams)
    {
        if (response.length > 0) {
            (_eventCode, _eventParams) = abi.decode(response, (string, bytes));
        }
    }

    function spell(address _target, bytes memory _data)
        internal
        returns (bytes memory response)
    {
        require(_target != address(0), "target-invalid");
        assembly {
            let succeeded := delegatecall(
                gas(),
                _target,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )

            let size := returndatasize()

            response := mload(0x40)
            mstore(
                0x40,
                add(response, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
                returndatacopy(0x00, 0x00, size)
                revert(0x00, size)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OpCommon {
    // auth is shared storage with AccountProxy and any OpCode.
    mapping(address => bool) internal _auth;
    address internal accountCenter;
    
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ConnectorCenterInterface {
    function setAccountIndex(address _accountIndex) external;
    function addConnectors(string[] calldata _connectorNames, address[] calldata _connectors) external;
    function updateConnectors(string[] calldata _connectorNames, address[] calldata _connectors) external;
    function removeConnectors(string[] calldata _connectorNames) external;
    function getConnectors(string[] calldata _connectorNames) external view returns (bool isOk, address[] memory _connectors);
    function getConnector(string memory _connectorName) external view returns (bool isOk, address _connectors);
}