pragma solidity ^0.6.0;

import "./IDoubleProxy.sol";

contract DoubleProxy is IDoubleProxy {

    address private _proxy;

    mapping(address => bool) private _isProxy;

    address[] private _proxies;

    constructor(address[] memory proxies, address currentProxy) public {
        init(proxies, currentProxy);
    }

    function init(address[] memory proxies, address currentProxy) public override {
        require(_proxies.length == 0, "Init already called!");
        for(uint256 i = 0; i < proxies.length; i++) {
            if(proxies[i] != address(0)) {
                _proxies.push(proxies[i]);
                _isProxy[proxies[i]] = true;
            }
        }
        if(currentProxy != address(0)) {
            _proxy = currentProxy;
            if(!_isProxy[currentProxy]) {
                _proxies.push(currentProxy);
                _isProxy[currentProxy] = true;
            }
        }
    }

    function proxy() public override view returns(address) {
        return _proxy;
    }

    function setProxy() public override {
        require(_proxy == address(0) || _proxy == msg.sender, _proxy != address(0) ? "Proxy already set!" : "Only Proxy can toggle itself!");
        _proxy = _proxy == address(0) ?  msg.sender : address(0);
        if(_proxy != address(0) && !_isProxy[_proxy]) {
            _proxies.push(_proxy);
            _isProxy[_proxy] = true;
        }
    }

    function isProxy(address addr) public override view returns(bool) {
        return _isProxy[addr];
    }

    function proxiesLength() public override view returns(uint256) {
        return _proxies.length;
    }

    function proxies() public override view returns(address[] memory) {
        return proxies(0, _proxies.length);
    }

    function proxies(uint256 start, uint256 offset) public override view returns(address[] memory out) {
        require(start < _proxies.length, "Invalid start");
        uint256 length = offset > _proxies.length ? _proxies.length : offset;
        out = new address[](length);
        length += start;
        length = length > _proxies.length ? _proxies.length : length;
        uint256 pos = 0;
        for(uint256 i = start; i < length; i++) {
            out[pos++] = _proxies[i];
        }
    }
}