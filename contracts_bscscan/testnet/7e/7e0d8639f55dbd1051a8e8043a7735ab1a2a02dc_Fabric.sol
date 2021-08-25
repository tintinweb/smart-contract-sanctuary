/**
 *Submitted for verification at BscScan.com on 2021-08-25
*/

pragma solidity ^0.4.24;

contract ERC20Interface {
    
    function totalSupply() public constant returns(uint256);
    function balanceOf(address who) public constant returns(uint256);
    function allowance(address owner, address spender) public constant returns(uint remaining);
    function transferFrom(address from, address to, uint256 value) public returns(bool success);
    function transfer(address to, uint256 value) public returns(bool success);
    function approve(address spender, uint256 value) public returns(bool success);
   
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _owner,uint256 _value);
    
}


  
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }


  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  
  

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
  
  function safeDiv(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
 
}

 
contract ApproveAndCallFallBack {
    
   function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract Fabric is ERC20Interface, SafeMath{
    
    address owner;
    string  public name = "Fabric Finance";
    string  public symbol = "FAB";
    uint8   public decimals = 18;
    uint256 public totalSupply;
    uint256 public maxSupply =  15*10**6 *10**uint(decimals);
    address public tokenSaleAddress; // sets crowdsale address
 
     
    mapping(address => uint256) balances;
    mapping(address => mapping(address=>uint256)) public allowance;
    mapping(address => bool) admins;
    mapping(address => bool) frozenAccounts;
    
  
   // bool internal released = false;
    
    ////modifier isReleased(){
       // if(!released){
           // revert();
       //}
       // _;
    //}
  
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyAdmin(){
        
        require(admins[msg.sender] == true);
        _;
    }
    
   
    event frozenAccount(address target, bool frozen);
    
   
    /*administrative functions for transfer of ownership for
    * setting administrators
    */
    
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
    
    function isAdmin(address account) onlyOwner public view returns(bool){
        
        return admins[account];
    }
    
    function addAdmin(address account) onlyOwner public{
        require(account != address(0) && !admins[account]);
        admins[account] = true;
    }
    function removeAdmin(address account) onlyOwner public{
        require(account != address(0) && (admins[account] = true));
        admins[account] = false;
    }
    
    
    constructor(uint256 initialSupply) public{
        
        owner = msg.sender;
        mint(owner, initialSupply);
    
    }
    
    function setTokenSaleAddress(address _tokenSaleAddress) onlyOwner public returns(uint256){
    tokenSaleAddress =  _tokenSaleAddress;
    mint(tokenSaleAddress, 4*10**6 *10**uint(decimals));
    
     
    }
    
     //function release() onlyOwner public{
      //  released = true;
    //}
    
    function mint(address _to, uint256 _mintedAmount) onlyOwner public {
        
        balances[_to] += _mintedAmount;
        totalSupply = SafeMath.safeAdd(totalSupply, _mintedAmount);
        emit Transfer(owner, _to, _mintedAmount);
    }
   
    function burn(uint256 value) public onlyOwner returns(bool success){
        require(balances[msg.sender] >= value );
        balances[msg.sender] = SafeMath.safeSub(balances[msg.sender],value);
        totalSupply = SafeMath.safeSub(totalSupply,value);
        emit Burn(msg.sender, value);
        return true;
    }
    
    function freezeAccount(address target,bool freeze) onlyOwner public {
        
        frozenAccounts[target] = freeze;
        emit frozenAccount(target,freeze);
    }
  
    
    //ERC20 interface implementations
    
    function totalSupply() public constant returns (uint256) {
        
        return totalSupply - balances[address(0)];
    }
    
    function balanceOf(address _owner) public view returns(uint256){
        
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _amount)  public returns(bool success){
        
        require(_to != 0x0);
        require(balances[msg.sender] >= _amount);
        require(balances[_to] + _amount >= balances[_to]);
        
       
        balances[msg.sender]= SafeMath.safeSub(balances[msg.sender], _amount);
        balances[_to] = SafeMath.safeAdd(balances[_to], _amount);
        emit Transfer(msg.sender,_to, _amount);
        return true;
        
    }
    
    function approve(address _spender, uint256 _amount) public returns(bool success){
        allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender,_spender,_amount);
        return true;
        
    }
    
    function allowance(address _owner, address _spender) public view returns(uint256 remaining){
        
        return allowance[_owner][_spender];
        
    }
    
    function transferFrom(address _from, address spender, uint256 _amount) public returns(bool success){
        
       
        require(spender != 0x0);
        require(balances[_from] >= _amount);
        require(balances[spender] + _amount >= balances[spender]);
        require(_amount <= allowance[_from][msg.sender]);
        
       
        balances[_from] = SafeMath.safeSub(balances[_from], _amount);
        balances[spender] = SafeMath.safeAdd(balances[spender], _amount);
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _amount);
       
        emit Transfer(_from, spender, _amount);
        return true;
        
    }
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowance[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    
    
    function () public payable {
    revert();
    }
    
}