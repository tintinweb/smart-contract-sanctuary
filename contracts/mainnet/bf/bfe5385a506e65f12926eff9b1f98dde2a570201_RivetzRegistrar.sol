pragma solidity ^0.4.24;


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
pragma solidity ^0.4.24;



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
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
pragma solidity ^0.4.24;


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
pragma solidity ^0.4.24;

/**
 * @title Rivetz SPID Registration Contract
 *
 * @dev This is a Registrar-like contract
 *
 */
contract RivetzRegistrar is Ownable {
    using SafeMath for uint256;

    struct SPEntry {
        // Ethereum Address of Registrant - may use a multi-sig wallet-contract and can assign an admin
        address registrant;
        // Ethereum address of Administrator - must be an address that can sign arbitrary messages for Registrar authentication
        address admin;
        // Hash of SPID public key that is stored in Registrar
        uint256 pubKeyHash;
        // Hash of Service Provider organization data, etc.
        uint256 infoHash;
        // Expiration date of subscription in UNIX epoch seconds
        uint256  expiration;
        // Flag indicating whether this SPID has been approved by Rivetz for operation (KYC/AML)
        bool    valid;
    }

    // Add an event, so we an find all SPIDs via the log
    event SPCreated(uint256 indexed spid);

    mapping(uint256 => SPEntry) public spEntries;

    // ERC-20 token that will be accepted for payment
    ERC20 public rvt;
    // Address of wallet to which received funds will be sent
    address public paymentWalletAddress;
    // Typed contract instance of the ERC20 token

    // Seconds per year, used in subscription calculations
    uint64 constant secPerYear = 365 days;  /* Sec/Year */

    // Fee in ERC-20 that is charged to register a SPID
    uint256 public registrationFee = 1000 ether;               /* Initial fee (in wei) -- includes 1 year */
    // Annual subscription fee
    uint256 constant defaultAnnualFee = 1000 ether;     /* wei/year */
    // Annual fee as a per-second charge in "wei"
    uint256 public feePerSec = defaultAnnualFee / secPerYear;  /* wei/sec = (wei/year) / (sec/year) */


    /**
      * Constructor
      * @param paymentTokenAddress Address of ERC-20 token that will be accepted for payment
      * @param paymentDestAddress Address wallet to which payments will be sent
      */
    constructor(address paymentTokenAddress, address paymentDestAddress) public {
        rvt = ERC20(paymentTokenAddress);
        paymentWalletAddress = paymentDestAddress;
    }

    /**
     * Register a new SPID
     * Sending address is initial registrant and administrator
     */
    function register(uint256 spid, uint256 pubKeyHash, uint256 infoHash) public {
        require(rvt.transferFrom(msg.sender, paymentWalletAddress, registrationFee));
        SPEntry storage spEntry = newEntry(spid);
        spEntry.registrant = msg.sender;
        spEntry.admin = msg.sender;
        spEntry.pubKeyHash = pubKeyHash;
        spEntry.infoHash = infoHash;
        spEntry.valid = false;
    }

    /**
     * Register a new SPID, sender must be Rivetz
     */
    function rivetzRegister(uint256 spid, uint256 pubKeyHash, uint256 infoHash, address spidRegistrant, address spidAdmin) onlyOwner public {
        SPEntry storage spEntry = newEntry(spid);
        spEntry.registrant = spidRegistrant;
        spEntry.admin = spidAdmin;
        spEntry.pubKeyHash = pubKeyHash;
        spEntry.infoHash = infoHash;
        spEntry.valid = true;
    }

    /**
     * Create a new SP entry for further modification
     */
    function newEntry(uint256 spid) internal returns (SPEntry storage) {
        SPEntry storage spEntry = spEntries[spid];
        require(spEntry.registrant == 0);
        spEntry.expiration = now + secPerYear;
        emit SPCreated(spid);
        return spEntry;
    }

    /**
     * Change registrant, must be existing registrant or Rivetz
     */
    function setRegistrant(uint256 spid, address registrant) public {
        SPEntry storage spEntry = spEntries[spid];
        require(spEntry.registrant != 0 && spEntry.registrant != address(0x1) );
        requireRegistrantOrGreater(spEntry);
        spEntry.registrant = registrant;
    }

    /**
     * Change admin, must be existing registrant or Rivetz
     */
    function setAdmin(uint256 spid, address admin) public {
        SPEntry storage spEntry = spEntries[spid];
        requireRegistrantOrGreater(spEntry);
        spEntry.admin = admin;
    }

    /**
     * Change pubKey, must be existing registrant or Rivetz
     */
    function setPubKey(uint256 spid, uint256 pubKeyHash) public {
        SPEntry storage spEntry = spEntries[spid];
        requireRegistrantOrGreater(spEntry);
        spEntry.pubKeyHash = pubKeyHash;
    }

    /**
     * Change info hash, must be admin, registrant or Rivetz
     */
    function setInfo(uint256 spid, uint256 infoHash) public {
        SPEntry storage spEntry = spEntries[spid];
        requireAdminOrGreater(spEntry);
        spEntry.infoHash = infoHash;
    }

    /**
     * Mark as approved, must be done by Rivetz
     */
    function setValid(uint256 spid, bool valid) onlyOwner public {
        spEntries[spid].valid = valid;
    }

    /**
     * Renew subscription -- can be done by anyone that pays
     */
    function renew(uint256 spid, uint256 payment) public returns (uint256 expiration) {
        SPEntry storage spEntry = spEntries[spid];
        require(rvt.transferFrom(msg.sender, paymentWalletAddress, payment));
        uint256 periodStart = (spEntry.expiration > now) ? spEntry.expiration : now;
        spEntry.expiration = periodStart.add(feeToSeconds(payment));
        return spEntry.expiration;
    }

    /**
     * Set subscription end date -- can only be done by Rivetz
     */
    function setExpiration(uint256 spid, uint256 expiration) onlyOwner public {
        spEntries[spid].expiration = expiration;
    }

    /**
     * Permanently deactivate SPID, must be registrant -- expires subscription, invalidates
     */
    function release(uint256 spid) public {
        SPEntry storage spEntry = spEntries[spid];
        requireRegistrantOrGreater(spEntry);
        spEntry.expiration = 0;
        spEntry.registrant = address(0x1);
        spEntry.admin = address(0x1);
        spEntry.valid = false;
    }

    /**
     * Disable SPID, zeroes out everything -- must be Rivetz
     */
    function rivetzRelease(uint256 spid) onlyOwner public {
        SPEntry storage spEntry = spEntries[spid];
        spEntry.registrant = address(0x1);
        spEntry.admin = address(0x1);
        spEntry.pubKeyHash = 0;
        spEntry.infoHash = 0;
        spEntry.expiration = 0;
        spEntry.valid = false;
    }

    /**
     * Set new registration and annual fees -- must be Rivetz
     */
    function setFees(uint256 newRegistrationFee, uint256 newAnnualFee) onlyOwner public {
        registrationFee = newRegistrationFee;
        feePerSec = newAnnualFee / secPerYear;
    }


    /**
     * RvT is upgradeable, make sure we can update Registrar to use upgraded RvT
     */
    function setToken(address erc20Address) onlyOwner public {
        rvt = ERC20(erc20Address);
    }

    /**
     * Change payment address -- must be Rivetz
     */
    function setPaymentAddress(address paymentAddress) onlyOwner public {
        paymentWalletAddress = paymentAddress;
    }

    /**
     * Permission check - admin or greater
     * SP Registrant or Admin can&#39;t proceed if subscription expired
     */
    function requireAdminOrGreater(SPEntry spEntry) internal view {
        require (msg.sender == spEntry.admin ||
                 msg.sender == spEntry.registrant ||
                 msg.sender == owner);
        require (isSubscribed(spEntry) || msg.sender == owner);
    }

    /**
     * Permission check - registrant or greater
     * SP Registrant or Admin can&#39;t proceed if subscription expired
     */
    function requireRegistrantOrGreater(SPEntry spEntry) internal view  {
        require (msg.sender == spEntry.registrant ||
                 msg.sender == owner);
        require (isSubscribed(spEntry) || msg.sender == owner);
    }

    /**
     * Get annual fee in RvT
     */
    function getAnnualFee() public view returns (uint256) {
        return feePerSec.mul(secPerYear);
    }

    /**
     * @dev Calculates the number of seconds feeAmount would add to expiration date
     * @param feeAmount : Amount of RvT-wei to convert to seconds
     * @return seconds :  Equivalent number of seconds purchased
     */
    function feeToSeconds(uint256 feeAmount) internal view returns (uint256 seconds_)
    {
        return feeAmount / feePerSec;                   /* secs = wei / ( wei/sec)  */
    }

    function isSubscribed(SPEntry spEntry) internal view returns (bool subscribed)
    {
        return now < spEntry.expiration;
    }
}