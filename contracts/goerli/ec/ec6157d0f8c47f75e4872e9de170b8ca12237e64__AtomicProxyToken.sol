/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

pragma solidity ^0.8.0;


/*
This contract allows anyone to atomically mutate ERC20 tokens to a new token and back at a 1:1 ratio.  
This contract is atomic, decentralized, and has no owner.
*/
 

abstract contract ERC20Basic {
  function totalSupply() virtual public view returns (uint256);
  function balanceOf(address who) virtual public view returns (uint256);
  function transfer(address to, uint256 value) virtual public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

abstract contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    virtual public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    virtual public returns (bool);

  function approve(address spender, uint256 value) virtual public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

abstract contract ApproveAndCallFallBack {

    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;

}
 

contract _AtomicProxyToken {
    
  
    address public _originalToken;

    string public name;
    string public symbol;
    uint8  public decimals = 8;
    uint private _totalSupply;
    
    uint public supplyFactor = 1000000;

    event  Approval(address src, address ext, uint amt);
    event  Transfer(address src, address dst, uint amt);
    event  Deposit(address dst, uint amt);
    event  Withdrawal(address src, uint amt);

    mapping (address => uint)                       public  balances;
    mapping (address => mapping (address => uint))  public  allowance;
  

   constructor(string memory tokenName, string memory tokenSymbol, address mutatingToken){
       name = tokenName;
       symbol = tokenSymbol;
       _originalToken = mutatingToken;
       
       
   }    

    /**
     *  
     * @dev Deposit original tokens, receive proxy tokens 
     * @param amount Amount of protocol tokens to charge
     */
    function depositTokens(address from, uint amount) public returns (bool)
    {
        require( amount > 0 );
        
        require( ERC20( _originalToken ).transferFrom( from, address(this), amount) );
            
        balances[from] = balances[from] + (amount * supplyFactor);
        _totalSupply = _totalSupply + (amount * supplyFactor);
        
        emit Transfer(address(this), from, (amount * supplyFactor));
        
        return true;
    }



    /**
     * @dev Withdraw original tokens, dissipate proxy tokens 
     * @param amount Amount of protocol tokens to charge
     */
    function withdrawTokens(uint amount) public returns (bool)
    {
        address from = msg.sender;
        require( amount > 0 );
        
        balances[from] = balances[from] - (amount * supplyFactor);
        _totalSupply = _totalSupply - (amount * supplyFactor);
        emit Transfer(from, address(this), (amount * supplyFactor));
            
        require( ERC20( _originalToken ).transfer( from, amount) );
        return true;
    }
    
    
     /**
     * Do not allow Ether to enter 
     */
     fallback()  external payable  
    {
        revert();
    }
    
    
     function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function approve(address ext, uint amt) public returns (bool) {
        allowance[msg.sender][ext] = amt;
        emit Approval(msg.sender, ext, amt);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool) {
        address from = msg.sender;
        balances[from] = balances[from] - (tokens);
        
        balances[to] = balances[to] + (tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


     function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from] - (tokens);
        allowance[from][msg.sender] = allowance[from][msg.sender] - (tokens);
        balances[to] = balances[to] + (tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {

        allowance[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);

        return true;

    }
    
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public returns (bool success) {
        
        require( token == _originalToken );
        
        require( depositTokens(from, tokens) );

        return true;

     }

}