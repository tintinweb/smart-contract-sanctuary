// SPDX-License-Identifier: MIT

/**
 * Created on 2021-06-07 08:50
 * @summary: Vault for storing ERC20 tokens that will be transferred by external event-based
 *           system to another network. The destination network can be checked on "connectedNetwork"
 * @author: Composable Finance - Pepe Blasco
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "../interfaces/IMosaicHolding.sol";
import "../interfaces/IMosaicExchange.sol";
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

    address public relayer;

    IMosaicVaultConfig public vaultConfig;

    struct DepositInfo {
        address token;
        uint256 amount;
    }
    
    struct WithdrawTemporaryData {
        address tokenIn;
        address remoteTokenIn;
        bytes32 id;
    }

    function initialize(address _mosaicVaultConfig) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        vaultConfig = IMosaicVaultConfig(_mosaicVaultConfig);
    }

    /// @notice External callable function to set the relayer address
    function setRelayer(address _relayer) external override onlyOwner {
        relayer = _relayer;
    }

    /// @notice External callable function to set the vault config address
    function setVaultConfig(address _vaultConfig) external override onlyOwner {
        vaultConfig = IMosaicVaultConfig(_vaultConfig);
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
        uint256 _maxTransferDelay,
        address _tokenOut,
        uint256 _remoteAmmId
    )
    external
    override
    onlyWhitelistedRemoteTokens(_remoteNetworkID, _tokenAddress)
    nonReentrant
    whenNotPausedNetwork(_remoteNetworkID)
    {
        require(_amount > 0, "ERR: AMOUNT");

        bytes32 id = vaultConfig.generateId();
        _transferERC20ToLayer(
            _amount,
            _tokenAddress,
            _remoteDestinationAddress,
            _remoteNetworkID,
            _tokenOut,
            _remoteAmmId,
            _maxTransferDelay,
            id
        );
    }

    // @notice transfer ETH converted to WETH to another Mosaic vault
    /// @param _maxTransferDelay delay in seconds for the relayer to execute the transaction
    function transferETHToLayer(
        address _remoteDestinationAddress,
        uint256 _remoteNetworkID,
        uint256 _maxTransferDelay,
        address _tokenOut,
        uint256 _remoteAmmId
    )
    external
    override
    payable
    nonReentrant
    whenNotPausedNetwork(_remoteNetworkID)
    {
        require(msg.value > 0, "ERR: AMOUNT");
        address weth = vaultConfig.wethAddress();
        require(weth != address(0), "WETH not set");
        require(vaultConfig.getUnderlyingIOUAddress(weth) != address(0), "WETH not whitelisted");
        // check if ETH transfer is possible
        require(
            vaultConfig.remoteTokenAddress(_remoteNetworkID, weth) != address(0),
            "ETH not whitelisted in this network"
        );

        bytes32 id = vaultConfig.generateId();
        _transferERC20ToLayer(
            msg.value,
            vaultConfig.wethAddress(),
            _remoteDestinationAddress,
            _remoteNetworkID,
            _tokenOut,
            _remoteAmmId,
            _maxTransferDelay,
            id
        );
    }

    function _transferERC20ToLayer(
        uint256 _amount,
        address _tokenAddress,
        address _remoteDestinationAddress,
        uint256 _remoteNetworkID,
        address _tokenOut,
        uint256 _remoteAmmId,
        uint256 _maxTransferDelay,
        bytes32 _id
    ) private inTokenTransferLimits(_tokenAddress, _amount) {
        require(
            lastTransfer[msg.sender] + vaultConfig.transferLockupTime() < block.timestamp,
            "Transfer not yet possible"
        );

        if (_tokenAddress == vaultConfig.wethAddress()) {
            // convert to WETH
            IWETH(_tokenAddress).deposit{value : _amount}();
            // transfer funds to holding
            IERC20Upgradeable(_tokenAddress).safeTransfer(
                vaultConfig.getMosaicHolding(),
                _amount
            );
        } else {
            // transfer funds to holding
            IERC20Upgradeable(_tokenAddress).safeTransferFrom(
                msg.sender,
                vaultConfig.getMosaicHolding(),
                _amount
            );
        }

        deposits[_id] = DepositInfo({token : _tokenAddress, amount : _amount});

        vaultConfig.setLockedTransferFunds(
            _tokenAddress,
            vaultConfig.transferLockupTime() + _amount
        );

        lastTransfer[msg.sender] = block.timestamp;

        // NOTE: _tokenOut == address(0) is reserved for
        //       the native token of the destination layer
        //       for eg: MATIC for Polygon
        emit TransferInitiated(
            msg.sender,
            _tokenAddress,
            vaultConfig.remoteTokenAddress(_remoteNetworkID, _tokenAddress),
            _remoteNetworkID,
            _amount,
            _remoteDestinationAddress,
            _id,
            _maxTransferDelay,
            _tokenOut,
            _remoteAmmId
        );

    }

    function provideActiveLiquidity(
        uint256 _amount,
        address _tokenAddress,
        uint256 _blocksForActiveLiquidity
    )
    external
    override
    validAddress(_tokenAddress)
    onlyWhitelistedToken(_tokenAddress)
    nonReentrant
    whenNotPaused
    inBlockApproveRange(_blocksForActiveLiquidity)
    {
        require(_amount > 0, "ERR: AMOUNT");
        _provideLiquidity(_amount, _tokenAddress, false, _blocksForActiveLiquidity);
    }

    function provideActiveEthLiquidity(uint256 _blocksForActiveLiquidity)
    public
    override
    payable
    validAddress(vaultConfig.wethAddress())
    onlyWhitelistedToken(vaultConfig.wethAddress())
    nonReentrant
    whenNotPaused
    inBlockApproveRange(_blocksForActiveLiquidity)
    {
        require(msg.value > 0, "ERR: AMOUNT");
        _provideLiquidity(msg.value, vaultConfig.wethAddress(), true, _blocksForActiveLiquidity);
    }
    
    function providePassiveLiquidity(uint256 _amount, address _tokenAddress)
    external
    override
    validAddress(_tokenAddress)
    onlyWhitelistedToken(_tokenAddress)
    nonReentrant
    whenNotPaused
    {
        require(_amount > 0, "ERR: AMOUNT");
        _provideLiquidity(_amount, _tokenAddress, false, 0);
    }

    function providePassiveEthLiquidity()
    public
    override
    payable
    validAddress(vaultConfig.wethAddress())
    onlyWhitelistedToken(vaultConfig.wethAddress())
    nonReentrant
    whenNotPaused
    {
        require(msg.value > 0, "ERR: AMOUNT");
        _provideLiquidity(msg.value, vaultConfig.wethAddress(), true, 0);
    }

    function _provideLiquidity(
        uint256 _amount,
        address _tokenAddress,
        bool _isWeth,
        uint256 _blocksForActiveLiquidity
    ) private {
        if (_isWeth) {
            IWETH(_tokenAddress).deposit{value : msg.value}();
        } else {
            IERC20Upgradeable(_tokenAddress).safeTransferFrom(
                msg.sender,
                vaultConfig.getMosaicHolding(),
                _amount
            );
        }
        if (_blocksForActiveLiquidity > 0) {
            IReceiptBase(vaultConfig.getUnderlyingIOUAddress(_tokenAddress)).mint(
                msg.sender,
                _amount
            );
            _updateAvailableTokenAfter(_tokenAddress, _blocksForActiveLiquidity);
            emit DepositActiveLiquidity(
                _tokenAddress,
                msg.sender,
                _amount,
                _blocksForActiveLiquidity
            );
        } else {
            IReceiptBase(vaultConfig.getUnderlyingReceiptAddress(_tokenAddress)).mint(
                msg.sender,
                _amount
            );
            emit DepositPassiveLiquidity(
                _tokenAddress,
                msg.sender,
                _amount
            );
        }
    }
    
    function _burnReceiptTokens(
        address _receiptAddress,
        address _provider,
        uint256 _amount
    ) internal {
        require(IReceiptBase(_receiptAddress).balanceOf(_provider) >= _amount, "Balance to low");
        IReceiptBase(_receiptAddress).burn(_provider, _amount);
    }
    
    // @notice for solving stack too deep error
    function _getWithdrawTemporaryData(
        address _receiptToken,
        address _tokenOut,
        uint256 _networkId
    ) private validAddress(_tokenOut) returns (WithdrawTemporaryData memory) {
        
        address tokenIn = IReceiptBase(_receiptToken).underlyingToken();
        address remoteTokenIn;
        // this condition is needed when the withdraw liquidity is requested on another network
        if (_networkId != block.chainid) {
            remoteTokenIn = vaultConfig.remoteTokenAddress(_networkId, tokenIn);
            require(remoteTokenIn != address(0), "TOKEN NOT WHITELISTED ON DESTINATION");
        } else {
            remoteTokenIn = tokenIn;
        }
        
        if (vaultConfig.getUnderlyingIOUAddress(tokenIn) == _receiptToken) {
            // active liquidity
            // check if liquidity period is over
            require(
                availableAfterBlock[msg.sender][tokenIn] <= block.number,
                "CANNOT WITHDRAW IN THIS BLOCK"
            );
        } else if (vaultConfig.getUnderlyingReceiptAddress(tokenIn) == _receiptToken){
            // passive liquidity
            // passive liquidity can only be withdrawn in the same token
            require(remoteTokenIn == _tokenOut, "TOKEN OUT IS DIFFERENT");
        } else {
            revert("TOKEN NOT WHITELISTED");
        }
        return WithdrawTemporaryData(tokenIn, remoteTokenIn, vaultConfig.generateId());
    }
    
    /// @notice External function called to add withdraw liquidity request
    /// @param _receiptToken Address of the iou token provider have
    /// @param _amountIn Amount of tokens provider want to withdraw
    /// @param _tokenOut Address of the token which LP wants to receive
    /// @param _amountOutMin Minimum amount of token user should get
    /// @param _ammID the amm to use for swapping
    function withdrawLiquidityRequest(
        address _receiptToken,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _amountOutMin,
        address _destinationAddress,
        uint256 _ammID,
        bytes calldata _data,
        uint256 _networkId
    )
    external
    override
    nonReentrant {
        
        require(_amountIn > 0, "ERR: AMOUNT");
        
        WithdrawTemporaryData memory tempData = _getWithdrawTemporaryData(_receiptToken, _tokenOut, _networkId);
        
        _burnReceiptTokens(_receiptToken, msg.sender, _amountIn);
        
        emit WithdrawRequest(
            msg.sender,
            tempData.tokenIn,
            _tokenOut,
            tempData.remoteTokenIn,
            _receiptToken,
            _destinationAddress,
            _amountIn,
            _amountOutMin,
            _ammID,
            _networkId,
            _data,
            tempData.id
        );
        
    }

    // called by relayer
    // @notice the relayer has to send _amountIn a bit less than emitted
    // in the WithdrawRequest event. this is because relayer will deduct a fee
    // for performing this transaction
    function withdrawLiquidity(
        address _receiver,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256 _ammID,
        bytes calldata _data,
        bytes32 _id
    ) external override nonReentrant onlyOwnerOrRelayer {
        
        require(hasBeenWithdrawn[_id] == false, "Already withdrawn");
        require(vaultConfig.getCurrentTokenLiquidity(_tokenIn) >= _amountIn, "ERR: VAULT BAL");
        
        uint256 amountOut;
        if (_tokenIn != _tokenOut) {
            // this might fail - in case of failed swap relayer has to call refundLiquidity
            amountOut = _swap(_amountIn, _amountOutMin, _tokenIn, _tokenOut, _ammID, _data);
        } else {
            amountOut = _amountIn;
        }
        
        IMosaicHolding(vaultConfig.getMosaicHolding()).transfer(
            _tokenOut,
            _receiver,
            amountOut
        );
        
        hasBeenWithdrawn[_id] = true;
        lastWithdrawID = _id;
        
        emit LiquidityWithdrawn(
            _receiver,
            _tokenIn,
            _tokenOut,
            _amountIn,
            amountOut
        );
    }

    // @notice called by the relayer to restore the user's liquidity
    //         when `withdrawLiquidityOnAnotherNetworkRequest` fails on the destination network
    /// @param _user address of the user account
    /// @param _amount amount of tokens
    /// @param _receiptToken  address of the receipt token
    /// @param _id the id generated by the withdraw method call by the user
    function refundLiquidity(
        address _user,
        uint256 _amount,
        address _receiptToken,
        bytes32 _id
    )
    external
    override
    onlyOwnerOrRelayer
    nonReentrant
    {
        require(_amount > 0, "ERR: AMOUNT");
        require(hasBeenRefunded[_id] == false, "REFUNDED");
        
        address tokenAddress = IReceiptBase(_receiptToken).underlyingToken();
        
        require(
            vaultConfig.getCurrentTokenLiquidity(tokenAddress) >= _amount,
            "ERR: VAULT BAL"
        );

        hasBeenRefunded[_id] = true;
        lastRefundedID = _id;
        
        if (vaultConfig.getUnderlyingIOUAddress(tokenAddress) == _receiptToken) {
            // is active
            IReceiptBase(vaultConfig.getUnderlyingIOUAddress(tokenAddress)).mint(
                _user,
                _amount
            );
        } else if(vaultConfig.getUnderlyingReceiptAddress(tokenAddress) == _receiptToken) {
            // is passive
            IReceiptBase(vaultConfig.getUnderlyingReceiptAddress(tokenAddress)).mint(
                _user,
                _amount
            );
        } else {
            revert("TOKEN NOT WHITELISTED");
        }

        emit LiquidityRefunded(tokenAddress, _receiptToken, _user, _amount, _id);
    }
    
    // @notice: method called by the relayer to release transfer funds
    /// @param _accountTo eth address to send the withdrawal tokens
    /// @param _amount amount of token in
    /// @param _tokenIn address of the token in
    /// @param _tokenOut address of the token out
    /// @param _id withdrawal _id
    /// @param _baseFee the fee taken by the relayer
    /// @param _amountOutMin minimum amount out user want
    /// @param _data additional _data required for each AMM implementation
    function withdrawTo(
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
    validAddress(_tokenOut)
    nonReentrant
    onlyOwnerOrRelayer
    whenNotPaused
    {
        require(hasBeenWithdrawn[_id] == false, "Already withdrawn");
        if (_tokenOut == _tokenIn) {
            require(
                vaultConfig.getCurrentTokenLiquidity(_tokenIn) >= _amount,
                "ERR: VAULT BAL"
            );
        }
        hasBeenWithdrawn[_id] = true;
        lastWithdrawID = _id;

        uint256 withdrawAmount = _takeFees(
            _tokenIn,
            _amount,
            _accountTo,
            _id,
            _baseFee
        );
        
        if (_tokenOut != _tokenIn) {
            withdrawAmount = _swap(
                withdrawAmount,
                _amountOutMin,
                _tokenIn,
                _tokenOut,
                _ammID,
                _data
            );
        }

        IMosaicHolding(vaultConfig.getMosaicHolding()).transfer(_tokenOut, _accountTo, withdrawAmount);

        emit WithdrawalCompleted(
            _accountTo,
            _amount,
            withdrawAmount,
            _tokenOut,
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

        uint256 fee = FeeOperations.getFeeAbsolute(_amount, vaultConfig.calculateFeePercentage(_token, _amount));

        if (_baseFee > 0) {
            IMosaicHolding(vaultConfig.getMosaicHolding()).transfer(
                _token,
                owner(),
                _baseFee
            );
        }

        if (fee > 0) {
            IMosaicHolding(vaultConfig.getMosaicHolding()).transfer(
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

        return _amount - fee;
    }



    /**
     * @notice Used to transfer randomly sent tokens to this contract to the Mosaic holding
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
            vaultConfig.getMosaicHolding(),
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
    )
    external
    override
    whenNotPaused
    onlyOwnerOrRelayer
    validDeposit(_token, _amount, _id) {
        
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
    )
    external
    override
    onlyOwnerOrRelayer
    nonReentrant
    validDeposit(_token, _amount, _id) {

        hasBeenRefunded[_id] = true;
        lastRefundedID = _id;

        IMosaicHolding(vaultConfig.getMosaicHolding()).transfer(
            _token,
            _user,
            _amount
        );
        
        // update the lockedTransferFunds for the token
        vaultConfig.setLockedTransferFunds(
            _token,
            vaultConfig.lockedTransferFunds(_token) - _amount
        );

        delete deposits[_id];

        emit TransferFundsRefunded(_token, _user, _amount, _id);
    }

    receive() external payable {
        provideActiveEthLiquidity(vaultConfig.maxLimitLiquidityBlocks());
    }

    function _swap(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _tokenIn,
        address _tokenOut,
        uint256 _ammID,
        bytes memory _data
    ) private returns (uint256) {
        address mosaicHolding = vaultConfig.getMosaicHolding();
        IMosaicHolding(mosaicHolding).transfer(
            _tokenIn,
            address(this),
            _amountIn
        );
        address ammAddress = vaultConfig.getAMMAddress(_ammID);
        require(ammAddress != address(0), "AMM not supported");

        IERC20Upgradeable(_tokenIn).safeApprove(ammAddress, _amountIn);

        uint256 amountToSend = IMosaicExchange(ammAddress).swap(
            _tokenIn,
            _tokenOut,
            _amountIn,
            _amountOutMin,
            _data
        );
        require(amountToSend >= _amountOutMin, "AMM: Price to low");
        IERC20Upgradeable(_tokenOut).safeTransfer(mosaicHolding, amountToSend);
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

    modifier onlyWhitelistedToken(address _tokenAddress) {
        require(
            vaultConfig.getUnderlyingIOUAddress(_tokenAddress) != address(0),
            "Token not whitelisted"
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
            "TOKEN NOT WHITELISTED ON DESTINATION"
        );
        _;
    }

    modifier whenNotPausedNetwork(uint256 _networkID) {
        require(paused() == false, "Contract is paused");
        require(vaultConfig.pausedNetwork(_networkID) == false, "Network is paused");
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

    modifier availableToWithdrawLiquidity(address _iouTokenAddress) {
        address _token = IReceiptBase(_iouTokenAddress).underlyingToken();
        require(
            availableAfterBlock[msg.sender][_token] <= block.number,
            "Can't withdraw token in this block"
        );
        _;
    }

    modifier inBlockApproveRange(uint256 _blocksForActiveLiquidity) {
        require(
            _blocksForActiveLiquidity >=
            vaultConfig.minLimitLiquidityBlocks() &&
            _blocksForActiveLiquidity <=
            vaultConfig.maxLimitLiquidityBlocks(),
            "Not within block approve range"
        );
        _;
    }
    
    modifier validDeposit(
        address _token,
        uint256 _amount,
        bytes32 _id
    ) {
        // should not be refunded
        require(hasBeenRefunded[_id] == false, "REFUNDED");
        // should not be unlocked
        require(hasBeenUnlocked[_id] == false, "UNLOCKED");
        // check if the vault has enough locked balance
        require(
            vaultConfig.lockedTransferFunds(_token) >= _amount, "VAULT LOCKED BAL"
        );
        // check if the deposit data matches
        require(
            deposits[_id].token == _token && deposits[_id].amount == _amount,
            "INVALID DEPOSIT"
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

interface IMosaicHolding {
    event FoundsInvested(
        address indexed strategy,
        address indexed admin,
        uint256 cTokensReceived
    );

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

    event TokenClaimed(
        address indexed strategy,
        address indexed rewardTokenAddress
    );

    event SaveFundsStarted(address owner, address token, address receiver);

    event LiquidityMoved(
        address indexed to,
        address indexed tokenAddress,
        uint256 amount
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

    function saveFundsLockupTime() external view returns (uint256);
    function newSaveFundsLockUpTime() external view returns (uint256);
    function durationToChangeTimer() external view returns (uint256);

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
     * @dev set save funds lock up time.
     */

    function setSaveFundsLockUpTime() external;

    /**
    * @dev starts save funds lockup timer change.
     * @param _time lock up time duration
     */

    function startSaveFundsLockUpTimerChange(uint256 _time) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMosaicExchange {
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

    function underlyingToken() external returns(address);
    
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
        address indexed owner,
        address indexed erc20,
        address remoteTokenAddress,
        uint256 indexed remoteNetworkID,
        uint256 value,
        address remoteDestinationAddress,
        bytes32 uniqueId,
        uint256 maxTransferDelay,
        address tokenOut,
        uint256 ammID
    );

    event WithdrawalCompleted(
        address indexed accountTo,
        uint256 amount,
        uint256 netAmount,
        address indexed tokenAddress,
        bytes32 indexed uniqueId
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

    event DepositActiveLiquidity(
        address indexed tokenAddress,
        address indexed provider,
        uint256 amount,
        uint256 blocks
    );

    event DepositPassiveLiquidity(
        address indexed tokenAddress,
        address indexed provider,
        uint256 amount
    );

    event LiquidityWithdrawn(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    event LiquidityRefunded(
        address indexed tokenAddress,
        address indexed receiptAddress,
        address indexed user,
        uint256 amount,
        bytes32 uniqueId
    );

    event WithdrawRequest(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        address remoteTokenInAddress,
        address receiptToken,
        address destinationAddress,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 ammId,
        uint256 remoteNetworkID,
        bytes data,
        bytes32 uniqueId
    );

    function setRelayer(address _relayer) external;

    function setVaultConfig(address _vaultConfig) external;

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
        uint256 _maxTransferDelay,
        address _tokenOut,
        uint256 _remoteAmmId
    ) external;

    /**
     * @dev transfer ETH to another Mosaic vault
     * @param _remoteDestinationAddress SC address of the ERC20 supported tokens in a diff network
     * @param _remoteNetworkID  network ID of remote token
     * @param _maxTransferDelay delay in seconds for the relayer to execute the transaction
     */

    function transferETHToLayer(
        address _remoteDestinationAddress,
        uint256 _remoteNetworkID,
        uint256 _maxTransferDelay,
        address _tokenOut,
        uint256 _remoteAmmId
    ) external payable;

    /**
     * @dev used to provide active liquidity.
     * @param _amount amount of tokens to deposit
     * @param _tokenAddress  SC address of the ERC20 token to deposit
     * @param _blocksForActiveLiquidity users choice of active liquidity
     */

    function provideActiveLiquidity(
        uint256 _amount,
        address _tokenAddress,
        uint256 _blocksForActiveLiquidity
    ) external;

    /**
   * @dev used to provide passive liquidity.
     * @param _amount amount of tokens to deposit
     * @param _tokenAddress  SC address of the ERC20 token to deposit
     */

    function providePassiveLiquidity(uint256 _amount, address _tokenAddress) external;

    /**
     * @dev used to provide active eth liquidity.
     * @param _blocksForActiveLiquidity  users choice of active liquidity
     */

    function provideActiveEthLiquidity(
        uint256 _blocksForActiveLiquidity
    ) external payable;

    /**
     * @dev used to provide active eth liquidity.
     */

    function providePassiveEthLiquidity() external payable;

    /**
     * @dev used by the relayer to send liquidity to the user
     * @param _receiver Address of the token receiver
     * @param _tokenIn  SC address of the ERC20 token to deposit
     * @param _amountIn amount of tokens to deposit
     */

    function withdrawLiquidity(
        address _receiver,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256 _ammID,
        bytes calldata _data,
        bytes32 _id
    ) external;

    /**
     * @dev used to add withdraw liquidity request
     * @param _receiptToken  SC address of the ERC20 token to deposit
     * @param _amountIn amount of tokens to deposit
     */
    function withdrawLiquidityRequest(
        address _receiptToken,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _amountOutMin,
        address _destinationAddress,
        uint256 _ammID,
        bytes calldata _data,
        uint256 _networkId
    ) external;

    /**
     * @dev called by the relayer to restore the user's liquidity
     * when `withdrawDifferentTokenTo` fails on the destination layer.
     * @param _user address of the user account
     * @param _amount amount of tokens
     * @param _receiptToken  address of the receipt token
     * @param _id the id generated by the withdraw method call by the user
     */

    function refundLiquidity(
        address _user,
        uint256 _amount,
        address _receiptToken,
        bytes32 _id
    ) external;

    /**
     * @dev used to release funds
     * @param _accountTo eth address to send the withdrawal tokens
     * @param _amount amount of token in
     * @param _tokenIn address of the token in
     * @param _tokenOut address of the token out
     * @param _id withdrawal id
     * @param _amountOutMin minimum amount out user want
     * @param _data additional data required for each AMM implementation
     */

    function withdrawTo(
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

    function getMosaicHolding() external view returns (address);

    function getTokenBalance(address _token) external view returns (uint256);

    function setTokenFactoryAddress(address _tokenFactoryAddress) external;

    function setVault(address _vault) external;
}