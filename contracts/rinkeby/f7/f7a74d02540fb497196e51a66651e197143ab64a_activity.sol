/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

pragma solidity ^0.4.23;
contract activity {
    address public manager;

    function activity(address _manager) public {
        manager = _manager;
    }

    function payAll () public {
        manager.transfer(this.balance);
    }
}