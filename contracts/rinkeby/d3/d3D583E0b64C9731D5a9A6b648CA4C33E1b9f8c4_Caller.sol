/**
 *Submitted for verification at Etherscan.io on 2021-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ITestCaller {
    function setValue(uint256 _v) external;
    function sender() external view returns(address);
    function value() external view returns(uint256);
}

contract Target {
    address public sender;
    uint256 public value;

    function setValue(uint256 _v) public {
        value = _v;
        sender = msg.sender;
    }
}

contract Proxy {
    address public target;

    constructor(address _target) public {
        target = _target;
    }
    
    function setValue(uint256 _v) public {
        ITestCaller(target).setValue(_v);
    }
    
    function sender() public view returns(address) {
        return ITestCaller(target).sender();
    }
    
    function value() public view returns(uint256) {
        return ITestCaller(target).value();
    }
}

contract Caller {
    address public sender;
    uint256 public value;
    address public proxy;

    constructor(address _proxy) public {
        proxy = _proxy;
    }

    function setValue1(uint256 _v) external {
        (bool success, ) =  proxy.call(abi.encodeWithSignature("setValue(uint256)", _v));

        require(success,"!success");
    }
    
    function setValue2(uint256 _v) external {
        (bool success, ) =  proxy.delegatecall(abi.encodeWithSignature("setValue(uint256)", _v));

        require(success,"!success");
    }
    
    function getSender1() public view returns(address) {
       return ITestCaller(proxy).sender();
    }
    
    function getValue1() public view returns(uint256) {
        return ITestCaller(proxy).value();
    }
    
    function getSender2() public view returns(address) {
        return sender;
    }
    
    function getValue2() public view returns(uint256) {
        return value;
    }
}

contract Factory {
    address[] public callers;
    address public proxy;
    address public target;

    constructor() public {
        target = address(new Target());
        proxy = address(new Proxy(target));
    }

    function createCaller() external returns (address) {
        address caller = address(new Caller(proxy));

        callers.push(caller);
    }
}