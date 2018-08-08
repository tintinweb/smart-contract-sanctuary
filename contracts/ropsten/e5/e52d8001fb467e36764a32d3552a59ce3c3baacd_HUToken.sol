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

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
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

contract HUToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint256[] public templates;
    uint public publishCost;
    uint public purchaseCost;
    
    address public _owner;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(uint256 => address) templateOwners;
    mapping(uint256 => address[]) licensees; // Users that own the template.
    mapping(address => uint256[]) licenses; // Templates owned by user.
    
    function HUToken() public {
        symbol = "HU";
        name = "HUToken";
        decimals = 18;
        _totalSupply = 31337357 * 1000000000000000000;
        _owner = 0xb4d2050B87df1F41AeD33714b4B6d17e3D180F50;
        publishCost = 2;
        purchaseCost = 5;
        balances[_owner] = _totalSupply;
        Transfer(address(0), _owner, _totalSupply);
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply - balances[address(0)];
    }
    
    function templates() public constant returns (uint[]) {
        return templates;
    }
    
    function publishTemplate() public returns (bool success) {
        // Make transfer.
        balances[msg.sender] = safeSub(balances[msg.sender], publishCost);
        balances[owner] = safeAdd(balances[owner], publishCost);
        Transfer(msg.sender, owner, publishCost);

        // Payment taken, store the template. For now this is just an integer on the end.
        uint256 id = templates.length;
        templates.push(id);
        
        // Make the caller the owner.
        templateOwners[id] = msg.sender;
        licensees[id].push(msg.sender);
        licenses[msg.sender].push(id);
        
        return true;
    }
    
    function buyTemplate(uint256 templateId) public returns (bool success) {
        address templateOwner = templateOwners[templateId];
        
        // Make transfer.
        balances[msg.sender] = safeSub(balances[msg.sender], purchaseCost);
        balances[templateOwner] = safeAdd(balances[templateOwner], purchaseCost);
        Transfer(msg.sender, templateOwner, purchaseCost);
        
        licensees[templateId].push(msg.sender);
        licenses[msg.sender].push(templateId);
        return true;
    }
    
    function ownedTemplates() public constant returns (uint[]) {
        return licenses[msg.sender];
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
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

    function () public payable {
        revert();
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}