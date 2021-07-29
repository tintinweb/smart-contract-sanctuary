/**
 *Submitted for verification at BscScan.com on 2021-07-29
*/

// SPDX-License-Identifier: UNLISCENSED

pragma solidity 0.8.4;
 
contract lolol {
    string public name = "name";
    string public symbol = "symbol";
    uint256 public totalSupply = 100*(10**3);
    uint8 public decimals = 3;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        currentSupply = totalSupply;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

uint256 public currentSupply;

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
    require(balanceOf[msg.sender] >= _value);
    balanceOf[msg.sender] -= _value;
    balanceOf[address(0)] += _value;
    currentSupply -= _value;
    emit Transfer(msg.sender, address(0), _value);
    return true;
    }
    
    function addAllowance(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] += _value;
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender] += _value);
        return true;
        }

    function removeAllowance(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] -= _value;
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender] -= _value);
        return true;
     } 
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        emit Approval(_from, msg.sender, allowance[_from][msg.sender] -= _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[address(0)] += _value;
        allowance[_from][msg.sender] -= _value;
        currentSupply -= _value;
        emit Transfer(_from, address(0), _value);
        emit Approval(_from, msg.sender, allowance[_from][msg.sender] -= _value);
        return true;
    }
    
}