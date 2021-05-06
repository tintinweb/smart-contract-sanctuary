/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity ^0.4.25;

contract VictomSingleFunction {
    
    mapping(address => uint) public userbalances;
    
    function withdraw() public returns (bool) {
        uint amountToWithdraw = userbalances[msg.sender];
        msg.sender.call.value(amountToWithdraw)();
        userbalances[msg.sender] = 0;
        return true;
    }
    
    function updateUserBalance(address _attacker, uint256 _bal) public returns (bool) {
        userbalances[_attacker];
    }
    
    function () external payable {
        
    }
}