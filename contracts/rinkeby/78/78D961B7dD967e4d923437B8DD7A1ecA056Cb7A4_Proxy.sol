// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";

contract Proxy is Ownable{
    string public  name = "Migrations";
    string public  symbol ="MIG";
    uint public  decimals = 18;
    uint256 public _totalSupply=10000000000 * 10 ** decimals;

    mapping (address => uint256) public _balanceOf;  //
    mapping (address => mapping (address => uint256)) public allowance;
    
    constructor () {
        _balanceOf[msg.sender] = _totalSupply;
    }
    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address _owner) external view returns (uint) {
        return _balanceOf[_owner];
    }
    enum HowToCall { Call, DelegateCall }
    function proxy(address dest, HowToCall howToCall, bytes memory _calldata) public returns (bool result,bytes memory returndata)
    {
        if (howToCall == HowToCall.Call) {
            (result,returndata) = dest.call(_calldata);
        } else if (howToCall == HowToCall.DelegateCall) {
            (result,returndata) = dest.delegatecall(_calldata);
        }
    }

    function proxyDelegateCall(address dest,string memory _method,address _to,uint _amount) public returns (bool result,bytes memory returndata)
    {
        (result,returndata) = dest.delegatecall(abi.encodeWithSignature(_method, _to, _amount));
    }

    function proxyCall(address dest,string memory _method,address _to,uint _amount) public returns (bool result,bytes memory returndata)
    {
        (result,returndata) = dest.call(abi.encodeWithSignature(_method, _to, _amount));
    }
    
}