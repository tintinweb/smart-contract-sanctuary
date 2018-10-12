pragma solidity ^0.4.25;
contract StoreParser {
    constructor() public {}
    function dataForBuy(address token) public pure returns(bytes) {
        return abi.encodePacked(bytes16(bytes4(0xf088d547)), token);
    }
    function dataForSell(address token, uint price) public pure returns(bytes) {
        return abi.encodePacked(bytes16(bytes4(0x6c197ff5)), token, price);
    }
    function dataForWithdraw(address token) public pure returns(bytes) {
        return abi.encodePacked(bytes16(bytes4(0x51cff8d9)), token);
    }
    function dataForOwner(address newOwner) public pure returns(bytes) {
        return abi.encodePacked(bytes16(bytes4(0xa6f9dae1)), newOwner);
    }
}