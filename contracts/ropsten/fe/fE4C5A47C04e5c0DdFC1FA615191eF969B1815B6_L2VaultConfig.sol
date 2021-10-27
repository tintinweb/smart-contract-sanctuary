// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IL2VaultConfig.sol";
import "../interfaces/IComposableHolding.sol";
import "../interfaces/ITokenFactory.sol";
import "../libraries/FeeOperations.sol";
import "./VaultConfigBase.sol";

contract L2VaultConfig is VaultConfigBase, IL2VaultConfig {
    using SafeMath for uint256;

    uint256 nonce;
    uint256 public override minFee;
    uint256 public override maxFee;
    uint256 public override feeThreshold;
    uint256 public override transferLockupTime;
    uint256 public override minLimitLiquidityBlocks;
    uint256 public override maxLimitLiquidityBlocks;
    uint256 public constant override tokenRatio = 1000;
    address public override feeAddress;
    address public override wethAddress;
    string internal constant tokenName = "IOU-";

    // @dev remoteTokenAddress[networkID][addressHere] = addressThere
    mapping(uint256 => mapping(address => address))
        public
        override remoteTokenAddress;
    mapping(uint256 => mapping(address => uint256))
        public
        override remoteTokenRatio;
    mapping(address => uint256) public override lockedTransferFunds;

    /*
    UNISWAP = 2
    SUSHISWAP = 3
    CURVE = 4
    */
    mapping(uint256 => address) private supportedAMMs;

    /// @notice Public function to query the whitelisted tokens list
    /// @dev token address => WhitelistedToken struct
    mapping(address => WhitelistedToken) public whitelistedTokens;

    struct WhitelistedToken {
        uint256 minTransferAllowed;
        uint256 maxTransferAllowed;
        address underlyingReceiptAddress;
    }

    event MinFeeChanged(uint256 newMinFee);
    event MaxFeeChanged(uint256 newMaxFee);
    event MinLiquidityBlockChanged(uint256 newMinLimitLiquidityBlocks);
    event MaxLiquidityBlockChanged(uint256 newMaxLimitLiquidityBlocks);
    event ThresholdFeeChanged(uint256 newFeeThreshold);
    event FeeAddressChanged(address feeAddress);
    event LockupTimeChanged(
        address indexed _owner,
        uint256 _oldVal,
        uint256 _newVal,
        string valType
    );
    event TokenWhitelisted(address indexed erc20, address indexed newIou);
    event TokenWhitelistRemoved(address indexed erc20);
    event RemoteTokenAdded(
        address indexed _erc20,
        address indexed _remoteErc20,
        uint256 indexed _remoteNetworkID,
        uint256 _remoteTokenRatio
    );
    event RemoteTokenRemoved(
        address indexed erc20,
        uint256 indexed remoteNetworkID
    );

    constructor(address _feeAddress, address _composableHolding) {
        require(
            _composableHolding != address(0),
            "Invalid ComposableHolding address"
        );
        require(_feeAddress != address(0), "Invalid fee address");

        nonce = 0;
        // 0.25%
        minFee = 25;
        // 5%
        maxFee = 500;
        // 30% of liquidity
        feeThreshold = 30;
        transferLockupTime = 1 days;
        // 1 day
        minLimitLiquidityBlocks = 1;
        //yet to be decided
        maxLimitLiquidityBlocks = 100;

        feeAddress = _feeAddress;
        composableHolding = IComposableHolding(_composableHolding);
    }

    function setWethAddress(address _weth)
        external
        override
        onlyOwner
        validAddress(_weth)
    {
        wethAddress = _weth;
    }

    function getAMMAddress(uint256 ammID)
        external
        view
        override
        returns (address)
    {
        return supportedAMMs[ammID];
    }

    function getUnderlyingReceiptAddress(address token)
        external
        view
        override
        returns (address)
    {
        return whitelistedTokens[token].underlyingReceiptAddress;
    }

    // @notice: checks for the current balance of this contract's address on the ERC20 contract
    // @param tokenAddress  SC address of the ERC20 token to get liquidity from
    function getCurrentTokenLiquidity(address tokenAddress)
        public
        view
        override
        returns (uint256)
    {
        uint256 tokenBalance = getTokenBalance(tokenAddress);
        // remove the locked transfer funds from the balance of the vault
        return tokenBalance.sub(lockedTransferFunds[tokenAddress]);
    }

    function calculateFeePercentage(address tokenAddress, uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        uint256 tokenLiquidity = getTokenBalance(tokenAddress);

        if (tokenLiquidity == 0) {
            return maxFee;
        }

        if ((amount.mul(100)).div(tokenLiquidity) > feeThreshold) {
            // Flat fee since it's above threshold
            return maxFee;
        }

        uint256 maxTransfer = tokenLiquidity.mul(feeThreshold).div(100);
        uint256 percentTransfer = amount.mul(100).div(maxTransfer);

        return
            percentTransfer.mul(maxFee.sub(minFee)).add(minFee.mul(100)).div(
                100
            );
    }

    /// @notice Public function to add address of the AMM used to swap tokens
    /// @param ammID the integer constant for the AMM
    /// @param ammAddress Address of the AMM
    /// @dev AMM should be a wrapper created by us over the AMM implementation
    function addSupportedAMM(uint256 ammID, address ammAddress)
        public
        override
        onlyOwner
        validAddress(ammAddress)
    {
        supportedAMMs[ammID] = ammAddress;
    }

    /// @notice Public function to remove address of the AMM
    /// @param ammID the integer constant for the AMM
    function removeSupportedAMM(uint256 ammID) public override onlyOwner {
        delete supportedAMMs[ammID];
    }

    function changeRemoteTokenRatio(
        address _tokenAddress,
        uint256 _remoteNetworkID,
        uint256 _remoteTokenRatio
    )
        external
        override
        onlyOwner
        validAmount(remoteTokenRatio[_remoteNetworkID][_tokenAddress])
    {
        remoteTokenRatio[_remoteNetworkID][_tokenAddress] = _remoteTokenRatio;
    }

    // @notice: Adds a whitelisted token to the contract, allowing for anyone to deposit their tokens.
    /// @param tokenAddress  SC address of the ERC20 token to add to whitelisted tokens
    function addWhitelistedToken(
        address tokenAddress,
        uint256 minTransferAmount,
        uint256 maxTransferAmount
    ) external override onlyOwner validAddress(tokenAddress) {
        require(
            maxTransferAmount > minTransferAmount,
            "Invalid token economics"
        );

        require(
            whitelistedTokens[tokenAddress].underlyingReceiptAddress ==
                address(0),
            "Token already whitelisted"
        );

        address newIou = _deployIOU(tokenAddress);
        whitelistedTokens[tokenAddress].minTransferAllowed = minTransferAmount;
        whitelistedTokens[tokenAddress].maxTransferAllowed = maxTransferAmount;

        emit TokenWhitelisted(tokenAddress, newIou);
    }

    function addTokenInNetwork(
        address _tokenAddress,
        address _tokenAddressRemote,
        uint256 _remoteNetworkID,
        uint256 _remoteTokenRatio
    )
        external
        override
        onlyOwner
        validAddress(_tokenAddress)
        validAddress(_tokenAddressRemote)
    {
        require(
            whitelistedTokens[_tokenAddress].underlyingReceiptAddress !=
                address(0),
            "Token not whitelisted"
        );
        require(_remoteNetworkID > 0, "Invalid network ID");

        remoteTokenAddress[_remoteNetworkID][
            _tokenAddress
        ] = _tokenAddressRemote;
        remoteTokenRatio[_remoteNetworkID][_tokenAddress] = _remoteTokenRatio;

        emit RemoteTokenAdded(
            _tokenAddress,
            _tokenAddressRemote,
            _remoteNetworkID,
            _remoteTokenRatio
        );
    }

    function removeTokenInNetwork(
        address _tokenAddress,
        uint256 _remoteNetworkID
    ) external override onlyOwner validAddress(_tokenAddress) {
        require(_remoteNetworkID > 0, "Invalid network ID");
        require(
            remoteTokenAddress[_remoteNetworkID][_tokenAddress] != address(0),
            "Token not whitelisted in that network"
        );

        delete remoteTokenAddress[_remoteNetworkID][_tokenAddress];
        delete remoteTokenRatio[_remoteNetworkID][_tokenAddress];

        emit RemoteTokenRemoved(_tokenAddress, _remoteNetworkID);
    }

    // @notice: removes whitelisted token from the contract, avoiding new deposits and withdrawals.
    // @param tokenAddress  SC address of the ERC20 token to remove from whitelisted tokens
    function removeWhitelistedToken(address _tokenAddress)
        external
        override
        onlyOwner
    {
        require(
            whitelistedTokens[_tokenAddress].underlyingReceiptAddress !=
                address(0),
            "Token not whitelisted"
        );
        emit TokenWhitelistRemoved(_tokenAddress);
        delete whitelistedTokens[_tokenAddress];
    }

    function setTransferLockupTime(uint256 lockupTime)
        external
        override
        onlyOwner
    {
        emit LockupTimeChanged(
            msg.sender,
            transferLockupTime,
            lockupTime,
            "Transfer"
        );
        transferLockupTime = lockupTime;
    }

    function setLockedTransferFunds(address _token, uint256 _amount)
        external
        override
        validAddress(_token)
        onlyOwnerOrVault(msg.sender)
    {
        lockedTransferFunds[_token] = _amount;
    }

    // @notice: Updates the minimum fee
    // @param newMinFee
    function setMinFee(uint256 newMinFee) external override onlyOwner {
        require(
            newMinFee < FeeOperations.feeFactor,
            "Min fee cannot be more than fee factor"
        );
        require(newMinFee < maxFee, "Min fee cannot be more than max fee");

        minFee = newMinFee;
        emit MinFeeChanged(newMinFee);
    }

    // @notice: Updates the maximum fee
    // @param newMaxFee
    function setMaxFee(uint256 newMaxFee) external override onlyOwner {
        require(
            newMaxFee < FeeOperations.feeFactor,
            "Max fee cannot be more than fee factor"
        );
        require(newMaxFee > minFee, "Max fee cannot be less than min fee");

        maxFee = newMaxFee;
        emit MaxFeeChanged(newMaxFee);
    }

    // @notice: Updates the minimum limit liquidity block
    // @param newMinLimitLiquidityBlocks
    function setMinLimitLiquidityBlocks(uint256 newMinLimitLiquidityBlocks)
        external
        override
        onlyOwner
    {
        require(
            newMinLimitLiquidityBlocks < maxLimitLiquidityBlocks,
            "Min liquidity block cannot be more than max liquidity block"
        );

        minLimitLiquidityBlocks = newMinLimitLiquidityBlocks;
        emit MinLiquidityBlockChanged(newMinLimitLiquidityBlocks);
    }

    // @notice: Updates the maximum limit liquidity block
    // @param newMaxLimitLiquidityBlocks
    function setMaxLimitLiquidityBlocks(uint256 newMaxLimitLiquidityBlocks)
        external
        override
        onlyOwner
    {
        require(
            newMaxLimitLiquidityBlocks > minLimitLiquidityBlocks,
            "Max liquidity block cannot be lower than min liquidity block"
        );

        maxLimitLiquidityBlocks = newMaxLimitLiquidityBlocks;
        emit MaxLiquidityBlockChanged(newMaxLimitLiquidityBlocks);
    }

    // @notice: Updates the fee threshold
    // @param newThresholdFee
    function setThresholdFee(uint256 newThresholdFee)
        external
        override
        onlyOwner
    {
        require(
            newThresholdFee < 100,
            "Threshold fee cannot be more than threshold factor"
        );

        feeThreshold = newThresholdFee;
        emit ThresholdFeeChanged(newThresholdFee);
    }

    // @notice: Updates the account where to send deposit fees
    // @param newFeeAddress
    function setFeeAddress(address newFeeAddress) external override onlyOwner {
        require(newFeeAddress != address(0), "Invalid fee address");

        feeAddress = newFeeAddress;
        emit FeeAddressChanged(feeAddress);
    }

    function generateId()
        external
        override
        onlyVault(msg.sender)
        returns (bytes32)
    {
        nonce = nonce + 1;
        return keccak256(abi.encodePacked(block.number, vault, nonce));
    }

    /// @dev Internal function called when deploy a receipt IOU token based on already deployed ERC20 token
    function _deployIOU(address underlyingToken) private returns (address) {
        require(
            address(receiptTokenFactory) != address(0),
            "IOU token factory not initialized"
        );
        require(address(vault) != address(0), "Vault not initialized");

        address newIou = receiptTokenFactory.createIOU(
            underlyingToken,
            tokenName,
            vault
        );

        whitelistedTokens[underlyingToken].underlyingReceiptAddress = newIou;

        emit TokenReceiptCreated(underlyingToken);
        return newIou;
    }

    function inTokenTransferLimits(address _token, uint256 _amount)
        external
        view
        override
        returns (bool)
    {
        return (whitelistedTokens[_token].minTransferAllowed <= _amount &&
            whitelistedTokens[_token].maxTransferAllowed >= _amount);
    }

    modifier onlyOwnerOrVault(address _addr) {
        require(
            _addr == owner() || _addr == vault,
            "Only vault or owner can call this"
        );
        _;
    }

    modifier onlyVault(address _addr) {
        require(_addr == vault, "Only vault can call this");
        _;
    }

    modifier onlyWhitelistedRemoteTokens(
        uint256 networkID,
        address tokenAddress
    ) {
        require(
            whitelistedTokens[tokenAddress].underlyingReceiptAddress !=
                address(0),
            "Token not whitelisted"
        );
        require(
            remoteTokenAddress[networkID][tokenAddress] != address(0),
            "token not whitelisted in this network"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

import "./IComposableHolding.sol";
import "./IVaultConfigBase.sol";

interface IL2VaultConfig is IVaultConfigBase {
    function minFee() external view returns (uint256);

    function maxFee() external view returns (uint256);

    function feeThreshold() external view returns (uint256);

    function transferLockupTime() external view returns (uint256);

    function maxLimitLiquidityBlocks() external view returns (uint256);

    function tokenRatio() external view returns (uint256);

    function minLimitLiquidityBlocks() external view returns (uint256);

    function feeAddress() external view returns (address);

    function remoteTokenAddress(uint256 id, address token)
        external
        view
        returns (address);

    function remoteTokenRatio(uint256 id, address token)
        external
        view
        returns (uint256);

    function lockedTransferFunds(address token) external view returns (uint256);

    function getAMMAddress(uint256 networkId) external view returns (address);

    function calculateFeePercentage(address tokenAddress, uint256 amount)
        external
        view
        returns (uint256);

    function addSupportedAMM(uint256 ammID, address ammAddress) external;

    function removeSupportedAMM(uint256 ammID) external;

    function setTransferLockupTime(uint256 lockupTime) external;

    function setMinFee(uint256 newMinFee) external;

    function setMaxFee(uint256 newMaxFee) external;

    function setMinLimitLiquidityBlocks(uint256 newMinLimitLiquidityBlocks)
        external;

    function setMaxLimitLiquidityBlocks(uint256 newMaxLimitLiquidityBlocks)
        external;

    function setThresholdFee(uint256 newThresholdFee) external;

    function setFeeAddress(address newFeeAddress) external;

    function setLockedTransferFunds(address _token, uint256 _amount) external;

    function generateId() external returns (bytes32);

    function inTokenTransferLimits(address, uint256) external returns (bool);

    function addWhitelistedToken(
        address tokenAddress,
        uint256 minTransferAmount,
        uint256 maxTransferAmount
    ) external;

    function addTokenInNetwork(
        address _tokenAddress,
        address _tokenAddressRemote,
        uint256 _remoteNetworkID,
        uint256 _remoteTokenRatio
    ) external;

    function removeTokenInNetwork(
        address _tokenAddress,
        uint256 _remoteNetworkID
    ) external;

    function changeRemoteTokenRatio(
        address _tokenAddress,
        uint256 _remoteNetworkID,
        uint256 _remoteTokenRatio
    ) external;

    function removeWhitelistedToken(address _token) external;

    function getCurrentTokenLiquidity(address token)
        external
        view
        returns (uint256);

    function setWethAddress(address _weth) external;

    function wethAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IComposableHolding {
    function transfer(address _token, address _receiver, uint256 _amount) external;

    function setUniqRole(bytes32 _role, address _address) external;

    function approve(address spender, address token, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

/**
 * Created on 2021-06-07 08:50
 * @summary: Vault for storing ERC20 tokens that will be transferred by external event-based system to another network. The destination network can be checked on "connectedNetwork"
 * @author: Composable Finance - Pepe Blasco
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library FeeOperations {
    using SafeMath for uint256;

    uint256 internal constant feeFactor = 10000;

    function getFeeAbsolute(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return amount.mul(fee).div(feeFactor);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IReceiptBase is IERC20 {
    function burn(address from, uint256 amount) external;

    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}