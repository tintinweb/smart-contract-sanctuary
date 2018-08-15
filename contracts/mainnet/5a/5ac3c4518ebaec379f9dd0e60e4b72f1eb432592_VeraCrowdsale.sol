pragma solidity ^0.4.24;

// File: contracts/math/Math.sol

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

// File: contracts/math/SafeMath.sol

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

// File: contracts/rbac/Roles.sol

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

// File: contracts/rbac/RBAC.sol

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

// File: contracts/VeraCrowdsale.sol

/**
 * @title Interface of Price oracle
 * @dev Implements methods of price oracle used in the crowdsale
 * @author OnGrid Systems
 */
contract PriceOracleIface {
  uint256 public ethPriceInCents;

  function getUsdCentsFromWei(uint256 _wei) public view returns (uint256) {
  }
}


/**
 * @title Interface of ERC-20 token
 * @dev Implements transfer methods and event used throughout crowdsale
 * @author OnGrid Systems
 */
contract TransferableTokenIface {
  function transfer(address to, uint256 value) public returns (bool) {
  }

  function balanceOf(address who) public view returns (uint256) {
  }

  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title CrowdSale contract for Vera.jobs
 * @dev Keep the list of investors passed KYC, receive ethers to fallback,
 * calculate correspinding amount of tokens, add bonus (depending on the deposit size)
 * then transfers tokens to the investor&#39;s account
 * @author OnGrid Systems
 */
contract VeraCrowdsale is RBAC {
  using SafeMath for uint256;

  // Price of one token (1.00000...) in USD cents
  uint256 public tokenPriceInCents = 200;

  // Minimal amount of USD cents to invest. Transactions of less value will be reverted.
  uint256 public minDepositInCents = 1000;

  // Amount of USD cents raised. Continuously increments on each transaction.
  // Note: may be irrelevant because the actual amount of harvested ethers depends on ETH/USD price at the moment.
  uint256 public centsRaised;

  // Amount of tokens distributed by this contract.
  // Note: doesn&#39;t include previous phases of tokensale.
  uint256 public tokensSold;

  // Address of VERA ERC-20 token contract
  TransferableTokenIface public token;

  // Address of ETH price feed
  PriceOracleIface public priceOracle;

  // Wallet address collecting received ETH
  address public wallet;

  // constants defining roles for access control
  string public constant ROLE_ADMIN = "admin";
  string public constant ROLE_BACKEND = "backend";
  string public constant ROLE_KYC_VERIFIED_INVESTOR = "kycVerified";

  // Value bonus configuration
  struct AmountBonus {

    // To understand which bonuses were applied bonus contains binary flag.
    // If several bonuses applied ids get summarized in resulting event.
    // Use values with a single 1-bit like 0x01, 0x02, 0x04, 0x08
    uint256 id;

    // amountFrom and amountTo define deposit value range.
    // Bonus percentage applies if deposit amount in cents is within the boundaries
    uint256 amountFrom;
    uint256 amountTo;
    uint256 bonusPercent;
  }

  // The list of available bonuses. Filled by the constructor on contract initialization
  AmountBonus[] public amountBonuses;

  /**
   * Event for token purchase logging
   * @param investor who received tokens
   * @param ethPriceInCents ETH price at the moment of purchase
   * @param valueInCents deposit calculated to USD cents
   * @param bonusPercent total bonus percent (sum of all bonuses)
   * @param bonusIds flags of all the bonuses applied to the purchase
   */
  event TokenPurchase(
    address indexed investor,
    uint256 ethPriceInCents,
    uint256 valueInCents,
    uint256 bonusPercent,
    uint256 bonusIds
  );

  /**
   * @dev modifier to scope access to admins
   * // reverts if called not by admin
   */
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }

  /**
   * @dev modifier to scope access of backend keys stored on
   * investor&#39;s portal
   * // reverts if called not by backend
   */
  modifier onlyBackend()
  {
    checkRole(msg.sender, ROLE_BACKEND);
    _;
  }

  /**
   * @dev modifier allowing calls from investors successfully passed KYC verification
   * // reverts if called by investor who didn&#39;t pass KYC via investor&#39;s portal
   */
  modifier onlyKYCVerifiedInvestor()
  {
    checkRole(msg.sender, ROLE_KYC_VERIFIED_INVESTOR);
    _;
  }

  /**
   * @dev Constructor initializing Crowdsale contract
   * @param _token address of the token ERC-20 contract.
   * @param _priceOracle ETH price feed
   * @param _wallet address where received ETH get forwarded
   */
  constructor(
    TransferableTokenIface _token,
    PriceOracleIface _priceOracle,
    address _wallet
  )
    public
  {
    require(_token != address(0), "Need token contract address");
    require(_priceOracle != address(0), "Need price oracle contract address");
    require(_wallet != address(0), "Need wallet address");
    addRole(msg.sender, ROLE_ADMIN);
    token = _token;
    priceOracle = _priceOracle;
    wallet = _wallet;
    // solium-disable-next-line arg-overflow
    amountBonuses.push(AmountBonus(0x1, 800000, 1999999, 20));
    // solium-disable-next-line arg-overflow
    amountBonuses.push(AmountBonus(0x2, 2000000, 2**256 - 1, 30));
  }

  /**
   * @dev Fallback function receiving ETH sent to the contract address
   * sender must be KYC (Know Your Customer) verified investor.
   */
  function ()
    external
    payable
    onlyKYCVerifiedInvestor
  {
    uint256 valueInCents = priceOracle.getUsdCentsFromWei(msg.value);
    buyTokens(msg.sender, valueInCents);
    wallet.transfer(msg.value);
  }

  /**
   * @dev Withdraws all remaining (not sold) tokens from the crowdsale contract
   * @param _to address of tokens receiver
   */
  function withdrawTokens(address _to) public onlyAdmin {
    uint256 amount = token.balanceOf(address(this));
    require(amount > 0, "no tokens on the contract");
    token.transfer(_to, amount);
  }

  /**
   * @dev Called when investor&#39;s portal (backend) receives non-ethereum payment
   * @param _investor address of investor
   * @param _cents received deposit amount in cents
   */
  function buyTokensViaBackend(address _investor, uint256 _cents)
    public
    onlyBackend
  {
    if (! RBAC.hasRole(_investor, ROLE_KYC_VERIFIED_INVESTOR)) {
      addKycVerifiedInvestor(_investor);
    }
    buyTokens(_investor, _cents);
  }

  /**
   * @dev Computes total bonuses amount by value
   * @param _cents deposit amount in USD cents
   * @return total bonus percent (sum of applied bonus percents), bonusIds (sum of applied bonus flags)
   */
  function computeBonuses(uint256 _cents)
    public
    view
    returns (uint256, uint256)
  {
    uint256 bonusTotal;
    uint256 bonusIds;
    for (uint i = 0; i < amountBonuses.length; i++) {
      if (_cents >= amountBonuses[i].amountFrom &&
      _cents <= amountBonuses[i].amountTo) {
        bonusTotal += amountBonuses[i].bonusPercent;
        bonusIds += amountBonuses[i].id;
      }
    }
    return (bonusTotal, bonusIds);
  }

  /**
   * @dev Calculates amount of tokens by cents
   * @param _cents deposit amount in USD cents
   * @return amount of tokens investor receive for the deposit
   */
  function computeTokens(uint256 _cents) public view returns (uint256) {
    uint256 tokens = _cents.mul(10 ** 18).div(tokenPriceInCents);
    (uint256 bonusPercent, ) = computeBonuses(_cents);
    uint256 bonusTokens = tokens.mul(bonusPercent).div(100);
    if (_cents >= minDepositInCents) {
      return tokens.add(bonusTokens);
    }
  }

  /**
   * @dev Add admin role to an address
   * @param addr address
   */
  function addAdmin(address addr)
    public
    onlyAdmin
  {
    addRole(addr, ROLE_ADMIN);
  }

  /**
   * @dev Revoke admin privileges from an address
   * @param addr address
   */
  function delAdmin(address addr)
    public
    onlyAdmin
  {
    removeRole(addr, ROLE_ADMIN);
  }

  /**
   * @dev Add backend privileges to an address
   * @param addr address
   */
  function addBackend(address addr)
    public
    onlyAdmin
  {
    addRole(addr, ROLE_BACKEND);
  }

  /**
   * @dev Revoke backend privileges from an address
   * @param addr address
   */
  function delBackend(address addr)
    public
    onlyAdmin
  {
    removeRole(addr, ROLE_BACKEND);
  }

  /**
   * @dev Mark investor&#39;s address as KYC-verified person
   * @param addr address
   */
  function addKycVerifiedInvestor(address addr)
    public
    onlyBackend
  {
    addRole(addr, ROLE_KYC_VERIFIED_INVESTOR);
  }

  /**
   * @dev Revoke KYC verification from the person
   * @param addr address
   */
  function delKycVerifiedInvestor(address addr)
    public
    onlyBackend
  {
    removeRole(addr, ROLE_KYC_VERIFIED_INVESTOR);
  }

  /**
   * @dev Calculates and applies bonuses and implements actual token transfer and events
   * @param _investor address of the beneficiary receiving tokens
   * @param _cents amount of deposit in cents
   */
  function buyTokens(address _investor, uint256 _cents) internal {
    (uint256 bonusPercent, uint256 bonusIds) = computeBonuses(_cents);
    uint256 tokens = computeTokens(_cents);
    require(tokens > 0, "value is not enough");
    token.transfer(_investor, tokens);
    centsRaised = centsRaised.add(_cents);
    tokensSold = tokensSold.add(tokens);
    emit TokenPurchase(
      _investor,
      priceOracle.ethPriceInCents(),
      _cents,
      bonusPercent,
      bonusIds
    );
  }
}