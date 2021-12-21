/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

/**
 *Submitted for verification at Etherscan.io on 2017-02-14
*/

pragma solidity ^0.4.8;



/**
 * Dentacoin extended ERC20 token contract created on February the 14th, 2017 by Dentacoin B.V. in the Netherlands
 *
 * For terms and conditions visit https://dentacoin.com
 */



contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner == 0x0) throw;
        owner = newOwner;
    }
}




/**
 * Overflow aware uint math functions.
 */
contract SafeMath {
    //internals

    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function assert(bool assertion) internal {
        if (!assertion) throw;
    }
}




contract Token {
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





contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
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
            balances[_from] -= _value;
            balances[_to] += _value;
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

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}







/* Dentacoin Contract */
contract DentacoinToken is owned, SafeMath, StandardToken {
    string public name = "Dentacoin";                                       // Set the name for display purposes
    string public symbol = "٨";                                             // Set the symbol for display purposes
    address public DentacoinAddress = this;                                 // Address of the Dentacoin token
    uint8 public decimals = 0;                                              // Amount of decimals for display purposes
    uint256 public totalSupply = 8000000000000;                             // Set total supply of Dentacoins (eight trillion)
    uint256 public buyPriceEth = 1 finney;                                  // Buy price for Dentacoins
    uint256 public sellPriceEth = 1 finney;                                 // Sell price for Dentacoins
    uint256 public gasForDCN = 5 finney;                                    // Eth from contract against DCN to pay tx (10 times sellPriceEth)
    uint256 public DCNForGas = 10;                                          // DCN to contract against eth to pay tx
    uint256 public gasReserve = 1 ether;                                    // Eth amount that remains in the contract for gas and can't be sold
    uint256 public minBalanceForAccounts = 10 finney;                       // Minimal eth balance of sender and recipient
    bool public directTradeAllowed = false;                                 // Halt trading DCN by sending to the contract directly


    /* Initializes contract with initial supply tokens to the creator of the contract */
    function DentacoinToken() {
        balances[msg.sender] = totalSupply;                                 // Give the creator all tokens
    }


    /* Constructor parameters */
    function setEtherPrices(uint256 newBuyPriceEth, uint256 newSellPriceEth) onlyOwner {
        buyPriceEth = newBuyPriceEth;                                       // Set prices to buy and sell DCN
        sellPriceEth = newSellPriceEth;
    }
    function setGasForDCN(uint newGasAmountInWei) onlyOwner {
        gasForDCN = newGasAmountInWei;
    }
    function setDCNForGas(uint newDCNAmount) onlyOwner {
        DCNForGas = newDCNAmount;
    }
    function setGasReserve(uint newGasReserveInWei) onlyOwner {
        gasReserve = newGasReserveInWei;
    }
    function setMinBalance(uint minimumBalanceInWei) onlyOwner {
        minBalanceForAccounts = minimumBalanceInWei;
    }


    /* Halts or unhalts direct trades without the sell/buy functions below */
    function haltDirectTrade() onlyOwner {
        directTradeAllowed = false;
    }
    function unhaltDirectTrade() onlyOwner {
        directTradeAllowed = true;
    }


    /* Transfer function extended by check of eth balances and pay transaction costs with DCN if not enough eth */
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (_value < DCNForGas) throw;                                      // Prevents drain and spam
        if (msg.sender != owner && _to == DentacoinAddress && directTradeAllowed) {
            sellDentacoinsAgainstEther(_value);                             // Trade Dentacoins against eth by sending to the token contract
            return true;
        }

        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {               // Check if sender has enough and for overflows
            balances[msg.sender] = safeSub(balances[msg.sender], _value);   // Subtract DCN from the sender

            if (msg.sender.balance >= minBalanceForAccounts && _to.balance >= minBalanceForAccounts) {    // Check if sender can pay gas and if recipient could
                balances[_to] = safeAdd(balances[_to], _value);             // Add the same amount of DCN to the recipient
                Transfer(msg.sender, _to, _value);                          // Notify anyone listening that this transfer took place
                return true;
            } else {
                balances[this] = safeAdd(balances[this], DCNForGas);        // Pay DCNForGas to the contract
                balances[_to] = safeAdd(balances[_to], safeSub(_value, DCNForGas));  // Recipient balance -DCNForGas
                Transfer(msg.sender, _to, safeSub(_value, DCNForGas));      // Notify anyone listening that this transfer took place

                if(msg.sender.balance < minBalanceForAccounts) {
                    if(!msg.sender.send(gasForDCN)) throw;                  // Send eth to sender
                }
                if(_to.balance < minBalanceForAccounts) {
                    if(!_to.send(gasForDCN)) throw;                         // Send eth to recipient
                }
            }
        } else { throw; }
    }


    /* User buys Dentacoins and pays in Ether */
    function buyDentacoinsAgainstEther() payable returns (uint amount) {
        if (buyPriceEth == 0 || msg.value < buyPriceEth) throw;             // Avoid dividing 0, sending small amounts and spam
        amount = msg.value / buyPriceEth;                                   // Calculate the amount of Dentacoins
        if (balances[this] < amount) throw;                                 // Check if it has enough to sell
        balances[msg.sender] = safeAdd(balances[msg.sender], amount);       // Add the amount to buyer's balance
        balances[this] = safeSub(balances[this], amount);                   // Subtract amount from Dentacoin balance
        Transfer(this, msg.sender, amount);                                 // Execute an event reflecting the change
        return amount;
    }


    /* User sells Dentacoins and gets Ether */
    function sellDentacoinsAgainstEther(uint256 amount) returns (uint revenue) {
        if (sellPriceEth == 0 || amount < DCNForGas) throw;                 // Avoid selling and spam
        if (balances[msg.sender] < amount) throw;                           // Check if the sender has enough to sell
        revenue = safeMul(amount, sellPriceEth);                            // Revenue = eth that will be send to the user
        if (safeSub(this.balance, revenue) < gasReserve) throw;             // Keep min amount of eth in contract to provide gas for transactions
        if (!msg.sender.send(revenue)) {                                    // Send ether to the seller. It's important
            throw;                                                          // To do this last to avoid recursion attacks
        } else {
            balances[this] = safeAdd(balances[this], amount);               // Add the amount to Dentacoin balance
            balances[msg.sender] = safeSub(balances[msg.sender], amount);   // Subtract the amount from seller's balance
            Transfer(this, msg.sender, revenue);                            // Execute an event reflecting on the change
            return revenue;                                                 // End function and returns
        }
    }


    /* refund to owner */
    function refundToOwner (uint256 amountOfEth, uint256 dcn) onlyOwner {
        uint256 eth = safeMul(amountOfEth, 1 ether);
        if (!msg.sender.send(eth)) {                                        // Send ether to the owner. It's important
            throw;                                                          // To do this last to avoid recursion attacks
        } else {
            Transfer(this, msg.sender, eth);                                // Execute an event reflecting on the change
        }
        if (balances[this] < dcn) throw;                                    // Check if it has enough to sell
        balances[msg.sender] = safeAdd(balances[msg.sender], dcn);          // Add the amount to buyer's balance
        balances[this] = safeSub(balances[this], dcn);                      // Subtract amount from seller's balance
        Transfer(this, msg.sender, dcn);                                    // Execute an event reflecting the change
    }


    /* This unnamed function is called whenever someone tries to send ether to it and possibly sells Dentacoins */
    function() payable {
        if (msg.sender != owner) {
            if (!directTradeAllowed) throw;
            buyDentacoinsAgainstEther();                                    // Allow direct trades by sending eth to the contract
        }
    }
}

/* JJG */