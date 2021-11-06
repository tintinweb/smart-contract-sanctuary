// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "../interfaces/IAggregatorV3Interface.sol";
import "../interfaces/IStableCoin.sol";
import "../interfaces/IJPEGDLock.sol";

/**
 * NFT lending vault
 */
contract NFTVault is AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    event PositionOpened(address owner, uint256 index);
    event Borrowed(address owner, uint256 index, uint256 amount);
    event Repaid(address owner, uint256 index, uint256 amount);
    event PositionClosed(address owner, uint256 index);
    event Liquidated(address liquidator, address owner, uint256 index);
    event Repurchased(address owner, uint256 index);
    event InsuranceExpired(address owner, uint256 index);

    enum BorrowType {
        NOT_CONFIRMED,
        NON_INSURANCE,
        USE_INSURANCE
    }

    struct Position {
        BorrowType borrowType;
        uint256 debtPrincipal;
        uint256 debtPortion;
        uint256 debtAmountForRepurchase;
        uint256 liquidatedAt;
        address liquidator;
    }

    struct Rate {
        uint128 numerator;
        uint128 denominator;
    }

    struct VaultSettings {
        Rate debtInterestApr;
        Rate creditLimitRate;
        Rate liquidationLimitRate;
        Rate valueIncreaseLockRate;
        Rate organizationFeeRate;
        Rate insurancePurchaseRate;
        Rate insuranceLiquidationPenaltyRate;
        uint256 insuraceRepurchaseTimeLimit;
        uint256 borrowAmountCap;
    }

    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");

    bytes32 public constant CUSTOM_NFT_HASH = keccak256("CUSTOM");

    uint256 internal constant SECS_YEAR = 86400 * 365;

    IStableCoin public stablecoin;
    IAggregatorV3Interface public ethAggregator;
    IAggregatorV3Interface public jpegdAggregator;
    IAggregatorV3Interface public floorOracle;
    IJPEGDLock public jpegdLocker;
    IERC721Upgradeable public nftContract;

    bool public daoFloorOverride;
    uint256 public totalPositions;
    uint256 public totalDebtAmount;
    uint256 public totalDebtAccruedAt;
    uint256 public totalFeeCollected;
    uint256 internal totalDebtPortion;

    VaultSettings public settings;

    mapping(uint256 => Position) private positions;
    mapping(uint256 => address) public positionOwner;
    mapping(bytes32 => uint256) public nftTypeValueETH;
    mapping(uint256 => uint256) public nftValueETH;
    mapping(uint256 => bytes32) public nftTypes;
    mapping(uint256 => uint256) public pendingNFTValueETH;

    modifier validNFTIndex(uint256 nftIndex) {
        //The standard OZ ERC721 implementation of ownerOf reverts on a non existing nft isntead of returning address(0)
        require(nftContract.ownerOf(nftIndex) != address(0), "invalid_nft");
        _;
    }

    struct NFTCategoryInitializer {
        //bytes32(0) is floor
        bytes32 hash;
        uint256 valueETH;
        uint256[] nfts;
    }

    function initialize(
        IStableCoin _stablecoin,
        IERC721Upgradeable _nftContract,
        IAggregatorV3Interface _ethAggregator,
        IAggregatorV3Interface _jpegdAggregator,
        IAggregatorV3Interface _floorOracle,
        NFTCategoryInitializer[] memory typeInitializers,
        IJPEGDLock _jpegdLocker,
        VaultSettings memory _settings
    ) external initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        _setupRole(DAO_ROLE, msg.sender);
        _setRoleAdmin(LIQUIDATOR_ROLE, DAO_ROLE);
        _setRoleAdmin(DAO_ROLE, DAO_ROLE);
        _setRoleAdmin(GOVERNANCE_ROLE, DAO_ROLE);

        stablecoin = _stablecoin;
        jpegdLocker = _jpegdLocker;
        ethAggregator = _ethAggregator;
        jpegdAggregator = _jpegdAggregator;
        floorOracle = _floorOracle;
        nftContract = _nftContract;

        settings = _settings;

        for (uint256 i = 0; i < typeInitializers.length; i++) {
            NFTCategoryInitializer memory initializer = typeInitializers[i];
            nftTypeValueETH[initializer.hash] = initializer.valueETH;
            for (uint256 j = 0; j < initializer.nfts.length; j++) {
                nftTypes[initializer.nfts[j]] = initializer.hash;
            }
        }
    }

    function accrue() public {
        // Number of seconds since accrue was called
        uint256 elapsedTime = block.timestamp - totalDebtAccruedAt;
        if (elapsedTime == 0) {
            return;
        }
        totalDebtAccruedAt = block.timestamp;

        if (totalDebtAmount == 0) {
            return;
        }

        // Accrue interest
        uint256 interestPerYear = (totalDebtAmount *
            settings.debtInterestApr.numerator) /
            settings.debtInterestApr.denominator;
        uint256 interestPerSec = interestPerYear / SECS_YEAR;
        uint256 interest = elapsedTime * interestPerSec;
        totalDebtAmount += interest;
        totalFeeCollected += interest;
    }

    function setBorrowAmountCap(uint256 _borrowAmountCap)
        external
        onlyRole(DAO_ROLE)
    {
        settings.borrowAmountCap = _borrowAmountCap;
    }

    function setDebtInterestApr(Rate memory _debtInterestApr)
        external
        onlyRole(DAO_ROLE)
    {
        settings.debtInterestApr = _debtInterestApr;
    }

    function setCreditLimitRate(Rate memory _creditLimitRate)
        external
        onlyRole(GOVERNANCE_ROLE)
    {
        settings.creditLimitRate = _creditLimitRate;

        // if credit limit is higher than liquidation limit
        if (
            _creditLimitRate.numerator *
                settings.liquidationLimitRate.denominator >
            settings.liquidationLimitRate.numerator *
                _creditLimitRate.denominator
        ) {
            settings.liquidationLimitRate = _creditLimitRate;
        }
    }

    function setLiquidationLimitRate(Rate memory _liquidationLimitRate)
        external
        onlyRole(GOVERNANCE_ROLE)
    {
        settings.liquidationLimitRate = _liquidationLimitRate;
        // if credit limit is higher than liquidation limit
        if (
            settings.creditLimitRate.numerator *
                _liquidationLimitRate.denominator >
            _liquidationLimitRate.numerator *
                settings.creditLimitRate.denominator
        ) {
            settings.creditLimitRate = _liquidationLimitRate;
        }
    }

    function overrideFloor(uint256 _newFloor) external onlyRole(DAO_ROLE) {
        require(_newFloor > 0, "Invalid floor");
        nftTypeValueETH[bytes32(0)] = _newFloor;
        daoFloorOverride = true;
    }

    function disableFloorOverride() external onlyRole(DAO_ROLE) {
        daoFloorOverride = false;
    }

    function setOrganizationFeeRate(Rate memory _organizationFeeRate)
        external
        onlyRole(DAO_ROLE)
    {
        settings.organizationFeeRate = _organizationFeeRate;
    }

    function setInsurancePurchaseRate(Rate memory _insurancePurchaseRate)
        external
        onlyRole(DAO_ROLE)
    {
        settings.insurancePurchaseRate = _insurancePurchaseRate;
    }

    function setInsuranceLiquidationPenaltyRate(
        Rate memory _insuranceLiquidationPenaltyRate
    ) external onlyRole(DAO_ROLE) {
        settings
            .insuranceLiquidationPenaltyRate = _insuranceLiquidationPenaltyRate;
    }

    function setNFTType(uint256 _nftIndex, bytes32 _type)
        external
        validNFTIndex(_nftIndex)
        onlyRole(DAO_ROLE)
    {
        require(
            _type == bytes32(0) || nftTypeValueETH[_type] > 0,
            "invalid_nftType"
        );
        nftTypes[_nftIndex] = _type;
    }

    function setNFTTypeValueETH(bytes32 _type, uint256 _amountETH)
        external
        onlyRole(DAO_ROLE)
    {
        nftTypeValueETH[_type] = _amountETH;
    }

    function setPendingNFTValueETH(uint256 _nftIndex, uint256 _amountETH)
        external
        validNFTIndex(_nftIndex)
        onlyRole(GOVERNANCE_ROLE)
    {
        pendingNFTValueETH[_nftIndex] = _amountETH;
    }

    function finalizePendingNFTValueETH(uint256 _nftIndex)
        external
        validNFTIndex(_nftIndex)
    {
        uint256 pendingValue = pendingNFTValueETH[_nftIndex];
        require(pendingValue > 0, "no_pending_value");
        uint256 toLockJpeg = (((pendingValue *
            _ethPriceUSD() *
            settings.creditLimitRate.numerator) /
            settings.creditLimitRate.denominator) *
            settings.valueIncreaseLockRate.numerator) /
            settings.valueIncreaseLockRate.denominator /
            _jpegdPriceUSD();

        jpegdLocker.lockFor(msg.sender, _nftIndex, toLockJpeg);

        nftTypes[_nftIndex] = CUSTOM_NFT_HASH;
        nftValueETH[_nftIndex] = pendingValue;
        pendingNFTValueETH[_nftIndex] = 0;
    }

    function _getNFTValueETH(uint256 _nftIndex)
        internal
        view
        returns (uint256)
    {
        bytes32 nftType = nftTypes[_nftIndex];

        if (nftType == bytes32(0) && !daoFloorOverride) {
            return _normalizeAggregatorAnswer(floorOracle);
        } else if (nftType == CUSTOM_NFT_HASH) return nftValueETH[_nftIndex];

        return nftTypeValueETH[nftType];
    }

    function _getNFTValueUSD(uint256 _nftIndex)
        internal
        view
        returns (uint256)
    {
        uint256 nft_value = _getNFTValueETH(_nftIndex);
        return (nft_value * _ethPriceUSD()) / 10**18;
    }

    function _ethPriceUSD() internal view returns (uint256) {
        return _normalizeAggregatorAnswer(ethAggregator);
    }

    function _jpegdPriceUSD() internal view returns (uint256) {
        return _normalizeAggregatorAnswer(jpegdAggregator);
    }

    function _normalizeAggregatorAnswer(IAggregatorV3Interface aggregator)
        internal
        view
        returns (uint256)
    {
        int256 answer = aggregator.latestAnswer();
        uint8 decimals = aggregator.decimals();

        return uint256(answer) * 10**(18 - decimals);
    }

    struct NFTInfo {
        uint256 index;
        bytes32 nftType;
        address owner;
        uint256 nftValueETH;
        uint256 nftValueUSD;
    }

    function getNFTInfo(uint256 _nftIndex)
        external
        view
        returns (NFTInfo memory nftInfo)
    {
        nftInfo = NFTInfo(
            _nftIndex,
            nftTypes[_nftIndex],
            nftContract.ownerOf(_nftIndex),
            _getNFTValueETH(_nftIndex),
            _getNFTValueUSD(_nftIndex)
        );
    }

    function _getCreditLimit(uint256 _nftIndex)
        internal
        view
        returns (uint256 collateralValue)
    {
        uint256 asset_value = _getNFTValueUSD(_nftIndex);
        collateralValue =
            (asset_value * settings.creditLimitRate.numerator) /
            settings.creditLimitRate.denominator;
    }

    function _getLiquidationLimit(uint256 _nftIndex)
        internal
        view
        returns (uint256 collateralValue)
    {
        uint256 asset_value = _getNFTValueUSD(_nftIndex);
        collateralValue =
            (asset_value * settings.liquidationLimitRate.numerator) /
            settings.liquidationLimitRate.denominator;
    }

    function _getDebtAmount(uint256 _nftIndex) internal view returns (uint256) {
        if (totalDebtPortion == 0) {
            return 0;
        }
        return
            (totalDebtAmount * positions[_nftIndex].debtPortion) /
            totalDebtPortion;
    }

    function _openPosition(address _owner, uint256 _nftIndex) internal {
        nftContract.transferFrom(_owner, address(this), _nftIndex);

        positions[_nftIndex] = Position({
            borrowType: BorrowType.NOT_CONFIRMED,
            debtPrincipal: 0,
            debtPortion: 0,
            debtAmountForRepurchase: 0,
            liquidatedAt: 0,
            liquidator: address(0)
        });
        positionOwner[_nftIndex] = _owner;
        totalPositions++;

        emit PositionOpened(_owner, _nftIndex);
    }

    struct PositionPreview {
        address owner;
        uint256 nftIndex;
        bytes32 nftType;
        uint256 nftValueUSD;
        VaultSettings vaultSettings;
        uint256 creditLimit;
        uint256 debtPrincipal;
        uint256 debtInterest;
        BorrowType borrowType;
        bool liquidatable;
        uint256 liquidatedAt;
        address liquidator;
    }

    function showPosition(uint256 _nftIndex)
        external
        view
        validNFTIndex(_nftIndex)
        returns (PositionPreview memory preview)
    {
        address posOwner = positionOwner[_nftIndex];
        require(posOwner != address(0), "position_not_exist");

        uint256 debtPrincipal = positions[_nftIndex].debtPrincipal;
        uint256 debtAmount = positions[_nftIndex].liquidatedAt > 0
            ? positions[_nftIndex].debtAmountForRepurchase
            : _getDebtAmount(_nftIndex);
        preview = PositionPreview({
            owner: posOwner,
            nftIndex: _nftIndex,
            nftType: nftTypes[_nftIndex],
            nftValueUSD: _getNFTValueUSD(_nftIndex),
            vaultSettings: settings,
            creditLimit: _getCreditLimit(_nftIndex),
            debtPrincipal: debtPrincipal,
            debtInterest: debtAmount - debtPrincipal,
            borrowType: positions[_nftIndex].borrowType,
            liquidatable: positions[_nftIndex].liquidatedAt == 0 &&
                debtAmount >= _getLiquidationLimit(_nftIndex),
            liquidatedAt: positions[_nftIndex].liquidatedAt,
            liquidator: positions[_nftIndex].liquidator
        });
    }

    function borrow(
        uint256 _nftIndex,
        uint256 _amount,
        bool _useInsurance
    ) external validNFTIndex(_nftIndex) nonReentrant {
        accrue();

        require(
            msg.sender == positionOwner[_nftIndex] ||
                address(0) == positionOwner[_nftIndex],
            "unauthorized"
        );
        require(_amount > 0, "invalid_amount");
        require(
            totalDebtAmount + _amount <= settings.borrowAmountCap,
            "debt_cap"
        );

        if (nftContract.ownerOf(_nftIndex) != address(this)) {
            _openPosition(msg.sender, _nftIndex);
        }

        Position storage position = positions[_nftIndex];
        require(position.liquidatedAt == 0, "liquidated");
        require(
            position.borrowType == BorrowType.NOT_CONFIRMED ||
                (position.borrowType == BorrowType.USE_INSURANCE &&
                    _useInsurance) ||
                (position.borrowType == BorrowType.NON_INSURANCE &&
                    !_useInsurance),
            "invalid_insurance_mode"
        );

        uint256 creditLimit = _getCreditLimit(_nftIndex);
        uint256 debtAmount = _getDebtAmount(_nftIndex);
        require(debtAmount + _amount <= creditLimit, "insufficient_credit");

        uint256 organizationFee = (_amount *
            settings.organizationFeeRate.numerator) /
            settings.organizationFeeRate.denominator;

        // mint stablecoin
        if (position.borrowType == BorrowType.USE_INSURANCE || _useInsurance) {
            uint256 feeAmount = ((_amount *
                settings.insurancePurchaseRate.numerator) /
                settings.insurancePurchaseRate.denominator) + organizationFee;
            // insurance & organization fee amount to dao
            totalFeeCollected += feeAmount;

            // remaining amount to user
            stablecoin.mint(msg.sender, _amount - feeAmount);
        } else {
            // organization fee amount to dao
            totalFeeCollected += organizationFee;

            // remaining amount to user
            stablecoin.mint(msg.sender, _amount - organizationFee);
        }

        if (position.borrowType == BorrowType.NOT_CONFIRMED) {
            position.borrowType = _useInsurance
                ? BorrowType.USE_INSURANCE
                : BorrowType.NON_INSURANCE;
        }

        // update debt portion
        if (totalDebtPortion == 0) {
            totalDebtPortion = _amount;
            position.debtPortion = _amount;
        } else {
            uint256 plusPortion = (totalDebtPortion * _amount) /
                totalDebtAmount;
            totalDebtPortion += plusPortion;
            position.debtPortion += plusPortion;
        }
        position.debtPrincipal += _amount;
        totalDebtAmount += _amount;

        emit Borrowed(msg.sender, _nftIndex, _amount);
    }

    function repay(uint256 _nftIndex, uint256 _amount)
        external
        validNFTIndex(_nftIndex)
        nonReentrant
    {
        accrue();

        require(msg.sender == positionOwner[_nftIndex], "unauthorized");
        require(_amount > 0, "invalid_amount");

        Position storage position = positions[_nftIndex];
        require(position.liquidatedAt == 0, "liquidated");

        uint256 debtAmount = _getDebtAmount(_nftIndex);
        require(debtAmount > 0, "position_not_borrowed");

        uint256 debtPrincipal = position.debtPrincipal;
        uint256 debtInterest = debtAmount - debtPrincipal;

        _amount = _amount > debtAmount ? debtAmount : _amount;

        // burn all payment
        stablecoin.burnFrom(msg.sender, _amount);

        uint256 paidPrincipal = _amount - debtInterest;
        uint256 minusPortion = (totalDebtPortion * _amount) / totalDebtAmount;
        totalDebtPortion -= minusPortion;
        position.debtPortion -= minusPortion;
        position.debtPrincipal -= paidPrincipal;
        totalDebtAmount -= _amount;

        emit Repaid(msg.sender, _nftIndex, _amount);
    }

    function closePosition(uint256 _nftIndex)
        external
        validNFTIndex(_nftIndex)
    {
        accrue();

        require(msg.sender == positionOwner[_nftIndex], "unauthorized");
        require(_getDebtAmount(_nftIndex) == 0, "position_not_repaid");

        positionOwner[_nftIndex] = address(0);
        totalPositions--;

        // transfer nft back to owner if nft was deposited
        if (nftContract.ownerOf(_nftIndex) == address(this)) {
            nftContract.safeTransferFrom(address(this), msg.sender, _nftIndex);
        }

        emit PositionClosed(msg.sender, _nftIndex);
    }

    function liquidate(uint256 _nftIndex)
        external
        onlyRole(LIQUIDATOR_ROLE)
        validNFTIndex(_nftIndex)
        nonReentrant
    {
        accrue();

        address posOwner = positionOwner[_nftIndex];
        require(posOwner != address(0), "position_not_exist");

        Position storage position = positions[_nftIndex];
        require(position.liquidatedAt == 0, "liquidated");

        uint256 debtAmount = _getDebtAmount(_nftIndex);
        require(
            debtAmount >= _getLiquidationLimit(_nftIndex),
            "position_not_liquidatable"
        );

        // burn all payment
        stablecoin.burnFrom(msg.sender, debtAmount);

        // update debt portion
        totalDebtPortion -= position.debtPortion;
        totalDebtAmount -= debtAmount;
        position.debtPortion = 0;

        if (position.borrowType == BorrowType.USE_INSURANCE) {
            position.debtAmountForRepurchase = debtAmount;
            position.liquidatedAt = block.timestamp;
            position.liquidator = msg.sender;
        } else {
            // transfer nft to liquidator
            nftContract.safeTransferFrom(address(this), msg.sender, _nftIndex);
            positionOwner[_nftIndex] = address(0);
        }

        emit Liquidated(msg.sender, posOwner, _nftIndex);
    }

    function repurchase(uint256 _nftIndex) external validNFTIndex(_nftIndex) {
        Position memory position = positions[_nftIndex];
        require(msg.sender == positionOwner[_nftIndex], "unauthorized");
        require(position.liquidatedAt > 0, "not_liquidated");
        require(
            position.borrowType == BorrowType.USE_INSURANCE,
            "non_insurance"
        );
        require(
            position.liquidatedAt + settings.insuraceRepurchaseTimeLimit >=
                block.timestamp,
            "insurance_expired"
        );

        uint256 debtAmount = position.debtAmountForRepurchase;
        uint256 penalty = (debtAmount *
            settings.insuranceLiquidationPenaltyRate.numerator) /
            settings.insuranceLiquidationPenaltyRate.denominator;

        // transfer payment to dao
        stablecoin.transferFrom(
            msg.sender,
            position.liquidator,
            debtAmount + penalty
        );

        // transfer nft to user
        nftContract.safeTransferFrom(address(this), msg.sender, _nftIndex);
        positionOwner[_nftIndex] = address(0);

        emit Repurchased(msg.sender, _nftIndex);
    }

    function claimExpiredInsuranceNFT(uint256 _nftIndex)
        external
        validNFTIndex(_nftIndex)
    {
        Position memory position = positions[_nftIndex];
        require(address(0) != positionOwner[_nftIndex], "no_position");
        require(position.liquidatedAt > 0, "not_liquidated");
        require(
            position.liquidatedAt + settings.insuraceRepurchaseTimeLimit <
                block.timestamp,
            "insurance_not_expired"
        );
        require(position.liquidator == msg.sender, "unauthorized");

        nftContract.safeTransferFrom(address(this), msg.sender, _nftIndex);

        emit InsuranceExpired(positionOwner[_nftIndex], _nftIndex);

        positionOwner[_nftIndex] = address(0);
    }

    function collect() external nonReentrant onlyRole(DAO_ROLE) {
        accrue();
        stablecoin.mint(msg.sender, totalFeeCollected);
        totalFeeCollected = 0;
    }

    uint256[50] private __gap;
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

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IAggregatorV3Interface {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (int256 answer);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IStableCoin is IERC20Upgradeable {
    function mint(address _to, uint256 _value) external;

    function burn(uint256 _value) external;

    function burnFrom(address _from, uint256 _value) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IJPEGDLock {
    function lockFor(
        address _account,
        uint256 _punkIndex,
        uint256 _lockAmount
    ) external;
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