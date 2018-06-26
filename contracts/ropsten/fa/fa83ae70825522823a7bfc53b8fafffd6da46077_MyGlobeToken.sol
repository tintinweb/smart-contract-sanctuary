pragma solidity ^0.4.21;

contract owned {
    address public owner;


    function owned() public {
        owner = msg.sender;
    }


    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }


contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;


    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public pointsbalanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);


    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);


    /**
     * Constrctor function
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
        ) public {
            totalSupply = initialSupply * 10 ** uint256(decimals);              // Update total supply with the decimal amount
            balanceOf[this] = totalSupply;                                      // Give the CONTRACT all the initial tokens
            name = tokenName;                                                   // Set the name for display purposes
            symbol = tokenSymbol;                                               // Set the symbol for display purposes
    }


    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        
        require(_to != 0x0);                                                    // Prevent transfer to 0x0 address. Use burn() instead
        require(balanceOf[_from] >= _value);                                    // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]);                      // Check for overflows
        uint previousBalances = balanceOf[_from] + balanceOf[_to];              // Save this for an assertion in the future
        balanceOf[_from] -= _value;                                             // Subtract from the sender
        balanceOf[_to] += _value;                                               // Add the same to the recipient
        emit Transfer(_from, _to, _value);                                      // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     * Send `_value` tokens to `_to` from your account
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }


    /**
     * Destroy tokens
     * Remove `_value` tokens from the system irreversibly
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);                               // Check if the sender has enough
        balanceOf[msg.sender] -= _value;                                        // Subtract from the sender
        totalSupply -= _value;                                                  // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }


    /**
     * Destroy tokens from other account
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                                    // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);                        // Check allowance
        balanceOf[_from] -= _value;                                             // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;                                 // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                                                  // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
    
    
}



//******************************************/
/*        MYGLOBE TOKEN STARTS HERE        */
//******************************************/

contract MyGlobeToken is owned, TokenERC20 {

    uint256 public sellPrice;
    uint256 public buyPrice;
    uint256 public circulation;
    uint256 public Tokens_in_Circulation;
    uint256 baseprice;
    address public mgfaddress;
    address public charityaddress;
    bool public initiatedstatus;
    uint public txpct;
    uint public altpct;
    uint256 public requiredbalance;
    uint256 public excessbalance;
    uint256 public pointscount;


    mapping (address => bool) public frozenAccount;


    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);


    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MyGlobeToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol)  public  {
        baseprice = 50000000;
        charityaddress = 0xa08b9E8e0C5c308D1a489974ad1f71eF890c53D0;
        mgfaddress = 0xaB438Ca1CCcD54328fc081727fB42D87c77b0A0D;
        requiredbalance = ((circulation * sellPrice / 2) / 10^18);
        excessbalance = address(this).balance - requiredbalance;
    }


    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require (_to != 0x0);                                                   // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);                                   // Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to]);                    // Check for overflows
        require(!frozenAccount[_from]);                                         // Check if sender is frozen
        require(!frozenAccount[_to]);                                           // Check if recipient is frozen
        balanceOf[_from] -= _value;                                             // Subtract from the sender
        balanceOf[_to] += _value;                                               // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }
    
    
    /**
     * Transfer tokens from other address
     * Send `_value` tokens to `_to` in behalf of `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);                        // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }


    /// @notice Create `mintedAmount` tokens 
    /// @param mintedAmount the amount of tokens to be created
    function mintToken(uint256 mintedAmount) onlyOwner public {
        balanceOf[this] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
    }


    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }


    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice, uint256 newCirculation) internal {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
        circulation = newCirculation;
        Tokens_in_Circulation = newCirculation;
    }
    
    /// @notice Set the transaction fee to `newtxpct` 
    /// @param newtxpct The percentage spent in fees
    function settxpct (uint newtxpct) onlyOwner public {
        require(newtxpct <= 100 && newtxpct >= 0);
        altpct = 100 - newtxpct;
        txpct = newtxpct;
    }
    
    /// @notice Send `pointsvalue` points to &#39;pointsto&#39; 
    /// @param pointsto The address that will receive the points 
    /// @param pointsvalue The number of points to send     
    function transferpoints(address pointsto, uint256 pointsvalue) public {
        require(pointsto != 0x0);                                               // Prevent transfer to 0x0 address. Use burn() instead
        require(pointsbalanceOf[msg.sender] >= pointsvalue);                    // Check if the sender has enough
        require(pointsbalanceOf[pointsto] + pointsvalue > pointsbalanceOf[pointsto]);       // Check for overflows
        uint previousBalances = pointsbalanceOf[msg.sender] + pointsbalanceOf[pointsto];    // Save this for an assertion in the future
        pointsbalanceOf[msg.sender] -= pointsvalue;                             // Subtract from the sender
        pointsbalanceOf[pointsto] += pointsvalue;                               // Add the same to the recipient
        assert(pointsbalanceOf[msg.sender] + balanceOf[pointsto] == previousBalances);
    }
    
    
    function givepoints (address pointsto, uint256 pointsvalue) internal {
        pointsbalanceOf[pointsto] += pointsvalue;
        pointscount += pointsvalue;
    }
    

    function sqrt(uint256 x) internal returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }


    /// @notice Buy tokens from contract by sending ether
    function () payable public {
        uint256 buyvalue = msg.value;
        uint256 Quant0 = circulation;                                           //sets initial Quantity on graph
        uint256 Q1calc = (buyvalue * baseprice * (10^18) * 2) + (Quant0 ^ 2);   //gets number to sqrt
        uint256 Quant1 = sqrt(Q1calc);                                          //calculates Q1
        uint256 Price1 = Quant1 / baseprice;                                    //sets P1 on graph
        
        uint256 buyquant = Quant1 - Quant0;                                     //calculates number of tokens
        uint256 txfee = buyvalue /100 * txpct;                                   //calculates amount to send to charity
        uint256 NSP1 = Price1 /100 * altpct;        
        
        //Finalise
        setPrices(NSP1,Price1,Quant1);                                          //Sets prices
        _transfer(this, msg.sender, buyquant);                                  // makes the token transfers
        mgfaddress.transfer (txfee);                                            //sends 20% to charity
        givepoints(msg.sender, msg.value);                                      //give points to purchaser
    }


    /// @notice Sell `tokenamount` tokens to contract
    /// @param tokenamount Amount of tokens to be sold
    function sell(uint256 tokenamount) public {
        uint256 Quant1 = circulation;                                           //sets Q1 on graph
        uint256 Price1 = Quant1/baseprice;                                      //sets P1 on graph

        uint256 Quant0 = Quant1 - tokenamount;                                  //Calculates Q0
        uint256 Price0 = Quant0/baseprice;                                      //Calculates P0
        
        uint256 avgprice = (Price0+Price1)/2;                                   //Finds average price
        uint256 sellvalue = (avgprice * tokenamount) / (10 ** decimals);        //Average price * amount
        uint256 discsellvalue = sellvalue /100 * altpct;                        //Discounts sell value
        uint256 NSP0 = Price0 /100 * altpct;                                    //Finds new sell price
        
        //Finalise
        setPrices(NSP0,Price0,Quant0);                                          //Sets prices
        _transfer(msg.sender, this, tokenamount);                               //Transfers tokens from seller to contract
        msg.sender.transfer(discsellvalue);                                     //Sends ether to the seller. It&#39;s important to do this last to avoid recursion attacks
    }
    
    
    /// @notice Donate `tokenamount` tokens to charity in exchange for extra points
    /// @param tokenamount Amount of tokens to be donated to charity
    function donatetokens(uint256 tokenamount) public {
        uint256 Quant1 = circulation;                                           //sets Q1 on graph
        uint256 Price1 = Quant1/baseprice;                                      //sets P1 on graph

        uint256 Quant0 = Quant1 - tokenamount;                                  //Calculates Q0
        uint256 Price0 = Quant0/baseprice;                                      //Calculates P0
        
        uint256 avgprice = (Price0+Price1)/2;                                   //Finds average price
        uint256 sellvalue = (avgprice * tokenamount) / (10 ** decimals);        //Average price * amount
        uint256 discsellvalue = sellvalue /100 * altpct;                        //Discounts sell value
        uint256 NSP0 = Price0 /100 * altpct;                                    //Finds new sell price
        uint256 pointsbonus = discsellvalue * sqrt(txpct);
        
        //Finalise
        setPrices(NSP0,Price0,Quant0);                                          //Sets prices
        _transfer(msg.sender, this, tokenamount);                               //Transfers tokens from seller to contract
        givepoints(msg.sender, pointsbonus);                                    //give bonus points to donor
        charityaddress.transfer(discsellvalue);                                 //Sends ether to the seller. It&#39;s important to do this last to avoid recursion attack 
    }


    function estimatesellvalue (uint256 tokenamount) public returns (uint256 discsellvalue) {
        uint256 Quant1 = circulation;                                           //sets Q1 on graph
        uint256 Price1 = Quant1/baseprice;                                      //sets P1 on graph

        uint256 Quant0 = Quant1 - tokenamount;                                  //Calculates Q0
        uint256 Price0 = Quant0/baseprice;                                      //Calculates P0
        
        uint256 avgprice = (Price0 + Price1) / 2;                               //Finds average price
        uint256 sellvalue = avgprice * tokenamount / (10 ** decimals);          //Average price * amount
        
        discsellvalue = sellvalue /100 * altpct;                                //Discounts sell value
    }


    //***************************** OWNER INTERFACE ****************************   
    
    function initiatecontract() onlyOwner public returns (bool success){
        //require (initiatedstatus == false); 
        setPrices(0,0,0);
        settxpct(20);
        initiatedstatus = true;
        success = true;
    } 
    
    
    function drainexcess() onlyOwner public {
        if (excessbalance > 0) {
            mgfaddress.transfer(excessbalance);
        } 
    }
    
    
    //*****************TO BE REMOVED WHEN IT ALL FINALLY WORKS******************
    
    function destructo() onlyOwner public {
        selfdestruct(mgfaddress);
    }
    
    
}