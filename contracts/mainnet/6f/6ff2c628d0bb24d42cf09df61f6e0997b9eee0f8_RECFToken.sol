pragma solidity ^0.4.21;

//SAFEMATHLIBRARY
//mmp
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}




 
contract RECFToken is owned {
    
    using SafeMath for uint256;
    
    // Public variables of the token
    string public constant name = "RealEstateCryptoFund";
    string public constant symbol = "RECF";
    // 18 decimals is the strongly suggested default, avoid changing it
    uint8 public constant decimals = 18;

    uint256 public totalSupply;

    // This creates an array with all balanceOf
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    bool public mintingFinished = false;

    modifier canMint() {
    require(!mintingFinished);
    _;
    }

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function RECFToken(
        uint256 initialSupply
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        
    }

       /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balanceOf[msg.sender]);
    // SafeMath.sub will throw if there is not enough balance.
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balanceOf[_from]);
    require(_value <= allowance[_from][msg.sender]);

    balanceOf[_from] = balanceOf[_from].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
    }


/* Internal transfer, only can be called by this contract */
function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));                                // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);                      // Check if the sender has enough
        require (balanceOf[_to].add(_value) >= balanceOf[_to]);    // Check for overflows
        balanceOf[_from] = balanceOf[_from].sub(_value);             // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);               // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }

    /**
* @dev Function to mint tokens
* @param _to The address that will receive the minted tokens.
* @param _amount The amount of tokens to mint.
* @return A boolean that indicates if the operation was successful.
*/
function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balanceOf[_to] = balanceOf[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
    }

    /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
    }  

    
   /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
function burn(uint256 _value) onlyOwner public {
    require(_value <= balanceOf[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balanceOf[burner] = balanceOf[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(burner, _value);
    emit Transfer(burner, address(0), _value);
  }


/**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
      
     */
function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[_from] >= _value);                                                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);                                    // Check allowance
        balanceOf[_from] = balanceOf[_from].sub(_value);                                   // Subtract from the targeted balance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);             // Subtract from the sender&#39;s allowance
        totalSupply = totalSupply.sub(_value);                                                // Update totalSupply
        emit Burn(_from, _value);
        return true;
        }



}