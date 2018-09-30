pragma solidity ^0.4.24;

// File: node_modules\openzeppelin-solidity\contracts\access\rbac\Roles.sol

/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 * See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

  /**
   * @dev remove an address&#39; access to this role
   */
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

// File: node_modules\openzeppelin-solidity\contracts\access\rbac\RBAC.sol

/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * Supports unlimited numbers of roles and addresses.
 * See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 * for you to write your own implementation of this interface using Enums or similar.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

  /**
   * @dev reverts if addr does not have role
   * @param _operator address
   * @param _role the name of the role
   * // reverts
   */
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

  /**
   * @dev determine if addr has role
   * @param _operator address
   * @param _role the name of the role
   * @return bool
   */
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

  /**
   * @dev add a role to an address
   * @param _operator address
   * @param _role the name of the role
   */
  function addRole(address _operator, string _role)
    public
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

  /**
   * @dev remove a role from an address
   * @param _operator address
   * @param _role the name of the role
   */
  function removeRole(address _operator, string _role)
    public
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param _role the name of the role
   * // reverts
   */
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param _roles the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] _roles) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < _roles.length; i++) {
  //         if (hasRole(msg.sender, _roles[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

// File: node_modules\openzeppelin-solidity\contracts\math\SafeMath.sol

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

// File: node_modules\openzeppelin-solidity\contracts\ownership\Ownable.sol

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

// File: node_modules\openzeppelin-solidity\contracts\token\ERC20\ERC20Basic.sol

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

// File: node_modules\openzeppelin-solidity\contracts\token\ERC20\ERC20.sol

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

// File: node_modules\openzeppelin-solidity\contracts\token\ERC20\SafeERC20.sol

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

// File: node_modules\openzeppelin-solidity\contracts\crowdsale\Crowdsale.sol

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using &#39;super&#39; where appropriate to concatenate
 * behavior.
 */
contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei.
  // The rate is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with a DetailedERC20 token with 3 decimals called TOK
  // 1 wei will give you 1 unit, or 0.001 TOK.
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use `super` in contracts that inherit from Crowdsale to extend their validations.
   * Example from CappedCrowdsale.sol&#39;s _preValidatePurchase method: 
   *   super._preValidatePurchase(_beneficiary, _weiAmount);
   *   require(weiRaised.add(_weiAmount) <= cap);
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

// File: node_modules\openzeppelin-solidity\contracts\crowdsale\validation\TimedCrowdsale.sol

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  constructor(uint256 _openingTime, uint256 _closingTime) public {
    // solium-disable-next-line security/no-block-members
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > closingTime;
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

// File: node_modules\openzeppelin-solidity\contracts\crowdsale\distribution\FinalizableCrowdsale.sol

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is Ownable, TimedCrowdsale {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() public onlyOwner {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal {
  }

}

// File: contracts\TrainDanyCrowdsale.sol

// solium-disable linebreak-style
pragma solidity ^0.4.24;



/**
* @title TrainDany Crowdsale Contracts   
* @dev It is a Timed Crowdsale 
*/
contract TrainDanyCrowdsale is RBAC, FinalizableCrowdsale {

    // TODO: buy token works
    // TODO: Roles should work
    // TODO: Finalize crowdsale

    uint256 public rate = 40000;                                    // fixed rate for 1 ETHER = 40000 TDY Token
    uint256 public openingTime;                                     // Sales Opening Time
    uint256 public closingTime;                                     // Sales Closing Time

    // ICO Stages ==========================================
    enum CrowdsaleStage { PrivateSale, PreSale, PublicSale }        // All 3 Sale Stages
    CrowdsaleStage public stage;                                    // the sale stages
    bool private privateSalesEnd = false;                           // flags for tracking private sales
    bool private preSalesEnd = false;                               // flags for tracking pre sales
    bool private publicSalesEnd = false;                            // flags for tracking public sales

    uint256 public minimumInvest;                                   // minimum invest for investor
    uint256 public totalTokenAvailableInThisStage;                  // Token availbale for sell in this stage
    uint256 public totalTokenSoldinThisStage;                       // Tokens Sold 
    uint256 public bonusMultiplier;                                 // Bonus tokens rate multiplier x1000 (i.e. 1200 is 1.2 x 1000 = 120% x1000 = +20% bonus)
    bool public closed;                                             // Is a crowdsale stage closed?
    uint256 public tokensIssued;                                    // Amount of issued tokens

    mapping(address => uint256) public balances;                    // Map of all purchaiser&#39;s balances (doesn&#39;t include bounty amounts)

    /**
    * Event for token delivered logging
    * @param _receiver who receive the tokens
    * @param _amount amount of tokens sent
    */
    event TokenDelivered(address indexed _receiver, uint256 _amount);
    /**
    * Event for Date Changed logging
    * @param _startTime opening time for crowdsale
    * @param _endTime closing time for crowdsale
    */
    event InitialDateReset(uint256 _startTime, uint256 _endTime);

    // Token Distribution
    // ====================================================
    uint256 private maxTokens = 625000000000000000;                 // There will be total 4000000000 TDY Tokens
    uint256 private tokensForSales = 400000000000000000;
    uint256 private tokensForTeam = 62500000000000000;                       // half blocked for 1 year / half blocked for 2 years
    uint256 private tokensForBonus = 18750000000000000;
    uint256 private tokenForAdvisor = 50000000000000000;                     // blocked for 6 months
    uint256 private totalTokensForSaleDuringPrivatesale = 62500000000000000; // 20 out of 60 HTs will be sold during PreICO
    uint256 private totalTokensForSaleDuringPresale = 62500000000000000;
    uint256 private totalTokensForSaleDuringPublicsale = 187500000000000000;
    /**
    * @dev Constructor for Initializing the sales upon deployment
    * @param _startTime start time in unix epoch can be got from https://www.epochconverter.com/
    * @param _endTime end time in unix epoch can be got from https://www.epochconverter.com/
    * @param _wallet wallet address where the fund will be forwared upon purchases
    * @param _trainDanyToken train dany token contract address
    */
    constructor(uint256 _startTime, uint256 _endTime, address _wallet, ERC20 _trainDanyToken)
        Crowdsale(rate, _wallet, _trainDanyToken) 
        TimedCrowdsale(_startTime, _endTime)
        public {
        setCrowdsale(0, _startTime, _endTime);                      // starts the private sale
    }

    /**
    * @dev time reset machanism
    * @param _startTime change start time
    * @param _endTime change end time
    */
    function changeDates(uint256 _startTime, uint256 _endTime) public onlyOwner returns (bool) { 
        require(openingTime > block.timestamp);
        require(_startTime >= now);
        require(_endTime >= _startTime);

        openingTime = _startTime;
        closingTime = _endTime;

        emit InitialDateReset(openingTime, closingTime);
        return true;
    }

    /**
    * @dev functions for setting up the crowdsale stage
    * @param _stageValue numerical value of the crowdsale stages.
    * Available options are 0 = private sale, 1 = pre sale, 2 = public sale
    * @param _startTime unix epoch time can be got from https://www.epochconverter.com/
    * @param _endTime unix epoch time can be got from https://www.epochconverter.com/
    */
    function setCrowdsale(uint _stageValue, uint256 _startTime, uint256 _endTime) onlyOwner public returns(bool){
        require(_stageValue <= 2);
        require(_startTime > now);
        require(_endTime > _startTime);

        openingTime = _startTime;
        closingTime = _endTime;
        
        if (_stageValue == uint(CrowdsaleStage.PrivateSale)) {
            stage = CrowdsaleStage.PrivateSale;
            minimumInvest = 250 ether;
            totalTokenAvailableInThisStage = 62500000000000000;
            bonusMultiplier = 1500;
            totalTokenSoldinThisStage = 0;
        } else if (_stageValue == uint(CrowdsaleStage.PreSale)) {
            stage = CrowdsaleStage.PreSale;
            minimumInvest = 0.1 ether;
            totalTokenAvailableInThisStage = 62500000000000000;
            bonusMultiplier = 1300;
            totalTokenSoldinThisStage = 0;
        } else if (_stageValue == uint(CrowdsaleStage.PublicSale)) {
            stage = CrowdsaleStage.PublicSale;
            minimumInvest = 0.1 ether;
            totalTokenAvailableInThisStage = 187500000000000000;
            bonusMultiplier = 1200;
            totalTokenSoldinThisStage = 0;
        }
        return true;
    }

    /**
    * @dev Closes the period in which the crowdsale stage is open.
    */
    function closeCrowdsale(bool closed_) public onlyOwner {
        closed = closed_;
        finalizeStage();
    }

    function finalizeStage() internal {
        // finalize the stage
        if (stage == CrowdsaleStage.PrivateSale) {
            privateSalesEnd = true;
            setCrowdsale(1, block.timestamp, closingTime);
        } else if (stage == CrowdsaleStage.PreSale) {
            preSalesEnd = true;
            setCrowdsale(2, block.timestamp, closingTime);
        } else if (stage == CrowdsaleStage.PublicSale) {
            publicSalesEnd = true;
        }
        // mint token to adjust with parameters
        uint256 tokenNotSold = totalTokenAvailableInThisStage - totalTokenSoldinThisStage;
        if (tokenNotSold > totalTokenAvailableInThisStage) {
            // add tokens
        } 
    }
    // Token Purchase
    // ==============================================================================
    /**
    * @dev Overrides parent for extra logic and requirements before purchasing tokens.
    * @param _beneficiary Token purchaser
    * @param _weiAmount Amount of tokens purchased
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        require(!hasClosed());                                                  // check if crowdslae is still opens
        require(totalTokenAvailableInThisStage >= totalTokenSoldinThisStage);   // check if all tokens sold out       
        require(msg.value >= minimumInvest);                                    // check minimum invest met

        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

    /**
    * @dev Overrides parent by storing balances instead of issuing tokens right away.
    * @param _beneficiary Token purchaser
    * @param _tokenAmount Amount of tokens purchased
    */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
        totalTokenSoldinThisStage = totalTokenSoldinThisStage.add(_tokenAmount);
    }

    /**
    * @dev Overrides the way in which ether is converted to tokens.
    * @param _weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _weiAmount
    */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(rate).mul(bonusMultiplier).div(1000);
    }

    // // Roles
    // function addRole(address _operator, string _role) onlyOwner public {
    //     roles[_role].add(_operator);
    //     emit RoleAdded(_operator, _role);
    // }

    // function removeRole(address _operator, string _role) onlyOwner public {
    //     roles[_role].remove(_operator);
    //     emit RoleRemoved(_operator, _role);
    // }

//     /**
//     * @dev Closes the period in which the crowdsale is open.
//     */
//     function closeCrowdsale(bool closed_) public onlyOwner {
//         closed = closed_;
//     }
    // // Token Purchase
    // // =========================
    // function () external payable {
    //     require(msg.value >= minimumInvest);  // beneficiary values should be more than minium invest
    //     // require(totalTokenAvailableInThisStage > );
        
    //     // uint256 tokensGet = msg.value.mul(rate) + bonusMultiplier;

    //     // if ((stage == CrowdsaleStage.PrivateSale)) {
    //     //     msg.sender.transfer(msg.value);
    //     //     return;
    //     // }

    //     buyTokens(msg.sender);

    //     // if (stage == CrowdsaleStage.PreICO) {
    //     //     totalWeiRaisedDuringPreICO = totalWeiRaisedDuringPreICO.add(msg.value);
    //     // }
    // }
    // // Finish: Mint Extra Tokens as needed before finalizing the Crowdsale.
    // // ====================================================================

    // function finish(address _team, address _advisor) public onlyOwner {

    //     require(!closed);
    //     uint256 alreadyMinted = token.totalSupply();
    //     require(alreadyMinted < maxTokens);

    //     if (stage == CrowdsaleStage.PrivateSale){
    //         uint256 unsoldTokens = totalTokenAvailableInThisStage - alreadyMinted;
    //         if (unsoldTokens > 0) {
    //             // mint to match cap for this stage
    //         }
    //     }
        
    //     // token.mint(_teamFund,tokensForTeam);
    //     // token.mint(_ecosystemFund,tokensForEcosystem);
    //     // token.mint(_bountyFund,tokensForBounty);
    //     // finalize();
    // }
    // ===============================
}