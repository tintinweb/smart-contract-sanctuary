pragma solidity 0.4.24;

import "./CanWorkJob.sol";

contract CanWork is CanWorkJob {
    ERC20 canYaCoin;

    event OnEmeregencyTransfer(address indexed toAddress, uint256 balance);

    function initialize(ERC20 _token, CanWorkAdmin _canworkAdmin, address _dApp, address _priceOracle) 
    public 
    isInitializer("CanWork", "0.1.2") {
        require(_token != address(0) && _canworkAdmin != address(0) && _dApp != address(0), "Addresses must be valid");

        CanWorkJob.initialize(_token, _canworkAdmin, _dApp, _priceOracle);      

        canYaCoin = _token;        
    }
  
    function emergencyTransfer(address toAddress) 
    public     
    returns (bool) {
        require(toAddress != address(0), "Address must be valid");
        require(canworkAdmin.hasRole(msg.sender, ROLE_OWNER), "Must have Owner role");

        bytes32 uniqueId = keccak256(abi.encodePacked(address(this), toAddress, "emergencyTransfer"));

        if (canworkAdmin.getSignersCount(uniqueId) < 2) {
            canworkAdmin.addSig(msg.sender, uniqueId);
            return false;
        }

        canworkAdmin.addSig(msg.sender, uniqueId);

        canworkAdmin.resetSignature(uniqueId);

        uint256 balance = canYaCoin.balanceOf(address(this));
        canYaCoin.transfer(toAddress, balance);

        emit OnEmeregencyTransfer(toAddress, balance);

        return true;
    }

    function getEmergencyTransferSignersCount(address _toAddress)
    public 
    view 
    returns(uint)
    {   
        bytes32 uniqueId = keccak256(abi.encodePacked(address(this), _toAddress, "emergencyTransfer"));
        return canworkAdmin.getSignersCount(uniqueId);
    }    

    function getEmergencyTransferSigner(address _toAddress, uint index)
    public 
    view 
    returns (address,bool)
    {
        bytes32 uniqueId = keccak256(abi.encodePacked(address(this), _toAddress, "emergencyTransfer"));
        return canworkAdmin.getSigner(uniqueId, index);
    }  
  
}

pragma solidity 0.4.24;

import "./Escrow.sol";

contract CanWorkAdmin {
    function addSig(address signer, bytes32 id) external returns (uint8);
    function resetSignature(bytes32 id) external returns (bool);  
    function getSignersCount(bytes32 id) external view returns (uint8);
    function getSigner(bytes32 id, uint index) external view returns (address,bool);
    function hasRole(address addr, string roleName) external view returns (bool);
}

contract CanWorkJob is Escrow {
    
    using SafeMath for uint256;
    
    CanWorkAdmin canworkAdmin;    
    string public constant ROLE_ADMIN = "admin";
    string public constant ROLE_OWNER = "owner";

    enum JobStatus {
        New,
        Completed,
        Cancelled
    }

    struct Job {
        bytes32 id;
        address client;
        address provider;
        uint256 escrowId;
        JobStatus status;
        uint256 amount;
    }

    mapping(bytes32 => Job) internal jobs;
    address dApp;

    event OnCreateJob(address indexed dapp, bytes32 indexed jobId, address client, address indexed provider, uint256 totalCosts);
    event OnCompleteJob(address indexed dapp, bytes32 indexed jobId);
    event OnCancelJobByProvider(address indexed dapp, bytes32 indexed jobId);
    event OnCancelJobByAdmin(address indexed dapp, bytes32 indexed jobId, uint8 payToProviderPercentage, address indexed arbiter, uint8 payToArbiterPercentage);

    function initialize(ERC20 _token, CanWorkAdmin _canworkAdmin, address _dApp, address _priceOracle)
    public 
    isInitializer("CanWorkJob", "0.1.3") {
        require(_token != address(0) && _canworkAdmin != address(0) && _dApp != address(0) && _priceOracle != address(0));
        Escrow.initialize(_token, _dApp, _priceOracle);
        canworkAdmin = CanWorkAdmin(_canworkAdmin);
        dApp = _dApp;
    }

    /** 
      * @dev Update the address of price oracle
      * @param _oracle Address
      */
    function updatePriceOracleAddress(address _oracle) 
    public {
        require(_oracle != address(0) && _oracle != address(priceOracle), "Must be valid, new address");
        require(canworkAdmin.hasRole(msg.sender, ROLE_OWNER), "Only owner can update");
        updateInternalOracleAddress(_oracle);
    }

    function createJob(bytes32 _jobId, address _client, address _provider, uint256 _totalCosts) 
    public 
    returns (bool) {
        require(_jobId[0] != 0);
        require(jobs[_jobId].id[0] == 0);

        jobs[_jobId].id = _jobId;
        jobs[_jobId].client = _client;
        jobs[_jobId].provider = _provider;
        jobs[_jobId].status = JobStatus.New;
        jobs[_jobId].amount = _totalCosts;
        jobs[_jobId].escrowId = createEscrow(_client, _provider, _totalCosts);

        emit OnCreateJob(dApp, _jobId, _client, _provider, _totalCosts);

        return true;
    }

    function completeJob(bytes32 _jobId) 
    public 
    returns (bool) {  
        require(_jobId[0] != 0);
        require(jobs[_jobId].status == JobStatus.New);
        require(jobs[_jobId].client == msg.sender);   
        
        require(completeEscrow(jobs[_jobId].escrowId));
        
        jobs[_jobId].status = JobStatus.Completed;

        emit OnCompleteJob(dApp, _jobId);

        return true;
    }

    function cancelJobByProvider(bytes32 _jobId) 
    public 
    returns (bool) {
        require(_jobId[0] != 0);  
        require(jobs[_jobId].status == JobStatus.New);
        require(jobs[_jobId].provider == msg.sender);
        
        require(cancelEscrowByProvider(jobs[_jobId].escrowId));
        
        jobs[_jobId].status = JobStatus.Cancelled;

        emit OnCancelJobByProvider(dApp, _jobId);

        return true;
    }

    function cancelJobByAdmin(bytes32 _jobId, uint8 _payToClientPercentage, uint8 _payToProviderPercentage, address _arbiter, uint8 _payToArbiterPercentage)
    public 
    returns (bool) {
        require(_jobId[0] != 0, "Must be valid jobId");  
        require(jobs[_jobId].status == JobStatus.New);
        require(canworkAdmin.hasRole(msg.sender, ROLE_ADMIN));
        require(_payToArbiterPercentage <= 5, "Arbiter cannot receive more than 5% of funds");
        
        require(cancelEscrow(jobs[_jobId].escrowId, _payToClientPercentage, _payToProviderPercentage, _arbiter, _payToArbiterPercentage));

        jobs[_jobId].status = JobStatus.Cancelled;

        emit OnCancelJobByAdmin(dApp, _jobId, _payToProviderPercentage, _arbiter, _payToArbiterPercentage);

        return true;
    }

    function getJob(bytes32 _jobId) 
    public 
    view 
    returns (
      address client, 
      address provider,
      uint256 amount,
      uint256 valueInDai, 
      uint8 status, 
      uint256 createdAt, 
      uint256 closedAt
      ) {
        require(_jobId[0] != 0, "Must be valid jobId"); 
        require(jobs[_jobId].id[0] != 0, "Job must exist");

        return getEscrow(jobs[_jobId].escrowId);
    }

    function getJobPayments(bytes32 _jobId) 
    public 
    view 
    returns (
      uint256 amount,  
      uint256 valueInDai,
      uint256 payoutAmount,
      uint256 paidToDappAmount,
      uint256 paidToProviderAmount,
      uint256 paidToClientAmount,
      uint256 paidToArbiterAmount
      ) {
        require(_jobId[0] != 0, "Must be valid jobId"); 
        require(jobs[_jobId].id[0] != 0, "Job must exist");

        return getEscrowPayments(jobs[_jobId].escrowId);
    } 
}

pragma solidity ^0.4.24;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
}

pragma solidity 0.4.24;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Migratable.sol";

/**
 * @title ERC20 Bancor Price Oracle Interface
 */


interface IOracle {
    function update() external;
    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);
}



contract Escrow is Migratable {
    using SafeMath for uint256;

    ERC20 internal escrowToken;
    uint256 internal escrowId;
    address escrowDapp;
    //address public paprOracle;
    address public priceOracle;


    uint256 internal DAPP_PAYMENT_PERCENTAGE;  

    //IOracle public priceOracle;

    enum EscrowStatus {
        New,
        Completed,
        Cancelled
    }

    struct EscrowRecord {
        uint256 id;
        address client;
        address provider;
        uint256 amount;
        uint256 totalValueDai;
        EscrowStatus status;
        uint256 createdAt;
        uint256 closedAt;
        uint256 payoutAmount;
        uint256 paidToDappAmount;
        uint256 paidToProviderAmount;
        uint256 paidToClientAmount;
        uint256 paidToArbiterAmount;
    }

    mapping(uint256 => EscrowRecord) internal escrows;

    event OnInitialize(address indexed token, address indexed dApp, address priceOracle);
    event OnCreateEscrow(address indexed dapp, address indexed client, address indexed provider, uint256 amount, uint256 daiAmount);
    event OnCompleteEscrow(address indexed dapp, uint256 indexed escrowId);
    event OnCancelEscrowByProvider(address indexed dapp, uint256 indexed escrowId);
    event OnCancelEscrow(address indexed dapp, uint256 indexed escrowId, uint256 payToProviderAmount, address indexed arbiter, uint256 payToArbiterAmount);
    
    function initialize(ERC20 _token, address _dApp, address _priceOracle) 
    internal 
    isInitializer("Escrow", "0.1.3") {
        require(_token != address(0) && _dApp != address(0) && _priceOracle != address(0), "Must be valid addresses");
        
        escrowToken = _token;
        escrowDapp = _dApp;
        priceOracle = _priceOracle;
        DAPP_PAYMENT_PERCENTAGE = 1;
        escrowId = 0;

        emit OnInitialize(_token, _dApp, _priceOracle);
    }

    function setpaprOracleAddress(address newOracle) external  {
        priceOracle = newOracle;
    }

    /**
     * @dev Initialise the escrow and store its details on chain
     * Calculates the DAI value equivalent of the deposited CAN tokens and stores this to hedge the escrow later
     * @return id of the escrow
     */

     function getPaprPrice() public view returns (uint256) {
      return IOracle(priceOracle).consult(escrowToken, 1e18); 
    }

    function getDaivalue() public view returns (uint256) {

      uint256 daiTest = getPaprPrice().div(1e18).mul(1);
      return daiTest; 
    }


    function createEscrow(address _client, address _provider, uint256 _amount) 
    internal 
    returns (uint256) {
        require(_client != address(0) && _provider != address(0) && _amount > 0, "Must be a valid addresses and non zero amounts");
        require(escrowToken.transferFrom(_client, address(this), _amount), "Client must have authorisation and balance to transfer CAN");

        uint256 daiValueInEscrow = getPaprPrice().mul(_amount.div(1e18));
        require(daiValueInEscrow > 0, "Job value must be greater than 0 USD");

        uint256 id = ++escrowId;
        EscrowRecord storage escrow = escrows[id];
        escrow.id = id;
        escrow.client = _client;
        escrow.provider = _provider;
        escrow.amount = _amount;
        escrow.totalValueDai = daiValueInEscrow;
        escrow.createdAt = block.number;
        escrow.status = EscrowStatus.New;
        escrow.payoutAmount = 0;
        escrow.paidToProviderAmount = 0;
        escrow.paidToClientAmount = 0;
        escrow.paidToArbiterAmount = 0;

        emit OnCreateEscrow(escrowDapp, _client, _provider, _amount, daiValueInEscrow);

        return id;
    }

    
    /**
     * @dev Completes the escrow, calculating the amount of CAN to pay out based on the DAI value
     * Sends DAPP_PAYMENT_PERCENTAGE amount to the dapp, and the rest to the provider
     * @param _escrowId Id of the escrow to complete
     * @return bool success
     */
    function completeEscrow(uint256 _escrowId) 
    internal 
    returns (bool) {
        require(escrows[_escrowId].status == EscrowStatus.New, "Escrow status must be 'new'");
        require(escrows[_escrowId].client == msg.sender, "Transaction must be sent by the client");

        escrows[_escrowId].status = EscrowStatus.Completed;
        escrows[_escrowId].closedAt = block.number;

        escrows[_escrowId].payoutAmount = getTotalPayoutCAN(_escrowId);

        uint256 payToDappAmount = escrows[_escrowId].payoutAmount.mul(DAPP_PAYMENT_PERCENTAGE).div(100);
        if(payToDappAmount > 0){
            escrows[_escrowId].paidToDappAmount = payToDappAmount;
            require(escrowToken.transfer(escrowDapp, payToDappAmount), "Dapp must receive payment");
        }

        uint256 providerPayoutCan = escrows[_escrowId].payoutAmount.sub(payToDappAmount);
        escrows[_escrowId].paidToProviderAmount = providerPayoutCan;

        require(escrowToken.transfer(escrows[_escrowId].provider, escrows[_escrowId].paidToProviderAmount), "Escrow must hold enough CAN for payout");

        emit OnCompleteEscrow(escrowDapp, _escrowId);

        return true;
    }
    
    /**
     * @dev Get the total amount of CAN to pay out for the job, based on the DAI value
     * @param _escrowId Id of the escrow to complete
     * @return uint256 amount of CAN
     */
    function getTotalPayoutCAN(uint _escrowId) 
    internal
    view 
    returns (uint256) {
        //uint256 totalPayoutCAN1 = getPaprPrice();
        uint256 totalPayoutCAN = escrows[_escrowId].totalValueDai;

        require(totalPayoutCAN > 0, "Oracle must return a non zero payout");
        if(totalPayoutCAN >= escrows[_escrowId].amount.mul(2)){ // max payout in CAN is 2x initial pay in
            return escrows[_escrowId].amount.mul(2);
        }
        return totalPayoutCAN;
    }

    /**
     * @dev The provider wishes to cancel the job before he begins working on it
     * Pay out 100% of the DAI value in CAN back to the client
     * @param _escrowId Id of the escrow to complete
     * @return bool success
     */
    function cancelEscrowByProvider(uint256 _escrowId) 
    internal 
    returns (bool) {
        require(escrows[_escrowId].status == EscrowStatus.New, "Escrow status must be 'new'");
        require(escrows[_escrowId].provider == msg.sender, "Transaction must be sent by provider");

        escrows[_escrowId].payoutAmount = getTotalPayoutCAN(_escrowId);

        escrows[_escrowId].paidToClientAmount = escrows[_escrowId].payoutAmount;
        escrows[_escrowId].status = EscrowStatus.Cancelled;
        escrows[_escrowId].closedAt = block.number;

        require(escrowToken.transfer(escrows[_escrowId].client, escrows[_escrowId].paidToClientAmount), "Client must receive payment");

        emit OnCancelEscrowByProvider(escrowDapp, _escrowId);

        return true;
    }    

    /**
     * @dev The escrow finishes early, so we split the money between the parties, and the rest goes back
     * to the client. We calculate payout from the DAI value
     * @param _escrowId Id of the escrow to finalise
     * @param _payToClientPercentage Percent of remaining funds to give to client
     * @param _payToProviderPercentage Percent of remaining funds to give to client
     * @param _arbiter Address of the arbiter
     * @param _payToArbiterPercentage Percentage of remaining funds to give to arbiter
     * @return bool success
     */
    function cancelEscrow(uint256 _escrowId, uint8 _payToClientPercentage, uint8 _payToProviderPercentage, address _arbiter, uint8 _payToArbiterPercentage) 
    internal 
    returns (bool) {
        require(escrows[_escrowId].status == EscrowStatus.New, "Escrow status must be 'new'");
        require(_payToClientPercentage >= 0 && _payToProviderPercentage >= 0 && _payToArbiterPercentage >= 0
            && _payToClientPercentage <= 100 && _payToProviderPercentage <= 100 && _payToArbiterPercentage <= 100, "Payments to client, provider and arbiter must be gte 0");
        require((_payToClientPercentage + _payToProviderPercentage + _payToArbiterPercentage) == 100, "Total payout must equal 100 percent");

        escrows[_escrowId].status = EscrowStatus.Cancelled;        
        escrows[_escrowId].closedAt = block.number;

        escrows[_escrowId].payoutAmount = getTotalPayoutCAN(_escrowId);

        uint256 payToDappAmount = escrows[_escrowId].payoutAmount.mul(DAPP_PAYMENT_PERCENTAGE).div(100);
        if (payToDappAmount > 0){
            escrows[_escrowId].paidToDappAmount = payToDappAmount;
            require(escrowToken.transfer(escrowDapp, payToDappAmount), "Dapp must receive payment");
        }

        uint payoutToSplit = escrows[_escrowId].payoutAmount.sub(payToDappAmount);

        if (_payToArbiterPercentage > 0) {
            require(_arbiter != address(0), "Arbiter address must be valid");
            escrows[_escrowId].paidToArbiterAmount = payoutToSplit.mul(_payToArbiterPercentage).div(100);
            require(escrowToken.transfer(_arbiter, escrows[_escrowId].paidToArbiterAmount), "Arbiter must receive payment");
        }                

        if (_payToProviderPercentage > 0) {
            escrows[_escrowId].paidToProviderAmount = payoutToSplit.mul(_payToProviderPercentage).div(100);
            require(escrowToken.transfer(escrows[_escrowId].provider, escrows[_escrowId].paidToProviderAmount), "Provider must receive payment");
        }        
             
        if (_payToClientPercentage > 0) {
            escrows[_escrowId].paidToClientAmount = payoutToSplit.mul(_payToClientPercentage).div(100); 
            require(escrowToken.transfer(escrows[_escrowId].client, escrows[_escrowId].paidToClientAmount), "Client must receive payment");
        }       

        emit OnCancelEscrow(escrowDapp, _escrowId, escrows[_escrowId].paidToProviderAmount, _arbiter, escrows[_escrowId].paidToArbiterAmount); 

        return true;
    }

    /** 
      * @dev Internal update the address of price oracle
      * @param _oracle Address
      */
    function updateInternalOracleAddress(address _oracle) 
    internal {
        IOracle(_oracle).update();
    }

    function getEscrow(uint256 _escrowId) 
    public 
    view
    returns (
      address client, 
      address provider, 
      uint256 amount, 
      uint256 totalValueDai, 
      uint8 status, 
      uint256 createdAt, 
      uint256 closedAt) 
      {      
        require(_escrowId > 0 && escrows[_escrowId].createdAt > 0, "Must be a valid escrow Id");
        return (
            escrows[_escrowId].client, 
            escrows[_escrowId].provider, 
            escrows[_escrowId].amount, 
            escrows[_escrowId].totalValueDai, 
            uint8(escrows[_escrowId].status),
            escrows[_escrowId].createdAt, 
            escrows[_escrowId].closedAt
            );       
    }

    function getEscrowPayments(uint256 _escrowId) 
    public 
    view
    returns (
      uint256 amount, 
      uint256 totalValueDai, 
      uint256 payoutAmount,
      uint256 paidToDappAmount,
      uint256 paidToProviderAmount,
      uint256 paidToClientAmount,      
      uint256 paidToArbiterAmount)
      {      
        require(_escrowId > 0 && escrows[_escrowId].createdAt > 0, "Must be a valid escrow Id");
        return (
            escrows[_escrowId].amount, 
            escrows[_escrowId].totalValueDai, 
            escrows[_escrowId].payoutAmount, 
            escrows[_escrowId].paidToDappAmount,
            escrows[_escrowId].paidToProviderAmount,
            escrows[_escrowId].paidToClientAmount,        
            escrows[_escrowId].paidToArbiterAmount
            );       
    }    
}

pragma solidity ^0.4.24;


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
   * @dev Modifier to use in the initialization function of a contract.
   * @param contractName Name of the contract.
   * @param migrationId Identifier of the migration.
   */
  modifier isInitializer(string contractName, string migrationId) {
    require(!isMigrated(contractName, migrationId));
    _;
    emit Migrated(contractName, migrationId);
    migrated[contractName][migrationId] = true;
  }

  /**
   * @dev Modifier to use in the migration of a contract.
   * @param contractName Name of the contract.
   * @param requiredMigrationId Identifier of the previous migration, required
   * to apply new one.
   * @param newMigrationId Identifier of the new migration to be applied.
   */
  modifier isMigration(string contractName, string requiredMigrationId, string newMigrationId) {
    require(isMigrated(contractName, requiredMigrationId) && !isMigrated(contractName, newMigrationId));
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
}

pragma solidity ^0.4.21;


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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}