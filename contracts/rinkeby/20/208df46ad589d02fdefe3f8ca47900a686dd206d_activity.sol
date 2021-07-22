/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

pragma solidity ^0.4.23;
contract activity {
    uint256 constant public cost = 0.1 ether;
    uint256 public people;
    mapping (address => bool) public list;
    address public manager;


    function getTicket (address _applicant) payable public {
        require(msg.value >=cost);
        people ++ ;
    }

}