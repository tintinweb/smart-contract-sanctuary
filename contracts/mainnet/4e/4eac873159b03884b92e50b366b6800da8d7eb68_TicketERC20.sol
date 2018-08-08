pragma solidity 0.4.23;

contract ERC20Interface {
    function totalSupply() public view returns(uint amount);
    function balanceOf(address tokenOwner) public view returns(uint balance);
    function allowance(address tokenOwner, address spender) public view returns(uint balanceRemaining);
    function transfer(address to, uint tokens) public returns(bool status);
    function approve(address spender, uint limit) public returns(bool status);
    function transferFrom(address from, address to, uint amount) public returns(bool status);
    function name() public view returns(string tokenName);
    function symbol() public view returns(string tokenSymbol);

    event Transfer(address from, address to, uint amount);
    event Approval(address tokenOwner, address spender, uint amount);
}

contract Owned {
    address contractOwner;

    constructor() public { 
        contractOwner = msg.sender; 
    }
    
    function whoIsTheOwner() public view returns(address) {
        return contractOwner;
    }
}


contract Mortal is Owned  {
    function kill() public {
        if (msg.sender == contractOwner) selfdestruct(contractOwner);
    }
}

contract TicketERC20 is ERC20Interface, Mortal {
    string private myName;
    string private mySymbol;
    uint private myTotalSupply;
    uint8 public decimals;

    mapping (address=>uint) balances;
    mapping (address=>mapping (address=>uint)) ownerAllowances;

    constructor() public {
        myName = "XiboquinhaCoins-teste-01";
        mySymbol = "XBCT01";
        myTotalSupply = 1000000;
        decimals = 0;
        balances[msg.sender] = myTotalSupply;
    }

    function name() public view returns(string tokenName) {
        return myName;
    }

    function symbol() public view returns(string tokenSymbol) {
        return mySymbol;
    }

    function totalSupply() public view returns(uint amount) {
        return myTotalSupply;
    }

    function balanceOf(address tokenOwner) public view returns(uint balance) {
        require(tokenOwner != address(0));
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns(uint balanceRemaining) {
        return ownerAllowances[tokenOwner][spender];
    }

    function transfer(address to, uint amount) public hasEnoughBalance(msg.sender, amount) tokenAmountValid(amount) returns(bool status) {
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint limit) public returns(bool status) {
        ownerAllowances[msg.sender][spender] = limit;
        emit Approval(msg.sender, spender, limit);
        return true;
    }

    function transferFrom(address from, address to, uint amount) public 
    hasEnoughBalance(from, amount) isAllowed(msg.sender, from, amount) tokenAmountValid(amount)
    returns(bool status) {
        balances[from] -= amount;
        balances[to] += amount;
        ownerAllowances[from][msg.sender] = amount;
        emit Transfer(from, to, amount);
        return true;
    }

    modifier hasEnoughBalance(address owner, uint amount) {
        uint balance;
        balance = balances[owner];
        require (balance >= amount); 
        _;
    }

    modifier isAllowed(address spender, address tokenOwner, uint amount) {
        require (amount <= ownerAllowances[tokenOwner][spender]);
        _;
    }

    modifier tokenAmountValid(uint amount) {
        require(amount > 0);
        _;
    }

}