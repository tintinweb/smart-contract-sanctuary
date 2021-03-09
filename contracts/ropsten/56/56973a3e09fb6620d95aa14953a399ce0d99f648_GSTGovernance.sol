/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// -----------------------------------

contract GSTGovernance {
    string public name;
    string public symbol;
    //uint8 public decimals; 
    address public owner;
    
    uint256 private _totalSupply;
    
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;
    mapping(address => bool) private Minters;
    mapping(address => bool) private CanLogHash;


    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event AddMinter(address indexed minteraddr);
    event HashLogger(address indexed canlog);



    constructor() public  {
        owner = msg.sender;
        name = "G Secure Token";
        symbol = "GST";
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    modifier OwnAndMint(){
       require(msg.sender == owner ||  Minters[msg.sender]==true , 'you are not owner nor trusted');
        _;
    }
    
     function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) internal pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) internal pure returns (uint c) { require(b > 0);
        c = a / b;
    }
    
    
    
    
  function mint(uint _amount)public OwnAndMint{
        name = "G Secure Token";
        symbol = "GST";
        _totalSupply = _amount;
        
        balances[msg.sender] +=_amount;
        emit Transfer(address(0), msg.sender, _amount);
  }
  
   function SetLogger(address _addr, bool _TrueFalse) public OwnAndMint{
        CanLogHash[_addr]=_TrueFalse;
        emit HashLogger(_addr);
    }
    
     function CheckLogger(address _addr) public view returns(bool){
       return CanLogHash[_addr];
    }
  
    function SetMinter(address _addr, bool _TrueFalse) public OwnAndMint{
        Minters[_addr]=_TrueFalse;
        emit HashLogger(_addr);
    }
    
     function CheckMinter(address _addr) public view returns(bool){
       return Minters[_addr];
    }
    
     function  totalSupply()  public view 	returns (uint) 
    {
        return balances[msg.sender];//a _totalSupply; //- balances[address(0)];
    }
    
    
    function balanceOf(address tokenOwner)  public view returns (uint balance) 
    {
        return balances[tokenOwner];
    }

  
    function transfer(address to, uint tokens) 	public OwnAndMint returns(bool success){
        //require(msg.sender == owner || Trusted[msg.sender]==true,'you are not an owner ask to be one');
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
    
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

 }