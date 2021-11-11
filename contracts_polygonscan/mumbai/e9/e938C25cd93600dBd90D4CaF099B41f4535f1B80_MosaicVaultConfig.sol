// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IMosaicVaultConfig.sol";
import "../interfaces/IMosaicHolding.sol";
import "../interfaces/ITokenFactory.sol";
import "../libraries/FeeOperations.sol";
import "./VaultConfigBase.sol";

contract MosaicVaultConfig is VaultConfigBase, IMosaicVaultConfig {
    uint256 public constant override tokenRatio = 1000;
    string internal constant activeTokenName = "IOU-";
    string internal constant passiveTokenName = "R-";

    uint256 nonce;
    uint256 public override minFee;
    uint256 public override maxFee;
    uint256 public override feeThreshold;
    uint256 public override transferLockupTime;
    uint256 public override minLimitLiquidityBlocks;
    uint256 public override maxLimitLiquidityBlocks;
    uint256 public override saveFundsLockupTime;
    uint256 public override newSaveFundsLockUpTime;
    uint256 public override durationToChangeTimer;

    address public override feeAddress;
    address public override wethAddress;

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

    mapping(uint256 => bool) public override pausedNetwork;

    struct WhitelistedToken {
        uint256 minTransferAllowed;
        uint256 maxTransferAllowed;
        address underlyingIOUAddress;
        address underlyingReceiptAddress;
    }

    function initialize(address _feeAddress, address _mosaicHolding)
        public
        initializer
    {
        require(_mosaicHolding != address(0), "Invalid MosaicHolding address");
        require(_feeAddress != address(0), "Invalid fee address");

        __Ownable_init();

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

        saveFundsLockupTime = 12 hours;

        feeAddress = _feeAddress;
        mosaicHolding = IMosaicHolding(_mosaicHolding);
    }

    function setWethAddress(address _weth)
        external
        override
        onlyOwner
        validAddress(_weth)
    {
        wethAddress = _weth;
    }

    function getAMMAddress(uint256 _ammID)
        external
        view
        override
        returns (address)
    {
        return supportedAMMs[_ammID];
    }

    function getUnderlyingIOUAddress(address _token)
        external
        view
        override
        returns (address)
    {
        return whitelistedTokens[_token].underlyingIOUAddress;
    }

    function getUnderlyingReceiptAddress(address _token)
    external
    view
    override
    returns (address)
    {
        return whitelistedTokens[_token].underlyingReceiptAddress;
    }

    // @notice: checks for the current balance of this contract's address on the ERC20 contract
    // @param tokenAddress  SC address of the ERC20 token to get liquidity from
    function getCurrentTokenLiquidity(address _tokenAddress)
        public
        view
        override
        returns (uint256)
    {
        uint256 tokenBalance = getTokenBalance(_tokenAddress);
        // remove the locked transfer funds from the balance of the vault
        return tokenBalance - lockedTransferFunds[_tokenAddress];
    }

    function calculateFeePercentage(address _tokenAddress, uint256 _amount)
        external
        view
        override
        returns (uint256)
    {
        uint256 tokenLiquidity = getTokenBalance(_tokenAddress);

        if (tokenLiquidity == 0) {
            return maxFee;
        }

        if ((_amount * 100) / tokenLiquidity > feeThreshold) {
            // Flat fee since it's above threshold
            return maxFee;
        }

        uint256 maxTransfer = (tokenLiquidity * feeThreshold) / 100;
        uint256 percentTransfer = (_amount * 100) / maxTransfer;

        return percentTransfer * (maxFee - minFee) + (minFee * 100) / 100;
    }

    /// @notice Public function to add address of the AMM used to swap tokens
    /// @param _ammID the integer constant for the AMM
    /// @param _ammAddress Address of the AMM
    /// @dev AMM should be a wrapper created by us over the AMM implementation
    function addSupportedAMM(uint256 _ammID, address _ammAddress)
        public
        override
        onlyOwner
        validAddress(_ammAddress)
    {
        supportedAMMs[_ammID] = _ammAddress;
    }

    /// @notice Public function to remove address of the AMM
    /// @param _ammID the integer constant for the AMM
    function removeSupportedAMM(uint256 _ammID) public override onlyOwner {
        delete supportedAMMs[_ammID];
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
    /// @param _tokenAddress  SC address of the ERC20 token to add to whitelisted tokens
    function addWhitelistedToken(
        address _tokenAddress,
        uint256 _minTransferAmount,
        uint256 _maxTransferAmount
    ) external override onlyOwner validAddress(_tokenAddress) {
        require(
            _maxTransferAmount > _minTransferAmount,
            "Invalid token economics"
        );

        require(
            whitelistedTokens[_tokenAddress].underlyingIOUAddress == address(0),
            "Token already whitelisted"
        );

        (address newIou, address newReceipt) = _deployLiquidityTokens(_tokenAddress);

        whitelistedTokens[_tokenAddress]
            .minTransferAllowed = _minTransferAmount;

        whitelistedTokens[_tokenAddress]
            .maxTransferAllowed = _maxTransferAmount;

        emit TokenWhitelisted(_tokenAddress, newIou, newReceipt);
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
        notZero(_remoteNetworkID)
    {
        require(
            whitelistedTokens[_tokenAddress].underlyingIOUAddress != address(0),
            "Token not whitelisted"
        );

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
    )
        external
        override
        onlyOwner
        notZero(_remoteNetworkID)
        validAddress(_tokenAddress)
    {
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
            whitelistedTokens[_tokenAddress].underlyingIOUAddress != address(0),
            "Token not whitelisted"
        );
        emit TokenWhitelistRemoved(_tokenAddress);
        delete whitelistedTokens[_tokenAddress];
    }

    function setTransferLockupTime(uint256 _lockupTime)
        external
        override
        onlyOwner
    {
        emit LockupTimeChanged(
            msg.sender,
            transferLockupTime,
            _lockupTime,
            "Transfer"
        );
        transferLockupTime = _lockupTime;
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
    /// @param _newMinFee new minimum fee value
    function setMinFee(uint256 _newMinFee) external override onlyOwner {
        require(
            _newMinFee < FeeOperations.feeFactor,
            "Min fee cannot be more than fee factor"
        );
        require(_newMinFee < maxFee, "Min fee cannot be more than max fee");

        minFee = _newMinFee;
        emit MinFeeChanged(_newMinFee);
    }

    // @notice: Updates the maximum fee
    /// @param _newMaxFee new maximum fee value
    function setMaxFee(uint256 _newMaxFee) external override onlyOwner {
        require(
            _newMaxFee < FeeOperations.feeFactor,
            "Max fee cannot be more than fee factor"
        );
        require(_newMaxFee > minFee, "Max fee cannot be less than min fee");

        maxFee = _newMaxFee;
        emit MaxFeeChanged(_newMaxFee);
    }

    // @notice: Updates the minimum limit liquidity block
    /// @param _newMinLimitLiquidityBlocks new minimum limit liquidity block value
    function setMinLimitLiquidityBlocks(uint256 _newMinLimitLiquidityBlocks)
        external
        override
        onlyOwner
    {
        require(
            _newMinLimitLiquidityBlocks < maxLimitLiquidityBlocks,
            "Min liquidity block cannot be more than max liquidity block"
        );

        minLimitLiquidityBlocks = _newMinLimitLiquidityBlocks;
        emit MinLiquidityBlockChanged(_newMinLimitLiquidityBlocks);
    }

    // @notice: Updates the maximum limit liquidity block
    /// @param _newMaxLimitLiquidityBlocks new maximum limit liquidity block value
    function setMaxLimitLiquidityBlocks(uint256 _newMaxLimitLiquidityBlocks)
        external
        override
        onlyOwner
    {
        require(
            _newMaxLimitLiquidityBlocks > minLimitLiquidityBlocks,
            "Max liquidity block cannot be lower than min liquidity block"
        );

        maxLimitLiquidityBlocks = _newMaxLimitLiquidityBlocks;
        emit MaxLiquidityBlockChanged(_newMaxLimitLiquidityBlocks);
    }

    // @notice: Updates the fee threshold
    /// @param _newThresholdFee new fee threshold value
    function setThresholdFee(uint256 _newThresholdFee)
        external
        override
        onlyOwner
    {
        require(
            _newThresholdFee < 100,
            "Threshold fee cannot be more than threshold factor"
        );

        feeThreshold = _newThresholdFee;
        emit ThresholdFeeChanged(_newThresholdFee);
    }

    // @notice: Updates the account where to send deposit fees
    /// @param _newFeeAddress new fee address
    function setFeeAddress(address _newFeeAddress) external override onlyOwner {
        require(_newFeeAddress != address(0), "Invalid fee address");

        feeAddress = _newFeeAddress;
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
    function _deployLiquidityTokens(address _underlyingToken) private returns (address, address) {
        require(
            address(tokenFactory) != address(0),
            "IOU token factory not initialized"
        );
        require(address(vault) != address(0), "Vault not initialized");

        address newIou = tokenFactory.createIOU(
            _underlyingToken,
            activeTokenName,
            vault
        );

        address newReceipt = tokenFactory.createReceipt(
            _underlyingToken,
            passiveTokenName,
            vault
        );

        whitelistedTokens[_underlyingToken].underlyingIOUAddress = newIou;
        whitelistedTokens[_underlyingToken].underlyingReceiptAddress = newReceipt;

        emit TokenCreated(_underlyingToken);
        return (newIou, newReceipt);
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

    /**
    * @notice starts save funds lockup timer change.
     * @param _time lock up time duration
     */

    function startSaveFundsLockUpTimerChange(uint256 _time)
    external
    override
    onlyOwner
    validAmount(_time)
    {
        newSaveFundsLockUpTime = _time;
        durationToChangeTimer = saveFundsLockupTime + block.timestamp;

        emit SaveFundsLockUpTimerStarted(
            msg.sender,
            _time,
            durationToChangeTimer
        );
    }

    /**
     * @notice set save funds lockup time.
     */

    function setSaveFundsLockUpTime() external override onlyOwner {
        require(
            durationToChangeTimer <= block.timestamp &&
            durationToChangeTimer != 0,
            "action not yet possible"
        );

        saveFundsLockupTime = newSaveFundsLockUpTime;
        durationToChangeTimer = 0;

        emit SaveFundsLockUpTimeSet(
            msg.sender,
            saveFundsLockupTime,
            durationToChangeTimer
        );
    }

    /// @notice External callable function to pause the contract
    function pauseNetwork(uint256 _networkID) external override onlyOwner {
        pausedNetwork[_networkID] = true;
        emit PauseNetwork(msg.sender, _networkID);
    }

    /// @notice External callable function to unpause the contract
    function unpauseNetwork(uint256 _networkID) external override onlyOwner {
        pausedNetwork[_networkID] = false;
        emit UnpauseNetwork(msg.sender, _networkID);
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
        uint256 _networkID,
        address _tokenAddress
    ) {
        require(
            whitelistedTokens[_tokenAddress].underlyingIOUAddress != address(0),
            "Token not whitelisted"
        );
        require(
            remoteTokenAddress[_networkID][_tokenAddress] != address(0),
            "token not whitelisted in this network"
        );
        _;
    }

    modifier notZero(uint256 _value) {
        require(_value > 0, "Zero value not allowed");
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

import "./IMosaicHolding.sol";
import "./IVaultConfigBase.sol";

interface IMosaicVaultConfig is IVaultConfigBase {
    event MinFeeChanged(uint256 newMinFee);
    event MaxFeeChanged(uint256 newMaxFee);
    event MinLiquidityBlockChanged(uint256 newMinLimitLiquidityBlocks);
    event MaxLiquidityBlockChanged(uint256 newMaxLimitLiquidityBlocks);
    event ThresholdFeeChanged(uint256 newFeeThreshold);
    event FeeAddressChanged(address feeAddress);
    event LockupTimeChanged(
        address indexed owner,
        uint256 oldVal,
        uint256 newVal,
        string valType
    );
    event TokenWhitelisted(address indexed erc20, address indexed newIou, address indexed newReceipt);
    event TokenWhitelistRemoved(address indexed erc20);
    event RemoteTokenAdded(
        address indexed erc20,
        address indexed remoteErc20,
        uint256 indexed remoteNetworkID,
        uint256 remoteTokenRatio
    );
    event RemoteTokenRemoved(
        address indexed erc20,
        uint256 indexed remoteNetworkID
    );

    event SaveFundsLockUpTimerStarted(
        address owner,
        uint256 time,
        uint256 durationToChangeTime
    );

    event SaveFundsLockUpTimeSet(
        address owner,
        uint256 time,
        uint256 durationToChangeTime
    );

    event PauseNetwork(address admin, uint256 networkID);

    event UnpauseNetwork(address admin, uint256 networkID);

    function minFee() external view returns (uint256);

    function pausedNetwork(uint256) external view returns (bool);

    function maxFee() external view returns (uint256);

    function feeThreshold() external view returns (uint256);

    function transferLockupTime() external view returns (uint256);

    function maxLimitLiquidityBlocks() external view returns (uint256);

    function tokenRatio() external view returns (uint256);

    function minLimitLiquidityBlocks() external view returns (uint256);

    function feeAddress() external view returns (address);

    function saveFundsLockupTime() external view returns (uint256);

    function newSaveFundsLockUpTime() external view returns (uint256);

    function durationToChangeTimer() external view returns (uint256);

    function remoteTokenAddress(uint256 _id, address _token)
        external
        view
        returns (address);

    function remoteTokenRatio(uint256 _id, address _token)
        external
        view
        returns (uint256);

    function lockedTransferFunds(address _token)
        external
        view
        returns (uint256);

    function getAMMAddress(uint256 _networkId) external view returns (address);

    /**
     * @dev used to calculate fee percentage.
     * @param _tokenAddress  SC address of the ERC20 token to deposit
     * @param _amount amount of tokens to deposit
     */
    function calculateFeePercentage(address _tokenAddress, uint256 _amount)
        external
        view
        returns (uint256);

    /**
     * @dev used to add address of the AMM used to swap tokens.
     * @param _ammID the integer constant for the AMM
     * @param _ammAddress Address of the AMM
     */

    function addSupportedAMM(uint256 _ammID, address _ammAddress) external;

    /**
     * @dev used to remove address of the AMM.
     * @param _ammID the integer constant for the AMM
     */
    function removeSupportedAMM(uint256 _ammID) external;

    /**
     * @dev used to set transfer lockup time.
     * @param _lockupTime  value to be set as new lock up duration
     */
    function setTransferLockupTime(uint256 _lockupTime) external;

    /**
     * @dev updates the minimum fee.
     * @param _newMinFee  value to be set as new minimum fee
     */

    function setMinFee(uint256 _newMinFee) external;

    /**
     * @dev updates the maximum fee.
     * @param _newMaxFee  value to be set as new minimum fee
     */

    function setMaxFee(uint256 _newMaxFee) external;

    /**
     * @dev updates the minimum limit liquidity block.
     * @param _newMinLimitLiquidityBlocks value to be set as new minimum limit liquidity block
     */

    function setMinLimitLiquidityBlocks(uint256 _newMinLimitLiquidityBlocks)
        external;

    /**
     * @dev updates the maximum limit liquidity block.
     * @param _newMaxLimitLiquidityBlocks value to be set as new maximum limit liquidity block
     */

    function setMaxLimitLiquidityBlocks(uint256 _newMaxLimitLiquidityBlocks)
        external;

    /**
     * @dev updates the fee threshold.
     * @param _newThresholdFee value to be set as new threshold fee

     */

    function setThresholdFee(uint256 _newThresholdFee) external;

    /**
     * @dev updates the account where to send deposit fees.
     * @param _newFeeAddress value to be set as new fee address
     */

    function setFeeAddress(address _newFeeAddress) external;

    function setLockedTransferFunds(address _token, uint256 _amount) external;

    function generateId() external returns (bytes32);

    function inTokenTransferLimits(address, uint256) external returns (bool);

    /**
     * @dev used to adds a whitelisted token to the contract.
     * @param _tokenAddress  SC address of the ERC20 token to add to supported tokens
     * @param _minTransferAmount Minimum amount of token can be transferred
     * @param _maxTransferAmount  Maximum amount of token can be transferred
     */

    function addWhitelistedToken(
        address _tokenAddress,
        uint256 _minTransferAmount,
        uint256 _maxTransferAmount
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

    /**
     * @dev used to removes whitelisted token from the contract.
     * @param _token  SC address of the ERC20 token to remove from supported tokens
     */
    function removeWhitelistedToken(address _token) external;

    /**
     * @dev checks for the current balance of this contract's address on the ERC20 contract.
     * @param _token SC address of the ERC20 token to get liquidity from
     */
    function getCurrentTokenLiquidity(address _token)
        external
        view
        returns (uint256);

    function setWethAddress(address _weth) external;

    function wethAddress() external view returns (address);

    function getUnderlyingIOUAddress(address _token)
        external
        view
        returns (address);

    function getUnderlyingReceiptAddress(address _token)
    external
    view
    returns (address);

    /**
    * @dev set save funds lock up time.
     */

    function setSaveFundsLockUpTime() external;

    /**
    * @dev starts save funds lockup timer change.
     * @param _time lock up time duration
     */

    function startSaveFundsLockUpTimerChange(uint256 _time) external;

    /**
    * @dev used to pause a network.
     * @param _networkID  network ID of remote token
     */

    function pauseNetwork(uint256 _networkID) external;

    /**
     * @dev used to unpause a network.
     * @param _networkID  network ID of remote token
     */

    function unpauseNetwork(uint256 _networkID) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMosaicHolding {
    function transfer(
        address _token,
        address _receiver,
        uint256 _amount
    ) external;

    function setUniqRole(bytes32 _role, address _address) external;

    function approve(
        address _spender,
        address _token,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITokenFactory {
    function createIOU(
        address _underlyingAddress,
        string calldata _tokenName,
        address _owner
    ) external returns (address);

    function createReceipt(
        address _underlyingAddress,
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


library FeeOperations {

    uint256 internal constant feeFactor = 10000;

    function getFeeAbsolute(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return amount * fee / feeFactor;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IMosaicHolding.sol";
import "../interfaces/ITokenFactory.sol";
import "../interfaces/IReceiptBase.sol";
import "../interfaces/IVaultConfigBase.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract VaultConfigBase is IVaultConfigBase, OwnableUpgradeable {
    ITokenFactory internal tokenFactory;
    IMosaicHolding internal mosaicHolding;

    address public vault;

    /// @notice Get mosaicHolding
    function getMosaicHolding() external view override returns (address) {
        return address(mosaicHolding);
    }

    function setVault(address _vault)
        external
        override
        validAddress(_vault)
        onlyOwner
    {
        vault = _vault;
    }

    /// @notice External function used to set the Token Factory Address
    /// @dev Address of the factory need to be set after the initialization in order to use the vault
    /// @param _tokenFactoryAddress Address of the already deployed Token Factory
    function setTokenFactoryAddress(address _tokenFactoryAddress)
        external
        override
        onlyOwner
        validAddress(_tokenFactoryAddress)
    {
        tokenFactory = ITokenFactory(_tokenFactoryAddress);
    }

    function getTokenBalance(address _token)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            address(mosaicHolding) != address(0),
            "Mosaic Holding address not set"
        );
        return IERC20(_token).balanceOf(address(mosaicHolding));
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
    event TokenCreated(address _underlyingToken);

    function getMosaicHolding() external view returns (address);

    function getTokenBalance(address _token) external view returns (uint256);

    function setTokenFactoryAddress(address _tokenFactoryAddress) external;

    function setVault(address _vault) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IReceiptBase is IERC20 {
    function burn(address _from, uint256 _amount) external;

    function mint(address _to, uint256 _amount) external;

    function underlyingToken() external returns(address);
    
    function isIOU() external view returns (bool);
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