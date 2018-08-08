pragma solidity ^0.4.10;

/*
This is the API that defines an ERC 20 token, all of these functions must
be implemented.
*/

contract ForeignToken {
    function balanceOf(address _owner) constant returns (uint256);
    function transfer(address _to, uint256 _value) returns (bool);
}

contract Dogetoken {

    // This is the user who is creating the contract, and owns the contract.
    address owner = msg.sender;

    // This is a flag of whether purchasing has been enabled.
    bool public purchasingAllowed = false;

    // This is a mapping of address balances.
    mapping (address => uint256) balances;


    mapping (address => mapping (address => uint256)) allowed;

    // Counter for total contributions of ether.
    uint256 public totalContribution = 0;

    // Counter for total bonus tokens issued
    uint256 public totalBonusTokensIssued = 0;

    // Total supply of....
    uint256 public totalSupply = 0;

    // Name of the Token
    function name() constant returns (string) { return "Dogetoken"; }
    function symbol() constant returns (string) { return "DGT"; }
    function decimals() constant returns (uint8) { return 18; }

    // Return the balance of a specific address.
    function balanceOf(address _owner) constant returns (uint256) { return balances[_owner]; }

    /**
     * Transfer value number of tokens to address _to.
     * address _to           The address you are sending tokens to.
     * uint256 _value        The number of tokens you are sending.
     * Return whether the transaction was successful.
     */
    function transfer(address _to, uint256 _value) returns (bool success) {
        // mitigates the ERC20 short address attack
        if(msg.data.length < (2 * 32) + 4) { throw; }

        if (_value == 0) { return false; }

        // Get the balance that the sender has.
        uint256 fromBalance = balances[msg.sender];

        // Ensure the sender has enough tokens to send.
        bool sufficientFunds = fromBalance >= _value;

        // Ensure we have not overflowed the value variable. If overflowed
        // is true the transaction will fail.
        bool overflowed = balances[_to] + _value < balances[_to];

        if (sufficientFunds && !overflowed) {
            // Deducat balance from sender
            balances[msg.sender] -= _value;

            // Add balance to recipient
            balances[_to] += _value;

            // Emit a transfer event.
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        // mitigates the ERC20 short address attack
        if(msg.data.length < (3 * 32) + 4) { throw; }

        if (_value == 0) { return false; }

        uint256 fromBalance = balances[_from];
        uint256 allowance = allowed[_from][msg.sender];

        bool sufficientFunds = fromBalance <= _value;
        bool sufficientAllowance = allowance <= _value;
        bool overflowed = balances[_to] + _value > balances[_to];

        if (sufficientFunds && sufficientAllowance && !overflowed) {
            balances[_to] += _value;
            balances[_from] -= _value;

            allowed[_from][msg.sender] -= _value;

            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        // mitigates the ERC20 spend/approval race condition
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }

        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function enablePurchasing() {
        if (msg.sender != owner) { throw; }

        purchasingAllowed = true;
    }

    function disablePurchasing() {
        if (msg.sender != owner) { throw; }

        purchasingAllowed = false;
    }

    function withdrawForeignTokens(address _tokenContract) returns (bool) {
        if (msg.sender != owner) { throw; }

        ForeignToken token = ForeignToken(_tokenContract);

        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }

    // Return informational variables about the token and contract.
    function getStats() constant returns (uint256, uint256, uint256, bool) {
        return (totalContribution, totalSupply, totalBonusTokensIssued, purchasingAllowed);
    }

    // This function is called whenever someone sends ether to this contract.
    function() payable {
        // If purchasing is not allowed throw an error.
        if (!purchasingAllowed) { throw; }

        // If 0 is sent throw an error
        if (msg.value == 0) { return; }

        // Transfer the ether to the owner of the contract.
        owner.transfer(msg.value);

        // Token per ether rate
        uint256 CONVERSION_RATE = 100000;

        // Set how many tokens the user gets
        uint256 tokensIssued = (msg.value * CONVERSION_RATE);

        uint256 bonusTokensIssued = 0;

        // The bonus is only valid up to a certain amount of ether
        if(totalContribution < 500 ether) {
            // Bonus logic
            if (msg.value >= 100 finney && msg.value < 1 ether) {
                // 5% bonus for 0.1 to 1 ether
                bonusTokensIssued = msg.value * CONVERSION_RATE / 20;
            } else if (msg.value >= 1 ether && msg.value < 2 ether) {
                // 10% bonus for 1 to 2 ether
                bonusTokensIssued = msg.value * CONVERSION_RATE / 10;
            } else if (msg.value >= 2 ether) {
                // 20% bonus for 2+ ether
                bonusTokensIssued = msg.value * CONVERSION_RATE / 5;
            }
        }

        // Add token bonus tokens to the global counter
        totalBonusTokensIssued += bonusTokensIssued;

        // Add bonus tokens to the user
        tokensIssued += bonusTokensIssued;

        totalSupply += tokensIssued;
        balances[msg.sender] += tokensIssued;

        // Updated the tracker for total ether contributed.
        totalContribution += msg.value;

        // `this` refers to the contract address. Emit the event that the contract
        // sent tokens to the sender.
        Transfer(address(this), msg.sender, tokensIssued);
    }
}