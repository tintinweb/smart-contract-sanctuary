/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

pragma solidity 0.8.0;

contract Owned {
    address payable private _owner;
    
    constructor(){
        _owner = payable(msg.sender);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner(), "caller is not the owner");
        _;
    }
    
    function owner() internal view returns (address payable) {
        return _owner;
    }
}

contract Proxy is Owned {
    event ProxyTransfer(address from, address to,uint256 value);
    
    address payable private proxyDestination;
    
    constructor(){
        proxyDestination = owner();
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
    
    function setDestination(address _to) public onlyOwner {
        proxyDestination = payable(_to);
    }
    
    function getProxyDestination() public view returns (address) {
        return proxyDestination;
    }
}

contract TokenWithdrawable is Owned {
    function send(address token, address _to, uint256 _value) public onlyOwner {
        (bool sent, ) = token.call(abi.encodeWithSelector(0xa9059cbb, _to, _value));
        require(sent);
    }
}

contract Store is Owned, Proxy, TokenWithdrawable {}