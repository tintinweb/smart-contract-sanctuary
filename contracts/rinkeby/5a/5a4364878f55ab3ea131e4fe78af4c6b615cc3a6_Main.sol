/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

pragma solidity ^0.4.25;
contract Main {

    uint[] a = [12,2,3,4,7];
    function Delete() public returns(uint[]) {
        delete a;
        return a;
        }
    function add(uint i) public returns(uint[]) {
        a.push(i);
        return a;
        }
}