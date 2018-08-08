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

contract ERC223Interface {
    function transfer(address to, uint value, bytes data) public returns (bool ok); // ERC223
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

/*
 * Contract that is working with ERC223 tokens
 */
 
contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {

    event Burn(address indexed from, uint value);
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

/**
 * Standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
 *
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, SafeMath, ERC223Interface, Ownable {

    /* Actual balances of token holders */
    mapping(address => uint) balances;
    uint public totalSupply;

    /* approve() allowances */
    mapping (address => mapping (address => uint)) internal allowed;
    /**
     *
     * Fix for the ERC20 short address attack
     *
     * http://vessenes.com/the-erc20-short-address-attack-explained/
     */
    modifier onlyPayloadSize(uint size) {
        if(msg.data.length < size + 4) {
            revert();
        }
        _;
    }


    function burn(address from, uint amount) onlyOwner public{
        require(balances[from] >= amount && amount > 0);
        balances[from] = safeSub(balances[from],amount);
        totalSupply = safeSub(totalSupply, amount);
        emit Transfer(from, address(0), amount);
        emit Burn(from, amount);
    }

    function burn(uint amount) onlyOwner public {
        burn(msg.sender, amount);
    }

    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *    Invokes the `tokenFallback` function if the recipient is a contract.
     *    The token transfer fails if the recipient is a contract
     *    but does not implement the `tokenFallback` function
     *    or the fallback function to receive funds.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _data    Transaction metadata.
     */
    function transfer(address _to, uint _value, bytes _data)
    onlyPayloadSize(2 * 32) 
    public
    returns (bool success) 
    {
        require(_to != address(0));
        if (balances[msg.sender] >= _value && _value > 0) {
            // Standard function transfer similar to ERC20 transfer with no _data .
            // Added due to backwards compatibility reasons .
            uint codeLength;

            assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
            }
            balances[msg.sender] = safeSub(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            if(codeLength>0) {
                ContractReceiver receiver = ContractReceiver(_to);
                receiver.tokenFallback(msg.sender, _value, _data);
            }
            emit Transfer(msg.sender, _to, _value, _data);
            return true;
        }else{return false;}

    }
    
    /**
     *
     * Transfer with ERC223 specification
     *
     * http://vessenes.com/the-erc20-short-address-attack-explained/
     */
    function transfer(address _to, uint _value) 
    onlyPayloadSize(2 * 32) 
    public
    returns (bool success)
    {
        require(_to != address(0));
        if (balances[msg.sender] >= _value && _value > 0) {
            uint codeLength;
            bytes memory empty;
            assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
            }

            balances[msg.sender] = safeSub(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            if(codeLength>0) {
                ContractReceiver receiver = ContractReceiver(_to);
                receiver.tokenFallback(msg.sender, _value, empty);
            }
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }

    }

    function transferFrom(address _from, address _to, uint _value)
    public
    returns (bool success) 
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
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

}


contract LICOToken is StandardToken {
    string public name;
    uint8 public decimals; 
    string public symbol;
    string public version = "1.0";
    uint totalEthInWei;

    constructor() public{
        decimals = 18;     // Amount of decimals for display purposes
        totalSupply = 315000000 * 10 ** uint256(decimals);    // Give the creator all initial tokens
        balances[msg.sender] = totalSupply;     // Update total supply
        name = "LifeCrossCoin";    // Set the name for display purposes
        symbol = "LICO";    // Set the symbol for display purposes
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

    function transferToCrowdsale(address _to, uint _value) 
    onlyPayloadSize(2 * 32) 
    onlyOwner
    public
    returns (bool success)
    {
        require(_to != address(0));
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }

    }
    
    function withdrawTokenFromCrowdsale(address _crowdsale) onlyOwner public returns (bool success){
        require(_crowdsale != address(0));
        if (balances[_crowdsale] >  0) {
            uint _value = balances[_crowdsale];
            balances[_crowdsale] = 0;
            balances[owner] = safeAdd(balances[owner], _value);
            emit Transfer(_crowdsale, owner, _value);
            return true;
        } else { return false; }
    }
}