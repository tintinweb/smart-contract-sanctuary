pragma solidity ^0.4.8;

/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint256 a, uint256 b)  internal pure returns (uint256) {
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

  function safeSub(uint256 a, uint256 b) internal pure  returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >=a);
    return c;
  }

 
  
}
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

  function kill() public {
      if (msg.sender == owner)
          selfdestruct(owner);
  }
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
  modifier whenNotPaused() {
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
    emit Pause();
  }
  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract richtestkk is SafeMath,Pausable{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
	  address public owner;
    uint256 public startTime;
    uint256[9] public founderAmounts;
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
	  mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

	/* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);

	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function richtestkk(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) public {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
		    owner = msg.sender;
        startTime=now;
        founderAmounts = [427*10** uint256(25), 304*10** uint256(25), 217*10** uint256(25), 154*10** uint256(25), 11*10** uint256(25), 78*10** uint256(25), 56*10** uint256(25), 34*10** uint256(25), 2*10** uint256(26)];
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public whenNotPaused {
        if (_to == 0x0) revert();                               // Prevent transfer to 0x0 address. Use burn() instead
        if (balanceOf[msg.sender] < _value) revert();           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); // Check for overflows
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    function minutestotal() public onlyOwner 
    {
       if (now > startTime + 3 days&& founderAmounts[0]>0)
       {
        totalSupply=  SafeMath.safeAdd(totalSupply, founderAmounts[0]);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], founderAmounts[0]);
        founderAmounts[0]=0;
        emit  Transfer(0, msg.sender, founderAmounts[0]);

       }
       if (now > startTime + 6 days&& founderAmounts[1]>0)
       {
        totalSupply=  SafeMath.safeAdd(totalSupply, founderAmounts[1]);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], founderAmounts[1]);
        founderAmounts[1]=0;
        emit Transfer(0, msg.sender, founderAmounts[1]);

       }
        if (now > startTime + 9 days&& founderAmounts[2]>0)
       {
        totalSupply=  SafeMath.safeAdd(totalSupply, founderAmounts[2]);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], founderAmounts[2]);
        founderAmounts[2]=0;
        emit Transfer(0, msg.sender, founderAmounts[2]);
       }

        if (now > startTime + 12 days&& founderAmounts[3]>0)
       {
        totalSupply=  SafeMath.safeAdd(totalSupply, founderAmounts[3]);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], founderAmounts[3]);
        founderAmounts[3]=0;
        emit  Transfer(0, msg.sender, founderAmounts[3]);
       }
        if (now > startTime + 15 days&& founderAmounts[4]>0)
       {
        totalSupply=  SafeMath.safeAdd(totalSupply, founderAmounts[4]);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], founderAmounts[4]);
        founderAmounts[4]=0;
        emit Transfer(0, msg.sender, founderAmounts[4]);
       }
        if (now > startTime + 18 days&& founderAmounts[5]>0)
       {
        totalSupply=  SafeMath.safeAdd(totalSupply, founderAmounts[5]);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], founderAmounts[5]);
        founderAmounts[5]=0;
        emit  Transfer(0, msg.sender, founderAmounts[5]);
       }
        if (now > startTime + 21 days&& founderAmounts[6]>0)
       {
        totalSupply=  SafeMath.safeAdd(totalSupply, founderAmounts[6]);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], founderAmounts[6]);
        founderAmounts[6]=0;
        emit  Transfer(0, msg.sender, founderAmounts[6]);
       }
         if (now > startTime + 24 days&& founderAmounts[7]>0)
       {
        totalSupply=  SafeMath.safeAdd(totalSupply, founderAmounts[7]);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], founderAmounts[7]);
        founderAmounts[7]=0;
        emit  Transfer(0, msg.sender, founderAmounts[7]);
       }
        if (now > startTime + 27 days&& founderAmounts[8]>0)
       {
        totalSupply=  SafeMath.safeAdd(totalSupply, founderAmounts[8]);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], founderAmounts[8]);
        founderAmounts[8]=0;
        emit  Transfer(0, msg.sender, founderAmounts[8]);
       }
    }
    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public whenNotPaused  returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit  Approval(msg.sender, _spender, _value);
        return true;
    }


    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success) {
        if (_to == 0x0) revert();                                // Prevent transfer to 0x0 address. 
        if (balanceOf[_from] < _value) revert();                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  // Check for overflows
        if (_value > allowance[_from][msg.sender]) revert();     // Check allowance
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }


	function freeze(uint256 _value) public whenNotPaused returns (bool success) {
        if (balanceOf[msg.sender] < _value) revert();            // Check if the sender has enough
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                // Updates totalSupply
        emit  Freeze(msg.sender, _value);
        return true;
    }

	function unfreeze(uint256 _value) public whenNotPaused returns (bool success) {
        if (freezeOf[msg.sender] < _value) revert();            // Check if the sender has enough
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                      // Subtract from the sender
		    balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }


}