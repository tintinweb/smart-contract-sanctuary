pragma solidity >=0.5.0;

contract BNSHelper {
    function checkTokenId(string memory name) pure public returns(uint256) {
        bytes32 label = keccak256(bytes(name));
        uint256 tokenId = uint256(label);

        return tokenId;
    }
}

