contract BitSTDLogic {
    function name()constant  public returns(string) {}
	function symbol()constant  public returns(string) {}
	function decimals()constant  public returns(uint8) {}
	function totalSupply()constant  public returns(uint256) {}
	function allowance(address add,address _add)constant  public returns(uint256) {}
	function sellPrice()constant  public returns(uint256) {}
	function buyPrice()constant  public returns(uint256) {}
	function frozenAccount(address add)constant  public returns(bool) {}
    function BitSTDLogic(address dataAddress){}
	function migration(address sender,address add) public{}
	function balanceOf(address add)constant  public returns(uint256) {}
	function transfer(address sender,address _to, uint256 _value) public {}
	function transferFrom(address _from,address sender, address _to, uint256 _value) public returns (bool success) {}
	function approve(address _spender,address sender, uint256 _value) public returns (bool success) {}
	function approveAndCall(address _spender,address sender,address _contract, uint256 _value, bytes _extraData)public returns (bool success) {}
	function burn(address sender,uint256 _value) public returns (bool success) {}
	function burnFrom(address _from,address sender, uint256 _value) public returns (bool success) {}
	function mintToken(address target,address _contract, uint256 mintedAmount)  public {}
	function freezeAccount(address target, bool freeze)  public {}
	function buy(address _contract,address sender,uint256 value) payable public {}
	function sell(address _contract,address sender,uint256 amount) public {}
	function Transfer_of_authority(address newOwner) public{}
	function Transfer_of_authority_data(address newOwner) public {}
	function setData(address dataAddress) public {}
}
contract BitSTDView{

	BitSTDLogic private logic;
	address public owner;

	//start Query data interface
    function balanceOf(address add)constant  public returns(uint256) {
	    return logic.balanceOf(add);
	}

	function name() constant  public returns(string) {
	    return logic.name();
	}

	function symbol() constant  public returns(string) {
	    return logic.symbol();
	}

	function decimals() constant  public returns(uint8) {
	    return logic.decimals();
	}

	function totalSupply() constant  public returns(uint256) {
	    return logic.totalSupply();
	}

	function allowance(address add,address _add) constant  public returns(uint256) {
	    return logic.allowance(add,_add);
	}

	function sellPrice() constant  public returns(uint256) {
	    return logic.sellPrice();
	}

	function buyPrice() constant  public returns(uint256) {
	    return logic.buyPrice();
	}

	function frozenAccount(address add) constant  public returns(bool) {
	    return logic.frozenAccount(add);
	}

	//End Query data interface

	//initialize
    function BitSTDView(address logicAddressr) public {
        logic=BitSTDLogic(logicAddressr);
        owner=msg.sender;
    }

    //start Authority and control
    modifier onlyOwner(){
		require(msg.sender == owner);
        _;
	}

	//Update the address of the data and logic layer
    function setBitSTD(address dataAddress,address logicAddressr) onlyOwner public{
        logic=BitSTDLogic(logicAddressr);
        logic.setData(dataAddress);
    }

    //Hand over the logical layer authority
    function Transfer_of_authority_logic(address newOwner) onlyOwner public{
        logic.Transfer_of_authority(newOwner);
    }

    //Hand over the data layer authority
    function Transfer_of_authority_data(address newOwner) onlyOwner public{
        logic.Transfer_of_authority_data(newOwner);
    }

    //Hand over the view layer authority
    function Transfer_of_authority(address newOwner) onlyOwner public{
        owner=newOwner;
    }
    //End Authority and control

    //data migration
    function migration(address add) public{
        logic.migration(msg.sender,add);
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
	    logic.transfer(msg.sender,_to,_value);
	}

	/**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
	    return logic.transferFrom( _from, msg.sender,  _to,  _value);
	}

	/**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
	function approve(address _spender, uint256 _value) public returns (bool success) {
	    return logic.approve( _spender, msg.sender,  _value);
	}

	/**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
	function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
	    return logic.approveAndCall( _spender, msg.sender,this,  _value,  _extraData);
	}

	/**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
	function burn(uint256 _value) public returns (bool success) {
	    return logic.burn( msg.sender, _value);
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
	    return logic.burnFrom( _from, msg.sender,  _value);
	}

	/// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
	function mintToken(address target, uint256 mintedAmount) onlyOwner public {
	    logic.mintToken( target,this,  mintedAmount);
	}

	/// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
	function freezeAccount(address target, bool freeze) onlyOwner public {
	    logic.freezeAccount( target,  freeze);
	}

	//The next two are buying and selling tokens
	function buy() payable public {
	    logic.buy( this,msg.sender,msg.value);
	}

	function sell(uint256 amount) public {
	    logic.sell( this,msg.sender, amount);
	}

}