pragma solidity ^0.4.25;
contract Sender_data_gen {
    string public Note;
    constructor() public {
        Note = "Data parser for https://etherscan.io/alamat/0x663A516fE9b890A451935b6a8B9444F81a2730cD";
    }
    function forward(address destination) public pure returns(bytes) {
        bytes memory x = abi.encodePacked(bytes16(bytes4(0x101e8952)), destination);
        return x;
    }
    function split(address[] destinations) public pure returns(bytes) {
        bytes memory x = abi.encodePacked(bytes16(bytes4(0x94e4a822)), destinations);
        return x;
    }
    function bulk(address[] destinations, uint[] amounts) public pure returns(bytes) {
        bytes memory x = abi.encodePacked(bytes16(bytes4(0xbb9efd5e)), destinations, amounts);
        return x;
    }
}