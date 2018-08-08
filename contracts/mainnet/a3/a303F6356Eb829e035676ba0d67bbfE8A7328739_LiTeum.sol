pragma solidity ^0.4.11;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 */
contract ERC20 is ERC20Basic {
  function transferFrom(address from, address to, uint256 value) public returns (bool);
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b != 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
    function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
    }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

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
  constructor() public {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is ERC20, BasicToken {

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);

    emit Transfer(_from, _to, _value);
    return true;
  }

}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }
}

contract LiTeum is StandardToken, BurnableToken, Ownable {

    // Constants
    string  public constant name = "LiTeum";
    string  public constant symbol = "LTMF";
    uint8   public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 100000000000 * (10 ** uint256(decimals));



    // Properties
    address public adminAddr;               // the address of a admin currently selling this token
    bool    public transferEnabled = false; // indicates if transferring tokens is enabled or not

    // Modifiers
    modifier onlyWhenTransferEnabled() {
        if (!transferEnabled) {
            require(msg.sender == adminAddr);
        }
        _;
    }

    /**
     * The listed addresses are not valid recipients of tokens.
     *
     * 0x0           - the zero address is not valid
     * this          - the contract itself should not receive tokens
     * owner         - the owner has all the initial tokens, but cannot receive any back
     * adminAddr     - the admin has an allowance of tokens to transfer, but does not receive any
     */
    modifier validDestination(address _to) {
        require(_to != address(0x0));
        require(_to != address(this));
        require(_to != owner);
        _;
    }

    /**
     * Constructor - instantiates token supply and allocates balanace of
     * to the owner (msg.sender).
     */
    constructor(address _admin)public  {
        // the owner is a custodian of tokens.
        require(msg.sender != _admin);

        totalSupply = INITIAL_SUPPLY;

        // mint all tokens
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);

        adminAddr = _admin;
    }

    /**
     * Enables the ability of anyone to transfer their tokens. This can
     * only be called by the token owner. Once enabled, it is not
     * possible to disable transfers.
     */
    function enableTransfer() external onlyOwner {
        transferEnabled = true;

    }

    /**
     * Disable the token transfer. This can
     * only be called by the token owner.
     */
    function disableTransfer() external onlyOwner {
        transferEnabled = false;

    }

    /**
     * owner send tokens to admin.
     */
    function transferToAdmin(uint256 _value) public onlyOwner onlyWhenTransferEnabled returns (bool) {
    	return super.transfer(adminAddr, _value);
    }

    function adminTransfer(address _to, uint256 _value) public onlyWhenTransferEnabled returns (bool) {

    	require (msg.sender == adminAddr);
    	return super.transfer(_to, _value);

    }

    /**
     * Overrides ERC20 transfer function with modifier that prevents the
     * ability to transfer tokens until after transfers have been enabled.
     */
    function transfer(address _to, uint256 _value) public onlyWhenTransferEnabled validDestination(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
     * Overrides ERC20 transferFrom function with modifier that prevents the
     * ability to transfer tokens until after transfers have been enabled.
     */
    function transferFrom(address _from, address _to, uint256 _value) public onlyWhenTransferEnabled validDestination(_to) returns (bool) {
      require(msg.sender==_from);
      bool result = super.transferFrom(_from, _to, _value);
        return result;
    }

    /**
     * Overrides the burn function so that it cannot be called until after
     * transfers have been enabled.
     *
     */
    function burn(uint256 _value) public {
        require(transferEnabled || msg.sender == owner);
        super.burn(_value);
        emit Transfer(msg.sender, address(0x0), _value);
    }

    /**
    *function to kill the token
    */
    function kill() public onlyOwner
    {
        selfdestruct(owner);
    }
}