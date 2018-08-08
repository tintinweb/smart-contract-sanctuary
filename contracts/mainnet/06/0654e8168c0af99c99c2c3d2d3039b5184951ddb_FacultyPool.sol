pragma solidity 0.4.24;

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

contract ERC20 {
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
}


// Contract Code for Faculty - Faculty Devs
contract FacultyPool is RBACWithAdmin {

    using SafeMath for uint;

    // Constants
    // ========================================================
    uint8 constant CONTRACT_OPEN = 1;
    uint8 constant CONTRACT_CLOSED = 2;
    uint8 constant CONTRACT_SUBMIT_FUNDS = 3;
    // 500,000 max gas
    uint256 constant public gasLimit = 50000000000;
    // 0.1 ether
    uint256 constant public minContribution = 100000000000000000;

    // State Vars
    // ========================================================
    // recipient address for fee
    address public owner;
    // the fee taken in tokens from the pool
    uint256 public feePct;
    // open our contract initially
    uint8 public contractStage = CONTRACT_OPEN;
    // the current Beneficiary Cap level in wei
    uint256 public currentBeneficiaryCap;
    // the total cap in wei of the pool
    uint256 public totalPoolCap;
    // the destination for this contract
    address public receiverAddress;
    // our beneficiaries
    mapping (address => Beneficiary) beneficiaries;
    // the total we raised before closing pool
    uint256 public finalBalance;
    // a set of refund amounts we may need to process
    uint256[] public ethRefundAmount;
    // mapping that holds the token allocation struct for each token address
    mapping (address => TokenAllocation) tokenAllocationMap;
    // the default token address
    address public defaultToken;


    // Modifiers and Structs
    // ========================================================
    // only run certain methods when contract is open
    modifier isOpenContract() {
        require (contractStage == CONTRACT_OPEN);
        _;
    }

    // stop double processing attacks
    bool locked;
    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    // Beneficiary
    struct Beneficiary {
        uint256 ethRefund;
        uint256 balance;
        uint256 cap;
        mapping (address => uint256) tokensClaimed;
    }

    // data structure for holding information related to token withdrawals.
    struct TokenAllocation {
        ERC20 token;
        uint256[] pct;
        uint256 balanceRemaining;
    }

    // Events
    // ========================================================
    event BeneficiaryBalanceChanged(address indexed beneficiary, uint256 totalBalance);
    event ReceiverAddressSet(address indexed receiverAddress);
    event ERC223Received(address indexed token, uint256 value);
    event DepositReceived(address indexed beneficiary, uint256 amount, uint256 gas, uint256 gasprice, uint256 gasLimit);
    event PoolStageChanged(uint8 stage);
    event PoolSubmitted(address indexed receiver, uint256 amount);
    event RefundReceived(address indexed sender, uint256 amount);
    event TokenWithdrawal(address indexed beneficiary, address indexed token, uint256 amount);
    event EthRefunded(address indexed beneficiary, uint256 amount);

    // CODE BELOW HERE
    // ========================================================

    /*
     * Construct a pool with a set of admins, the poolCap and the cap each beneficiary gets. And,
     * optionally, the receiving address if know at time of contract creation.
     * fee is in bips so 3.5% would be set as 350 and 100% == 100*100 => 10000
     */
    constructor(address[] _admins, uint256 _poolCap, uint256 _beneficiaryCap, address _receiverAddr, uint256 _feePct) public {
        require(_admins.length > 0, "Must have at least one admin apart from msg.sender");
        require(_poolCap >= _beneficiaryCap, "Cannot have the poolCap <= beneficiaryCap");
        require(_feePct >=  0 && _feePct < 10000);
        feePct = _feePct;
        receiverAddress = _receiverAddr;
        totalPoolCap = _poolCap;
        currentBeneficiaryCap = _beneficiaryCap;
        // setup privileges
        owner = msg.sender;
        addRole(msg.sender, ROLE_ADMIN);
        for (uint8 i = 0; i < _admins.length; i++) {
            addRole(_admins[i], ROLE_ADMIN);
        }
    }

    // we pay in here
    function () payable public {
        if (contractStage == CONTRACT_OPEN) {
            emit DepositReceived(msg.sender, msg.value, gasleft(), tx.gasprice, gasLimit);
            _receiveDeposit();
        } else {
            _receiveRefund();
        }
    }

    // receive funds. gas limited. min contrib.
    function _receiveDeposit() isOpenContract internal {
        require(tx.gasprice <= gasLimit, "Gas too high");
        require(address(this).balance <= totalPoolCap, "Deposit will put pool over limit. Reverting.");
        // Now the code
        Beneficiary storage b = beneficiaries[msg.sender];
        uint256 newBalance = b.balance.add(msg.value);
        require(newBalance >= minContribution, "contribution is lower than minContribution");
        if(b.cap > 0){
            require(newBalance <= b.cap, "balance is less than set cap for beneficiary");
        } else if(currentBeneficiaryCap == 0) {
            // we have an open cap, no limits
            b.cap = totalPoolCap;
        }else {
            require(newBalance <= currentBeneficiaryCap, "balance is more than currentBeneficiaryCap");
            // we set it to the default cap
            b.cap = currentBeneficiaryCap;
        }
        b.balance = newBalance;
        emit BeneficiaryBalanceChanged(msg.sender, newBalance);
    }

    // Handle refunds only in closed state.
    function _receiveRefund() internal {
        assert(contractStage >= 2);
        require(hasRole(msg.sender, ROLE_ADMIN) || msg.sender == receiverAddress, "Receiver or Admins only");
        ethRefundAmount.push(msg.value);
        emit RefundReceived(msg.sender, msg.value);
    }

    function getCurrentBeneficiaryCap() public view returns(uint256 cap) {
        return currentBeneficiaryCap;
    }

    function getPoolDetails() public view returns(uint256 total, uint256 currentBalance, uint256 remaining) {
        remaining = totalPoolCap.sub(address(this).balance);
        return (totalPoolCap, address(this).balance, remaining);
    }

    // close the pool from receiving more funds
    function closePool() onlyAdmin isOpenContract public {
        contractStage = CONTRACT_CLOSED;
        emit PoolStageChanged(contractStage);
    }

    function submitPool(uint256 weiAmount) public onlyAdmin noReentrancy {
        require(contractStage < CONTRACT_SUBMIT_FUNDS, "Cannot resubmit pool.");
        require(receiverAddress != 0x00, "receiver address cannot be empty");
        uint256 contractBalance = address(this).balance;
        if(weiAmount == 0){
            weiAmount = contractBalance;
        }
        require(minContribution <= weiAmount && weiAmount <= contractBalance, "submitted amount too small or larger than the balance");
        finalBalance = contractBalance;
        // transfer to upstream receiverAddress
        require(receiverAddress.call.value(weiAmount)
            .gas(gasleft().sub(5000))(),
            "Error submitting pool to receivingAddress");
        // get balance post transfer
        contractBalance = address(this).balance;
        if(contractBalance > 0) {
            ethRefundAmount.push(contractBalance);
        }
        contractStage = CONTRACT_SUBMIT_FUNDS;
        emit PoolSubmitted(receiverAddress, weiAmount);
    }

    function viewBeneficiaryDetails(address beneficiary) public view returns (uint256 cap, uint256 balance, uint256 remaining, uint256 ethRefund){
        Beneficiary storage b = beneficiaries[beneficiary];
        return (b.cap, b.balance, b.cap.sub(b.balance), b.ethRefund);
    }

    function withdraw(address _tokenAddress) public {
        Beneficiary storage b = beneficiaries[msg.sender];
        require(b.balance > 0, "msg.sender has no balance. Nice Try!");
        if(contractStage == CONTRACT_OPEN){
            uint256 transferAmt = b.balance;
            b.balance = 0;
            msg.sender.transfer(transferAmt);
            emit BeneficiaryBalanceChanged(msg.sender, 0);
        } else {
            _withdraw(msg.sender, _tokenAddress);
        }
    }

    // This function allows the contract owner to force a withdrawal to any contributor.
    function withdrawFor (address _beneficiary, address tokenAddr) public onlyAdmin {
        require (contractStage == CONTRACT_SUBMIT_FUNDS, "Can only be done on Submitted Contract");
        require (beneficiaries[_beneficiary].balance > 0, "Beneficary has no funds to withdraw");
        _withdraw(_beneficiary, tokenAddr);
    }

    function _withdraw (address _beneficiary, address _tokenAddr) internal {
        require(contractStage == CONTRACT_SUBMIT_FUNDS, "Cannot withdraw when contract is not CONTRACT_SUBMIT_FUNDS");
        Beneficiary storage b = beneficiaries[_beneficiary];
        if (_tokenAddr == 0x00) {
            _tokenAddr = defaultToken;
        }
        TokenAllocation storage ta = tokenAllocationMap[_tokenAddr];
        require ( (ethRefundAmount.length > b.ethRefund) || ta.pct.length > b.tokensClaimed[_tokenAddr] );

        if (ethRefundAmount.length > b.ethRefund) {
            uint256 pct = _toPct(b.balance,finalBalance);
            uint256 ethAmount = 0;
            for (uint i= b.ethRefund; i < ethRefundAmount.length; i++) {
                ethAmount = ethAmount.add(_applyPct(ethRefundAmount[i],pct));
            }
            b.ethRefund = ethRefundAmount.length;
            if (ethAmount > 0) {
                _beneficiary.transfer(ethAmount);
                emit EthRefunded(_beneficiary, ethAmount);
            }
        }
        if (ta.pct.length > b.tokensClaimed[_tokenAddr]) {
            uint tokenAmount = 0;
            for (i= b.tokensClaimed[_tokenAddr]; i< ta.pct.length; i++) {
                tokenAmount = tokenAmount.add(_applyPct(b.balance, ta.pct[i]));
            }
            b.tokensClaimed[_tokenAddr] = ta.pct.length;
            if (tokenAmount > 0) {
                require(ta.token.transfer(_beneficiary,tokenAmount));
                ta.balanceRemaining = ta.balanceRemaining.sub(tokenAmount);
                emit TokenWithdrawal(_beneficiary, _tokenAddr, tokenAmount);
            }
        }
    }

    function setReceiver(address addr) public onlyAdmin {
        require (contractStage < CONTRACT_SUBMIT_FUNDS);
        receiverAddress = addr;
        emit ReceiverAddressSet(addr);
    }

    // once we have tokens we can enable the withdrawal
    // setting this _useAsDefault to true will set this incoming address to the defaultToken.
    function enableTokenWithdrawals (address _tokenAddr, bool _useAsDefault) public onlyAdmin noReentrancy {
        require (contractStage == CONTRACT_SUBMIT_FUNDS, "wrong contract stage");
        if (_useAsDefault) {
            defaultToken = _tokenAddr;
        } else {
            require (defaultToken != 0x00, "defaultToken must be set");
        }
        TokenAllocation storage ta  = tokenAllocationMap[_tokenAddr];
        if (ta.pct.length==0){
            ta.token = ERC20(_tokenAddr);
        }
        uint256 amount = ta.token.balanceOf(this).sub(ta.balanceRemaining);
        require (amount > 0);
        if (feePct > 0) {
            uint256 feePctFromBips = _toPct(feePct, 10000);
            uint256 feeAmount = _applyPct(amount, feePctFromBips);
            require (ta.token.transfer(owner, feeAmount));
            emit TokenWithdrawal(owner, _tokenAddr, feeAmount);
        }
        amount = ta.token.balanceOf(this).sub(ta.balanceRemaining);
        ta.balanceRemaining = ta.token.balanceOf(this);
        ta.pct.push(_toPct(amount,finalBalance));
    }

    // get the available tokens
    function checkAvailableTokens (address addr, address tokenAddr) view public returns (uint tokenAmount) {
        Beneficiary storage b = beneficiaries[addr];
        TokenAllocation storage ta = tokenAllocationMap[tokenAddr];
        for (uint i = b.tokensClaimed[tokenAddr]; i < ta.pct.length; i++) {
            tokenAmount = tokenAmount.add(_applyPct(b.balance, ta.pct[i]));
        }
        return tokenAmount;
    }

    // This is a standard function required for ERC223 compatibility.
    function tokenFallback (address from, uint value, bytes data) public {
        emit ERC223Received (from, value);
    }

    // returns a value as a % accurate to 20 decimal points
    function _toPct (uint numerator, uint denominator ) internal pure returns (uint) {
        return numerator.mul(10 ** 20) / denominator;
    }

    // returns % of any number, where % given was generated with toPct
    function _applyPct (uint numerator, uint pct) internal pure returns (uint) {
        return numerator.mul(pct) / (10 ** 20);
    }


}