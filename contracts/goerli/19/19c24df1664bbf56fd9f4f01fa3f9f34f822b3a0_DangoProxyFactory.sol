//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import { DangoProxy } from "./Proxy.sol";

contract DangoProxyFactory {
    event CreateProxy(address indexed owner, address indexed proxy, address indexed sender);

    mapping(address => address) public registry;
    mapping(address => bool) public isProxy;

    function build(address _owner) public returns (address _proxy) {
        _proxy = address(new DangoProxy(_owner));
        registry[_owner] = _proxy;
        isProxy[_proxy] = true;

        emit CreateProxy(_owner, _proxy, msg.sender);
    }

    function build() public returns (address _proxy) {
        _proxy = build(msg.sender);
    }
}