pragma solidity 0.4.25;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

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
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
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
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
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
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

  // ERC20 basic token contract being held
  ERC20Basic public token;

  // beneficiary of tokens after they are released
  address public beneficiary;

  // timestamp when token release is enabled
  uint256 public releaseTime;

  constructor(
    ERC20Basic _token,
    address _beneficiary,
    uint256 _releaseTime
  )
    public
  {
    // solium-disable-next-line security/no-block-members
    require(_releaseTime > block.timestamp);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

  /**
   * @notice Transfers tokens held by timelock to beneficiary.
   */
  function release() public {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= releaseTime);

    uint256 amount = token.balanceOf(address(this));
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
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

/**
 * @title DiscoperiTokenVesting
 * @dev DiscoperiTokenVesting mixin that gives possibility for token holders to have vested amounts of tokens on their balances. 
 * Token should check a balance spot for transfer and transferFrom functions to use this feature.
 */
contract DiscoperiTokenVesting {
    using SafeMath for uint256;  

    // vesting parts count
    uint256 public constant VESTING_PARTS = 4;

    // vesting releases timestamps
    uint256[VESTING_PARTS] public vestingReleases;

    // list of vested amounts by beneficiary
    mapping (address => uint256) public vestedAmount;
    
    // vesting event logging
    event Vesting(address indexed to, uint256 amount);    

    /**
     * @dev Find out if the address has vested amounts
     * @param _who address Address checked for vested amounts
     * @return bool Returns true if address has vested amounts     
     */  
    function hasVested(address _who) public view returns (bool) {
        return balanceVested(_who) > 0;
    }

    /**
     * @dev Get balance vested to the current moment of time
     * @param _who address Address owns vested amounts
     * @return uint256 Balance vested to the current moment of time     
     */       
    function balanceVested(address _who) public view returns (uint256) {
        for (uint256 i = 0; i < VESTING_PARTS; i++) {
            if (now < vestingReleases[i]) // solium-disable-line security/no-block-members
               return vestedAmount[_who].mul(VESTING_PARTS - i).div(VESTING_PARTS);
        }
    } 
 
    /**
     * @dev Make vesting for the amount using contract with vesting rules
     * @param _who address Address gets the vested amount
     * @param _amount uint256 Amount to vest
     */ 
    function _vest(address _who, uint256 _amount) internal {
        require(_who != address(0), "Vesting target address can&#39;t be zero.");
        require(_amount > 0, "Vesting amount should be > 0.");
        vestedAmount[_who] = vestedAmount[_who].add(_amount);
        emit Vesting(_who, _amount);
    }        
}

/**
 * @title DiscoperiTokenLockup
 * @dev This contract gives possibility for token holders to have locked up (till release time) amounts of tokens on their balances. 
 */
contract DiscoperiTokenLockup {
    using SafeMath for uint256;  

    // LockedUp struct
    struct LockedUp {
        uint256 amount; // lockedup amount
        uint256 release; // release timestamp
    }

    // list of lockedup amounts and release timestamps
    mapping (address => LockedUp[]) public lockedup;

    // lockup event logging
    event Lockup(address indexed to, uint256 amount, uint256 release);

    /**
     * @dev Find out if the address has locked up amounts
     * @param _who address Address checked for lockedup amounts
     * @return bool Returns true if address has lockedup amounts     
     */    
    function hasLockedUp(address _who) public view returns (bool) {
        return balanceLockedUp(_who) > 0;
    }    

    /**
     * @dev Get balance locked up to the current moment of time
     * @param _who address Address owns lockedup amounts
     * @return uint256 Balance locked up to the current moment of time     
     */       
    function balanceLockedUp(address _who) public view returns (uint256) {
        uint256 _balanceLockedUp = 0;
        for (uint256 i = 0; i < lockedup[_who].length; i++) {
            if (lockedup[_who][i].release > block.timestamp) // solium-disable-line security/no-block-members
                _balanceLockedUp = _balanceLockedUp.add(lockedup[_who][i].amount);
        }
        return _balanceLockedUp;
    }    
    
    /**
     * @dev Lockup amount till release time
     * @param _who address Address gets the lockedup amount
     * @param _amount uint256 Amount to lockup
     * @param _release uint256 Release timestamp     
     */     
    function _lockup(address _who, uint256 _amount, uint256 _release) internal {
        if (_release != 0) {
            require(_who != address(0), "Lockup target address can&#39;t be zero.");
            require(_amount > 0, "Lockup amount should be > 0.");   
            require(_release > block.timestamp, "Lockup release time should be > now."); // solium-disable-line security/no-block-members 
            lockedup[_who].push(LockedUp(_amount, _release));
            emit Lockup(_who, _amount, _release);
        }
    }      

}

/**
 * @title IDiscoperiSale
 * @dev IDiscoperiSale is a ..
 */
contract IDiscoperiSale {
    
    /**
     * @dev Order tokens for beneficiary
     * @param _collector  collector id
     * @param _tx hash of the transaction
     * @param _beneficiary beneficiary who has paid coins for tokens
     * @param _funds amount of coins beneficiary has paid 
     */
    function acquireTokens(uint256 _collector, uint256 _tx, address _beneficiary, uint256 _funds) external payable;

}

/**
 * @title IDiscoperiToken
 * @dev IDiscoperiToken is a ..
 */
contract IDiscoperiToken {

    /**
     * @dev Burn tokens from sale contract
     */
    function burnSaleTokens() external;

     /**
     * @dev Transfer tokens from one address to another with westing
     * @param _to address which you want to transfer to
     * @param _value the amount of tokens to be transferred
     * @return true if the transfer was succeeded
     */
    function transferWithVesting(address _to, uint256 _value) external returns (bool); 

}

/**
 * @title DiscoperiToken
 * @dev Discoperi Token contract
 */
contract DiscoperiToken is  
    IDiscoperiToken,
    StandardToken, 
    Ownable,
    DiscoperiTokenLockup,
    DiscoperiTokenVesting
{
    using SafeMath for uint256;

    // token constants
    string public constant name = "Discoperi Token"; // solium-disable-line uppercase
    string public constant symbol = "DISC"; // solium-disable-line uppercase
    uint8 public constant decimals = 18; // solium-disable-line uppercase

    // total tokens supply
    uint256 public constant TOTAL_SUPPLY = 200000000000 * (10 ** uint256(decimals)); // 200,000,000,000 DISCs

    // TOTAL_SUPPLY is distributed as follows
    uint256 public constant SALES_SUPPLY = 50000000000 * (10 ** uint256(decimals)); // 50,000,000,000 DISCs - 25%
    uint256 public constant INVESTORS_SUPPLY = 50000000000 * (10 ** uint256(decimals)); // 50,000,000,000 DISCs - 25%
    uint256 public constant TEAM_SUPPLY = 30000000000 * (10 ** uint256(decimals)); // 30,000,000,000 DISCs - 15%
    uint256 public constant RESERVE_SUPPLY = 22000000000 * (10 ** uint256(decimals)); // 22,000,000,000 DISCs - 11%
    uint256 public constant MARKET_DEV_SUPPLY = 20000000000 * (10 ** uint256(decimals)); // 20,000,000,000 DISCs - 10%    
    uint256 public constant PR_ADVERSTISING_SUPPLY = 15000000000 * (10 ** uint256(decimals)); // 15,000,000,000 DISCs - 7.5%
    uint256 public constant REFERRAL_SUPPLY = 8000000000 * (10 ** uint256(decimals)); // 8,000,000,000 DISCs - 4%
    uint256 public constant ANGEL_INVESTORS_SUPPLY = 5000000000 * (10 ** uint256(decimals)); // 5,000,000,000 DISCs - 2.5%
    
    // fund wallets
    address public constant MARKET_DEV_ADDRESS = 0x3f272f26C2322cB38781D0C6C42B1c2531Ec79Be;
    address public constant TEAM_ADDRESS = 0xD8069C8c24D10023DBC5823156994aC2A638dBBd;
    address public constant RESERVE_ADDRESS = 0x7656Cee371A812775A5E0Fb98a565Cc731aCC44B;
    address public constant INVESTORS_ADDRESS= 0x25230591492198b6DD4363d03a7dAa5aD7590D2d;
    address public constant PR_ADVERSTISING_ADDRESS = 0xC36d70AE6ddBE87F973bf4248Df52d0370FBb7E7;

    // sale address
    address public sale;

    // restrict execution only for sale address
    modifier onlySale() {
        require(msg.sender == sale, "Attemp to execute by not sale address");
        _;
    }

    // restrict execution only for authorized address
    modifier onlyLockupAuthorized() {
        require(msg.sender == INVESTORS_ADDRESS, "Attemp to lockup tokens by not authorized address");
        _;
    }

    // check balance spot on transfer
    modifier spotTransfer(address _from, uint256 _value) {
        require(_value <= balanceSpot(_from), "Attempt to transfer more than balance spot");
        _;
    }

    // burn event
    event Burn(address indexed burner, uint256 value);

    /**
     * CONSTRUCTOR
     * @dev Allocate investors tokens supply
     */
    constructor() public { 
        balances[INVESTORS_ADDRESS] = balances[INVESTORS_ADDRESS].add(INVESTORS_SUPPLY);
        totalSupply_ = totalSupply_.add(INVESTORS_SUPPLY);
        emit Transfer(address(0), INVESTORS_ADDRESS, INVESTORS_SUPPLY);

        balances[INVESTORS_ADDRESS] = balances[INVESTORS_ADDRESS].add(ANGEL_INVESTORS_SUPPLY);
        totalSupply_ = totalSupply_.add(ANGEL_INVESTORS_SUPPLY);
        emit Transfer(address(0), INVESTORS_ADDRESS, ANGEL_INVESTORS_SUPPLY);
    }

    /**
     * @dev Initialize token contract and allocate tokens supply
     * @param _sale address of the sale contract
     * @param _teamRelease team tokens release timestamp
     * @param _vestingFirstRelease first release timestamp of tokens vesting
     * @param _vestingSecondRelease second release timestamp of tokens vesting
     * @param _vestingThirdRelease third release timestamp of tokens vesting
     * @param _vestingFourthRelease fourth release timestamp of tokens vesting
     */
    function init(
        address _sale, 
        uint256 _teamRelease, 
        uint256 _vestingFirstRelease,
        uint256 _vestingSecondRelease,
        uint256 _vestingThirdRelease,
        uint256 _vestingFourthRelease
    ) 
        external 
        onlyOwner 
    {
        require(sale == address(0), "cannot execute init function twice");
        require(_sale != address(0), "cannot set zero address as sale");
        require(_teamRelease > now, "team tokens release date should be > now"); // solium-disable-line security/no-block-members
        require(_vestingFirstRelease > now, "vesting first release date should be > now"); // solium-disable-line security/no-block-members
        require(_vestingSecondRelease > now, "vesting second release date should be > now"); // solium-disable-line security/no-block-members
        require(_vestingThirdRelease > now, "vesting third release date should be > now"); // solium-disable-line security/no-block-members
        require(_vestingFourthRelease > now, "vesting fourth release date should be > now"); // solium-disable-line security/no-block-members

        sale = _sale;

        balances[sale] = balances[sale].add(SALES_SUPPLY);
        totalSupply_ = totalSupply_.add(SALES_SUPPLY);
        emit Transfer(address(0), sale, SALES_SUPPLY);

        balances[sale] = balances[sale].add(REFERRAL_SUPPLY);
        totalSupply_ = totalSupply_.add(REFERRAL_SUPPLY);
        emit Transfer(address(0), sale, REFERRAL_SUPPLY);

        TokenTimelock teamTimelock = new TokenTimelock(this, TEAM_ADDRESS, _teamRelease);
        balances[teamTimelock] = balances[teamTimelock].add(TEAM_SUPPLY);
        totalSupply_ = totalSupply_.add(TEAM_SUPPLY);
        emit Transfer(address(0), teamTimelock, TEAM_SUPPLY);
         
        balances[MARKET_DEV_ADDRESS] = balances[MARKET_DEV_ADDRESS].add(MARKET_DEV_SUPPLY);
        totalSupply_ = totalSupply_.add(MARKET_DEV_SUPPLY);
        emit Transfer(address(0), MARKET_DEV_ADDRESS, MARKET_DEV_SUPPLY);

        balances[RESERVE_ADDRESS] = balances[RESERVE_ADDRESS].add(RESERVE_SUPPLY);
        totalSupply_ = totalSupply_.add(RESERVE_SUPPLY);
        emit Transfer(address(0), RESERVE_ADDRESS, RESERVE_SUPPLY);
       
        balances[PR_ADVERSTISING_ADDRESS] = balances[PR_ADVERSTISING_ADDRESS].add(PR_ADVERSTISING_SUPPLY);
        totalSupply_ = totalSupply_.add(PR_ADVERSTISING_SUPPLY);
        emit Transfer(address(0), PR_ADVERSTISING_ADDRESS, PR_ADVERSTISING_SUPPLY);

        vestingReleases[0] = _vestingFirstRelease;
        vestingReleases[1] = _vestingSecondRelease;
        vestingReleases[2] = _vestingThirdRelease;
        vestingReleases[3] = _vestingFourthRelease;
    }

    /**
     * @dev Transfer tokens from one address to another with vesting
     * @param _to address which you want to transfer to
     * @param _value the amount of tokens to be transferred
     * @return true if the transfer was succeeded
     */
    function transferWithVesting(address _to, uint256 _value) external onlySale returns (bool) {    
        _vest(_to, _value);
        return super.transfer(_to, _value);
    }

    /**
     * @dev Transfer  tokens from one address to another with locking up
     * @param _to address which you want to transfer to
     * @param _value the amount of tokens to be transferred
     * @param _release the amount of tokens to be transferred
     * @return true if the transfer was succeeded
     */
    function transferWithLockup(address _to, uint256 _value, uint256 _release) external onlyLockupAuthorized returns (bool) {    
        _lockup(_to, _value, _release);
        return super.transfer(_to, _value);
    }

    /**
     * @dev Burn all tokens, remaining on sale contract
     */
    function burnSaleTokens() external onlySale {
        uint256 _amount = balances[sale];
        balances[sale] = 0;
        totalSupply_ = totalSupply_.sub(_amount);
        emit Burn(sale, _amount);
        emit Transfer(sale, address(0), _amount);        
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _to address which you want to transfer to
     * @param _value the amount of tokens to be transferred
     * @return true if the transfer was succeeded
     */
    function transfer(address _to, uint256 _value) public spotTransfer(msg.sender, _value) returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from the address which you want to send tokens from
     * @param _to the address which you want to transfer to
     * @param _value the amount of tokens to be transferred
     * @return true if the transfer was succeeded
     */
    function transferFrom(address _from, address _to, uint256 _value) public spotTransfer(_from, _value) returns (bool) {    
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Get balance spot for the current moment of time
     * @param _who address owns balance spot
     * @return balance spot for the current moment of time     
     */   
    function balanceSpot(address _who) public view returns (uint256) {
        return balanceOf(_who).sub(balanceVested(_who)).sub(balanceLockedUp(_who));
    }     

}