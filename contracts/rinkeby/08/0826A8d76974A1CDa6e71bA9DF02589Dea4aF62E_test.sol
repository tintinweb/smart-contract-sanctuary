pragma solidity=0.8.9;

contract test{

event LockTokens(bytes32 messageHash,bytes message);
event test(address a, address b);
uint public nonce;
address public validator = 0x40EDEeE82a998df03fa7C9EE3aE9E3cB96d4E0a0;

function lockTokens(uint amount, address targetChain) external 
{

    uint oldNonce = nonce;
    nonce = nonce+1;
    emit LockTokens(keccak256(abi.encode(amount,oldNonce,address(this),targetChain)),abi.encode(amount,oldNonce,address(this),targetChain));
}
 function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
 function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 byt (es).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

 function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function unlockTokens(bytes32 messageHash, bytes memory message, bytes memory signature) external {
        (uint amount, uint nonce, address contCheck, address to) = abi.decode(message,(uint,uint,address,address));
        require(contCheck==address(this));

        bytes32 myHash = keccak256(abi.encode(amount,nonce,contCheck,to));
        bytes32 prefixHash = prefixed(myHash);
        require(messageHash==prefixHash,"hash check failed");
        address addressOfSig = recoverSigner(prefixHash, signature);
        //signature check
        require(addressOfSig==validator,"signature failed");
        eventCheck(addressOfSig,validator);
    }
    function eventCheck(address c , address d ) internal {
        emit test(c,d);

    }

    
    


}

//bytes32 messageHash, bytes memory message, bytes[] memory signatures