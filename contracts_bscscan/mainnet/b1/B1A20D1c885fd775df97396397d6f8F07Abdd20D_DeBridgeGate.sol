// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../interfaces/IERC20Permit.sol";
import "../interfaces/IDeBridgeToken.sol";
import "../interfaces/IDeBridgeTokenDeployer.sol";
import "../interfaces/ISignatureVerifier.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IDeBridgeGate.sol";
import "../interfaces/ICallProxy.sol";
import "../interfaces/IFlashCallback.sol";
import "../libraries/SignatureUtil.sol";
import "../libraries/Flags.sol";
import "../interfaces/IWethGate.sol";

contract DeBridgeGate is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IDeBridgeGate
{
    using SafeERC20 for IERC20;
    using SignatureUtil for bytes;
    using Flags for uint256;

    /* ========== STATE VARIABLES ========== */

    /// @dev Basis points or bps, set to 10 000 (equal to 1/10000). Used to express relative values (fees)
    uint256 public constant BPS_DENOMINATOR = 10000;
    /// @dev Role allowed to stop transfers
    bytes32 public constant GOVMONITORING_ROLE = keccak256("GOVMONITORING_ROLE");

    /// @dev Address of IDeBridgeTokenDeployer contract
    address public deBridgeTokenDeployer;
    /// @dev Current signature verifier address to verify signatures.
    address public signatureVerifier;
    /// @dev Minimal required confirmations in case sent amount is big, have no effect if less than SignatureVerifier.minConfirmations
    uint8 public excessConfirmations;
    /// @dev Flash loan fee in basis points (1/10000)
    uint256 public flashFeeBps;
    /// @dev Outgoing submissions count
    uint256 public nonce;

    /// @dev Maps debridgeId (see getDebridgeId) => bridge-specific information.
    mapping(bytes32 => DebridgeInfo) public getDebridge;
    /// @dev Maps debridgeId (see getDebridgeId) => fee information
    mapping(bytes32 => DebridgeFeeInfo) public getDebridgeFeeInfo;
    /// @dev Returns whether the transfer with the submissionId was claimed.
    /// submissionId is generated in getSubmissionIdFrom
    mapping(bytes32 => bool) public override isSubmissionUsed;
    /// @dev Returns whether the transfer with the submissionId is blocked.
    mapping(bytes32 => bool) public isBlockedSubmission;
    /// @dev Maps debridgeId (see getDebridgeId) to threshold amount after which
    /// Math.max(excessConfirmations,SignatureVerifier.minConfirmations) is used instead of
    /// SignatureVerifier.minConfirmations
    mapping(bytes32 => uint256) public getAmountThreshold;
    /// @dev Whether the chain for the asset is supported to send
    mapping(uint256 => ChainSupportInfo) public getChainToConfig;
    /// @dev Whether the chain for the asset is supported to claim
    mapping(uint256 => ChainSupportInfo) public getChainFromConfig;
    /// @dev Fee discount for address
    mapping(address => DiscountInfo) public feeDiscount;
    /// @dev Returns native token info by wrapped token address
    mapping(address => TokenInfo) public getNativeInfo;

    /// @dev Return DefiController that can supply liquidity to staking strategies (AAVE, Compound, etc.)
    address public defiController;
    /// @dev Returns proxy to convert the collected fees and transfer to Ethereum network to treasury
    address public feeProxy;
    /// @dev Returns address of the proxy to execute user's calls.
    address public callProxy;
    /// @dev Returns contract for wrapped native token.
    IWETH public weth;

    /// @dev Contract address that can override globalFixedNativeFee
    address public feeContractUpdater;

    /// @dev Fallback fixed fee in native asset, used if a chain fixed fee is set to 0
    uint256 public globalFixedNativeFee;
    /// @dev Fallback transfer fee in BPS, used if a chain transfer fee is set to 0
    uint16 public globalTransferFeeBps;

    /// @dev WethGate contract, that is used for weth withdraws affected by EIP1884
    IWethGate public wethGate;
    /// @dev Locker for claim method
    bool public lockedClaim;

    /* ========== ERRORS ========== */

    error FeeProxyBadRole();
    error DefiControllerBadRole();
    error FeeContractUpdaterBadRole();
    error AdminBadRole();
    error GovMonitoringBadRole();
    error DebridgeNotFound();

    error WrongChainTo();
    error WrongChainFrom();
    error WrongArgument();
    error WrongAutoArgument();

    error TransferAmountTooHigh();

    error NotSupportedFixedFee();
    error TransferAmountNotCoverFees();
    error InvalidTokenToSend();

    error SubmissionUsed();
    error SubmissionNotConfirmed();
    error SubmissionAmountNotConfirmed();
    error SubmissionBlocked();

    error AmountMismatch();

    error AssetAlreadyExist();
    error AssetNotConfirmed();
    error ZeroAddress();

    error ProposedFeeTooHigh();
    error FeeNotPaid();

    error NotEnoughReserves();
    error EthTransferFailed();
    error Locked();

    /* ========== MODIFIERS ========== */

    modifier onlyFeeProxy() {
        if (feeProxy != msg.sender) revert FeeProxyBadRole();
        _;
    }

    modifier onlyDefiController() {
        if (defiController != msg.sender) revert DefiControllerBadRole();
        _;
    }

    modifier onlyFeeContractUpdater() {
        if (feeContractUpdater != msg.sender) revert FeeContractUpdaterBadRole();
        _;
    }

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert AdminBadRole();
        _;
    }

    modifier onlyGovMonitoring() {
        if (!hasRole(GOVMONITORING_ROLE, msg.sender)) revert GovMonitoringBadRole();
        _;
    }

    /// @dev lock for claim method
    modifier lockClaim() {
        if (lockedClaim) revert Locked();
        lockedClaim = true;
        _;
        lockedClaim = false;
    }

    /* ========== CONSTRUCTOR  ========== */

    /// @dev Constructor that initializes the most important configurations.
    /// @param _excessConfirmations minimal required confirmations in case of too many confirmations
    /// @param _weth wrapped native token contract
    function initialize(
        uint8 _excessConfirmations,
        IWETH _weth
    ) public initializer {
        excessConfirmations = _excessConfirmations;
        weth = _weth;

        _addAsset(
            getDebridgeId(getChainId(), address(_weth)),
            address(_weth),
            abi.encodePacked(address(_weth)),
            getChainId()
        );

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __ReentrancyGuard_init();
    }

    /* ========== send, claim ========== */

    /// @inheritdoc IDeBridgeGate
    function send(
        address _tokenAddress,
        uint256 _amount,
        uint256 _chainIdTo,
        bytes memory _receiver,
        bytes memory _permit,
        bool _useAssetFee,
        uint32 _referralCode,
        bytes calldata _autoParams
    ) external payable override nonReentrant whenNotPaused {
        bytes32 debridgeId;
        FeeParams memory feeParams;
        uint256 amountAfterFee;
        // the amount will be reduced by the protocol fee
        (amountAfterFee, debridgeId, feeParams) = _send(
            _permit,
            _tokenAddress,
            _amount,
            _chainIdTo,
            _useAssetFee
        );

        SubmissionAutoParamsTo memory autoParams = _validateAutoParams(_autoParams, amountAfterFee);
        amountAfterFee -= autoParams.executionFee;

        // round down amount in order not to bridge dust
        amountAfterFee = _normalizeTokenAmount(_tokenAddress, amountAfterFee);

        bytes32 submissionId = getSubmissionIdTo(
            debridgeId,
            _chainIdTo,
            amountAfterFee,
            _receiver,
            autoParams,
            _autoParams.length > 0
        );

        emit Sent(
            submissionId,
            debridgeId,
            amountAfterFee,
            _receiver,
            nonce,
            _chainIdTo,
            _referralCode,
            feeParams,
            _autoParams,
            msg.sender
        );
        nonce++;
    }

    /// @inheritdoc IDeBridgeGate
    function claim(
        bytes32 _debridgeId,
        uint256 _amount,
        uint256 _chainIdFrom,
        address _receiver,
        uint256 _nonce,
        bytes calldata _signatures,
        bytes calldata _autoParams
    ) external override lockClaim whenNotPaused {
        if (!getChainFromConfig[_chainIdFrom].isSupported) revert WrongChainFrom();

        SubmissionAutoParamsFrom memory autoParams;
        if (_autoParams.length > 0) {
            autoParams = abi.decode(_autoParams, (SubmissionAutoParamsFrom));
        }

        bytes32 submissionId = getSubmissionIdFrom(
            _debridgeId,
            _chainIdFrom,
            _amount,
            _receiver,
            _nonce,
            autoParams,
            _autoParams.length > 0
        );

        // check if submission already claimed
        if (isSubmissionUsed[submissionId]) revert SubmissionUsed();
        isSubmissionUsed[submissionId] = true;

        _checkConfirmations(submissionId, _debridgeId, _amount, _signatures);

        bool isNativeToken =_claim(
            submissionId,
            _debridgeId,
            _receiver,
            _amount,
            _chainIdFrom,
            autoParams
        );

        emit Claimed(
            submissionId,
            _debridgeId,
            _amount,
            _receiver,
            _nonce,
            _chainIdFrom,
            _autoParams,
            isNativeToken
        );
    }

    /// @inheritdoc IDeBridgeGate
    function flash(
        address _tokenAddress,
        address _receiver,
        uint256 _amount,
        bytes memory _data
    ) external override nonReentrant whenNotPaused
    {
        bytes32 debridgeId = getDebridgeId(getChainId(), _tokenAddress);
        if (!getDebridge[debridgeId].exist) revert DebridgeNotFound();
        uint256 currentFlashFee = (_amount * flashFeeBps) / BPS_DENOMINATOR;
        uint256 balanceBefore = IERC20(_tokenAddress).balanceOf(address(this));

        IERC20(_tokenAddress).safeTransfer(_receiver, _amount);
        IFlashCallback(msg.sender).flashCallback(currentFlashFee, _data);

        uint256 balanceAfter = IERC20(_tokenAddress).balanceOf(address(this));
        if (balanceBefore + currentFlashFee > balanceAfter) revert FeeNotPaid();

        uint256 paid = balanceAfter - balanceBefore;
        getDebridgeFeeInfo[debridgeId].collectedFees += paid;
        emit Flash(msg.sender, _tokenAddress, _receiver, _amount, paid);
    }

    /// @dev Deploy a deToken(DeBridgeTokenProxy) for an asset
    /// @param _nativeTokenAddress A token address on a native chain
    /// @param _nativeChainId The token native chain's id
    /// @param _name The token's name
    /// @param _symbol The token's symbol
    /// @param _decimals The token's decimals
    /// @param _signatures Validators' signatures
    function deployNewAsset(
        bytes memory _nativeTokenAddress,
        uint256 _nativeChainId,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        bytes memory _signatures
    ) external nonReentrant whenNotPaused{
        bytes32 debridgeId = getbDebridgeId(_nativeChainId, _nativeTokenAddress);

        if (getDebridge[debridgeId].exist) revert AssetAlreadyExist();

        bytes32 deployId =  keccak256(abi.encodePacked(debridgeId, _name, _symbol, _decimals));

        // verify signatures
        ISignatureVerifier(signatureVerifier).submit(deployId, _signatures, excessConfirmations);

        address deBridgeTokenAddress = IDeBridgeTokenDeployer(deBridgeTokenDeployer)
        .deployAsset(debridgeId, _name, _symbol, _decimals);

        _addAsset(debridgeId, deBridgeTokenAddress, _nativeTokenAddress, _nativeChainId);
    }

    /// @dev Update native fix fee. Called by our fee update contract
    /// @param _globalFixedNativeFee  new value
    function autoUpdateFixedNativeFee(
        uint256 _globalFixedNativeFee
    ) external onlyFeeContractUpdater {
        globalFixedNativeFee = _globalFixedNativeFee;
        emit FixedNativeFeeAutoUpdated(_globalFixedNativeFee);
    }

    /* ========== ADMIN ========== */

    /// @dev Update asset's fees.
    /// @param _chainIds Chain identifiers.
    /// @param _chainSupportInfo Chain support info.
    /// @param _isChainFrom is true for editing getChainFromConfig.
    function updateChainSupport(
        uint256[] memory _chainIds,
        ChainSupportInfo[] memory _chainSupportInfo,
        bool _isChainFrom
    ) external onlyAdmin {
        if (_chainIds.length != _chainSupportInfo.length) revert WrongArgument();
        for (uint256 i = 0; i < _chainIds.length; i++) {
            if(_isChainFrom){
                getChainFromConfig[_chainIds[i]] = _chainSupportInfo[i];
            }
            else {
                getChainToConfig[_chainIds[i]] = _chainSupportInfo[i];
            }
            emit ChainsSupportUpdated(_chainIds[i], _chainSupportInfo[i], _isChainFrom);
        }
    }

    /// @dev Update fallbacks for fixed fee in native asset and transfer fee
    /// @param _globalFixedNativeFee Fallback fixed fee in native asset, used if a chain fixed fee is set to 0
    /// @param _globalTransferFeeBps Fallback transfer fee in BPS, used if a chain transfer fee is set to 0
    function updateGlobalFee(
        uint256 _globalFixedNativeFee,
        uint16 _globalTransferFeeBps
    ) external onlyAdmin {
        globalFixedNativeFee = _globalFixedNativeFee;
        globalTransferFeeBps = _globalTransferFeeBps;
        emit FixedNativeFeeUpdated(_globalFixedNativeFee, _globalTransferFeeBps);
    }

    /// @dev Update asset's fees.
    /// @param _debridgeId Asset identifier.
    /// @param _supportedChainIds Chain identifiers.
    /// @param _assetFeesInfo Chain support info.
    function updateAssetFixedFees(
        bytes32 _debridgeId,
        uint256[] memory _supportedChainIds,
        uint256[] memory _assetFeesInfo
    ) external onlyAdmin {
        if (_supportedChainIds.length != _assetFeesInfo.length) revert WrongArgument();
        DebridgeFeeInfo storage debridgeFee = getDebridgeFeeInfo[_debridgeId];
        for (uint256 i = 0; i < _supportedChainIds.length; i++) {
            debridgeFee.getChainFee[_supportedChainIds[i]] = _assetFeesInfo[i];
        }
    }

    /// @dev Update minimal amount of required signatures, must be > SignatureVerifier.minConfirmations to have an effect
    /// @param _excessConfirmations Minimal amount of required signatures
    function updateExcessConfirmations(uint8 _excessConfirmations) external onlyAdmin {
        if (_excessConfirmations == 0) revert WrongArgument();
        excessConfirmations = _excessConfirmations;
    }

    /// @dev Set support for the chains where the token can be transferred.
    /// @param _chainId Chain id where tokens are sent.
    /// @param _isSupported Whether the token is transferable to the other chain.
    /// @param _isChainFrom is true for editing getChainFromConfig.
    function setChainSupport(uint256 _chainId, bool _isSupported, bool _isChainFrom) external onlyAdmin {
        if (_isChainFrom) {
            getChainFromConfig[_chainId].isSupported = _isSupported;
        }
        else {
            getChainToConfig[_chainId].isSupported = _isSupported;
        }
        emit ChainSupportUpdated(_chainId, _isSupported, _isChainFrom);
    }

    /// @dev Set address of the call proxy.
    /// @param _callProxy Address of the proxy that executes external calls.
    function setCallProxy(address _callProxy) external onlyAdmin {
        callProxy = _callProxy;
        emit CallProxyUpdated(_callProxy);
    }

    /// @dev Update specific asset's bridge parameters.
    /// @param _debridgeId Asset identifier.
    /// @param _maxAmount Maximum amount of current chain token to be wrapped.
    /// @param _minReservesBps Minimal reserve ration in BPS.
    /// @param _amountThreshold Threshold amount after which Math.max(excessConfirmations,SignatureVerifier.minConfirmations) is used instead of SignatureVerifier.minConfirmations
    function updateAsset(
        bytes32 _debridgeId,
        uint256 _maxAmount,
        uint16 _minReservesBps,
        uint256 _amountThreshold
    ) external onlyAdmin {
        if (_minReservesBps > BPS_DENOMINATOR) revert WrongArgument();
        DebridgeInfo storage debridge = getDebridge[_debridgeId];
        // don't check existence of debridge - it allows to setup asset before first transfer
        debridge.maxAmount = _maxAmount;
        debridge.minReservesBps = _minReservesBps;
        getAmountThreshold[_debridgeId] = _amountThreshold;
    }


    /// @dev Set signature verifier address.
    /// @param _verifier Signature verifier address.
    function setSignatureVerifier(address _verifier) external onlyAdmin {
        signatureVerifier = _verifier;
    }

    /// @dev Set asset deployer address.
    /// @param _deBridgeTokenDeployer Asset deployer address.
    function setDeBridgeTokenDeployer(address _deBridgeTokenDeployer) external onlyAdmin {
        deBridgeTokenDeployer = _deBridgeTokenDeployer;
    }

    /// @dev Set defi controller.
    /// @param _defiController Defi controller address.
    function setDefiController(address _defiController) external onlyAdmin {
        defiController = _defiController;
    }

    /// @dev Set fee contract updater, that can update fix native fee
    /// @param _value new contract address.
    function setFeeContractUpdater(address _value) external onlyAdmin {
        feeContractUpdater = _value;
    }

    /// @dev Set wethGate contract, that uses for weth withdraws affected by EIP1884
    /// @param _wethGate address of new wethGate contract.
    function setWethGate(IWethGate _wethGate) external onlyAdmin {
        wethGate = _wethGate;
    }

    /// @dev Stop all transfers.
    function pause() external onlyGovMonitoring {
        _pause();
    }

    /// @dev Allow transfers.
    function unpause() external onlyAdmin whenPaused {
        _unpause();
    }

    /// @inheritdoc IDeBridgeGate
    function withdrawFee(bytes32 _debridgeId) external override nonReentrant onlyFeeProxy {
        DebridgeFeeInfo storage debridgeFee = getDebridgeFeeInfo[_debridgeId];
        // Amount for transfer to treasury
        uint256 amount = debridgeFee.collectedFees - debridgeFee.withdrawnFees;

        if (amount == 0) revert NotEnoughReserves();

        debridgeFee.withdrawnFees += amount;

        if (_debridgeId == getDebridgeId(getChainId(), address(0))) {
            _safeTransferETH(feeProxy, amount);
        } else {
            // don't need this check as we check that amount is not zero
            // if (!getDebridge[_debridgeId].exist) revert DebridgeNotFound();
            IERC20(getDebridge[_debridgeId].tokenAddress).safeTransfer(feeProxy, amount);
        }
        emit WithdrawnFee(_debridgeId, amount);
    }

    /// @inheritdoc IDeBridgeGate
    function requestReserves(address _tokenAddress, uint256 _amount)
        external
        override
        onlyDefiController
        nonReentrant
    {
        bytes32 debridgeId = getDebridgeId(getChainId(), _tokenAddress);
        DebridgeInfo storage debridge = getDebridge[debridgeId];
        if (!debridge.exist) revert DebridgeNotFound();
        uint256 minReserves = (debridge.balance * debridge.minReservesBps) / BPS_DENOMINATOR;

        if (minReserves + _amount > IERC20(_tokenAddress).balanceOf(address(this)))
            revert NotEnoughReserves();

        debridge.lockedInStrategies += _amount;
        IERC20(_tokenAddress).safeTransfer(defiController, _amount);
    }

    /// @inheritdoc IDeBridgeGate
    function returnReserves(address _tokenAddress, uint256 _amount)
        external
        override
        onlyDefiController
        nonReentrant
    {
        bytes32 debridgeId = getDebridgeId(getChainId(), _tokenAddress);
        DebridgeInfo storage debridge = getDebridge[debridgeId];
        if (!debridge.exist) revert DebridgeNotFound();
        debridge.lockedInStrategies -= _amount;
        IERC20(debridge.tokenAddress).safeTransferFrom(
            defiController,
            address(this),
            _amount
        );
    }

    /// @dev Set fee converter proxy.
    /// @param _feeProxy Fee proxy address.
    function setFeeProxy(address _feeProxy) external onlyAdmin {
        feeProxy = _feeProxy;
    }

    /// @dev Block or unblock a list of submissions
    /// @param _submissionIds Ids of submissions to block/unblock
    /// @param isBlocked True to block, false to unblock
    function blockSubmission(bytes32[] memory _submissionIds, bool isBlocked) external onlyAdmin {
        for (uint256 i = 0; i < _submissionIds.length; i++) {
            isBlockedSubmission[_submissionIds[i]] = isBlocked;
            if (isBlocked) {
                emit Blocked(_submissionIds[i]);
            } else {
                emit Unblocked(_submissionIds[i]);
            }
        }
    }

    /// @dev Update flash fees.
    /// @param _flashFeeBps new fee in BPS
    function updateFlashFee(uint256 _flashFeeBps) external onlyAdmin {
        if (_flashFeeBps > BPS_DENOMINATOR) revert WrongArgument();
        flashFeeBps = _flashFeeBps;
    }

    /// @dev Update discount.
    /// @param _address customer address
    /// @param _discountFixBps  fix discount in BPS
    /// @param _discountTransferBps transfer % discount in BPS
    function updateFeeDiscount(
        address _address,
        uint16 _discountFixBps,
        uint16 _discountTransferBps
    ) external onlyAdmin {
        if (_address == address(0) ||
        _discountFixBps > BPS_DENOMINATOR ||
            _discountTransferBps > BPS_DENOMINATOR
        ) revert WrongArgument();
        DiscountInfo storage discountInfo = feeDiscount[_address];
        discountInfo.discountFixBps = _discountFixBps;
        discountInfo.discountTransferBps = _discountTransferBps;
    }

    // we need to accept ETH sends to unwrap WETH
    receive() external payable {
        // assert(msg.sender == address(weth)); // only accept ETH via fallback from the WETH contract
    }

    /* ========== INTERNAL ========== */

    function _checkConfirmations(
        bytes32 _submissionId,
        bytes32 _debridgeId,
        uint256 _amount,
        bytes calldata _signatures
    ) internal {
        if (isBlockedSubmission[_submissionId]) revert SubmissionBlocked();
        // inside check is confirmed
        ISignatureVerifier(signatureVerifier).submit(
            _submissionId,
            _signatures,
            _amount >= getAmountThreshold[_debridgeId] ? excessConfirmations : 0
        );
    }

    /// @dev Add support for the asset.
    /// @param _debridgeId Asset identifier.
    /// @param _tokenAddress Address of the asset on the current chain.
    /// @param _nativeAddress Address of the asset on the native chain.
    /// @param _nativeChainId Native chain id.
    function _addAsset(
        bytes32 _debridgeId,
        address _tokenAddress,
        bytes memory _nativeAddress,
        uint256 _nativeChainId
    ) internal {
        DebridgeInfo storage debridge = getDebridge[_debridgeId];

        if (debridge.exist) revert AssetAlreadyExist();
        if (_tokenAddress == address(0)) revert ZeroAddress();

        debridge.exist = true;
        debridge.tokenAddress = _tokenAddress;
        debridge.chainId = _nativeChainId;
        // Don't override if the admin already set maxAmount in updateAsset method before
        if (debridge.maxAmount == 0) {
            debridge.maxAmount = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        // debridge.minReservesBps = BPS;
        if (getAmountThreshold[_debridgeId] == 0) {
            getAmountThreshold[
            _debridgeId
            ] = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }

        TokenInfo storage tokenInfo = getNativeInfo[_tokenAddress];
        tokenInfo.nativeChainId = _nativeChainId;
        tokenInfo.nativeAddress = _nativeAddress;

        emit PairAdded(
            _debridgeId,
            _tokenAddress,
            _nativeAddress,
            _nativeChainId,
            debridge.maxAmount,
            debridge.minReservesBps
        );
    }

    /// @dev Locks asset on the chain and enables minting on the other chain.
    /// @param _amount Amount to be transferred (note: the fee can be applied).
    /// @param _chainIdTo Chain id of the target chain.
    /// @param _permit deadline + signature for approving the spender by signature.
    function _send(
        bytes memory _permit,
        address _tokenAddress,
        uint256 _amount,
        uint256 _chainIdTo,
        bool _useAssetFee
    ) internal returns (
    // bool isNativeToken,
        uint256 amountAfterFee,
        bytes32 debridgeId,
        FeeParams memory feeParams
    ) {
        _validateToken(_tokenAddress);

        // Run _permit first. Avoid Stack too deep
        if (_permit.length > 0) {
            // call permit before transferring token
            uint256 deadline = _permit.toUint256(0);
            (bytes32 r, bytes32 s, uint8 v) = _permit.parseSignature(32);
            IERC20Permit(_tokenAddress).permit(
                msg.sender,
                address(this),
                _amount,
                deadline,
                v,
                r,
                s);
        }

        TokenInfo memory nativeTokenInfo = getNativeInfo[_tokenAddress];
        bool isNativeToken = nativeTokenInfo.nativeChainId  == 0
        ? true // token not in mapping
        : nativeTokenInfo.nativeChainId == getChainId(); // token native chain id the same

        if (isNativeToken) {
            //We use WETH debridgeId for transfer ETH
            debridgeId = getDebridgeId(
                getChainId(),
                _tokenAddress == address(0) ? address(weth) : _tokenAddress
            );
        }
        else {
            debridgeId = getbDebridgeId(
                nativeTokenInfo.nativeChainId,
                nativeTokenInfo.nativeAddress
            );
        }

        DebridgeInfo storage debridge = getDebridge[debridgeId];
        if (!debridge.exist) {
            if (isNativeToken) {
                _addAsset(
                    debridgeId,
                    _tokenAddress == address(0) ? address(weth) : _tokenAddress,
                    abi.encodePacked(_tokenAddress),
                    getChainId()
                );
            } else revert DebridgeNotFound();
        }

        ChainSupportInfo memory chainFees = getChainToConfig[_chainIdTo];
        if (!chainFees.isSupported) revert WrongChainTo();
        if (_amount > debridge.maxAmount) revert TransferAmountTooHigh();

        if (_tokenAddress == address(0)) {
            if (msg.value < _amount) revert AmountMismatch();
            else if (msg.value > _amount) {
                // refund extra eth
                payable(msg.sender).transfer(msg.value - _amount);
            }
            weth.deposit{value: _amount}();
            _useAssetFee = true;
        } else {
            IERC20 token = IERC20(_tokenAddress);
            uint256 balanceBefore = token.balanceOf(address(this));
            token.safeTransferFrom(msg.sender, address(this), _amount);
            // Received real amount
            _amount = token.balanceOf(address(this)) - balanceBefore;
        }

        //_processFeeForTransfer
        {
            DiscountInfo memory discountInfo = feeDiscount[msg.sender];
            DebridgeFeeInfo storage debridgeFee = getDebridgeFeeInfo[debridgeId];

            // calculate fixed fee
            uint256 assetsFixedFee;
            if (_useAssetFee) {
                assetsFixedFee = debridgeFee.getChainFee[_chainIdTo];
                if (assetsFixedFee == 0) revert NotSupportedFixedFee();
                // Apply discount for a asset fixed fee
                assetsFixedFee -= assetsFixedFee * discountInfo.discountFixBps / BPS_DENOMINATOR;
                feeParams.fixFee = assetsFixedFee;
            } else {
                // collect native fees

                // use globalFixedNativeFee if value for chain is not set
                uint256 nativeFee = chainFees.fixedNativeFee == 0 ? globalFixedNativeFee : chainFees.fixedNativeFee;
                // Apply discount for a fixed fee
                nativeFee -= nativeFee * discountInfo.discountFixBps / BPS_DENOMINATOR;

                if (msg.value < nativeFee) revert TransferAmountNotCoverFees();
                else if (msg.value > nativeFee) {
                    // refund extra fee eth
                    payable(msg.sender).transfer(msg.value - nativeFee);
                }
                bytes32 nativeDebridgeId = getDebridgeId(getChainId(), address(0));
                getDebridgeFeeInfo[nativeDebridgeId].collectedFees += nativeFee;
                feeParams.fixFee = nativeFee;
            }

            // Calculate transfer fee
            if (chainFees.transferFeeBps == 0) {
                // use globalTransferFeeBps if value for chain is not set
                chainFees.transferFeeBps = globalTransferFeeBps;
            }
            uint256 transferFee = (_amount * chainFees.transferFeeBps) / BPS_DENOMINATOR;
            // apply discount for a transfer fee
            transferFee -= transferFee * discountInfo.discountTransferBps / BPS_DENOMINATOR;

            uint256 totalFee = transferFee + assetsFixedFee;
            if (_amount < totalFee) revert TransferAmountNotCoverFees();
            debridgeFee.collectedFees += totalFee;
            amountAfterFee = _amount - totalFee;

            // initialize feeParams
            // feeParams.fixFee = _useAssetFee ? assetsFixedFee : msg.value;
            feeParams.transferFee = transferFee;
            feeParams.useAssetFee = _useAssetFee;
            feeParams.receivedAmount = _amount;
            feeParams.isNativeToken = isNativeToken;
        }

        // Is native token
        if (isNativeToken) {
            debridge.balance += amountAfterFee;
        }
        else {
            debridge.balance -= amountAfterFee;
            IDeBridgeToken(debridge.tokenAddress).burn(amountAfterFee);
        }
        return (amountAfterFee, debridgeId, feeParams);
    }

    function _validateToken(address _token) internal {
        if (_token == address(0)) {
            // no validation for native tokens
            return;
        }

        // check existence of decimals method
        (bool success, ) = _token.call(abi.encodeWithSignature("decimals()"));
        if (!success) revert InvalidTokenToSend();

        // check existence of symbol method
        (success, ) = _token.call(abi.encodeWithSignature("symbol()"));
        if (!success) revert InvalidTokenToSend();
    }

    function _validateAutoParams(
        bytes calldata _autoParams,
        uint256 _amount
    ) internal pure returns (SubmissionAutoParamsTo memory autoParams) {
        if (_autoParams.length > 0) {
            autoParams = abi.decode(_autoParams, (SubmissionAutoParamsTo));
            if (autoParams.executionFee > _amount) revert ProposedFeeTooHigh();
            if (autoParams.data.length > 0 && autoParams.fallbackAddress.length == 0 ) revert WrongAutoArgument();
        }
    }

    /// @dev Unlock the asset on the current chain and transfer to receiver.
    /// @param _debridgeId Asset identifier.
    /// @param _receiver Receiver address.
    /// @param _amount Amount of the transfered asset (note: the fee can be applyed).
    function _claim(
        bytes32 _submissionId,
        bytes32 _debridgeId,
        address _receiver,
        uint256 _amount,
        uint256 _chainIdFrom,
        SubmissionAutoParamsFrom memory _autoParams
    ) internal returns (bool isNativeToken) {
        DebridgeInfo storage debridge = getDebridge[_debridgeId];
        if (!debridge.exist) revert DebridgeNotFound();
        // if (debridge.chainId != getChainId()) revert WrongChain();
        isNativeToken = debridge.chainId == getChainId();

        if (isNativeToken) {
            debridge.balance -= _amount + _autoParams.executionFee;
        } else {
            debridge.balance += _amount + _autoParams.executionFee;
        }

        address _token = debridge.tokenAddress;
        bool unwrapETH = isNativeToken
        && _autoParams.flags.getFlag(Flags.UNWRAP_ETH)
        && _token == address(weth);

        if (_autoParams.executionFee > 0) {
            _mintOrTransfer(_token, msg.sender, _autoParams.executionFee, isNativeToken);
        }
        if (_autoParams.data.length > 0) {
            // use local variable to reduce gas usage
            address _callProxy = callProxy;
            bool status;
            if (unwrapETH) {
                // withdraw weth to callProxy directly
                _withdrawWeth(_callProxy, _amount);
                status = ICallProxy(_callProxy).call(
                    _autoParams.fallbackAddress,
                    _receiver,
                    _autoParams.data,
                    _autoParams.flags,
                    _autoParams.nativeSender,
                    _chainIdFrom
                );
            }
            else {
                _mintOrTransfer(_token, _callProxy, _amount, isNativeToken);

                status = ICallProxy(_callProxy).callERC20(
                    _token,
                    _autoParams.fallbackAddress,
                    _receiver,
                    _autoParams.data,
                    _autoParams.flags,
                    _autoParams.nativeSender,
                    _chainIdFrom
                );
            }
            emit AutoRequestExecuted(_submissionId, status, _callProxy);
        } else if (unwrapETH) {
            // transferring WETH with unwrap flag
            _withdrawWeth(_receiver, _amount);
        } else {
            _mintOrTransfer(_token, _receiver, _amount, isNativeToken);
        }
    }

    function _mintOrTransfer(
        address _token,
        address _receiver,
        uint256 _amount,
        bool isNativeToken
    ) internal {
        if (isNativeToken) {
            IERC20(_token).safeTransfer(_receiver, _amount);
        } else {
            IDeBridgeToken(_token).mint(_receiver, _amount);
        }
    }

    /*
    * @dev transfer ETH to an address, revert if it fails.
    * @param to recipient of the transfer
    * @param value the amount to send
    */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        if (!success) revert EthTransferFailed();
    }


    function _withdrawWeth(address _receiver, uint _amount) internal {
        if (address(wethGate) == address(0)) {
            // dealing with weth withdraw affected by EIP1884
            weth.withdraw(_amount);
            _safeTransferETH(_receiver, _amount);
        }
        else {
            IERC20(address(weth)).safeTransfer(address(wethGate), _amount);
            wethGate.withdraw(_receiver, _amount);
        }
    }

    /*
    * @dev round down token amount
    * @param _token address of token, zero for native tokens
    * @param __amount amount for rounding
    */
    function _normalizeTokenAmount(
        address _token,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 decimals = _token == address(0)
        ? 18
        : IERC20Metadata(_token).decimals();
        uint256 maxDecimals = 8;
        if (decimals > maxDecimals) {
            uint256 multiplier = 10 ** (decimals - maxDecimals);
            _amount = _amount / multiplier * multiplier;
        }
        return _amount;
    }

    /* VIEW */

    /// @inheritdoc IDeBridgeGate
    function getDefiAvaliableReserves(address _tokenAddress)
    external
    view
    override
    returns (uint256)
    {
        DebridgeInfo storage debridge = getDebridge[getDebridgeId(getChainId(), _tokenAddress)];
        return (debridge.balance * (BPS_DENOMINATOR - debridge.minReservesBps)) / BPS_DENOMINATOR;
    }

    /// @dev Calculates asset identifier.
    /// @param _chainId Current chain id.
    /// @param _tokenAddress Address of the asset on the other chain.
    function getDebridgeId(uint256 _chainId, address _tokenAddress) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_chainId, _tokenAddress));
    }

    /// @dev Calculates asset identifier.
    /// @param _chainId Current chain id.
    /// @param _tokenAddress Address of the asset on the other chain.
    function getbDebridgeId(uint256 _chainId, bytes memory _tokenAddress) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_chainId, _tokenAddress));
    }

    /// @inheritdoc IDeBridgeGate
    function getDebridgeChainAssetFixedFee(
        bytes32 _debridgeId,
        uint256 _chainId
    ) external view override returns (uint256) {
        // if (!getDebridge[_debridgeId].exist) revert DebridgeNotFound();
        return getDebridgeFeeInfo[_debridgeId].getChainFee[_chainId];
    }

    /// @dev Calculate submission id for auto claimable transfer.
    /// @param _debridgeId Asset identifier.
    /// @param _chainIdFrom Chain identifier of the chain where tokens are sent from.
    /// @param _amount Amount of the transferred asset (note: the fee can be applied).
    /// @param _receiver Receiver address.
    /// @param _nonce Submission id.
    /// @param autoParams Auto params for external call
    /// @param hasAutoParams True if auto params are provided
    function getSubmissionIdFrom(
        bytes32 _debridgeId,
        uint256 _chainIdFrom,
        uint256 _amount,
        address _receiver,
        uint256 _nonce,
        SubmissionAutoParamsFrom memory autoParams,
        bool hasAutoParams
    ) public view returns (bytes32) {
        bytes memory packedSubmission = abi.encodePacked(
            _debridgeId,
            _chainIdFrom,
            getChainId(),
            _amount,
            _receiver,
            _nonce
        );
        if (hasAutoParams) {
            // auto submission
            return keccak256(
                abi.encodePacked(
                    packedSubmission,
                    autoParams.executionFee,
                    autoParams.flags,
                    autoParams.fallbackAddress,
                    autoParams.data,
                    autoParams.nativeSender
                )
            );
        }
        // regular submission
        return keccak256(packedSubmission);
    }

    function getSubmissionIdTo(
        bytes32 _debridgeId,
        uint256 _chainIdTo,
        uint256 _amount,
        bytes memory _receiver,
        SubmissionAutoParamsTo memory autoParams,
        bool hasAutoParams
    ) private view returns (bytes32) {
        bytes memory packedSubmission = abi.encodePacked(
            _debridgeId,
            getChainId(),
            _chainIdTo,
            _amount,
            _receiver,
            nonce
        );
        if (hasAutoParams) {
            // auto submission
            return keccak256(
                abi.encodePacked(
                    packedSubmission,
                    autoParams.executionFee,
                    autoParams.flags,
                    autoParams.fallbackAddress,
                    autoParams.data,
                    msg.sender
                )
            );
        }
        // regular submission
        return keccak256(packedSubmission);
    }

    /// @inheritdoc IDeBridgeGate
    function getNativeTokenInfo(address currentTokenAddress)
    external
    view
    override
    returns (uint256 nativeChainId, bytes memory nativeAddress)
    {
        TokenInfo memory tokenInfo = getNativeInfo[currentTokenAddress];
        return (tokenInfo.nativeChainId, tokenInfo.nativeAddress);
    }

    /// @dev Get current chain id
    function getChainId() public view virtual returns (uint256 cid) {
        assembly {
            cid := chainid()
        }
    }

    // ============ Version Control ============
    /// @dev Get this contract's version
    function version() external pure returns (uint256) {
        return 120; // 1.2.0
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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

pragma solidity 0.8.7;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../interfaces/IERC20Permit.sol";

interface IDeBridgeToken is IERC20Upgradeable, IERC20Permit {
    function mint(address _receiver, uint256 _amount) external;

    function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IDeBridgeTokenDeployer {

    /// @dev Deploy a deToken(DeBridgeTokenProxy) for an asset
    /// @param _debridgeId Asset id, see DeBridgeGate.getDebridgeId
    /// @param _name The asset's name
    /// @param _symbol The asset's symbol
    /// @param _decimals The asset's decimals
    function deployAsset(
        bytes32 _debridgeId,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external returns (address deTokenAddress);

    /// @dev Emitted when a deToken(DeBridgeTokenProxy) is deployed using this contract
    event DeBridgeTokenDeployed(
        address asset,
        string name,
        string symbol,
        uint8 decimals
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ISignatureVerifier {

    /* ========== EVENTS ========== */

    /// @dev Emitted once the submission is confirmed by one oracle.
    event Confirmed(bytes32 submissionId, address operator);
    /// @dev Emitted once the submission is confirmed by min required amount of oracles.
    event DeployConfirmed(bytes32 deployId, address operator);

    /* ========== FUNCTIONS ========== */

    /// @dev Check confirmation (validate signatures) for the transfer request.
    /// @param _submissionId Submission identifier.
    /// @param _signatures Array of signatures by oracles.
    /// @param _excessConfirmations override min confirmations count
    function submit(
        bytes32 _submissionId,
        bytes memory _signatures,
        uint8 _excessConfirmations
    ) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IDeBridgeGate {
    /* ========== STRUCTS ========== */

    struct TokenInfo {
        uint256 nativeChainId;
        bytes nativeAddress;
    }

    struct DebridgeInfo {
        uint256 chainId; // native chain id
        uint256 maxAmount; // maximum amount to transfer
        uint256 balance; // total locked assets
        uint256 lockedInStrategies; // total locked assets in strategy (AAVE, Compound, etc)
        address tokenAddress; // asset address on the current chain
        uint16 minReservesBps; // minimal hot reserves in basis points (1/10000)
        bool exist;
    }

    struct DebridgeFeeInfo {
        uint256 collectedFees; // total collected fees
        uint256 withdrawnFees; // fees that already withdrawn
        mapping(uint256 => uint256) getChainFee; // whether the chain for the asset is supported
    }

    struct ChainSupportInfo {
        uint256 fixedNativeFee; // transfer fixed fee
        bool isSupported; // whether the chain for the asset is supported
        uint16 transferFeeBps; // transfer fee rate nominated in basis points (1/10000) of transferred amount
    }

    struct DiscountInfo {
        uint16 discountFixBps; // fix discount in BPS
        uint16 discountTransferBps; // transfer % discount in BPS
    }

    /// @param executionFee Fee paid to the transaction executor.
    /// @param fallbackAddress Receiver of the tokens if the call fails.
    struct SubmissionAutoParamsTo {
        uint256 executionFee;
        uint256 flags;
        bytes fallbackAddress;
        bytes data;
    }

    /// @param executionFee Fee paid to the transaction executor.
    /// @param fallbackAddress Receiver of the tokens if the call fails.
    struct SubmissionAutoParamsFrom {
        uint256 executionFee;
        uint256 flags;
        address fallbackAddress;
        bytes data;
        bytes nativeSender;
    }

    struct FeeParams {
        uint256 receivedAmount;
        uint256 fixFee;
        uint256 transferFee;
        bool useAssetFee;
        bool isNativeToken;
    }

    /* ========== PUBLIC VARS GETTERS ========== */
    /// @dev Returns whether the transfer with the submissionId was claimed.
    /// submissionId is generated in getSubmissionIdFrom
    function isSubmissionUsed(bytes32 submissionId) external returns (bool);

    /* ========== FUNCTIONS ========== */

    /// @dev This method is used for the transfer of assets [from the native chain](https://docs.debridge.finance/the-core-protocol/transfers#transfer-from-native-chain).
    /// It locks an asset in the smart contract in the native chain and enables minting of deAsset on the secondary chain.
    /// @param _tokenAddress Asset identifier.
    /// @param _amount Amount to be transferred (note: the fee can be applied).
    /// @param _chainIdTo Chain id of the target chain.
    /// @param _receiver Receiver address.
    /// @param _permit deadline + signature for approving the spender by signature.
    /// @param _useAssetFee use assets fee for pay protocol fix (work only for specials token)
    /// @param _referralCode Referral code
    /// @param _autoParams Auto params for external call in target network
    function send(
        address _tokenAddress,
        uint256 _amount,
        uint256 _chainIdTo,
        bytes memory _receiver,
        bytes memory _permit,
        bool _useAssetFee,
        uint32 _referralCode,
        bytes calldata _autoParams
    ) external payable;

    /// @dev Is used for transfers [into the native chain](https://docs.debridge.finance/the-core-protocol/transfers#transfer-from-secondary-chain-to-native-chain)
    /// to unlock the designated amount of asset from collateral and transfer it to the receiver.
    /// @param _debridgeId Asset identifier.
    /// @param _amount Amount of the transferred asset (note: the fee can be applied).
    /// @param _chainIdFrom Chain where submission was sent
    /// @param _receiver Receiver address.
    /// @param _nonce Submission id.
    /// @param _signatures Validators signatures to confirm
    /// @param _autoParams Auto params for external call
    function claim(
        bytes32 _debridgeId,
        uint256 _amount,
        uint256 _chainIdFrom,
        address _receiver,
        uint256 _nonce,
        bytes calldata _signatures,
        bytes calldata _autoParams
    ) external;

    /// @dev Get a flash loan, msg.sender must implement IFlashCallback
    /// @param _tokenAddress An asset to loan
    /// @param _receiver Where funds should be sent
    /// @param _amount Amount to loan
    /// @param _data Data to pass to sender's flashCallback function
    function flash(
        address _tokenAddress,
        address _receiver,
        uint256 _amount,
        bytes memory _data
    ) external;

    /// @dev Get reserves of a token available to use in defi
    /// @param _tokenAddress Token address
    function getDefiAvaliableReserves(address _tokenAddress) external view returns (uint256);

    /// @dev Request the assets to be used in DeFi protocol.
    /// @param _tokenAddress Asset address.
    /// @param _amount Amount of tokens to request.
    function requestReserves(address _tokenAddress, uint256 _amount) external;

    /// @dev Return the assets that were used in DeFi  protocol.
    /// @param _tokenAddress Asset address.
    /// @param _amount Amount of tokens to claim.
    function returnReserves(address _tokenAddress, uint256 _amount) external;

    /// @dev Withdraw collected fees to feeProxy
    /// @param _debridgeId Asset identifier.
    function withdrawFee(bytes32 _debridgeId) external;

    /// @dev Get native chain id and native address of a token
    /// @param currentTokenAddress address of a token on the current chain
    function getNativeTokenInfo(address currentTokenAddress)
    external
    view
    returns (uint256 chainId, bytes memory nativeAddress);

    /// @dev Returns asset fixed fee value for specified debridge and chainId.
    /// @param _debridgeId Asset identifier.
    /// @param _chainId Chain id.
    function getDebridgeChainAssetFixedFee(
        bytes32 _debridgeId,
        uint256 _chainId
    ) external view returns (uint256);

    /* ========== EVENTS ========== */

    /// @dev Emitted once the tokens are sent from the original(native) chain to the other chain; the transfer tokens
    /// are expected to be claimed by the users.
    event Sent(
        bytes32 submissionId,
        bytes32 indexed debridgeId,
        uint256 amount,
        bytes receiver,
        uint256 nonce,
        uint256 indexed chainIdTo,
        uint32 referralCode,
        FeeParams feeParams,
        bytes autoParams,
        address nativeSender
    // bool isNativeToken //added to feeParams
    );

    /// @dev Emitted once the tokens are transferred and withdrawn on a target chain
    event Claimed(
        bytes32 submissionId,
        bytes32 indexed debridgeId,
        uint256 amount,
        address indexed receiver,
        uint256 nonce,
        uint256 indexed chainIdFrom,
        bytes autoParams,
        bool isNativeToken
    );

    /// @dev Emitted when new asset support is added.
    event PairAdded(
        bytes32 debridgeId,
        address tokenAddress,
        bytes nativeAddress,
        uint256 indexed nativeChainId,
        uint256 maxAmount,
        uint16 minReservesBps
    );

    /// @dev Emitted when the asset is allowed/disallowed to be transferred to the chain.
    event ChainSupportUpdated(uint256 chainId, bool isSupported, bool isChainFrom);
    /// @dev Emitted when the supported chains are updated.
    event ChainsSupportUpdated(
        uint256 chainIds,
        ChainSupportInfo chainSupportInfo,
        bool isChainFrom);

    /// @dev Emitted when the new call proxy is set.
    event CallProxyUpdated(address callProxy);
    /// @dev Emitted when the transfer request is executed.
    event AutoRequestExecuted(
        bytes32 submissionId,
        bool indexed success,
        address callProxy
    );

    /// @dev Emitted when a submission is blocked.
    event Blocked(bytes32 submissionId);
    /// @dev Emitted when a submission is unblocked.
    event Unblocked(bytes32 submissionId);

    /// @dev Emitted when a flash loan is successfully returned.
    event Flash(
        address sender,
        address indexed tokenAddress,
        address indexed receiver,
        uint256 amount,
        uint256 paid
    );

    /// @dev Emitted when fee is withdrawn.
    event WithdrawnFee(bytes32 debridgeId, uint256 fee);

    /// @dev Emitted when globalFixedNativeFee and globalTransferFeeBps are updated.
    event FixedNativeFeeUpdated(
        uint256 globalFixedNativeFee,
        uint256 globalTransferFeeBps);

    /// @dev Emitted when globalFixedNativeFee is updated by feeContractUpdater
    event FixedNativeFeeAutoUpdated(uint256 globalFixedNativeFee);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ICallProxy {

    /// @dev Chain from which the current submission is received
    function submissionChainIdFrom() external returns (uint256);
    /// @dev Native sender of the current submission
    function submissionNativeSender() external returns (bytes memory);

    /// @dev Used for calls where native asset transfer is involved.
    /// @param _reserveAddress Receiver of the tokens if the call to _receiver fails
    /// @param _receiver Contract to be called
    /// @param _data Call data
    /// @param _flags Flags to change certain behavior of this function, see Flags library for more details
    /// @param _nativeSender Native sender
    /// @param _chainIdFrom Id of a chain that originated the request
    function call(
        address _reserveAddress,
        address _receiver,
        bytes memory _data,
        uint256 _flags,
        bytes memory _nativeSender,
        uint256 _chainIdFrom
    ) external payable returns (bool);

    /// @dev Used for calls where ERC20 transfer is involved.
    /// @param _token Asset address
    /// @param _reserveAddress Receiver of the tokens if the call to _receiver fails
    /// @param _receiver Contract to be called
    /// @param _data Call data
    /// @param _flags Flags to change certain behavior of this function, see Flags library for more details
    /// @param _nativeSender Native sender
    /// @param _chainIdFrom Id of a chain that originated the request
    function callERC20(
        address _token,
        address _reserveAddress,
        address _receiver,
        bytes memory _data,
        uint256 _flags,
        bytes memory _nativeSender,
        uint256 _chainIdFrom
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/// @title Callback for IDeBridgeGate#flash
/// @notice Any contract that calls IDeBridgeGate#flash must implement this interface
interface IFlashCallback {
    /// @param fee The fee amount in token due to the pool by the end of the flash
    /// @param data Any data passed through by the caller via the IDeBridgeGate#flash call
    function flashCallback(uint256 fee, bytes calldata data) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

library SignatureUtil {
    /* ========== ERRORS ========== */

    error WrongArgumentLength();
    error SignatureInvalidLength();
    error SignatureInvalidV();

    /// @dev Prepares raw msg that was signed by the oracle.
    /// @param _submissionId Submission identifier.
    function getUnsignedMsg(bytes32 _submissionId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _submissionId));
    }

    /// @dev Splits signature bytes to r,s,v components.
    /// @param _signature Signature bytes in format r+s+v.
    function splitSignature(bytes memory _signature)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        if (_signature.length != 65) revert SignatureInvalidLength();
        return parseSignature(_signature, 0);
    }

    function parseSignature(bytes memory _signatures, uint256 offset)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        assembly {
            r := mload(add(_signatures, add(32, offset)))
            s := mload(add(_signatures, add(64, offset)))
            v := and(mload(add(_signatures, add(65, offset))), 0xff)
        }

        if (v < 27) v += 27;
        if (v != 27 && v != 28) revert SignatureInvalidV();
    }

    function toUint256(bytes memory _bytes, uint256 _offset)
        internal
        pure
        returns (uint256 result)
    {
        if (_bytes.length < _offset + 32) revert WrongArgumentLength();

        assembly {
            result := mload(add(add(_bytes, 0x20), _offset))
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

library Flags {

    /* ========== FLAGS ========== */

    /// @dev Flag to unwrap ETH
    uint256 public constant UNWRAP_ETH = 0;
    /// @dev Flag to revert if external call fails
    uint256 public constant REVERT_IF_EXTERNAL_FAIL = 1;
    /// @dev Flag to call proxy with a sender contract
    uint256 public constant PROXY_WITH_SENDER = 2;

    /// @dev Get flag
    /// @param _packedFlags Flags packed to uint256
    /// @param _flag Flag to check
    function getFlag(
        uint256 _packedFlags,
        uint256 _flag
    ) internal pure returns (bool) {
        uint256 flag = (_packedFlags >> _flag) & uint256(1);
        return flag == 1;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IWethGate {
    function withdraw(address receiver, uint wad) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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