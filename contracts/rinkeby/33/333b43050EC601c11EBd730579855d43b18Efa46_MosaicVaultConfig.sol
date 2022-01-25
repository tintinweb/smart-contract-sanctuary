// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IMosaicVaultConfig.sol";
import "../interfaces/IMosaicHolding.sol";
import "../interfaces/ITokenFactory.sol";
import "../libraries/FeeOperations.sol";
import "./VaultConfigBase.sol";

contract MosaicVaultConfig is IMosaicVaultConfig, VaultConfigBase {
    /// @notice ratio for token transfers. 1000 -> 1:1 transfer
    uint256 public constant TOKEN_RATIO = 1000;
    uint256 private nonce;
    string private constant ACTIVE_TOKEN_NAME = "IOU-";
    string private constant PASSIVE_TOKEN_NAME = "R-";

    /// @notice lock time for passive liquidity
    uint256 public override passiveLiquidityLocktime;
    /// @notice min fee per transfer
    uint256 public override minFee;
    /// @notice max fee per transfer
    uint256 public override maxFee;
    /// @notice minimum number of blocks to provide liquidity
    uint256 public override minLimitLiquidityBlocks;
    /// @notice maximum number of blocks to provide liquidity
    uint256 public override maxLimitLiquidityBlocks;

    /// @notice Address of ERC20 wrap eth
    address public override wethAddress;

    /// @notice Store address of a token in another network
    // @dev remoteTokenAddress[networkID][addressHere] = addressThere
    mapping(uint256 => mapping(address => address)) public override remoteTokenAddress;
    /// @notice Ratio of token in another network
    mapping(uint256 => mapping(address => uint256)) public override remoteTokenRatio;

    /*
    UNISWAP = 2
    SUSHISWAP = 3
    CURVE = 4
    */
    mapping(uint256 => address) public override supportedAMMs;

    /// @notice Public function to query the whitelisted tokens list
    /// @dev token address => WhitelistedToken struct
    mapping(address => WhitelistedToken) public whitelistedTokens;

    /// @notice Public reference to the paused networks
    mapping(uint256 => bool) public override pausedNetwork;

    /// @notice flag that indicates if part of a Mosaic transfer or liquidity withdrawal
    ///         can be swapped into the native token of the destination network
    bool public override ableToPerformSmallBalanceSwap;

    /// @notice Public reference to the addresses of the NativeSwapper contracts used to swap
    ///         a part of a transfer or liquidity withdrawal to native token
    mapping(uint256 => address) public override supportedMosaicNativeSwappers;

    /// @notice Initialize function to set up the contract
    /// @dev it should be called immediately after deploy
    /// @param _mosaicHolding Address of the MosaicHolding contract
    function initialize(address _mosaicHolding) public initializer {
        require(_mosaicHolding != address(0), "ERR: HOLDING ADDRESS");

        __Ownable_init();

        nonce = 0;
        // 0%
        minFee = 0;
        // 5%
        maxFee = 500;
        // 1 day
        minLimitLiquidityBlocks = 1;
        maxLimitLiquidityBlocks = 100;
        passiveLiquidityLocktime = 1 days;
        mosaicHolding = IMosaicHolding(_mosaicHolding);
    }

    /// @notice sets the lock time for passive liquidity
    /// @param _locktime new lock time for passive liquidity
    function setPassiveLiquidityLocktime(uint256 _locktime) external override onlyOwner {
        passiveLiquidityLocktime = _locktime;
    }

    /// @notice External function called by owner to set the ERC20 WETH address
    /// @param _weth address of the WETH
    /// @param _minTransferAmount min amount of ETH that can be transfered
    /// @param _maxTransferAmount max amount of ETH that can be transfered
    function setWethAddress(
        address _weth,
        uint256 _minTransferAmount,
        uint256 _maxTransferAmount
    ) external override onlyOwner validAddress(_weth) {
        if (wethAddress != address(0)) {
            _removeWhitelistedToken(wethAddress);
        }

        _addWhitelistedToken(_weth, _minTransferAmount, _maxTransferAmount);
        wethAddress = _weth;
    }

    /// @notice Get IOU address of an ERC20 token
    /// @param _token address of the token whose underlying IOU we are requesting
    function getUnderlyingIOUAddress(address _token) external view override returns (address) {
        return whitelistedTokens[_token].underlyingIOUAddress;
    }

    /// @notice Get Receipt address of an ERC20 token
    /// @param _token address of the token whose underlying Receipt we are requesting
    function getUnderlyingReceiptAddress(address _token) external view override returns (address) {
        return whitelistedTokens[_token].underlyingReceiptAddress;
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

    /// @notice External function called by the owner in order to change remote token ration
    /// @param _tokenAddress Address of the token in this network
    /// @param _remoteNetworkID Network Id
    /// @param _remoteTokenRatio New token ratio
    function changeRemoteTokenRatio(
        address _tokenAddress,
        uint256 _remoteNetworkID,
        uint256 _remoteTokenRatio
    ) external override onlyOwner validAmount(remoteTokenRatio[_remoteNetworkID][_tokenAddress]) {
        remoteTokenRatio[_remoteNetworkID][_tokenAddress] = _remoteTokenRatio;
    }

    /// @notice Adds a whitelisted token to the contract, allowing for anyone to deposit their tokens.
    /// @param _tokenAddress SC address of the ERC20 token to add to whitelisted tokens
    /// @param _minTransferAmount min amount of tokens that can be transfered
    /// @param _maxTransferAmount max amount of tokens that can be transfered
    function addWhitelistedToken(
        address _tokenAddress,
        uint256 _minTransferAmount,
        uint256 _maxTransferAmount
    ) external override onlyOwner validAddress(_tokenAddress) {
        _addWhitelistedToken(_tokenAddress, _minTransferAmount, _maxTransferAmount);
    }

    /// @notice Internal function that adds a whitelisted token to the contract, allowing for anyone to deposit their tokens
    /// @param _tokenAddress SC address of the ERC20 token to add to whitelisted tokens
    /// @param _minTransferAmount min amount of tokens that can be transfered
    /// @param _maxTransferAmount max amount of tokens that can be transfered
    function _addWhitelistedToken(
        address _tokenAddress,
        uint256 _minTransferAmount,
        uint256 _maxTransferAmount
    ) private nonReentrant {
        require(_maxTransferAmount > _minTransferAmount, "ERR: MAX > MIN");

        require(
            whitelistedTokens[_tokenAddress].underlyingIOUAddress == address(0),
            "ERR: ALREADY WHITELISTED"
        );

        (address newIou, address newReceipt) = _deployLiquidityTokens(_tokenAddress);

        whitelistedTokens[_tokenAddress].minTransferAllowed = _minTransferAmount;

        whitelistedTokens[_tokenAddress].maxTransferAllowed = _maxTransferAmount;

        emit TokenWhitelisted(_tokenAddress, newIou, newReceipt);
    }

    /// @dev Private function called when deploy a receipt IOU token based on already deployed ERC20 token
    /// @param _underlyingToken address of the underlying token
    function _deployLiquidityTokens(address _underlyingToken) private returns (address, address) {
        require(address(tokenFactory) != address(0), "ERR: FACTORY INIT");
        require(address(vault) != address(0), "ERR: VAULT INIT");

        address newIou = tokenFactory.createIOU(_underlyingToken, ACTIVE_TOKEN_NAME, vault);

        address newReceipt = tokenFactory.createReceipt(
            _underlyingToken,
            PASSIVE_TOKEN_NAME,
            vault
        );

        whitelistedTokens[_underlyingToken].underlyingIOUAddress = newIou;
        whitelistedTokens[_underlyingToken].underlyingReceiptAddress = newReceipt;

        emit TokenCreated(_underlyingToken);
        return (newIou, newReceipt);
    }

    /// @notice removes whitelisted token from the contract, avoiding new deposits and withdrawals.
    /// @param _tokenAddress SC address of the ERC20 token to remove from whitelisted tokens
    function removeWhitelistedToken(address _tokenAddress) external override onlyOwner {
        _removeWhitelistedToken(_tokenAddress);
    }

    /// @notice private function that removes whitelisted token from the contract, avoiding new deposits and withdrawals.
    /// @param _tokenAddress SC address of the ERC20 token to remove from whitelisted tokens
    function _removeWhitelistedToken(address _tokenAddress) private {
        require(
            whitelistedTokens[_tokenAddress].underlyingIOUAddress != address(0),
            "ERR: NOT WHITELISTED"
        );
        emit TokenWhitelistRemoved(_tokenAddress);
        delete whitelistedTokens[_tokenAddress];
    }

    /// @notice External function called by the owner to add whitelisted token in network
    /// @param _tokenAddress Address of the token in this network
    /// @param _tokenAddressRemote Address of the token in destination network
    /// @param _remoteNetworkID Network Id
    /// @param _remoteTokenRatio New token ratio
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
            "ERR: NOT WHITELISTED"
        );

        remoteTokenAddress[_remoteNetworkID][_tokenAddress] = _tokenAddressRemote;
        remoteTokenRatio[_remoteNetworkID][_tokenAddress] = _remoteTokenRatio;

        emit RemoteTokenAdded(
            _tokenAddress,
            _tokenAddressRemote,
            _remoteNetworkID,
            _remoteTokenRatio
        );
    }

    /// @notice Called only by the owner to remove whitelisted token from remote network
    /// @param _tokenAddress address of the token to remove
    /// @param _remoteNetworkID id of the remote network
    function removeTokenInNetwork(address _tokenAddress, uint256 _remoteNetworkID)
        external
        override
        onlyOwner
        notZero(_remoteNetworkID)
        validAddress(_tokenAddress)
    {
        require(
            remoteTokenAddress[_remoteNetworkID][_tokenAddress] != address(0),
            "ERR: NOT WHITELISTED NETWORK"
        );

        delete remoteTokenAddress[_remoteNetworkID][_tokenAddress];
        delete remoteTokenRatio[_remoteNetworkID][_tokenAddress];

        emit RemoteTokenRemoved(_tokenAddress, _remoteNetworkID);
    }

    /// @notice Updates the minimum fee
    /// @param _newMinFee new minimum fee value
    function setMinFee(uint256 _newMinFee) external override onlyOwner {
        require(_newMinFee < FeeOperations.FEE_FACTOR, "ERR: MIN > FACTOR");
        require(_newMinFee < maxFee, "ERR: MIN > MAX");

        minFee = _newMinFee;
        emit MinFeeChanged(_newMinFee);
    }

    /// @notice Updates the maximum fee
    /// @param _newMaxFee new maximum fee value
    function setMaxFee(uint256 _newMaxFee) external override onlyOwner {
        require(_newMaxFee < FeeOperations.FEE_FACTOR, "ERR: MAX > FACTOR");
        require(_newMaxFee > minFee, "ERR: MIN > MAX");

        maxFee = _newMaxFee;
        emit MaxFeeChanged(_newMaxFee);
    }

    /// @notice Updates the minimum limit liquidity block
    /// @param _newMinLimitLiquidityBlocks new minimum limit liquidity block value
    function setMinLimitLiquidityBlocks(uint256 _newMinLimitLiquidityBlocks)
        external
        override
        onlyOwner
    {
        require(_newMinLimitLiquidityBlocks < maxLimitLiquidityBlocks, "ERR: MIN > MAX");

        minLimitLiquidityBlocks = _newMinLimitLiquidityBlocks;
        emit MinLiquidityBlockChanged(_newMinLimitLiquidityBlocks);
    }

    /// @notice Updates the maximum limit liquidity block
    /// @param _newMaxLimitLiquidityBlocks new maximum limit liquidity block value
    function setMaxLimitLiquidityBlocks(uint256 _newMaxLimitLiquidityBlocks)
        external
        override
        onlyOwner
    {
        require(_newMaxLimitLiquidityBlocks > minLimitLiquidityBlocks, "ERR: MIN > MAX");

        maxLimitLiquidityBlocks = _newMaxLimitLiquidityBlocks;
        emit MaxLiquidityBlockChanged(_newMaxLimitLiquidityBlocks);
    }

    /// @notice External function called by the vault to generate new ID
    /// @dev Nonce variable is incremented on each call
    function generateId() external override onlyVault(msg.sender) returns (bytes32) {
        nonce = nonce + 1;
        return keccak256(abi.encodePacked(block.number, vault, nonce));
    }

    /// @notice Check if amount is in token transfer limits
    function inTokenTransferLimits(address _token, uint256 _amount)
        external
        view
        override
        returns (bool)
    {
        return (whitelistedTokens[_token].minTransferAllowed <= _amount &&
            whitelistedTokens[_token].maxTransferAllowed >= _amount);
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

    /// @notice Sets the value of the flag that controls if part of a Mosaic transfer
    ///         can be swapped into the native token of the destination network
    function setAbleToPerformSmallBalanceSwap(bool _flag) external override onlyOwner {
        ableToPerformSmallBalanceSwap = _flag;
    }

    /// @notice Public function to add address of the MosaicNativeSwapper used to swap into native tokens
    /// @param _mosaicNativeSwapperID the integer constant for the MosaicNativeSwapper
    /// @param _mosaicNativeSwapperAddress Address of the MosaicNativeSwapper
    function addSupportedMosaicNativeSwapper(
        uint256 _mosaicNativeSwapperID,
        address _mosaicNativeSwapperAddress
    ) public override onlyOwner validAddress(_mosaicNativeSwapperAddress) {
        supportedMosaicNativeSwappers[_mosaicNativeSwapperID] = _mosaicNativeSwapperAddress;
        ableToPerformSmallBalanceSwap = true;
    }

    /// @notice Public function to remove address of the MosaicNativeSwapper
    /// @param _mosaicNativeSwapperID the integer constant for the MosaicNativeSwapper
    function removeSupportedMosaicNativeSwapper(uint256 _mosaicNativeSwapperID)
        public
        override
        onlyOwner
    {
        delete supportedMosaicNativeSwappers[_mosaicNativeSwapperID];
    }

    modifier onlyOwnerOrVault(address _address) {
        require(_address == owner() || _address == vault, "ERR: PERMISSIONS O-V");
        _;
    }

    modifier onlyVault(address _address) {
        require(_address == vault, "ERR: PERMISSIONS VAULT");
        _;
    }

    modifier onlyWhitelistedRemoteTokens(uint256 _networkID, address _tokenAddress) {
        require(
            whitelistedTokens[_tokenAddress].underlyingIOUAddress != address(0),
            "ERR: NOT WHITELISTED"
        );
        require(
            remoteTokenAddress[_networkID][_tokenAddress] != address(0),
            "ERR: NOT WHITELISTED NETWORK"
        );
        _;
    }

    modifier notZero(uint256 _value) {
        require(_value > 0, "ERR: ZERO");
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
    event LockupTimeChanged(address indexed owner, uint256 oldVal, uint256 newVal, string valType);
    event TokenWhitelisted(
        address indexed erc20,
        address indexed newIou,
        address indexed newReceipt
    );
    event TokenWhitelistRemoved(address indexed erc20);
    event RemoteTokenAdded(
        address indexed erc20,
        address indexed remoteErc20,
        uint256 indexed remoteNetworkID,
        uint256 remoteTokenRatio
    );
    event RemoteTokenRemoved(address indexed erc20, uint256 indexed remoteNetworkID);

    event PauseNetwork(address admin, uint256 networkID);

    event UnpauseNetwork(address admin, uint256 networkID);

    struct WhitelistedToken {
        uint256 minTransferAllowed;
        uint256 maxTransferAllowed;
        address underlyingIOUAddress;
        address underlyingReceiptAddress;
    }

    function passiveLiquidityLocktime() external view returns (uint256);

    function minFee() external view returns (uint256);

    function maxFee() external view returns (uint256);

    function maxLimitLiquidityBlocks() external view returns (uint256);

    function minLimitLiquidityBlocks() external view returns (uint256);

    function wethAddress() external view returns (address);

    function remoteTokenAddress(uint256 _id, address _token) external view returns (address);

    function remoteTokenRatio(uint256 _id, address _token) external view returns (uint256);

    function supportedAMMs(uint256 _ammID) external view returns (address);

    function pausedNetwork(uint256) external view returns (bool);

    function ableToPerformSmallBalanceSwap() external view returns (bool);

    function supportedMosaicNativeSwappers(uint256 _mosaicNativeSwapperID)
        external
        view
        returns (address);

    /**
     * @dev used to set the passive liquidity lock time
     * @param _locktime  Lock time in seconds until the passive liquidity withdrawal is unavailable
     */
    function setPassiveLiquidityLocktime(uint256 _locktime) external;

    /**
     * @dev used to set WETH address
     * @param _weth  Address of WETH token
     * @param _minTransferAmount Minimum transfer allowed amount
     * @param _maxTransferAmount Maximum transfer allowed amount
     */
    function setWethAddress(
        address _weth,
        uint256 _minTransferAmount,
        uint256 _maxTransferAmount
    ) external;

    function getUnderlyingIOUAddress(address _token) external view returns (address);

    function getUnderlyingReceiptAddress(address _token) external view returns (address);

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

    function changeRemoteTokenRatio(
        address _tokenAddress,
        uint256 _remoteNetworkID,
        uint256 _remoteTokenRatio
    ) external;

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

    /**
     * @dev used to removes whitelisted token from the contract.
     * @param _token  SC address of the ERC20 token to remove from supported tokens
     */
    function removeWhitelistedToken(address _token) external;

    function addTokenInNetwork(
        address _tokenAddress,
        address _tokenAddressRemote,
        uint256 _remoteNetworkID,
        uint256 _remoteTokenRatio
    ) external;

    function removeTokenInNetwork(address _tokenAddress, uint256 _remoteNetworkID) external;

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
    function setMinLimitLiquidityBlocks(uint256 _newMinLimitLiquidityBlocks) external;

    /**
     * @dev updates the maximum limit liquidity block.
     * @param _newMaxLimitLiquidityBlocks value to be set as new maximum limit liquidity block
     */
    function setMaxLimitLiquidityBlocks(uint256 _newMaxLimitLiquidityBlocks) external;

    function generateId() external returns (bytes32);

    function inTokenTransferLimits(address, uint256) external view returns (bool);

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

    function setAbleToPerformSmallBalanceSwap(bool _flag) external;

    function addSupportedMosaicNativeSwapper(
        uint256 _mosaicNativeSwapperID,
        address _mosaicNativeSwapperAddress
    ) external;

    function removeSupportedMosaicNativeSwapper(uint256 _mosaicNativeSwapperID) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IInvestmentStrategy.sol";

interface IMosaicHolding {
    event FoundsInvested(address indexed strategy, address indexed admin, uint256 cTokensReceived);

    event InvestmentWithdrawn(address indexed strategy, address indexed admin);

    event RebalancingThresholdChanged(
        address indexed admin,
        address indexed token,
        uint256 oldAmount,
        uint256 newAmount
    );

    event RebalancingInitiated(
        address indexed by,
        address indexed token,
        address indexed receiver,
        uint256 amount
    );

    event TokenClaimed(address indexed strategy, address indexed rewardTokenAddress);

    event SaveFundsStarted(address owner, address token, address receiver);

    event LiquidityMoved(address indexed to, address indexed tokenAddress, uint256 amount);

    event SaveFundsLockUpTimerStarted(address owner, uint256 time, uint256 durationToChangeTime);

    event SaveFundsLockUpTimeSet(address owner, uint256 time, uint256 durationToChangeTime);

    event ETHTransfered(address receiver, uint256 amount);

    function getTokenLiquidity(address _token, address[] calldata _investmentStrategies)
        external
        view
        returns (uint256);

    function saveFundsLockupTime() external view returns (uint256);

    function newSaveFundsLockUpTime() external view returns (uint256);

    function durationToChangeTimer() external view returns (uint256);

    function transfer(
        address _token,
        address _receiver,
        uint256 _amount
    ) external;

    function transferETH(address _receiver, uint256 _amount) external;

    function setUniqRole(bytes32 _role, address _address) external;

    function approve(
        address _spender,
        address _token,
        uint256 _amount
    ) external;

    /**
     * @dev starts save funds transfer.
     * @param _token Token's balance the owner wants to withdraw
     * @param _to Receiver address
     */
    function startSaveFunds(address _token, address _to) external;

    /**
     * @dev manually moves funds back to L1.
     */
    function executeSaveFunds() external;

    /**
     * @dev starts save funds lockup timer change.
     * @param _time lock up time duration
     */
    function startSaveFundsLockUpTimerChange(uint256 _time) external;

    /**
     * @dev set save funds lock up time.
     */
    function setSaveFundsLockUpTime() external;

    function invest(
        IInvestmentStrategy.Investment[] calldata _investments,
        address _investmentStrategy,
        bytes calldata _data
    ) external;

    function withdrawInvestment(
        IInvestmentStrategy.Investment[] calldata _investments,
        address _investmentStrategy,
        bytes calldata _data
    ) external;

    function coverWithdrawRequest(
        address[] calldata investmentStrategies,
        address _token,
        uint256 _amount
    ) external;

    function claim(address _investmentStrategy, bytes calldata _data) external;
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

pragma solidity ^0.8.0;

library FeeOperations {
    uint256 internal constant FEE_FACTOR = 10000;

    function getFeeAbsolute(uint256 amount, uint256 fee) internal pure returns (uint256) {
        return (amount * fee) / FEE_FACTOR;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IMosaicHolding.sol";
import "../interfaces/ITokenFactory.sol";
import "../interfaces/IReceiptBase.sol";
import "../interfaces/IVaultConfigBase.sol";

abstract contract VaultConfigBase is
    IVaultConfigBase,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    ITokenFactory internal tokenFactory;
    IMosaicHolding public mosaicHolding;

    /// @notice Address of the MosaicVault
    address public vault;

    /// @notice Get mosaicHolding address
    function getMosaicHolding() external view override returns (address) {
        return address(mosaicHolding);
    }

    /// @notice Used to set address of the MosaicVault
    /// @param _vault address of the MosaicVault
    function setVault(address _vault) external override validAddress(_vault) onlyOwner {
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

    modifier validAddress(address _address) {
        require(_address != address(0), "Invalid address");
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

    function setTokenFactoryAddress(address _tokenFactoryAddress) external;

    function setVault(address _vault) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IInvestmentStrategy {
    struct Investment {
        address token;
        uint256 amount;
    }

    function makeInvestment(Investment[] calldata _investments, bytes calldata _data)
        external
        returns (uint256);

    function withdrawInvestment(Investment[] calldata _investments, bytes calldata _data) external;

    function claimTokens(bytes calldata _data) external returns (address);

    function investmentAmount(address _token) external view returns (uint256);
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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IReceiptBase is IERC20 {
    function burn(address _from, uint256 _amount) external;

    function mint(address _to, uint256 _amount) external;

    function underlyingToken() external returns (address);
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