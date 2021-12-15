// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AccountCenterInterface {
    function owner() external view returns (address);
}

interface ConnectorInterface {
    function name() external view returns (string memory);
}

contract ConnectorCenter {

    address public accountCenter;

    mapping(string => address) public connectors;


    event ConnectorAdded(
        bytes32 indexed connectorNameHash,
        string connectorName,
        address indexed connector
    );

    event ConnectorUpdated(
        bytes32 indexed connectorNameHash,
        string connectorName,
        address indexed oldConnector,
        address indexed newConnector
    );
    
    event ConnectorRemoved(
        bytes32 indexed connectorNameHash,
        string connectorName,
        address indexed connector
    );

    modifier onlyOwner {
        require(accountCenter != address(0),"CHFRY: accountCenter not setup");
        require(msg.sender == AccountCenterInterface(accountCenter).owner(), "CHFRY: only AccountCenter Owner");
        _;
    }

    function setAccountCenter(address _accountCenter) external {
        require(accountCenter == address(0),"CHFRY: accountCenter already set");
        accountCenter = _accountCenter;
    }


    function addConnector(string calldata _connectorNames, address _connectors) external onlyOwner {
            require(connectors[_connectorNames] == address(0), "CHFRY addConnectors: already added");
            require(_connectors != address(0), "CHFRY addConnectors: address not vaild");
            ConnectorInterface(_connectors).name();
            connectors[_connectorNames] = _connectors;
            emit ConnectorAdded(keccak256(abi.encodePacked(_connectorNames)), _connectorNames, _connectors);
    }

    function updateConnector(string calldata _connectorNames, address _connectors) external onlyOwner {
            require(connectors[_connectorNames] == address(0), "CHFRY updateConnector: _connectorName added already");
            require(_connectors != address(0), "CHFRY updateConnector: _connectors address not vaild");
            ConnectorInterface(_connectors).name();
            emit ConnectorUpdated(keccak256(abi.encodePacked(_connectorNames)), _connectorNames,connectors[_connectorNames], _connectors);
            connectors[_connectorNames] = _connectors;
    }

    function removeConnectors(string calldata _connectorNames) external onlyOwner {
            require(connectors[_connectorNames] != address(0), "CHFRY removeConnector: _connectorName not added to update");
            emit ConnectorRemoved(keccak256(abi.encodePacked(_connectorNames)),_connectorNames,connectors[_connectorNames]);
            delete connectors[_connectorNames];
    }

    function getConnector(string memory _connectorName) external view returns (bool isOk, address _connectors) {
        isOk = true;
        _connectors = connectors[_connectorName];
        if (_connectors == address(0)) {
            isOk = false;
        }
    }
}