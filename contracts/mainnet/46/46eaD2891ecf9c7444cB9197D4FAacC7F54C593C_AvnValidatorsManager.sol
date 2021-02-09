/**
 *Submitted for verification at Etherscan.io on 2021-02-09
*/

// File: contracts\interfaces\IAvnValidatorsManager.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IAvnValidatorsManager {
  event LogValidatorDepositUpdated(uint256 validatorDeposit);
  event LogValidatorChallengeWindowUpdated(uint256 challengeWindowInSeconds);
  event LogQuorumUpdated(uint256[2] quorum);
  event LogValidatorRegistered(bytes32 indexed t1PublicKeyLHS, bytes32 indexed t1PublicKeyRHS, bytes32 indexed t2PublicKey,
      uint256 validatorId);
  event LogValidatorActivated(address indexed t1Address, bytes32 indexed t2PublicKey, uint256 indexed t2TransactionId,
      uint256 validatorId);
  event LogValidatorDeregistered(address indexed t1Address, bytes32 indexed t2PublicKey, uint256 indexed t2TransactionId,
      uint256 validatorId);
  event LogValidatorSlashed(address indexed t1Address, bytes32 indexed t2PublicKey, uint256 indexed t2TransactionId,
      uint256 slashedAmount);
  event LogValidatorDepositClaimed(address indexed t1Address);
  event LogRootPublished(bytes32 indexed rootHash, uint256 indexed t2TransactionId);

  function disableValidatorFunctions(bool _isDisabled) external;
  function setValidatorDeposit(uint256 validatorDeposit) external;
  function setValidatorChallengeWindow(uint256 challengeWindowInSeconds) external;
  function setQuorum(uint256[2] calldata quorum) external;
  function initialiseAvn(address[] calldata t1Address, bytes32[] calldata t1PublicKeyLHS, bytes32[] calldata t1PublicKeyRHS,
      bytes32[] calldata t2PublicKey) external;
  function registerValidator(bytes calldata t1PublicKey, bytes32 t2PublicKey) external;
  function activateValidator(bytes32 targetT2PublicKey, uint256 t2TransactionId, bytes calldata confirmations) external;
  function deregisterValidator(bytes32 targetT2PublicKey, uint256 t2TransactionId, bytes calldata confirmations) external;
  function claimValidatorDeposit(bytes32 t2PublicKey) external;
  function slashValidator(bytes32 targetT2PublicKey, uint256 t2TransactionId, bytes calldata confirmations) external;
  function publishRoot(bytes32 rootHash, uint256 t2TransactionId, bytes calldata confirmations) external;
  function retire() external;
}

// File: contracts\interfaces\IAvnStorage.sol


pragma solidity 0.7.5;

interface IAvnStorage {
  event LogStoragePermissionUpdated(address indexed publisher, bool status);

  function setStoragePermission(address publisher, bool status) external;
  function storeT2TransactionId(uint256 _t2TransactionId) external;
  function storeT2TransactionIdAndRoot(uint256 _t2TransactionId, bytes32 rootHash) external;
  function confirmLeaf(bytes32 leafHash, bytes32[] memory merklePath) external view returns (bool);
}

// File: contracts\interfaces\IAvnFTTreasury.sol


pragma solidity 0.7.5;

interface IAvnFTTreasury {
  event LogFTTreasuryPermissionUpdated(address indexed treasurer, bool status);

  function setTreasurerPermission(address treasurer, bool status) external;
  function getTreasurers() external view returns(address[] memory);
  function unlockERC777Tokens(address token, uint256 amount, bytes calldata data) external;
  function unlockERC20Tokens(address token, uint256 amount) external;
}

// File: contracts\interfaces\IERC20.sol


pragma solidity 0.7.5;

// As described in https://eips.ethereum.org/EIPS/eip-20
interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function name() external view returns (string memory); // optional method - see eip spec
  function symbol() external view returns (string memory); // optional method - see eip spec
  function decimals() external view returns (uint8); // optional method - see eip spec
  function totalSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
}

// File: contracts\Owned.sol


pragma solidity 0.7.5;

contract Owned {

  address public owner = msg.sender;

  event LogOwnershipTransferred(address indexed owner, address indexed newOwner);

  modifier onlyOwner {
    require(msg.sender == owner, "Only owner");
    _;
  }

  function setOwner(address _owner)
    external
    onlyOwner
  {
    require(_owner != address(0), "Owner cannot be zero address");
    emit LogOwnershipTransferred(owner, _owner);
    owner = _owner;
  }
}

// File: ..\contracts\AvnValidatorsManager.sol


pragma solidity 0.7.5;

contract AvnValidatorsManager is IAvnValidatorsManager, Owned {

  uint256 constant internal SIGNATURE_LENGTH = 65;

  IERC20 immutable public avt;
  IAvnStorage immutable public avnStorage;
  IAvnFTTreasury immutable public avnFTTreasury;

  uint256 public validatorDeposit;
  uint256 public validatorChallengeWindowInSeconds;
  uint256[2] public quorum;

  uint256 public numActiveValidators;
  uint256 public validatorIdNum;
  bool public validatorFunctionsDisabled;
  bool public avnInitialised;

  // Validator data
  mapping (uint256 => address) public t1Address;
  mapping (uint256 => bytes32) public t2PublicKey;
  mapping (uint256 => uint256) public deposit;
  mapping (uint256 => bool) public isRegistered;
  mapping (uint256 => bool) public isActive;
  mapping (uint256 => bool) public isDeregistered;
  mapping (uint256 => uint256) public challengeEnd;
  mapping (address => uint256) public idByT1Address;
  mapping (bytes32 => uint256) public idByT2PublicKey;

  constructor(IERC20 _avt, IAvnStorage _avnStorage, IAvnFTTreasury _avnFTTreasury, uint256 _validatorDeposit,
      uint256 _validatorChallengeWindowInSeconds, uint256[2] memory _quorum)
  {
    avt = _avt;
    avnStorage = _avnStorage;
    avnFTTreasury = _avnFTTreasury;
    validatorDeposit = _validatorDeposit;
    validatorChallengeWindowInSeconds = _validatorChallengeWindowInSeconds;
    setQuorum(_quorum);
    validatorIdNum = 1;
  }

  modifier onlyWhenValidatorFunctionsEnabled() {
    require(!validatorFunctionsDisabled && avnInitialised, "Function currently disabled");
    _;
  }

  modifier onlyUniqueTransaction(uint256 _t2TransactionId) {
    avnStorage.storeT2TransactionId(_t2TransactionId);
    _;
  }

  function disableValidatorFunctions(bool _isDisabled)
    onlyOwner
    external
    override
  {
    validatorFunctionsDisabled = _isDisabled;
  }

  function setValidatorDeposit(uint256 _validatorDeposit)
    onlyOwner
    external
    override
  {
    validatorDeposit = _validatorDeposit;
    emit LogValidatorDepositUpdated(validatorDeposit);
  }

  function setValidatorChallengeWindow(uint256 _validatorChallengeWindowInSeconds)
    onlyOwner
    external
    override
  {
    validatorChallengeWindowInSeconds = _validatorChallengeWindowInSeconds;
    emit LogValidatorChallengeWindowUpdated(_validatorChallengeWindowInSeconds);
  }

  function initialiseAvn(address[] calldata _t1Address, bytes32[] calldata _t1PublicKeyLHS, bytes32[] calldata _t1PublicKeyRHS,
      bytes32[] calldata _t2PublicKey)
    onlyOwner
    external
    override
  {
    require(!avnInitialised, "AVN already initialised");
    require(_t1Address.length == _t1PublicKeyLHS.length && _t1PublicKeyLHS.length == _t1PublicKeyRHS.length
        && _t1PublicKeyRHS.length == _t2PublicKey.length, "Validator keys missing");

    uint256 targetId;
    bytes memory t1PublicKey;

    for (uint256 i; i < _t1Address.length; i++) {
      t1PublicKey = abi.encodePacked(_t1PublicKeyLHS[i], _t1PublicKeyRHS[i]);
      doRegisterValidator(_t1Address[i], t1PublicKey, _t2PublicKey[i]);
      targetId = idByT1Address[_t1Address[i]];
      isActive[targetId] = true;
      numActiveValidators++;
      emit LogValidatorActivated(_t1Address[i], _t2PublicKey[i], 0, targetId);
    }

    avnInitialised = true;
  }

  function registerValidator(bytes calldata _t1PublicKey, bytes32 _t2PublicKey)
    onlyWhenValidatorFunctionsEnabled
    external
    override
  {
    doRegisterValidator(msg.sender, _t1PublicKey, _t2PublicKey);
  }

  function activateValidator(bytes32 _targetT2PublicKey, uint256 _t2TransactionId, bytes calldata _confirmations)
    onlyWhenValidatorFunctionsEnabled
    onlyUniqueTransaction(_t2TransactionId)
    external
    override
  {
    uint256 targetId = idByT2PublicKey[_targetT2PublicKey];
    require(!isActive[targetId], "Target already active");
    require(isRegistered[targetId], "Target must be registered");
    verifyConfirmations(toConfirmationHash(_targetT2PublicKey, _t2TransactionId), _confirmations);
    isActive[targetId] = true;
    numActiveValidators++;
    emit LogValidatorActivated(t1Address[targetId], _targetT2PublicKey, _t2TransactionId, targetId);
  }

  function deregisterValidator(bytes32 _targetT2PublicKey, uint256 _t2TransactionId, bytes calldata _confirmations)
    onlyWhenValidatorFunctionsEnabled
    onlyUniqueTransaction(_t2TransactionId)
    external
    override
  {
    uint256 targetId = idByT2PublicKey[_targetT2PublicKey];
    require(isRegistered[targetId], "Target not currently registered");
    deregisterAndDeactivateValidator(targetId);
    verifyConfirmations(toConfirmationHash(_targetT2PublicKey, _t2TransactionId), _confirmations);
    challengeEnd[targetId] = block.timestamp + validatorChallengeWindowInSeconds;
    emit LogValidatorDeregistered(t1Address[targetId], _targetT2PublicKey, _t2TransactionId, targetId);
  }

  function claimValidatorDeposit(bytes32 _t2PublicKey)
    onlyWhenValidatorFunctionsEnabled
    external
    override
  {
    uint256 id = idByT2PublicKey[_t2PublicKey];
    uint256 lockedDeposit = deposit[id];

    require(lockedDeposit != 0, "Has no deposit");
    require(isDeregistered[id] == true, 'Must be deregistered first');
    require(challengeEnd[id] <= block.timestamp, "Cannot withdraw yet");
    deposit[id] = 0;
    challengeEnd[id] = 0;
    unlockAVTFromTreasuryAndTransfer(t1Address[id], lockedDeposit);
    emit LogValidatorDepositClaimed(t1Address[id]);
  }

  function slashValidator(bytes32 _targetT2PublicKey, uint256 _t2TransactionId, bytes calldata _confirmations)
    onlyWhenValidatorFunctionsEnabled
    onlyUniqueTransaction(_t2TransactionId)
    external
    override
  {
    uint256 targetId = idByT2PublicKey[_targetT2PublicKey];
    require(targetId != 0, "Validator does not exist");

    deregisterAndDeactivateValidator(targetId);
    verifyConfirmations(toConfirmationHash(_targetT2PublicKey, _t2TransactionId), _confirmations);
    uint256 lockedDeposit = deposit[targetId];
    deposit[targetId] = 0;
    challengeEnd[targetId] = 0;
    unlockAVTFromTreasuryAndTransfer(owner, lockedDeposit);
    emit LogValidatorSlashed(t1Address[targetId], _targetT2PublicKey, _t2TransactionId, lockedDeposit);
  }

  function publishRoot(bytes32 _rootHash, uint256 _t2TransactionId, bytes calldata _confirmations)
    onlyWhenValidatorFunctionsEnabled
    external
    override
  {
    avnStorage.storeT2TransactionIdAndRoot(_t2TransactionId, _rootHash);
    verifyConfirmations(toConfirmationHash(_rootHash, _t2TransactionId), _confirmations);
    emit LogRootPublished(_rootHash, _t2TransactionId);
  }

  function retire()
    onlyOwner
    external
    override
  {
    selfdestruct(payable(owner));
  }

  function setQuorum(uint256[2] memory _quorum)
    onlyOwner
    public
    override
  {
    require(_quorum[1] != 0, "Invalid: div by zero");
    require(_quorum[0] <= _quorum[1], "Invalid: above 100%");
    quorum = _quorum;
    emit LogQuorumUpdated(quorum);
  }

  function doRegisterValidator(address _t1Address, bytes memory _t1PublicKey, bytes32 _t2PublicKey)
    private
  {
    uint256 id = idByT1Address[_t1Address];
    require(!isRegistered[id], "Already registered");
    checkT1PublicKey(_t1Address, _t1PublicKey);

    if (isDeregistered[id]) {
      require(t2PublicKey[id] == _t2PublicKey, "Cannot change T2 public key");
      uint256 existingDeposit = deposit[id];
      deposit[id] = validatorDeposit;
      isRegistered[id] = true;
      isDeregistered[id] = false;
      challengeEnd[id] = 0;
      if (existingDeposit > validatorDeposit) {
        unlockAVTFromTreasuryAndTransfer(_t1Address, existingDeposit - validatorDeposit);
      } else if (existingDeposit < validatorDeposit) {
        lockAVTInTreasury(_t1Address, validatorDeposit - existingDeposit);
      }
    } else {
      require(idByT2PublicKey[_t2PublicKey] == 0, "T2 public key already associated");
      lockAVTInTreasury(_t1Address, validatorDeposit);
      id = validatorIdNum;
      idByT1Address[_t1Address] = id;
      isRegistered[id] = true;
      t1Address[id] = _t1Address;
      t2PublicKey[id] = _t2PublicKey;
      deposit[id] = validatorDeposit;
      idByT2PublicKey[_t2PublicKey] = id;
      validatorIdNum++;
    }

    bytes memory t1PublicKey = _t1PublicKey;
    bytes32 t1PublicKeyLHS;
    bytes32 t1PublicKeyRHS;

    assembly {
      t1PublicKeyLHS := mload(add(t1PublicKey, 0x20))
      t1PublicKeyRHS := mload(add(t1PublicKey, 0x40))
    }

    emit LogValidatorRegistered(t1PublicKeyLHS, t1PublicKeyRHS, _t2PublicKey, id);
  }

  function unlockAVTFromTreasuryAndTransfer(address _recipient, uint256 _amount)
    private
  {
    avnFTTreasury.unlockERC20Tokens(address(avt), _amount);
    assert(avt.transfer(_recipient, _amount));
  }

  function lockAVTInTreasury(address _t1Address, uint256 _amount)
    private
  {
    require(avt.balanceOf(_t1Address) >= _amount, 'Insufficient AVT funds');
    require(avt.allowance(_t1Address, address(this)) >= _amount, 'AVT amount requires approval');
    assert(avt.transferFrom(_t1Address, address(this), _amount));
    // locks the AVT in the treasury
    assert(avt.transfer(address(avnFTTreasury), _amount));
  }

  function toConfirmationHash(bytes32 _data, uint256 _t2TransactionId)
    private
    view
    returns (bytes32)
  {
    return keccak256(abi.encode(_data, _t2TransactionId, t2PublicKey[idByT1Address[msg.sender]]));
  }

  function verifyConfirmations(bytes32 _msgHash, bytes memory _confirmations)
    private
    view
  {
    require(isActive[idByT1Address[msg.sender]], "Must be an active validator");
    bytes32 ethSignedPrefixMsgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _msgHash));
    uint256 numConfirmations = _confirmations.length / SIGNATURE_LENGTH;
    uint256 requiredConfirmations = numActiveValidators * quorum[0] / quorum[1] + 1;
    uint256 validConfirmations;
    uint256 id;
    bytes32 r;
    bytes32 s;
    uint8 v;
    bool[] memory confirmed = new bool[](validatorIdNum);

    for (uint256 i; i < numConfirmations; i++) {
      assembly {
        let offset := mul(i, SIGNATURE_LENGTH)
        r := mload(add(_confirmations, add(0x20, offset)))
        s := mload(add(_confirmations, add(0x40, offset)))
        v := byte(0, mload(add(_confirmations, add(0x60, offset))))
      }
      if (v < 27) v += 27;
      if (v != 27 && v != 28 || uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0)
        continue;
      else {
        id = idByT1Address[ecrecover(ethSignedPrefixMsgHash, v, r, s)];
        if (isActive[id] && !confirmed[id]) {
          if (++validConfirmations == requiredConfirmations) break;
          confirmed[id] = true;
        }
      }
    }

    require(validConfirmations == requiredConfirmations, "Invalid confirmations");
  }

  function checkT1PublicKey(address _t1Address, bytes memory _t1PublicKey)
    private
    pure
  {
    require(_t1PublicKey.length == 64, "T1 public key must be 64 bytes");
    require(address(bytes20(uint160(uint256(keccak256(abi.encodePacked(_t1PublicKey)))))) == _t1Address, "Bad T1 public key");
  }

  function deregisterAndDeactivateValidator(uint256 _targetId)
    private
  {
    isRegistered[_targetId] = false;
    isDeregistered[_targetId] = true;
    if (isActive[_targetId]) {
      isActive[_targetId] = false;
      numActiveValidators--;
    }
  }
}