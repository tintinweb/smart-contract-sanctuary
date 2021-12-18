/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Token{
    string constant name = "Maybik";
    string constant symbol = "MIK";
    uint8 constant decimals = 25;
    uint totalSupply = 0;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    address owner;

    event Transfer(address _from, address _to, uint transf_val);
    event Approval(address _from, address _to, uint allowed_val);

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    function mint(address adr_to_trans, uint val) public onlyOwner{
            totalSupply += val;
            balances[adr_to_trans] += val;
    }

    function transfer(address _to, uint val) public{
        address _from = msg.sender;
        require(balances[_from] >= val);
        balances[_from] -= val;
        balances[_to] += val;
        emit Transfer(_from, _to, val);
    }

    function transferFrom(address _from, address _to, uint val) public{
        require(balances[_from] >= val);
        require(allowed[_from][msg.sender]>=val);
        balances[_from] -= val;
        balances[_to] += val;
        allowed[_from][msg.sender] -= val;
        emit Transfer(_from, _to, val);
        emit Approval(_from, msg.sender, allowed[_from][msg.sender]);
    }

    function approve(address _to, uint value) public{
        address _from = msg.sender;
        allowed[_from][_to] = value;
        emit Approval(_from, _to, value);
    }

    function allowance(address _from, address _to) public view returns(uint){
            return(allowed[_from][_to]);
    }

    function balanceOf(address adr) public view returns(uint){
        return(balances[adr]);
    }

    function balanceOf() public view returns(uint){
        return(balances[msg.sender]);
    }






}