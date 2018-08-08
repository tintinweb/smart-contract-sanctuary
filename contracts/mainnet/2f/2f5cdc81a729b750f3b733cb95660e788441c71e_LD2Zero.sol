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

// File: contracts/Issuable.sol

contract Issuable is RocketBase, Authorized, PausableRedemption {
    using SafeMath for uint256;

    event AssetsUpdated(address indexed depository, uint256 amount);
    event CertificationUpdated(address indexed auditor, uint256 amount);

    // Get assetsOnDeposit
    function assetsOnDeposit() public view returns (uint256) {
        return rocketStorage.getUint(keccak256("issuable.assetsOnDeposit"));
    }

    // Get assetsCertified
    function assetsCertified() public view returns (uint256) {
        return rocketStorage.getUint(keccak256("issuable.assetsCertified"));
    }

    /******* For paused redemption *******/

    // Set assetsOnDeposit
    function setAssetsOnDeposit(uint256 _total) public onlyDepository whenRedemptionPaused {
        uint256 totalSupply_ = rocketStorage.getUint(keccak256("token.totalSupply"));
        require(_total >= totalSupply_);
        rocketStorage.setUint(keccak256("issuable.assetsOnDeposit"), _total);
        emit AssetsUpdated(msg.sender, _total);
    }

    // Set assetsCertified
    function setAssetsCertified(uint256 _total) public onlyAuditor whenRedemptionPaused {
        uint256 totalSupply_ = rocketStorage.getUint(keccak256("token.totalSupply"));
        require(_total >= totalSupply_);
        rocketStorage.setUint(keccak256("issuable.assetsCertified"), _total);
        emit CertificationUpdated(msg.sender, _total);
    }

    /******* For during both paused and non-paused redemption *******/

    // Depository can receive assets (increasing)
    function receiveAssets(uint256 _units) public onlyDepository {
        uint256 total_ = assetsOnDeposit().add(_units);
        rocketStorage.setUint(keccak256("issuable.assetsOnDeposit"), total_);
        emit AssetsUpdated(msg.sender, total_);
    }

    // Depository can release assets (decreasing), but never to less than the totalSupply
    function releaseAssets(uint256 _units) public onlyDepository {
        uint256 totalSupply_ = rocketStorage.getUint(keccak256("token.totalSupply"));
        uint256 total_ = assetsOnDeposit().sub(_units);
        require(total_ >= totalSupply_);
        rocketStorage.setUint(keccak256("issuable.assetsOnDeposit"), total_);
        emit AssetsUpdated(msg.sender, total_);
    }

    // Auditor can increase certified assets
    function increaseAssetsCertified(uint256 _units) public onlyAuditor {
        uint256 total_ = assetsCertified().add(_units);
        rocketStorage.setUint(keccak256("issuable.assetsCertified"), total_);
        emit CertificationUpdated(msg.sender, total_);
    }

    // Auditor can decrease certified assets
    function decreaseAssetsCertified(uint256 _units) public onlyAuditor {
        uint256 totalSupply_ = rocketStorage.getUint(keccak256("token.totalSupply"));
        uint256 total_ = assetsCertified().sub(_units);
        require(total_ >= totalSupply_);
        rocketStorage.setUint(keccak256("issuable.assetsCertified"), total_);
        emit CertificationUpdated(msg.sender, total_);
    }

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

// File: contracts/LD2Token.sol

/// @title The primary ERC20 token contract, using LD2 storage
/// @author Steven Brendtro
contract LD2Token is ERC20, RocketBase, Issuable {
  using SafeMath for uint256;

  event TokensIssued(address indexed issuer, uint256 amount);

  // The balances of the token, per ERC20, but stored in contract storage (rocketStorage)
  // mapping(address => uint256) token.balances;

  // The totalSupply of the token, per ERC20, but stored in contract storage (rocketStorage)
  // uint256 token.totalSupply;

  // The authorizations of the token, per ERC20, but stored in contract storage (rocketStorage)
  // This is accomplished by hashing token.allowed + _fromAddr + _toAddr
  // mapping (address => mapping (address => uint256)) internal allowed;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return rocketStorage.getUint(keccak256("token.totalSupply"));
  }

  /**
  * @dev increase total number of tokens in existence
  */
  function increaseTotalSupply(uint256 _increase) internal {
    uint256 totalSupply_ = totalSupply();
    totalSupply_ = totalSupply_.add(_increase);
    rocketStorage.setUint(keccak256("token.totalSupply"),totalSupply_);
  }

  /**
  * @dev decrease total number of tokens in existence
  */
  function decreaseTotalSupply(uint256 _decrease) internal {
    uint256 totalSupply_ = totalSupply();
    totalSupply_ = totalSupply_.sub(_decrease);
    rocketStorage.setUint(keccak256("token.totalSupply"),totalSupply_);
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balanceOf(msg.sender));

    // SafeMath.sub will throw if there is not enough balance.
    // Use the contract storage
    setBalanceOf(msg.sender, balanceOf(msg.sender).sub(_value));
    setBalanceOf(_to, balanceOf(_to).add(_value));
    emit Transfer(msg.sender, _to, _value);
    return true;
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

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return rocketStorage.getUint(keccak256("token.allowed",_owner,_spender));
  }

  /**
  * @dev Updates the allowance by _owner of the _spender to have access to _balance.
  * @param _owner The address to query the the balance of.
  * @param _spender The address which will spend the funds
  * @param _balance An uint256 representing the amount owned by the passed address.
  */
  function setAllowance(address _owner, address _spender, uint256 _balance) internal {
    rocketStorage.setUint(keccak256("token.allowed",_owner,_spender), _balance);
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balanceOf(_from));
    require(_value <= allowance(_from, msg.sender));
    
    setBalanceOf(_from, balanceOf(_from).sub(_value));
    setBalanceOf(_to, balanceOf(_to).add(_value));
    setAllowance(_from, msg.sender, allowance(_from, msg.sender).sub(_value));
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
    setAllowance(msg.sender, _spender, _value);
    emit Approval(msg.sender, _spender, _value);
    return true;
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
    setAllowance(msg.sender, _spender, allowance(msg.sender, _spender).add(_addedValue));
    emit Approval(msg.sender, _spender, allowance(msg.sender, _spender));
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
    uint oldValue = allowance(msg.sender, _spender);
    if (_subtractedValue > oldValue) {
      setAllowance(msg.sender, _spender, 0);
    } else {
      setAllowance(msg.sender, _spender, oldValue.sub(_subtractedValue));
    }
    emit Approval(msg.sender, _spender, allowance(msg.sender, _spender));
    return true;
  }


  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * Issuer can only issue tokens up to the lesser of assetsOnDeposit and
   * assetsCertified.  This prevents issuing uncertified tokens and ensures
   * that every token issued has exactly one unit of the asset backing it.
   * @param _units Total amount of additional tokens to issue
   */
  function issueTokensForAssets( uint256 _units ) public onlyIssuer {

    uint256 newSupply_ = totalSupply().add(_units);

    // Find the greater of assetsOnDeposit and assetsCertified
    uint256 limit_ = 0;
    if ( assetsOnDeposit() > assetsCertified() )
      limit_ = assetsOnDeposit();
    else
      limit_ = assetsCertified();

    // the new supply can&#39;t be larger than our issuance limit
    require( newSupply_ <= limit_ );

    // Increase the total supply
    increaseTotalSupply( _units );

    // Increase the issuer&#39;s balance
    setBalanceOf(issuer(), balanceOf(issuer()).add(_units));

    emit TokensIssued(issuer(), _units);
  }

}

// File: contracts/LD2Zero.sol

/// @title The LD2-style ERC20 token for LD2.zero
/// @author Steven Brendtro
contract LD2Zero is LD2Token {

  string public name = "LD2.zero";
  string public symbol = "XLDZ";
  // Decimals are stored in RocketStorage
  // uint8 public token.decimals = 18;

  /*** Constructor ***********/

  /// @dev LD2Zero constructor
  constructor(address _rocketStorageAddress) RocketBase(_rocketStorageAddress) public {
    // Set the decimals
    if(decimals() == 0) {
      rocketStorage.setUint(keccak256("token.decimals"),18);
    }
  }

  function decimals() public view returns (uint8) {
    return uint8(rocketStorage.getUint(keccak256("token.decimals")));
  }

}