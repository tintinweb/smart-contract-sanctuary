/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// File contracts/interface/IVerifyAttestation.sol

// SPDX-License-Identifier: MIT

/* Retort contract for handling offer commitment and 'transmogrification' of NFTs */
/* AlphaWallet 2021 */

pragma solidity ^0.8.4;

struct ERC721Token { 
        address erc721;
        uint256 tokenId;
        bytes auth; // authorisation; null if underlying contract doesn't support it
}

interface IVerifyAttestation {
    function verifyNFTAttestation(bytes memory attestation, address attestorAddress, address sender) external pure returns(ERC721Token[] memory tokens, string memory identifier, address payable subject, bool isValid);
    function verifyNFTAttestation(bytes memory attestation) external pure returns(ERC721Token[] memory tokens, string memory identifier, address payable subject, address attestorAddress);
    function getNFTAttestationTimestamp(bytes memory attestation) external pure returns(string memory startTime, string memory endTime);
    function checkAttestationValidity(bytes memory nftAttestation, ERC721Token[] memory commitmentNFTs,
        string memory commitmentIdentifier, address attestorAddress, address sender) external pure returns(bool passedVerification, address payable subjectAddress);
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File contracts/VerifyAttestation.sol


/* Attestation decode and validation */
/* AlphaWallet 2021 */

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
contract VerifyAttestation is IVerifyAttestation {
    address payable owner;

    constructor()
    {
        owner = payable(msg.sender);
    }

    struct Length {
        uint decodeIndex;
        uint length;
    }

    function verifyPublicAttestation(bytes memory attestation, uint256 nIndex) public pure returns(address payable subject, string memory identifier, address attestorAddress)
    {
        bytes memory attestationData;
        bytes memory preHash;

        uint256 decodeIndex = 0;
        uint256 length = 0;

        /*
        Attestation structure:
            Length, Length
            - Version,
            - Serial,
            - Signature type,
            - Issuer Sequence,
            - Validity Time period Start, finish
        */
        
        (length, nIndex) = decodeLength(attestation, nIndex+1); //nIndex is start of prehash
        
        (length, decodeIndex) = decodeLength(attestation, nIndex+1); // length of prehash is decodeIndex (result) - nIndex

        //obtain pre-hash
        preHash = copyDataBlock(attestation, nIndex, (decodeIndex + length) - nIndex);

        nIndex = (decodeIndex + length); //set pointer to read data after the pre-hash block

        (length, decodeIndex) = decodeLength(preHash, 1); //read pre-hash header

        (length, decodeIndex) = decodeLength(preHash, decodeIndex + 1); // Version

        (length, decodeIndex) = decodeLength(preHash, decodeIndex + 1 + length); // Serial

        (length, decodeIndex) = decodeLength(preHash, decodeIndex + 1 + length); // Signature type (9) 1.2.840.10045.2.1

        (length, decodeIndex) = decodeLength(preHash, decodeIndex + 1 + length); // Issuer Sequence (14) [[2.5.4.3, ALX]]], (Issuer: CN=ALX)

        (length, attestationData, decodeIndex) = decodeElement(preHash, decodeIndex + length); // Validity Time (34) (Start, End) 32303231303331343030303835315A, 32303231303331343031303835315A
        
        (length, decodeIndex) = decodeLength(preHash, decodeIndex + 1); 
        (length, attestationData, decodeIndex) = decodeElementOffset(preHash, decodeIndex, 15); //Twitter ID
        
        identifier = copyStringBlock(attestationData);

        (length, decodeIndex) = decodeLength(preHash, decodeIndex + 1);
        (length, decodeIndex) = decodeLength(preHash, decodeIndex + 1);
        
        (length, attestationData, decodeIndex) = decodeElementOffset(preHash, decodeIndex + length, 2); // public key
        
        subject = payable(publicKeyToAddress(attestationData));

        (length, attestationData, nIndex) = decodeElement(attestation, nIndex); // Signature algorithm ID (9) 1.2.840.10045.2.1

        (length, attestationData, nIndex) = decodeElementOffset(attestation, nIndex, 1); // Signature (72) : #0348003045022100F1862F9616B43C1F1550156341407AFB11EEC8B8BB60A513B346516DBC4F1F3202204E1B19196B97E4AECD6AE7E701BF968F72130959A01FCE83197B485A6AD2C7EA

        //return attestorPass && subjectPass && identifierPass;
        attestorAddress = recoverSigner(keccak256(preHash), attestationData);
    }
    
    function getTokenInformation(bytes memory attestation, uint256 nIndex) public pure returns(ERC721Token[] memory tokens)
    {
        //currently format only handles one token
        uint256 length = 0;
        bytes memory tokenData;
        
        (length, nIndex) = decodeLength(attestation, nIndex+1); //move past overall size (312) ([4])
        (length, nIndex) = decodeLength(attestation, nIndex+1); //move past attestation size (281)   
        nIndex += length;
        
        (length, nIndex) = decodeLength(attestation, nIndex+1);
        
        uint256 tokenCount = length / 25;
        
        tokens = new ERC721Token[](tokenCount);
        address tokenAddr;
        
        for (uint256 index = 0; index < tokenCount; index++)
        {
            (length, tokenData, nIndex) = decodeElement(attestation, nIndex+2);
            //to address
            bytes memory scratch = new bytes(32);
            assembly { 
                mstore(add(scratch, 44), mload(add(tokenData, 0x20))) //load address data to final bytes160 of scratch
                tokenAddr := mload(add(scratch, 0x20))                //directly convert to address
                mstore(add(scratch, 32), 0x00) //blank scratch for use as auth placeholder
            }
        
            (length, tokenData, nIndex) = decodeElement(attestation, nIndex);
            tokens[index] = ERC721Token(tokenAddr, bytesToUint(tokenData), scratch);
        }
    }

    // Leave this function public as a utility function to check attestation against commitmentmentId
    // The check takes into account the NFTs signed by the SignedNFTAttestation vs those stored in the commitment
    function checkAttestationValidity(bytes memory nftAttestation, ERC721Token[] memory commitmentNFTs,
        string memory commitmentIdentifier, address attestorAddress, address sender) public override pure returns(bool passedVerification, address payable subjectAddress)
    {
        ERC721Token[] memory attestationNFTs;
        string memory attestationIdentifier;
        (attestationNFTs, attestationIdentifier, subjectAddress, passedVerification)
                = verifyNFTAttestation(nftAttestation, attestorAddress, sender);
                
        passedVerification = passedVerification && 
                checkValidity(attestationNFTs, commitmentNFTs, commitmentIdentifier, attestationIdentifier);
    }

    // Check that the attestion tokens match the commitment tokens 
    // And that the identifier in the attestation matches the identifier in the commitment 
    function checkValidity(ERC721Token[] memory attestationNFTs, ERC721Token[] memory commitmentNFTs, string memory commitIdentifier, 
        string memory attestationIdentifier) internal pure returns(bool)
    {
        //check that the tokens in the attestation match those in the commitment
        if (attestationNFTs.length != commitmentNFTs.length)
        {
            return false;
        }
        else 
        {
            //check each token. NB Tokens must be in same order in original commitment package as in attestation package
            for (uint256 index = 0; index < attestationNFTs.length; index++)
            {
                if (attestationNFTs[index].erc721 != commitmentNFTs[index].erc721
                    || attestationNFTs[index].tokenId != commitmentNFTs[index].tokenId)
                {
                    return false;
                }    
            }
            
            //now check identifiers match if attestation is still passing
            return checkIdentifier(attestationIdentifier, commitIdentifier);
        }
    }

    // In production we need to match the full string, as the second part of the attestation is the unique ID
    function checkIdentifier(string memory attestationId, string memory checkId) internal pure returns(bool)
    {
        return (keccak256(abi.encodePacked((attestationId))) == 
                    keccak256(abi.encodePacked((checkId))));
    }

    function messageWithPrefix(bytes memory preHash) public pure returns (bytes32 hash)
    {
        uint256 dataLength;
        uint256 length = 3;
        assembly {
            dataLength := mload(preHash)
            if gt(dataLength, 999) { length := 4 }
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        uint256 j = dataLength;
        while (j != 0)
        {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        
        bytes memory str = abi.encodePacked("\x19Ethereum Signed Message:\n", bstr, preHash);
        hash = keccak256(str);
    }

    function getNFTAttestationTimestamp(bytes memory attestation) public override pure returns(string memory startTime, string memory endTime) 
    {
        uint256 length = 0;
        uint256 nIndex = 0;
        bytes memory timeData;

        (length, nIndex) = decodeLength(attestation, nIndex+1); //move past overall size
        (length, nIndex) = decodeLength(attestation, nIndex+1); //move past token wrapper size  

        //now into PublicAttestation
        (length, nIndex) = decodeLength(attestation, nIndex+1); //nIndex is start of prehash
        
        (length, nIndex) = decodeLength(attestation, nIndex+1); // length of prehash is decodeIndex (result) - nIndex

        (length, nIndex) = decodeLength(attestation, nIndex + 1); // Version

        (length, nIndex) = decodeLength(attestation, nIndex + 1 + length); // Serial

        (length, nIndex) = decodeLength(attestation, nIndex + 1 + length); // Signature type (9) 1.2.840.10045.2.1
        
        //startTime = nIndex;

        (length, nIndex) = decodeLength(attestation, nIndex + 1 + length); // Issuer Sequence (14) [[2.5.4.3, ALX]]], (Issuer: CN=ALX)
        
        (length, nIndex) = decodeLength(attestation, nIndex + 1 + length); // Time sequence header
        
        (length, timeData, nIndex) = decodeElement(attestation, nIndex);
        startTime = copyStringBlock(timeData);
        (length, timeData, nIndex) = decodeElement(attestation, nIndex);
        endTime = copyStringBlock(timeData);
    }

    function verifyNFTAttestation(bytes memory attestation) public override pure returns(ERC721Token[] memory tokens, string memory identifier, address payable subject, address attestorAddress)
    {
        bool isValid;
        (tokens, identifier, subject, attestorAddress, isValid) = verifyNFTAttestation(attestation, address(0));

        if (!isValid)
        {
            identifier = "";
            subject = payable(address(0));
            attestorAddress = address(0);
        }
    }
    
    function verifyNFTAttestation(bytes memory attestation, address attestorAddress, address sender) public override pure returns(ERC721Token[] memory tokens, string memory identifier, address payable subject, bool isValid)
    {
        address receivedAttestorAddress;
        (tokens, identifier, subject, receivedAttestorAddress, isValid) = verifyNFTAttestation(attestation, sender);
        
        isValid = isValid && (receivedAttestorAddress == attestorAddress);
    }
    
    function verifyNFTAttestation(bytes memory attestation, address sender) public pure returns(ERC721Token[] memory tokens, string memory identifier, address payable subject, address attestorAddress, bool isValid)
    {
        bytes memory signatureData;
        uint256 nIndex = 1;
        uint256 length = 0;
        uint256 preHashStart = 0;
        uint256 preHashLength = 0;

        (length, nIndex) = decodeLength(attestation, nIndex); //move past overall size (395)
        preHashStart = nIndex;
        tokens = getTokenInformation(attestation, nIndex); // handle tokenData  
        (length, nIndex) = decodeLength(attestation, nIndex+1); //move past token wrapper size   (312)
        preHashLength = length + (nIndex - preHashStart);
        (subject, identifier, attestorAddress) = verifyPublicAttestation(attestation, nIndex); //pull out subject, identifier and check attesting signature
        
        //If the sender is the NFT subject, then no need to check the wrapping signature, the intention is signed from transaction
        if (subject != sender)
        {
            //check wrapping signature equals subject signature
            nIndex += length;
            (length, nIndex) = decodeLength(attestation, nIndex+1); //move past the signature type
            (length, signatureData, nIndex) = decodeElementOffset(attestation, nIndex+length, 1); //extract signature
            bytes memory preHash = copyDataBlock(attestation, preHashStart, preHashLength);
            //check SignedNFTAddress
            isValid = (recoverSigner(messageWithPrefix(preHash), signatureData) == subject); //Note we sign with SignPersonal
        }
        else
        {
            isValid = true;
        }
    }
    
    function publicKeyToAddress(bytes memory publicKey) pure internal returns(address)
    {
        return address(uint160(uint256(keccak256(publicKey))));
    }

    function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns(address signer)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        return ECDSA.recover(hash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal pure returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature length");

        assembly {

        // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
        // second 32 bytes
            s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }
    
    //Truncates if input is greater than 32 bytes; we only handle 32 byte values.
    function bytesToUint(bytes memory b) internal pure returns (uint256 conv)
    {
        if (b.length < 0x20) //if b is less than 32 bytes we need to pad to get correct value
        {
            bytes memory b2 = new bytes(32);
            uint startCopy = 0x20 + 0x20 - b.length;
            assembly
            {
                let bcc := add(b, 0x20)         // pointer to start of b's data
                let bbc := add(b2, startCopy)   // pointer to where we want to start writing to b2's data
                mstore(bbc, mload(bcc))         // store
                conv := mload(add(b2, 32))
            }
        }
        else
        {
            assembly
            {
                conv := mload(add(b, 32))
            }
        }
    }

    function decodeDERData(bytes memory byteCode, uint dIndex) internal pure returns(bytes memory data, uint256 index, uint256 length)
    {
        return decodeDERData(byteCode, dIndex, 0);
    }

    function copyDataBlock(bytes memory byteCode, uint dIndex, uint length) internal pure returns(bytes memory data)
    {
        uint256 blank = 0;
        uint256 index = dIndex;

        uint dStart = 0x20 + index;
        uint cycles = length / 0x20;
        uint requiredAlloc = length;

        if (length % 0x20 > 0) //optimise copying the final part of the bytes - remove the looping
        {
            cycles++;
            requiredAlloc += 0x20; //expand memory to allow end blank
        }

        data = new bytes(requiredAlloc);

        assembly {
            let mc := add(data, 0x20) //offset into bytes we're writing into
            let cycle := 0

            for
            {
                let cc := add(byteCode, dStart)
            } lt(cycle, cycles) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
                cycle := add(cycle, 0x01)
            } {
                mstore(mc, mload(cc))
            }
        }

        //finally blank final bytes and shrink size
        if (length % 0x20 > 0)
        {
            uint offsetStart = 0x20 + length;
            assembly
            {
                let mc := add(data, offsetStart)
                mstore(mc, mload(add(blank, 0x20)))
            //now shrink the memory back
                mstore(data, length)
            }
        }
    }
    
    function copyStringBlock(bytes memory byteCode) internal pure returns(string memory stringData)
    {
        uint256 blank = 0; //blank 32 byte value
        uint256 length = byteCode.length;

        uint cycles = byteCode.length / 0x20;
        uint requiredAlloc = length;

        if (length % 0x20 > 0) //optimise copying the final part of the bytes - to avoid looping with single byte writes
        {
            cycles++;
            requiredAlloc += 0x20; //expand memory to allow end blank, so we don't smack the next stack entry
        }

        stringData = new string(requiredAlloc);

        //copy data in 32 byte blocks
        assembly {
            let cycle := 0

            for
            {
                let mc := add(stringData, 0x20) //pointer into bytes we're writing to
                let cc := add(byteCode, 0x20)   //pointer to where we're reading from
            } lt(cycle, cycles) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
                cycle := add(cycle, 0x01)
            } {
                mstore(mc, mload(cc))
            }
        }

        //finally blank final bytes and shrink size (part of the optimisation to avoid looping adding blank bytes1)
        if (length % 0x20 > 0)
        {
            uint offsetStart = 0x20 + length;
            assembly
            {
                let mc := add(stringData, offsetStart)
                mstore(mc, mload(add(blank, 0x20)))
                //now shrink the memory back so the returned object is the correct size
                mstore(stringData, length)
            }
        }
    }

    function decodeDERData(bytes memory byteCode, uint dIndex, uint offset) internal pure returns(bytes memory data, uint256 index, uint256 length)
    {
        index = dIndex + 1;

        (length, index) = decodeLength(byteCode, index);
        
        if (offset <= length)
        {
            uint requiredLength = length - offset;
            uint dStart = index + offset;

            data = copyDataBlock(byteCode, dStart, requiredLength);
        }
        else
        {
            data = bytes("");
        }

        index += length;
    }

    function decodeElement(bytes memory byteCode, uint decodeIndex) internal pure returns(uint256 length, bytes memory content, uint256 newIndex)
    {
        (content, newIndex, length) = decodeDERData(byteCode, decodeIndex);
    }

    function decodeElementOffset(bytes memory byteCode, uint decodeIndex, uint offset) internal pure returns(uint256 length, bytes memory content, uint256 newIndex)
    {
        (content, newIndex, length) = decodeDERData(byteCode, decodeIndex, offset);
    }

    function decodeLength(bytes memory byteCode, uint decodeIndex) internal pure returns(uint256 length, uint256 newIndex)
    {
        uint codeLength = 1;
        length = 0;
        newIndex = decodeIndex;

        if ((byteCode[newIndex] & 0x80) == 0x80)
        {
            codeLength = uint8((byteCode[newIndex++] & 0x7f));
        }

        for (uint i = 0; i < codeLength; i++)
        {
            length |= uint(uint8(byteCode[newIndex++] & 0xFF)) << ((codeLength - i - 1) * 8);
        }
    }

    function decodeIA5String(bytes memory byteCode, uint256[] memory objCodes, uint objCodeIndex, uint decodeIndex) internal pure returns(Status memory)
    {
        uint length = uint8(byteCode[decodeIndex++]);
        bytes32 store = 0;
        for (uint j = 0; j < length; j++) store |= bytes32(byteCode[decodeIndex++] & 0xFF) >> (j * 8);
        objCodes[objCodeIndex++] = uint256(store);
        Status memory retVal;
        retVal.decodeIndex = decodeIndex;
        retVal.objCodeIndex = objCodeIndex;

        return retVal;
    }
    
    function mapTo256BitInteger(bytes memory input) internal pure returns(uint256 res)
    {
        bytes32 idHash = keccak256(input);
        res = uint256(idHash);
    }
    
    struct Status {
        uint decodeIndex;
        uint objCodeIndex;
    }

    function endContract() public payable
    {
        if(msg.sender == owner)
        {
            selfdestruct(owner);
        }
        else revert();
    }
}