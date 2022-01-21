// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../claimtoken/IGovClaimToken.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IGovWorldAdminRegistry {
    function isSuperAdminAccess(address admin) external view returns (bool);
}

contract GovClaimToken is OwnableUpgradeable, IGovClaimToken {

    function initialize() external initializer {
        __Ownable_init();
    }

    IGovWorldAdminRegistry govAdminRegistry;

    mapping(address => bool) public approvedClaimTokens;

    mapping(address => ClaimTokenData) claimTokens;
    //sun token mapping to the claimToken
    mapping(address => address) claimTokenofSUN;

    function configureAdminRegistry(address _adminRegistry) public onlyOwner {
        require(_adminRegistry != address(0), "GovClaimToken: null address");
        govAdminRegistry = IGovWorldAdminRegistry(_adminRegistry);
    }

    //modifier: only super admin wallet can add claim tokens
    modifier onlySuperAdmin(address _superAdminWallet) {
        require(
            govAdminRegistry.isSuperAdminAccess(_superAdminWallet),
            "GovClaimToken: only super admin wallet allowed"
        );
        _;
    }

    /** external functions of the Gov Protocol Contract */
    /**
    @dev function to add token to approvedTokens mapping
    *@param _claimTokenAddress of the new claim token Address
    *@param _claimtokendata struct of the _claimTokenAddress
    */
    function addClaimToken(
        address _claimTokenAddress,
        ClaimTokenData memory _claimtokendata
    )
        external
        onlySuperAdmin(msg.sender) /** only super admin wallet can add sun tokens */
    {
        require(_claimTokenAddress != address(0), "GCL: null address error");
        require(
            _claimtokendata.sunTokens.length ==
                _claimtokendata.sunTokenPricePercentage.length,
            "GCL: length mismatch"
        );
        require(
            !approvedClaimTokens[_claimTokenAddress],
            "GCL: already approved"
        );
        approvedClaimTokens[_claimTokenAddress] = true;
        claimTokens[_claimTokenAddress] = _claimtokendata;
        for (uint256 i = 0; i < _claimtokendata.sunTokens.length; i++) {
            claimTokenofSUN[_claimtokendata.sunTokens[i]] = _claimTokenAddress;
        }
    }

    /**
     @dev function to update the token market data
     *@param _claimTokenAddress to check if it exit in the array and mapping
     *@param _newClaimtokendata struct to update the token market
     */
    function updateClaimToken(
        address _claimTokenAddress,
        ClaimTokenData memory _newClaimtokendata
    )
        external
        onlySuperAdmin(msg.sender) /** only super admin wallet can add sun tokens */
    {
        ClaimTokenData memory prevClaimTokenData = claimTokens[
            _claimTokenAddress
        ];

        require(
            prevClaimTokenData.sunTokens.length ==
                _newClaimtokendata.sunTokens.length &&
                prevClaimTokenData.sunTokenPricePercentage.length ==
                _newClaimtokendata.sunTokenPricePercentage.length,
            "GCL: length mismatch"
        );
        require(
            approvedClaimTokens[_claimTokenAddress],
            "GCL: claim token not approved"
        );

        claimTokens[_claimTokenAddress] = _newClaimtokendata;
    }

    /**
     *@dev function to make claim token false
     *@param _removeClaimTokenAddress the key to remove
     */
    function removeClaimToken(address _removeClaimTokenAddress)
        external
        onlySuperAdmin(msg.sender) /** only super admin wallet can add sun tokens */
    {
        require(
            approvedClaimTokens[_removeClaimTokenAddress],
            "GCL: claim token not approved"
        );
        approvedClaimTokens[_removeClaimTokenAddress] = false;
    }

    function isClaimToken(address _claimTokenAddress)
        external
        view
        override
        returns (bool)
    {
        return approvedClaimTokens[_claimTokenAddress];
    }

    function getClaimTokenofSUNToken(address _sunToken)
        external
        view
        override
        returns (address)
    {
        return claimTokenofSUN[_sunToken];
    }

    function getClaimTokensData(address _claimTokenAddress)
        external
        view
        override
        returns (ClaimTokenData memory)
    {
        return claimTokens[_claimTokenAddress];
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct ClaimTokenData {
    address[] sunTokens;
    uint256[] sunTokenPricePercentage;
    address dexRouter; //this address will get the price from the AMM DEX (uniswap, sushiswap etc...)
}

interface IGovClaimToken {
    function isClaimToken(address _claimTokenAddress)
        external
        view
        returns (bool);

    function getClaimTokensData(address _claimTokenAddress)
        external
        view
        returns (ClaimTokenData memory);

    function getClaimTokenofSUNToken(address _sunToken)
        external
        view
        returns (address);
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