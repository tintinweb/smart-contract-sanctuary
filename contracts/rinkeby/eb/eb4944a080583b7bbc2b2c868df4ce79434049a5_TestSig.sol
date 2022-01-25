/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract TestSig {
   
    
address public signer;  
bool public minted;
 
function getMessageHash(address _message) public pure returns(bytes32) 
{ 
    return keccak256(abi.encodePacked(_message)); 
} 
 
function getMessageHashEth(bytes32 _sender) public pure returns(bytes32) 
{ 
    bytes memory prefix = "\x19Ethereum Signed Message:\n32"; 
    return keccak256(abi.encodePacked(prefix,_sender)); 
} 
 
function getHashTest(string memory addressToHash) public pure returns(bytes32) 
{ 
    return keccak256(abi.encodePacked(addressToHash)); 
} 


function mint(bytes memory sig) public {
    require(verify(sig, msg.sender), "Wrong signature, You are not verified to mint");
    minted = true;
}

function verify(bytes memory _signature, address sender) public returns(bool) 
{ 
    bytes32 messageHas = getMessageHash(sender); 
    bytes32 messageHashEth = getMessageHashEth(messageHas); 
     
    return recoverSigner(messageHashEth, _signature) == 0x7C6B970eF4E98E973830735a3eE89c2BAA8A1b1C; 
 
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