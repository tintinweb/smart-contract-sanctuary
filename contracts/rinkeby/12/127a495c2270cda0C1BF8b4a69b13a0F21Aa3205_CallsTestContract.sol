// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import './Proxy.sol';

contract CallsTestContract is Proxy {
    uint num;
    address smart;
    event CalledSomeLib(address _from);
    function set(address _addr) public {
        smart = _addr;
    }
    
    function _implementation() public view override returns (address){
        return smart;
    }
    
    function callTheOtherContract(address _contractAddress) public {
        bool result;
        bytes memory str;
        (result,str) = _contractAddress.call(abi.encodeWithSignature("callMeMaybe()"));
        require(result);
        (result,str) = _contractAddress.delegatecall(abi.encodeWithSignature("callMeMaybe()"));
        require(result);
        (result,str) = address(this).call(abi.encodeWithSignature("callMeMaybe()"));
        require(result);
        (result,str) = address(this).delegatecall(abi.encodeWithSignature("callMeMaybe()"));
        require(result);
        emit CalledSomeLib(address(this));
    }
    
    function getNum() public view returns(uint256){
        return num;
    }
}