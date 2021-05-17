/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

pragma solidity ^0.4.23;

/**
 * Math operations with safety checks
 */
contract SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        require(a == b * c + a % b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c>=a && c>=b);
        return c;
    }
  }

contract BitgetToken is SafeMath{   
    address public owner;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    string public name;
    string public symbol;
     /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezeOf;

    //events
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
	
	/* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
	
	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    constructor(
        uint256 initSupply, 
        string tokenName, 
        string tokenSymbol, 
        uint8 decimalUnits) public {
        owner = msg.sender;
        totalSupply = initSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;  
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // public functions
    /// @return total amount of tokens
    function totalSupply() public view returns (uint256){
        return totalSupply;
    }

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256) {
        return balanceOf[_owner];
    }
    
    /// @param _owner The address from which the freeze amount will be retrieved
    /// @return The freeze amount
    function freezeOf(address _owner) public view returns (uint256) {
        return freezeOf[_owner];
    }

    /* Send coins */
    /* This generates a public event on the blockchain that will notify clients */
    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    function transfer(address _to, uint256 _value) public {
        require(_to != 0x0);                                // Prevent transfer to 0x0 address.
        require(_value > 0);                                // Check send amount is greater than 0.
        require(balanceOf[msg.sender] >= _value);           // Check balance of the sender is enough
        require(balanceOf[_to] + _value > balanceOf[_to]);  // Check for overflow
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);// Subtract _value amount from the sender
        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);// Add the same amount to the recipient
        emit Transfer(msg.sender, _to, _value);// Notify anyone listening that this transfer took place
    }

    /* Burn coins */
    /// @notice burn `_value` token of owner
    /// @param _value The amount of token to be burned
    function burn(uint256 _value) public {
        require(owner == msg.sender);                //Check owner
        require(balanceOf[msg.sender] >= _value);    // Check if the sender has enough
        require(_value > 0);                         //Check _value is valid
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);    // Subtract from the owner
        totalSupply = SafeMath.sub(totalSupply,_value);                         // Updates totalSupply
        emit Burn(msg.sender, _value);
    }
	
    /// @notice freeze `_value` token of '_addr' address
    /// @param _addr The address to be freezed
    /// @param _value The amount of token to be freezed
	function freeze(address _addr, uint256 _value) public {
        require(owner == msg.sender);                //Check owner
        require(balanceOf[_addr] >= _value);         // Check if the sender has enough
		require(_value > 0);                         //Check _value is valid
        balanceOf[_addr] = SafeMath.sub(balanceOf[_addr], _value);              // Subtract _value amount from balance of _addr address
        freezeOf[_addr] = SafeMath.add(freezeOf[_addr], _value);                // Add the same amount to freeze of _addr address
        emit Freeze(_addr, _value);
    }
	
    /// @notice unfreeze `_value` token of '_addr' address
    /// @param _addr The address to be unfreezed
    /// @param _value The amount of token to be unfreezed
	function unfreeze(address _addr, uint256 _value) public {
        require(owner == msg.sender);                //Check owner
        require(freezeOf[_addr] >= _value);          // Check if the sender has enough
		require(_value > 0);                         //Check _value is valid
        freezeOf[_addr] = SafeMath.sub(freezeOf[_addr], _value);                // Subtract _value amount from freeze of _addr address
		balanceOf[_addr] = SafeMath.add(balanceOf[_addr], _value);              // Add the same amount to balance of _addr address
        emit Unfreeze(_addr, _value);
    }

    // transfer balance to owner
	function withdrawEther(uint256 amount) public {
		require(owner == msg.sender);
		owner.transfer(amount);
	}
	
	// can accept ether
	function() payable public {
    }
}