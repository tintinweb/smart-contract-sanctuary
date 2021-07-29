/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

pragma solidity ^0.4.24;



contract ERC20Interface2 {
  
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    

    function transfer(address _to,uint256 _value) public returns(bool success);
    
    function transferFrom(address _from,address _to,uint256 _value) public returns(bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    
        // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    
    
} 


contract Erc20Impl is ERC20Interface2 {
    
    mapping(address =>uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowed;
    
    constructor(string _name,string _symbol,uint8 _decimals,uint _totalSupply){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;  
        balanceOf[msg.sender] = _totalSupply;
    }
    
    function transfer(address _to,uint256 _value) public returns(bool success){
        require(_to != address(0) );
        require(balanceOf[msg.sender] >= _value );
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender,_to,_value);
        return true;
    }
    
    function transferFrom(address _from,address _to,uint256 _value) public returns(bool success){
        
        require(balanceOf[_from] >= _value );
        require(allowed[msg.sender][_from] >=_value );
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowed[msg.sender][_from] -= _value;
        emit Transfer(_from,_to,_value);
        return true;
    }


    function approve(address _spender, uint256 _value) public returns (bool success){
        emit Approval(msg.sender,_spender, _value);
        allowed[msg.sender][_spender] =_value;
        return true;
    }


    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }
    
}