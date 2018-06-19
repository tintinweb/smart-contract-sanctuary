pragma solidity ^0.4.16;

// The following is the Ethereum Mining Manager Contract, Version Two.

// It assumes that each graphics card draws 80 watts (75 watts for gtx 1050 ti and 5 watts for 1/13 of the rig, an underestimate)
// It also assumes that the cost of electricity is .20$/KWh
// Tokens can only be tranferred by their owners.

// Tokens(Graphics Cards) can be created to and destroyed from anyone if done by the Contract creator.


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

contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    //mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }


    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        //require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        //allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
}

/******************************************/
/*       MINING CONTRACT MAIN CODE        */
/******************************************/

contract MiningToken is owned, TokenERC20 {
    uint256 public supplyReady;  // How many are in stock to be bought (set to zero to disable the buying of cards)
    uint256 public min4payout;   // Minimum ether in contract for payout to be allowed
    uint256 public centsPerMonth;// Cost to run a card
    mapping(uint256 => address) public holders;    // Contract&#39;s list of people who own graphics cards
    mapping(address => uint256) public indexes;
    uint256 public num_holders=1;
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MiningToken(
        string tokenName,
        string tokenSymbol
    ) TokenERC20(0, tokenName, tokenSymbol) public {
        centsPerMonth=0;
        decimals=0;
        setMinimum(0);
        holders[num_holders++]=(msg.sender);
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        if(indexes[_to]==0||holders[indexes[_to]]==0){
            indexes[_to]=num_holders;
            holders[num_holders++]=_to;
        }
        Transfer(_from, _to, _value);
    }
	
	// Set minimum payout
    function setMinimum(uint256 d) onlyOwner public{
        min4payout=d*1 ether / 1000;
    }
	
	// set card $/watt/month
    function setCentsPerMonth(uint256 amount) onlyOwner public {
        centsPerMonth=amount;
    }
	
	// get mining payout and send to everyone
	// Requires price of ethereum to deduct electricity cost
    function getPayout(uint etherPrice) onlyOwner public {
        require(this.balance>min4payout);
        uint256 perToken=this.balance/totalSupply;
        for (uint i = 1; i < num_holders; i++) {
            address d=holders[i];
            if(d!=0){
                uint bal=balanceOf[d];
                if(bal==0){
                    holders[i]=0;
                }else{
                    uint powercost=((bal*centsPerMonth)/100) *( 1 ether/etherPrice);
                    holders[i].transfer((bal * perToken)-powercost);
                }
            }
        }
        owner.transfer(((totalSupply*centsPerMonth)/100) *( 1 ether/etherPrice)); // transfer elecricity cost to contract owner
    }
	
	// add graphics card for owner of contract
    function mint(uint256 amt) onlyOwner public {
        balanceOf[owner] += amt;
        totalSupply += amt;
        Transfer(this, msg.sender, amt);
    }
	// add graphics cards for someone else
    function mintTo(uint256 amt,address to) onlyOwner public {
        balanceOf[to] += amt;
        totalSupply += amt;
        Transfer(this, to, amt);
        if(indexes[to]==0||holders[indexes[to]]==0){
            indexes[to]=num_holders;
            holders[num_holders++]=to;
        }
    }
	
	
	// cards cannot be sold unless the contract is destroyed
	
    /// notice Sell `amount` tokens to contract
    /// param amount amount of tokens to be sold
    //function sell(uint256 amount) public {
    //    require(this.balance >= amount * sellPrice);      // checks if the contract has enough ether to buy
    //    burnFrom(msg.sender, amount);                     // makes the transfers
    //    msg.sender.transfer(amount * sellPrice);          // sends ether to the seller. It&#39;s important to do this last to avoid recursion attacks
    //}
	
	// allows contract to be paid:
	
    function() payable public{
        
    }
	
	
	// If something goes wrong we can destroy the contract and everyone gets a refund at card price for each of their cards.
	// by setting the price of cards to zero then no refund is sent.
	
	// if a refund is executed then the contract first must have enough Ether to do the refund.
	// Send the Ethereum to the contract as necessary first.
    function selfDestruct() onlyOwner payable public{
        uint256 perToken=this.balance/totalSupply;
        for (uint i = 1; i < num_holders; i++) {
            holders[i].transfer(balanceOf[holders[i]] * perToken);
        }
		// pay the rest to the owner
        selfdestruct(owner);
    }
}