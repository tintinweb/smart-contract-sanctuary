//SourceUnit: MazePresale.sol

// SPDX-License-Identifier: 
// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.5.0;


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
contract Context is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.5.0;


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
 */
contract ReentrancyGuard is Initializable {
    // counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    function initialize() public initializer {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }

    uint256[50] private ______gap;
}

// File: contracts/BasisPoints.sol

pragma solidity ^0.5.0;


library BasisPoints {
    using SafeMath for uint;

    uint constant private BASIS_POINTS = 10000;

    function mulBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        return amt.mul(bp).div(BASIS_POINTS);
    }

    function divBP(uint amt, uint bp) internal pure returns (uint) {
        require(bp > 0, "Cannot divide by zero.");
        if (amt == 0) return 0;
        return amt.mul(BASIS_POINTS).div(bp);
    }

    function addBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.add(mulBP(amt, bp));
    }

    function subBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.sub(mulBP(amt, bp));
    }
}

// File: contracts/MazePresaleTimer.sol

pragma solidity ^0.5.0;


contract MazePresaleTimer is Initializable, Ownable {
    using SafeMath for uint;

    uint public startTime;
    uint public baseTimer;
    uint public deltaTimer;

    function init(
        uint _startTime,
        uint _baseTimer,
        uint _deltaTimer,
        address owner
    ) external initializer {
        Ownable.initialize(msg.sender);
        startTime = _startTime;
        baseTimer = _baseTimer;
        deltaTimer = _deltaTimer;
        //Due to issue in oz testing suite, the msg.sender might not be owner
        _transferOwnership(owner);
    }

    function setStartTime(uint time) external onlyOwner {
        startTime = time;
    }

    function isStarted() external view returns (bool) {
        return (startTime != 0 && now > startTime);
    }

    function getEndTime(uint bal) external view returns (uint) {
        uint multiplier = bal.div(4000000 );
        return startTime.add(baseTimer).add(deltaTimer.mul(multiplier));
    }
}

// File: contracts/IMazeCertifiableToken.sol

pragma solidity ^0.5.0;


interface IMazeCertifiableToken {
    function activateTransfers() external;
    function mint(address account, uint256 amount) external returns (bool);
    function addMinter(address account) external;
    function renounceMinter() external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function isMinter(address account) external view returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

// File: contracts/justswap/IJustswapExchange.sol

pragma solidity ^0.5.0;

interface IJustswapExchange {
    event TokenPurchase(address indexed buyer, uint256 indexed trx_sold, uint256 indexed tokens_bought);
    event TrxPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed trx_bought);
    event AddLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);
    event RemoveLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);
    function () external payable;
    function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve)
             external view returns (uint256);
    function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve)
             external view returns (uint256);
    function trxToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256);
    function trxToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient)
             external payable returns(uint256);
    function trxToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns(uint256);
    function trxToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient)
             external payable returns (uint256);
    function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline) external returns (uint256);
    function tokenToTrxTransferInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline, address recipient)
             external returns (uint256);
    function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline) external returns (uint256);
    function tokenToTrxTransferOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline, address recipient)
             external returns (uint256);
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_trx_bought,
             uint256 deadline, address token_addr) external returns (uint256);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_trx_bought,
             uint256 deadline, address recipient, address token_addr) external returns (uint256);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_trx_sold,
             uint256 deadline, address token_addr) external returns (uint256);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_trx_sold,
             uint256 deadline, address recipient, address token_addr) external returns (uint256);
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_trx_bought,
             uint256 deadline, address exchange_addr) external returns (uint256);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_trx_bought,
             uint256 deadline, address recipient, address exchange_addr) external returns (uint256);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_trx_sold,
             uint256 deadline, address exchange_addr) external returns (uint256);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_trx_sold,
             uint256 deadline, address recipient, address exchange_addr) external returns (uint256);
    function getTrxToTokenInputPrice(uint256 trx_sold) external view returns (uint256);
    function getTrxToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256);
    function getTokenToTrxInputPrice(uint256 tokens_sold) external view returns (uint256);
    function getTokenToTrxOutputPrice(uint256 trx_bought) external view returns (uint256);
    function tokenAddress() external view returns (address);
    function factoryAddress() external view returns (address);
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline)
    external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_trx, uint256 min_tokens, uint256 deadline)
             external returns (uint256, uint256);
}

// File: contracts/justswap/IJustswapFactory.sol

pragma solidity ^0.5.0;

interface IJustswapFactory {
    event NewExchange(address indexed token, address indexed exchange);
    function initializeFactory(address template) external;
    function createExchange(address token) external returns (address payable);
    function getExchange(address token) external view returns (address payable);
    function getToken(address token) external view returns (address);
    function getTokenWihId(uint256 token_id) external view returns (address);
}

// File: contracts/MazePresale.sol

pragma solidity ^0.5.0;


contract MazePresale is Initializable, Ownable, ReentrancyGuard {
    using BasisPoints for uint;
    using SafeMath for uint;

    uint public maxBuyPerAddress;
    uint public minBuyPerAddress;

    uint public redeemBP;
    uint public redeemInterval;

    uint public referralBP;

    uint public justswapTrxBP;
    address payable[] public trxPools;
    uint[] public trxPoolBPs;

    uint public justswapTokenBP;
    uint public presaleTokenBP;
    address[] public tokenPools;
    uint[] public tokenPoolBPs;

    uint public price;

    bool public hasSentToJustswap;
    bool public hasIssuedTokens;
    bool public hasSentTrx;

    uint public totalTokens;
    uint private totalTrx;
    uint public finalEndTime;

    IMazeCertifiableToken private token;
    IJustswapExchange public justswapExchange;
    MazePresaleTimer private timer;

    mapping(address => uint) public depositAccounts;
    mapping(address => uint) public accountEarnedMaze;
    mapping(address => uint) public accountClaimedMaze;
    mapping(address => bool) public whitelist;
    mapping(address => uint) public earnedReferrals;

    uint public totalDepositors;
    mapping(address => uint) public referralCounts;

    uint mazeRepaired;
    bool pauseDeposit;

    mapping(address => bool) public isRepaired;

    modifier whenPresaleActive {
        require(timer.isStarted(), "Presale not yet started.");
        require(!isPresaleEnded(), "Presale has ended.");
        _;
    }

    modifier whenPresaleFinished {
        require(timer.isStarted(), "Presale not yet started.");
        require(isPresaleEnded(), "Presale has not yet ended.");
        _;
    }

    function init(
        uint _maxBuyPerAddress,
        uint _minBuyPerAddress,
        uint _redeemBP,
        uint _redeemInterval,
        uint _referralBP,
        uint _price,
        uint _justswapTrxBP,
        uint _justswapTokenBP,
        uint _presaleTokenBP,
        address owner,
        MazePresaleTimer _timer,
        IMazeCertifiableToken _token
    ) external initializer {
        require(_token.isMinter(address(this)), "Presale must be minter.");
        Ownable.initialize(msg.sender);
        ReentrancyGuard.initialize();

        token = _token;
        timer = _timer;

        maxBuyPerAddress = _maxBuyPerAddress;
        minBuyPerAddress = _minBuyPerAddress;

        redeemBP = _redeemBP;

        referralBP = _referralBP;
        redeemInterval = _redeemInterval;

        price = _price;

        justswapTrxBP = _justswapTrxBP;
        justswapTokenBP = _justswapTokenBP;
        presaleTokenBP = _presaleTokenBP;


        //Due to issue in oz testing suite, the msg.sender might not be owner
        _transferOwnership(owner);

        // Real Liquidity Pool
        // comment for testing
        IJustswapFactory factory = IJustswapFactory(address(0x41EED9E56A5CDDAA15EF0C42984884A8AFCF1BDEBB));
        address payable exchange_addr = factory.createExchange(address(token));
        justswapExchange = IJustswapExchange(exchange_addr);
    }

    //    function deposit() external payable {
    //        deposit(address(0x0));
    //    }

    function setTrxPools(
        address payable[] calldata _trxPools,
        uint[] calldata _trxPoolBPs
    ) external onlyOwner {
        require(_trxPools.length == _trxPoolBPs.length, "Must have exactly one trxPool addresses for each BP.");
        delete trxPools;
        delete trxPoolBPs;
        for (uint i = 0; i < _trxPools.length; ++i) {
            trxPools.push(_trxPools[i]);
        }
        uint totalTrxPoolsBP = justswapTrxBP;
        for (uint i = 0; i < _trxPoolBPs.length; ++i) {
            trxPoolBPs.push(_trxPoolBPs[i]);
            totalTrxPoolsBP = totalTrxPoolsBP.add(_trxPoolBPs[i]);
        }
        require(totalTrxPoolsBP == 10000, "Must allocate exactly 100% (10000 BP) of trx to pools");
    }

    function setTokenPools(
        address[] calldata _tokenPools,
        uint[] calldata _tokenPoolBPs
    ) external onlyOwner {
        require(_tokenPools.length == _tokenPoolBPs.length, "Must have exactly one tokenPool addresses for each BP.");
        delete tokenPools;
        delete tokenPoolBPs;
        for (uint i = 0; i < _tokenPools.length; ++i) {
            tokenPools.push(_tokenPools[i]);
        }
        uint totalTokenPoolBPs = justswapTokenBP.add(presaleTokenBP);
        for (uint i = 0; i < _tokenPoolBPs.length; ++i) {
            tokenPoolBPs.push(_tokenPoolBPs[i]);
            totalTokenPoolBPs = totalTokenPoolBPs.add(_tokenPoolBPs[i]);
        }
        require(totalTokenPoolBPs == 10000, "Must allocate exactly 100% (10000 BP) of tokens to pools");
    }

    // No TESTNET for JustSwap at this moment
    // We use this fake function only for testing
    //    function testSendToJustswap(address payable fakeAddr) external whenPresaleFinished nonReentrant {
    //        require(trxPools.length > 0, "Must have set trx pools");
    //        require(tokenPools.length > 0, "Must have set token pools");
    //        require(!hasSentToJustswap, "Has already sent to Justswap.");
    //        finalEndTime = now;
    //        hasSentToJustswap = true;
    //        totalTokens = totalTokens.divBP(presaleTokenBP);
    //        uint justswapTokens = totalTokens.mulBP(justswapTokenBP);
    //        totalTrx = address(this).balance;
    //        uint justswapTrx = totalTrx.mulBP(justswapTrxBP);
    //        token.mint(address(this), justswapTokens);
    //        token.activateTransfers();
    //
    //        // Fake Liquidity Pool Creation
    //        token.approve(fakeAddr, justswapTokens);
    //        token.transfer(fakeAddr, justswapTokens);
    //        fakeAddr.transfer(justswapTrx);
    //
    //    }

    function sendToJustswap() external whenPresaleFinished nonReentrant {
        require(trxPools.length > 0, "Must have set trx pools");
        require(tokenPools.length > 0, "Must have set token pools");
        require(!hasSentToJustswap, "Has already sent to Justswap.");
        finalEndTime = now;
        hasSentToJustswap = true;
        totalTokens = totalTokens.divBP(presaleTokenBP);
        uint justswapTokens = totalTokens.mulBP(justswapTokenBP);
        totalTrx = address(this).balance;
        uint justswapTrx = totalTrx.mulBP(justswapTrxBP);
        token.mint(address(this), justswapTokens);
        token.activateTransfers();

        token.approve(address(justswapExchange), justswapTokens);
        justswapExchange.addLiquidity.value(justswapTrx)(
            justswapTokens,
            justswapTokens,
            now.add(1 hours)
        );
    }

    function issueTokens() external whenPresaleFinished {
        require(hasSentToJustswap, "Has not yet sent to Justswap.");
        require(!hasIssuedTokens, "Has already issued tokens.");
        hasIssuedTokens = true;
        for (uint i = 0; i < tokenPools.length; ++i) {
            token.mint(
                tokenPools[i],
                totalTokens.mulBP(tokenPoolBPs[i])
            );
        }
    }

    function sendTrx() external whenPresaleFinished nonReentrant {
        require(hasSentToJustswap, "Has not yet sent to Justswap.");
        require(!hasSentTrx, "Has already sent trx.");
        hasSentTrx = true;
        for (uint i = 0; i < trxPools.length; ++i) {
            trxPools[i].transfer(
                totalTrx.mulBP(trxPoolBPs[i])
            );
        }
        //remove dust
        if (address(this).balance > 0) {
            trxPools[0].transfer(
                address(this).balance
            );
        }
    }

    function emergencyTrxWithdraw() external whenPresaleFinished nonReentrant onlyOwner {
        require(hasSentToJustswap, "Has not yet sent to Justswap.");
        msg.sender.transfer(address(this).balance);
    }

    function setDepositPause(bool val) external onlyOwner {
        pauseDeposit = val;
    }

    function redeem() external whenPresaleFinished {
        require(hasSentToJustswap, "Must have sent to Justswap before any redeems.");
        uint claimable = calculateRedeemable(msg.sender);
        accountClaimedMaze[msg.sender] = accountClaimedMaze[msg.sender].add(claimable);
        token.mint(msg.sender, claimable);
    }

    function getDepositInTrx(address user) public view returns (uint) {
        return depositAccounts[user];
    }

    function deposit(address payable referrer) public payable whenPresaleActive nonReentrant {
        require(!pauseDeposit, "Deposits are paused.");
        require(
            depositAccounts[msg.sender].add(msg.value) <= maxBuyPerAddress,
            "Deposit exceeds max buy per address."
        );
        require(
            depositAccounts[msg.sender].add(msg.value) >= minBuyPerAddress,
            "Must purchase at least 100 trx."
        );

        if (depositAccounts[msg.sender] == 0) totalDepositors = totalDepositors.add(1);

        uint depositVal = msg.value;
        uint tokensToIssue = depositVal.mul(10 ** 12).mul(getCurrentPrice());
        depositAccounts[msg.sender] = depositAccounts[msg.sender].add(depositVal);

        totalTokens = totalTokens.add(tokensToIssue);

        accountEarnedMaze[msg.sender] = accountEarnedMaze[msg.sender].add(tokensToIssue);

        if (referrer != msg.sender && referrer != address(0x0)) {
            uint referralValue = msg.value.sub(depositVal.subBP(referralBP));
            earnedReferrals[referrer] = earnedReferrals[referrer].add(referralValue);
            referralCounts[referrer] = referralCounts[referrer].add(1);
            referrer.transfer(referralValue);
        }
    }

    function calculateRedeemable(address account) public view returns (uint) {
        if (finalEndTime == 0) return 0;
        uint earnedMaze = accountEarnedMaze[account];
        uint claimedMaze = accountClaimedMaze[account];
        uint cycles = now.sub(finalEndTime).div(redeemInterval).add(1);
        uint totalRedeemable = earnedMaze.mulBP(redeemBP).mul(cycles);
        uint claimable;
        if (totalRedeemable >= earnedMaze) {
            claimable = earnedMaze.sub(claimedMaze);
        } else {
            claimable = totalRedeemable.sub(claimedMaze);
        }
        return claimable;
    }

    function getCurrentPrice() public view returns (uint) {
        uint _price = price;
        if (totalDepositors <= 50) {
            _price = _price.add(3);
        }
        if (totalDepositors <= 100) {
            _price = _price.add(2);
        }
        return _price;
    }

    function isPresaleEnded() public view returns (bool) {
        return (
        (timer.isStarted() && (now > timer.getEndTime(address(this).balance)))
        );
    }

}