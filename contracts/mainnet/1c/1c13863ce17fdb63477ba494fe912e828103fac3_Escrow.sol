/**
 *Submitted for verification at Etherscan.io on 2020-05-06
*/

pragma solidity ^0.4.24;

// File: /Users/matthewmcclure/repos/Token-Audit/node_modules/openzeppelin-zos/contracts/token/ERC20/ERC20Basic.sol

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

// File: /Users/matthewmcclure/repos/Token-Audit/node_modules/openzeppelin-zos/contracts/token/ERC20/ERC20.sol

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

// File: /Users/matthewmcclure/repos/Token-Audit/node_modules/openzeppelin-zos/contracts/token/ERC20/SafeERC20.sol

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

// File: /Users/matthewmcclure/repos/Token-Audit/node_modules/zos-lib/contracts/migrations/Migratable.sol

/**
 * @title Migratable
 * Helper contract to support intialization and migration schemes between
 * different implementations of a contract in the context of upgradeability.
 * To use it, replace the constructor with a function that has the
 * `isInitializer` modifier starting with `"0"` as `migrationId`.
 * When you want to apply some migration code during an upgrade, increase
 * the `migrationId`. Or, if the migration code must be applied only after
 * another migration has been already applied, use the `isMigration` modifier.
 * This helper supports multiple inheritance.
 * WARNING: It is the developer's responsibility to ensure that migrations are
 * applied in a correct order, or that they are run at all.
 * See `Initializable` for a simpler version.
 */
contract Migratable {
  /**
   * @dev Emitted when the contract applies a migration.
   * @param contractName Name of the Contract.
   * @param migrationId Identifier of the migration applied.
   */
  event Migrated(string contractName, string migrationId);

  /**
   * @dev Mapping of the already applied migrations.
   * (contractName => (migrationId => bool))
   */
  mapping (string => mapping (string => bool)) internal migrated;

  /**
   * @dev Internal migration id used to specify that a contract has already been initialized.
   */
  string constant private INITIALIZED_ID = "initialized";


  /**
   * @dev Modifier to use in the initialization function of a contract.
   * @param contractName Name of the contract.
   * @param migrationId Identifier of the migration.
   */
  modifier isInitializer(string contractName, string migrationId) {
    validateMigrationIsPending(contractName, INITIALIZED_ID);
    validateMigrationIsPending(contractName, migrationId);
    _;
    emit Migrated(contractName, migrationId);
    migrated[contractName][migrationId] = true;
    migrated[contractName][INITIALIZED_ID] = true;
  }

  /**
   * @dev Modifier to use in the migration of a contract.
   * @param contractName Name of the contract.
   * @param requiredMigrationId Identifier of the previous migration, required
   * to apply new one.
   * @param newMigrationId Identifier of the new migration to be applied.
   */
  modifier isMigration(string contractName, string requiredMigrationId, string newMigrationId) {
    require(isMigrated(contractName, requiredMigrationId), "Prerequisite migration ID has not been run yet");
    validateMigrationIsPending(contractName, newMigrationId);
    _;
    emit Migrated(contractName, newMigrationId);
    migrated[contractName][newMigrationId] = true;
  }

  /**
   * @dev Returns true if the contract migration was applied.
   * @param contractName Name of the contract.
   * @param migrationId Identifier of the migration.
   * @return true if the contract migration was applied, false otherwise.
   */
  function isMigrated(string contractName, string migrationId) public view returns(bool) {
    return migrated[contractName][migrationId];
  }

  /**
   * @dev Initializer that marks the contract as initialized.
   * It is important to run this if you had deployed a previous version of a Migratable contract.
   * For more information see https://github.com/zeppelinos/zos-lib/issues/158.
   */
  function initialize() isInitializer("Migratable", "1.2.1") public {
  }

  /**
   * @dev Reverts if the requested migration was already executed.
   * @param contractName Name of the contract.
   * @param migrationId Identifier of the migration.
   */
  function validateMigrationIsPending(string contractName, string migrationId) private {
    require(!isMigrated(contractName, migrationId), "Requested target migration ID has already been run");
  }
}

// File: /Users/matthewmcclure/repos/Token-Audit/node_modules/openzeppelin-zos/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Migratable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function initialize(address _sender) public isInitializer("Ownable", "1.9.0") {
    owner = _sender;
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

// File: /Users/matthewmcclure/repos/Token-Audit/node_modules/openzeppelin-zos/contracts/math/SafeMath.sol

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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

// File: /Users/matthewmcclure/repos/Token-Audit/contracts/Escrow.sol

/**
 * @title Escrow
 * @dev Escrow contract that works with RNDR token
 * This contract holds tokens while render jobs are being completed
 * and information on token allottment per job
 */
contract Escrow is Migratable, Ownable {
  using SafeERC20 for ERC20;
  using SafeMath for uint256;

  // This is a mapping of job IDs to the number of tokens allotted to the job
  mapping(string => uint256) private jobBalances;
  // This is the address of the render token contract
  address public renderTokenAddress;
  // This is the address with authority to call the disburseJob function
  address public disbursalAddress;

  // Emit new disbursal address when disbursalAddress has been changed
  event DisbursalAddressUpdate(address disbursalAddress);
  // Emit the jobId along with the new balance of the job
  // Used on job creation, additional funding added to jobs, and job disbursal
  // Internal systems for assigning jobs will watch this event to determine balances available
  event JobBalanceUpdate(string _jobId, uint256 _balance);
  // Emit new contract address when renderTokenAddress has been changed
  event RenderTokenAddressUpdate(address renderTokenAddress);

  /**
   * @dev Modifier to check if the message sender can call the disburseJob function
   */
  modifier canDisburse() {
    require(msg.sender == disbursalAddress, "message sender not authorized to disburse funds");
    _;
  }

  /**
   * @dev Initailization
   * @param _owner because this contract uses proxies, owner must be passed in as a param
   * @param _renderTokenAddress see renderTokenAddress
   */
  function initialize (address _owner, address _renderTokenAddress) public isInitializer("Escrow", "0") {
    require(_owner != address(0), "_owner must not be null");
    require(_renderTokenAddress != address(0), "_renderTokenAddress must not be null");
    Ownable.initialize(_owner);
    disbursalAddress = _owner;
    renderTokenAddress = _renderTokenAddress;
  }

  /**
   * @dev Change the address authorized to distribute tokens for completed jobs
   *
   * Because there are no on-chain details to indicate who performed a render, an outside
   * system must call the disburseJob function with the information needed to properly
   * distribute tokens. This function updates the address with the authority to perform distributions
   * @param _newDisbursalAddress see disbursalAddress
   */
  function changeDisbursalAddress(address _newDisbursalAddress) external onlyOwner {
    disbursalAddress = _newDisbursalAddress;

    emit DisbursalAddressUpdate(disbursalAddress);
  }

  /**
   * @dev Change the address allowances will be sent to after job completion
   *
   * Ideally, this will not be used, but is included as a failsafe.
   * RNDR is still in its infancy, and changes may need to be made to this
   * contract and / or the renderToken contract. Including methods to update the
   * addresses allows the contracts to update independently.
   * If the RNDR token contract is ever migrated to another address for
   * either added security or functionality, this will need to be called.
   * @param _newRenderTokenAddress see renderTokenAddress
   */
  function changeRenderTokenAddress(address _newRenderTokenAddress) external onlyOwner {
    require(_newRenderTokenAddress != address(0), "_newRenderTokenAddress must not be null");
    renderTokenAddress = _newRenderTokenAddress;

    emit RenderTokenAddressUpdate(renderTokenAddress);
  }

  /**
   * @dev Send allowances to node(s) that performed a job
   *
   * This can only be called by the disbursalAddress, an accound owned
   * by OTOY, and it provides the number of tokens to send to each node
   * @param _jobId the ID of the job used in the jobBalances mapping
   * @param _recipients the address(es) of the nodes that performed rendering
   * @param _amounts the amount(s) to send to each address. These must be in the same
   * order as the recipient addresses
   */
  function disburseJob(string _jobId, address[] _recipients, uint256[] _amounts) external canDisburse {
    require(jobBalances[_jobId] > 0, "_jobId has no available balance");
    require(_recipients.length == _amounts.length, "_recipients and _amounts must be the same length");

    for(uint256 i = 0; i < _recipients.length; i++) {
      jobBalances[_jobId] = jobBalances[_jobId].sub(_amounts[i]);
      ERC20(renderTokenAddress).safeTransfer(_recipients[i], _amounts[i]);
    }

    emit JobBalanceUpdate(_jobId, jobBalances[_jobId]);
  }

  /**
   * @dev Add RNDR tokens to a job
   *
   * This can only be called by a function on the RNDR token contract
   * @param _jobId the ID of the job used in the jobBalances mapping
   * @param _tokens the number of tokens sent by the artist to fund the job
   */
  function fundJob(string _jobId, uint256 _tokens) external {
    // Jobs can only be created by the address stored in the renderTokenAddress variable
    require(msg.sender == renderTokenAddress, "message sender not authorized");
    jobBalances[_jobId] = jobBalances[_jobId].add(_tokens);

    emit JobBalanceUpdate(_jobId, jobBalances[_jobId]);
  }

  /**
   * @dev See the tokens available for a job
   *
   * @param _jobId the ID used to lookup the job balance
   */
  function jobBalance(string _jobId) external view returns(uint256) {
    return jobBalances[_jobId];
  }

}

// File: /Users/matthewmcclure/repos/Token-Audit/contracts/MigratableERC20.sol

/**
 * @title MigratableERC20
 * @dev This strategy carries out an optional migration of the token balances. This migration is performed and paid for
 * @dev by the token holders. The new token contract starts with no initial supply and no balances. The only way to
 * @dev "mint" the new tokens is for users to "turn in" their old ones. This is done by first approving the amount they
 * @dev want to migrate via `ERC20.approve(newTokenAddress, amountToMigrate)` and then calling a function of the new
 * @dev token called `migrateTokens`. The old tokens are sent to a burn address, and the holder receives an equal amount
 * @dev in the new contract.
 */
contract MigratableERC20 is Migratable {
  using SafeERC20 for ERC20;

  /// Burn address where the old tokens are going to be transferred
  address public constant BURN_ADDRESS = address(0xdead);

  /// Address of the old token contract
  ERC20 public legacyToken;

  /**
   * @dev Initializes the new token contract
   * @param _legacyToken address of the old token contract
   */
  function initialize(address _legacyToken) isInitializer("OptInERC20Migration", "1.9.0") public {
    legacyToken = ERC20(_legacyToken);
  }

  /**
   * @dev Migrates the total balance of the token holder to this token contract
   * @dev This function will burn the old token balance and mint the same balance in the new token contract
   */
  function migrate() public {
    uint256 amount = legacyToken.balanceOf(msg.sender);
    migrateToken(amount);
  }

  /**
   * @dev Migrates the given amount of old-token balance to the new token contract
   * @dev This function will burn a given amount of tokens from the old contract and mint the same amount in the new one
   * @param _amount uint256 representing the amount of tokens to be migrated
   */
  function migrateToken(uint256 _amount) public {
    migrateTokenTo(msg.sender, _amount);
  }

  /**
   * @dev Burns a given amount of the old token contract for a token holder and mints the same amount of
   * @dev new tokens for a given recipient address
   * @param _amount uint256 representing the amount of tokens to be migrated
   * @param _to address the recipient that will receive the new minted tokens
   */
  function migrateTokenTo(address _to, uint256 _amount) public {
    _mintMigratedTokens(_to, _amount);
    legacyToken.safeTransferFrom(msg.sender, BURN_ADDRESS, _amount);
  }

  /**
   * @dev Internal minting function
   * This function must be overwritten by the implementation
   */
  function _mintMigratedTokens(address _to, uint256 _amount) internal;
}

// File: /Users/matthewmcclure/repos/Token-Audit/node_modules/openzeppelin-zos/contracts/token/ERC20/BasicToken.sol

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

// File: /Users/matthewmcclure/repos/Token-Audit/node_modules/openzeppelin-zos/contracts/token/ERC20/StandardToken.sol

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
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
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

// File: contracts/RenderToken.sol

// Escrow constract






/**
 * @title RenderToken
 * @dev ERC20 mintable token
 * The token will be minted by the crowdsale contract only
 */
contract RenderToken is Migratable, MigratableERC20, Ownable, StandardToken {

  string public constant name = "Render Token";
  string public constant symbol = "RNDR";
  uint8 public constant decimals = 18;

  // The address of the contract that manages job balances. Address is used for forwarding tokens
  // that come in to fund jobs
  address public escrowContractAddress;

  // Emit new contract address when escrowContractAddress has been changed
  event EscrowContractAddressUpdate(address escrowContractAddress);
  // Emit information related to tokens being escrowed
  event TokensEscrowed(address indexed sender, string jobId, uint256 amount);
  // Emit information related to legacy tokens being migrated
  event TokenMigration(address indexed receiver, uint256 amount);

  /**
   * @dev Initailization
   * @param _owner because this contract uses proxies, owner must be passed in as a param
   */
  function initialize(address _owner, address _legacyToken) public isInitializer("RenderToken", "0") {
    require(_owner != address(0), "_owner must not be null");
    require(_legacyToken != address(0), "_legacyToken must not be null");
    Ownable.initialize(_owner);
    MigratableERC20.initialize(_legacyToken);
  }

  /**
   * @dev Take tokens prior to beginning a job
   *
   * This function is called by the artist, and it will transfer tokens
   * to a separate escrow contract to be held until the job is completed
   * @param _jobID is the ID of the job used within the ORC backend
   * @param _amount is the number of RNDR tokens being held in escrow
   */
  function holdInEscrow(string _jobID, uint256 _amount) public {
    require(transfer(escrowContractAddress, _amount), "token transfer to escrow address failed");
    Escrow(escrowContractAddress).fundJob(_jobID, _amount);

    emit TokensEscrowed(msg.sender, _jobID, _amount);
  }

  /**
   * @dev Mints new tokens equal to the amount of legacy tokens burned
   *
   * This function is called internally, but triggered by a user choosing to
   * migrate their balance.
   * @param _to is the address tokens will be sent to
   * @param _amount is the number of RNDR tokens being sent to the address
   */
  function _mintMigratedTokens(address _to, uint256 _amount) internal {
    require(_to != address(0), "_to address must not be null");
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);

    emit TokenMigration(_to, _amount);
    emit Transfer(address(0), _to, _amount);
  }

  /**
   * @dev Set the address of the escrow contract
   *
   * This will dictate the contract that will hold tokens in escrow and keep
   * a ledger of funds available for jobs.
   * RNDR is still in its infancy, and changes may need to be made to this
   * contract and / or the escrow contract. Including methods to update the
   * addresses allows the contracts to update independently.
   * If the escrow contract is ever migrated to another address for
   * either added security or functionality, this will need to be called.
   * @param _escrowAddress see escrowContractAddress
   */
  function setEscrowContractAddress(address _escrowAddress) public onlyOwner {
    require(_escrowAddress != address(0), "_escrowAddress must not be null");
    escrowContractAddress = _escrowAddress;

    emit EscrowContractAddressUpdate(escrowContractAddress);
  }

}