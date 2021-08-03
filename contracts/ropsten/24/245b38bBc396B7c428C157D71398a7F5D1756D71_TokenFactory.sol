/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

pragma solidity ^0.8.4;

contract TokenFactory {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping (address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfered(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event created(string tknname, string tknsymbol, uint8 tkndecimals, uint256 tkntotalSupply);
    
    constructor (string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) public  {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;
        
        emit created(_name, _symbol, _decimals, _totalSupply);
    }
    
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfered(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        emit Transfered(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}