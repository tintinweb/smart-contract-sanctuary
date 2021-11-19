pragma solidity >=0.6.0 <0.8.0;

contract DharmalifeProof {
    bytes32[] rootRegistry;

    function uploadRoot(bytes32 root) public returns (bool) {
        rootRegistry.push(root);
    }

    function returnRoot() public view returns (bytes32) {
        bytes32 root = rootRegistry[rootRegistry.length - 1];
        return root;
    }

    function verify(
        bytes32[] memory proof,
        uint256[] memory positions,
        bytes32 leaf
    ) public view returns (bool) {
        require(rootRegistry.length > 0, "No root uploaded to smartcontract");

        bytes32 computedHash = leaf;
        bytes32 root = rootRegistry[rootRegistry.length - 1];

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (positions[i] == 1) {
                computedHash = keccak256(
                    abi.encode(computedHash, proofElement)
                );
            } else {
                computedHash = keccak256(
                    abi.encode(proofElement, computedHash)
                );
            }
        }

        return computedHash == root;
    }
}