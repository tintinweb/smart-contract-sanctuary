/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

pragma solidity^0.8.0;

contract FirstToken {
    string public name = "UCP Token";
    string public symbol = "UCP";
    uint public decimal;
    uint256 public TotalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address=>mapping(address => uint256)) public Allowance;
    
    event Transfer(address indexed from,address indexed to,uint256 amount);
    event approveal(address indexed owner,address indexed spender,uint256 amount);
    
    constructor () public {
    decimal = 18;
    TotalSupply = 10000 * 10 ** uint256(decimal);
    balanceOf[msg.sender] = TotalSupply;
    }
    
    function transfer(address to,uint256 amount) public {
     require (to != address(0),"Invalid Address");
     balanceOf[msg.sender] -= amount;
     balanceOf[to] += amount;
     emit Transfer(msg.sender,to,amount);
    }
    
    function approve(address spender,uint256 amount) public {
        Allowance[msg.sender][spender] = amount;
        emit approveal(msg.sender,spender,amount);
    }  
    
    function transferFrom(address from,address to,uint256 amount) public {
        require(amount <= balanceOf[from]);
        require(amount <= Allowance[from][msg.sender]);
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        Allowance[to][msg.sender] -= amount;
        emit Transfer(from,to,amount);
    }
}