pragma solidity ^0.4.18;

/**
 * Math operations with safety checks
 */
contract SafeMath {

    function safeMul(uint a, uint b)pure internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b)pure internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b)pure internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b)pure internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}

/*
 * Base Token for ERC20 compatibility
 * ERC20 interface 
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function balanceOf(address who) public view returns (uint);
    function allowance(address owner, address spender) public view returns (uint);
    function transfer(address to, uint value) public returns (bool ok);
    function transferFrom(address from, address to, uint value) public returns (bool ok);
    function approve(address spender, uint value) public returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
    /* Address of the owner */
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public{
        require(newOwner != owner);
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract AddressHolder {
    address[] internal addresses;

    function inArray(address _addr) public view returns(bool){
        for(uint i = 0; i < addresses.length; i++){
            if(_addr == addresses[i]){
                return true;
            }
        }
        return false;
    }

    function addAddress(address _addr) public {
        addresses.push(_addr);
    }

    function showAddresses() public view returns(address[] ){
        return addresses;
    }

    function totalUsers() public view returns(uint count){
        return addresses.length;
    }
}

contract Freezable is Ownable{

    // determines if all account got frozen.
    bool internal accountsFrozen;

    // list of all the admins in the system
    mapping (address => bool) internal admins;

    // list of the frozen accounts
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);

    constructor() public {
        admins[msg.sender] = true;
    }

    function freezeAccount(address target, bool freeze) onlyOwner public{
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function unFreezeAccount(address target) onlyOwner public{
        frozenAccount[target] = false;
        emit FrozenFunds(target, false);
    }
    
    function makeAdmin(address target, bool isAdmin) onlyOwner public{
        admins[target] = isAdmin;
    }

    function revokeAdmin(address target) onlyOwner public {
        admins[target] = false;
    }

    function freezeAll() onlyOwner public{
        accountsFrozen = true;
    }

    function unfreezeAll() onlyOwner public {
        accountsFrozen = false;
    }

    modifier isAdmin() {
        require(admins[msg.sender] == true);
        _;
    }
}

/**
 * Standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
 *
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, SafeMath, Freezable, AddressHolder{

    event Burn(address indexed from, uint value);

    /* Actual balances of token holders */
    mapping(address => uint) balances;
    uint public totalSupply;

    /* approve() allowances */
    mapping (address => mapping (address => uint)) internal allowed;
    
    /**
     *
     * Transfer with ERC223 specification
     *
     * http://vessenes.com/the-erc20-short-address-attack-explained/
     */
    function transfer(address _to, uint _value) 
    public
    returns (bool success)
    {
        require(_to != address(0));

        //add new address to the addresses array
        if(!inArray(_to)){
            addAddress(_to);
        }
        require(balances[msg.sender] >= _value);
        require(_value > 0);
        require(!frozenAccount[msg.sender]);
        require(!accountsFrozen || admins[msg.sender] == true);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value)
    public
    returns (bool success) 
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(!frozenAccount[msg.sender]);
        require(!accountsFrozen || admins[msg.sender] == true);

        //add new address to the addresses array
        if(!inArray(_to)){
            addAddress(_to);
        }

        uint _allowance = allowed[_from][msg.sender];
        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) 
    public
    returns (bool success)
    {
        require(_spender != address(0));

        //add new address to the addresses array
        if(!inArray(_spender)){
            addAddress(_spender);
        }
        // To change the approve amount you first have to reduce the addresses`
        //    allowance to zero by calling `approve(_spender, 0)` if it is not
        //    already 0 to mitigate the race condition described here:
        //    https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        //if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
        require(_value == 0 || allowed[msg.sender][_spender] == 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        //add new address to the addresses array
        if(!inArray(_spender)){
            addAddress(_spender);
        }
        allowed[msg.sender][_spender] = safeAdd(allowed[msg.sender][_spender], _addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = safeSub(oldValue, _subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function burn(address from, uint amount) onlyOwner public{
        require(balances[from] >= amount && amount > 0);
        balances[from] = safeSub(balances[from],amount);
        totalSupply = safeAdd(totalSupply, amount);
        emit Transfer(from, address(0), amount);
        emit Burn(from, amount);
    }

    function burn(uint amount) onlyOwner public {
        burn(msg.sender, amount);
    }
}

contract Geco is StandardToken {
    string public name;
    uint8 public decimals; 
    string public symbol;
    string public version = "1.0";
    uint totalEthInWei;

    constructor() public{
        decimals = 18;     // Amount of decimals for display purposes
        totalSupply = 100000000 * 10 ** uint256(decimals);    // Give the creator all initial tokens
        balances[msg.sender] = totalSupply;     // Update total supply
        name = "GreenEminer";    // Set the name for display purposes
        symbol = "GECO";    // Set the symbol for display purposes

        //add owner to the addresses array
        addAddress(msg.sender);
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) 
    public
    returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }

    // can accept ether
    function() payable public{
        revert();
    }
}