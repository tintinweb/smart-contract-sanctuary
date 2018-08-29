pragma solidity ^0.4.21;

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
/**
 * Math operations with safety checks
 */
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract BigerToken is Ownable {
   /**
  * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint256 size) {
    require(size > 0);
    require(msg.data.length >= size + 4) ;
    _;
  }
  using SafeMath for uint256;
    
  string public constant name = "BigerToken";
  string public constant symbol = "BG";
  uint256 public constant decimals = 18;
  string public version = "1.0";
  uint256 public  totalSupply = 100 * (10**8) * 10**decimals;   // 100*10^8 BG total
  //address public owner;
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
	
	/* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
	
	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract  constructor() public */
 function BigerToken() public {
    balanceOf[msg.sender] = totalSupply;
    owner = msg.sender;
    emit Transfer(0x0, msg.sender, totalSupply);
  }

    /* Send coins */
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool){
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(this)); //Prevent to contract address
		require(0 <= _value); 
        require(_value <= balanceOf[msg.sender]);           // Check if the sender has enough
        require(balanceOf[_to] <= balanceOf[_to] + _value); // Check for overflows
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public returns (bool success) {
		require (0 <= _value ) ; 
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public returns (bool success) {
        require (_to != 0x0);             // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(this));        //Prevent to contract address
		require( 0 <= _value); 
        require(_value <= balanceOf[_from]);                 // Check if the sender has enough
        require( balanceOf[_to] <= balanceOf[_to] + _value) ;  // Check for overflows
        require(_value <= allowance[_from][msg.sender]) ;     // Check allowance
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) onlyOwner public returns (bool success) {
        require(_value <= balanceOf[msg.sender]);            // Check if the sender has enough
		require(0 <= _value); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
	
	function freeze(uint256 _value) onlyOwner public returns (bool success) {
        require(_value <= balanceOf[msg.sender]);            // Check if the sender has enough
		require(0 <= _value); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) onlyOwner public returns (bool success) {
        require( _value <= freezeOf[msg.sender]);            // Check if the sender has enough
		require(0 <= _value) ; 
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                      // Subtract from the sender
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
	
	// can not accept ether
	function() payable public {
	     revert();
    }
}