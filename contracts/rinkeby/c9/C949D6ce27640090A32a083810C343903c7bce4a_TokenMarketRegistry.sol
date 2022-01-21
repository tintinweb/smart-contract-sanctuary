// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/ITokenMarketRegistry.sol";
import "../../admin/interfaces/IGovWorldAdminRegistry.sol";
import "../../admin/interfaces/IGovWorldProtocolRegistry.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TokenMarketRegistry is ITokenMarketRegistry, OwnableUpgradeable {
    mapping(address => bool) public whitelistAddress;

    uint256 private loanActivateLimit;
    uint256 ltvPercentage;

    address govAdminRegistry;
    address govWorldProtocolRegistry;

    function initialize(
        address _govAdminRegistry,
        address _govWorldProtocolRegistry
    ) external initializer {
        __Ownable_init();
        govAdminRegistry = _govAdminRegistry;
        govWorldProtocolRegistry = _govWorldProtocolRegistry;
        ltvPercentage = 125;
    }

    modifier onlySuperAdmin(address _superAdmin) {
        require(
            IGovWorldAdminRegistry(govAdminRegistry).isSuperAdminAccess(
                msg.sender
            ),
            "GTM: Not a Gov Super Admin."
        );
        _;
    }

    function setloanActivateLimit(uint256 _loansLimit)
        public
        onlySuperAdmin(msg.sender)
    {
        require(_loansLimit > 0, "GTM: loanlimit error");
        loanActivateLimit = _loansLimit;
    }

    function getLoanActivateLimitt() external view override returns (uint256) {
        return loanActivateLimit;
    }

    function setLTVPercentage(uint256 _ltvPercentage)
        public
        onlySuperAdmin(msg.sender)
    {
        require(_ltvPercentage > 0, "GTM: percentage amount error");
        ltvPercentage = _ltvPercentage;
    }

    function getLTVPercentage() external view override returns (uint256) {
        return ltvPercentage;
    }

    function setWhilelistAddress(address _lender, bool _value)
        public
        onlySuperAdmin(msg.sender)
    {
        require(_lender != address(0x0), "GTM: null address error");
        whitelistAddress[_lender] = _value;
    }

    function isWhitelistedForActivation(address _lender)
        external
        view
        override
        returns (bool)
    {
        return whitelistAddress[_lender];
    }

    function isSuperAdminAccess(address _wallet)
        external
        view
        override
        returns (bool)
    {
        return
            IGovWorldAdminRegistry(govAdminRegistry).isSuperAdminAccess(
                _wallet
            );
    }

    function isTokenApproved(address _token)
        external
        view
        override
        returns (bool)
    {
        return
            IGovWorldProtocolRegistry(govWorldProtocolRegistry).isTokenApproved(
                _token
            );
    }

    function isTokenEnabledForCreateLoan(address _token)
        external
        view
        override
        returns (bool)
    {
        return
            IGovWorldProtocolRegistry(govWorldProtocolRegistry)
                .isTokenEnabledForCreateLoan(_token);
    }

    function getGovPlatformFee() external view override returns (uint256) {
        return
            IGovWorldProtocolRegistry(govWorldProtocolRegistry)
                .getGovPlatformFee();
    }

    /**
    @dev functiosn that will get AutoSell APY fee of the loan amount
     */
    function getautosellAPYFee(
        uint256 loanAmount,
        uint256 autosellAPY,
        uint256 loanterminDays
    ) external pure override returns (uint256) {
        // APY Fee Formula
        return ((loanAmount * autosellAPY) / 10000 / 365) * loanterminDays;
    }

    /**
    @dev function that will get APY fee of the loan amount in borrower
     */
    function getAPYFee(
        uint256 _loanAmountInBorrowed,
        uint256 _apyOffer,
        uint256 _termsLengthInDays
    ) external pure override returns (uint256) {
        // APY Fee Formula
        return
            ((_loanAmountInBorrowed * _apyOffer) / 10000 / 365) *
            _termsLengthInDays;
    }

    function getSingleApproveTokenData(address _tokenAddress)
        external
        view
        override
        returns (
            address,
            bool,
            uint256
        )
    {
        return
            IGovWorldProtocolRegistry(govWorldProtocolRegistry)
                .getSingleApproveTokenData(_tokenAddress);
    }

    function isSynthetticMintOn(address _tokenAddress)
        external
        view
        override
        returns (bool)
    {
        return
            IGovWorldProtocolRegistry(govWorldProtocolRegistry)
                .isSynthetticMintOn(_tokenAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenMarketRegistry {
    /**
    @dev function that will get APY fee of the loan amount in borrower
     */
    function getAPYFee(
        uint256 _loanAmountInBorrowed,
        uint256 _apyOffer,
        uint256 _termsLengthInDays
    ) external returns (uint256);

    /**
    @dev function that will get AutoSell APY fee of the loan amount
     */
    function getautosellAPYFee(
        uint256 loanAmount,
        uint256 autosellAPY,
        uint256 loanterminDays
    ) external returns (uint256);

    function getLoanActivateLimitt() external view returns (uint256);

    function getLTVPercentage() external view returns (uint256);

    function isWhitelistedForActivation(address) external returns (bool);

    function isSuperAdminAccess(address) external returns (bool);

    function isTokenApproved(address) external returns (bool);

    function isTokenEnabledForCreateLoan(address) external returns (bool);

    function getGovPlatformFee() external view returns (uint256);

    function getSingleApproveTokenData(address _tokenAddress)
        external
        view
        returns (
            address,
            bool,
            uint256
        );

    function isSynthetticMintOn(address _token) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGovWorldAdminRegistry {
    struct AdminAccess {
        //access-modifier variables to add projects to gov-intel
        bool addGovIntel;
        bool editGovIntel;
        //access-modifier variables to add tokens to gov-world protocol
        bool addToken;
        bool editToken;
        //access-modifier variables to add strategic partners to gov-world protocol
        bool addSp;
        bool editSp;
        //access-modifier variables to add gov-world admins to gov-world protocol
        bool addGovAdmin;
        bool editGovAdmin;
        //access-modifier variables to add bridges to gov-world protocol
        bool addBridge;
        bool editBridge;
        //access-modifier variables to add pools to gov-world protocol
        bool addPool;
        bool editPool;
        //superAdmin role assigned only by the super admin
        bool superAdmin;
    }

    function isAddGovAdminRole(address admin) external view returns (bool);

    //using this function externally in Gov Tier Level Smart Contract
    function isEditAdminAccessGranted(address admin)
        external
        view
        returns (bool);

    //using this function externally in other Smart Contracts
    function isAddTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isAddSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditAPYPerAccess(address admin) external view returns (bool);

    //using this function in loan smart contracts to withdraw network balance
    function isSuperAdminAccess(address admin) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum TokenType {
    ISDEX,
    ISELITE,
    ISVIP
}

// Token Market Data
struct Market {
    address dexRouter;
    address gToken;
    bool isMint;
    TokenType tokenType;
    bool isTokenEnabledAsCollateral;
}

interface IGovWorldProtocolRegistry {
    /** 
    @dev check function if Token Contract address is already added 
    @param _tokenAddress token address */
    function isTokenApproved(address _tokenAddress)
        external
        view
        returns (bool);

    /**
    @dev check fundtion token enable for staking as collateral
    */

    function isTokenEnabledForCreateLoan(address _tokenAddress)
        external
        view
        returns (bool);

    function getUnearnedAPYPercentageForLender()
        external
        view
        returns (uint256);

    function getGovPlatformFee() external view returns (uint256);

    function getThresholdPercentage() external view returns (uint256);

    function getAutosellPercentage() external view returns (uint256);

    function getAdminWalletPercentage() external view returns (uint256);

    function getSingleApproveToken(address _tokenAddress)
        external
        view
        returns (Market memory);

    function getSingleApproveTokenData(address _tokenAddress)
        external
        view
        returns (
            address,
            bool,
            uint256
        );

    function isSynthetticMintOn(address _token) external view returns (bool);

    function getTokenMarket() external view returns (address[] memory);

    function getAdminFeeWallet() external view returns (address);

    function getSingleTokenSps(address _tokenAddress)
        external
        view
        returns (address[] memory);

    function isAddedSPWallet(address _tokenAddress, address _walletAddress)
        external
        view
        returns (bool);
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