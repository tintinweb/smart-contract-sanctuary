// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.24;



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts/interfaces/ERC677.sol

pragma solidity 0.4.24;


contract ERC677 is ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

    function transferAndCall(address, uint256, bytes) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool);
}

// File: contracts/interfaces/IBurnableMintableERC677Token.sol

pragma solidity 0.4.24;


contract IBurnableMintableERC677Token is ERC677 {
    function mint(address _to, uint256 _amount) public returns (bool);
    function burn(uint256 _value) public;
    function claimTokens(address _token, address _to) public;
}

// File: contracts/upgradeable_contracts/Sacrifice.sol

pragma solidity 0.4.24;

contract Sacrifice {
    constructor(address _recipient) public payable {
        selfdestruct(_recipient);
    }
}

// File: contracts/libraries/Address.sol

pragma solidity 0.4.24;


/**
 * @title Address
 * @dev Helper methods for Address type.
 */
library Address {
    /**
    * @dev Try to send native tokens to the address. If it fails, it will force the transfer by creating a selfdestruct contract
    * @param _receiver address that will receive the native tokens
    * @param _value the amount of native tokens to send
    */
    function safeSendValue(address _receiver, uint256 _value) internal {
        if (!_receiver.send(_value)) {
            (new Sacrifice).value(_value)(_receiver);
        }
    }
}

// File: contracts/upgradeability/EternalStorage.sol

pragma solidity 0.4.24;

/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {
    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;

}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: contracts/interfaces/IRewardableValidators.sol

pragma solidity 0.4.24;

interface IRewardableValidators {
    function isValidator(address _validator) external view returns (bool);
    function requiredSignatures() external view returns (uint256);
    function owner() external view returns (address);
    function validatorList() external view returns (address[]);
    function getValidatorRewardAddress(address _validator) external view returns (address);
    function validatorCount() external view returns (uint256);
    function getNextValidator(address _address) external view returns (address);
}

// File: contracts/upgradeable_contracts/FeeTypes.sol

pragma solidity 0.4.24;

contract FeeTypes {
    bytes32 internal constant HOME_FEE = 0x89d93e5e92f7e37e490c25f0e50f7f4aad7cc94b308a566553280967be38bcf1; // keccak256(abi.encodePacked("home-fee"))
    bytes32 internal constant FOREIGN_FEE = 0xdeb7f3adca07d6d1f708c1774389db532a2b2f18fd05a62b957e4089f4696ed5; // keccak256(abi.encodePacked("foreign-fee"))
}

// File: contracts/upgradeable_contracts/BaseFeeManager.sol

pragma solidity 0.4.24;





contract BaseFeeManager is EternalStorage, FeeTypes {
    using SafeMath for uint256;

    event HomeFeeUpdated(uint256 fee);
    event ForeignFeeUpdated(uint256 fee);

    // This is not a real fee value but a relative value used to calculate the fee percentage
    uint256 internal constant MAX_FEE = 1 ether;
    bytes32 internal constant HOME_FEE_STORAGE_KEY = 0xc3781f3cec62d28f56efe98358f59c2105504b194242dbcb2cc0806850c306e7; // keccak256(abi.encodePacked("homeFee"))
    bytes32 internal constant FOREIGN_FEE_STORAGE_KEY = 0x68c305f6c823f4d2fa4140f9cf28d32a1faccf9b8081ff1c2de11cf32c733efc; // keccak256(abi.encodePacked("foreignFee"))

    function calculateFee(uint256 _value, bool _recover, bytes32 _feeType) public view returns (uint256) {
        uint256 fee = _feeType == HOME_FEE ? getHomeFee() : getForeignFee();
        if (!_recover) {
            return _value.mul(fee).div(MAX_FEE);
        }
        return _value.mul(fee).div(MAX_FEE.sub(fee));
    }

    modifier validFee(uint256 _fee) {
        require(_fee < MAX_FEE);
        /* solcov ignore next */
        _;
    }

    function setHomeFee(uint256 _fee) external validFee(_fee) {
        uintStorage[HOME_FEE_STORAGE_KEY] = _fee;
        emit HomeFeeUpdated(_fee);
    }

    function getHomeFee() public view returns (uint256) {
        return uintStorage[HOME_FEE_STORAGE_KEY];
    }

    function setForeignFee(uint256 _fee) external validFee(_fee) {
        uintStorage[FOREIGN_FEE_STORAGE_KEY] = _fee;
        emit ForeignFeeUpdated(_fee);
    }

    function getForeignFee() public view returns (uint256) {
        return uintStorage[FOREIGN_FEE_STORAGE_KEY];
    }

    /* solcov ignore next */
    function distributeFeeFromAffirmation(uint256 _fee) external;

    /* solcov ignore next */
    function distributeFeeFromSignatures(uint256 _fee) external;

    /* solcov ignore next */
    function getFeeManagerMode() external pure returns (bytes4);

    function random(uint256 _count) internal view returns (uint256) {
        return uint256(blockhash(block.number.sub(1))) % _count;
    }
}

// File: contracts/upgradeable_contracts/ValidatorStorage.sol

pragma solidity 0.4.24;

contract ValidatorStorage {
    bytes32 internal constant VALIDATOR_CONTRACT = 0x5a74bb7e202fb8e4bf311841c7d64ec19df195fee77d7e7ae749b27921b6ddfe; // keccak256(abi.encodePacked("validatorContract"))
}

// File: contracts/upgradeable_contracts/ValidatorsFeeManager.sol

pragma solidity 0.4.24;




contract ValidatorsFeeManager is BaseFeeManager, ValidatorStorage {
    bytes32 public constant REWARD_FOR_TRANSFERRING_FROM_HOME = 0x2a11db67c480122765825a7e4bc5428e8b7b9eca0d4e62b91aac194f99edd0d7; // keccak256(abi.encodePacked("reward-transferring-from-home"))
    bytes32 public constant REWARD_FOR_TRANSFERRING_FROM_FOREIGN = 0xb14796d751eb4f2570065a479f9e526eabeb2077c564c8a1c5ea559883ea2fab; // keccak256(abi.encodePacked("reward-transferring-from-foreign"))

    function distributeFeeFromAffirmation(uint256 _fee) external {
        distributeFeeProportionally(_fee, REWARD_FOR_TRANSFERRING_FROM_FOREIGN);
    }

    function distributeFeeFromSignatures(uint256 _fee) external {
        distributeFeeProportionally(_fee, REWARD_FOR_TRANSFERRING_FROM_HOME);
    }

    function rewardableValidatorContract() internal view returns (IRewardableValidators) {
        return IRewardableValidators(addressStorage[VALIDATOR_CONTRACT]);
    }

    function distributeFeeProportionally(uint256 _fee, bytes32 _direction) internal {
        IRewardableValidators validators = rewardableValidatorContract();
        // solhint-disable-next-line var-name-mixedcase
        address F_ADDR = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
        uint256 numOfValidators = validators.validatorCount();

        uint256 feePerValidator = _fee.div(numOfValidators);

        uint256 randomValidatorIndex;
        uint256 diff = _fee.sub(feePerValidator.mul(numOfValidators));
        if (diff > 0) {
            randomValidatorIndex = random(numOfValidators);
        }

        address nextValidator = validators.getNextValidator(F_ADDR);
        require((nextValidator != F_ADDR) && (nextValidator != address(0)));

        uint256 i = 0;
        while (nextValidator != F_ADDR) {
            uint256 feeToDistribute = feePerValidator;
            if (diff > 0 && randomValidatorIndex == i) {
                feeToDistribute = feeToDistribute.add(diff);
            }

            address rewardAddress = validators.getValidatorRewardAddress(nextValidator);
            onFeeDistribution(rewardAddress, feeToDistribute, _direction);

            nextValidator = validators.getNextValidator(nextValidator);
            require(nextValidator != address(0));
            i = i + 1;
        }
    }

    function onFeeDistribution(address _rewardAddress, uint256 _fee, bytes32 _direction) internal {
        if (_direction == REWARD_FOR_TRANSFERRING_FROM_FOREIGN) {
            onAffirmationFeeDistribution(_rewardAddress, _fee);
        } else {
            onSignatureFeeDistribution(_rewardAddress, _fee);
        }
    }

    /* solcov ignore next */
    function onAffirmationFeeDistribution(address _rewardAddress, uint256 _fee) internal;

    /* solcov ignore next */
    function onSignatureFeeDistribution(address _rewardAddress, uint256 _fee) internal;
}

// File: contracts/upgradeable_contracts/ERC677Storage.sol

pragma solidity 0.4.24;

contract ERC677Storage {
    bytes32 internal constant ERC677_TOKEN = 0xa8b0ade3e2b734f043ce298aca4cc8d19d74270223f34531d0988b7d00cba21d; // keccak256(abi.encodePacked("erc677token"))
}

// File: contracts/upgradeable_contracts/native_to_erc20/FeeManagerNativeToErc.sol

pragma solidity 0.4.24;





contract FeeManagerNativeToErc is ValidatorsFeeManager, ERC677Storage {
    function getFeeManagerMode() external pure returns (bytes4) {
        return 0xf2aed8f7; // bytes4(keccak256(abi.encodePacked("manages-one-direction")))
    }

    function erc677token() public view returns (IBurnableMintableERC677Token) {
        return IBurnableMintableERC677Token(addressStorage[ERC677_TOKEN]);
    }

    function onAffirmationFeeDistribution(address _rewardAddress, uint256 _fee) internal {
        Address.safeSendValue(_rewardAddress, _fee);
    }

    function onSignatureFeeDistribution(address _rewardAddress, uint256 _fee) internal {
        erc677token().mint(_rewardAddress, _fee);
    }
}