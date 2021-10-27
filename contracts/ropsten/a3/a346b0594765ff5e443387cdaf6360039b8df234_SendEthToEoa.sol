/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

pragma solidity ^0.8.7;


contract SendEthToEoa {

    event Received(address, uint);
    address public owner;
    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    modifier onlyOwner() {
        require(msg.sender == owner); 
        _;
    }

    function withdrawMoney(address payable _to, uint _amount) public onlyOwner {
        _to.transfer(_amount);
    } 


}