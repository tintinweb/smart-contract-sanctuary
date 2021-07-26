/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface Ipledger {
    event Pledge(address node, address user, uint256 amount);
    event DePledge(address link, address user);
    
    function stakeWLuca(address _nodeAddr, uint256 _amount, address _sender) external returns(bool);
    function cancleStakeWLuca(address _sender) external returns(bool);
}

contract Pledger is Ipledger {
    
    function stakeWLuca(address _node, uint256 _amount, address _user) override external returns(bool) {
        emit Pledge(_node, _user, _amount);
        return true;
    }
    
    function cancleStakeWLuca(address _user) override external returns(bool){
        emit DePledge(msg.sender, _user);
        return true;
    }
}