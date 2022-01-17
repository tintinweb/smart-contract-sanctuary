pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title InstaConnectorsV2
 * @dev Registry for Connectors.
 */

interface IndexInterface {
    function master() external view returns (address);
}

interface ConnectorInterface {
    function name() external view returns (string memory);
}

contract Controllers {

    event LogController(address indexed addr, bool indexed isChief);

    // InstaIndex Address.
    address public immutable instaIndex;

    constructor(address _instaIndex) {
        instaIndex = _instaIndex;
    }

    // Enabled Chief(Address of Chief => bool).
    mapping(address => bool) public chief;
    // Enabled Connectors(Connector name => address).
    mapping(string => address) public connectors;

    /**
    * @dev Throws if the sender not is Master Address from InstaIndex
    * or Enabled Chief.
    */
    modifier isChief {
        require(chief[msg.sender] || msg.sender == IndexInterface(instaIndex).master(), "not-an-chief");
        _;
    }

    /**
     * @dev Toggle a Chief. Enable if disable & vice versa
     * @param _chiefAddress Chief Address.
    */
    function toggleChief(address _chiefAddress) external {
        require(msg.sender == IndexInterface(instaIndex).master(), "toggleChief: not-master");
        chief[_chiefAddress] = !chief[_chiefAddress];
        emit LogController(_chiefAddress, chief[_chiefAddress]);
    }
}


contract InstaConnectorsV2 is Controllers {
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

    constructor(address _instaIndex) public Controllers(_instaIndex) {}

    /**
     * @dev Add Connectors
     * @param _connectorNames Array of Connector Names.
     * @param _connectors Array of Connector Address.
    */
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

    /**
     * @dev Update Connectors
     * @param _connectorNames Array of Connector Names.
     * @param _connectors Array of Connector Address.
    */
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

    /**
     * @dev Remove Connectors
     * @param _connectorNames Array of Connector Names.
    */
    function removeConnectors(string[] calldata _connectorNames) external isChief {
        for (uint i = 0; i < _connectorNames.length; i++) {
            require(connectors[_connectorNames[i]] != address(0), "removeConnectors: _connectorName not added to update");
            emit LogConnectorRemoved(keccak256(abi.encodePacked(_connectorNames[i])), _connectorNames[i], connectors[_connectorNames[i]]);
            delete connectors[_connectorNames[i]];
        }
    }

    /**
     * @dev Check if Connector addresses are enabled.
     * @param _connectors Array of Connector Names.
    */
    function isConnectors(string[] calldata _connectorNames) external view returns (bool isOk, address[] memory _connectors) {
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
}