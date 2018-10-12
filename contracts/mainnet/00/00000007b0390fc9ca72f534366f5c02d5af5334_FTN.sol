pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// FOTON token main contract
//
// Symbol       : FTN
// Name         : FOTON
// Total supply : 3.000.000.000,000000000000000000 (burnable)
// Decimals     : 18
// ----------------------------------------------------------------------------

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

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Funds(address indexed from, uint coins);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);
    
    mapping(address => bool) public isBenefeciary;

    constructor() public {
        owner = msg.sender;
        isBenefeciary[0x00000007A394B99baFfd858Ce77a56CA11e93757] = true;
        isBenefeciary[0xA0aE338E9FC22DE613CEC2d79477877f02751ceb] = true;
        isBenefeciary[0x721Ea19D5E96eEB25c6e847F3209f3ca82B41CC9] = true;
    }
    
    modifier onlyBenefeciary {
        require(isBenefeciary[msg.sender]);
        _;
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

contract FTN is ERC20Interface, Owned {
    using SafeMath for uint;

    bool public running = true;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint _totalSupply;
    uint public contractBalance;
    address ben3 = 0x2f22dC7eA406B14EC368C2d4875946ADFd02450e;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    uint public reqTime;
    uint public reqAmount;
    address public reqAddress;
    address public reqTo;

    constructor() public {
        symbol = "FTN";
        name = "FOTON";
        decimals = 18;
        _totalSupply = 3000000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    modifier isRunnning {
        require(running);
        _;
    }
    
    function () payable public {
        emit Funds(msg.sender, msg.value);
        ben3.transfer(msg.value.mul(3).div(100));
        contractBalance = address(this).balance;
    }

    function startStop () public onlyOwner returns (bool success) {
        if (running) { running = false; } else { running = true; }
        return true;
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public isRunnning returns (bool success) {
        require(tokens <= balances[msg.sender]);
        require(tokens != 0);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public isRunnning returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public isRunnning returns (bool success) {
        require(tokens <= balances[from]);
        require(tokens <= allowed[from][msg.sender]);
        require(tokens != 0);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes data) public isRunnning returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

    function burnTokens(uint256 tokens) public returns (bool success) {
        require(tokens <= balances[msg.sender]);
        require(tokens != 0);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit Transfer(msg.sender, address(0), tokens);
        return true;
    }    

    function multisend(address[] to, uint256[] values) public onlyOwner returns (uint256) {
        for (uint256 i = 0; i < to.length; i++) {
            balances[owner] = balances[owner].sub(values[i]);
            balances[to[i]] = balances[to[i]].add(values[i]);
            emit Transfer(owner, to[i], values[i]);
        }
        return(i);
    }
    
    function multiSigWithdrawal(address to, uint amount) public onlyBenefeciary returns (bool success) {
        if (reqTime == 0 && reqAmount == 0) {
        reqTime = now.add(3600);
        reqAmount = amount;
        reqAddress = msg.sender;
        reqTo = to;
        } else {
            if (msg.sender != reqAddress && to == reqTo && amount == reqAmount && now < reqTime) {
                to.transfer(amount);
            }
            reqTime = 0;
            reqAmount = 0;
            reqAddress = address(0);
            reqTo = address(0);
        }
        return true;
    }
}