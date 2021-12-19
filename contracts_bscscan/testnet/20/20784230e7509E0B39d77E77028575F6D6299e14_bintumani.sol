/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


 
contract bintumani {
    
    string public name = "Bintumani";
    string public symbol = "Bintu";
    uint256  totalSupply = 1000000000000000000000000; // 1 million tokens
    uint8 public decimals = 18;
     uint publicmoney;
      address public myaddress=address(this);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

   
    constructor()  {
         
         publicmoney =(totalSupply*80)/100;
        balanceOf[myaddress] =(totalSupply*20)/100;
         balanceOf[msg.sender]=publicmoney;
    }
    
    function ownmoney() public view returns (uint256) {
        return  balanceOf[myaddress];
    }
      
    function totalsupply() public view returns (uint256) {
        return  totalSupply;
    }
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
 

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[myaddress];
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}