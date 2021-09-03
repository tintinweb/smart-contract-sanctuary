/**
 *Submitted for verification at Etherscan.io on 2021-09-03
*/

pragma solidity ^0.4.16;

 contract Phishable {
        address public owner;
        event withdraw(address _to, uint256 value);

        function Phishable() public {
            owner =  msg.sender;
            }
  
  
function withdrawAll(address _to) public {
        require(tx.origin == owner);
        _to.transfer(this.balance); 
        withdraw(_to,this.balance);
             }
  
function () public payable {}
 }