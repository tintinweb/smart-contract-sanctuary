/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

pragma solidity 0.5.17;

contract Token {
    mapping(address=> uint) public balances;
    //0x93d0C7BD078265c4ffD803af8316cD39aF1498ca => 5000000
   //0xCB050b59f99C17EB817cF72675D99B52c24a0DC0 => 5000000
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalsupply = 100000000 * 10 ** 18;
    string public name = "shibuae";
    string public symbol = "ashib";
    uint public decimals = 18;
   
     
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() public {
    balances[msg.sender] = totalsupply;}
   
   
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >=value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
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