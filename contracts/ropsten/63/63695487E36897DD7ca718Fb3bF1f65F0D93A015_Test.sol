pragma solidity 0.8.3;

contract Test {
    uint256 a;
    uint256 b;

    constructor (uint256 _a, uint256 _b) public {
        a = _a;
        b = _b;
    }

    function changeA(uint256 _a) external {
      a = _a;
    }

    function changeB(uint256 _b) external {
      b = _b;
    }
}