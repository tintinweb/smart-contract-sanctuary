pragma solidity ^0.5.0;

/// @dev Supports both prefixed and un-prefixed signatures.
contract SignatureVerifier {
    /// @notice Determines whether the passed signature of `messageHash` was made by the private key of `_address`.
    /// @param _address The address that may or may not have signed the passed messageHash.
    /// @param messageHash The messageHash that may or may not have been signed.
    /// @param v The v component of the signature.
    /// @param r The r component of the signature.
    /// @param s The s component of the signature.
    /// @return true if the signature can be verified, false otherwise.
    function isSigned(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s) public pure returns (bool) {
        return _isSigned(_address, messageHash, v, r, s) || _isSignedPrefixed(_address, messageHash, v, r, s);
    }

    /// @dev Checks unprefixed signatures.
    function _isSigned(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s)
        internal pure returns (bool)
    {
        return ecrecover(messageHash, v, r, s) == _address;
    }

    /// @dev Checks prefixed signatures.
    function _isSignedPrefixed(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s)
        internal pure returns (bool)
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return _isSigned(_address, keccak256(abi.encodePacked(prefix, messageHash)), v, r, s);
    }
}

contract StringToLower {
	function lower(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
    * Lower
    *
    * Convert an alphabetic character to lower case and return the original
    * value when not alphabetic
    *
    * @param _b1 The byte to be converted to lower case
    * @return bytes1 The converted value if the passed value was alphabetic
    *                and in a upper case otherwise returns the original value
    */
    function _lower(bytes1 _b1) internal pure returns (bytes1) {
        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }
        return _b1;
    }
}

contract IPFS is SignatureVerifier, StringToLower {
    
    event NewUser(string username, string hash, address publicKey);
    
    struct User {
        string ipfsHash;
        address publicKey;
    }
    
    mapping(string => User) usernames;
    
    function newUser(string memory username, string memory ipfsHash, address publicKey, uint8 v, bytes32 r, bytes32 s) public {
        require(
            usernames[username].publicKey == address(0), 
            "Username already taken"
        );
        require(
            isSigned(
                publicKey,
                keccak256(
                    abi.encodePacked(
                        lower(username),
                        ipfsHash,
                        publicKey
                    )
                ),
                v, r, s
            ),
            "Permission denied."
        );
            
        usernames[username] = User(ipfsHash, publicKey);
        
        emit NewUser(username, ipfsHash, publicKey);
    }
    
    function newUserNoSigning(string memory username, string memory ipfsHash, address publicKey) public {
        require(
            usernames[username].publicKey == address(0), 
            "Username already taken"
        );
            
        usernames[username] = User(ipfsHash, publicKey);
        
        emit NewUser(username, ipfsHash, publicKey);
    }
    
    function getUser(string memory username) public view returns(string memory, address) {
        return (usernames[username].ipfsHash, usernames[username].publicKey);
    }
    
}