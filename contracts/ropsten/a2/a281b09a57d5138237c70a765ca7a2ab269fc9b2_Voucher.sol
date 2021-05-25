/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.6.0;

contract Voucher {
    
    mapping (address=>uint256) public balances;
    address owner;
    uint256 _totalSupply;
    
    function name() public pure returns (string memory){
        return "PhDBlockToken";
    }
    
    function symbol() public pure returns (string memory){
        return "PHD";
    }
    function decimals() public pure returns (uint8){
        return 0;
    }
    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }
    
    /*
    function balanceOf(address _owner) public view returns (uint256 balance)
    function transfer(address _to, uint256 _value) public returns (bool success)
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    function approve(address _spender, uint256 _value) public returns (bool success)
    function allowance(address _owner, address _spender) public view returns (uint256 remaining)
    */

    constructor(){
        balances[msg.sender] = 100;
        _totalSupply = 100;
        owner = msg.sender;
    }
    
    function ownershipTransfer(address _to) public{
        require(msg.sender == owner);
        owner = _to;
    }
    
    function mint(uint256 _value) public{
        require (msg.sender == owner);
        balances[msg.sender] += _value;
        _totalSupply += _value;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balances[msg.sender] >= _value, "Not enought funds");
        // transfer tokens from msg.sender to _to
        balances[msg.sender] -= _value; 
        balances[_to] += _value;
        return true;
    }
}