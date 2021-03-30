/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

pragma solidity 0.5.16;

contract IdentityContract{
    mapping (address => bool) public whitelist;
    
    function isValid(address addy) public view returns (bool) {
        return whitelist[addy];
    }
    
    function approve(address addy) public returns (bool) {
        whitelist[addy] = !whitelist[addy];
    }
}