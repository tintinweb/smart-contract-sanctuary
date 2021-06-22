// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IERC20} from '../ERC20/IERC20.sol';
import {SafeMath} from '../utils/math/SafeMath.sol';
import {IARTHPool} from './Pools/IARTHPool.sol';
import {IARTHController} from './IARTHController.sol';
import {AccessControl} from '../access/AccessControl.sol';
import {
    IUniswapPairOracle
} from '../Oracle/Variants/uniswap/IUniswapPairOracle.sol';
import {IOracle} from '../Oracle/IOracle.sol';
import {ICurve} from '../Curves/ICurve.sol';
import {Math} from '../utils/math/Math.sol';
import {IBondingCurve} from '../Curves/IBondingCurve.sol';

/**
 * @title  ARTHStablecoin.
 * @author MahaDAO.
 */
contract ArthController is AccessControl, IARTHController {
    using SafeMath for uint256;

    IERC20 public ARTH;
    IERC20 public ARTHX;
    IERC20 public MAHA;

    IUniswapPairOracle public MAHAGMUOracle;
    IUniswapPairOracle public ARTHXGMUOracle;

    ICurve public recollateralizeDiscountCruve;
    IBondingCurve public bondingCurve;

    address public ownerAddress;
    address public timelockAddress;
    address public DEFAULT_ADMIN_ADDRESS;

    uint256 public globalCollateralRatio;
    uint256 public collateralRaisedOnOtherChain = 0;

    uint256 public override buybackFee; // 6 decimals of precision, divide by 1000000 in calculations for fee.
    uint256 public override mintingFee;
    uint256 public override redemptionFee;

    uint256 public maxRecollateralizeDiscount = 750000; // In 1e6 precision.

    /// @notice Timestamp at which contract was deployed.
    uint256 public immutable genesisTimestamp;
    /// @notice Will use uniswap oracle after this duration.
    uint256 public constant maxGenesisDuration = 7 days;
    /// @notice Will force use of genesis oracle during genesis.
    bool public isARTHXGenesActive = true;

    bool public isColalteralRatioPaused = false;

    bytes32 public constant COLLATERAL_RATIO_PAUSER =
        keccak256('COLLATERAL_RATIO_PAUSER');
    bytes32 public constant _RECOLLATERALIZE_PAUSER =
        keccak256('RECOLLATERALIZE_PAUSER');
    bytes32 public constant _MINT_PAUSER = keccak256('MINT_PAUSER');
    bytes32 public constant _REDEEM_PAUSER = keccak256('REDEEM_PAUSER');
    bytes32 public constant _BUYBACK_PAUSER = keccak256('BUYBACK_PAUSER');

    address[] public arthPoolsArray; // These contracts are able to mint ARTH.
    mapping(address => bool) public override arthPools;

    bool public mintPaused = false;
    bool public redeemPaused = false;
    bool public buyBackPaused = true;
    bool public recollateralizePaused = true;

    uint256 public constant _PRICE_PRECISION = 1e6;
    uint256 public stabilityFee = 0; // 1e4; // 1% in e6 precision.

    event TargetPriceChanged(uint256 old, uint256 current);
    event RedemptionFeeChanged(uint256 old, uint256 current);
    event MintingFeeChanged(uint256 old, uint256 current);

    /**
     * Modifiers.
     */

    modifier onlyCollateralRatioPauser() {
        require(
            hasRole(COLLATERAL_RATIO_PAUSER, msg.sender),
            'ARTHController: FORBIDDEN'
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            'ARTHController: FORBIDDEN'
        );
        _;
    }

    modifier onlyByOwnerOrGovernance() {
        require(
            msg.sender == ownerAddress || msg.sender == timelockAddress,
            'ARTHController: FORBIDDEN'
        );
        _;
    }

    modifier onlyByOwnerGovernanceOrPool() {
        require(
            msg.sender == ownerAddress ||
                msg.sender == timelockAddress ||
                arthPools[msg.sender],
            'ARTHController: FORBIDDEN'
        );
        _;
    }

    /**
     * Constructor.
     */

    constructor(
        IERC20 _arth,
        IERC20 _arthx,
        IERC20 _maha,
        address _owner,
        address _timelockAddress
    ) {
        ARTH = _arth;
        MAHA = _maha;
        ARTHX = _arthx;

        timelockAddress = _timelockAddress;

        DEFAULT_ADMIN_ADDRESS = _msgSender();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(COLLATERAL_RATIO_PAUSER, timelockAddress);

        globalCollateralRatio = 11e5;

        grantRole(_MINT_PAUSER, _timelockAddress);
        grantRole(_REDEEM_PAUSER, _timelockAddress);
        grantRole(_BUYBACK_PAUSER, _timelockAddress);
        grantRole(_RECOLLATERALIZE_PAUSER, _timelockAddress);

        genesisTimestamp = block.timestamp;
        ownerAddress = _owner;
    }

    /**
     * External.
     */

    function deactivateGenesis() external onlyByOwnerOrGovernance {
        isARTHXGenesActive = false;
    }

    function setBondingCurve(IBondingCurve curve)
        external
        onlyByOwnerOrGovernance
    {
        bondingCurve = curve;
    }

    function setRecollateralizationCurve(ICurve curve)
        external
        onlyByOwnerGovernanceOrPool
    {
        recollateralizeDiscountCruve = curve;
    }

    /// @notice Adds collateral addresses supported.
    /// @dev    Collateral must be an ERC20.
    function addPool(address poolAddress)
        external
        override
        onlyByOwnerOrGovernance
    {
        require(!arthPools[poolAddress], 'ARTHController: address present');

        arthPools[poolAddress] = true;
        arthPoolsArray.push(poolAddress);
    }

    function addPools(address[] memory poolAddress)
        external
        override
        onlyByOwnerOrGovernance
    {
        for (uint256 index = 0; index < poolAddress.length; index++) {
            arthPools[poolAddress[index]] = true;
            arthPoolsArray.push(poolAddress[index]);
        }
    }

    function removePool(address poolAddress)
        external
        override
        onlyByOwnerOrGovernance
    {
        require(arthPools[poolAddress], 'ARTHController: address absent');

        // Delete from the mapping.
        delete arthPools[poolAddress];

        uint256 noOfPools = arthPoolsArray.length;
        // 'Delete' from the array by setting the address to 0x0
        for (uint256 i = 0; i < noOfPools; i++) {
            if (arthPoolsArray[i] == poolAddress) {
                arthPoolsArray[i] = address(0); // This will leave a null in the array and keep the indices the same.
                break;
            }
        }
    }

    function setGlobalCollateralRatio(uint256 _globalCollateralRatio)
        external
        override
        onlyAdmin
    {
        globalCollateralRatio = _globalCollateralRatio;
    }

    function setStabilityFee(uint256 percent)
        external
        override
        onlyByOwnerOrGovernance
    {
        require(percent <= 1e6, 'ArthPool: percent > 1e6');
        stabilityFee = percent;
    }

    function setARTHXGMUOracle(address _arthxOracleAddress)
        external
        override
        onlyByOwnerOrGovernance
    {
        ARTHXGMUOracle = IUniswapPairOracle(_arthxOracleAddress);
    }

    function setMAHAGMUOracle(address oracle)
        external
        override
        onlyByOwnerOrGovernance
    {
        MAHAGMUOracle = IUniswapPairOracle(oracle);
    }

    function setFeesParameters(
        uint256 _mintingFee,
        uint256 _buybackFee,
        uint256 _redemptionFee
    ) external override onlyByOwnerOrGovernance {
        mintingFee = _mintingFee;
        buybackFee = _buybackFee;
        redemptionFee = _redemptionFee;
    }

    function toggleCollateralRatio()
        external
        override
        onlyCollateralRatioPauser
    {
        isColalteralRatioPaused = !isColalteralRatioPaused;
    }

    function setMintingFee(uint256 fee)
        external
        override
        onlyByOwnerOrGovernance
    {
        uint256 old = mintingFee;
        mintingFee = fee;
        emit MintingFeeChanged(old, mintingFee);
    }

    function setRedemptionFee(uint256 fee)
        external
        override
        onlyByOwnerOrGovernance
    {
        uint256 old = redemptionFee;
        redemptionFee = fee;
        emit RedemptionFeeChanged(old, redemptionFee);
    }

    function setBuybackFee(uint256 fee)
        external
        override
        onlyByOwnerOrGovernance
    {
        buybackFee = fee;
    }

    function setOwner(address _ownerAddress)
        external
        override
        onlyByOwnerOrGovernance
    {
        ownerAddress = _ownerAddress;
    }

    function setGlobalColletaralValue(uint256 _collateralRaised) public onlyAdmin {
        collateralRaisedOnOtherChain = _collateralRaised;
    }

    function setTimelock(address newTimelock)
        external
        override
        onlyByOwnerOrGovernance
    {
        timelockAddress = newTimelock;
    }

    function getMAHAPrice() public view override returns (uint256) {
        return MAHAGMUOracle.consult(address(MAHA), _PRICE_PRECISION);
    }

    function getARTHXPrice() public view override returns (uint256) {
        if (getIsGenesisActive()) return getARTHXGenesisPrice();
        return ARTHXGMUOracle.consult(address(ARTHX), _PRICE_PRECISION);
    }

    function getIsGenesisActive() public view override returns (bool) {
        return (isARTHXGenesActive &&
            block.timestamp.sub(genesisTimestamp) <= maxGenesisDuration);
    }

    function getARTHXGenesisPrice() public pure override returns (uint256) {
        return 1e4;
    }

    function getARTHXGenesisDiscount()
        external
        view
        override
        returns (uint256)
    {
        return bondingCurve.getY(getPercentCollateralized());
    }

    function getGlobalCollateralRatio() public view override returns (uint256) {
        return globalCollateralRatio;
    }

    function getGlobalCollateralValue() public view override returns (uint256) {
        uint256 totalCollateralValueD18 = 0;

        uint256 noOfPools = arthPoolsArray.length;
        for (uint256 i = 0; i < noOfPools; i++) {
            // Exclude null addresses.
            if (arthPoolsArray[i] != address(0)) {
                totalCollateralValueD18 = totalCollateralValueD18.add(
                    IARTHPool(arthPoolsArray[i]).getCollateralGMUBalance()
                );
            }
        }

        return totalCollateralValueD18.add(collateralRaisedOnOtherChain);
    }

    function getARTHSupply() public view override returns (uint256) {
        return ARTH.totalSupply();
    }

    function getMintingFee() external view override returns (uint256) {
        return mintingFee;
    }

    function getBuybackFee() external view override returns (uint256) {
        return buybackFee;
    }

    function getRedemptionFee() external view override returns (uint256) {
        return redemptionFee;
    }

    function getTargetCollateralValue() public view override returns (uint256) {
        return getARTHSupply().mul(getGlobalCollateralRatio()).div(1e6);
    }

    function getPercentCollateralized() public view override returns (uint256) {
        uint256 targetCollatValue = getTargetCollateralValue();
        uint256 currentCollatValue = getGlobalCollateralValue();

        return currentCollatValue.mul(1e18).div(targetCollatValue);
    }

    function getRecollateralizationDiscount()
        public
        view
        override
        returns (uint256)
    {
        return
            Math.min(
                recollateralizeDiscountCruve
                    .getY(getPercentCollateralized())
                    .mul(_PRICE_PRECISION)
                    .div(100),
                maxRecollateralizeDiscount
            );
    }

    function getARTHInfo()
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            // uint256,
            uint256
        )
    {
        return (
            0, // getARTHPrice(), // ARTH price.
            getARTHXPrice(), // ARTHX price.
            ARTH.totalSupply(), // ARTH total supply.
            globalCollateralRatio, // Global collateralization ratio.
            getGlobalCollateralValue(), // Global collateral value.
            mintingFee, // Minting fee.
            redemptionFee, // Redemtion fee.
            // getETHGMUPrice(), // ETH/GMU price.
            buybackFee
        );
    }

    function toggleMinting() external override {
        require(hasRole(_MINT_PAUSER, msg.sender));
        mintPaused = !mintPaused;
    }

    function toggleRedeeming() external override {
        require(hasRole(_REDEEM_PAUSER, msg.sender));
        redeemPaused = !redeemPaused;
    }

    function toggleRecollateralize() external override {
        require(hasRole(_RECOLLATERALIZE_PAUSER, msg.sender));
        recollateralizePaused = !recollateralizePaused;
    }

    function toggleBuyBack() external override {
        require(hasRole(_BUYBACK_PAUSER, msg.sender));
        buyBackPaused = !buyBackPaused;
    }

    function isRedeemPaused() external view override returns (bool) {
        if (getIsGenesisActive()) return true;
        return redeemPaused;
    }

    function isMintPaused() external view override returns (bool) {
        if (getIsGenesisActive()) return true;
        return mintPaused;
    }

    function isBuybackPaused() external view override returns (bool) {
        return buyBackPaused;
    }

    function isRecollaterlizePaused() external view override returns (bool) {
        return recollateralizePaused;
    }

    function getStabilityFee() external view override returns (uint256) {
        if (getIsGenesisActive()) return 0;
        return stabilityFee;
    }

    function isPool(address pool) external view override returns (bool) {
        return arthPools[pool];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IARTHController {
    function toggleCollateralRatio() external;

    function addPool(address pool_address) external;

    function addPools(address[] memory poolAddress) external;

    function removePool(address pool_address) external;

    function getARTHSupply() external view returns (uint256);

    function isPool(address pool) external view returns (bool);

    function getARTHInfo()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            // uint256,
            uint256
        );

    function setMintingFee(uint256 fee) external;

    function setMAHAGMUOracle(address oracle) external;

    function setARTHXGMUOracle(address _arthxOracleAddress) external;

    function setFeesParameters(
        uint256 _mintingFee,
        uint256 _buybackFee,
        uint256 _redemptionFee
    ) external;

    function setRedemptionFee(uint256 fee) external;

    function setBuybackFee(uint256 fee) external;

    function setOwner(address _ownerAddress) external;

    function setTimelock(address newTimelock) external;

    function setGlobalCollateralRatio(uint256 _globalCollateralRatio) external;

    function getARTHXPrice() external view returns (uint256);

    function getMintingFee() external view returns (uint256);

    function getMAHAPrice() external view returns (uint256);

    function getBuybackFee() external view returns (uint256);

    function getRedemptionFee() external view returns (uint256);

    function getGlobalCollateralRatio() external view returns (uint256);

    function getARTHXGenesisDiscount() external view returns (uint256);

    function getGlobalCollateralValue() external view returns (uint256);

    function arthPools(address pool) external view returns (bool);

    function setStabilityFee(uint256 val) external;

    function isRedeemPaused() external view returns (bool);

    function isMintPaused() external view returns (bool);

    function isBuybackPaused() external view returns (bool);

    function isRecollaterlizePaused() external view returns (bool);

    function toggleMinting() external;

    function toggleRedeeming() external;

    function toggleRecollateralize() external;

    function toggleBuyBack() external;

    function getStabilityFee() external view returns (uint256);

    // todo add this here
    function mintingFee() external returns (uint256);

    function redemptionFee() external returns (uint256);

    function buybackFee() external returns (uint256);

    function getRecollateralizationDiscount() external returns (uint256);

    function getIsGenesisActive() external view returns (bool);

    function getARTHXGenesisPrice() external view returns (uint256);

    function getTargetCollateralValue() external view returns (uint256);

    function getPercentCollateralized() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IARTHPool {
    function repay(uint256 amount) external;

    function borrow(uint256 amount) external;

    function setBuyBackCollateralBuffer(uint256 percent) external;

    function setCollatGMUOracle(address _collateralGMUOracleAddress) external;

    function setPoolParameters(uint256 newCeiling, uint256 newRedemptionDelay)
        external;

    function setTimelock(address newTimelock) external;

    function setOwner(address ownerAddress) external;

    function mint(uint256 collateralAmount, uint256 arthOutMin, uint256 arthxOutMin)
        external
        returns (uint256, uint256);

    function redeem(uint256 arthAmount, uint256 arthxAmount, uint256 collateralOutMin)
        external;

    function collectRedemption() external;

    function recollateralizeARTH(uint256 collateralAmount, uint256 arthxOutMin)
        external
        returns (uint256);

    function buyBackARTHX(uint256 arthxAmount, uint256 collateralOutMin)
        external;

    function getGlobalCR() external view returns (uint256);

    function getCollateralGMUBalance() external view returns (uint256);

    function getAvailableExcessCollateralDV() external view returns (uint256);

    function getCollateralPrice() external view returns (uint256);

    function collateralGMUOracleAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ICurve} from './ICurve.sol';

interface IBondingCurve is ICurve {
    function getFixedPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICurve {
    function getY(uint256 x) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the number of decimals for token.
     */
    function decimals() external view returns (uint8);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracle {
    function getPrice() external view returns (uint256);

    function getDecimalPercision() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapPairOracle {
    function update() external;

    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);

    function canUpdate() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../utils/Context.sol';
import '../utils/introspection/ERC165.sol';

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return _roles[role].members[account];
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
    function grantRole(bytes32 role, address account) public virtual override {
        require(
            hasRole(getRoleAdmin(role), _msgSender()),
            'AccessControl: sender must be an admin to grant'
        );

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
    function revokeRole(bytes32 role, address account) public virtual override {
        require(
            hasRole(getRoleAdmin(role), _msgSender()),
            'AccessControl: sender must be an admin to revoke'
        );

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
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            'AccessControl: can only renounce roles for self'
        );

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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 100000
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}