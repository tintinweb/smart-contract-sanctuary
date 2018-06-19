pragma solidity ^0.4.18;
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
}
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

// Owned contract
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
    
    //Transfer owner rights, can use only owner (the best practice of secure for the contracts)
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    //Accept tranfer owner rights
    function acceptOwnership() public onlyOwner {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract NSCDistributionContract is ERC20Interface, Owned {
    using SafeMath for uint;
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _initialDistribution;
    uint private _totalSupply;
    uint256 public unitsOneEthCanBuy;
    uint256 private totalEthInWei;
    address private fundsWallet;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    function NSCDistributionContract() public {
        symbol = &#39;NSC&#39;;
        name = &#39;NSC&#39;;
        decimals = 18;
        _totalSupply = 500000000 * 10**uint(decimals);
        _initialDistribution = 1000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);
        unitsOneEthCanBuy = 692;
        fundsWallet = msg.sender;
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
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

    function () public payable {
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        if (balances[fundsWallet] < amount) {
            return;
        }
        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;
        Transfer(fundsWallet, msg.sender, amount);
        fundsWallet.transfer(msg.value);
    }
    
    //Send tokens to users from the exel file
    function send(address[] receivers, uint[] values) public payable {
      for (uint i = 0; receivers.length > i; i++) {
           sendTokens(receivers[i], values[i]);
        }
    }
    
    //Send tokens to specific user
    function sendTokens (address receiver, uint token) public onlyOwner {
        require(balances[msg.sender] >= token);
        balances[msg.sender] -= token;
        balances[receiver] += token;
        Transfer(msg.sender, receiver, token);
    }
    
    //Send initial tokens
    function sendInitialTokens (address user) public onlyOwner {
        sendTokens(user, balanceOf(owner));
    }
}