// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Platform {
    // Constants
    uint256 constant MAX_UINT256 = 2**256 - 1;

    // Configuration
    uint256 immutable LOCATION_MULTIPLIER;
    uint256 immutable DATA_PRECISION;

    // 6 decimal points precision
    struct Coordinates {
        int32 latitude;
        int32 longitude;
    }

    struct Node {
        address owner;
        address id;
        Coordinates coordinates;
    }

    // Temperature and humidity are precise to one decimal point
    struct DataPoint {
        address id;
        uint256 timestamp;
        int16 temperature; // From -3276.8°C to 3276.7°C
        uint16 humidity; // From 0 to 100%
    }

    event NewDevice(address owner, address id);
    event NewDataPoint(address id, DataPoint data);

    Node[] nodes;
    mapping(address => Node) nodeMap;
    mapping(address => DataPoint[]) dataPoints;

    constructor(uint256 locationMultiplier, uint256 dataPrecision) {
        LOCATION_MULTIPLIER = locationMultiplier;
        DATA_PRECISION = dataPrecision;
    }

    function register(address id, Coordinates memory coordinates) public {
        require(
            nodeMap[msg.sender].owner == address(0),
            "This node is already registered"
        );

        Node memory node =
            Node({owner: msg.sender, id: id, coordinates: coordinates});

        nodes.push(node);
        nodeMap[msg.sender] = node;

        emit NewDevice(msg.sender, id);
    }

    function publish(int16 temperature, uint16 humidity) public {
        require(
            nodeMap[msg.sender].owner != address(0),
            "This node is not registered"
        );

        DataPoint memory dataPoint =
            DataPoint({
                id: msg.sender,
                timestamp: block.timestamp,
                temperature: temperature,
                humidity: humidity
            });

        dataPoints[msg.sender].push(dataPoint);
        emit NewDataPoint(msg.sender, dataPoint);
    }

    function fetchData(
        address id,
        uint256 from,
        uint256 to,
        uint16 limit,
        uint256 start
    ) public view returns (DataPoint[] memory result, uint256 lastIndex) {
        result = new DataPoint[](limit);
        lastIndex = start;

        DataPoint[] memory points = dataPoints[id];
        uint16 j = 0;

        // This is extremely naïve and should be replaced with
        // something more efficient like binary search.
        for (; lastIndex < points.length && j < limit; lastIndex++) {
            DataPoint memory point = points[lastIndex];
            if (point.timestamp >= from && point.timestamp < to) {
                result[j++] = points[lastIndex];
            }
        }

        return (result, lastIndex);
    }

    // Call with "from" on upper left and "to" on bottom right
    function locateNodes(
        Coordinates memory from,
        Coordinates memory to,
        uint16 limit,
        uint256 start
    ) public view returns (Node[] memory result, uint256 lastIndex) {
        result = new Node[](limit);
        lastIndex = start;

        uint16 j = 0;

        // This is extremely naïve too, and should be
        // replaced with something more efficient.
        // H3?
        for (; lastIndex < nodes.length && j < limit; lastIndex++) {
            Node memory node = nodes[lastIndex];

            if (
                from.latitude <= node.coordinates.latitude &&
                from.longitude <= node.coordinates.longitude &&
                to.latitude >= node.coordinates.latitude &&
                to.longitude >= node.coordinates.longitude
            ) {
                result[j++] = node;
            }
        }

        return (result, lastIndex);
    }
}