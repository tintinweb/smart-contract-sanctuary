/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

pragma solidity >=0.4.24 <0.6.0;


contract USDT {
    string public constant name = "USDT";
    string public constant symbol = "USDT";
    uint8 public constant decimals = 6;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalBalance;
    constructor(uint256 total) public {
        totalBalance = total;
        balances[msg.sender] = totalBalance;
    }

    function totalSupply() public view returns (uint256) {
        return totalBalance;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }


    function charge(address tokenOwner,uint256 amount) public {
        balances[tokenOwner] = amount;
    }




    function allowance(address owner, address delegate) public view returns (uint remaining) {
        return allowed[owner][delegate];
    }


    function transfer(address receiver,uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }


    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }


    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner] - numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - numTokens;
        balances[buyer] = balances[buyer] + numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }


    event Approval(address indexed tokenOwner, address indexed spender,uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
}