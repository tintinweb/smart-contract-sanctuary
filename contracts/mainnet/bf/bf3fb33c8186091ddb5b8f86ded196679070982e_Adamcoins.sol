pragma solidity 0.4.25;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/* contract ownership status*/
contract owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _oshiAmount, address _token, bytes _extraData) external; }

contract TokenERC20 {
    
    using SafeMath for uint256;
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // @param M Multiplier,
    uint256 public M = 10**uint256(decimals); 
    uint256 public totalSupply;

    
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowed;

    /** oshi for Adamcoin is like wei for Ether, 1 Adamcoin = M * oshi as 1 Ether = 1e18 wei  */
    
    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed _from, address indexed _to, uint256 _oshiAmount);
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _approvedBy, address _spender, uint256 _oshiAmount);
    // This notifies clients about the amount burnt
    event Burn(address indexed _from, uint256 _oshiAmount);

    /**
     * Constructor
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
       uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    )   public {
        
        totalSupply = initialSupply * M;
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                         // Set the name for display purposes
        symbol = tokenSymbol;                    // Set the symbol for display purposes
    }
    
    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _oshiAmount) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Subtract from the sender
        balanceOf[_from] = balanceOf[_from].sub(_oshiAmount);
        // Add the same to the recipient
        balanceOf[_to] = balanceOf[_to].add(_oshiAmount);
        emit Transfer(_from, _to, _oshiAmount);
        
    }

    /**
     * Transfer tokens
     *
     * Send `_oshiAmount` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _oshiAmount the amount of oshi to send
     */
    function transfer(address _to, uint256 _oshiAmount) public {
        _transfer(msg.sender, _to, _oshiAmount);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_oshiAmount`  to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _oshiAmount the amount or oshi to send
     */
     function transferFrom(address _from, address _to, uint256 _oshiAmount) public returns (bool success) {
        require(_oshiAmount <= balanceOf[_from]);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_oshiAmount);
        require(_oshiAmount > 0 && _from != _to); 
        _transfer(_from, _to, _oshiAmount);
        
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_oshiAmount` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _oshiAmount the max amount of oshi they can spend 
     */
     function approve(address _spender, uint _oshiAmount) public returns (bool success) {
       
        allowed[msg.sender][_spender] = _oshiAmount;
        emit Approval(msg.sender, _spender, _oshiAmount);
        return true;
    }
    
      /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_oshiAmount`  in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _oshiAmount the max amount of oshi they can spend 
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _oshiAmount, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _oshiAmount)) {
            spender.receiveApproval(msg.sender, _oshiAmount, this, _extraData);
            return true;
        }
    }
  
    /**
     * Destroy tokens
     *
     * Remove `_oshiAmount`  from the system irreversibly
     *
     * @param _oshiAmount the amount of oshi to burn 
     */
    function burn(uint256 _oshiAmount) public returns (bool success) {
    
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_oshiAmount);            // Subtract from the sender
        totalSupply = totalSupply.sub(_oshiAmount);                      // Updates totalSupply
        emit Burn(msg.sender, _oshiAmount);
        return true;
    }


    /**
     * Destroy tokens from other account
     *
     * Remove `_oshiAmount`  from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _oshiAmount the amount of oshi to burn 
     */
    function burnFrom(address _from, uint256 _oshiAmount)  public returns (bool success) {
        balanceOf[_from] = balanceOf[_from].sub(_oshiAmount);                         // Subtract from the targeted balance
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_oshiAmount);             // Subtract from the sender&#39;s allowed
        totalSupply = totalSupply.sub(_oshiAmount);                              // Update totalSupply
        emit Burn(_from, _oshiAmount);
        return true;
    }
}
/******************************************/
/*       ADAMCOINS ADM STARTS HERE       */
/******************************************/

contract Adamcoins is owned, TokenERC20 {
    
    using SafeMath for uint256;
    
    uint256 public sellPrice;                //Adamcoins sell price
    uint256 public buyPrice;                 //Adamcoins buy price
    bool public purchasingAllowed = true;
    bool public sellingAllowed = true;

    
    mapping (address => uint) public pendingWithdrawals;
    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
     constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}
    
    /// @dev Public function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) view public returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

    /// @notice allows to purchase from the contract 
    function enablePurchasing() onlyOwner public {
        require (msg.sender == owner); 
        purchasingAllowed = true;
    }
    /// @notice doesn&#39;t allow to purchase from the contract
    function disablePurchasing() onlyOwner public {
        require (msg.sender == owner); 
        purchasingAllowed = false;
    }
    
    /// @notice allows to sell to the contract
    function enableSelling() onlyOwner public {
        require (msg.sender == owner); 
        sellingAllowed = true;
    }
    /// @notice doesn&#39;t allow to sell to the contract
    function disableSelling() onlyOwner public {
        require (msg.sender == owner); 
        sellingAllowed = false;
    }
    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _oshiAmount) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] = balanceOf[_from].sub(_oshiAmount);    // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_oshiAmount);        // Add the same to the recipient
        emit Transfer(_from, _to, _oshiAmount);
    }

    /// @notice Create `mintedOshiAmount` and send it to `target`
    /// @param target Address to receive oshi
    /// @param mintedOshiAmount the amount of oshi it will receive 
    function mintToken(address target, uint256 mintedOshiAmount) onlyOwner public returns (bool) {
        
        balanceOf[target] = balanceOf[target].add(mintedOshiAmount);
        totalSupply = totalSupply.add(mintedOshiAmount);
        emit Transfer(0, address(this), mintedOshiAmount);
        emit Transfer(address(this), target, mintedOshiAmount);
        return true;
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    /// @notice Allow users to buy adamcoins for `newBuyPrice` and sell adamcoins for `newSellPrice`
    /// @param newSellPrice the Price in wei that users can sell to the contract
    /// @param newBuyPrice the Price in wei that users can buy from the contract
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    
    }

   /* transfer amount of wei to owner*/
	function withdrawEther(uint256 amount) onlyOwner public {
		require(msg.sender == owner);
		owner.transfer(amount);
	}
	/// @notice This method can be used by the owner to extract sent tokens 
	/// or ethers to this contract.
    /// @param _token The address of token contract that you want to recover
    ///  set to 0 address in case of ether
	function claimTokens(address _token) onlyOwner public {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }

        TokenERC20 token = TokenERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);
        
    }
    
    /// @notice Buy tokens from contract by sending ether
    function() public payable {
        
        require(msg.value > 0);
        require(purchasingAllowed);
        uint tokens = (msg.value * M)/buyPrice; // calculates the amount
        
	    pendingWithdrawals[msg.sender] = pendingWithdrawals[msg.sender].add(tokens); // update the pendingWithdrawals amount for buyer
	}
	
	/// @notice Withdraw the amount of pendingWithdrawals from contract
    function withdrawAdamcoins() public {
        require(purchasingAllowed);
        uint withdrawalAmount = pendingWithdrawals[msg.sender]; // calculates withdrawal amount 
        
        pendingWithdrawals[msg.sender] = 0;
        
        _transfer(address(this), msg.sender, withdrawalAmount);    // makes the transfers
       
    }
    
    /// @notice Sell Adamcoins  to the contract
    /// @param _adamcoinsAmountToSell amount of  Adamcoins to be sold
    function sell(uint256 _adamcoinsAmountToSell) public {
        require(sellingAllowed);
        uint256 weiAmount = _adamcoinsAmountToSell.mul(sellPrice);
        require(address(this).balance >= weiAmount);      // checks if the contract has enough ether to buy
        uint adamcoinsAmountToSell = _adamcoinsAmountToSell * M;
        _transfer(msg.sender, address(this), adamcoinsAmountToSell);              // makes the transfers
        msg.sender.transfer(weiAmount);          // sends ether to the seller.
    }
    
    
}