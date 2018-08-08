pragma solidity ^0.4.17;

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
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 *      See RBAC.sol for example usage.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an address access to this role
     */
    function add(Role storage role, address addr)
    internal
    {
        role.bearer[addr] = true;
    }

    /**
     * @dev remove an address&#39; access to this role
     */
    function remove(Role storage role, address addr)
    internal
    {
        role.bearer[addr] = false;
    }

    /**
     * @dev check if an address has this role
     * // reverts
     */
    function check(Role storage role, address addr)
    view
    internal
    {
        require(has(role, addr));
    }

    /**
     * @dev check if an address has this role
     * @return bool
     */
    function has(Role storage role, address addr)
    view
    internal
    returns (bool)
    {
        return role.bearer[addr];
    }
}



/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * @dev Supports unlimited numbers of roles and addresses.
 * @dev See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 *  for you to write your own implementation of this interface using Enums or similar.
 * It&#39;s also recommended that you define constants in the contract, like ROLE_ADMIN below,
 *  to avoid typos.
 */
contract RBAC {
    using Roles for Roles.Role;

    mapping (string => Roles.Role) private roles;

    event RoleAdded(address addr, string roleName);
    event RoleRemoved(address addr, string roleName);

    /**
     * @dev reverts if addr does not have role
     * @param addr address
     * @param roleName the name of the role
     * // reverts
     */
    function checkRole(address addr, string roleName)
    view
    public
    {
        roles[roleName].check(addr);
    }

    /**
     * @dev determine if addr has role
     * @param addr address
     * @param roleName the name of the role
     * @return bool
     */
    function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
    {
        return roles[roleName].has(addr);
    }

    /**
     * @dev add a role to an address
     * @param addr address
     * @param roleName the name of the role
     */
    function addRole(address addr, string roleName)
    internal
    {
        roles[roleName].add(addr);
        emit RoleAdded(addr, roleName);
    }

    /**
     * @dev remove a role from an address
     * @param addr address
     * @param roleName the name of the role
     */
    function removeRole(address addr, string roleName)
    internal
    {
        roles[roleName].remove(addr);
        emit RoleRemoved(addr, roleName);
    }

    /**
     * @dev modifier to scope access to a single role (uses msg.sender as addr)
     * @param roleName the name of the role
     * // reverts
     */
    modifier onlyRole(string roleName)
    {
        checkRole(msg.sender, roleName);
        _;
    }

    /**
     * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
     * @param roleNames the names of the roles to scope access to
     * // reverts
     *
     * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
     *  see: https://github.com/ethereum/solidity/issues/2467
     */
    // modifier onlyRoles(string[] roleNames) {
    //     bool hasAnyRole = false;
    //     for (uint8 i = 0; i < roleNames.length; i++) {
    //         if (hasRole(msg.sender, roleNames[i])) {
    //             hasAnyRole = true;
    //             break;
    //         }
    //     }

    //     require(hasAnyRole);

    //     _;
    // }
}


/**
 * @title RBACWithAdmin
 * @author Matt Condon (@Shrugs)
 * @dev It&#39;s recommended that you define constants in the contract,
 * @dev like ROLE_ADMIN below, to avoid typos.
 */
contract RBACWithAdmin is RBAC {
    /**
     * A constant role name for indicating admins.
     */
    string public constant ROLE_ADMIN = "admin";

    /**
     * @dev modifier to scope access to admins
     * // reverts
     */
    modifier onlyAdmin()
    {
        checkRole(msg.sender, ROLE_ADMIN);
        _;
    }

    /**
     * @dev constructor. Sets msg.sender as admin by default
     */
    function RBACWithAdmin()
    public
    {
        addRole(msg.sender, ROLE_ADMIN);
    }

    /**
     * @dev add a role to an address
     * @param addr address
     * @param roleName the name of the role
     */
    function adminAddRole(address addr, string roleName)
    onlyAdmin
    public
    {
        addRole(addr, roleName);
    }

    /**
     * @dev remove a role from an address
     * @param addr address
     * @param roleName the name of the role
     */
    function adminRemoveRole(address addr, string roleName)
    onlyAdmin
    public
    {
        removeRole(addr, roleName);
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
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using &#39;super&#39; where appropiate to concatenate
 * behavior.
 */
contract Crowdsale {
    using SafeMath for uint256;

    // The token being sold
    ERC20 public token;

    // Address where funds are collected
    address public wallet;

    // How many token units a buyer gets per wei
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
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @param _rate Number of token units a buyer gets per wei
     * @param _wallet Address where collected funds will be forwarded to
     * @param _token Address of the token being sold
     */
    function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
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
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        // optional override
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.transfer(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
     * @param _beneficiary Address receiving the tokens
     * @param _tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
     * @param _beneficiary Address receiving the tokens
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
        // optional override
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(rate);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}



// NbtToken crowdsale-valuable interface
contract NbtToken  {
    uint256 public saleableTokens;
    uint256 public MAX_SALE_VOLUME;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function moveTokensFromSaleToCirculating(address _to, uint256 _amount) public returns (bool);
}

/// @title Nbt Token Crowdsale Contract
// Main crowdsale contract
contract NbtCrowdsale is Crowdsale, Pausable, RBACWithAdmin {

    /*** EVENTS ***/

    event NewStart(uint256 start);
    event NewDeadline(uint256 deadline);
    event NewRate(uint256 rate);
    event NewWallet(address new_address);
    event Sale(address indexed buyer, uint256 tokens_with_bonuses);

    /*** CONSTANTS ***/

    uint256 public DECIMALS = 8;
    uint256 public BONUS1 = 100; // %
    uint256 public BONUS1_LIMIT = 150000000 * 10**DECIMALS;
    uint256 public BONUS2 = 60; // %
    uint256 public BONUS2_LIMIT = 250000000 * 10**DECIMALS;
    uint256 public MIN_TOKENS = 1000 * 10**DECIMALS;

    NbtToken public token;

    /*** STORAGE ***/

    uint256 public start;
    uint256 public deadline;
    bool crowdsaleClosed = false;

    /*** MODIFIERS ***/

    modifier afterDeadline() { if (now > deadline) _; }
    modifier beforeDeadline() { if (now <= deadline) _; }
    modifier afterStart() { if (now >= start) _; }
    modifier beforeStart() { if (now < start) _; }

    /*** CONSTRUCTOR ***/

    /**
      * @param _rate Number of token units a buyer gets per wei
      * @param _wallet Address where collected funds will be forwarded to
      * @param _token Address of the token being sold
      * @param _start Start date of the crowdsale
      * @param _deadline Deadline of the crowdsale
      */
    function NbtCrowdsale(uint256 _rate, address _wallet, NbtToken _token, uint256 _start, uint256 _deadline) Crowdsale(_rate, _wallet, ERC20(_token)) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));
        require(_start < _deadline);

        start = _start;
        deadline = _deadline;

        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

    /*** PUBLIC AND EXTERNAL FUNCTIONS ***/

    /**
     * @dev set new start date for crowdsale.
     * @param _start The new start timestamp
     */
    function setStart(uint256 _start) onlyAdmin whenPaused public returns (bool) {
        require(_start < deadline);
        start = _start;
        emit NewStart(start);
        return true;
    }

    /**
     * @dev set new start date for crowdsale.
     * @param _deadline The new deadline timestamp
     */
    function setDeadline(uint256 _deadline) onlyAdmin whenPaused public returns (bool) {
        require(start < _deadline);
        deadline = _deadline;
        emit NewDeadline(_deadline);
        return true;
    }

    /**
     * @dev set new wallet address
     * @param _addr The new wallet address
     */
    function setWallet(address _addr) onlyAdmin public returns (bool) {
        require(_addr != address(0) && _addr != address(this));
        wallet = _addr;
        emit NewWallet(wallet);
        return true;
    }

    /**
     * @dev set new rate for crowdsale.
     * @param _rate Number of token units a buyer gets per wei
     */
    function setRate(uint256 _rate) onlyAdmin public returns (bool) {
        require(_rate > 0);
        rate = _rate;
        emit NewRate(rate);
        return true;
    }

    /**
      * @dev called by the admin to pause, triggers stopped state
      */
    function pause() onlyAdmin whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the admin to unpause, returns to normal state
     */
    function unpause() onlyAdmin whenPaused public {
        paused = false;
        emit Unpause();
    }

    function getCurrentBonus() public view returns (uint256) {
        if (token.MAX_SALE_VOLUME().sub(token.saleableTokens()) < BONUS1_LIMIT) {
            return BONUS1;
        } else if (token.MAX_SALE_VOLUME().sub(token.saleableTokens()) < BONUS2_LIMIT) {
            return BONUS2;
        } else {
            return 0;
        }
    }

    function getTokenAmount(uint256 _weiAmount) public view returns (uint256) {
        return _getTokenAmount(_weiAmount);
    }

    /**
     * Close the crowdsale
     */
    function closeCrowdsale() onlyAdmin afterDeadline public {
        crowdsaleClosed = true;
    }

    /*** INTERNAL FUNCTIONS ***/

    /**
       * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
       * @param _beneficiary Address performing the token purchase
       * @param _weiAmount Value in wei involved in the purchase
       */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) whenNotPaused afterStart beforeDeadline internal {
        require(!crowdsaleClosed);
        require(_weiAmount >= 1000000000000);
        require(_getTokenAmount(_weiAmount) <= token.balanceOf(this));
        require(_getTokenAmount(_weiAmount) >= MIN_TOKENS);
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

    /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
    function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        // optional override
    }

    /**
      * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
      * @param _beneficiary Address performing the token purchase
      * @param _tokenAmount Number of tokens to be emitted
      */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.moveTokensFromSaleToCirculating(_beneficiary, _tokenAmount);
        token.transfer(_beneficiary, _tokenAmount);
        emit Sale(_beneficiary, _tokenAmount);
    }

    /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
        // optional override
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 _current_bonus =  getCurrentBonus();
        if (_current_bonus == 0) {
            return _weiAmount.mul(rate).div(1000000000000); // token amount for 1 szabo
        } else {
            return _weiAmount.mul(rate).mul(_current_bonus.add(100)).div(100).div(1000000000000); // token amount for 1 szabo
        }
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}