pragma solidity 0.4.18;

/**

 * Math operations with safety checks

 */

contract BaseSafeMath {


    /*
    standard uint256 functions
     */



    function add(uint256 a, uint256 b) internal pure

    returns (uint256) {

        uint256 c = a + b;

        assert(c >= a);

        return c;

    }


    function sub(uint256 a, uint256 b) internal pure

    returns (uint256) {

        assert(b <= a);

        return a - b;

    }


    function mul(uint256 a, uint256 b) internal pure

    returns (uint256) {

        uint256 c = a * b;

        assert(a == 0 || c / a == b);

        return c;

    }


    function div(uint256 a, uint256 b) internal pure

    returns (uint256) {

	    assert( b > 0 );
		
        uint256 c = a / b;

        return c;

    }


    function min(uint256 x, uint256 y) internal pure

    returns (uint256 z) {

        return x <= y ? x : y;

    }


    function max(uint256 x, uint256 y) internal pure

    returns (uint256 z) {

        return x >= y ? x : y;

    }



    /*

    uint128 functions

     */



    function madd(uint128 a, uint128 b) internal pure

    returns (uint128) {

        uint128 c = a + b;

        assert(c >= a);

        return c;

    }


    function msub(uint128 a, uint128 b) internal pure

    returns (uint128) {

        assert(b <= a);

        return a - b;

    }


    function mmul(uint128 a, uint128 b) internal pure

    returns (uint128) {

        uint128 c = a * b;

        assert(a == 0 || c / a == b);

        return c;

    }


    function mdiv(uint128 a, uint128 b) internal pure

    returns (uint128) {

	    assert( b > 0 );
	
        uint128 c = a / b;

        return c;

    }


    function mmin(uint128 x, uint128 y) internal pure

    returns (uint128 z) {

        return x <= y ? x : y;

    }


    function mmax(uint128 x, uint128 y) internal pure

    returns (uint128 z) {

        return x >= y ? x : y;

    }



    /*

    uint64 functions

     */



    function miadd(uint64 a, uint64 b) internal pure

    returns (uint64) {

        uint64 c = a + b;

        assert(c >= a);

        return c;

    }


    function misub(uint64 a, uint64 b) internal pure

    returns (uint64) {

        assert(b <= a);

        return a - b;

    }


    function mimul(uint64 a, uint64 b) internal pure

    returns (uint64) {

        uint64 c = a * b;

        assert(a == 0 || c / a == b);

        return c;

    }


    function midiv(uint64 a, uint64 b) internal pure

    returns (uint64) {

	    assert( b > 0 );
	
        uint64 c = a / b;

        return c;

    }


    function mimin(uint64 x, uint64 y) internal pure

    returns (uint64 z) {

        return x <= y ? x : y;

    }


    function mimax(uint64 x, uint64 y) internal pure

    returns (uint64 z) {

        return x >= y ? x : y;

    }


}


// Abstract contract for the full ERC 20 Token standard

// https://github.com/ethereum/EIPs/issues/20



contract BaseERC20 {

    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowed;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
	
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal;

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success);
    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success);
}

/** 
   * @title Ownable 
   * @dev The Ownable contract has an owner address, and provides basic authorization control 
   * functions, this simplifies the implementation of 
   "user permissions". 
*/ 

contract Ownable { 
	address public publishOwner; 
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner); 
	
	/**
	   * @dev The Ownable constructor sets the original `owner` of the contract to the sender 
	   * account. 
	   */
	function Ownable() public {
		publishOwner = msg.sender; 
	} 
	
	/**
	   * @dev Throws if called by any account other than the owner. 
	   */ 
	modifier onlyOwner() { 
		require(msg.sender == publishOwner); 
		_; 
	}
 
	/** 
      * @dev Allows the current owner to transfer control of the contract to a newOwner. 
      * @param newOwner The address to transfer ownership to. 
      */ 
	function transferOwnership(address newOwner) onlyOwner public { 
		require(newOwner != address(0)); 
		OwnershipTransferred(publishOwner, newOwner); 
		publishOwner = newOwner; 
	} 
} 

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable { 
	event Pause(); 
	event Unpause(); 
	bool public paused = false;
 
	/** 
      * @dev Modifier to make a function callable only when the contract is not paused. 
      */
	modifier whenNotPaused() 
	{ 
		require(!paused); 
		_; 
	}
	 /** 
       * @dev Modifier to make a function callable only when the contract is paused. 
       */
	modifier whenPaused() { 
		require(paused); 
		_;
	} 

	/** 
      * @dev called by the owner to pause, triggers stopped state 
      */ 
	function pause() onlyOwner whenNotPaused public { 
		paused = true; 
		Pause(); 
	} 

	/** 
      * @dev called by the owner to unpause, returns to normal state 
      */ 
	function unpause() onlyOwner whenPaused public {
		paused = false; 
		Unpause(); 
	} 
} 


/**

 * @title Standard ERC20 token

 *

 * @dev Implementation of the basic standard token.

 * @dev https://github.com/ethereum/EIPs/issues/20

 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol

 */

contract LightCoinToken is BaseERC20, BaseSafeMath, Pausable {

    //The solidity created time
	address public owner;
	address public lockOwner;
	uint256 public lockAmount ;
	uint256 public startTime ;
    function LightCoinToken() public {
		owner = 0x55ae8974743DB03761356D703A9cfc0F24045ebb;
		lockOwner = 0x07d4C8CC52BB7c4AB46A1A65DCEEdC1ab29aBDd6;
		startTime = 1515686400;
        name = "Lightcoin";
        symbol = "Light";
        decimals = 8;
        ///totalSupply = 21000000000000000000;
        totalSupply = 2.1e19;
		balanceOf[owner] = totalSupply * 90 /100;
		lockAmount = totalSupply * 10 / 100 ;
	    Transfer(address(0), owner, balanceOf[owner]);
    }

	/// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function getBalanceOf(address _owner) public constant returns (uint256 balance) {
		 return balanceOf[_owner];
	}
	
    function _transfer(address _from, address _to, uint256 _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);

        // Save this for an assertion in the future
        uint previousBalances = add(balanceOf[_from], balanceOf[_to]);
		
        // Subtract from the sender
        balanceOf[_from] = sub(balanceOf[_from], _value);
        // Add the same to the recipient
        balanceOf[_to] = add(balanceOf[_to], _value);
		
		// Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(add(balanceOf[_from], balanceOf[_to]) == previousBalances);
		
        Transfer(_from, _to, _value);

    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success)  {
        _transfer(msg.sender, _to, _value);
		return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success) {
        // Check allowance
        allowed[_from][msg.sender] = sub(allowed[_from][msg.sender], _value);
		
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowed[msg.sender][_spender] = _value;
		
		Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
	}
	
	function releaseToken() public{
	   uint256 releaseBegin = add(startTime,  2 * 365 * 86400);
	   require(now >= releaseBegin );
	   
	   uint256 interval = sub(now, releaseBegin);
       uint256 i = div(interval, (0.5 * 365 * 86400));
       if (i > 3) 
       {
            i = 3;
       }

	   uint256 releasevalue = div(totalSupply, 40);
	   uint256 remainInterval = sub(3, i);
	   
	   require(lockAmount > mul(remainInterval, releasevalue));
	   lockAmount = sub(lockAmount, releasevalue);
	   
	   balanceOf[lockOwner] = add( balanceOf[lockOwner],  releasevalue);
	   Transfer(address(0), lockOwner, releasevalue);
    }
    
    function () public payable{ revert(); }
}