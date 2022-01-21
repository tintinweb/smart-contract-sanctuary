/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract MyTokenERC20JG{

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;


    constructor(){
        name = "Token JhoG";
        symbol = "JG";   
        totalSupply = 50000 * (uint256(10) ** decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    //////////////////////////////// TRANSFER ///////////////////////////////////
    function _transfer(address _from, address _to, uint _value) internal {
        //require(_to != 0x0); //la dirección no sea nula
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        _transfer(msg.sender, _to, _value);        
        return true;        
    }

    ////////////////////////// ALLOWANCE ////////////////////////////////////
    function transferFrom (address _from, address _to, uint256 _value) public returns (bool success){
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve (address _spender, uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    ///////////////////// BURN /////////////////////////////////////////////
    function burn (uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        totalSupply -= _value;

        return true;
    }


}