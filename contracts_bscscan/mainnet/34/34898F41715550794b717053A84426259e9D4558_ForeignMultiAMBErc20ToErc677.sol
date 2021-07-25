/**
 *Submitted for verification at BscScan.com on 2021-07-25
*/

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

// File: openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol

pragma solidity ^0.4.24;



/**
 * @title DetailedERC20 token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

// File: contracts/interfaces/IAMB.sol

pragma solidity 0.4.24;

interface IAMB {
    function messageSender() external view returns (address);
    function maxGasPerTx() external view returns (uint256);
    function transactionHash() external view returns (bytes32);
    function messageId() external view returns (bytes32);
    function messageSourceChainId() external view returns (bytes32);
    function messageCallStatus(bytes32 _messageId) external view returns (bool);
    function failedMessageDataHash(bytes32 _messageId) external view returns (bytes32);
    function failedMessageReceiver(bytes32 _messageId) external view returns (address);
    function failedMessageSender(bytes32 _messageId) external view returns (address);
    function requireToPassMessage(address _contract, bytes _data, uint256 _gas) external returns (bytes32);
    function requireToConfirmMessage(address _contract, bytes _data, uint256 _gas) external returns (bytes32);
    function sourceChainId() external view returns (uint256);
    function destinationChainId() external view returns (uint256);
}

// File: contracts/interfaces/ERC677.sol

pragma solidity 0.4.24;


contract ERC677 is ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

    function transferAndCall(address, uint256, bytes) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool);
}

contract LegacyERC20 {
    function transfer(address _spender, uint256 _value) public; // returns (bool);
    function transferFrom(address _owner, address _spender, uint256 _value) public; // returns (bool);
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
        _setOwner(newOwner);
    }

    /**
    * @dev Sets a new owner address
    */
    function _setOwner(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner(), newOwner);
        addressStorage[OWNER] = newOwner;
    }
}

// File: contracts/upgradeable_contracts/multi_amb_erc20_to_erc677/BasicMultiTokenBridge.sol

pragma solidity 0.4.24;




contract BasicMultiTokenBridge is EternalStorage, Ownable {
    using SafeMath for uint256;

    // token == 0x00..00 represents default limits (assuming decimals == 18) for all newly created tokens
    event DailyLimitChanged(address indexed token, uint256 newLimit);
    event ExecutionDailyLimitChanged(address indexed token, uint256 newLimit);

    /**
    * @dev Checks if specified token was already bridged at least once.
    * @param _token address of the token contract.
    * @return true, if token address is address(0) or token was already bridged.
    */
    function isTokenRegistered(address _token) public view returns (bool) {
        return minPerTx(_token) > 0;
    }

    /**
    * @dev Retrieves the total spent amount for particular token during specific day.
    * @param _token address of the token contract.
    * @param _day day number for which spent amount if requested.
    * @return amount of tokens sent through the bridge to the other side.
    */
    function totalSpentPerDay(address _token, uint256 _day) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("totalSpentPerDay", _token, _day))];
    }

    /**
    * @dev Retrieves the total executed amount for particular token during specific day.
    * @param _token address of the token contract.
    * @param _day day number for which spent amount if requested.
    * @return amount of tokens received from the bridge from the other side.
    */
    function totalExecutedPerDay(address _token, uint256 _day) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("totalExecutedPerDay", _token, _day))];
    }

    /**
    * @dev Retrieves current daily limit for a particular token contract.
    * @param _token address of the token contract.
    * @return daily limit on tokens that can be sent through the bridge per day.
    */
    function dailyLimit(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("dailyLimit", _token))];
    }

    /**
    * @dev Retrieves current execution daily limit for a particular token contract.
    * @param _token address of the token contract.
    * @return daily limit on tokens that can be received from the bridge on the other side per day.
    */
    function executionDailyLimit(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("executionDailyLimit", _token))];
    }

    /**
    * @dev Retrieves current maximum amount of tokens per one transfer for a particular token contract.
    * @param _token address of the token contract.
    * @return maximum amount on tokens that can be sent through the bridge in one transfer.
    */
    function maxPerTx(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("maxPerTx", _token))];
    }

    /**
    * @dev Retrieves current maximum execution amount of tokens per one transfer for a particular token contract.
    * @param _token address of the token contract.
    * @return maximum amount on tokens that can received from the bridge on the other side in one transaction.
    */
    function executionMaxPerTx(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("executionMaxPerTx", _token))];
    }

    /**
    * @dev Retrieves current minimum amount of tokens per one transfer for a particular token contract.
    * @param _token address of the token contract.
    * @return minimum amount on tokens that can be sent through the bridge in one transfer.
    */
    function minPerTx(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("minPerTx", _token))];
    }

    /**
    * @dev Checks that bridged amount of tokens conforms to the configured limits.
    * @param _token address of the token contract.
    * @param _amount amount of bridge tokens.
    * @return true, if specified amount can be bridged.
    */
    function withinLimit(address _token, uint256 _amount) public view returns (bool) {
        uint256 nextLimit = totalSpentPerDay(_token, getCurrentDay()).add(_amount);
        return
            dailyLimit(address(0)) > 0 &&
                dailyLimit(_token) >= nextLimit &&
                _amount <= maxPerTx(_token) &&
                _amount >= minPerTx(_token);
    }

    /**
    * @dev Checks that bridged amount of tokens conforms to the configured execution limits.
    * @param _token address of the token contract.
    * @param _amount amount of bridge tokens.
    * @return true, if specified amount can be processed and executed.
    */
    function withinExecutionLimit(address _token, uint256 _amount) public view returns (bool) {
        uint256 nextLimit = totalExecutedPerDay(_token, getCurrentDay()).add(_amount);
        return
            executionDailyLimit(address(0)) > 0 &&
                executionDailyLimit(_token) >= nextLimit &&
                _amount <= executionMaxPerTx(_token);
    }

    /**
    * @dev Returns current day number.
    * @return day number.
    */
    function getCurrentDay() public view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return now / 1 days;
    }

    /**
    * @dev Updates daily limit for the particular token. Only owner can call this method.
    * @param _token address of the token contract, or address(0) for configuring the efault limit.
    * @param _dailyLimit daily allowed amount of bridged tokens, should be greater than maxPerTx.
    * 0 value is also allowed, will stop the bridge operations in outgoing direction.
    */
    function setDailyLimit(address _token, uint256 _dailyLimit) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_dailyLimit > maxPerTx(_token) || _dailyLimit == 0);
        uintStorage[keccak256(abi.encodePacked("dailyLimit", _token))] = _dailyLimit;
        emit DailyLimitChanged(_token, _dailyLimit);
    }

    /**
    * @dev Updates execution daily limit for the particular token. Only owner can call this method.
    * @param _token address of the token contract, or address(0) for configuring the default limit.
    * @param _dailyLimit daily allowed amount of executed tokens, should be greater than executionMaxPerTx.
    * 0 value is also allowed, will stop the bridge operations in incoming direction.
    */
    function setExecutionDailyLimit(address _token, uint256 _dailyLimit) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_dailyLimit > executionMaxPerTx(_token) || _dailyLimit == 0);
        uintStorage[keccak256(abi.encodePacked("executionDailyLimit", _token))] = _dailyLimit;
        emit ExecutionDailyLimitChanged(_token, _dailyLimit);
    }

    /**
    * @dev Updates execution maximum per transaction for the particular token. Only owner can call this method.
    * @param _token address of the token contract, or address(0) for configuring the default limit.
    * @param _maxPerTx maximum amount of executed tokens per one transaction, should be less than executionDailyLimit.
    * 0 value is also allowed, will stop the bridge operations in incoming direction.
    */
    function setExecutionMaxPerTx(address _token, uint256 _maxPerTx) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_maxPerTx == 0 || (_maxPerTx > 0 && _maxPerTx < executionDailyLimit(_token)));
        uintStorage[keccak256(abi.encodePacked("executionMaxPerTx", _token))] = _maxPerTx;
    }

    /**
    * @dev Updates maximum per transaction for the particular token. Only owner can call this method.
    * @param _token address of the token contract, or address(0) for configuring the default limit.
    * @param _maxPerTx maximum amount of tokens per one transaction, should be less than dailyLimit, greater than minPerTx.
    * 0 value is also allowed, will stop the bridge operations in outgoing direction.
    */
    function setMaxPerTx(address _token, uint256 _maxPerTx) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_maxPerTx == 0 || (_maxPerTx > minPerTx(_token) && _maxPerTx < dailyLimit(_token)));
        uintStorage[keccak256(abi.encodePacked("maxPerTx", _token))] = _maxPerTx;
    }

    /**
    * @dev Updates minumum per transaction for the particular token. Only owner can call this method.
    * @param _token address of the token contract, or address(0) for configuring the default limit.
    * @param _minPerTx minumum amount of tokens per one transaction, should be less than maxPerTx and dailyLimit.
    */
    function setMinPerTx(address _token, uint256 _minPerTx) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_minPerTx > 0 && _minPerTx < dailyLimit(_token) && _minPerTx < maxPerTx(_token));
        uintStorage[keccak256(abi.encodePacked("minPerTx", _token))] = _minPerTx;
    }

    /**
    * @dev Retrieves maximum available bridge amount per one transaction taking into account maxPerTx() and dailyLimit() parameters.
    * @param _token address of the token contract, or address(0) for the default limit.
    * @return minimum of maxPerTx parameter and remaining daily quota.
    */
    function maxAvailablePerTx(address _token) public view returns (uint256) {
        uint256 _maxPerTx = maxPerTx(_token);
        uint256 _dailyLimit = dailyLimit(_token);
        uint256 _spent = totalSpentPerDay(_token, getCurrentDay());
        uint256 _remainingOutOfDaily = _dailyLimit > _spent ? _dailyLimit - _spent : 0;
        return _maxPerTx < _remainingOutOfDaily ? _maxPerTx : _remainingOutOfDaily;
    }

    /**
    * @dev Internal function for adding spent amount for some token.
    * @param _token address of the token contract.
    * @param _day day number, when tokens are processed.
    * @param _value amount of bridge tokens.
    */
    function addTotalSpentPerDay(address _token, uint256 _day, uint256 _value) internal {
        uintStorage[keccak256(abi.encodePacked("totalSpentPerDay", _token, _day))] = totalSpentPerDay(_token, _day).add(
            _value
        );
    }

    /**
    * @dev Internal function for adding execcuted amount for some token.
    * @param _token address of the token contract.
    * @param _day day number, when tokens are processed.
    * @param _value amount of bridge tokens.
    */
    function addTotalExecutedPerDay(address _token, uint256 _day, uint256 _value) internal {
        uintStorage[keccak256(abi.encodePacked("totalExecutedPerDay", _token, _day))] = totalExecutedPerDay(
            _token,
            _day
        )
            .add(_value);
    }

    /**
    * @dev Internal function for initializing limits for some token.
    * @param _token address of the token contract.
    * @param _limits [ 0 = dailyLimit, 1 = maxPerTx, 2 = minPerTx ].
    */
    function _setLimits(address _token, uint256[3] _limits) internal {
        require(
            _limits[2] > 0 && // minPerTx > 0
                _limits[1] > _limits[2] && // maxPerTx > minPerTx
                _limits[0] > _limits[1] // dailyLimit > maxPerTx
        );

        uintStorage[keccak256(abi.encodePacked("dailyLimit", _token))] = _limits[0];
        uintStorage[keccak256(abi.encodePacked("maxPerTx", _token))] = _limits[1];
        uintStorage[keccak256(abi.encodePacked("minPerTx", _token))] = _limits[2];

        emit DailyLimitChanged(_token, _limits[0]);
    }

    /**
    * @dev Internal function for initializing execution limits for some token.
    * @param _token address of the token contract.
    * @param _limits [ 0 = executionDailyLimit, 1 = executionMaxPerTx ].
    */
    function _setExecutionLimits(address _token, uint256[2] _limits) internal {
        require(_limits[1] < _limits[0]); // foreignMaxPerTx < foreignDailyLimit

        uintStorage[keccak256(abi.encodePacked("executionDailyLimit", _token))] = _limits[0];
        uintStorage[keccak256(abi.encodePacked("executionMaxPerTx", _token))] = _limits[1];

        emit ExecutionDailyLimitChanged(_token, _limits[0]);
    }

    /**
    * @dev Internal function for initializing limits for some token relative to its decimals parameter.
    * @param _token address of the token contract.
    * @param _decimals token decimals parameter.
    */
    function _initializeTokenBridgeLimits(address _token, uint256 _decimals) internal {
        uint256 factor;
        if (_decimals < 18) {
            factor = 10**(18 - _decimals);

            uint256 _minPerTx = minPerTx(address(0)).div(factor);
            uint256 _maxPerTx = maxPerTx(address(0)).div(factor);
            uint256 _dailyLimit = dailyLimit(address(0)).div(factor);
            uint256 _executionMaxPerTx = executionMaxPerTx(address(0)).div(factor);
            uint256 _executionDailyLimit = executionDailyLimit(address(0)).div(factor);

            // such situation can happen when calculated limits relative to the token decimals are too low
            // e.g. minPerTx(address(0)) == 10 ** 14, _decimals == 3. _minPerTx happens to be 0, which is not allowed.
            // in this case, limits are raised to the default values
            if (_minPerTx == 0) {
                // Numbers 1, 100, 10000 are chosen in a semi-random way,
                // so that any token with small decimals can still be bridged in some amounts.
                // It is possible to override limits for the particular token later if needed.
                _minPerTx = 1;
                if (_maxPerTx <= _minPerTx) {
                    _maxPerTx = 100;
                    _executionMaxPerTx = 100;
                    if (_dailyLimit <= _maxPerTx || _executionDailyLimit <= _executionMaxPerTx) {
                        _dailyLimit = 10000;
                        _executionDailyLimit = 10000;
                    }
                }
            }
            _setLimits(_token, [_dailyLimit, _maxPerTx, _minPerTx]);
            _setExecutionLimits(_token, [_executionDailyLimit, _executionMaxPerTx]);
        } else {
            factor = 10**(_decimals - 18);
            _setLimits(
                _token,
                [dailyLimit(address(0)).mul(factor), maxPerTx(address(0)).mul(factor), minPerTx(address(0)).mul(factor)]
            );
            _setExecutionLimits(
                _token,
                [executionDailyLimit(address(0)).mul(factor), executionMaxPerTx(address(0)).mul(factor)]
            );
        }
    }
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

// File: contracts/upgradeable_contracts/BasicAMBMediator.sol

pragma solidity 0.4.24;





/**
* @title BasicAMBMediator
* @dev Basic storage and methods needed by mediators to interact with AMB bridge.
*/
contract BasicAMBMediator is Ownable {
    bytes32 internal constant BRIDGE_CONTRACT = 0x811bbb11e8899da471f0e69a3ed55090fc90215227fc5fb1cb0d6e962ea7b74f; // keccak256(abi.encodePacked("bridgeContract"))
    bytes32 internal constant MEDIATOR_CONTRACT = 0x98aa806e31e94a687a31c65769cb99670064dd7f5a87526da075c5fb4eab9880; // keccak256(abi.encodePacked("mediatorContract"))
    bytes32 internal constant REQUEST_GAS_LIMIT = 0x2dfd6c9f781bb6bbb5369c114e949b69ebb440ef3d4dd6b2836225eb1dc3a2be; // keccak256(abi.encodePacked("requestGasLimit"))

    /**
    * @dev Throws if caller on the other side is not an associated mediator.
    */
    modifier onlyMediator {
        require(msg.sender == address(bridgeContract()));
        require(messageSender() == mediatorContractOnOtherSide());
        _;
    }

    /**
    * @dev Sets the AMB bridge contract address. Only the owner can call this method.
    * @param _bridgeContract the address of the bridge contract.
    */
    function setBridgeContract(address _bridgeContract) external onlyOwner {
        _setBridgeContract(_bridgeContract);
    }

    /**
    * @dev Sets the mediator contract address from the other network. Only the owner can call this method.
    * @param _mediatorContract the address of the mediator contract.
    */
    function setMediatorContractOnOtherSide(address _mediatorContract) external onlyOwner {
        _setMediatorContractOnOtherSide(_mediatorContract);
    }

    /**
    * @dev Sets the gas limit to be used in the message execution by the AMB bridge on the other network.
    * This value can't exceed the parameter maxGasPerTx defined on the AMB bridge.
    * Only the owner can call this method.
    * @param _requestGasLimit the gas limit for the message execution.
    */
    function setRequestGasLimit(uint256 _requestGasLimit) external onlyOwner {
        _setRequestGasLimit(_requestGasLimit);
    }

    /**
    * @dev Get the AMB interface for the bridge contract address
    * @return AMB interface for the bridge contract address
    */
    function bridgeContract() public view returns (IAMB) {
        return IAMB(addressStorage[BRIDGE_CONTRACT]);
    }

    /**
    * @dev Tells the mediator contract address from the other network.
    * @return the address of the mediator contract.
    */
    function mediatorContractOnOtherSide() public view returns (address) {
        return addressStorage[MEDIATOR_CONTRACT];
    }

    /**
    * @dev Tells the gas limit to be used in the message execution by the AMB bridge on the other network.
    * @return the gas limit for the message execution.
    */
    function requestGasLimit() public view returns (uint256) {
        return uintStorage[REQUEST_GAS_LIMIT];
    }

    /**
    * @dev Stores a valid AMB bridge contract address.
    * @param _bridgeContract the address of the bridge contract.
    */
    function _setBridgeContract(address _bridgeContract) internal {
        require(AddressUtils.isContract(_bridgeContract));
        addressStorage[BRIDGE_CONTRACT] = _bridgeContract;
    }

    /**
    * @dev Stores the mediator contract address from the other network.
    * @param _mediatorContract the address of the mediator contract.
    */
    function _setMediatorContractOnOtherSide(address _mediatorContract) internal {
        addressStorage[MEDIATOR_CONTRACT] = _mediatorContract;
    }

    /**
    * @dev Stores the gas limit to be used in the message execution by the AMB bridge on the other network.
    * @param _requestGasLimit the gas limit for the message execution.
    */
    function _setRequestGasLimit(uint256 _requestGasLimit) internal {
        require(_requestGasLimit <= maxGasPerTx());
        uintStorage[REQUEST_GAS_LIMIT] = _requestGasLimit;
    }

    /**
    * @dev Tells the address that generated the message on the other network that is currently being executed by
    * the AMB bridge.
    * @return the address of the message sender.
    */
    function messageSender() internal view returns (address) {
        return bridgeContract().messageSender();
    }

    /**
    * @dev Tells the id of the message originated on the other network.
    * @return the id of the message originated on the other network.
    */
    function messageId() internal view returns (bytes32) {
        return bridgeContract().messageId();
    }

    /**
    * @dev Tells the maximum gas limit that a message can use on its execution by the AMB bridge on the other network.
    * @return the maximum gas limit value.
    */
    function maxGasPerTx() internal view returns (uint256) {
        return bridgeContract().maxGasPerTx();
    }
}

// File: contracts/upgradeable_contracts/ChooseReceiverHelper.sol

pragma solidity 0.4.24;


contract ChooseReceiverHelper {
    /**
    * @dev Helper function for alternative receiver feature. Chooses the actual receiver out of sender and passed data.
    * @param _from address of tokens sender.
    * @param _data passed data in the transfer message.
    * @return address of the receiver on the other side.
    */
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
    function bridgeContractOnOtherSide() internal view returns (address);
}

// File: contracts/upgradeable_contracts/TransferInfoStorage.sol

pragma solidity 0.4.24;


contract TransferInfoStorage is EternalStorage {
    /**
    * @dev Stores the value of a message sent to the AMB bridge.
    * @param _messageId of the message sent to the bridge.
    * @param _value amount of tokens bridged.
    */
    function setMessageValue(bytes32 _messageId, uint256 _value) internal {
        uintStorage[keccak256(abi.encodePacked("messageValue", _messageId))] = _value;
    }

    /**
    * @dev Tells the amount of tokens of a message sent to the AMB bridge.
    * @return value representing amount of tokens.
    */
    function messageValue(bytes32 _messageId) internal view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("messageValue", _messageId))];
    }

    /**
    * @dev Stores the receiver of a message sent to the AMB bridge.
    * @param _messageId of the message sent to the bridge.
    * @param _recipient receiver of the tokens bridged.
    */
    function setMessageRecipient(bytes32 _messageId, address _recipient) internal {
        addressStorage[keccak256(abi.encodePacked("messageRecipient", _messageId))] = _recipient;
    }

    /**
    * @dev Tells the receiver of a message sent to the AMB bridge.
    * @return address of the receiver.
    */
    function messageRecipient(bytes32 _messageId) internal view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("messageRecipient", _messageId))];
    }

    /**
    * @dev Sets that the message sent to the AMB bridge has been fixed.
    * @param _messageId of the message sent to the bridge.
    */
    function setMessageFixed(bytes32 _messageId) internal {
        boolStorage[keccak256(abi.encodePacked("messageFixed", _messageId))] = true;
    }

    /**
    * @dev Tells if a message sent to the AMB bridge has been fixed.
    * @return bool indicating the status of the message.
    */
    function messageFixed(bytes32 _messageId) public view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked("messageFixed", _messageId))];
    }
}

// File: contracts/upgradeable_contracts/multi_amb_erc20_to_erc677/MultiTokenBridgeMediator.sol

pragma solidity 0.4.24;






/**
* @title MultiTokenBridgeMediator
* @dev Common mediator functionality to handle operations related to multi-token bridge messages sent to AMB bridge.
*/
contract MultiTokenBridgeMediator is
    BasicAMBMediator,
    BasicMultiTokenBridge,
    TransferInfoStorage,
    ChooseReceiverHelper
{
    event FailedMessageFixed(bytes32 indexed messageId, address token, address recipient, uint256 value);
    event TokensBridgingInitiated(
        address indexed token,
        address indexed sender,
        uint256 value,
        bytes32 indexed messageId
    );
    event TokensBridged(address indexed token, address indexed recipient, uint256 value, bytes32 indexed messageId);

    /**
    * @dev Stores the bridged token of a message sent to the AMB bridge.
    * @param _messageId of the message sent to the bridge.
    * @param _token bridged token address.
    */
    function setMessageToken(bytes32 _messageId, address _token) internal {
        addressStorage[keccak256(abi.encodePacked("messageToken", _messageId))] = _token;
    }

    /**
    * @dev Tells the bridged token address of a message sent to the AMB bridge.
    * @return address of a token contract.
    */
    function messageToken(bytes32 _messageId) internal view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("messageToken", _messageId))];
    }

    /**
    * @dev Handles the bridged tokens. Checks that the value is inside the execution limits and invokes the method
    * to execute the Mint or Unlock accordingly.
    * @param _token bridged ERC20/ERC677 token
    * @param _recipient address that will receive the tokens
    * @param _value amount of tokens to be received
    */
    function _handleBridgedTokens(ERC677 _token, address _recipient, uint256 _value) internal {
        if (withinExecutionLimit(_token, _value)) {
            addTotalExecutedPerDay(_token, getCurrentDay(), _value);
            executeActionOnBridgedTokens(_token, _recipient, _value);
        } else {
            executeActionOnBridgedTokensOutOfLimit(_token, _recipient, _value);
        }
    }

    /**
    * @dev Method to be called when a bridged message execution failed. It will generate a new message requesting to
    * fix/roll back the transferred assets on the other network.
    * @param _messageId id of the message which execution failed.
    */
    function requestFailedMessageFix(bytes32 _messageId) external {
        require(!bridgeContract().messageCallStatus(_messageId));
        require(bridgeContract().failedMessageReceiver(_messageId) == address(this));
        require(bridgeContract().failedMessageSender(_messageId) == mediatorContractOnOtherSide());

        bytes4 methodSelector = this.fixFailedMessage.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, _messageId);
        bridgeContract().requireToPassMessage(mediatorContractOnOtherSide(), data, requestGasLimit());
    }

    /**
    * @dev Handles the request to fix transferred assets which bridged message execution failed on the other network.
    * It uses the information stored by passMessage method when the assets were initially transferred
    * @param _messageId id of the message which execution failed on the other network.
    */
    function fixFailedMessage(bytes32 _messageId) public onlyMediator {
        require(!messageFixed(_messageId));

        address token = messageToken(_messageId);
        address recipient = messageRecipient(_messageId);
        uint256 value = messageValue(_messageId);
        setMessageFixed(_messageId);
        executeActionOnFixedTokens(token, recipient, value);
        emit FailedMessageFixed(_messageId, token, recipient, value);
    }

    /**
    * @dev Execute the action to be performed when the bridge tokens are out of execution limits.
    */
    function executeActionOnBridgedTokensOutOfLimit(address, address, uint256) internal {
        revert();
    }

    /* solcov ignore next */
    function executeActionOnBridgedTokens(address _token, address _recipient, uint256 _value) internal;

    /* solcov ignore next */
    function executeActionOnFixedTokens(address _token, address _recipient, uint256 _value) internal;
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

// File: contracts/upgradeable_contracts/ReentrancyGuard.sol

pragma solidity 0.4.24;

contract ReentrancyGuard {
    function lock() internal returns (bool res) {
        assembly {
            // Even though this is not the same as boolStorage[keccak256(abi.encodePacked("lock"))],
            // since solidity mapping introduces another level of addressing, such slot change is safe
            // for temporary variables which are cleared at the end of the call execution.
            res := sload(0x6168652c307c1e813ca11cfb3a601f1cf3b22452021a5052d8b05f1f1f8a3e92) // keccak256(abi.encodePacked("lock"))
        }
    }

    function setLock(bool _lock) internal {
        assembly {
            // Even though this is not the same as boolStorage[keccak256(abi.encodePacked("lock"))],
            // since solidity mapping introduces another level of addressing, such slot change is safe
            // for temporary variables which are cleared at the end of the call execution.
            sstore(0x6168652c307c1e813ca11cfb3a601f1cf3b22452021a5052d8b05f1f1f8a3e92, _lock) // keccak256(abi.encodePacked("lock"))
        }
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

// File: contracts/libraries/SafeERC20.sol

pragma solidity 0.4.24;



/**
 * @title SafeERC20
 * @dev Helper methods for safe token transfers.
 * Functions perform additional checks to be sure that token transfer really happened.
 */
library SafeERC20 {
    using SafeMath for uint256;

    /**
    * @dev Same as ERC20.transfer(address,uint256) but with extra consistency checks.
    * @param _token address of the token contract
    * @param _to address of the receiver
    * @param _value amount of tokens to send
    */
    function safeTransfer(address _token, address _to, uint256 _value) internal {
        LegacyERC20(_token).transfer(_to, _value);
        assembly {
            if returndatasize {
                returndatacopy(0, 0, 32)
                if iszero(mload(0)) {
                    revert(0, 0)
                }
            }
        }
    }

    /**
    * @dev Same as ERC20.transferFrom(address,address,uint256) but with extra consistency checks.
    * @param _token address of the token contract
    * @param _from address of the sender
    * @param _value amount of tokens to send
    */
    function safeTransferFrom(address _token, address _from, uint256 _value) internal {
        LegacyERC20(_token).transferFrom(_from, address(this), _value);
        assembly {
            if returndatasize {
                returndatacopy(0, 0, 32)
                if iszero(mload(0)) {
                    revert(0, 0)
                }
            }
        }
    }
}

// File: contracts/upgradeable_contracts/Claimable.sol

pragma solidity 0.4.24;



/**
 * @title Claimable
 * @dev Implementation of the claiming utils that can be useful for withdrawing accidentally sent tokens that are not used in bridge operations.
 */
contract Claimable {
    using SafeERC20 for address;

    /**
     * Throws if a given address is equal to address(0)
     */
    modifier validAddress(address _to) {
        require(_to != address(0));
        /* solcov ignore next */
        _;
    }

    /**
     * @dev Withdraws the erc20 tokens or native coins from this contract.
     * Caller should additionally check that the claimed token is not a part of bridge operations (i.e. that token != erc20token()).
     * @param _token address of the claimed token or address(0) for native coins.
     * @param _to address of the tokens/coins receiver.
     */
    function claimValues(address _token, address _to) internal validAddress(_to) {
        if (_token == address(0)) {
            claimNativeCoins(_to);
        } else {
            claimErc20Tokens(_token, _to);
        }
    }

    /**
     * @dev Internal function for withdrawing all native coins from the contract.
     * @param _to address of the coins receiver.
     */
    function claimNativeCoins(address _to) internal {
        uint256 value = address(this).balance;
        Address.safeSendValue(_to, value);
    }

    /**
     * @dev Internal function for withdrawing all tokens of ssome particular ERC20 contract from this contract.
     * @param _token address of the claimed ERC20 token.
     * @param _to address of the tokens receiver.
     */
    function claimErc20Tokens(address _token, address _to) internal {
        ERC20Basic token = ERC20Basic(_token);
        uint256 balance = token.balanceOf(this);
        _token.safeTransfer(_to, balance);
    }
}

// File: contracts/upgradeable_contracts/VersionableBridge.sol

pragma solidity 0.4.24;

contract VersionableBridge {
    function getBridgeInterfacesVersion() external pure returns (uint64 major, uint64 minor, uint64 patch) {
        return (5, 2, 0);
    }

    /* solcov ignore next */
    function getBridgeMode() external pure returns (bytes4);
}

// File: contracts/upgradeable_contracts/multi_amb_erc20_to_erc677/BasicMultiAMBErc20ToErc677.sol

pragma solidity 0.4.24;









/**
* @title BasicMultiAMBErc20ToErc677
* @dev Common functionality for multi-erc20-to-erc677 mediator intended to work on top of AMB bridge.
*/
contract BasicMultiAMBErc20ToErc677 is
    Initializable,
    ReentrancyGuard,
    Upgradeable,
    Claimable,
    VersionableBridge,
    MultiTokenBridgeMediator
{
    /**
    * @dev Tells the address of the mediator contract on the other side, used by chooseReceiver method
    * to avoid sending the native tokens to that address.
    * @return address of the mediator contract con the other side
    */
    function bridgeContractOnOtherSide() internal view returns (address) {
        return mediatorContractOnOtherSide();
    }

    /**
    * @dev Initiate the bridge operation for some amount of tokens from msg.sender.
    * The user should first call Approve method of the ERC677 token.
    * @param token bridged token contract address.
    * @param _receiver address that will receive the native tokens on the other network.
    * @param _value amount of tokens to be transferred to the other network.
    */
    function relayTokens(ERC677 token, address _receiver, uint256 _value) external {
        _relayTokens(token, _receiver, _value);
    }

    /**
    * @dev Initiate the bridge operation for some amount of tokens from msg.sender to msg.sender on the other side.
    * The user should first call Approve method of the ERC677 token.
    * @param token bridged token contract address.
    * @param _value amount of tokens to be transferred to the other network.
    */
    function relayTokens(ERC677 token, uint256 _value) external {
        _relayTokens(token, msg.sender, _value);
    }

    /**
    * @dev Tells the bridge interface version that this contract supports.
    * @return major value of the version
    * @return minor value of the version
    * @return patch value of the version
    */
    function getBridgeInterfacesVersion() external pure returns (uint64 major, uint64 minor, uint64 patch) {
        return (1, 5, 0);
    }

    /**
    * @dev Tells the bridge mode that this contract supports.
    * @return _data 4 bytes representing the bridge mode
    */
    function getBridgeMode() external pure returns (bytes4 _data) {
        return 0xb1516c26; // bytes4(keccak256(abi.encodePacked("multi-erc-to-erc-amb")))
    }

    /**
    * @dev Claims stucked tokens. Only unsupported tokens can be claimed.
    * When dealing with already supported tokens, fixMediatorBalance can be used instead.
    * @param _token address of claimed token, address(0) for native
    * @param _to address of tokens receiver
    */
    function claimTokens(address _token, address _to) external onlyIfUpgradeabilityOwner {
        // Only unregistered tokens and native coins are allowed to be claimed with the use of this function
        require(_token == address(0) || !isTokenRegistered(_token));
        claimValues(_token, _to);
    }

    /* solcov ignore next */
    function onTokenTransfer(address _from, uint256 _value, bytes _data) public returns (bool);

    /* solcov ignore next */
    function _relayTokens(ERC677 token, address _receiver, uint256 _value) internal;

    /* solcov ignore next */
    function bridgeSpecificActionsOnTokenTransfer(ERC677 _token, address _from, address _receiver, uint256 _value)
        internal;
}

// File: contracts/upgradeability/Proxy.sol

pragma solidity 0.4.24;

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract Proxy {
    /**
    * @dev Tells the address of the implementation where every call will be delegated.
    * @return address of the implementation to which it will be delegated
    */
    /* solcov ignore next */
    function implementation() public view returns (address);

    /**
    * @dev Fallback function allowing to perform a delegatecall to the given implementation.
    * This function will return whatever the implementation call returns
    */
    function() public payable {
        // solhint-disable-previous-line no-complex-fallback
        address _impl = implementation();
        require(_impl != address(0));
        assembly {
            /*
                0x40 is the "free memory slot", meaning a pointer to next slot of empty memory. mload(0x40)
                loads the data in the free memory slot, so `ptr` is a pointer to the next slot of empty
                memory. It's needed because we're going to write the return data of delegatecall to the
                free memory slot.
            */
            let ptr := mload(0x40)
            /*
                `calldatacopy` is copy calldatasize bytes from calldata
                First argument is the destination to which data is copied(ptr)
                Second argument specifies the start position of the copied data.
                    Since calldata is sort of its own unique location in memory,
                    0 doesn't refer to 0 in memory or 0 in storage - it just refers to the zeroth byte of calldata.
                    That's always going to be the zeroth byte of the function selector.
                Third argument, calldatasize, specifies how much data will be copied.
                    calldata is naturally calldatasize bytes long (same thing as msg.data.length)
            */
            calldatacopy(ptr, 0, calldatasize)
            /*
                delegatecall params explained:
                gas: the amount of gas to provide for the call. `gas` is an Opcode that gives
                    us the amount of gas still available to execution

                _impl: address of the contract to delegate to

                ptr: to pass copied data

                calldatasize: loads the size of `bytes memory data`, same as msg.data.length

                0, 0: These are for the `out` and `outsize` params. Because the output could be dynamic,
                        these are set to 0, 0 so the output data will not be written to memory. The output
                        data will be read using `returndatasize` and `returdatacopy` instead.

                result: This will be 0 if the call fails and 1 if it succeeds
            */
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            /*

            */
            /*
                ptr current points to the value stored at 0x40,
                because we assigned it like ptr := mload(0x40).
                Because we use 0x40 as a free memory pointer,
                we want to make sure that the next time we want to allocate memory,
                we aren't overwriting anything important.
                So, by adding ptr and returndatasize,
                we get a memory location beyond the end of the data we will be copying to ptr.
                We place this in at 0x40, and any reads from 0x40 will now read from free memory
            */
            mstore(0x40, add(ptr, returndatasize))
            /*
                `returndatacopy` is an Opcode that copies the last return data to a slot. `ptr` is the
                    slot it will copy to, 0 means copy from the beginning of the return data, and size is
                    the amount of data to copy.
                `returndatasize` is an Opcode that gives us the size of the last return data. In this case, that is the size of the data returned from delegatecall
            */
            returndatacopy(ptr, 0, returndatasize)

            /*
                if `result` is 0, revert.
                if `result` is 1, return `size` amount of data from `ptr`. This is the data that was
                copied to `ptr` from the delegatecall return data
            */
            switch result
                case 0 {
                    revert(ptr, returndatasize)
                }
                default {
                    return(ptr, returndatasize)
                }
        }
    }
}

// File: contracts/upgradeable_contracts/multi_amb_erc20_to_erc677/TokenProxy.sol

pragma solidity 0.4.24;


interface IPermittableTokenVersion {
    function version() external pure returns (string);
}

/**
* @title TokenProxy
* @dev Helps to reduces the size of the deployed bytecode for automatically created tokens, by using a proxy contract.
*/
contract TokenProxy is Proxy {
    // storage layout is copied from PermittableToken.sol
    string internal name;
    string internal symbol;
    uint8 internal decimals;
    mapping(address => uint256) internal balances;
    uint256 internal totalSupply;
    mapping(address => mapping(address => uint256)) internal allowed;
    address internal owner;
    bool internal mintingFinished;
    address internal bridgeContractAddr;
    // string public constant version = "1";
    bytes32 internal DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
    mapping(address => uint256) internal nonces;
    mapping(address => mapping(address => uint256)) internal expirations;

    /**
    * @dev Creates a non-upgradeable token proxy for PermitableToken.sol, initializes its eternalStorage.
    * @param _tokenImage address of the token image used for mirroring all functions.
    * @param _name token name.
    * @param _symbol token symbol.
    * @param _decimals token decimals.
    * @param _chainId chain id for current network.
    */
    constructor(address _tokenImage, string memory _name, string memory _symbol, uint8 _decimals, uint256 _chainId)
        public
    {
        string memory version = IPermittableTokenVersion(_tokenImage).version();

        assembly {
            // EIP 1967
            // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, _tokenImage)
        }
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = msg.sender; // msg.sender == HomeMultiAMBErc20ToErc677 mediator
        bridgeContractAddr = msg.sender;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(_name)),
                keccak256(bytes(version)),
                _chainId,
                address(this)
            )
        );
    }

    /**
    * @dev Retrieves the implementation contract address, mirrored token image.
    * @return token image address.
    */
    function implementation() public view returns (address impl) {
        assembly {
            impl := sload(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)
        }
    }
}

// File: contracts/upgradeable_contracts/BaseRewardAddressList.sol

pragma solidity 0.4.24;



/**
* @title BaseRewardAddressList
* @dev Implements the logic to store, add and remove reward account addresses. Works as a linked list.
*/
contract BaseRewardAddressList is EternalStorage {
    using SafeMath for uint256;

    address public constant F_ADDR = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
    uint256 internal constant MAX_REWARD_ADDRESSES = 50;
    bytes32 internal constant REWARD_ADDRESS_COUNT = 0xabc77c82721ced73eef2645facebe8c30249e6ac372cce6eb9d1fed31bd6648f; // keccak256(abi.encodePacked("rewardAddressCount"))

    event RewardAddressAdded(address indexed addr);
    event RewardAddressRemoved(address indexed addr);

    /**
    * @dev Retrieves all registered reward accounts.
    * @return address list of the registered reward receivers.
    */
    function rewardAddressList() external view returns (address[]) {
        address[] memory list = new address[](rewardAddressCount());
        uint256 counter = 0;
        address nextAddr = getNextRewardAddress(F_ADDR);

        while (nextAddr != F_ADDR) {
            require(nextAddr != address(0));

            list[counter] = nextAddr;
            nextAddr = getNextRewardAddress(nextAddr);
            counter++;
        }

        return list;
    }

    /**
    * @dev Retrieves amount of registered reward accounts.
    * @return length of reward addresses list.
    */
    function rewardAddressCount() public view returns (uint256) {
        return uintStorage[REWARD_ADDRESS_COUNT];
    }

    /**
    * @dev Checks if specified address is included into the registered rewards receivers list.
    * @param _addr address to verify.
    * @return true, if specified address is associated with one of the registered reward accounts.
    */
    function isRewardAddress(address _addr) public view returns (bool) {
        return _addr != F_ADDR && getNextRewardAddress(_addr) != address(0);
    }

    /**
    * @dev Retrieves next reward address in the linked list, or F_ADDR if given address is the last one.
    * @param _address address of some reward account.
    * @return address of the next reward receiver.
    */
    function getNextRewardAddress(address _address) public view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("rewardAddressList", _address))];
    }

    /**
    * @dev Internal function for adding a new reward address to the linked list.
    * @param _addr new reward account.
    */
    function _addRewardAddress(address _addr) internal {
        require(_addr != address(0) && _addr != F_ADDR);
        require(!isRewardAddress(_addr));

        address nextAddr = getNextRewardAddress(F_ADDR);

        require(nextAddr != address(0));

        _setNextRewardAddress(_addr, nextAddr);
        _setNextRewardAddress(F_ADDR, _addr);
        _setRewardAddressCount(rewardAddressCount().add(1));
    }

    /**
    * @dev Internal function for removing existing reward address from the linked list.
    * @param _addr old reward account which should be removed.
    */
    function _removeRewardAddress(address _addr) internal {
        require(isRewardAddress(_addr));
        address nextAddr = getNextRewardAddress(_addr);
        address index = F_ADDR;
        address next = getNextRewardAddress(index);

        while (next != _addr) {
            require(next != address(0));
            index = next;
            next = getNextRewardAddress(index);
            require(next != F_ADDR);
        }

        _setNextRewardAddress(index, nextAddr);
        delete addressStorage[keccak256(abi.encodePacked("rewardAddressList", _addr))];
        _setRewardAddressCount(rewardAddressCount().sub(1));
    }

    /**
    * @dev Internal function for initializing linked list with the array of the initial reward addresses.
    * @param _rewardAddresses initial reward addresses list, should be non-empty.
    */
    function _setRewardAddressList(address[] _rewardAddresses) internal {
        require(_rewardAddresses.length > 0);

        _setNextRewardAddress(F_ADDR, _rewardAddresses[0]);

        for (uint256 i = 0; i < _rewardAddresses.length; i++) {
            require(_rewardAddresses[i] != address(0) && _rewardAddresses[i] != F_ADDR);
            require(!isRewardAddress(_rewardAddresses[i]));

            if (i == _rewardAddresses.length - 1) {
                _setNextRewardAddress(_rewardAddresses[i], F_ADDR);
            } else {
                _setNextRewardAddress(_rewardAddresses[i], _rewardAddresses[i + 1]);
            }

            emit RewardAddressAdded(_rewardAddresses[i]);
        }

        _setRewardAddressCount(_rewardAddresses.length);
    }

    /**
    * @dev Internal function for updating the length of the reward accounts list.
    * @param _rewardAddressCount new linked list length.
    */
    function _setRewardAddressCount(uint256 _rewardAddressCount) internal {
        require(_rewardAddressCount <= MAX_REWARD_ADDRESSES);
        uintStorage[REWARD_ADDRESS_COUNT] = _rewardAddressCount;
    }

    /**
    * @dev Internal function for updating the pointer to the next reward receiver.
    * @param _prevAddr address of some reward receiver.
    * @param _addr address of the next receiver to which _prevAddr should point to.
    */
    function _setNextRewardAddress(address _prevAddr, address _addr) internal {
        addressStorage[keccak256(abi.encodePacked("rewardAddressList", _prevAddr))] = _addr;
    }
}

// File: contracts/interfaces/IBurnableMintableERC677Token.sol

pragma solidity 0.4.24;


contract IBurnableMintableERC677Token is ERC677 {
    function mint(address _to, uint256 _amount) public returns (bool);
    function burn(uint256 _value) public;
    function claimTokens(address _token, address _to) external;
}

// File: contracts/upgradeable_contracts/multi_amb_erc20_to_erc677/HomeFeeManagerMultiAMBErc20ToErc677.sol

pragma solidity 0.4.24;






/**
* @title HomeFeeManagerMultiAMBErc20ToErc677
* @dev Implements the logic to distribute fees from the multi erc20 to erc677 mediator contract operations.
* The fees are distributed in the form of native tokens to the list of reward accounts.
*/
contract HomeFeeManagerMultiAMBErc20ToErc677 is BaseRewardAddressList, Ownable, BasicMultiTokenBridge {
    using SafeMath for uint256;

    event FeeUpdated(bytes32 feeType, address indexed token, uint256 fee);
    event FeeDistributed(uint256 fee, address indexed token, bytes32 indexed messageId);

    // This is not a real fee value but a relative value used to calculate the fee percentage
    uint256 internal constant MAX_FEE = 1 ether;
    bytes32 public constant HOME_TO_FOREIGN_FEE = 0x741ede137d0537e88e0ea0ff25b1f22d837903dbbee8980b4a06e8523247ee26; // keccak256(abi.encodePacked("homeToForeignFee"))
    bytes32 public constant FOREIGN_TO_HOME_FEE = 0x03be2b2875cb41e0e77355e802a16769bb8dfcf825061cde185c73bf94f12625; // keccak256(abi.encodePacked("foreignToHomeFee"))

    /**
    * @dev Throws if given fee percentage is >= 100%.
    */
    modifier validFee(uint256 _fee) {
        require(_fee < MAX_FEE);
        /* solcov ignore next */
        _;
    }

    /**
    * @dev Throws if given fee type is unknown.
    */
    modifier validFeeType(bytes32 _feeType) {
        require(_feeType == HOME_TO_FOREIGN_FEE || _feeType == FOREIGN_TO_HOME_FEE);
        /* solcov ignore next */
        _;
    }

    /**
    * @dev Adds a new reward address to the list, which will receive fees collected from the bridge operations.
    * Only the owner can call this method.
    * @param _addr new reward account.
    */
    function addRewardAddress(address _addr) external onlyOwner {
        _addRewardAddress(_addr);
    }

    /**
    * @dev Removes a reward address from the rewards list.
    * Only the owner can call this method.
    * @param _addr old reward account, that should be removed.
    */
    function removeRewardAddress(address _addr) external onlyOwner {
        _removeRewardAddress(_addr);
    }

    /**
    * @dev Updates the value for the particular fee type.
    * Only the owner can call this method.
    * @param _feeType type of the updated fee, can be one of [HOME_TO_FOREIGN_FEE, FOREIGN_TO_HOME_FEE].
    * @param _token address of the token contract for which fee should apply, 0x00..00 describes the initial fee for newly created tokens.
    * @param _fee new fee value, in percentage (1 ether == 10**18 == 100%).
    */
    function setFee(bytes32 _feeType, address _token, uint256 _fee) external onlyOwner {
        require(isTokenRegistered(_token));
        _setFee(_feeType, _token, _fee);
    }

    /**
    * @dev Retrieves the value for the particular fee type.
    * @param _feeType type of the updated fee, can be one of [HOME_TO_FOREIGN_FEE, FOREIGN_TO_HOME_FEE].
    * @param _token address of the token contract for which fee should apply, 0x00..00 describes the initial fee for newly created tokens.
    * @return fee value associated with the requested fee type.
    */
    function getFee(bytes32 _feeType, address _token) public view validFeeType(_feeType) returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked(_feeType, _token))];
    }

    /**
    * @dev Calculates the amount of fee to pay for the value of the particular fee type.
    * @param _feeType type of the updated fee, can be one of [HOME_TO_FOREIGN_FEE, FOREIGN_TO_HOME_FEE].
    * @param _token address of the token contract for which fee should apply, 0x00..00 describes the initial fee for newly created tokens.
    * @param _value bridged value, for which fee should be evaluated.
    * @return amount of fee to be subtracted from the transferred value.
    */
    function calculateFee(bytes32 _feeType, address _token, uint256 _value) public view returns (uint256) {
        uint256 _fee = getFee(_feeType, _token);
        return _value.mul(_fee).div(MAX_FEE);
    }

    /**
    * @dev Internal function for updating the fee value for the given fee type.
    * @param _feeType type of the updated fee, can be one of [HOME_TO_FOREIGN_FEE, FOREIGN_TO_HOME_FEE].
    * @param _token address of the token contract for which fee should apply, 0x00..00 describes the initial fee for newly created tokens.
    * @param _fee new fee value, in percentage (1 ether == 10**18 == 100%).
    */
    function _setFee(bytes32 _feeType, address _token, uint256 _fee) internal validFeeType(_feeType) validFee(_fee) {
        uintStorage[keccak256(abi.encodePacked(_feeType, _token))] = _fee;
        emit FeeUpdated(_feeType, _token, _fee);
    }

    /**
    * @dev Calculates a random number based on the block number.
    * @param _count the max value for the random number.
    * @return a number between 0 and _count.
    */
    function random(uint256 _count) internal view returns (uint256) {
        return uint256(blockhash(block.number.sub(1))) % _count;
    }

    /**
    * @dev Calculates and distributes the amount of fee proportionally between registered reward addresses.
    * @param _feeType type of the updated fee, can be one of [HOME_TO_FOREIGN_FEE, FOREIGN_TO_HOME_FEE].
    * @param _token address of the token contract for which fee should apply, 0x00..00 describes the initial fee for newly created tokens.
    * @param _value bridged value, for which fee should be evaluated.
    * @return total amount of fee subtracted from the transferred value and distributed between the reward accounts.
    */
    function _distributeFee(bytes32 _feeType, address _token, uint256 _value) internal returns (uint256) {
        uint256 numOfAccounts = rewardAddressCount();
        uint256 _fee = calculateFee(_feeType, _token, _value);
        if (numOfAccounts == 0 || _fee == 0) {
            return 0;
        }
        uint256 feePerAccount = _fee.div(numOfAccounts);
        uint256 randomAccountIndex;
        uint256 diff = _fee.sub(feePerAccount.mul(numOfAccounts));
        if (diff > 0) {
            randomAccountIndex = random(numOfAccounts);
        }

        address nextAddr = getNextRewardAddress(F_ADDR);
        require(nextAddr != F_ADDR && nextAddr != address(0));

        uint256 i = 0;
        while (nextAddr != F_ADDR) {
            uint256 feeToDistribute = feePerAccount;
            if (diff > 0 && randomAccountIndex == i) {
                feeToDistribute = feeToDistribute.add(diff);
            }

            if (_feeType == HOME_TO_FOREIGN_FEE) {
                ERC677(_token).transfer(nextAddr, feeToDistribute);
            } else {
                _getMinterFor(_token).mint(nextAddr, feeToDistribute);
            }

            nextAddr = getNextRewardAddress(nextAddr);
            require(nextAddr != address(0));
            i = i + 1;
        }
        return _fee;
    }

    function _getMinterFor(address _token) internal view returns (IBurnableMintableERC677Token);
}

// File: contracts/upgradeable_contracts/multi_amb_erc20_to_erc677/MultiTokenForwardingRules.sol

pragma solidity 0.4.24;


/**
 * @title MultiTokenForwardingRules
 * @dev Multi token mediator functionality for managing destination AMB lanes permissions.
 */
contract MultiTokenForwardingRules is Ownable {
    address internal constant ANY_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    event ForwardingRuleUpdated(address token, address sender, address receiver, int256 lane);

    /**
     * @dev Tells the destination lane for a particular bridge operation by checking several wildcard forwarding rules.
     * @param _token address of the token contract on the foreign side of the bridge.
     * @param _sender address of the tokens sender on the home side of the bridge.
     * @param _receiver address of the tokens receiver on the foreign side of the bridge.
     * @return destination lane identifier, where the message should be forwarded to.
     *  1 - oracle-driven-lane should be used.
     *  0 - default behaviour should be applied.
     * -1 - manual lane should be used.
     */
    function destinationLane(address _token, address _sender, address _receiver) public view returns (int256) {
        int256 defaultLane = forwardingRule(_token, ANY_ADDRESS, ANY_ADDRESS); // specific token for all senders and receivers
        int256 lane;
        if (defaultLane < 0) {
            lane = forwardingRule(_token, _sender, ANY_ADDRESS); // specific token for specific sender
            if (lane != 0) return lane;
            lane = forwardingRule(_token, ANY_ADDRESS, _receiver); // specific token for specific receiver
            if (lane != 0) return lane;
            return defaultLane;
        }
        lane = forwardingRule(ANY_ADDRESS, _sender, ANY_ADDRESS); // all tokens for specific sender
        if (lane != 0) return lane;
        return forwardingRule(ANY_ADDRESS, ANY_ADDRESS, _receiver); // all tokens for specific receiver
    }

    /**
     * Updates the forwarding rule for bridging specific token.
     * Only owner can call this method.
     * @param _token address of the token contract on the foreign side.
     * @param _enable true, if bridge operations for a given token should be forwarded to the manual lane.
     */
    function setTokenForwardingRule(address _token, bool _enable) external {
        require(_token != ANY_ADDRESS);
        _setForwardingRule(_token, ANY_ADDRESS, ANY_ADDRESS, _enable ? int256(-1) : int256(0));
    }

    /**
     * Allows a particular address to send bridge requests to the oracle-driven lane for a particular token.
     * Only owner can call this method.
     * @param _token address of the token contract on the foreign side.
     * @param _sender address of the tokens sender on the home side of the bridge.
     * @param _enable true, if bridge operations for a given token and sender should be forwarded to the oracle-driven lane.
     */
    function setSenderExceptionForTokenForwardingRule(address _token, address _sender, bool _enable) external {
        require(_token != ANY_ADDRESS);
        require(_sender != ANY_ADDRESS);
        _setForwardingRule(_token, _sender, ANY_ADDRESS, _enable ? int256(1) : int256(0));
    }

    /**
     * Allows a particular address to receive bridged tokens from the oracle-driven lane for a particular token.
     * Only owner can call this method.
     * @param _token address of the token contract on the foreign side.
     * @param _receiver address of the tokens receiver on the foreign side of the bridge.
     * @param _enable true, if bridge operations for a given token and receiver should be forwarded to the oracle-driven lane.
     */
    function setReceiverExceptionForTokenForwardingRule(address _token, address _receiver, bool _enable) external {
        require(_token != ANY_ADDRESS);
        require(_receiver != ANY_ADDRESS);
        _setForwardingRule(_token, ANY_ADDRESS, _receiver, _enable ? int256(1) : int256(0));
    }

    /**
     * Updates the forwarding rule for the specific sender.
     * Only owner can call this method.
     * @param _sender address of the tokens sender on the home side.
     * @param _enable true, if all bridge operations from a given sender should be forwarded to the manual lane.
     */
    function setSenderForwardingRule(address _sender, bool _enable) external {
        require(_sender != ANY_ADDRESS);
        _setForwardingRule(ANY_ADDRESS, _sender, ANY_ADDRESS, _enable ? int256(-1) : int256(0));
    }

    /**
     * Updates the forwarding rule for the specific receiver.
     * Only owner can call this method.
     * @param _receiver address of the tokens receiver on the foreign side.
     * @param _enable true, if all bridge operations to a given receiver should be forwarded to the manual lane.
     */
    function setReceiverForwardingRule(address _receiver, bool _enable) external {
        require(_receiver != ANY_ADDRESS);
        _setForwardingRule(ANY_ADDRESS, ANY_ADDRESS, _receiver, _enable ? int256(-1) : int256(0));
    }

    /**
     * @dev Tells forwarding rule set up for a particular bridge operation.
     * @param _token address of the token contract on the foreign side of the bridge.
     * @param _sender address of the tokens sender on the home side of the bridge.
     * @param _receiver address of the tokens receiver on the foreign side of the bridge.
     * @return preferred destination lane for the particular bridge operation.
     */
    function forwardingRule(address _token, address _sender, address _receiver) public view returns (int256) {
        return intStorage[keccak256(abi.encodePacked("forwardTo", _token, _sender, _receiver))];
    }

    /**
     * @dev Internal function for updating the preferred destination lane for the specific wildcard pattern.
     * Only owner can call this method.
     * Examples:
     *   _setForwardingRule(tokenA, ANY_ADDRESS, ANY_ADDRESS, -1) - forward all operations on tokenA to the manual lane
     *   _setForwardingRule(tokenA, Alice, ANY_ADDRESS, 1) - allow Alice to use the oracle-driven lane for bridging tokenA
     *   _setForwardingRule(tokenA, ANY_ADDRESS, Bob, 1) - forward all tokenA bridge operations, where Bob is the receiver, to the oracle-driven lane
     *   _setForwardingRule(ANY_ADDRESS, Mallory, ANY_ADDRESS, -1) - forward all bridge operations from Mallory to the manual lane
     * @param _token address of the token contract on the foreign side of the bridge.
     * @param _sender address of the tokens sender on the home side of the bridge.
     * @param _receiver address of the tokens receiver on the foreign side of the bridge.
     * @param _lane preferred destination lane for the particular sender.
     *  1 - forward to the oracle-driven lane.
     *  0 - behaviour is unset, proceed by checking other less-specific rules.
     * -1 - manual lane should be used.
     */
    function _setForwardingRule(address _token, address _sender, address _receiver, int256 _lane) internal onlyOwner {
        intStorage[keccak256(abi.encodePacked("forwardTo", _token, _sender, _receiver))] = _lane;

        emit ForwardingRuleUpdated(_token, _sender, _receiver, _lane);
    }
}

// File: contracts/upgradeable_contracts/multi_amb_erc20_to_erc677/HomeMultiAMBErc20ToErc677.sol

pragma solidity 0.4.24;






/**
* @title HomeMultiAMBErc20ToErc677
* @dev Home side implementation for multi-erc20-to-erc677 mediator intended to work on top of AMB bridge.
* It is designed to be used as an implementation contract of EternalStorageProxy contract.
*/
contract HomeMultiAMBErc20ToErc677 is
    BasicMultiAMBErc20ToErc677,
    HomeFeeManagerMultiAMBErc20ToErc677,
    MultiTokenForwardingRules
{
    bytes32 internal constant TOKEN_IMAGE_CONTRACT = 0x20b8ca26cc94f39fab299954184cf3a9bd04f69543e4f454fab299f015b8130f; // keccak256(abi.encodePacked("tokenImageContract"))

    event NewTokenRegistered(address indexed foreignToken, address indexed homeToken);

    /**
     * @dev Throws if called by any account other than the owner.
     * Overrides modifier from the Ownable contract in order to reduce bytecode size.
     */
    modifier onlyOwner() {
        _onlyOwner();
        /* solcov ignore next */
        _;
    }

    /**
     * @dev Internal function for reducing onlyOwner modifier bytecode size overhead.
     */
    function _onlyOwner() internal {
        require(msg.sender == owner());
    }

    /**
    * @dev Throws if caller on the other side is not an associated mediator.
    */
    modifier onlyMediator() {
        _onlyMediator();
        /* solcov ignore next */
        _;
    }

    /**
     * @dev Internal function for reducing onlyMediator modifier bytecode size overhead.
     */
    function _onlyMediator() internal {
        require(msg.sender == address(bridgeContract()));
        require(messageSender() == mediatorContractOnOtherSide());
    }

    /**
    * @dev Stores the initial parameters of the mediator.
    * @param _bridgeContract the address of the AMB bridge contract.
    * @param _mediatorContract the address of the mediator contract on the other network.
    * @param _dailyLimitMaxPerTxMinPerTxArray array with limit values for the assets to be bridged to the other network.
    *   [ 0 = dailyLimit, 1 = maxPerTx, 2 = minPerTx ]
    * @param _executionDailyLimitExecutionMaxPerTxArray array with limit values for the assets bridged from the other network.
    *   [ 0 = executionDailyLimit, 1 = executionMaxPerTx ]
    * @param _requestGasLimit the gas limit for the message execution.
    * @param _owner address of the owner of the mediator contract.
    * @param _tokenImage address of the PermittableToken contract that will be used for deploying of new tokens.
    * @param _rewardAddresses list of reward addresses, between whom fees will be distributed.
    * @param _fees array with initial fees for both bridge directions.
    *   [ 0 = homeToForeignFee, 1 = foreignToHomeFee ]
    */
    function initialize(
        address _bridgeContract,
        address _mediatorContract,
        uint256[3] _dailyLimitMaxPerTxMinPerTxArray, // [ 0 = _dailyLimit, 1 = _maxPerTx, 2 = _minPerTx ]
        uint256[2] _executionDailyLimitExecutionMaxPerTxArray, // [ 0 = _executionDailyLimit, 1 = _executionMaxPerTx ]
        uint256 _requestGasLimit,
        address _owner,
        address _tokenImage,
        address[] _rewardAddresses,
        uint256[2] _fees // [ 0 = homeToForeignFee, 1 = foreignToHomeFee ]
    ) external onlyRelevantSender returns (bool) {
        require(!isInitialized());

        _setBridgeContract(_bridgeContract);
        _setMediatorContractOnOtherSide(_mediatorContract);
        _setLimits(address(0), _dailyLimitMaxPerTxMinPerTxArray);
        _setExecutionLimits(address(0), _executionDailyLimitExecutionMaxPerTxArray);
        _setRequestGasLimit(_requestGasLimit);
        _setOwner(_owner);
        _setTokenImage(_tokenImage);
        if (_rewardAddresses.length > 0) {
            _setRewardAddressList(_rewardAddresses);
        }
        _setFee(HOME_TO_FOREIGN_FEE, address(0), _fees[0]);
        _setFee(FOREIGN_TO_HOME_FEE, address(0), _fees[1]);

        setInitialize();

        return isInitialized();
    }

    /**
    * @dev Updates an address of the token image contract used for proxifying newly created tokens.
    * @param _tokenImage address of PermittableToken contract.
    */
    function setTokenImage(address _tokenImage) external onlyOwner {
        _setTokenImage(_tokenImage);
    }

    /**
    * @dev Retrieves address of the token image contract.
    * @return address of block reward contract.
    */
    function tokenImage() public view returns (address) {
        return addressStorage[TOKEN_IMAGE_CONTRACT];
    }

    /**
    * @dev Handles the bridged tokens for the first time, includes deployment of new TokenProxy contract.
    * Checks that the value is inside the execution limits and invokes the method
    * to execute the Mint or Unlock accordingly.
    * @param _token address of the bridged ERC20/ERC677 token on the foreign side.
    * @param _name name of the bridged token, "x" will be appended, if empty, symbol will be used instead.
    * @param _symbol symbol of the bridged token, "x" will be appended, if empty, name will be used instead.
    * @param _decimals decimals of the bridge foreign token.
    * @param _recipient address that will receive the tokens.
    * @param _value amount of tokens to be received.
    */
    function deployAndHandleBridgedTokens(
        address _token,
        string _name,
        string _symbol,
        uint8 _decimals,
        address _recipient,
        uint256 _value
    ) external onlyMediator {
        require(owner() == _recipient);
        string memory name = _name;
        string memory symbol = _symbol;
        require(bytes(name).length > 0 || bytes(symbol).length > 0);
        if (bytes(name).length == 0) {
            name = symbol;
        } else if (bytes(symbol).length == 0) {
            symbol = name;
        }
        name = string(abi.encodePacked(name, " on FTM"));
        address homeToken = new TokenProxy(tokenImage(), name, symbol, _decimals, bridgeContract().sourceChainId());
        _setTokenAddressPair(_token, homeToken);
        _initializeTokenBridgeLimits(homeToken, _decimals);
        _setFee(HOME_TO_FOREIGN_FEE, homeToken, getFee(HOME_TO_FOREIGN_FEE, address(0)));
        _setFee(FOREIGN_TO_HOME_FEE, homeToken, getFee(FOREIGN_TO_HOME_FEE, address(0)));
        _handleBridgedTokens(ERC677(homeToken), _recipient, _value);

        emit NewTokenRegistered(_token, homeToken);
    }

    /**
    * @dev Handles the bridged tokens. Checks that the value is inside the execution limits and invokes the method
    * to execute the Mint or Unlock accordingly.
    * @param _token bridged ERC20 token.
    * @param _recipient address that will receive the tokens.
    * @param _value amount of tokens to be received.
    */
    function handleBridgedTokens(ERC677 _token, address _recipient, uint256 _value) external onlyMediator {
        ERC677 homeToken = ERC677(homeTokenAddress(_token));
        require(isTokenRegistered(homeToken));
        _handleBridgedTokens(homeToken, _recipient, _value);
    }

    /**
    * @dev ERC677 transfer callback function.
    * @param _from address of tokens sender.
    * @param _value amount of transferred tokens.
    * @param _data additional transfer data, can be used for passing alternative receiver address.
    */
    function onTokenTransfer(address _from, uint256 _value, bytes _data) public returns (bool) {
        // if onTokenTransfer is called as a part of call to _relayTokens, this callback does nothing
        if (!lock()) {
            ERC677 token = ERC677(msg.sender);
            // if msg.sender if not a valid token contract, this check will fail, since limits are zeros
            // so the following check is not needed
            // require(isTokenRegistered(token));
            require(withinLimit(token, _value));
            addTotalSpentPerDay(token, getCurrentDay(), _value);
            bridgeSpecificActionsOnTokenTransfer(token, _from, chooseReceiver(_from, _data), _value);
        }
        return true;
    }

    /**
    * @dev Validates that the token amount is inside the limits, calls transferFrom to transfer the tokens to the contract
    * and invokes the method to burn/lock the tokens and unlock/mint the tokens on the other network.
    * The user should first call Approve method of the ERC677 token.
    * @param token bridge token contract address.
    * @param _receiver address that will receive the native tokens on the other network.
    * @param _value amount of tokens to be transferred to the other network.
    */
    function _relayTokens(ERC677 token, address _receiver, uint256 _value) internal {
        // This lock is to prevent calling passMessage twice if a ERC677 token is used.
        // When transferFrom is called, after the transfer, the ERC677 token will call onTokenTransfer from this contract
        // which will call passMessage.
        require(!lock());
        address to = address(this);
        // if msg.sender if not a valid token contract, this check will fail, since limits are zeros
        // so the following check is not needed
        // require(isTokenRegistered(token));
        require(withinLimit(token, _value));
        addTotalSpentPerDay(token, getCurrentDay(), _value);

        setLock(true);
        token.transferFrom(msg.sender, to, _value);
        setLock(false);
        bridgeSpecificActionsOnTokenTransfer(token, msg.sender, _receiver, _value);
    }

    /**
     * @dev Executes action on the request to deposit tokens relayed from the other network
     * @param _recipient address of tokens receiver
     * @param _value amount of bridged tokens
     */
    function executeActionOnBridgedTokens(address _token, address _recipient, uint256 _value) internal {
        bytes32 _messageId = messageId();
        uint256 valueToMint = _value;
        uint256 fee = _distributeFee(FOREIGN_TO_HOME_FEE, _token, valueToMint);
        if (fee > 0) {
            emit FeeDistributed(fee, _token, _messageId);
            valueToMint = valueToMint.sub(fee);
        }
        _getMinterFor(_token).mint(_recipient, valueToMint);
        emit TokensBridged(_token, _recipient, valueToMint, _messageId);
    }

    /**
    * @dev Mints back the amount of tokens that were bridged to the other network but failed.
    * @param _token address that bridged token contract.
    * @param _recipient address that will receive the tokens.
    * @param _value amount of tokens to be received.
    */
    function executeActionOnFixedTokens(address _token, address _recipient, uint256 _value) internal {
        _getMinterFor(_token).mint(_recipient, _value);
    }

    /**
    * @dev Retrieves address of the home bridged token contract associated with a specific foreign token contract.
    * @param _foreignToken address of the created home token contract.
    * @return address of the home token contract.
    */
    function homeTokenAddress(address _foreignToken) public view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("homeTokenAddress", _foreignToken))];
    }

    /**
    * @dev Retrieves address of the foreign bridged token contract associated with a specific home token contract.
    * @param _homeToken address of the created home token contract.
    * @return address of the foreign token contract.
    */
    function foreignTokenAddress(address _homeToken) public view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("foreignTokenAddress", _homeToken))];
    }

    /**
    * @dev Internal function for updating an address of the token image contract.
    * @param _foreignToken address of bridged foreign token contract.
    * @param _foreignToken address of created home token contract.
    */
    function _setTokenAddressPair(address _foreignToken, address _homeToken) internal {
        addressStorage[keccak256(abi.encodePacked("homeTokenAddress", _foreignToken))] = _homeToken;
        addressStorage[keccak256(abi.encodePacked("foreignTokenAddress", _homeToken))] = _foreignToken;
    }

    /**
    * @dev Internal function for updating an address of the token image contract.
    * @param _tokenImage address of deployed PermittableToken contract.
    */
    function _setTokenImage(address _tokenImage) internal {
        require(AddressUtils.isContract(_tokenImage));
        addressStorage[TOKEN_IMAGE_CONTRACT] = _tokenImage;
    }

    /**
     * @dev Executes action on withdrawal of bridged tokens
     * @param _token address of token contract
     * @param _from address of tokens sender
     * @param _receiver address of tokens receiver on the other side
     * @param _value requested amount of bridged tokens
     */
    function bridgeSpecificActionsOnTokenTransfer(ERC677 _token, address _from, address _receiver, uint256 _value)
        internal
    {
        uint256 valueToBridge = _value;
        uint256 fee = 0;
        // Next line disables fee collection in case sender is one of the reward addresses.
        // It is needed to allow a 100% withdrawal of tokens from the home side.
        // If fees are not disabled for reward receivers, small fraction of tokens will always
        // be redistributed between the same set of reward addresses, which is not the desired behaviour.
        if (!isRewardAddress(_from)) {
            fee = _distributeFee(HOME_TO_FOREIGN_FEE, _token, valueToBridge);
            valueToBridge = valueToBridge.sub(fee);
        }
        IBurnableMintableERC677Token(_token).burn(valueToBridge);
        bytes32 _messageId = passMessage(_token, _from, _receiver, valueToBridge);
        if (fee > 0) {
            emit FeeDistributed(fee, _token, _messageId);
        }
    }

    /**
    * @dev Call AMB bridge to require the invocation of handleBridgedTokens method of the mediator on the other network.
    * Store information related to the bridged tokens in case the message execution fails on the other network
    * and the action needs to be fixed/rolled back.
    * @param _token bridged ERC20 token
    * @param _from address of sender, if bridge operation fails, tokens will be returned to this address
    * @param _receiver address of receiver on the other side, will eventually receive bridged tokens
    * @param _value bridged amount of tokens
    * @return id of the created and passed message
    */
    function passMessage(ERC677 _token, address _from, address _receiver, uint256 _value) internal returns (bytes32) {
        bytes4 methodSelector = this.handleBridgedTokens.selector;
        address foreignToken = foreignTokenAddress(_token);
        bytes memory data = abi.encodeWithSelector(methodSelector, foreignToken, _receiver, _value);

        address executor = mediatorContractOnOtherSide();
        uint256 gasLimit = requestGasLimit();
        IAMB bridge = bridgeContract();

        // Address of the foreign token is used here for determining lane permissions.
        // Such decision makes it possible to set rules for tokens that are not bridged yet.
        bytes32 _messageId = destinationLane(foreignToken, _from, _receiver) >= 0
            ? bridge.requireToPassMessage(executor, data, gasLimit)
            : bridge.requireToConfirmMessage(executor, data, gasLimit);

        setMessageToken(_messageId, _token);
        setMessageValue(_messageId, _value);
        setMessageRecipient(_messageId, _from);

        emit TokensBridgingInitiated(_token, _from, _value, _messageId);

        return _messageId;
    }

    /**
     * @dev Internal function for getting minter proxy address.
     * Returns the token address itself, expect for the case with bridged STAKE token.
     * For bridged STAKE token, returns the hardcoded TokenMinter contract address.
     * @param _token address of the token to mint.
     * @return address of the minter contract that should be used for calling mint(address,uint256)
     */
    function _getMinterFor(address _token) internal view returns (IBurnableMintableERC677Token) {
        return IBurnableMintableERC677Token(_token);
    }

    /**
     * @dev Withdraws erc20 tokens or native coins from the bridged token contract.
     * Only the proxy owner is allowed to call this method.
     * @param _bridgedToken address of the bridged token contract.
     * @param _token address of the claimed token or address(0) for native coins.
     * @param _to address of the tokens/coins receiver.
     */
    function claimTokensFromTokenContract(address _bridgedToken, address _token, address _to)
        external
        onlyIfUpgradeabilityOwner
    {
        IBurnableMintableERC677Token(_bridgedToken).claimTokens(_token, _to);
    }
}

// File: contracts/libraries/TokenReader.sol

pragma solidity 0.4.24;

/**
 * @title TokenReader
 * @dev Helper methods for reading name/symbol/decimals parameters from ERC20 token contracts.
 */
library TokenReader {
    /**
    * @dev Reads the name property of the provided token.
    * Either name() or NAME() method is used.
    * Both, string and bytes32 types are supported.
    * @param _token address of the token contract.
    * @return token name as a string or an empty string if none of the methods succeeded.
    */
    function readName(address _token) internal view returns (string) {
        uint256 ptr;
        uint256 size;
        assembly {
            ptr := mload(0x40)
            mstore(ptr, 0x06fdde0300000000000000000000000000000000000000000000000000000000) // name()
            if iszero(staticcall(gas, _token, ptr, 4, ptr, 32)) {
                mstore(ptr, 0xa3f4df7e00000000000000000000000000000000000000000000000000000000) // NAME()
                staticcall(gas, _token, ptr, 4, ptr, 32)
                pop
            }

            mstore(0x40, add(ptr, returndatasize))

            switch gt(returndatasize, 32)
                case 1 {
                    returndatacopy(mload(0x40), 32, 32) // string length
                    size := mload(mload(0x40))
                }
                default {
                    size := returndatasize // 32 or 0
                }
        }
        string memory res = new string(size);
        assembly {
            if gt(returndatasize, 32) {
                // load as string
                returndatacopy(add(res, 32), 64, size)
                jump(exit)
            }
            /* solhint-disable */
            if gt(returndatasize, 0) {
                let i := 0
                ptr := mload(ptr) // load bytes32 value
                mstore(add(res, 32), ptr) // save value in result string

                for { } gt(ptr, 0) { i := add(i, 1) } { // until string is empty
                    ptr := shl(8, ptr) // shift left by one symbol
                }
                mstore(res, i) // save result string length
            }
            exit:
            /* solhint-enable */
        }
        return res;
    }

    /**
    * @dev Reads the symbol property of the provided token.
    * Either symbol() or SYMBOL() method is used.
    * Both, string and bytes32 types are supported.
    * @param _token address of the token contract.
    * @return token symbol as a string or an empty string if none of the methods succeeded.
    */
    function readSymbol(address _token) internal view returns (string) {
        uint256 ptr;
        uint256 size;
        assembly {
            ptr := mload(0x40)
            mstore(ptr, 0x95d89b4100000000000000000000000000000000000000000000000000000000) // symbol()
            if iszero(staticcall(gas, _token, ptr, 4, ptr, 32)) {
                mstore(ptr, 0xf76f8d7800000000000000000000000000000000000000000000000000000000) // SYMBOL()
                staticcall(gas, _token, ptr, 4, ptr, 32)
                pop
            }

            mstore(0x40, add(ptr, returndatasize))

            switch gt(returndatasize, 32)
                case 1 {
                    returndatacopy(mload(0x40), 32, 32) // string length
                    size := mload(mload(0x40))
                }
                default {
                    size := returndatasize // 32 or 0
                }
        }
        string memory res = new string(size);
        assembly {
            if gt(returndatasize, 32) {
                // load as string
                returndatacopy(add(res, 32), 64, size)
                jump(exit)
            }
            /* solhint-disable */
            if gt(returndatasize, 0) {
                let i := 0
                ptr := mload(ptr) // load bytes32 value
                mstore(add(res, 32), ptr) // save value in result string

                for { } gt(ptr, 0) { i := add(i, 1) } { // until string is empty
                    ptr := shl(8, ptr) // shift left by one symbol
                }
                mstore(res, i) // save result string length
            }
            exit:
            /* solhint-enable */
        }
        return res;
    }

    /**
    * @dev Reads the decimals property of the provided token.
    * Either decimals() or DECIMALS() method is used.
    * @param _token address of the token contract.
    * @return token decimals or 0 if none of the methods succeeded.
    */
    function readDecimals(address _token) internal view returns (uint256) {
        uint256 decimals;
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 32))
            mstore(ptr, 0x313ce56700000000000000000000000000000000000000000000000000000000) // decimals()
            if iszero(staticcall(gas, _token, ptr, 4, ptr, 32)) {
                mstore(ptr, 0x2e0f262500000000000000000000000000000000000000000000000000000000) // DECIMALS()
                if iszero(staticcall(gas, _token, ptr, 4, ptr, 32)) {
                    mstore(ptr, 0)
                }
            }
            decimals := mload(ptr)
        }
        return decimals;
    }
}

// File: contracts/upgradeable_contracts/multi_amb_erc20_to_erc677/ForeignMultiAMBErc20ToErc677.sol

pragma solidity 0.4.24;






/**
 * @title ForeignMultiAMBErc20ToErc677
 * @dev Foreign side implementation for multi-erc20-to-erc677 mediator intended to work on top of AMB bridge.
 * It is designed to be used as an implementation contract of EternalStorageProxy contract.
 */
contract ForeignMultiAMBErc20ToErc677 is BasicMultiAMBErc20ToErc677 {
    using SafeERC20 for address;
    using SafeERC20 for ERC677;

    /**
    * @dev Stores the initial parameters of the mediator.
    * @param _bridgeContract the address of the AMB bridge contract.
    * @param _mediatorContract the address of the mediator contract on the other network.
    * @param _dailyLimitMaxPerTxMinPerTxArray array with limit values for the assets to be bridged to the other network.
    *   [ 0 = dailyLimit, 1 = maxPerTx, 2 = minPerTx ]
    * @param _executionDailyLimitExecutionMaxPerTxArray array with limit values for the assets bridged from the other network.
    *   [ 0 = executionDailyLimit, 1 = executionMaxPerTx ]
    * @param _requestGasLimit the gas limit for the message execution.
    * @param _owner address of the owner of the mediator contract.
    */
    function initialize(
        address _bridgeContract,
        address _mediatorContract,
        uint256[3] _dailyLimitMaxPerTxMinPerTxArray, // [ 0 = _dailyLimit, 1 = _maxPerTx, 2 = _minPerTx ]
        uint256[2] _executionDailyLimitExecutionMaxPerTxArray, // [ 0 = _executionDailyLimit, 1 = _executionMaxPerTx ]
        uint256 _requestGasLimit,
        address _owner
    ) external onlyRelevantSender returns (bool) {
        require(!isInitialized());

        _setBridgeContract(_bridgeContract);
        _setMediatorContractOnOtherSide(_mediatorContract);
        _setLimits(address(0), _dailyLimitMaxPerTxMinPerTxArray);
        _setExecutionLimits(address(0), _executionDailyLimitExecutionMaxPerTxArray);
        _setRequestGasLimit(_requestGasLimit);
        _setOwner(_owner);

        setInitialize();

        return isInitialized();
    }

    /**
     * @dev Executes action on the request to withdraw tokens relayed from the other network
     * @param _token address of the token contract
     * @param _recipient address of tokens receiver
     * @param _value amount of bridged tokens
     */
    function executeActionOnBridgedTokens(address _token, address _recipient, uint256 _value) internal {
        bytes32 _messageId = messageId();
        _releaseTokens(_token, _recipient, _value);
        emit TokensBridged(_token, _recipient, _value, _messageId);
    }

    /**
    * @dev ERC677 transfer callback function.
    * @param _from address of tokens sender.
    * @param _value amount of transferred tokens.
    * @param _data additional transfer data, can be used for passing alternative receiver address.
    */
    function onTokenTransfer(address _from, uint256 _value, bytes _data) public returns (bool) {
        if (!lock()) {
            ERC677 token = ERC677(msg.sender);
            bridgeSpecificActionsOnTokenTransfer(token, _from, chooseReceiver(_from, _data), _value);
        }
        return true;
    }

    /**
    * @dev Handles the bridged tokens. Checks that the value is inside the execution limits and invokes the method
    * to execute the Mint or Unlock accordingly.
    * @param _token bridged ERC20 token.
    * @param _recipient address that will receive the tokens.
    * @param _value amount of tokens to be received.
    */
    function handleBridgedTokens(ERC677 _token, address _recipient, uint256 _value) external onlyMediator {
        require(isTokenRegistered(_token));
        _handleBridgedTokens(_token, _recipient, _value);
    }

    /**
    * @dev Validates that the token amount is inside the limits, calls transferFrom to transfer the tokens to the contract
    * and invokes the method to burn/lock the tokens and unlock/mint the tokens on the other network.
    * The user should first call Approve method of the ERC677 token.
    * @param token bridge token contract address.
    * @param _receiver address that will receive the native tokens on the other network.
    * @param _value amount of tokens to be transferred to the other network.
    */
    function _relayTokens(ERC677 token, address _receiver, uint256 _value) internal {
        // This lock is to prevent calling passMessage twice if a ERC677 token is used.
        // When transferFrom is called, after the transfer, the ERC677 token will call onTokenTransfer from this contract
        // which will call passMessage.
        require(!lock());

        uint256 balanceBefore = token.balanceOf(address(this));
        setLock(true);
        token.safeTransferFrom(msg.sender, _value);
        setLock(false);
        uint256 balanceDiff = token.balanceOf(address(this)).sub(balanceBefore);
        require(balanceDiff <= _value);
        bridgeSpecificActionsOnTokenTransfer(token, msg.sender, _receiver, balanceDiff);
    }

    /**
     * @dev Executes action on deposit of bridged tokens
     * @param _token address of the token contract
     * @param _from address of tokens sender
     * @param _receiver address of tokens receiver on the other side
     * @param _value requested amount of bridged tokens
     */
    function bridgeSpecificActionsOnTokenTransfer(ERC677 _token, address _from, address _receiver, uint256 _value)
        internal
    {
        bool isKnownToken = isTokenRegistered(_token);
        if (!isKnownToken) {
            string memory name = TokenReader.readName(_token);
            string memory symbol = TokenReader.readSymbol(_token);
            uint8 decimals = uint8(TokenReader.readDecimals(_token));

            require(bytes(name).length > 0 || bytes(symbol).length > 0);

            _initializeTokenBridgeLimits(_token, decimals);
        }

        require(withinLimit(_token, _value));
        addTotalSpentPerDay(_token, getCurrentDay(), _value);

        bytes memory data;

        if (isKnownToken) {
            data = abi.encodeWithSelector(this.handleBridgedTokens.selector, _token, _receiver, _value);
        } else {
            data = abi.encodeWithSelector(
                HomeMultiAMBErc20ToErc677(this).deployAndHandleBridgedTokens.selector,
                _token,
                name,
                symbol,
                decimals,
                _receiver,
                _value
            );
        }

        _setMediatorBalance(_token, mediatorBalance(_token).add(_value));

        bytes32 _messageId = bridgeContract().requireToPassMessage(
            mediatorContractOnOtherSide(),
            data,
            requestGasLimit()
        );

        setMessageToken(_messageId, _token);
        setMessageValue(_messageId, _value);
        setMessageRecipient(_messageId, _from);

        if (!isKnownToken) {
            _setTokenRegistrationMessageId(_token, _messageId);
        }

        emit TokensBridgingInitiated(_token, _from, _value, _messageId);
    }

    /**
    * @dev Handles the request to fix transferred assets which bridged message execution failed on the other network.
    * It uses the information stored by passMessage method when the assets were initially transferred
    * @param _messageId id of the message which execution failed on the other network.
    */
    function fixFailedMessage(bytes32 _messageId) public {
        super.fixFailedMessage(_messageId);
        address token = messageToken(_messageId);
        if (_messageId == tokenRegistrationMessageId(token)) {
            delete uintStorage[keccak256(abi.encodePacked("dailyLimit", token))];
            delete uintStorage[keccak256(abi.encodePacked("maxPerTx", token))];
            delete uintStorage[keccak256(abi.encodePacked("minPerTx", token))];
            delete uintStorage[keccak256(abi.encodePacked("executionDailyLimit", token))];
            delete uintStorage[keccak256(abi.encodePacked("executionMaxPerTx", token))];
            _setTokenRegistrationMessageId(token, bytes32(0));
        }
    }

    /**
    * @dev Unlock back the amount of tokens that were bridged to the other network but failed.
    * @param _token address that bridged token contract.
    * @param _recipient address that will receive the tokens.
    * @param _value amount of tokens to be received.
    */
    function executeActionOnFixedTokens(address _token, address _recipient, uint256 _value) internal {
        _releaseTokens(_token, _recipient, _value);
    }

    /**
    * @dev Allows to send to the other network the amount of locked tokens that can be forced into the contract
    * without the invocation of the required methods. (e. g. regular transfer without a call to onTokenTransfer)
    * @param _token address of the token contract.
    * @param _receiver the address that will receive the tokens on the other network.
    */
    function fixMediatorBalance(address _token, address _receiver)
        external
        onlyIfUpgradeabilityOwner
        validAddress(_receiver)
    {
        require(isTokenRegistered(_token));
        uint256 balance = ERC677(_token).balanceOf(address(this));
        uint256 expectedBalance = mediatorBalance(_token);
        require(balance > expectedBalance);
        uint256 diff = balance - expectedBalance;
        uint256 available = maxAvailablePerTx(_token);
        require(available > 0);
        if (diff > available) {
            diff = available;
        }
        addTotalSpentPerDay(_token, getCurrentDay(), diff);
        _setMediatorBalance(_token, expectedBalance.add(diff));

        bytes memory data = abi.encodeWithSelector(this.handleBridgedTokens.selector, _token, _receiver, diff);

        bytes32 _messageId = bridgeContract().requireToPassMessage(
            mediatorContractOnOtherSide(),
            data,
            requestGasLimit()
        );

        setMessageToken(_messageId, _token);
        setMessageValue(_messageId, diff);
        setMessageRecipient(_messageId, _receiver);
    }

    /**
    * @dev Tells the expected token balance of the contract.
    * @param _token address of token contract.
    * @return the current tracked token balance of the contract.
    */
    function mediatorBalance(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("mediatorBalance", _token))];
    }

    /**
    * @dev Returns message id where specified token was first seen and deploy on the other side was requested.
    * @param _token address of token contract.
    * @return message id of the send message.
    */
    function tokenRegistrationMessageId(address _token) public view returns (bytes32) {
        return bytes32(uintStorage[keccak256(abi.encodePacked("tokenRegistrationMessageId", _token))]);
    }

    /**
    * @dev Updates expected token balance of the contract.
    * @param _token address of token contract.
    * @param _balance the new token balance of the contract.
    */
    function _setMediatorBalance(address _token, uint256 _balance) internal {
        uintStorage[keccak256(abi.encodePacked("mediatorBalance", _token))] = _balance;
    }

    /**
    * @dev Updates message id where specified token was first seen and deploy on the other side was requested.
    * @param _token address of token contract.
    * @param _messageId message id of the send message.
    */
    function _setTokenRegistrationMessageId(address _token, bytes32 _messageId) internal {
        uintStorage[keccak256(abi.encodePacked("tokenRegistrationMessageId", _token))] = uint256(_messageId);
    }

    /**
     * Internal function for unlocking some amount of tokens.
     * In case of bridging STAKE token, the insufficient amount of tokens can be additionally minted.
     */
    function _releaseTokens(address _token, address _recipient, uint256 _value) internal {
        // It is necessary to use mediatorBalance(STAKE) instead of STAKE.balanceOf(this) to disallow user
        // withdraw mistakenly locked funds (via regular transfer()) instead of minting new tokens.
        // It should be possible to process mistakenly locked funds by calling fixMediatorBalance.
        uint256 balance = mediatorBalance(_token);

        _token.safeTransfer(_recipient, _value);
        _setMediatorBalance(_token, balance.sub(_value));
    }
}