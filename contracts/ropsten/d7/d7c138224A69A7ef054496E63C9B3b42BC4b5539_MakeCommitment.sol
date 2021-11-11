pragma solidity >=0.5.16;

contract MakeCommitment {
    function makeCommitmentWithConfig(
        string memory name,
        address owner,
        bytes32 secret,
        address resolver,
        address addr
    ) public pure returns (bytes32) {
        bytes32 label = keccak256(bytes(name));
        if (resolver == address(0) && addr == address(0)) {
            return keccak256(abi.encodePacked(label, owner, secret));
        }
        require(resolver != address(0));
        return keccak256(abi.encodePacked(label, owner, resolver, addr, secret));
    }

    function parse(string memory name)
        public
        pure
        returns (
            bytes32 label,
            uint256 tokenId,
            bytes32 nodehash
        )
    {
        bytes32 basenode = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;
        label = keccak256(bytes(name));
        tokenId = uint256(label);
        nodehash = keccak256(abi.encodePacked(basenode, label));
    }
}