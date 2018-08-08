pragma solidity ^0.4.23;

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


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract MamaToken is ERC20Interface, Owned, SafeMath {
    string public constant name = "MamaMutua";
    string public constant symbol = "M2M";
    uint32 public constant decimals = 18;
    uint public _rate = 600;
    uint256 public _totalSupply = 60000000 * (10 ** 18);
    address owner;

    // amount of raised money in Wei
    uint256 public weiRaised;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    uint public openingTime = 1527638401; // 30 May 2018 00:01
    uint public closingTime = 1546214399; // 30 Dec 2018 23:59

    constructor() public {
        balances[msg.sender] = _totalSupply;
        owner = msg.sender;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function burn(uint256 _amount) public onlyOwner returns (bool) {
        require(_amount <= balances[msg.sender]);

        balances[msg.sender] = safeSub(balances[msg.sender], _amount);
        _totalSupply = safeSub(_totalSupply, _amount);
        emit Transfer(msg.sender, address(0), _amount);
        return true;
    }

    function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(_totalSupply + _amount >= _totalSupply); // Overflow check

        _totalSupply = safeAdd(_totalSupply, _amount);
        balances[_to] = safeAdd(balances[_to], _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 tokens) public returns (bool success) {
        /* Check if sender has balance and for overflows */
        require(balances[msg.sender] >= tokens && balances[to] + tokens >= balances[to]);
        // mitigates the ERC20 short address attack
        if(msg.data.length < (2 * 32) + 4) { revert(); }

        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        // mitigates the ERC20 spend/approval race condition
        if (tokens != 0 && allowed[msg.sender][spender] != 0) { return false; }

        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        // mitigates the ERC20 short address attack
        if(msg.data.length < (3 * 32) + 4) { revert(); }

        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function () external payable {
        // Check ICO period
        require(block.timestamp >= openingTime && block.timestamp <= closingTime);
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(beneficiary != 0x0);
        require(msg.value > 1 finney);

        uint256 weiAmount = msg.value;

        // update state
        weiRaised = safeAdd(weiRaised, weiAmount);

        // calculate token amount to be created
        uint256 tokensIssued = safeMul(_rate, weiAmount);

        // transfer tokens
        balances[owner] = safeSub(balances[owner], tokensIssued);
        balances[beneficiary] = safeAdd(balances[beneficiary], tokensIssued);

        emit Transfer(owner, beneficiary, tokensIssued);
        forwardFunds(weiAmount);
    }

    function forwardFunds(uint256 _weiAmount) internal {
        owner.transfer(_weiAmount);
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}