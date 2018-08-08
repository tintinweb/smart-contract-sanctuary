pragma solidity 0.4.13;


contract ERC20Abstract {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

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

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract ERC20Contract is ERC20Abstract {

    mapping (address => uint256) public balances;

    mapping (address => mapping (address => uint256)) allowed;

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
}


contract ForeignToken {
    function balanceOf(address _owner) constant returns (uint256);

    function transfer(address _to, uint256 _value) returns (bool);
}

contract NeymarTokenEvents {
    event NeymarHasMintedEvent(uint256 _value);
    event UserClaimedTokens(address _address, uint256 _tokens);
}

contract NeymarToken is ERC20Contract, NeymarTokenEvents {
  
    address public owner = msg.sender;

    string public name = "Neymar Token";

    string public symbol = "NT";

    uint256 public decimals = 18;

    uint256 private ethDecimals = 18;

    // Neymar specific variables
    uint256[] public tokenMinted;

    uint256[] private totalSupplies;

    mapping (address => uint256) private positions;
    //===========================

    // ICO Variables
    bool public purchasingAllowed = true;

    uint256 public totalContribution = 0;

    uint256 public totalETHLimit = 400;

    uint256 public totalTokenDistribution = 222000000;

    uint256 public ethTokenRatio = totalTokenDistribution / totalETHLimit;

    uint256 public icoETHContributionLimit = totalETHLimit * 10 ** 18;
    // ==========================

    function() payable { 
        uint256 ethValue = msg.value;
        address _address = msg.sender;
        if (!purchasingAllowed) {revert();}
        if (ethValue == 0) {return;}
        claimTokensFor(_address);
        totalContribution += ethValue;

        uint256 digitsRatio = decimals - ethDecimals;
        uint256 tokensIssued = (ethValue * 10 ** digitsRatio * ethTokenRatio);

        totalSupply += tokensIssued;
        balances[_address] += tokensIssued;
        Transfer(address(this), _address, tokensIssued);

        if (totalContribution >= icoETHContributionLimit) {
            purchasingAllowed = false;
        }
     }

    function neymarHasMinted(uint256 tokensNumber) public returns (bool) {
        if (msg.sender != owner) {revert();}
        NeymarHasMintedEvent(tokensNumber);
        tokensNumber = tokensNumber * 10 ** decimals;
        tokenMinted.push(tokensNumber);
        totalSupplies.push(totalSupply);
        totalSupply += tokensNumber;
        return true;
    }

    function getVirtualBalance(address _address) public constant returns (uint256 virtualBalance){
        return howManyTokensAreReservedFor(_address) + balanceOf(_address);
    }
        
    function howManyTokensAreReservedForMe() public constant returns (uint256 tokenCount) {
        return howManyTokensAreReservedFor(msg.sender);
    }

    function howManyTokensAreReservedFor(address _address) public constant returns (uint256 tokenCount) {
        uint256 currentTokenNumbers = balances[_address];
        if (currentTokenNumbers == 0) {
            return 0;
        }
        
        uint256 neymarGoals = tokenMinted.length;
        uint256 currentPosition = positions[_address];
        uint256 tokenMintedAt = 0;
        uint256 totalSupplyAt = 0;
        uint256 tokensWon = 0;

        while (currentPosition < neymarGoals) {
            tokenMintedAt = tokenMinted[currentPosition];
            totalSupplyAt = totalSupplies[currentPosition];
            tokensWon = tokenMintedAt * currentTokenNumbers / totalSupplyAt;
            currentTokenNumbers += tokensWon;
            currentPosition += 1;
        }
        return currentTokenNumbers - balances[_address];
    }

    function claimMyTokens() public returns (bool success) {
        return claimTokensFor(msg.sender);
    }

    function claimTokensFor(address _address) private returns (bool success) {
        uint256 currentTokenNumbers = balances[_address];
        uint256 neymarGoals = tokenMinted.length;
        if (currentTokenNumbers == 0) {
            balances[_address] = 0;
            positions[_address] = neymarGoals;
            return true;
        }
        uint256 tokens = howManyTokensAreReservedFor(_address);
        balances[_address] += tokens;
        positions[_address] = neymarGoals;
        UserClaimedTokens(_address, tokens);       
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (msg.data.length < (2 * 32) + 4) {revert();}
        claimTokensFor(msg.sender);
        claimTokensFor(_to);
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (msg.data.length < (3 * 32) + 4) {revert();}
        claimTokensFor(_from);
        claimTokensFor(_to);
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function withdrawForeignTokens(address _tokenContract) public returns (bool) {
        if (msg.sender != owner) {revert();}

        ForeignToken token = ForeignToken(_tokenContract);

        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }

    function getReadableStats() public constant returns (uint256, uint256, bool) {
        return (totalContribution / 10 ** decimals, totalSupply / 10 ** decimals, purchasingAllowed);
    }

    function getReadableSupply() public constant returns (uint256) {
        return totalSupply / 10 ** decimals;
    }

    function getReadableContribution() public constant returns (uint256) {
        return totalContribution / 10 ** decimals;
    }

    function getTotalGoals() public constant returns (uint256) {
        return totalSupplies.length;
    }

    function getETH() public {
        if (msg.sender != owner) {revert();}
        owner.transfer(this.balance);
    }
}