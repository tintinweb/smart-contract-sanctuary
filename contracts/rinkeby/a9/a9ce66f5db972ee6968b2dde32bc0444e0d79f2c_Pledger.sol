/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Ipledger {
    function pledge(address _user, uint256 _amount) external;
    function depledge(address _user) external;
    event Pledge(address link, address user, uint256 amount);
    event DePledge(address link, address user, uint256 amount);
}


contract Pledger is Ipledger {
    mapping(address=>mapping(address=> uint256)) public ledger;
    
    function pledge(address _user, uint256 _amount) override external{
      ledger[msg.sender][_user] = _amount;
      emit Pledge(msg.sender, _user, _amount);
    }
    
    function depledge(address _user) override external{
       uint256 _pledgeAmount = ledger[msg.sender][_user];
       ledger[msg.sender][_user] = 0;
       emit DePledge(msg.sender, _user, _pledgeAmount);
    }
}