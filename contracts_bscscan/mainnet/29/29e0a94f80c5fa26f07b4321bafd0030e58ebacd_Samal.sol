/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

pragma solidity ^0.5.0;

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

contract Samal is ERC20Interface {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public price;
    uint256 public length;
    uint256 public length_now;

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "Samal";
        symbol = "SML";
        decimals = 18;
        _totalSupply = 1000000000000000000000000000;
        price = 128000000000000000000;
        length = 1024000000000000000000;
        length_now = 0;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function changeEpoch(uint tokens) public returns (bool success) {
        if (length_now*1000000000000000000 >= length) {
                price = price*1085/1000;
                length = length*12/10;
                length_now = 0;
        }
        else {
            length_now = length_now+tokens;
        }
        _totalSupply = _totalSupply+tokens/(price/1000000000000000000);
        return true;
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply;
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
        changeEpoch(tokens);
        balances[msg.sender] = balances[msg.sender]-tokens+tokens/(price/1000000000000000000);
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        changeEpoch(tokens);
        balances[from] = balances[from]-tokens+tokens/(price/1000000000000000000);
        allowed[from][msg.sender] = allowed[from][msg.sender]-tokens+tokens/(price/1000000000000000000);
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }
}