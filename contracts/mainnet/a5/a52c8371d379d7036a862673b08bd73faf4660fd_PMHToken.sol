pragma solidity ^0.4.18;



contract owned {
    /* Owner definition. */
    address public owner; // Owner address.
    function owned() internal {
        owner = msg.sender ;
    }

    modifier onlyOwner {
        require(msg.sender == owner); _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract token { 
    /* Base token definition. */
    string  public name;        // Name for the token.
    string  public symbol;      // Symbol for the token.
    uint8   public decimals;    // Number of decimals of the token.
    uint256 public totalSupply; // Total of tokens created.

    // Array containing the balance foreach address.
    mapping (address => uint256) public balanceOf;
    // Array containing foreach address, an array containing each approved address and the amount of tokens it can spend.
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify about a transfer done. */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes the contract */
    function token(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) internal {
        balanceOf[msg.sender] = initialSupply; // Gives the creator all initial tokens.
        totalSupply           = initialSupply; // Update total supply.
        name                  = tokenName;     // Set the name for display purposes.
        symbol                = tokenSymbol;   // Set the symbol for display purposes.
        decimals              = decimalUnits;  // Amount of decimals for display purposes.
    }

    /* Internal transfer, only can be called by this contract. */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);                               // Prevent transfer to 0x0 address.
        require(balanceOf[_from] > _value);                // Check if the sender has enough.
        require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows.
        balanceOf[_from] -= _value; // Subtract from the sender.
        balanceOf[_to]   += _value; // Add the same to the recipient.
        Transfer(_from, _to, _value); // Notifies the blockchain about the transfer.
    }

    /// @notice Send `_value` tokens to `_to` from your account.
    /// @param _to The address of the recipient.
    /// @param _value The amount to send.
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /// @notice Send `_value` tokens to `_to` in behalf of `_from`.
    /// @param _from The address of the sender.
    /// @param _to The address of the recipient.
    /// @param _value The amount to send.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]); // Check allowance.
        allowance[_from][msg.sender] -= _value; // Updates the allowance array, substracting the amount sent.
        _transfer(_from, _to, _value); // Makes the transfer.
        return true;
    }

    /// @notice Allows `_spender` to spend a maximum of `_value` tokens in your behalf.
    /// @param _spender The address authorized to spend.
    /// @param _value The max amount they can spend.
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value; // Adds a new register to allowance, permiting _spender to use _value of your tokens.
        return true;
    }
}

contract PMHToken is owned, token {
    /* Specific token definition for -HormitechToken-. */
    uint256 public sellPrice         = 5000000000000000;  // Price applied if someone wants to sell a token.
    uint256 public buyPrice          = 10000000000000000; // Price applied if someone wants to buy a token.
    bool    public closeBuy          = false;             // If true, nobody will be able to buy.
    bool    public closeSell         = false;             // If true, nobody will be able to sell.
    uint256 public tokensAvailable   = balanceOf[this];   // Number of tokens available for sell.
    uint256 public solvency          = this.balance;      // Amount of Ether available to pay sales.
    uint256 public profit            = 0;                 // Shows the actual profit for the company.
    address public comisionGetter = 0x70B593f89DaCF6e3BD3e5bD867113FEF0B2ee7aD ; // The address that gets the comisions paid.

// added MAR 2018
    mapping (address => string ) public emails ;   // Array containing the e-mail addresses of the token holders 
    mapping (uint => uint) public dividends ; // for each period in the index, how many weis set for dividends distribution

    mapping (address => uint[]) public paidDividends ; // for each address, if the period dividend was paid or not and the amount 
// added MAR 2018

    mapping (address => bool) public frozenAccount; // Array containing foreach address if it&#39;s frozen or not.

    /* This generates a public event on the blockchain that will notify about an address being freezed. */
    event FrozenFunds(address target, bool frozen);
    /* This generates a public event on the blockchain that will notify about an addition of Ether to the contract. */
    event LogDeposit(address sender, uint amount);
    /* This generates a public event on the blockchain that will notify about a Withdrawal of Ether from the contract. */
    event LogWithdrawal(address receiver, uint amount);

    /* Initializes the contract */
    function PMHToken(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) public 
    token (initialSupply, tokenName, decimalUnits, tokenSymbol) {}

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);                               // Prevent transfer to 0x0 address.
        require(balanceOf[_from] >= _value);               // Check if the sender has enough.
        require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows.
        require(!frozenAccount[_from]);                    // Check if sender is frozen.
        require(!frozenAccount[_to]);                      // Check if recipient is frozen.
		balanceOf[_from] -= _value; // Subtracts _value tokens from the sender.
        balanceOf[_to]   += _value; // Adds the same amount to the recipient.

        _updateTokensAvailable(balanceOf[this]); // Update the balance of tokens available if necessary.
        Transfer(_from, _to, _value); // Notifies the blockchain about the transfer.
    }

    function refillTokens(uint256 _value) public onlyOwner{
        // Owner sends tokens to the contract.
        _transfer(msg.sender, this, _value);
    }

    /* Overrides basic transfer function due to comision value */
    function transfer(address _to, uint256 _value) public {
    	// This function requires a comision value of 0.4% of the market value.
        uint market_value = _value * sellPrice;
        uint comision = market_value * 4 / 1000;
        // The token smart-contract pays comision, else the transfer is not possible.
        require(this.balance >= comision);
        comisionGetter.transfer(comision); // Transfers comision to the comisionGetter.
        _transfer(msg.sender, _to, _value);
    }

    /* Overrides basic transferFrom function due to comision value */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]); // Check allowance.
        // This function requires a comision value of 0.4% of the market value.
        uint market_value = _value * sellPrice;
        uint comision = market_value * 4 / 1000;
        // The token smart-contract pays comision, else the transfer is not possible.
        require(this.balance >= comision);
        comisionGetter.transfer(comision); // Transfers comision to the comisionGetter.
        allowance[_from][msg.sender] -= _value; // Updates the allowance array, substracting the amount sent.
        _transfer(_from, _to, _value); // Makes the transfer.
        return true;
    }

    /* Internal, updates the balance of tokens available. */
    function _updateTokensAvailable(uint256 _tokensAvailable) internal { tokensAvailable = _tokensAvailable; }

    /* Internal, updates the balance of Ether available in order to cover potential sales. */
    function _updateSolvency(uint256 _solvency) internal { solvency = _solvency; }

    /* Internal, updates the profit value */
    function _updateProfit(uint256 _increment, bool add) internal{
        if (add){
            // Increase the profit value
            profit = profit + _increment;
        }else{
            // Decrease the profit value
            if(_increment > profit){ profit = 0; }
            else{ profit = profit - _increment; }
        }
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`.
    /// @param target Address to receive the tokens.
    /// @param mintedAmount The amount of tokens target will receive.
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount; // Updates target&#39;s balance.
        totalSupply       += mintedAmount; // Updates totalSupply.
        _updateTokensAvailable(balanceOf[this]); // Update the balance of tokens available if necessary.
        Transfer(0, this, mintedAmount);      // Notifies the blockchain about the tokens created.
        Transfer(this, target, mintedAmount); // Notifies the blockchain about the transfer to target.
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens.
    /// @param target Address to be frozen.
    /// @param freeze Either to freeze target or not.
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze; // Sets the target status. True if it&#39;s frozen, False if it&#39;s not.
        FrozenFunds(target, freeze); // Notifies the blockchain about the change of state.
    }

    /// @notice Allow addresses to pay `newBuyPrice`ETH when buying and receive `newSellPrice`ETH when selling, foreach token bought/sold.
    /// @param newSellPrice Price applied when an address sells its tokens, amount in WEI (1ETH = 10&#185;⁸WEI).
    /// @param newBuyPrice Price applied when an address buys tokens, amount in WEI (1ETH = 10&#185;⁸WEI).
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice; // Updates the buying price.
        buyPrice = newBuyPrice;   // Updates the selling price.
    }

    /// @notice Sets the state of buy and sell operations
    /// @param isClosedBuy True if buy operations are closed, False if opened.
    /// @param isClosedSell True if sell operations are closed, False if opened.
    function setStatus(bool isClosedBuy, bool isClosedSell) onlyOwner public {
        closeBuy = isClosedBuy;   // Updates the state of buy operations.
        closeSell = isClosedSell; // Updates the state of sell operations.
    }

    /// @notice Deposits Ether to the contract
    function deposit() payable public returns(bool success) {
        require((this.balance + msg.value) > this.balance); // Checks for overflows.
        //Contract has already received the Ether when this function is executed.
        _updateSolvency(this.balance);   // Updates the solvency value of the contract.
        _updateProfit(msg.value, false); // Decrease profit value.
        // Decrease because deposits will be done mostly by the owner.
        // Possible donations won&#39;t count as profit for the company, but in favor of the investors.
        LogDeposit(msg.sender, msg.value); // Notifies the blockchain about the Ether received.
        return true;
    }

    /// @notice The owner withdraws Ether from the contract.
    /// @param amountInWeis Amount of ETH in WEI which will be withdrawed.
    function withdraw(uint amountInWeis) onlyOwner public {
        LogWithdrawal(msg.sender, amountInWeis); // Notifies the blockchain about the withdrawal.
        _updateSolvency( (this.balance - amountInWeis) ); // Updates the solvency value of the contract.
        _updateProfit(amountInWeis, true);                // Increase the profit value.
        owner.transfer(amountInWeis); // Sends the Ether to owner address.
    }

    function withdrawDividends(uint amountInWeis) internal returns(bool success) {
        LogWithdrawal(msg.sender, amountInWeis); // Notifies the blockchain about the withdrawal.
        _updateSolvency( (this.balance - amountInWeis) ); // Updates the solvency value of the contract.
        msg.sender.transfer(amountInWeis); // Sends the Ether to owner address.
        return true ; 
    }

    /// @notice Buy tokens from contract by sending Ether.
    function buy() public payable {
        require(!closeBuy); //Buy operations must be opened
        uint amount = msg.value / buyPrice; //Calculates the amount of tokens to be sent
        uint market_value = amount * buyPrice; //Market value for this amount
        uint comision = market_value * 4 / 1000; //Calculates the comision for this transaction
        uint profit_in_transaction = market_value - (amount * sellPrice) - comision; //Calculates the relative profit for this transaction
        require(this.balance >= comision); //The token smart-contract pays comision, else the operation is not possible.
        comisionGetter.transfer(comision); //Transfers comision to the comisionGetter.
        _transfer(this, msg.sender, amount); //Makes the transfer of tokens.
        _updateSolvency((this.balance - profit_in_transaction)); //Updates the solvency value of the contract.
        _updateProfit(profit_in_transaction, true); //Increase the profit value.
        owner.transfer(profit_in_transaction); //Sends profit to the owner of the contract.
    }

    /// @notice Sell `amount` tokens to the contract.
    /// @param amount amount of tokens to be sold.
    function sell(uint256 amount) public {
        require(!closeSell); //Sell operations must be opened
        uint market_value = amount * sellPrice; //Market value for this amount
        uint comision = market_value * 4 / 1000; //Calculates the comision for this transaction
        uint amount_weis = market_value + comision; //Total in weis that must be paid
        require(this.balance >= amount_weis); //Contract must have enough weis
        comisionGetter.transfer(comision); //Transfers comision to the comisionGetter
        _transfer(msg.sender, this, amount); //Makes the transfer of tokens, the contract receives the tokens.
        _updateSolvency( (this.balance - amount_weis) ); //Updates the solvency value of the contract.
        msg.sender.transfer(market_value); //Sends Ether to the seller.
    }

    /// Default function, sender buys tokens by sending ether to the contract:
    function () public payable { buy(); }


    function setDividends(uint _period, uint _totalAmount) onlyOwner public returns (bool success) {
        require(this.balance >= _totalAmount ) ; 
// period is 201801 201802 etc. yyyymm - no more than 1 dividend distribution per month
        dividends[_period] = _totalAmount ; 
        return true ; 
    } 


function setEmail(string _email ) public returns (bool success) {
    require(balanceOf[msg.sender] > 0 ) ;
   // require(emails[msg.sender] == "" ) ; // checks the e-mail for this address was not already set
    emails[msg.sender] = _email ; 
    return true ; 
    } 


    function dividendsGetPaid(uint _period) public returns (bool success) {
     uint percentageDividends ; 
     uint qtyDividends ; 

     require(!frozenAccount[msg.sender]); // frozen accounts are not allowed to withdraw ether 
     require(balanceOf[msg.sender] > 0 ) ; // sender has a positive balance of tokens to get paid 
     require(dividends[_period] > 0) ; // there is an active dividend period  
     require(paidDividends[msg.sender][_period] == 0) ;  // the dividend for this token holder was not yet paid

    // using here a 10000 (ten thousand) arbitrary multiplying factor for floating point precision
     percentageDividends = (balanceOf[msg.sender] / totalSupply  ) * 10000 ; 
     qtyDividends = ( percentageDividends * dividends[_period] ) / 10000  ;
     require(this.balance >= qtyDividends) ; // contract has enough ether to pay this dividend 
     paidDividends[msg.sender][_period] = qtyDividends ;  // record the dividend was paid 
     require(withdrawDividends(qtyDividends)); 
     return true ; 

    }


function adminResetEmail(address _address, string _newEmail ) public onlyOwner  {
    require(balanceOf[_address] > 0 ) ;
    emails[_address] = _newEmail ; 
    
    } 



}