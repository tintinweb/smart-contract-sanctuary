/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 */
contract Mintable {
    uint gadget = 0;

    function mint(uint8 count) public returns (uint) {
        gadget += count;
        return gadget;
    }

    function totalSupply() public view returns (uint) {
        return gadget;
    }
}