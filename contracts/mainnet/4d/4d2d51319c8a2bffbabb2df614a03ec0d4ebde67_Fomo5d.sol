pragma solidity ^0.4.18;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract Fomo5d {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
	
	mapping(address=>bool) public frozenAccount;
	uint256 public rate = 20000 ;//1 ether=how many tokens
	uint256 public amount; 
	
	address public owner;
	bool public fundOnContract=true;	
	bool public contractStart=true;	 
	bool public exchangeStart=true;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
	 
	modifier  onlyOwner{
        if(msg.sender != owner){
            revert();
        }else{
            _;
        }
    }

    function transferOwner(address newOwner)  public onlyOwner{
        owner = newOwner;
    }
	 

	 
    function Fomo5d() public payable{
		decimals=18;
        totalSupply = 1000000000 * (10 ** uint256(decimals));  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = "Fomo5d";                                   // Set the name for display purposes
        symbol = "F5d";                               // Set the symbol for display purposes
		owner = msg.sender;
		rate=20000;
		fundOnContract=true;
		contractStart=true;
		exchangeStart=true;
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
		if(frozenAccount[_from]){
            revert();
        }
		if(frozenAccount[_to]){
            revert();
        }
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
		if(!contractStart){
			revert();
		}
        _transfer(msg.sender, _to, _value);
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
		if(!contractStart){
			revert();
		}
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
		require(_value > 0);     // Check allowance
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
		if(!contractStart){
			revert();
		}
		require(balanceOf[msg.sender] >= _value);
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
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
		if(!contractStart){
			revert();
		}
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
		if(!contractStart){
			revert();
		}
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
		require(_value > 0);
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
		Transfer(msg.sender, 0, _value);
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
    function burnFrom(address _from, uint256 _value) public onlyOwner returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
		require(_value> 0); 
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        totalSupply -= _value;                              // Update totalSupply
		Transfer(_from, 0, _value);
        return true;
    }
	
	function () public payable{
		if(!contractStart){
			revert();
		}
        if(frozenAccount[msg.sender]){
            revert();
        }
		amount = uint256(msg.value * rate);
		
		if(balanceOf[msg.sender]+amount<balanceOf[msg.sender]){
			revert();
		}
		if(balanceOf[owner]<amount){
			revert();
		}
		//if(amount>0){
			if(exchangeStart){
				balanceOf[owner] -=amount ;
				balanceOf[msg.sender] +=amount;
				Transfer(owner, msg.sender, amount); //token event
			}
			if(!fundOnContract){
				owner.transfer(msg.value);
			}
		//}
    }

	function transferFund(address target,uint256 _value) public onlyOwner{
		if(frozenAccount[target]){
            revert();
        }
		if(_value<=0){
			revert();
		}
		if(_value>this.balance){
			revert();
		}
		if(target != 0){
			target.transfer(_value);
		}
    }
	
	
	function setFundOnContract(bool _fundOnContract)  public onlyOwner{
            fundOnContract = _fundOnContract;
    }
	
	function setContractStart(bool _contractStart)  public onlyOwner{
            contractStart = _contractStart;
    }
	
	function freezeAccount(address target,bool _bool)  public onlyOwner{
        if(target != 0){
            frozenAccount[target] = _bool;
        }
    }
	function setRate(uint thisRate) public onlyOwner{
	   if(thisRate>=0){
         rate = thisRate;
		}
    }
	
	function mintToken(address target, uint256 mintedAmount) public onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
    }
	function ownerKill(address target) public onlyOwner {
		selfdestruct(target);
    }
	function withdraw(address target) public onlyOwner {
		target.transfer(this.balance);
    }
	function getBalance() public constant returns(uint) {
		return this.balance;
	}
	function setExchangeStart(bool _exchangeStart)  public onlyOwner{
            exchangeStart = _exchangeStart;
    }
}