// SPDX-License-Identifier: MIT

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    constructor() {
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
        return msg.data;
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IDividendDistributor.sol';

contract DividendDistributor is IDividendDistributor, ReentrancyGuard {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;

    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 1e36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1e18;

    uint256 currentIndex;

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor() {
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        totalDividends = totalDividends.add(msg.value);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(msg.value).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return
            shareholderClaims[shareholder] + minPeriod < block.timestamp &&
            getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            TransferHelper.safeTransferETH(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function claimDividend() external nonReentrant {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './interfaces/IERC20.sol';
import './interfaces/IShipTicketNFT.sol';
import './interfaces/IShipDividendDistributor.sol';

contract ShipDividendDistributor is IShipDividendDistributor, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 ECONOMY = 0;
    uint256 BUSINESS = 1;

    address _token;

    IERC20 token;
    IShipTicketNFT economyTicketNFT;
    IShipTicketNFT businessTicketNFT;

    struct Share {
        uint256 totalRealised;
        uint256 dividendsDebt;
        bool validated;
    }

    struct ShareInfo {
        uint256 totalShares;
        uint256 totalDividends;
        uint256 totalDistributed;
        uint256 dividendsPerShare;
    }

    mapping(uint256 => Share) public economyShares;
    ShareInfo public economyShareInfo;

    mapping(uint256 => Share) public businessShares;
    ShareInfo public businessShareInfo;

    uint256 public dividendsPerShareAccuracyFactor = 1e6;
    uint256 totalDistributed;

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(address _economyTicketNFT, address _businessTicketNFT) {
        _token = msg.sender;

        token = IERC20(_token);
        economyTicketNFT = IShipTicketNFT(_economyTicketNFT);
        businessTicketNFT = IShipTicketNFT(_businessTicketNFT);

        economyShareInfo = ShareInfo({
            totalShares: economyTicketNFT.totalSupply(),
            totalDividends: 0,
            totalDistributed: 0,
            dividendsPerShare: 0
        });
        businessShareInfo = ShareInfo({
            totalShares: businessTicketNFT.totalSupply(),
            totalDividends: 0,
            totalDistributed: 0,
            dividendsPerShare: 0
        });
    }

    function deposit(uint256 _economyAmount, uint256 _businessAmount) external override onlyToken {
        uint256 totalShares = economyTicketNFT.totalSupply();
        uint256 dividendsPerShare = economyShareInfo.dividendsPerShare.add(
            _economyAmount.mul(dividendsPerShareAccuracyFactor).div(totalShares)
        );
        economyShareInfo.totalShares = totalShares;
        economyShareInfo.totalDividends = economyShareInfo.totalDividends.add(_economyAmount);
        economyShareInfo.dividendsPerShare = dividendsPerShare;

        totalShares = businessTicketNFT.totalSupply();
        dividendsPerShare = businessShareInfo.dividendsPerShare.add(
            _businessAmount.mul(dividendsPerShareAccuracyFactor).div(totalShares)
        );
        businessShareInfo.totalShares = totalShares;
        businessShareInfo.totalDividends = businessShareInfo.totalDividends.add(_businessAmount);
        businessShareInfo.dividendsPerShare = dividendsPerShare;
    }

    function validateEconomyTicket(uint256 ticketId) public {
        require(economyTicketNFT.ownerOf(ticketId) != address(0), 'ShipDividendDistributor: Invalid ticketId');

        if (economyShares[ticketId].validated == true) {
            return;
        }
        economyShares[ticketId].validated = true;
        economyShares[ticketId].dividendsDebt = economyShareInfo.dividendsPerShare;
    }

    function claimEconomyDividend(uint256 ticketId) external nonReentrant {
        require(msg.sender == economyTicketNFT.ownerOf(ticketId), 'ShipDividendDistributor: Invalid ticketId');

        uint256 amount = getEconomyUnpaidEarnings(ticketId);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            economyShareInfo.totalDistributed = economyShareInfo.totalDistributed.add(amount);
            economyShares[ticketId].totalRealised = economyShares[ticketId].totalRealised.add(amount);
            economyShares[ticketId].dividendsDebt = economyShareInfo.dividendsPerShare;
            token.transfer(msg.sender, amount);
        }
    }

    function getEconomyUnpaidEarnings(uint256 ticketId) public view returns (uint256) {
        if (economyShares[ticketId].validated != true) {
            return 0;
        }

        return
            economyShareInfo.dividendsPerShare.sub(economyShares[ticketId].dividendsDebt).div(
                dividendsPerShareAccuracyFactor
            );
    }

    function validateBusinessTicket(uint256 ticketId) public {
        require(businessTicketNFT.ownerOf(ticketId) != address(0), 'ShipDividendDistributor: Invalid ticketId');

        if (businessShares[ticketId].validated == true) {
            return;
        }
        businessShares[ticketId].validated = true;
        businessShares[ticketId].dividendsDebt = businessShareInfo.dividendsPerShare;
    }

    function claimBusinessDividend(uint256 ticketId) external nonReentrant {
        require(msg.sender == businessTicketNFT.ownerOf(ticketId), 'ShipDividendDistributor: Invalid ticketId');

        uint256 amount = getBusinessUnpaidEarnings(ticketId);
        if (amount > 0) {
            businessShareInfo.totalDistributed = businessShareInfo.totalDistributed.add(amount);
            businessShares[ticketId].totalRealised = businessShares[ticketId].totalRealised.add(amount);
            businessShares[ticketId].dividendsDebt = businessShareInfo.dividendsPerShare;
            token.transfer(msg.sender, amount);
        }
    }

    function getBusinessUnpaidEarnings(uint256 ticketId) public view returns (uint256) {
        if (businessShares[ticketId].validated != true) {
            return 0;
        }

        return
            businessShareInfo.dividendsPerShare.sub(businessShares[ticketId].dividendsDebt).div(
                dividendsPerShareAccuracyFactor
            );
    }

    function validateTickets() external nonReentrant {
        for (uint256 i = 0; i < economyTicketNFT.totalSupply(); i++) {
            validateEconomyTicket(i);
        }

        for (uint256 i = 0; i < businessTicketNFT.totalSupply(); i++) {
            validateBusinessTicket(i);
        }
    }

    function isValidated(uint256 ticketClass, uint256 ticketId) external view returns (bool) {
        if (ticketClass == ECONOMY) {
            return economyShares[ticketId].validated;
        }
        if (ticketId == BUSINESS) {
            return businessShares[ticketId].validated;
        }
        return false;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IERC20.sol';
import './interfaces/IDEXFactory.sol';
import './interfaces/IDEXRouter.sol';
import './DividendDistributor.sol';
import './ShipDividendDistributor.sol';

contract Sterbund is Context, Ownable, IERC20 {
    using SafeMath for uint256;

    address private constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; // WBNB on testnet
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = 'Sterbund';
    string constant _symbol = 'HARPA';
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 1000000000 * (10**_decimals); // 1,000,000,000
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public isDividendExempt;
    mapping(address => uint256) public cooldowns;
    uint256 private cooldownLength = 20 seconds;

    uint256 public _maxTxAmount = _totalSupply / 2000; // 0.05%

    uint256 private feeDenominator = 10000;
    uint256 private reflectionFee = 500;
    uint256 private marketingFee = 300;
    uint256 private economyTicketFee = 50;
    uint256 private businessTicketFee = 50;
    uint256 public totalFee = 900;

    address public marketingFeeReceiver;

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;

    uint256 public feeExemptStartAt;
    uint256 public feeExemptLength;

    DividendDistributor public distributor;
    uint256 private distributorGas = 500000;

    ShipDividendDistributor public shipDistributor;

    bool public swapBackEnabled = true;
    uint256 public swapBackThreshold = _totalSupply / 20000; // 0.005%
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        address _router,
        address _economyTicket,
        address _businessTicket
    ) {
        // PancakeswapRouter mainnet
        router = _router != ZERO ? IDEXRouter(_router) : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        distributor = new DividendDistributor();
        shipDistributor = new ShipDividendDistributor(_economyTicket, _businessTicket);

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;

        marketingFeeReceiver = msg.sender;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(ZERO, msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, 'Insufficient Allowance');
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (sender == pair) {
            require(cooldowns[recipient].add(cooldownLength) < block.timestamp, 'Under cooldown period');
        }

        checkTxLimit(sender, amount);

        if (shouldSwapBack()) {
            swapBack();
        }

        if (!launched() && recipient == pair) {
            require(_balances[sender] > 0);
            launch();
        }

        _balances[sender] = _balances[sender].sub(amount, 'Insufficient Balance');

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if (!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }
        if (!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, _balances[recipient]) {} catch {}
        }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);

        if (sender == pair) {
            _setCooldown(recipient);
        }

        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, 'Insufficient Balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _setCooldown(address recipient) internal {
        if (launchedAt.add(cooldownLength) >= block.timestamp) {
            cooldowns[recipient] = block.timestamp;
        }
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], 'TX Limit Exceeded');
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool buying) public view returns (uint256) {
        if (
            buying &&
            feeExemptStartAt != 0 &&
            feeExemptStartAt <= block.timestamp &&
            feeExemptStartAt.add(feeExemptLength) >= block.timestamp
        ) {
            return economyTicketFee.add(businessTicketFee);
        }
        return totalFee;
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 economyTicketFeeAmount = amount.mul(economyTicketFee).div(feeDenominator);
        uint256 businessTicketFeeAmount = amount.mul(businessTicketFee).div(feeDenominator);
        uint256 ticketFeeAmount = economyTicketFeeAmount.add(businessTicketFeeAmount);
        uint256 feeAmount = amount.mul(getTotalFee(sender == pair)).div(feeDenominator);

        if (ticketFeeAmount >= feeAmount) {
            feeAmount = 0;
        }

        _balances[address(shipDistributor)] = _balances[address(shipDistributor)].add(ticketFeeAmount);
        emit Transfer(sender, address(shipDistributor), ticketFeeAmount);
        shipDistributor.deposit(economyTicketFeeAmount, businessTicketFeeAmount);

        if (feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair && !inSwap && swapBackEnabled && _balances[address(this)] >= swapBackThreshold;
    }

    function swapBack() internal swapping {
        uint256 amountToSwap = swapBackThreshold;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFee;
        uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        TransferHelper.safeTransferETH(marketingFeeReceiver, amountBNBMarketing);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.timestamp;
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt) public onlyOwner {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(
        uint256 _reflectionFee,
        uint256 _marketingFee,
        uint256 _economyTicketFee,
        uint256 _businessTicketFee,
        uint256 _feeDenominator
    ) external onlyOwner {
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        economyTicketFee = _economyTicketFee;
        businessTicketFee = _businessTicketFee;
        totalFee = _reflectionFee.add(_marketingFee).add(_economyTicketFee).add(_businessTicketFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator / 5);
    }

    function setFeeReceivers(address _marketingFeeReceiver) external onlyOwner {
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapBackEnabled = _enabled;
        swapBackThreshold = _amount;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
    }

    function setFeeExemptSettings(uint256 startAt, uint256 length) external onlyOwner {
        require(startAt > block.timestamp);
        feeExemptStartAt = startAt;
        feeExemptLength = length;
    }

    function clearFeeExempt() external onlyOwner {
        feeExemptStartAt = 0;
        feeExemptLength = 0;
    }

    function setIsAllExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
        isTxLimitExempt[holder] = exempt;
        setIsDividendExempt(holder, exempt);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit() external payable;

    function process(uint256 gas) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/**
 * ERC20 standard interface.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IShipDividendDistributor {
    function deposit(uint256 economyAmount, uint256 businessAmount) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IShipTicketNFT {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function balanceOf(address owner) external view returns (uint256 balance);

    function totalSupply() external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

