/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.1;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// Contract address 0x56973a3E09fb6620D95aA14953A399CE0d99F648
// -----------------------------------

contract GSTGovernance {
    string public name;
    string public symbol;
    uint8 public decimals; 
    address public owner;
   
    uint256 private _totalSupply;
    
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;
    mapping(address => bool) private Minters;
    mapping(address => bool) private CanLogHash;
    mapping(bytes32 => bytes32) private Hashes;
    
    bytes32[] public HashList;


    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event AddMinter(address indexed minteraddr);
    event HashLogger(address indexed WhoGrantLogging, address indexed ToWhome, uint256 When);
    event HashRecording(bytes32 indexed hash, address indexed Logger, uint256 time);
    

    constructor() public  {
        owner = msg.sender;
        name = "G Secure Token";
        symbol = "GST";
        decimals= 18;
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
         decimals= 18;
        _totalSupply = _amount;
        
        balances[msg.sender] +=_amount;
        emit Transfer(address(0), msg.sender, _amount);
  }
  
   function SetLogger(address _addr, bool _TrueFalse) public OwnAndMint{
        CanLogHash[_addr]=_TrueFalse;
        emit HashLogger(msg.sender,_addr,now);
    }
    
     function CheckLogger(address _addr) public view returns(bool){
       return CanLogHash[_addr];
    }
  
    function SetMinter(address _addr, bool _TrueFalse) public OwnAndMint{
        Minters[_addr]=_TrueFalse;
        emit HashLogger(msg.sender,_addr,now);
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
    
    function Record_Hash(bytes32 _hash)public{
        require(CanLogHash[msg.sender]==true,'Sorry you have no permission to log the hash');
        Hashes[_hash]=_hash;
        emit HashRecording(_hash, msg.sender,now);
    }
    
    function Verify_Hash(bytes32 _hash)public view returns(bool){
      
      if(Hashes[_hash]== _hash){
          return true;
           
       }else{
            return false; 
         }
        
     }
   
 }