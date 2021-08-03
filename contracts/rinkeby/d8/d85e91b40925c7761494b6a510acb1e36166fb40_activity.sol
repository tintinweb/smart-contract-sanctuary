/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

pragma solidity ^0.4.23;
contract activity {
    uint256 constant public cost = 0.1 ether;
    address public manager;

    function activity( ) public {
        address _manager;
        manager = _manager;
    }



    function getTicket (address _applicant) payable public {
        require(msg.value >=cost);
    }

    function payAll () public {
        manager.transfer(this.balance);
    }
}