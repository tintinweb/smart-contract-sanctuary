pragma solidity ^0.4.21;

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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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
  function allowance(address _owner, address _spender) public view returns (uint256) {
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
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
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
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
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

/* solium-disable security/no-block-members */









/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  function TokenVesting(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool _revocable
  )
    public
  {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    emit Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20 token which is being vested
   */
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    emit Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
   * @param token ERC20 token which is being vested
   */
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}

/**
 * @title PresaleTokenVesting
 * @dev PresaleTokenVesting allows for vesting periods which begin at
 * the time the token sale ends.
 */
contract PresaleTokenVesting is TokenVesting {

    function PresaleTokenVesting(address _beneficiary, uint256 _duration) TokenVesting(_beneficiary, 0, _duration, _duration, false) public {
    }

    function vestedAmount(ERC20Basic token) public view returns (uint256) {
        UrbitToken urbit = UrbitToken(token); 
        if (!urbit.saleClosed()) {
            return(0);
        } else {
            uint256 currentBalance = token.balanceOf(this);
            uint256 totalBalance = currentBalance.add(released[token]);
            uint256 saleClosedTime = urbit.saleClosedTimestamp();
            if (block.timestamp >= duration.add(saleClosedTime)) { // solium-disable-line security/no-block-members
                return totalBalance;
            } else {
                return totalBalance.mul(block.timestamp.sub(saleClosedTime)).div(duration); // solium-disable-line security/no-block-members

            }
        }
    }
}

/**
 * @title TokenVault
 * @dev TokenVault is a token holder contract that will allow a
 * beneficiary to spend the tokens from some function of a specified ERC20 token
 */
contract TokenVault {
    using SafeERC20 for ERC20;

    // ERC20 token contract being held
    ERC20 public token;

    function TokenVault(ERC20 _token) public {
        token = _token;
    }

    /**
     * @notice Allow the token itself to send tokens
     * using transferFrom().
     */
    function fillUpAllowance() public {
        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.approve(token, amount);
    }
}

/**
 * @title UrbitToken
 * @dev UrbitToken is a contract for the Urbit token sale, creating the
 * tokens and managing the vaults.
 */
contract UrbitToken is BurnableToken, StandardToken {
    string public constant name = "Urbit Token"; // solium-disable-line uppercase
    string public constant symbol = "URB"; // solium-disable-line uppercase
    uint8 public constant decimals = 18; // solium-disable-line uppercase
    uint256 public constant MAGNITUDE = 10**uint256(decimals);

    /// Maximum tokens to be allocated (600 million)
    uint256 public constant HARD_CAP = 600000000 * MAGNITUDE;

    /// This address is used to manage the admin functions and allocate vested tokens
    address public urbitAdminAddress;

    /// This address is used to keep the tokens for sale
    address public saleTokensAddress;

    /// This vault is used to keep the bounty and marketing tokens
    TokenVault public bountyTokensVault;

    /// This vault is used to keep the team and founders tokens
    TokenVault public urbitTeamTokensVault;

    /// This vault is used to keep the advisors tokens
    TokenVault public advisorsTokensVault;

    /// This vault is used to keep the rewards tokens
    TokenVault public rewardsTokensVault;

    /// This vault is used to keep the retained tokens
    TokenVault public retainedTokensVault;

    /// Store the vesting contracts addresses
    mapping(address => address[]) public vestingsOf;

    /// when the token sale is closed, the trading is open
    uint256 public saleClosedTimestamp = 0;

    /// Only allowed to execute before the token sale is closed
    modifier beforeSaleClosed {
        require(!saleClosed());
        _;
    }

    /// Limiting functions to the admins of the token only
    modifier onlyAdmin {
        require(senderIsAdmin());
        _;
    }

    function UrbitToken(
        address _urbitAdminAddress,
        address _saleTokensAddress) public
    {
        require(_urbitAdminAddress != address(0));
        require(_saleTokensAddress != address(0));

        urbitAdminAddress = _urbitAdminAddress;
        saleTokensAddress = _saleTokensAddress;
    }

    /// @dev allows the admin to assign a new admin
    function changeAdmin(address _newUrbitAdminAddress) external onlyAdmin {
        require(_newUrbitAdminAddress != address(0));
        urbitAdminAddress = _newUrbitAdminAddress;
    }

    /// @dev creates the tokens needed for sale
    function createSaleTokens() external onlyAdmin beforeSaleClosed {
        require(bountyTokensVault == address(0));

        /// Maximum tokens to be allocated on the sale
        /// 252,000,000 URB
        createTokens(252000000, saleTokensAddress);

        /// Bounty tokens - 24M URB
        bountyTokensVault = createTokenVault(24000000);
    }

    /// @dev Close the token sale
    function closeSale() external onlyAdmin beforeSaleClosed {
        createAwardTokens();
        saleClosedTimestamp = block.timestamp; // solium-disable-line security/no-block-members
    }

    /// @dev Once the token sale is closed and tokens are distributed,
    /// burn the remaining unsold, undistributed tokens
    function burnUnsoldTokens() external onlyAdmin {
        require(saleClosed());
        _burn(saleTokensAddress, balances[saleTokensAddress]);
        _burn(bountyTokensVault, balances[bountyTokensVault]);
    }

    function lockBountyTokens(uint256 _tokensAmount, address _beneficiary, uint256 _duration) external beforeSaleClosed {
        require(msg.sender == saleTokensAddress || senderIsAdmin());
        _presaleLock(bountyTokensVault, _tokensAmount, _beneficiary, _duration);
    }

    /// @dev Shorter version of vest tokens (lock for a single whole period)
    function lockTokens(address _fromVault, uint256 _tokensAmount, address _beneficiary, uint256 _unlockTime) external onlyAdmin {
        this.vestTokens(_fromVault, _tokensAmount, _beneficiary, _unlockTime, 0, 0, false); // solium-disable-line arg-overflow
    }

    /// @dev Vest tokens
    function vestTokens(
        address _fromVault,
        uint256 _tokensAmount,
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        bool _revocable)
        external onlyAdmin
    {
        TokenVesting vesting = new TokenVesting(_beneficiary, _start, _cliff, _duration, _revocable);
        vestingsOf[_beneficiary].push(address(vesting));

        require(this.transferFrom(_fromVault, vesting, _tokensAmount));
    }

    /// @dev releases vested tokens for the caller&#39;s own address
    function releaseVestedTokens() external {
        this.releaseVestedTokensFor(msg.sender);
    }

    /// @dev releases vested tokens for the specified address.
    /// Can be called by any account for any address.
    function releaseVestedTokensFor(address _owner) external {
        ERC20Basic token = ERC20Basic(address(this));
        for (uint i = 0; i < vestingsOf[_owner].length; i++) {
            TokenVesting tv = TokenVesting(vestingsOf[_owner][i]);
            if (tv.releasableAmount(token) > 0) {
                tv.release(token);
            }
        }
    }

    /// @dev returns whether the sender is admin (or the contract itself)
    function senderIsAdmin() public view returns (bool) {
        return (msg.sender == urbitAdminAddress || msg.sender == address(this));
    }

    /// @dev The sale is closed when the saleClosedTimestamp is set.
    function saleClosed() public view returns (bool) {
        return (saleClosedTimestamp > 0);
    }

    /// @dev check the locked balance for an address
    function lockedBalanceOf(address _owner) public view returns (uint256) {
        uint256 result = 0;
        for (uint i = 0; i < vestingsOf[_owner].length; i++) {
            result += balances[vestingsOf[_owner][i]];
        }
        return result;
    }

    /// @dev check the locked but releasable balance for an address
    function releasableBalanceOf(address _owner) public view returns (uint256) {
        uint256 result = 0;
        for (uint i = 0; i < vestingsOf[_owner].length; i++) {
            result += TokenVesting(vestingsOf[_owner][i]).releasableAmount(this);
        }
        return result;
    }

    /// @dev get the number of TokenVesting contracts for an address
    function vestingCountOf(address _owner) public view returns (uint) {
        return vestingsOf[_owner].length;
    }

    /// @dev get the specified TokenVesting contract address for an address
    function vestingOf(address _owner, uint _index) public view returns (address) {
        return vestingsOf[_owner][_index];
    }

    /// @dev Trading is limited before the sale is closed
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (saleClosed() || msg.sender == saleTokensAddress || senderIsAdmin()) {
            return super.transferFrom(_from, _to, _value);
        }
        return false;
    }

    /// @dev Trading is limited before the sale is closed
    function transfer(address _to, uint256 _value) public returns (bool) {
        if (saleClosed() || msg.sender == saleTokensAddress || senderIsAdmin()) {
            return super.transfer(_to, _value);
        }
        return false;
    }

    /// @dev Grant tokens which begin vesting upon close of sale.
    function _presaleLock(TokenVault _fromVault, uint256 _tokensAmount, address _beneficiary, uint256 _duration) internal {
        PresaleTokenVesting vesting = new PresaleTokenVesting(_beneficiary, _duration);
        vestingsOf[_beneficiary].push(address(vesting));

        require(this.transferFrom(_fromVault, vesting, _tokensAmount));
    }

    // @dev create specified number of toekns and transfer to destination
    function createTokens(uint32 count, address destination) internal onlyAdmin {
        uint256 tokens = count * MAGNITUDE;
        totalSupply_ = totalSupply_.add(tokens);
        balances[destination] = tokens;
        emit Transfer(0x0, destination, tokens);
    }

    /// @dev Create a TokenVault and fill with the specified newly minted tokens
    function createTokenVault(uint32 count) internal onlyAdmin returns (TokenVault) {
        TokenVault tokenVault = new TokenVault(ERC20(this));
        createTokens(count, tokenVault);
        tokenVault.fillUpAllowance();
        return tokenVault;
    }

    /// @dev Creates the tokens awarded after the sale is closed
    function createAwardTokens() internal onlyAdmin {
        /// Team tokens - 30M URB
        urbitTeamTokensVault = createTokenVault(30000000);

        /// Advisors tokens - 24M URB
        advisorsTokensVault = createTokenVault(24000000);

        /// Rewards tokens - 150M URB
        rewardsTokensVault = createTokenVault(150000000);

        /// Retained tokens - 120M URB
        retainedTokensVault = createTokenVault(120000000);
    }
}