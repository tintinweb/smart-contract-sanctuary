/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

pragma solidity 0.7.4;

contract MiyabiVault {

    event Lock(address indexed _from, uint _value);
    event UnLock(address indexed _from, uint _value);

    function lock() public payable {
        emit Lock(msg.sender, msg.value);
    }
    
     function unlock() public payable {
        emit UnLock(msg.sender, msg.value);
    }
}