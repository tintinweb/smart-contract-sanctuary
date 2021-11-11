/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.22;

contract calledContract{
    event callEvent(address sender, address origin, address from);
    function calledFunction() public{
        emit callEvent(msg.sender, tx.origin, this);
    }
}

library calledLibrary {
    event callEvent(address sender, address origin, address from);
    function calledFunction() public{
        emit callEvent(msg.sender, tx.origin, this);
    }
}

contract caller {
    function make_calls(calledContract _calledContract) public{
        
        // use calledContract, calledLibrary directly
        _calledContract.calledFunction();
        calledLibrary.calledFunction();
        
        // use address lowlevel object about calledContract
        require(address(_calledContract).call(bytes4(keccak256("calledFunction()"))));
        require(address(_calledContract).delegatecall(bytes4(keccak256("calledFunction()"))));
    }
}