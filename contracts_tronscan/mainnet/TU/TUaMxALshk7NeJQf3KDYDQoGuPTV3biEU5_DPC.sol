//SourceUnit: NSA.sol

/**
 *Submitted for verification at Etherscan.io on 2017-12-28
*/

pragma solidity 0.5.12;

/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}
contract DPC is SafeMath{
    string public name;
    string public symbol;
    address payable public owner;
    uint8 public decimals;
    uint256 public totalSupply;
    address public icoContractAddress;
    uint256 public  tokensTotalSupply =  33000000 * 10**6;
    mapping (address => bool) restrictedAddresses;
    uint256 constant initialSupply = 33000000 * 10**6;
    string constant  tokenName = 'Dark Pool Chain';
    uint8 constant decimalUnits = 6;
    string constant tokenSymbol = 'DPC';


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
    //  Mint event
    event Mint(address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    modifier onlyOwner {
      assert(owner == msg.sender);
      _;
    }

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor() public {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
	    owner = msg.sender;
    }

    /* Send coins */
    function  transfer(address _to, uint256 _value) public {
		require (_value > 0) ;
        require (balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to]) ;     // Check for overflows
        require (!restrictedAddresses[_to]);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;          // Set allowance
      	emit Approval(msg.sender, _spender, _value);             // Raise Approval event
      		return true;
    }

    function prodTokens(address _to, uint256 _amount) public
    onlyOwner {
      require (_amount != 0 ) ;   // Check if values are not null;
      require (balanceOf[_to] + _amount > balanceOf[_to]) ;     // Check for overflows
      require (totalSupply <=tokensTotalSupply);
      //require (!restrictedAddresses[_to]);
      totalSupply += _amount;                                      // Update total supply
      balanceOf[_to] += _amount;                    		    // Set minted coins to target
      emit Mint(_to, _amount);                          		    // Create Mint event
      emit Transfer(address(0), _to, _amount);                            // Create Transfer event from 0x
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require (balanceOf[_from] >= _value);                 // Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to]) ;  // Check for overflows
        require (_value <= allowance[_from][msg.sender]) ;     // Check allowance
        require (!restrictedAddresses[_to]);
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] >= _value) ;            // Check if the sender has enough
		    require (_value >= 0) ;
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

	function freeze(uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] >= _value) ;            // Check if the sender has enough
		    require (_value > 0) ;
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }

	function unfreeze(uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] >= _value) ;            // Check if the sender has enough
        require (_value > 0) ;
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                      // Subtract from the sender
		    balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function() external payable {
    revert();
    }

    /* Owner can add new restricted address or removes one */
	function editRestrictedAddress(address _newRestrictedAddress) public onlyOwner {
		restrictedAddresses[_newRestrictedAddress] = !restrictedAddresses[_newRestrictedAddress];
	}

	function isRestrictedAddress(address _querryAddress) public view returns (bool answer){
		return restrictedAddresses[_querryAddress];
	}
}