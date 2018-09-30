pragma solidity ^0.4.18;


contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


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

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract ExToke is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    address public oldAddress;
    address public tokenAdmin;
    uint public _totalSupply;
    uint256 public totalEthInWei;         // WEI is the smallest unit of ETH (the equivalent of cent in USD or satoshi in BTC). We&#39;ll store the total ETH raised via our ICO here.  
    uint256 public unitsOneEthCanBuy;     // How many units of your coin can be bought by 1 ETH?
    address public fundsWallet;           
    uint256 public crowdSaleSupply;
    uint256 public tokenSwapSupply;
    uint256 public dividendSupply;
    
    uint256 public scaling;
    uint256 public scaledRemainder;
    
    uint256 public finishTime = 1548057600;
    uint256 public startTime = 1540814400;
    
    uint256[] public releaseDates = 
        [1575201600, 1577880000, 1580558400, 1583064000, 1585742400, 1588334400,
        1591012800, 1593604800, 1596283200, 1598961600, 1601553600, 1604232000,
        1606824000, 1609502400, 1612180800, 1614600000, 1617278400, 1619870400,
        1622548800, 1625140800, 1627819200, 1630497600, 1633089600, 1635768000];
    
    uint256 public nextRelease;

    mapping(address => uint256) public scaledDividendBalanceOf;

    uint256 public scaledDividendPerToken;

    mapping(address => uint256) public scaledDividendCreditedTo;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    function ExToke() public {
        symbol = "XTE";
        name = "ExToke";
        decimals = 18;
        tokenAdmin = 0xEd86f5216BCAFDd85E5875d35463Aca60925bF16;
        oldAddress = 0x28925299Ee1EDd8Fd68316eAA64b651456694f0f;
    	_totalSupply = 7000000000000000000000000000;
    	crowdSaleSupply = 500000000000000000000000000;
    	tokenSwapSupply = 2911526439961880000000000000;
    	dividendSupply = 2400000000000000000000000000;
    	unitsOneEthCanBuy = 100000;
        balances[this] = 5811526439961880000000000000;
        balances[0x6baba6fb9d2cb2f109a41de2c9ab0f7a1b5744ce] = 1188473560038120000000000000;
        
        nextRelease = 0;
        
        scaledRemainder = 0;
        scaling = uint256(10) ** 8;
        
    	fundsWallet = tokenAdmin;
        Transfer(this, 0x6baba6fb9d2cb2f109a41de2c9ab0f7a1b5744ce, 1188473560038120000000000000);

    }
    
    

    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        update(msg.sender);
        update(to);
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        update(from);
        update(to);
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    
    function update(address account) internal {
        if(nextRelease < 24 && block.timestamp > releaseDates[nextRelease]){
            releaseDivTokens();
        }
        uint256 owed =
            scaledDividendPerToken - scaledDividendCreditedTo[account];
        scaledDividendBalanceOf[account] += balances[account] * owed;
        scaledDividendCreditedTo[account] = scaledDividendPerToken;
        
        
    }
    
    function () public payable {
        if(startTime < block.timestamp && finishTime >= block.timestamp && crowdSaleSupply >= msg.value * unitsOneEthCanBuy){
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(balances[this] >= amount);

        balances[this] = balances[this] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;
        
        crowdSaleSupply -= msg.value * unitsOneEthCanBuy;

        Transfer(this, msg.sender, amount); // Broadcast a message to the blockchain

        tokenAdmin.transfer(msg.value);
        }
        else if(finishTime < block.timestamp){
            balances[this] = balances[this] - amount;
            balances[tokenAdmin] += crowdSaleSupply;
            tokenAdmin.transfer(msg.value);
            Transfer(this, tokenAdmin, amount);
            crowdSaleSupply = 0;
        }
        
        
    }
    
    function releaseDivTokens() public returns (bool success){
        require(block.timestamp > releaseDates[nextRelease]);
        uint256 releaseAmount = 100000000 * (uint256(10) ** decimals);
        dividendSupply -= releaseAmount;
        uint256 available = (releaseAmount * scaling) + scaledRemainder;
        scaledDividendPerToken += available / _totalSupply;
        scaledRemainder = available % _totalSupply;
        nextRelease += 1;
        return true;
    }
    
    function withdraw() public returns (bool success){
        require(block.timestamp > releaseDates[0]);
        update(msg.sender);
        uint256 amount = scaledDividendBalanceOf[msg.sender] / scaling;
        scaledDividendBalanceOf[msg.sender] %= scaling;  // retain the remainder
        balances[msg.sender] += amount;
        balances[this] -= amount;
        emit Transfer(this, msg.sender, amount);
        return true;
    }
    
    function swap(uint256 sendAmount) returns (bool success){
        require(tokenSwapSupply >= sendAmount * 3);
        if(ERC20Interface(oldAddress).transferFrom(msg.sender, tokenAdmin, sendAmount)){
            balances[msg.sender] += sendAmount * 3;
            balances[this] -= sendAmount * 3;
            tokenSwapSupply -= sendAmount * 3;
        }
        emit Transfer(this, msg.sender, sendAmount * 3);
        return true;
    }
    


}