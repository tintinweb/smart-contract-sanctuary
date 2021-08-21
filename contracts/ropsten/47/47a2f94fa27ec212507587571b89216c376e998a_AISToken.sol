/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

}

contract Ownable is SafeMath {
    address public owner;

    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
    constructor() {
        owner = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the owner.
      */
    modifier onlyOwner() {
        require(msg.sender == owner,"Your have unathorize person");
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
            owner = newOwner;
    }

}

contract AISToken is Ownable{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf; /* This creates an array with all balances */
	mapping (address => uint256) public freezeOf; /* This creates an array for all freeze account address */
    mapping (address => mapping (address => uint256)) public allowance; /* This creates an array for all allowance */
    mapping (address => bool) public isBlackListed; /* This creates an array for all blacklist account address */
    
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
	
	/* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
	
	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);
    
    /* This notifies clients about the MintToken */
    event MintToken(address indexed from, uint256 value);
    
    /* This notifies clients about the DestroyBlacklist account funds */
    event DestroyedBlackFunds(address _blackListedUser, uint _balance);
    
    event AddedBlackList(address _user); /* This notifies clients about the blacklist user*/
    event RemovedBlackList(address _user); /* This notifies clients about the remove blacklist user*/
    
    /* @dev  account chcek is block or not */
     modifier isBlock() {
        require(!isBlackListed[msg.sender],"Administrator block your account");
        _;
    }

    constructor(uint256 initialSupply, string memory tokenName, uint8 decimalUnits, string memory _tokenSymbol){
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
		owner = msg.sender;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public isBlock {
        // require (_to == 0x0,"Invalid Address");                               // Prevent transfer to 0x0 address. Use burn() instead
		require (_value > 0,"Enter number greater than zero"); 
        require (balanceOf[msg.sender] >= _value,"Insufficient funds to allow transfer");           // Check if the sender has enough
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public isBlock returns (bool success) {
		require (_value > 0,"Enter number greater than zero"); 
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value)public isBlock returns (bool success) {
		require (_value > 0,"Enter number greater than zero"); 
        require (balanceOf[_from] >= _value,"Insufficient funds to allow transfer");                 // Check if the sender has enough
        require (_value <= allowance[_from][msg.sender],"Insufficient funds to allow transfer");     // Check allowance
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    // Burn a new amount of tokens
    // these tokens are deposited into the owner address
    //
    // @param _amount Number of tokens to be burn
    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require (_value > 0,"Enter number greater than zero"); 
        require (balanceOf[msg.sender] >= _value,"Insufficient funds to allow burn");            // Check if the sender has enough
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
    
    // Mint an amount of tokens
    // these tokens are withdraw into the owner address
    //
    // @param _amount Number of tokens to be mint
    function mint(uint256 _value)public onlyOwner returns (bool success){
        require (_value > 0,"Enter number greater than zero"); 
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        totalSupply = SafeMath.safeAdd(totalSupply, _value); 
        emit MintToken(msg.sender,balanceOf[msg.sender]);
        return true;
    }
    
    // Account owner freeze his amount of token  
    function freeze(uint256 _value)public isBlock returns (bool success) {
	    require (_value > 0,"Enter number greater than zero"); 
        require (balanceOf[msg.sender] >= _value,"Insufficient funds to allow freeze");            // Check if the sender has enough
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	// Account owner unfreeze his amount of token  
	function unfreeze(uint256 _value)public isBlock returns (bool success) {
	    require (_value > 0,"Enter number greater than zero"); 
        require (freezeOf[msg.sender] >= _value,"Insufficient funds to allow unfreeze");            // Check if the sender has enough
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                      // Subtract from the sender
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }

    // get blacklist account status
    function getBlackListStatus(address _maker) public view returns (bool) {
        return isBlackListed[_maker];
    }

    // Owner add to blacklist other account
    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    // Owner remove blacklist account
    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }
    
    // Owner blacklist account fund transfer to own account
    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf[_blackListedUser];
        balanceOf[_blackListedUser] = 0;
        totalSupply -= dirtyFunds;
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], dirtyFunds);
        totalSupply = SafeMath.safeAdd(totalSupply, dirtyFunds); 
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }
}