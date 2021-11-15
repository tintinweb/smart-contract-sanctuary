// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interface/IRouter.sol";
import "./interface/IFeeder.sol";

contract Feeder is OwnableUpgradeable, IFeeder {
    // TODO:
    // methods
    // add security deposite
    // deactivate admin and remove security deposite

    IRouter public router;
    string public feedDescription;
    bool public penaltyAllowed; // is security deposite required
    uint256 public securityDeposite; // security deposite

    modifier onlyRouter() {
        require(address(router) == msg.sender, "Feed: only owner");
        _;
    }

    modifier isSecured() {
        if (penaltyAllowed) {
            require(
                penaltyAllowed && router.getFeedSecurity() <= securityDeposite,
                "Feed: security violation!"
            );
        }
        _;
    }

    /**
     * @dev init function
     */

    function initialize(
        address _router,
        address _owner,
        string calldata _feedDescription,
        bool _penaltyAllowed
    ) external override initializer {
        __Ownable_init();
        transferOwnership(_owner);
        router = IRouter(_router);
        penaltyAllowed = _penaltyAllowed;
        feedDescription = _feedDescription;
    }

    function createCondition(
        uint256[] calldata lpRegs,
        uint256 oracleConditionID,
        uint256 coreType,
        uint256[] calldata rates,
        uint256 timestamp,
        string memory ipfsHash
    ) external override onlyOwner isSecured {
        router.createCondition(
            lpRegs,
            oracleConditionID,
            coreType,
            rates,
            timestamp,
            ipfsHash
        );
    }

    /**
     * @dev resolveCondition not used modifier isSecured() to allow resolve condition in any case
     */

    function resolveCondition(
        uint256[] calldata lpRegs,
        uint256 conditionID,
        uint128 outcomeWin
    ) external override onlyOwner {
        router.resolveCondition(lpRegs, conditionID, outcomeWin);
    }
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IRouter {
    function registerLP(
        address paymentToken,
        uint256 period,
        uint256[] calldata _coreTypes,
        uint256 reinforcement,
        uint256 marginality,
        address LPOwner,
        bool isActive
    ) external;

    function changeLPPeriod(uint256 lpID, uint256 newPeriod) external;

    function registerFeed(
        address feedOwner,
        string calldata feedDescription,
        uint256[] calldata feedCoreTypes,
        bool isActive,
        bool penaltyAllowed
    ) external;

    function addLiquidity(uint256 lpID, uint256 _amount) external;

    function withdrawLiquidity(uint256 lpID, uint256 valueLP) external;

    function liquidityRequest(uint256 lpID, uint256 valueLP) external;

    function createCondition(
        uint256[] calldata lpRegs,
        uint256 oracleConditionID,
        uint256 coreType,
        uint256[] calldata rates,
        uint256 timestamp,
        string memory ipfsHash
    ) external;

    function resolveCondition(
        uint256[] calldata lpRegs,
        uint256 conditionID,
        uint128 outcomeWin
    ) external;

    function bet(
        uint256 lpID,
        uint256 conditionID,
        uint256 amount,
        uint256 outcomeID,
        uint256 deadline,
        uint256 minRate,
        bool mintNFT
    ) external;

    function withdrawPrize(uint256 lpID, uint256 tokenId) external;

    function claimAzuroBetToken(uint256 tokenId) external;

    function addCoreType(address core) external;

    function setLPCoreType(
        uint256 lpID,
        uint256 coreType,
        bool isActive
    ) external;

    function getAzuroToken() external returns (address);

    function getLPRegistry(uint256 lpID)
        external
        view
        returns (
            address pool,
            address paymentToken,
            uint256 period,
            bool isActive
        );

    function getLPpaymentToken(address lp)
        external
        view
        returns (address paymentToken);

    function getLPperiod(address lp) external view returns (uint256 period);

    function getLPowner(address lp) external view returns (address owner);

    function getLPIDowner(uint256 lpID) external view returns (address owner);

    function getCorebyType(uint256 typeId) external view returns (address core);

    function getCoreTypebyCore(address core)
        external
        view
        returns (uint256 typeId);

    function getLiquidityRequests(uint256 lpID, address wallet)
        external
        view
        returns (uint256 total, uint256 personal);

    function getLPReserve(uint256 lpID) external view returns (uint256 reserve);

    function getLPSupply(uint256 lpID)
        external
        view
        returns (uint256 totalSupply);

    function getLPcount() external view returns (uint256 LPcount);

    function getFeedSecurity() external view returns (uint256 FEEDSecurity);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IFeeder {
    function initialize(
        address _router,
        address _owner,
        string calldata _feedDescription,
        bool _penaltyAllowed
    ) external;

    function createCondition(
        uint256[] calldata lpRegs,
        uint256 oracleConditionID,
        uint256 coreType,
        uint256[] calldata rates,
        uint256 timestamp,
        string memory ipfsHash
    ) external;

    function resolveCondition(
        uint256[] calldata lpRegs,
        uint256 conditionID,
        uint128 outcomeWin
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
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
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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

