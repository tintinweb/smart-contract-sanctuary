// SPDX-License-Identifier: MIT
// @unsupported: ovm

/**
 * Created on 2021-06-07 08:50
 * @summary: Vault for storing ERC20 tokens that will be transferred by external event-based system to another network. The destination network can be checked on "connectedNetwork"
 * @author: Composable Finance - Pepe Blasco
 */
pragma solidity ^0.6.8;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import "../interfaces/IComposableHolding.sol";
import "../interfaces/IComposableExchange.sol";
import "../interfaces/IReceiptBase.sol";
import "../interfaces/ITokenFactory.sol";

import "../libraries/FeeOperations.sol";

//@title: Composable Finance L2 ERC20 Vault
contract L2Vault is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeMath for uint256;

    uint256 nonce;
    uint256 minFee;
    uint256 maxFee;
    uint256 feeThreshold;
    uint256 transferLockupTime;
    uint256 public minLimitLiquidityBlocks;
    uint256 public maxLimitLiquidityBlocks;
    address public feeAddress;
    string private constant tokenName = "IOU-";

    mapping(uint256 => bool) public pausedNetwork;

    IComposableHolding private composableHolding;
    ITokenFactory private iouTokenFactory;

    /*
    UNISWAP = 2
    SUSHISWAP = 3
    CURVE = 4
    */
    mapping(uint256 => address) private supportedAMMs;

    mapping(bytes32 => bool) public hasBeenWithdrawn;
    mapping(bytes32 => bool) public hasBeenUnlocked;
    mapping(bytes32 => bool) public hasBeenRefunded;

    bytes32 public lastWithdrawID;
    bytes32 public lastUnlockID;
    bytes32 public lastRefundedID;

    mapping(address => uint256) public lastTransfer;
    mapping(uint256 => mapping(address => address)) public remoteTokenAddress; // remoteTokenAddress[networkID][addressHere] = addressThere
    mapping(address => uint256) public lockedTransferFunds;
    /// @dev Store the address of the IOU token receipt
    mapping(address => address) public underlyingIOUAddress;

    event TransferInitiated(
        address indexed account,
        address indexed erc20,
        address remoteTokenAddress,
        uint256 indexed remoteNetworkID,
        uint256 value,
        address remoteDestinationAddress,
        bytes32 uniqueId,
        uint256 transferDelay
    );
    event TokenAdded(
        address indexed erc20,
        address indexed remoteTokenAddress,
        uint256 indexed remoteNetworkID
    );
    event TokenRemoved(
        address indexed erc20,
        address indexed remoteTokenAddress,
        uint256 indexed remoteNetworkID
    );
    event MinFeeChanged(uint256 newMinFee);
    event MaxFeeChanged(uint256 newMaxFee);
    event MinLiquidityBlockChanged(uint256 newMinLimitLiquidityBlocks);
    event MaxLiquidityBlockChanged(uint256 newMaxLimitLiquidityBlocks);
    event ThresholdFeeChanged(uint256 newFeeThreshold);
    event FeeAddressChanged(address feeAddress);
    event WithdrawalCompleted(
        address accountTo,
        uint256 amount,
        address tokenAddress,
        bytes32 uniqueId
    );
    event LiquidityMoved(
        address indexed _owner,
        address indexed _to,
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
    event LockupTimeChanged(
        address indexed _owner,
        uint256 _oldVal,
        uint256 _newVal,
        string valType
    );
    event PauseNetwork(address admin, uint256 networkID);
    event UnpauseNetwork(address admin, uint256 networkID);
    event FeeTaken(
        address indexed _owner,
        address indexed _user,
        address indexed _token,
        uint256 _amount,
        uint256 _fee,
        bytes32 uniqueId
    );

    event TokenReceiptCreated(address underlyingToken);

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

    function initialize(address _feeAddress, address _composableHolding)
        public
        initializer
    {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

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

    /// @notice Public function to add address of the AMM used to swap tokens
    /// @param ammID the integer constant for the AMM
    /// @param ammAddress Address of the AMM
    /// @dev AMM should be a wrapper created by us over the AMM implementation
    function addSupportedAMM(uint256 ammID, address ammAddress)
        public
        onlyOwner
        validAddress(ammAddress)
    {
        supportedAMMs[ammID] = ammAddress;
    }

    /// @notice Public function to remove address of the AMM
    /// @param ammID the integer constant for the AMM
    function removeSupportedAMM(uint256 ammID) public onlyOwner {
        delete supportedAMMs[ammID];
    }

    /// @notice External function used to set the IOU Token Factory Address
    /// @dev Address of the factory need to be set after the initialization in order to use the vault
    /// @param iouTokenFactoryAddress Address of the already deployed IOU Token Factory
    function setIOUTokenFactoryAddress(address iouTokenFactoryAddress)
        external
        onlyOwner
        validAddress(iouTokenFactoryAddress)
    {
        iouTokenFactory = ITokenFactory(iouTokenFactoryAddress);
    }

    function _generateId() private returns (bytes32) {
        return
            keccak256(abi.encodePacked(block.number, address(this), nonce++));
    }

    // @notice: Adds a supported token to the contract, allowing for anyone to deposit their tokens.
    // @param tokenAddress  SC address of the ERC20 token to add to supported tokens

    function addSupportedToken(
        address tokenAddress,
        address tokenAddressRemote,
        uint256 remoteNetworkID
    ) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        require(tokenAddressRemote != address(0), "Invalid token address");
        require(remoteNetworkID > 0, "Invalid network ID");

        _deployIOU(tokenAddress);

        remoteTokenAddress[remoteNetworkID][tokenAddress] = tokenAddressRemote;

        emit TokenAdded(tokenAddress, tokenAddressRemote, remoteNetworkID);
    }

    // @notice: removes supported token from the contract, avoiding new deposits and withdrawals.
    // @param tokenAddress  SC address of the ERC20 token to remove from supported tokens

    function removeSupportedToken(address tokenAddress, uint256 remoteNetworkID)
        external
        onlyOwner
        onlySupportedRemoteTokens(remoteNetworkID, tokenAddress)
    {
        emit TokenRemoved(
            tokenAddress,
            remoteTokenAddress[remoteNetworkID][tokenAddress],
            remoteNetworkID
        );
        delete remoteTokenAddress[remoteNetworkID][tokenAddress];
        delete underlyingIOUAddress[tokenAddress];
    }

    function setTransferLockupTime(uint256 lockupTime) external onlyOwner {
        emit LockupTimeChanged(
            msg.sender,
            transferLockupTime,
            lockupTime,
            "Transfer"
        );
        transferLockupTime = lockupTime;
    }

    /// @notice External callable function to pause the contract
    function pauseNetwork(uint256 networkID) external onlyOwner {
        pausedNetwork[networkID] = true;
        emit PauseNetwork(msg.sender, networkID);
    }

    /// @notice External callable function to unpause the contract
    function unpauseNetwork(uint256 networkID) external onlyOwner {
        pausedNetwork[networkID] = false;
        emit UnpauseNetwork(msg.sender, networkID);
    }

    // @notice: Updates the minimum fee
    // @param newMinFee
    function setMinFee(uint256 newMinFee) external onlyOwner {
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
    function setMaxFee(uint256 newMaxFee) external onlyOwner {
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
    function setThresholdFee(uint256 newThresholdFee) external onlyOwner {
        require(
            newThresholdFee < 100,
            "Threshold fee cannot be more than threshold factor"
        );

        feeThreshold = newThresholdFee;
        emit ThresholdFeeChanged(newThresholdFee);
    }

    // @notice: Updates the account where to send deposit fees
    // @param newFeeAddress
    function setFeeAddress(address newFeeAddress) external onlyOwner {
        require(newFeeAddress != address(0), "Invalid fee address");

        feeAddress = newFeeAddress;
        emit FeeAddressChanged(feeAddress);
    }

    // @notice: checks for the current balance of this contract's address on the ERC20 contract
    // @param tokenAddress  SC address of the ERC20 token to get liquidity from
    function getCurrentTokenLiquidity(address tokenAddress)
        public
        view
        returns (uint256)
    {
        require(
            address(composableHolding) != address(0),
            "Composable Holding address not set"
        );
        // remove the locked transfer funds from the balance of the vault
        return
            IERC20(tokenAddress).balanceOf(address(composableHolding)).sub(
                lockedTransferFunds[tokenAddress]
            );
    }

    // @notice transfer ERC20 token to another l2 vault
    // @param amount amount of tokens to deposit
    // @param tokenAddress  SC address of the ERC20 token to deposit
    // @param transferDelay delay in seconds for the relayer to execute the transaction
    function transferERC20ToLayer(
        uint256 amount,
        address tokenAddress,
        address remoteDestinationAddress,
        uint256 remoteNetworkID,
        uint256 transferDelay
    )
        external
        validAmount(amount)
        onlySupportedRemoteTokens(remoteNetworkID, tokenAddress)
        nonReentrant
        whenNotPausedNetwork(remoteNetworkID)
    {
        require(
            lastTransfer[msg.sender].add(transferLockupTime) < block.timestamp,
            "Transfer not yet possible"
        );
        SafeERC20.safeTransferFrom(
            IERC20(tokenAddress),
            msg.sender,
            address(composableHolding),
            amount
        );

        uint256 newLockedAmount = lockedTransferFunds[tokenAddress].add(amount);
        lockedTransferFunds[tokenAddress] = newLockedAmount;

        lastTransfer[msg.sender] = block.timestamp;
        bytes32 id = _generateId();
        emit TransferInitiated(
            msg.sender,
            tokenAddress,
            remoteTokenAddress[remoteNetworkID][tokenAddress],
            remoteNetworkID,
            amount,
            remoteDestinationAddress,
            id,
            transferDelay
        );
    }

    function provideLiquidity(
        uint256 amount,
        address tokenAddress,
        uint256 blocksForActiveLiquidity
    )
        external
        validAddress(tokenAddress)
        validAmount(amount)
        onlySupportedToken(tokenAddress)
        nonReentrant
        whenNotPaused
    {
        require(
            blocksForActiveLiquidity >= minLimitLiquidityBlocks &&
                blocksForActiveLiquidity <= maxLimitLiquidityBlocks,
            "not within block approve range"
        );
        SafeERC20.safeTransferFrom(
            IERC20(tokenAddress),
            msg.sender,
            address(composableHolding),
            amount
        );
        IReceiptBase(underlyingIOUAddress[tokenAddress]).mint(
            msg.sender,
            amount
        );
        emit DepositLiquidity(
            tokenAddress,
            msg.sender,
            amount,
            blocksForActiveLiquidity
        );
    }

    function withdrawLiquidity(address tokenAddress, uint256 amount)
        external
        validAddress(tokenAddress)
        validAmount(amount)
        enoughLiquidityInVault(tokenAddress, amount)
    {
        _burnIOUTokens(tokenAddress, msg.sender, amount);

        composableHolding.transfer(tokenAddress, msg.sender, amount);
        emit LiquidityWithdrawn(tokenAddress, msg.sender, amount);
    }

    // @notice called by the relayer to restore the user's liquidity
    //         when `withdrawDifferentTokenTo` fails on the destination layer
    // @param _user address of the user account
    // @param _amount amount of tokens
    // @param _tokenAddress  address of the ERC20 token
    // @param _id the id generated by the withdraw method call by the user
    function refundLiquidity(
        address _user,
        uint256 _amount,
        address _tokenAddress,
        bytes32 _id
    )
        external
        onlyOwner
        validAmount(_amount)
        enoughLiquidityInVault(_tokenAddress, _amount)
        nonReentrant
    {
        require(hasBeenRefunded[_id] == false, "Already refunded");

        hasBeenRefunded[_id] = true;
        lastRefundedID = _id;

        IReceiptBase(underlyingIOUAddress[_tokenAddress]).mint(_user, _amount);

        emit LiquidityRefunded(_tokenAddress, _user, _amount, _id);
    }

    /// @notice External function called to withdraw liquidity in different token
    /// @param tokenIn Address of the token provider have
    /// @param tokenOut Address of the token provider want to receive
    /// @param amountIn Amount of tokens provider want to withdraw
    /// @param amountOutMin Minimum amount of token user should get
    function withdrawLiquidityToDifferentToken(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 ammID,
        bytes calldata data
    )
        external
        validAmount(amountIn)
        onlySupportedToken(tokenOut)
        onlySupportedToken(tokenIn)
        differentAddresses(tokenIn, tokenOut)
        isAMMSupported(ammID)
    {
        _burnIOUTokens(tokenIn, msg.sender, amountIn);
        composableHolding.transfer(tokenIn, address(this), amountIn);
        SafeERC20.safeApprove(IERC20(tokenIn), supportedAMMs[ammID], amountIn);
        uint256 amountToSend = IComposableExchange(supportedAMMs[ammID]).swap(
            tokenIn,
            tokenOut,
            amountIn,
            amountOutMin,
            data
        );
        SafeERC20.safeTransfer(IERC20(tokenOut), msg.sender, amountToSend);
        emit LiquidityWithdrawn(tokenOut, msg.sender, amountToSend);
    }

    function withdrawLiquidityOnAnotherL2Network(
        address tokenAddress,
        uint256 amount,
        address remoteDestinationAddress,
        uint256 _networkID
    )
        external
        validAddress(tokenAddress)
        validAmount(amount)
        onlySupportedRemoteTokens(_networkID, tokenAddress)
    {
        _burnIOUTokens(tokenAddress, msg.sender, amount);

        emit WithdrawOnRemoteNetworkStarted(
            msg.sender,
            tokenAddress,
            remoteTokenAddress[_networkID][tokenAddress],
            _networkID,
            amount,
            remoteDestinationAddress,
            _generateId()
        );
    }

    /// @notice External function called to withdraw liquidity in different token on another network
    /// @param tokenIn Address of the token provider have
    /// @param tokenOut Address of the token provider want to receive
    /// @param amountIn Amount of tokens provider want to withdraw
    /// @param networkID Id of the network want to receive the other token
    /// @param amountOutMin Minimum amount of token user should get
    function withdrawLiquidityToDifferentTokenOnAnotherL2Network(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 networkID,
        uint256 amountOutMin,
        address remoteDestinationAddress,
        uint256 remoteAmmId
    )
        external
        validAmount(amountIn)
        onlySupportedToken(tokenOut)
        onlySupportedToken(tokenIn)
        onlySupportedRemoteTokens(networkID, tokenOut)
    {
        _withdrawToNetworkInDifferentToken(
            tokenIn,
            tokenOut,
            amountIn,
            networkID,
            amountOutMin,
            remoteDestinationAddress,
            remoteAmmId
        );
    }

    /// @dev internal function to withdraw different token on another network
    /// @dev use this approach to avoid stack too deep error
    function _withdrawToNetworkInDifferentToken(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 networkID,
        uint256 amountOutMin,
        address remoteDestinationAddress,
        uint256 remoteAmmId
    ) internal differentAddresses(tokenIn, tokenOut) {
        _burnIOUTokens(tokenIn, msg.sender, amountIn);

        emit WithdrawOnRemoteNetworkForDifferentTokenStarted(
            msg.sender,
            remoteTokenAddress[networkID][tokenOut],
            networkID,
            amountIn,
            amountOutMin,
            remoteDestinationAddress,
            remoteAmmId,
            _generateId()
        );
    }

    function _burnIOUTokens(
        address tokenAddress,
        address provider,
        uint256 amount
    ) internal {
        IReceiptBase t = IReceiptBase(underlyingIOUAddress[tokenAddress]);
        require(t.balanceOf(provider) >= amount, "IOU Token balance to low");
        t.burn(provider, amount);
    }

    function calculateFeePercentage(address tokenAddress, uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 tokenLiquidity = getCurrentTokenLiquidity(tokenAddress);

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

    // @notice: method called by the relayer to release funds
    // @param accountTo eth address to send the withdrawal tokens
    function withdrawTo(
        address accountTo,
        uint256 amount,
        address tokenAddress,
        bytes32 id
    )
        external
        onlySupportedToken(tokenAddress)
        enoughLiquidityInVault(tokenAddress, amount)
        nonReentrant
        onlyOwner
        whenNotPaused
        notAlreadyWithdrawn(id)
    {
        _withdraw(accountTo, amount, tokenAddress, address(0), id, 0, 0, "");
    }

    // @notice: method called by the relayer to release funds in different token
    // @param accountTo eth address to send the withdrawal tokens
    // @param amount amount of token in
    // @param tokenIn address of the token in
    // @param tokenOut address of the token out
    // @param id withdrawal id
    // @param amountOutMin minimum amount out user want
    // @param data additional data required for each AMM implementation
    function withdrawDifferentTokenTo(
        address accountTo,
        uint256 amount,
        address tokenIn,
        address tokenOut,
        bytes32 id,
        uint256 amountOutMin,
        uint256 ammID,
        bytes calldata data
    )
        external
        onlySupportedToken(tokenIn)
        nonReentrant
        onlyOwner
        whenNotPaused
        notAlreadyWithdrawn(id)
    {
        _withdraw(
            accountTo,
            amount,
            tokenIn,
            tokenOut,
            id,
            amountOutMin,
            ammID,
            data
        );
    }

    function _withdraw(
        address accountTo,
        uint256 amount,
        address tokenIn,
        address tokenOut,
        bytes32 id,
        uint256 amountOutMin,
        uint256 ammID,
        bytes memory data
    ) private {
        hasBeenWithdrawn[id] = true;
        lastWithdrawID = id;
        uint256 withdrawAmount = _takeFees(tokenIn, amount, accountTo, id);

        if (tokenOut == address(0)) {
            composableHolding.transfer(tokenIn, accountTo, withdrawAmount);
        } else {
            require(supportedAMMs[ammID] != address(0), "AMM not supported");
            composableHolding.transfer(tokenIn, address(this), withdrawAmount);
            SafeERC20.safeApprove(
                IERC20(tokenIn),
                supportedAMMs[ammID],
                withdrawAmount
            );
            uint256 amountToSend = IComposableExchange(supportedAMMs[ammID])
                .swap(tokenIn, tokenOut, withdrawAmount, amountOutMin, data);
            require(amountToSend >= amountOutMin, "AMM: Price to low");
            SafeERC20.safeTransfer(IERC20(tokenOut), accountTo, amountToSend);
        }

        emit WithdrawalCompleted(accountTo, amount, tokenIn, id);
    }

    function _takeFees(
        address token,
        uint256 amount,
        address accountTo,
        bytes32 withdrawRequestId
    ) private returns (uint256) {
        uint256 fee = calculateFeePercentage(token, amount);
        uint256 feeAbsolute = FeeOperations.getFeeAbsolute(amount, fee);
        uint256 withdrawAmount = amount.sub(feeAbsolute);

        if (feeAbsolute > 0) {
            composableHolding.transfer(token, feeAddress, feeAbsolute);
            emit FeeTaken(
                msg.sender,
                accountTo,
                token,
                amount,
                feeAbsolute,
                withdrawRequestId
            );
        }
        return withdrawAmount;
    }

    /**
     * @notice Will be called once the contract is paused and token's available liquidity will be manually moved back to L1
     * @param _token Token's balance the owner wants to withdraw
     * @param _to Receiver address
     */
    function saveFunds(address _token, address _to)
        external
        onlyOwner
        whenPaused
        validAddress(_token)
        validAddress(_to)
    {
        uint256 balance = IERC20(_token).balanceOf(address(composableHolding));
        require(balance > 0, "nothing to transfer");
        composableHolding.transfer(_token, _to, balance);
        emit LiquidityMoved(msg.sender, _to, balance);
    }

    /**
     * @notice The idea is to be able to withdraw to a controlled address certain amount of
               token liquidity in order to re-balance among different L2s (manual bridge to L1
               and then act accordingly)
     * @param _token Token's balance the owner wants to withdraw
     * @param _to Receiver address
     * @param _amount the amount of tokens to withdraw from the vault
     */
    function withdrawFunds(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner validAddress(_token) validAddress(_to) {
        uint256 tokenLiquidity = getCurrentTokenLiquidity(_token);
        require(
            tokenLiquidity >= _amount,
            "withdrawFunds: vault balance is low"
        );
        composableHolding.transfer(_token, _to, _amount);
        emit LiquidityMoved(msg.sender, _to, _amount);
    }

    /*
    this method is called by the relayer after a successful transfer of tokens between layers
    this is called to unlock the funds to be added in the liquidity of the vault
    */
    function unlockTransferFunds(
        address _token,
        uint256 _amount,
        bytes32 _id
    ) public whenNotPaused onlyOwner {
        require(hasBeenUnlocked[_id] == false, "Already unlocked");
        require(
            lockedTransferFunds[_token] >= _amount,
            "More amount than available"
        );

        hasBeenUnlocked[_id] = true;
        lastUnlockID = _id;

        // update the lockedTransferFunds for the token
        uint256 newInTransferFunds = lockedTransferFunds[_token].sub(_amount);
        lockedTransferFunds[_token] = newInTransferFunds;

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
    ) external onlyOwner nonReentrant {
        require(hasBeenRefunded[_id] == false, "Already refunded");

        // unlock the funds
        if (hasBeenUnlocked[_id] == false) {
            unlockTransferFunds(_token, _amount, _id);
        }

        hasBeenRefunded[_id] = true;
        lastRefundedID = _id;

        composableHolding.transfer(_token, _user, _amount);

        emit TransferFundsRefunded(_token, _user, _amount, _id);
    }

    /// @dev Internal function called when deploy a receipt IOU token based on already deployed ERC20 token
    function _deployIOU(address underlyingToken) private returns (address) {
        require(
            address(iouTokenFactory) != address(0),
            "IOU token factory not initialized"
        );

        address newIou = iouTokenFactory.createIOU(
            underlyingToken,
            tokenName
        );

        underlyingIOUAddress[underlyingToken] = newIou;

        emit TokenReceiptCreated(underlyingToken);
        return newIou;
    }

    function getRemoteTokenAddress(uint256 _networkID, address _tokenAddress)
        external
        view
        returns (address tokenAddressRemote)
    {
        tokenAddressRemote = remoteTokenAddress[_networkID][_tokenAddress];
    }

    /// @notice External callable function to pause the contract
    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    /// @notice External callable function to unpause the contract
    function unpause() external whenPaused onlyOwner {
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

    modifier onlySupportedToken(address tokenAddress) {
        require(
            underlyingIOUAddress[tokenAddress] != address(0),
            "Unsupported token"
        );
        _;
    }

    modifier onlySupportedRemoteTokens(
        uint256 networkID,
        address tokenAddress
    ) {
        require(
            remoteTokenAddress[networkID][tokenAddress] != address(0),
            "Unsupported token in this network"
        );
        _;
    }

    modifier whenNotPausedNetwork(uint256 networkID) {
        require(paused() == false, "Contract is paused");
        require(pausedNetwork[networkID] == false, "Network is paused");
        _;
    }

    modifier differentAddresses(
        address tokenAddress,
        address tokenAddressReceive
    ) {
        require(tokenAddress != tokenAddressReceive, "Same token address");
        _;
    }

    modifier isAMMSupported(uint256 ammID) {
        require(supportedAMMs[ammID] != address(0), "AMM not supported");
        _;
    }

    modifier enoughLiquidityInVault(address tokenAddress, uint256 amount) {
        require(
            getCurrentTokenLiquidity(tokenAddress) >= amount,
            "Not enough tokens in the vault"
        );
        _;
    }

    modifier notAlreadyWithdrawn(bytes32 id) {
        require(hasBeenWithdrawn[id] == false, "Already withdrawn");
        _;
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

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

interface IComposableExchange {
    function swap(address tokenA, address tokenB, uint256 amountIn, uint256 amountOut, bytes calldata data) external returns(uint256);

    function getAmountsOut(address tokenIn, address tokenOut, uint256 amountIn, bytes calldata data) external returns(uint256);
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
// @unsupported: ovm
pragma solidity ^0.6.8;

interface ITokenFactory {
    function createIOU(address underlyingAddress, string calldata _tokenName)
        external
        returns (address);

    function createReceipt(
        address underlyingAddress,
        string calldata _tokenName
    ) external returns (address);
}

// SPDX-License-Identifier: MIT

/**
 * Created on 2021-06-07 08:50
 * @summary: Vault for storing ERC20 tokens that will be transferred by external event-based system to another network. The destination network can be checked on "connectedNetwork"
 * @author: Composable Finance - Pepe Blasco
 */
pragma solidity ^0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";

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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
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

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}