// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "./interfaces/IAddressRegistry.sol";

/**
 * @title APY.Finance's address registry
 * @author APY.Finance
 * @notice The address registry has two important purposes, one which
 *         is fairly concrete and another abstract.
 *
 *         1. The registry enables components of the APY.Finance system
 *         and external systems to retrieve core addresses reliably
 *         even when the functionality may move to a different
 *         address.
 *
 *         2. The registry also makes explicit which contracts serve
 *         as primary entrypoints for interacting with different
 *         components.  Not every contract is registered here, only
 *         the ones properly deserving of an identifier.  This helps
 *         define explicit boundaries between groups of contracts,
 *         each of which is logically cohesive.
 */
contract AddressRegistry is
    Initializable,
    OwnableUpgradeSafe,
    IAddressRegistry
{
    /* ------------------------------- */
    /* impl-specific storage variables */
    /* ------------------------------- */
    /** @notice the same address as the proxy admin; used
     *  to protect init functions for upgrades */
    address public proxyAdmin;
    bytes32[] internal _idList;
    mapping(bytes32 => address) internal _idToAddress;

    /* ------------------------------- */

    event AdminChanged(address);
    event AddressRegistered(bytes32 id, address _address);

    /**
     * @dev Since the proxy delegate calls to this "logic" contract, any
     * storage set by the logic contract's constructor during deploy is
     * disregarded and this function is needed to initialize the proxy
     * contract's storage according to this contract's layout.
     *
     * Since storage is not set yet, there is no simple way to protect
     * calling this function with owner modifiers.  Thus the OpenZeppelin
     * `initializer` modifier protects this function from being called
     * repeatedly.  It should be called during the deployment so that
     * it cannot be called by someone else later.
     */
    function initialize(address adminAddress) external initializer {
        require(adminAddress != address(0), "INVALID_ADMIN");

        // initialize ancestor storage
        __Context_init_unchained();
        __Ownable_init_unchained();

        // initialize impl-specific storage
        setAdminAddress(adminAddress);
    }

    /**
     * @dev Dummy function to show how one would implement an init function
     * for future upgrades.  Note the `initializer` modifier can only be used
     * once in the entire contract, so we can't use it here.  Instead,
     * we set the proxy admin address as a variable and protect this
     * function with `onlyAdmin`, which only allows the proxy admin
     * to call this function during upgrades.
     */
    // solhint-disable-next-line no-empty-blocks
    function initializeUpgrade() external virtual onlyAdmin {}

    function setAdminAddress(address adminAddress) public onlyOwner {
        require(adminAddress != address(0), "INVALID_ADMIN");
        proxyAdmin = adminAddress;
        emit AdminChanged(adminAddress);
    }

    /**
     * @dev Throws if called by any account other than the proxy admin.
     */
    modifier onlyAdmin() {
        require(msg.sender == proxyAdmin, "ADMIN_ONLY");
        _;
    }

    /// @notice Returns the list of all registered identifiers.
    function getIds() public view override returns (bytes32[] memory) {
        return _idList;
    }

    /// @dev block ETHER transfers as the registry will never need it
    receive() external payable {
        revert("DONT_SEND_ETHER");
    }

    /**
     * @notice Register address with identifier.
     * @dev Using an existing ID will replace the old address with new.
     *      Currently there is no way to remove an ID, as attempting to
     *      register the zero address will revert.
     */
    function registerAddress(bytes32 id, address _address) public onlyOwner {
        require(_address != address(0), "Invalid address");
        if (_idToAddress[id] == address(0)) {
            // id wasn't registered before, so add it to the list
            _idList.push(id);
        }
        _idToAddress[id] = _address;
        emit AddressRegistered(id, _address);
    }

    /// @dev Convenient method to register multiple addresses at once.
    function registerMultipleAddresses(
        bytes32[] calldata ids,
        address[] calldata addresses
    ) external onlyOwner {
        require(ids.length == addresses.length, "Inputs have differing length");
        for (uint256 i = 0; i < ids.length; i++) {
            bytes32 id = ids[i];
            address _address = addresses[i];
            registerAddress(id, _address);
        }
    }

    /// @notice Retrieve the address corresponding to the identifier.
    function getAddress(bytes32 id) public view override returns (address) {
        address _address = _idToAddress[id];
        require(_address != address(0), "Missing address");
        return _address;
    }

    /**
     * @notice Get the address for the APY Manager.
     * @dev Not just a helper function, this makes explicit a key ID
     *      for the system.
     */
    function managerAddress() public view returns (address) {
        return getAddress("manager");
    }

    /**
     * @notice Get the address for the TVLManager,
     *         aka the "Chainlink Registry", as it is used by
     *         Chainlink nodes to compute the deployed value of the
     *         APY.Finance system.
     * @dev Not just a helper function, this makes explicit a key ID
     *      for the system.
     */
    function chainlinkRegistryAddress() public view returns (address) {
        return getAddress("chainlinkRegistry");
    }

    /**
     * @notice Get the address for APY.Finance's DAI stablecoin pool.
     * @dev Not just a helper function, this makes explicit a key ID
     *      for the system.
     */
    function daiPoolAddress() public view returns (address) {
        return getAddress("daiPool");
    }

    /**
     * @notice Get the address for APY.Finance's USDC stablecoin pool.
     * @dev Not just a helper function, this makes explicit a key ID
     *      for the system.
     */
    function usdcPoolAddress() public view returns (address) {
        return getAddress("usdcPool");
    }

    /**
     * @notice Get the address for APY.Finance's USDT stablecoin pool.
     * @dev Not just a helper function, this makes explicit a key ID
     *      for the system.
     */
    function usdtPoolAddress() public view returns (address) {
        return getAddress("usdtPool");
    }
}

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
import "../Initializable.sol";
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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

/**
 * @title Interface to access APY.Finance's address registry
 * @author APY.Finance
 * @notice The address registry has two important purposes, one which
 *         is fairly concrete and another abstract.
 *
 *         1. The registry enables components of the APY.Finance system
 *         and external systems to retrieve core addresses reliably
 *         even when the functionality may move to a different
 *         address.
 *
 *         2. The registry also makes explicit which contracts serve
 *         as primary entrypoints for interacting with different
 *         components.  Not every contract is registered here, only
 *         the ones properly deserving of an identifier.  This helps
 *         define explicit boundaries between groups of contracts,
 *         each of which is logically cohesive.
 */
interface IAddressRegistry {
    /**
     * @notice Returns the list of identifiers for core components of
     *         the APY.Finance system.
     * @return List of identifiers
     */
    function getIds() external view returns (bytes32[] memory);

    /**
     * @notice Returns the current address represented by an identifier
     *         for a core component.
     * @param id Component identifier
     * @return The current address represented by an identifier
     */
    function getAddress(bytes32 id) external view returns (address);
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../AddressRegistry.sol";

contract AddressRegistryUpgraded is AddressRegistry {
    bool public newlyAddedVariable;

    function initializeUpgrade() public override onlyAdmin {
        newlyAddedVariable = true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "./interfaces/ILiquidityPool.sol";
import "./interfaces/IDetailedERC20.sol";

contract PoolToken is
    ILiquidityPool,
    Initializable,
    OwnableUpgradeSafe,
    ReentrancyGuardUpgradeSafe,
    PausableUpgradeSafe,
    ERC20UpgradeSafe
{
    using SafeMath for uint256;
    using SafeERC20 for IDetailedERC20;
    uint256 public constant DEFAULT_APT_TO_UNDERLYER_FACTOR = 1000;

    /* ------------------------------- */
    /* impl-specific storage variables */
    /* ------------------------------- */
    address public proxyAdmin;
    bool public addLiquidityLock;
    bool public redeemLock;
    IDetailedERC20 public underlyer;
    AggregatorV3Interface public priceAgg;

    /* ------------------------------- */

    function initialize(
        address adminAddress,
        IDetailedERC20 _underlyer,
        AggregatorV3Interface _priceAgg
    ) external initializer {
        require(adminAddress != address(0), "INVALID_ADMIN");
        require(address(_underlyer) != address(0), "INVALID_TOKEN");
        require(address(_priceAgg) != address(0), "INVALID_AGG");

        // initialize ancestor storage
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained("APY Pool Token", "APT");

        // initialize impl-specific storage
        setAdminAddress(adminAddress);
        addLiquidityLock = false;
        redeemLock = false;
        underlyer = _underlyer;
        setPriceAggregator(_priceAgg);
    }

    // solhint-disable-next-line no-empty-blocks
    function initializeUpgrade() external virtual onlyAdmin {}

    function setAdminAddress(address adminAddress) public onlyOwner {
        require(adminAddress != address(0), "INVALID_ADMIN");
        proxyAdmin = adminAddress;
        emit AdminChanged(adminAddress);
    }

    function setPriceAggregator(AggregatorV3Interface _priceAgg)
        public
        onlyOwner
    {
        require(address(_priceAgg) != address(0), "INVALID_AGG");
        priceAgg = _priceAgg;
        emit PriceAggregatorChanged(address(_priceAgg));
    }

    modifier onlyAdmin() {
        require(msg.sender == proxyAdmin, "ADMIN_ONLY");
        _;
    }

    function lock() external onlyOwner {
        _pause();
    }

    function unlock() external onlyOwner {
        _unpause();
    }

    receive() external payable {
        revert("DONT_SEND_ETHER");
    }

    /**
     * @notice Mint corresponding amount of APT tokens for sent token amount.
     * @dev If no APT tokens have been minted yet, fallback to a fixed ratio.
     */
    function addLiquidity(uint256 tokenAmt)
        external
        virtual
        override
        nonReentrant
        whenNotPaused
    {
        require(!addLiquidityLock, "LOCKED");
        require(tokenAmt > 0, "AMOUNT_INSUFFICIENT");
        require(
            underlyer.allowance(msg.sender, address(this)) >= tokenAmt,
            "ALLOWANCE_INSUFFICIENT"
        );

        // calculateMintAmount() is not used because deposit value
        // is needed for the event
        uint256 depositEthValue = getEthValueFromTokenAmount(tokenAmt);
        uint256 poolTotalEthValue = getPoolTotalEthValue();
        uint256 mintAmount =
            _calculateMintAmount(depositEthValue, poolTotalEthValue);

        _mint(msg.sender, mintAmount);
        underlyer.safeTransferFrom(msg.sender, address(this), tokenAmt);

        emit DepositedAPT(
            msg.sender,
            underlyer,
            tokenAmt,
            mintAmount,
            depositEthValue,
            getPoolTotalEthValue()
        );
    }

    function getPoolTotalEthValue() public view virtual returns (uint256) {
        return getEthValueFromTokenAmount(underlyer.balanceOf(address(this)));
    }

    function getAPTEthValue(uint256 amount) public view returns (uint256) {
        require(totalSupply() > 0, "INSUFFICIENT_TOTAL_SUPPLY");
        return (amount.mul(getPoolTotalEthValue())).div(totalSupply());
    }

    function getEthValueFromTokenAmount(uint256 amount)
        public
        view
        returns (uint256)
    {
        if (amount == 0) {
            return 0;
        }
        uint256 decimals = underlyer.decimals();
        return ((getTokenEthPrice()).mul(amount)).div(10**decimals);
    }

    function getTokenAmountFromEthValue(uint256 ethValue)
        public
        view
        returns (uint256)
    {
        uint256 tokenEthPrice = getTokenEthPrice();
        uint256 decimals = underlyer.decimals();
        return ((10**decimals).mul(ethValue)).div(tokenEthPrice);
    }

    function getTokenEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceAgg.latestRoundData();
        require(price > 0, "UNABLE_TO_RETRIEVE_ETH_PRICE");
        return uint256(price);
    }

    /** @notice Disable deposits. */
    function lockAddLiquidity() external onlyOwner {
        addLiquidityLock = true;
        emit AddLiquidityLocked();
    }

    /** @notice Enable deposits. */
    function unlockAddLiquidity() external onlyOwner {
        addLiquidityLock = false;
        emit AddLiquidityUnlocked();
    }

    /**
     * @notice Redeems APT amount for its underlying token amount.
     * @param aptAmount The amount of APT tokens to redeem
     */
    function redeem(uint256 aptAmount)
        external
        virtual
        override
        nonReentrant
        whenNotPaused
    {
        require(!redeemLock, "LOCKED");
        require(aptAmount > 0, "AMOUNT_INSUFFICIENT");
        require(aptAmount <= balanceOf(msg.sender), "BALANCE_INSUFFICIENT");

        uint256 redeemTokenAmt = getUnderlyerAmount(aptAmount);

        _burn(msg.sender, aptAmount);
        underlyer.safeTransfer(msg.sender, redeemTokenAmt);

        emit RedeemedAPT(
            msg.sender,
            underlyer,
            redeemTokenAmt,
            aptAmount,
            getEthValueFromTokenAmount(redeemTokenAmt),
            getPoolTotalEthValue()
        );
    }

    /** @notice Disable APT redeeming. */
    function lockRedeem() external onlyOwner {
        redeemLock = true;
        emit RedeemLocked();
    }

    /** @notice Enable APT redeeming. */
    function unlockRedeem() external onlyOwner {
        redeemLock = false;
        emit RedeemUnlocked();
    }

    /** @notice Calculate APT amount to be minted from deposit amount.
     *  @param tokenAmt The deposit amount of stablecoin
     *  @return The mint amount
     */
    function calculateMintAmount(uint256 tokenAmt)
        public
        view
        returns (uint256)
    {
        uint256 depositEthValue = getEthValueFromTokenAmount(tokenAmt);
        uint256 poolTotalEthValue = getPoolTotalEthValue();
        return _calculateMintAmount(depositEthValue, poolTotalEthValue);
    }

    /**
     *  @dev amount of APT minted should be in same ratio to APT supply
     *       as token amount sent is to contract's token balance, i.e.:
     *
     *       mint amount / total supply (before deposit)
     *       = token amount sent / contract token balance (before deposit)
     */
    function _calculateMintAmount(
        uint256 depositEthAmount,
        uint256 totalEthAmount
    ) internal view returns (uint256) {
        uint256 totalSupply = totalSupply();

        if (totalEthAmount == 0 || totalSupply == 0) {
            return depositEthAmount.mul(DEFAULT_APT_TO_UNDERLYER_FACTOR);
        }

        return (depositEthAmount.mul(totalSupply)).div(totalEthAmount);
    }

    /**
     * @notice Get the underlying amount represented by APT amount.
     * @param aptAmount The amount of APT tokens
     * @return uint256 The underlying value of the APT tokens
     */
    function getUnderlyerAmount(uint256 aptAmount)
        public
        view
        returns (uint256)
    {
        return getTokenAmountFromEthValue(getAPTEthValue(aptAmount));
    }
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;


    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {


        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;

    }


    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    uint256[49] private __gap;
}

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
import "../Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PausableUpgradeSafe is Initializable, ContextUpgradeSafe {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */

    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {


        _paused = false;

    }


    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    uint256[49] private __gap;
}

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20UpgradeSafe is Initializable, ContextUpgradeSafe, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */

    function __ERC20_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol) internal initializer {


        _name = name;
        _symbol = symbol;
        _decimals = 18;

    }


    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    uint256[44] private __gap;
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

/**
 * @title Interface for APY.Finance liquidity pools
 * @author APY.Finance
 * @notice Liquidity pools accept deposits and withdrawals of a single token.
 *         APT is minted and burned to track an account's stake in the pool.
 *         A Chainlink price aggregator is also set so the total value of the
 *         pool can be computed.
 */
interface ILiquidityPool {
    event DepositedAPT(
        address indexed sender,
        IERC20 token,
        uint256 tokenAmount,
        uint256 aptMintAmount,
        uint256 tokenEthValue,
        uint256 totalEthValueLocked
    );
    event RedeemedAPT(
        address indexed sender,
        IERC20 token,
        uint256 redeemedTokenAmount,
        uint256 aptRedeemAmount,
        uint256 tokenEthValue,
        uint256 totalEthValueLocked
    );
    event AddLiquidityLocked();
    event AddLiquidityUnlocked();
    event RedeemLocked();
    event RedeemUnlocked();
    event AdminChanged(address);
    event PriceAggregatorChanged(address agg);

    /**
     * @notice Mint corresponding amount of APT tokens for deposited stablecoin.
     * @param amount Amount to deposit of the underlying stablecoin
     */
    function addLiquidity(uint256 amount) external;

    /**
     * @notice Redeems APT amount for its underlying stablecoin amount.
     * @param tokenAmount The amount of APT tokens to redeem
     */
    function redeem(uint256 tokenAmount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

interface IDetailedERC20 is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

import "../PoolToken.sol";

/**
 * @dev Proxy contract to test internal variables and functions
 *      Should not be used other than in test files!
 */
contract TestPoolToken is PoolToken {
    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../PoolToken.sol";

contract PoolTokenUpgraded is PoolToken {
    bool public newlyAddedVariable;

    function initializeUpgrade() public override onlyAdmin {
        newlyAddedVariable = true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SignedSafeMath.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "./interfaces/ILiquidityPoolV2.sol";
import "./interfaces/IDetailedERC20.sol";
import "./interfaces/IAddressRegistryV2.sol";
import "./MetaPoolToken.sol";

/**
 * @title APY.Finance Pool Token
 * @author APY.Finance
 * @notice This token (APT) is the basic liquidity-provider token used
 *         within the APY.Finance system.
 *
 *         For simplicity, it has been integrated with pool functionality
 *         enabling users to deposit and withdraw in an underlying token,
 *         currently one of three stablecoins.
 *
 *         Upon deposit of the underlyer, an appropriate amount of APT
 *         is minted.  This amount is calculated as a share of the pool's
 *         total value, which may change as strategies gain or lose.
 *
 *         The pool's total value is comprised of the value of its balance
 *         of the underlying stablecoin and also the value of its balance
 *         of mAPT, an internal token used by the system to track how much
 *         is owed to the pool.  Every time the PoolManager withdraws funds
 *         from the pool, mAPT is issued to the pool.
 *
 *         Upon redemption of APT (withdrawal), the user will get back
 *         in the underlying stablecoin, the amount equivalent in value
 *         to the user's APT share of the pool's total value.
 *
 *         Currently the user may not be able to redeem their full APT
 *         balance, as the majority of funds will be deployed at any
 *         given time.  Funds will periodically be pushed to the pools
 *         so that each pool maintains a reserve percentage of the
 *         pool's total value.
 *
 *         Later upgrades to the system will enable users to submit
 *         withdrawal requests, which will be processed periodically
 *         and unwind positions to free up funds.
 */
contract PoolTokenV2 is
    ILiquidityPoolV2,
    Initializable,
    OwnableUpgradeSafe,
    ReentrancyGuardUpgradeSafe,
    PausableUpgradeSafe,
    ERC20UpgradeSafe
{
    using Address for address;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeERC20 for IDetailedERC20;
    uint256 public constant DEFAULT_APT_TO_UNDERLYER_FACTOR = 1000;
    uint256 internal constant _MAX_INT256 = 2**255 - 1;

    event AdminChanged(address);

    /* ------------------------------- */
    /* impl-specific storage variables */
    /* ------------------------------- */

    // V1
    /// @notice used to protect init functions for upgrades
    address public proxyAdmin;
    /// @notice true if depositing is locked
    bool public addLiquidityLock;
    /// @notice true if withdrawing is locked
    bool public redeemLock;
    /// @notice underlying stablecoin
    IDetailedERC20 public underlyer;
    /// @notice USD price feed for the stablecoin
    // AggregatorV3Interface public priceAgg; <-- removed in V2

    // V2
    /// @notice registry to fetch core platform addresses from
    /// @dev this slot replaces the last V1 slot for the price agg
    IAddressRegistryV2 public addressRegistry;
    /// @notice seconds since last deposit during which withdrawal fee is charged
    uint256 public feePeriod;
    /// @notice percentage charged for withdrawal fee
    uint256 public feePercentage;
    /// @notice time of last deposit
    mapping(address => uint256) public lastDepositTime;
    /// @notice percentage of pool total value available for immediate withdrawal
    uint256 public reservePercentage;

    /* ------------------------------- */

    /**
     * @dev Since the proxy delegate calls to this "logic" contract, any
     * storage set by the logic contract's constructor during deploy is
     * disregarded and this function is needed to initialize the proxy
     * contract's storage according to this contract's layout.
     *
     * Since storage is not set yet, there is no simple way to protect
     * calling this function with owner modifiers.  Thus the OpenZeppelin
     * `initializer` modifier protects this function from being called
     * repeatedly.  It should be called during the deployment so that
     * it cannot be called by someone else later.
     *
     * NOTE: this function is copied from the V1 contract and has already
     * been called during V1 deployment.  It is included here for clarity.
     */
    function initialize(
        address adminAddress,
        IDetailedERC20 _underlyer,
        AggregatorV3Interface _priceAgg
    ) external initializer {
        require(adminAddress != address(0), "INVALID_ADMIN");
        require(address(_underlyer) != address(0), "INVALID_TOKEN");
        require(address(_priceAgg) != address(0), "INVALID_AGG");

        // initialize ancestor storage
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained("APY Pool Token", "APT");

        // initialize impl-specific storage
        setAdminAddress(adminAddress);
        addLiquidityLock = false;
        redeemLock = false;
        underlyer = _underlyer;
        // setPriceAggregator(_priceAgg);  <-- deprecated in V2.
    }

    /**
     * @dev Note the `initializer` modifier can only be used once in the
     * entire contract, so we can't use it here.  Instead, we protect
     * this function with `onlyAdmin`, which allows only the `proxyAdmin`
     * address to call this function.  Since that address is in fact
     * set to the actual proxy admin during deployment, this ensures
     * this function can only be called as part of a delegate call
     * during upgrades, i.e. in ProxyAdmin's `upgradeAndCall`.
     */
    function initializeUpgrade(address _addressRegistry)
        external
        virtual
        onlyAdmin
    {
        require(_addressRegistry.isContract(), "INVALID_ADDRESS");
        addressRegistry = IAddressRegistryV2(_addressRegistry);
        feePeriod = 1 days;
        feePercentage = 5;
        reservePercentage = 5;
    }

    function setAdminAddress(address adminAddress) public onlyOwner {
        require(adminAddress != address(0), "INVALID_ADMIN");
        proxyAdmin = adminAddress;
        emit AdminChanged(adminAddress);
    }

    function setAddressRegistry(address payable _addressRegistry)
        public
        onlyOwner
    {
        require(Address.isContract(_addressRegistry), "INVALID_ADDRESS");
        addressRegistry = IAddressRegistryV2(_addressRegistry);
    }

    function setFeePeriod(uint256 _feePeriod) public onlyOwner {
        feePeriod = _feePeriod;
    }

    function setFeePercentage(uint256 _feePercentage) public onlyOwner {
        feePercentage = _feePercentage;
    }

    function setReservePercentage(uint256 _reservePercentage) public onlyOwner {
        reservePercentage = _reservePercentage;
    }

    /**
     * @dev Throws if called by any account other than the proxy admin.
     */
    modifier onlyAdmin() {
        require(msg.sender == proxyAdmin, "ADMIN_ONLY");
        _;
    }

    /**
     * @notice Disable both depositing and withdrawals.
     *      Note that `addLiquidity` and `redeem` also have individual locks.
     */
    function lock() external onlyOwner {
        _pause();
    }

    /**
     * @notice Re-enable both depositing and withdrawals.
     *      Note that `addLiquidity` and `redeem` also have individual locks.
     */
    function unlock() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Mint corresponding amount of APT tokens for deposited stablecoin.
     * @dev If no APT tokens have been minted yet, fallback to a fixed ratio.
     * @param depositAmount Amount to deposit of the underlying stablecoin
     */
    function addLiquidity(uint256 depositAmount)
        external
        virtual
        override
        nonReentrant
        whenNotPaused
    {
        require(!addLiquidityLock, "LOCKED");
        require(depositAmount > 0, "AMOUNT_INSUFFICIENT");
        require(
            underlyer.allowance(msg.sender, address(this)) >= depositAmount,
            "ALLOWANCE_INSUFFICIENT"
        );
        // solhint-disable-next-line not-rely-on-time
        lastDepositTime[msg.sender] = block.timestamp;

        // calculateMintAmount() is not used because deposit value
        // is needed for the event
        uint256 depositValue = getValueFromUnderlyerAmount(depositAmount);
        uint256 poolTotalValue = getPoolTotalValue();
        uint256 mintAmount = _calculateMintAmount(depositValue, poolTotalValue);

        _mint(msg.sender, mintAmount);
        underlyer.safeTransferFrom(msg.sender, address(this), depositAmount);

        emit DepositedAPT(
            msg.sender,
            underlyer,
            depositAmount,
            mintAmount,
            depositValue,
            getPoolTotalValue()
        );
    }

    /** @notice Disable deposits. */
    function lockAddLiquidity() external onlyOwner {
        addLiquidityLock = true;
        emit AddLiquidityLocked();
    }

    /** @notice Enable deposits. */
    function unlockAddLiquidity() external onlyOwner {
        addLiquidityLock = false;
        emit AddLiquidityUnlocked();
    }

    /**
     * @notice Redeems APT amount for its underlying stablecoin amount.
     * @dev May revert if there is not enough in the pool.
     * @param aptAmount The amount of APT tokens to redeem
     */
    function redeem(uint256 aptAmount)
        external
        virtual
        override
        nonReentrant
        whenNotPaused
    {
        require(!redeemLock, "LOCKED");
        require(aptAmount > 0, "AMOUNT_INSUFFICIENT");
        require(aptAmount <= balanceOf(msg.sender), "BALANCE_INSUFFICIENT");

        uint256 redeemUnderlyerAmt = getUnderlyerAmountWithFee(aptAmount);
        require(
            redeemUnderlyerAmt <= underlyer.balanceOf(address(this)),
            "RESERVE_INSUFFICIENT"
        );

        _burn(msg.sender, aptAmount);
        underlyer.safeTransfer(msg.sender, redeemUnderlyerAmt);

        emit RedeemedAPT(
            msg.sender,
            underlyer,
            redeemUnderlyerAmt,
            aptAmount,
            getValueFromUnderlyerAmount(redeemUnderlyerAmt),
            getPoolTotalValue()
        );
    }

    /** @notice Disable APT redeeming. */
    function lockRedeem() external onlyOwner {
        redeemLock = true;
        emit RedeemLocked();
    }

    /** @notice Enable APT redeeming. */
    function unlockRedeem() external onlyOwner {
        redeemLock = false;
        emit RedeemUnlocked();
    }

    /**
     * @notice Calculate APT amount to be minted from deposit amount.
     * @param depositAmount The deposit amount of stablecoin
     * @return The mint amount
     */
    function calculateMintAmount(uint256 depositAmount)
        public
        view
        returns (uint256)
    {
        uint256 depositValue = getValueFromUnderlyerAmount(depositAmount);
        uint256 poolTotalValue = getPoolTotalValue();
        return _calculateMintAmount(depositValue, poolTotalValue);
    }

    /**
     *  @dev amount of APT minted should be in same ratio to APT supply
     *       as deposit value is to pool's total value, i.e.:
     *
     *       mint amount / total supply
     *       = deposit value / pool total value
     *
     *       For denominators, pre or post-deposit amounts can be used.
     *       The important thing is they are consistent, i.e. both pre-deposit
     *       or both post-deposit.
     */
    function _calculateMintAmount(uint256 depositValue, uint256 poolTotalValue)
        internal
        view
        returns (uint256)
    {
        uint256 totalSupply = totalSupply();

        if (poolTotalValue == 0 || totalSupply == 0) {
            return depositValue.mul(DEFAULT_APT_TO_UNDERLYER_FACTOR);
        }

        return (depositValue.mul(totalSupply)).div(poolTotalValue);
    }

    /**
     * @notice Get the underlying amount represented by APT amount,
     *         deducting early withdraw fee, if applicable.
     * @dev To check if fee will be applied, use `isEarlyRedeem`.
     * @param aptAmount The amount of APT tokens
     * @return uint256 The underlyer value of the APT tokens
     */
    function getUnderlyerAmountWithFee(uint256 aptAmount)
        public
        view
        returns (uint256)
    {
        uint256 redeemUnderlyerAmt = getUnderlyerAmount(aptAmount);
        if (isEarlyRedeem()) {
            uint256 fee = redeemUnderlyerAmt.mul(feePercentage).div(100);
            redeemUnderlyerAmt = redeemUnderlyerAmt.sub(fee);
        }
        return redeemUnderlyerAmt;
    }

    /**
     * @notice Get the underlying amount represented by APT amount.
     * @param aptAmount The amount of APT tokens
     * @return uint256 The underlying value of the APT tokens
     */
    function getUnderlyerAmount(uint256 aptAmount)
        public
        view
        returns (uint256)
    {
        if (aptAmount == 0) {
            return 0;
        }
        require(totalSupply() > 0, "INSUFFICIENT_TOTAL_SUPPLY");
        // the below is mathematically equivalent to:
        //
        // getUnderlyerAmountFromValue(getAPTValue(aptAmount));
        //
        // but composing the two functions leads to early loss
        // of precision from division, so it's better to do it
        // this way:
        uint256 underlyerPrice = getUnderlyerPrice();
        uint256 decimals = underlyer.decimals();
        return
            aptAmount
                .mul(getPoolTotalValue())
                .mul(10**decimals)
                .div(totalSupply())
                .div(underlyerPrice);
    }

    /**
     * @notice Checks if caller will be charged early withdrawal fee.
     * @dev `lastDepositTime` is stored each time user makes a deposit, so
     *      the waiting period is restarted on each deposit.
     * @return "true" when fee will apply, "false" when it won't.
     */
    function isEarlyRedeem() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp.sub(lastDepositTime[msg.sender]) < feePeriod;
    }

    /**
     * @notice Get the total USD-denominated value (in bits) of the pool's assets,
     *         including not only its underlyer balance, but any part of deployed
     *         capital that is owed to it.
     * @return USD value
     */
    function getPoolTotalValue() public view virtual returns (uint256) {
        uint256 underlyerValue = getPoolUnderlyerValue();
        uint256 mAptValue = getDeployedValue();
        return underlyerValue.add(mAptValue);
    }

    /**
     * @notice Get the USD-denominated value (in bits) of the pool's
     *         underlyer balance.
     * @return USD value
     */
    function getPoolUnderlyerValue() public view virtual returns (uint256) {
        return getValueFromUnderlyerAmount(underlyer.balanceOf(address(this)));
    }

    /**
     * @notice Get the USD-denominated value (in bits) of the pool's share
     *         of the deployed capital, as tracked by the mAPT token.
     * @return USD value
     */
    function getDeployedValue() public view virtual returns (uint256) {
        MetaPoolToken mApt = MetaPoolToken(addressRegistry.mAptAddress());
        return mApt.getDeployedValue(address(this));
    }

    /**
     * @notice Get the USD-denominated value (in bits) represented by APT amount.
     * @param aptAmount APT amount
     * @return USD value
     */
    function getAPTValue(uint256 aptAmount) public view returns (uint256) {
        require(totalSupply() > 0, "INSUFFICIENT_TOTAL_SUPPLY");
        return aptAmount.mul(getPoolTotalValue()).div(totalSupply());
    }

    /**
     * @notice Get the USD-denominated value (in bits) represented by stablecoin amount.
     * @param underlyerAmount amount of underlying stablecoin
     * @return USD value
     */
    function getValueFromUnderlyerAmount(uint256 underlyerAmount)
        public
        view
        returns (uint256)
    {
        if (underlyerAmount == 0) {
            return 0;
        }
        uint256 decimals = underlyer.decimals();
        return getUnderlyerPrice().mul(underlyerAmount).div(10**decimals);
    }

    /**
     * @notice Get the underlyer amount equivalent to given USD-denominated value (in bits).
     * @param value USD value
     * @return amount of underlying stablecoin
     */
    function getUnderlyerAmountFromValue(uint256 value)
        public
        view
        returns (uint256)
    {
        uint256 underlyerPrice = getUnderlyerPrice();
        uint256 decimals = underlyer.decimals();
        return (10**decimals).mul(value).div(underlyerPrice);
    }

    /**
     * @notice Get the underlyer stablecoin's USD price (in bits).
     * @return USD price
     */
    function getUnderlyerPrice() public view returns (uint256) {
        IOracleAdapter oracleAdapter =
            IOracleAdapter(addressRegistry.oracleAdapterAddress());
        return oracleAdapter.getAssetPrice(address(underlyer));
    }

    /**
     * @notice Get the USD value needed to meet the reserve percentage
     *         of the pool's deployed value.
     *
     *         This "top-up" value should satisfy:
     *
     *         top-up USD value + pool underlyer USD value
     *            = (reserve %) * pool deployed value (after unwinding)
     *
     * @dev Taking the percentage of the pool's current deployed value
     *      is not sufficient, because the requirement is to have the
     *      resulting values after unwinding capital satisfy the
     *      above equation.
     *
     *      More precisely:
     *
     *      R_pre = pool underlyer USD value before pushing unwound
     *              capital to the pool
     *      R_post = pool underlyer USD value after pushing
     *      DV_pre = pool's deployed USD value before unwinding
     *      DV_post = pool's deployed USD value after unwinding
     *      rPerc = the reserve percentage as a whole number
     *                          out of 100
     *
     *      We want:
     *
     *          R_post = (rPerc / 100) * DV_post          (equation 1)
     *
     *          where R_post = R_pre + top-up value
     *                DV_post = DV_pre - top-up value
     *
     *      Making the latter substitutions in equation 1, gives:
     *
     *      top-up value = (rPerc * DV_pre - 100 * R_pre) / (100 + rPerc)
     *
     * @return int256 The underlyer value to top-up the pool's reserve
     */
    function getReserveTopUpValue() public view returns (int256) {
        uint256 unnormalizedTargetValue =
            getDeployedValue().mul(reservePercentage);
        uint256 unnormalizedUnderlyerValue = getPoolUnderlyerValue().mul(100);

        require(unnormalizedTargetValue <= _MAX_INT256, "SIGNED_INT_OVERFLOW");
        require(
            unnormalizedUnderlyerValue <= _MAX_INT256,
            "SIGNED_INT_OVERFLOW"
        );
        int256 topUpValue =
            int256(unnormalizedTargetValue)
                .sub(int256(unnormalizedUnderlyerValue))
                .div(int256(reservePercentage).add(100));
        return topUpValue;
    }

    /**
     * @notice Allow `delegate` to withdraw any amount from the pool.
     * @dev Will fail if called twice, due to usage of `safeApprove`.
     * @param delegate Address to give infinite allowance to
     */
    function infiniteApprove(address delegate)
        external
        nonReentrant
        whenNotPaused
        onlyOwner
    {
        underlyer.safeApprove(delegate, type(uint256).max);
    }

    /**
     * @notice Revoke given allowance from `delegate`.
     * @dev Can be called even when the pool is locked.
     * @param delegate Address to remove allowance from
     */
    function revokeApprove(address delegate) external nonReentrant onlyOwner {
        underlyer.safeApprove(delegate, 0);
    }

    /**
     * @dev This hook is in-place to block inter-user APT transfers, as it
     *      is one avenue that can be used by arbitrageurs to drain the
     *      reserves.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        // allow minting and burning
        if (from == address(0) || to == address(0)) return;
        // block transfer between users
        revert("INVALID_TRANSFER");
    }
}

pragma solidity ^0.6.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Multiplies two signed integers, reverts on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

/**
 * @title Interface for APY.Finance liquidity pools
 * @author APY.Finance
 * @notice Liquidity pools accept deposits and withdrawals of a single token.
 *         APT is minted and burned to track an account's stake in the pool.
 *         A Chainlink price aggregator is also set so the total value of the
 *         pool can be computed.
 */
interface ILiquidityPoolV2 {
    event DepositedAPT(
        address indexed sender,
        IERC20 token,
        uint256 tokenAmount,
        uint256 aptMintAmount,
        uint256 tokenEthValue,
        uint256 totalEthValueLocked
    );
    event RedeemedAPT(
        address indexed sender,
        IERC20 token,
        uint256 redeemedTokenAmount,
        uint256 aptRedeemAmount,
        uint256 tokenEthValue,
        uint256 totalEthValueLocked
    );
    event AddLiquidityLocked();
    event AddLiquidityUnlocked();
    event RedeemLocked();
    event RedeemUnlocked();

    /**
     * @notice Mint corresponding amount of APT tokens for deposited stablecoin.
     * @param amount Amount to deposit of the underlying stablecoin
     */
    function addLiquidity(uint256 amount) external;

    /**
     * @notice Redeems APT amount for its underlying stablecoin amount.
     * @param tokenAmount The amount of APT tokens to redeem
     */
    function redeem(uint256 tokenAmount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

/**
 * @title Interface to access APY.Finance's address registry
 * @author APY.Finance
 * @notice The address registry has two important purposes, one which
 *         is fairly concrete and another abstract.
 *
 *         1. The registry enables components of the APY.Finance system
 *         and external systems to retrieve core addresses reliably
 *         even when the functionality may move to a different
 *         address.
 *
 *         2. The registry also makes explicit which contracts serve
 *         as primary entrypoints for interacting with different
 *         components.  Not every contract is registered here, only
 *         the ones properly deserving of an identifier.  This helps
 *         define explicit boundaries between groups of contracts,
 *         each of which is logically cohesive.
 */
interface IAddressRegistryV2 {
    /**
     * @notice Returns the list of identifiers for core components of
     *         the APY.Finance system.
     * @return List of identifiers
     */
    function getIds() external view returns (bytes32[] memory);

    /**
     * @notice Returns the current address represented by an identifier
     *         for a core component.
     * @param id Component identifier
     * @return The current address represented by an identifier
     */
    function getAddress(bytes32 id) external view returns (address);

    function poolManagerAddress() external view returns (address);

    function tvlManagerAddress() external view returns (address);

    function chainlinkRegistryAddress() external view returns (address);

    function daiPoolAddress() external view returns (address);

    function usdcPoolAddress() external view returns (address);

    function usdtPoolAddress() external view returns (address);

    function mAptAddress() external view returns (address);

    function lpSafeAddress() external view returns (address);

    function oracleAdapterAddress() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "./interfaces/IAddressRegistryV2.sol";
import "./interfaces/IMintable.sol";
import "./interfaces/IOracleAdapter.sol";

/**
 * @title Meta Pool Token
 * @author APY.Finance
 * @notice This token is used to keep track of the capital that has been
 * pulled from the PoolToken contracts.
 *
 * When the PoolManager pulls capital from the PoolToken contracts to
 * deploy to yield farming strategies, it will mint mAPT and transfer it to
 * the PoolToken contracts. The ratio of the mAPT held by each PoolToken
 * to the total supply of mAPT determines the amount of the TVL dedicated to
 * PoolToken.
 *
 * DEPLOY CAPITAL TO YIELD FARMING STRATEGIES
 * Tracks the share of deployed TVL owned by an PoolToken using mAPT.
 *
 * +-------------+   PoolManager.fundAccount   +-------------+
 * |             |---------------------------->|             |
 * | PoolTokenV2 |     MetaPoolToken.mint      | PoolManager |
 * |             |<----------------------------|             |
 * +-------------+                             +-------------+
 *
 *
 * WITHDRAW CAPITAL FROM YIELD FARMING STRATEGIES
 * Uses mAPT to calculate the amount of capital returned to the PoolToken.
 *
 * +-------------+    PoolManager.withdrawFromAccount   +-------------+
 * |             |<-------------------------------------|             |
 * | PoolTokenV2 |          MetaPoolToken.burn          | PoolManager |
 * |             |------------------------------------->|             |
 * +-------------+                                      +-------------+
 */
contract MetaPoolToken is
    Initializable,
    OwnableUpgradeSafe,
    ReentrancyGuardUpgradeSafe,
    PausableUpgradeSafe,
    ERC20UpgradeSafe,
    IMintable
{
    using SafeMath for uint256;
    uint256 public constant DEFAULT_MAPT_TO_UNDERLYER_FACTOR = 1000;

    /* ------------------------------- */
    /* impl-specific storage variables */
    /* ------------------------------- */
    /// @notice used to protect init functions for upgrades
    address public proxyAdmin;
    /// @notice used to protect mint and burn function
    IAddressRegistryV2 public addressRegistry;

    /* ------------------------------- */

    event Mint(address acccount, uint256 amount);
    event Burn(address acccount, uint256 amount);
    event AdminChanged(address);

    /**
     * @dev Since the proxy delegate calls to this "logic" contract, any
     * storage set by the logic contract's constructor during deploy is
     * disregarded and this function is needed to initialize the proxy
     * contract's storage according to this contract's layout.
     *
     * Since storage is not set yet, there is no simple way to protect
     * calling this function with owner modifiers.  Thus the OpenZeppelin
     * `initializer` modifier protects this function from being called
     * repeatedly.  It should be called during the deployment so that
     * it cannot be called by someone else later.
     */
    function initialize(address adminAddress, address _addressRegistry)
        external
        initializer
    {
        require(adminAddress != address(0), "INVALID_ADMIN");

        // initialize ancestor storage
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained("APY MetaPool Token", "mAPT");

        // initialize impl-specific storage
        setAdminAddress(adminAddress);
        setAddressRegistry(_addressRegistry);
    }

    /**
     * @dev Dummy function to show how one would implement an init function
     * for future upgrades.  Note the `initializer` modifier can only be used
     * once in the entire contract, so we can't use it here.  Instead,
     * we set the proxy admin address as a variable and protect this
     * function with `onlyAdmin`, which only allows the proxy admin
     * to call this function during upgrades.
     */
    // solhint-disable-next-line no-empty-blocks
    function initializeUpgrade() external virtual onlyAdmin {}

    function setAdminAddress(address adminAddress) public onlyOwner {
        require(adminAddress != address(0), "INVALID_ADMIN");
        proxyAdmin = adminAddress;
        emit AdminChanged(adminAddress);
    }

    /**
     * @dev Throws if called by any account other than the proxy admin.
     */
    modifier onlyAdmin() {
        require(msg.sender == proxyAdmin, "ADMIN_ONLY");
        _;
    }

    /**
     * @dev Throws if called by any account other than the PoolManager.
     */
    modifier onlyManager() {
        require(
            msg.sender == addressRegistry.poolManagerAddress(),
            "MANAGER_ONLY"
        );
        _;
    }

    /**
     * @notice Mint specified amount of mAPT to the given account.
     * @dev Only the manager can call this.
     * @param account address to mint to
     * @param amount mint amount
     */
    function mint(address account, uint256 amount)
        public
        override
        nonReentrant
        onlyManager
    {
        require(amount > 0, "INVALID_MINT_AMOUNT");
        IOracleAdapter oracleAdapter = _getOracleAdapter();
        oracleAdapter.lock();
        _mint(account, amount);
        emit Mint(account, amount);
    }

    /**
     * @notice Burn specified amount of mAPT from the given account.
     * @dev Only the manager can call this.
     * @param account address to burn from
     * @param amount burn amount
     */
    function burn(address account, uint256 amount)
        public
        override
        nonReentrant
        onlyManager
    {
        require(amount > 0, "INVALID_BURN_AMOUNT");
        IOracleAdapter oracleAdapter = _getOracleAdapter();
        oracleAdapter.lock();
        _burn(account, amount);
        emit Burn(account, amount);
    }

    /**
     * @notice Get the USD value of all assets in the system, not just those
     *         being managed by the AccountManager but also the pool underlyers.
     *
     *         Note this is NOT the same as the total value represented by the
     *         total mAPT supply, i.e. the "deployed capital".
     *
     * @dev Chainlink nodes read from the TVLManager, pull the
     *      prices from market feeds, and submits the calculated total value
     *      to an aggregator contract.
     *
     *      USD prices have 8 decimals.
     *
     * @return "Total Value Locked", the USD value of all APY Finance assets.
     */
    function getTvl() public view returns (uint256) {
        IOracleAdapter oracleAdapter = _getOracleAdapter();
        return oracleAdapter.getTvl();
    }

    function _getOracleAdapter() internal view returns (IOracleAdapter) {
        address oracleAdapterAddress = addressRegistry.oracleAdapterAddress();
        return IOracleAdapter(oracleAdapterAddress);
    }

    /** @notice Calculate mAPT amount to be minted for given pool's underlyer amount.
     *  @param depositAmount Pool underlyer amount to be converted
     *  @param tokenPrice Pool underlyer's USD price (in wei) per underlyer token
     *  @param decimals Pool underlyer's number of decimals
     *  @dev Price parameter is in units of wei per token ("big" unit), since
     *       attempting to express wei per token bit ("small" unit) will be
     *       fractional, requiring fixed-point representation.  This means we need
     *       to also pass in the underlyer's number of decimals to do the appropriate
     *       multiplication in the calculation.
     */
    function calculateMintAmount(
        uint256 depositAmount,
        uint256 tokenPrice,
        uint256 decimals
    ) public view returns (uint256) {
        uint256 depositValue = depositAmount.mul(tokenPrice).div(10**decimals);
        uint256 totalValue = getTvl();
        return _calculateMintAmount(depositValue, totalValue);
    }

    /**
     *  @dev amount of APT minted should be in same ratio to APT supply
     *       as deposit value is to pool's total value, i.e.:
     *
     *       mint amount / total supply
     *       = deposit value / pool total value
     *
     *       For denominators, pre or post-deposit amounts can be used.
     *       The important thing is they are consistent, i.e. both pre-deposit
     *       or both post-deposit.
     */
    function _calculateMintAmount(uint256 depositValue, uint256 totalValue)
        internal
        view
        returns (uint256)
    {
        uint256 totalSupply = totalSupply();

        if (totalValue == 0 || totalSupply == 0) {
            return depositValue.mul(DEFAULT_MAPT_TO_UNDERLYER_FACTOR);
        }

        return depositValue.mul(totalSupply).div(totalValue);
    }

    /** @notice Calculate amount in pool's underlyer token from given mAPT amount.
     *  @param mAptAmount mAPT amount to be converted
     *  @param tokenPrice Pool underlyer's USD price (in wei) per underlyer token
     *  @param decimals Pool underlyer's number of decimals
     *  @dev Price parameter is in units of wei per token ("big" unit), since
     *       attempting to express wei per token bit ("small" unit) will be
     *       fractional, requiring fixed-point representation.  This means we need
     *       to also pass in the underlyer's number of decimals to do the appropriate
     *       multiplication in the calculation.
     */
    function calculatePoolAmount(
        uint256 mAptAmount,
        uint256 tokenPrice,
        uint256 decimals
    ) public view returns (uint256) {
        if (mAptAmount == 0) return 0;
        require(totalSupply() > 0, "INSUFFICIENT_TOTAL_SUPPLY");
        uint256 poolValue = mAptAmount.mul(getTvl()).div(totalSupply());
        uint256 poolAmount = poolValue.mul(10**decimals).div(tokenPrice);
        return poolAmount;
    }

    /**
     * @notice Get the USD-denominated value (in wei) of the pool's share
     *         of the deployed capital, as tracked by the mAPT token.
     * @return uint256
     */
    function getDeployedValue(address pool) public view returns (uint256) {
        uint256 balance = balanceOf(pool);
        uint256 totalSupply = totalSupply();
        if (totalSupply == 0 || balance == 0) return 0;

        return getTvl().mul(balance).div(totalSupply);
    }

    /**
     * @notice Sets the address registry
     * @dev only callable by owner
     * @param _addressRegistry the address of the registry
     */
    function setAddressRegistry(address _addressRegistry) public onlyOwner {
        require(Address.isContract(_addressRegistry), "INVALID_ADDRESS");
        addressRegistry = IAddressRegistryV2(_addressRegistry);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

interface IMintable {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

interface IOracleAdapter {
    struct Value {
        uint256 value;
        uint256 periodEnd;
    }

    function setTvl(uint256 value, uint256 period) external;

    function setAssetValue(
        address asset,
        uint256 value,
        uint256 period
    ) external;

    function lock() external;

    function defaultLockPeriod() external returns (uint256 period);

    function setDefaultLockPeriod(uint256 period) external;

    function lockFor(uint256 period) external;

    function unlock() external;

    function getAssetPrice(address asset) external view returns (uint256);

    function getTvl() external view returns (uint256);

    function isLocked() external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

import "../PoolTokenV2.sol";

/**
 * @dev Proxy contract to test internal variables and functions
 *      Should not be used other than in test files!
 */
contract TestPoolTokenV2 is PoolTokenV2 {
    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function testMint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function testBurn(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function testTransfer(
        address from,
        address to,
        uint256 amount
    ) public {
        testBurn(from, amount);
        testMint(to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../MetaPoolToken.sol";

contract MetaPoolTokenUpgraded is MetaPoolToken {
    bool public newlyAddedVariable;

    function initializeUpgrade() public override onlyAdmin {
        newlyAddedVariable = true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IAssetAllocation.sol";
import "./interfaces/IAddressRegistryV2.sol";
import "./interfaces/IDetailedERC20.sol";
import "./interfaces/ILpSafeFunder.sol";
import "./interfaces/ITVLManager.sol";
import "./PoolTokenV2.sol";
import "./MetaPoolToken.sol";

/**
 * @title Pool Manager
 * @author APY.Finance
 * @notice The pool manager logic contract for use with the pool manager proxy contract.
 *
 * The Pool Manager orchestrates the movement of capital within the APY system
 * between pools (PoolTokenV2 contracts) and strategy accounts, e.g. LP Safe.
 *
 * Transferring from a PoolToken to an account stages capital in preparation
 * for executing yield farming strategies.
 *
 * Capital is unwound from yield farming strategies for user withdrawals by transferring
 * from accounts to PoolTokens.
 *
 * When funding an account from a pool, the Pool Manager simultaneously register the asset
 * allocation with the TVL Manager to ensure the TVL is properly updated.
 */
contract PoolManager is
    Initializable,
    OwnableUpgradeSafe,
    ReentrancyGuardUpgradeSafe,
    ILpSafeFunder
{
    using SafeMath for uint256;
    using SafeERC20 for IDetailedERC20;

    /* ------------------------------- */
    /* impl-specific storage variables */
    /* ------------------------------- */
    address public proxyAdmin;
    IAddressRegistryV2 public addressRegistry;

    /* ------------------------------- */

    event AdminChanged(address);

    /**
     * @dev Since the proxy delegate calls to this "logic" contract, any
     * storage set by the logic contract's constructor during deploy is
     * disregarded and this function is needed to initialize the proxy
     * contract's storage according to this contract's layout.
     *
     * Since storage is not set yet, there is no simple way to protect
     * calling this function with owner modifiers.  Thus the OpenZeppelin
     * `initializer` modifier protects this function from being called
     * repeatedly.
     *
     * Our proxy deployment will call this as part of the constructor.
     * @param adminAddress the admin proxy to initialize with
     * @param _addressRegistry the address registry to initialize with
     */
    function initialize(address adminAddress, address _addressRegistry)
        external
        initializer
    {
        require(adminAddress != address(0), "INVALID_ADMIN");

        // initialize ancestor storage
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();

        // initialize impl-specific storage
        setAdminAddress(adminAddress);
        setAddressRegistry(_addressRegistry);
    }

    /**
     * @notice Initialize the new logic in V2 when upgrading from V1.
     * @dev The `onlyAdmin` modifier prevents this function from being called
     * multiple times, because the call has to come from the ProxyAdmin contract
     * and it can only call this during its `upgradeAndCall` function.
     *
     * Note the `initializer` modifier can only be used once in the entire
     * contract, so we can't use it here.
     */
    // solhint-disable-next-line no-empty-blocks
    function initializeUpgrade() external virtual onlyAdmin {}

    /**
     * @dev Throws if called by any account other than the proxy admin.
     */
    modifier onlyAdmin() {
        require(msg.sender == proxyAdmin, "ADMIN_ONLY");
        _;
    }

    /**
     * @notice Sets the proxy admin address of the pool manager proxy
     * @dev only callable by owner
     * @param adminAddress the new proxy admin address of the pool manager
     */
    function setAdminAddress(address adminAddress) public onlyOwner {
        require(adminAddress != address(0), "INVALID_ADMIN");
        proxyAdmin = adminAddress;
        emit AdminChanged(adminAddress);
    }

    /**
     * @notice Sets the address registry
     * @dev only callable by owner
     * @param _addressRegistry the address of the registry
     */
    function setAddressRegistry(address _addressRegistry) public onlyOwner {
        require(Address.isContract(_addressRegistry), "INVALID_ADDRESS");
        addressRegistry = IAddressRegistryV2(_addressRegistry);
    }

    /**
     * @notice Funds LP Safe account and register an asset allocation
     * @dev only callable by owner. Also registers the pool underlyer for the account being funded
     * @param poolAmounts a list of PoolAmount structs denoting the pools id and amounts used to fund the account
     * @notice PoolAmount example (pulls ~$1 from each pool to the account):
     *      [
     *          { poolId: "daiPool", amount: "1000000000000" },
     *          { poolId: "usdcPool", amount: "1000000" },
     *          { poolId: "usdtPool", amount: "1000000" },
     *      ]
     */
    function fundLpSafe(ILpSafeFunder.PoolAmount[] memory poolAmounts)
        external
        override
        onlyOwner
        nonReentrant
    {
        address lpSafeAddress = addressRegistry.lpSafeAddress();
        require(lpSafeAddress != address(0), "INVALID_LP_SAFE");
        (PoolTokenV2[] memory pools, uint256[] memory amounts) =
            _getPoolsAndAmounts(poolAmounts);
        _fund(lpSafeAddress, pools, amounts);
        _registerPoolUnderlyers(lpSafeAddress, pools);
    }

    function _getPoolsAndAmounts(ILpSafeFunder.PoolAmount[] memory poolAmounts)
        internal
        view
        returns (PoolTokenV2[] memory, uint256[] memory)
    {
        PoolTokenV2[] memory pools = new PoolTokenV2[](poolAmounts.length);
        uint256[] memory amounts = new uint256[](poolAmounts.length);
        for (uint256 i = 0; i < poolAmounts.length; i++) {
            amounts[i] = poolAmounts[i].amount;
            pools[i] = PoolTokenV2(
                addressRegistry.getAddress(poolAmounts[i].poolId)
            );
        }
        return (pools, amounts);
    }

    /**
     * @notice Register an asset allocation for the account with each pool underlyer
     * @param account address of the registered account
     * @param pools list of pools whose underlyers will be registered
     */
    function _registerPoolUnderlyers(
        address account,
        PoolTokenV2[] memory pools
    ) internal {
        ITVLManager tvlManager =
            ITVLManager(addressRegistry.getAddress("tvlManager"));
        for (uint256 i = 0; i < pools.length; i++) {
            PoolTokenV2 pool = pools[i];
            IDetailedERC20 underlyer = pool.underlyer();
            string memory symbol = underlyer.symbol();
            bytes memory _data =
                abi.encodeWithSignature("balanceOf(address)", account);
            ITVLManager.Data memory data =
                ITVLManager.Data(address(pool.underlyer()), _data);
            if (!tvlManager.isAssetAllocationRegistered(data)) {
                tvlManager.addAssetAllocation(
                    data,
                    symbol,
                    underlyer.decimals()
                );
            }
        }
    }

    /**
     * @notice Helper function move capital from PoolToken contracts to an account
     * @param account the address to move funds to
     * @param pools a list of pools to pull funds from
     * @param amounts a list of fund amounts to pull from pools
     */
    function _fund(
        address account,
        PoolTokenV2[] memory pools,
        uint256[] memory amounts
    ) internal {
        MetaPoolToken mApt = MetaPoolToken(addressRegistry.mAptAddress());
        uint256[] memory mintAmounts = new uint256[](pools.length);
        for (uint256 i = 0; i < pools.length; i++) {
            PoolTokenV2 pool = pools[i];
            uint256 poolAmount = amounts[i];
            require(poolAmount > 0, "INVALID_AMOUNT");
            IDetailedERC20 underlyer = pool.underlyer();

            uint256 tokenPrice = pool.getUnderlyerPrice();
            uint8 decimals = underlyer.decimals();
            uint256 mintAmount =
                mApt.calculateMintAmount(poolAmount, tokenPrice, decimals);
            mintAmounts[i] = mintAmount;

            underlyer.safeTransferFrom(address(pool), account, poolAmount);
        }
        // MUST do the actual minting after calculating *all* mint amounts,
        // otherwise due to Chainlink not updating during a transaction,
        // the totalSupply will change while TVL doesn't.
        //
        // Using the pre-mint TVL and totalSupply gives the same answer
        // as using post-mint values.
        for (uint256 i = 0; i < pools.length; i++) {
            mApt.mint(address(pools[i]), mintAmounts[i]);
        }
    }

    /**
     * @notice Moves capital from LP Safe account to the PoolToken contracts
     * @dev only callable by owner
     * @param poolAmounts list of PoolAmount structs denoting pool IDs and pool deposit amounts
     * @notice PoolAmount example (pushes ~$1 to each pool from the account):
     *      [
     *          { poolId: "daiPool", amount: "1000000000000" },
     *          { poolId: "usdcPool", amount: "1000000" },
     *          { poolId: "usdtPool", amount: "1000000" },
     *      ]
     */
    function withdrawFromLpSafe(ILpSafeFunder.PoolAmount[] memory poolAmounts)
        external
        override
        onlyOwner
        nonReentrant
    {
        address lpSafeAddress = addressRegistry.lpSafeAddress();
        require(lpSafeAddress != address(0), "INVALID_LP_SAFE");
        (PoolTokenV2[] memory pools, uint256[] memory amounts) =
            _getPoolsAndAmounts(poolAmounts);
        _checkManagerAllowances(lpSafeAddress, pools, amounts);
        _withdraw(lpSafeAddress, pools, amounts);
    }

    /**
     * @notice Check if pool manager has sufficient allowance to transfer pool underlyer from account
     * @param account the address of the account to check
     * @param pools list of pools to transfer funds to; used for retrieving the underlyer
     * @param amounts list of required minimal allowances needed by the manager
     */
    function _checkManagerAllowances(
        address account,
        PoolTokenV2[] memory pools,
        uint256[] memory amounts
    ) internal view {
        for (uint256 i = 0; i < pools.length; i++) {
            IDetailedERC20 underlyer = pools[i].underlyer();
            uint256 allowance = underlyer.allowance(account, address(this));
            require(amounts[i] <= allowance, "INSUFFICIENT_ALLOWANCE");
        }
    }

    /**
     * @notice Move capital from an account back to the PoolToken contracts
     * @param account account that funds are being withdrawn from
     * @param pools a list of pools to place recovered funds back into
     * @param amounts a list of amounts to send from the account to the pools
     *
     */
    function _withdraw(
        address account,
        PoolTokenV2[] memory pools,
        uint256[] memory amounts
    ) internal {
        MetaPoolToken mApt = MetaPoolToken(addressRegistry.mAptAddress());
        uint256[] memory burnAmounts = new uint256[](pools.length);
        for (uint256 i = 0; i < pools.length; i++) {
            PoolTokenV2 pool = pools[i];
            uint256 amountToSend = amounts[i];
            require(amountToSend > 0, "INVALID_AMOUNT");
            IDetailedERC20 underlyer = pool.underlyer();

            uint256 tokenPrice = pool.getUnderlyerPrice();
            uint8 decimals = underlyer.decimals();
            uint256 burnAmount =
                mApt.calculateMintAmount(amountToSend, tokenPrice, decimals);
            burnAmounts[i] = burnAmount;

            underlyer.safeTransferFrom(account, address(pool), amountToSend);
        }
        // MUST do the actual burning after calculating *all* burn amounts,
        // otherwise due to Chainlink not updating during a transaction,
        // the totalSupply will change while TVL doesn't.
        //
        // Using the pre-burn TVL and totalSupply gives the same answer
        // as using post-burn values.
        for (uint256 i = 0; i < pools.length; i++) {
            mApt.burn(address(pools[i]), burnAmounts[i]);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

/// @title Interface to Access APY.Finance's Asset Allocations
/// @author APY.Finance
/// @notice Enables 3rd Parties (ie. Chainlink) to pull relevant asset allocations
/// in order to compute the TVL across the entire APY.Finance system.
interface IAssetAllocation {
    /// @notice Returns a list of all identifiers where asset allocations have been registered
    /// @dev the list contains no duplicate identifiers
    /// @return list of all the registered identifiers
    function getAssetAllocationIds() external view returns (bytes32[] memory);

    /// @notice Executes the bytes lookup data registered under an id
    /// @dev The balance of an id may be aggregated from multiple contracts
    /// @param allocationId the id to fetch the balance for
    /// @return returns the result of the executed lookup data registered for the provided id
    function balanceOf(bytes32 allocationId) external view returns (uint256);

    /// @notice Returns the token symbol registered under an id
    /// @param allocationId the id to fetch the token for
    /// @return returns the result of the token symbol registered for the provided id
    function symbolOf(bytes32 allocationId)
        external
        view
        returns (string memory);

    /// @notice Returns the decimals registered under an id
    /// @param allocationId the id to fetch the decimals for
    /// @return returns the result of the decimal value registered for the provided id
    function decimalsOf(bytes32 allocationId) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface ILpSafeFunder {
    // struct representing the pool and the amount to move when funding an account
    // poolId represents the pool to move funds from
    // amount represents the amount to move when funding
    struct PoolAmount {
        bytes32 poolId;
        uint256 amount;
    }

    function fundLpSafe(PoolAmount[] calldata poolAmounts) external;

    function withdrawFromLpSafe(PoolAmount[] calldata poolAmounts) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

/**
 * @title Interface for addition and removal of asset allocations
          for account deployments
 * @author APY.Finance
 * @notice These functions enable external systems to pull necessary info
 *         to compute the TVL of the APY.Finance system.
 */
interface ITVLManager {
    // struct representing a view call execution against a target contract given bytes
    // target is the target contract to execute view calls against
    // bytes data represents the encoded function signature + parameters
    struct Data {
        address target;
        bytes data;
    }

    // struct representing the relevant pieces of data that need to be provided when registering an asset allocation
    // symbol is the symbol of the token that the resulting view call execution will need to be evaluated as
    // decimals is the number of decimals that the resulting view call execution will need to be evaluated as
    // data is the struct representing the view call execution
    struct AssetAllocation {
        string symbol;
        uint256 decimals;
        Data data;
    }

    function addAssetAllocation(
        Data calldata data,
        string calldata symbol,
        uint256 decimals
    ) external;

    function removeAssetAllocation(Data calldata data) external;

    function generateDataHash(Data calldata data)
        external
        pure
        returns (bytes32);

    function isAssetAllocationRegistered(Data calldata data)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../PoolManager.sol";

contract PoolManagerUpgraded is PoolManager {
    bool public newlyAddedVariable;

    function initializeUpgrade() public override onlyAdmin {
        newlyAddedVariable = true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./utils/EnumerableSet.sol";
import "./interfaces/IAssetAllocation.sol";
import "./interfaces/ITVLManager.sol";
import "./interfaces/IOracleAdapter.sol";
import "./interfaces/IAddressRegistryV2.sol";

/// @title TVL Manager
/// @author APY.Finance
/// @notice Deployed assets can exist across various platforms within the
/// defi ecosystem: pools, accounts, defi protocols, etc. This contract
/// tracks deployed capital by registering the look up functions so that
/// the TVL can be properly computed.
/// @dev It is imperative that this manager has the most up to date asset
/// allocations registered. Any assets in the system that have been deployed,
/// but are not registered can have devastating and catastrophic effects on the TVL.
contract TVLManager is Ownable, ReentrancyGuard, ITVLManager, IAssetAllocation {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using Address for address;

    IAddressRegistryV2 public addressRegistry;

    // all registered allocation ids
    EnumerableSet.Bytes32Set private _allocationIds;
    // ids mapped to data
    mapping(bytes32 => Data) private _allocationData;
    // ids mapped to symbol
    mapping(bytes32 => string) private _allocationSymbols;
    // ids mapped to decimals
    mapping(bytes32 => uint256) private _allocationDecimals;

    /// @notice Constructor TVLManager
    /// @param _addressRegistry the address registry to initialize with
    constructor(address _addressRegistry) public {
        setAddressRegistry(_addressRegistry);
    }

    /// @dev Reverts if non-permissed account calls.
    /// Permissioned accounts are: owner, pool manager, and account manager
    modifier onlyPermissioned() {
        require(
            msg.sender == owner() ||
                msg.sender == addressRegistry.poolManagerAddress() ||
                msg.sender == addressRegistry.lpSafeAddress(),
            "PERMISSIONED_ONLY"
        );
        _;
    }

    function lockOracleAdapter() internal {
        IOracleAdapter oracleAdapter =
            IOracleAdapter(addressRegistry.oracleAdapterAddress());
        oracleAdapter.lock();
    }

    /// @notice Registers a new asset allocation
    /// @dev only permissed accounts can call.
    /// New ids are uniquely determined by the provided data struct; no duplicates are allowed
    /// @param data the data struct containing the target address and the bytes lookup data that will be registered
    /// @param symbol the token symbol to register for the asset allocation
    /// @param decimals the decimals to register for the new asset allocation
    function addAssetAllocation(
        Data memory data,
        string calldata symbol,
        uint256 decimals
    ) external override nonReentrant onlyPermissioned {
        require(!isAssetAllocationRegistered(data), "DUPLICATE_DATA_DETECTED");
        bytes32 dataHash = generateDataHash(data);
        _allocationIds.add(dataHash);
        _allocationData[dataHash] = data;
        _allocationSymbols[dataHash] = symbol;
        _allocationDecimals[dataHash] = decimals;
        lockOracleAdapter();
    }

    /// @notice Removes an existing asset allocation
    /// @dev only permissed accounts can call.
    /// @param data the data struct containing the target address and bytes lookup data that will be removed
    function removeAssetAllocation(Data memory data)
        external
        override
        nonReentrant
        onlyPermissioned
    {
        require(isAssetAllocationRegistered(data), "ALLOCATION_DOES_NOT_EXIST");
        bytes32 dataHash = generateDataHash(data);
        _allocationIds.remove(dataHash);
        delete _allocationData[dataHash];
        delete _allocationSymbols[dataHash];
        delete _allocationDecimals[dataHash];
        lockOracleAdapter();
    }

    /// @notice Generates a data hash used for uniquely identifying asset allocations
    /// @param data the data hash containing the target address and the bytes lookup data
    /// @return returns the resulting bytes32 hash of the abi encode packed target address and bytes look up data
    function generateDataHash(Data memory data)
        public
        pure
        override
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(data.target, data.data));
    }

    /// @notice determines if a target address and bytes lookup data has already been registered
    /// @param data the data hash containing the target address and the bytes lookup data
    /// @return returns true if the asset allocation is currently registered, otherwise false
    function isAssetAllocationRegistered(Data memory data)
        public
        view
        override
        returns (bool)
    {
        return _isAssetAllocationRegistered(generateDataHash(data));
    }

    /// @notice helper function for isAssetallocationRegistered function
    /// @param data the bytes32 hash
    /// @return returns true if the asset allocation is currently registered, otherwise false
    function _isAssetAllocationRegistered(bytes32 data)
        public
        view
        returns (bool)
    {
        return _allocationIds.contains(data);
    }

    /// @notice Returns a list of all identifiers where asset allocations have been registered
    /// @dev the list contains no duplicate identifiers
    /// @return list of all the registered identifiers
    function getAssetAllocationIds()
        external
        view
        override
        returns (bytes32[] memory)
    {
        uint256 length = _allocationIds.length();
        bytes32[] memory allocationIds = new bytes32[](length);
        for (uint256 i = 0; i < length; i++) {
            allocationIds[i] = _allocationIds.at(i);
        }
        return allocationIds;
    }

    /// @notice Executes the bytes lookup data registered under an id
    /// @dev The balance of an id may be aggregated from multiple contracts
    /// @param allocationId the id to fetch the balance for
    /// @return returns the result of the executed lookup data registered for the provided id
    function balanceOf(bytes32 allocationId)
        external
        view
        override
        returns (uint256)
    {
        require(
            _isAssetAllocationRegistered(allocationId),
            "INVALID_ALLOCATION_ID"
        );
        Data memory data = _allocationData[allocationId];
        bytes memory returnData = executeView(data);

        uint256 _balance;
        assembly {
            _balance := mload(add(returnData, 0x20))
        }

        return _balance;
    }

    /// @notice Returns the token symbol registered under an id
    /// @param allocationId the id to fetch the token for
    /// @return returns the result of the token symbol registered for the provided id
    function symbolOf(bytes32 allocationId)
        external
        view
        override
        returns (string memory)
    {
        return _allocationSymbols[allocationId];
    }

    /// @notice Returns the decimals registered under an id
    /// @param allocationId the id to fetch the decimals for
    /// @return returns the result of the decimal value registered for the provided id
    function decimalsOf(bytes32 allocationId)
        external
        view
        override
        returns (uint256)
    {
        return _allocationDecimals[allocationId];
    }

    /// @notice Executes data's bytes look up data against data's target address
    /// @dev execution is a static call
    /// @param data the data hash containing the target address and the bytes lookup data to execute
    /// @return returnData returns return data from the executed contract
    function executeView(Data memory data)
        public
        view
        returns (bytes memory returnData)
    {
        returnData = data.target.functionStaticCall(data.data);
    }

    /**
     * @notice Sets the address registry
     * @dev only callable by owner
     * @param _addressRegistry the address of the registry
     */
    function setAddressRegistry(address _addressRegistry) public onlyOwner {
        require(Address.isContract(_addressRegistry), "INVALID_ADDRESS");
        addressRegistry = IAddressRegistryV2(_addressRegistry);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */

/* solhint-disable */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IOracleAdapter.sol";
import "./interfaces/IAddressRegistryV2.sol";

/**
 * @title Oracle Adapter
 * @author APY.Finance
 * @notice Acts as a gateway to oracle values and implements oracle safeguards.
 *
 * Oracle Safeguard Flows:
 *
 *      - Unlocked → No Manual Submitted Value → Use Chainlink Value (default)
 *      - Unlocked → No Manual Submitted Value → No Chainlink Source → Reverts
 *      - Unlocked → No Manual Submitted Value → Chainlink Value Call Reverts → Reverts
 *      - Unlocked → No Manual Submitted Value → Chainlink Value > 24 hours → Reverts
 *      - Unlocked → Use Manual Submitted Value (emergency)
 *      - Locked → Reverts (nominal)
 *
 * @dev It is important to not that zero values are allowed for manual
 * submission, but will result in a revert for Chainlink.
 *
 * This is because there are very rare situations where the TVL value can
 * accurately be zero, such as a situation where all funds are unwound and
 * moved back to the liquidity pools, but a zero value can also indicate a
 * failure with Chainlink.
 *
 * Because accurate zero values are rare, and occur due to intentional system
 * states where no funds are deployed, they due not need to be detected
 * automatically by Chainlink.
 *
 * In addition, the impact of failing to manually set a zero value when
 * necessary compared to the impact of an incorrect zero value from Chainlink
 * is much lower.
 *
 * Failing to manually set a zero value can result in either a locked contract,
 * which can be unlocked by setting the value, or reduced deposit/withdraw
 * amounts. But never a loss of funds.
 *
 * Conversely, if Chainlink reports a zero value in error and the contract
 * were to accept it, funds up to the amount available in the reserve pools
 * could be lost.
 */
contract OracleAdapter is Ownable, IOracleAdapter {
    using SafeMath for uint256;
    using Address for address;

    IAddressRegistryV2 public addressRegistry;

    uint256 public override defaultLockPeriod;
    /// @notice Contract is locked until this block number is passed
    uint256 public lockEnd;

    /// @notice Chainlink variables
    uint256 public chainlinkStalePeriod; // Duration of Chainlink heartbeat
    AggregatorV3Interface public tvlSource;
    mapping(address => AggregatorV3Interface) public assetSources;

    /// @notice Submitted values that override Chainlink values until stale
    mapping(address => Value) public submittedAssetValues;
    Value public submittedTvlValue;

    event AssetSourceUpdated(address indexed asset, address indexed source);
    event TvlSourceUpdated(address indexed source);
    event ChainlinkStalePeriodUpdated(uint256 period);

    modifier unlocked() {
        require(!isLocked(), "ORACLE_LOCKED");
        _;
    }

    modifier locked() {
        require(isLocked(), "ORACLE_UNLOCKED");
        _;
    }

    /// @dev Reverts if non-permissioned account calls.
    /// Permissioned accounts are: owner, mAPT, and TVL manager
    modifier onlyPermissioned() {
        require(
            msg.sender == owner() ||
                msg.sender == addressRegistry.mAptAddress() ||
                msg.sender == addressRegistry.tvlManagerAddress(),
            "PERMISSIONED_ONLY"
        );
        _;
    }

    /**
     * @notice Constructor
     * @param _addressRegistry the address registry
     * @param assets the assets priced by sources
     * @param sources the source for each asset
     * @param tvlSource the source for the TVL value
     * @param _chainlinkStalePeriod the number of seconds until a source value is stale
     */
    constructor(
        address _addressRegistry,
        address tvlSource,
        address[] memory assets,
        address[] memory sources,
        uint256 _chainlinkStalePeriod,
        uint256 _defaultLockPeriod
    ) public {
        setAddressRegistry(_addressRegistry);
        setTvlSource(tvlSource);
        setAssetSources(assets, sources);
        setChainlinkStalePeriod(_chainlinkStalePeriod);
        setDefaultLockPeriod(_defaultLockPeriod);
    }

    function setDefaultLockPeriod(uint256 newPeriod) public override onlyOwner {
        defaultLockPeriod = newPeriod;
    }

    function lock() external override onlyPermissioned {
        lockFor(defaultLockPeriod);
    }

    function unlock() external override onlyPermissioned {
        lockFor(0);
    }

    function lockFor(uint256 activePeriod) public override onlyPermissioned {
        lockEnd = block.number.add(activePeriod);
    }

    /**
     * @notice Sets the address registry
     * @dev only callable by owner
     * @param _addressRegistry the address of the registry
     */
    function setAddressRegistry(address _addressRegistry) public onlyOwner {
        require(Address.isContract(_addressRegistry), "INVALID_ADDRESS");
        addressRegistry = IAddressRegistryV2(_addressRegistry);
    }

    //------------------------------------------------------------
    // MANUAL SUBMISSION SETTERS
    //------------------------------------------------------------

    function setAssetValue(
        address asset,
        uint256 value,
        uint256 period
    ) external override locked onlyOwner {
        // We do allow 0 values for submitted values
        submittedAssetValues[asset] = Value(value, block.number.add(period));
    }

    function setTvl(uint256 value, uint256 period)
        external
        override
        locked
        onlyOwner
    {
        // We do allow 0 values for submitted values
        submittedTvlValue = Value(value, block.number.add(period));
    }

    //------------------------------------------------------------
    // CHAINLINK SETTERS
    //------------------------------------------------------------

    /**
     * @notice Set or replace the TVL source
     * @param source the TVL source address
     */
    function setTvlSource(address source) public onlyOwner {
        require(source.isContract(), "INVALID_SOURCE");
        tvlSource = AggregatorV3Interface(source);
        emit TvlSourceUpdated(source);
    }

    /**
     * @notice Set or replace asset price sources
     * @param assets the array of assets token addresses
     * @param sources the array of price sources (aggregators)
     */
    function setAssetSources(address[] memory assets, address[] memory sources)
        public
        onlyOwner
    {
        require(assets.length == sources.length, "INCONSISTENT_PARAMS_LENGTH");
        for (uint256 i = 0; i < assets.length; i++) {
            setAssetSource(assets[i], sources[i]);
        }
    }

    /**
     * @notice Set a single asset price source
     * @param asset asset token address
     * @param source the price source (aggregator)
     */
    function setAssetSource(address asset, address source) public onlyOwner {
        require(source.isContract(), "INVALID_SOURCE");
        assetSources[asset] = AggregatorV3Interface(source);
        emit AssetSourceUpdated(asset, source);
    }

    /**
     * @notice Set the length of time before an agg value is considered stale
     * @param _chainlinkStalePeriod the length of time in seconds
     */
    function setChainlinkStalePeriod(uint256 _chainlinkStalePeriod)
        public
        onlyOwner
    {
        require(_chainlinkStalePeriod > 0, "INVALID_STALE_PERIOD");
        chainlinkStalePeriod = _chainlinkStalePeriod;
        emit ChainlinkStalePeriodUpdated(_chainlinkStalePeriod);
    }

    function isLocked() public view override returns (bool) {
        return block.number < lockEnd;
    }

    //------------------------------------------------------------
    // ORACLE VALUE GETTERS
    //------------------------------------------------------------

    function getTvl() external view override unlocked returns (uint256) {
        if (block.number < submittedTvlValue.periodEnd) {
            return submittedTvlValue.value;
        }
        return _getPriceFromSource(tvlSource);
    }

    /**
     * @notice Gets an asset price by address
     * @param asset the asset address
     * @return the asset price
     */
    function getAssetPrice(address asset)
        public
        view
        override
        unlocked
        returns (uint256)
    {
        if (block.number < submittedAssetValues[asset].periodEnd) {
            return submittedAssetValues[asset].value;
        }
        AggregatorV3Interface source = assetSources[asset];
        return _getPriceFromSource(source);
    }

    /**
     * @notice Get the price from a source (aggregator)
     * @dev Prices and TVL values should always be positive
     * @return the price from the source
     */
    function _getPriceFromSource(AggregatorV3Interface source)
        internal
        view
        returns (uint256)
    {
        require(address(source).isContract(), "INVALID_SOURCE");
        (, int256 price, , uint256 updatedAt, ) = source.latestRoundData();

        //we do not allow 0 values for chainlink
        require(price > 0, "MISSING_ASSET_VALUE");

        // solhint-disable not-rely-on-time
        require(
            block.timestamp.sub(updatedAt) <= chainlinkStalePeriod,
            "CHAINLINK_STALE_DATA"
        );
        // solhint-enable not-rely-on-time

        return uint256(price);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity >=0.6.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

pragma solidity >=0.6.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

/**
SPDX-License-Identifier: UNLICENSED
----------------------------------
---- APY.Finance comments --------
----------------------------------

Due to pragma being fixed at 0.6.6, we had to copy over this contract
and fix the imports.

original path: @chainlink/contracts/src/v0.6/FluxAggregator.sol
npm package version: 0.0.9
 */
pragma solidity 0.6.11;

import "@chainlink/contracts/src/v0.6/Median.sol";
import "@chainlink/contracts/src/v0.6/Owned.sol";
import "@chainlink/contracts/src/v0.6/SafeMath128.sol";
import "@chainlink/contracts/src/v0.6/SafeMath32.sol";
import "@chainlink/contracts/src/v0.6/SafeMath64.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV2V3Interface.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorValidatorInterface.sol";
import "@chainlink/contracts/src/v0.6/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMath.sol";

/* solhint-disable */
/**
 * @title The Prepaid Aggregator contract
 * @notice Handles aggregating data pushed in from off-chain, and unlocks
 * payment for oracles as they report. Oracles' submissions are gathered in
 * rounds, with each round aggregating the submissions for each oracle into a
 * single answer. The latest aggregated answer is exposed as well as historical
 * answers and their updated at timestamp.
 */
contract FluxAggregator is AggregatorV2V3Interface, Owned {
    using SafeMath for uint256;
    using SafeMath128 for uint128;
    using SafeMath64 for uint64;
    using SafeMath32 for uint32;

    struct Round {
        int256 answer;
        uint64 startedAt;
        uint64 updatedAt;
        uint32 answeredInRound;
    }

    struct RoundDetails {
        int256[] submissions;
        uint32 maxSubmissions;
        uint32 minSubmissions;
        uint32 timeout;
        uint128 paymentAmount;
    }

    struct OracleStatus {
        uint128 withdrawable;
        uint32 startingRound;
        uint32 endingRound;
        uint32 lastReportedRound;
        uint32 lastStartedRound;
        int256 latestSubmission;
        uint16 index;
        address admin;
        address pendingAdmin;
    }

    struct Requester {
        bool authorized;
        uint32 delay;
        uint32 lastStartedRound;
    }

    struct Funds {
        uint128 available;
        uint128 allocated;
    }

    LinkTokenInterface public linkToken;
    AggregatorValidatorInterface public validator;

    // Round related params
    uint128 public paymentAmount;
    uint32 public maxSubmissionCount;
    uint32 public minSubmissionCount;
    uint32 public restartDelay;
    uint32 public timeout;
    uint8 public override decimals;
    string public override description;

    int256 public immutable minSubmissionValue;
    int256 public immutable maxSubmissionValue;

    uint256 public constant override version = 3;

    /**
     * @notice To ensure owner isn't withdrawing required funds as oracles are
     * submitting updates, we enforce that the contract maintains a minimum
     * reserve of RESERVE_ROUNDS * oracleCount() LINK earmarked for payment to
     * oracles. (Of course, this doesn't prevent the contract from running out of
     * funds without the owner's intervention.)
     */
    uint256 private constant RESERVE_ROUNDS = 2;
    uint256 private constant MAX_ORACLE_COUNT = 77;
    uint32 private constant ROUND_MAX = 2**32 - 1;
    uint256 private constant VALIDATOR_GAS_LIMIT = 100000;
    // An error specific to the Aggregator V3 Interface, to prevent possible
    // confusion around accidentally reading unset values as reported values.
    string private constant V3_NO_DATA_ERROR = "No data present";

    uint32 private reportingRoundId;
    uint32 internal latestRoundId;
    mapping(address => OracleStatus) private oracles;
    mapping(uint32 => Round) internal rounds;
    mapping(uint32 => RoundDetails) internal details;
    mapping(address => Requester) internal requesters;
    address[] private oracleAddresses;
    Funds private recordedFunds;

    event AvailableFundsUpdated(uint256 indexed amount);
    event RoundDetailsUpdated(
        uint128 indexed paymentAmount,
        uint32 indexed minSubmissionCount,
        uint32 indexed maxSubmissionCount,
        uint32 restartDelay,
        uint32 timeout // measured in seconds
    );
    event OraclePermissionsUpdated(
        address indexed oracle,
        bool indexed whitelisted
    );
    event OracleAdminUpdated(address indexed oracle, address indexed newAdmin);
    event OracleAdminUpdateRequested(
        address indexed oracle,
        address admin,
        address newAdmin
    );
    event SubmissionReceived(
        int256 indexed submission,
        uint32 indexed round,
        address indexed oracle
    );
    event RequesterPermissionsSet(
        address indexed requester,
        bool authorized,
        uint32 delay
    );
    event ValidatorUpdated(address indexed previous, address indexed current);

    /**
     * @notice set up the aggregator with initial configuration
     * @param _link The address of the LINK token
     * @param _paymentAmount The amount paid of LINK paid to each oracle per submission, in wei (units of 10⁻¹⁸ LINK)
     * @param _timeout is the number of seconds after the previous round that are
     * allowed to lapse before allowing an oracle to skip an unfinished round
     * @param _validator is an optional contract address for validating
     * external validation of answers
     * @param _minSubmissionValue is an immutable check for a lower bound of what
     * submission values are accepted from an oracle
     * @param _maxSubmissionValue is an immutable check for an upper bound of what
     * submission values are accepted from an oracle
     * @param _decimals represents the number of decimals to offset the answer by
     * @param _description a short description of what is being reported
     */
    constructor(
        address _link,
        uint128 _paymentAmount,
        uint32 _timeout,
        address _validator,
        int256 _minSubmissionValue,
        int256 _maxSubmissionValue,
        uint8 _decimals,
        string memory _description
    ) public {
        linkToken = LinkTokenInterface(_link);
        updateFutureRounds(_paymentAmount, 0, 0, 0, _timeout);
        setValidator(_validator);
        minSubmissionValue = _minSubmissionValue;
        maxSubmissionValue = _maxSubmissionValue;
        decimals = _decimals;
        description = _description;
        rounds[0].updatedAt = uint64(block.timestamp.sub(uint256(_timeout)));
    }

    /**
     * @notice called by oracles when they have witnessed a need to update
     * @param _roundId is the ID of the round this submission pertains to
     * @param _submission is the updated data that the oracle is submitting
     */
    function submit(uint256 _roundId, int256 _submission) external {
        bytes memory error = validateOracleRound(msg.sender, uint32(_roundId));
        require(
            _submission >= minSubmissionValue,
            "value below minSubmissionValue"
        );
        require(
            _submission <= maxSubmissionValue,
            "value above maxSubmissionValue"
        );
        require(error.length == 0, string(error));

        oracleInitializeNewRound(uint32(_roundId));
        recordSubmission(_submission, uint32(_roundId));
        (bool updated, int256 newAnswer) = updateRoundAnswer(uint32(_roundId));
        payOracle(uint32(_roundId));
        deleteRoundDetails(uint32(_roundId));
        if (updated) {
            validateAnswer(uint32(_roundId), newAnswer);
        }
    }

    /**
     * @notice called by the owner to remove and add new oracles as well as
     * update the round related parameters that pertain to total oracle count
     * @param _removed is the list of addresses for the new Oracles being removed
     * @param _added is the list of addresses for the new Oracles being added
     * @param _addedAdmins is the admin addresses for the new respective _added
     * list. Only this address is allowed to access the respective oracle's funds
     * @param _minSubmissions is the new minimum submission count for each round
     * @param _maxSubmissions is the new maximum submission count for each round
     * @param _restartDelay is the number of rounds an Oracle has to wait before
     * they can initiate a round
     */
    function changeOracles(
        address[] calldata _removed,
        address[] calldata _added,
        address[] calldata _addedAdmins,
        uint32 _minSubmissions,
        uint32 _maxSubmissions,
        uint32 _restartDelay
    ) external onlyOwner() {
        for (uint256 i = 0; i < _removed.length; i++) {
            removeOracle(_removed[i]);
        }

        require(
            _added.length == _addedAdmins.length,
            "need same oracle and admin count"
        );
        require(
            uint256(oracleCount()).add(_added.length) <= MAX_ORACLE_COUNT,
            "max oracles allowed"
        );

        for (uint256 i = 0; i < _added.length; i++) {
            addOracle(_added[i], _addedAdmins[i]);
        }

        updateFutureRounds(
            paymentAmount,
            _minSubmissions,
            _maxSubmissions,
            _restartDelay,
            timeout
        );
    }

    /**
     * @notice update the round and payment related parameters for subsequent
     * rounds
     * @param _paymentAmount is the payment amount for subsequent rounds
     * @param _minSubmissions is the new minimum submission count for each round
     * @param _maxSubmissions is the new maximum submission count for each round
     * @param _restartDelay is the number of rounds an Oracle has to wait before
     * they can initiate a round
     */
    function updateFutureRounds(
        uint128 _paymentAmount,
        uint32 _minSubmissions,
        uint32 _maxSubmissions,
        uint32 _restartDelay,
        uint32 _timeout
    ) public onlyOwner() {
        uint32 oracleNum = oracleCount(); // Save on storage reads
        require(
            _maxSubmissions >= _minSubmissions,
            "max must equal/exceed min"
        );
        require(oracleNum >= _maxSubmissions, "max cannot exceed total");
        require(
            oracleNum == 0 || oracleNum > _restartDelay,
            "delay cannot exceed total"
        );
        require(
            recordedFunds.available >= requiredReserve(_paymentAmount),
            "insufficient funds for payment"
        );
        if (oracleCount() > 0) {
            require(_minSubmissions > 0, "min must be greater than 0");
        }

        paymentAmount = _paymentAmount;
        minSubmissionCount = _minSubmissions;
        maxSubmissionCount = _maxSubmissions;
        restartDelay = _restartDelay;
        timeout = _timeout;

        emit RoundDetailsUpdated(
            paymentAmount,
            _minSubmissions,
            _maxSubmissions,
            _restartDelay,
            _timeout
        );
    }

    /**
     * @notice the amount of payment yet to be withdrawn by oracles
     */
    function allocatedFunds() external view returns (uint128) {
        return recordedFunds.allocated;
    }

    /**
     * @notice the amount of future funding available to oracles
     */
    function availableFunds() external view returns (uint128) {
        return recordedFunds.available;
    }

    /**
     * @notice recalculate the amount of LINK available for payouts
     */
    function updateAvailableFunds() public {
        Funds memory funds = recordedFunds;

        uint256 nowAvailable =
            linkToken.balanceOf(address(this)).sub(funds.allocated);

        if (funds.available != nowAvailable) {
            recordedFunds.available = uint128(nowAvailable);
            emit AvailableFundsUpdated(nowAvailable);
        }
    }

    /**
     * @notice returns the number of oracles
     */
    function oracleCount() public view returns (uint8) {
        return uint8(oracleAddresses.length);
    }

    /**
     * @notice returns an array of addresses containing the oracles on contract
     */
    function getOracles() external view returns (address[] memory) {
        return oracleAddresses;
    }

    /**
     * @notice get the most recently reported answer
     *
     * @dev #[deprecated] Use latestRoundData instead. This does not error if no
     * answer has been reached, it will simply return 0. Either wait to point to
     * an already answered Aggregator or use the recommended latestRoundData
     * instead which includes better verification information.
     */
    function latestAnswer() public view virtual override returns (int256) {
        return rounds[latestRoundId].answer;
    }

    /**
     * @notice get the most recent updated at timestamp
     *
     * @dev #[deprecated] Use latestRoundData instead. This does not error if no
     * answer has been reached, it will simply return 0. Either wait to point to
     * an already answered Aggregator or use the recommended latestRoundData
     * instead which includes better verification information.
     */
    function latestTimestamp() public view virtual override returns (uint256) {
        return rounds[latestRoundId].updatedAt;
    }

    /**
     * @notice get the ID of the last updated round
     *
     * @dev #[deprecated] Use latestRoundData instead. This does not error if no
     * answer has been reached, it will simply return 0. Either wait to point to
     * an already answered Aggregator or use the recommended latestRoundData
     * instead which includes better verification information.
     */
    function latestRound() public view virtual override returns (uint256) {
        return latestRoundId;
    }

    /**
     * @notice get past rounds answers
     * @param _roundId the round number to retrieve the answer for
     *
     * @dev #[deprecated] Use getRoundData instead. This does not error if no
     * answer has been reached, it will simply return 0. Either wait to point to
     * an already answered Aggregator or use the recommended getRoundData
     * instead which includes better verification information.
     */
    function getAnswer(uint256 _roundId)
        public
        view
        virtual
        override
        returns (int256)
    {
        if (validRoundId(_roundId)) {
            return rounds[uint32(_roundId)].answer;
        }
        return 0;
    }

    /**
     * @notice get timestamp when an answer was last updated
     * @param _roundId the round number to retrieve the updated timestamp for
     *
     * @dev #[deprecated] Use getRoundData instead. This does not error if no
     * answer has been reached, it will simply return 0. Either wait to point to
     * an already answered Aggregator or use the recommended getRoundData
     * instead which includes better verification information.
     */
    function getTimestamp(uint256 _roundId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (validRoundId(_roundId)) {
            return rounds[uint32(_roundId)].updatedAt;
        }
        return 0;
    }

    /**
     * @notice get data about a round. Consumers are encouraged to check
     * that they're receiving fresh data by inspecting the updatedAt and
     * answeredInRound return values.
     * @param _roundId the round ID to retrieve the round data for
     * @return roundId is the round ID for which data was retrieved
     * @return answer is the answer for the given round
     * @return startedAt is the timestamp when the round was started. This is 0
     * if the round hasn't been started yet.
     * @return updatedAt is the timestamp when the round last was updated (i.e.
     * answer was last computed)
     * @return answeredInRound is the round ID of the round in which the answer
     * was computed. answeredInRound may be smaller than roundId when the round
     * timed out. answeredInRound is equal to roundId when the round didn't time out
     * and was completed regularly.
     * @dev Note that for in-progress rounds (i.e. rounds that haven't yet received
     * maxSubmissions) answer and updatedAt may change between queries.
     */
    function getRoundData(uint80 _roundId)
        public
        view
        virtual
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        Round memory r = rounds[uint32(_roundId)];

        require(
            r.answeredInRound > 0 && validRoundId(_roundId),
            V3_NO_DATA_ERROR
        );

        return (
            _roundId,
            r.answer,
            r.startedAt,
            r.updatedAt,
            r.answeredInRound
        );
    }

    /**
     * @notice get data about the latest round. Consumers are encouraged to check
     * that they're receiving fresh data by inspecting the updatedAt and
     * answeredInRound return values. Consumers are encouraged to
     * use this more fully featured method over the "legacy" latestRound/
     * latestAnswer/latestTimestamp functions. Consumers are encouraged to check
     * that they're receiving fresh data by inspecting the updatedAt and
     * answeredInRound return values.
     * @return roundId is the round ID for which data was retrieved
     * @return answer is the answer for the given round
     * @return startedAt is the timestamp when the round was started. This is 0
     * if the round hasn't been started yet.
     * @return updatedAt is the timestamp when the round last was updated (i.e.
     * answer was last computed)
     * @return answeredInRound is the round ID of the round in which the answer
     * was computed. answeredInRound may be smaller than roundId when the round
     * timed out. answeredInRound is equal to roundId when the round didn't time
     * out and was completed regularly.
     * @dev Note that for in-progress rounds (i.e. rounds that haven't yet
     * received maxSubmissions) answer and updatedAt may change between queries.
     */
    function latestRoundData()
        public
        view
        virtual
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return getRoundData(latestRoundId);
    }

    /**
     * @notice query the available amount of LINK for an oracle to withdraw
     */
    function withdrawablePayment(address _oracle)
        external
        view
        returns (uint256)
    {
        return oracles[_oracle].withdrawable;
    }

    /**
     * @notice transfers the oracle's LINK to another address. Can only be called
     * by the oracle's admin.
     * @param _oracle is the oracle whose LINK is transferred
     * @param _recipient is the address to send the LINK to
     * @param _amount is the amount of LINK to send
     */
    function withdrawPayment(
        address _oracle,
        address _recipient,
        uint256 _amount
    ) external {
        require(oracles[_oracle].admin == msg.sender, "only callable by admin");

        // Safe to downcast _amount because the total amount of LINK is less than 2^128.
        uint128 amount = uint128(_amount);
        uint128 available = oracles[_oracle].withdrawable;
        require(available >= amount, "insufficient withdrawable funds");

        oracles[_oracle].withdrawable = available.sub(amount);
        recordedFunds.allocated = recordedFunds.allocated.sub(amount);

        assert(linkToken.transfer(_recipient, uint256(amount)));
    }

    /**
     * @notice transfers the owner's LINK to another address
     * @param _recipient is the address to send the LINK to
     * @param _amount is the amount of LINK to send
     */
    function withdrawFunds(address _recipient, uint256 _amount)
        external
        onlyOwner()
    {
        uint256 available = uint256(recordedFunds.available);
        require(
            available.sub(requiredReserve(paymentAmount)) >= _amount,
            "insufficient reserve funds"
        );
        require(
            linkToken.transfer(_recipient, _amount),
            "token transfer failed"
        );
        updateAvailableFunds();
    }

    /**
     * @notice get the admin address of an oracle
     * @param _oracle is the address of the oracle whose admin is being queried
     */
    function getAdmin(address _oracle) external view returns (address) {
        return oracles[_oracle].admin;
    }

    /**
     * @notice transfer the admin address for an oracle
     * @param _oracle is the address of the oracle whose admin is being transferred
     * @param _newAdmin is the new admin address
     */
    function transferAdmin(address _oracle, address _newAdmin) external {
        require(oracles[_oracle].admin == msg.sender, "only callable by admin");
        oracles[_oracle].pendingAdmin = _newAdmin;

        emit OracleAdminUpdateRequested(_oracle, msg.sender, _newAdmin);
    }

    /**
     * @notice accept the admin address transfer for an oracle
     * @param _oracle is the address of the oracle whose admin is being transferred
     */
    function acceptAdmin(address _oracle) external {
        require(
            oracles[_oracle].pendingAdmin == msg.sender,
            "only callable by pending admin"
        );
        oracles[_oracle].pendingAdmin = address(0);
        oracles[_oracle].admin = msg.sender;

        emit OracleAdminUpdated(_oracle, msg.sender);
    }

    /**
     * @notice allows non-oracles to request a new round
     */
    function requestNewRound() external returns (uint80) {
        require(requesters[msg.sender].authorized, "not authorized requester");

        uint32 current = reportingRoundId;
        require(
            rounds[current].updatedAt > 0 || timedOut(current),
            "prev round must be supersedable"
        );

        uint32 newRoundId = current.add(1);
        requesterInitializeNewRound(newRoundId);
        return newRoundId;
    }

    /**
     * @notice allows the owner to specify new non-oracles to start new rounds
     * @param _requester is the address to set permissions for
     * @param _authorized is a boolean specifying whether they can start new rounds or not
     * @param _delay is the number of rounds the requester must wait before starting another round
     */
    function setRequesterPermissions(
        address _requester,
        bool _authorized,
        uint32 _delay
    ) external onlyOwner() {
        if (requesters[_requester].authorized == _authorized) return;

        if (_authorized) {
            requesters[_requester].authorized = _authorized;
            requesters[_requester].delay = _delay;
        } else {
            delete requesters[_requester];
        }

        emit RequesterPermissionsSet(_requester, _authorized, _delay);
    }

    /**
     * @notice called through LINK's transferAndCall to update available funds
     * in the same transaction as the funds were transferred to the aggregator
     * @param _data is mostly ignored. It is checked for length, to be sure
     * nothing strange is passed in.
     */
    function onTokenTransfer(
        address,
        uint256,
        bytes calldata _data
    ) external {
        require(_data.length == 0, "transfer doesn't accept calldata");
        updateAvailableFunds();
    }

    /**
     * @notice a method to provide all current info oracles need. Intended only
     * only to be callable by oracles. Not for use by contracts to read state.
     * @param _oracle the address to look up information for.
     */
    function oracleRoundState(address _oracle, uint32 _queriedRoundId)
        external
        view
        returns (
            bool _eligibleToSubmit,
            uint32 _roundId,
            int256 _latestSubmission,
            uint64 _startedAt,
            uint64 _timeout,
            uint128 _availableFunds,
            uint8 _oracleCount,
            uint128 _paymentAmount
        )
    {
        require(msg.sender == tx.origin, "off-chain reading only");

        if (_queriedRoundId > 0) {
            Round storage round = rounds[_queriedRoundId];
            RoundDetails storage details = details[_queriedRoundId];
            return (
                eligibleForSpecificRound(_oracle, _queriedRoundId),
                _queriedRoundId,
                oracles[_oracle].latestSubmission,
                round.startedAt,
                details.timeout,
                recordedFunds.available,
                oracleCount(),
                (round.startedAt > 0 ? details.paymentAmount : paymentAmount)
            );
        } else {
            return oracleRoundStateSuggestRound(_oracle);
        }
    }

    /**
     * @notice method to update the address which does external data validation.
     * @param _newValidator designates the address of the new validation contract.
     */
    function setValidator(address _newValidator) public onlyOwner() {
        address previous = address(validator);

        if (previous != _newValidator) {
            validator = AggregatorValidatorInterface(_newValidator);

            emit ValidatorUpdated(previous, _newValidator);
        }
    }

    /**
     * Private
     */

    function initializeNewRound(uint32 _roundId) private {
        updateTimedOutRoundInfo(_roundId.sub(1));

        reportingRoundId = _roundId;
        RoundDetails memory nextDetails =
            RoundDetails(
                new int256[](0),
                maxSubmissionCount,
                minSubmissionCount,
                timeout,
                paymentAmount
            );
        details[_roundId] = nextDetails;
        rounds[_roundId].startedAt = uint64(block.timestamp);

        emit NewRound(_roundId, msg.sender, rounds[_roundId].startedAt);
    }

    function oracleInitializeNewRound(uint32 _roundId) private {
        if (!newRound(_roundId)) return;
        uint256 lastStarted = oracles[msg.sender].lastStartedRound; // cache storage reads
        if (_roundId <= lastStarted + restartDelay && lastStarted != 0) return;

        initializeNewRound(_roundId);

        oracles[msg.sender].lastStartedRound = _roundId;
    }

    function requesterInitializeNewRound(uint32 _roundId) private {
        if (!newRound(_roundId)) return;
        uint256 lastStarted = requesters[msg.sender].lastStartedRound; // cache storage reads
        require(
            _roundId > lastStarted + requesters[msg.sender].delay ||
                lastStarted == 0,
            "must delay requests"
        );

        initializeNewRound(_roundId);

        requesters[msg.sender].lastStartedRound = _roundId;
    }

    function updateTimedOutRoundInfo(uint32 _roundId) private {
        if (!timedOut(_roundId)) return;

        uint32 prevId = _roundId.sub(1);
        rounds[_roundId].answer = rounds[prevId].answer;
        rounds[_roundId].answeredInRound = rounds[prevId].answeredInRound;
        rounds[_roundId].updatedAt = uint64(block.timestamp);

        delete details[_roundId];
    }

    function eligibleForSpecificRound(address _oracle, uint32 _queriedRoundId)
        private
        view
        returns (bool _eligible)
    {
        if (rounds[_queriedRoundId].startedAt > 0) {
            return
                acceptingSubmissions(_queriedRoundId) &&
                validateOracleRound(_oracle, _queriedRoundId).length == 0;
        } else {
            return
                delayed(_oracle, _queriedRoundId) &&
                validateOracleRound(_oracle, _queriedRoundId).length == 0;
        }
    }

    function oracleRoundStateSuggestRound(address _oracle)
        private
        view
        returns (
            bool _eligibleToSubmit,
            uint32 _roundId,
            int256 _latestSubmission,
            uint64 _startedAt,
            uint64 _timeout,
            uint128 _availableFunds,
            uint8 _oracleCount,
            uint128 _paymentAmount
        )
    {
        Round storage round = rounds[0];
        OracleStatus storage oracle = oracles[_oracle];

        bool shouldSupersede =
            oracle.lastReportedRound == reportingRoundId ||
                !acceptingSubmissions(reportingRoundId);
        // Instead of nudging oracles to submit to the next round, the inclusion of
        // the shouldSupersede bool in the if condition pushes them towards
        // submitting in a currently open round.
        if (supersedable(reportingRoundId) && shouldSupersede) {
            _roundId = reportingRoundId.add(1);
            round = rounds[_roundId];

            _paymentAmount = paymentAmount;
            _eligibleToSubmit = delayed(_oracle, _roundId);
        } else {
            _roundId = reportingRoundId;
            round = rounds[_roundId];

            _paymentAmount = details[_roundId].paymentAmount;
            _eligibleToSubmit = acceptingSubmissions(_roundId);
        }

        if (validateOracleRound(_oracle, _roundId).length != 0) {
            _eligibleToSubmit = false;
        }

        return (
            _eligibleToSubmit,
            _roundId,
            oracle.latestSubmission,
            round.startedAt,
            details[_roundId].timeout,
            recordedFunds.available,
            oracleCount(),
            _paymentAmount
        );
    }

    function updateRoundAnswer(uint32 _roundId)
        internal
        returns (bool, int256)
    {
        if (
            details[_roundId].submissions.length <
            details[_roundId].minSubmissions
        ) {
            return (false, 0);
        }

        int256 newAnswer =
            Median.calculateInplace(details[_roundId].submissions);
        rounds[_roundId].answer = newAnswer;
        rounds[_roundId].updatedAt = uint64(block.timestamp);
        rounds[_roundId].answeredInRound = _roundId;
        latestRoundId = _roundId;

        emit AnswerUpdated(newAnswer, _roundId, now);

        return (true, newAnswer);
    }

    function validateAnswer(uint32 _roundId, int256 _newAnswer) private {
        AggregatorValidatorInterface av = validator; // cache storage reads
        if (address(av) == address(0)) return;

        uint32 prevRound = _roundId.sub(1);
        uint32 prevAnswerRoundId = rounds[prevRound].answeredInRound;
        int256 prevRoundAnswer = rounds[prevRound].answer;
        // We do not want the validator to ever prevent reporting, so we limit its
        // gas usage and catch any errors that may arise.
        try
            av.validate{gas: VALIDATOR_GAS_LIMIT}(
                prevAnswerRoundId,
                prevRoundAnswer,
                _roundId,
                _newAnswer
            )
        {} catch {}
    }

    function payOracle(uint32 _roundId) private {
        uint128 payment = details[_roundId].paymentAmount;
        Funds memory funds = recordedFunds;
        funds.available = funds.available.sub(payment);
        funds.allocated = funds.allocated.add(payment);
        recordedFunds = funds;
        oracles[msg.sender].withdrawable = oracles[msg.sender].withdrawable.add(
            payment
        );

        emit AvailableFundsUpdated(funds.available);
    }

    function recordSubmission(int256 _submission, uint32 _roundId) private {
        require(
            acceptingSubmissions(_roundId),
            "round not accepting submissions"
        );

        details[_roundId].submissions.push(_submission);
        oracles[msg.sender].lastReportedRound = _roundId;
        oracles[msg.sender].latestSubmission = _submission;

        emit SubmissionReceived(_submission, _roundId, msg.sender);
    }

    function deleteRoundDetails(uint32 _roundId) private {
        if (
            details[_roundId].submissions.length <
            details[_roundId].maxSubmissions
        ) return;

        delete details[_roundId];
    }

    function timedOut(uint32 _roundId) private view returns (bool) {
        uint64 startedAt = rounds[_roundId].startedAt;
        uint32 roundTimeout = details[_roundId].timeout;
        return
            startedAt > 0 &&
            roundTimeout > 0 &&
            startedAt.add(roundTimeout) < block.timestamp;
    }

    function getStartingRound(address _oracle) private view returns (uint32) {
        uint32 currentRound = reportingRoundId;
        if (currentRound != 0 && currentRound == oracles[_oracle].endingRound) {
            return currentRound;
        }
        return currentRound.add(1);
    }

    function previousAndCurrentUnanswered(uint32 _roundId, uint32 _rrId)
        private
        view
        returns (bool)
    {
        return _roundId.add(1) == _rrId && rounds[_rrId].updatedAt == 0;
    }

    function requiredReserve(uint256 payment) private view returns (uint256) {
        return payment.mul(oracleCount()).mul(RESERVE_ROUNDS);
    }

    function addOracle(address _oracle, address _admin) private {
        require(!oracleEnabled(_oracle), "oracle already enabled");

        require(_admin != address(0), "cannot set admin to 0");
        require(
            oracles[_oracle].admin == address(0) ||
                oracles[_oracle].admin == _admin,
            "owner cannot overwrite admin"
        );

        oracles[_oracle].startingRound = getStartingRound(_oracle);
        oracles[_oracle].endingRound = ROUND_MAX;
        oracles[_oracle].index = uint16(oracleAddresses.length);
        oracleAddresses.push(_oracle);
        oracles[_oracle].admin = _admin;

        emit OraclePermissionsUpdated(_oracle, true);
        emit OracleAdminUpdated(_oracle, _admin);
    }

    function removeOracle(address _oracle) private {
        require(oracleEnabled(_oracle), "oracle not enabled");

        oracles[_oracle].endingRound = reportingRoundId.add(1);
        address tail = oracleAddresses[uint256(oracleCount()).sub(1)];
        uint16 index = oracles[_oracle].index;
        oracles[tail].index = index;
        delete oracles[_oracle].index;
        oracleAddresses[index] = tail;
        oracleAddresses.pop();

        emit OraclePermissionsUpdated(_oracle, false);
    }

    function validateOracleRound(address _oracle, uint32 _roundId)
        private
        view
        returns (bytes memory)
    {
        // cache storage reads
        uint32 startingRound = oracles[_oracle].startingRound;
        uint32 rrId = reportingRoundId;

        if (startingRound == 0) return "not enabled oracle";
        if (startingRound > _roundId) return "not yet enabled oracle";
        if (oracles[_oracle].endingRound < _roundId)
            return "no longer allowed oracle";
        if (oracles[_oracle].lastReportedRound >= _roundId)
            return "cannot report on previous rounds";
        if (
            _roundId != rrId &&
            _roundId != rrId.add(1) &&
            !previousAndCurrentUnanswered(_roundId, rrId)
        ) return "invalid round to report";
        if (_roundId != 1 && !supersedable(_roundId.sub(1)))
            return "previous round not supersedable";
    }

    function supersedable(uint32 _roundId) private view returns (bool) {
        return rounds[_roundId].updatedAt > 0 || timedOut(_roundId);
    }

    function oracleEnabled(address _oracle) private view returns (bool) {
        return oracles[_oracle].endingRound == ROUND_MAX;
    }

    function acceptingSubmissions(uint32 _roundId) private view returns (bool) {
        return details[_roundId].maxSubmissions != 0;
    }

    function delayed(address _oracle, uint32 _roundId)
        private
        view
        returns (bool)
    {
        uint256 lastStarted = oracles[_oracle].lastStartedRound;
        return _roundId > lastStarted + restartDelay || lastStarted == 0;
    }

    function newRound(uint32 _roundId) private view returns (bool) {
        return _roundId == reportingRoundId.add(1);
    }

    function validRoundId(uint256 _roundId) private view returns (bool) {
        return _roundId <= ROUND_MAX;
    }
}

pragma solidity ^0.6.0;

import "./vendor/SafeMath.sol";
import "./SignedSafeMath.sol";

library Median {
  using SignedSafeMath for int256;

  int256 constant INT_MAX = 2**255-1;

  /**
   * @notice Returns the sorted middle, or the average of the two middle indexed items if the
   * array has an even number of elements.
   * @dev The list passed as an argument isn't modified.
   * @dev This algorithm has expected runtime O(n), but for adversarially chosen inputs
   * the runtime is O(n^2).
   * @param list The list of elements to compare
   */
  function calculate(int256[] memory list)
    internal
    pure
    returns (int256)
  {
    return calculateInplace(copy(list));
  }

  /**
   * @notice See documentation for function calculate.
   * @dev The list passed as an argument may be permuted.
   */
  function calculateInplace(int256[] memory list)
    internal
    pure
    returns (int256)
  {
    require(0 < list.length, "list must not be empty");
    uint256 len = list.length;
    uint256 middleIndex = len / 2;
    if (len % 2 == 0) {
      int256 median1;
      int256 median2;
      (median1, median2) = quickselectTwo(list, 0, len - 1, middleIndex - 1, middleIndex);
      return SignedSafeMath.avg(median1, median2);
    } else {
      return quickselect(list, 0, len - 1, middleIndex);
    }
  }

  /**
   * @notice Maximum length of list that shortSelectTwo can handle
   */
  uint256 constant SHORTSELECTTWO_MAX_LENGTH = 7;

  /**
   * @notice Select the k1-th and k2-th element from list of length at most 7
   * @dev Uses an optimal sorting network
   */
  function shortSelectTwo(
    int256[] memory list,
    uint256 lo,
    uint256 hi,
    uint256 k1,
    uint256 k2
  )
    private
    pure
    returns (int256 k1th, int256 k2th)
  {
    // Uses an optimal sorting network (https://en.wikipedia.org/wiki/Sorting_network)
    // for lists of length 7. Network layout is taken from
    // http://jgamble.ripco.net/cgi-bin/nw.cgi?inputs=7&algorithm=hibbard&output=svg

    uint256 len = hi + 1 - lo;
    int256 x0 = list[lo + 0];
    int256 x1 = 1 < len ? list[lo + 1] : INT_MAX;
    int256 x2 = 2 < len ? list[lo + 2] : INT_MAX;
    int256 x3 = 3 < len ? list[lo + 3] : INT_MAX;
    int256 x4 = 4 < len ? list[lo + 4] : INT_MAX;
    int256 x5 = 5 < len ? list[lo + 5] : INT_MAX;
    int256 x6 = 6 < len ? list[lo + 6] : INT_MAX;

    if (x0 > x1) {(x0, x1) = (x1, x0);}
    if (x2 > x3) {(x2, x3) = (x3, x2);}
    if (x4 > x5) {(x4, x5) = (x5, x4);}
    if (x0 > x2) {(x0, x2) = (x2, x0);}
    if (x1 > x3) {(x1, x3) = (x3, x1);}
    if (x4 > x6) {(x4, x6) = (x6, x4);}
    if (x1 > x2) {(x1, x2) = (x2, x1);}
    if (x5 > x6) {(x5, x6) = (x6, x5);}
    if (x0 > x4) {(x0, x4) = (x4, x0);}
    if (x1 > x5) {(x1, x5) = (x5, x1);}
    if (x2 > x6) {(x2, x6) = (x6, x2);}
    if (x1 > x4) {(x1, x4) = (x4, x1);}
    if (x3 > x6) {(x3, x6) = (x6, x3);}
    if (x2 > x4) {(x2, x4) = (x4, x2);}
    if (x3 > x5) {(x3, x5) = (x5, x3);}
    if (x3 > x4) {(x3, x4) = (x4, x3);}

    uint256 index1 = k1 - lo;
    if (index1 == 0) {k1th = x0;}
    else if (index1 == 1) {k1th = x1;}
    else if (index1 == 2) {k1th = x2;}
    else if (index1 == 3) {k1th = x3;}
    else if (index1 == 4) {k1th = x4;}
    else if (index1 == 5) {k1th = x5;}
    else if (index1 == 6) {k1th = x6;}
    else {revert("k1 out of bounds");}

    uint256 index2 = k2 - lo;
    if (k1 == k2) {return (k1th, k1th);}
    else if (index2 == 0) {return (k1th, x0);}
    else if (index2 == 1) {return (k1th, x1);}
    else if (index2 == 2) {return (k1th, x2);}
    else if (index2 == 3) {return (k1th, x3);}
    else if (index2 == 4) {return (k1th, x4);}
    else if (index2 == 5) {return (k1th, x5);}
    else if (index2 == 6) {return (k1th, x6);}
    else {revert("k2 out of bounds");}
  }

  /**
   * @notice Selects the k-th ranked element from list, looking only at indices between lo and hi
   * (inclusive). Modifies list in-place.
   */
  function quickselect(int256[] memory list, uint256 lo, uint256 hi, uint256 k)
    private
    pure
    returns (int256 kth)
  {
    require(lo <= k);
    require(k <= hi);
    while (lo < hi) {
      if (hi - lo < SHORTSELECTTWO_MAX_LENGTH) {
        int256 ignore;
        (kth, ignore) = shortSelectTwo(list, lo, hi, k, k);
        return kth;
      }
      uint256 pivotIndex = partition(list, lo, hi);
      if (k <= pivotIndex) {
        // since pivotIndex < (original hi passed to partition),
        // termination is guaranteed in this case
        hi = pivotIndex;
      } else {
        // since (original lo passed to partition) <= pivotIndex,
        // termination is guaranteed in this case
        lo = pivotIndex + 1;
      }
    }
    return list[lo];
  }

  /**
   * @notice Selects the k1-th and k2-th ranked elements from list, looking only at indices between
   * lo and hi (inclusive). Modifies list in-place.
   */
  function quickselectTwo(
    int256[] memory list,
    uint256 lo,
    uint256 hi,
    uint256 k1,
    uint256 k2
  )
    internal // for testing
    pure
    returns (int256 k1th, int256 k2th)
  {
    require(k1 < k2);
    require(lo <= k1 && k1 <= hi);
    require(lo <= k2 && k2 <= hi);

    while (true) {
      if (hi - lo < SHORTSELECTTWO_MAX_LENGTH) {
        return shortSelectTwo(list, lo, hi, k1, k2);
      }
      uint256 pivotIdx = partition(list, lo, hi);
      if (k2 <= pivotIdx) {
        hi = pivotIdx;
      } else if (pivotIdx < k1) {
        lo = pivotIdx + 1;
      } else {
        assert(k1 <= pivotIdx && pivotIdx < k2);
        k1th = quickselect(list, lo, pivotIdx, k1);
        k2th = quickselect(list, pivotIdx + 1, hi, k2);
        return (k1th, k2th);
      }
    }
  }

  /**
   * @notice Partitions list in-place using Hoare's partitioning scheme.
   * Only elements of list between indices lo and hi (inclusive) will be modified.
   * Returns an index i, such that:
   * - lo <= i < hi
   * - forall j in [lo, i]. list[j] <= list[i]
   * - forall j in [i, hi]. list[i] <= list[j]
   */
  function partition(int256[] memory list, uint256 lo, uint256 hi)
    private
    pure
    returns (uint256)
  {
    // We don't care about overflow of the addition, because it would require a list
    // larger than any feasible computer's memory.
    int256 pivot = list[(lo + hi) / 2];
    lo -= 1; // this can underflow. that's intentional.
    hi += 1;
    while (true) {
      do {
        lo += 1;
      } while (list[lo] < pivot);
      do {
        hi -= 1;
      } while (list[hi] > pivot);
      if (lo < hi) {
        (list[lo], list[hi]) = (list[hi], list[lo]);
      } else {
        // Let orig_lo and orig_hi be the original values of lo and hi passed to partition.
        // Then, hi < orig_hi, because hi decreases *strictly* monotonically
        // in each loop iteration and
        // - either list[orig_hi] > pivot, in which case the first loop iteration
        //   will achieve hi < orig_hi;
        // - or list[orig_hi] <= pivot, in which case at least two loop iterations are
        //   needed:
        //   - lo will have to stop at least once in the interval
        //     [orig_lo, (orig_lo + orig_hi)/2]
        //   - (orig_lo + orig_hi)/2 < orig_hi
        return hi;
      }
    }
  }

  /**
   * @notice Makes an in-memory copy of the array passed in
   * @param list Reference to the array to be copied
   */
  function copy(int256[] memory list)
    private
    pure
    returns(int256[] memory)
  {
    int256[] memory list2 = new int256[](list.length);
    for (uint256 i = 0; i < list.length; i++) {
      list2[i] = list[i];
    }
    return list2;
  }
}

pragma solidity ^0.6.0;

/**
 * @title The Owned contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract Owned {

  address payable public owner;
  address private pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address _to)
    external
    onlyOwner()
  {
    pendingOwner = _to;

    emit OwnershipTransferRequested(owner, _to);
  }

  /**
   * @dev Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
  {
    require(msg.sender == pendingOwner, "Must be proposed owner");

    address oldOwner = owner;
    owner = msg.sender;
    pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @dev Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Only callable by owner");
    _;
  }

}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * This library is a version of Open Zeppelin's SafeMath, modified to support
 * unsigned 128 bit integers.
 */
library SafeMath128 {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint128 a, uint128 b) internal pure returns (uint128) {
    uint128 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint128 a, uint128 b) internal pure returns (uint128) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint128 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint128 a, uint128 b) internal pure returns (uint128) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint128 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint128 a, uint128 b) internal pure returns (uint128) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint128 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint128 a, uint128 b) internal pure returns (uint128) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * This library is a version of Open Zeppelin's SafeMath, modified to support
 * unsigned 32 bit integers.
 */
library SafeMath32 {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint32 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint32 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint32 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint32 a, uint32 b) internal pure returns (uint32) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * This library is a version of Open Zeppelin's SafeMath, modified to support
 * unsigned 64 bit integers.
 */
library SafeMath64 {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint64 a, uint64 b) internal pure returns (uint64) {
    uint64 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint64 a, uint64 b) internal pure returns (uint64) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint64 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint64 a, uint64 b) internal pure returns (uint64) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint64 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint64 a, uint64 b) internal pure returns (uint64) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint64 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint64 a, uint64 b) internal pure returns (uint64) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

pragma solidity ^0.6.0;

interface AggregatorValidatorInterface {
  function validate(
    uint256 previousRoundId,
    int256 previousAnswer,
    uint256 currentRoundId,
    int256 currentAnswer
  ) external returns (bool);
}

pragma solidity ^0.6.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

pragma solidity ^0.6.0;

library SignedSafeMath {
  int256 constant private _INT256_MIN = -2**255;

  /**
   * @dev Multiplies two signed integers, reverts on overflow.
   */
  function mul(int256 a, int256 b) internal pure returns (int256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

    int256 c = a * b;
    require(c / a == b, "SignedSafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
   */
  function div(int256 a, int256 b) internal pure returns (int256) {
    require(b != 0, "SignedSafeMath: division by zero");
    require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

    int256 c = a / b;

    return c;
  }

  /**
   * @dev Subtracts two signed integers, reverts on overflow.
   */
  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

    return c;
  }

  /**
   * @dev Adds two signed integers, reverts on overflow.
   */
  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

    return c;
  }

  /**
   * @notice Computes average of two signed integers, ensuring that the computation
   * doesn't overflow.
   * @dev If the result is not an integer, it is rounded towards zero. For example,
   * avg(-3, -4) = -3
   */
  function avg(int256 _a, int256 _b)
    internal
    pure
    returns (int256)
  {
    if ((_a < 0 && _b > 0) || (_a > 0 && _b < 0)) {
      return add(_a, _b) / 2;
    }
    int256 remainder = (_a % 2 + _b % 2) / 2;
    return add(add(_a / 2, _b / 2), remainder);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external virtual ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable virtual ifAdmin {
        _upgradeTo(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

contract PoolTokenProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _proxyAdmin,
        address _underlyer,
        address _priceAgg
    )
        public
        TransparentUpgradeableProxy(
            _logic,
            _proxyAdmin,
            abi.encodeWithSignature(
                "initialize(address,address,address)",
                _proxyAdmin,
                _underlyer,
                _priceAgg
            )
        )
    {} // solhint-disable no-empty-blocks
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

contract PoolManagerProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _proxyAdmin,
        address _addressRegistry
    )
        public
        TransparentUpgradeableProxy(
            _logic,
            _proxyAdmin,
            abi.encodeWithSignature(
                "initialize(address,address)",
                _proxyAdmin,
                _addressRegistry
            )
        )
    {} // solhint-disable no-empty-blocks
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

contract MetaPoolTokenProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _proxyAdmin,
        address _addressRegistry
    )
        public
        TransparentUpgradeableProxy(
            _logic,
            _proxyAdmin,
            abi.encodeWithSignature(
                "initialize(address,address)",
                _proxyAdmin,
                _addressRegistry
            )
        )
    {} // solhint-disable no-empty-blocks
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../access/Ownable.sol";
import "./TransparentUpgradeableProxy.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {

    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(TransparentUpgradeableProxy proxy, address implementation, bytes memory data) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardDistributor is Ownable {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    event SignerSet(address newSigner);
    event Claimed(uint256 nonce, address recipient, uint256 amount);

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct Recipient {
        uint256 nonce;
        address wallet;
        uint256 amount;
    }

    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 private constant RECIPIENT_TYPEHASH =
        keccak256("Recipient(uint256 nonce,address wallet,uint256 amount)");

    bytes32 private immutable DOMAIN_SEPARATOR;

    IERC20 public immutable apyToken;
    mapping(address => uint256) public accountNonces;
    address public signer;

    constructor(IERC20 token, address signerAddress) public {
        require(address(token) != address(0), "Invalid APY Address");
        require(signerAddress != address(0), "Invalid Signer Address");
        apyToken = token;
        signer = signerAddress;

        DOMAIN_SEPARATOR = _hashDomain(
            EIP712Domain({
                name: "APY Distribution",
                version: "1",
                chainId: _getChainID(),
                verifyingContract: address(this)
            })
        );
    }

    function _hashDomain(EIP712Domain memory eip712Domain)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract
                )
            );
    }

    function _hashRecipient(Recipient memory recipient)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    RECIPIENT_TYPEHASH,
                    recipient.nonce,
                    recipient.wallet,
                    recipient.amount
                )
            );
    }

    function _hash(Recipient memory recipient) private returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    _hashRecipient(recipient)
                )
            );
    }

    function _getChainID() private view returns (uint256) {
        uint256 id;
        // no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    function setSigner(address newSigner) external onlyOwner {
        signer = newSigner;
    }

    function claim(
        Recipient calldata recipient,
        uint8 v,
        bytes32 r,
        bytes32 s // bytes calldata signature
    ) external {
        address signatureSigner = ecrecover(_hash(recipient), v, r, s);
        require(signatureSigner == signer, "Invalid Signature");

        require(
            recipient.nonce == accountNonces[recipient.wallet],
            "Nonce Mismatch"
        );
        require(
            apyToken.balanceOf(address(this)) >= recipient.amount,
            "Insufficient Funds"
        );

        accountNonces[recipient.wallet] += 1;
        apyToken.safeTransfer(recipient.wallet, recipient.amount);

        emit Claimed(recipient.nonce, recipient.wallet, recipient.amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Uniswap contract for adding/removing liquidity from pools
interface IUniswapV2Router {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

interface IUniswapV2Pair is IERC20 {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

/**
 * @title Periphery Contract for the Uniswap V2 Router
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 *         of an underlyer of a Uniswap LP token. The balance is used as part
 *         of the Chainlink computation of the deployed TVL.  The primary
 *         `getUnderlyerBalance` function is invoked indirectly when a
 *         Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
contract UniswapPeriphery {
    using SafeMath for uint256;

    /**
     * @notice Returns the balance of an underlying token represented by
     *         an account's LP token balance.
     * @param lpToken the LP token representing the share of the pool
     * @param tokenIndex the index indicating which underlyer
     * @return balance
     */
    function getUnderlyerBalance(
        address account,
        IUniswapV2Pair lpToken,
        uint256 tokenIndex
    ) external view returns (uint256 balance) {
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        uint256 poolBalance = getPoolBalance(lpToken, tokenIndex);
        (uint256 lpTokenBalance, uint256 lpTokenSupply) =
            getLpTokenShare(account, lpToken);

        balance = lpTokenBalance.mul(poolBalance).div(lpTokenSupply);
    }

    function getPoolBalance(IUniswapV2Pair lpToken, uint256 tokenIndex)
        public
        view
        returns (uint256 poolBalance)
    {
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");
        IERC20 token;
        if (tokenIndex == 0) {
            token = IERC20(lpToken.token0());
        } else if (tokenIndex == 1) {
            token = IERC20(lpToken.token1());
        } else {
            revert("INVALID_TOKEN_INDEX");
        }
        poolBalance = token.balanceOf(address(lpToken));
    }

    function getLpTokenShare(address account, IERC20 lpToken)
        public
        view
        returns (uint256 balance, uint256 totalSupply)
    {
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        totalSupply = lpToken.totalSupply();
        balance = lpToken.balanceOf(account);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice the stablecoin pool contract
interface IStableSwap {
    function balances(uint256 coin) external view returns (uint256);

    /// @dev the number of coins is hard-coded in curve contracts
    // solhint-disable-next-line
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external;

    /// @dev the number of coins is hard-coded in curve contracts
    // solhint-disable-next-line
    function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts)
        external;

    // solhint-disable-next-line
    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        int128 tokenIndex,
        uint256 minAmount
    ) external;

    /// @dev For newest curve pools like aave; older pools refer to a private `token` variable.
    // function lp_token() external view returns (address); // solhint-disable-line func-name-mixedcase
}

/// @notice the liquidity gauge, i.e. staking contract, for the stablecoin pool
interface ILiquidityGauge {
    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address _addr) external;

    function withdraw(uint256 _value) external;

    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title Periphery Contract for the Curve 3pool
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 *         of an underlyer of a Curve LP token. The balance is used as part
 *         of the Chainlink computation of the deployed TVL.  The primary
 *         `getUnderlyerBalance` function is invoked indirectly when a
 *         Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
contract CurvePeriphery {
    using SafeMath for uint256;

    /**
     * @notice Returns the balance of an underlying token represented by
     *         an account's LP token balance.
     * @param stableSwap the liquidity pool comprised of multiple underlyers
     * @param gauge the staking contract for the LP tokens
     * @param lpToken the LP token representing the share of the pool
     * @param coin the index indicating which underlyer
     * @return balance
     */
    function getUnderlyerBalance(
        address account,
        IStableSwap stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken,
        uint256 coin
    ) external view returns (uint256 balance) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        uint256 poolBalance = getPoolBalance(stableSwap, coin);
        (uint256 lpTokenBalance, uint256 lpTokenSupply) =
            getLpTokenShare(account, stableSwap, gauge, lpToken);

        balance = lpTokenBalance.mul(poolBalance).div(lpTokenSupply);
    }

    function getPoolBalance(IStableSwap stableSwap, uint256 coin)
        public
        view
        returns (uint256)
    {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        return stableSwap.balances(coin);
    }

    function getLpTokenShare(
        address account,
        IStableSwap stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken
    ) public view returns (uint256 balance, uint256 totalSupply) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        totalSupply = lpToken.totalSupply();
        balance = lpToken.balanceOf(account);
        balance = balance.add(gauge.balanceOf(account));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice the lending pool contract
interface IAaveLendingPool {
    /**
     * @notice Deposits a certain amount of an asset into the protocol, minting
     *         the same amount of corresponding aTokens, and transferring them
     *         to the onBehalfOf address.
     *         E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @dev When depositing, the LendingPool contract must have at least an
     *      allowance() of amount for the asset being deposited.
     *      During testing, you can use the referral code: 0.
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning
     *         the equivalent aTokens owned.
     *         E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC,
     *         burning the 100 aUSDC
     * @dev Ensure you set the relevant ERC20 allowance of the aToken,
     *      before calling this function, so the LendingPool
     *      contract can burn the associated aTokens.
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

/**
 * @title Periphery Contract for the Aave lending pool
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 *         of an underlyer of an Aave lending token. The balance is used as part
 *         of the Chainlink computation of the deployed TVL.  The primary
 *         `getUnderlyerBalance` function is invoked indirectly when a
 *         Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
contract AavePeriphery {
    using SafeMath for uint256;

    /**
     * @notice Returns the balance of an underlying token represented by
     *         an account's aToken balance
     * @dev aTokens represent the underlyer amount at par (1-1), growing with interest.
     * @param aToken the LP token representing the share of the pool
     * @return balance
     */
    function getUnderlyerBalance(address account, IERC20 aToken)
        external
        view
        returns (uint256)
    {
        require(account != address(0), "INVALID_ACCOUNT");
        require(address(aToken) != address(0), "INVALID_AAVE_TOKEN");

        return aToken.balanceOf(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

// We import the contract so truffle compiles it, and we have the ABI
// available when working from truffle console.
import "@gnosis.pm/mock-contract/contracts/MockContract.sol";
import "@openzeppelin/contracts/proxy/ProxyAdmin.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity ^0.6.0;

interface MockInterface {
	/**
	 * @dev After calling this method, the mock will return `response` when it is called
	 * with any calldata that is not mocked more specifically below
	 * (e.g. using givenMethodReturn).
	 * @param response ABI encoded response that will be returned if method is invoked
	 */
	function givenAnyReturn(bytes calldata response) external;
	function givenAnyReturnBool(bool response) external;
	function givenAnyReturnUint(uint response) external;
	function givenAnyReturnAddress(address response) external;

	function givenAnyRevert() external;
	function givenAnyRevertWithMessage(string calldata message) external;
	function givenAnyRunOutOfGas() external;

	/**
	 * @dev After calling this method, the mock will return `response` when the given
	 * methodId is called regardless of arguments. If the methodId and arguments
	 * are mocked more specifically (using `givenMethodAndArguments`) the latter
	 * will take precedence.
	 * @param method ABI encoded methodId. It is valid to pass full calldata (including arguments). The mock will extract the methodId from it
	 * @param response ABI encoded response that will be returned if method is invoked
	 */
	function givenMethodReturn(bytes calldata method, bytes calldata response) external;
	function givenMethodReturnBool(bytes calldata method, bool response) external;
	function givenMethodReturnUint(bytes calldata method, uint response) external;
	function givenMethodReturnAddress(bytes calldata method, address response) external;

	function givenMethodRevert(bytes calldata method) external;
	function givenMethodRevertWithMessage(bytes calldata method, string calldata message) external;
	function givenMethodRunOutOfGas(bytes calldata method) external;

	/**
	 * @dev After calling this method, the mock will return `response` when the given
	 * methodId is called with matching arguments. These exact calldataMocks will take
	 * precedence over all other calldataMocks.
	 * @param call ABI encoded calldata (methodId and arguments)
	 * @param response ABI encoded response that will be returned if contract is invoked with calldata
	 */
	function givenCalldataReturn(bytes calldata call, bytes calldata response) external;
	function givenCalldataReturnBool(bytes calldata call, bool response) external;
	function givenCalldataReturnUint(bytes calldata call, uint response) external;
	function givenCalldataReturnAddress(bytes calldata call, address response) external;

	function givenCalldataRevert(bytes calldata call) external;
	function givenCalldataRevertWithMessage(bytes calldata call, string calldata message) external;
	function givenCalldataRunOutOfGas(bytes calldata call) external;

	/**
	 * @dev Returns the number of times anything has been called on this mock since last reset
	 */
	function invocationCount() external returns (uint);

	/**
	 * @dev Returns the number of times the given method has been called on this mock since last reset
	 * @param method ABI encoded methodId. It is valid to pass full calldata (including arguments). The mock will extract the methodId from it
	 */
	function invocationCountForMethod(bytes calldata method) external returns (uint);

	/**
	 * @dev Returns the number of times this mock has been called with the exact calldata since last reset.
	 * @param call ABI encoded calldata (methodId and arguments)
	 */
	function invocationCountForCalldata(bytes calldata call) external returns (uint);

	/**
	 * @dev Resets all mocked methods and invocation counts.
	 */
	 function reset() external;
}

/**
 * Implementation of the MockInterface.
 */
contract MockContract is MockInterface {
	enum MockType { Return, Revert, OutOfGas }
	
	bytes32 public constant MOCKS_LIST_START = hex"01";
	bytes public constant MOCKS_LIST_END = "0xff";
	bytes32 public constant MOCKS_LIST_END_HASH = keccak256(MOCKS_LIST_END);
	bytes4 public constant SENTINEL_ANY_MOCKS = hex"01";
	bytes public constant DEFAULT_FALLBACK_VALUE = abi.encode(false);

	// A linked list allows easy iteration and inclusion checks
	mapping(bytes32 => bytes) calldataMocks;
	mapping(bytes => MockType) calldataMockTypes;
	mapping(bytes => bytes) calldataExpectations;
	mapping(bytes => string) calldataRevertMessage;
	mapping(bytes32 => uint) calldataInvocations;

	mapping(bytes4 => bytes4) methodIdMocks;
	mapping(bytes4 => MockType) methodIdMockTypes;
	mapping(bytes4 => bytes) methodIdExpectations;
	mapping(bytes4 => string) methodIdRevertMessages;
	mapping(bytes32 => uint) methodIdInvocations;

	MockType fallbackMockType;
	bytes fallbackExpectation = DEFAULT_FALLBACK_VALUE;
	string fallbackRevertMessage;
	uint invocations;
	uint resetCount;

	constructor() public {
		calldataMocks[MOCKS_LIST_START] = MOCKS_LIST_END;
		methodIdMocks[SENTINEL_ANY_MOCKS] = SENTINEL_ANY_MOCKS;
	}

	function trackCalldataMock(bytes memory call) private {
		bytes32 callHash = keccak256(call);
		if (calldataMocks[callHash].length == 0) {
			calldataMocks[callHash] = calldataMocks[MOCKS_LIST_START];
			calldataMocks[MOCKS_LIST_START] = call;
		}
	}

	function trackMethodIdMock(bytes4 methodId) private {
		if (methodIdMocks[methodId] == 0x0) {
			methodIdMocks[methodId] = methodIdMocks[SENTINEL_ANY_MOCKS];
			methodIdMocks[SENTINEL_ANY_MOCKS] = methodId;
		}
	}

	function _givenAnyReturn(bytes memory response) internal {
		fallbackMockType = MockType.Return;
		fallbackExpectation = response;
	}

	function givenAnyReturn(bytes calldata response) override external {
		_givenAnyReturn(response);
	}

	function givenAnyReturnBool(bool response) override external {
		uint flag = response ? 1 : 0;
		_givenAnyReturn(uintToBytes(flag));
	}

	function givenAnyReturnUint(uint response) override external {
		_givenAnyReturn(uintToBytes(response));	
	}

	function givenAnyReturnAddress(address response) override external {
		_givenAnyReturn(uintToBytes(uint(response)));
	}

	function givenAnyRevert() override external {
		fallbackMockType = MockType.Revert;
		fallbackRevertMessage = "";
	}

	function givenAnyRevertWithMessage(string calldata message) override external {
		fallbackMockType = MockType.Revert;
		fallbackRevertMessage = message;
	}

	function givenAnyRunOutOfGas() override external {
		fallbackMockType = MockType.OutOfGas;
	}

	function _givenCalldataReturn(bytes memory call, bytes memory response) private  {
		calldataMockTypes[call] = MockType.Return;
		calldataExpectations[call] = response;
		trackCalldataMock(call);
	}

	function givenCalldataReturn(bytes calldata call, bytes calldata response) override external  {
		_givenCalldataReturn(call, response);
	}

	function givenCalldataReturnBool(bytes calldata call, bool response) override external {
		uint flag = response ? 1 : 0;
		_givenCalldataReturn(call, uintToBytes(flag));
	}

	function givenCalldataReturnUint(bytes calldata call, uint response) override external {
		_givenCalldataReturn(call, uintToBytes(response));
	}

	function givenCalldataReturnAddress(bytes calldata call, address response) override external {
		_givenCalldataReturn(call, uintToBytes(uint(response)));
	}

	function _givenMethodReturn(bytes memory call, bytes memory response) private {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.Return;
		methodIdExpectations[method] = response;
		trackMethodIdMock(method);		
	}

	function givenMethodReturn(bytes calldata call, bytes calldata response) override external {
		_givenMethodReturn(call, response);
	}

	function givenMethodReturnBool(bytes calldata call, bool response) override external {
		uint flag = response ? 1 : 0;
		_givenMethodReturn(call, uintToBytes(flag));
	}

	function givenMethodReturnUint(bytes calldata call, uint response) override external {
		_givenMethodReturn(call, uintToBytes(response));
	}

	function givenMethodReturnAddress(bytes calldata call, address response) override external {
		_givenMethodReturn(call, uintToBytes(uint(response)));
	}

	function givenCalldataRevert(bytes calldata call) override external {
		calldataMockTypes[call] = MockType.Revert;
		calldataRevertMessage[call] = "";
		trackCalldataMock(call);
	}

	function givenMethodRevert(bytes calldata call) override external {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.Revert;
		trackMethodIdMock(method);		
	}

	function givenCalldataRevertWithMessage(bytes calldata call, string calldata message) override external {
		calldataMockTypes[call] = MockType.Revert;
		calldataRevertMessage[call] = message;
		trackCalldataMock(call);
	}

	function givenMethodRevertWithMessage(bytes calldata call, string calldata message) override external {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.Revert;
		methodIdRevertMessages[method] = message;
		trackMethodIdMock(method);		
	}

	function givenCalldataRunOutOfGas(bytes calldata call) override external {
		calldataMockTypes[call] = MockType.OutOfGas;
		trackCalldataMock(call);
	}

	function givenMethodRunOutOfGas(bytes calldata call) override external {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.OutOfGas;
		trackMethodIdMock(method);	
	}

	function invocationCount() override external returns (uint) {
		return invocations;
	}

	function invocationCountForMethod(bytes calldata call) override external returns (uint) {
		bytes4 method = bytesToBytes4(call);
		return methodIdInvocations[keccak256(abi.encodePacked(resetCount, method))];
	}

	function invocationCountForCalldata(bytes calldata call) override external returns (uint) {
		return calldataInvocations[keccak256(abi.encodePacked(resetCount, call))];
	}

	function reset() override external {
		// Reset all exact calldataMocks
		bytes memory nextMock = calldataMocks[MOCKS_LIST_START];
		bytes32 mockHash = keccak256(nextMock);
		// We cannot compary bytes
		while(mockHash != MOCKS_LIST_END_HASH) {
			// Reset all mock maps
			calldataMockTypes[nextMock] = MockType.Return;
			calldataExpectations[nextMock] = hex"";
			calldataRevertMessage[nextMock] = "";
			// Set next mock to remove
			nextMock = calldataMocks[mockHash];
			// Remove from linked list
			calldataMocks[mockHash] = "";
			// Update mock hash
			mockHash = keccak256(nextMock);
		}
		// Clear list
		calldataMocks[MOCKS_LIST_START] = MOCKS_LIST_END;

		// Reset all any calldataMocks
		bytes4 nextAnyMock = methodIdMocks[SENTINEL_ANY_MOCKS];
		while(nextAnyMock != SENTINEL_ANY_MOCKS) {
			bytes4 currentAnyMock = nextAnyMock;
			methodIdMockTypes[currentAnyMock] = MockType.Return;
			methodIdExpectations[currentAnyMock] = hex"";
			methodIdRevertMessages[currentAnyMock] = "";
			nextAnyMock = methodIdMocks[currentAnyMock];
			// Remove from linked list
			methodIdMocks[currentAnyMock] = 0x0;
		}
		// Clear list
		methodIdMocks[SENTINEL_ANY_MOCKS] = SENTINEL_ANY_MOCKS;

		fallbackExpectation = DEFAULT_FALLBACK_VALUE;
		fallbackMockType = MockType.Return;
		invocations = 0;
		resetCount += 1;
	}

	function useAllGas() private {
		while(true) {
			bool s;
			assembly {
				//expensive call to EC multiply contract
				s := call(sub(gas(), 2000), 6, 0, 0x0, 0xc0, 0x0, 0x60)
			}
		}
	}

	function bytesToBytes4(bytes memory b) private pure returns (bytes4) {
		bytes4 out;
		for (uint i = 0; i < 4; i++) {
			out |= bytes4(b[i] & 0xFF) >> (i * 8);
		}
		return out;
	}

	function uintToBytes(uint256 x) private pure returns (bytes memory b) {
		b = new bytes(32);
		assembly { mstore(add(b, 32), x) }
	}

	function updateInvocationCount(bytes4 methodId, bytes memory originalMsgData) public {
		require(msg.sender == address(this), "Can only be called from the contract itself");
		invocations += 1;
		methodIdInvocations[keccak256(abi.encodePacked(resetCount, methodId))] += 1;
		calldataInvocations[keccak256(abi.encodePacked(resetCount, originalMsgData))] += 1;
	}

	fallback () payable external {
		bytes4 methodId;
		assembly {
			methodId := calldataload(0)
		}

		// First, check exact matching overrides
		if (calldataMockTypes[msg.data] == MockType.Revert) {
			revert(calldataRevertMessage[msg.data]);
		}
		if (calldataMockTypes[msg.data] == MockType.OutOfGas) {
			useAllGas();
		}
		bytes memory result = calldataExpectations[msg.data];

		// Then check method Id overrides
		if (result.length == 0) {
			if (methodIdMockTypes[methodId] == MockType.Revert) {
				revert(methodIdRevertMessages[methodId]);
			}
			if (methodIdMockTypes[methodId] == MockType.OutOfGas) {
				useAllGas();
			}
			result = methodIdExpectations[methodId];
		}

		// Last, use the fallback override
		if (result.length == 0) {
			if (fallbackMockType == MockType.Revert) {
				revert(fallbackRevertMessage);
			}
			if (fallbackMockType == MockType.OutOfGas) {
				useAllGas();
			}
			result = fallbackExpectation;
		}

		// Record invocation as separate call so we don't rollback in case we are called with STATICCALL
		(, bytes memory r) = address(this).call{gas: 100000}(abi.encodeWithSignature("updateInvocationCount(bytes4,bytes)", methodId, msg.data));
		assert(r.length == 0);
		
		assembly {
			return(add(0x20, result), mload(result))
		}
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

contract GovernanceTokenProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _proxyAdmin,
        uint256 _totalSupply
    )
        public
        TransparentUpgradeableProxy(
            _logic,
            _proxyAdmin,
            abi.encodeWithSignature(
                "initialize(address,uint256)",
                _proxyAdmin,
                _totalSupply
            )
        )
    {} // solhint-disable no-empty-blocks
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "./interfaces/IAddressRegistryV2.sol";

/**
 * @title APY.Finance's address registry
 * @author APY.Finance
 * @notice The address registry has two important purposes, one which
 *         is fairly concrete and another abstract.
 *
 *         1. The registry enables components of the APY.Finance system
 *         and external systems to retrieve core addresses reliably
 *         even when the functionality may move to a different
 *         address.
 *
 *         2. The registry also makes explicit which contracts serve
 *         as primary entrypoints for interacting with different
 *         components.  Not every contract is registered here, only
 *         the ones properly deserving of an identifier.  This helps
 *         define explicit boundaries between groups of contracts,
 *         each of which is logically cohesive.
 */
contract AddressRegistryV2 is
    Initializable,
    OwnableUpgradeSafe,
    IAddressRegistryV2
{
    /* ------------------------------- */
    /* impl-specific storage variables */
    /* ------------------------------- */
    /** @notice the same address as the proxy admin; used
     *  to protect init functions for upgrades */
    address public proxyAdmin;
    bytes32[] internal _idList;
    mapping(bytes32 => address) internal _idToAddress;

    /* ------------------------------- */

    event AdminChanged(address);
    event AddressRegistered(bytes32 id, address _address);

    /**
     * @dev Since the proxy delegate calls to this "logic" contract, any
     * storage set by the logic contract's constructor during deploy is
     * disregarded and this function is needed to initialize the proxy
     * contract's storage according to this contract's layout.
     *
     * Since storage is not set yet, there is no simple way to protect
     * calling this function with owner modifiers.  Thus the OpenZeppelin
     * `initializer` modifier protects this function from being called
     * repeatedly.  It should be called during the deployment so that
     * it cannot be called by someone else later.
     *
     * NOTE: this function is copied from the V1 contract and has already
     * been called during V1 deployment.  It is included here for clarity.
     */
    function initialize(address adminAddress) external initializer {
        require(adminAddress != address(0), "INVALID_ADMIN");

        // initialize ancestor storage
        __Context_init_unchained();
        __Ownable_init_unchained();

        // initialize impl-specific storage
        setAdminAddress(adminAddress);
    }

    /**
     * @dev Dummy function to show how one would implement an init function
     * for future upgrades.  Note the `initializer` modifier can only be used
     * once in the entire contract, so we can't use it here.  Instead,
     * we set the proxy admin address as a variable and protect this
     * function with `onlyAdmin`, which only allows the proxy admin
     * to call this function during upgrades.
     */
    // solhint-disable-next-line no-empty-blocks
    function initializeUpgrade() external virtual onlyAdmin {}

    function setAdminAddress(address adminAddress) public onlyOwner {
        require(adminAddress != address(0), "INVALID_ADMIN");
        proxyAdmin = adminAddress;
        emit AdminChanged(adminAddress);
    }

    /**
     * @dev Throws if called by any account other than the proxy admin.
     */
    modifier onlyAdmin() {
        require(msg.sender == proxyAdmin, "ADMIN_ONLY");
        _;
    }

    /// @notice Returns the list of all registered identifiers.
    function getIds() public view override returns (bytes32[] memory) {
        return _idList;
    }

    /**
     * @notice Register address with identifier.
     * @dev Using an existing ID will replace the old address with new.
     *      Currently there is no way to remove an ID, as attempting to
     *      register the zero address will revert.
     */
    function registerAddress(bytes32 id, address _address) public onlyOwner {
        require(_address != address(0), "Invalid address");
        if (_idToAddress[id] == address(0)) {
            // id wasn't registered before, so add it to the list
            _idList.push(id);
        }
        _idToAddress[id] = _address;
        emit AddressRegistered(id, _address);
    }

    /// @dev Convenient method to register multiple addresses at once.
    function registerMultipleAddresses(
        bytes32[] calldata ids,
        address[] calldata addresses
    ) external onlyOwner {
        require(ids.length == addresses.length, "Inputs have differing length");
        for (uint256 i = 0; i < ids.length; i++) {
            bytes32 id = ids[i];
            address _address = addresses[i];
            registerAddress(id, _address);
        }
    }

    /// @notice Retrieve the address corresponding to the identifier.
    function getAddress(bytes32 id) public view override returns (address) {
        address _address = _idToAddress[id];
        require(_address != address(0), "Missing address");
        return _address;
    }

    /**
     * @dev Delete the address corresponding to the identifier.
     *      Time-complexity is O(n) where n is the length of `_idList`.
     */
    function deleteAddress(bytes32 id) public onlyOwner {
        for (uint256 i = 0; i < _idList.length; i++) {
            if (_idList[i] == id) {
                // copy last element to slot i and shorten array
                _idList[i] = _idList[_idList.length - 1];
                _idList.pop();
                delete _idToAddress[id];
                break;
            }
        }
    }

    /**
     * @notice Get the address for the Pool Manager.
     * @dev Not just a helper function, this makes explicit a key ID
     *      for the system.
     */
    function poolManagerAddress() public view override returns (address) {
        return getAddress("poolManager");
    }

    /**
     * @notice Get the address for the TVL Manager.
     * @dev Not just a helper function, this makes explicit a key ID
     *      for the system.
     */
    function tvlManagerAddress() public view override returns (address) {
        return getAddress("tvlManager");
    }

    /**
     * @notice An alias for the TVL Manager.  This is used by
     *         Chainlink nodes to compute the deployed value of the
     *         APY.Finance system.
     * @dev Not just a helper function, this makes explicit a key ID
     *      for the system.
     */
    function chainlinkRegistryAddress() public view override returns (address) {
        return tvlManagerAddress();
    }

    /**
     * @notice Get the address for APY.Finance's DAI stablecoin pool.
     * @dev Not just a helper function, this makes explicit a key ID
     *      for the system.
     */
    function daiPoolAddress() public view override returns (address) {
        return getAddress("daiPool");
    }

    /**
     * @notice Get the address for APY.Finance's USDC stablecoin pool.
     * @dev Not just a helper function, this makes explicit a key ID
     *      for the system.
     */
    function usdcPoolAddress() public view override returns (address) {
        return getAddress("usdcPool");
    }

    /**
     * @notice Get the address for APY.Finance's USDT stablecoin pool.
     * @dev Not just a helper function, this makes explicit a key ID
     *      for the system.
     */
    function usdtPoolAddress() public view override returns (address) {
        return getAddress("usdtPool");
    }

    function mAptAddress() public view override returns (address) {
        return getAddress("mApt");
    }

    /**
     * @notice Get the address for the APY.Finance LP Safe.
     */
    function lpSafeAddress() public view override returns (address) {
        return getAddress("lpSafe");
    }

    function oracleAdapterAddress() public view override returns (address) {
        return getAddress("oracleAdapter");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";

contract GovernanceToken is
    Initializable,
    OwnableUpgradeSafe,
    ERC20UpgradeSafe
{
    /* ------------------------------- */
    /* impl-specific storage variables */
    /* ------------------------------- */
    address public proxyAdmin;

    /* ------------------------------- */

    event AdminChanged(address);

    function initialize(address adminAddress, uint256 totalSupply)
        external
        initializer
    {
        require(adminAddress != address(0), "INVALID_ADMIN");

        // initialize ancestor storage
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC20_init_unchained("APY Governance Token", "APY");

        // initialize impl-specific storage
        setAdminAddress(adminAddress);

        _mint(msg.sender, totalSupply);
    }

    // solhint-disable-next-line no-empty-blocks
    function initializeUpgrade() external virtual onlyAdmin {}

    function setAdminAddress(address adminAddress) public onlyOwner {
        require(adminAddress != address(0), "INVALID_ADMIN");
        proxyAdmin = adminAddress;
        emit AdminChanged(adminAddress);
    }

    modifier onlyAdmin() {
        require(msg.sender == proxyAdmin, "ADMIN_ONLY");
        _;
    }

    receive() external payable {
        revert("DONT_SEND_ETHER");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../GovernanceToken.sol";

contract GovernanceTokenUpgraded is GovernanceToken {
    bool public newlyAddedVariable;

    function initializeUpgrade() public override onlyAdmin {
        newlyAddedVariable = true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

import "./IDetailedERC20.sol";
import "./IMintable.sol";

// solhint-disable no-empty-blocks
interface IMintableERC20 is IDetailedERC20, IMintable {

}

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}