/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/Land.sol
// SPDX-License-Identifier: Unlicense
pragma solidity =0.8.10;

////// src/Land.sol
/* pragma solidity 0.8.10; */

// represents a 3D object.
// contains the two points representing the cuboid in which
// the object will be rendered and a link to its GLB file.
struct Object {
  // Point is the place in which we position the object
  Point point;
  string gltfURL;
}

struct Point {
  int x;
  int y;
  int z;
}

struct Space {
  Object[] objects;
  Point p1;
  Point p2;
}

contract Land {
  // might also allow people to own more than one space:
  // mapping(uint => address) public owners;
  // mapping(uint => Space) public spaces;
  mapping(address => Space) public spaces;
  uint lastSpaceID;

  function mint() external {
    // a user can mint as many times as they want but they will always
    // override their existing space.
    Space storage sp = spaces[msg.sender];
    sp.p1 = Point(-100, -100, -100);
    sp.p2 = Point(100, 100, 100);
  }

  // addObject adds a single object to the `objects` array.
  // It's the gas efficient version when you only need to add a single one.
  function addObject(int[3] calldata position, string calldata _gltfURL) external {
    Space storage sp = spaces[msg.sender];

    Object memory obj = Object({
      point: Point(position[0], position[1], position[2]),
      gltfURL: _gltfURL 
    });

    sp.objects.push(obj);
  }

  function deleteSpace() external {
    delete spaces[msg.sender];
  }
}