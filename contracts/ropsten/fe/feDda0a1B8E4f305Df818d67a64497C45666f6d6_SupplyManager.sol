pragma solidity ^0.4.13;

contract SupplyManager {
    // let uint256 use SafeMath methods to avoid overflows and underflows
    using SafeMath for uint256;

    /// @dev the addresses to the tokens we want to regulate
    UtilityToken public utilityToken;
    SecurityToken public securityToken;

    /**
     * @notice How many utility tokens an account can mint per security
     * token held.
     * @dev Cannot be dynamic unless we&#39;re willing to break assertions.
     */
    uint256 public constant mint_capacity_multiplier = 1;

    /// @dev the current amount of utility tokens minted
    mapping (address=>uint256) mintBalance;

    /**
     * @notice Creates a SupplyManager along with the tokens it manages
     * @dev Because the three contracts are so deeply dependent, it made
     * sense to create/deploy all of them at once.
     */
    constructor() public {
        utilityToken = new UtilityToken(msg.sender, this);
        securityToken = new SecurityToken(msg.sender, this);
    }

    /**
     * @dev Update the `mintBalance` when `utilityToken` is successfully
     * minted.
     * @param _account the minter whose `mintBalance` needs updating
     * @param _amount the quantity of successfully minted tokens
     */
    function finalizeMintUtility(address _account, uint256 _amount) public {
        require(msg.sender == address(utilityToken));
        require(_account != address(0));

        uint256 current_balance_security = securityToken.balanceOf(_account);
        uint256 mint_capacity = current_balance_security.mul(mint_capacity_multiplier);

        uint256 newMintBalance = mintBalance[_account].add(_amount);

        assert(mint_capacity >= mintBalance[_account]);
        require(mint_capacity >= newMintBalance);
        mintBalance[_account] = newMintBalance;
    }

    /**
     * @dev Update the `mintBalance` when `utilityToken` is successfully
     * burned.
     * @param _account the burner whose `mintBalance` needs updating
     * @param _amount the quantity of successfully burned tokens
     */
    function finalizeBurnUtility(address _account, uint256 _amount) public {
        require(msg.sender == address(utilityToken));
        require(_account != address(0));
        require(_amount <= mintBalance[_account]);

        mintBalance[_account] = mintBalance[_account].sub(_amount);
    }

    /**
     * @dev This function validates that a given account has enough "mint
     * credit" (security tokens - minted utility tokens) to be able to 
     * mint utility tokens.
     * @param _account any ethereum address representing
     * an account that holds security tokens
     * @param _amount the amount of tokens _account wants to mint
     */
    function canMintUtility(address _account, uint256 _amount) public view returns (bool){                
        require(msg.sender == address(utilityToken));
        require(_account != address(0));

        uint256 current_balance_security = securityToken.balanceOf(_account);
        uint256 mint_capacity = current_balance_security.mul(mint_capacity_multiplier);

        assert(mint_capacity >= mintBalance[_account]);

        return _amount <= mint_capacity.sub(mintBalance[_account]);
    }

    /**
     * @dev This function validates that a given account has enough "mint
     * balance" (confirmed minted utility tokens) to be able to 
     * burn utility tokens.
     * @param _account any ethereum address representing
     * an account that holds security and utility tokens
     * @param _amount the amount of utility tokens `_account` wants to burn
     */
    function canBurnUtility(address _account, uint256 _amount) public view returns (bool){                
        require(msg.sender == address(utilityToken));
        require(_account != address(0));

        return _amount <= mintBalance[_account];
    }

    /**
     * @dev This function validates that by burning a certain amount
     * of security token, an address does not have more minted utility
     * tokens in circulation than its capacity.
     * @param _account any ethereum address representing
     * an account that holds security tokens
     * @param _amount the amount of security tokens `_account` wants to burn
     */
    function canBurnSecurity(address _account, uint256 _amount) public view returns (bool){                
        require(msg.sender == address(securityToken));
        require(_account != address(0));

        uint256 current_balance_security = securityToken.balanceOf(_account);
        uint256 mint_capacity = current_balance_security.mul(mint_capacity_multiplier);

        assert(mint_capacity >= mintBalance[_account]);

        uint256 unstaked_capacity = mint_capacity.sub(mintBalance[_account]);
        uint256 unstaked_tokens = unstaked_capacity.div(mint_capacity_multiplier);
        
        assert(current_balance_security >= unstaked_tokens);

        return unstaked_tokens >= _amount;
    }
}

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

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
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
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract VariableTaxToken is StandardToken, Ownable {
    // let uint256 use SafeMath methods to avoid overflows and underflows
    using SafeMath for uint256;

    /// Internal state for fee calculation
    uint256 public tax = 2; // initial value: 0.02%
    uint256 internal constant taxBase = 10000;

    /// Address that receives the fee collected
    address public taxMan = address(0);

    /** 
     * @dev The Tax event is somewhat redundant, as it may be inferred by
     * the Transfer events happening, and may be removed in the future
     */
    event Tax(address from, address to, uint256 amount, uint256 fee);

    /**
     * @notice Calculates the fee to be charged based on the 
     * contract&#39;s internal state. 
     * @dev The formula for the fee being charged is
     *
     * `fee = _value * tax / taxBase`
     *
     * @param _value the transferred amount to be taxed
     * @return the fee that should be charged
     */
    function calculateFee(uint256 _value) private view returns (uint256) {
        require(tax > 0, "No fee can be applied if no tax is defined.");
        assert(taxBase > 0);
        uint256 taxFee = _value.mul(tax).div(taxBase);
        return taxFee;
    }

    /**
     * @dev Changes the value being used to calculate the tax fee.
     * It is a sensitive method, so it is restricted to the owner
     * of the Token.
     * @param _value the new `tax` value
     */
    function updateTax(uint256 _value) public onlyOwner {
        require(tax != _value, "Tax value is unchanged");
        tax = _value;
    }

    /**
     * @dev Changes the address being used to receive the tax fee.
     * It is a sensitive method, so it is restricted to the owner
     * of the Token.
     * @param _to the new `taxMan` address
     */
    function taxTo(address _to) public onlyOwner {
        require(taxMan != _to, "Tax recipient is unchanged.");
        taxMan = _to;
    }

    /**
     * @dev Overrides the `transferFrom` implementation of the token,
     * so as to charge the fee on a successful transfer.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value > 0, "Useless waste of gas");
        super.transferFrom(_from, _to, _value);
        // tax is only applied when the necessary variables are defined
        if (taxMan != address(0) && tax > 0) {
            uint256 taxFee = calculateFee(_value);
            super.transferFrom(_to, taxMan, taxFee);
            emit Tax(_from, _to, _value, taxFee);
        }
        return true;
    }

    /**
     * @dev Overrides the `transfer` implementation of the token,
     * so as to charge the fee on a successful transfer.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value > 0, "Useless waste of gas");
        super.transfer(_to, _value);
        // tax is only applied when the necessary variables are defined
        if (taxMan != address(0) && tax > 0) {
            uint256 taxFee = calculateFee(_value);
            if (taxFee > 0) {
                super.transfer(taxMan, taxFee);
            }
            emit Tax(msg.sender, _to, _value, taxFee);
        }
        return true;
    }
}

contract UtilityToken is StandardToken, Ownable, BurnableToken, VariableTaxToken {
    using SafeMath for uint256;

    string public constant name = "GoldBackedToken";
    string public constant symbol = "GBT";
    uint8 public constant decimals = 0;

    event Mint(address indexed to, uint256 amount);

    SupplyManager supplyManager;

    constructor(address _owner, SupplyManager _supplyManager) public {
        owner = _owner;
        supplyManager = _supplyManager;
    }

    function mint(uint256 _amount) public {
        require(supplyManager.canMintUtility(msg.sender, _amount));

        totalSupply_ = totalSupply_.add(_amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);
        
        emit Mint(msg.sender, _amount);
        emit Transfer(address(0), msg.sender, _amount);

        supplyManager.finalizeMintUtility(msg.sender, _amount);
    }


    function burn(uint256 _value) public {
        require(supplyManager.canBurnUtility(msg.sender, _value));
        
        super.burn(_value);
        supplyManager.finalizeBurnUtility(msg.sender, _value);
    }

}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
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
    hasMintPermission
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
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract SecurityToken is StandardToken, MintableToken, BurnableToken {
    using SafeMath for uint256;

    string public constant name = "MMintToken";
    string public constant symbol = "MMT";
    uint8 public constant decimals = 0;

    SupplyManager supplyManager;

    constructor(address _owner, SupplyManager _supplyManager) public {
        owner = _owner;
        supplyManager = _supplyManager;
    }
    
    function burn(uint256 _value) public {
        require(supplyManager.canBurnSecurity(msg.sender, _value));
        
        super.burn(_value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(supplyManager.canBurnSecurity(_from, _value));

        super.transferFrom(_from, _to, _value);
    }


    function transfer(address _to, uint256 _value) public returns (bool) {
        require(supplyManager.canBurnSecurity(msg.sender, _value));

        super.transfer(_to, _value);
    }

}