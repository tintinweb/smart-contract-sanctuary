/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

pragma solidity 0.5.16;

contract myFirstContract {
    string name = "KC";
    function whatisYourName(string memory input) public view returns (string memory){
        if ( keccak256(abi.encodePacked ( input )) == keccak256(abi.encodePacked( name ))){
            return "Welcome, Kenneth Cordova";
        }
        if ( keccak256(abi.encodePacked ( input )) != keccak256(abi.encodePacked( name ))){
            return "You cannot access";
        }
        }
}