/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

pragma solidity 0.8.6;




contract C_Token{
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    string public name;
    string public symbol;
    uint public totalSupply;
    mapping(address=>uint) public balanceOf;
    mapping(address=>mapping(address => uint256)) public allowance;
    
    constructor(uint _initialSupply, string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
        
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    
    function transfer(address _to, uint _value) public returns(bool success){
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value); // Log Transfer
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value)public returns (bool success){
        uint256 allowed = allowance[_from][msg.sender];
        require(balanceOf[_from] >= _value && allowed >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        if (allowed < MAX_UINT256) {
            allowance[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
        
    }
    
    function approve(address _spender, uint _value) public returns (bool success){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    
}