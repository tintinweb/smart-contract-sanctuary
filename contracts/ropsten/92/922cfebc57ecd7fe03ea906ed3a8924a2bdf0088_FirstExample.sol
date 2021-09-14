/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

pragma solidity ^0.8.7;
contract FirstExample{
    
    string input;
    
    constructor (string memory myinput) payable{
        input = myinput;
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function getInput() public view returns(string memory){
        return input;
    }
}