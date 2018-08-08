pragma solidity ^0.4.24;

contract owned {
    address public owner;
}

contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint8 public decimals = 18;
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
}

contract BitSTDShares is owned, TokenERC20 {

    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping (address => bool) public frozenAccount;
}

contract BitSTDData {
    // Used to control data migration
    bool public data_migration_control = true;
    address public owner;
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    // An array of all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    uint256 public sellPrice;
    uint256 public buyPrice;
    // The allowed address zhi value wei value is true
    mapping (address => bool) public owners;
    // Freeze address
    mapping (address => bool) public frozenAccount;
    BitSTDShares private bit;

    constructor(address contractAddress) public {
        bit = BitSTDShares(contractAddress);
        owner = msg.sender;
        name = bit.name();
        symbol = bit.symbol();
        decimals = bit.decimals();
        sellPrice = bit.sellPrice();
        buyPrice = bit.buyPrice();
        totalSupply = bit.totalSupply();
        balanceOf[msg.sender] = totalSupply;
    }

    modifier qualification {
        require(msg.sender == owner);
        _;
    }

    // Move the super administrator
    function transferAuthority(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }

    function setBalanceOfAddr(address addr, uint256 value) qualification public {
        balanceOf[addr] = value;
    }

    function setAllowance(address authorizer, address sender, uint256 value) qualification public {
        allowance[authorizer][sender] = value;
    }


    function setFrozenAccount(address addr, bool value) qualification public {
        frozenAccount[addr] = value;
    }

    function addTotalSupply(uint256 value) qualification public {
        totalSupply = value;
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public {
        require(msg.sender == owner);
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    // Old contract data
    function getOldBalanceOf(address addr) constant  public returns(uint256) {
       return bit.balanceOf(addr);
    }
   
    
    function getOldAllowance(address authorizer, address sender) constant  public returns(uint256) {
        return bit.allowance(authorizer, sender);
    }

    function getOldFrozenAccount(address addr) constant public returns(bool) {
        return bit.frozenAccount(addr);
    }
   
}



interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract BitSTDLogic {
    address public owner;
    // data layer
	BitSTDData private data;

    constructor(address dataAddress) {
        data = BitSTDData(dataAddress);
        owner = msg.sender;
    }
    
    // Transfer logical layer authority
    function transferAuthority(address newOwner) onlyOwner public {
        owner = newOwner;
    }
	modifier onlyOwner(){
		require(msg.sender == owner);
        _;
	}
	
	// Transfer data layer authority
    function transferDataAuthority(address newOwner) onlyOwner public {
        data.transferAuthority(newOwner);
    }
    function setData(address dataAddress)onlyOwner public {
        data = BitSTDData(dataAddress);
    }

    // Old contract data
    function getOldBalanceOf(address addr) constant public returns (uint256) {
        return data.getOldBalanceOf(addr);
    }

	/**
	 * Internal transfers can only be invoked through this contract
	*/
    function _transfer(address _from, address _to, uint _value) internal {
        uint256 f_value = balanceOf(_from);
        uint256 t_value = balanceOf(_to);
        // Prevents transmission to 0x0 address.Call to Burn ()
        require(_to != 0x0);
        // Check that the sender is adequate
        require(f_value >= _value);
        // Check the overflow
        require(t_value + _value > t_value);
        // Save it as a future assertion
        uint previousBalances = f_value + t_value;
        // Minus from the sender
        setBalanceOf(_from, f_value - _value);
        // Add to receiver
        setBalanceOf(_to, t_value + _value);

        // Assertions are used to use static analysis to detect errors in code.They should not fail
        assert(balanceOf(_from) + balanceOf(_to) == previousBalances);

    }
    // data migration
    function migration(address sender, address receiver) onlyOwner public returns (bool) {
        require(sender != receiver);
        bool result= false;
        // Start data migration
        // uint256 t_value = balanceOf(receiver);
        uint256 _value = data.getOldBalanceOf(receiver);
        //Transfer balance
        if (data.balanceOf(receiver) == 0) {
            if (_value > 0) {
                _transfer(sender, receiver, _value);
                result = true;
            }
        }
        //Frozen account migration
        if (data.getOldFrozenAccount(receiver)== true) {
            if (data.frozenAccount(receiver)!= true) {
                data.setFrozenAccount(receiver, true);
            }
        }
        //End data migration
        return result;
    }

    // Check the contract token
    function balanceOf(address addr) constant public returns (uint256) {
        return data.balanceOf(addr);
    }

    function name() constant public returns (string) {
  	   return data.name();
  	}

  	function symbol() constant public returns(string) {
  	   return data.symbol();
  	}

  	function decimals() constant public returns(uint8) {
  	   return data.decimals();
  	}

  	function totalSupply() constant public returns(uint256) {
  	   return data.totalSupply();
  	}

  	function allowance(address authorizer, address sender) constant public returns(uint256) {
  	   return data.allowance(authorizer, sender);
  	}

  	function sellPrice() constant public returns (uint256) {
  	   return data.sellPrice();
  	}

  	function buyPrice() constant public returns (uint256) {
  	   return data.buyPrice();
  	}

  	function frozenAccount(address addr) constant public returns(bool) {
  	   return data.frozenAccount(addr);
  	}

    //Modify the contract
    function setBalanceOf(address addr, uint256 value) onlyOwner public {
        data.setBalanceOfAddr(addr, value);
    }

    /**
     * Pass the token
     * send a value token to your account
    */
    function transfer(address sender, address _to, uint256 _value) onlyOwner public returns (bool) {
        _transfer(sender, _to, _value);
        return true;
    }

    /**
     *Passing tokens from other addresses
      *
      * sends the value token to "to", representing "from"
      *
      * @param _from sender&#39;s address
      * @param _to recipient&#39;s address
      * @param _value number sent
     */
    function transferFrom(address _from, address sender, address _to, uint256 _value) onlyOwner public returns (bool success) {
        uint256 a_value = data.allowance(_from, sender);
        require(_value <=_value ); // Check allowance
        data.setAllowance(_from, sender, a_value - _value);
        _transfer(_from, _to, _value);
        return true;
    }

     /**
* set allowances for other addresses
*
* allow the "spender" to spend only the "value" card in your name
*
* @param _spender authorized address
* @param _value they can spend the most money
     */
    function approve(address _spender, address sender, uint256 _value) onlyOwner public returns (bool success) {
        data.setAllowance(sender, _spender, _value);
        return true;
    }

    /**
     * Grant and notify other addresses
       *
       * allow "spender" to only mark "value" in your name and then write the contract on it.
       *
       * @param _spender authorized address
       * @param _value they can spend the most money
       * @param _extraData sends some additional information to the approved contract
     */
    function approveAndCall(address _spender, address sender, address _contract, uint256 _value, bytes _extraData) onlyOwner public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, sender, _value)) {
            spender.receiveApproval(sender, _value, _contract, _extraData);
            return true;
        }
    }

     /**
     * Destroy the tokens,
       *
       * delete "value" tokens from the system
       *
       * param _value the amount of money to burn
     */
    function burn(address sender, uint256 _value) onlyOwner public returns (bool success) {
        uint256 f_value = balanceOf(sender);
        require(f_value >= _value);                 // Check that the sender is adequate
        setBalanceOf(sender, f_value - _value);    // Minus from the sender
        data.addTotalSupply(totalSupply() - _value);                      // Renewal aggregate supply
        return true;
    }

    /**
     * Destroy tokens from other accounts
       *
       * delete "value" tokens from "from" in the system.
       *
       * @param _from the address of the sender
       * param _value the amount of money to burn
     */
    function burnFrom(address _from, address sender, uint256 _value) onlyOwner public returns (bool success) {
        uint256 f_value = balanceOf(sender);
        uint256 a_value = data.allowance(_from, sender);
        require(f_value >= _value);                             // Check that the target balance is adequate
        require(_value <= a_value);                             // Check the allowance
        setBalanceOf(_from, f_value - _value);                // Subtract from the goal balance
        data.setAllowance(_from, sender, f_value - _value);  // Minus the sender&#39;s allowance
        data.addTotalSupply(totalSupply() - _value);         // update totalSupply

        return true;
    }

    //@ notifies you to create the mintedAmount token and send it to the target
      // @param target address receiving token
      // @param mintedAmount will receive the number of tokens
    function mintToken(address target, address _contract, uint256 mintedAmount) onlyOwner public {
        uint256 f_value = balanceOf(target);
        setBalanceOf(target, f_value + mintedAmount);
        data.addTotalSupply(totalSupply() + mintedAmount);

    }

    //Notice freezes the account to prevent "target" from sending and receiving tokens
      // @param target address is frozen
      // @param freezes or does not freeze
    function freezeAccount(address target, bool freeze) onlyOwner public returns (bool) {
        data.setFrozenAccount(target, freeze);
        return true;

    }

    // Notice of purchase of tokens by sending ether
    function buy(address _contract, address sender, uint256 value) payable public {
        require(false);
        uint amount = value / data.buyPrice();        // Calculate the purchase amount
        _transfer(_contract, sender, amount);              // makes the transfers
    }
    // @notice to sell the amount token
    // @param amount
    function sell(address _contract, address sender, uint256 amount) public {
        require(false);
        require(address(_contract).balance >= amount * data.sellPrice());      // Check if there is enough ether in the contract
        _transfer(sender, _contract, amount);              // makes the transfers
        sender.transfer(amount * data.sellPrice());          // Shipping ether to the seller.This is important to avoid recursive attacks
    }

}



contract BitSTDView {

	BitSTDLogic private logic;
	address public owner;

    // This creates a public event on the blockchain that notifies the customer
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);

    // This tells the customer how much money is being burned
    event Burn(address indexed from, uint256 value);

	//start Query data interface
    function balanceOf(address add)constant  public returns (uint256) {
	    return logic.balanceOf(add);
	}

	function name() constant  public returns (string) {
	    return logic.name();
	}

	function symbol() constant  public returns (string) {
	    return logic.symbol();
	}

	function decimals() constant  public returns (uint8) {
	    return logic.decimals();
	}

	function totalSupply() constant  public returns (uint256) {
	    return logic.totalSupply();
	}

	function allowance(address authorizer, address sender) constant  public returns (uint256) {
	    return logic.allowance(authorizer, sender);
	}

	function sellPrice() constant  public returns (uint256) {
	    return logic.sellPrice();
	}

	function buyPrice() constant  public returns (uint256) {
	    return logic.buyPrice();
	}

	function frozenAccount(address addr) constant  public returns (bool) {
	    return logic.frozenAccount(addr);
	}

	//End Query data interface

	//initialize
    constructor(address logicAddressr) public {
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
    function transferLogicAuthority(address newOwner) onlyOwner public{
        logic.transferAuthority(newOwner);
    }

    //Hand over the data layer authority
    function transferDataAuthority(address newOwner) onlyOwner public{
        logic.transferDataAuthority(newOwner);
    }

    //Hand over the view layer authority
    function transferAuthority(address newOwner) onlyOwner public{
        owner=newOwner;
    }
    //End Authority and control

    //data migration
    function migration(address addr) public {
        if (logic.migration(msg.sender, addr) == true) {
            emit Transfer(msg.sender, addr,logic.getOldBalanceOf(addr));
        }
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
	    if (logic.transfer(msg.sender, _to, _value) == true) {
	        emit Transfer(msg.sender, _to, _value);
	    }
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
	    if (logic.transferFrom(_from, msg.sender, _to, _value) == true) {
	        emit Transfer(_from, _to, _value);
	        return true;
	    }
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
	    return logic.approveAndCall(_spender, msg.sender, this, _value, _extraData);
	}

	/**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
	function burn(uint256 _value) public returns (bool success) {
	    if (logic.burn(msg.sender, _value) == true) {
	        emit Burn(msg.sender, _value);
	        return true;
	    }
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
	    if (logic.burnFrom( _from, msg.sender, _value) == true) {
	        emit Burn(_from, _value);
	        return true;
	    }
	}

	/// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
	function mintToken(address target, uint256 mintedAmount) onlyOwner public {
	    logic.mintToken(target, this,  mintedAmount);
	    emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
	}

	/// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
	function freezeAccount(address target, bool freeze) onlyOwner public {
	    if (logic.freezeAccount(target,  freeze) == true) {
	        emit FrozenFunds(target, freeze);
	    }
	}

	//The next two are buying and selling tokens
	function buy() payable public {
	    logic.buy(this, msg.sender, msg.value);
	}

	function sell(uint256 amount) public {
	    logic.sell(this,msg.sender, amount);
	}
}