/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

pragma solidity ^0.5.0;
contract Sig1 {

    event HaveSigned( string msg, address signer );
    
    bytes32 public signedHash = 0;
    address public signer;
    string public message ='';

    function SigMessage( string memory mesgdata ) public {
        signer = msg.sender;
        message = mesgdata;
        signedHash =  keccak256(abi.encodePacked(mesgdata, msg.sender));
        emit HaveSigned( mesgdata, signer );
    }
    
    function SigCheck(string memory mesgdata, address onesigner ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(mesgdata, onesigner));
    }
}