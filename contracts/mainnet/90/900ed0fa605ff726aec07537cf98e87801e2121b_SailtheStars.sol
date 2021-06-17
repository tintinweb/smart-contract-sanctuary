/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; 
    } 
    function safeMul(uint a, uint b) public pure returns (uint c) { 
        c = a * b; require(a == 0 || c / a == b); 
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) { 
        require(b > 0);
        c = a / b;
    }

}

// ----------------------------------------------------------------------------
// AddOns: Minting, Burning, DisableBurning, DisableMinting, Roles, Token Retrieval
// ----------------------------------------------------------------------------

contract Extras { 
    
    function Mint(address to, uint _mintage) public returns (bool success);
    function Burn(address from, uint _burnage) public returns (bool success);
    function DisableMinting() public returns (bool success);
    function DisableBurning() public returns (bool success);
    function SetSafety(uint8 position, address from) public returns (bool success);
    function GetSafetyStatus() public view returns (uint _safety);
    function GetMintingStatus() public view returns (bool _mintingstatus);
    function GetBurningStatus() public view returns (bool _burningstatus);
    
    function addAdmin(address manager) public returns (bool success);
    function RemoveAdmin(address newadmin) public returns (bool success);
    function GetRole(address user) public view returns(string memory);
    
// To retrieve native tokens accidentally sent to the contract and send them somewhere. 
    function RetrieveTokens(address to, uint amount) public returns (bool success);
    function GetTokenBalance() public view returns (uint balance);
    
}

// ----------------------------------------------------------------------------
//Ether Transfers, for managing Ether sent to the contract directly or accidentally
// ----------------------------------------------------------------------------
   
contract EtherTransactions {
     function () payable external {} 
     function sendEther(address payable recipient, uint256 amount) public returns (bool success);
     function getBalance() public view returns (uint);
}


contract SailtheStars is ERC20Interface, SafeMath, Extras, EtherTransactions {
    string public name;
    string public symbol;
    uint8 public decimals; 
    bool MintingAllowed = true;
    bool BurningAllowed = true;
    uint SafetyKey = 1;
    uint256 public _totalSupply;
    
    address public _sailthestars;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) admins;
     
    constructor() public {
        name = "SAIL";
        symbol = "SAIL";
        decimals = 18;
        _totalSupply = 8888888000000000000000000;
        _sailthestars = msg.sender;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
 
// ----------------------------------------------------------------------------
// Minting and Burning additional tokens, 
// only operable while MintingAllowed and BurningAllowed are true
// ----------------------------------------------------------------------------   
    
    
    function Mint(address to, uint _mintage) public returns (bool success)
    {
        require(MintingAllowed == true);
        require(msg.sender == _sailthestars || admins[msg.sender] == true);
        _totalSupply = safeAdd(_totalSupply, _mintage);
        balances[to] = safeAdd(balances[to], _mintage);
        emit Transfer(address(0), to, _mintage);
        return true;
     }
     
     function Burn(address from, uint _burnage) public returns (bool success)
    {
        require(BurningAllowed == true);
        require(msg.sender == _sailthestars || admins[msg.sender] == true);
        _totalSupply = safeSub(_totalSupply, _burnage);
        balances[from] = safeSub(balances[from], _burnage);
        emit Transfer(from, address(0), _burnage);
        return true;
    }
   
// ----------------------------------------------------------------------------
// Permnanantly disable minting or burning
// operations cannot be reversed
// ----------------------------------------------------------------------------   

     function DisableMinting() public returns (bool success)
    {
        require(SafetyKey == 0);
        require(msg.sender == _sailthestars || admins[msg.sender] == true);
        
        MintingAllowed = false;
        SafetyKey=1;
        return true;
    }
    
    function DisableBurning() public returns (bool success)
    {
        require(SafetyKey == 0);
        require(msg.sender == _sailthestars || admins[msg.sender] == true);
        BurningAllowed = false;
        SafetyKey=1;
        return true;
    }
    
   
// ----------------------------------------------------------------------------
// Enables/Disables/Reports Safety Key which allows access to DisableMinting()/DisableBurning()
// This is to prevent the accidental calling of these functions with major consequences.
// ----------------------------------------------------------------------------   
    
     function SetSafety(uint8 position, address from) public returns (bool success)
    {
        require(msg.sender == from);
        require(msg.sender == _sailthestars || admins[msg.sender] == true);
        
        SafetyKey = position;
        return true;
        
    }
    
// ----------------------------------------------------------------------------
// Functins for Get Minting / Burning Status
// ----------------------------------------------------------------------------   

     function GetSafetyStatus() public view returns (uint _safety)
    {
        return SafetyKey;
    }
    
     function GetMintingStatus() public view returns (bool _mintingstatus)
    {
        return MintingAllowed;
    }
    
    function GetBurningStatus() public view returns (bool _burningstatus)
    {
        return BurningAllowed;
    }
    
// ----------------------------------------------------------------------------
// Functions for adding admins and managers
// ----------------------------------------------------------------------------       
    
    
     function addAdmin(address newadmin) public returns (bool success) {
       require(msg.sender == _sailthestars || admins[msg.sender] == true);
       admins[newadmin] = true;
       return true;
    }
    
     function RemoveAdmin(address newadmin) public returns (bool success) {
       require(msg.sender == _sailthestars || admins[msg.sender] == true);
       admins[newadmin] = false;
       return true; 
    }
    
    function GetRole(address user) public view returns(string memory) { 
       if(user == _sailthestars) { return "User is Sail the Stars"; }
       if(admins[user]==true) { return "User is an admin."; }
       if(admins[user]==false) { return "User has no permissions."; }
    }
    
// ----------------------------------------------------------------------------
// For sending Ether accidentally sent to the contract
// ----------------------------------------------------------------------------          
    
    function getBalance() public view returns (uint)
     {
        return address(this).balance;
     }
     
    function sendEther(address payable recipient, uint256 amount) public returns (bool success) {
        require(msg.sender == _sailthestars || admins[msg.sender] == true);
        recipient.transfer(amount);
        return true;
    }
    
// ----------------------------------------------------------------------------
// For retrieving Tokens accidentally sent to the contract
// ----------------------------------------------------------------------------    
    
    function GetTokenBalance() public view returns (uint balance) {
        return balances[address(this)];
    }
    
    function RetrieveTokens(address to, uint amount) public returns (bool success) {
        require(msg.sender == _sailthestars || admins[msg.sender] == true); 
        require(to != address(this));
        balances[address(this)] = safeSub(balances[address(this)], amount);
        balances[to] = safeAdd(balances[to], amount);
        return true; 
    }

    
}