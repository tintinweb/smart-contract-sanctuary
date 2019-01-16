pragma solidity ^0.4.20;

contract ERC20Interface {

    string public  name;
    string public  symbol;
    uint8 public  decimals;  // 18 is the most common number of decimal places
    // 0.0000000000000000001  个代币
    uint public totalSupply;




    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function approve(address spender, uint value) public returns (bool success);

    function transfer(address to, uint value) public returns (bool success);
    function transferFrom(address from, address to, uint value) public returns (bool success);


    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed tokenOwner, address indexed spender, uint value);
}

contract ERC20 is ERC20Interface{
    //mapping(address =>value) public balanceOf;
    mapping(address=>uint256)public balanceOf;
    mapping(address =>mapping(address => uint256))  allowed;
    
    constructor(string _name) public{
    name = _name;
    symbol = "TJT";
    decimals = 0;
    totalSupply = 100000;
    balanceOf[msg.sender]=totalSupply;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining){
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint value) public returns (bool success){
        allowed[msg.sender][spender]=value;
        
        emit Approval(msg.sender,spender,value);
        
        return true;
    }

    function transfer(address to, uint value) public returns (bool success){
        require(to !=address(0));
        
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to]+value >= value);
        
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender,to,value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns (bool success){
        
        require(to !=address(0));
        
        require(allowed[from][msg.sender] >= value);
        
        require(balanceOf[from] >= value);
        require(balanceOf[to]+value >= value);
        
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowed[from][msg.sender]-=value;
        
        emit Transfer(msg.sender,to,value);
        return true;
    }


    
}