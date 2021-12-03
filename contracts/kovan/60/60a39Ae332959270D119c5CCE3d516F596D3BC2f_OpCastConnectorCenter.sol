/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface AccountIndexInterface {
    function owner() external view returns (address);
}

interface ConnectorInterface {
    function name() external view returns (string memory);
}

contract OpCastConnectorCenter {

    address public immutable accountIndex;
    mapping(address => bool) public chief;
    mapping(string => address) public connectors;

    event LogController(address indexed addr, bool indexed isChief);

    event LogConnectorAdded(
        bytes32 indexed connectorNameHash,
        string connectorName,
        address indexed connector
    );
    event LogConnectorUpdated(
        bytes32 indexed connectorNameHash,
        string connectorName,
        address indexed oldConnector,
        address indexed newConnector
    );
    event LogConnectorRemoved(
        bytes32 indexed connectorNameHash,
        string connectorName,
        address indexed connector
    );

    modifier isChief {
        require(chief[msg.sender] || msg.sender == AccountIndexInterface(accountIndex).owner(), "not-an-chief");
        _;
    }

    constructor(address _accountIndex) {
        accountIndex = _accountIndex;
    }

    function toggleChief(address _chiefAddress) external {
        require(msg.sender == AccountIndexInterface(accountIndex).owner(), "toggleChief: not-owner");
        chief[_chiefAddress] = !chief[_chiefAddress];
        emit LogController(_chiefAddress, chief[_chiefAddress]);
    }

    function addConnectors(string[] calldata _connectorNames, address[] calldata _connectors) external isChief {
        require(_connectors.length == _connectors.length, "addConnectors: not same length");
        for (uint i = 0; i < _connectors.length; i++) {
            require(connectors[_connectorNames[i]] == address(0), "addConnectors: _connectorName added already");
            require(_connectors[i] != address(0), "addConnectors: _connectors address not vaild");
            ConnectorInterface(_connectors[i]).name(); // Checking if connector has function name()
            connectors[_connectorNames[i]] = _connectors[i];
            emit LogConnectorAdded(keccak256(abi.encodePacked(_connectorNames[i])), _connectorNames[i], _connectors[i]);
        }
    }

    function updateConnectors(string[] calldata _connectorNames, address[] calldata _connectors) external isChief {
        require(_connectorNames.length == _connectors.length, "updateConnectors: not same length");
        for (uint i = 0; i < _connectors.length; i++) {
            require(connectors[_connectorNames[i]] != address(0), "updateConnectors: _connectorName not added to update");
            require(_connectors[i] != address(0), "updateConnectors: _connector address is not vaild");
            ConnectorInterface(_connectors[i]).name(); // Checking if connector has function name()
            emit LogConnectorUpdated(keccak256(abi.encodePacked(_connectorNames[i])), _connectorNames[i], connectors[_connectorNames[i]], _connectors[i]);
            connectors[_connectorNames[i]] = _connectors[i];
        }
    }

    function removeConnectors(string[] calldata _connectorNames) external isChief {
        for (uint i = 0; i < _connectorNames.length; i++) {
            require(connectors[_connectorNames[i]] != address(0), "removeConnectors: _connectorName not added to update");
            emit LogConnectorRemoved(keccak256(abi.encodePacked(_connectorNames[i])), _connectorNames[i], connectors[_connectorNames[i]]);
            delete connectors[_connectorNames[i]];
        }
    }

    function getConnectors(string[] calldata _connectorNames) external view returns (bool isOk, address[] memory _connectors) {
        isOk = true;
        uint len = _connectorNames.length;
        _connectors = new address[](len);
        for (uint i = 0; i < _connectors.length; i++) {
            _connectors[i] = connectors[_connectorNames[i]];
            if (_connectors[i] == address(0)) {
                isOk = false;
                break;
            }
        }
    }

    function getConnector(string memory _connectorName) external view returns (bool isOk, address _connectors) {
        isOk = true;
        _connectors = connectors[_connectorName];
        if (_connectors == address(0)) {
            isOk = false;
        }
    }

    function test() external {

    }
}