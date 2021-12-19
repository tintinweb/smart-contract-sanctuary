/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

pragma solidity ^0.8.10;
    
abstract contract MyRegistry {
    function registerDomain(string memory domain) public virtual;
}

contract CallMyRegistry {

    MyRegistry my = MyRegistry(address(0x0eb294a34e9932E7123a14CFB5E9E0a828Da3593));

    function call(string memory domain) public {
        my.registerDomain(domain);    
    }
}