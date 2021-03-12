// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Platform {
    uint256 constant LOCATION_MULTIPLIER = 10**6;
    uint256 constant DATA_PRECISION = 10;

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
    mapping(address => DataPoint[]) dataPoints;

    function register(address id, Coordinates memory coordinates) public {
        nodes.push(Node({owner: msg.sender, id: id, coordinates: coordinates}));
        emit NewDevice(msg.sender, id);
    }

    function publish(int16 temperature, uint16 humidity) public {
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
        uint16 limit
    ) public view returns (DataPoint[] memory) {
        DataPoint[] memory points = dataPoints[id];
        DataPoint[] memory result = new DataPoint[](limit);
        uint16 j = 0;

        // This is extremely naïve and should be replaced with
        // something more efficient like binary search.
        for (uint256 i = 0; i < points.length && j < limit; i++) {
            DataPoint memory point = points[i];
            if (point.timestamp >= from && point.timestamp < to) {
                result[j] = points[i];
                j++;
            }
        }

        return result;
    }

    // Call with "from" on upper left and "to" on bottom right
    function locateNodes(
        Coordinates memory from,
        Coordinates memory to,
        uint16 limit,
        uint256 start
    ) public view returns (Node[] memory, uint256) {
        Node[] memory result = new Node[](limit);
        uint16 j = 0;
        uint256 i = start;

        // This is extremely naïve too, and should be
        // replaced with something more efficient.
        // H3?
        for (; i < nodes.length && j < limit; i++) {
            Node memory node = nodes[i];

            if (
                from.latitude <= node.coordinates.latitude &&
                from.longitude <= node.coordinates.longitude &&
                to.latitude >= node.coordinates.latitude &&
                to.longitude >= node.coordinates.longitude
            ) {
                result[j] = nodes[i];
                j++;
            }
        }

        return (result, i);
    }
}