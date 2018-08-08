pragma solidity ^0.4.19;

// File: contracts/storage/interface/RocketStorageInterface.sol

// Our eternal storage interface
contract RocketStorageInterface {
    // Modifiers
    modifier onlyLatestRocketNetworkContract() {_;}
    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string);
    function getBytes(bytes32 _key) external view returns (bytes);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
    // Setters
    function setAddress(bytes32 _key, address _value) onlyLatestRocketNetworkContract external;
    function setUint(bytes32 _key, uint _value) onlyLatestRocketNetworkContract external;
    function setString(bytes32 _key, string _value) onlyLatestRocketNetworkContract external;
    function setBytes(bytes32 _key, bytes _value) onlyLatestRocketNetworkContract external;
    function setBool(bytes32 _key, bool _value) onlyLatestRocketNetworkContract external;
    function setInt(bytes32 _key, int _value) onlyLatestRocketNetworkContract external;
    // Deleters
    function deleteAddress(bytes32 _key) onlyLatestRocketNetworkContract external;
    function deleteUint(bytes32 _key) onlyLatestRocketNetworkContract external;
    function deleteString(bytes32 _key) onlyLatestRocketNetworkContract external;
    function deleteBytes(bytes32 _key) onlyLatestRocketNetworkContract external;
    function deleteBool(bytes32 _key) onlyLatestRocketNetworkContract external;
    function deleteInt(bytes32 _key) onlyLatestRocketNetworkContract external;
    // Hash helpers
    function kcck256str(string _key1) external pure returns (bytes32);
    function kcck256strstr(string _key1, string _key2) external pure returns (bytes32);
    function kcck256stradd(string _key1, address _key2) external pure returns (bytes32);
    function kcck256straddadd(string _key1, address _key2, address _key3) external pure returns (bytes32);
}

// File: contracts/storage/RocketBase.sol

/// @title Base settings / modifiers for each contract in Rocket Pool
/// @author David Rugendyke
contract RocketBase {

    /*** Events ****************/

    event ContractAdded (
        address indexed _newContractAddress,                    // Address of the new contract
        uint256 created                                         // Creation timestamp
    );

    event ContractUpgraded (
        address indexed _oldContractAddress,                    // Address of the contract being upgraded
        address indexed _newContractAddress,                    // Address of the new contract
        uint256 created                                         // Creation timestamp
    );

    /**** Properties ************/

    uint8 public version;                                                   // Version of this contract


    /*** Contracts **************/

    RocketStorageInterface rocketStorage = RocketStorageInterface(0);       // The main storage contract where primary persistant storage is maintained


    /*** Modifiers ************/

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        roleCheck("owner", msg.sender);
        _;
    }

    /**
    * @dev Modifier to scope access to admins
    */
    modifier onlyAdmin() {
        roleCheck("admin", msg.sender);
        _;
    }

    /**
    * @dev Modifier to scope access to admins
    */
    modifier onlySuperUser() {
        require(roleHas("owner", msg.sender) || roleHas("admin", msg.sender));
        _;
    }

    /**
    * @dev Reverts if the address doesn&#39;t have this role
    */
    modifier onlyRole(string _role) {
        roleCheck(_role, msg.sender);
        _;
    }

  
    /*** Constructor **********/
   
    /// @dev Set the main Rocket Storage address
    constructor(address _rocketStorageAddress) public {
        // Update the contract address
        rocketStorage = RocketStorageInterface(_rocketStorageAddress);
    }


    /*** Role Utilities */

    /**
    * @dev Check if an address is an owner
    * @return bool
    */
    function isOwner(address _address) public view returns (bool) {
        return rocketStorage.getBool(keccak256("access.role", "owner", _address));
    }

    /**
    * @dev Check if an address has this role
    * @return bool
    */
    function roleHas(string _role, address _address) internal view returns (bool) {
        return rocketStorage.getBool(keccak256("access.role", _role, _address));
    }

     /**
    * @dev Check if an address has this role, reverts if it doesn&#39;t
    */
    function roleCheck(string _role, address _address) view internal {
        require(roleHas(_role, _address) == true);
    }

}

// File: contracts/Authorized.sol

/**
 * @title Authorized
 * @dev The Authorized contract has an issuer, depository, and auditor address, and provides basic 
 * authorization control functions, this simplifies the implementation of "user permissions".
 */
contract Authorized is RocketBase {

    // The issuer&#39;s address
    // In contract&#39;s RocketStorage 
    // address public token.issuer;

    // The depository&#39;s address
    // In contract&#39;s RocketStorage 
    // address public token.depository;

    // The auditor&#39;s address
    // In contract&#39;s RocketStorage 
    // address public token.auditor;

    event IssuerTransferred(address indexed previousIssuer, address indexed newIssuer);
    event AuditorTransferred(address indexed previousAuditor, address indexed newAuditor);
    event DepositoryTransferred(address indexed previousDepository, address indexed newDepository);

    /* 
     *  Modifiers
     */

    // Ensure sender is issuer   
    modifier onlyIssuer {
        require( msg.sender == issuer() );
        _;
    }

    // Ensure sender is depository
    modifier onlyDepository {
        require( msg.sender == depository() );
        _;
    }

    // Ensure sender is auditor
    modifier onlyAuditor {
        require( msg.sender == auditor() );
        _;
    }


  /**
   * @dev Allows the current owner to explicity assign a new issuer.
   * @param newIssuer The address of the new issuer.
   */
  function setIssuer(address newIssuer) public onlyOwner {
    require(newIssuer != address(0));
    rocketStorage.setAddress(keccak256("token.issuer"), newIssuer);
    emit IssuerTransferred(issuer(), newIssuer);
  }

  /**
   * @dev Get the current issuer address from storage.
   */
  function issuer() public view returns (address) {
    return rocketStorage.getAddress(keccak256("token.issuer"));
  }

  /**
   * @dev Allows the current owner to explicity assign a new auditor.
   * @param newAuditor The address of the new auditor.
   */
  function setAuditor(address newAuditor) public onlyOwner {
    require(newAuditor != address(0));
    rocketStorage.setAddress(keccak256("token.auditor"), newAuditor);
    emit AuditorTransferred(auditor(), newAuditor);
  }

  /**
   * @dev Get the current auditor address from storage.
   */
  function auditor() public view returns (address) {
    return rocketStorage.getAddress(keccak256("token.auditor"));
  }

  /**
   * @dev Allows the current owner to explicity assign a new depository.
   * @param newDepository The address of the new depository.
   */
  function setDepository(address newDepository) public onlyOwner {
    require(newDepository != address(0));
    rocketStorage.setAddress(keccak256("token.depository"), newDepository);
    emit DepositoryTransferred(depository(), newDepository);
  }

  /**
   * @dev Get the current depository address from storage.
   */
  function depository() public view returns (address) {
    return rocketStorage.getAddress(keccak256("token.depository"));
  }

}

// File: contracts/Delegated.sol

/**
 * @title Delegated
 * @dev The Delegated contract allows the issuer, depository, and auditor the ability to 
 * delegate certain tasks to other signers, providing authorization control functions,
 * this further simplifies the implementation of "user permissions".
 */
contract Delegated is Authorized {

    // The issuer delegate&#39;s address 
    // In contract&#39;s RocketStorage 
    // address public token.issuerDelegate;

    // The depository delegate&#39;s address
    // In contract&#39;s RocketStorage 
    // address public token.depositoryDelegate;

    // The auditor delegate&#39;s address
    // In contract&#39;s RocketStorage 
    // address public token.auditorDelegate;

    event IssuerDelegated(address indexed previousDelegate, address indexed newDelegate);
    event AuditorDelegated(address indexed previousDelegate, address indexed newDelegate);
    event DepositoryDelegated(address indexed previousDelegate, address indexed newDelegate);

    /* 
     *  Modifiers
     */

    // Ensure sender is issuer delegate
    modifier onlyIssuerDelegate {
        require( msg.sender == issuerDelegate() );
        _;
    }

    // Ensure sender is depository delegate
    modifier onlyDepositoryDelegate {
        require( msg.sender == depositoryDelegate() );
        _;
    }

    // Ensure sender is auditor delegate 
    modifier onlyAuditorDelegate {
        require( msg.sender == auditorDelegate() );
        _;
    }


  /**
   * @dev Allows the current issuer to assign a new delegate.
   * @param newDelegate The address of the new delegate.
   */
  function setIssuerDelegate(address newDelegate) public onlyIssuer {
    require(newDelegate != address(0));
    address oldDelegate_ = issuerDelegate();
    rocketStorage.setAddress(keccak256("token.issuerDelegate"), newDelegate);
    emit IssuerDelegated(oldDelegate_, newDelegate);
  }

  /**
   * @dev Get the current issuer delegate address from storage.
   */
  function issuerDelegate() public view returns (address) {
    return rocketStorage.getAddress(keccak256("token.issuerDelegate"));
  }

  /**
   * @dev Allows the current auditor to assign a new delegate.
   * @param newDelegate The address of the new delegate.
   */
  function setAuditorDelegate(address newDelegate) public onlyAuditor {
    require(newDelegate != address(0));
    address oldDelegate_ = auditorDelegate();
    rocketStorage.setAddress(keccak256("token.auditorDelegate"), newDelegate);
    emit AuditorDelegated(oldDelegate_, newDelegate);
  }

  /**
   * @dev Get the current auditor delegate address from storage.
   */
  function auditorDelegate() public view returns (address) {
    return rocketStorage.getAddress(keccak256("token.auditorDelegate"));
  }

  /**
   * @dev Allows the current depository to assign a new delegate.
   * @param newDelegate The address of the new delegate.
   */
  function setDepositoryDelegate(address newDelegate) public onlyDepository {
    require(newDelegate != address(0));
    address oldDelegate_ = depositoryDelegate();
    rocketStorage.setAddress(keccak256("token.depositoryDelegate"), newDelegate);
    emit DepositoryDelegated(oldDelegate_, newDelegate);
  }

  /**
   * @dev Get the current depository delegate address from storage.
   */
  function depositoryDelegate() public view returns (address) {
    return rocketStorage.getAddress(keccak256("token.depositoryDelegate"));
  }

}

// File: contracts/PausableRedemption.sol

/**
 * @title PausableRedemption
 * @dev Base contract which allows children to implement an emergency stop mechanism, specifically for redemption.
 */
contract PausableRedemption is RocketBase {
  event PauseRedemption();
  event UnpauseRedemption();

  // Whether redemption is paused or not
  // Stored in RocketStorage
  // bool public token.redemptionPaused = false;

  /**
   * @dev Modifier to make a function callable only when the contract redemption is not paused.
   */
  modifier whenRedemptionNotPaused() {
    require(!redemptionPaused());
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract redemption is paused.
   */
  modifier whenRedemptionPaused() {
    require(redemptionPaused());
    _;
  }

  /**
   * @dev returns the redemptionPaused status from contract storage
   */
  function redemptionPaused() public view returns (bool) {
    return rocketStorage.getBool(keccak256("token.redemptionPaused"));
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pauseRedemption() onlyOwner whenRedemptionNotPaused public {
    rocketStorage.setBool(keccak256("token.redemptionPaused"), true);
    emit PauseRedemption();
  }

  /**
   * @dev called by the owner to unpause redemption, returns to normal state
   */
  function unpauseRedemption() onlyOwner whenRedemptionPaused public {
    rocketStorage.setBool(keccak256("token.redemptionPaused"), false);
    emit UnpauseRedemption();
  }
}

// File: zeppelin-solidity/contracts/ECRecovery.sol

/**
 * @title Eliptic curve signature operations
 *
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 */

library ECRecovery {

  /**
   * @dev Recover signer address from a message by using his signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    //Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }

}

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
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

// File: contracts/Redeemable.sol

/**
 * @title Redeemable
 * @author Steven Brendtro <steven.brendtro@gmail.com>
 * @dev The Redeemable contract allows for tokens to be redeemed from depository
 */
contract Redeemable is RocketBase, PausableRedemption, Delegated {

    using SafeMath for uint256;


    // The Redeem event
    event Redemption(address indexed from, bytes32 indexed hash, uint amount);

    // The maximum allowed for any single redemption, in tokens
    uint public maxRedemption = 100000000000000000000;
    
    constructor(address _rocketStorageAddress) RocketBase(_rocketStorageAddress) public {
    }

    // Allow anyone with valid prior authorization to redeem tokens  
    function redeem(uint _amount, bytes32 _hash, bytes _sig) public whenRedemptionNotPaused {
        // Redemption hashes can only be used once
        require(! checkRedemptionFulfilled(_hash));

        // Verify Redemption hash, signed by the depository OR the depository&#39;s delegate
        require(ecverify(_hash, _sig, depository()) || ecverify(_hash, _sig, depositoryDelegate()));

        // Redeem the tokens
        _redeem(_amount);

        // Mark the redemption hash as used, preventing later reuse
        _markRedemptionFulfilled(_hash);

        emit Redemption(msg.sender, _hash, _amount);
    }

    // Allow the issuer to complete a redemption without prior authorization from the depository
    // This redeems directly from the issuer&#39;s wallet
    function backofficeRedeem(uint _amount) public onlyIssuer {
        // Redeem the tokens
        _redeem(_amount);

        // Send event, but without a hash
        //emit Redemption(msg.sender, bytes32(""), _amount);
    }

    // The internal functionality for redeem
    function _redeem(uint _amount) internal {
        // Each redemption is limited in size, though multiple redemptions are allowed.
        require(_amount <= maxRedemption);

        // Get Token Details
        uint8 decimals_ = decimals();
        uint256 totalSupply_ = totalSupply();
        uint256 assetsOnDeposit_ = assetsOnDeposit();
        uint256 assetsCertified_ = assetsCertified();

        // Redemption is only allowed in whole tokens
        require( ( _amount % pow(10, decimals_) ) == 0);
        require( (_amount.div(pow(10, decimals_)) >= 1));

        // Get Balance
        uint256 senderBalance_ = balanceOf(msg.sender);

        // msg.sender must have _amount available in token balance
        require(_amount <= senderBalance_);

        // Just to be safe, _amount can&#39;t be more than totalSupply_, assetsOnDeposit_, and assetsCertified_
        // This condition should never happen, but redeeming this much is physically impossible, so we protect against it
        require(_amount <= totalSupply_);
        require(_amount <= assetsOnDeposit_);
        require( _amount <= assetsCertified_);


        //   - decrease totalSupply_
        rocketStorage.setUint(keccak256("token.totalSupply"), totalSupply_.sub(_amount));
        //   - decrease assetsOnDeposit_
        rocketStorage.setUint(keccak256("issuable.assetsOnDeposit"), assetsOnDeposit_.sub(_amount));
        //   - decrease assetsCertified_
        rocketStorage.setUint(keccak256("issuable.assetsCertified"), assetsCertified_.sub(_amount));
        
        //   - burn token(s) (the ONLY place this should happen)
        setBalanceOf(msg.sender, balanceOf(msg.sender).sub(_amount));
        //     - NOTE: We COULD burn them by sending to the zero address, but for more correct accounting, they simply
        //       are removed from the ledger.  The following is commented to show the INTENT of what is happening here
        // setBalanceOf(address(0), balanceOf(address(0)).add(_amount));
       

    }

    // Set the max redemption in wei (decimal) equivalent
    function setMaxRedemption( uint _amount ) public onlyDepository {
        maxRedemption = _amount;
    }

    // Mark the redemption hash as fulfilled/used to prevent reuse (internal)
    function _markRedemptionFulfilled(bytes32 _hash) internal {
      rocketStorage.setBool(keccak256("token.redemptionFulfilled",_hash), true);
    }

    // Mark the redemption hash as fulfilled/used to prevent reuse (Depository)
    // This function is available should the need arise to invalidate a previously
    // signed hash.  For instance, someone &#39;lost&#39; their hash before calling redeem()
    // Depository issues a second hash, and invalidates the first, preventing them
    // from calling redeem() twice for the same order.
    function markRedemptionFulfilled(bytes32 _hash) public onlyDepository {
      _markRedemptionFulfilled(_hash);
    }

    function checkRedemptionFulfilled(bytes32 _hash) public view returns (bool) {
      return rocketStorage.getBool(keccak256("token.redemptionFulfilled",_hash));
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
      return rocketStorage.getUint(keccak256("token.balances",_owner));
    }

    /**
    * @dev Updates the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @param _balance An uint256 representing the amount owned by the passed address.
    */
    function setBalanceOf(address _owner, uint256 _balance) internal {
      rocketStorage.setUint(keccak256("token.balances",_owner), _balance);
    }

    function ecverify(bytes32 hash_, bytes sig_, address signer_) public pure returns (bool) {
      return (ECRecovery.recover(hash_, sig_) == signer_);
    }

    /**
    * @dev Calculates the power of the nubmr
    */
    function pow(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a ** b;
      assert(c >= a);
      return c;
    }

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
      return rocketStorage.getUint(keccak256("token.totalSupply"));
    }

    /**
    * @dev total number of tokens in the valut, per the depository record
    */
    function assetsOnDeposit() public view returns (uint256) {
        return rocketStorage.getUint(keccak256("issuable.assetsOnDeposit"));
    }

    /**
    * @dev total number of tokens certified in vault by auditor
    */
    function assetsCertified() public view returns (uint256) {
        return rocketStorage.getUint(keccak256("issuable.assetsCertified"));
    }

    function decimals() public view returns (uint8) {
      return uint8(rocketStorage.getUint(keccak256("token.decimals")));
    }


}