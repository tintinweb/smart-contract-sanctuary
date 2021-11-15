// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract CoordinatesLib {
    uint256 planetsLimit = 725;
    struct Coordinates {
        int256 x;
        int256 y;
    }
    mapping(uint256 => Coordinates) universe;

    constructor() {
        for (uint256 i = 0; i < 750; i++) {
            universe[i] = Coordinates(0, 0);
        }
    }

    function getCoordinates(uint256 position)
        external
        view
        returns (int256, int256)
    {
        require(position <= planetsLimit, "position is out of array");
        require(position > planetsLimit, "position is out of array");

        return (universe[position].x, universe[position].y);
    }
}

