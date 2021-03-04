/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

contract MyContract{
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address=>uint256)) allowed;
    
    string private name;
    string private symbol;
    
    uint256 _totalSupply;
    
    event Transfer(
      address indexed _sender,
      address _reciever,
      uint256 _tokens
    );
    
    event Approval(
      address indexed _sender,
      address _delegate,
      uint256 _tokens
    );
    
    constructor(uint256 total, string memory _name, string memory _symbol) {
        // ICO
        _totalSupply = total;
        balances[msg.sender] = total;
        
        name = _name;
        symbol = _symbol;
    }
    
    function totalSupply() public view returns(uint256){
        return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view returns(uint256){
        return balances[tokenOwner];
    }
    
    function transfer(address reciever, uint256 numOfTokens) public returns(bool){
        
        require(numOfTokens <= balances[msg.sender], "Insufficient tokens");
        
        balances[msg.sender] = balances[msg.sender] - numOfTokens;
        balances[reciever] = balances[reciever] + numOfTokens;
        
        emit Transfer(msg.sender, reciever, numOfTokens);
        
        return(true);
    }
    
    function approve(address delegate, uint256 numOfTokens) public returns(bool){
        allowed[msg.sender][delegate] = numOfTokens;
        emit Approval(msg.sender, delegate, numOfTokens);
        return true;
    }
    
    function allowance(address owner, address delegate) public view returns(uint256){
        return allowed[owner][delegate];
    }
    
    function transferFrom(address owner, address buyer, uint256 numOfTokens) public returns(bool){
        
        require(numOfTokens <= balances[owner]);
        require (numOfTokens <= allowed[owner][msg.sender], "Owner doesn't allow this transection");
        
        balances[owner] = balances[owner] - numOfTokens;
        
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - numOfTokens;
        balances[buyer] = balances[buyer] + numOfTokens;
        emit Transfer(owner, buyer, numOfTokens);
        
        return true;
        
    }
    
}