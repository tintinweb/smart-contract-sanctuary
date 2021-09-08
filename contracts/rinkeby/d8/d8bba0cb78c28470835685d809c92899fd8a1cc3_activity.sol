/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

pragma solidity ^0.4.23;
contract activity {
    uint256 constant public cost = 0.2 ether;
    address public manager;

    function activity(address _manager) public {
        manager = _manager;
    }

    function getTicket (address _applicant) payable public {
        require(msg.value >=cost);
    }

    function payAll () public {
        manager.transfer(this.balance);
    }
}