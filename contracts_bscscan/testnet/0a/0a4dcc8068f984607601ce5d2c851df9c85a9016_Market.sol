/**
 *Submitted for verification at BscScan.com on 2021-10-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.0 <0.9.0;


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

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}

contract ERC20TOKEN is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        name = "Arash"; // CHANGEME, token name ex: Bitcoin
        symbol = "SAM"; // CHANGEME, token symbol ex: BTC
        decimals = 18; // token decimals (ETH=18,USDT=6,BTC=8)
        _totalSupply = 10000 * 10 ** 18 ; // total supply including decimals

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
}

contract Market {
    uint ID  = 0 ;
    
    ERC20Interface public token;
    
    struct Order {
        uint _ID ;
        address payable walletAddress ;
        uint tokenAmount;
        uint amount;
        address destination;
    }
    
    
    mapping (uint => Order) public orders ;
    
      constructor() public {

        token = ERC20TOKEN(address(0xB3fE673afF2c523A4FF52fE3036Ea1a988d8a3D3));
        
    }

    
    function addOrder (uint _amount , uint256 _tokenAmount ) public {
        ID++;
        orders[ID]._ID = ID;
        orders[ID].walletAddress = msg.sender;
        orders[ID].amount = _amount;
        orders[ID].tokenAmount = _tokenAmount;
    }
    
    function transferFrom (uint _id)  public payable{
        // @dosc set address destination  
        
        orders[_id].destination = msg.sender;
        
        // @dosc send ether from destination address wallet to contract 
        
        address(this).call.value(msg.value);
        
        // @dosc send ether from contract to wallet order creator
        
        orders[_id].walletAddress.transfer(address(this).balance);
        
        // @dosc send ERC20TOKEN from wallet sender to destination address walletl
        
        token.transferFrom(orders[_id].walletAddress, orders[ID].destination,  orders[ID].tokenAmount );
    }
    
    // @dosc Send ether from msg.sender to contract address
    
    function showOrderWalletAddress (uint _id) public view returns(address){
        return orders[_id].walletAddress;
    }

    function showOrderDestinationAddress (uint _id) public view returns(address){
        return orders[_id].destination;
    }
    
    // @dosc getBalance contract address
    
     function balanceOf () public  view returns(uint){
        return address(this).balance;
    }
    
    // @dosc getBalance Token 
    
     function getBalance(address tokenOwner) public view returns (uint balance) {
         return token.balanceOf(tokenOwner);
    }
    
}