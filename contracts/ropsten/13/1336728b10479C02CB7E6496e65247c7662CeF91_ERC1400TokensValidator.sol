/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../tools/Pausable.sol";
import "../../roles/CertificateSignerRole.sol";
import "../../roles/AllowlistedRole.sol";
import "../../roles/BlocklistedRole.sol";

import "../../interface/IHoldableERC1400TokenExtension.sol";
import "../../tools/ERC1820Client.sol";
import "../../tools/DomainAware.sol";
import "../../interface/ERC1820Implementer.sol";

import "../../IERC1400.sol";

import "./IERC1400TokensValidator.sol";

/**
 * @notice Interface to the Minterrole contract
 */
interface IMinterRole {
  function isMinter(address account) external view returns (bool);
}


contract ERC1400TokensValidator is IERC1400TokensValidator, Pausable, CertificateSignerRole, AllowlistedRole, BlocklistedRole, ERC1820Client, ERC1820Implementer, IHoldableERC1400TokenExtension {
  using SafeMath for uint256;

  string constant internal ERC1400_TOKENS_VALIDATOR = "ERC1400TokensValidator";

  bytes4 constant internal ERC20_TRANSFER_ID = bytes4(keccak256("transfer(address,uint256)"));
  bytes4 constant internal ERC20_TRANSFERFROM_ID = bytes4(keccak256("transferFrom(address,address,uint256)"));

  bytes32 constant internal ZERO_ID = 0x00000000000000000000000000000000;

  // Mapping from token to token controllers.
  mapping(address => address[]) internal _tokenControllers;

  // Mapping from (token, operator) to token controller status.
  mapping(address => mapping(address => bool)) internal _isTokenController;

  // Mapping from token to allowlist activation status.
  mapping(address => bool) internal _allowlistActivated;

  // Mapping from token to blocklist activation status.
  mapping(address => bool) internal _blocklistActivated;

  // Mapping from token to certificate activation status.
  mapping(address => CertificateValidation) internal _certificateActivated;

  enum CertificateValidation {
    None,
    NonceBased,
    SaltBased
  }

  // Mapping from (token, certificateNonce) to "used" status to ensure a certificate can be used only once
  mapping(address => mapping(address => uint256)) internal _usedCertificateNonce;

  // Mapping from (token, certificateSalt) to "used" status to ensure a certificate can be used only once
  mapping(address => mapping(bytes32 => bool)) internal _usedCertificateSalt;

  // Mapping from token to partition granularity activation status.
  mapping(address => bool) internal _granularityByPartitionActivated;

  // Mapping from token to holds activation status.
  mapping(address => bool) internal _holdsActivated;

  struct Hold {
    bytes32 partition;
    address sender;
    address recipient;
    address notary;
    uint256 value;
    uint256 expiration;
    bytes32 secretHash;
    bytes32 secret;
    HoldStatusCode status;
  }

  // Mapping from (token, partition) to partition granularity.
  mapping(address => mapping(bytes32 => uint256)) internal _granularityByPartition;
  
  // Mapping from (token, holdId) to hold.
  mapping(address => mapping(bytes32 => Hold)) internal _holds;

  // Mapping from (token, tokenHolder) to balance on hold.
  mapping(address => mapping(address => uint256)) internal _heldBalance;

  // Mapping from (token, tokenHolder, partition) to balance on hold of corresponding partition.
  mapping(address => mapping(address => mapping(bytes32 => uint256))) internal _heldBalanceByPartition;

  // Mapping from (token, partition) to global balance on hold of corresponding partition.
  mapping(address => mapping(bytes32 => uint256)) internal _totalHeldBalanceByPartition;

  // Total balance on hold.
  mapping(address => uint256) internal _totalHeldBalance;

  // Mapping from hash to hold ID.
  mapping(bytes32 => bytes32) internal _holdIds;

  event HoldCreated(
    address indexed token,
    bytes32 indexed holdId,
    bytes32 partition,
    address sender,
    address recipient,
    address indexed notary,
    uint256 value,
    uint256 expiration,
    bytes32 secretHash
  );
  event HoldReleased(address indexed token, bytes32 holdId, address indexed notary, HoldStatusCode status);
  event HoldRenewed(address indexed token, bytes32 holdId, address indexed notary, uint256 oldExpiration, uint256 newExpiration);
  event HoldExecuted(address indexed token, bytes32 holdId, address indexed notary, uint256 heldValue, uint256 transferredValue, bytes32 secret);
  event HoldExecutedAndKeptOpen(address indexed token, bytes32 holdId, address indexed notary, uint256 heldValue, uint256 transferredValue, bytes32 secret);
  
  /**
   * @dev Modifier to verify if sender is a token controller.
   */
  modifier onlyTokenController(address token) {
    require(
      msg.sender == token ||
      msg.sender == Ownable(token).owner() ||
      _isTokenController[token][msg.sender],
      "Sender is not a token controller."
    );
    _;
  }

  /**
   * @dev Modifier to verify if sender is a pauser.
   */
  modifier onlyPauser(address token) override {
    require(
      msg.sender == token ||
      msg.sender == Ownable(token).owner() ||
      _isTokenController[token][msg.sender] ||
      isPauser(token, msg.sender),
      "Sender is not a pauser"
    );
    _;
  }

  /**
   * @dev Modifier to verify if sender is a pauser.
   */
  modifier onlyCertificateSigner(address token) override {
    require(
      msg.sender == token ||
      msg.sender == Ownable(token).owner() ||
      _isTokenController[token][msg.sender] ||
      isCertificateSigner(token, msg.sender),
      "Sender is not a certificate signer"
    );
    _;
  }

  /**
   * @dev Modifier to verify if sender is an allowlist admin.
   */
  modifier onlyAllowlistAdmin(address token) override {
    require(
      msg.sender == token ||
      msg.sender == Ownable(token).owner() ||
      _isTokenController[token][msg.sender] ||
      isAllowlistAdmin(token, msg.sender),
      "Sender is not an allowlist admin"
    );
    _;
  }

  /**
   * @dev Modifier to verify if sender is a blocklist admin.
   */
  modifier onlyBlocklistAdmin(address token) override {
    require(
      msg.sender == token ||
      msg.sender == Ownable(token).owner() ||
      _isTokenController[token][msg.sender] ||
      isBlocklistAdmin(token, msg.sender),
      "Sender is not a blocklist admin"
    );
    _;
  }

  constructor() {
    ERC1820Implementer._setInterface(ERC1400_TOKENS_VALIDATOR);


  }

  /**
   * @dev Get the list of token controllers for a given token.
   * @return Setup of a given token.
   */
  function retrieveTokenSetup(address token) external view returns (CertificateValidation, bool, bool, bool, bool, address[] memory) {
    return (
      _certificateActivated[token],
      _allowlistActivated[token],
      _blocklistActivated[token],
      _granularityByPartitionActivated[token],
      _holdsActivated[token],
      _tokenControllers[token]
    );
  }

  /**
   * @dev Register token setup.
   */
  function registerTokenSetup(
    address token,
    CertificateValidation certificateActivated,
    bool allowlistActivated,
    bool blocklistActivated,
    bool granularityByPartitionActivated,
    bool holdsActivated,
    address[] calldata operators
  ) external onlyTokenController(token) {
    _certificateActivated[token] = certificateActivated;
    _allowlistActivated[token] = allowlistActivated;
    _blocklistActivated[token] = blocklistActivated;
    _granularityByPartitionActivated[token] = granularityByPartitionActivated;
    _holdsActivated[token] = holdsActivated;
    _setTokenControllers(token, operators);
  }

  /**
   * @dev Set list of token controllers for a given token.
   * @param token Token address.
   * @param operators Operators addresses.
   */
  function _setTokenControllers(address token, address[] memory operators) internal {
    for (uint i = 0; i<_tokenControllers[token].length; i++){
      _isTokenController[token][_tokenControllers[token][i]] = false;
    }
    for (uint j = 0; j<operators.length; j++){
      _isTokenController[token][operators[j]] = true;
    }
    _tokenControllers[token] = operators;
  }

  /**
   * @dev Verify if a token transfer can be executed or not, on the validator's perspective.
   * @param data The struct containing the validation information.
   * @return 'true' if the token transfer can be validated, 'false' if not.
   */
  function canValidate(IERC1400TokensValidator.ValidateData calldata data) // Comments to avoid compilation warnings for unused variables.
    external
    override
    view 
    returns(bool)
  {
    (bool canValidateToken,,) = _canValidateCertificateToken(data.token, data.payload, data.operator, data.operatorData.length != 0 ? data.operatorData : data.data);

    canValidateToken = canValidateToken && _canValidateAllowlistAndBlocklistToken(data.token, data.payload, data.from, data.to);
    
    canValidateToken = canValidateToken && !paused(data.token);

    canValidateToken = canValidateToken && _canValidateGranularToken(data.token, data.partition, data.value);

    canValidateToken = canValidateToken && _canValidateHoldableToken(data.token, data.partition, data.operator, data.from, data.to, data.value);

    return canValidateToken;
  }

  /**
   * @dev Function called by the token contract before executing a transfer.
   * @param payload Payload of the initial transaction.
   * @param partition Name of the partition (left empty for ERC20 transfer).
   * @param operator Address which triggered the balance decrease (through transfer or redemption).
   * @param from Token holder.
   * @param to Token recipient for a transfer and 0x for a redemption.
   * @param value Number of tokens the token holder balance is decreased by.
   * @param data Extra information.
   * @param operatorData Extra information, attached by the operator (if any).
   */
  function tokensToValidate(
    bytes calldata payload,
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint value,
    bytes calldata data,
    bytes calldata operatorData
  ) // Comments to avoid compilation warnings for unused variables.
    external
    override
  {
    //Local scope variables to avoid stack too deep
    {
        (bool canValidateCertificateToken, CertificateValidation certificateControl, bytes32 salt) = _canValidateCertificateToken(msg.sender, payload, operator, operatorData.length != 0 ? operatorData : data);
        require(canValidateCertificateToken, "54"); // 0x54	transfers halted (contract paused)

        _useCertificateIfActivated(msg.sender, certificateControl, operator, salt);
    }

    {
        require(_canValidateAllowlistAndBlocklistToken(msg.sender, payload, from, to), "54"); // 0x54	transfers halted (contract paused)
    }
    
    {
        require(!paused(msg.sender), "54"); // 0x54	transfers halted (contract paused)
    }
    
    {
        require(_canValidateGranularToken(msg.sender, partition, value), "50"); // 0x50	transfer failure

        require(_canValidateHoldableToken(msg.sender, partition, operator, from, to, value), "55"); // 0x55	funds locked (lockup period)
    }
    
    {
        (, bytes32 holdId) = _retrieveHoldHashId(msg.sender, partition, operator, from, to, value);
        if (_holdsActivated[msg.sender] && holdId != "") {
          Hold storage executableHold = _holds[msg.sender][holdId];
          _setHoldToExecuted(
            msg.sender,
            executableHold,
            holdId,
            value,
            executableHold.value,
            ""
          );
        }
    }
  }

  /**
   * @dev Verify if a token transfer can be executed or not, on the validator's perspective.
   * @return 'true' if the token transfer can be validated, 'false' if not.
   * @return hold ID in case a hold can be executed for the given parameters.
   */
  function _canValidateCertificateToken(
    address token,
    bytes memory payload,
    address operator,
    bytes memory certificate
  )
    internal
    view
    returns(bool, CertificateValidation, bytes32)
  {
    if(
      _certificateActivated[token] > CertificateValidation.None &&
      _functionSupportsCertificateValidation(payload) &&
      !isCertificateSigner(token, operator) &&
      address(this) != operator
    ) {
      if(_certificateActivated[token] == CertificateValidation.SaltBased) {
        (bool valid, bytes32 salt) = _checkSaltBasedCertificate(
          token,
          operator,
          payload,
          certificate
        );
        if(valid) {
          return (true, CertificateValidation.SaltBased, salt);
        } else {
          return (false, CertificateValidation.SaltBased, "");
        }
        
      } else { // case when _certificateActivated[token] == CertificateValidation.NonceBased
        if(
          _checkNonceBasedCertificate(
            token,
            operator,
            payload,
            certificate
          )
        ) {
          return (true, CertificateValidation.NonceBased, "");
        } else {
          return (false, CertificateValidation.NonceBased, "");
        }
      }
    }

    return (true, CertificateValidation.None, "");
  }

  /**
   * @dev Verify if a token transfer can be executed or not, on the validator's perspective.
   * @return 'true' if the token transfer can be validated, 'false' if not.
   */
  function _canValidateAllowlistAndBlocklistToken(
    address token,
    bytes memory payload,
    address from,
    address to
  ) // Comments to avoid compilation warnings for unused variables.
    internal
    view
    returns(bool)
  {
    if(
      !_functionSupportsCertificateValidation(payload) ||
      _certificateActivated[token] == CertificateValidation.None
    ) {
      if(_allowlistActivated[token]) {
        if(from != address(0) && !isAllowlisted(token, from)) {
          return false;
        }
        if(to != address(0) && !isAllowlisted(token, to)) {
          return false;
        }
      }
      if(_blocklistActivated[token]) {
        if(from != address(0) && isBlocklisted(token, from)) {
          return false;
        }
        if(to != address(0) && isBlocklisted(token, to)) {
          return false;
        }
      }
    }
    
    return true;
  }

  /**
   * @dev Verify if a token transfer can be executed or not, on the validator's perspective.
   * @return 'true' if the token transfer can be validated, 'false' if not.
   */
  function _canValidateGranularToken(
    address token,
    bytes32 partition,
    uint value
  )
    internal
    view
    returns(bool)
  {
    if(_granularityByPartitionActivated[token]) {
      if(
        _granularityByPartition[token][partition] > 0 &&
        !_isMultiple(_granularityByPartition[token][partition], value)
      ) {
        return false;
      } 
    }

    return true;
  }

  /**
   * @dev Verify if a token transfer can be executed or not, on the validator's perspective.
   * @return 'true' if the token transfer can be validated, 'false' if not.
   */
  function _canValidateHoldableToken(
    address token,
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint value
  )
    internal
    view
    returns(bool)
  {
    if (_holdsActivated[token] && from != address(0)) {
      if(operator != from) {
        (, bytes32 holdId) = _retrieveHoldHashId(token, partition, operator, from, to, value);
        Hold storage hold = _holds[token][holdId];
        
        if (_holdCanBeExecutedAsNotary(hold, operator, value) && value <= IERC1400(token).balanceOfByPartition(partition, from)) {
          return true;
        }
      }
      
      if(value > _spendableBalanceOfByPartition(token, partition, from)) {
        return false;
      }
    }

    return true;
  }

  /**
   * @dev Get granularity for a given partition.
   * @param token Token address.
   * @param partition Name of the partition.
   * @return Granularity of the partition.
   */
  function granularityByPartition(address token, bytes32 partition) external view returns (uint256) {
    return _granularityByPartition[token][partition];
  }
  
  /**
   * @dev Set partition granularity
   */
  function setGranularityByPartition(
    address token,
    bytes32 partition,
    uint256 granularity
  )
    external
    onlyTokenController(token)
  {
    _granularityByPartition[token][partition] = granularity;
  }

  /**
   * @dev Create a new token pre-hold.
   */
  function preHoldFor(
    address token,
    bytes32 holdId,
    address recipient,
    address notary,
    bytes32 partition,
    uint256 value,
    uint256 timeToExpiration,
    bytes32 secretHash,
    bytes calldata certificate
  )
    external
    returns (bool)
  {
    return _createHold(
      token,
      holdId,
      address(0),
      recipient,
      notary,
      partition,
      value,
      _computeExpiration(timeToExpiration),
      secretHash,
      certificate
    );
  }

  /**
   * @dev Create a new token pre-hold with expiration date.
   */
  function preHoldForWithExpirationDate(
    address token,
    bytes32 holdId,
    address recipient,
    address notary,
    bytes32 partition,
    uint256 value,
    uint256 expiration,
    bytes32 secretHash,
    bytes calldata certificate
  )
    external
    returns (bool)
  {
    _checkExpiration(expiration);

    return _createHold(
      token,
      holdId,
      address(0),
      recipient,
      notary,
      partition,
      value,
      expiration,
      secretHash,
      certificate
    );
  }

  /**
   * @dev Create a new token hold.
   */
  function hold(
    address token,
    bytes32 holdId,
    address recipient,
    address notary,
    bytes32 partition,
    uint256 value,
    uint256 timeToExpiration,
    bytes32 secretHash,
    bytes calldata certificate
  ) 
    external
    returns (bool)
  {
    return _createHold(
      token,
      holdId,
      msg.sender,
      recipient,
      notary,
      partition,
      value,
      _computeExpiration(timeToExpiration),
      secretHash,
      certificate
    );
  }

  /**
   * @dev Create a new token hold with expiration date.
   */
  function holdWithExpirationDate(
    address token,
    bytes32 holdId,
    address recipient,
    address notary,
    bytes32 partition,
    uint256 value,
    uint256 expiration,
    bytes32 secretHash,
    bytes calldata certificate
  )
    external
    returns (bool)
  {
    _checkExpiration(expiration);

    return _createHold(
      token,
      holdId,
      msg.sender,
      recipient,
      notary,
      partition,
      value,
      expiration,
      secretHash,
      certificate
    );
  }

  /**
   * @dev Create a new token hold on behalf of the token holder.
   */
  function holdFrom(
    address token,
    bytes32 holdId,
    address sender,
    address recipient,
    address notary,
    bytes32 partition,
    uint256 value,
    uint256 timeToExpiration,
    bytes32 secretHash,
    bytes calldata certificate
  )
    external
    returns (bool)
  {
    require(sender != address(0), "Payer address must not be zero address");
    return _createHold(
      token,
      holdId,
      sender,
      recipient,
      notary,
      partition,
      value,
      _computeExpiration(timeToExpiration),
      secretHash,
      certificate
    );
  }

  /**
   * @dev Create a new token hold with expiration date on behalf of the token holder.
   */
  function holdFromWithExpirationDate(
    address token,
    bytes32 holdId,
    address sender,
    address recipient,
    address notary,
    bytes32 partition,
    uint256 value,
    uint256 expiration,
    bytes32 secretHash,
    bytes calldata certificate
  )
    external
    returns (bool)
  {
    _checkExpiration(expiration);
    require(sender != address(0), "Payer address must not be zero address");

    return _createHold(
      token,
      holdId,
      sender,
      recipient,
      notary,
      partition,
      value,
      expiration,
      secretHash,
      certificate
    );
  }

  /**
   * @dev Create a new token hold.
   */
  function _createHold(
    address token,
    bytes32 holdId,
    address sender,
    address recipient,
    address notary,
    bytes32 partition,
    uint256 value,
    uint256 expiration,
    bytes32 secretHash,
    bytes memory certificate
  ) internal returns (bool)
  {
    Hold storage newHold = _holds[token][holdId];

    require(recipient != address(0), "Payee address must not be zero address");
    require(value != 0, "Value must be greater than zero");
    require(newHold.value == 0, "This holdId already exists");
    require(
      _canHoldOrCanPreHold(token, msg.sender, sender, certificate),
      "A hold can only be created with adapted authorizations"
    );
    
    if (sender != address(0)) { // hold (tokens already exist)
      require(value <= _spendableBalanceOfByPartition(token, partition, sender), "Amount of the hold can't be greater than the spendable balance of the sender");
    }
    
    newHold.partition = partition;
    newHold.sender = sender;
    newHold.recipient = recipient;
    newHold.notary = notary;
    newHold.value = value;
    newHold.expiration = expiration;
    newHold.secretHash = secretHash;
    newHold.status = HoldStatusCode.Ordered;

    if(sender != address(0)) {
      // In case tokens already exist, increase held balance
      _increaseHeldBalance(token, newHold, holdId);

      (bytes32 holdHash,) = _retrieveHoldHashId(
        token, newHold.partition,
        newHold.notary,
        newHold.sender,
        newHold.recipient,
        newHold.value
      );

      _holdIds[holdHash] = holdId;
    }

    emit HoldCreated(
      token,
      holdId,
      partition,
      sender,
      recipient,
      notary,
      value,
      expiration,
      secretHash
    );

    return true;
  }

  /**
   * @dev Release token hold.
   */
  function releaseHold(address token, bytes32 holdId) external returns (bool) {
    return _releaseHold(token, holdId);
  }

  /**
   * @dev Release token hold.
   */
  function _releaseHold(address token, bytes32 holdId) internal returns (bool) {
    Hold storage releasableHold = _holds[token][holdId];

    require(
        releasableHold.status == HoldStatusCode.Ordered || releasableHold.status == HoldStatusCode.ExecutedAndKeptOpen,
        "A hold can only be released in status Ordered or ExecutedAndKeptOpen"
    );
    require(
        _isExpired(releasableHold.expiration) ||
        (msg.sender == releasableHold.notary) ||
        (msg.sender == releasableHold.recipient),
        "A not expired hold can only be released by the notary or the payee"
    );

    if (_isExpired(releasableHold.expiration)) {
        releasableHold.status = HoldStatusCode.ReleasedOnExpiration;
    } else {
        if (releasableHold.notary == msg.sender) {
            releasableHold.status = HoldStatusCode.ReleasedByNotary;
        } else {
            releasableHold.status = HoldStatusCode.ReleasedByPayee;
        }
    }

    if(releasableHold.sender != address(0)) { // In case tokens already exist, decrease held balance
      _decreaseHeldBalance(token, releasableHold, releasableHold.value);

      (bytes32 holdHash,) = _retrieveHoldHashId(
        token, releasableHold.partition,
        releasableHold.notary,
        releasableHold.sender,
        releasableHold.recipient,
        releasableHold.value
      );

      delete _holdIds[holdHash];
    }

    emit HoldReleased(token, holdId, releasableHold.notary, releasableHold.status);

    return true;
  }

  /**
   * @dev Renew hold.
   */
  function renewHold(address token, bytes32 holdId, uint256 timeToExpiration, bytes calldata certificate) external returns (bool) {
    return _renewHold(token, holdId, _computeExpiration(timeToExpiration), certificate);
  }

  /**
   * @dev Renew hold with expiration time.
   */
  function renewHoldWithExpirationDate(address token, bytes32 holdId, uint256 expiration, bytes calldata certificate) external returns (bool) {
    _checkExpiration(expiration);

    return _renewHold(token, holdId, expiration, certificate);
  }

  /**
   * @dev Renew hold.
   */
  function _renewHold(address token, bytes32 holdId, uint256 expiration, bytes memory certificate) internal returns (bool) {
    Hold storage renewableHold = _holds[token][holdId];

    require(
      renewableHold.status == HoldStatusCode.Ordered
      || renewableHold.status == HoldStatusCode.ExecutedAndKeptOpen,
      "A hold can only be renewed in status Ordered or ExecutedAndKeptOpen"
    );
    require(!_isExpired(renewableHold.expiration), "An expired hold can not be renewed");

    require(
      _canHoldOrCanPreHold(token, msg.sender, renewableHold.sender, certificate),
      "A hold can only be renewed with adapted authorizations"
    );
    
    uint256 oldExpiration = renewableHold.expiration;
    renewableHold.expiration = expiration;

    emit HoldRenewed(
      token,
      holdId,
      renewableHold.notary,
      oldExpiration,
      expiration
    );

    return true;
  }

  /**
   * @dev Execute hold.
   */
  function executeHold(address token, bytes32 holdId, uint256 value, bytes32 secret) external override returns (bool) {
    return _executeHold(
      token,
      holdId,
      msg.sender,
      value,
      secret,
      false
    );
  }

  /**
   * @dev Execute hold and keep open.
   */
  function executeHoldAndKeepOpen(address token, bytes32 holdId, uint256 value, bytes32 secret) external returns (bool) {
    return _executeHold(
      token,
      holdId,
      msg.sender,
      value,
      secret,
      true
    );
  }
  
  /**
   * @dev Execute hold.
   */
  function _executeHold(
    address token,
    bytes32 holdId,
    address operator,
    uint256 value,
    bytes32 secret,
    bool keepOpenIfHoldHasBalance
  ) internal returns (bool)
  {
    Hold storage executableHold = _holds[token][holdId];

    bool canExecuteHold;
    if(secret != "" && _holdCanBeExecutedAsSecretHolder(executableHold, value, secret)) {
      executableHold.secret = secret;
      canExecuteHold = true;
    } else if(_holdCanBeExecutedAsNotary(executableHold, operator, value)) {
      canExecuteHold = true;
    }

    if(canExecuteHold) {
      if (keepOpenIfHoldHasBalance && ((executableHold.value - value) > 0)) {
        _setHoldToExecutedAndKeptOpen(
          token,
          executableHold,
          holdId,
          value,
          value,
          secret
        );
      } else {
        _setHoldToExecuted(
          token,
          executableHold,
          holdId,
          value,
          executableHold.value,
          secret
        );
      }

      if (executableHold.sender == address(0)) { // pre-hold (tokens do not already exist)
        IERC1400(token).issueByPartition(executableHold.partition, executableHold.recipient, value, "");
      } else { // post-hold (tokens already exist)
        IERC1400(token).operatorTransferByPartition(executableHold.partition, executableHold.sender, executableHold.recipient, value, "", "");
      }
      
    } else {
      revert("hold can not be executed");
    }

  }

  /**
   * @dev Set hold to executed.
   */
  function _setHoldToExecuted(
    address token,
    Hold storage executableHold,
    bytes32 holdId,
    uint256 value,
    uint256 heldBalanceDecrease,
    bytes32 secret
  ) internal
  {
    if(executableHold.sender != address(0)) { // In case tokens already exist, decrease held balance
      _decreaseHeldBalance(token, executableHold, heldBalanceDecrease);
    }

    executableHold.status = HoldStatusCode.Executed;

    emit HoldExecuted(
      token,
      holdId,
      executableHold.notary,
      executableHold.value,
      value,
      secret
    );
  }

  /**
   * @dev Set hold to executed and kept open.
   */
  function _setHoldToExecutedAndKeptOpen(
    address token,
    Hold storage executableHold,
    bytes32 holdId,
    uint256 value,
    uint256 heldBalanceDecrease,
    bytes32 secret
  ) internal
  {
    if(executableHold.sender != address(0)) { // In case tokens already exist, decrease held balance
      _decreaseHeldBalance(token, executableHold, heldBalanceDecrease);
    } 

    executableHold.status = HoldStatusCode.ExecutedAndKeptOpen;
    executableHold.value = executableHold.value.sub(value);

    emit HoldExecutedAndKeptOpen(
      token,
      holdId,
      executableHold.notary,
      executableHold.value,
      value,
      secret
    );
  }

  /**
   * @dev Increase held balance.
   */
  function _increaseHeldBalance(address token, Hold storage executableHold, bytes32 holdId) private {
    _heldBalance[token][executableHold.sender] = _heldBalance[token][executableHold.sender].add(executableHold.value);
    _totalHeldBalance[token] = _totalHeldBalance[token].add(executableHold.value);

    _heldBalanceByPartition[token][executableHold.sender][executableHold.partition] = _heldBalanceByPartition[token][executableHold.sender][executableHold.partition].add(executableHold.value);
    _totalHeldBalanceByPartition[token][executableHold.partition] = _totalHeldBalanceByPartition[token][executableHold.partition].add(executableHold.value);
  }

  /**
   * @dev Decrease held balance.
   */
  function _decreaseHeldBalance(address token, Hold storage executableHold, uint256 value) private {
    _heldBalance[token][executableHold.sender] = _heldBalance[token][executableHold.sender].sub(value);
    _totalHeldBalance[token] = _totalHeldBalance[token].sub(value);

    _heldBalanceByPartition[token][executableHold.sender][executableHold.partition] = _heldBalanceByPartition[token][executableHold.sender][executableHold.partition].sub(value);
    _totalHeldBalanceByPartition[token][executableHold.partition] = _totalHeldBalanceByPartition[token][executableHold.partition].sub(value);
  }

  /**
   * @dev Check secret.
   */
  function _checkSecret(Hold storage executableHold, bytes32 secret) internal view returns (bool) {
    if(executableHold.secretHash == sha256(abi.encodePacked(secret))) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Compute expiration time.
   */
  function _computeExpiration(uint256 timeToExpiration) internal view returns (uint256) {
    uint256 expiration = 0;

    if (timeToExpiration != 0) {
        expiration = block.timestamp.add(timeToExpiration);
    }

    return expiration;
  }

  /**
   * @dev Check expiration time.
   */
  function _checkExpiration(uint256 expiration) private view {
    require(expiration > block.timestamp || expiration == 0, "Expiration date must be greater than block timestamp or zero");
  }

  /**
   * @dev Check is expiration date is past.
   */
  function _isExpired(uint256 expiration) internal view returns (bool) {
    return expiration != 0 && (block.timestamp >= expiration);
  }

  /**
   * @dev Retrieve hold hash, and ID for given parameters
   */
  function _retrieveHoldHashId(address token, bytes32 partition, address notary, address sender, address recipient, uint value) internal view returns (bytes32, bytes32) {
    // Pack and hash hold parameters
    bytes32 holdHash = keccak256(abi.encodePacked(
      token,
      partition,
      sender,
      recipient,
      notary,
      value
    ));
    bytes32 holdId = _holdIds[holdHash];

    return (holdHash, holdId);
  }  

  /**
   * @dev Check if hold can be executed
   */
  function _holdCanBeExecuted(Hold storage executableHold, uint value) internal view returns (bool) {
    if(!(executableHold.status == HoldStatusCode.Ordered || executableHold.status == HoldStatusCode.ExecutedAndKeptOpen)) {
      return false; // A hold can only be executed in status Ordered or ExecutedAndKeptOpen
    } else if(value == 0) {
      return false; // Value must be greater than zero
    } else if(_isExpired(executableHold.expiration)) {
      return false; // The hold has already expired
    } else if(value > executableHold.value) {
      return false; // The value should be equal or less than the held amount
    } else {
      return true;
    }
  }

  /**
   * @dev Check if hold can be executed as secret holder
   */
  function _holdCanBeExecutedAsSecretHolder(Hold storage executableHold, uint value, bytes32 secret) internal view returns (bool) {
    if(
      _checkSecret(executableHold, secret)
      && _holdCanBeExecuted(executableHold, value)) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Check if hold can be executed as notary
   */
  function _holdCanBeExecutedAsNotary(Hold storage executableHold, address operator, uint value) internal view returns (bool) {
    if(
      executableHold.notary == operator
      && _holdCanBeExecuted(executableHold, value)) {
      return true;
    } else {
      return false;
    }
  }  

  /**
   * @dev Retrieve hold data.
   */
  function retrieveHoldData(address token, bytes32 holdId) external override view returns (
    bytes32 partition,
    address sender,
    address recipient,
    address notary,
    uint256 value,
    uint256 expiration,
    bytes32 secretHash,
    bytes32 secret,
    HoldStatusCode status)
  {
    Hold storage retrievedHold = _holds[token][holdId];
    return (
      retrievedHold.partition,
      retrievedHold.sender,
      retrievedHold.recipient,
      retrievedHold.notary,
      retrievedHold.value,
      retrievedHold.expiration,
      retrievedHold.secretHash,
      retrievedHold.secret,
      retrievedHold.status
    );
  }

  /**
   * @dev Total supply on hold.
   */
  function totalSupplyOnHold(address token) external view returns (uint256) {
    return _totalHeldBalance[token];
  }

  /**
   * @dev Total supply on hold for a specific partition.
   */
  function totalSupplyOnHoldByPartition(address token, bytes32 partition) external view returns (uint256) {
    return _totalHeldBalanceByPartition[token][partition];
  }

  /**
   * @dev Get balance on hold of a tokenholder.
   */
  function balanceOnHold(address token, address account) external view returns (uint256) {
    return _heldBalance[token][account];
  }

  /**
   * @dev Get balance on hold of a tokenholder for a specific partition.
   */
  function balanceOnHoldByPartition(address token, bytes32 partition, address account) external view returns (uint256) {
    return _heldBalanceByPartition[token][account][partition];
  }

  /**
   * @dev Get spendable balance of a tokenholder.
   */
  function spendableBalanceOf(address token, address account) external view returns (uint256) {
    return _spendableBalanceOf(token, account);
  }

  /**
   * @dev Get spendable balance of a tokenholder for a specific partition.
   */
  function spendableBalanceOfByPartition(address token, bytes32 partition, address account) external view returns (uint256) {
    return _spendableBalanceOfByPartition(token, partition, account);
  }

  /**
   * @dev Get spendable balance of a tokenholder.
   */
  function _spendableBalanceOf(address token, address account) internal view returns (uint256) {
    return IERC20(token).balanceOf(account) - _heldBalance[token][account];
  }

  /**
   * @dev Get spendable balance of a tokenholder for a specific partition.
   */
  function _spendableBalanceOfByPartition(address token, bytes32 partition, address account) internal view returns (uint256) {
    return IERC1400(token).balanceOfByPartition(partition, account) - _heldBalanceByPartition[token][account][partition];
  }

  /**
   * @dev Check if hold (or pre-hold) can be created.
   * @return 'true' if the operator can create pre-holds, 'false' if not.
   */
  function _canHoldOrCanPreHold(address token, address operator, address sender, bytes memory certificate) internal returns(bool) { 
    (bool canValidateCertificate, CertificateValidation certificateControl, bytes32 salt) = _canValidateCertificateToken(token, msg.data, operator, certificate);
    _useCertificateIfActivated(token, certificateControl, operator, salt);

    if (sender != address(0)) { // hold
      return canValidateCertificate && (_isTokenController[token][operator] || operator == sender);
    } else { // pre-hold
      return canValidateCertificate && IMinterRole(token).isMinter(operator); 
    }
  }

  /**
   * @dev Check if validator is activated for the function called in the smart contract.
   * @param payload Payload of the initial transaction.
   * @return 'true' if the function requires validation, 'false' if not.
   */
  function _functionSupportsCertificateValidation(bytes memory payload) internal pure returns(bool) {
    bytes4 functionSig = _getFunctionSig(payload);
    if(functionSig == ERC20_TRANSFER_ID || functionSig == ERC20_TRANSFERFROM_ID) {
      return false;
    } else {
      return true;
    }
  }

  /**
   * @dev Use certificate, if validated.
   * @param token Token address.
   * @param certificateControl Type of certificate.
   * @param msgSender Transaction sender (only for nonce-based certificates).
   * @param salt Salt extracted from the certificate (only for salt-based certificates).
   */
  function _useCertificateIfActivated(address token, CertificateValidation certificateControl, address msgSender, bytes32 salt) internal {
    // Declare certificate as used
    if (certificateControl == CertificateValidation.NonceBased) {
      _usedCertificateNonce[token][msgSender] += 1;
    } else if (certificateControl == CertificateValidation.SaltBased) {
      _usedCertificateSalt[token][salt] = true;
    }
  }

  /**
   * @dev Extract function signature from payload.
   * @param payload Payload of the initial transaction.
   * @return Function signature.
   */
  function _getFunctionSig(bytes memory payload) internal pure returns(bytes4) {
    return (bytes4(payload[0]) | bytes4(payload[1]) >> 8 | bytes4(payload[2]) >> 16 | bytes4(payload[3]) >> 24);
  }

  /**
   * @dev Check if 'value' is multiple of 'granularity'.
   * @param granularity The granularity that want's to be checked.
   * @param value The quantity that want's to be checked.
   * @return 'true' if 'value' is a multiple of 'granularity'.
   */
  function _isMultiple(uint256 granularity, uint256 value) internal pure returns(bool) {
    return(value.div(granularity).mul(granularity) == value);
  }

  /**
   * @dev Get state of certificate (used or not).
   * @param token Token address.
   * @param sender Address whom to check the counter of.
   * @return uint256 Number of transaction already sent for this token contract.
   */
  function usedCertificateNonce(address token, address sender) external view returns (uint256) {
    return _usedCertificateNonce[token][sender];
  }

  /**
   * @dev Checks if a nonce-based certificate is correct
   * @param certificate Certificate to control
   */
  function _checkNonceBasedCertificate(
    address token,
    address msgSender,
    bytes memory payloadWithCertificate,
    bytes memory certificate
  )
    internal
    view
    returns(bool)
  {
    // Certificate should be 97 bytes long
    if (certificate.length != 97) {
      return false;
    }

    uint256 e;
    uint8 v;

    // Extract certificate information and expiration time from payload
    assembly {
      // Retrieve expirationTime & ECDSA element (v) from certificate which is a 97 long bytes
      // Certificate encoding format is: <expirationTime (32 bytes)>@<r (32 bytes)>@<s (32 bytes)>@<v (1 byte)>
      e := mload(add(certificate, 0x20))
      v := byte(0, mload(add(certificate, 0x80)))
    }

    // Certificate should not be expired
    if (e < block.timestamp) {
      return false;
    }

    if (v < 27) {
      v += 27;
    }

    // Perform ecrecover to ensure message information corresponds to certificate
    if (v == 27 || v == 28) {
      // Extract certificate from payload
      bytes memory payloadWithoutCertificate = new bytes(payloadWithCertificate.length.sub(160));
      for (uint i = 0; i < payloadWithCertificate.length.sub(160); i++) { // replace 4 bytes corresponding to function selector
        payloadWithoutCertificate[i] = payloadWithCertificate[i];
      }

      // Pack and hash
      bytes memory pack = abi.encodePacked(
        msgSender,
        token,
        payloadWithoutCertificate,
        e,
        _usedCertificateNonce[token][msgSender]
      );
      bytes32 hash = keccak256(
        abi.encodePacked(
          DomainAware(token).generateDomainSeparator(),
          keccak256(pack)
        )
      );

      bytes32 r;
      bytes32 s;
      // Extract certificate information and expiration time from payload
      assembly {
        // Retrieve ECDSA elements (r, s) from certificate which is a 97 long bytes
        // Certificate encoding format is: <expirationTime (32 bytes)>@<r (32 bytes)>@<s (32 bytes)>@<v (1 byte)>
        r := mload(add(certificate, 0x40))
        s := mload(add(certificate, 0x60))
      }

      // Check if certificate match expected transactions parameters
      if (isCertificateSigner(token, ecrecover(hash, v, r, s))) {
        return true;
      }
    }
    return false;
  }

  /**
   * @dev Get state of certificate (used or not).
   * @param token Token address.
   * @param salt First 32 bytes of certificate whose validity is being checked.
   * @return bool 'true' if certificate is already used, 'false' if not.
   */
  function usedCertificateSalt(address token, bytes32 salt) external view returns (bool) {
    return _usedCertificateSalt[token][salt];
  }

  /**
   * @dev Checks if a salt-based certificate is correct
   * @param certificate Certificate to control
   */
  function _checkSaltBasedCertificate(
    address token,
    address msgSender,
    bytes memory payloadWithCertificate,
    bytes memory certificate
  )
    internal
    view
    returns(bool, bytes32)
  {
    // Certificate should be 129 bytes long
    if (certificate.length != 129) {
      return (false, "");
    }

    bytes32 salt;
    uint256 e;
    uint8 v;

    // Extract certificate information and expiration time from payload
    assembly {
      // Retrieve expirationTime & ECDSA elements from certificate which is a 97 long bytes
      // Certificate encoding format is: <salt (32 bytes)>@<expirationTime (32 bytes)>@<r (32 bytes)>@<s (32 bytes)>@<v (1 byte)>
      salt := mload(add(certificate, 0x20))
      e := mload(add(certificate, 0x40))
      v := byte(0, mload(add(certificate, 0xa0)))
    }

    // Certificate should not be expired
    if (e < block.timestamp) {
      return (false, "");
    }

    if (v < 27) {
      v += 27;
    }

    // Perform ecrecover to ensure message information corresponds to certificate
    if (v == 27 || v == 28) {
      // Extract certificate from payload
      bytes memory payloadWithoutCertificate = new bytes(payloadWithCertificate.length.sub(192));
      for (uint i = 0; i < payloadWithCertificate.length.sub(192); i++) { // replace 4 bytes corresponding to function selector
        payloadWithoutCertificate[i] = payloadWithCertificate[i];
      }

      // Pack and hash
      bytes memory pack = abi.encodePacked(
        msgSender,
        token,
        payloadWithoutCertificate,
        e,
        salt
      );

      bytes32 hash = keccak256(
        abi.encodePacked(
          DomainAware(token).generateDomainSeparator(),
          keccak256(pack)
        )
      );

      bytes32 r;
      bytes32 s;
      // Extract certificate information and expiration time from payload
      assembly {
        // Retrieve ECDSA elements (r, s) from certificate which is a 97 long bytes
        // Certificate encoding format is: <expirationTime (32 bytes)>@<r (32 bytes)>@<s (32 bytes)>@<v (1 byte)>
        r := mload(add(certificate, 0x60))
        s := mload(add(certificate, 0x80))
      }

      // Check if certificate match expected transactions parameters
      if (isCertificateSigner(token, ecrecover(hash, v, r, s)) && !_usedCertificateSalt[token][salt]) {
        return (true, salt);
      }
    }
    return (false, "");
  }
}

pragma solidity ^0.8.0;

import "../roles/PauserRole.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is PauserRole {
    event Paused(address indexed token, address account);
    event Unpaused(address indexed token, address account);

    // Mapping from token to token paused status.
    mapping(address => bool) private _paused;

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused(address token) public view returns (bool) {
        return _paused[token];
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused(address token) {
        require(!_paused[token]);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused(address token) {
        require(_paused[token]);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause(address token) public onlyPauser(token) whenNotPaused(token) {
        _paused[token] = true;
        emit Paused(token, msg.sender);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause(address token) public onlyPauser(token) whenPaused(token) {
        _paused[token] = false;
        emit Unpaused(token, msg.sender);
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";


/// Base client to interact with the registry.
contract ERC1820Client {
    IERC1820Registry constant ERC1820REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    function setInterfaceImplementation(string memory _interfaceLabel, address _implementation) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        ERC1820REGISTRY.setInterfaceImplementer(address(this), interfaceHash, _implementation);
    }

    function interfaceAddr(address addr, string memory _interfaceLabel) internal view returns(address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return ERC1820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        ERC1820REGISTRY.setManager(address(this), _newManager);
    }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

abstract contract DomainAware {

    // Mapping of ChainID to domain separators. This is a very gas efficient way
    // to not recalculate the domain separator on every call, while still
    // automatically detecting ChainID changes.
    mapping(uint256 => bytes32) private domainSeparators;

    constructor() {
        _updateDomainSeparator();
    }

    function domainName() public virtual view returns (string memory);

    function domainVersion() public virtual view returns (string memory);

    function generateDomainSeparator() public view returns (bytes32) {
        uint256 chainID = _chainID();

        // no need for assembly, running very rarely
        bytes32 domainSeparatorHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(domainName())), // ERC-20 Name
                keccak256(bytes(domainVersion())), // Version
                chainID,
                address(this)
            )
        );

        return domainSeparatorHash;
    }

    function domainSeparator() public returns (bytes32) {
        return _domainSeparator();
    }

    function _updateDomainSeparator() private returns (bytes32) {
        uint256 chainID = _chainID();

        bytes32 newDomainSeparator = generateDomainSeparator();

        domainSeparators[chainID] = newDomainSeparator;

        return newDomainSeparator;
    }

    // Returns the domain separator, updating it if chainID changes
    function _domainSeparator() private returns (bytes32) {
        bytes32 currentDomainSeparator = domainSeparators[_chainID()];

        if (currentDomainSeparator != 0x00) {
            return currentDomainSeparator;
        }

        return _updateDomainSeparator();
    }

    function _chainID() internal view returns (uint256) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        return chainID;
    }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

import "./Roles.sol";


/**
 * @title PauserRole
 * @dev Pausers are responsible for pausing/unpausing transfers.
 */
abstract contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed token, address indexed account);
    event PauserRemoved(address indexed token, address indexed account);

    // Mapping from token to token pausers.
    mapping(address => Roles.Role) private _pausers;

    modifier onlyPauser(address token) virtual {
        require(isPauser(token, msg.sender));
        _;
    }

    function isPauser(address token, address account) public view returns (bool) {
        return _pausers[token].has(account);
    }

    function addPauser(address token, address account) public onlyPauser(token) {
        _addPauser(token, account);
    }

    function removePauser(address token, address account) public onlyPauser(token) {
        _removePauser(token, account);
    }

    function renouncePauser(address token) public {
        _removePauser(token, msg.sender);
    }

    function _addPauser(address token, address account) internal {
        _pausers[token].add(account);
        emit PauserAdded(token, account);
    }

    function _removePauser(address token, address account) internal {
        _pausers[token].remove(account);
        emit PauserRemoved(token, account);
    }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

import "./Roles.sol";


/**
 * @title CertificateSignerRole
 * @dev Certificate signers are responsible for signing certificates.
 */
abstract contract CertificateSignerRole {
    using Roles for Roles.Role;

    event CertificateSignerAdded(address indexed token, address indexed account);
    event CertificateSignerRemoved(address indexed token, address indexed account);

    // Mapping from token to token certificate signers.
    mapping(address => Roles.Role) private _certificateSigners;

    modifier onlyCertificateSigner(address token) virtual {
        require(isCertificateSigner(token, msg.sender));
        _;
    }

    function isCertificateSigner(address token, address account) public view returns (bool) {
        return _certificateSigners[token].has(account);
    }

    function addCertificateSigner(address token, address account) public onlyCertificateSigner(token) {
        _addCertificateSigner(token, account);
    }

    function removeCertificateSigner(address token, address account) public onlyCertificateSigner(token) {
        _removeCertificateSigner(token, account);
    }

    function renounceCertificateSigner(address token) public {
        _removeCertificateSigner(token, msg.sender);
    }

    function _addCertificateSigner(address token, address account) internal {
        _certificateSigners[token].add(account);
        emit CertificateSignerAdded(token, account);
    }

    function _removeCertificateSigner(address token, address account) internal {
        _certificateSigners[token].remove(account);
        emit CertificateSignerRemoved(token, account);
    }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

import "./Roles.sol";
import "./BlocklistAdminRole.sol";


/**
 * @title BlocklistedRole
 * @dev Blocklisted accounts have been forbidden by a BlocklistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are BlocklistAdmins (who can also remove
 * it), and not Blocklisteds themselves.
 */
abstract contract BlocklistedRole is BlocklistAdminRole {
    using Roles for Roles.Role;

    event BlocklistedAdded(address indexed token, address indexed account);
    event BlocklistedRemoved(address indexed token, address indexed account);

    // Mapping from token to token blocklisteds.
    mapping(address => Roles.Role) private _blocklisteds;

    modifier onlyNotBlocklisted(address token) {
        require(!isBlocklisted(token, msg.sender));
        _;
    }

    function isBlocklisted(address token, address account) public view returns (bool) {
        return _blocklisteds[token].has(account);
    }

    function addBlocklisted(address token, address account) public onlyBlocklistAdmin(token) {
        _addBlocklisted(token, account);
    }

    function removeBlocklisted(address token, address account) public onlyBlocklistAdmin(token) {
        _removeBlocklisted(token, account);
    }

    function _addBlocklisted(address token, address account) internal {
        _blocklisteds[token].add(account);
        emit BlocklistedAdded(token, account);
    }

    function _removeBlocklisted(address token, address account) internal {
        _blocklisteds[token].remove(account);
        emit BlocklistedRemoved(token, account);
    }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

import "./Roles.sol";


/**
 * @title BlocklistAdminRole
 * @dev BlocklistAdmins are responsible for assigning and removing Blocklisted accounts.
 */
abstract contract BlocklistAdminRole {
    using Roles for Roles.Role;

    event BlocklistAdminAdded(address indexed token, address indexed account);
    event BlocklistAdminRemoved(address indexed token, address indexed account);

    // Mapping from token to token blocklist admins.
    mapping(address => Roles.Role) private _blocklistAdmins;

    modifier onlyBlocklistAdmin(address token) virtual {
        require(isBlocklistAdmin(token, msg.sender));
        _;
    }

    function isBlocklistAdmin(address token, address account) public view returns (bool) {
        return _blocklistAdmins[token].has(account);
    }

    function addBlocklistAdmin(address token, address account) public onlyBlocklistAdmin(token) {
        _addBlocklistAdmin(token, account);
    }

    function removeBlocklistAdmin(address token, address account) public onlyBlocklistAdmin(token) {
        _removeBlocklistAdmin(token, account);
    }

    function renounceBlocklistAdmin(address token) public {
        _removeBlocklistAdmin(token, msg.sender);
    }

    function _addBlocklistAdmin(address token, address account) internal {
        _blocklistAdmins[token].add(account);
        emit BlocklistAdminAdded(token, account);
    }

    function _removeBlocklistAdmin(address token, address account) internal {
        _blocklistAdmins[token].remove(account);
        emit BlocklistAdminRemoved(token, account);
    }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

import "./Roles.sol";
import "./AllowlistAdminRole.sol";


/**
 * @title AllowlistedRole
 * @dev Allowlisted accounts have been forbidden by a AllowlistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are AllowlistAdmins (who can also remove
 * it), and not Allowlisteds themselves.
 */
abstract contract AllowlistedRole is AllowlistAdminRole {
    using Roles for Roles.Role;

    event AllowlistedAdded(address indexed token, address indexed account);
    event AllowlistedRemoved(address indexed token, address indexed account);

    // Mapping from token to token allowlisteds.
    mapping(address => Roles.Role) private _allowlisteds;

    modifier onlyNotAllowlisted(address token) {
        require(!isAllowlisted(token, msg.sender));
        _;
    }

    function isAllowlisted(address token, address account) public view returns (bool) {
        return _allowlisteds[token].has(account);
    }

    function addAllowlisted(address token, address account) public onlyAllowlistAdmin(token) {
        _addAllowlisted(token, account);
    }

    function removeAllowlisted(address token, address account) public onlyAllowlistAdmin(token) {
        _removeAllowlisted(token, account);
    }

    function _addAllowlisted(address token, address account) internal {
        _allowlisteds[token].add(account);
        emit AllowlistedAdded(token, account);
    }

    function _removeAllowlisted(address token, address account) internal {
        _allowlisteds[token].remove(account);
        emit AllowlistedRemoved(token, account);
    }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

import "./Roles.sol";


/**
 * @title AllowlistAdminRole
 * @dev AllowlistAdmins are responsible for assigning and removing Allowlisted accounts.
 */
abstract contract AllowlistAdminRole {
    using Roles for Roles.Role;

    event AllowlistAdminAdded(address indexed token, address indexed account);
    event AllowlistAdminRemoved(address indexed token, address indexed account);

    // Mapping from token to token allowlist admins.
    mapping(address => Roles.Role) private _allowlistAdmins;

    modifier onlyAllowlistAdmin(address token) virtual {
        require(isAllowlistAdmin(token, msg.sender));
        _;
    }

    function isAllowlistAdmin(address token, address account) public view returns (bool) {
        return _allowlistAdmins[token].has(account);
    }

    function addAllowlistAdmin(address token, address account) public onlyAllowlistAdmin(token) {
        _addAllowlistAdmin(token, account);
    }

    function removeAllowlistAdmin(address token, address account) public onlyAllowlistAdmin(token) {
        _removeAllowlistAdmin(token, account);
    }

    function renounceAllowlistAdmin(address token) public {
        _removeAllowlistAdmin(token, msg.sender);
    }

    function _addAllowlistAdmin(address token, address account) internal {
        _allowlistAdmins[token].add(account);
        emit AllowlistAdminAdded(token, account);
    }

    function _removeAllowlistAdmin(address token, address account) internal {
        _allowlistAdmins[token].remove(account);
        emit AllowlistAdminRemoved(token, account);
    }
}

pragma solidity ^0.8.0;

import "./HoldStatusCode.sol";

interface IHoldableERC1400TokenExtension {
    function executeHold(
        address token,
        bytes32 holdId,
        uint256 value,
        bytes32 lockPreimage
    ) external returns (bool);

    function retrieveHoldData(address token, bytes32 holdId) external view returns (
        bytes32 partition,
        address sender,
        address recipient,
        address notary,
        uint256 value,
        uint256 expiration,
        bytes32 secretHash,
        bytes32 secret,
        HoldStatusCode status
    );
}

pragma solidity ^0.8.0;

/// @title IERC1643 Document Management (part of the ERC1400 Security Token Standards)
/// @dev See https://github.com/SecurityTokenStandard/EIP-Spec

interface IERC1643 {

    // Document Management
    function getDocument(bytes32 _name) external view returns (string memory, bytes32, uint256);
    function setDocument(bytes32 _name, string memory _uri, bytes32 _documentHash) external;
    function removeDocument(bytes32 _name) external;
    function getAllDocuments() external view returns (bytes32[] memory);

    // Document Events
    event DocumentRemoved(bytes32 indexed name, string uri, bytes32 documentHash);
    event DocumentUpdated(bytes32 indexed name, string uri, bytes32 documentHash);

}

pragma solidity ^0.8.0;

enum HoldStatusCode {
    Nonexistent,
    Ordered,
    Executed,
    ExecutedAndKeptOpen,
    ReleasedByNotary,
    ReleasedByPayee,
    ReleasedOnExpiration
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;


contract ERC1820Implementer {
  bytes32 constant ERC1820_ACCEPT_MAGIC = keccak256(abi.encodePacked("ERC1820_ACCEPT_MAGIC"));

  mapping(bytes32 => bool) internal _interfaceHashes;

  function canImplementInterfaceForAddress(bytes32 interfaceHash, address /*addr*/) // Comments to avoid compilation warnings for unused variables.
    external
    view
    returns(bytes32)
  {
    if(_interfaceHashes[interfaceHash]) {
      return ERC1820_ACCEPT_MAGIC;
    } else {
      return "";
    }
  }

  function _setInterface(string memory interfaceLabel) internal {
    _interfaceHashes[keccak256(abi.encodePacked(interfaceLabel))] = true;
  }

}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

/**
 * @title IERC1400TokensValidator
 * @dev ERC1400TokensValidator interface
 */
interface IERC1400TokensValidator {
  
  /**
   * @dev Verify if a token transfer can be executed or not, on the validator's perspective.
   * @param token Token address.
   * @param payload Payload of the initial transaction.
   * @param partition Name of the partition (left empty for ERC20 transfer).
   * @param operator Address which triggered the balance decrease (through transfer or redemption).
   * @param from Token holder.
   * @param to Token recipient for a transfer and 0x for a redemption.
   * @param value Number of tokens the token holder balance is decreased by.
   * @param data Extra information.
   * @param operatorData Extra information, attached by the operator (if any).
   * @return 'true' if the token transfer can be validated, 'false' if not.
   */
  struct ValidateData {
    address token;
    bytes payload;
    bytes32 partition;
    address operator;
    address from;
    address to;
    uint value;
    bytes data;
    bytes operatorData;
  }

  function canValidate(ValidateData calldata data) external view returns(bool);

  function tokensToValidate(
    bytes calldata payload,
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint value,
    bytes calldata data,
    bytes calldata operatorData
  ) external;

}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// ****************** Document Management *******************
import "./interface/IERC1643.sol";

/**
 * @title IERC1400 security token standard
 * @dev See https://github.com/SecurityTokenStandard/EIP-Spec/blob/master/eip/eip-1400.md
 */
interface IERC1400 is IERC20, IERC1643 {

  // ******************* Token Information ********************
  function balanceOfByPartition(bytes32 partition, address tokenHolder) external view returns (uint256);
  function partitionsOf(address tokenHolder) external view returns (bytes32[] memory);

  // *********************** Transfers ************************
  function transferWithData(address to, uint256 value, bytes calldata data) external;
  function transferFromWithData(address from, address to, uint256 value, bytes calldata data) external;

  // *************** Partition Token Transfers ****************
  function transferByPartition(bytes32 partition, address to, uint256 value, bytes calldata data) external returns (bytes32);
  function operatorTransferByPartition(bytes32 partition, address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external returns (bytes32);
  function allowanceByPartition(bytes32 partition, address owner, address spender) external view returns (uint256);

  // ****************** Controller Operation ******************
  function isControllable() external view returns (bool);
  // function controllerTransfer(address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external; // removed because same action can be achieved with "operatorTransferByPartition"
  // function controllerRedeem(address tokenHolder, uint256 value, bytes calldata data, bytes calldata operatorData) external; // removed because same action can be achieved with "operatorRedeemByPartition"

  // ****************** Operator Management *******************
  function authorizeOperator(address operator) external;
  function revokeOperator(address operator) external;
  function authorizeOperatorByPartition(bytes32 partition, address operator) external;
  function revokeOperatorByPartition(bytes32 partition, address operator) external;

  // ****************** Operator Information ******************
  function isOperator(address operator, address tokenHolder) external view returns (bool);
  function isOperatorForPartition(bytes32 partition, address operator, address tokenHolder) external view returns (bool);

  // ********************* Token Issuance *********************
  function isIssuable() external view returns (bool);
  function issue(address tokenHolder, uint256 value, bytes calldata data) external;
  function issueByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes calldata data) external;

  // ******************** Token Redemption ********************
  function redeem(uint256 value, bytes calldata data) external;
  function redeemFrom(address tokenHolder, uint256 value, bytes calldata data) external;
  function redeemByPartition(bytes32 partition, uint256 value, bytes calldata data) external;
  function operatorRedeemByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes calldata operatorData) external;

  // ******************* Transfer Validity ********************
  // We use different transfer validity functions because those described in the interface don't allow to verify the certificate's validity.
  // Indeed, verifying the ecrtificate's validity requires to keeps the function's arguments in the exact same order as the transfer function.
  //
  // function canTransfer(address to, uint256 value, bytes calldata data) external view returns (byte, bytes32);
  // function canTransferFrom(address from, address to, uint256 value, bytes calldata data) external view returns (byte, bytes32);
  // function canTransferByPartition(address from, address to, bytes32 partition, uint256 value, bytes calldata data) external view returns (byte, bytes32, bytes32);    

  // ******************* Controller Events ********************
  // We don't use this event as we don't use "controllerTransfer"
  //   event ControllerTransfer(
  //       address controller,
  //       address indexed from,
  //       address indexed to,
  //       uint256 value,
  //       bytes data,
  //       bytes operatorData
  //   );
  //
  // We don't use this event as we don't use "controllerRedeem"
  //   event ControllerRedemption(
  //       address controller,
  //       address indexed tokenHolder,
  //       uint256 value,
  //       bytes data,
  //       bytes operatorData
  //   );

  // ******************** Transfer Events *********************
  event TransferByPartition(
      bytes32 indexed fromPartition,
      address operator,
      address indexed from,
      address indexed to,
      uint256 value,
      bytes data,
      bytes operatorData
  );

  event ChangedPartition(
      bytes32 indexed fromPartition,
      bytes32 indexed toPartition,
      uint256 value
  );

  // ******************** Operator Events *********************
  event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
  event RevokedOperator(address indexed operator, address indexed tokenHolder);
  event AuthorizedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);
  event RevokedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);

  // ************** Issuance / Redemption Events **************
  event Issued(address indexed operator, address indexed to, uint256 value, bytes data);
  event Redeemed(address indexed operator, address indexed from, uint256 value, bytes data);
  event IssuedByPartition(bytes32 indexed partition, address indexed operator, address indexed to, uint256 value, bytes data, bytes operatorData);
  event RedeemedByPartition(bytes32 indexed partition, address indexed operator, address indexed from, uint256 value, bytes operatorData);

}

/**
 * Reason codes - ERC-1066
 *
 * To improve the token holder experience, canTransfer MUST return a reason byte code
 * on success or failure based on the ERC-1066 application-specific status codes specified below.
 * An implementation can also return arbitrary data as a bytes32 to provide additional
 * information not captured by the reason code.
 * 
 * Code	Reason
 * 0x50	transfer failure
 * 0x51	transfer success
 * 0x52	insufficient balance
 * 0x53	insufficient allowance
 * 0x54	transfers halted (contract paused)
 * 0x55	funds locked (lockup period)
 * 0x56	invalid sender
 * 0x57	invalid receiver
 * 0x58	invalid operator (transfer agent)
 * 0x59	
 * 0x5a	
 * 0x5b	
 * 0x5a	
 * 0x5b	
 * 0x5c	
 * 0x5d	
 * 0x5e	
 * 0x5f	token meta or info
 *
 * These codes are being discussed at: https://ethereum-magicians.org/t/erc-1066-ethereum-status-codes-esc/283/24
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}