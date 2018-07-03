pragma solidity ^0.4.24;

contract Impossible {
    address public owner = msg.sender;
    
    mapping(bytes => bool) invalidatedSignatures;
    
    event EmergencyOwnershipTransfer(address oldOwner, address newOwner);
    
    function concat(uint8 v, bytes32 r, bytes32 s) public pure returns (bytes) {
        bytes memory result = new bytes(96);
        assembly {
            mstore(add(result, 0x20), v)
            mstore(add(result, 0x40), r)
            mstore(add(result, 0x60), s)
        }
        return result;
    }
    
    function validSignature(uint8 v, bytes32 r, bytes32 s) public constant returns (bool) {
        return !invalidatedSignatures[concat(v, r, s)];
    }
    
    function invalidateSignature(uint8 v, bytes32 r, bytes32 s) public {
        invalidatedSignatures[concat(v, r, s)] = true;
    }
    
    function claimOwnership(uint8 v, bytes32 r, bytes32 s) public returns (bool) {
        require(validSignature(v, r, s));
        invalidateSignature(v, r, s);
        
        if (ecrecover(keccak256(&quot;emergency ownership transfer&quot;), v, r, s) == owner) {
            address oldOwner = owner;
            owner = msg.sender;
            
            emit EmergencyOwnershipTransfer(oldOwner, msg.sender);
            return true;
        }
        
        return false;
    }
}