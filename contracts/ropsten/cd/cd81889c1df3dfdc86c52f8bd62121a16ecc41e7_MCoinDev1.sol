/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library 
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) { c = a + b; require(c >= a); }
    function safeSub(uint a, uint b) public pure returns (uint c) { require(b <= a); c = a - b; } 
    function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } 
    function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0); c = a / b;  }
}


contract MCoinDev1 is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    bool private deprecated;
    address private creator; // the contract creator
    address private newAddress;
    uint256 private _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    event ContractDeprecated(address newAddress);
    
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "MCoinDev1";
        symbol = "MCD1";
        decimals = 18; // 000000000000000000
        _totalSupply = 20000000000000000000000000;
        
        creator = msg.sender;
        deprecated = false;
        newAddress = address(0);

        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    modifier isCreator()
    {
        require(msg.sender == creator, "Only the creator can do this!");
        // Do not forget the "_;"! It will
        // be replaced by the actual function
        // body when the modifier is used.
        _; 
    }
    
    /**
    *
    * IMPLEMENTATION OF ERC20Interface
    * 
    */
    
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    /**
     * 
     * MINT AND BURN
     * 
     */
     
     // MINT: The Contract Owner stocked up the frozen Mett Reserve
    
    function mint(address to, uint256 amount) public isCreator() returns (bool success)
    {
     balances[to] = safeAdd(balances[to], amount);
     _totalSupply = safeAdd(_totalSupply, amount);
     emit Transfer(address(0), to, amount);
     return true;
    }
    
    // BURN: MettCoiner burned some Mett
    function burn(uint256 amount) public returns (bool success)
    {
     require(balances[msg.sender] >= amount, "You do not have enough Mett!");
     balances[msg.sender] = safeSub(balances[msg.sender], amount);
     _totalSupply = safeSub(_totalSupply, amount);
     emit Transfer(msg.sender, address(0), amount);
     return true;
    }
    
    /**
     * Deprecation: Contract can be marked as deprecated and refer to a new contract address, but everything still works.
     * (Its just a recommendation to use the newer contract and also makes it possible to verify that it was created by the original creator)
     * 
     */
    
    function deprecate(address _newAddress) public isCreator() returns (bool success)
    {
        deprecated = true;
        newAddress = _newAddress;
        emit ContractDeprecated(newAddress);
        return true;
    }
    
    function isDeprecated() public view returns (bool _deprecated)
    {
        return deprecated;
    }
    function getNewAddress() public view returns (address _newAddress)
    {
        require(isDeprecated() == true, "Contract is not deprecated!");
        return newAddress;
    }
}