/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

/*
 * Buy Coin (BC)
 *
 * 1. It is called Buy Coin (BC)， so that everybody will buy for fun.
 * 2. Trade with this smart contract at the etherscan interface.  
 * 3. The price will always increase after each buy if there is no other market. 
 *    First buy 0.001ETH = 1M BC, second buy 0.001ETH = 1M-1 BC, until a fixed price 0.001ETH = 1BC. 
 * 4. Max buy: 0.017 ETH.
 * 5. Selling at the current price will always be hornored when there is sufficient ETH in the contract. 
 * 6. Buy and havve fun!
 */ 
 
pragma solidity ^0.5.17;


contract ERC20Interface { 
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint rawAmt) public returns (bool success);
    function approve(address spender, uint rawAmt) public returns (bool success);
    function transferFrom(address from, address to, uint rawAmt) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint rawAmt);
    event Approval(address indexed tokenOwner, address indexed spender, uint rawAmt);
}


contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a); 
        c = a - b; 
    } 
        
    function safeMul(uint a, uint b) internal pure returns (uint c) { 
        c = a * b; 
        require(a == 0 || c / a == b); 
    } 
        
    function safeDiv(uint a, uint b) internal pure returns (uint c) { 
        require(b > 0);
        c = a / b;
    }
}

contract BC is ERC20Interface, SafeMath{
    string public constant name = "Buy Coin";
    string public constant symbol = "BC";
    uint8 public constant decimals = 18; 
    uint public constant _totalSupply = 1*10**12*10**18; 
    uint public buyID = 0; 
    uint rewardPool = 0;


    mapping(address => uint) balances;       
    mapping(address => mapping(address => uint)) allowed;
    event BuyBC(uint ETHAmt, uint BCAmt);
    event SellBC(uint BCAmt, uint ETHmt);
 
    constructor() public { 
        balances[address(this)] = _totalSupply; 
        emit Transfer(address(0), address(this), _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }


     // The contract does not accept ETH
    function () external payable  {
        revert();
    }  

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];

    }
    
    

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint rawAmt) public returns (bool success) {
        allowed[msg.sender][spender] = rawAmt;
        emit Approval(msg.sender, spender, rawAmt);
        return true;
    }

    function transfer(address to, uint rawAmt) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], rawAmt);
        balances[to] = safeAdd(balances[to], rawAmt);
        emit Transfer(msg.sender, to, rawAmt);
        return true;
    }

    
    function transferFrom(address from, address to, uint rawAmt) public returns (bool success) 
    {
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], rawAmt);
        balances[from] = safeSub(balances[from], rawAmt);
        balances[to] = safeAdd(balances[to], rawAmt);
        emit Transfer(from, to, rawAmt);
        return true;
    }    
    

    function BCPrice() 
    public
    view
    returns (uint)
    {
         uint nBC;
         
         if(buyID < 1000000)
                nBC = 1000000-buyID;
         else
                nBC = 1;
        
         return nBC*1000;

    }
    
    function buy()
    public
    payable 
    returns (bool)
    {
        
        require(msg.value <= 17*10**15, "The max buy is 0.017 ETH");
        
        buyID = buyID + 1;
        
        uint BCAmt = BCPrice()*msg.value; 
        balances[address(this)] = safeSub(balances[address(this)], BCAmt);
        balances[msg.sender] = safeAdd(balances[msg.sender], BCAmt);
        emit Transfer(address(this), msg.sender, BCAmt);
        emit BuyBC(msg.value, BCAmt);
        return true;
    }
    
    function sell(uint BCAmt)
    public 
    returns(bool)
    {
        uint amtETH = safeDiv(BCAmt, BCPrice());
        balances[msg.sender] =  safeSub(balances[msg.sender], BCAmt);
        balances[address(this)] = safeAdd(balances[address(this)], BCAmt);
        msg.sender.transfer(amtETH);
        emit Transfer(msg.sender, address(this), BCAmt);
        emit SellBC(BCAmt, amtETH);
        return true;
    }
}