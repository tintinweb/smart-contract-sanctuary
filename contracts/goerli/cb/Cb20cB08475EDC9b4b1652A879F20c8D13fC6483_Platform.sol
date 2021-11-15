// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

struct Coordinates {
    int32 latitude;
    int32 longitude;
}

struct Device {
    address owner;
    bytes id;
    Coordinates coordinates;
}

struct Point {
    int32 latitude;
    int32 longitude;
    Device device;
}

struct Rectangle {
    int32 latitude;
    int32 longitude;
    int32 width;
    int32 height;
}

struct QuadTree {
    Rectangle boundary;
    uint32 capacity;
    Point[] points;
    QuadTree[] children;
}

library RectangleLib {
    function intersects(Rectangle memory a, Rectangle memory b)
        internal
        pure
        returns (bool)
    {
        return
            !(a.latitude - a.width > b.latitude + b.width ||
                a.latitude + a.width < b.latitude - b.width ||
                a.longitude - a.height > b.longitude + b.height ||
                a.longitude + a.height < b.longitude - b.height);
    }

    function contains(Rectangle memory rectangle, Point memory point)
        internal
        pure
        returns (bool)
    {
        return
            point.latitude <= rectangle.latitude + rectangle.width &&
            point.latitude >= rectangle.latitude - rectangle.width &&
            point.longitude <= rectangle.longitude + rectangle.height &&
            point.longitude >= rectangle.longitude - rectangle.height;
    }
}

library QuadTreeLib {
    using RectangleLib for Rectangle;
    using QuadTreeLib for QuadTree;

    function insert(QuadTree storage self, Point memory point)
        internal
        returns (bool)
    {
        if (!self.boundary.contains(point)) {
            return false;
        }

        if (self.points.length < self.capacity) {
            self.points.push(point);
            return true;
        }

        if (self.children.length == 0) {
            self.divide();
        }

        // Try to insert in each child
        for (uint8 i = 0; i < self.children.length; i++) {
            if (self.children[i].insert(point)) {
                return true;
            }
        }

        // Should never happen
        return false;
    }

    function createChild(
        QuadTree storage self,
        int32 latitude,
        int32 longitude,
        int32 width,
        int32 height
    ) internal {
        QuadTree storage tree = self.children.push();

        // Initialize the boundary
        tree.boundary.latitude = latitude;
        tree.boundary.longitude = longitude;
        tree.boundary.width = width;
        tree.boundary.height = height;

        // Set the remaining properties
        tree.capacity = self.capacity;
    }

    function divide(QuadTree storage self) internal {
        int32 x = self.boundary.latitude;
        int32 y = self.boundary.longitude;
        int32 w = self.boundary.width;
        int32 h = self.boundary.height;

        self.createChild(x + w / 2, y - h / 2, w / 2, h / 2);
        self.createChild(x - w / 2, y - h / 2, w / 2, h / 2);
        self.createChild(x + w / 2, y + h / 2, w / 2, h / 2);
        self.createChild(x - w / 2, y + h / 2, w / 2, h / 2);
    }

    function query(
        QuadTree storage self,
        Rectangle memory range,
        uint256 limit
    ) internal view returns (Point[] memory points, uint256 count) {
        points = new Point[](limit);
        count = self.query(range, points, 0, limit);
        return (points, count);
    }

    function query(
        QuadTree storage self,
        Rectangle memory range,
        Point[] memory points,
        uint256 _index,
        uint256 limit
    ) internal view returns (uint256 index) {
        index = _index;

        if (!range.intersects(self.boundary)) {
            return index;
        }

        for (uint256 i = 0; i < self.points.length; i++) {
            if (index > limit) {
                return index;
            }

            if (range.contains(self.points[i])) {
                points[index++] = self.points[i];
            }
        }

        for (uint8 i = 0; i < self.children.length; i++) {
            index = self.children[i].query(range, points, index, limit);
        }

        return index;
    }
}

contract Platform {
    using QuadTreeLib for QuadTree;

    QuadTree tree;

    uint32 public immutable LOCATION_MULTIPLIER;

    constructor(uint32 locationMultiplier, uint32 capacity) {
        LOCATION_MULTIPLIER = locationMultiplier;

        // Setup tree
        tree.boundary = Rectangle(
            -90 * int32(locationMultiplier),
            -180 * int32(locationMultiplier),
            180 * int32(locationMultiplier),
            360 * int32(locationMultiplier)
        );
        tree.capacity = capacity;
    }

    event NewDevice(address owner, bytes id, Coordinates coordinates);
    mapping(bytes => Device) deviceMap;

    function register(bytes memory id, Coordinates memory coordinates) public {
        require(
            deviceMap[id].owner == address(0),
            "This device is already registered"
        );

        deviceMap[id] = Device({
            owner: msg.sender,
            id: id,
            coordinates: coordinates
        });

        bool success =
            tree.insert(
                Point(
                    coordinates.latitude,
                    coordinates.longitude,
                    deviceMap[id]
                )
            );
        require(success, "was not inserted in tree");

        // Emit the event
        emit NewDevice(msg.sender, id, coordinates);
    }

    function find(Rectangle memory range, uint256 limit)
        public
        view
        returns (Device[] memory devices, uint256 count)
    {
        devices = new Device[](limit);
        Point[] memory result;

        (result, count) = tree.query(range, limit);

        for (uint256 i = 0; i < count; i++) {
            devices[i] = result[i].device;
        }

        return (devices, count);
    }
}

