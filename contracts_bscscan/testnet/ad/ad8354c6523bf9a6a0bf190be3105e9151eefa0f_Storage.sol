/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    mapping (address => mapping(uint256=> uint256)) userStatus;

    address owner;
    
    constructor () {
        owner = msg.sender;
    }
    modifier only_owner {
        require(msg.sender == owner);
        _;
    }
    
    function set(address user, uint256 id, uint256 value) public only_owner {
        userStatus[user][id] = value;
    }

    function get(address user, uint256 id) public view returns (uint256) {
        return userStatus[user][id];
    }
}