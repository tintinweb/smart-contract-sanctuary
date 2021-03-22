// SPDX-License-Identifier: MIT
// ERC 20 Token
pragma solidity ^0.8.2;
import "./MYERC20.sol";
import "./SafeMath.sol";

contract MastroERC20 is MYERC20{
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) _allowed;
    uint256 private _totalSupply = 100000000000;
    string public constant name = "MASTRO TOKEN";
    string public constant symbol = "MASERC";
    uint8 public constant decimals = 6;
    address minter;
    
    constructor(){
        minter = msg.sender;
        _balances[minter] = _totalSupply;
    }


    function totalSupply() public view override returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address _owner) public view override returns (uint256){
        return _balances[_owner];
    }

    function allowance(address _owner, address _spender) public view override returns (uint256){
        return _allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public override returns (bool){
        require(_to != address(0));
        require(_value <= _balances[msg.sender]);
        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value);        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool){
        require(_spender != address(0));
        _allowed[msg.sender][_spender] = _value;        
        emit Approval(msg.sender, _spender, _value);
        return true;
    } 
    
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool){
        require(_to != address(0));
        require(_value <= _balances[_from]);
        require(_value <= _allowed[_from][msg.sender]);

        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value); 
        emit Transfer(_from, _to, _value);    
        return true;
    }  
}