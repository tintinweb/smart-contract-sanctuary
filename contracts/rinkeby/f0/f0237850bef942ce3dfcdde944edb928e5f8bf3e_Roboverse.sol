/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;




contract Roboverse {
    
  
    
uint256 public nomer;
address public signer; 
bytes32 public hashedText;
bytes32 private hashedT = 0x456e9aea5e197a1f1af7a3e85a3212fa4049a3ba34c2289b4c860fc0b0c64ef3;


function getMessageHash(string memory _message) public pure returns(bytes32)
{
    return keccak256(abi.encodePacked(_message));
}

function getMessageHashEth(bytes32 messageHash) public pure returns(bytes32)
{
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    return keccak256(abi.encodePacked(prefix,messageHash));
}

function getHashTest(string memory _txt) public pure returns(bytes32)
{
    return keccak256(abi.encodePacked(_txt));
}

function verify(bytes memory _signature) public returns(bool)
{
    //bytes32 messageHash = getMessageHash(_message);
    //bytes32 messageHashEth = getMessageHashEth(messageHash);
    //hashedText = messageHashEth;
    
    if(recoverSigner(hashedT, _signature) == 0x120f6521592154E710939f9D19f6C7B3fd29F9a0)
    {
        nomer++;
    }
    return recoverSigner(hashedT, _signature) == 0x120f6521592154E710939f9D19f6C7B3fd29F9a0;

}

function recoverSigner(bytes32 _messageHash, bytes memory _signature) public returns (address)
{
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
    signer = ecrecover(_messageHash, v ,r, s);
    return ecrecover(_messageHash, v ,r, s);
}

function splitSignature(bytes memory _sig) public pure returns (bytes32 r, bytes32 s, uint8 v)
{
    require(_sig.length == 65, "invalid signature length");
    
    assembly {
        r := mload(add(_sig, 32))
        s := mload(add(_sig, 64))
        v := byte(0, mload(add(_sig, 96)))
    }
}




}