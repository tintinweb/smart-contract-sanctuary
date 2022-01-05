//SPDX-License-Identifier: MIT

pragma solidity =0.7.6;
pragma abicoder v2;

// interface
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {IWETH9} from "../interfaces/IWETH9.sol";
import {IWPowerPerp} from "../interfaces/IWPowerPerp.sol";
import {IShortPowerPerp} from "../interfaces/IShortPowerPerp.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

//contract
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

//lib
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ABDKMath64x64} from "../libs/ABDKMath64x64.sol";
import {VaultLib} from "../libs/VaultLib.sol";
import {Uint256Casting} from "../libs/Uint256Casting.sol";
import {Power2Base} from "../libs/Power2Base.sol";

/**
 *
 * Error
 * C0: Paused
 * C1: Not paused
 * C2: Shutdown
 * C3: Not shutdown
 * C4: Invalid oracle address
 * C5: Invalid shortPowerPerp address
 * C6: Invalid wPowerPerp address
 * C7: Invalid weth address
 * C8: Invalid quote currency address
 * C9: Invalid eth:quoteCurrency pool address
 * C10: Invalid wPowerPerp:eth pool address
 * C11: Invalid Uniswap position manager
 * C12: Can not liquidate safe vault
 * C13: Invalid address
 * C14: Set fee recipient first
 * C15: Fee too high
 * C16: Paused too many times
 * C17: Pause time limit exceeded
 * C18: Not enough paused time has passed
 * C19: Cannot receive eth
 * C20: Not allowed
 * C21: Need full liquidation
 * C22: Dust vault left
 * C23: Invalid nft
 * C24: Invalid state
 * C25: 0 liquidity Uniswap position token
 */
contract Controller is Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeMath for uint256;
    using Uint256Casting for uint256;
    using ABDKMath64x64 for int128;
    using VaultLib for VaultLib.Vault;
    using Address for address payable;

    uint256 internal constant MIN_COLLATERAL = 6.9 ether;
    /// @dev system can only be paused for 182 days from deployment
    uint256 internal constant PAUSE_TIME_LIMIT = 182 days;

    uint256 public constant FUNDING_PERIOD = 420 hours;
    uint32 public constant TWAP_PERIOD = 5 minutes;

    //80% of index
    uint256 internal constant LOWER_MARK_RATIO = 8e17;
    //125% of index
    uint256 internal constant UPPER_MARK_RATIO = 125e16;
    // 10%
    uint256 internal constant LIQUIDATION_BOUNTY = 1e17;
    // 2%
    uint256 internal constant REDUCE_DEBT_BOUNTY = 2e16;

    /// @dev basic unit used for calculation
    uint256 private constant ONE = 1e18;
    uint256 private constant ONE_ONE = 1e36;

    address public immutable weth;
    address public immutable quoteCurrency;
    address public immutable ethQuoteCurrencyPool;
    /// @dev address of the powerPerp/weth pool
    address public immutable wPowerPerpPool;
    address internal immutable uniswapPositionManager;
    address public immutable shortPowerPerp;
    address public immutable wPowerPerp;
    address public immutable oracle;
    address public feeRecipient;

    uint256 internal immutable deployTimestamp;
    /// @dev fee rate in basis point. feeRate of 1 = 0.01%
    uint256 public feeRate;
    /// @dev the settlement price for each wPowerPerp for settlement
    uint256 public indexForSettlement;

    uint256 public pausesLeft = 4;
    uint256 public lastPauseTime;

    // these 2 parameters are always updated together. Use uint128 to batch read and write.
    uint128 public normalizationFactor;
    uint128 public lastFundingUpdateTimestamp;

    bool internal immutable isWethToken0;
    bool public isShutDown;
    bool public isSystemPaused;

    /// @dev vault data storage
    mapping(uint256 => VaultLib.Vault) public vaults;

    /// Events
    event OpenVault(address sender, uint256 vaultId);
    event DepositCollateral(address sender, uint256 vaultId, uint256 amount);
    event DepositUniPositionToken(address sender, uint256 vaultId, uint256 tokenId);
    event WithdrawCollateral(address sender, uint256 vaultId, uint256 amount);
    event WithdrawUniPositionToken(address sender, uint256 vaultId, uint256 tokenId);
    event MintShort(address sender, uint256 amount, uint256 vaultId);
    event BurnShort(address sender, uint256 amount, uint256 vaultId);
    event ReduceDebt(
        address sender,
        uint256 vaultId,
        uint256 ethRedeemed,
        uint256 wPowerPerpRedeemed,
        uint256 wPowerPerpBurned,
        uint256 wPowerPerpExcess,
        uint256 bounty
    );
    event UpdateOperator(address sender, uint256 vaultId, address operator);
    event FeeRateUpdated(uint256 oldFee, uint256 newFee);
    event FeeRecipientUpdated(address oldFeeRecipient, address newFeeRecipient);
    event Liquidate(address liquidator, uint256 vaultId, uint256 debtAmount, uint256 collateralPaid);
    event NormalizationFactorUpdated(
        uint256 oldNormFactor,
        uint256 newNormFactor,
        uint256 lastModificationTimestamp,
        uint256 timestamp
    );
    event Paused(uint256 pausesLeft);
    event UnPaused(address unpauser);
    event Shutdown(uint256 indexForSettlement);
    event RedeemLong(address sender, uint256 wPowerPerpAmount, uint256 payoutAmount);
    event RedeemShort(address sender, uint256 vauldId, uint256 collateralAmount);

    modifier notPaused() {
        require(!isSystemPaused, "C0");
        _;
    }

    modifier isPaused() {
        require(isSystemPaused, "C1");
        _;
    }

    modifier notShutdown() {
        require(!isShutDown, "C2");
        _;
    }

    modifier isShutdown() {
        require(isShutDown, "C3");
        _;
    }

    /**
     * @notice constructor
     * @param _oracle oracle address
     * @param _shortPowerPerp ERC721 token address representing the short position
     * @param _wPowerPerp ERC20 token address representing the long position
     * @param _weth weth address
     * @param _quoteCurrency quoteCurrency address
     * @param _ethQuoteCurrencyPool uniswap v3 pool for weth / quoteCurrency
     * @param _wPowerPerpPool uniswap v3 pool for wPowerPerp / weth
     * @param _uniPositionManager uniswap v3 position manager address
     */
    constructor(
        address _oracle,
        address _shortPowerPerp,
        address _wPowerPerp,
        address _weth,
        address _quoteCurrency,
        address _ethQuoteCurrencyPool,
        address _wPowerPerpPool,
        address _uniPositionManager
    ) {
        require(_oracle != address(0), "C4");
        require(_shortPowerPerp != address(0), "C5");
        require(_wPowerPerp != address(0), "C6");
        require(_weth != address(0), "C7");
        require(_quoteCurrency != address(0), "C8");
        require(_ethQuoteCurrencyPool != address(0), "C9");
        require(_wPowerPerpPool != address(0), "C10");
        require(_uniPositionManager != address(0), "C11");

        oracle = _oracle;
        shortPowerPerp = _shortPowerPerp;
        wPowerPerp = _wPowerPerp;
        weth = _weth;
        quoteCurrency = _quoteCurrency;
        ethQuoteCurrencyPool = _ethQuoteCurrencyPool;
        wPowerPerpPool = _wPowerPerpPool;
        uniswapPositionManager = _uniPositionManager;
        isWethToken0 = _weth < _wPowerPerp;

        normalizationFactor = 1e18;
        deployTimestamp = block.timestamp;
        lastFundingUpdateTimestamp = block.timestamp.toUint128();
    }

    /**
     * ======================
     * | External Functions |
     * ======================
     */

    /**
     * @notice returns the expected normalization factor, if the funding is paid right now
     * @dev can be used for on-chain and off-chain calculations
     */
    function getExpectedNormalizationFactor() external view returns (uint256) {
        return _getNewNormalizationFactor();
    }

    /**
     * @notice get the index price of the powerPerp, scaled down
     * @dev the index price is scaled down by INDEX_SCALE in the associated PowerXBase library
     * @dev this is the index price used when calculating funding and for collateralization
     * @param _period period which you want to calculate twap with
     * @return index price denominated in $USD, scaled by 1e18
     */
    function getIndex(uint32 _period) external view returns (uint256) {
        return Power2Base._getIndex(_period, oracle, ethQuoteCurrencyPool, weth, quoteCurrency);
    }

    /**
     * @notice the unscaled index of the power perp in USD, scaled by 18 decimals
     * @dev this is the mark that would be be used for future funding after a new normalization factor is applied
     * @param _period period which you want to calculate twap with
     * @return index price denominated in $USD, scaled by 1e18
     */
    function getUnscaledIndex(uint32 _period) external view returns (uint256) {
        return Power2Base._getUnscaledIndex(_period, oracle, ethQuoteCurrencyPool, weth, quoteCurrency);
    }

    /**
     * @notice get the expected mark price of powerPerp after funding has been applied
     * @param _period period of time for the twap in seconds
     * @return mark price denominated in $USD, scaled by 1e18
     */
    function getDenormalizedMark(uint32 _period) external view returns (uint256) {
        return
            Power2Base._getDenormalizedMark(
                _period,
                oracle,
                wPowerPerpPool,
                ethQuoteCurrencyPool,
                weth,
                quoteCurrency,
                wPowerPerp,
                _getNewNormalizationFactor()
            );
    }

    /**
     * @notice get the mark price of powerPerp before funding has been applied
     * @dev this is the mark that would be used to calculate a new normalization factor if funding was calculated now
     * @param _period period which you want to calculate twap with
     * @return mark price denominated in $USD, scaled by 1e18
     */
    function getDenormalizedMarkForFunding(uint32 _period) external view returns (uint256) {
        return
            Power2Base._getDenormalizedMark(
                _period,
                oracle,
                wPowerPerpPool,
                ethQuoteCurrencyPool,
                weth,
                quoteCurrency,
                wPowerPerp,
                normalizationFactor
            );
    }

    /**
     * @dev return if the vault is properly collateralized
     * @param _vaultId id of the vault
     * @return true if the vault is properly collateralized
     */
    function isVaultSafe(uint256 _vaultId) external view returns (bool) {
        VaultLib.Vault memory vault = vaults[_vaultId];
        uint256 expectedNormalizationFactor = _getNewNormalizationFactor();
        return _isVaultSafe(vault, expectedNormalizationFactor);
    }

    /**
     * @notice deposit collateral and mint wPowerPerp (non-rebasing) for specified powerPerp (rebasing) amount
     * @param _vaultId vault to mint wPowerPerp in
     * @param _powerPerpAmount amount of powerPerp to mint
     * @param _uniTokenId uniswap v3 position token id (additional collateral)
     * @return vaultId
     * @return amount of wPowerPerp minted
     */
    function mintPowerPerpAmount(
        uint256 _vaultId,
        uint256 _powerPerpAmount,
        uint256 _uniTokenId
    ) external payable notPaused nonReentrant returns (uint256, uint256) {
        return _openDepositMint(msg.sender, _vaultId, _powerPerpAmount, msg.value, _uniTokenId, false);
    }

    /**
     * @notice deposit collateral and mint wPowerPerp
     * @param _vaultId vault to mint wPowerPerp in
     * @param _wPowerPerpAmount amount of wPowerPerp to mint
     * @param _uniTokenId uniswap v3 position token id (additional collateral)
     * @return vaultId
     */
    function mintWPowerPerpAmount(
        uint256 _vaultId,
        uint256 _wPowerPerpAmount,
        uint256 _uniTokenId
    ) external payable notPaused nonReentrant returns (uint256) {
        (uint256 vaultId, ) = _openDepositMint(msg.sender, _vaultId, _wPowerPerpAmount, msg.value, _uniTokenId, true);
        return vaultId;
    }

    /**
     * @dev deposit collateral into a vault
     * @param _vaultId id of the vault
     */
    function deposit(uint256 _vaultId) external payable notPaused nonReentrant {
        _checkCanModifyVault(_vaultId, msg.sender);

        _applyFunding();
        VaultLib.Vault memory cachedVault = vaults[_vaultId];
        _addEthCollateral(cachedVault, _vaultId, msg.value);

        _writeVault(_vaultId, cachedVault);
    }

    /**
     * @notice deposit uniswap position token into a vault to increase collateral ratio
     * @param _vaultId id of the vault
     * @param _uniTokenId uniswap position token id
     */
    function depositUniPositionToken(uint256 _vaultId, uint256 _uniTokenId) external notPaused nonReentrant {
        _checkCanModifyVault(_vaultId, msg.sender);

        _applyFunding();
        VaultLib.Vault memory cachedVault = vaults[_vaultId];

        _depositUniPositionToken(cachedVault, msg.sender, _vaultId, _uniTokenId);
        _writeVault(_vaultId, cachedVault);
    }

    /**
     * @notice withdraw collateral from a vault
     * @param _vaultId id of the vault
     * @param _amount amount of eth to withdraw
     */
    function withdraw(uint256 _vaultId, uint256 _amount) external notPaused nonReentrant {
        _checkCanModifyVault(_vaultId, msg.sender);

        uint256 cachedNormFactor = _applyFunding();
        VaultLib.Vault memory cachedVault = vaults[_vaultId];

        _withdrawCollateral(cachedVault, _vaultId, _amount);
        _checkVault(cachedVault, cachedNormFactor);
        _writeVault(_vaultId, cachedVault);
        payable(msg.sender).sendValue(_amount);
    }

    /**
     * @notice withdraw uniswap v3 position token from a vault
     * @param _vaultId id of the vault
     */
    function withdrawUniPositionToken(uint256 _vaultId) external notPaused nonReentrant {
        _checkCanModifyVault(_vaultId, msg.sender);

        uint256 cachedNormFactor = _applyFunding();
        VaultLib.Vault memory cachedVault = vaults[_vaultId];
        _withdrawUniPositionToken(cachedVault, msg.sender, _vaultId);
        _checkVault(cachedVault, cachedNormFactor);
        _writeVault(_vaultId, cachedVault);
    }

    /**
     * @notice burn wPowerPerp and remove collateral from a vault
     * @param _vaultId id of the vault
     * @param _wPowerPerpAmount amount of wPowerPerp to burn
     * @param _withdrawAmount amount of eth to withdraw
     */
    function burnWPowerPerpAmount(
        uint256 _vaultId,
        uint256 _wPowerPerpAmount,
        uint256 _withdrawAmount
    ) external notPaused nonReentrant {
        _checkCanModifyVault(_vaultId, msg.sender);

        _burnAndWithdraw(msg.sender, _vaultId, _wPowerPerpAmount, _withdrawAmount, true);
    }

    /**
     * @notice burn powerPerp and remove collateral from a vault
     * @param _vaultId id of the vault
     * @param _powerPerpAmount amount of powerPerp to burn
     * @param _withdrawAmount amount of eth to withdraw
     * @return amount of wPowerPerp burned
     */
    function burnPowerPerpAmount(
        uint256 _vaultId,
        uint256 _powerPerpAmount,
        uint256 _withdrawAmount
    ) external notPaused nonReentrant returns (uint256) {
        _checkCanModifyVault(_vaultId, msg.sender);

        return _burnAndWithdraw(msg.sender, _vaultId, _powerPerpAmount, _withdrawAmount, false);
    }

    /**
     * @notice after the system is shutdown, insolvent vaults need to be have their uniswap v3 token assets withdrawn by force
     * @notice if a vault has a uniswap v3 position in it, anyone can call to withdraw uniswap v3 token assets, reducing debt and increasing collateral in the vault
     * @dev the caller won't get any bounty. this is expected to be used for insolvent vaults in shutdown
     * @param _vaultId vault containing uniswap v3 position to liquidate
     */
    function reduceDebtShutdown(uint256 _vaultId) external isShutdown nonReentrant {
        VaultLib.Vault memory cachedVault = vaults[_vaultId];
        _reduceDebt(cachedVault, IShortPowerPerp(shortPowerPerp).ownerOf(_vaultId), _vaultId, false);
        _writeVault(_vaultId, cachedVault);
    }

    /**
     * @notice withdraw assets from uniswap v3 position, reducing debt and increasing collateral in the vault
     * @dev the caller won't get any bounty. this is expected to be used by vault owner
     * @param _vaultId target vault
     */
    function reduceDebt(uint256 _vaultId) external notPaused nonReentrant {
        _checkCanModifyVault(_vaultId, msg.sender);
        VaultLib.Vault memory cachedVault = vaults[_vaultId];

        _reduceDebt(cachedVault, IShortPowerPerp(shortPowerPerp).ownerOf(_vaultId), _vaultId, false);

        _writeVault(_vaultId, cachedVault);
    }

    /**
     * @notice if a vault is under the 150% collateral ratio, anyone can liquidate the vault by burning wPowerPerp
     * @dev liquidator can get back (wPowerPerp burned) * (index price) * (normalizationFactor)  * 110% in collateral
     * @dev normally can only liquidate 50% of a vault's debt
     * @dev if a vault is under dust limit after a liquidation can fully liquidate
     * @dev will attempt to reduceDebt first, and can earn a bounty if sucessful
     * @param _vaultId vault to liquidate
     * @param _maxDebtAmount max amount of wPowerPerpetual to repay
     * @return amount of wPowerPerp repaid
     */
    function liquidate(uint256 _vaultId, uint256 _maxDebtAmount) external notPaused nonReentrant returns (uint256) {
        uint256 cachedNormFactor = _applyFunding();

        VaultLib.Vault memory cachedVault = vaults[_vaultId];

        require(!_isVaultSafe(cachedVault, cachedNormFactor), "C12");

        // try to save target vault before liquidation by reducing debt
        uint256 bounty = _reduceDebt(cachedVault, IShortPowerPerp(shortPowerPerp).ownerOf(_vaultId), _vaultId, true);

        // if vault is safe after saving, pay bounty and return early
        if (_isVaultSafe(cachedVault, cachedNormFactor)) {
            _writeVault(_vaultId, cachedVault);
            payable(msg.sender).sendValue(bounty);
            return 0;
        }

        // add back the bounty amount, liquidators onlly get reward from liquidation
        cachedVault.addEthCollateral(bounty);

        // if the vault is still not safe after saving, liquidate it
        (uint256 debtAmount, uint256 collateralPaid) = _liquidate(
            cachedVault,
            _maxDebtAmount,
            cachedNormFactor,
            msg.sender
        );

        emit Liquidate(msg.sender, _vaultId, debtAmount, collateralPaid);

        _writeVault(_vaultId, cachedVault);

        // pay the liquidator
        payable(msg.sender).sendValue(collateralPaid);

        return debtAmount;
    }

    /**
     * @notice authorize an address to modify the vault
     * @dev can be revoke by setting address to 0
     * @param _vaultId id of the vault
     * @param _operator new operator address
     */
    function updateOperator(uint256 _vaultId, address _operator) external {
        require(
            (shortPowerPerp == msg.sender) || (IShortPowerPerp(shortPowerPerp).ownerOf(_vaultId) == msg.sender),
            "C20"
        );
        vaults[_vaultId].operator = _operator;
        emit UpdateOperator(msg.sender, _vaultId, _operator);
    }

    /**
     * @notice set the recipient who will receive the fee
     * @dev this should be a contract handling insurance
     * @param _newFeeRecipient new fee recipient
     */
    function setFeeRecipient(address _newFeeRecipient) external onlyOwner {
        require(_newFeeRecipient != address(0), "C13");
        emit FeeRecipientUpdated(feeRecipient, _newFeeRecipient);
        feeRecipient = _newFeeRecipient;
    }

    /**
     * @notice set the fee rate when user mints
     * @dev this function cannot be called if the feeRecipient is still un-set
     * @param _newFeeRate new fee rate in basis points. can't be higher than 1%
     */
    function setFeeRate(uint256 _newFeeRate) external onlyOwner {
        require(feeRecipient != address(0), "C14");
        require(_newFeeRate <= 100, "C15");
        emit FeeRateUpdated(feeRate, _newFeeRate);
        feeRate = _newFeeRate;
    }

    /**
     * @notice pause (if not paused) and then immediately shutdown the system, can be called when paused already
     * @dev this bypasses the check on number of pauses or time based checks, but is irreversible and enables emergency settlement
     */
    function shutDown() external onlyOwner notShutdown {
        isSystemPaused = true;
        isShutDown = true;
        indexForSettlement = Power2Base._getScaledTwap(
            oracle,
            ethQuoteCurrencyPool,
            weth,
            quoteCurrency,
            TWAP_PERIOD,
            false
        );
    }

    /**
     * @notice pause the system for up to 24 hours after which any one can unpause
     * @dev can only be called for 365 days since the contract was launched or 4 times
     */
    function pause() external onlyOwner notShutdown notPaused {
        require(pausesLeft > 0, "C16");
        uint256 timeSinceDeploy = block.timestamp.sub(deployTimestamp);
        require(timeSinceDeploy < PAUSE_TIME_LIMIT, "C17");
        isSystemPaused = true;
        pausesLeft -= 1;
        lastPauseTime = block.timestamp;

        emit Paused(pausesLeft);
    }

    /**
     * @notice unpause the contract
     * @dev anyone can unpause the contract after 24 hours
     */
    function unPauseAnyone() external isPaused notShutdown {
        require(block.timestamp > (lastPauseTime + 1 days), "C18");
        isSystemPaused = false;
        emit UnPaused(msg.sender);
    }

    /**
     * @notice unpause the contract
     * @dev owner can unpause at any time
     */
    function unPauseOwner() external onlyOwner isPaused notShutdown {
        isSystemPaused = false;
        emit UnPaused(msg.sender);
    }

    /**
     * @notice redeem wPowerPerp for (settlement index value) * normalizationFactor when the system is shutdown
     * @param _wPerpAmount amount of wPowerPerp to burn
     */
    function redeemLong(uint256 _wPerpAmount) external isShutdown nonReentrant {
        IWPowerPerp(wPowerPerp).burn(msg.sender, _wPerpAmount);

        uint256 longValue = Power2Base._getLongSettlementValue(_wPerpAmount, indexForSettlement, normalizationFactor);
        payable(msg.sender).sendValue(longValue);

        emit RedeemLong(msg.sender, _wPerpAmount, longValue);
    }

    /**
     * @notice redeem short position when the system is shutdown
     * @dev short position is redeemed by valuing the debt at the (settlement index value) * normalizationFactor
     * @param _vaultId vault id
     */
    function redeemShort(uint256 _vaultId) external isShutdown nonReentrant {
        _checkCanModifyVault(_vaultId, msg.sender);

        VaultLib.Vault memory cachedVault = vaults[_vaultId];
        uint256 cachedNormFactor = normalizationFactor;

        _reduceDebt(cachedVault, msg.sender, _vaultId, false);

        uint256 debt = Power2Base._getLongSettlementValue(
            cachedVault.shortAmount,
            indexForSettlement,
            cachedNormFactor
        );
        // if the debt is more than collateral, this line will revert
        uint256 excess = uint256(cachedVault.collateralAmount).sub(debt);

        // reset the vault but don't burn the nft, just because people may want to keep it
        cachedVault.shortAmount = 0;
        cachedVault.collateralAmount = 0;
        _writeVault(_vaultId, cachedVault);

        payable(msg.sender).sendValue(excess);

        emit RedeemShort(msg.sender, _vaultId, excess);
    }

    /**
     * @notice update the normalization factor as a way to pay funding
     */
    function applyFunding() external notPaused {
        _applyFunding();
    }

    /**
     * @notice add eth into a contract. used in case contract has insufficient eth to pay for settlement transactions
     */
    function donate() external payable isShutdown {}

    /**
     * @notice fallback function to accept eth
     */
    receive() external payable {
        require(msg.sender == weth, "C19");
    }

    /**
     * @dev accept erc721 from safeTransferFrom and safeMint after callback
     * @return returns received selector
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /*
     * ======================
     * | Internal Functions |
     * ======================
     */

    /**
     * @notice check if an address can modify a vault
     * @param _vaultId the id of the vault to check if can be modified by _account
     * @param _account the address to check if can modify the vault
     */
    function _checkCanModifyVault(uint256 _vaultId, address _account) internal view {
        require(
            IShortPowerPerp(shortPowerPerp).ownerOf(_vaultId) == _account || vaults[_vaultId].operator == _account,
            "C20"
        );
    }

    /**
     * @notice wrapper function which opens a vault, adds collateral and mints wPowerPerp
     * @param _account account to receive wPowerPerp
     * @param _vaultId id of the vault
     * @param _mintAmount amount to mint
     * @param _depositAmount amount of eth as collateral
     * @param _uniTokenId id of uniswap v3 position token
     * @param _isWAmount if the input amount is a wPowerPerp amount (as opposed to rebasing powerPerp)
     * @return the vaultId that was acted on or for a new vault the newly created vaultId
     * @return the minted wPowerPerp amount
     */
    function _openDepositMint(
        address _account,
        uint256 _vaultId,
        uint256 _mintAmount,
        uint256 _depositAmount,
        uint256 _uniTokenId,
        bool _isWAmount
    ) internal returns (uint256, uint256) {
        uint256 cachedNormFactor = _applyFunding();
        uint256 depositAmountWithFee = _depositAmount;
        uint256 wPowerPerpAmount = _isWAmount ? _mintAmount : _mintAmount.mul(ONE).div(cachedNormFactor);
        uint256 feeAmount;
        VaultLib.Vault memory cachedVault;

        // load vault or create new a new one
        if (_vaultId == 0) {
            (_vaultId, cachedVault) = _openVault(_account);
        } else {
            // make sure we're not accessing an unexistent vault.
            _checkCanModifyVault(_vaultId, msg.sender);
            cachedVault = vaults[_vaultId];
        }

        if (wPowerPerpAmount > 0) {
            (feeAmount, depositAmountWithFee) = _getFee(cachedVault, wPowerPerpAmount, _depositAmount);
            _mintWPowerPerp(cachedVault, _account, _vaultId, wPowerPerpAmount);
        }
        if (_depositAmount > 0) _addEthCollateral(cachedVault, _vaultId, depositAmountWithFee);
        if (_uniTokenId != 0) _depositUniPositionToken(cachedVault, _account, _vaultId, _uniTokenId);

        _checkVault(cachedVault, cachedNormFactor);
        _writeVault(_vaultId, cachedVault);

        // pay insurance fee
        if (feeAmount > 0) payable(feeRecipient).sendValue(feeAmount);

        return (_vaultId, wPowerPerpAmount);
    }

    /**
     * @notice wrapper function to burn wPowerPerp and redeem collateral
     * @param _account who should receive collateral
     * @param _vaultId id of the vault
     * @param _burnAmount amount of wPowerPerp to burn
     * @param _withdrawAmount amount of eth collateral to withdraw
     * @param _isWAmount true if the amount is wPowerPerp (as opposed to rebasing powerPerp)
     * @return total burned wPowerPower amount
     */
    function _burnAndWithdraw(
        address _account,
        uint256 _vaultId,
        uint256 _burnAmount,
        uint256 _withdrawAmount,
        bool _isWAmount
    ) internal returns (uint256) {
        uint256 cachedNormFactor = _applyFunding();
        uint256 wBurnAmount = _isWAmount ? _burnAmount : _burnAmount.mul(ONE).div(cachedNormFactor);

        VaultLib.Vault memory cachedVault = vaults[_vaultId];
        if (wBurnAmount > 0) _burnWPowerPerp(cachedVault, _account, _vaultId, wBurnAmount);
        if (_withdrawAmount > 0) _withdrawCollateral(cachedVault, _vaultId, _withdrawAmount);
        _checkVault(cachedVault, cachedNormFactor);
        _writeVault(_vaultId, cachedVault);

        if (_withdrawAmount > 0) payable(msg.sender).sendValue(_withdrawAmount);

        return wBurnAmount;
    }

    /**
     * @notice open a new vault
     * @dev create a new vault and bind it with a new short vault id
     * @param _recipient owner of new vault
     * @return id of the new vault
     * @return new in-memory vault
     */
    function _openVault(address _recipient) internal returns (uint256, VaultLib.Vault memory) {
        uint256 vaultId = IShortPowerPerp(shortPowerPerp).mintNFT(_recipient);

        VaultLib.Vault memory vault = VaultLib.Vault({
            NftCollateralId: 0,
            collateralAmount: 0,
            shortAmount: 0,
            operator: address(0)
        });
        emit OpenVault(msg.sender, vaultId);
        return (vaultId, vault);
    }

    /**
     * @notice deposit uniswap v3 position token into a vault
     * @dev this function will update the vault memory in-place
     * @param _vault the Vault memory to update
     * @param _account account to transfer the uniswap v3 position from
     * @param _vaultId id of the vault
     * @param _uniTokenId uniswap position token id
     */
    function _depositUniPositionToken(
        VaultLib.Vault memory _vault,
        address _account,
        uint256 _vaultId,
        uint256 _uniTokenId
    ) internal {
        //get tokens for uniswap NFT
        (, , address token0, address token1, , , , uint128 liquidity, , , , ) = INonfungiblePositionManager(
            uniswapPositionManager
        ).positions(_uniTokenId);

        //require that liquidity is above 0
        require(liquidity > 0, "C25");
        // only check token0 and token1, ignore fee
        // if there are multiple wPowerPerp/weth pools with different fee rate, accept position tokens from any of them
        require((token0 == wPowerPerp && token1 == weth) || (token1 == wPowerPerp && token0 == weth), "C23");

        _vault.addUniNftCollateral(_uniTokenId);
        INonfungiblePositionManager(uniswapPositionManager).safeTransferFrom(_account, address(this), _uniTokenId);
        emit DepositUniPositionToken(msg.sender, _vaultId, _uniTokenId);
    }

    /**
     * @notice add eth collateral into a vault
     * @dev this function will update the vault memory in-place
     * @param _vault the Vault memory to update.
     * @param _vaultId id of the vault
     * @param _amount amount of eth adding to the vault
     */
    function _addEthCollateral(
        VaultLib.Vault memory _vault,
        uint256 _vaultId,
        uint256 _amount
    ) internal {
        _vault.addEthCollateral(_amount);
        emit DepositCollateral(msg.sender, _vaultId, _amount);
    }

    /**
     * @notice remove uniswap v3 position token from the vault
     * @dev this function will update the vault memory in-place
     * @param _vault the Vault memory to update
     * @param _account where to send the uni position token to
     * @param _vaultId id of the vault
     */
    function _withdrawUniPositionToken(
        VaultLib.Vault memory _vault,
        address _account,
        uint256 _vaultId
    ) internal {
        uint256 tokenId = _vault.NftCollateralId;
        _vault.removeUniNftCollateral();
        INonfungiblePositionManager(uniswapPositionManager).safeTransferFrom(address(this), _account, tokenId);
        emit WithdrawUniPositionToken(msg.sender, _vaultId, tokenId);
    }

    /**
     * @notice remove eth collateral from the vault
     * @dev this function will update the vault memory in-place
     * @param _vault the Vault memory to update
     * @param _vaultId id of the vault
     * @param _amount amount of eth to withdraw
     */
    function _withdrawCollateral(
        VaultLib.Vault memory _vault,
        uint256 _vaultId,
        uint256 _amount
    ) internal {
        _vault.removeEthCollateral(_amount);

        emit WithdrawCollateral(msg.sender, _vaultId, _amount);
    }

    /**
     * @notice mint wPowerPerp (ERC20) to an account
     * @dev this function will update the vault memory in-place
     * @param _vault the Vault memory to update
     * @param _account account to receive wPowerPerp
     * @param _vaultId id of the vault
     * @param _wPowerPerpAmount wPowerPerp amount to mint
     */
    function _mintWPowerPerp(
        VaultLib.Vault memory _vault,
        address _account,
        uint256 _vaultId,
        uint256 _wPowerPerpAmount
    ) internal {
        _vault.addShort(_wPowerPerpAmount);
        IWPowerPerp(wPowerPerp).mint(_account, _wPowerPerpAmount);

        emit MintShort(msg.sender, _wPowerPerpAmount, _vaultId);
    }

    /**
     * @notice burn wPowerPerp (ERC20) from an account
     * @dev this function will update the vault memory in-place
     * @param _vault the Vault memory to update
     * @param _account account burning the wPowerPerp
     * @param _vaultId id of the vault
     * @param _wPowerPerpAmount wPowerPerp amount to burn
     */
    function _burnWPowerPerp(
        VaultLib.Vault memory _vault,
        address _account,
        uint256 _vaultId,
        uint256 _wPowerPerpAmount
    ) internal {
        _vault.removeShort(_wPowerPerpAmount);
        IWPowerPerp(wPowerPerp).burn(_account, _wPowerPerpAmount);

        emit BurnShort(msg.sender, _wPowerPerpAmount, _vaultId);
    }

    /**
     * @notice liquidate a vault, pay the liquidator
     * @dev liquidator can only liquidate at most 1/2 of the vault in 1 transaction
     * @dev this function will update the vault memory in-place
     * @param _vault the Vault memory to update
     * @param _maxWPowerPerpAmount maximum debt amount liquidator is willing to repay
     * @param _normalizationFactor current normalization factor
     * @param _liquidator liquidator address to receive eth
     * @return debtAmount amount of wPowerPerp repaid (burn from the vault)
     * @return collateralToPay amount of collateral paid to liquidator
     */
    function _liquidate(
        VaultLib.Vault memory _vault,
        uint256 _maxWPowerPerpAmount,
        uint256 _normalizationFactor,
        address _liquidator
    ) internal returns (uint256, uint256) {
        (uint256 liquidateAmount, uint256 collateralToPay) = _getLiquidationResult(
            _maxWPowerPerpAmount,
            uint256(_vault.shortAmount),
            uint256(_vault.collateralAmount)
        );

        // if the liquidator didn't specify enough wPowerPerp to burn, revert.
        require(_maxWPowerPerpAmount >= liquidateAmount, "C21");

        IWPowerPerp(wPowerPerp).burn(_liquidator, liquidateAmount);
        _vault.removeShort(liquidateAmount);
        _vault.removeEthCollateral(collateralToPay);

        (, bool isDust) = _getVaultStatus(_vault, _normalizationFactor);
        require(!isDust, "C22");

        return (liquidateAmount, collateralToPay);
    }

    /**
     * @notice redeem uniswap v3 position in a vault for its constituent eth and wPowerPerp
     * @notice this will increase vault collateral by the amount of eth, and decrease debt by the amount of wPowerPerp
     * @dev will be executed before liquidation if there's an NFT in the vault
     * @dev pays a 2% bounty to the liquidator if called by liquidate()
     * @dev will update the vault memory in-place
     * @param _vault the Vault memory to update
     * @param _owner account to send any excess
     * @param _vaultId id of the vault to reduce debt on
     * @param _payBounty true if paying caller 2% bounty
     * @return bounty amount of bounty paid for liquidator
     */
    function _reduceDebt(
        VaultLib.Vault memory _vault,
        address _owner,
        uint256 _vaultId,
        bool _payBounty
    ) internal returns (uint256) {
        uint256 nftId = _vault.NftCollateralId;
        if (nftId == 0) return 0;

        (uint256 withdrawnEthAmount, uint256 withdrawnWPowerPerpAmount) = _redeemUniToken(nftId);

        // change weth back to eth
        if (withdrawnEthAmount > 0) IWETH9(weth).withdraw(withdrawnEthAmount);

        (uint256 burnAmount, uint256 excess, uint256 bounty) = _getReduceDebtResultInVault(
            _vault,
            withdrawnEthAmount,
            withdrawnWPowerPerpAmount,
            _payBounty
        );

        if (excess > 0) IWPowerPerp(wPowerPerp).transfer(_owner, excess);
        if (burnAmount > 0) IWPowerPerp(wPowerPerp).burn(address(this), burnAmount);

        emit ReduceDebt(
            msg.sender,
            _vaultId,
            withdrawnEthAmount,
            withdrawnWPowerPerpAmount,
            burnAmount,
            excess,
            bounty
        );

        return bounty;
    }

    /**
     * @notice pay fee recipient
     * @dev pay in eth from either the vault or the deposit amount
     * @param _vault the Vault memory to update
     * @param _wPowerPerpAmount the amount of wPowerPerpAmount minting
     * @param _depositAmount the amount of eth depositing or withdrawing
     * @return the amount of actual deposited eth into the vault, this is less than the original amount if a fee was taken
     */
    function _getFee(
        VaultLib.Vault memory _vault,
        uint256 _wPowerPerpAmount,
        uint256 _depositAmount
    ) internal view returns (uint256, uint256) {
        uint256 cachedFeeRate = feeRate;
        if (cachedFeeRate == 0) return (uint256(0), _depositAmount);
        uint256 depositAmountAfterFee;
        uint256 ethEquivalentMinted = Power2Base._getDebtValueInEth(
            _wPowerPerpAmount,
            oracle,
            wPowerPerpPool,
            wPowerPerp,
            weth
        );
        uint256 feeAmount = ethEquivalentMinted.mul(cachedFeeRate).div(10000);

        // if fee can be paid from deposited collateral, pay from _depositAmount
        if (_depositAmount > feeAmount) {
            depositAmountAfterFee = _depositAmount.sub(feeAmount);
            // if not, adjust the vault to pay from the vault collateral
        } else {
            _vault.removeEthCollateral(feeAmount);
            depositAmountAfterFee = _depositAmount;
        }
        //return the fee and deposit amount, which has only been reduced by a fee if it is paid out of the deposit amount
        return (feeAmount, depositAmountAfterFee);
    }

    /**
     * @notice write vault to storage
     * @dev writes to vaults mapping
     */
    function _writeVault(uint256 _vaultId, VaultLib.Vault memory _vault) private {
        vaults[_vaultId] = _vault;
    }

    /**
     * @dev redeem a uni position token and get back wPowerPerp and eth
     * @param _uniTokenId uniswap v3 position token id
     * @return wethAmount amount of weth withdrawn from uniswap
     * @return wPowerPerpAmount amount of wPowerPerp withdrawn from uniswap
     */
    function _redeemUniToken(uint256 _uniTokenId) internal returns (uint256, uint256) {
        INonfungiblePositionManager positionManager = INonfungiblePositionManager(uniswapPositionManager);

        (, , uint128 liquidity, , ) = VaultLib._getUniswapPositionInfo(uniswapPositionManager, _uniTokenId);

        // prepare parameters to withdraw liquidity from uniswap v3 position manager
        INonfungiblePositionManager.DecreaseLiquidityParams memory decreaseParams = INonfungiblePositionManager
            .DecreaseLiquidityParams({
                tokenId: _uniTokenId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        positionManager.decreaseLiquidity(decreaseParams);

        // withdraw max amount of weth and wPowerPerp from uniswap
        INonfungiblePositionManager.CollectParams memory collectParams = INonfungiblePositionManager.CollectParams({
            tokenId: _uniTokenId,
            recipient: address(this),
            amount0Max: uint128(-1),
            amount1Max: uint128(-1)
        });

        (uint256 collectedToken0, uint256 collectedToken1) = positionManager.collect(collectParams);

        return isWethToken0 ? (collectedToken0, collectedToken1) : (collectedToken1, collectedToken0);
    }

    /**
     * @notice update the normalization factor as a way to pay in-kind funding
     * @dev the normalization factor scales amount of debt that must be repaid, effecting an interest rate paid between long and short positions
     * @return new normalization factor
     **/
    function _applyFunding() internal returns (uint256) {
        // only update the norm factor once per block
        if (lastFundingUpdateTimestamp == block.timestamp) return normalizationFactor;

        uint256 newNormalizationFactor = _getNewNormalizationFactor();

        emit NormalizationFactorUpdated(
            normalizationFactor,
            newNormalizationFactor,
            lastFundingUpdateTimestamp,
            block.timestamp
        );

        // the following will be batch into 1 SSTORE because of type uint128
        normalizationFactor = newNormalizationFactor.toUint128();
        lastFundingUpdateTimestamp = block.timestamp.toUint128();

        return newNormalizationFactor;
    }

    /**
     * @dev calculate new normalization factor base on the current timestamp
     * @return new normalization factor if funding happens in the current block
     */
    function _getNewNormalizationFactor() internal view returns (uint256) {
        uint32 period = block.timestamp.sub(lastFundingUpdateTimestamp).toUint32();

        if (period == 0) {
            return normalizationFactor;
        }

        // make sure we use the same period for mark and index
        uint32 periodForOracle = _getConsistentPeriodForOracle(period);

        // avoid reading normalizationFactor from storage multiple times
        uint256 cacheNormFactor = normalizationFactor;

        uint256 mark = Power2Base._getDenormalizedMark(
            periodForOracle,
            oracle,
            wPowerPerpPool,
            ethQuoteCurrencyPool,
            weth,
            quoteCurrency,
            wPowerPerp,
            cacheNormFactor
        );
        uint256 index = Power2Base._getIndex(periodForOracle, oracle, ethQuoteCurrencyPool, weth, quoteCurrency);

        //the fraction of the funding period. used to compound the funding rate
        int128 rFunding = ABDKMath64x64.divu(period, FUNDING_PERIOD);

        // floor mark to be at least LOWER_MARK_RATIO of index
        uint256 lowerBound = index.mul(LOWER_MARK_RATIO).div(ONE);
        if (mark < lowerBound) {
            mark = lowerBound;
        } else {
            // cap mark to be at most UPPER_MARK_RATIO of index
            uint256 upperBound = index.mul(UPPER_MARK_RATIO).div(ONE);
            if (mark > upperBound) mark = upperBound;
        }

        // normFactor(new) = multiplier * normFactor(old)
        // multiplier = (index/mark)^rFunding
        // x^r = n^(log_n(x) * r)
        // multiplier = 2^( log2(index/mark) * rFunding )

        int128 base = ABDKMath64x64.divu(index, mark);
        int128 logTerm = ABDKMath64x64.log_2(base).mul(rFunding);
        int128 multiplier = logTerm.exp_2();
        return multiplier.mulu(cacheNormFactor);
    }

    /**
     * @notice check if vault has enough collateral and is not a dust vault
     * @dev revert if vault has insufficient collateral or is a dust vault
     * @param _vault the Vault memory to update
     * @param _normalizationFactor normalization factor
     */
    function _checkVault(VaultLib.Vault memory _vault, uint256 _normalizationFactor) internal view {
        (bool isSafe, bool isDust) = _getVaultStatus(_vault, _normalizationFactor);
        require(isSafe, "C24");
        require(!isDust, "C22");
    }

    /**
     * @notice check that the vault has enough collateral
     * @param _vault in-memory vault
     * @param _normalizationFactor normalization factor
     * @return true if the vault is properly collateralized
     */
    function _isVaultSafe(VaultLib.Vault memory _vault, uint256 _normalizationFactor) internal view returns (bool) {
        (bool isSafe, ) = _getVaultStatus(_vault, _normalizationFactor);
        return isSafe;
    }

    /**
     * @notice return if the vault is properly collateralized and if it is a dust vault
     * @param _vault the Vault memory to update
     * @param _normalizationFactor normalization factor
     * @return true if the vault is safe
     * @return true if the vault is a dust vault
     */
    function _getVaultStatus(VaultLib.Vault memory _vault, uint256 _normalizationFactor)
        internal
        view
        returns (bool, bool)
    {
        uint256 scaledEthPrice = Power2Base._getScaledTwap(
            oracle,
            ethQuoteCurrencyPool,
            weth,
            quoteCurrency,
            TWAP_PERIOD,
            true // do not call more than maximum period so it does not revert
        );
        return
            VaultLib.getVaultStatus(
                _vault,
                uniswapPositionManager,
                _normalizationFactor,
                scaledEthPrice,
                MIN_COLLATERAL,
                IOracle(oracle).getTimeWeightedAverageTickSafe(wPowerPerpPool, TWAP_PERIOD),
                isWethToken0
            );
    }

    /**
     * @notice get the expected excess, burnAmount and bounty if Uniswap position token got burned
     * @dev this function will update the vault memory in-place
     * @return burnAmount amount of wPowerPerp that should be burned
     * @return wPowerPerpExcess amount of wPowerPerp that should be send to the vault owner
     * @return bounty amount of bounty should be paid out to caller
     */
    function _getReduceDebtResultInVault(
        VaultLib.Vault memory _vault,
        uint256 nftEthAmount,
        uint256 nftWPowerperpAmount,
        bool _payBounty
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 bounty;
        if (_payBounty) bounty = _getReduceDebtBounty(nftEthAmount, nftWPowerperpAmount);

        uint256 burnAmount = nftWPowerperpAmount;
        uint256 wPowerPerpExcess;

        if (nftWPowerperpAmount > _vault.shortAmount) {
            wPowerPerpExcess = nftWPowerperpAmount.sub(_vault.shortAmount);
            burnAmount = _vault.shortAmount;
        }

        _vault.removeShort(burnAmount);
        _vault.removeUniNftCollateral();
        _vault.addEthCollateral(nftEthAmount);
        _vault.removeEthCollateral(bounty);

        return (burnAmount, wPowerPerpExcess, bounty);
    }

    /**
     * @notice get how much bounty you can get by helping a vault reducing the debt.
     * @dev bounty is 2% of the total value of the position token
     * @param _ethWithdrawn amount of eth withdrawn from uniswap by redeeming the position token
     * @param _wPowerPerpReduced amount of wPowerPerp withdrawn from uniswap by redeeming the position token
     */
    function _getReduceDebtBounty(uint256 _ethWithdrawn, uint256 _wPowerPerpReduced) internal view returns (uint256) {
        return
            Power2Base
                ._getDebtValueInEth(_wPowerPerpReduced, oracle, wPowerPerpPool, wPowerPerp, weth)
                .add(_ethWithdrawn)
                .mul(REDUCE_DEBT_BOUNTY)
                .div(ONE);
    }

    /**
     * @notice get the expected wPowerPerp needed to liquidate a vault.
     * @dev a liquidator cannot liquidate more than half of a vault, unless only liquidating half of the debt will make the vault a "dust vault"
     * @dev a liquidator cannot take out more collateral than the vault holds
     * @param _maxWPowerPerpAmount the max amount of wPowerPerp willing to pay
     * @param _vaultShortAmount the amount of short in the vault
     * @param _maxWPowerPerpAmount the amount of collateral in the vault
     * @return finalLiquidateAmount the amount that should be liquidated. This amount can be higher than _maxWPowerPerpAmount, which should be checked
     * @return collateralToPay final amount of collateral paying out to the liquidator
     */
    function _getLiquidationResult(
        uint256 _maxWPowerPerpAmount,
        uint256 _vaultShortAmount,
        uint256 _vaultCollateralAmount
    ) internal view returns (uint256, uint256) {
        // try limiting liquidation amount to half of the vault debt
        (uint256 finalLiquidateAmount, uint256 collateralToPay) = _getSingleLiquidationAmount(
            _maxWPowerPerpAmount,
            _vaultShortAmount.div(2)
        );

        if (_vaultCollateralAmount > collateralToPay) {
            if (_vaultCollateralAmount.sub(collateralToPay) < MIN_COLLATERAL) {
                // the vault is left with dust after liquidation, allow liquidating full vault
                // calculate the new liquidation amount and collateral again based on the new limit
                (finalLiquidateAmount, collateralToPay) = _getSingleLiquidationAmount(
                    _maxWPowerPerpAmount,
                    _vaultShortAmount
                );
            }
        }

        // check if final collateral to pay is greater than vault amount.
        // if so the system only pays out the amount the vault has, which may not be profitable
        if (collateralToPay > _vaultCollateralAmount) {
            // force liquidator to pay full debt amount
            finalLiquidateAmount = _vaultShortAmount;
            collateralToPay = _vaultCollateralAmount;
        }

        return (finalLiquidateAmount, collateralToPay);
    }

    /**
     * @notice determine how much wPowerPerp to liquidate, and how much collateral to return
     * @param _maxInputWAmount maximum wPowerPerp amount liquidator is willing to repay
     * @param _maxLiquidatableWAmount maximum wPowerPerp amount a liquidator is allowed to repay
     * @return finalWAmountToLiquidate amount of wPowerPerp the liquidator will burn
     * @return collateralToPay total collateral the liquidator will get
     */
    function _getSingleLiquidationAmount(uint256 _maxInputWAmount, uint256 _maxLiquidatableWAmount)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 finalWAmountToLiquidate = _maxInputWAmount > _maxLiquidatableWAmount
            ? _maxLiquidatableWAmount
            : _maxInputWAmount;

        uint256 collateralToPay = Power2Base._getDebtValueInEth(
            finalWAmountToLiquidate,
            oracle,
            wPowerPerpPool,
            wPowerPerp,
            weth
        );

        // add 10% bonus for liquidators
        collateralToPay = collateralToPay.add(collateralToPay.mul(LIQUIDATION_BOUNTY).div(ONE));

        return (finalWAmountToLiquidate, collateralToPay);
    }

    /**
     * @notice get a period can be used to request a twap for 2 uniswap v3 pools
     * @dev if the period is greater than min(max_pool_1, max_pool_2), return min(max_pool_1, max_pool_2)
     * @param _period max period that we intend to use
     * @return fair period not greator than _period to be used for both pools.
     */
    function _getConsistentPeriodForOracle(uint32 _period) internal view returns (uint32) {
        uint32 maxPeriodPool1 = IOracle(oracle).getMaxPeriod(ethQuoteCurrencyPool);
        uint32 maxPeriodPool2 = IOracle(oracle).getMaxPeriod(wPowerPerpPool);

        uint32 maxSafePeriod = maxPeriodPool1 > maxPeriodPool2 ? maxPeriodPool2 : maxPeriodPool1;
        return _period > maxSafePeriod ? maxSafePeriod : _period;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol';

import './IPoolInitializer.sol';
import './IERC721Permit.sol';
import './IPeripheryPayments.sol';
import './IPeripheryImmutableState.sol';
import '../libraries/PoolAddress.sol';

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWPowerPerp is IERC20 {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IShortPowerPerp is IERC721 {
    function nextId() external view returns (uint256);

    function mintNFT(address recipient) external returns (uint256 _newId);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

interface IOracle {
    function getHistoricalTwap(
        address _pool,
        address _base,
        address _quote,
        uint32 _period,
        uint32 _periodToHistoricPrice
    ) external view returns (uint256);

    function getTwap(
        address _pool,
        address _base,
        address _quote,
        uint32 _period,
        bool _checkPeriod
    ) external view returns (uint256);

    function getMaxPeriod(address _pool) external view returns (uint32);

    function getTimeWeightedAverageTickSafe(address _pool, uint32 _period)
        external
        view
        returns (int24 timeWeightedAverageTick);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
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

pragma solidity ^0.7.0;

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

    constructor () {
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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 * Copyright (c) 2019, ABDK Consulting
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * All advertising materials mentioning features or use of this software must display the following acknowledgement: This product includes software developed by ABDK Consulting.
 * Neither the name of ABDK Consulting nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED BY ABDK CONSULTING ''AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL ABDK CONSULTING BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

pragma solidity ^0.7.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 *
 * Commit used - 16d7e1dd8628dfa2f88d5dadab731df7ada70bdd
 * Copied from - https://github.com/abdk-consulting/abdk-libraries-solidity/tree/v2.4
 * Changes - some function visibility switched to public, solidity version set to 0.7.x
 * Changes (cont) - revert strings added
 * solidity version set to ^0.7.0
 */
library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     * Minimum value signed 64.64-bit fixed point number may have.
     * Minimum value signed 64.64-bit fixed point number may have.
     * -2^127
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     * Maximum value signed 64.64-bit fixed point number may have.
     * Maximum value signed 64.64-bit fixed point number may have.
     * 2^127-1
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function mul(int128 x, int128 y) internal pure returns (int128) {
        int256 result = (int256(x) * y) >> 64;
        require(result >= MIN_64x64 && result <= MAX_64x64, "MUL-OVUF");
        return int128(result);
    }

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) return 0;

        require(x >= 0, "MULU-X0");

        uint256 lo = (uint256(x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
        uint256 hi = uint256(x) * (y >> 128);

        require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "MULU-OF1");
        hi <<= 64;

        require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo, "MULU-OF2");
        return hi + lo;
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu(uint256 x, uint256 y) public pure returns (int128) {
        require(y != 0, "DIVU-INF");
        uint128 result = divuu(x, y);
        require(result <= uint128(MAX_64x64), "DIVU-OF");
        return int128(result);
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function log_2(int128 x) public pure returns (int128) {
        require(x > 0, "LOG_2-X0");

        int256 msb = 0;
        int256 xc = x;
        if (xc >= 0x10000000000000000) {
            xc >>= 64;
            msb += 64;
        }
        if (xc >= 0x100000000) {
            xc >>= 32;
            msb += 32;
        }
        if (xc >= 0x10000) {
            xc >>= 16;
            msb += 16;
        }
        if (xc >= 0x100) {
            xc >>= 8;
            msb += 8;
        }
        if (xc >= 0x10) {
            xc >>= 4;
            msb += 4;
        }
        if (xc >= 0x4) {
            xc >>= 2;
            msb += 2;
        }
        if (xc >= 0x2) msb += 1; // No need to shift xc anymore

        int256 result = (msb - 64) << 64;
        uint256 ux = uint256(x) << uint256(127 - msb);
        for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
            ux *= ux;
            uint256 b = ux >> 255;
            ux >>= 127 + b;
            result += bit * int256(b);
        }

        return int128(result);
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp_2(int128 x) public pure returns (int128) {
        require(x < 0x400000000000000000, "EXP_2-OF"); // Overflow

        if (x < -0x400000000000000000) return 0; // Underflow

        uint256 result = 0x80000000000000000000000000000000;

        if (x & 0x8000000000000000 > 0) result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
        if (x & 0x4000000000000000 > 0) result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
        if (x & 0x2000000000000000 > 0) result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
        if (x & 0x1000000000000000 > 0) result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
        if (x & 0x800000000000000 > 0) result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
        if (x & 0x400000000000000 > 0) result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
        if (x & 0x200000000000000 > 0) result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
        if (x & 0x100000000000000 > 0) result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
        if (x & 0x80000000000000 > 0) result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
        if (x & 0x40000000000000 > 0) result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
        if (x & 0x20000000000000 > 0) result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
        if (x & 0x10000000000000 > 0) result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
        if (x & 0x8000000000000 > 0) result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
        if (x & 0x4000000000000 > 0) result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
        if (x & 0x2000000000000 > 0) result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
        if (x & 0x1000000000000 > 0) result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
        if (x & 0x800000000000 > 0) result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
        if (x & 0x400000000000 > 0) result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
        if (x & 0x200000000000 > 0) result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
        if (x & 0x100000000000 > 0) result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
        if (x & 0x80000000000 > 0) result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
        if (x & 0x40000000000 > 0) result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
        if (x & 0x20000000000 > 0) result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
        if (x & 0x10000000000 > 0) result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
        if (x & 0x8000000000 > 0) result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
        if (x & 0x4000000000 > 0) result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
        if (x & 0x2000000000 > 0) result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
        if (x & 0x1000000000 > 0) result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
        if (x & 0x800000000 > 0) result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
        if (x & 0x400000000 > 0) result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
        if (x & 0x200000000 > 0) result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
        if (x & 0x100000000 > 0) result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
        if (x & 0x80000000 > 0) result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
        if (x & 0x40000000 > 0) result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
        if (x & 0x20000000 > 0) result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
        if (x & 0x10000000 > 0) result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
        if (x & 0x8000000 > 0) result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
        if (x & 0x4000000 > 0) result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
        if (x & 0x2000000 > 0) result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
        if (x & 0x1000000 > 0) result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
        if (x & 0x800000 > 0) result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
        if (x & 0x400000 > 0) result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
        if (x & 0x200000 > 0) result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
        if (x & 0x100000 > 0) result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
        if (x & 0x80000 > 0) result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
        if (x & 0x40000 > 0) result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
        if (x & 0x20000 > 0) result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
        if (x & 0x10000 > 0) result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
        if (x & 0x8000 > 0) result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
        if (x & 0x4000 > 0) result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
        if (x & 0x2000 > 0) result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
        if (x & 0x1000 > 0) result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
        if (x & 0x800 > 0) result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
        if (x & 0x400 > 0) result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
        if (x & 0x200 > 0) result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
        if (x & 0x100 > 0) result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
        if (x & 0x80 > 0) result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
        if (x & 0x40 > 0) result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
        if (x & 0x20 > 0) result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
        if (x & 0x10 > 0) result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
        if (x & 0x8 > 0) result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
        if (x & 0x4 > 0) result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
        if (x & 0x2 > 0) result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
        if (x & 0x1 > 0) result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;

        result >>= uint256(63 - (x >> 64));
        require(result <= uint256(MAX_64x64));

        return int128(result);
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return unsigned 64.64-bit fixed point number
     */
    function divuu(uint256 x, uint256 y) private pure returns (uint128) {
        require(y != 0);

        uint256 result;

        if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) result = (x << 64) / y;
        else {
            uint256 msb = 192;
            uint256 xc = x >> 192;
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
            require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "DIVUU-OF1");

            uint256 hi = result * (y >> 128);
            uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 xh = x >> 192;
            uint256 xl = x << 64;

            if (xl < lo) xh -= 1;
            xl -= lo; // We rely on overflow behavior here
            lo = hi << 128;
            if (xl < lo) xh -= 1;
            xl -= lo; // We rely on overflow behavior here

            assert(xh == hi >> 128);

            result += xl / y;
        }

        require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "DIVUU-OF2");
        return uint128(result);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

//interface
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

//lib
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/SqrtPriceMath.sol";
import {Uint256Casting} from "./Uint256Casting.sol";

/**
 * Error code:
 * V1: Vault already had nft
 * V2: Vault has no NFT
 */
library VaultLib {
    using SafeMath for uint256;
    using Uint256Casting for uint256;

    uint256 constant ONE_ONE = 1e36;

    // the collateralization ratio (CR) is checked with the numerator and denominator separately
    // a user is safe if - collateral value >= (COLLAT_RATIO_NUMER/COLLAT_RATIO_DENOM)* debt value
    uint256 public constant CR_NUMERATOR = 3;
    uint256 public constant CR_DENOMINATOR = 2;

    struct Vault {
        // the address that can update the vault
        address operator;
        // uniswap position token id deposited into the vault as collateral
        // 2^32 is 4,294,967,296, which means the vault structure will work with up to 4 billion positions
        uint32 NftCollateralId;
        // amount of eth (wei) used in the vault as collateral
        // 2^96 / 1e18 = 79,228,162,514, which means a vault can store up to 79 billion eth
        // when we need to do calculations, we always cast this number to uint256 to avoid overflow
        uint96 collateralAmount;
        // amount of wPowerPerp minted from the vault
        uint128 shortAmount;
    }

    /**
     * @notice add eth collateral to a vault
     * @param _vault in-memory vault
     * @param _amount amount of eth to add
     */
    function addEthCollateral(Vault memory _vault, uint256 _amount) internal pure {
        _vault.collateralAmount = uint256(_vault.collateralAmount).add(_amount).toUint96();
    }

    /**
     * @notice add uniswap position token collateral to a vault
     * @param _vault in-memory vault
     * @param _tokenId uniswap position token id
     */
    function addUniNftCollateral(Vault memory _vault, uint256 _tokenId) internal pure {
        require(_vault.NftCollateralId == 0, "V1");
        require(_tokenId != 0, "C23");
        _vault.NftCollateralId = _tokenId.toUint32();
    }

    /**
     * @notice remove eth collateral from a vault
     * @param _vault in-memory vault
     * @param _amount amount of eth to remove
     */
    function removeEthCollateral(Vault memory _vault, uint256 _amount) internal pure {
        _vault.collateralAmount = uint256(_vault.collateralAmount).sub(_amount).toUint96();
    }

    /**
     * @notice remove uniswap position token collateral from a vault
     * @param _vault in-memory vault
     */
    function removeUniNftCollateral(Vault memory _vault) internal pure {
        require(_vault.NftCollateralId != 0, "V2");
        _vault.NftCollateralId = 0;
    }

    /**
     * @notice add debt to vault
     * @param _vault in-memory vault
     * @param _amount amount of debt to add
     */
    function addShort(Vault memory _vault, uint256 _amount) internal pure {
        _vault.shortAmount = uint256(_vault.shortAmount).add(_amount).toUint128();
    }

    /**
     * @notice remove debt from vault
     * @param _vault in-memory vault
     * @param _amount amount of debt to remove
     */
    function removeShort(Vault memory _vault, uint256 _amount) internal pure {
        _vault.shortAmount = uint256(_vault.shortAmount).sub(_amount).toUint128();
    }

    /**
     * @notice check if a vault is properly collateralized
     * @param _vault the vault we want to check
     * @param _positionManager address of the uniswap position manager
     * @param _normalizationFactor current _normalizationFactor
     * @param _ethQuoteCurrencyPrice current eth price scaled by 1e18
     * @param _minCollateral minimum collateral that needs to be in a vault
     * @param _wsqueethPoolTick current price tick for wsqueeth pool
     * @param _isWethToken0 whether weth is token0 in the wsqueeth pool
     * @return true if the vault is sufficiently collateralized
     * @return true if the vault is considered as a dust vault
     */
    function getVaultStatus(
        Vault memory _vault,
        address _positionManager,
        uint256 _normalizationFactor,
        uint256 _ethQuoteCurrencyPrice,
        uint256 _minCollateral,
        int24 _wsqueethPoolTick,
        bool _isWethToken0
    ) internal view returns (bool, bool) {
        if (_vault.shortAmount == 0) return (true, false);

        uint256 debtValueInETH = uint256(_vault.shortAmount).mul(_normalizationFactor).mul(_ethQuoteCurrencyPrice).div(
            ONE_ONE
        );
        uint256 totalCollateral = _getEffectiveCollateral(
            _vault,
            _positionManager,
            _normalizationFactor,
            _ethQuoteCurrencyPrice,
            _wsqueethPoolTick,
            _isWethToken0
        );

        bool isDust = totalCollateral < _minCollateral;
        bool isAboveWater = totalCollateral.mul(CR_DENOMINATOR) >= debtValueInETH.mul(CR_NUMERATOR);
        return (isAboveWater, isDust);
    }

    /**
     * @notice get the total effective collateral of a vault, which is:
     *         collateral amount + uniswap position token equivelent amount in eth
     * @param _vault the vault we want to check
     * @param _positionManager address of the uniswap position manager
     * @param _normalizationFactor current _normalizationFactor
     * @param _ethQuoteCurrencyPrice current eth price scaled by 1e18
     * @param _wsqueethPoolTick current price tick for wsqueeth pool
     * @param _isWethToken0 whether weth is token0 in the wsqueeth pool
     * @return the total worth of collateral in the vault
     */
    function _getEffectiveCollateral(
        Vault memory _vault,
        address _positionManager,
        uint256 _normalizationFactor,
        uint256 _ethQuoteCurrencyPrice,
        int24 _wsqueethPoolTick,
        bool _isWethToken0
    ) internal view returns (uint256) {
        if (_vault.NftCollateralId == 0) return _vault.collateralAmount;

        // the user has deposited uniswap position token as collateral, see how much eth / wSqueeth the uniswap position token has
        (uint256 nftEthAmount, uint256 nftWsqueethAmount) = _getUniPositionBalances(
            _positionManager,
            _vault.NftCollateralId,
            _wsqueethPoolTick,
            _isWethToken0
        );
        // convert squeeth amount from uniswap position token as equivalent amount of collateral
        uint256 wSqueethIndexValueInEth = nftWsqueethAmount.mul(_normalizationFactor).mul(_ethQuoteCurrencyPrice).div(
            ONE_ONE
        );
        // add eth value from uniswap position token as collateral
        return nftEthAmount.add(wSqueethIndexValueInEth).add(_vault.collateralAmount);
    }

    /**
     * @notice determine how much eth / wPowerPerp the uniswap position contains
     * @param _positionManager address of the uniswap position manager
     * @param _tokenId uniswap position token id
     * @param _wPowerPerpPoolTick current price tick
     * @param _isWethToken0 whether weth is token0 in the pool
     * @return ethAmount the eth amount this LP token contains
     * @return wPowerPerpAmount the wPowerPerp amount this LP token contains
     */
    function _getUniPositionBalances(
        address _positionManager,
        uint256 _tokenId,
        int24 _wPowerPerpPoolTick,
        bool _isWethToken0
    ) internal view returns (uint256 ethAmount, uint256 wPowerPerpAmount) {
        (
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = _getUniswapPositionInfo(_positionManager, _tokenId);
        (uint256 amount0, uint256 amount1) = _getToken0Token1Balances(
            tickLower,
            tickUpper,
            _wPowerPerpPoolTick,
            liquidity
        );

        return
            _isWethToken0
                ? (amount0 + tokensOwed0, amount1 + tokensOwed1)
                : (amount1 + tokensOwed1, amount0 + tokensOwed0);
    }

    /**
     * @notice get uniswap position token info
     * @param _positionManager address of the uniswap position position manager
     * @param _tokenId uniswap position token id
     * @return tickLower lower tick of the position
     * @return tickUpper upper tick of the position
     * @return liquidity raw liquidity amount of the position
     * @return tokensOwed0 amount of token 0 can be collected as fee
     * @return tokensOwed1 amount of token 1 can be collected as fee
     */
    function _getUniswapPositionInfo(address _positionManager, uint256 _tokenId)
        internal
        view
        returns (
            int24,
            int24,
            uint128,
            uint128,
            uint128
        )
    {
        INonfungiblePositionManager positionManager = INonfungiblePositionManager(_positionManager);
        (
            ,
            ,
            ,
            ,
            ,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            ,
            ,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = positionManager.positions(_tokenId);
        return (tickLower, tickUpper, liquidity, tokensOwed0, tokensOwed1);
    }

    /**
     * @notice get balances of token0 / token1 in a uniswap position
     * @dev knowing liquidity, tick range, and current tick gives balances
     * @param _tickLower address of the uniswap position manager
     * @param _tickUpper uniswap position token id
     * @param _tick current price tick used for calculation
     * @return amount0 the amount of token0 in the uniswap position token
     * @return amount1 the amount of token1 in the uniswap position token
     */
    function _getToken0Token1Balances(
        int24 _tickLower,
        int24 _tickUpper,
        int24 _tick,
        uint128 _liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        // get the current price and tick from wPowerPerp pool
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(_tick);

        // the following line is copied from the _modifyPosition function implemented by Uniswap core
        // we use the same logic to determine how much token0, token1 equals to given "liquidity"
        // https://github.com/Uniswap/uniswap-v3-core/blob/b2c5555d696428c40c4b236069b3528b2317f3c1/contracts/UniswapV3Pool.sol#L306

        // use these 2 functions directly, because liquidity is always positive
        // getAmount0Delta: https://github.com/Uniswap/uniswap-v3-core/blob/b2c5555d696428c40c4b236069b3528b2317f3c1/contracts/libraries/SqrtPriceMath.sol#L209
        // getAmount1Delta: https://github.com/Uniswap/uniswap-v3-core/blob/b2c5555d696428c40c4b236069b3528b2317f3c1/contracts/libraries/SqrtPriceMath.sol#L225

        if (_tick < _tickLower) {
            amount0 = SqrtPriceMath.getAmount0Delta(
                TickMath.getSqrtRatioAtTick(_tickLower),
                TickMath.getSqrtRatioAtTick(_tickUpper),
                _liquidity,
                true
            );
        } else if (_tick < _tickUpper) {
            amount0 = SqrtPriceMath.getAmount0Delta(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(_tickUpper),
                _liquidity,
                true
            );
            amount1 = SqrtPriceMath.getAmount1Delta(
                TickMath.getSqrtRatioAtTick(_tickLower),
                sqrtPriceX96,
                _liquidity,
                true
            );
        } else {
            amount1 = SqrtPriceMath.getAmount1Delta(
                TickMath.getSqrtRatioAtTick(_tickLower),
                TickMath.getSqrtRatioAtTick(_tickUpper),
                _liquidity,
                true
            );
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

library Uint256Casting {
    /**
     * @notice cast a uint256 to a uint128, revert on overflow
     * @param y the uint256 to be downcasted
     * @return z the downcasted integer, now type uint128
     */
    function toUint128(uint256 y) internal pure returns (uint128 z) {
        require((z = uint128(y)) == y, "OF128");
    }

    /**
     * @notice cast a uint256 to a uint96, revert on overflow
     * @param y the uint256 to be downcasted
     * @return z the downcasted integer, now type uint96
     */
    function toUint96(uint256 y) internal pure returns (uint96 z) {
        require((z = uint96(y)) == y, "OF96");
    }

    /**
     * @notice cast a uint256 to a uint32, revert on overflow
     * @param y the uint256 to be downcasted
     * @return z the downcasted integer, now type uint32
     */
    function toUint32(uint256 y) internal pure returns (uint32 z) {
        require((z = uint32(y)) == y, "OF32");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

//interface
import {IOracle} from "../interfaces/IOracle.sol";

//lib
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

library Power2Base {
    using SafeMath for uint256;

    uint32 private constant TWAP_PERIOD = 5 minutes;
    uint256 private constant INDEX_SCALE = 1e4;
    uint256 private constant ONE = 1e18;
    uint256 private constant ONE_ONE = 1e36;

    /**
     * @notice return the scaled down index of the power perp in USD, scaled by 18 decimals
     * @param _period period of time for the twap in seconds (cannot be longer than maximum period for the pool)
     * @param _oracle oracle address
     * @param _ethQuoteCurrencyPool uniswap v3 pool for weth / quoteCurrency
     * @param _weth weth address
     * @param _quoteCurrency quoteCurrency address
     * @return for squeeth, return ethPrice^2
     */
    function _getIndex(
        uint32 _period,
        address _oracle,
        address _ethQuoteCurrencyPool,
        address _weth,
        address _quoteCurrency
    ) internal view returns (uint256) {
        uint256 ethQuoteCurrencyPrice = _getScaledTwap(
            _oracle,
            _ethQuoteCurrencyPool,
            _weth,
            _quoteCurrency,
            _period,
            false
        );
        return ethQuoteCurrencyPrice.mul(ethQuoteCurrencyPrice).div(ONE);
    }

    /**
     * @notice return the unscaled index of the power perp in USD, scaled by 18 decimals
     * @param _period period of time for the twap in seconds (cannot be longer than maximum period for the pool)
     * @param _oracle oracle address
     * @param _ethQuoteCurrencyPool uniswap v3 pool for weth / quoteCurrency
     * @param _weth weth address
     * @param _quoteCurrency quoteCurrency address
     * @return for squeeth, return ethPrice^2
     */
    function _getUnscaledIndex(
        uint32 _period,
        address _oracle,
        address _ethQuoteCurrencyPool,
        address _weth,
        address _quoteCurrency
    ) internal view returns (uint256) {
        uint256 ethQuoteCurrencyPrice = _getTwap(_oracle, _ethQuoteCurrencyPool, _weth, _quoteCurrency, _period, false);
        return ethQuoteCurrencyPrice.mul(ethQuoteCurrencyPrice).div(ONE);
    }

    /**
     * @notice return the mark price of power perp in quoteCurrency, scaled by 18 decimals
     * @param _period period of time for the twap in seconds (cannot be longer than maximum period for the pool)
     * @param _oracle oracle address
     * @param _wSqueethEthPool uniswap v3 pool for wSqueeth / weth
     * @param _ethQuoteCurrencyPool uniswap v3 pool for weth / quoteCurrency
     * @param _weth weth address
     * @param _quoteCurrency quoteCurrency address
     * @param _wSqueeth wSqueeth address
     * @param _normalizationFactor current normalization factor
     * @return for squeeth, return ethPrice * squeethPriceInEth
     */
    function _getDenormalizedMark(
        uint32 _period,
        address _oracle,
        address _wSqueethEthPool,
        address _ethQuoteCurrencyPool,
        address _weth,
        address _quoteCurrency,
        address _wSqueeth,
        uint256 _normalizationFactor
    ) internal view returns (uint256) {
        uint256 ethQuoteCurrencyPrice = _getScaledTwap(
            _oracle,
            _ethQuoteCurrencyPool,
            _weth,
            _quoteCurrency,
            _period,
            false
        );
        uint256 wsqueethEthPrice = _getTwap(_oracle, _wSqueethEthPool, _wSqueeth, _weth, _period, false);

        return wsqueethEthPrice.mul(ethQuoteCurrencyPrice).div(_normalizationFactor);
    }

    /**
     * @notice get the fair collateral value for a _debtAmount of wSqueeth
     * @dev the actual amount liquidator can get should have a 10% bonus on top of this value.
     * @param _debtAmount wSqueeth amount paid by liquidator
     * @param _oracle oracle address
     * @param _wSqueethEthPool uniswap v3 pool for wSqueeth / weth
     * @param _wSqueeth wSqueeth address
     * @param _weth weth address
     * @return returns value of debt in ETH
     */
    function _getDebtValueInEth(
        uint256 _debtAmount,
        address _oracle,
        address _wSqueethEthPool,
        address _wSqueeth,
        address _weth
    ) internal view returns (uint256) {
        uint256 wSqueethPrice = _getTwap(_oracle, _wSqueethEthPool, _wSqueeth, _weth, TWAP_PERIOD, false);
        return _debtAmount.mul(wSqueethPrice).div(ONE);
    }

    /**
     * @notice request twap from our oracle, scaled down by INDEX_SCALE
     * @param _oracle oracle address
     * @param _pool uniswap v3 pool address
     * @param _base base currency. to get eth/usd price, eth is base token
     * @param _quote quote currency. to get eth/usd price, usd is the quote currency
     * @param _period number of seconds in the past to start calculating time-weighted average.
     * @param _checkPeriod check that period is not longer than maximum period for the pool to prevent reverts
     * @return twap price scaled down by INDEX_SCALE
     */
    function _getScaledTwap(
        address _oracle,
        address _pool,
        address _base,
        address _quote,
        uint32 _period,
        bool _checkPeriod
    ) internal view returns (uint256) {
        uint256 twap = _getTwap(_oracle, _pool, _base, _quote, _period, _checkPeriod);
        return twap.div(INDEX_SCALE);
    }

    /**
     * @notice request twap from our oracle
     * @dev this will revert if period is > max period for the pool
     * @param _oracle oracle address
     * @param _pool uniswap v3 pool address
     * @param _base base currency. to get eth/quoteCurrency price, eth is base token
     * @param _quote quote currency. to get eth/quoteCurrency price, quoteCurrency is the quote currency
     * @param _period number of seconds in the past to start calculating time-weighted average
     * @param _checkPeriod check that period is not longer than maximum period for the pool to prevent reverts
     * @return human readable price. scaled by 1e18
     */
    function _getTwap(
        address _oracle,
        address _pool,
        address _base,
        address _quote,
        uint32 _period,
        bool _checkPeriod
    ) internal view returns (uint256) {
        // period reaching this point should be check, otherwise might revert
        return IOracle(_oracle).getTwap(_pool, _base, _quote, _period, _checkPeriod);
    }

    /**
     * @notice get the index value of wsqueeth in wei, used when system settles
     * @dev the index of squeeth is ethPrice^2, so each squeeth will need to pay out {ethPrice} eth
     * @param _wsqueethAmount amount of wsqueeth used in settlement
     * @param _indexPriceForSettlement index price for settlement
     * @param _normalizationFactor current normalization factor
     * @return amount in wei that should be paid to the token holder
     */
    function _getLongSettlementValue(
        uint256 _wsqueethAmount,
        uint256 _indexPriceForSettlement,
        uint256 _normalizationFactor
    ) internal pure returns (uint256) {
        return _wsqueethAmount.mul(_normalizationFactor).mul(_indexPriceForSettlement).div(ONE_ONE);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
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

pragma solidity ^0.7.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import './LowGasSafeMath.sol';
import './SafeCast.sol';

import './FullMath.sol';
import './UnsafeMath.sol';
import './FixedPoint96.sol';

/// @title Functions based on Q64.96 sqrt price and liquidity
/// @notice Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
library SqrtPriceMath {
    using LowGasSafeMath for uint256;
    using SafeCast for uint256;

    /// @notice Gets the next sqrt price given a delta of token0
    /// @dev Always rounds up, because in the exact output case (increasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (decreasing price) we need to move the
    /// price less in order to not send too much output.
    /// The most precise formula for this is liquidity * sqrtPX96 / (liquidity +- amount * sqrtPX96),
    /// if this is impossible because of overflow, we calculate liquidity / (liquidity / sqrtPX96 +- amount).
    /// @param sqrtPX96 The starting price, i.e. before accounting for the token0 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token0 to add or remove from virtual reserves
    /// @param add Whether to add or remove the amount of token0
    /// @return The price after adding or removing amount, depending on add
    function getNextSqrtPriceFromAmount0RoundingUp(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // we short circuit amount == 0 because the result is otherwise not guaranteed to equal the input price
        if (amount == 0) return sqrtPX96;
        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;

        if (add) {
            uint256 product;
            if ((product = amount * sqrtPX96) / amount == sqrtPX96) {
                uint256 denominator = numerator1 + product;
                if (denominator >= numerator1)
                    // always fits in 160 bits
                    return uint160(FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator));
            }

            return uint160(UnsafeMath.divRoundingUp(numerator1, (numerator1 / sqrtPX96).add(amount)));
        } else {
            uint256 product;
            // if the product overflows, we know the denominator underflows
            // in addition, we must check that the denominator does not underflow
            require((product = amount * sqrtPX96) / amount == sqrtPX96 && numerator1 > product);
            uint256 denominator = numerator1 - product;
            return FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator).toUint160();
        }
    }

    /// @notice Gets the next sqrt price given a delta of token1
    /// @dev Always rounds down, because in the exact output case (decreasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (increasing price) we need to move the
    /// price less in order to not send too much output.
    /// The formula we compute is within <1 wei of the lossless version: sqrtPX96 +- amount / liquidity
    /// @param sqrtPX96 The starting price, i.e., before accounting for the token1 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token1 to add, or remove, from virtual reserves
    /// @param add Whether to add, or remove, the amount of token1
    /// @return The price after adding or removing `amount`
    function getNextSqrtPriceFromAmount1RoundingDown(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // if we're adding (subtracting), rounding down requires rounding the quotient down (up)
        // in both cases, avoid a mulDiv for most inputs
        if (add) {
            uint256 quotient =
                (
                    amount <= type(uint160).max
                        ? (amount << FixedPoint96.RESOLUTION) / liquidity
                        : FullMath.mulDiv(amount, FixedPoint96.Q96, liquidity)
                );

            return uint256(sqrtPX96).add(quotient).toUint160();
        } else {
            uint256 quotient =
                (
                    amount <= type(uint160).max
                        ? UnsafeMath.divRoundingUp(amount << FixedPoint96.RESOLUTION, liquidity)
                        : FullMath.mulDivRoundingUp(amount, FixedPoint96.Q96, liquidity)
                );

            require(sqrtPX96 > quotient);
            // always fits 160 bits
            return uint160(sqrtPX96 - quotient);
        }
    }

    /// @notice Gets the next sqrt price given an input amount of token0 or token1
    /// @dev Throws if price or liquidity are 0, or if the next price is out of bounds
    /// @param sqrtPX96 The starting price, i.e., before accounting for the input amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountIn How much of token0, or token1, is being swapped in
    /// @param zeroForOne Whether the amount in is token0 or token1
    /// @return sqrtQX96 The price after adding the input amount to token0 or token1
    function getNextSqrtPriceFromInput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountIn,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0);
        require(liquidity > 0);

        // round to make sure that we don't pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountIn, true)
                : getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountIn, true);
    }

    /// @notice Gets the next sqrt price given an output amount of token0 or token1
    /// @dev Throws if price or liquidity are 0 or the next price is out of bounds
    /// @param sqrtPX96 The starting price before accounting for the output amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountOut How much of token0, or token1, is being swapped out
    /// @param zeroForOne Whether the amount out is token0 or token1
    /// @return sqrtQX96 The price after removing the output amount of token0 or token1
    function getNextSqrtPriceFromOutput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountOut,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0);
        require(liquidity > 0);

        // round to make sure that we pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountOut, false)
                : getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountOut, false);
    }

    /// @notice Gets the amount0 delta between two prices
    /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
    /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up or down
    /// @return amount0 Amount of token0 required to cover a position of size liquidity between the two passed prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

        require(sqrtRatioAX96 > 0);

        return
            roundUp
                ? UnsafeMath.divRoundingUp(
                    FullMath.mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96),
                    sqrtRatioAX96
                )
                : FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
    }

    /// @notice Gets the amount1 delta between two prices
    /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up, or down
    /// @return amount1 Amount of token1 required to cover a position of size liquidity between the two passed prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            roundUp
                ? FullMath.mulDivRoundingUp(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96)
                : FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Helper that gets signed token0 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount0 delta
    /// @return amount0 Amount of token0 corresponding to the passed liquidityDelta between the two prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount0) {
        return
            liquidity < 0
                ? -getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
                : getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
    }

    /// @notice Helper that gets signed token1 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount1 delta
    /// @return amount1 Amount of token1 corresponding to the passed liquidityDelta between the two prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount1) {
        return
            liquidity < 0
                ? -getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
                : getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math functions that do not check inputs or outputs
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}