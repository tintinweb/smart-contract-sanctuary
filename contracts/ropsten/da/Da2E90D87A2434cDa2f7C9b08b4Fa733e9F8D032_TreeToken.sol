/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity ^0.4.16;

contract TreeToken{
    
    string public name = "Tree Token";
    string public symbol = "TREE";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 1000000;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _tokens);
    
    event Approval(address indexed _owner, address indexed _spender, uint _tokens);
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    function totalSupply(uint256 _initialSupply) public view returns (uint256){
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
    }
    
    function transfer(address _to, uint256 _tokens) public returns (bool success) {
        require(balanceOf[msg.sender] >= _tokens);
        balanceOf[msg.sender] -= _tokens;
        balanceOf[_to] += _tokens;
        
        Transfer(msg.sender, _to, _tokens);
        
        return true;
    }
    
    function approve(address _spender, uint _tokens)  public returns (bool) {
        
        allowance[msg.sender][_spender] = _tokens;
        
        Approval(msg.sender, _spender, _tokens);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _tokens) public returns (bool) {
        
        require(_tokens <= balanceOf[_from]);
        require(_tokens <= allowance[_from][msg.sender]);
        
        balanceOf[_from] -= _tokens;
        balanceOf[_to] += _tokens;
        
        allowance[_from][msg.sender] -= _tokens;
        
        Transfer(_from, _to, _tokens);
        return true;
        
    }
    
    
}