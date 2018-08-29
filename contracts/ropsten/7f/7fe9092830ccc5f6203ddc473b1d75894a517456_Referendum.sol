/*
 greeter był bez sensu
 zrobimy kontrakt, kt&#243;ry wykorzystuje możliwości blockchaina
 przede wszystkim transparentność i zaufanie
 np. referendum jak w przypadku Brexitu
 anonimowość - public/private
*/
pragma solidity 0.4.24;

contract Referendum {
    mapping (address => bool) votes;
    uint public yesCount;
    uint public noCount;
    
    function sayYes() public {
        yesCount++;
        votes[msg.sender] = true;    
    }   
    
    function sayNo() public {
        noCount++;
        votes[msg.sender] = false;    
    }
}