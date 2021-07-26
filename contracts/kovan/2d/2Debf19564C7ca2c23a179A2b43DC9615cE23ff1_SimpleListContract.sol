/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

pragma solidity ^0.8.0;

contract SimpleListContract {
    address owner = msg.sender;
    
    struct Event {
        bool enabled;
        bool claimed;
    }
    
    mapping (uint256 => Event) public events;
    uint public num_events;
    
    function addEvent() public {
        require(msg.sender == owner);
        events[num_events++].enabled = true;
    }
    
    function claimEvent(uint i) public {
        require(events[i].enabled);
        require(!events[i].claimed);
        events[i].claimed;
    }
}