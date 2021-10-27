/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract ZCM {
    //token name
    string public name ;
    string public symbol ;
    //decimals count
    uint256 public decimals  ;
    uint256 public totalSupply;
    
    mapping(address =>uint256) public balanceOf ;
    
    mapping(address =>mapping(address=>uint256)) allowrance;
    
    event Transfer(address indexed from, address indexed to , uint256 value);
    
    event Approval(address indexed owner , address indexed spender , uint256 value);
    
    constructor(string memory _name , string memory _symbol , uint _decimals , uint _totalSupply)  {
        name = _name;
        symbol=_symbol;
        decimals=_decimals;
        totalSupply=_totalSupply;
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer(address _to , uint256 value) external  returns (bool success)  {
        require(value<= balanceOf[msg.sender]);
        _transfer(msg.sender,_to,value);
        return true;
    }
    
    function _transfer(address _from , address _to , uint256 value) internal returns(bool success){
        require(balanceOf[_from]>=value);
        balanceOf[_from] = balanceOf[_from]-value;
        balanceOf[_to] = balanceOf[_to]+value;
        emit Transfer(_from,_to,value);
        return true;
    }
    
    function approval(address _spender , uint256 cost) external returns (bool success){
        require(balanceOf[msg.sender]>cost);
        require(_spender!=address(0x0));
        allowrance[msg.sender][_spender] = cost;
        emit Approval(msg.sender,_spender , cost);
        return true;
    }
    
    function transferFrom(address _from , address _to , uint256 value) external returns(bool success){
        require(_to!=address(0x0));
        require(value<=balanceOf[_from]);
        require(value<=balanceOf[_to]);
        allowrance[_from][msg.sender] = allowrance[_from][msg.sender]-value;
        _transfer(_from,_to,value);
        return true;
    }
}