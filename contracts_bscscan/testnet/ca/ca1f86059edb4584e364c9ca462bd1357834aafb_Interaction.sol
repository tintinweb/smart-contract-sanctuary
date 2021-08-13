/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

pragma solidity ^0.5.0;

interface ICounter {
    function numberOfStaker() external view returns (uint);
}

contract Interaction {
    address counterAddr;

    function setContractAddr(address _counter) public payable {
       counterAddr = _counter;
    }

    function getNumberOfStaker() external view returns (uint) {
        return ICounter(counterAddr).numberOfStaker();
    }
}