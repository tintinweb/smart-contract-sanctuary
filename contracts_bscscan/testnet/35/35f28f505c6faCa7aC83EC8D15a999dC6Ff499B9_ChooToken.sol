/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

contract ChooToken {
    mapping(address => uint) public tokenBalances;
    mapping(address => mapping(address => uint)) public tokenAllowance;
    uint public numberOfToken = 5500000000 * 10 ** 18;
    string public nameOfToken = "ChooToken";
    string public tokenSymbol = "CHO";
    uint public tokenDecimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor(){
        tokenBalances[msg.sender] = numberOfToken;
    }
    
    function balanceOf(address owner) public view returns(uint){
        return tokenBalances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool){
        require(balanceOf(msg.sender) >= value, "balance to low");
        tokenBalances[to] += value;
        tokenBalances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool){
        require(balanceOf(from) >= value, "balance too low ");
        require(tokenAllowance[from][msg.sender] >= value, "tokenAllowance too low");
        tokenBalances[to] += value;
        tokenBalances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool){
        tokenAllowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}