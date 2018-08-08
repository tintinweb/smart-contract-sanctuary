pragma solidity ^0.4.16;

contract Owned {
	address public owner;
	address public signer;

    function Owned() public {
    	owner = msg.sender;
    	signer = msg.sender;
    }

    modifier onlyOwner {
    	require(msg.sender == owner);
        _;
    }

	modifier onlySigner {
    	require(msg.sender == signer);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
    	owner = newOwner;
	}

	function transferSignership(address newSigner) public onlyOwner {
        signer = newSigner;
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract ERC20Token {

    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balances;

	// Mapping for allowance
    mapping (address => mapping (address => uint256)) public allowed;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed sender, address indexed spender, uint256 value);

	function ERC20Token(uint256 _supply, string _name, string _symbol)
		public
	{
		//initial mint
        totalSupply = _supply * 10**uint256(decimals);
        balances[msg.sender] = totalSupply;

		//set variables
		name=_name;
		symbol=_symbol;

    	//trigger event
        Transfer(0x0, msg.sender, totalSupply);
	}

	/**
	 * Returns current tokens total supply
	 */
    function totalSupply()
    	public
    	constant
    	returns (uint256)
    {
		return totalSupply;
    }

	/**
     * Get the token balance for account `tokenOwner`
     */
    function balanceOf(address _owner)
    	public
    	constant
    	returns (uint256 balance)
    {
        return balances[_owner];
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
    	returns (bool success)
    {
		// To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
		require((_value == 0) || (allowed[msg.sender][_spender] == 0));

      	//set allowance
      	allowed[msg.sender][_spender] = _value;

		//trigger event
      	Approval(msg.sender, _spender, _value);

		return true;
    }

    /**
     * Show allowance
     */
    function allowance(address _owner, address _spender)
    	public
    	constant
    	returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

	/**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint256 _value)
    	internal
    	returns (bool success)
    {
		// Do not allow transfer to 0x0 or the token contract itself or from address to itself
		require((_to != address(0)) && (_to != address(this)) && (_to != _from));

        // Check if the sender has enough
        require((_value > 0) && (balances[_from] >= _value));

        // Check for overflows
        require(balances[_to] + _value > balances[_to]);

        // Subtract from the sender
        balances[_from] -= _value;

        // Add the same to the recipient
        balances[_to] += _value;

        Transfer(_from, _to, _value);

        return true;
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
    	public
    	returns (bool success)
    {
    	return _transfer(msg.sender, _to, _value);
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
    	public
    	returns (bool success)
    {
		// Check allowance
    	require(_value <= allowed[_from][msg.sender]);

		//decrement allowance
		allowed[_from][msg.sender] -= _value;

    	//transfer tokens
        return _transfer(_from, _to, _value);
    }
}



contract MiracleTeleToken is ERC20Token, Owned {

    using SafeMath for uint256;

    // Mapping for allowance
    mapping (address => uint8) public delegations;

	mapping (address => uint256) public contributions;

    // This generates a public event on the blockchain that will notify clients
    event Delegate(address indexed from, address indexed to);
    event UnDelegate(address indexed from, address indexed to);

    // This generates a public event on the blockchain that will notify clients
    event Contribute(address indexed from, uint256 indexed value);
    event Reward(address indexed from, uint256 indexed value);

    /**
	 * Initializes contract with initial supply tokens to the creator of the contract
	 */
    function MiracleTeleToken(uint256 _supply) ERC20Token(_supply, "MiracleTele", "TELE") public {}

	/**
	 * Mint new tokens
	 *
	 * @param _value the amount of new tokens
	 */
    function mint(uint256 _value)
        public
        onlyOwner
    {
    	// Prevent mine 0 tokens
        require(_value > 0);

    	// Check overflow
    	balances[owner] = balances[owner].add(_value);
        totalSupply = totalSupply.add(_value);

        Transfer(address(0), owner, _value);
    }

    function delegate(uint8 _v, bytes32 _r, bytes32 _s)
        public
        onlySigner
    {
		address allowes = ecrecover(getPrefixedHash(signer), _v, _r, _s);

        delegations[allowes]=1;

        Delegate(allowes, signer);
    }

	function unDelegate(uint8 _v, bytes32 _r, bytes32 _s)
        public
        onlySigner
    {
    	address allowes = ecrecover(getPrefixedHash(signer), _v, _r, _s);

        delegations[allowes]=0;

        UnDelegate(allowes, signer);
    }

	/**
     * Show delegation
     */
    function delegation(address _owner)
    	public
    	constant
    	returns (uint8 status)
    {
        return delegations[_owner];
    }

    /**
     * @notice Hash a hash with `"\x19Ethereum Signed Message:\n32"`
     * @param _message Data to ign
     * @return signHash Hash to be signed.
     */
    function getPrefixedHash(address _message)
        pure
        public
        returns(bytes32 signHash)
    {
        signHash = keccak256("\x19Ethereum Signed Message:\n20", _message);
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
    function transferDelegated(address _from, address _to, uint256 _value)
        public
        onlySigner
        returns (bool success)
    {
        // Check delegate
    	require(delegations[_from]==1);

    	//transfer tokens
        return _transfer(_from, _to, _value);
    }

	/**
      * Contribute tokens from delegated address
      *
      * Contribute `_value` tokens `_from` address
      *
      * @param _from The address of the sender
	  * @param _value the amount to send
      */
    function contributeDelegated(address _from, uint256 _value)
        public
        onlySigner
    {
        // Check delegate
    	require(delegations[_from]==1);

        // Check if the sender has enough
        require((_value > 0) && (balances[_from] >= _value));

        // Subtract from the sender
        balances[_from] = balances[_from].sub(_value);

        contributions[_from] = contributions[_from].add(_value);

        Contribute(_from, _value);
    }

	/**
      * Reward tokens from delegated address
      *
      * Reward `_value` tokens to `_from` address
      *
      * @param _from The address of the sender
	  * @param _value the amount to send
      */
    function reward(address _from, uint256 _value)
        public
        onlySigner
    {
        require(contributions[_from]>=_value);

        contributions[_from] = contributions[_from].sub(_value);

        balances[_from] = balances[_from].add(_value);

        Reward(_from, _value);
    }

    /**
     * Don&#39;t accept ETH, it is utility token
     */
	function ()
	    public
	    payable
	{
		revert();
	}
}