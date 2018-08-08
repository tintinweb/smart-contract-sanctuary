pragma solidity ^0.4.13;

/**
 * @title SKP-T ERC20 token by Sleekplay.
 *
 * @dev Based on OpenZeppelin framework.
 *
 * Features:
 *
 * * ERC20 compatibility, with token details as properties.
 * * total supply: 6400000000 (initially given to the contract author).
 * * decimals: 18
 * * BurnableToken: some addresses are allowed to burn tokens.
 * * “third-party smart contract trading protection”: transferFrom/approve/allowance methods are present but do nothing.
 * * TimeLock: implemented externally (in TokenTimelock contract)
 */

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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
    require(_value <= balances[msg.sender]);

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
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SKPT is BasicToken, BurnableToken, ERC20, Ownable {

    string public constant name = "SKP-T: Sleekplay Token";
    string public constant symbol = "SKPT";
    uint8 public constant decimals = 18;
    string public constant version = "1.0";

    uint256 constant INITIAL_SUPPLY_SKPT = 6400000000;

    /// @dev whether an address is permitted to perform burn operations.
    mapping(address => bool) public isBurner;

    /**
     * @dev Constructor that:
     * * gives all of existing tokens to the message sender;
     * * initializes the burners (also adding the message sender);
     */
    function SKPT() public {
        totalSupply = INITIAL_SUPPLY_SKPT * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply;

        isBurner[msg.sender] = true;
    }

    /**
     * @dev Standard method to comply with ERC20 interface;
     * prevents some Ethereum-contract-initiated operations.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        return false;
    }

    /**
     * @dev Standard method to comply with ERC20 interface;
     * prevents some Ethereum-contract-initiated operations.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        return false;
    }

    /**
     * @dev Standard method to comply with ERC20 interface;
     * prevents some Ethereum-contract-initiated operations.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return 0;
    }

    /**
     * @dev Grant or remove burn permissions. Only owner can do that!
     */
    function grantBurner(address _burner, bool _value) public onlyOwner {
        isBurner[_burner] = _value;
    }

    /**
     * @dev Throws if called by any account other than the burner.
     */
    modifier onlyBurner() {
        require(isBurner[msg.sender]);
        _;
    }

    /**
     * @dev Burns a specific amount of tokens.
     * Only an address listed in `isBurner` can do this.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public onlyBurner {
        super.burn(_value);
    }
    
}