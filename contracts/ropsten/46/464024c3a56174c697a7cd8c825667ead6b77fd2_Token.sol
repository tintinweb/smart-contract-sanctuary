/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

pragma solidity 0.4.18;

contract Token {

 mapping(address => uint) balances;

 function transfer(address _to, uint _value) public {
   require(balances[msg.sender] - _value > 0);
   balances[msg.sender] = _value;
   balances[_to] += _value;
 }


function deposit() public payable{
           balances[msg.sender] = balances[msg.sender]+msg.value;       
     }

function withdraw(uint amount) public payable {
        msg.sender.transfer(amount);
   }
    
    function kill() public {
       selfdestruct(msg.sender);
       
    }
    }