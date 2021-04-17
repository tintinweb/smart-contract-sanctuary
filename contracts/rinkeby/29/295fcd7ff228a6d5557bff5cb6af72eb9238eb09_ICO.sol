/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

pragma solidity ^0.4.25;

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}



contract ICO is ERC20Interface{
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint public decimals;
    uint public bonusEnds;
    uint public icoEnds;
    uint public icoStarts;
    uint public allContributers;
    uint allTokens;
    address admin;
    mapping (address => uint) public balances;
    mapping(address => mapping(address => uint)) allowed;

    function ICO () public {
        name = "Demo Coin";
        decimals = 18;
        symbol = "DC";
        bonusEnds = now + 2 weeks;
        icoEnds = now + 4 weeks;
        icoStarts = now;
        allTokens = 100000000000000000000 * 100;   // equals 100 ether * 100 DC
        admin = (msg.sender);
        balances[msg.sender] = allTokens;
    }


    // 100 DC token == 1 Ether
    function buyTokens() public payable {

        uint tokens;

        if(now <= bonusEnds) {
            tokens =  msg.value.mul(125);  // 25% bonus
        }else {
            tokens =  msg.value.mul(100); // no bunus
        }

        balances[msg.sender] = balances[msg.sender].add(tokens);
        allTokens = allTokens.add(tokens);
        Transfer(address(0), msg.sender, tokens);

        allContributers++;
    }



    // needed for erc20 interface
    function totalSupply() public constant returns (uint) {
        return allTokens;
    }
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    // --->



    function myBalance() public constant returns (uint){
        return (balances[msg.sender]);
    }

    function myAddress() public constant returns (address){
        address myAdr = msg.sender;
        return myAdr;
    }

    function endSale() public {
        require(msg.sender == admin);
        admin.transfer(address(this).balance);
    }



}