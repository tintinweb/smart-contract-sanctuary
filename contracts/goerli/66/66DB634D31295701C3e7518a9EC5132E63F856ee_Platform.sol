// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Platform {
    // Configuration
    uint256 public immutable LOCATION_MULTIPLIER;
    uint256 public immutable DATA_PRECISION;

    // 6 decimal points precision
    struct Coordinates {
        int32 latitude;
        int32 longitude;
    }

    struct Device {
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
    event NewDataPoint(DataPoint data);

    Device[] devices;
    mapping(address => Device) deviceMap;
    mapping(address => DataPoint[]) dataPoints;

    constructor(uint256 locationMultiplier, uint256 dataPrecision) {
        LOCATION_MULTIPLIER = locationMultiplier;
        DATA_PRECISION = dataPrecision;
    }

    function register(address id, Coordinates memory coordinates) public {
        require(
            deviceMap[msg.sender].owner == address(0),
            "This device is already registered"
        );

        Device memory device =
            Device({owner: msg.sender, id: id, coordinates: coordinates});

        devices.push(device);
        deviceMap[id] = device;

        emit NewDevice(msg.sender, id);
    }

    function publish(int16 temperature, uint16 humidity) public {
        require(
            deviceMap[msg.sender].owner != address(0),
            "This device is not registered"
        );

        DataPoint memory dataPoint =
            DataPoint({
                id: msg.sender,
                timestamp: block.timestamp,
                temperature: temperature,
                humidity: humidity
            });

        dataPoints[msg.sender].push(dataPoint);
        emit NewDataPoint(dataPoint);
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
    function locateDevices(
        Coordinates memory from,
        Coordinates memory to,
        uint16 limit,
        uint256 start
    ) public view returns (Device[] memory result, uint256 lastIndex) {
        result = new Device[](limit);
        lastIndex = start;

        uint16 j = 0;

        // This is extremely naïve too, and should be
        // replaced with something more efficient.
        // H3?
        for (; lastIndex < devices.length && j < limit; lastIndex++) {
            Device memory device = devices[lastIndex];

            if (
                from.latitude <= device.coordinates.latitude &&
                from.longitude <= device.coordinates.longitude &&
                to.latitude >= device.coordinates.latitude &&
                to.longitude >= device.coordinates.longitude
            ) {
                result[j++] = device;
            }
        }

        return (result, lastIndex);
    }
}