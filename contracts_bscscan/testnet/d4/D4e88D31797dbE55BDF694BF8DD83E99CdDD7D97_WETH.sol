/**
 *Submitted for verification at BscScan.com on 2022-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract WETH {
    
    address public owner;
    string public name = "WETH";
    string public symbol = "WETH";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 decimalfactor = 10 ** uint256(decimals);
    uint256 public Max_Token = 100000 * decimalfactor;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    constructor (address ownerAddress)  { 
        owner = ownerAddress;
        totalSupply = Max_Token;
        balanceOf[owner]=Max_Token;
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value; 
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
   function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;            
        Max_Token -= _value;                      
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function mint(address _to, uint256 _value) public returns (bool success) {
       require(msg.sender == owner,"Only Owner Can Mint");
        // totalSupply +=_value;
        if (totalSupply + _value <= Max_Token) {
            balanceOf[msg.sender] += _value;
            require(balanceOf[msg.sender] >= _value);
    
            balanceOf[msg.sender] -= _value;
            balanceOf[_to] += _value;
    
            emit Transfer(msg.sender, _to, _value); 
        }
       
        return true;
    }
}