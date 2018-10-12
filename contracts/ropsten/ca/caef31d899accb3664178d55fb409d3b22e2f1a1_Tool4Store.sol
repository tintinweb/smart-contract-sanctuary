pragma solidity ^0.4.25;
contract Tool4Store {
    constructor() public {}
    function dataForBuy(address token) public pure returns(bytes) {
        return abi.encodePacked(bytes16(0xf088d547), token);
    }
}