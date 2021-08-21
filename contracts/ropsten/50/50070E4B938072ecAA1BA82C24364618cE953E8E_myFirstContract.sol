/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

pragma solidity 0.5.16;

contract myFirstContract {
    string name = "AJ";
    string anotherName = "Lovely";
    function whatIsYourName(string memory input) public view returns (string memory){
        if ( keccak256(abi.encodePacked (input)) == keccak256(abi.encodePacked(name))){
            return "Welcome AJ Rojo";
        }
        else if (keccak256(abi.encodePacked(input)) == keccak256(abi.encodePacked(anotherName))){
            return "Welcome Lovely Aguenza";
        }
        else {
            return "Sorry your name is not on the Database";
        }
    }
}