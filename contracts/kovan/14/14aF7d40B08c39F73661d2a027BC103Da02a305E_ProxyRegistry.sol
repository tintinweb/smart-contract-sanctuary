/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity ^0.5.0;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
    
    function setProxy(address owner, address proxy) external {
        proxies[owner] = OwnableDelegateProxy(proxy);
    }
}