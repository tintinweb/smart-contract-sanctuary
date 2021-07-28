/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

pragma solidity ^0.4.21;

contract Storage {
    uint public val;
}

contract LogicOne is Storage {

    function setVal(uint _val) public returns (bool success) {
        val = 2 * _val;
        return true;
    }

}