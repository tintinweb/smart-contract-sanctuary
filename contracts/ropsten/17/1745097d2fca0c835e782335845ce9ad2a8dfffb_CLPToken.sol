pragma solidity ^0.4.11;

/**
 * Math operations with safety checks
 *
 */
contract SafeMath {
    //internals

    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        require(c>=a && c>=b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
        require(b > 0);
        uint c = a / b;
        require(a == b * c + a % b);
        return c;
    }
}


/**
 * ERC 20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 */
interface Token {

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

/**
 * ERC 20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is Token {

    /**
     * Reviewed:
     * - Integer overflow = OK, checked
     */
    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            //if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;
}


/**
 * CLP crowdsale ICO contract.
 *
 */
contract CLPToken is StandardToken, SafeMath {

    string public name = "CLP Token";
    string public symbol = "CLP";
	uint public decimals = 9;

    // Initial founder address (set in constructor)
    // This address handle administration of the token.
    address public founder = 0x0;
	
    // Block timing/contract unlocking information
	uint public month6companyUnlock = 1525132801; // May 01, 2018 UTC
	uint public month12companyUnlock = 1541030401; // Nov 01, 2018 UTC
	uint public month18companyUnlock = 1556668801; // May 01, 2019 UTC
	uint public month24companyUnlock = 1572566401; // Nov 01, 2019 UTC
    uint public year1Unlock = 1541030401; // Nov 01, 2018 UTC
    uint public year2Unlock = 1572566401; // Nov 01, 2019 UTC
    uint public year3Unlock = 1604188801; // Nov 01, 2020 UTC
    uint public year4Unlock = 1635724801; // Nov 01, 2021 UTC

    // Have the post-reward allocations been completed
    bool public allocated1Year = false;
    bool public allocated2Year = false;
    bool public allocated3Year = false;
    bool public allocated4Year = false;
	
	bool public allocated6Months = false;
    bool public allocated12Months = false;
    bool public allocated18Months = false;
    bool public allocated24Months = false;

    // Token count information
	uint currentTokenSaled = 0;
    uint public totalTokensSale = 87000000 * 10**decimals;
    uint public totalTokensReserve = 39000000 * 10**decimals; 
    uint public totalTokensCompany = 24000000 * 10**decimals;

    event Buy(address indexed sender, uint eth, uint fbt);
    event Withdraw(address indexed sender, address to, uint eth);
    event AllocateTokens(address indexed sender);

    function CLPToken() {
        /*
            Initialize the contract with a sane set of owners
        */
        founder = msg.sender;
    }

	/*
        Allocate reserved tokens based on the running time and state of the contract.
     */
    function allocateReserveCompanyTokens() {
        require(msg.sender==founder);
        uint tokens = 0;

        if(block.timestamp > month6companyUnlock && !allocated6Months)
        {
            allocated6Months = true;
            tokens = safeDiv(totalTokensCompany, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else if(block.timestamp > month12companyUnlock && !allocated12Months)
        {
            allocated12Months = true;
            tokens = safeDiv(totalTokensCompany, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else if(block.timestamp > month18companyUnlock && !allocated18Months)
        {
            allocated18Months = true;
            tokens = safeDiv(totalTokensCompany, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else if(block.timestamp > month24companyUnlock && !allocated24Months)
        {
            allocated24Months = true;
            tokens = safeDiv(totalTokensCompany, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else revert();

        AllocateTokens(msg.sender);
    }

    /*
        Allocate reserved tokens based on the running time and state of the contract.
     */
    function allocateReserveTokens() {
        require(msg.sender==founder);
        uint tokens = 0;

        if(block.timestamp > year1Unlock && !allocated1Year)
        {
            allocated1Year = true;
            tokens = safeDiv(totalTokensReserve, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else if(block.timestamp > year2Unlock && !allocated2Year)
        {
            allocated2Year = true;
            tokens = safeDiv(totalTokensReserve, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else if(block.timestamp > year3Unlock && !allocated3Year)
        {
            allocated3Year = true;
            tokens = safeDiv(totalTokensReserve, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else if(block.timestamp > year4Unlock && !allocated4Year)
        {
            allocated4Year = true;
            tokens = safeDiv(totalTokensReserve, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else revert();

        AllocateTokens(msg.sender);
    }


   /**
    *   Change founder address (Controlling address for contract)
    */
    function changeFounder(address newFounder) {
        require(msg.sender==founder);
        founder = newFounder;
    }

	/**
    *   Get current total token sale
    */
    function getTotalCurrentSaled() constant returns (uint256 currentTokenSaled)  {
		require(msg.sender==founder);
		
		return currentTokenSaled;
    }

   /**
    *   Send token to investor
    */
    function addInvestorList(address investor, uint256 amountToken)  returns (bool success) {
		require(msg.sender==founder);
		
		if(currentTokenSaled + amountToken <= totalTokensSale)
		{
			balances[investor] = safeAdd(balances[investor], amountToken);
			currentTokenSaled = safeAdd(currentTokenSaled, amountToken);
			totalSupply = safeAdd(totalSupply, amountToken);
			return true;
		}
		else
		{
		    return false;
		}
    }
}