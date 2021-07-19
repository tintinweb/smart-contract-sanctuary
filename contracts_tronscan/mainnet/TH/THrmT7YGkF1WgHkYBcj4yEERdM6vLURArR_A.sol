//SourceUnit: HjzToken.sol

pragma solidity >=0.5.0 <0.6.0;

contract A {
    uint256 a = 1000;

    constructor() public {}

    function getA() external view returns (uint256) {
        return a;
    }
}