pragma solidity^0.4.24;

/**
* 
*    
*       ▄▄▄▄███▄▄▄▄    ▄██████▄  ▀█████████▄   ▄█  ███    █▄     ▄████████      
*     ▄██▀▀▀███▀▀▀██▄ ███    ███   ███    ███ ███  ███    ███   ███    ███      
*     ███   ███   ███ ███    ███   ███    ███ ███▌ ███    ███   ███    █▀       
*     ███   ███   ███ ███    ███  ▄███▄▄▄██▀  ███▌ ███    ███   ███             
*     ███   ███   ███ ███    ███ ▀▀███▀▀▀██▄  ███▌ ███    ███ ▀███████████      
*     ███   ███   ███ ███    ███   ███    ██▄ ███  ███    ███          ███      
*     ███   ███   ███ ███    ███   ███    ███ ███  ███    ███    ▄█    ███      
*      ▀█   ███   █▀   ▀██████▀  ▄█████████▀  █▀   ████████▀   ▄████████▀       
*                                                                               
*    ▀█████████▄   ▄█       ███    █▄     ▄████████                             
*      ███    ███ ███       ███    ███   ███    ███                             
*      ███    ███ ███       ███    ███   ███    █▀                              
*     ▄███▄▄▄██▀  ███       ███    ███  ▄███▄▄▄                                 
*    ▀▀███▀▀▀██▄  ███       ███    ███ ▀▀███▀▀▀                                 
*      ███    ██▄ ███       ███    ███   ███    █▄                              
*      ███    ███ ███▌    ▄ ███    ███   ███    ███                             
*    ▄█████████▀  █████▄▄██ ████████▀    ██████████                             
*                 ▀                                                             
*     
*   ////////     https://mobius.blue       \\\\\\\
*  //////// BLU Token Holders receive divs  \\\\\\\
* 
*/

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

contract StandardToken  {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 totalSupply_;

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
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
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
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
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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
      public
      hasMintPermission
      canMint
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
    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract MobiusBlueToken is MintableToken {

    using SafeMath for uint;
    address creator = msg.sender;
    uint8 public decimals = 18;
    string public name = "M&#246;bius BLUE";
    string public symbol = "BLU";

    uint public totalDividends;
    uint public lastRevenueBnum;

    uint public unclaimedDividends;

    struct DividendAccount {
        uint balance;
        uint lastCumulativeDividends;
        uint lastWithdrawnBnum;
    }

    mapping (address => DividendAccount) public dividendAccounts;

    modifier onlyTokenHolders{
        require(balances[msg.sender] > 0, "Not a token owner!");
        _;
    }
    
    modifier updateAccount(address _of) {
        _updateDividends(_of);
        _;
    }

    event DividendsWithdrawn(address indexed from, uint value);
    event DividendsTransferred(address indexed from, address indexed to, uint value);
    event DividendsDisbursed(uint value);
        
    function mint(address _to, uint256 _amount) public 
    returns (bool)
    {   
        // devs get 33.3% of all tokens. Much of this will be used for bounties and community incentives
        super.mint(creator, _amount/2);
        // When an investor gets 2 tokens, devs get 1
        return super.mint(_to, _amount);
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        
        _transferDividends(msg.sender, _to, _value);
        require(super.transfer(_to, _value), "Failed to transfer tokens!");
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        
        _transferDividends(_from, _to, _value);
        require(super.transferFrom(_from, _to, _value), "Failed to transfer tokens!");
        return true;
    }

    // Devs can move tokens without dividends during the ICO for bounty purposes
    function donate(address _to, uint _value) public returns (bool success) {
        require(msg.sender == creator, "You can&#39;t do that!");
        require(!mintingFinished, "ICO Period is over - use a normal transfer.");
        return super.transfer(_to, _value);
    }

    function withdrawDividends() public onlyTokenHolders {
        uint amount = _getDividendsBalance(msg.sender);
        require(amount > 0, "Nothing to withdraw!");
        unclaimedDividends = unclaimedDividends.sub(amount);
        dividendAccounts[msg.sender].balance = 0;
        dividendAccounts[msg.sender].lastWithdrawnBnum = block.number;
        msg.sender.transfer(amount);
        emit DividendsWithdrawn(msg.sender, amount);
    }

    function dividendsAvailable(address _for) public view returns(bool) {
        return lastRevenueBnum >= dividendAccounts[_for].lastWithdrawnBnum;
    }

    function getDividendsBalance(address _of) external view returns(uint) {
        uint outstanding = _dividendsOutstanding(_of);
        if (outstanding > 0) {
            return dividendAccounts[_of].balance.add(outstanding);
        }
        return dividendAccounts[_of].balance;
    }

    function disburseDividends() public payable {
        if(msg.value == 0) {
            return;
        }
        totalDividends = totalDividends.add(msg.value);
        unclaimedDividends = unclaimedDividends.add(msg.value);
        lastRevenueBnum = block.number;
        emit DividendsDisbursed(msg.value);
    }

    function () public payable {
        disburseDividends();
    }

    function _transferDividends(address _from, address _to, uint _tokensValue) internal 
    updateAccount(_from)
    updateAccount(_to) 
    {
        uint amount = dividendAccounts[_from].balance.mul(_tokensValue).div(balances[_from]);
        if(amount > 0) {
            dividendAccounts[_from].balance = dividendAccounts[_from].balance.sub(amount);
            dividendAccounts[_to].balance = dividendAccounts[_to].balance.add(amount); 
            dividendAccounts[_to].lastWithdrawnBnum = dividendAccounts[_from].lastWithdrawnBnum;
            emit DividendsTransferred(_from, _to, amount);
        }
    }
    
    function _getDividendsBalance(address _holder) internal
    updateAccount(_holder)
    returns(uint) 
    {
        return dividendAccounts[_holder].balance;
    }    

    function _updateDividends(address _holder) internal {
        require(mintingFinished, "Can&#39;t calculate balances if still minting tokens!");
        uint outstanding = _dividendsOutstanding(_holder);
        if (outstanding > 0) {
            dividendAccounts[_holder].balance = dividendAccounts[_holder].balance.add(outstanding);
        }
        dividendAccounts[_holder].lastCumulativeDividends = totalDividends;
    }

    function _dividendsOutstanding(address _holder) internal view returns(uint) {
        uint newDividends = totalDividends.sub(dividendAccounts[_holder].lastCumulativeDividends);
        
        if(newDividends == 0) {
            return 0;
        } else {
            return newDividends.mul(balances[_holder]).div(totalSupply_);
        }
    }   
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}