/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

pragma solidity ^0.7.6;

contract TestContract {
    address public owner;
    uint public foo;

    constructor(address _owner, uint _foo) payable {
        owner = _owner;
        foo = _foo;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}