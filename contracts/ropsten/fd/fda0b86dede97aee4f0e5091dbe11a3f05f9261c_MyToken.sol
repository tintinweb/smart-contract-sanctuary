/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

pragma solidity ^0.8.7;

interface ERC20
{
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
}
contract MyToken is ERC20
{
    string public name = "MyToken";
    string public symbol = "MY";
    uint8 public decimals = 0;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
   
    uint256 totalSupply_= 1500;
    address admin;
   
    constructor()
    {
       balances[msg.sender] = totalSupply_;
       
       admin = msg.sender;
    }
    
    function totalSupply() public view returns (uint256)
    {
        return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint256)
    {
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint num ) public returns (bool)
    {
        require(balances[msg.sender]>=num);
        balances[msg.sender]-= num;
        balances[to]+= num;
        emit Transfer(msg.sender, to, num);
        return true;
    }
    modifier onlyAdmin
    {
        require(msg.sender == admin, "only admin can run this function");
        _;
    }
    
    function mint(uint256 _qty)public onlyAdmin returns (uint256)
    {
        totalSupply_ += _qty;
        balances[msg.sender]+= _qty;
        return totalSupply_ ;   
    }
    
    function burn(uint256 _qty)public onlyAdmin returns (uint256)
    {
        totalSupply_ -= _qty;
        balances[msg.sender]-= _qty;
        return totalSupply_ ;   
    }
    
    function allowance (address _owner, address _spender) public view returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
    
    function approve (address _spender, uint256 _value) public returns(bool success)
    {
        allowed[msg.sender][_spender]= _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom (address _from, address _to, uint256 _value) public returns (bool success)
    {
        uint256 allowance1 = allowed[_from][msg.sender];
        require (balances[_from]>=_value && allowance1 >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer (_from, _to, _value);
        return true;
    }
}