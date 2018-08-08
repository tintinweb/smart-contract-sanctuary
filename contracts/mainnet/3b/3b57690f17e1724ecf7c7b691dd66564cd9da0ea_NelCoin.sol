pragma solidity ^ 0.4.24;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    function balanceOf(address _owner) external view returns (uint256 amount);
    function transfer(address _to, uint256 _value) external returns(bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract Burnable {
    
    function burn(uint256 _value) external returns(bool success);
    function burnFrom(address _from, uint256 _value) external returns(bool success);
    
    // This notifies clients about the amount burnt
    event Burn(address indexed _from, uint256 _value);
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    
    address public owner;
    address public newOwner;

    modifier onlyOwner {
        require(msg.sender == owner, "only Owner can do this");
        _;
    }

    function transferOwnership(address _newOwner) 
    external onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() 
    external {
        require(msg.sender == newOwner, "only new Owner can do this");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    
    event OwnershipTransferred(address indexed _from, address indexed _to);
}

contract Permissioned {
    
    function approve(address _spender, uint256 _value) public returns(bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns(bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 amount);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "mul overflow");
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div by zero");
        uint256 c = a / b;
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "sub overflow");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "add overflow");
        return c;
    }
}

//interface for approveAndCall
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

/** @title NelCoin token. */
contract NelCoin is ERC20Interface, Burnable, Owned, Permissioned {
    // be aware of overflows
    using SafeMath for uint256;

    // This creates an array with all balances
    mapping(address => uint256) internal _balanceOf;
    
    // This creates an array with all allowance
    mapping(address => mapping(address => uint256)) internal _allowance;
	
	uint public forSale;

    /**
    * Constructor function
    *
    * Initializes contract with initial supply tokens to the creator of the contract
    */
    constructor()
    public {
        owner = msg.sender;
        symbol = "NEL";
        name = "NelCoin";
        decimals = 2;
        forSale = 12000000 * (10 ** uint(decimals));
        totalSupply = 21000000 * (10 ** uint256(decimals));
        _balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    /**
    * Get the token balance for account
    *
    * Get token balance of `_owner` account
    *
    * @param _owner The address of the owner
    */
    function balanceOf(address _owner)
    external view
    returns(uint256 balance) {
        return _balanceOf[_owner];
    }

    /**
    * Internal transfer, only can be called by this contract
    */
    function _transfer(address _from, address _to, uint256 _value)
    internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0), "use burn() instead");
        // Check if the sender has enough
        require(_balanceOf[_from] >= _value, "not enough balance");
        // Subtract from the sender
        _balanceOf[_from] = _balanceOf[_from].sub(_value);
        // Add the same to the recipient
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    /**
    * Transfer tokens
    *
    * Send `_value` tokens to `_to` from your account
    *
    * @param _to The address of the recipient
    * @param _value the amount to send
    */
    function transfer(address _to, uint256 _value)
    external
    returns(bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
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
    function transferFrom(address _from, address _to, uint256 _value)
    external
    returns(bool success) {
        require(_value <= _allowance[_from][msg.sender], "allowance too loow");     // Check allowance
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        emit Approval(_from, _to, _allowance[_from][_to]);
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
    function approve(address _spender, uint256 _value)
    public
    returns(bool success) {
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
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
    external
    returns(bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender)
    external view
    returns(uint256 amount) {
        return _allowance[_owner][_spender];
    }

    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    *
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _addedValue The amount of tokens to increase the allowance by.
    */
    function increaseApproval(address _spender, uint _addedValue)
    external
    returns(bool success) {
        _allowance[msg.sender][_spender] = _allowance[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, _allowance[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    *
    * approve should be called when allowed[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseApproval(address _spender, uint _subtractedValue)
    external
    returns(bool success) {
        uint256 oldValue = _allowance[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            _allowance[msg.sender][_spender] = 0;
        } else {
            _allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, _allowance[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Destroy tokens
    *
    * Remove `_value` tokens from the system irreversibly
    *
    * @param _value the amount of money to burn
    */
    function burn(uint256 _value)
    external
    returns(bool success) {
        _burn(msg.sender, _value);
        return true;
    }

    /**
    * @dev Destroy tokens from other account
    *
    * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
    *
    * @param _from the address of the sender
    * @param _value the amount of money to burn
    */
    function burnFrom(address _from, uint256 _value)
    external
    returns(bool success) {
        require(_value <= _allowance[_from][msg.sender], "allowance too low");                           // Check allowance
        require(_value <= _balanceOf[_from], "balance too low");                                       // Is tehere enough coins on account
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);  // Subtract from the sender&#39;s allowance
        _burn(_from, _value);
        emit Approval(_from, msg.sender, _allowance[_from][msg.sender]);
        return true;
    }

    //internal burn function
    function _burn(address _from, uint256 _value)
    internal {
        require(_balanceOf[_from] >= _value, "balance too low");               // Check if the targeted balance is enough
        _balanceOf[_from] = _balanceOf[_from].sub(_value);  // Subtract from the sender
        totalSupply = totalSupply.sub(_value);              // Updates totalSupply
        emit Burn(msg.sender, _value);
        emit Transfer(_from, address(0), _value);
    }

	//We accept intentional donations in ETH
    event Donated(address indexed _from, uint256 _value);

	/**
    * Donate ETH tokens to contract (Owner)
    */
	function donation() 
    external payable 
    returns (bool success){
        emit Donated(msg.sender, msg.value);
        return(true);
    }
    
    //Don`t accept accidental ETH
    function()
    external payable
    {
        require(false, "Use fund() or donation()");
    }
    
	/**
	 * Buy NelCoin using ETH
	 * Contract is selling tokens at price 20000NEL/1ETH, 
	 * total 12000000NEL for sale
	 */
	function fund()
	external payable
	returns (uint amount){
		require(forSale > 0, "Sold out!");
		uint tokenCount = ((msg.value).mul(20000 * (10 ** uint(decimals)))).div(10**18);
		require(tokenCount >= 1, "Send more ETH to buy at least one token!");
		require(tokenCount <= forSale, "You want too much! Check forSale()");
		forSale -= tokenCount;
		_transfer(owner, msg.sender, tokenCount);
		return tokenCount;
	}
	
	/**
    * Tranfer all ETH from contract to Owner addres.
    */
    function withdraw()
    onlyOwner external
    returns (bool success){
        require(address(this).balance > 0, "Nothing to withdraw");
        owner.transfer(address(this).balance);
        return true;
    }
	
	/**
    * Transfer some ETH tokens from contract
    *
    * Transfer _value of ETH from contract to Owner addres.
    * @param _value number of wei to trasfer
    */
	function withdraw(uint _value)
    onlyOwner external
    returns (bool success){
		require(_value > 0, "provide amount pls");
		require(_value < address(this).balance, "Too much! Check balance()");
		owner.transfer(_value);
        return true;
	}
	
    /**
    * Check ETH balance of contract
    */
	function balance()
	external view
	returns (uint amount){
		return (address(this).balance);
	}
    
	/**
    * Transfer ERC20 tokens from contract
    *
    * Tranfer _amount of ERC20 from contract _tokenAddress to Owner addres.
    *
    * @param _amount amount of ERC20 tokens to be transferred 
	* @param _tokenAddress address of ERC20 token contract
    */
	function transferAnyERC20Token(address _tokenAddress, uint256 _amount)
    onlyOwner external
    returns(bool success) {
        return ERC20Interface(_tokenAddress).transfer(owner, _amount);
    }
}