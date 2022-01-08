// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;
pragma abicoder v2;

import '@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol';

import './maths/Math.sol';
import './interfaces/IVolmexPool.sol';
import './interfaces/IERC20Modified.sol';
import './interfaces/IVolmexPoolView.sol';
import './interfaces/IPausablePool.sol';

/**
 * @title Reading key data from specified derivative trading Pool
 */
contract VolmexPoolView is ERC165StorageUpgradeable, Math, IVolmexPoolView {
    // Interface ID of VolmexPoolView contract
    bytes4 private constant _IVOLMEX_POOLVIEW_ID = type(IVolmexPoolView).interfaceId;

    function initialize() external initializer {
        __ERC165Storage_init();
        _registerInterface(_IVOLMEX_POOLVIEW_ID);
    }

    /**
     * @notice Getting information about Pool configuration, it's derivative and pool(LP) tokens
     * @param _pool the vault address
     * @return primary pool's primary token metadata
     * @return complement pool' complement token metadata
     * @return poolToken pool's own token metadata
     * @return config pool configuration
     */
    function getPoolInfo(address _pool, address _sender)
        external
        view
        returns (
            TokenRecord memory primary,
            TokenRecord memory complement,
            TokenData memory poolToken,
            Config memory config
        )
    {
        IVolmexPool pool = IVolmexPool(_pool);

        address _primaryAddress = address(pool.protocol().volatilityToken());
        primary = TokenRecord(
            _primaryAddress,
            pool.getBalance(_primaryAddress),
            pool.getLeverage(_primaryAddress),
            IERC20Modified(_primaryAddress).decimals(),
            _sender == address(0) ? 0 : IERC20(_primaryAddress).balanceOf(_sender)
        );

        address _complementAddress = address(pool.protocol().inverseVolatilityToken());
        complement = TokenRecord(
            _complementAddress,
            pool.getBalance(_complementAddress),
            pool.getLeverage(_complementAddress),
            IERC20Modified(_complementAddress).decimals(),
            _sender == address(0) ? 0 : IERC20(_complementAddress).balanceOf(_sender)
        );

        poolToken = TokenData(
            _pool,
            pool.totalSupply(),
            IERC20Modified(_pool).decimals(),
            _sender == address(0) ? 0 : IERC20(_pool).balanceOf(_sender)
        );

        config = Config(
            address(pool.protocol()),
            address(pool.repricer()),
            IPausablePool(address(pool)).paused(),
            IERC20Modified(_primaryAddress).decimals(),
            IERC20Modified(_pool).decimals(),
            pool.exposureLimitPrimary(),
            pool.exposureLimitComplement(),
            pool.pMin(),
            pool.qMin(),
            pool.baseFee(),
            pool.maxFee(),
            pool.feeAmpPrimary(),
            pool.feeAmpComplement()
        );
    }

    /**
     * @notice Getting current state of Pool, token balances and leverages, LP token supply
     * @param _pool vault address
     * @return primary pool's primary token address
     * @return primaryBalance pool's primary token balance
     * @return primaryLeverage pool's primary token leverage
     * @return primaryDecimals pool's primary token decimals
     * @return complement pool's complement token address
     * @return complementBalance pool's complement token balance
     * @return complementLeverage pool's complement token leverage
     * @return complementDecimals pool's complement token decimals
     * @return lpTotalSupply pool's LP token total supply
     * @return lpDecimals pool's LP token decimals
     */
    function getPoolTokenData(address _pool)
        external
        view
        returns (
            address primary,
            uint256 primaryBalance,
            uint256 primaryLeverage,
            uint8 primaryDecimals,
            address complement,
            uint256 complementBalance,
            uint256 complementLeverage,
            uint8 complementDecimals,
            uint256 lpTotalSupply,
            uint8 lpDecimals
        )
    {
        IVolmexPool pool = IVolmexPool(_pool);

        primary = address(pool.protocol().volatilityToken());
        complement = address(pool.protocol().inverseVolatilityToken());

        primaryBalance = pool.getBalance(primary);
        primaryLeverage = pool.getLeverage(primary);
        primaryDecimals = IERC20Modified(primary).decimals();

        complementBalance = pool.getBalance(complement);
        complementLeverage = pool.getLeverage(complement);
        complementDecimals = IERC20Modified(complement).decimals();

        lpTotalSupply = pool.totalSupply();
        lpDecimals = IERC20Modified(_pool).decimals();
    }

    /**
     * @notice Getting Pool configuration only to reduce data loading time
     */
    function getPoolConfig(address _pool)
        external
        view
        returns (
            address protocol,
            address repricer,
            uint256 exposureLimitPrimary,
            uint256 exposureLimitComplement,
            uint256 pMin,
            uint256 qMin,
            uint256 baseFee,
            uint256 maxFee,
            uint256 feeAmpPrimary,
            uint256 feeAmpComplement
        )
    {
        IVolmexPool pool = IVolmexPool(_pool);
        protocol = address(pool.protocol());
        repricer = address(pool.repricer());
        pMin = pool.pMin();
        qMin = pool.qMin();
        exposureLimitPrimary = pool.exposureLimitPrimary();
        exposureLimitComplement = pool.exposureLimitComplement();
        baseFee = pool.baseFee();
        feeAmpPrimary = pool.feeAmpPrimary();
        feeAmpComplement = pool.feeAmpComplement();
        maxFee = pool.maxFee();
    }

    function getTokensToJoin(IVolmexPool _pool, uint256 _poolAmountOut)
        external
        view
        returns (uint256[2] memory _maxAmountsIn)
    {
        uint256 ratio = _div(_poolAmountOut, _pool.totalSupply());
        require(ratio != 0, 'VolmexPoolView: Invalid math approximation in join');

        for (uint256 i = 0; i < 2; i++) {
            uint256 bal = _pool.getBalance(_pool.tokens(i));
            _maxAmountsIn[i] = _mul(ratio, bal);
        }
    }

    function getTokensToExit(IVolmexPool _pool, uint256 _poolAmountIn)
        external
        view
        returns (uint256[2] memory _minAmountsOut)
    {
        uint256 ratio = _div(_poolAmountIn, _pool.totalSupply());
        require(ratio != 0, 'VolmexPoolView: Invalid math approximation in exit');

        uint256 upperBoundary = _pool.upperBoundary();
        uint256 adminFee = _pool.adminFee();
        for (uint256 i = 0; i < 2; i++) {
            uint256 bal = _pool.getBalance(_pool.tokens(i));
            _minAmountsOut[i] = _calculateAmountOut(
                _poolAmountIn,
                ratio,
                bal,
                upperBoundary,
                adminFee
            );
        }
    }

    uint256[10] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165StorageUpgradeable is Initializable, ERC165Upgradeable {
    function __ERC165Storage_init() internal initializer {
        __ERC165_init_unchained();
        __ERC165Storage_init_unchained();
    }

    function __ERC165Storage_init_unchained() internal initializer {
    }
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import './Num.sol';

contract Math is Num {
    /**********************************************************************************************
    // calcSpotPrice                                                                             //
    // sP = spotPrice                                                                            //
    // bI = tokenBalanceIn                 bI          1                                         //
    // bO = tokenBalanceOut         sP =  ----  *  ----------                                    //
    // sF = swapFee                        bO      ( 1 - sF )                                    //
    **********************************************************************************************/
    function calcSpotPrice(
        uint256 _tokenBalanceIn,
        uint256 _tokenBalanceOut,
        uint256 _swapFee
    ) public pure returns (uint256 spotPrice) {
        uint256 ratio = _div(_tokenBalanceIn, _tokenBalanceOut);
        uint256 scale = _div(BONE, BONE - _swapFee);
        spotPrice = _mul(ratio, scale);
    }

    /**********************************************************************************************
    // calcOutGivenIn                                                                            //
    // aO = tokenAmountOut                                                                       //
    // bO = tokenBalanceOut                                                                      //
    // bI = tokenBalanceIn              /      /            bI             \   \                 //
    // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  |  |                 //
    // sF = swapFee                     \      \ ( bI + ( aI * ( 1 - sF )) /   /                 //
    **********************************************************************************************/
    function _calcOutGivenIn(
        uint256 _tokenBalanceIn,
        uint256 _tokenBalanceOut,
        uint256 _tokenAmountIn,
        uint256 _swapFee
    ) internal pure returns (uint256 tokenAmountOut) {
        uint256 adjustedIn = BONE - _swapFee;
        adjustedIn = _mul(_tokenAmountIn, adjustedIn);
        uint256 y = _div(_tokenBalanceIn, _tokenBalanceIn + adjustedIn);
        uint256 bar = BONE - y;
        tokenAmountOut = _mul(_tokenBalanceOut, bar);
    }

    /**
     * @notice Used to calculate the out amount after fee deduction
     */
    function _calculateAmountOut(
        uint256 _poolAmountIn,
        uint256 _ratio,
        uint256 _tokenReserve,
        uint256 _upperBoundary,
        uint256 _adminFee
    ) internal pure returns (uint256 amountOut) {
        uint256 tokenAmount = _mul(_div(_poolAmountIn, _upperBoundary), BONE);
        amountOut = _mul(_ratio, _tokenReserve);
        if (amountOut > tokenAmount) {
            uint256 feeAmount = _div(_mul(tokenAmount, _adminFee), 10000);
            amountOut = amountOut - feeAmount;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import '../libs/tokens/Token.sol';
import './IVolmexProtocol.sol';
import './IVolmexRepricer.sol';
import './IVolmexController.sol';

interface IVolmexPool is IERC20 {
    struct Record {
        uint256 leverage;
        uint256 balance;
    }

    event Swapped(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 tokenAmountIn,
        uint256 tokenAmountOut,
        uint256 fee,
        uint256 tokenBalanceIn,
        uint256 tokenBalanceOut,
        uint256 tokenLeverageIn,
        uint256 tokenLeverageOut
    );
    event Joined(address indexed caller, address indexed tokenIn, uint256 tokenAmountIn);
    event Exited(address indexed caller, address indexed tokenOut, uint256 tokenAmountOut);
    event Repriced(
        uint256 repricingBlock,
        uint256 balancePrimary,
        uint256 balanceComplement,
        uint256 leveragePrimary,
        uint256 leverageComplement,
        uint256 newLeveragePrimary,
        uint256 newLeverageComplement,
        uint256 estPricePrimary,
        uint256 estPriceComplement
    );
    event Called(bytes4 indexed sig, address indexed caller, bytes data) anonymous;
    event Loaned(
        address indexed target,
        address indexed asset,
        uint256 amount,
        uint256 premium
    );
    event FlashLoanPremiumUpdated(uint256 premium);
    event ControllerSet(address indexed controller);
    event FeeParamsSet(
        uint256 baseFee,
        uint256 maxFee,
        uint256 feeAmpPrimary,
        uint256 feeAmpComplement
    );

    // Getter methods
    function repricingBlock() external view returns (uint256);
    function baseFee() external view returns (uint256);
    function feeAmpPrimary() external view returns (uint256);
    function feeAmpComplement() external view returns (uint256);
    function maxFee() external view returns (uint256);
    function pMin() external view returns (uint256);
    function qMin() external view returns (uint256);
    function exposureLimitPrimary() external view returns (uint256);
    function exposureLimitComplement() external view returns (uint256);
    function protocol() external view returns (IVolmexProtocol);
    function repricer() external view returns (IVolmexRepricer);
    function volatilityIndex() external view returns (uint256);
    function finalized() external view returns (bool);
    function upperBoundary() external view returns (uint256);
    function adminFee() external view returns (uint256);
    function getLeverage(address _token) external view returns (uint256);
    function getBalance(address _token) external view returns (uint256);
    function tokens(uint256 _index) external view returns (address);
    function flashLoanPremium() external view returns (uint256);
    function getLeveragedBalance(Record memory r) external pure returns (uint256);
    function getTokenAmountOut(
        address _tokenIn,
        uint256 _tokenAmountIn
    ) external view returns (uint256, uint256);

    // Setter methods
    function setController(IVolmexController _controller) external;
    function updateFlashLoanPremium(uint256 _premium) external;
    function joinPool(uint256 _poolAmountOut, uint256[2] calldata _maxAmountsIn, address _receiver) external;
    function exitPool(uint256 _poolAmountIn, uint256[2] calldata _minAmountsOut, address _receiver) external;
    function pause() external;
    function unpause() external;
    function reprice() external;
    function swapExactAmountIn(
        address _tokenIn,
        uint256 _tokenAmountIn,
        address _tokenOut,
        uint256 _minAmountOut,
        address _receiver,
        bool _toController
    ) external returns (uint256, uint256);
    function flashLoan(
        address _receiverAddress,
        address _assetToken,
        uint256 _amount,
        bytes calldata _params
    ) external;
    function finalize(
        uint256 _primaryBalance,
        uint256 _primaryLeverage,
        uint256 _complementBalance,
        uint256 _complementLeverage,
        uint256 _exposureLimitPrimary,
        uint256 _exposureLimitComplement,
        uint256 _pMin,
        uint256 _qMin,
        address _receiver
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

interface IERC20Modified {
    // IERC20 Methods
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Custom Methods
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
    function mint(address _toWhom, uint256 amount) external;
    function burn(address _whose, uint256 amount) external;
    function grantRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
    function pause() external;
    function unpause() external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import './IVolmexPool.sol';

interface IVolmexPoolView {
    struct TokenRecord {
        address self;
        uint256 balance;
        uint256 leverage;
        uint8 decimals;
        uint256 userBalance;
    }

    struct TokenData {
        address self;
        uint256 totalSupply;
        uint8 decimals;
        uint256 userBalance;
    }

    struct Config {
        address protocol;
        address repricer;
        bool isPaused;
        uint8 qMinDecimals;
        uint8 decimals;
        uint256 exposureLimitPrimary;
        uint256 exposureLimitComplement;
        uint256 pMin;
        uint256 qMin;
        uint256 baseFee;
        uint256 maxFee;
        uint256 feeAmpPrimary;
        uint256 feeAmpComplement;
    }

    function getTokensToJoin(IVolmexPool _pool, uint256 _poolAmountOut) external view returns (uint256[2] memory);
    function getTokensToExit(IVolmexPool _pool, uint256 _poolAmountIn) external view returns (uint256[2] memory);
    function getPoolInfo(address _pool, address _sender)
        external
        view
        returns (
            TokenRecord memory primary,
            TokenRecord memory complement,
            TokenData memory poolToken,
            Config memory config
        );
    function getPoolTokenData(address _pool)
        external
        view
        returns (
            address primary,
            uint256 primaryBalance,
            uint256 primaryLeverage,
            uint8 primaryDecimals,
            address complement,
            uint256 complementBalance,
            uint256 complementLeverage,
            uint8 complementDecimals,
            uint256 lpTotalSupply,
            uint8 lpDecimals
        );
    function getPoolConfig(address _pool)
        external
        view
        returns (
            address protocol,
            address repricer,
            uint256 exposureLimitPrimary,
            uint256 exposureLimitComplement,
            uint256 pMin,
            uint256 qMin,
            uint256 baseFee,
            uint256 maxFee,
            uint256 feeAmpPrimary,
            uint256 feeAmpComplement
        );
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

interface IPausablePool {
    // Getter method
    function paused() external view returns (bool);

    // Setter methods
    function pause() external;
    function unpause() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import './Const.sol';

contract Num is Const {
    function _subSign(uint256 _a, uint256 _b) internal pure returns (uint256, bool) {
        if (_a >= _b) {
            return (_a - _b, false);
        } else {
            return (_b - _a, true);
        }
    }

    function _mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        uint256 c0 = _a * _b;
        uint256 c1 = c0 + (BONE / 2);
        c = c1 / BONE;
    }

    function _div(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        require(_b != 0, 'DIV_ZERO');
        uint256 c0 = _a * BONE;
        uint256 c1 = c0 + (_b / 2);
        c = c1 / _b;
    }

    function _min(uint256 _first, uint256 _second) internal pure returns (uint256) {
        if (_first < _second) {
            return _first;
        }
        return _second;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

contract Const {
    uint256 public constant BONE = 10**18;

    int256 public constant iBONE = int256(BONE);

    uint256 public constant MAX_IN_RATIO = BONE / 2;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import '../../maths/Num.sol';
import '../../interfaces/IERC20.sol';

contract TokenBase is Num {
    mapping(address => uint256) internal _balance;
    mapping(address => mapping(address => uint256)) internal _allowance;
    uint256 internal _totalSupply;

    event Approval(address indexed _src, address indexed _dst, uint256 _amt);
    event Transfer(address indexed _src, address indexed _dst, uint256 _amt);

    function _mint(uint256 _amt) internal {
        _balance[address(this)] = _balance[address(this)] + _amt;
        _totalSupply = _totalSupply + _amt;
        emit Transfer(address(0), address(this), _amt);
    }

    function _burn(uint256 _amt) internal {
        require(_balance[address(this)] >= _amt, 'INSUFFICIENT_BAL');
        _balance[address(this)] = _balance[address(this)] - _amt;
        _totalSupply = _totalSupply - _amt;
        emit Transfer(address(this), address(0), _amt);
    }

    function _move(
        address _src,
        address _dst,
        uint256 _amt
    ) internal {
        require(_balance[_src] >= _amt, 'INSUFFICIENT_BAL');
        _balance[_src] = _balance[_src] - _amt;
        _balance[_dst] = _balance[_dst] + _amt;
        emit Transfer(_src, _dst, _amt);
    }

    function _push(address _to, uint256 _amt) internal {
        _move(address(this), _to, _amt);
    }

    function _pull(address _from, uint256 _amt) internal {
        _move(_from, address(this), _amt);
    }
}

contract Token is TokenBase, IERC20 {
    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 18;

    function approve(address _dst, uint256 _amt) external override returns (bool) {
        _allowance[msg.sender][_dst] = _amt;
        emit Approval(msg.sender, _dst, _amt);
        return true;
    }

    function increaseApproval(address _dst, uint256 _amt) external returns (bool) {
        _allowance[msg.sender][_dst] = _allowance[msg.sender][_dst] + _amt;
        emit Approval(msg.sender, _dst, _allowance[msg.sender][_dst]);
        return true;
    }

    function decreaseApproval(address _dst, uint256 _amt) external returns (bool) {
        uint256 oldValue = _allowance[msg.sender][_dst];
        if (_amt > oldValue) {
            _allowance[msg.sender][_dst] = 0;
        } else {
            _allowance[msg.sender][_dst] = oldValue - _amt;
        }
        emit Approval(msg.sender, _dst, _allowance[msg.sender][_dst]);
        return true;
    }

    function transfer(address _dst, uint256 _amt) external override returns (bool) {
        _move(msg.sender, _dst, _amt);
        return true;
    }

    function transferFrom(
        address _src,
        address _dst,
        uint256 _amt
    ) external override returns (bool) {
        uint256 oldValue = _allowance[_src][msg.sender];
        require(msg.sender == _src || _amt <= oldValue, 'TOKEN_BAD_CALLER');
        _move(_src, _dst, _amt);
        if (msg.sender != _src && oldValue != type(uint128).max) {
            _allowance[_src][msg.sender] = oldValue - _amt;
            emit Approval(msg.sender, _dst, _allowance[_src][msg.sender]);
        }
        return true;
    }

    function allowance(address _src, address _dst) external view override returns (uint256) {
        return _allowance[_src][_dst];
    }

    function balanceOf(address _whom) external view override returns (uint256) {
        return _balance[_whom];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _setName(string memory _poolName) internal {
        _name = _poolName;
    }

    function _setSymbol(string memory _poolSymbol) internal {
        _symbol = _poolSymbol;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import './IERC20Modified.sol';

interface IVolmexProtocol {
    //getter methods
    function minimumCollateralQty() external view returns (uint256);
    function active() external view returns (bool);
    function isSettled() external view returns (bool);
    function volatilityToken() external view returns (IERC20Modified);
    function inverseVolatilityToken() external view returns (IERC20Modified);
    function collateral() external view returns (IERC20Modified);
    function issuanceFees() external view returns (uint256);
    function redeemFees() external view returns (uint256);
    function accumulatedFees() external view returns (uint256);
    function volatilityCapRatio() external view returns (uint256);
    function settlementPrice() external view returns (uint256);
    function precisionRatio() external view returns (uint256);

    //setter methods
    function toggleActive() external;
    function updateMinimumCollQty(uint256 _newMinimumCollQty) external;
    function updatePositionToken(address _positionToken, bool _isVolatilityIndex) external;
    function collateralize(uint256 _collateralQty) external;
    function redeem(uint256 _positionTokenQty) external;
    function redeemSettled(
        uint256 _volatilityIndexTokenQty,
        uint256 _inverseVolatilityIndexTokenQty
    ) external;
    function settle(uint256 _settlementPrice) external;
    function recoverTokens(
        address _token,
        address _toWhom,
        uint256 _howMuch
    ) external;
    function updateFees(uint256 _issuanceFees, uint256 _redeemFees) external;
    function claimAccumulatedFees() external;
    function togglePause(bool _isPause) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import './IVolmexOracle.sol';

interface IVolmexRepricer {
    // Getter method
    function oracle() external view returns (IVolmexOracle);

    // Setter methods
    function sqrtWrapped(int256 value) external pure returns (int256);
    function reprice(uint256 _volatilityIndex)
        external
        view
        returns (
            uint256 estPrimaryPrice,
            uint256 estComplementPrice,
            uint256 estPrice
        );
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import './IERC20Modified.sol';
import './IVolmexPool.sol';
import './IPausablePool.sol';
import './IVolmexProtocol.sol';
import './IVolmexOracle.sol';

interface IVolmexController {
    event AdminFeeUpdated(uint256 adminFee);
    event CollateralSwapped(
        uint256 volatilityInAmount,
        uint256 collateralOutAmount,
        uint256 protocolFee,
        uint256 poolFee,
        uint256 indexed stableCoinIndex,
        address indexed token
    );
    event PoolSwapped(
        uint256 volatilityInAmount,
        uint256 volatilityOutAmount,
        uint256 protocolFee,
        uint256[2] poolFee,
        uint256 indexed stableCoinIndex,
        address[2] tokens
    );
    event PoolAdded(uint256 indexed poolIndex, address indexed pool);
    event StableCoinAdded(uint256 indexed stableCoinIndex, address indexed stableCoin);
    event ProtocolAdded(uint256 poolIndex, uint256 stableCoinIndex, address indexed protocol);
    event PoolTokensCollected(address indexed owner, uint256 amount);

    // Getter methods
    function stableCoinIndex() external view returns (uint256);
    function poolIndex() external view returns (uint256);
    function pools(uint256 _index) external view returns (IVolmexPool);
    function stableCoins(uint256 _index) external view returns (IERC20Modified);
    function isPool(address _pool) external view returns (bool);
    function oracle() external view returns (IVolmexOracle);
    function protocols(
        uint256 _poolIndex,
        uint256 _stableCoinIndex
    ) external view returns (IVolmexProtocol);

    // Setter methods
    function addPool(IVolmexPool _pool) external;
    function addStableCoin(IERC20Modified _stableCoin) external;
    function pausePool(IPausablePool _pool) external;
    function unpausePool(IPausablePool _pool) external;
    function collect(IVolmexPool _pool) external;
    function addProtocol(
        uint256 _poolIndex,
        uint256 _stableCoinIndex,
        IVolmexProtocol _protocol
    ) external;
    function swapCollateralToVolatility(
        uint256[2] calldata _amounts,
        address _tokenOut,
        uint256[2] calldata _indices
    ) external;
    function swapVolatilityToCollateral(
        uint256[2] calldata _amounts,
        uint256[2] calldata _indices,
        IERC20Modified _tokenIn
    ) external;
    function swapBetweenPools(
        address[2] calldata _tokens,
        uint256[2] calldata _amounts,
        uint256[3] calldata _indices
    ) external;
    function addLiquidity(
        uint256 _poolAmountOut,
        uint256[2] calldata _maxAmountsIn,
        uint256 _poolIndex
    ) external;
    function removeLiquidity(
        uint256 _poolAmountIn,
        uint256[2] calldata _minAmountsOut,
        uint256 _poolIndex
    ) external;
    function makeFlashLoan(
        address _receiver,
        address _assetToken,
        uint256 _amount,
        bytes calldata _params,
        uint256 _poolIndex
    ) external;
    function swap(
        uint256 _poolIndex,
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _amountOut
    ) external;
    function getCollateralToVolatility(
        uint256 _collateralAmount,
        address _tokenOut,
        uint256[2] calldata _indices
    ) external view returns (uint256, uint256[2] memory);
    function getVolatilityToCollateral(
        address _tokenIn,
        uint256 _amount,
        uint256[2] calldata _indices,
        bool _isInverse
    ) external view returns (uint256, uint256[2] memory);
    function getSwapAmountBetweenPools(
        address[2] calldata _tokens,
        uint256 _amountIn,
        uint256[3] calldata _indices
    ) external view returns (uint256, uint256[3] memory);
    function transferAssetToPool(
        IERC20Modified _token,
        address _account,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _whom) external view returns (uint256);
    function allowance(address _src, address _dst) external view returns (uint256);
    function approve(address _dst, uint256 _amt) external returns (bool);
    function transfer(address _dst, uint256 _amt) external returns (bool);
    function transferFrom(
        address _src,
        address _dst,
        uint256 _amt
    ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import './IVolmexProtocol.sol';

interface IVolmexOracle {
    event BatchVolatilityTokenPriceUpdated(
        uint256[] _volatilityIndexes,
        uint256[] _volatilityTokenPrices,
        bytes32[] _proofHashes
    );

    event VolatilityIndexAdded(
        uint256 indexed volatilityTokenIndex,
        uint256 volatilityCapRatio,
        string volatilityTokenSymbol,
        uint256 volatilityTokenPrice
    );

    event SymbolIndexUpdated(uint256 indexed _index);

    // Getter  methods
    function volatilityCapRatioByIndex(uint256 _index) external view returns (uint256);
    function volatilityTokenPriceProofHash(uint256 _index) external view returns (bytes32);
    function volatilityIndexBySymbol(string calldata _tokenSymbol) external view returns (uint256);
    function indexCount() external view returns (uint256);

    // Setter methods
    function updateIndexBySymbol(string calldata _tokenSymbol, uint256 _index) external;
    function getVolatilityTokenPriceByIndex(uint256 _index)
        external
        view
        returns (uint256, uint256);
    function getVolatilityPriceBySymbol(string calldata _volatilityTokenSymbol)
        external
        view
        returns (uint256 volatilityTokenPrice, uint256 iVolatilityTokenPrice);
    function updateBatchVolatilityTokenPrice(
        uint256[] memory _volatilityIndexes,
        uint256[] memory _volatilityTokenPrices,
        bytes32[] memory _proofHashes
    ) external;
    function addVolatilityIndex(
        uint256 _volatilityTokenPrice,
        IVolmexProtocol _protocol,
        string calldata _volatilityTokenSymbol,
        bytes32 _proofHash
    ) external;
}