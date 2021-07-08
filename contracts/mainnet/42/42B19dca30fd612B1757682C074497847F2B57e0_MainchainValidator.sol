/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

// File: @axie/contract-library/contracts/math/SafeMath.sol

pragma solidity ^0.5.2;


library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a);
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b <= a);
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }

    c = a * b;
    require(c / a == b);
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Since Solidity automatically asserts when dividing by 0,
    // but we only need it to revert.
    require(b > 0);
    return a / b;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Same reason as `div`.
    require(b > 0);
    return a % b;
  }

  function ceilingDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    return add(div(a, b), mod(a, b) > 0 ? 1 : 0);
  }

  function subU64(uint64 a, uint64 b) internal pure returns (uint64 c) {
    require(b <= a);
    return a - b;
  }

  function addU8(uint8 a, uint8 b) internal pure returns (uint8 c) {
    c = a + b;
    require(c >= a);
  }
}

// File: @axie/contract-library/contracts/access/HasAdmin.sol

pragma solidity ^0.5.2;


contract HasAdmin {
  event AdminChanged(address indexed _oldAdmin, address indexed _newAdmin);
  event AdminRemoved(address indexed _oldAdmin);

  address public admin;

  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
  }

  constructor() internal {
    admin = msg.sender;
    emit AdminChanged(address(0), admin);
  }

  function changeAdmin(address _newAdmin) external onlyAdmin {
    require(_newAdmin != address(0));
    emit AdminChanged(admin, _newAdmin);
    admin = _newAdmin;
  }

  function removeAdmin() external onlyAdmin {
    emit AdminRemoved(admin);
    admin = address(0);
  }
}

// File: contracts/chain/common/IValidator.sol

pragma solidity ^0.5.17;


contract IValidator {
  event ValidatorAdded(uint256 indexed _id, address indexed _validator);
  event ValidatorRemoved(uint256 indexed _id, address indexed _validator);
  event ThresholdUpdated(
    uint256 indexed _id,
    uint256 indexed _numerator,
    uint256 indexed _denominator,
    uint256 _previousNumerator,
    uint256 _previousDenominator
  );

  function isValidator(address _addr) public view returns (bool);
  function getValidators() public view returns (address[] memory _validators);

  function checkThreshold(uint256 _voteCount) public view returns (bool);
}

// File: contracts/chain/common/Validator.sol

pragma solidity ^0.5.17;




contract Validator is IValidator {
  using SafeMath for uint256;

  mapping(address => bool) validatorMap;
  address[] public validators;
  uint256 public validatorCount;

  uint256 public num;
  uint256 public denom;

  constructor(address[] memory _validators, uint256 _num, uint256 _denom)
    public
  {
    validators = _validators;
    validatorCount = _validators.length;

    for (uint256 _i = 0; _i < validatorCount; _i++) {
      address _validator = _validators[_i];
      validatorMap[_validator] = true;
    }

    num = _num;
    denom = _denom;
  }

  function isValidator(address _addr)
    public
    view
    returns (bool)
  {
    return validatorMap[_addr];
  }

  function getValidators()
    public
    view
    returns (address[] memory _validators)
  {
    _validators = validators;
  }

  function checkThreshold(uint256 _voteCount)
    public
    view
    returns (bool)
  {
    return _voteCount.mul(denom) >= num.mul(validatorCount);
  }

  function _addValidator(uint256 _id, address _validator)
    internal
  {
    require(!validatorMap[_validator]);

    validators.push(_validator);
    validatorMap[_validator] = true;
    validatorCount++;

    emit ValidatorAdded(_id, _validator);
  }

  function _removeValidator(uint256 _id, address _validator)
    internal
  {
    require(isValidator(_validator));

    uint256 _index;
    for (uint256 _i = 0; _i < validatorCount; _i++) {
      if (validators[_i] == _validator) {
        _index = _i;
        break;
      }
    }

    validatorMap[_validator] = false;
    validators[_index] = validators[validatorCount - 1];
    validators.pop();

    validatorCount--;

    emit ValidatorRemoved(_id, _validator);
  }

  function _updateQuorum(uint256 _id, uint256 _numerator, uint256 _denominator)
    internal
  {
    require(_numerator <= _denominator);
    uint256 _previousNumerator = num;
    uint256 _previousDenominator = denom;

    num = _numerator;
    denom = _denominator;

    emit ThresholdUpdated(
      _id,
      _numerator,
      _denominator,
      _previousNumerator,
      _previousDenominator
    );
  }
}

// File: contracts/chain/mainchain/MainchainValidator.sol

pragma solidity ^0.5.17;




/**
 * @title Validator
 * @dev Simple validator contract
 */
contract MainchainValidator is Validator, HasAdmin {
  uint256 nonce;

  constructor(
    address[] memory _validators,
    uint256 _num,
    uint256 _denom
  ) Validator(_validators, _num, _denom) public {
  }

  function addValidators(address[] calldata _validators) external onlyAdmin {
    for (uint256 _i; _i < _validators.length; ++_i) {
      _addValidator(nonce++, _validators[_i]);
    }
  }

  function removeValidator(address _validator) external onlyAdmin {
    _removeValidator(nonce++, _validator);
  }

  function updateQuorum(uint256 _numerator, uint256 _denominator) external onlyAdmin {
    _updateQuorum(nonce++, _numerator, _denominator);
  }
}