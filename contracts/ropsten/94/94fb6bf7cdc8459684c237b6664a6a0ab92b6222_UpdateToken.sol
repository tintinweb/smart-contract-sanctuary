pragma solidity ^0.4.18;

contract SafeMath {
    function safeAdd(uint d, uint e) public pure returns (uint f) {
        f = d + e;
        require(f >= d);
    }
    function safeSub(uint d, uint e) public pure returns (uint f) {
        require(e <= d);
        f = d - e;
    }
    function safeMul(uint d, uint e) public pure returns (uint f) {
        f = d * e;
        require(d == 0 || f / d == e);
    }
    function safeDiv(uint d, uint e) public pure returns (uint f) {
        require(e > 0);
        f = d / e;
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
	    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
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

contract UpdateToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    function UpdateToken() public {
        symbol = &quot;UTP&quot;;
        name = &quot;Update Token&quot;;
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        balances[0x42CA549a136A9d4a5839b1a04c27dfA93d9e42b2] = _totalSupply;
       // balances[0x42CA549a136A9d4a5839b1a04c27dfA93d9e42b2] = totalSupply; 
        
        Transfer(address(0), 0x42CA549a136A9d4a5839b1a04c27dfA93d9e42b2, _totalSupply);
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require(!frozenAccount[msg.sender]);
        
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

    function airdrop(address _tokenAddr, address[] dests, uint256[] values)
    onlyOwner
    returns (uint256) {
        uint256 a = 0;
        while (a < dests.length) {
           ERC20Interface(_tokenAddr).transfer(dests[a], values[a]);
           a += 1;
        }
        return(a);
    }
	
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);

    //freeze accounts
    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
     // This notifies clients about the amount burnt
     event Burn(address indexed from, uint256 value);
    
        /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) onlyOwner public returns (bool success)  {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        _totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /// Create new tokens ans send to target address
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balances[target] += mintedAmount;
        _totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    
    //mint shit
    
}