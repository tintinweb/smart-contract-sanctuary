/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

pragma solidity ^0.8.0;
 
 contract CTF {
    bytes32 public secret;
    address payable public withdrawAddress;
    
    constructor (string memory flag) payable{
        secret = keccak256(abi.encodePacked(flag));
    }
    
    receive () external payable{}
    
    function setWithdrawAddress(address payable a, string calldata secretValue) payable public{
        if (keccak256(abi.encodePacked(secretValue)) == secret){
            withdrawAddress = a;
        }
    }
    
    function withdrawPrizeMoney() external {
        if (withdrawAddress != address(0x0)){
            withdrawAddress.transfer(address(this).balance);
        }
    }
 }