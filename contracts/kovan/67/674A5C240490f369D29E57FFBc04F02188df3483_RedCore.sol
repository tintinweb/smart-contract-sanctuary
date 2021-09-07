//SPDX-License-Identifier: GPL-3.0 
pragma solidity > 0.6.0 < 0.9.0;
import './RedCore_Interface.sol'; 
import './SafeMath.sol';

contract RedCore is RedCore_Interface {
    using SafeMath for uint256;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    
    
    string public name = "RedCore";
    string public symbol = "RedCore";
    uint256 public decimal = 15;
    uint256 _totalSupply = 2000000000000000000000000; 
    
    mapping(address => uint256)_balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    constructor()  {
        _balanceOf[msg.sender] = _totalSupply;
    }
    
    function totalSupply() external view override returns (uint256){
        return _totalSupply;
    }
    function balanceOf() external view override returns (uint256 balance){
        return _balanceOf[msg.sender];
    }
    function transfer(address _to, uint256 _value) external override returns(bool success){
        
        require(_balanceOf[msg.sender]>=_value,"Not enough amount");
        require(_to != address(0));
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
        
    }
    function transferFrom(address _from, address _to, uint256 _value) external override returns (bool success){
        require(_value <=_balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        _balanceOf[_from] = _balanceOf[_from].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
         
        return true;
    }
    function approve(address _spender, uint256 _value) external override returns (bool success){
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
        
    }
}