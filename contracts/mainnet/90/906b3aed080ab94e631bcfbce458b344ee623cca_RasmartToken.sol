pragma solidity ^0.4.25;

/// @title Role based access control mixin for Rasmart Platform
/// @author Abha Mai <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="bad7dbd3dbd8d2db8288faddd7dbd3d694d9d5d7">[email&#160;protected]</a>>
/// @dev Ignore DRY approach to achieve readability
contract RBACMixin {
  /// @notice Constant string message to throw on lack of access
  string constant FORBIDDEN = "Haven&#39;t enough right to access";
  /// @notice Public map of owners
  mapping (address => bool) public owners;
  /// @notice Public map of minters
  mapping (address => bool) public minters;

  /// @notice The event indicates the addition of a new owner
  /// @param who is address of added owner
  event AddOwner(address indexed who);
  /// @notice The event indicates the deletion of an owner
  /// @param who is address of deleted owner
  event DeleteOwner(address indexed who);

  /// @notice The event indicates the addition of a new minter
  /// @param who is address of added minter
  event AddMinter(address indexed who);
  /// @notice The event indicates the deletion of a minter
  /// @param who is address of deleted minter
  event DeleteMinter(address indexed who);

  constructor () public {
    _setOwner(msg.sender, true);
  }

  /// @notice The functional modifier rejects the interaction of senders who are not owners
  modifier onlyOwner() {
    require(isOwner(msg.sender), FORBIDDEN);
    _;
  }

  /// @notice Functional modifier for rejecting the interaction of senders that are not minters
  modifier onlyMinter() {
    require(isMinter(msg.sender), FORBIDDEN);
    _;
  }

  /// @notice Look up for the owner role on providen address
  /// @param _who is address to look up
  /// @return A boolean of owner role
  function isOwner(address _who) public view returns (bool) {
    return owners[_who];
  }

  /// @notice Look up for the minter role on providen address
  /// @param _who is address to look up
  /// @return A boolean of minter role
  function isMinter(address _who) public view returns (bool) {
    return minters[_who];
  }

  /// @notice Adds the owner role to provided address
  /// @dev Requires owner role to interact
  /// @param _who is address to add role
  /// @return A boolean that indicates if the operation was successful.
  function addOwner(address _who) public onlyOwner returns (bool) {
    _setOwner(_who, true);
  }

  /// @notice Deletes the owner role to provided address
  /// @dev Requires owner role to interact
  /// @param _who is address to delete role
  /// @return A boolean that indicates if the operation was successful.
  function deleteOwner(address _who) public onlyOwner returns (bool) {
    _setOwner(_who, false);
  }

  /// @notice Adds the minter role to provided address
  /// @dev Requires owner role to interact
  /// @param _who is address to add role
  /// @return A boolean that indicates if the operation was successful.
  function addMinter(address _who) public onlyOwner returns (bool) {
    _setMinter(_who, true);
  }

  /// @notice Deletes the minter role to provided address
  /// @dev Requires owner role to interact
  /// @param _who is address to delete role
  /// @return A boolean that indicates if the operation was successful.
  function deleteMinter(address _who) public onlyOwner returns (bool) {
    _setMinter(_who, false);
  }

  /// @notice Changes the owner role to provided address
  /// @param _who is address to change role
  /// @param _flag is next role status after success
  /// @return A boolean that indicates if the operation was successful.
  function _setOwner(address _who, bool _flag) private returns (bool) {
    require(owners[_who] != _flag);
    owners[_who] = _flag;
    if (_flag) {
      emit AddOwner(_who);
    } else {
      emit DeleteOwner(_who);
    }
    return true;
  }

  /// @notice Changes the minter role to provided address
  /// @param _who is address to change role
  /// @param _flag is next role status after success
  /// @return A boolean that indicates if the operation was successful.
  function _setMinter(address _who, bool _flag) private returns (bool) {
    require(minters[_who] != _flag);
    minters[_who] = _flag;
    if (_flag) {
      emit AddMinter(_who);
    } else {
      emit DeleteMinter(_who);
    }
    return true;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
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

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

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
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract RBACMintableTokenMixin is StandardToken, RBACMixin {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    onlyMinter
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint internal returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract ERC223ReceiverMixin {
  function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

/// @title Custom implementation of ERC223 
/// @author Abha Mai <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="93fef2faf2f1fbf2aba1d3f4fef2faffbdf0fcfe">[email&#160;protected]</a>>
contract ERC223Mixin is StandardToken {
  event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public returns (bool) 
  {
    bytes memory empty;
    return transferFrom(
      _from, 
      _to,
      _value,
      empty);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  ) public returns (bool)
  {
    require(_value <= allowed[_from][msg.sender]);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    if (isContract(_to)) {
      return transferToContract(
        _from, 
        _to, 
        _value, 
        _data);
    } else {
      return transferToAddress(
        _from, 
        _to, 
        _value, 
        _data); 
    }
  }

  function transfer(address _to, uint256 _value, bytes _data) public returns (bool success) {
    if (isContract(_to)) {
      return transferToContract(
        msg.sender,
        _to,
        _value,
        _data); 
    } else {
      return transferToAddress(
        msg.sender,
        _to,
        _value,
        _data);
    }
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    bytes memory empty;
    return transfer(_to, _value, empty);
  }

  function isContract(address _addr) internal view returns (bool) {
    uint256 length;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      //retrieve the size of the code on target address, this needs assembly
      length := extcodesize(_addr)
    }  
    return (length>0);
  }

  function moveTokens(address _from, address _to, uint256 _value) internal returns (bool success) {
    if (balanceOf(_from) < _value) {
      revert();
    }
    balances[_from] = balanceOf(_from).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);

    return true;
  }

  function transferToAddress(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  ) internal returns (bool success) 
  {
    require(moveTokens(_from, _to, _value));
    emit Transfer(_from, _to, _value);
    emit Transfer(_from, _to, _value, _data); // solium-disable-line arg-overflow
    return true;
  }
  
  //function that is called when transaction target is a contract
  function transferToContract(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  ) internal returns (bool success) 
  {
    require(moveTokens(_from, _to, _value));
    ERC223ReceiverMixin(_to).tokenFallback(_from, _value, _data);
    emit Transfer(_from, _to, _value);
    emit Transfer(_from, _to, _value, _data); // solium-disable-line arg-overflow
    return true;
  }
}

/// @title Role based token finalization mixin
/// @author Abha Mai <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f79a969e96959f96cfc5b7909a969e9bd994989a">[email&#160;protected]</a>>
contract RBACERC223TokenFinalization is ERC223Mixin, RBACMixin {
  event Finalize();
  /// @notice Public field inicates the finalization state of smart-contract
  bool public finalized;

  /// @notice The functional modifier rejects the interaction if contract isn&#39;t finalized
  modifier isFinalized() {
    require(finalized);
    _;
  }

  /// @notice The functional modifier rejects the interaction if contract is finalized
  modifier notFinalized() {
    require(!finalized);
    _;
  }

  /// @notice Finalizes contract
  /// @dev Requires owner role to interact
  /// @return A boolean that indicates if the operation was successful.
  function finalize() public notFinalized onlyOwner returns (bool) {
    finalized = true;
    emit Finalize();
    return true;
  }

  /// @dev Overrides ERC20 interface to prevent interaction before finalization
  function transferFrom(address _from, address _to, uint256 _value) public isFinalized returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  /// @dev Overrides ERC223 interface to prevent interaction before finalization
  // solium-disable-next-line arg-overflow
  function transferFrom(address _from, address _to, uint256 _value, bytes _data) public isFinalized returns (bool) {
    return super.transferFrom(_from, _to, _value, _data); // solium-disable-line arg-overflow
  }

  /// @dev Overrides ERC223 interface to prevent interaction before finalization
  function transfer(address _to, uint256 _value, bytes _data) public isFinalized returns (bool) {
    return super.transfer(_to, _value, _data);
  }

  /// @dev Overrides ERC20 interface to prevent interaction before finalization
  function transfer(address _to, uint256 _value) public isFinalized returns (bool) {
    return super.transfer(_to, _value);
  }

  /// @dev Overrides ERC20 interface to prevent interaction before finalization
  function approve(address _spender, uint256 _value) public isFinalized returns (bool) {
    return super.approve(_spender, _value);
  }

  /// @dev Overrides ERC20 interface to prevent interaction before finalization
  function increaseApproval(address _spender, uint256 _addedValue) public isFinalized returns (bool) {
    return super.increaseApproval(_spender, _addedValue);
  }

  /// @dev Overrides ERC20 interface to prevent interaction before finalization
  function decreaseApproval(address _spender, uint256 _subtractedValue) public isFinalized returns (bool) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

/**
 * @title Standard Burnable Token
 * @dev Adds burnFrom method to ERC20 implementations
 */
contract StandardBurnableToken is BurnableToken, StandardToken {

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param _from address The address which you want to send tokens from
   * @param _value uint256 The amount of token to be burned
   */
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}

/// @title Rasmart Platform token implementation
/// @author Abha Mai <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="5439353d35363c356c66143339353d387a373b39">[email&#160;protected]</a>>
/// @dev Implements ERC20, ERC223 and MintableToken interfaces as well as capped and finalization logic
contract RasmartToken is StandardBurnableToken, RBACERC223TokenFinalization, RBACMintableTokenMixin {
  /// @notice Constant field with token full name
  // solium-disable-next-line uppercase
  string constant public name = "RASMART"; 
  /// @notice Constant field with token symbol
  string constant public symbol = "RAS"; // solium-disable-line uppercase
  /// @notice Constant field with token precision depth
  uint256 constant public decimals = 18; // solium-disable-line uppercase
  /// @notice Constant field with token cap (total supply limit)
  uint256 constant public cap = 500 * (10 ** 6) * (10 ** decimals); // solium-disable-line uppercase

  /// @notice Overrides original mint function from MintableToken to limit minting over cap
  /// @param _to The address that will receive the minted tokens.
  /// @param _amount The amount of tokens to mint.
  /// @return A boolean that indicates if the operation was successful.
  function mint(
    address _to,
    uint256 _amount
  )
    public
    returns (bool) 
  {
    require(totalSupply().add(_amount) <= cap);
    return super.mint(_to, _amount);
  }

  /// @notice Overrides finalize function from RBACERC223TokenFinalization to prevent future minting after finalization
  /// @return A boolean that indicates if the operation was successful.
  function finalize() public returns (bool) {
    require(super.finalize());
    require(finishMinting());
    return true;
  }

  /// @notice Overrides finishMinting function from RBACMintableTokenMixin to prevent finishing minting before finalization
  /// @return A boolean that indicates if the operation was successful.
  function finishMinting() internal returns (bool) {
    require(finalized == true);
    require(super.finishMinting());
    return true;
  }
}