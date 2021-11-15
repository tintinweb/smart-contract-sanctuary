// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IL1VaultConfig.sol";
import "../interfaces/IComposableHolding.sol";
import "../interfaces/ITokenFactory.sol";
import "./VaultConfigBase.sol";

contract L1VaultConfig is VaultConfigBase, IL1VaultConfig {
    string internal constant override tokenName = "R-";

    /// @notice Public function to query the supported wallets
    /// @dev wallet address => bool supported/not supported
    mapping(address => bool) public override whitelistedWallets;

    /// @notice Public function to query the supported tokens list
    /// @dev token address => WhitelistedToken struct
    mapping(address => WhitelistedToken) public whitelistedTokens;

    struct WhitelistedToken
    {
        uint256 maxAssetCap;
        address underlyingReceiptAddress;
        bool allowToWithdraw;
    }

    /// @notice event emitted when a new wallet is added to the whitelist
    /// @param wallet address of the wallet
    event WalletAddedToWhitelist(address indexed wallet);

    /// @notice event emitted when a wallet is removed from the whitelist
    /// @param wallet address of the wallet
    event WalletRemovedFromWhitelist(address indexed wallet);

    constructor(address _composableHolding) public {
        require(
            _composableHolding != address(0),
            "Invalid ComposableHolding address"
        );
        composableHolding = IComposableHolding(_composableHolding);
    }

    /// @notice external function used to define a max cap per asset
    /// @param _token Token address
    /// @param _maxCap Cap
    function setMaxCapAsset(address _token, uint256 _maxCap)
    external
    override
    onlySupportedToken(_token)
    validAmount(_maxCap)
    onlyOwnerOrVault(msg.sender)
    {
        require(getTokenBalance(_token) <= _maxCap, "Current token balance is higher");
        whitelistedTokens[_token].maxAssetCap = _maxCap;
    }


    /// @notice External function used to set the underlying Receipt Address
    /// @param _token Underlying token
    /// @param _receipt Receipt token
    function setUnderlyingReceiptAddress(address _token, address _receipt)
    external
    override
    onlyOwner
    validAddress(_token)
    validAddress(_receipt)
    {
        whitelistedTokens[_token].underlyingReceiptAddress = _receipt;
    }

    function getUnderlyingReceiptAddress(address _token)
    external
    override
    view
    returns(address)
    {
        return whitelistedTokens[_token].underlyingReceiptAddress;
    }

    /// @notice external function used to add token in the whitelist
    /// @param _token ERC20 token address
    function addWhitelistedToken(address _token, uint256 _maxCap)
    external
    override
    onlyOwner
    validAddress(_token)
    validAmount(_maxCap)
    {
        whitelistedTokens[_token].maxAssetCap = _maxCap;
        _deployReceipt(_token);
    }

    /// @notice external function used to remove token from the whitelist
    /// @param _token ERC20 token address
    function removeWhitelistedToken(address _token)
    external
    override
    onlyOwner
    validAddress(_token)
    {
        delete whitelistedTokens[_token];
    }

    /// @notice external function used to add wallet in the whitelist
    /// @param _wallet Wallet address
    function addWhitelistedWallet(address _wallet)
    external
    onlyOwner
    validAddress(_wallet)
    {
        whitelistedWallets[_wallet] = true;

        emit WalletAddedToWhitelist(_wallet);
    }

    /// @notice external function used to remove wallet from the whitelist
    /// @param _wallet Wallet address
    function removeWhitelistedWallet(address _wallet)
    external
    onlyOwner
    validAddress(_wallet)
    {
        require(whitelistedWallets[_wallet] == true, "Not registered");
        delete whitelistedWallets[_wallet];

        emit WalletRemovedFromWhitelist(_wallet);
    }

    /// @notice External function called by the owner to pause asset withdrawal
    /// @param _token address of the ERC20 token
    function pauseWithdraw(address _token)
    external
    override
    onlySupportedToken(_token)
    onlyOwner
    {
        require(whitelistedTokens[_token].allowToWithdraw, "Already paused");
        delete whitelistedTokens[_token].allowToWithdraw;
    }

    /// @notice External function called by the owner to unpause asset withdrawal
    /// @param _token address of the ERC20 token
    function unpauseWithdraw(address _token)
    external
    override
    onlySupportedToken(_token)
    onlyOwner
    {
        require(!whitelistedTokens[_token].allowToWithdraw, "Already allowed");
        whitelistedTokens[_token].allowToWithdraw = true;
    }

    /// @dev Internal function called when deploy a receipt Receipt token based on already deployed ERC20 token
    function _deployReceipt(address underlyingToken) private returns (address) {
        require(
            address(receiptTokenFactory) != address(0),
            "Receipt token factory not initialized"
        );
        require(address(vault) != address(0), "Vault not initialized");

        address newReceipt = receiptTokenFactory.createReceipt(
            underlyingToken,
            tokenName,
            vault
        );
        whitelistedTokens[underlyingToken].underlyingReceiptAddress = newReceipt;
        emit TokenReceiptCreated(underlyingToken);
        return newReceipt;
    }

    function isTokenSupported(address _token) public override view returns(bool) {
        return whitelistedTokens[_token].underlyingReceiptAddress != address(0);
    }

    function allowToWithdraw(address _token) public override view returns(bool) {
        return whitelistedTokens[_token].allowToWithdraw;
    }

    function getMaxAssetCap(address _token) external override view returns(uint) {
        return whitelistedTokens[_token].maxAssetCap;
    }

    modifier onlyOwnerOrVault(address _addr) {
        require(
            _addr == owner() || _addr == vault,
            "Only vault or owner can call this"
        );
        _;
    }

    modifier onlySupportedToken(address _tokenAddress) {
        require(isTokenSupported(_tokenAddress), "Token is not supported");
        _;
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
// @unsupported: ovm
pragma solidity ^0.6.8;

import "./IVaultConfigBase.sol";

interface IL1VaultConfig is IVaultConfigBase {
    function allowToWithdraw(address token) external view returns (bool);

    function getMaxAssetCap(address token) external view returns (uint256);

    function whitelistedWallets(address wallet) external view returns (bool);

    function setUnderlyingReceiptAddress(address _token, address _receipt)
    external;

    function setMaxCapAsset(address _token, uint256 _maxCap) external;

    function pauseWithdraw(address _token) external;

    function unpauseWithdraw(address _token) external;

    function isTokenSupported(address) external view returns(bool);

    function addWhitelistedToken(address _token, uint256 _maxCap) external;

    function removeWhitelistedToken(address _token) external;
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

interface IComposableHolding {
    function transfer(address _token, address _receiver, uint256 _amount) external;

    function setUniqRole(bytes32 _role, address _address) external;

    function approve(address spender, address token, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

interface ITokenFactory {
    function createIOU(
        address underlyingAddress,
        string calldata _tokenName,
        address _owner
    ) external returns (address);

    function createReceipt(
        address underlyingAddress,
        string calldata _tokenName,
        address _owner
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IComposableHolding.sol";
import "../interfaces/ITokenFactory.sol";
import "../interfaces/IReceiptBase.sol";
import "../interfaces/IVaultConfigBase.sol";

abstract contract VaultConfigBase is IVaultConfigBase, Ownable {
    ITokenFactory internal receiptTokenFactory;
    IComposableHolding internal composableHolding;

    address public vault;

    event TokenReceiptCreated(address underlyingToken);

    /// @notice Get ComposableHolding
    function getComposableHolding() external view override returns (address) {
        return address(composableHolding);
    }

    function setVault(address _vault)
    external
    override
    validAddress(_vault)
    onlyOwner
    {
        vault = _vault;
    }

    /// @notice External function used to set the Receipt Token Factory Address
    /// @dev Address of the factory need to be set after the initialization in order to use the vault
    /// @param receiptTokenFactoryAddress Address of the already deployed Receipt Token Factory
    function setReceiptTokenFactoryAddress(address receiptTokenFactoryAddress)
    external
    override
    onlyOwner
    validAddress(receiptTokenFactoryAddress)
    {
        receiptTokenFactory = ITokenFactory(receiptTokenFactoryAddress);
    }

    function getTokenBalance(address _token) virtual public override view returns (uint256) {
        require(
            address(composableHolding) != address(0),
            "Composable Holding address not set"
        );
        return IERC20(_token).balanceOf(address(composableHolding));
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Invalid address");
        _;
    }

    modifier validAmount(uint256 _value) {
        require(_value > 0, "Invalid amount");
        _;
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

interface IVaultConfigBase {
    function getComposableHolding() external view returns (address);

    function getTokenBalance(address _token) external view returns (uint256);

    function setReceiptTokenFactoryAddress(address receiptTokenFactoryAddress)
    external;

    function getUnderlyingReceiptAddress(address token)
    external
    view
    returns (address);

    function setVault(address _vault) external;
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
// @unsupported: ovm
pragma solidity ^0.6.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IReceiptBase is IERC20 {
    function burn(address from, uint256 amount) external;

    function mint(address to, uint256 amount) external;
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

