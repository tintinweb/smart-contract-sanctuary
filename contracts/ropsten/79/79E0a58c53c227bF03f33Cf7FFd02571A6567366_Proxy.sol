/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

pragma solidity 0.7.1;

contract Proxy {
    event ProxyTransfer(address from, address to,uint256 value);
    
    address payable proxyDestination;

    address payable owner;

    constructor(address _owner){
        owner = payable(_owner);
        proxyDestination = owner;
    }
    
    receive() external payable {
        (bool sent, ) = proxyDestination.call{value:msg.value}("");
        require(sent);
        emit ProxyTransfer(msg.sender, proxyDestination, msg.value);
    }

    fallback() external payable {
        if (msg.value != 0) {
            (bool sent, ) = proxyDestination.call{value:msg.value}("");
            require(sent);
            emit ProxyTransfer(msg.sender, proxyDestination, msg.value);
        }
    }

    function setDestination(address _to) public returns (bool) {
        if(msg.sender == owner){
            proxyDestination = payable(_to);
            return true;
        } else {
            return false;
        }
    }
    
    function getProxyDestination() public returns (address) {
        return proxyDestination;
    }
}