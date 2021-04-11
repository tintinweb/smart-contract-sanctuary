/**
 *Submitted for verification at Etherscan.io on 2021-04-11
*/

pragma solidity ^0.5.0;

contract modifierSolidity {
   
    address[10] lesecret;
    
    function getSecret(uint256 a) public view returns(address) {
        return lesecret[a];
    }
    
    function getAllSecret() public view returns(address[10] memory) {
        return lesecret;
    }
    function changeSecret(uint256 a, address b) public returns(int) {
        lesecret[a] = b;
        return 1;
    }
}