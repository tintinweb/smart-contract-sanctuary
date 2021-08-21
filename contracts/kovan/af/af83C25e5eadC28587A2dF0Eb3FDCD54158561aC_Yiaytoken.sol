/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Yiaytoken{
    
    // Variables
    string public name = 'TestToken';
    string public symbol = 'TTO';
    uint256 public decimals = 18;
    uint256 public totalSupply = 1000000000000000000000000;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    
    constructor(){
                balanceOf[msg.sender] = totalSupply;
                }
    
    function transfer(address _to, uint256 _value) external returns (bool success){
                    require(balanceOf[msg.sender] >= _value);
                    _transfer(msg.sender, _to, _value);
                    return true;
                }
    
    function _transfer(address _from, address _to, uint256 _value) internal{
                    require(_to != address(0));
                    balanceOf[_from] -= _value;
                    balanceOf[_to] += _value;
                    emit Transfer(_from, _to, _value);
                }
    
    
    function approve(address _sender, uint256 _value) external returns (bool) {
                    require(_sender != address(0));
                    allowance[msg.sender][_sender] = _value;
                    emit Approval(msg.sender, _sender, _value);
                    return true;
    }
    
    
    function trasnferFrom(address _from, address _to, uint256 _value) external returns (bool) {
                    require(_to != address(0));
                    require(balanceOf[_from] >= _value);
                    require(allowance[_from][msg.sender] >= _value);
                    allowance[_from][msg.sender] -= _value;
                    _transfer(_from, _to, _value);
                    return true;
    }
                         
}