pragma experimental ABIEncoderV2;
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "../core/VRFConsumerBaseUpgradeable.sol";
import "../libraries/SafeMath.sol";
import "../jackpot/IPirateJackpot.sol";
import "../interfaces/IPirateBank.sol";
import "../jackpot/IPirateJackpot.sol";
import "../interfaces/IPirateBank.sol";

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title BarbellRoll 
 */
contract BarbellRoll is VRFConsumerBaseUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;

    IPirateBank public constant BANK = IPirateBank(0x827287219E5bECF4f2c5c18e19562f96F0139D41);
    address public constant PIRATE = 0x3750144AcD56CC1d3e8dAFD8a187Ad10d174d462;
    IPirateJackpot public constant JACKPOT = IPirateJackpot(0x4711c3141C635646293da2680bBDD7e66C9FBe94);
    bytes32 constant KEY_HASH = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
    uint private constant chainlinkFee = 100000000000000;
    uint private constant wealthTaxIncrementThreshold = 150 ether;
    uint private constant wealthTaxIncrementPercent = 1;
    uint private constant HOUSE_EDGE_PERCENT = 1;
    
    // Info of each bet.
    struct Bet {
        // Wager amount in wei.
        uint betAmount;
        // Player choice
        uint low;
        uint high;
        // Block number of placeBet tx.
        uint placeBlockNumber;
        // Address of player, used to pay out winning bets.
        address payable player;
        // Status of bet settlement.
        bool isSettled;
        // Outcome of bet.
        uint outcome;
        // Win amount.
        uint winAmount;
        // Random number used to settle bet.
        uint randomNumber;
        // Token used to bet.
        address token;
    }

    // List of bets
    Bet[] public bets;

    // Store Number of bets
    uint public betsLength;

    // Mapping requestId returned by Chainlink VRF to bet Id
    mapping(bytes32 => uint) public betMap;
    mapping (address => uint256) public tokenMinBet; // token => minimum bet amount
    mapping (address => uint256) public tokenMaxBet; // token => maximum bet amount
    mapping (address => uint256) public wealthTaxThreshold; // token => wealth tax threshold

    // Events
    event BetPlaced(uint indexed betId, address indexed gambler, uint low, uint high, uint amount, address token);
    event BetSettled(uint indexed betId, address indexed gambler, uint low, uint high, uint amount, address token, uint outcome, uint winAmount);
    event BetRefunded(uint indexed betId, address indexed gambler);

    function initialize() external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __VRFOwnable_init(0x3d2341ADb2D31f1c5530cDC622016af293177AE0, 0xb0897686c545045aFc77CF20eC7A532E3120E0F1);
        require(owner() != address(0), "owner must be set");
    }

    // @dev owner can set token min and max amount
    function setTokenMinMaxWealthBet(address token, uint256 min, uint256 max, uint256 wealth) external onlyOwner {
        tokenMinBet[token] = min;
        tokenMaxBet[token] = max;
        wealthTaxThreshold[token] = wealth;
    }

    /* ========== View Functions ========== */
    
    // Get wealth tax 
    function getWealthTax(uint amount, address token) private view returns (uint wealthTax) {
        if (token == address(0)) {
            wealthTax = amount / 150 ether * wealthTaxIncrementPercent;    
        } else {
            wealthTax = amount / wealthTaxThreshold[token] * wealthTaxIncrementPercent;
        }
        wealthTax = amount / wealthTaxIncrementThreshold * wealthTaxIncrementPercent;
    }

    // Get the expected win amount after house edge is subtracted.
    function getWinAmount(address token, uint amount, uint range) private view returns (uint winAmount) {
        uint wealthTax = token == PIRATE ? 0 : getWealthTax(amount, token);
        uint houseEdge = amount * (HOUSE_EDGE_PERCENT + wealthTax) / 100;
        winAmount = (amount - houseEdge) * 95 / range;
    }

    /* ========== External Functions ========== */

    /**
     * @dev Roll with between setting
     * @param low The predicted low number
     * @param high The predicted high number
     */
    function takeBet(uint low, uint high) external payable nonReentrant {
        //Validate sender and bet limits
        require(msg.value >= 1 ether, "minimum 1 MATIC");
        require(msg.value <= 1500 ether, "maximum of 1500 MATIC");

        //Validate predictions range
        require(low <= 99);
        require(high <= 99);
        require(low <= high);

        uint range = high - low + 1;

        require(range >= 5);
        require(range <= 95);

        uint totalPayout = getWinAmount(address(0), msg.value, range);

        // check that house has enough for payouts
        require(BANK.balanceOf(address(0)) > totalPayout, "House: Not enough balance.");
        require(BANK.serviceableBetAmount(address(0)) > totalPayout, "House: Not enough to service locked in bets.");
        // require(BANK.balanceOf(address(0)) > msg.value.mul(95).div(range), "House: Not enough balance.");

        BANK.lockFunds(address(0), totalPayout);

        bets.push(Bet(
            {
                betAmount: msg.value,
                low: low,
                high: high,
                placeBlockNumber: block.number,
                player: msg.sender,
                isSettled: false,
                outcome: 0,
                winAmount: 0,
                randomNumber: 0,
                token: address(0)
            }
        ));

        BANK.deposit{value: msg.value}(address(0), msg.value);

        // Request random number from Chainlink VRF. Store requestId for validation checks later.
        bytes32 requestId = requestRandomness(KEY_HASH, chainlinkFee, betsLength);

        // Map requestId to bet ID
        betMap[requestId] = betsLength;

        // Record bet in event logs
        emit BetPlaced(betsLength, msg.sender, low, high, msg.value, address(0));

        betsLength++;
    }

    /**
     * @dev Roll with between setting
     * @param low The predicted low number
     * @param high The predicted high number
     */
    function takeBetToken(address token, uint amount, uint low, uint high) external nonReentrant {
        //Validate sender and bet limits
        require(amount >= tokenMinBet[token], "minimum 50 token");
        require(amount <= tokenMaxBet[token], "maximum of 3000 tokens");

        //Validate predictions range
        require(low <= 99);
        require(high <= 99);
        require(low <= high);

        uint range = high - low + 1;
        
        require(range >= 5);
        require(range <= 95);

        uint totalPayout = getWinAmount(token, amount, range);
        // check that house has enough for payouts
        // require(BANK.balanceOf(token) > amount.mul(95).div(range), "House: Not enough balance.");
        require(BANK.balanceOf(token) > totalPayout, "House: Not enough balance.");
        require(BANK.serviceableBetAmount(token) > totalPayout, "House: Not enough to service locked in bets.");

        //Receive token
        require(ERC20(token).transferFrom(msg.sender, address(this), amount));

        BANK.lockFunds(token, totalPayout);

        bets.push(Bet(
            {
                betAmount: amount,
                low: low,
                high: high,
                placeBlockNumber: block.number,
                player: msg.sender,
                isSettled: false,
                outcome: 0,
                winAmount: 0,
                randomNumber: 0,
                token: token
            }
        ));

        _approveTokenIfNeeded(token);
        BANK.deposit(token, amount);

        // Request random number from Chainlink VRF. Store requestId for validation checks later.
        bytes32 requestId = requestRandomness(KEY_HASH, chainlinkFee, betsLength);

        // Map requestId to bet ID
        betMap[requestId] = betsLength;

        // Record bet in event logs
        emit BetPlaced(betsLength, msg.sender, low, high, amount, token);

        betsLength++;
        //Log results
        // emit Result(msg.sender, luck, amount, payout, low, high, token);
    }

    /* ========== Internal Functions ========== */

    // Settle bet. Function can only be called by fulfillRandomness function, which in turn can only be called by Chainlink VRF.
    function settleBet(bytes32 requestId, uint randomNumber) internal nonReentrant {
        uint betId = betMap[requestId];
        Bet storage b = bets[betId];

        uint range = b.high - b.low + 1;
        uint totalPayout = getWinAmount(b.token, b.betAmount, range);
        // Win amount if gambler wins this bet
        // uint possibleWinAmount = getWinAmount(b.token, b.betAmount);

        require(b.betAmount > 0, "Bet does not exist."); // Check that bet exists
        require(b.isSettled == false, "Bet is settled already"); // Check that bet is not settled yet

        // Fetch bet parameters into local variables (to save gas).
        address payable player = b.player;

        // Do a roll by taking a modulo of random number.
        uint luck = uint(randomNumber % 100);

        // unlocking funds regardless of win or lose
        BANK.unlockFunds(b.token, totalPayout);

        if (luck >= b.low && luck <= b.high) {
            if (b.token == address(0)) {
                BANK.withdrawTo(address(0), totalPayout, player);
            } else {
                BANK.withdraw(b.token, totalPayout);
                require(ERC20(b.token).transfer(player, totalPayout));
            }
        } else {
            totalPayout = 0;
        }

        if (JACKPOT.isWhitelist(address(this)) && b.token == PIRATE) {
            JACKPOT.getLucky(player);
        }

        b.isSettled = true;
        b.winAmount = totalPayout;
        b.randomNumber = randomNumber;
        b.outcome = luck;

        emit BetSettled(betId, player, b.low, b.high, b.betAmount, b.token, luck, totalPayout);
    }

    function _approveTokenIfNeeded(address token) internal {
        if (ERC20(token).allowance(address(this), address(BANK)) == 0) {
            ERC20(token).approve(address(BANK), uint(~0));
        }
    }

    /* ========== Chain Link Functions ========== */

    // Callback function called by VRF coordinator
    function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
        settleBet(requestId, randomness);
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

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";
import "@chainlink/contracts/src/v0.6/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.6/VRFRequestIDBase.sol";

abstract contract VRFConsumerBaseUpgradeable is Initializable, VRFRequestIDBase {
    using SafeMathChainlink for uint256;

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal virtual;

    function requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed)
        internal returns (bytes32 requestId)
    {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
    
        uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
    
        nonces[_keyHash] = nonces[_keyHash].add(1);
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface internal LINK;
    address private vrfCoordinator;

    mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

    function __VRFOwnable_init(address _vrfCoordinator, address _link) internal initializer  {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }

    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * change notes:  original SafeMath library from OpenZeppelin modified by Inventor
 * - added sqrt
 * - added sq
 * - added pwr
 * - changed asserts to requires with error log outputs
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }

    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = ((add(x, 1)) / 2);
        y = x;
        while (z < y) {
            y = z;
            z = ((add((x / z), z)) / 2);
        }
    }

    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x) internal pure returns (uint256) {
        return (mul(x, x));
    }

    /**
     * @dev x to the power of y
     */
    function pwr(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x == 0) return (0);
        else if (y == 0) return (1);
        else {
            uint256 z = x;
            for (uint256 i = 1; i < y; i++) z = mul(z, x);
            return (z);
        }
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IPirateJackpot {
  function getLucky(address account) external;
  function claim(uint roundIndex) external;
  function isWhitelist(address _address) external view returns(bool);
}

interface IPirateBank {
    function balanceOf(address token) external view returns (uint);
    function earned(address token) external view returns (uint);
    function serviceableBetAmount(address token) external view returns (uint);

    function withdraw(address token, uint256 amount) external;
    function withdrawTo(address token, uint256 amount, address recipient) external;
    function deposit(address token, uint256 amount) external payable;
    function depositCapital(address token, uint amount) external payable;
    function lockFunds(address token, uint256 amount) external;
    function unlockFunds(address token, uint256 amount) external;
    function withdrawEarnings(address token, uint256 amount) external;
    function withdrawAll(address token) external payable;

    function setTokenOwner(address token, address account) external;
    function setTokenReturnRatio(address token, uint ratio) external;
    function setTokenRouter(address token, address router) external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
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
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}