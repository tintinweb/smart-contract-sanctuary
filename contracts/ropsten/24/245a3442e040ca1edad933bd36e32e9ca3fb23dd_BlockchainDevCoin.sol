pragma solidity 0.4.24;

contract Token {
    function totalSupply() public constant returns (uint);

    function balanceOf(address tokenOwner) public constant returns (uint balance);

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract StandardToken is Token {

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(from, to, tokens);
        return true;
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    uint public _totalSupply;
}

contract BlockchainDevCoin is StandardToken {

    string public  name;
    uint8 public decimals;
    string public version = &quot;H1.0&quot;;
    string public symbol;
    uint256 public unitsOneEthCanBuy;
    uint256 public totalEthInWei;

    address public fundsWallet;

    constructor() public {
        _totalSupply = 100000000000000000000000000;
        balances[msg.sender] = _totalSupply;

        name = &quot;BlockchainDevCoin&quot;;
        decimals = 18;
        symbol = &quot;BDC&quot;;
        unitsOneEthCanBuy = 10;
        fundsWallet = msg.sender;

        Transfer(address(0), msg.sender, _totalSupply);
    }

    function() public payable {
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        if (balances[fundsWallet] < amount) {
            return;
        }
        balances[fundsWallet] -= amount;
        balances[msg.sender] += amount;

        emit Transfer(fundsWallet, msg.sender, amount);

        fundsWallet.transfer(msg.value);
    }

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);

        if (!spender.call(bytes4(bytes32(sha3(&quot;receiveApproval(address,uint256,address,bytes)&quot;))),
            msg.sender, tokens, this, data)) {
            throw;
        }
        return true;
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply - balances[address(0)];
    }
}