pragma solidity ^0.4.15;

contract LarsGeburtstagsgruss {
    address owner;
    string gruss = &quot;Alles Gute zum Geburtstag Lars! - S&#246;ren&quot;;
    string datum = &quot;19.08.2017&quot;;

    function LarsGeburtstagsgruss() { 
        owner = msg.sender;
    }
    
    function greet() constant returns (string) {
        return gruss;
    }
    
    function kill() {
        if (msg.sender == owner) selfdestruct(owner);
    }
}