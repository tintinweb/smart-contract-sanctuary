// SPDX-License-Identifier: MIT

/**
 * Created on 2021-06-07 08:50
 * @summary: Vault for storing ERC20 tokens that will be transferred by external event-based system to another network. The destination network can be checked on "connectedNetwork"
 * @author: Composable Finance - Pepe Blasco
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "../interfaces/IComposableHolding.sol";
import "../interfaces/IComposableExchange.sol";
import "../interfaces/IReceiptBase.sol";
import "../interfaces/ITokenFactory.sol";
import "../interfaces/IMosaicVaultConfig.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IMosaicVault.sol";

import "../libraries/FeeOperations.sol";

//@title: Composable Finance Mosaic ERC20 Vault
contract MosaicVault is
    IMosaicVault,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(uint256 => bool) public pausedNetwork;

    mapping(bytes32 => bool) public hasBeenWithdrawn;

    mapping(bytes32 => bool) public hasBeenUnlocked;

    mapping(bytes32 => bool) public hasBeenRefunded;

    /// @dev mapping userAddress => tokenAddress => availableAfterBlock
    mapping(address => mapping(address => uint256)) private availableAfterBlock;

    mapping(bytes32 => DepositInfo) public deposits;

    mapping(address => uint256) public lastTransfer;

    bytes32 public lastWithdrawID;
    bytes32 public lastUnlockID;
    bytes32 public lastRefundedID;

    uint256 public saveFundsTimer;
    uint256 public saveFundsAmount;
    uint256 public saveFundsLockupTime;
    uint256 public durationToChangeTimer;
    uint256 public newSaveFundsLockUpTime;

    address public relayer;
    address public tokenAddressToSaveFunds;
    address public userAddressToSaveFundsTo;

    IMosaicVaultConfig public vaultConfig;

    struct DepositInfo {
        address token;
        uint256 amount;
    }

    function initialize(address _mosaicVaultConfig) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        vaultConfig = IMosaicVaultConfig(_mosaicVaultConfig);

        saveFundsLockupTime = 12 hours;
    }

    /// @notice External callable function to set the relayer address
    function setRelayer(address _relayer) external override onlyOwner {
        relayer = _relayer;
    }

    /// @notice External callable function to set the vault config address
    function setVaultConfig(address _vaultConfig) external override onlyOwner {
        vaultConfig = IMosaicVaultConfig(_vaultConfig);
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

    // @notice transfer ERC20 token to another Mosaic vault
    /// @param _amount amount of tokens to deposit
    /// @param _tokenAddress  SC address of the ERC20 token to deposit
    /// @param _maxTransferDelay delay in seconds for the relayer to execute the transaction
    function transferERC20ToLayer(
        uint256 _amount,
        address _tokenAddress,
        address _remoteDestinationAddress,
        uint256 _remoteNetworkID,
        uint256 _maxTransferDelay
    )
        external
        override
        validAmount(_amount)
        onlyWhitelistedRemoteTokens(_remoteNetworkID, _tokenAddress)
        nonReentrant
        whenNotPausedNetwork(_remoteNetworkID)
    {
        bytes32 id = vaultConfig.generateId();
        _transferERC20ToLayer(_tokenAddress, _amount, id);

        emit TransferInitiated(
            msg.sender,
            _tokenAddress,
            vaultConfig.remoteTokenAddress(_remoteNetworkID, _tokenAddress),
            _remoteNetworkID,
            _amount,
            _remoteDestinationAddress,
            id,
            _maxTransferDelay
        );
    }

    // @notice transfer ERC20 token to another Mosaic vault
    /// @param _amount amount of tokens to deposit
    /// @param _tokenAddress  SC address of the ERC20 token to deposit
    /// @param _maxTransferDelay delay in seconds for the relayer to execute the transaction
    /// @param _tokenOut  SC address of the ERC20 token to receive tokens
    /// @param _remoteAmmId remote integer constant for the AMM
    function transferERC20ToLayerForDifferentToken(
        uint256 _amount,
        address _tokenAddress,
        address _remoteDestinationAddress,
        uint256 _remoteNetworkID,
        uint256 _maxTransferDelay,
        address _tokenOut,
        uint256 _remoteAmmId
    ) external override nonReentrant whenNotPausedNetwork(_remoteNetworkID) {
        require(_amount > 0, "Invalid amount");
        address remoteTokenAddress = vaultConfig.remoteTokenAddress(
            _remoteNetworkID,
            _tokenAddress
        );
        require(
            remoteTokenAddress != address(0),
            "token not whitelisted in this network"
        );
        bytes32 id = vaultConfig.generateId();
        _transferERC20ToLayer(_tokenAddress, _amount, id);

        emit TransferToDifferentTokenInitiated(
            msg.sender,
            _tokenAddress,
            _tokenOut,
            remoteTokenAddress,
            _remoteNetworkID,
            _amount,
            _remoteAmmId,
            _remoteDestinationAddress,
            id,
            _maxTransferDelay
        );
    }

    function _transferERC20ToLayer(
        address _tokenAddress,
        uint256 _amount,
        bytes32 _id
    ) private inTokenTransferLimits(_tokenAddress, _amount) {
        require(
            lastTransfer[msg.sender] + vaultConfig.transferLockupTime() <
                block.timestamp,
            "Transfer not yet possible"
        );
        IERC20Upgradeable(_tokenAddress).safeTransferFrom(
            msg.sender,
            vaultConfig.getComposableHolding(),
            _amount
        );

        deposits[_id] = DepositInfo({token: _tokenAddress, amount: _amount});

        vaultConfig.setLockedTransferFunds(
            _tokenAddress,
            vaultConfig.transferLockupTime() + _amount
        );

        lastTransfer[msg.sender] = block.timestamp;
    }

    function provideLiquidity(
        uint256 _amount,
        address _tokenAddress,
        uint256 _blocksForActiveLiquidity
    )
        external
        override
        validAddress(_tokenAddress)
        validAmount(_amount)
        onlyWhitelistedToken(_tokenAddress)
        nonReentrant
        whenNotPaused
    {
        require(
            _blocksForActiveLiquidity >=
                vaultConfig.minLimitLiquidityBlocks() &&
                _blocksForActiveLiquidity <=
                vaultConfig.maxLimitLiquidityBlocks(),
            "not within block approve range"
        );
        IERC20Upgradeable(_tokenAddress).safeTransferFrom(
            msg.sender,
            vaultConfig.getComposableHolding(),
            _amount
        );
        IReceiptBase(vaultConfig.getUnderlyingIOUAddress(_tokenAddress)).mint(
            msg.sender,
            _amount
        );
        _updateAvailableTokenAfter(_tokenAddress, _blocksForActiveLiquidity);
        emit DepositLiquidity(
            _tokenAddress,
            msg.sender,
            _amount,
            _blocksForActiveLiquidity
        );
    }

    function provideEthLiquidity(uint256 _blocksForActiveLiquidity)
        public
        payable
        whenNotPaused
        nonReentrant
        validAmount(msg.value)
    {
        require(
            _blocksForActiveLiquidity >=
                vaultConfig.minLimitLiquidityBlocks() &&
                _blocksForActiveLiquidity <=
                vaultConfig.maxLimitLiquidityBlocks(),
            "not within block approve range"
        );

        address weth = vaultConfig.wethAddress();

        require(weth != address(0), "WETH not set");
        IWETH(weth).deposit{value: msg.value}();

        IReceiptBase(vaultConfig.getUnderlyingIOUAddress(weth)).mint(
            msg.sender,
            msg.value
        );
        _updateAvailableTokenAfter(weth, _blocksForActiveLiquidity);
        emit DepositLiquidity(
            weth,
            msg.sender,
            msg.value,
            _blocksForActiveLiquidity
        );
    }

    function addLiquidityWithdrawRequest(address _tokenAddress, uint256 _amount)
        external
        override
        validAddress(_tokenAddress)
        validAmount(_amount)
        enoughLiquidityInVault(_tokenAddress, _amount)
        availableToWithdrawLiquidity(_tokenAddress)
    {
        _burnIOUTokens(_tokenAddress, msg.sender, _amount);
        emit WithdrawRequest(
            msg.sender,
            _tokenAddress,
            _tokenAddress,
            _amount,
            block.chainid
        );
    }

    function withdrawLiquidity(
        address _receiver,
        address _tokenAddress,
        uint256 _amount
    ) external override onlyOwnerOrRelayer {
        IComposableHolding(vaultConfig.getComposableHolding()).transfer(
            _tokenAddress,
            _receiver,
            _amount
        );
        emit LiquidityWithdrawn(_tokenAddress, _receiver, _amount);
    }

    // @notice called by the relayer to restore the user's liquidity
    //         when `withdrawDifferentTokenTo` fails on the destination layer
    /// @param _user address of the user account
    /// @param _amount amount of tokens
    /// @param _tokenAddress  address of the ERC20 token
    /// @param _id the id generated by the withdraw method call by the user
    function refundLiquidity(
        address _user,
        uint256 _amount,
        address _tokenAddress,
        bytes32 _id
    )
        external
        override
        onlyOwnerOrRelayer
        validAmount(_amount)
        enoughLiquidityInVault(_tokenAddress, _amount)
        nonReentrant
    {
        require(hasBeenRefunded[_id] == false, "Already refunded");

        hasBeenRefunded[_id] = true;
        lastRefundedID = _id;

        IReceiptBase(vaultConfig.getUnderlyingIOUAddress(_tokenAddress)).mint(
            _user,
            _amount
        );

        emit LiquidityRefunded(_tokenAddress, _user, _amount, _id);
    }

    /// @notice External function called to add withdraw liquidity request in different token
    /// @param _tokenIn Address of the token provider have
    /// @param _tokenOut Address of the token provider want to receive
    /// @param _amountIn Amount of tokens provider want to withdraw
    /// @param _amountOutMin Minimum amount of token user should get
    function addWithdrawLiquidityToDifferentTokenRequest(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256 _ammID,
        bytes calldata _data
    )
        external
        override
        onlyWhitelistedToken(_tokenOut)
        onlyWhitelistedToken(_tokenIn)
        differentAddresses(_tokenIn, _tokenOut)
        availableToWithdrawLiquidity(_tokenIn)
    {
        _burnIOUTokens(_tokenIn, msg.sender, _amountIn);
        emit WithdrawRequest(
            msg.sender,
            _tokenOut,
            _tokenIn,
            _swap(_amountIn, _amountOutMin, _tokenIn, _tokenOut, _ammID, _data),
            block.chainid
        );
    }

    function withdrawLiquidityOnAnotherMosaicNetwork(
        address _tokenAddress,
        uint256 _amount,
        address _remoteDestinationAddress,
        uint256 _networkID
    )
        external
        override
        validAddress(_tokenAddress)
        validAmount(_amount)
        onlyWhitelistedRemoteTokens(_networkID, _tokenAddress)
        availableToWithdrawLiquidity(_tokenAddress)
    {
        _burnIOUTokens(_tokenAddress, msg.sender, _amount);

        emit WithdrawOnRemoteNetworkStarted(
            msg.sender,
            _tokenAddress,
            vaultConfig.remoteTokenAddress(_networkID, _tokenAddress),
            _networkID,
            _amount,
            _remoteDestinationAddress,
            vaultConfig.generateId()
        );
    }

    /// @notice External function called to withdraw liquidity in different token on another network
    /// @param _tokenIn Address of the token provider have
    /// @param _tokenOut Address of the token provider want to receive
    /// @param _amountIn Amount of tokens provider want to withdraw
    /// @param _networkID Id of the network want to receive the other token
    /// @param _amountOutMin Minimum amount of token user should get
    function withdrawLiquidityToDifferentTokenOnAnotherMosaicNetwork(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _networkID,
        uint256 _amountOutMin,
        address _remoteDestinationAddress,
        uint256 _remoteAmmId
    )
        external
        override
        validAmount(_amountIn)
        onlyWhitelistedToken(_tokenOut)
        onlyWhitelistedToken(_tokenIn)
        onlyWhitelistedRemoteTokens(_networkID, _tokenOut)
        availableToWithdrawLiquidity(_tokenIn)
    {
        _withdrawToNetworkInDifferentToken(
            _tokenIn,
            _tokenOut,
            _amountIn,
            _networkID,
            _amountOutMin,
            _remoteDestinationAddress,
            _remoteAmmId
        );
    }

    /// @dev internal function to withdraw different token on another network
    /// @dev use this approach to avoid stack too deep error
    function _withdrawToNetworkInDifferentToken(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _networkID,
        uint256 _amountOutMin,
        address _remoteDestinationAddress,
        uint256 _remoteAmmId
    ) internal differentAddresses(_tokenIn, _tokenOut) {
        _burnIOUTokens(_tokenIn, msg.sender, _amountIn);

        emit WithdrawOnRemoteNetworkForDifferentTokenStarted(
            msg.sender,
            vaultConfig.remoteTokenAddress(_networkID, _tokenOut),
            _networkID,
            _amountIn,
            _amountOutMin,
            _remoteDestinationAddress,
            _remoteAmmId,
            vaultConfig.generateId()
        );
    }

    function _burnIOUTokens(
        address _tokenAddress,
        address _provider,
        uint256 _amount
    ) internal validAmount(_amount) {
        IReceiptBase receipt = IReceiptBase(
            vaultConfig.getUnderlyingIOUAddress(_tokenAddress)
        );
        require(
            receipt.balanceOf(_provider) >= _amount,
            "IOU Token balance to low"
        );
        receipt.burn(_provider, _amount);
    }

    // @notice: method called by the relayer to release funds
    /// @param _accountTo eth address to send the withdrawal tokens
    function withdrawTo(
        address _accountTo,
        uint256 _amount,
        address _tokenAddress,
        bytes32 _id,
        uint256 _baseFee
    )
        external
        override
        onlyWhitelistedToken(_tokenAddress)
        enoughLiquidityInVault(_tokenAddress, _amount)
        nonReentrant
        onlyOwnerOrRelayer
        whenNotPaused
        notAlreadyWithdrawn(_id)
    {
        _withdraw(
            _accountTo,
            _amount,
            _tokenAddress,
            address(0),
            _id,
            _baseFee,
            0,
            0,
            ""
        );
    }

    // @notice: method called by the relayer to release funds in different token
    /// @param _accountTo eth address to send the withdrawal tokens
    /// @param _amount amount of token in
    /// @param _tokenIn address of the token in
    /// @param _tokenOut address of the token out
    /// @param _id withdrawal _id
    /// @param _baseFee the fee taken by the relayer
    /// @param _amountOutMin minimum amount out user want
    /// @param _data additional _data required for each AMM implementation
    function withdrawDifferentTokenTo(
        address _accountTo,
        uint256 _amount,
        address _tokenIn,
        address _tokenOut,
        bytes32 _id,
        uint256 _baseFee,
        uint256 _amountOutMin,
        uint256 _ammID,
        bytes calldata _data
    )
        external
        override
        onlyWhitelistedToken(_tokenIn)
        nonReentrant
        onlyOwnerOrRelayer
        whenNotPaused
        notAlreadyWithdrawn(_id)
    {
        _withdraw(
            _accountTo,
            _amount,
            _tokenIn,
            _tokenOut,
            _id,
            _baseFee,
            _amountOutMin,
            _ammID,
            _data
        );
    }

    function _withdraw(
        address _accountTo,
        uint256 _amount,
        address _tokenIn,
        address _tokenOut,
        bytes32 _id,
        uint256 _baseFee,
        uint256 _amountOutMin,
        uint256 _ammID,
        bytes memory _data
    ) private {
        hasBeenWithdrawn[_id] = true;
        lastWithdrawID = _id;
        uint256 withdrawAmount = _takeFees(
            _tokenIn,
            _amount,
            _accountTo,
            _id,
            _baseFee
        );

        IComposableHolding composableHolding = IComposableHolding(
            vaultConfig.getComposableHolding()
        );
        if (_tokenOut == address(0)) {
            composableHolding.transfer(_tokenIn, _accountTo, withdrawAmount);
        } else {
            uint256 amountToSend = _swap(
                withdrawAmount,
                _amountOutMin,
                _tokenIn,
                _tokenOut,
                _ammID,
                _data
            );
            composableHolding.transfer(_tokenOut, _accountTo, amountToSend);
        }

        emit WithdrawalCompleted(
            _accountTo,
            _amount,
            withdrawAmount,
            _tokenIn,
            _id
        );
    }

    function _takeFees(
        address _token,
        uint256 _amount,
        address _accountTo,
        bytes32 _withdrawRequestId,
        uint256 _baseFee
    ) private returns (uint256) {
        uint256 feePercentage = vaultConfig.calculateFeePercentage(
            _token,
            _amount
        );

        uint256 fee = FeeOperations.getFeeAbsolute(_amount, feePercentage);
        uint256 withdrawAmount = _amount - fee;

        if (_baseFee > 0) {
            IComposableHolding(vaultConfig.getComposableHolding()).transfer(
                _token,
                owner(),
                _baseFee
            );
        }

        if (fee > 0) {
            IComposableHolding(vaultConfig.getComposableHolding()).transfer(
                _token,
                vaultConfig.feeAddress(),
                fee
            );
        }

        if (_baseFee + fee > 0) {
            emit FeeTaken(
                msg.sender,
                _accountTo,
                _token,
                _amount,
                fee,
                _baseFee,
                fee + _baseFee,
                _withdrawRequestId
            );
        }

        return withdrawAmount;
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

        emit saveFundsLockUpTimerStarted(
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

        emit saveFundsLockUpTimeSet(
            msg.sender,
            saveFundsLockupTime,
            durationToChangeTimer
        );
    }

    /**
     * @notice Starts save funds transfer
     * @param _token Token's balance the owner wants to withdraw
     * @param _to Receiver address
     */

    function startSaveFunds(address _token, address _to)
        external
        override
        onlyOwner
        whenPaused
        validAddress(_token)
        validAddress(_to)
    {
        tokenAddressToSaveFunds = _token;
        userAddressToSaveFundsTo = _to;

        saveFundsTimer = block.timestamp + saveFundsLockupTime;

        emit saveFundsStarted(msg.sender, _token, _to);
    }

    /**
     * @notice Will be called once the contract is paused and token's available liquidity will be manually moved
     */

    function executeSaveFunds() external override onlyOwner whenPaused {
        require(
            saveFundsTimer <= block.timestamp && saveFundsTimer != 0,
            "action not yet possible"
        );

        uint256 balance = IERC20Upgradeable(tokenAddressToSaveFunds).balanceOf(
            vaultConfig.getComposableHolding()
        );
        if (balance == 0) {
            saveFundsTimer = 0;
            return;
        } else {
            IComposableHolding(vaultConfig.getComposableHolding()).transfer(
                tokenAddressToSaveFunds,
                userAddressToSaveFundsTo,
                balance
            );
            saveFundsTimer = 0;
        }
        emit LiquidityMoved(msg.sender, userAddressToSaveFundsTo, balance);
    }

    /**
     * @notice Used to transfer randomly sent tokens to this contract to the composable holding
     * @param _token Token's address
     */
    function digestFunds(address _token)
        external
        override
        onlyOwner
        validAddress(_token)
    {
        uint256 balance = IERC20Upgradeable(_token).balanceOf(address(this));
        require(balance > 0, "Nothing to transfer");
        IERC20Upgradeable(_token).safeTransfer(
            vaultConfig.getComposableHolding(),
            balance
        );
        emit FundsDigested(_token, balance);
    }

    /*
    this method is called by the relayer after a successful transfer of tokens between layers
    this is called to unlock the funds to be added in the liquidity of the vault
    */
    function unlockTransferFunds(
        address _token,
        uint256 _amount,
        bytes32 _id
    ) public override whenNotPaused onlyOwnerOrRelayer {
        require(hasBeenUnlocked[_id] == false, "Already unlocked");
        require(
            vaultConfig.lockedTransferFunds(_token) >= _amount,
            "More amount than available"
        );

        require(
            deposits[_id].token == _token && deposits[_id].amount == _amount,
            "Registered deposit data does not match provided"
        );

        hasBeenUnlocked[_id] = true;
        lastUnlockID = _id;

        // update the lockedTransferFunds for the token
        vaultConfig.setLockedTransferFunds(
            _token,
            vaultConfig.lockedTransferFunds(_token) - _amount
        );

        emit TransferFundsUnlocked(_token, _amount, _id);
    }

    /*
    called by the relayer to return the tokens back to user in case of a failed
    transfer between layers. this method will mark the `id` as used and emit
    the event that funds has been claimed by the user
    */
    function refundTransferFunds(
        address _token,
        address _user,
        uint256 _amount,
        bytes32 _id
    ) external override onlyOwnerOrRelayer nonReentrant {
        require(hasBeenRefunded[_id] == false, "Already refunded");

        // unlock the funds
        if (hasBeenUnlocked[_id] == false) {
            unlockTransferFunds(_token, _amount, _id);
        }

        hasBeenRefunded[_id] = true;
        lastRefundedID = _id;

        IComposableHolding(vaultConfig.getComposableHolding()).transfer(
            _token,
            _user,
            _amount
        );

        delete deposits[_id];

        emit TransferFundsRefunded(_token, _user, _amount, _id);
    }

    function getRemoteTokenAddress(uint256 _networkID, address _tokenAddress)
        external
        view
        override
        returns (address _tokenAddressRemote)
    {
        _tokenAddressRemote = vaultConfig.remoteTokenAddress(
            _networkID,
            _tokenAddress
        );
    }

    receive() external payable {
        provideEthLiquidity(vaultConfig.maxLimitLiquidityBlocks());
    }

    function _swap(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _tokenIn,
        address _tokenOut,
        uint256 _ammID,
        bytes memory _data
    ) private returns (uint256) {
        address composableHolding = vaultConfig.getComposableHolding();
        IComposableHolding(composableHolding).transfer(
            _tokenIn,
            address(this),
            _amountIn
        );
        address ammAddress = vaultConfig.getAMMAddress(_ammID);
        require(ammAddress != address(0), "AMM not supported");

        IERC20Upgradeable(_tokenIn).safeApprove(ammAddress, _amountIn);

        uint256 amountToSend = IComposableExchange(ammAddress).swap(
            _tokenIn,
            _tokenOut,
            _amountIn,
            _amountOutMin,
            _data
        );
        require(amountToSend >= _amountOutMin, "AMM: Price to low");
        IERC20Upgradeable(_tokenOut).safeTransfer(
            composableHolding,
            amountToSend
        );
        return amountToSend;
    }

    function _updateAvailableTokenAfter(
        address _token,
        uint256 _blocksForActiveLiquidity
    ) private {
        uint256 _availableAfter = availableAfterBlock[msg.sender][_token];
        uint256 _newAvailability = block.number + _blocksForActiveLiquidity;
        if (_availableAfter < _newAvailability) {
            availableAfterBlock[msg.sender][_token] = _newAvailability;
        }
    }

    /// @notice External callable function to pause the contract
    function pause() external override whenNotPaused onlyOwner {
        _pause();
    }

    /// @notice External callable function to unpause the contract
    function unpause() external override whenPaused onlyOwner {
        _unpause();
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Invalid address");
        _;
    }

    modifier validAmount(uint256 _value) {
        require(_value > 0, "Invalid amount");
        _;
    }

    modifier onlyWhitelistedToken(address _tokenAddress) {
        require(
            vaultConfig.getUnderlyingIOUAddress(_tokenAddress) != address(0),
            "token not whitelisted"
        );
        _;
    }

    modifier onlyWhitelistedRemoteTokens(
        uint256 _networkID,
        address _tokenAddress
    ) {
        require(
            vaultConfig.remoteTokenAddress(_networkID, _tokenAddress) !=
                address(0),
            "token not whitelisted in this network"
        );
        _;
    }

    modifier whenNotPausedNetwork(uint256 _networkID) {
        require(paused() == false, "Contract is paused");
        require(pausedNetwork[_networkID] == false, "Network is paused");
        _;
    }

    modifier differentAddresses(
        address _tokenAddress,
        address _tokenAddressReceive
    ) {
        require(_tokenAddress != _tokenAddressReceive, "Same token address");
        _;
    }

    modifier enoughLiquidityInVault(address _tokenAddress, uint256 _amount) {
        require(
            vaultConfig.getCurrentTokenLiquidity(_tokenAddress) >= _amount,
            "Not enough tokens in the vault"
        );
        _;
    }

    modifier notAlreadyWithdrawn(bytes32 _id) {
        require(hasBeenWithdrawn[_id] == false, "Already withdrawn");
        _;
    }

    modifier inTokenTransferLimits(address _token, uint256 _amount) {
        require(
            vaultConfig.inTokenTransferLimits(_token, _amount),
            "Amount out of token transfer limits"
        );
        _;
    }

    modifier onlyOwnerOrRelayer() {
        require(
            _msgSender() == owner() || _msgSender() == relayer,
            "Only owner or relayer"
        );
        _;
    }

    modifier availableToWithdrawLiquidity(address _token) {
        require(
            availableAfterBlock[msg.sender][_token] <= block.number,
            "Can't withdraw token in this block"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IComposableHolding {
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

interface IComposableExchange {
    function swap(
        address _tokenA,
        address _tokenB,
        uint256 _amountIn,
        uint256 _amountOut,
        bytes calldata _data
    ) external returns (uint256);

    function getAmountsOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        bytes calldata _data
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IReceiptBase is IERC20 {
    function burn(address _from, uint256 _amount) external;

    function mint(address _to, uint256 _amount) external;
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

import "./IComposableHolding.sol";
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
    event TokenWhitelisted(address indexed erc20, address indexed newIou);
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

    function minFee() external view returns (uint256);

    function maxFee() external view returns (uint256);

    function feeThreshold() external view returns (uint256);

    function transferLockupTime() external view returns (uint256);

    function maxLimitLiquidityBlocks() external view returns (uint256);

    function tokenRatio() external view returns (uint256);

    function minLimitLiquidityBlocks() external view returns (uint256);

    function feeAddress() external view returns (address);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 _wad) external;

    function balanceOf(address _account) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of L1Vault.
 */
interface IMosaicVault {
    event TransferInitiated(
        address indexed account,
        address indexed erc20,
        address remoteTokenAddress,
        uint256 indexed remoteNetworkID,
        uint256 value,
        address remoteDestinationAddress,
        bytes32 uniqueId,
        uint256 maxTransferDelay
    );

    event TransferToDifferentTokenInitiated(
        address owner,
        address indexed erc20,
        address tokenOut,
        address remoteTokenAddress,
        uint256 indexed remoteNetworkID,
        uint256 value,
        uint256 ammID,
        address remoteDestinationAddress,
        bytes32 uniqueId,
        uint256 maxTransferDelay
    );

    event WithdrawalCompleted(
        address indexed accountTo,
        uint256 amount,
        uint256 netAmount,
        address indexed tokenAddress,
        bytes32 indexed uniqueId
    );
    event LiquidityMoved(
        address indexed owner,
        address indexed to,
        uint256 amount
    );
    event TransferFundsRefunded(
        address indexed tokenAddress,
        address indexed user,
        uint256 amount,
        bytes32 uniqueId
    );
    event TransferFundsUnlocked(
        address indexed tokenAddress,
        uint256 amount,
        bytes32 uniqueId
    );
    event FundsDigested(address indexed tokenAddress, uint256 amount);

    event PauseNetwork(address admin, uint256 networkID);
    event UnpauseNetwork(address admin, uint256 networkID);
    event FeeTaken(
        address indexed owner,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 fee,
        uint256 baseFee,
        uint256 totalFee,
        bytes32 uniqueId
    );

    event DepositLiquidity(
        address indexed tokenAddress,
        address indexed provider,
        uint256 amount,
        uint256 blocks
    );

    event LiquidityWithdrawn(
        address indexed tokenAddress,
        address indexed provider,
        uint256 amount
    );

    event LiquidityRefunded(
        address indexed tokenAddress,
        address indexed user,
        uint256 amount,
        bytes32 uniqueId
    );

    event WithdrawOnRemoteNetworkStarted(
        address indexed account,
        address indexed erc20,
        address remoteTokenAddress,
        uint256 indexed remoteNetworkID,
        uint256 value,
        address remoteDestinationAddress,
        bytes32 uniqueId
    );

    event WithdrawOnRemoteNetworkForDifferentTokenStarted(
        address indexed account,
        address indexed remoteTokenAddress,
        uint256 indexed remoteNetworkID,
        uint256 value,
        uint256 amountOutMin,
        address remoteDestinationAddress,
        uint256 remoteAmmId,
        bytes32 uniqueId
    );

    event WithdrawRequest(
        address indexed receiver,
        address indexed token,
        address withdrawFromToken,
        uint256 indexed amount,
        uint256 networkId
    );

    event saveFundsLockUpTimerStarted(
        address owner,
        uint256 time,
        uint256 durationToChangeTime
    );

    event saveFundsLockUpTimeSet(
        address owner,
        uint256 time,
        uint256 durationToChangeTime
    );

    event saveFundsStarted(address owner, address token, address receiver);

    function setRelayer(address _relayer) external;

    function setVaultConfig(address _vaultConfig) external;

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

    /**
     * @dev transfer ERC20 token to another Mosaic vault.
     * @param _amount amount of tokens to deposit
     * @param _tokenAddress  SC address of the ERC20 token to deposit
     * @param _remoteDestinationAddress SC address of the ERC20 supported tokens in a diff network
     * @param _remoteNetworkID  network ID of remote token
     * @param _maxTransferDelay delay in seconds for the relayer to execute the transaction
     */

    function transferERC20ToLayer(
        uint256 _amount,
        address _tokenAddress,
        address _remoteDestinationAddress,
        uint256 _remoteNetworkID,
        uint256 _maxTransferDelay
    ) external;

    /**
     * @dev transfer ERC20 token to another Mosaic vault.
     * @param _amount amount of tokens to deposit
     * @param _tokenAddress  SC address of the ERC20 token to deposit
     * @param _remoteDestinationAddress SC address of the ERC20 supported tokens in a diff network
     * @param _remoteNetworkID  network ID of remote token
     * @param _maxTransferDelay delay in seconds for the relayer to execute the transaction
     * @param _tokenOut  SC address of the ERC20 token to receive tokens
     * @param _remote_AmmId remote integer constant for the AMM
     */

    function transferERC20ToLayerForDifferentToken(
        uint256 _amount,
        address _tokenAddress,
        address _remoteDestinationAddress,
        uint256 _remoteNetworkID,
        uint256 _maxTransferDelay,
        address _tokenOut,
        uint256 _remote_AmmId
    ) external;

    /**
     * @dev used to provide liquidity.
     * @param _amount amount of tokens to deposit
     * @param _tokenAddress  SC address of the ERC20 token to deposit
     * @param _blocksForActiveLiquidity users choice of active liquidity
     */

    function provideLiquidity(
        uint256 _amount,
        address _tokenAddress,
        uint256 _blocksForActiveLiquidity
    ) external;

    /**
     * @dev used by the relayer to send liquidity to the user
     * @param _receiver Address of the token receiver
     * @param _tokenAddress  SC address of the ERC20 token to deposit
     * @param _amount amount of tokens to deposit
     */

    function withdrawLiquidity(
        address _receiver,
        address _tokenAddress,
        uint256 _amount
    ) external;

    /**
     * @dev used to add withdraw liquidity request
     * @param _tokenAddress  SC address of the ERC20 token to deposit
     * @param _amount amount of tokens to deposit
     */
    function addLiquidityWithdrawRequest(address _tokenAddress, uint256 _amount)
        external;

    /**
     * @dev called by the relayer to restore the user's liquidity
     * when `withdrawDifferentTokenTo` fails on the destination layer.
     * @param _user address of the user account
     * @param _amount amount of tokens
     * @param _tokenAddress  address of the ERC20 token
     * @param _id the id generated by the withdraw method call by the user
     */

    function refundLiquidity(
        address _user,
        uint256 _amount,
        address _tokenAddress,
        bytes32 _id
    ) external;

    /**
     * @dev used to withdraw liquidity in different token.
     * @param _tokenIn Address of the token provider have
     * @param _tokenOut Address of the token provider want to receive
     * @param _amountIn Amount of tokens provider want to withdraw
     * @param _amountOutMin Minimum amount of token user should get
     * @param _ammID ID of AMM to use
     * @param _data data additional data required for each AMM implementation
     */

    function addWithdrawLiquidityToDifferentTokenRequest(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256 _ammID,
        bytes calldata _data
    ) external;

    /**
     * @dev used to withdraw liquidity on another Mosaic network.
     * @param _tokenAddress  SC address of the ERC20 token to deposit
     * @param _amount amount of tokens to deposit
     * @param _remoteDestinationAddress SC address of the ERC20 supported tokens in a diff network
     * @param _networkID  network ID of remote token
     */

    function withdrawLiquidityOnAnotherMosaicNetwork(
        address _tokenAddress,
        uint256 _amount,
        address _remoteDestinationAddress,
        uint256 _networkID
    ) external;

    /**
     * @dev used to withdraw liquidity to different token on another Mosaic network.
     * @param _tokenIn Address of the token provider have
     * @param _tokenOut Address of the token provider want to receive
     * @param _amountIn Amount of tokens provider want to withdraw
     * @param _networkID Id of the network want to receive the other token
     * @param _amountOutMin Minimum amount of token user should get
     * @param _remoteDestinationAddress SC address of the ERC20 supported tokens in a diff network
     * @param _remote_AmmId remote token amm id
     */

    function withdrawLiquidityToDifferentTokenOnAnotherMosaicNetwork(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _networkID,
        uint256 _amountOutMin,
        address _remoteDestinationAddress,
        uint256 _remote_AmmId
    ) external;

    /**
     * @dev used to release funds.
     * @param _accountTo eth address to send the withdrawal tokens
     * @param _amount amount of tokens to deposit
     * @param _tokenAddress  SC address of the ERC20 token to deposit
     * @param _id the id generated by the withdraw method call by the user
     */

    function withdrawTo(
        address _accountTo,
        uint256 _amount,
        address _tokenAddress,
        bytes32 _id,
        uint256 _baseFee
    ) external;

    /**
     * @dev used to release funds in different token.
     * @param _accountTo eth address to send the withdrawal tokens
     * @param _amount amount of token in
     * @param _tokenIn address of the token in
     * @param _tokenOut address of the token out
     * @param _id withdrawal id
     * @param _amountOutMin minimum amount out user want
     * @param _data additional data required for each AMM implementation
     */

    function withdrawDifferentTokenTo(
        address _accountTo,
        uint256 _amount,
        address _tokenIn,
        address _tokenOut,
        bytes32 _id,
        uint256 _baseFee,
        uint256 _amountOutMin,
        uint256 _ammID,
        bytes calldata _data
    ) external;

    /**
     * @dev starts save funds lockup timer change.
     * @param _time lock up time duration
     */

    function startSaveFundsLockUpTimerChange(uint256 _time) external;

    /**
     * @dev starts save funds transfer.
     * @param _token Token's balance the owner wants to withdraw
     * @param _to Receiver address
     */

    function startSaveFunds(address _token, address _to) external;

    /**
     * @dev set save funds lock up time.
     */

    function setSaveFundsLockUpTime() external;

    /**
     * @dev manually moves funds back to L1.
     */

    function executeSaveFunds() external;

    /**
     * @dev used to unlock the funds to be added in the liquidity of the vault.
     * @param _token erc20 address
     * @param _amount the amount of tokens to unlock for transfer
     * @param _id withdrawal id
     */

    function unlockTransferFunds(
        address _token,
        uint256 _amount,
        bytes32 _id
    ) external;

    /**
     * @dev used to return the tokens back to user in case of a failed
     * transfer between layers.
     * @param _token erc20 address
     * @param _user receivers address
     * @param _amount the amount of tokens to unlock for transfer
     * @param _id withdrawal id
     */

    function refundTransferFunds(
        address _token,
        address _user,
        uint256 _amount,
        bytes32 _id
    ) external;

    /**
     * @dev returns remote token address by network ID.
     * @param _networkID  network ID of remote token
     * @param _tokenAddress  SC address of the ERC20 token to deposit
     */

    function getRemoteTokenAddress(uint256 _networkID, address _tokenAddress)
        external
        view
        returns (address tokenAddressRemote);

    /**
     * @dev used to pause the contract.
     */

    function pause() external;

    /**
     * @dev used to unpause the contract.
     */

    function unpause() external;

    /**
     * @dev used to send random tokens to the holding.
     * @param _token Address of the ERC20 token
     */

    function digestFunds(address _token) external;
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

interface IVaultConfigBase {
    event TokenCreated(address _underlyingToken);

    function getComposableHolding() external view returns (address);

    function getTokenBalance(address _token) external view returns (uint256);

    function setTokenFactoryAddress(address _tokenFactoryAddress) external;

    function setVault(address _vault) external;
}