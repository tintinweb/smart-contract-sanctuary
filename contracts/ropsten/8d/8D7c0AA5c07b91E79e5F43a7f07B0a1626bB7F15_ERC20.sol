/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

abstract contract  ERC20Interface {
    string public name;
    string public symbol;
    uint public decimals;
    uint public totalSupply;

    function transfer (address _to, uint256 _value) virtual  public returns (bool success) ;
    function transferFrom(address _from, address _to, uint256 _value) virtual public  returns(bool success);

    function approve(address _spender, uint256 _value) virtual public returns (bool success);

    function allowance(address _owner, address _spender) virtual public  view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approve(address indexed _owner, address indexed _spender, uint256 _value);

}

contract ERC20 is ERC20Interface {

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) allowed;

    constructor(string memory _name) {
        name = _name;
        symbol ="UPT";
        decimals = 0;
        totalSupply = 100000;
        balanceOf[msg.sender] = totalSupply;

    }

     function transfer (address _to, uint256 _value) override  public returns (bool success){

         require(_to != address(0));
         require(balanceOf[msg.sender] >= _value);
         require(balanceOf[_to] + _value >= balanceOf[_to]);

         balanceOf[msg.sender] -= _value;
         balanceOf[_to] += _value;

         emit Transfer(msg.sender,_to,_value);

         return true;
     }
    function transferFrom(address _from, address _to, uint256 _value) override  public  returns(bool success){

         require(_to != address(0));
         require(allowed[_from][msg.sender] >= _value);
         require(balanceOf[_from] >= _value);
         require(balanceOf[_to] + _value >= balanceOf[_to]);


         allowed[_from][msg.sender] -= _value;
         balanceOf[_from] -= _value;
         balanceOf[_to] += _value;

         emit Transfer(msg.sender,_to,_value);

         return true;

    }

    function approve(address _spender, uint256 _value) override public returns (bool success){

        allowed[msg.sender][_spender] = _value;

        emit Approve(msg.sender,_spender,_value);

        return true;
    }
        

    function allowance(address _owner, address _spender) override  public  view returns (uint256 remaining){

        return allowed[_owner][_spender];

    }
}