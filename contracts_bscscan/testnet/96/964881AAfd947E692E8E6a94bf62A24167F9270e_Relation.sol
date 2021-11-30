/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Relation { 
    mapping(address => address) public up;
    mapping(address => address[]) public down;

    mapping(address => bool) public operator;

    address public owner;

    constructor () public {
        owner = msg.sender; 
    }
    
    modifier ownerOnly() {
        require(msg.sender == owner,'who are you');
        _;
    }

    function setOperator(address _addr,bool _bol) public ownerOnly{
        operator[_addr] = _bol;
    }
    
    function add(address _up,address _down) public {
        require(operator[msg.sender] ,"error address");
        if(up[_down] == address(0) && _up != _down){
            up[_down] = _up;
            down[_up].push(_down);
        }
    }
}