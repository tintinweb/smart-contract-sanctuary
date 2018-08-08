pragma solidity 0.4.21;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: lib/solidity-rationals/contracts/Rationals.sol

library R {

    struct Rational {
        uint n;  // numerator
        uint d;  // denominator
    }

}


library Rationals {
    using SafeMath for uint;

    function rmul(uint256 amount, R.Rational memory r) internal pure returns (uint256) {
        return amount.mul(r.n).div(r.d);
    }

}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

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

// File: zeppelin-solidity/contracts/ownership/rbac/Roles.sol

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

// File: zeppelin-solidity/contracts/ownership/rbac/RBAC.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: contracts/Exchange.sol

/**
 * @title Atomic exchange to facilitate swaps from ETH or DAI to a token.
 * Users an oracle bot to update market prices.
 */
contract Exchange is Pausable, RBAC {
    using SafeMath for uint256;

    string constant ROLE_ORACLE = "oracle";

    ERC20 baseToken;
    ERC20 dai;  // 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359
    address public oracle;
    R.Rational public ethRate;
    R.Rational public daiRate;

    event TradeETH(uint256 amountETH, uint256 amountBaseToken);
    event TradeDAI(uint256 amountDAI, uint256 amountBaseToken);
    event RateUpdatedETH(uint256 n, uint256 d);
    event RateUpdatedDAI(uint256 n, uint256 d);
    event OracleSet(address oracle);

    /**
     * Constructor for exchange.
     *
     * @param _baseToken Address of the token to exchange for
     * @param _dai Address of DAI token
     * @param _oracle Address of oracle tasked with periodically setting market rates
     * @param _ethRateN Numerator of the ETH to token exchange rate
     * @param _ethRateD Denominator of the ETH to token exchange rate
     * @param _daiRateN Numerator of the DAI to token exchange rate
     * @param _daiRateD Denominator of the DAI to token exchange rate
     */
    function Exchange(
        address _baseToken,
        address _dai,
        address _oracle,
        uint256 _ethRateN,
        uint256 _ethRateD,
        uint256 _daiRateN,
        uint256 _daiRateD
    ) public {
        baseToken = ERC20(_baseToken);
        dai = ERC20(_dai);
        addRole(_oracle, ROLE_ORACLE);
        oracle = _oracle;
        ethRate = R.Rational(_ethRateN, _ethRateD);
        daiRate = R.Rational(_daiRateN, _daiRateD);
    }

    /**
     * Trades ETH for tokens at ethRate.
     *
     * @param expectedAmountBaseToken Amount of tokens expected to receive.
     * This prevents front-running race conditions from occurring when ethRate
     * is updated.
     */
    function tradeETH(uint256 expectedAmountBaseToken) public whenNotPaused() payable {
        uint256 amountBaseToken = calculateAmountForETH(msg.value);
        require(amountBaseToken == expectedAmountBaseToken);
        require(baseToken.transfer(msg.sender, amountBaseToken));
        emit TradeETH(msg.value, amountBaseToken);
    }

    /**
     * Trades DAI for tokens at daiRate. User must first approve DAI to be
     * transferred by Exchange.
     *
     * @param amountDAI Amount of DAI to exchange
     * @param expectedAmountBaseToken Amount of tokens expected to receive.
     * This prevents front-running race conditions from occurring when daiRate
     * is updated.
     */
    function tradeDAI(uint256 amountDAI, uint256 expectedAmountBaseToken) public whenNotPaused() {
        uint256 amountBaseToken = calculateAmountForDAI(amountDAI);
        require(amountBaseToken == expectedAmountBaseToken);
        require(dai.transferFrom(msg.sender, address(this), amountDAI));
        require(baseToken.transfer(msg.sender, amountBaseToken));
        emit TradeDAI(amountDAI, amountBaseToken);
    }

    /**
     * Calculates exchange amount for ETH to token.
     *
     * @param amountETH Amount of ETH, in base units
     */
    function calculateAmountForETH(uint256 amountETH) public view returns (uint256) {
        return Rationals.rmul(amountETH, ethRate);
    }

    /**
     * Calculates exchange amount for DAI to token.
     *
     * @param amountDAI Amount of DAI, in base units
     */
    function calculateAmountForDAI(uint256 amountDAI) public view returns (uint256) {
        return Rationals.rmul(amountDAI, daiRate);
    }

    /**
     * Sets the exchange rate from ETH to token.
     *
     * @param n Numerator for ethRate
     * @param d Denominator for ethRate
     */
    function setETHRate(uint256 n, uint256 d) external onlyRole(ROLE_ORACLE) {
        ethRate = R.Rational(n, d);
        emit RateUpdatedETH(n, d);
    }

    /**
     * Sets the exchange rate from ETH to token.
     *
     * @param n Numerator for daiRate
     * @param d Denominator for daiRate
     */
    function setDAIRate(uint256 n, uint256 d) external onlyRole(ROLE_ORACLE) {
        daiRate = R.Rational(n, d);
        emit RateUpdatedDAI(n, d);
    }

    /**
     * Recovers DAI, leftover tokens, or other.
     *
     * @param token Address of token to withdraw
     * @param amount Amount of tokens to withdraw
     */
    function withdrawERC20s(address token, uint256 amount) external onlyOwner {
        ERC20 erc20 = ERC20(token);
        require(erc20.transfer(owner, amount));
    }

    /**
     * Changes the oracle.
     *
     * @param _oracle Address of new oracle
     */
    function setOracle(address _oracle) external onlyOwner {
        removeRole(oracle, ROLE_ORACLE);
        addRole(_oracle, ROLE_ORACLE);
        oracle = _oracle;
        emit OracleSet(_oracle);
    }

    /// @notice Owner: Withdraw Ether
    function withdrawEther() external onlyOwner {
        owner.transfer(address(this).balance);
    }

}