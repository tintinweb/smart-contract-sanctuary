pragma solidity ^0.5.0;

contract Support {
    function generateBytes(address add, uint256 id) public pure returns (bytes memory) {
        bytes memory mesageByte = abi.encodePacked(add, id);
        return mesageByte;
    }

    function generateBytesForString(string memory message) public pure returns (bytes memory) {
        bytes memory mesageByte = abi.encodePacked(message);
        return mesageByte;
    }

    function generateBytesForPermissioned(address contractAdd, uint256 id, address userWallet) public pure returns (bytes memory) {
        bytes memory mesageByte = abi.encodePacked(contractAdd, id, userWallet);
        return mesageByte;
    }
}

