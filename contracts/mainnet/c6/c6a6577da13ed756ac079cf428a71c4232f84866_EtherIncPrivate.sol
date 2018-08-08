pragma solidity ^0.4.16;

contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        safeassert(a == 0 || c / a == b);
        return c;
    }
    
    function safeSub(uint a, uint b) internal returns (uint) {
        safeassert(b <= a);
        return a - b;
    }
    
    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        safeassert(c>=a && c>=b);
        return c;
    }
    
    function safeassert(bool assertion) internal {
        require(assertion);
    }
}

contract ERC20Interface {

    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract Owner {
    address public owner;

    function Owner() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address new_owner) onlyOwner public {
        require(new_owner != 0x0);
        owner = new_owner;
    }
}

contract EtherIncPrivate is ERC20Interface,Owner,SafeMath {
    string public symbol;
    string public name;
    uint public decimals = 18;
    
    uint256 rate = 2000;
    
    uint256 _totalSupply;
    bool privateIco = true;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    mapping(address => uint256) balances;
    mapping(address => Whitelist) public whitelist;
    mapping(address => uint256) public withdrawable;
    mapping(address => mapping (address => uint256)) allowed;
    
    
    struct Whitelist {
        uint256 amount;
        address beneficiary;
        bool active;
    }
    
    /**
    * @dev Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4) ;
        _;
    }
    
    function endprivateIco(bool __status) onlyOwner public {
        if(__status){
            privateIco = false;
        }
    }
    
    function totalSupply() constant returns (uint256 __totalSupply) {        
        return _totalSupply;
    }
    
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    function EtherIncPrivate() {
        name = "EtherInc Private";
        symbol = "ETI-P";
        owner = msg.sender;
        _totalSupply = 0;
    }
    
    function () payable {
        require(privateIco);
        Whitelist storage w = whitelist[msg.sender];
        require(w.active && msg.value >= w.amount);
        uint256 token_amount = safeMul(msg.value, rate);
        _totalSupply = safeAdd(_totalSupply, token_amount);
        balances[msg.sender] = token_amount;
        (w.beneficiary).transfer(msg.value);
        Transfer(address(this), msg.sender, token_amount);
    }
    
    function transfer(
        address _to, uint256 _amount
    ) onlyPayloadSize(2 * 32) public returns (bool success) {
        if (balances[msg.sender] >= _amount
            && _amount > 0
            && safeAdd(balances[_to], _amount) > balances[_to]) {
            balances[msg.sender] = safeSub(balances[msg.sender], _amount);
            balances[_to] = safeAdd(balances[_to], _amount);
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) onlyPayloadSize(2 * 32) public returns (bool success) {
        if (balances[_from] >= _amount
        && allowed[_from][msg.sender] >= _amount
        && _amount > 0
        && safeAdd(balances[_to], _amount) > balances[_to]) {
            balances[_from] = safeSub(balances[_from], _amount);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _amount);
            balances[_to] = safeAdd(balances[_to], _amount);
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
    
    function approve(
        address _spender, uint256 _amount
    ) public returns (bool success) {
        require(balances[msg.sender] >= _amount);
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function allowance(
        address _owner, address _spender
    ) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function whitelist_pool(
        address _pool, address _beneficiary, uint _amount
    ) onlyPayloadSize(2 * 32) onlyOwner public returns (bool success) {
        Whitelist storage w = whitelist[_pool];
        // check already whitelisted 
        require(!w.active);
        
        w.active = true;
        w.beneficiary = _beneficiary;
        w.amount = _amount * 1 ether;
        
        return true;
    }
    
    function withdraw_to_eti() onlyPayloadSize(2 * 32) public returns (bool success) {
        require(privateIco && balances[msg.sender] > 0);
        
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        withdrawable[msg.sender] = amount;
        return true;
    }
}