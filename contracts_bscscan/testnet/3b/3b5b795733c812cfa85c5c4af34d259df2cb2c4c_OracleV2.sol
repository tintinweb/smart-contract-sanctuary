// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "../../utils/SafeMath.sol";
import "../interface/IOracleV2.sol";
import "../interface/IClientV2.sol";
import "../../v1/server/Oracle.sol";

contract OracleV2 is IOracleV2, Oracle { 
    using SafeMath for uint256;

    event RequestBurnableTree(address requester, uint256 requestId, address treeOwner, uint256 provideGas);

    function requestBurnableTree(uint256 requestId, address treeOwner) onlyOpen requireGas payable override external {
        require(requestId > 0, "Oracle: Invalid request is zero");
        require(treeOwner != address(0), "Oracle: tree owner address cannot be zero");
        require(!isRequestPending(msg.sender, requestId), "Oracle: Get duplicated processing request"); 

        address requester = msg.sender;
        uint256 providedGas = msg.value;

        requesterAndIdToProvidedGas[requester][requestId] = providedGas;

        emit RequestBurnableTree(requester, requestId, treeOwner, providedGas);
    }

    // =============== Prophet method ================

    // This method is going to be used by only trust prophet
    // After they done their job that the provided gas can be transfered to conpensate their advances usage
    function provideBurnableTree(address requester, uint256 requestId, uint256 availbleTree) external onlyProphet {
        require(isRequestPending(requester, requestId), "Oracle: Transaction was refunded or responded"); 
        
        uint256 providedGas = requesterAndIdToProvidedGas[requester][requestId];
        delete requesterAndIdToProvidedGas[requester][requestId];  

        IClientV2(requester).onBurnableTreeReceived(requestId, availbleTree);
        payable(msg.sender).transfer(providedGas);

        emit ProphetResponse(requester, requestId);  
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 result) {
        result = a + b;
        require(result >= a, "overflow is prevented");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 result) {
        require(a >= b, "overflow is prevented");
        result = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 result) {
        result = a * b;

        if (b > 0) {
            require((result / b) == a, "overflow is prevented");
        }
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 result) {
        require(b > 0, "divide by zero error");
        result = a / b;
    }

    // Sample data: precision = 1E6
    function div(uint256 a, uint256 b, uint256 precision) internal pure returns (uint256 result, uint256 returnPrecision) {
        require(b > 0, "divide by zero error");
        returnPrecision = precision;
        result = (a * precision) / b;

        require(a <= (a * precision), "overflow is prevented");
        require((result * b) <= (a * precision), "overflow is prevented");
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256 result) {
        require(b > 0, "divide by zero error");
        result = a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../../v1/interface/IOracle.sol";

interface IOracleV2 is IOracle {
    function requestBurnableTree(uint256 requestId, address treeOwner) payable external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "../../v1/interface/IClient.sol";

interface IClientV2 is IClient {
    function onBurnableTreeReceived(uint256 requestId, uint256 availbleTree) external returns (bool isCompleted);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/IOracle.sol";
import "../interface/IClient.sol";
import "../../utils/Prophetable.sol";
import "../../utils/SafeMath.sol";


contract Oracle is IOracle, Prophetable {
    using SafeMath for uint256;

    event MinimumGasChanged(uint256 newMinimumGas);
    event ServiceStatusChanged(bool isOpen);
    event PartnerChanged(address address_, bool isPartner);

    event ProphetResponse(address requester, uint256 requestId);
    event ErrorOnProphetResponse(address requester, uint256 requestId);
    event Refund(address requester, uint256 requestId);
    event InsufficientProvidedGas(address requster, uint256 requestId, uint256 requiredGas);

    event RequestRandomNumber(address requester, uint256 requestId, uint256 minNumber, uint256 maxNumber, uint256 requiredNumber, uint256 provideGas);
    event RequestRandomSeedmon(address requester, uint256 requestId, uint256 packId, uint256 minNumber, uint256 maxNumber, uint256 provideGas);

    uint256 public minimumGas;
    bool public isOpen;

    mapping(address => mapping(uint256 => uint256)) public requesterAndIdToProvidedGas;
    mapping(address => mapping(uint256 => uint256)) public requesterAndIdToBlockNumber;

    modifier onlyOpen() {
        require(isOpen, "Oracle: Service is under maintenance");
        _;
    }

    modifier requireGas() {
        require(msg.value >= minimumGas, "Oracle: Minimum gas must be provided");
        _;
    }

    function initialize(uint256 minimumGas_, bool isOpen_) external initializer {
        __Prophetable_init();
        
        setMinimumGas(minimumGas_);
        setIsOpen(isOpen_);
    }

    function getTotalBalance() public view returns (uint256 totalProvidedGas) {
        return address(this).balance;
    }

    function isRequestPending(address requester, uint256 requestId) public view override returns (bool result) {
        result = requesterAndIdToProvidedGas[requester][requestId] > 0;
    }

    // In case the prophet cannot provide job in your time limit 
    // then you can request for the refund by yourself
    function refund(uint256 requestId) external override {
        require(isRequestPending(msg.sender, requestId), "Oracle: Transaction was refunded or responded"); 
        
        uint256 providedGas = requesterAndIdToProvidedGas[msg.sender][requestId];
        delete requesterAndIdToProvidedGas[msg.sender][requestId];  

        IClient(msg.sender).onRefund{value: providedGas}(requestId);

        emit Refund(msg.sender, requestId);
    }

    function requestRandomNumber(uint256 requestId, uint256 minNumber, uint256 maxNumber, uint256 requiredNumber) onlyOpen requireGas payable override external {
        require(requestId > 0, "Oracle: Invalid request is zero");
        require(maxNumber > minNumber, "Oracle: Max number must exceed min number");
        require(requiredNumber <= 6, "Oracle: 6 is max required number");
        require(!isRequestPending(msg.sender, requestId), "Oracle: Get duplicated processing request"); 

        address requester = msg.sender;
        uint256 providedGas = msg.value;

        requesterAndIdToProvidedGas[requester][requestId] = providedGas;

        emit RequestRandomNumber(requester, requestId, minNumber, maxNumber, requiredNumber, providedGas);
    }

    function requestRandomSeedmon(uint256 requestId, uint256 packId, uint256 minBonusStat, uint256 maxBonusStat) onlyOpen requireGas payable override external {
        require(requestId > 0, "Oracle: Invalid request is zero");
        require(maxBonusStat >= minBonusStat, "Oracle: Max number must exceed min number");
        require(!isRequestPending(msg.sender, requestId), "Oracle: Get duplicated processing request"); 

        address requester = msg.sender;
        uint256 providedGas = msg.value;

        requesterAndIdToProvidedGas[requester][requestId] = providedGas;

        emit RequestRandomSeedmon(requester, requestId, packId, minBonusStat, maxBonusStat, providedGas);
    }

    // =============== Prophet method ================

    // This is method is going to be used in case the provided gas is insufficient
    // certianly we pay gas to process so the provided gas is not going to be refunded
    function alertInsufficientGas(address requester, uint256 requestId, uint256 requiredGas) external onlyProphet {
        require(isRequestPending(requester, requestId), "Oracle: Transaction was refunded or responded"); 
        delete requesterAndIdToProvidedGas[requester][requestId];  

        uint256 providedGas = requesterAndIdToProvidedGas[requester][requestId];
        payable(msg.sender).transfer(providedGas);

        emit InsufficientProvidedGas(requester, requestId, requiredGas);
    }

    // This method is going to be used by only trust prophet
    // After they done their job that the provided gas can be transfered to conpensate their advances usage
    function provideRandomNumber(address requester, uint256 requestId, uint256[] calldata randomNumbers) external onlyProphet {
        require(isRequestPending(requester, requestId), "Oracle: Transaction was refunded or responded"); 
        
        uint256 providedGas = requesterAndIdToProvidedGas[requester][requestId];
        delete requesterAndIdToProvidedGas[requester][requestId];  

        try IClient(requester).onRandomNumberReceived(requestId, randomNumbers) {
        } catch {
            emit ErrorOnProphetResponse(requester, requestId);
        }

        payable(msg.sender).transfer(providedGas);

        emit ProphetResponse(requester, requestId);  
    }

    // This method is going to be used by only trust prophet
    // After they done their job that the provided gas can be transfered to conpensate their advances usage
    function provideRandomSeedmon(address requester, uint256 requestId, bytes32 seedmonName,  uint256[] memory bonusStats) external onlyProphet {
        require(isRequestPending(requester, requestId), "Oracle: Transaction was refunded or responded"); 
        
        uint256 providedGas = requesterAndIdToProvidedGas[requester][requestId];
        delete requesterAndIdToProvidedGas[requester][requestId];  

        IClient(requester).onRandomSeedmonReceived(requestId, seedmonName, bonusStats);
        payable(msg.sender).transfer(providedGas);

        emit ProphetResponse(requester, requestId);  
    }

    // =============== Owner method =================

    // This method is to set lower of minimum gas to ensure the prophercy can be provided
    // since the average gas price is changed on daily basis
    function setMinimumGas(uint256 minimumGas_) public onlyOwner {
        minimumGas = minimumGas_;

        emit MinimumGasChanged(minimumGas);
    }

    // This method is to ensure why the service is under maintenance the user is not get much impact
    function setIsOpen(bool isOpen_) public onlyOwner {
        isOpen = isOpen_;

        emit ServiceStatusChanged(isOpen);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IOracle {
    function refund(uint256 requestId) external;
    function isRequestPending(address requester, uint256 requestId) external returns (bool result);

    function requestRandomNumber(uint256 requestId, uint256 minNumber, uint256 maxNumber, uint256 requiredNumber) payable external;
    function requestRandomSeedmon(uint256 requestId, uint256 packId, uint256 minBonusStat, uint256 maxBonusStat) payable external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IClient {
    function onRandomNumberReceived(uint256 requestId, uint256[] memory randomNumbers) external returns (bool isCompleted);
    function onRandomSeedmonReceived(uint256 requestId, bytes32 seedmonName,  uint256[] memory bonusStats) external returns (bool isCompleted);
    function onRefund(uint256 requestId) payable external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


abstract contract Prophetable is OwnableUpgradeable {
    event ProphetSet(address account, bool isProphet);

    mapping(address => bool) public prophets;

    function __Prophetable_init() internal initializer {
        __Ownable_init();
    }

    function isProphet(address account) external view returns (bool) {
        return prophets[account];
    }

    function setProphet(address account, bool isProphet_) external onlyOwner {
        prophets[account] = isProphet_;

        emit ProphetSet(account, isProphet_);
    }

    modifier onlyProphet() {
        require(prophets[msg.sender], "Prophet: Caller is not prophet");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

