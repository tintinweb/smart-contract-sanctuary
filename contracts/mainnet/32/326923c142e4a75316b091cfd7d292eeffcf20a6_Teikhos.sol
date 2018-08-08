/* 
   A vault so that anyone can try out the Teikhos authentication method 

   proof-of-public-key = f(nextPublicKey) xor sha512(nextPublicKey)
   
   note, very high gas cost since it uses an on-state sha3_512 library
*/



contract SHA3_512 {
   function hash(uint64[8]) pure public returns(uint32[16]) {}
}

contract Teikhos {

    SHA3_512 public sha3_512 = SHA3_512(0x367b9E7d0364CF8aa8fEc906DDa56Faf41292dB7);

    // Use a string as the account identifier, so people can use any name they want

    mapping(string => bytes) proof_of_public_key;
    
    mapping(string => uint) balanceOf;


    function checkAccount(string _name) view public returns (uint balance, bytes proof) {
         return (balanceOf[_name], proof_of_public_key[_name]);
    }

    function newAccount(string _name, bytes _proof_of_public_key) public {
        require(proof_of_public_key[_name].length == 0);
        require(_proof_of_public_key.length == 64); 
        require(bytes(_name).length != 0);
    
        proof_of_public_key[_name] = _proof_of_public_key;
    }

    function deposit(string _name) public payable {
        require(proof_of_public_key[_name].length == 64);
        balanceOf[_name] += msg.value;
    }
    

    function authenticate(string _name, bytes _publicKey) public {

        require(proof_of_public_key[_name].length == 64);

        // Get address from public key
        address signer = address(keccak256(_publicKey));

        require(signer == msg.sender);

        bytes memory keyHash = getHash(_publicKey);
         
        // Split hash of public key in 2xbytes32, to support xor operator and ecrecover r, s v format

        bytes32 hash1;
        bytes32 hash2;

        assembly {
        hash1 := mload(add(keyHash,0x20))
        hash2 := mload(add(keyHash,0x40))
        }

        // Split proof_of_public_key in 2xbytes32, to support xor operator and ecrecover r, s v format

        bytes memory PoPk = proof_of_public_key[_name];

        bytes32 proof_of_public_key1;
        bytes32 proof_of_public_key2;

        assembly {
        proof_of_public_key1 := mload(add(PoPk,0x20))
        proof_of_public_key2 := mload(add(PoPk,0x40))
        }

        // Use xor (reverse cipher) to get signature in r, s v format
        bytes32 r = proof_of_public_key1 ^ hash1;
        bytes32 s = proof_of_public_key2 ^ hash2;

        // Get msgHash for use with ecrecover
        bytes32 msgHash = keccak256("\x19Ethereum Signed Message:\n64", _publicKey);

        // The value v is not known, try both 27 and 28
        if(ecrecover(msgHash, 27, r, s) == signer || ecrecover(msgHash, 28, r, s) == signer ) {
           uint amount = balanceOf[_name];
           // delete the account to prevent recursive call attacks
           delete balanceOf[_name];
           delete proof_of_public_key[_name];
           // then withdraw all ether held in the vault
           require(msg.sender.send(amount));
        }
    }

   // A separate method getHash() for converting bytes to uint64[8], which is done since the EVM cannot pass bytes between contracts
   // The SHA3_512 logic is in a separate contract to make it easier to read, that contract could be audited on its own, and so on

   function getHash(bytes _message) view internal returns (bytes messageHash) {

        // Use SHA3_512 library to get a sha3_512 hash of public key

        uint64[8] memory input;

        // The evm is big endian, have to reverse the bytes

        bytes memory reversed = new bytes(64);

        for(uint i = 0; i < 64; i++) {
            reversed[i] = _message[63 - i];
        }

        for(i = 0; i < 8; i++) {
            bytes8 oneEigth;
            // Load 8 byte from reversed public key at position 32 + i * 8
            assembly {
                oneEigth := mload(add(reversed, add(32, mul(i, 8)))) 
            }
            input[7 - i] = uint64(oneEigth);
        }

        uint32[16] memory output = sha3_512.hash(input);
        
        bytes memory toBytes = new bytes(64);
        
        for(i = 0; i < 16; i++) {
            bytes4 oneSixteenth = bytes4(output[15 - i]);
            // Store 4 byte in keyHash at position 32 + i * 4
            assembly { mstore(add(toBytes, add(32, mul(i, 4))), oneSixteenth) }
        }

        messageHash = new bytes(64);

        for(i = 0; i < 64; i++) {
            messageHash[i] = toBytes[63 - i];
        }   
   }

}