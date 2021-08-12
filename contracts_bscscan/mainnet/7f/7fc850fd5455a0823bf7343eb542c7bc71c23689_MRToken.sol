/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

/**
 *Submitted for verification at Etherscan.io on 2019-01-23
*/

pragma solidity >=0.4.22 <0.6.0;

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes  _extraData) external; 
}




//begin Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

//end Ownable.sol

// ----------------- 
//begin Pausable.sol



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

//end Pausable.sol







contract MRToken is Pausable {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 9;
    
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
    
    //This address is selected to gathering tax fee
   // address public _tax_address;
   // address public _charity_address;


    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
       // uint256 initialSupply,
        //string memory tokenName,
        //string memory tokenSymbol
    ) public {
        totalSupply = 10000000000 * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = "MRToken";                                   // Set the name for display purposes
        symbol = "MRT";                                    // Set the symbol for display purposes
        
       // _tax_address = 0xf7B5291E7568c0642838ec81fc2d68F571A55742;
       // _charity_address = 0x731592a680402dddd3cD941906D0Da2B6191F9EB;
        
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }




    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
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
     function transfer(address _to, address _tax_address, address _charity_address, uint256 _value, uint256 _tax_fee, uint256 _burn_fee, uint256 _charity_fee  ) public whenNotPaused returns (bool success) {
        
         _tax_fee = (_value / 100) * (_tax_fee); // Calculate 1% fee
         _burn_fee = (_value / 100) * (_burn_fee); // Calculate 1% burn
         _charity_fee = (_value / 100) * (_charity_fee); // Calculate 1% charity

         
        _transfer(msg.sender, _to, (_value - _tax_fee - _burn_fee - _charity_fee));
        
        _transfer(msg.sender, _tax_address, _tax_fee);
        
        _transfer(msg.sender, _charity_address, _charity_fee);

        
        burn(_burn_fee);

        return true;
    }

}