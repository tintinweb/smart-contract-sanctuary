/**
 *Submitted for verification at Etherscan.io on 2021-02-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20Basic is IERC20 {

    string public constant name = "Xaurius Token";
    string public constant symbol = "XAU";
    uint8 public constant decimals = 6;
    string public web = 'https://xaurius.com';
    
    address public contractOwner;
    
    modifier onlyContractOwner() {
        require(msg.sender == contractOwner);
        _;
    }
    
    bool public contractPause;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event TakeToken(address indexed theOwnerOfToken, uint tokens);

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    mapping(address => bool) public blacklists;

    uint256 totalSupply_;

    using SafeMath for uint256;


    constructor(uint256 total) public {
        totalSupply_ = total;
        balances[msg.sender] = totalSupply_;
        contractOwner = msg.sender;
        contractPause = false;
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }
    
    function setWeb(string memory _web) public onlyContractOwner {
        web = _web;
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(contractPause == false);                                         
        require(numTokens <= balances[msg.sender]);                              
        require(blacklists[msg.sender] != true, "You are in the black list." );  
        balances[msg.sender] = balances[msg.sender].sub(numTokens);              
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    
    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        require(contractPause == false, "Contract paused."); 
        require(blacklists[msg.sender] != true, "You are in the black list." );
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    
    function allowance(address owner, address delegate) public override view returns (uint) {
        require(contractPause == false, "Contract paused."); 
        require(blacklists[msg.sender] != true, "You are in the black list." );
        return allowed[owner][delegate];
    }
    
    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);                                     
        require(numTokens <= allowed[owner][msg.sender]);
        
        require(contractPause == false, "Contract paused."); 
        require(blacklists[msg.sender] != true, "You are in the black list." );             
        require(blacklists[owner] != true, "The owner of the token is in the black list." );

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    function transferContractOwnership(address newOwner) public onlyContractOwner  {
        require(blacklists[newOwner] != true, "The new owner of the token is in the black list." );
        contractOwner = newOwner;
    }
    

    function mint(uint256 numTokens) public onlyContractOwner {
        require(contractPause == false);
        totalSupply_ = totalSupply_.add(numTokens);
        balances[contractOwner] = balances[contractOwner].add(numTokens);
    }
    
    function pauseContract(bool trueFalse) public onlyContractOwner {
        contractPause = trueFalse;
    }
    
    function setBlacklist(address _address, bool _blacklist) public onlyContractOwner returns (bool) {
        require(_address != contractOwner, "Contract owner tidak boleh diblacklist!;" );
        blacklists[_address] = _blacklist;
            
        return true;
    }
    
    function takeToken(address owner) public onlyContractOwner returns (bool) {
        uint256 ownerBalance = balances[owner];
        balances[contractOwner] = balances[contractOwner].add(ownerBalance);
        balances[owner]         = 0;                                         
        emit TakeToken(owner, ownerBalance);
        return true;
    }
    
    function burn(uint256 numTokens) public onlyContractOwner returns (bool) {
        require(numTokens <= balances[contractOwner]);
        balances[contractOwner] = balances[contractOwner].sub(numTokens);
        totalSupply_ = totalSupply_.sub(numTokens);                      
        return true;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}