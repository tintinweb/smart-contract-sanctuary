/**
 *Submitted for verification at BscScan.com on 2021-09-27
*/

pragma solidity ^0.7.4;
// SPDX-License-Identifier: UNLICENSED
contract ASETOKEN{
    string public name = "Asset Security Token";
    string public symbol = "ASETOKEN";
    string public standard = "Asset Security Token v1.0";
    uint256 public totalSupply;
    uint256 public decimals = 18;
    address payable public _owner;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value

    );
    mapping(address =>uint256) public balanceOf;
    mapping(address=>mapping(address=>uint256)) public allowed;

    constructor(uint256 _initialSupply){
        _owner = msg.sender;
        balanceOf[_owner] = _initialSupply;
        totalSupply = _initialSupply;
    }

    
    //Transfer Token 
    function transfer 
    (address _to, uint256 _value) 
    public returns(bool) 
    {
        require(balanceOf[msg.sender]>=_value,"Insufficient balance");
         balanceOf[msg.sender] -= _value;
         balanceOf[_to]+=_value;
         return true;
    }




    //approve 
    function approve(address _spender, uint256 _value) public  returns(bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;       
    }

    //transferFrom
    function transferFrom
    (address _from, address _to, uint256 _value) public returns (bool success){
        require(_value<=balanceOf[_from]);
        require (_value <= allowed[_from][msg.sender]);
        balanceOf[_from] -=_value;
        balanceOf[_to] +=_value;
        Transfer(_from,_to,_value);
        return true;

    }

    
    //check bnb balance
    
function bnbBalance() public returns (uint256 balance){
    require(msg.sender == _owner,"Access denied");
    _owner.transfer(address(this).balance);
    return address(this).balance;
}

}