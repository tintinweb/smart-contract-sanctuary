/**
 *Submitted for verification at Etherscan.io on 2021-02-13
*/

pragma solidity ^0.7;

contract Badges {
    
    event badge_created(uint16 badge_id, string name);
    event badge_awarded(address _to, address _from, uint16 badge_id);
    
    uint16 badge_count;
    
    function create_badge(string calldata name) public {
        emit badge_created(badge_count, name);
        require(badge_count + 1 > badge_count);
        badge_count = badge_count + 1;
    }
    function award_badge(uint16 badge_id, address target) public {
        emit badge_awarded(target, msg.sender, badge_id);
    }
    
}