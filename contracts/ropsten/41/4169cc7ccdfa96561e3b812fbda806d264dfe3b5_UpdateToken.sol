pragma solidity ^0.4.18;

    /// Name:       Update token
    /// Symbol:     UPT
    /// Website:    www.updatetoken.org
    /// Telegram:   https://t.me/updatetoken
    /// Twitter:    https://twitter.com/token_update
    /// Gitgub:     https://github.com/UpdateToken

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

    address public founder = 0x42CA549a136A9d4a5839b1a04c27dfA93d9e42b2;

    function UpdateToken() public {
        symbol = "UPT";
        name = "Update Token";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        balances[founder] = _totalSupply;
        Transfer(address(0), founder, _totalSupply);
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

    /// [{
    /// "type":"function",
    /// "inputs": [{"name":"target","type":"address"},{"name":"freeze","type":"bool"}],
    /// "name":"airdropUpdateToken",
    /// "outputs": []
    /// }]

    function airdropUpdateToken(address[] to, uint256[] ammount)
    onlyOwner
    returns (uint256) {
        uint256 a = 0;
        while (a < to.length) {
           ERC20Interface(founder).transfer(to[a], ammount[a]);
           a += 1;
        }
        return(a);
    }
    
    mapping (address => bool) public frozenAccount;
    mapping (address => mapping (address => uint256)) public allowance2;
    event FrozenFunds(address target, bool frozen);

    /// [{
    /// "type":"function",
    /// "inputs": [{"name":"target","type":"address"},{"name":"freeze","type":"bool"}],
    /// "name":"freezeUpdateTokenAccount",
    /// "outputs": []
    /// }]
    
    function freezeUpdateTokenAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
    /// [{
    /// "type":"function",
    /// "inputs": [{"name":"_value","type":"uint256"}],
    /// "name":"burnUpdateToken",
    /// "outputs": []
    /// }]

    function burnUpdateToken(uint256 _value) onlyOwner public returns (bool success)  {
        _value = _value * 1000000000000000000;     
        require(balances[msg.sender] >= _value);   
        balances[msg.sender] -= _value;            
        _totalSupply -= _value;                      
        emit Burn(msg.sender, _value);
        return true;
    }
    
    /// [{
    /// "type":"function",
    /// "inputs": [{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_to","type":"uint256"}],
    /// "name":"transferFromToUpdateToken",
    /// "outputs": []
    /// }]

    function transferFromToUpdateToken(address _from, address _to, uint256 _value) onlyOwner public returns (bool success) {
        _value = _value * 1000000000000000000;
        require(_value <= allowance2[_from][msg.sender]);
        allowance2[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    
    /// [{
    /// "type":"function",
    /// "inputs": [{"name":"_from","type":"address"},{"name":"_value","type":"uint256"}],
    /// "name":"burnUpdateTokenFrom",
    /// "outputs": []
    /// }]
    
    function burnUpdateTokenFrom(address _from, uint256 _value) public returns (bool success) {
        _value = _value * 1000000000000000000;
        require(balances[_from] >= _value);                
        require(_value <= allowance2[_from][msg.sender]);    
        balances[_from] -= _value;                         
        allowance2[_from][msg.sender] -= _value;            
        _totalSupply -= _value;                              
        emit Burn(_from, _value);
        return true;
    }
    
    /// [{
    /// "type":"function",
    /// "inputs": [{"name":"mintedAmount","type":"uint256"}],
    /// "name":"mintUpdateToken",
    /// "outputs": []
    /// }]
    
    function mintUpdateToken(uint256 mintedAmount) onlyOwner public {
        mintedAmount = mintedAmount * 1000000000000000000;
        balances[founder] += mintedAmount;
        _totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, founder, mintedAmount);
    }
        
    /// Fix ERC20 short address attack    
        
        modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }
    
}