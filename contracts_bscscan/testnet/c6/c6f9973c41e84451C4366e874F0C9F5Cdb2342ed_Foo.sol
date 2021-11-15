pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract Foo {
    struct Point {
        uint x;
        uint y;
    }

    uint256 public version = 2;

    uint public x;
    string public s;
    Point public point;
    bytes public b;

    constructor (uint _x, string memory _s, Point memory _point, bytes memory _b) public {
        x = _x;
        s = _s;
        point = _point;
        b = _b;
    }
}

