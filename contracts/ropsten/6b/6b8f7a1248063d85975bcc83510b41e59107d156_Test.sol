pragma solidity 0.4.23;

library LibTest {
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        return a + b;
    }
}

contract Test {
    using LibTest for uint256;

    uint256 private counter;

    function incrementWrite() public {
        counter = incrementRead();
    }

    function incrementRead() public constant returns(uint256) {
        return counter.add(1);
    }
}