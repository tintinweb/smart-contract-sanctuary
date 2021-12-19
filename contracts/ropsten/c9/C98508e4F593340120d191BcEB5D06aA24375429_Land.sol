/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

pragma solidity 0.8.10;

// represents a 3D object.
// contains the two points representing the cuboid in which
// the object will be rendered and a link to its GLB file.
struct Object {
  Point p1;
  Point p2;
  string glbUrl;
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
  function addObject(Object memory o) external {
    Space storage sp = spaces[msg.sender];
    sp.objects.push(o);
  }

  function deleteSpace() external {
    delete spaces[msg.sender];
  }
}