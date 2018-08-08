//File: node_modules\openzeppelin-solidity\contracts\ownership\Ownable.sol
pragma solidity ^0.4.23;


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

//File: node_modules\openzeppelin-solidity\contracts\lifecycle\Pausable.sol
pragma solidity ^0.4.23;





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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

//File: node_modules\openzeppelin-solidity\contracts\token\ERC20\ERC20Basic.sol
pragma solidity ^0.4.23;


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

//File: node_modules\openzeppelin-solidity\contracts\token\ERC20\ERC20.sol
pragma solidity ^0.4.23;




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

//File: node_modules\openzeppelin-solidity\contracts\token\ERC20\SafeERC20.sol
pragma solidity ^0.4.23;





/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

//File: node_modules\openzeppelin-solidity\contracts\ownership\CanReclaimToken.sol
pragma solidity ^0.4.23;






/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

//File: node_modules\openzeppelin-solidity\contracts\math\SafeMath.sol
pragma solidity ^0.4.23;


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

//File: contracts\ico\KYCBase.sol
pragma solidity ^0.4.24;



// Abstract base contract
contract KYCBase {
    using SafeMath for uint256;

    mapping (address => bool) public isKycSigner;
    mapping (uint64 => uint256) public alreadyPayed;

    event KycVerified(address indexed signer, address buyerAddress, uint64 buyerId, uint maxAmount);

    constructor(address[] kycSigners) internal {
        for (uint i = 0; i < kycSigners.length; i++) {
            isKycSigner[kycSigners[i]] = true;
        }
    }

    // Must be implemented in descending contract to assign tokens to the buyers. Called after the KYC verification is passed
    function releaseTokensTo(address buyer) internal returns(bool);

    // This method can be overridden to enable some sender to buy token for a different address
    function senderAllowedFor(address buyer)
    internal view returns(bool)
    {
        return buyer == msg.sender;
    }

    function buyTokensFor(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
    public payable returns (bool)
    {
        require(senderAllowedFor(buyerAddress));
        return buyImplementation(buyerAddress, buyerId, maxAmount, v, r, s);
    }

    function buyTokens(uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
    public payable returns (bool)
    {
        return buyImplementation(msg.sender, buyerId, maxAmount, v, r, s);
    }

    function buyImplementation(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
    private returns (bool)
    {
        // check the signature
        bytes32 hash = sha256(abi.encodePacked("Eidoo icoengine authorization", this, buyerAddress, buyerId, maxAmount));
        address signer = ecrecover(hash, v, r, s);
        if (!isKycSigner[signer]) {
            revert();
        } else {
            uint256 totalPayed = alreadyPayed[buyerId].add(msg.value);
            require(totalPayed <= maxAmount);
            alreadyPayed[buyerId] = totalPayed;
            emit KycVerified(signer, buyerAddress, buyerId, maxAmount);
            return releaseTokensTo(buyerAddress);
        }
    }

    // No payable fallback function, the tokens must be buyed using the functions buyTokens and buyTokensFor
    function () public {
        revert();
    }
}
//File: contracts\ico\ICOEngineInterface.sol
pragma solidity ^0.4.24;


contract ICOEngineInterface {

    // false if the ico is not started, true if the ico is started and running, true if the ico is completed
    function started() public view returns(bool);

    // false if the ico is not started, false if the ico is started and running, true if the ico is completed
    function ended() public view returns(bool);

    // time stamp of the starting time of the ico, must return 0 if it depends on the block number
    function startTime() public view returns(uint);

    // time stamp of the ending time of the ico, must retrun 0 if it depends on the block number
    function endTime() public view returns(uint);

    // Optional function, can be implemented in place of startTime
    // Returns the starting block number of the ico, must return 0 if it depends on the time stamp
    // function startBlock() public view returns(uint);

    // Optional function, can be implemented in place of endTime
    // Returns theending block number of the ico, must retrun 0 if it depends on the time stamp
    // function endBlock() public view returns(uint);

    // returns the total number of the tokens available for the sale, must not change when the ico is started
    function totalTokens() public view returns(uint);

    // returns the number of the tokens available for the ico. At the moment that the ico starts it must be equal to totalTokens(),
    // then it will decrease. It is used to calculate the percentage of sold tokens as remainingTokens() / totalTokens()
    function remainingTokens() public view returns(uint);

    // return the price as number of tokens released for each ether
    function price() public view returns(uint);
}
//File: node_modules\openzeppelin-solidity\contracts\token\ERC20\BasicToken.sol
pragma solidity ^0.4.23;






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

//File: node_modules\openzeppelin-solidity\contracts\token\ERC20\StandardToken.sol
pragma solidity ^0.4.23;





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

//File: node_modules\openzeppelin-solidity\contracts\token\ERC20\MintableToken.sol
pragma solidity ^0.4.23;





/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
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

//File: node_modules\openzeppelin-solidity\contracts\token\ERC20\PausableToken.sol
pragma solidity ^0.4.23;





/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

//File: node_modules\openzeppelin-solidity\contracts\token\ERC20\BurnableToken.sol
pragma solidity ^0.4.23;




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

//File: contracts\ico\GotToken.sol
/**
 * @title ParkinGO token
 *
 * @version 1.0
 * @author ParkinGO
 */
pragma solidity ^0.4.24;







contract GotToken is CanReclaimToken, MintableToken, PausableToken, BurnableToken {
    string public constant name = "GOToken";
    string public constant symbol = "GOT";
    uint8 public constant decimals = 18;

    /**
     * @dev Constructor of GotToken that instantiates a new Mintable Pausable Token
     */
    constructor() public {
        // token should not be transferable until after all tokens have been issued
        paused = true;
    }
}


//File: contracts\ico\PGOVault.sol
/**
 * @title PGOVault
 * @dev A token holder contract that allows the release of tokens to the ParkinGo Wallet.
 *
 * @version 1.0
 * @author ParkinGo
 */

pragma solidity ^0.4.24;







contract PGOVault {
    using SafeMath for uint256;
    using SafeERC20 for GotToken;

    uint256[4] public vesting_offsets = [
        360 days,
        540 days,
        720 days,
        900 days
    ];

    uint256[4] public vesting_amounts = [
        0.875e7 * 1e18,
        0.875e7 * 1e18,
        0.875e7 * 1e18,
        0.875e7 * 1e18
    ];

    address public pgoWallet;
    GotToken public token;
    uint256 public start;
    uint256 public released;
    uint256 public vestingOffsetsLength = vesting_offsets.length;

    /**
     * @dev Constructor.
     * @param _pgoWallet The address that will receive the vested tokens.
     * @param _token The GOT Token, which is being vested.
     * @param _start The start time from which each release time will be calculated.
     */
    constructor(
        address _pgoWallet,
        address _token,
        uint256 _start
    )
        public
    {
        pgoWallet = _pgoWallet;
        token = GotToken(_token);
        start = _start;
    }

    /**
     * @dev Transfers vested tokens to ParkinGo Wallet.
     */
    function release() public {
        uint256 unreleased = releasableAmount();
        require(unreleased > 0);

        released = released.add(unreleased);

        token.safeTransfer(pgoWallet, unreleased);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
     */
    function releasableAmount() public view returns (uint256) {
        return vestedAmount().sub(released);
    }

    /**
     * @dev Calculates the amount that has already vested.
     */
    function vestedAmount() public view returns (uint256) {
        uint256 vested = 0;
        for (uint256 i = 0; i < vestingOffsetsLength; i = i.add(1)) {
            if (block.timestamp > start.add(vesting_offsets[i])) {
                vested = vested.add(vesting_amounts[i]);
            }
        }
        return vested;
    }
    
    /**
     * @dev Calculates the amount that has not yet released.
     */
    function unreleasedAmount() public view returns (uint256) {
        uint256 unreleased = 0;
        for (uint256 i = 0; i < vestingOffsetsLength; i = i.add(1)) {
            unreleased = unreleased.add(vesting_amounts[i]);
        }
        return unreleased.sub(released);
    }
}


//File: contracts\ico\PGOMonthlyInternalVault.sol
/**
 * @title PGOMonthlyVault
 * @dev A token holder contract that allows the release of tokens after a vesting period.
 *
 * @version 1.0
 * @author ParkinGO
 */

pragma solidity ^0.4.24;







contract PGOMonthlyInternalVault {
    using SafeMath for uint256;
    using SafeERC20 for GotToken;

    struct Investment {
        address beneficiary;
        uint256 totalBalance;
        uint256 released;
    }

    /*** CONSTANTS ***/
    uint256 public constant VESTING_DIV_RATE = 21;                  // division rate of monthly vesting
    uint256 public constant VESTING_INTERVAL = 30 days;             // vesting interval
    uint256 public constant VESTING_CLIFF = 90 days;                // duration until cliff is reached
    uint256 public constant VESTING_DURATION = 720 days;            // vesting duration

    GotToken public token;
    uint256 public start;
    uint256 public end;
    uint256 public cliff;

    //Investment[] public investments;

    // key: investor address; value: index in investments array.
    //mapping(address => uint256) public investorLUT;

    mapping(address => Investment) public investments;

    /**
     * @dev Function to be fired by the initPGOMonthlyInternalVault function from the GotCrowdSale contract to set the
     * InternalVault&#39;s state after deployment.
     * @param beneficiaries Array of the internal investors addresses to whom vested tokens are transferred.
     * @param balances Array of token amount per beneficiary.
     * @param startTime Start time at which the first released will be executed, and from which the cliff for second
     * release is calculated.
     * @param _token The address of the GOT Token.
     */
    function init(address[] beneficiaries, uint256[] balances, uint256 startTime, address _token) public {
        // makes sure this function is only called once
        require(token == address(0));
        require(beneficiaries.length == balances.length);

        start = startTime;
        cliff = start.add(VESTING_CLIFF);
        end = start.add(VESTING_DURATION);

        token = GotToken(_token);

        for (uint256 i = 0; i < beneficiaries.length; i = i.add(1)) {
            investments[beneficiaries[i]] = Investment(beneficiaries[i], balances[i], 0);
        }
    }

    /**
     * @dev Allows a sender to transfer vested tokens to the beneficiary&#39;s address.
     * @param beneficiary The address that will receive the vested tokens.
     */
    function release(address beneficiary) public {
        uint256 unreleased = releasableAmount(beneficiary);
        require(unreleased > 0);

        investments[beneficiary].released = investments[beneficiary].released.add(unreleased);
        token.safeTransfer(beneficiary, unreleased);
    }

    /**
     * @dev Transfers vested tokens to the sender&#39;s address.
     */
    function release() public {
        release(msg.sender);
    }

    /**
     * @dev Allows to check an investment.
     * @param beneficiary The address of the beneficiary of the investment to check.
     */
    function getInvestment(address beneficiary) public view returns(address, uint256, uint256) {
        return (
            investments[beneficiary].beneficiary,
            investments[beneficiary].totalBalance,
            investments[beneficiary].released
        );
    }

    /**
     * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
     * @param beneficiary The address that will receive the vested tokens.
     */
    function releasableAmount(address beneficiary) public view returns (uint256) {
        return vestedAmount(beneficiary).sub(investments[beneficiary].released);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param beneficiary The address that will receive the vested tokens.
     */
    function vestedAmount(address beneficiary) public view returns (uint256) {
        uint256 vested = 0;
        if (block.timestamp >= cliff && block.timestamp < end) {
            // after cliff -> 1/21 of totalBalance every month, must skip first 3 months
            uint256 totalBalance = investments[beneficiary].totalBalance;
            uint256 monthlyBalance = totalBalance.div(VESTING_DIV_RATE);
            uint256 time = block.timestamp.sub(cliff);
            uint256 elapsedOffsets = time.div(VESTING_INTERVAL);
            uint256 vestedToSum = elapsedOffsets.mul(monthlyBalance);
            vested = vested.add(vestedToSum);
        }
        if (block.timestamp >= end) {
            // after end -> all vested
            vested = investments[beneficiary].totalBalance;
        }
        return vested;
    }
}


//File: contracts\ico\PGOMonthlyPresaleVault.sol
/**
 * @title PGOMonthlyVault
 * @dev A token holder contract that allows the release of tokens after a vesting period.
 *
 * @version 1.0
 * @author ParkinGO
 */

pragma solidity ^0.4.24;








contract PGOMonthlyPresaleVault is PGOMonthlyInternalVault {
    /**
     * @dev OVERRIDE vestedAmount from PGOMonthlyInternalVault
     * Calculates the amount that has already vested, release 1/3 of token immediately.
     * @param beneficiary The address that will receive the vested tokens.
     */
    function vestedAmount(address beneficiary) public view returns (uint256) {
        uint256 vested = 0;

        if (block.timestamp >= start) {
            // after start -> 1/3 released (fixed)
            vested = investments[beneficiary].totalBalance.div(3);
        }
        if (block.timestamp >= cliff && block.timestamp < end) {
            // after cliff -> 1/27 of totalBalance every month, must skip first 9 month 
            uint256 unlockedStartBalance = investments[beneficiary].totalBalance.div(3);
            uint256 totalBalance = investments[beneficiary].totalBalance;
            uint256 lockedBalance = totalBalance.sub(unlockedStartBalance);
            uint256 monthlyBalance = lockedBalance.div(VESTING_DIV_RATE);
            uint256 daysToSkip = 90 days;
            uint256 time = block.timestamp.sub(start).sub(daysToSkip);
            uint256 elapsedOffsets = time.div(VESTING_INTERVAL);
            vested = vested.add(elapsedOffsets.mul(monthlyBalance));
        }
        if (block.timestamp >= end) {
            // after end -> all vested
            vested = investments[beneficiary].totalBalance;
        }
        return vested;
    }
}


//File: contracts\ico\GotCrowdSale.sol
/**
 * @title GotCrowdSale
 *
 * @version 1.0
 * @author ParkinGo
 */
pragma solidity ^0.4.24;












contract GotCrowdSale is Pausable, CanReclaimToken, ICOEngineInterface, KYCBase {
    /*** CONSTANTS ***/
    uint256 public constant START_TIME = 1529416800;
    //uint256 public constant START_TIME = 1529416800;                     // 19 June 2018 14:00:00 GMT
    uint256 public constant END_TIME = 1530655140;                       // 03 July 2018 21:59:00 GMT
    //uint256 public constant USD_PER_TOKEN = 75;                          // 0.75$
    //uint256 public constant USD_PER_ETHER = 60000;                       // REMEMBER TO CHANGE IT AT ICO START
    uint256 public constant TOKEN_PER_ETHER = 740;                       // REMEMBER TO CHANGE IT AT ICO START

    //Token allocation
    //Team, founder, partners and advisor cap locked using Monthly Internal Vault
    uint256 public constant MONTHLY_INTERNAL_VAULT_CAP = 2.85e7 * 1e18;
    //Company unlocked liquidity and Airdrop allocation
    uint256 public constant PGO_UNLOCKED_LIQUIDITY_CAP = 1.5e7 * 1e18;
    //Internal reserve fund
    uint256 public constant PGO_INTERNAL_RESERVE_CAP = 3.5e7 * 1e18;
    //Reserved Presale Allocation 33% free and 67% locked using Monthly Presale Vault
    uint256 public constant RESERVED_PRESALE_CAP = 1.5754888e7 * 1e18;
    //ICO TOKEN ALLOCATION
    //Public ICO Cap
    //uint256 public constant CROWDSALE_CAP = 0.15e7 * 1e18;
    //Reservation contract Cap
    uint256 public constant RESERVATION_CAP = 0.4297111e7 * 1e18;
    //TOTAL ICO CAP
    uint256 public constant TOTAL_ICO_CAP = 0.5745112e7 * 1e18;

    uint256 public start;                                             // ICOEngineInterface
    uint256 public end;                                               // ICOEngineInterface
    uint256 public cap;                                               // ICOEngineInterface
    uint256 public tokenPerEth;
    uint256 public availableTokens;                                   // ICOEngineInterface
    address[] public kycSigners;                                      // KYCBase
    bool public capReached;
    uint256 public weiRaised;
    uint256 public tokensSold;

    // Vesting contracts.
    //Unlock funds after 9 months monthly
    PGOMonthlyInternalVault public pgoMonthlyInternalVault;
    //Unlock 1/3 funds immediately and remaining after 9 months monthly
    PGOMonthlyPresaleVault public pgoMonthlyPresaleVault;
    //Unlock funds after 12 months 25% every 6 months
    PGOVault public pgoVault;

    // Vesting wallets.
    address public pgoInternalReserveWallet;
    //Unlocked wallets
    address public pgoUnlockedLiquidityWallet;
    //ether wallet
    address public wallet;

    GotToken public token;

    // Lets owner manually end crowdsale.
    bool public didOwnerEndCrowdsale;

    /**
     * @dev Constructor.
     * @param _token address contract got tokens.
     * @param _wallet The address where funds should be transferred.
     * @param _pgoInternalReserveWallet The address where token will be send after vesting should be transferred.
     * @param _pgoUnlockedLiquidityWallet The address where token will be send after vesting should be transferred.
     * @param _pgoMonthlyInternalVault The address of internal funds vault contract with monthly unlocking after 9 months.
     * @param _pgoMonthlyPresaleVault The address of presale funds vault contract with 1/3 free funds and monthly unlocking after 9 months.
     * @param _kycSigners Array of the signers addresses required by the KYCBase constructor, provided by Eidoo.
     * See https://github.com/eidoo/icoengine
     */
    constructor(
        address _token,
        address _wallet,
        address _pgoInternalReserveWallet,
        address _pgoUnlockedLiquidityWallet,
        address _pgoMonthlyInternalVault,
        address _pgoMonthlyPresaleVault,
        address[] _kycSigners
    )
        public
        KYCBase(_kycSigners)
    {
        require(END_TIME >= START_TIME);
        require(TOTAL_ICO_CAP > 0);

        start = START_TIME;
        end = END_TIME;
        cap = TOTAL_ICO_CAP;
        wallet = _wallet;
        tokenPerEth = TOKEN_PER_ETHER;// USD_PER_ETHER.div(USD_PER_TOKEN);
        availableTokens = TOTAL_ICO_CAP;
        kycSigners = _kycSigners;

        token = GotToken(_token);
        pgoMonthlyInternalVault = PGOMonthlyInternalVault(_pgoMonthlyInternalVault);
        pgoMonthlyPresaleVault = PGOMonthlyPresaleVault(_pgoMonthlyPresaleVault);
        pgoInternalReserveWallet = _pgoInternalReserveWallet;
        pgoUnlockedLiquidityWallet = _pgoUnlockedLiquidityWallet;
        wallet = _wallet;
        // Creates ParkinGo vault contract
        pgoVault = new PGOVault(pgoInternalReserveWallet, address(token), END_TIME);
    }

    /**
     * @dev Mints unlocked tokens to unlockedLiquidityWallet and
     * assings tokens to be held into the internal reserve vault contracts.
     * To be called by the crowdsale&#39;s owner only.
     */
    function mintPreAllocatedTokens() public onlyOwner {
        mintTokens(pgoUnlockedLiquidityWallet, PGO_UNLOCKED_LIQUIDITY_CAP);
        mintTokens(address(pgoVault), PGO_INTERNAL_RESERVE_CAP);
    }

    /**
     * @dev Sets the state of the internal monthly locked vault contract and mints tokens.
     * It will contains all TEAM, FOUNDER, ADVISOR and PARTNERS tokens.
     * All token are locked for the first 9 months and then unlocked monthly.
     * It will check that all internal token are correctly allocated.
     * So far, the internal monthly vault contract has been deployed and this function
     * needs to be called to set its investments and vesting conditions.
     * @param beneficiaries Array of the internal addresses to whom vested tokens are transferred.
     * @param balances Array of token amount per beneficiary.
     */
    function initPGOMonthlyInternalVault(address[] beneficiaries, uint256[] balances)
        public
        onlyOwner
        equalLength(beneficiaries, balances)
    {
        uint256 totalInternalBalance = 0;
        uint256 balancesLength = balances.length;

        for (uint256 i = 0; i < balancesLength; i++) {
            totalInternalBalance = totalInternalBalance.add(balances[i]);
        }
        //check that all balances matches internal vault allocated Cap
        require(totalInternalBalance == MONTHLY_INTERNAL_VAULT_CAP);

        pgoMonthlyInternalVault.init(beneficiaries, balances, END_TIME, token);

        mintTokens(address(pgoMonthlyInternalVault), MONTHLY_INTERNAL_VAULT_CAP);
    }

    /**
     * @dev Sets the state of the reserved presale vault contract and mints reserved presale tokens. 
     * It will contains all reserved PRESALE token,
     * 1/3 of tokens are free and the remaining are locked for the first 9 months and then unlocked monthly.
     * It will check that all reserved presale token are correctly allocated.
     * So far, the monthly presale vault contract has been deployed and
     * this function needs to be called to set its investments and vesting conditions.
     * @param beneficiaries Array of the presale investors addresses to whom vested tokens are transferred.
     * @param balances Array of token amount per beneficiary.
     */
    function initPGOMonthlyPresaleVault(address[] beneficiaries, uint256[] balances)
        public
        onlyOwner
        equalLength(beneficiaries, balances)
    {
        uint256 totalPresaleBalance = 0;
        uint256 balancesLength = balances.length;

        for (uint256 i = 0; i < balancesLength; i++) {
            totalPresaleBalance = totalPresaleBalance.add(balances[i]);
        }
        //check that all balances matches internal vault allocated Cap
        require(totalPresaleBalance == RESERVED_PRESALE_CAP);

        pgoMonthlyPresaleVault.init(beneficiaries, balances, END_TIME, token);

        mintTokens(address(pgoMonthlyPresaleVault), totalPresaleBalance);
    }

    /**
     * @dev Mint all token collected by second private presale (called reservation),
     * all KYC control are made outside contract under responsability of ParkinGO.
     * Also, updates tokensSold and availableTokens in the crowdsale contract,
     * it checks that sold token are less than reservation contract cap.
     * @param beneficiaries Array of the reservation user that bought tokens in private reservation sale.
     * @param balances Array of token amount per beneficiary.
     */
    function mintReservation(address[] beneficiaries, uint256[] balances)
        public
        onlyOwner
        equalLength(beneficiaries, balances)
    {
        //require(tokensSold == 0);

        uint256 totalReservationBalance = 0;
        uint256 balancesLength = balances.length;

        for (uint256 i = 0; i < balancesLength; i++) {
            totalReservationBalance = totalReservationBalance.add(balances[i]);
            uint256 amount = balances[i];
            //update token sold of crowdsale contract
            tokensSold = tokensSold.add(amount);
            //update available token of crowdsale contract
            availableTokens = availableTokens.sub(amount);
            mintTokens(beneficiaries[i], amount);
        }

        require(totalReservationBalance <= RESERVATION_CAP);
    }

    /**
     * @dev Allows the owner to close the crowdsale manually before the end time.
     */
    function closeCrowdsale() public onlyOwner {
        require(block.timestamp >= START_TIME && block.timestamp < END_TIME);
        didOwnerEndCrowdsale = true;
    }

    /**
     * @dev Allows the owner to unpause tokens, stop minting and transfer ownership of the token contract.
     */
    function finalise() public onlyOwner {
        require(didOwnerEndCrowdsale || block.timestamp > end || capReached);

        token.finishMinting();
        token.unpause();

        // Token contract extends CanReclaimToken so the owner can recover
        // any ERC20 token received in this contract by mistake.
        // So far, the owner of the token contract is the crowdsale contract.
        // We transfer the ownership so the owner of the crowdsale is also the owner of the token.
        token.transferOwnership(owner);
    }

    /**
     * @dev Implements the price function from EidooEngineInterface.
     * @notice Calculates the price as tokens/ether based on the corresponding bonus bracket.
     * @return Price as tokens/ether.
     */
    function price() public view returns (uint256 _price) {
        return tokenPerEth;
    }

    /**
     * @dev Implements the ICOEngineInterface.
     * @return False if the ico is not started, true if the ico is started and running, true if the ico is completed.
     */
    function started() public view returns(bool) {
        if (block.timestamp >= start) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Implements the ICOEngineInterface.
     * @return False if the ico is not started, false if the ico is started and running, true if the ico is completed.
     */
    function ended() public view returns(bool) {
        if (block.timestamp >= end) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Implements the ICOEngineInterface.
     * @return Timestamp of the ico start time.
     */
    function startTime() public view returns(uint) {
        return start;
    }

    /**
     * @dev Implements the ICOEngineInterface.
     * @return Timestamp of the ico end time.
     */
    function endTime() public view returns(uint) {
        return end;
    }

    /**
     * @dev Implements the ICOEngineInterface.
     * @return The total number of the tokens available for the sale, must not change when the ico is started.
     */
    function totalTokens() public view returns(uint) {
        return cap;
    }

    /**
     * @dev Implements the ICOEngineInterface.
     * @return The number of the tokens available for the ico.
     * At the moment the ico starts it must be equal to totalTokens(),
     * then it will decrease.
     */
    function remainingTokens() public view returns(uint) {
        return availableTokens;
    }

    /**
     * @dev Implements the KYCBase senderAllowedFor function to enable a sender to buy tokens for a different address.
     * @return true.
     */
    function senderAllowedFor(address buyer) internal view returns(bool) {
        require(buyer != address(0));

        return true;
    }

    /**
     * @dev Implements the KYCBase releaseTokensTo function to mint tokens for an investor.
     * Called after the KYC process has passed.
     * @return A boolean that indicates if the operation was successful.
     */
    function releaseTokensTo(address buyer) internal returns(bool) {
        require(validPurchase());

        uint256 overflowTokens;
        uint256 refundWeiAmount;

        uint256 weiAmount = msg.value;
        uint256 tokenAmount = weiAmount.mul(price());

        if (tokenAmount >= availableTokens) {
            capReached = true;
            overflowTokens = tokenAmount.sub(availableTokens);
            tokenAmount = tokenAmount.sub(overflowTokens);
            refundWeiAmount = overflowTokens.div(price());
            weiAmount = weiAmount.sub(refundWeiAmount);
            buyer.transfer(refundWeiAmount);
        }

        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokenAmount);
        availableTokens = availableTokens.sub(tokenAmount);
        mintTokens(buyer, tokenAmount);
        forwardFunds(weiAmount);

        return true;
    }

    /**
     * @dev Fired by the releaseTokensTo function after minting tokens,
     * to forward the raised wei to the address that collects funds.
     * @param _weiAmount Amount of wei send by the investor.
     */
    function forwardFunds(uint256 _weiAmount) internal {
        wallet.transfer(_weiAmount);
    }

    /**
     * @dev Validates an incoming purchase. Required statements revert state when conditions are not met.
     * @return true If the transaction can buy tokens.
     */
    function validPurchase() internal view returns (bool) {
        require(!paused && !capReached);
        require(block.timestamp >= start && block.timestamp <= end);

        return true;
    }

    /**
     * @dev Mints tokens being sold during the crowdsale phase as part of the implementation of releaseTokensTo function
     * from the KYCBase contract.
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mintTokens(address to, uint256 amount) private {
        token.mint(to, amount);
    }

    modifier equalLength(address[] beneficiaries, uint256[] balances) {
        require(beneficiaries.length == balances.length);
        _;
    }
}