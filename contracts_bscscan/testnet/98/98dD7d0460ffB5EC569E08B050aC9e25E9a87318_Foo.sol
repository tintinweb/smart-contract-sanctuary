pragma solidity ^0.8.0;

contract Foo {
    struct Point {
        uint x;
        uint y;
    }

    uint public x;
    string public s;
    Point public point;
    bytes public b;

    constructor (uint _x, string memory _s, Point memory _point, bytes memory _b) {
        x = _x;
        s = _s;
        point = _point;
        b = _b;
    }
}

