/**
 *Submitted for verification at Etherscan.io on 2021-04-11
*/

pragma solidity ^0.5.0;

contract modifierSolidity {
   
    address[10] lesecret;
    uint256 result;

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
    
    function sendNow(address payable a,address payable b,address payable c) public payable returns(uint256) {
        a.transfer(msg.value/5);
        b.transfer(msg.value/5);
        c.transfer(msg.value/5);
    }
    
    function callBalance(address a,address b) public returns(bytes memory) {
        (bool status, bytes memory returnData) = a.call(abi.encodeWithSignature("balanceOf(address)", b));
        return returnData;
    }
}