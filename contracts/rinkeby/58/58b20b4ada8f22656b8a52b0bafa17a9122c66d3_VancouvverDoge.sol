/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-17
*/

pragma solidity ^0.8.2;

interface ERC20Interface {
    function balanceOf(address whom) view external returns (uint);
}

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract VancouvverDoge is owned {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 21000000 * 10 ** 18;
    uint public currentSupply=0;
    uint public claimTokens=10000;
    string public name = "Vancouver Doge";
    string public symbol = "V DOGE";
    uint public decimals = 18;
    address addresstoken;
    bool public isMintingPaused;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor(address jeju, uint claimnos) {
        addresstoken=jeju;
        claimTokens=claimnos;
        isMintingPaused = false;
        //balances[msg.sender] = totalSupply;
    }
    
    function mintToken() public 
    {
       require (!isMintingPaused);
         
        //check if person owns jeju
       uint tokensowned= queryERC20Balance(addresstoken,msg.sender);
       uint tokensownedcur= queryERC20Balance(address(this),msg.sender);
       
       if(tokensowned>0 && tokensownedcur==0)
       {
           
           currentSupply+=claimTokens;
           if(currentSupply<=totalSupply)
           {
               balances[msg.sender]=claimTokens;
           }
           
       }
    }
    

    function pauseMinting(bool isPaused) onlyOwner public  
    {
        isMintingPaused = isPaused;
    } 

    
    function changeAddress(address addresstokenstr) onlyOwner public 
    {
        addresstoken=addresstokenstr;
    }
    
    function queryERC20Balance(address _tokenAddress, address _addressToQuery) view public returns (uint) {
        return ERC20Interface(_tokenAddress).balanceOf(_addressToQuery);
    }
    
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance to low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance to low');
        require(allowance[from][msg.sender] >= value, 'allowance to low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}