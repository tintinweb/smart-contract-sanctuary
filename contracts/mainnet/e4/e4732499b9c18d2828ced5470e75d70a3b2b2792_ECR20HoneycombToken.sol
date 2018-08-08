pragma solidity ^0.4.21;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract owned {
    address public owner;
    bool public ownershipTransferAllowed = false;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function allowTransferOwnership(bool flag ) public onlyOwner {
      ownershipTransferAllowed = flag;
    }
 
    function transferOwnership(address newOwner) public onlyOwner {
        require( newOwner != 0x0 );                                             // not to 0x0
        require( ownershipTransferAllowed );                                 
        owner = newOwner;
        ownershipTransferAllowed = false;
    }
}

contract ECR20HoneycombToken is owned {
    // Public variables of the token
    string public name = "Honeycomb";
    string public symbol = "COMB";
    uint8 public decimals = 18;
    
    // used for buyPrice
    uint256 private tokenFactor = 10 ** uint256(decimals);
    uint256 private initialBuyPrice = 3141592650000000000000;                   // PI Token per Finney
    uint256 private buyConst1 = 10000 * tokenFactor;                            // Faktor for buy price calculation
    uint256 private buyConst2 = 4;                                              // Faktor for buy price calculation
    
    uint256 public minimumPayout = 1000000000000000;							// minimal payout initially to 0.001 ether
       
    uint256 public totalSupply;                                                 // total number of issued tokent

	// price token are sold/bought
    uint256 public sellPrice;
    uint256 public buyPrice;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        totalSupply = 1048576 * tokenFactor;                                    // token total created
        balanceOf[msg.sender] = totalSupply;                                    // Give the creator all initial tokens
        owner = msg.sender;			                                            // assign ownership of contract to initial coin holder
        emit Transfer(0, owner, totalSupply);                                   // notify event owner
        _transfer(owner, this, totalSupply - (16384*tokenFactor));              // transfer token to contract
        _setPrices(_newPrice(balanceOf[this]));                                 // set prices according to token left
    }
    /**
     * Calculate new price based on a new token left
     * 
     * @param tokenLeft new token left on contract after transaction
    **/
    function _newPrice(uint256 tokenLeft) internal view returns (uint256 newPrice) {
        newPrice = initialBuyPrice 
            * ( tokenLeft * buyConst1 )
            / ( totalSupply*buyConst1 + totalSupply*tokenLeft/buyConst2 - tokenLeft*tokenLeft/buyConst2 ); 
        return newPrice;
    }

    function _setPrices(uint256 newPrice) internal {
        buyPrice = newPrice;
        sellPrice = buyPrice * 141421356 / 100000000;                           // sellPrice is sqrt(2) higher
    }

	/**
	 * Called when token are bought by sending ether
	 * 
	 * @return amount amount of token bought
	 **/
	function buy() payable public returns (uint256 amountToken){
        amountToken = msg.value * buyPrice / tokenFactor;                       // calculates the amount of token
        uint256 newPrice = _newPrice(balanceOf[this] - amountToken);            // calc new price after transfer
        require( (2*newPrice) > sellPrice);                                     // check whether new price is not lower than sqrt(2) of old one
        _transfer(this, msg.sender, amountToken);                               // transfer token from contract to buyer
        _setPrices( newPrice );                                                 // update prices after transfer
        return amountToken;
    }

    /**
      Fallback function
    **/
	function () payable public {
	    buy();
    }

    /**
     * Sell token back to contract
     * 
     * @param amountToken The amount of token in wei 
     * 
     * @return eth to receive in wei
     **/
    function sell(uint256 amountToken) public returns (uint256 revenue){
        revenue = amountToken * tokenFactor / sellPrice;                        // calulate the revenue in Wei
        require( revenue >= minimumPayout );									// check whether selling get more ether than the minimum payout
        uint256 newPrice = _newPrice(balanceOf[this] + amountToken);            // calc new price after transfer
        require( newPrice < sellPrice );                                        // check whether new price is more than sell price
        _transfer(msg.sender, this, amountToken);                               // transfer token back to contract
        _setPrices( newPrice );                                                 // update prices after transfer
        msg.sender.transfer(revenue);                                           // send ether to seller
        return revenue;
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
        if ( _to  == address(this) )
        {
          sell(_value);                                                         // sending token to a contract means selling them
        }
        else
        {
          _transfer(msg.sender, _to, _value);
        }
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

	/**
     * set minimumPayout price
     * 
     * @param amount minimumPayout amount in Wei
     */
		function setMinimumPayout(uint256 amount) public onlyOwner {
		minimumPayout = amount;
    }
		
	/**
     * save ether to owner account
     * 
     * @param amount amount in Wei
     */
		function save(uint256 amount) public onlyOwner {
        require( amount >= minimumPayout );	
        owner.transfer( amount);
    }
		
	/**
     * Give back token to contract bypassing selling from owner account
     * 
     * @param amount amount of token in wei
     */
		function restore(uint256 amount) public onlyOwner {
        uint256 newPrice = _newPrice(balanceOf[this] + amount);                 // calc new price after transfer
        _transfer(owner, this, amount );                                        // transfer token back to contract
        _setPrices( newPrice );                                                 // update prices after transfer
    }
		
	/**
     * Internal transfer, can be called only by this contract
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
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

}