// SPDX-License-Identifier: UNLICENSED
/*
 *
 * ****************************************,***************************************
 * ***********************************,,,,,,,,,,,**********************************
 * *********************************,,,,*******,,,,********************************
 * ********************************,,,***********,,,*******************************
 * ******************************,,,,*************,,,******************************
 * *****************************,,,,***************,,,%****************************
 * *****************************,,,*****************,,,****************************
 * ****************************,,,*******************,,,*******         ***********
 * ****,,,,,,,,,,,,,,,,,******,,,*********************,,,*****           ,,,,,,,***
 * *,,,,**************,,,,,,,,,,,*********************,,,,,,,,           ******,,,,
 * ,,,***********************,,,,,,,,,%*********%,,,,,,,,,*****         *********,,
 * *,,(**********************,,,*****,,,,,,,,,,,,,*****,,,**********************,,,
 * *,,,     *****************,,,******,,,,,,,,,,.******,,,*********************.,,,
 * *.          *************,,,***,,,,,,*******,,,,,,***,,,*******************,,,**
 * *           *************,,,,,,,#***************,,,,,,,,*****************,,,,***
 * *           ***********,,,,,********         *******#,,,,,*************,,,,*****
 * ****     ,,,********,,,,,,,,*****%             ******,,,,,,,,*******&,,,,*******
 * ***********,,,,*,,,,,****,,,****                 ****,,,****,,,,,*,,,,**********
 * *************,,,,,*******,,,****                 ****,,,*******,,,,,************
 * ***********,,,,*.,,,,****,,,****                 ****,,,****,,,, *,,,,**********
 * ********,,,,********,,,,,,,,******             ******,,,,,,,,********,,,,*******
 * ******,,,,*************,,,,,/*******%       *********,,,,,*************,,,,*****
 * ****,,,,*****************,,,,,,,****************,,,,,,,,*****************,,,,***
 * **%,,,*******************,,,***,,,,,,*******,,,,,,***,,,*******************,,,**
 * *,,,#*********************,,,******#,,,,,,,,,*******,,,**********************,,,
 * *,,(**********************,,,*****,,,,,,,,,,,,,*****,,,**********************,,,
 * ,,,***********************,,,,,,,,,***********,,,,,,,,,***********************,,
 * *,,,,#************%,,,,,,,,,,,*********************,,,,,,,,,,,%************%,,,,
 * ****,,,,,,,,,,,,,,,,,******,,,*********************,,,******,,,,,,,,,,,,,,,,,***
 * ****************************,,,*******************,,,***************************
 * *****************************.    &**************,,,****************************
 * ***************************          ***********,,,%****************************
 * **************************            *********,,,&*****************************
 * ***************************          *********,,,*******************************
 * *****************************      ,,*******,,,,********************************
 * ***********************************,,,,,,,,,,,**********************************
 *
 *    Web:     https://universe.army
 */

// This contract contains an innovative anti-dump technology developed by the Universe team
//
// The limits are as follow:
// - A limit of how much coins a wallet can hold at any given point in time (e.g 420M)
// (this limit is not concerned by rewards claim, however, the wallet won't be able to receive any further funds if it exceeds)
// (withdrawing liquidity is limited to the quota)
// - A limit of how much coins a wallet can receive for every specific point in time (eg. every day, 105M)
// - A limit of how much coins a wallet can send for every specific point in time (eg. every day, 105M)
// - A deny mechanism to manually restrict wallets from sending or receiving coins
// (should be protected by multi-sig or used for a limited amount of time only)
//
// Exclusions are automatically set to the following: owner, pair, self transfers, mint / burn txs
// Liquidity add and remove are counted as regular transfers so there is no benefit in adding liquidity and withdrawing in another wallet
//
// By limiting the amount of coins someone can transfer (and therefore sell), it will prevent big price swings,
// even if the interest-bearing Planet is transferred around as it can be claimed only once by the wallet that owns it.

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./helpers/OwnerRecovery.sol";
import "./interfaces/IJoePair.sol";
import "../implementations/output/UniverseImplementationPointer.sol";
import "../implementations/output/LiquidityPoolManagerImplementationPointer.sol";
import "../implementations/output/PlanetsManagerImplementationPointer.sol";

contract WalletObserver is
    Ownable,
    OwnerRecovery,
    UniverseImplementationPointer,
    LiquidityPoolManagerImplementationPointer,
    PlanetsManagerImplementationPointer
{
    mapping(address => uint256) public _boughtTokens;
    mapping(uint256 => mapping(address => uint256)) public _inTokens;
    mapping(uint256 => mapping(address => uint256)) public _outTokens;

    mapping(address => bool) public _isDenied;
    mapping(address => bool) public _isExcludedFromObserver;

    uint256 public LPSupplyTotal;

    event WalletObserverEventBuy(
        address indexed _sender,
        address indexed from,
        address indexed to
    );
    event WalletObserverEventSell(
        address indexed _sender,
        address indexed from,
        address indexed to
    );
    event WalletObserverEventTransfer(
        address indexed _sender,
        address indexed from,
        address indexed to
    );

    event WalletObserverLiquidityWithdrawal(bool indexed _status);

    bool private debug = true;

    // Current time window
    uint256 private timeframeCurrent = 0;

    // Maximum amount of coins a wallet can hold
    // If equal or above, transfers and buys will be denied
    // He can still claim rewards
    uint256 private maxTokenPerWallet;

    // The TIMEFRAME in seconds
    uint256 private timeframeExpiresAfter;

    // The token amount limit per timeframe given to a wallet
    uint256 private timeframeQuota;

    constructor(
        address _universe,
        address _liquidityPoolManager,
        address _planetsManager
    ) {
        changeUniverseImplementation(_universe);
        changeLiquidityPoolManagerImplementation(_liquidityPoolManager);
        changePlanetsManagerImplementation(_planetsManager);

        // By default set every day
        setTimeframeExpiresAfter(1 days);

        // Limit token to 1% of the supply per wallet (doesn't count rewards)
        // 1% of 42 000 000 000 = 420 000 000
        setMaxTokenPerWallet(420_000_000 * (10**18));

        // Timeframe buys / transfers to 0.25% of the supply per wallet
        // 0.25% of 42 000 000 000 = 105 000 000
        setTimeframeQuota(105_000_000 * (10**18));

        // Default exclusions
        excludeFromObserver(universe.owner(), true);
    }

    modifier checkTimeframe() {
        uint256 _currentTime = block.timestamp;
        if (_currentTime > timeframeCurrent + timeframeExpiresAfter) {
            timeframeCurrent = _currentTime;
        }
        _;
    }

    modifier isNotDenied(address from, address to) {
        require(
            !_isDenied[from] && !_isDenied[to],
            "WalletObserver: Denied address"
        );
        _;
    }

    function changeLiquidityPoolManagerImplementation(address newImplementation)
        public
        virtual
        override
    {
        super.changeLiquidityPoolManagerImplementation(newImplementation);
        excludeFromObserver(newImplementation, true);
    }

    function beforeTokenTransfer(
        address _sender,
        address from,
        address to,
        uint256 amount
    )
        external
        onlyUniverse
        checkTimeframe
        isNotDenied(from, to)
        returns (bool)
    {
        // Do not observe self-transfers
        if (from == to) {
            return true;
        }

        // Do not observe mint / burn
        if (from == address(0) || to == address(0)) {
            return true;
        }

        require(
            to != address(planetsManager),
            "WalletObserver: Cannot send directly tokens to planetsManager, use Web UI to create a planet"
        );

        if (!debug) {
            require(
                to != address(liquidityPoolManager),
                "WalletObserver: Cannot send directly tokens to liquidityPoolManager, tokens are automatically collected"
            );
        }

        bool isBuy = false;
        bool isSell = false;
        bool isTransfer = false;

        if (
            liquidityPoolManager.isPair(_sender) &&
            liquidityPoolManager.isPair(from) &&
            !liquidityPoolManager.isLiquidityBeingRemoved()
        ) {
            isBuy = true;
            if (!isExcludedFromObserver(to)) {
                _boughtTokens[to] += amount;
                _inTokens[timeframeCurrent][to] += amount;
            }
            emit WalletObserverEventBuy(_sender, from, to);
        } else if (
            liquidityPoolManager.isRouter(_sender) &&
            liquidityPoolManager.isPair(to)
        ) {
            isSell = true;
            emit WalletObserverEventSell(_sender, from, to);
        } else {
            isTransfer = true;
            if (!isExcludedFromObserver(to)) {
                _inTokens[timeframeCurrent][to] += amount;
            }
            emit WalletObserverEventTransfer(_sender, from, to);
        }

        if ((isSell || isTransfer) && !isExcludedFromObserver(from)) {
            int256 newBoughtTokenValue = int256(getBoughtTokensOf(from)) -
                int256(amount);
            if (newBoughtTokenValue >= 0) {
                _boughtTokens[from] = uint256(newBoughtTokenValue);
            } else {
                _outTokens[timeframeCurrent][from] += uint256(
                    -newBoughtTokenValue
                );
                _boughtTokens[from] = 0;
            }
        }

        if (!isExcludedFromObserver(to)) {
            // Revert if the receiving wallet exceed the maximum a wallet can hold
            require(
                maxTokenPerWallet >= universe.balanceOf(to) + amount,
                "WalletObserver: Cannot transfer to this wallet, it would exceed the limit per wallet. [balanceOf > maxTokenPerWallet]"
            );

            // Revert if receiving wallet exceed daily limit
            require(
                getRemainingTransfersIn(to) >= 0,
                "WalletObserver: Cannot transfer to this wallet for this timeframe, it would exceed the limit per timeframe. [_inTokens > timeframeLimit]"
            );
        }

        if (!isExcludedFromObserver(from)) {
            // Revert if the sending wallet exceed the maximum transfer limit per day
            // We take into calculation the number ever bought of tokens available at this point
            require(
                getRemainingTransfersOut(from) >= 0,
                "WalletObserver: Cannot transfer out from this wallet for this timeframe, it would exceed the limit per timeframe. [_outTokens > timeframeLimit]"
            );
        }

        return true;
    }

    function getMaxTokenPerWallet() external view returns (uint256) {
        return maxTokenPerWallet;
    }

    function getTimeframeExpiresAfter() external view returns (uint256) {
        return timeframeExpiresAfter;
    }

    function getTimeframeQuota() external view returns (uint256) {
        return timeframeQuota;
    }

    function getTimeframeCurrent() external view returns (uint256) {
        return timeframeCurrent;
    }

    function getRemainingTransfersOut(address account)
        public
        view
        returns (int256)
    {
        return
            int256(timeframeQuota) -
            (int256(_outTokens[timeframeCurrent][account]) +
                int256(getBoughtTokensOf(account)));
    }

    function getRemainingTransfersIn(address account)
        public
        view
        returns (int256)
    {
        return
            int256(timeframeQuota) -
            int256(_inTokens[timeframeCurrent][account]);
    }

    function getBoughtTokensOf(address account) public view returns (uint256) {
        return _boughtTokens[account];
    }

    function isWalletFull(address account) public view returns (bool) {
        return universe.balanceOf(account) >= maxTokenPerWallet;
    }

    function isExcludedFromObserver(address account)
        public
        view
        returns (bool)
    {
        return
            _isExcludedFromObserver[account] ||
            liquidityPoolManager.isRouter(account) ||
            liquidityPoolManager.isPair(account) ||
            liquidityPoolManager.isFeeReceiver(account);
    }

    function setMaxTokenPerWallet(uint256 _maxTokenPerWallet) public onlyOwner {
        // Modifying this with a lower value won't brick wallets
        // It will just prevent transferring / buys to be made for them
        require(
            _maxTokenPerWallet >= timeframeQuota,
            "WalletObserver: Max token per wallet must be above or equal to timeframeQuota"
        );
        maxTokenPerWallet = _maxTokenPerWallet;
    }

    function setTimeframeExpiresAfter(uint256 _timeframeExpiresAfter)
        public
        onlyOwner
    {
        require(
            _timeframeExpiresAfter > 0,
            "WalletObserver: Timeframe expiration cannot be 0"
        );
        timeframeExpiresAfter = _timeframeExpiresAfter;
    }

    function setTimeframeQuota(uint256 _timeframeQuota) public onlyOwner {
        require(
            _timeframeQuota > 0,
            "WalletObserver: Timeframe token quota cannot be 0"
        );
        timeframeQuota = _timeframeQuota;
    }

    // In case of an upgrade, do not forget the manually set the blacklisted addresses before going into production
    function denyMalicious(address account, bool status) external onlyOwner {
        _isDenied[account] = status;
    }

    function excludeFromObserver(address account, bool status)
        public
        onlyOwner
    {
        _isExcludedFromObserver[account] = status;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../../contracts/interfaces/IUniverse.sol";

abstract contract UniverseImplementationPointer is Ownable {
    IUniverse internal universe;

    event UpdateUniverse(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    modifier onlyUniverse() {
        require(
            address(universe) != address(0),
            "Implementations: Universe is not set"
        );
        address sender = _msgSender();
        require(
            sender == address(universe),
            "Implementations: Not Universe"
        );
        _;
    }

    function getUniverseImplementation() public view returns (address) {
        return address(universe);
    }

    function changeUniverseImplementation(address newImplementation)
        public
        virtual
        onlyOwner
    {
        address oldImplementation = address(universe);
        require(
            Address.isContract(newImplementation) ||
                newImplementation == address(0),
            "Universe: You can only set 0x0 or a contract address as a new implementation"
        );
        universe = IUniverse(newImplementation);
        emit UpdateUniverse(oldImplementation, newImplementation);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../../contracts/interfaces/IPlanetsManager.sol";

abstract contract PlanetsManagerImplementationPointer is Ownable {
    IPlanetsManager internal planetsManager;

    event UpdatePlanetsManager(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    modifier onlyPlanetsManager() {
        require(
            address(planetsManager) != address(0),
            "Implementations: PlanetsManager is not set"
        );
        address sender = _msgSender();
        require(
            sender == address(planetsManager),
            "Implementations: Not PlanetsManager"
        );
        _;
    }

    function getPlanetsManagerImplementation() public view returns (address) {
        return address(planetsManager);
    }

    function changePlanetsManagerImplementation(address newImplementation)
        public
        virtual
        onlyOwner
    {
        address oldImplementation = address(planetsManager);
        require(
            Address.isContract(newImplementation) ||
                newImplementation == address(0),
            "PlanetsManager: You can only set 0x0 or a contract address as a new implementation"
        );
        planetsManager = IPlanetsManager(newImplementation);
        emit UpdatePlanetsManager(oldImplementation, newImplementation);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../../contracts/interfaces/ILiquidityPoolManager.sol";

abstract contract LiquidityPoolManagerImplementationPointer is Ownable {
    ILiquidityPoolManager internal liquidityPoolManager;

    event UpdateLiquidityPoolManager(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    modifier onlyLiquidityPoolManager() {
        require(
            address(liquidityPoolManager) != address(0),
            "Implementations: LiquidityPoolManager is not set"
        );
        address sender = _msgSender();
        require(
            sender == address(liquidityPoolManager),
            "Implementations: Not LiquidityPoolManager"
        );
        _;
    }

    function getLiquidityPoolManagerImplementation() public view returns (address) {
        return address(liquidityPoolManager);
    }

    function changeLiquidityPoolManagerImplementation(address newImplementation)
        public
        virtual
        onlyOwner
    {
        address oldImplementation = address(liquidityPoolManager);
        require(
            Address.isContract(newImplementation) ||
                newImplementation == address(0),
            "LiquidityPoolManager: You can only set 0x0 or a contract address as a new implementation"
        );
        liquidityPoolManager = ILiquidityPoolManager(newImplementation);
        emit UpdateLiquidityPoolManager(oldImplementation, newImplementation);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniverse is IERC20 {
    function owner() external view returns (address);

    function accountBurn(address account, uint256 amount) external;

    function accountReward(address account, uint256 amount) external;

    function liquidityReward(uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface IPlanetsManager {
    function owner() external view returns (address);

    function setToken(address token_) external;

    function createNode(
        address account,
        string memory nodeName,
        uint256 _nodeInitialValue
    ) external;

    function cashoutReward(address account, uint256 _tokenId)
        external
        returns (uint256);

    function _cashoutAllNodesReward(address account) external returns (uint256);

    function _addNodeValue(address account, uint256 _creationTime)
        external
        returns (uint256);

    function _addAllNodeValue(address account) external returns (uint256);

    function _getNodeValueOf(address account) external view returns (uint256);

    function _getNodeValueOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256);

    function _getNodeValueAmountOf(address account, uint256 creationTime)
        external
        view
        returns (uint256);

    function _getAddValueCountOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256);

    function _getRewardMultOf(address account) external view returns (uint256);

    function _getRewardMultOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256);

    function _getRewardMultAmountOf(address account, uint256 creationTime)
        external
        view
        returns (uint256);

    function _getRewardAmountOf(address account)
        external
        view
        returns (uint256);

    function _getRewardAmountOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256);

    function _getNodeRewardAmountOf(address account, uint256 creationTime)
        external
        view
        returns (uint256);

    function _getNodesNames(address account)
        external
        view
        returns (string memory);

    function _getNodesCreationTime(address account)
        external
        view
        returns (string memory);

    function _getNodesRewardAvailable(address account)
        external
        view
        returns (string memory);

    function _getNodesLastClaimTime(address account)
        external
        view
        returns (string memory);

    function _changeNodeMinPrice(uint256 newNodeMinPrice) external;

    function _changeRewardPerValue(uint256 newPrice) external;

    function _changeClaimTime(uint256 newTime) external;

    function _changeAutoDistri(bool newMode) external;

    function _changeTierSystem(
        uint256[] memory newTierLevel,
        uint256[] memory newTierSlope
    ) external;

    function _changeGasDistri(uint256 newGasDistri) external;

    function _getNodeNumberOf(address account) external view returns (uint256);

    function _isNodeOwner(address account) external view returns (bool);

    function _distributeRewards()
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function getNodeMinPrice() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface ILiquidityPoolManager {
    function owner() external view returns (address);

    function getRouter() external view returns (address);

    function getPair() external view returns (address);

    function getLeftSide() external view returns (address);

    function getRightSide() external view returns (address);

    function isPair(address _pair) external view returns (bool);

    function isRouter(address _router) external view returns (bool);

    function isFeeReceiver(address _receiver) external view returns (bool);

    function isLiquidityBeingRemoved() external view returns (bool);

    function afterTokenTransfer(address sender) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface IJoePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract OwnerRecovery is Ownable {
    function recoverLostAVAX() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function recoverLostTokens(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}