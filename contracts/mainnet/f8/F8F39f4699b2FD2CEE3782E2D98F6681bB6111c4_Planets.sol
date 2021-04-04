// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;


contract Planets {

  /**
   * @dev Returns the orbital elements for the specified planet
   * @param _planet Id of the planet
   */
  function getElements(uint _planet) public pure returns (uint16[6] memory elements) {
    require(_planet >= 1 && _planet <= 5);

    if (_planet == 1) {
      elements = [ 258, 178, 639, 27693, 4955, 9342 ];
    } else if (_planet == 2) {
      elements = [ 781, 29, 182, 31965, 7588, 24762 ];
    } else if (_planet == 3) {
      elements = [ 3912, 13, 28, 33765, 6312, 26301 ];
    } else if (_planet == 4) {
      elements = [ 7249, 42, 48, 35649, 32961, 17878 ];
    } else if (_planet == 5) {
      elements = [ 9206, 37, 71, 9248, 25823, 22124 ];
    }

    return elements;
  }

  /**
   * @dev Returns whether the planet is rocky or a gas giant
   * @param _planet The Id of the planet
   */
  function getType(uint _planet) public pure returns (uint8) {
    require(_planet >= 1 && _planet <= 5);
    uint8[5] memory planetTypes = [ 1, 1, 2, 2, 2 ];
    return planetTypes[_planet - 1];
  }

  /**
   * @dev Gets the radius of the planet
   * @param _planet The Id of the planet
   */
  function getRadius(uint _planet) public pure returns (uint32) {
    require(_planet >= 1 && _planet <= 5);
    uint32[5] memory radii = [ 1937420, 2910672, 69120870, 41059721, 19559342 ];
    return radii[_planet - 1];
  }

  /**
   * @dev Returns the elements for the planet that has trojan asteroids
   */
  function getPlanetWithTrojanAsteroids() public pure returns (uint16[6] memory) {
    return getElements(3);
  }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}