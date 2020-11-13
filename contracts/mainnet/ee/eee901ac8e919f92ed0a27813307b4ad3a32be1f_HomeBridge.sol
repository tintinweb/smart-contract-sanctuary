pragma solidity ^0.4.24;

// File: contracts/IBridgeValidators.sol

interface IBridgeValidators {
    function isValidator(address _validator) public view returns(bool);
    function requiredSignatures() public view returns(uint256);
    function owner() public view returns(address);
}

// File: contracts/libraries/Message.sol

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
    // offset 116: 32 bytes :: uint256 - home gas price

    // bytes 1 to 32 are 0 because message length is stored as little endian.
    // mload always reads 32 bytes.
    // so we can and have to start reading recipient at offset 20 instead of 32.
    // if we were to read at 32 the address would contain part of value and be corrupted.
    // when reading from offset 20 mload will read 12 zero bytes followed
    // by the 20 recipient address bytes and correctly convert it into an address.
    // this saves some storage/gas over the alternative solution
    // which is padding address to 32 bytes and reading recipient at offset 32.
    // for more details see discussion in:
    // https://github.com/paritytech/parity-bridge/issues/61
    function parseMessage(bytes message)
    internal
    pure
    returns(address recipient, uint256 amount, bytes32 txHash)
    {
        require(isMessageValid(message));
        assembly {
            recipient := and(mload(add(message, 20)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            amount := mload(add(message, 52))
            txHash := mload(add(message, 84))
        }
    }

    function isMessageValid(bytes _msg) internal pure returns(bool) {
        return _msg.length == 116;
    }

    function recoverAddressFromSignedMessage(bytes signature, bytes message) internal pure returns (address) {
        require(signature.length == 65);
        bytes32 r;
        bytes32 s;
        bytes1 v;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := mload(add(signature, 0x60))
        }
        return ecrecover(hashMessage(message), uint8(v), r, s);
    }

    function hashMessage(bytes message) internal pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n";
        // message is always 116 length
        string memory msgLength = "116";
        return keccak256(prefix, msgLength, message);
    }

    function hasEnoughValidSignatures(
        bytes _message,
        uint8[] _vs,
        bytes32[] _rs,
        bytes32[] _ss,
        IBridgeValidators _validatorContract) internal view {
        require(isMessageValid(_message));
        uint256 requiredSignatures = _validatorContract.requiredSignatures();
        require(_vs.length >= requiredSignatures);
        bytes32 hash = hashMessage(_message);
        address[] memory encounteredAddresses = new address[](requiredSignatures);

        for (uint256 i = 0; i < requiredSignatures; i++) {
            address recoveredAddress = ecrecover(hash, _vs[i], _rs[i], _ss[i]);
            require(_validatorContract.isValidator(recoveredAddress));
            if (addressArrayContains(encounteredAddresses, recoveredAddress)) {
                revert();
            }
            encounteredAddresses[i] = recoveredAddress;
        }
    }
}

// File: contracts/libraries/SafeMath.sol

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

// File: contracts/upgradeability/EternalStorage.sol

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

// File: contracts/IOwnedUpgradeabilityProxy.sol

interface IOwnedUpgradeabilityProxy {
    function proxyOwner() public view returns (address);
}

// File: contracts/upgradeable_contracts/OwnedUpgradeability.sol

contract OwnedUpgradeability {

    function upgradeabilityAdmin() public view returns (address) {
        return IOwnedUpgradeabilityProxy(this).proxyOwner();
    }

    // Avoid using onlyProxyOwner name to prevent issues with implementation from proxy contract
    modifier onlyIfOwnerOfProxy() {
        require(msg.sender == upgradeabilityAdmin());
        _;
    }
}

// File: contracts/upgradeable_contracts/Ownable.sol

/**
 * @title Ownable
 * @dev This contract has an owner address providing basic authorization control
 */
contract Ownable is EternalStorage {
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
        _;
    }

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function owner() public view returns (address) {
        return addressStorage[keccak256("owner")];
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner the address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        setOwner(newOwner);
    }

    /**
    * @dev Sets a new owner address
    */
    function setOwner(address newOwner) internal {
        emit OwnershipTransferred(owner(), newOwner);
        addressStorage[keccak256("owner")] = newOwner;
    }
}

// File: contracts/upgradeable_contracts/Validatable.sol

contract Validatable is EternalStorage {

    function validatorContract() public view returns(IBridgeValidators) {
        return IBridgeValidators(addressStorage[keccak256("validatorContract")]);
    }

    modifier onlyValidator() {
        require(validatorContract().isValidator(msg.sender));
        _;
    }
}

// File: contracts/upgradeable_contracts/U_BasicBridge.sol

contract BasicBridge is EternalStorage, Validatable, Ownable {
    event GasPriceChanged(uint256 gasPrice);
    event RequiredBlockConfirmationChanged(uint256 requiredBlockConfirmations);

    function setGasPrice(uint256 _gasPrice) public onlyOwner {
        require(_gasPrice > 0);
        uintStorage[keccak256("gasPrice")] = _gasPrice;
        emit GasPriceChanged(_gasPrice);
    }

    function gasPrice() public view returns(uint256) {
        return uintStorage[keccak256("gasPrice")];
    }

    function setRequiredBlockConfirmations(uint256 _blockConfirmations) public onlyOwner {
        require(_blockConfirmations > 0);
        uintStorage[keccak256("requiredBlockConfirmations")] = _blockConfirmations;
        emit RequiredBlockConfirmationChanged(_blockConfirmations);
    }

    function requiredBlockConfirmations() public view returns(uint256) {
        return uintStorage[keccak256("requiredBlockConfirmations")];
    }
}

// File: contracts/upgradeable_contracts/U_HomeBridge.sol

contract Sacrifice {
    constructor(address _recipient) public payable {
        selfdestruct(_recipient);
    }
}

contract HomeBridge is EternalStorage, BasicBridge, OwnedUpgradeability {
    using SafeMath for uint256;
    event GasConsumptionLimitsUpdated(uint256 gas);
    event Deposit (address recipient, uint256 value);
    event Withdraw (address recipient, uint256 value, bytes32 transactionHash);
    event DailyLimit(uint256 newLimit);
    event ForeignDailyLimit(uint256 newLimit);

    function initialize (
        address _validatorContract,
        uint256 _homeDailyLimit,
        uint256 _maxPerTx,
        uint256 _minPerTx,
        uint256 _homeGasPrice,
        uint256 _requiredBlockConfirmations
    ) public
    returns(bool)
    {
        require(!isInitialized());
        require(_validatorContract != address(0));
        require(_homeGasPrice > 0);
        require(_requiredBlockConfirmations > 0);
        require(_minPerTx > 0 && _maxPerTx > _minPerTx && _homeDailyLimit > _maxPerTx);
        addressStorage[keccak256("validatorContract")] = _validatorContract;
        uintStorage[keccak256("deployedAtBlock")] = block.number;
        uintStorage[keccak256("homeDailyLimit")] = _homeDailyLimit;
        uintStorage[keccak256("maxPerTx")] = _maxPerTx;
        uintStorage[keccak256("minPerTx")] = _minPerTx;
        uintStorage[keccak256("gasPrice")] = _homeGasPrice;
        uintStorage[keccak256("requiredBlockConfirmations")] = _requiredBlockConfirmations;
        setInitialize(true);
        return isInitialized();
    }

    function () public payable {
        require(msg.value > 0);
        require(msg.data.length == 0);
        require(withinLimit(msg.value));
        setTotalSpentPerDay(getCurrentDay(), totalSpentPerDay(getCurrentDay()).add(msg.value));
        emit Deposit(msg.sender, msg.value);
    }

    function upgradeFrom3To4() public {
        require(owner() == address(0));
        setOwner(validatorContract().owner());
    }

    function gasLimitWithdrawRelay() public view returns(uint256) {
        return uintStorage[keccak256("gasLimitWithdrawRelay")];
    }

    function deployedAtBlock() public view returns(uint256) {
        return uintStorage[keccak256("deployedAtBlock")];
    }

    function homeDailyLimit() public view returns(uint256) {
        return uintStorage[keccak256("homeDailyLimit")];
    }

    function foreignDailyLimit() public view returns(uint256) {
        return uintStorage[keccak256("foreignDailyLimit")];
    }

    function totalSpentPerDay(uint256 _day) public view returns(uint256) {
        return uintStorage[keccak256("totalSpentPerDay", _day)];
    }

    function totalExecutedPerDay(uint256 _day) public view returns(uint256) {
        return uintStorage[keccak256("totalExecutedPerDay", _day)];
    }

    function withdraws(bytes32 _withdraw) public view returns(bool) {
        return boolStorage[keccak256("withdraws", _withdraw)];
    }

    function setGasLimitWithdrawRelay(uint256 _gas) external onlyOwner {
        uintStorage[keccak256("gasLimitWithdrawRelay")] = _gas;
        emit GasConsumptionLimitsUpdated(_gas);
    }

    function withdraw(uint8[] vs, bytes32[] rs, bytes32[] ss, bytes message) external {
        Message.hasEnoughValidSignatures(message, vs, rs, ss, validatorContract());
        address recipient;
        uint256 amount;
        bytes32 txHash;
        (recipient, amount, txHash) = Message.parseMessage(message);
        require(withinForeignLimit(amount));
        setTotalExecutedPerDay(getCurrentDay(), totalExecutedPerDay(getCurrentDay()).add(amount));
        require(!withdraws(txHash));
        setWithdraws(txHash, true);

        // pay out recipient
        if (!recipient.send(amount)) {
            (new Sacrifice).value(amount)(recipient);
        }

        emit Withdraw(recipient, amount, txHash);
    }

    function setHomeDailyLimit(uint256 _homeDailyLimit) external onlyOwner {
        uintStorage[keccak256("homeDailyLimit")] = _homeDailyLimit;
        emit DailyLimit(_homeDailyLimit);
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        require(_maxPerTx < homeDailyLimit());
        uintStorage[keccak256("maxPerTx")] = _maxPerTx;
    }

    function setForeignDailyLimit(uint256 _foreignDailyLimit) external onlyOwner {
        uintStorage[keccak256("foreignDailyLimit")] = _foreignDailyLimit;
        emit ForeignDailyLimit(_foreignDailyLimit);
    }

    function setForeignMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        require(_maxPerTx < foreignDailyLimit());
        uintStorage[keccak256("foreignMaxPerTx")] = _maxPerTx;
    }

    function setMinPerTx(uint256 _minPerTx) external onlyOwner {
        require(_minPerTx < homeDailyLimit() && _minPerTx < maxPerTx());
        uintStorage[keccak256("minPerTx")] = _minPerTx;
    }

    function minPerTx() public view returns(uint256) {
        return uintStorage[keccak256("minPerTx")];
    }

    function getCurrentDay() public view returns(uint256) {
        return now / 1 days;
    }

    function maxPerTx() public view returns(uint256) {
        return uintStorage[keccak256("maxPerTx")];
    }

    function foreignMaxPerTx() public view returns(uint256) {
        return uintStorage[keccak256("foreignMaxPerTx")];
    }

    function withinLimit(uint256 _amount) public view returns(bool) {
        uint256 nextLimit = totalSpentPerDay(getCurrentDay()).add(_amount);
        return homeDailyLimit() >= nextLimit && _amount <= maxPerTx() && _amount >= minPerTx();
    }

    function withinForeignLimit(uint256 _amount) public view returns(bool) {
        uint256 nextLimit = totalExecutedPerDay(getCurrentDay()).add(_amount);
        return foreignDailyLimit() >= nextLimit && _amount <= foreignMaxPerTx();
    }

    function isInitialized() public view returns(bool) {
        return boolStorage[keccak256("isInitialized")];
    }

    function setTotalSpentPerDay(uint256 _day, uint256 _value) private {
        uintStorage[keccak256("totalSpentPerDay", _day)] = _value;
    }

    function setTotalExecutedPerDay(uint256 _day, uint256 _value) private {
        uintStorage[keccak256("totalExecutedPerDay", _day)] = _value;
    }

    function setWithdraws(bytes32 _withdraw, bool _status) private {
        boolStorage[keccak256("withdraws", _withdraw)] = _status;
    }

    function setInitialize(bool _status) private {
        boolStorage[keccak256("isInitialized")] = _status;
    }
}