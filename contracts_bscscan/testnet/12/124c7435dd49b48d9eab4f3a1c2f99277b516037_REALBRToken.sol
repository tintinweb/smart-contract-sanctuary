/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

pragma solidity ^0.4.13;
contract owned {
    /* Owner definition. */
    address public owner; // Owner address.
    function owned() { owner = msg.sender; }
    modifier onlyOwner { require(msg.sender == owner); _; }
    function transferOwnership(address newOwner) onlyOwner { owner = newOwner; }
}
contract token { 
    /* Base token definition. */
    string  public name;    // Name for the token.
    string  public symbol ;    // Symbol for the token.
    uint8   public decimals;    // Number of decimals of the token.
    uint256 public totalSupply; // Total of tokens created.

    // Array containing the balance foreach address.
    mapping (address => uint256) public balanceOf;
    // Array containing foreach address, an array containing each approved address and the amount of tokens it can spend.
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify about a transfer done. */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes the contract */
    function token(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) {
        balanceOf[msg.sender] = initialSupply; // Gives the creator all initial tokens.
        totalSupply           = initialSupply; // Update total supply.
        name                  = tokenName;     // Set the name for display purposes.
        symbol                = tokenSymbol;  // Set the symbol for display purposes.
        decimals              = decimalUnits;  // Amount of decimals for display purposes.
    }

    /* Internal transfer, only can be called by this contract. */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead.
        require(balanceOf[_from] > _value);                // Check if the sender has enough.
        require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows.
        balanceOf[_from] -= _value; // Subtract from the sender.
        balanceOf[_to]   += _value; // Add the same to the recipient.
        Transfer(_from, _to, _value); // Notifies the blockchain about the transfer.
    }

    /// @notice Send `_value` tokens to `_to` from your account.
    /// @param _to The address of the recipient.
    /// @param _value The amount to send.
    function transfer(address _to, uint256 _value) {
        _transfer(msg.sender, _to, _value);
    }

    /// @notice Send `_value` tokens to `_to` in behalf of `_from`.
    /// @param _from The address of the sender.
    /// @param _to The address of the recipient.
    /// @param _value The amount to send.
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(_value <= allowance[_from][msg.sender]); // Check allowance.
        allowance[_from][msg.sender] -= _value; // Updates the allowance array, substracting the amount sent.
        _transfer(_from, _to, _value); // Makes the transfer.
        return true;
    }

    /// @notice Allows `_spender` to spend a maximum of `_value` tokens in your behalf.
    /// @param _spender The address authorized to spend.
    /// @param _value The max amount they can spend.
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value; // Adds a new register to allowance, permiting _spender to use _value of your tokens.
        return true;
    }
}

contract REALBRToken is owned, token {
    /* Specific token definition for -Bitcoin StartUp Capital S.A.- company. */
    uint256 public sellPrice         = 5000000000000000;  // Price applied if someone wants to sell a token.
    uint256 public buyPrice          = 10000000000000000; // Price applied if someone wants to buy a token.
    bool    public closeBuy          = false;             // If true, nobody will be able to buy.
    bool    public closeSell         = false;             // If true, nobody will be able to sell.
    uint256 public tokensAvailable   = balanceOf[this];   // Number of tokens available for sell.
    uint256 public distributedTokens = 0;                 // Number of tokens distributed.
    uint256 public solvency          = this.balance;      // Amount of Ether available to pay sales.
    uint256 public profit            = 0;                 // Shows the actual profit for the company.

    // Array containing foreach address if it's frozen or not.
    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify about an address being freezed. */
    event FrozenFunds(address target, bool frozen);
    /* This generates a public event on the blockchain that will notify about an addition of Ether to the contract. */
    event LogDeposit(address sender, uint amount);
    /* This generates a public event on the blockchain that will notify about a migration has been completed. */
    event LogMigration(address receiver, uint amount);
    /* This generates a public event on the blockchain that will notify about a Withdrawal of Ether from the contract. */
    event LogWithdrawal(address receiver, uint amount);

    /* Initializes the contract */
    function REALBRToken( uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol ) token (initialSupply, tokenName, decimalUnits, tokenSymbol) {}

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);                               // Prevent transfer to 0x0 address. User should use burn() instead.
        require(balanceOf[_from] >= _value);               // Check if the sender has enough.
        require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows.
        require(!frozenAccount[_from]);                    // Check if sender is frozen.
        require(!frozenAccount[_to]);                      // Check if recipient is frozen.
        
        balanceOf[_from] -= _value; // Subtracts from the sender.
        balanceOf[_to]   += _value; // Adds the same to the recipient.

        _updateTokensAvailable(balanceOf[this]); // Update the balance of tokens available if necessary.
        
        Transfer(_from, _to, _value); // Notifies the blockchain about the transfer.
    }

    /* Internal, updates the balance of tokens available. */
    function _updateTokensAvailable(uint256 _tokensAvailable) internal {
        tokensAvailable = _tokensAvailable;
    }

    /* Internal, updates the balance of Ether available in order to cover potential sales. */
    function _updateSolvency(uint256 _solvency) internal {
        solvency = _solvency;
    }

    /* Internal, updates the profit value */
    function _updateProfit(uint256 _increment, bool add) internal{
        if (add){
            // Increase the profit value
            profit = profit + _increment;
        }else{
            // Decrease the profit value
            if(_increment > profit){
                profit = 0;
            }else{
                profit = profit - _increment;
            }
        }
    }

    /// @notice The owner sends `_value` tokens to `_to`, because `_to` have the right. The tokens migrated count as pre-distributed ones.
    /// @param _to The address of the recipient.
    /// @param _value The amount to send.
    function completeMigration(address _to, uint256 _value) onlyOwner payable{
        require( msg.value >= (_value * sellPrice) );       // Owner has to send enough ETH to proceed.
        require((this.balance + msg.value) > this.balance); // Checks for overflows.
        
        //Contract has already received the Ether when this function is executed.
        _updateSolvency(this.balance);   // Updates the value of solvency of the contract.
        _updateProfit(msg.value, false); // Decrease profit value.
        // Decrease because the owner invests his own Ether in order to guarantee the solvency.

        _transfer(msg.sender, _to, _value); // Transfers the tokens to the investor's address.
        distributedTokens = distributedTokens + _value; // Increase the number of tokens distributed.

        LogMigration( _to, _value); // Notifies the blockchain about the migration taking place.
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`.
    /// @param target Address to receive the tokens.
    /// @param mintedAmount The amount of tokens target will receive.
    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount; // Updates target's balance.
        totalSupply       += mintedAmount; // Updates totalSupply.

        _updateTokensAvailable(balanceOf[this]); // Update the balance of tokens available if necessary.
        
        Transfer(0, this, mintedAmount);      // Notifies the blockchain about the tokens created.
        Transfer(this, target, mintedAmount); // Notifies the blockchain about the transfer to target.
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens.
    /// @param target Address to be frozen.
    /// @param freeze Either to freeze target or not.
    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze; // Sets the target status. True if it's frozen, False if it's not.
        FrozenFunds(target, freeze); // Notifies the blockchain about the change of state.
    }

    /// @notice Allow addresses to pay `newBuyPrice`ETH when buying and receive `newSellPrice`ETH when selling, foreach token bought/sold.
    /// @param newSellPrice Price applied when an address sells its tokens, amount in WEI (1ETH = 10¹⁸WEI).
    /// @param newBuyPrice Price applied when an address buys tokens, amount in WEI (1ETH = 10¹⁸WEI).
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice; // Updates the buying price.
        buyPrice = newBuyPrice;   // Updates the selling price.
    }

    /// @notice Sets the state of buy and sell operations
    /// @param isClosedBuy True if buy operations are closed, False if opened.
    /// @param isClosedSell True if sell operations are closed, False if opened.
    function setStatus(bool isClosedBuy, bool isClosedSell) onlyOwner {
        closeBuy = isClosedBuy;   // Updates the state of buy operations.
        closeSell = isClosedSell; // Updates the state of sell operations.
    }

    /// @notice Deposits Ether to the contract
    function deposit() payable returns(bool success) {
        require((this.balance + msg.value) > this.balance); // Checks for overflows.
        
        //Contract has already received the Ether when this function is executed.
        _updateSolvency(this.balance);   // Updates the value of solvency of the contract.
        _updateProfit(msg.value, false); // Decrease profit value.
        // Decrease because deposits will be done mostly by the owner.
        // Possible donations won't count as profit. Atleast not for the company, but in favor of the investors.

        LogDeposit(msg.sender, msg.value); // Notifies the blockchain about the Ether received.
        return true;
    }

    /// @notice The owner withdraws Ether from the contract.
    /// @param amountInWeis Amount of ETH in WEI which will be withdrawed.
    function withdraw(uint amountInWeis) onlyOwner {
        LogWithdrawal(msg.sender, amountInWeis); // Notifies the blockchain about the withdrawal.
        _updateSolvency( (this.balance - amountInWeis) ); // Updates the value of solvency of the contract.
        _updateProfit(amountInWeis, true);                // Increase the profit value.
        owner.transfer(amountInWeis); // Sends the Ether to owner address.
    }

    /// @notice Buy tokens from contract by sending Ether.
    function buy() payable {
        require(!closeBuy); // Buy operations must be opened.
        uint amount = msg.value / buyPrice; // Calculates the amount of tokens to be sent.
        uint256 profit_in_transaction = msg.value - (amount * sellPrice); // Calculates the relative profit for this transaction.
        require( profit_in_transaction > 0 );

        //Contract has already received the Ether when this function is executed.
        _transfer(this, msg.sender, amount); // Makes the transfer of tokens.
        distributedTokens = distributedTokens + amount; // Increase the number of tokens distributed.
        _updateSolvency(this.balance - profit_in_transaction);   // Updates the value of solvency of the contract.
        _updateProfit(profit_in_transaction, true);              // Increase the profit value.
        owner.transfer(profit_in_transaction); // Sends profit to the owner of the contract.
    }

    /// @notice Sell `amount` tokens to the contract.
    /// @param amount amount of tokens to be sold.
    function sell(uint256 amount) {
        require(!closeSell); // Sell operations must be opened.
        require(this.balance >= amount * sellPrice); // Checks if the contract has enough Ether to buy.
        
        _transfer(msg.sender, this, amount); // Makes the transfer of tokens, the contract receives the tokens.
        distributedTokens = distributedTokens - amount; // Decrease the number of tokens distributed.
        _updateSolvency( (this.balance - (amount * sellPrice)) ); // Updates the value of solvency of the contract.
        msg.sender.transfer(amount * sellPrice); // Sends Ether to the seller.
    }
}