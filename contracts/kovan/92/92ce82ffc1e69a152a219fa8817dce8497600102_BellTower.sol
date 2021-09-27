/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

contract BellTower {
    // Counter of how many times the bell has been rung
    uint public bellRung;
    
    // Event for ringing a bell
    event BellRung(uint rangForTheNthTime, address WhoRangIt);
    
    // Ring the bell
    function ringTheBell() public {
        bellRung++;
    
        emit BellRung(bellRung, msg.sender);
        
    }
}