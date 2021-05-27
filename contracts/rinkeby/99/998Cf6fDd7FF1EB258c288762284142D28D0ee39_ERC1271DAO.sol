/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

pragma solidity 0.7.5;

interface IERC1271 {
    function isValidSignature(bytes32 _messageHash, bytes memory _signature)
        external
        view
        returns (bytes4 magicValue);
}

/// @title ERC1271DAO
/// @notice Demo module to show how DAOs can use ERC1271 for signatures
/// @dev Security contact: [email protected]
contract ERC1271DAO is IERC1271 {
  
  struct DAOSignature {
      bytes32 signatureHash;
      bytes4 magicValue;
      uint256 proposalId;
  }

    mapping (bytes32 => DAOSignature) signatures;
    
    mapping (uint256 => bool) public fakeProposals;
    
    function setFakeProposal(uint256 proposalId, bool passed) public {
        fakeProposals[proposalId] = passed;
    }
    
    function setFakeSignature(bytes32 permissionHash, bytes32 signatureHash, bytes4 magicValue, uint256 proposalId) public {
        signatures[permissionHash] = DAOSignature(signatureHash, magicValue, proposalId);
    }
    
    function hashHelper(bytes memory signature) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(signature));
    }

    function isValidSignature(bytes32 permissionHash, bytes memory signature)
        public
        view
        override
        returns (bytes4)
    {
        require(fakeProposals[signatures[permissionHash].proposalId], 'Proposal has not passed');
        require(signatures[permissionHash].signatureHash == keccak256(abi.encodePacked(signature)), 'Invalid signature hash');
        return signatures[permissionHash].magicValue;
    }
}