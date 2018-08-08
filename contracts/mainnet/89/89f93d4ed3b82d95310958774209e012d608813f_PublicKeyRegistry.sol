pragma solidity 0.4.24;

// Author: Henk Dieter Oordt / Baksteen Blockchain
// Git: https://github.com/baksteenblockchain/eth-pubkeyreg
/*
    This contract is used to register public keys that correspond to Ethereum addresses.
    These public keys can be usedfor encryption and the like.
*/
contract PublicKeyRegistry {
    mapping(address => bytes) public publicKeys;
    
    function pubKeyToAddress(bytes _pubKey) internal pure returns (address) {
        return address(keccak256(_pubKey));
    }
    
    function isValidPubKey(bytes _pubKey) internal pure returns (bool) {
        return _pubKey.length == 64;
    }
    
    function registerPubKey(address _addr, bytes _pubKey) external {
        require(
            isValidPubKey(_pubKey),
            "The public key was invalid"
        );
        require(
            pubKeyToAddress(_pubKey) == _addr, 
            "The public key does not correspond with the address"
        );
        
        publicKeys[_addr] = _pubKey;
        
        emit PublicKeyRegistered(_addr, _pubKey);
    }
    
    event PublicKeyRegistered(address addr, bytes pubKey);
}