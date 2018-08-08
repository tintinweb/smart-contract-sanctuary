pragma solidity  ^0.4.21;

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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */

contract ERC20Interface {

    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint totalSupply);
    is replaced with:
    uint public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// Total amount of tokens
    uint public totalSupply;

    /**
     * @dev Get the account balance of another account with address _owner
     * @param _owner address The address from which the balance will be retrieved
     * @return uint The balance
     */
    function balanceOf(address _owner) public constant returns (uint balance);

    /**
     * @dev Send _value amount of tokens to address _to from `msg.sender`
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint _value) public returns (bool success);

    /**
     * @dev Send _value amount of tokens from address _from to address _to
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amount of tokens to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);

    /**
     * @dev Allow _spender to withdraw from your account, multiple times, up to the _value amount
     * If this function is called again it overwrites the current allowance with _value.
     * this function is required for some DEX functionality
     *
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of tokens to be approved for transfer
     */
    function approve(address _spender, uint _value) public returns (bool success);

    /**
     * @dev Returns the amount which _spender is still allowed to withdraw from _owner
     * @param _owner The address of the account owning tokens
     * @param _spender The address of the account able to transfer the tokens
     * @return A uint specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public constant returns (uint remaining);

    /// Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint _value);
    /// Triggered whenever approve(address _spender, uint _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    /// Triggered when _value of tokens are minted for _owner
    event Mint(address _owner, uint _value);
    /// Triggered when mint finished
    event MintFinished();
    /// This notifies clients about the amount burnt
    event Burn(address indexed _from, uint _value);
}

contract ERC20Token is ERC20Interface {

    using SafeMath for uint;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        require(_value <= balances[msg.sender]);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        _transferFrom(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        // TODO: Revert _value if we have some problems with transfer
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transferFrom(_from, _to, _value);
        return true;
    }

    function _transferFrom(address _from, address _to, uint _value) internal {
        require(_to != address(0)); // Use burnTokens for this case
        require(_value > 0);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
    }
}

contract TokenReceiver {
  function tokenFallback(address _sender, address _origin, uint _value) public returns (bool ok);
}

contract Burnable is ERC20Interface {

  /**
   * @dev Function to burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   * @return A boolean that indicates if the operation was successful
   */
  function burnTokens(uint _value) public returns (bool success);

  /**
   * @dev Function to burns a specific amount of tokens from another account that `msg.sender`
   * was approved to burn tokens for using `approve` earlier.
   * @param _from The address to burn tokens from.
   * @param _value The amount of token to be burned.
   * @return A boolean that indicates if the operation was successful
   */
  function burnFrom(address _from, uint _value) public returns (bool success);

}

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

contract LEN is ERC20Token, Ownable {

    using SafeMath for uint;

    string public name = "LIQNET";         // Original name
    string public symbol = "LEN";                   // Token identifier
    uint8 public decimals = 8;                      // How many decimals to show
    bool public mintingFinished;         // Status of minting

    event Transfer(address indexed _from, address indexed _to, uint _value, bytes _data);

    /**
     * @dev Function to mint tokens
     * @param target The address that will receive the minted tokens
     * @param mintedAmount The amount of tokens to mint
     * @return A boolean that indicates if the operation was successful
     */
    function mintTokens(address target, uint mintedAmount) public onlyOwner returns (bool success) {
        require(!mintingFinished); // Can minting
        totalSupply = totalSupply.add(mintedAmount);
        balances[target] = balances[target].add(mintedAmount);
        Mint(target, mintedAmount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens
     * @return A boolean that indicates if the operation was successful
     */
    function finishMinting() public onlyOwner returns (bool success) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

      /**
       * @dev Function that is called when a user or another contract wants
       *  to transfer funds .
       * @return A boolean that indicates if the operation was successful
       */
    function transfer(address _to, uint _value) public returns (bool success) {
        if (isContract(_to)) {
            return _transferToContract(msg.sender, _to, _value);
        } else {
            _transferFrom(msg.sender, _to, _value);
            return true;
        }
    }

    /**
     * @dev Function to burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     * @return A boolean that indicates if the operation was successful
     */
    function burnTokens(uint _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        totalSupply = totalSupply.sub(_value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * @dev Function to burns a specific amount of tokens from another account that `msg.sender`
     * was approved to burn tokens for using `approve` earlier.
     * @param _from The address to burn tokens from.
     * @param _value The amount of token to be burned.
     * @return A boolean that indicates if the operation was successful
     */
    function burnFrom(address _from, uint _value) public returns (bool success) {
        require(_value > 0);
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);

        Burn(_from, _value);
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private returns (bool is_contract) {
        uint length;
        assembly {
             //retrieve the size of the code on target address, this needs assembly
             length := extcodesize(_addr)
        }
        return (length > 0);
     }

   /**
    * @dev Function that is called when a user or another contract wants
    *  to transfer funds to smart-contract
    * @return A boolean that indicates if the operation was successful
    */
    function _transferToContract(address _from, address _to, uint _value) private returns (bool success) {
        _transferFrom(msg.sender, _to, _value);
        TokenReceiver receiver = TokenReceiver(_to);
        receiver.tokenFallback(msg.sender, this, _value);
        return true;
    }
}