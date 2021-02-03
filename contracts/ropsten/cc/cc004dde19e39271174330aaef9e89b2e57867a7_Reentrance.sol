/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

pragma solidity ^0.4.25;
// 공격 대상의 컨트랙트
contract Reentrance {
    
    uint public totalBalance;
    mapping (address => uint) userBalance;
   
    function getBalance(address u) public constant returns(uint){
        return userBalance[u];
    }
    function addToBalance() public payable{
        userBalance[msg.sender] += msg.value;
        totalBalance += msg.value;
    }
    function withdrawBalance() public {
        if( ! (msg.sender.call.value(userBalance[msg.sender])() ) ){
            revert();
        }
        userBalance[msg.sender] = 0;
        totalBalance -= userBalance[msg.sender];
    }
   
}