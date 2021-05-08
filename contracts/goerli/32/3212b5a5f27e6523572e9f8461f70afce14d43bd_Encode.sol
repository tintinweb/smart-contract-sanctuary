/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

contract Encode {
    function toBytesPacked(address a) public pure returns (bytes memory) {
        return abi.encodePacked(a);
    }
    function toBytes(address a) public pure returns (bytes memory) {
        return abi.encode(a);
    }
    function toBytesPacked(uint256 a) public pure returns (bytes memory) {
        return abi.encodePacked(a);
    }
    function toBytes(uint256 a) public pure returns (bytes memory) {
        return abi.encode(a);
    }
    function toBytesPacked(uint8 a) public pure returns (bytes memory) {
        return abi.encodePacked(a);
    }
    function toBytes(uint8 a) public pure returns (bytes memory) {
        return abi.encode(a);
    }
}