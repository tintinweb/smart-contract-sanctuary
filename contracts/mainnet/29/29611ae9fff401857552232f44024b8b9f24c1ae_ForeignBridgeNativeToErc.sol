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

// File: contracts/interfaces/IBridgeValidators.sol

pragma solidity 0.4.24;

interface IBridgeValidators {
    function isValidator(address _validator) external view returns (bool);
    function requiredSignatures() external view returns (uint256);
    function owner() external view returns (address);
}

// File: contracts/upgradeable_contracts/ValidatorStorage.sol

pragma solidity 0.4.24;

contract ValidatorStorage {
    bytes32 internal constant VALIDATOR_CONTRACT = 0x5a74bb7e202fb8e4bf311841c7d64ec19df195fee77d7e7ae749b27921b6ddfe; // keccak256(abi.encodePacked("validatorContract"))
}

// File: contracts/upgradeable_contracts/Validatable.sol

pragma solidity 0.4.24;




contract Validatable is EternalStorage, ValidatorStorage {
    function validatorContract() public view returns (IBridgeValidators) {
        return IBridgeValidators(addressStorage[VALIDATOR_CONTRACT]);
    }

    modifier onlyValidator() {
        require(validatorContract().isValidator(msg.sender));
        /* solcov ignore next */
        _;
    }

    function requiredSignatures() public view returns (uint256) {
        return validatorContract().requiredSignatures();
    }

}

// File: contracts/libraries/Message.sol

pragma solidity 0.4.24;


library Message {
    // function uintToString(uint256 inputValue) internal pure returns (string) {
    //     // figure out the length of the resulting string
    //     uint256 length = 0;
    //     uint256 currentValue = inputValue;
    //     do {
    //         length++;
    //         currentValue /= 10;
    //     } while (currentValue != 0);
    //     // allocate enough memory
    //     bytes memory result = new bytes(length);
    //     // construct the string backwards
    //     uint256 i = length - 1;
    //     currentValue = inputValue;
    //     do {
    //         result[i--] = byte(48 + currentValue % 10);
    //         currentValue /= 10;
    //     } while (currentValue != 0);
    //     return string(result);
    // }

    function addressArrayContains(address[] array, address value) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }
    // layout of message :: bytes:
    // offset  0: 32 bytes :: uint256 - message length
    // offset 32: 20 bytes :: address - recipient address
    // offset 52: 32 bytes :: uint256 - value
    // offset 84: 32 bytes :: bytes32 - transaction hash
    // offset 104: 20 bytes :: address - contract address to prevent double spending

    // mload always reads 32 bytes.
    // so we can and have to start reading recipient at offset 20 instead of 32.
    // if we were to read at 32 the address would contain part of value and be corrupted.
    // when reading from offset 20 mload will read 12 bytes (most of them zeros) followed
    // by the 20 recipient address bytes and correctly convert it into an address.
    // this saves some storage/gas over the alternative solution
    // which is padding address to 32 bytes and reading recipient at offset 32.
    // for more details see discussion in:
    // https://github.com/paritytech/parity-bridge/issues/61
    function parseMessage(bytes message)
        internal
        pure
        returns (address recipient, uint256 amount, bytes32 txHash, address contractAddress)
    {
        require(isMessageValid(message));
        assembly {
            recipient := mload(add(message, 20))
            amount := mload(add(message, 52))
            txHash := mload(add(message, 84))
            contractAddress := mload(add(message, 104))
        }
    }

    function isMessageValid(bytes _msg) internal pure returns (bool) {
        return _msg.length == requiredMessageLength();
    }

    function requiredMessageLength() internal pure returns (uint256) {
        return 104;
    }

    function recoverAddressFromSignedMessage(bytes signature, bytes message, bool isAMBMessage)
        internal
        pure
        returns (address)
    {
        require(signature.length == 65);
        bytes32 r;
        bytes32 s;
        bytes1 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := mload(add(signature, 0x60))
        }
        return ecrecover(hashMessage(message, isAMBMessage), uint8(v), r, s);
    }

    function hashMessage(bytes message, bool isAMBMessage) internal pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n";
        if (isAMBMessage) {
            return keccak256(abi.encodePacked(prefix, uintToString(message.length), message));
        } else {
            string memory msgLength = "104";
            return keccak256(abi.encodePacked(prefix, msgLength, message));
        }
    }

    /**
    * @dev Validates provided signatures, only first requiredSignatures() number
    * of signatures are going to be validated, these signatures should be from different validators.
    * @param _message bytes message used to generate signatures
    * @param _signatures bytes blob with signatures to be validated.
    * First byte X is a number of signatures in a blob,
    * next X bytes are v components of signatures,
    * next 32 * X bytes are r components of signatures,
    * next 32 * X bytes are s components of signatures.
    * @param _validatorContract contract, which conforms to the IBridgeValidators interface,
    * where info about current validators and required signatures is stored.
    * @param isAMBMessage true if _message is an AMB message with arbitrary length.
    */
    function hasEnoughValidSignatures(
        bytes _message,
        bytes _signatures,
        IBridgeValidators _validatorContract,
        bool isAMBMessage
    ) internal view {
        require(isAMBMessage || isMessageValid(_message));
        uint256 requiredSignatures = _validatorContract.requiredSignatures();
        uint256 amount;
        assembly {
            amount := and(mload(add(_signatures, 1)), 0xff)
        }
        require(amount >= requiredSignatures);
        bytes32 hash = hashMessage(_message, isAMBMessage);
        address[] memory encounteredAddresses = new address[](requiredSignatures);

        for (uint256 i = 0; i < requiredSignatures; i++) {
            uint8 v;
            bytes32 r;
            bytes32 s;
            uint256 posr = 33 + amount + 32 * i;
            uint256 poss = posr + 32 * amount;
            assembly {
                v := mload(add(_signatures, add(2, i)))
                r := mload(add(_signatures, posr))
                s := mload(add(_signatures, poss))
            }

            address recoveredAddress = ecrecover(hash, v, r, s);
            require(_validatorContract.isValidator(recoveredAddress));
            require(!addressArrayContains(encounteredAddresses, recoveredAddress));
            encounteredAddresses[i] = recoveredAddress;
        }
    }

    function uintToString(uint256 i) internal pure returns (string) {
        if (i == 0) return "0";
        uint256 j = i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length - 1;
        while (i != 0) {
            bstr[k--] = bytes1(48 + (i % 10));
            i /= 10;
        }
        return string(bstr);
    }
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

// File: contracts/upgradeable_contracts/DecimalShiftBridge.sol

pragma solidity 0.4.24;



contract DecimalShiftBridge is EternalStorage {
    using SafeMath for uint256;

    bytes32 internal constant DECIMAL_SHIFT = 0x1e8ecaafaddea96ed9ac6d2642dcdfe1bebe58a930b1085842d8fc122b371ee5; // keccak256(abi.encodePacked("decimalShift"))

    /**
    * @dev Internal function for setting the decimal shift for bridge operations.
    * Decimal shift can be positive, negative, or equal to zero.
    * It has the following meaning: N tokens in the foreign chain are equivalent to N * pow(10, shift) tokens on the home side.
    * @param _shift new value of decimal shift.
    */
    function _setDecimalShift(int256 _shift) internal {
        // since 1 wei * 10**77 > 2**255, it does not make any sense to use higher values
        require(_shift > -77 && _shift < 77);
        uintStorage[DECIMAL_SHIFT] = uint256(_shift);
    }

    /**
    * @dev Returns the value of foreign-to-home decimal shift.
    * @return decimal shift.
    */
    function decimalShift() public view returns (int256) {
        return int256(uintStorage[DECIMAL_SHIFT]);
    }

    /**
    * @dev Converts the amount of home tokens into the equivalent amount of foreign tokens.
    * @param _value amount of home tokens.
    * @return equivalent amount of foreign tokens.
    */
    function _unshiftValue(uint256 _value) internal view returns (uint256) {
        return _shiftUint(_value, -decimalShift());
    }

    /**
    * @dev Converts the amount of foreign tokens into the equivalent amount of home tokens.
    * @param _value amount of foreign tokens.
    * @return equivalent amount of home tokens.
    */
    function _shiftValue(uint256 _value) internal view returns (uint256) {
        return _shiftUint(_value, decimalShift());
    }

    /**
    * @dev Calculates _value * pow(10, _shift).
    * @param _value amount of tokens.
    * @param _shift decimal shift to apply.
    * @return shifted value.
    */
    function _shiftUint(uint256 _value, int256 _shift) private pure returns (uint256) {
        if (_shift == 0) {
            return _value;
        }
        if (_shift > 0) {
            return _value.mul(10**uint256(_shift));
        }
        return _value.div(10**uint256(-_shift));
    }
}

// File: contracts/interfaces/IUpgradeabilityOwnerStorage.sol

pragma solidity 0.4.24;

interface IUpgradeabilityOwnerStorage {
    function upgradeabilityOwner() external view returns (address);
}

// File: contracts/upgradeable_contracts/Ownable.sol

pragma solidity 0.4.24;



/**
 * @title Ownable
 * @dev This contract has an owner address providing basic authorization control
 */
contract Ownable is EternalStorage {
    bytes4 internal constant UPGRADEABILITY_OWNER = 0x6fde8202; // upgradeabilityOwner()

    /**
    * @dev Event to show ownership has been transferred
    * @param previousOwner representing the address of the previous owner
    * @param newOwner representing the address of the new owner
    */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner());
        /* solcov ignore next */
        _;
    }

    /**
    * @dev Throws if called by any account other than contract itself or owner.
    */
    modifier onlyRelevantSender() {
        // proxy owner if used through proxy, address(0) otherwise
        require(
            !address(this).call(abi.encodeWithSelector(UPGRADEABILITY_OWNER)) || // covers usage without calling through storage proxy
                msg.sender == IUpgradeabilityOwnerStorage(this).upgradeabilityOwner() || // covers usage through regular proxy calls
                msg.sender == address(this) // covers calls through upgradeAndCall proxy method
        );
        /* solcov ignore next */
        _;
    }

    bytes32 internal constant OWNER = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0; // keccak256(abi.encodePacked("owner"))

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function owner() public view returns (address) {
        return addressStorage[OWNER];
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner the address to transfer ownership to.
    */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        setOwner(newOwner);
    }

    /**
    * @dev Sets a new owner address
    */
    function setOwner(address newOwner) internal {
        emit OwnershipTransferred(owner(), newOwner);
        addressStorage[OWNER] = newOwner;
    }
}

// File: contracts/upgradeable_contracts/BasicTokenBridge.sol

pragma solidity 0.4.24;





contract BasicTokenBridge is EternalStorage, Ownable, DecimalShiftBridge {
    using SafeMath for uint256;

    event DailyLimitChanged(uint256 newLimit);
    event ExecutionDailyLimitChanged(uint256 newLimit);

    bytes32 internal constant MIN_PER_TX = 0xbbb088c505d18e049d114c7c91f11724e69c55ad6c5397e2b929e68b41fa05d1; // keccak256(abi.encodePacked("minPerTx"))
    bytes32 internal constant MAX_PER_TX = 0x0f8803acad17c63ee38bf2de71e1888bc7a079a6f73658e274b08018bea4e29c; // keccak256(abi.encodePacked("maxPerTx"))
    bytes32 internal constant DAILY_LIMIT = 0x4a6a899679f26b73530d8cf1001e83b6f7702e04b6fdb98f3c62dc7e47e041a5; // keccak256(abi.encodePacked("dailyLimit"))
    bytes32 internal constant EXECUTION_MAX_PER_TX = 0xc0ed44c192c86d1cc1ba51340b032c2766b4a2b0041031de13c46dd7104888d5; // keccak256(abi.encodePacked("executionMaxPerTx"))
    bytes32 internal constant EXECUTION_DAILY_LIMIT = 0x21dbcab260e413c20dc13c28b7db95e2b423d1135f42bb8b7d5214a92270d237; // keccak256(abi.encodePacked("executionDailyLimit"))

    function totalSpentPerDay(uint256 _day) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("totalSpentPerDay", _day))];
    }

    function totalExecutedPerDay(uint256 _day) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("totalExecutedPerDay", _day))];
    }

    function dailyLimit() public view returns (uint256) {
        return uintStorage[DAILY_LIMIT];
    }

    function executionDailyLimit() public view returns (uint256) {
        return uintStorage[EXECUTION_DAILY_LIMIT];
    }

    function maxPerTx() public view returns (uint256) {
        return uintStorage[MAX_PER_TX];
    }

    function executionMaxPerTx() public view returns (uint256) {
        return uintStorage[EXECUTION_MAX_PER_TX];
    }

    function minPerTx() public view returns (uint256) {
        return uintStorage[MIN_PER_TX];
    }

    function withinLimit(uint256 _amount) public view returns (bool) {
        uint256 nextLimit = totalSpentPerDay(getCurrentDay()).add(_amount);
        return dailyLimit() >= nextLimit && _amount <= maxPerTx() && _amount >= minPerTx();
    }

    function withinExecutionLimit(uint256 _amount) public view returns (bool) {
        uint256 nextLimit = totalExecutedPerDay(getCurrentDay()).add(_amount);
        return executionDailyLimit() >= nextLimit && _amount <= executionMaxPerTx();
    }

    function getCurrentDay() public view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return now / 1 days;
    }

    function setTotalSpentPerDay(uint256 _day, uint256 _value) internal {
        uintStorage[keccak256(abi.encodePacked("totalSpentPerDay", _day))] = _value;
    }

    function setTotalExecutedPerDay(uint256 _day, uint256 _value) internal {
        uintStorage[keccak256(abi.encodePacked("totalExecutedPerDay", _day))] = _value;
    }

    function setDailyLimit(uint256 _dailyLimit) external onlyOwner {
        require(_dailyLimit > maxPerTx() || _dailyLimit == 0);
        uintStorage[DAILY_LIMIT] = _dailyLimit;
        emit DailyLimitChanged(_dailyLimit);
    }

    function setExecutionDailyLimit(uint256 _dailyLimit) external onlyOwner {
        require(_dailyLimit > executionMaxPerTx() || _dailyLimit == 0);
        uintStorage[EXECUTION_DAILY_LIMIT] = _dailyLimit;
        emit ExecutionDailyLimitChanged(_dailyLimit);
    }

    function setExecutionMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        require(_maxPerTx < executionDailyLimit());
        uintStorage[EXECUTION_MAX_PER_TX] = _maxPerTx;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        require(_maxPerTx == 0 || (_maxPerTx > minPerTx() && _maxPerTx < dailyLimit()));
        uintStorage[MAX_PER_TX] = _maxPerTx;
    }

    function setMinPerTx(uint256 _minPerTx) external onlyOwner {
        require(_minPerTx > 0 && _minPerTx < dailyLimit() && _minPerTx < maxPerTx());
        uintStorage[MIN_PER_TX] = _minPerTx;
    }
}

// File: contracts/upgradeable_contracts/MessageRelay.sol

pragma solidity 0.4.24;


contract MessageRelay is EternalStorage {
    function relayedMessages(bytes32 _txHash) public view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked("relayedMessages", _txHash))];
    }

    function setRelayedMessages(bytes32 _txHash, bool _status) internal {
        boolStorage[keccak256(abi.encodePacked("relayedMessages", _txHash))] = _status;
    }
}

// File: contracts/upgradeable_contracts/Upgradeable.sol

pragma solidity 0.4.24;


contract Upgradeable {
    // Avoid using onlyUpgradeabilityOwner name to prevent issues with implementation from proxy contract
    modifier onlyIfUpgradeabilityOwner() {
        require(msg.sender == IUpgradeabilityOwnerStorage(this).upgradeabilityOwner());
        /* solcov ignore next */
        _;
    }
}

// File: contracts/upgradeable_contracts/Initializable.sol

pragma solidity 0.4.24;


contract Initializable is EternalStorage {
    bytes32 internal constant INITIALIZED = 0x0a6f646cd611241d8073675e00d1a1ff700fbf1b53fcf473de56d1e6e4b714ba; // keccak256(abi.encodePacked("isInitialized"))

    function setInitialize() internal {
        boolStorage[INITIALIZED] = true;
    }

    function isInitialized() public view returns (bool) {
        return boolStorage[INITIALIZED];
    }
}

// File: contracts/upgradeable_contracts/InitializableBridge.sol

pragma solidity 0.4.24;


contract InitializableBridge is Initializable {
    bytes32 internal constant DEPLOYED_AT_BLOCK = 0xb120ceec05576ad0c710bc6e85f1768535e27554458f05dcbb5c65b8c7a749b0; // keccak256(abi.encodePacked("deployedAtBlock"))

    function deployedAtBlock() external view returns (uint256) {
        return uintStorage[DEPLOYED_AT_BLOCK];
    }
}

// File: openzeppelin-solidity/contracts/AddressUtils.sol

pragma solidity ^0.4.24;


/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param _addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

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

// File: contracts/upgradeable_contracts/Claimable.sol

pragma solidity 0.4.24;



contract Claimable {
    bytes4 internal constant TRANSFER = 0xa9059cbb; // transfer(address,uint256)

    modifier validAddress(address _to) {
        require(_to != address(0));
        /* solcov ignore next */
        _;
    }

    function claimValues(address _token, address _to) internal {
        if (_token == address(0)) {
            claimNativeCoins(_to);
        } else {
            claimErc20Tokens(_token, _to);
        }
    }

    function claimNativeCoins(address _to) internal {
        uint256 value = address(this).balance;
        Address.safeSendValue(_to, value);
    }

    function claimErc20Tokens(address _token, address _to) internal {
        ERC20Basic token = ERC20Basic(_token);
        uint256 balance = token.balanceOf(this);
        safeTransfer(_token, _to, balance);
    }

    function safeTransfer(address _token, address _to, uint256 _value) internal {
        bytes memory returnData;
        bool returnDataResult;
        bytes memory callData = abi.encodeWithSelector(TRANSFER, _to, _value);
        assembly {
            let result := call(gas, _token, 0x0, add(callData, 0x20), mload(callData), 0, 32)
            returnData := mload(0)
            returnDataResult := mload(0)

            switch result
                case 0 {
                    revert(0, 0)
                }
        }

        // Return data is optional
        if (returnData.length > 0) {
            require(returnDataResult);
        }
    }
}

// File: contracts/upgradeable_contracts/VersionableBridge.sol

pragma solidity 0.4.24;

contract VersionableBridge {
    function getBridgeInterfacesVersion() external pure returns (uint64 major, uint64 minor, uint64 patch) {
        return (5, 0, 0);
    }

    /* solcov ignore next */
    function getBridgeMode() external pure returns (bytes4);
}

// File: contracts/upgradeable_contracts/BasicBridge.sol

pragma solidity 0.4.24;








contract BasicBridge is InitializableBridge, Validatable, Ownable, Upgradeable, Claimable, VersionableBridge {
    event GasPriceChanged(uint256 gasPrice);
    event RequiredBlockConfirmationChanged(uint256 requiredBlockConfirmations);

    bytes32 internal constant GAS_PRICE = 0x55b3774520b5993024893d303890baa4e84b1244a43c60034d1ced2d3cf2b04b; // keccak256(abi.encodePacked("gasPrice"))
    bytes32 internal constant REQUIRED_BLOCK_CONFIRMATIONS = 0x916daedf6915000ff68ced2f0b6773fe6f2582237f92c3c95bb4d79407230071; // keccak256(abi.encodePacked("requiredBlockConfirmations"))

    /**
    * @dev Public setter for fallback gas price value. Only bridge owner can call this method.
    * @param _gasPrice new value for the gas price.
    */
    function setGasPrice(uint256 _gasPrice) external onlyOwner {
        _setGasPrice(_gasPrice);
    }

    function gasPrice() external view returns (uint256) {
        return uintStorage[GAS_PRICE];
    }

    function setRequiredBlockConfirmations(uint256 _blockConfirmations) external onlyOwner {
        require(_blockConfirmations > 0);
        uintStorage[REQUIRED_BLOCK_CONFIRMATIONS] = _blockConfirmations;
        emit RequiredBlockConfirmationChanged(_blockConfirmations);
    }

    function requiredBlockConfirmations() external view returns (uint256) {
        return uintStorage[REQUIRED_BLOCK_CONFIRMATIONS];
    }

    function claimTokens(address _token, address _to) public onlyIfUpgradeabilityOwner validAddress(_to) {
        claimValues(_token, _to);
    }

    /**
    * @dev Internal function for updating fallback gas price value.
    * @param _gasPrice new value for the gas price, zero gas price is allowed.
    */
    function _setGasPrice(uint256 _gasPrice) internal {
        uintStorage[GAS_PRICE] = _gasPrice;
        emit GasPriceChanged(_gasPrice);
    }
}

// File: contracts/upgradeable_contracts/BasicForeignBridge.sol

pragma solidity 0.4.24;










contract BasicForeignBridge is EternalStorage, Validatable, BasicBridge, BasicTokenBridge, MessageRelay {
    /// triggered when relay of deposit from HomeBridge is complete
    event RelayedMessage(address recipient, uint256 value, bytes32 transactionHash);
    event UserRequestForAffirmation(address recipient, uint256 value);

    /**
    * @dev Validates provided signatures and relays a given message
    * @param message bytes to be relayed
    * @param signatures bytes blob with signatures to be validated
    */
    function executeSignatures(bytes message, bytes signatures) external {
        Message.hasEnoughValidSignatures(message, signatures, validatorContract(), false);

        address recipient;
        uint256 amount;
        bytes32 txHash;
        address contractAddress;
        (recipient, amount, txHash, contractAddress) = Message.parseMessage(message);
        if (withinExecutionLimit(amount)) {
            require(contractAddress == address(this));
            require(!relayedMessages(txHash));
            setRelayedMessages(txHash, true);
            require(onExecuteMessage(recipient, amount, txHash));
            emit RelayedMessage(recipient, amount, txHash);
        } else {
            onFailedMessage(recipient, amount, txHash);
        }
    }

    /**
    * @dev Internal function for updating fallback gas price value.
    * @param _gasPrice new value for the gas price, zero gas price is not allowed.
    */
    function _setGasPrice(uint256 _gasPrice) internal {
        require(_gasPrice > 0);
        super._setGasPrice(_gasPrice);
    }

    /* solcov ignore next */
    function onExecuteMessage(address, uint256, bytes32) internal returns (bool);

    /* solcov ignore next */
    function onFailedMessage(address, uint256, bytes32) internal;
}

// File: contracts/interfaces/ERC677Receiver.sol

pragma solidity 0.4.24;

contract ERC677Receiver {
    function onTokenTransfer(address _from, uint256 _value, bytes _data) external returns (bool);
}

// File: contracts/upgradeable_contracts/ERC677Storage.sol

pragma solidity 0.4.24;

contract ERC677Storage {
    bytes32 internal constant ERC677_TOKEN = 0xa8b0ade3e2b734f043ce298aca4cc8d19d74270223f34531d0988b7d00cba21d; // keccak256(abi.encodePacked("erc677token"))
}

// File: contracts/libraries/Bytes.sol

pragma solidity 0.4.24;

/**
 * @title Bytes
 * @dev Helper methods to transform bytes to other solidity types.
 */
library Bytes {
    /**
    * @dev Converts bytes array to bytes32.
    * Truncates bytes array if its size is more than 32 bytes.
    * NOTE: This function does not perform any checks on the received parameter.
    * Make sure that the _bytes argument has a correct length, not less than 32 bytes.
    * A case when _bytes has length less than 32 will lead to the undefined behaviour,
    * since assembly will read data from memory that is not related to the _bytes argument.
    * @param _bytes to be converted to bytes32 type
    * @return bytes32 type of the firsts 32 bytes array in parameter.
    */
    function bytesToBytes32(bytes _bytes) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(_bytes, 32))
        }
    }

    /**
    * @dev Truncate bytes array if its size is more than 20 bytes.
    * NOTE: Similar to the bytesToBytes32 function, make sure that _bytes is not shorter than 20 bytes.
    * @param _bytes to be converted to address type
    * @return address included in the firsts 20 bytes of the bytes array in parameter.
    */
    function bytesToAddress(bytes _bytes) internal pure returns (address addr) {
        assembly {
            addr := mload(add(_bytes, 20))
        }
    }
}

// File: contracts/upgradeable_contracts/BaseERC677Bridge.sol

pragma solidity 0.4.24;







contract BaseERC677Bridge is BasicTokenBridge, ERC677Receiver, ERC677Storage {
    function _erc677token() internal view returns (ERC677) {
        return ERC677(addressStorage[ERC677_TOKEN]);
    }

    function setErc677token(address _token) internal {
        require(AddressUtils.isContract(_token));
        addressStorage[ERC677_TOKEN] = _token;
    }

    function onTokenTransfer(address _from, uint256 _value, bytes _data) external returns (bool) {
        ERC677 token = _erc677token();
        require(msg.sender == address(token));
        require(withinLimit(_value));
        setTotalSpentPerDay(getCurrentDay(), totalSpentPerDay(getCurrentDay()).add(_value));
        bridgeSpecificActionsOnTokenTransfer(token, _from, _value, _data);
        return true;
    }

    function chooseReceiver(address _from, bytes _data) internal view returns (address recipient) {
        recipient = _from;
        if (_data.length > 0) {
            require(_data.length == 20);
            recipient = Bytes.bytesToAddress(_data);
            require(recipient != address(0));
            require(recipient != bridgeContractOnOtherSide());
        }
    }

    /* solcov ignore next */
    function bridgeSpecificActionsOnTokenTransfer(ERC677 _token, address _from, uint256 _value, bytes _data) internal;

    /* solcov ignore next */
    function bridgeContractOnOtherSide() internal view returns (address);
}

// File: contracts/upgradeable_contracts/OtherSideBridgeStorage.sol

pragma solidity 0.4.24;


contract OtherSideBridgeStorage is EternalStorage {
    bytes32 internal constant BRIDGE_CONTRACT = 0x71483949fe7a14d16644d63320f24d10cf1d60abecc30cc677a340e82b699dd2; // keccak256(abi.encodePacked("bridgeOnOtherSide"))

    function _setBridgeContractOnOtherSide(address _bridgeContract) internal {
        addressStorage[BRIDGE_CONTRACT] = _bridgeContract;
    }

    function bridgeContractOnOtherSide() internal view returns (address) {
        return addressStorage[BRIDGE_CONTRACT];
    }
}

// File: contracts/upgradeable_contracts/ERC677Bridge.sol

pragma solidity 0.4.24;



contract ERC677Bridge is BaseERC677Bridge, OtherSideBridgeStorage {
    function erc677token() public view returns (ERC677) {
        return _erc677token();
    }

    function bridgeSpecificActionsOnTokenTransfer(
        ERC677, /*_token*/
        address _from,
        uint256 _value,
        bytes _data
    ) internal {
        fireEventOnTokenTransfer(chooseReceiver(_from, _data), _value);
    }

    /* solcov ignore next */
    function fireEventOnTokenTransfer(address _from, uint256 _value) internal;
}

// File: contracts/upgradeable_contracts/ERC677BridgeForBurnableMintableToken.sol

pragma solidity 0.4.24;



contract ERC677BridgeForBurnableMintableToken is ERC677Bridge {
    function bridgeSpecificActionsOnTokenTransfer(ERC677 _token, address _from, uint256 _value, bytes _data) internal {
        IBurnableMintableERC677Token(_token).burn(_value);
        fireEventOnTokenTransfer(chooseReceiver(_from, _data), _value);
    }
}

// File: contracts/upgradeable_contracts/FeeTypes.sol

pragma solidity 0.4.24;

contract FeeTypes {
    bytes32 internal constant HOME_FEE = 0x89d93e5e92f7e37e490c25f0e50f7f4aad7cc94b308a566553280967be38bcf1; // keccak256(abi.encodePacked("home-fee"))
    bytes32 internal constant FOREIGN_FEE = 0xdeb7f3adca07d6d1f708c1774389db532a2b2f18fd05a62b957e4089f4696ed5; // keccak256(abi.encodePacked("foreign-fee"))
}

// File: contracts/upgradeable_contracts/RewardableBridge.sol

pragma solidity 0.4.24;




contract RewardableBridge is Ownable, FeeTypes {
    event FeeDistributedFromAffirmation(uint256 feeAmount, bytes32 indexed transactionHash);
    event FeeDistributedFromSignatures(uint256 feeAmount, bytes32 indexed transactionHash);

    bytes32 internal constant FEE_MANAGER_CONTRACT = 0x779a349c5bee7817f04c960f525ee3e2f2516078c38c68a3149787976ee837e5; // keccak256(abi.encodePacked("feeManagerContract"))
    bytes4 internal constant GET_HOME_FEE = 0x94da17cd; // getHomeFee()
    bytes4 internal constant GET_FOREIGN_FEE = 0xffd66196; // getForeignFee()
    bytes4 internal constant GET_FEE_MANAGER_MODE = 0xf2ba9561; // getFeeManagerMode()
    bytes4 internal constant SET_HOME_FEE = 0x34a9e148; // setHomeFee(uint256)
    bytes4 internal constant SET_FOREIGN_FEE = 0x286c4066; // setForeignFee(uint256)
    bytes4 internal constant CALCULATE_FEE = 0x9862f26f; // calculateFee(uint256,bool,bytes32)
    bytes4 internal constant DISTRIBUTE_FEE_FROM_SIGNATURES = 0x59d78464; // distributeFeeFromSignatures(uint256)
    bytes4 internal constant DISTRIBUTE_FEE_FROM_AFFIRMATION = 0x054d46ec; // distributeFeeFromAffirmation(uint256)

    function _getFee(bytes32 _feeType) internal view returns (uint256) {
        uint256 fee;
        address feeManager = feeManagerContract();
        bytes4 method = _feeType == HOME_FEE ? GET_HOME_FEE : GET_FOREIGN_FEE;
        bytes memory callData = abi.encodeWithSelector(method);

        assembly {
            let result := callcode(gas, feeManager, 0x0, add(callData, 0x20), mload(callData), 0, 32)
            fee := mload(0)

            switch result
                case 0 {
                    revert(0, 0)
                }
        }
        return fee;
    }

    function getFeeManagerMode() external view returns (bytes4) {
        bytes4 mode;
        bytes memory callData = abi.encodeWithSelector(GET_FEE_MANAGER_MODE);
        address feeManager = feeManagerContract();
        assembly {
            let result := callcode(gas, feeManager, 0x0, add(callData, 0x20), mload(callData), 0, 4)
            mode := mload(0)

            switch result
                case 0 {
                    revert(0, 0)
                }
        }
        return mode;
    }

    function feeManagerContract() public view returns (address) {
        return addressStorage[FEE_MANAGER_CONTRACT];
    }

    function setFeeManagerContract(address _feeManager) external onlyOwner {
        require(_feeManager == address(0) || AddressUtils.isContract(_feeManager));
        addressStorage[FEE_MANAGER_CONTRACT] = _feeManager;
    }

    function _setFee(address _feeManager, uint256 _fee, bytes32 _feeType) internal {
        bytes4 method = _feeType == HOME_FEE ? SET_HOME_FEE : SET_FOREIGN_FEE;
        require(_feeManager.delegatecall(abi.encodeWithSelector(method, _fee)));
    }

    function calculateFee(uint256 _value, bool _recover, address _impl, bytes32 _feeType)
        internal
        view
        returns (uint256)
    {
        uint256 fee;
        bytes memory callData = abi.encodeWithSelector(CALCULATE_FEE, _value, _recover, _feeType);
        assembly {
            let result := callcode(gas, _impl, 0x0, add(callData, 0x20), mload(callData), 0, 32)
            fee := mload(0)

            switch result
                case 0 {
                    revert(0, 0)
                }
        }
        return fee;
    }

    function distributeFeeFromSignatures(uint256 _fee, address _feeManager, bytes32 _txHash) internal {
        require(_feeManager.delegatecall(abi.encodeWithSelector(DISTRIBUTE_FEE_FROM_SIGNATURES, _fee)));
        emit FeeDistributedFromSignatures(_fee, _txHash);
    }

    function distributeFeeFromAffirmation(uint256 _fee, address _feeManager, bytes32 _txHash) internal {
        require(_feeManager.delegatecall(abi.encodeWithSelector(DISTRIBUTE_FEE_FROM_AFFIRMATION, _fee)));
        emit FeeDistributedFromAffirmation(_fee, _txHash);
    }
}

// File: contracts/upgradeable_contracts/native_to_erc20/RewardableForeignBridgeNativeToErc.sol

pragma solidity 0.4.24;


contract RewardableForeignBridgeNativeToErc is RewardableBridge {
    function setHomeFee(uint256 _fee) external onlyOwner {
        _setFee(feeManagerContract(), _fee, HOME_FEE);
    }

    function getHomeFee() public view returns (uint256) {
        return _getFee(HOME_FEE);
    }
}

// File: contracts/upgradeable_contracts/native_to_erc20/ForeignBridgeNativeToErc.sol

pragma solidity 0.4.24;






contract ForeignBridgeNativeToErc is
    BasicForeignBridge,
    ERC677BridgeForBurnableMintableToken,
    RewardableForeignBridgeNativeToErc
{
    function initialize(
        address _validatorContract,
        address _erc677token,
        uint256[3] _dailyLimitMaxPerTxMinPerTxArray, // [ 0 = _dailyLimit, 1 = _maxPerTx, 2 = _minPerTx ]
        uint256 _foreignGasPrice,
        uint256 _requiredBlockConfirmations,
        uint256[2] _homeDailyLimitHomeMaxPerTxArray, // [ 0 = _homeDailyLimit, 1 = _homeMaxPerTx ]
        address _owner,
        int256 _decimalShift,
        address _bridgeOnOtherSide
    ) external onlyRelevantSender returns (bool) {
        _initialize(
            _validatorContract,
            _erc677token,
            _dailyLimitMaxPerTxMinPerTxArray,
            _foreignGasPrice,
            _requiredBlockConfirmations,
            _homeDailyLimitHomeMaxPerTxArray,
            _owner,
            _decimalShift,
            _bridgeOnOtherSide
        );
        setInitialize();
        return isInitialized();
    }

    function rewardableInitialize(
        address _validatorContract,
        address _erc677token,
        uint256[3] _dailyLimitMaxPerTxMinPerTxArray, // [ 0 = _dailyLimit, 1 = _maxPerTx, 2 = _minPerTx ]
        uint256 _foreignGasPrice,
        uint256 _requiredBlockConfirmations,
        uint256[2] _homeDailyLimitHomeMaxPerTxArray, // [ 0 = _homeDailyLimit, 1 = _homeMaxPerTx ]
        address _owner,
        address _feeManager,
        uint256 _homeFee,
        int256 _decimalShift,
        address _bridgeOnOtherSide
    ) external onlyRelevantSender returns (bool) {
        _initialize(
            _validatorContract,
            _erc677token,
            _dailyLimitMaxPerTxMinPerTxArray,
            _foreignGasPrice,
            _requiredBlockConfirmations,
            _homeDailyLimitHomeMaxPerTxArray,
            _owner,
            _decimalShift,
            _bridgeOnOtherSide
        );
        require(AddressUtils.isContract(_feeManager));
        addressStorage[FEE_MANAGER_CONTRACT] = _feeManager;
        _setFee(_feeManager, _homeFee, HOME_FEE);
        setInitialize();
        return isInitialized();
    }

    function getBridgeMode() external pure returns (bytes4 _data) {
        return 0x92a8d7fe; // bytes4(keccak256(abi.encodePacked("native-to-erc-core")))
    }

    function claimTokensFromErc677(address _token, address _to) external onlyIfUpgradeabilityOwner {
        IBurnableMintableERC677Token(erc677token()).claimTokens(_token, _to);
    }

    function _initialize(
        address _validatorContract,
        address _erc677token,
        uint256[3] _dailyLimitMaxPerTxMinPerTxArray, // [ 0 = _dailyLimit, 1 = _maxPerTx, 2 = _minPerTx ]
        uint256 _foreignGasPrice,
        uint256 _requiredBlockConfirmations,
        uint256[2] _homeDailyLimitHomeMaxPerTxArray, // [ 0 = _homeDailyLimit, 1 = _homeMaxPerTx ]
        address _owner,
        int256 _decimalShift,
        address _bridgeOnOtherSide
    ) internal {
        require(!isInitialized());
        require(AddressUtils.isContract(_validatorContract));
        require(
            _dailyLimitMaxPerTxMinPerTxArray[2] > 0 && // _minPerTx > 0
                _dailyLimitMaxPerTxMinPerTxArray[1] > _dailyLimitMaxPerTxMinPerTxArray[2] && // _maxPerTx > _minPerTx
                _dailyLimitMaxPerTxMinPerTxArray[0] > _dailyLimitMaxPerTxMinPerTxArray[1] // _dailyLimit > _maxPerTx
        );
        require(_requiredBlockConfirmations > 0);
        require(_homeDailyLimitHomeMaxPerTxArray[1] < _homeDailyLimitHomeMaxPerTxArray[0]); // _homeMaxPerTx < _homeDailyLimit
        require(_owner != address(0));

        addressStorage[VALIDATOR_CONTRACT] = _validatorContract;
        setErc677token(_erc677token);
        uintStorage[DAILY_LIMIT] = _dailyLimitMaxPerTxMinPerTxArray[0];
        uintStorage[DEPLOYED_AT_BLOCK] = block.number;
        uintStorage[MAX_PER_TX] = _dailyLimitMaxPerTxMinPerTxArray[1];
        uintStorage[MIN_PER_TX] = _dailyLimitMaxPerTxMinPerTxArray[2];
        _setGasPrice(_foreignGasPrice);
        uintStorage[REQUIRED_BLOCK_CONFIRMATIONS] = _requiredBlockConfirmations;
        uintStorage[EXECUTION_DAILY_LIMIT] = _homeDailyLimitHomeMaxPerTxArray[0];
        uintStorage[EXECUTION_MAX_PER_TX] = _homeDailyLimitHomeMaxPerTxArray[1];
        _setDecimalShift(_decimalShift);
        setOwner(_owner);
        _setBridgeContractOnOtherSide(_bridgeOnOtherSide);

        emit RequiredBlockConfirmationChanged(_requiredBlockConfirmations);
        emit DailyLimitChanged(_dailyLimitMaxPerTxMinPerTxArray[0]);
        emit ExecutionDailyLimitChanged(_homeDailyLimitHomeMaxPerTxArray[0]);
    }

    function onExecuteMessage(address _recipient, uint256 _amount, bytes32 _txHash) internal returns (bool) {
        setTotalExecutedPerDay(getCurrentDay(), totalExecutedPerDay(getCurrentDay()).add(_amount));
        uint256 valueToMint = _unshiftValue(_amount);
        address feeManager = feeManagerContract();
        if (feeManager != address(0)) {
            uint256 fee = calculateFee(valueToMint, false, feeManager, HOME_FEE);
            if (fee != 0) {
                distributeFeeFromSignatures(fee, feeManager, _txHash);
                valueToMint = valueToMint.sub(fee);
            }
        }
        return IBurnableMintableERC677Token(erc677token()).mint(_recipient, valueToMint);
    }

    function fireEventOnTokenTransfer(address _from, uint256 _value) internal {
        emit UserRequestForAffirmation(_from, _value);
    }

    function onFailedMessage(address, uint256, bytes32) internal {
        revert();
    }
}