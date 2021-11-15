pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "../lib/ReentrancyGuard.sol";
import "../lib/Utils.sol";
import "../lib/SafePeakToken.sol";
import "../interfaces/IPeakToken.sol";
import "../interfaces/IPeakDeFiFund.sol";
import "../interfaces/IUniswapOracle.sol";
import "../interfaces/IProtectionStaking.sol";


contract ProtectionStaking is IProtectionStaking, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafePeakToken for IPeakToken;

    address public sharesToken;

    IPeakDeFiFund public fund;
    IPeakToken public peakToken;
    IUniswapOracle public uniswapOracle;

    uint256 public mintedPeakTokens;
    uint256 public peakMintCap = 5000000 * PEAK_PRECISION; // default 5 million PEAK
    uint256 internal constant PEAK_PRECISION = 10**8;
    uint256 internal constant USDC_PRECISION = 10**6;
    uint256 internal constant PERCENTS_DECIMALS = 10**20;

    mapping(address => uint256) public peaks;
    mapping(address => uint256) public shares;
    mapping(address => uint256) public startProtectTimestamp;
    mapping(address => uint256) internal _lastClaimTimestamp;
    mapping(address => uint256) public lastClaimAmount;

    event ClaimCompensation(
        address investor,
        uint256 amount,
        uint256 timestamp
    );
    event RequestProtection(
        address investor,
        uint256 amount,
        uint256 timestamp
    );
    event Withdraw(address investor, uint256 amount, uint256 timestamp);
    event ProtectShares(address investor, uint256 amount, uint256 timestamp);
    event WithdrawShares(address investor, uint256 amount, uint256 timestamp);
    event ChangePeakMintCap(uint256 newAmmount);

    modifier during(IPeakDeFiFund.CyclePhase phase) {
        require(fund.cyclePhase() == phase, "wrong phase");
        if (fund.cyclePhase() == IPeakDeFiFund.CyclePhase.Intermission) {
            require(fund.isInitialized(), "fund not initialized");
        }
        _;
    }

    modifier ifNoCompensation() {
        uint256 peakPriceInUsdc = _getPeakPriceInUsdc();
        uint256 compensationAmount = _calculateCompensating(
            msg.sender,
            peakPriceInUsdc
        );
        require(compensationAmount == 0, "have compensation");
        _;
    }

    constructor(
        address payable _fundAddr,
        address _peakTokenAddr,
        address _sharesTokenAddr,
        address _uniswapOracle
    ) public {
        __initReentrancyGuard();
        require(_fundAddr != address(0));
        require(_peakTokenAddr != address(0));

        fund = IPeakDeFiFund(_fundAddr);
        peakToken = IPeakToken(_peakTokenAddr);
        uniswapOracle = IUniswapOracle(_uniswapOracle);
        sharesToken = _sharesTokenAddr;
    }

    function() external {}

    function _lostFundAmount(address _investor)
        internal
        view
        returns (uint256 lostFundAmount)
    {
        uint256 totalLostFundAmount = fund.totalLostFundAmount();
        uint256 investorLostFundAmount = lastClaimAmount[_investor];
        lostFundAmount = totalLostFundAmount.sub(investorLostFundAmount);
    }

    function _calculateCompensating(address _investor, uint256 _peakPriceInUsdc)
        internal
        view
        returns (uint256)
    {
        uint256 totalFundsAtManagePhaseStart = fund
        .totalFundsAtManagePhaseStart();
        uint256 totalShares = fund.totalSharesAtLastManagePhaseStart();
        uint256 managePhaseStartTime = fund.startTimeOfLastManagementPhase();
        uint256 lostFundAmount = _lostFundAmount(_investor);
        uint256 sharesAmount = shares[_investor];
        if (
            fund.cyclePhase() != IPeakDeFiFund.CyclePhase.Intermission ||
            managePhaseStartTime < _lastClaimTimestamp[_investor] ||
            managePhaseStartTime < startProtectTimestamp[_investor] ||
            mintedPeakTokens >= peakMintCap ||
            peaks[_investor] == 0 ||
            lostFundAmount == 0 ||
            totalShares == 0 ||
            _peakPriceInUsdc == 0 ||
            sharesAmount == 0
        ) {
            return 0;
        }
        uint256 sharesInUsdcAmount = sharesAmount
        .mul(totalFundsAtManagePhaseStart)
        .div(totalShares);
        uint256 peaksInUsdcAmount = peaks[_investor].mul(_peakPriceInUsdc).div(
            PEAK_PRECISION
        );
        uint256 protectedPercent = PERCENTS_DECIMALS;
        if (peaksInUsdcAmount < sharesInUsdcAmount) {
            protectedPercent = peaksInUsdcAmount.mul(PERCENTS_DECIMALS).div(
                sharesInUsdcAmount
            );
        }
        uint256 ownLostFundInUsd = lostFundAmount.mul(sharesAmount).div(
            totalShares
        );
        uint256 compensationInUSDC = ownLostFundInUsd.mul(protectedPercent).div(
            PERCENTS_DECIMALS
        );
        uint256 compensationInPeak = compensationInUSDC.mul(PEAK_PRECISION).div(
            _peakPriceInUsdc
        );
        if (peakMintCap - mintedPeakTokens < compensationInPeak) {
            compensationInPeak = peakMintCap - mintedPeakTokens;
        }
        return compensationInPeak;
    }

    function calculateCompensating(address _investor, uint256 _peakPriceInUsdc)
        public
        view
        returns (uint256)
    {
        return _calculateCompensating(_investor, _peakPriceInUsdc);
    }

    function updateLastClaimAmount() internal {
        lastClaimAmount[msg.sender] = fund.totalLostFundAmount();
    }

    function claimCompensation()
        external
        during(IPeakDeFiFund.CyclePhase.Intermission)
        nonReentrant
    {
        uint256 peakPriceInUsdc = _getPeakPriceInUsdc();
        uint256 compensationAmount = _calculateCompensating(
            msg.sender,
            peakPriceInUsdc
        );
        require(compensationAmount > 0, "not have compensation");
        _lastClaimTimestamp[msg.sender] = block.timestamp;
        peakToken.mint(msg.sender, compensationAmount);
        mintedPeakTokens = mintedPeakTokens.add(compensationAmount);
        require(
            mintedPeakTokens <= peakMintCap,
            "ProtectionStaking: reached cap"
        );
        updateLastClaimAmount();
        emit ClaimCompensation(msg.sender, compensationAmount, block.timestamp);
    }

    function requestProtection(uint256 _amount)
        external
        during(IPeakDeFiFund.CyclePhase.Intermission)
        nonReentrant
        ifNoCompensation
    {
        require(_amount > 0, "amount is 0");
        peakToken.safeTransferFrom(msg.sender, address(this), _amount);
        peaks[msg.sender] = peaks[msg.sender].add(_amount);
        startProtectTimestamp[msg.sender] = block.timestamp;
        updateLastClaimAmount();
        emit RequestProtection(msg.sender, _amount, block.timestamp);
    }

    function withdraw(uint256 _amount) external ifNoCompensation {
        require(
            peaks[msg.sender] >= _amount,
            "insufficient fund in Peak Token"
        );
        require(_amount > 0, "amount is 0");
        peaks[msg.sender] = peaks[msg.sender].sub(_amount);
        peakToken.safeTransfer(msg.sender, _amount);
        updateLastClaimAmount();
        emit Withdraw(msg.sender, _amount, block.timestamp);
    }

    function protectShares(uint256 _amount)
        external
        nonReentrant
        during(IPeakDeFiFund.CyclePhase.Intermission)
        ifNoCompensation
    {
        require(_amount > 0, "amount is 0");
        IERC20(sharesToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        startProtectTimestamp[msg.sender] = block.timestamp;
        shares[msg.sender] = shares[msg.sender].add(_amount);
        updateLastClaimAmount();
        emit ProtectShares(msg.sender, _amount, block.timestamp);
    }

    function withdrawShares(uint256 _amount)
        external
        nonReentrant
        ifNoCompensation
    {
        require(
            shares[msg.sender] >= _amount,
            "insufficient fund in Share Token"
        );
        require(_amount > 0, "amount is 0");
        shares[msg.sender] = shares[msg.sender].sub(_amount);
        IERC20(sharesToken).safeTransfer(msg.sender, _amount);
        emit WithdrawShares(msg.sender, _amount, block.timestamp);
    }

    function setPeakMintCap(uint256 _amount) external onlyOwner {
        require(mintedPeakTokens < _amount, "wrong amount");
        peakMintCap = _amount;
        emit ChangePeakMintCap(_amount);
    }

    function _getPeakPriceInUsdc() internal returns (uint256) {
        uniswapOracle.update();
        uint256 priceInUSDC = uniswapOracle.consult(
            address(peakToken),
            PEAK_PRECISION
        );
        if (priceInUSDC == 0) {
            return USDC_PRECISION.mul(3).div(10);
        }
        return priceInUSDC;
    }
}

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

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
     * NOTE: Renouncing ownership will leave the contract without an owner,
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
}

pragma solidity 0.5.17;

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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    function __initReentrancyGuard() internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IKyberNetwork.sol";

/**
 * @title The smart contract for useful utility functions and constants.
 * @author Zefram Lou (Zebang Liu)
 */
contract Utils {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Detailed;

    /**
     * @notice Checks if `_token` is a valid token.
     * @param _token the token's address
     */
    modifier isValidToken(address _token) {
        require(_token != address(0));
        if (_token != address(ETH_TOKEN_ADDRESS)) {
            require(isContract(_token));
        }
        _;
    }

    address public USDC_ADDR;
    address payable public KYBER_ADDR;
    address payable public ONEINCH_ADDR;

    bytes public constant PERM_HINT = "PERM";

    // The address Kyber Network uses to represent Ether
    ERC20Detailed internal constant ETH_TOKEN_ADDRESS =
        ERC20Detailed(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    ERC20Detailed internal usdc;
    IKyberNetwork internal kyber;

    uint256 internal constant PRECISION = (10**18);
    uint256 internal constant MAX_QTY = (10**28); // 10B tokens
    uint256 internal constant ETH_DECIMALS = 18;
    uint256 internal constant MAX_DECIMALS = 18;

    constructor(
        address _usdcAddr,
        address payable _kyberAddr,
        address payable _oneInchAddr
    ) public {
        USDC_ADDR = _usdcAddr;
        KYBER_ADDR = _kyberAddr;
        ONEINCH_ADDR = _oneInchAddr;

        usdc = ERC20Detailed(_usdcAddr);
        kyber = IKyberNetwork(_kyberAddr);
    }

    /**
     * @notice Get the number of decimals of a token
     * @param _token the token to be queried
     * @return number of decimals
     */
    function getDecimals(ERC20Detailed _token) internal view returns (uint256) {
        if (address(_token) == address(ETH_TOKEN_ADDRESS)) {
            return uint256(ETH_DECIMALS);
        }
        return uint256(_token.decimals());
    }

    /**
     * @notice Get the token balance of an account
     * @param _token the token to be queried
     * @param _addr the account whose balance will be returned
     * @return token balance of the account
     */
    function getBalance(ERC20Detailed _token, address _addr)
        internal
        view
        returns (uint256)
    {
        if (address(_token) == address(ETH_TOKEN_ADDRESS)) {
            return uint256(_addr.balance);
        }
        return uint256(_token.balanceOf(_addr));
    }

    /**
     * @notice Calculates the rate of a trade. The rate is the price of the source token in the dest token, in 18 decimals.
     *         Note: the rate is on the token level, not the wei level, so for example if 1 Atoken = 10 Btoken, then the rate
     *         from A to B is 10 * 10**18, regardless of how many decimals each token uses.
     * @param srcAmount amount of source token
     * @param destAmount amount of dest token
     * @param srcDecimals decimals used by source token
     * @param dstDecimals decimals used by dest token
     */
    function calcRateFromQty(
        uint256 srcAmount,
        uint256 destAmount,
        uint256 srcDecimals,
        uint256 dstDecimals
    ) internal pure returns (uint256) {
        require(srcAmount <= MAX_QTY);
        require(destAmount <= MAX_QTY);

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return ((destAmount * PRECISION) /
                ((10**(dstDecimals - srcDecimals)) * srcAmount));
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return ((destAmount *
                PRECISION *
                (10**(srcDecimals - dstDecimals))) / srcAmount);
        }
    }

    /**
     * @notice Wrapper function for doing token conversion on Kyber Network
     * @param _srcToken the token to convert from
     * @param _srcAmount the amount of tokens to be converted
     * @param _destToken the destination token
     * @return _destPriceInSrc the price of the dest token, in terms of source tokens
     *         _srcPriceInDest the price of the source token, in terms of dest tokens
     *         _actualDestAmount actual amount of dest token traded
     *         _actualSrcAmount actual amount of src token traded
     */
    function __kyberTrade(
        ERC20Detailed _srcToken,
        uint256 _srcAmount,
        ERC20Detailed _destToken
    )
        internal
        returns (
            uint256 _destPriceInSrc,
            uint256 _srcPriceInDest,
            uint256 _actualDestAmount,
            uint256 _actualSrcAmount
        )
    {
        require(_srcToken != _destToken);

        uint256 beforeSrcBalance = getBalance(_srcToken, address(this));
        uint256 msgValue;
        if (_srcToken != ETH_TOKEN_ADDRESS) {
            msgValue = 0;
            _srcToken.safeApprove(KYBER_ADDR, 0);
            _srcToken.safeApprove(KYBER_ADDR, _srcAmount);
        } else {
            msgValue = _srcAmount;
        }
        _actualDestAmount = kyber.tradeWithHint.value(msgValue)(
            _srcToken,
            _srcAmount,
            _destToken,
            toPayableAddr(address(this)),
            MAX_QTY,
            1,
            address(0),
            PERM_HINT
        );
        _actualSrcAmount = beforeSrcBalance.sub(
            getBalance(_srcToken, address(this))
        );
        require(_actualDestAmount > 0 && _actualSrcAmount > 0);
        _destPriceInSrc = calcRateFromQty(
            _actualDestAmount,
            _actualSrcAmount,
            getDecimals(_destToken),
            getDecimals(_srcToken)
        );
        _srcPriceInDest = calcRateFromQty(
            _actualSrcAmount,
            _actualDestAmount,
            getDecimals(_srcToken),
            getDecimals(_destToken)
        );
    }

    /**
     * @notice Wrapper function for doing token conversion on 1inch
     * @param _srcToken the token to convert from
     * @param _srcAmount the amount of tokens to be converted
     * @param _destToken the destination token
     * @return _destPriceInSrc the price of the dest token, in terms of source tokens
     *         _srcPriceInDest the price of the source token, in terms of dest tokens
     *         _actualDestAmount actual amount of dest token traded
     *         _actualSrcAmount actual amount of src token traded
     */
    function __oneInchTrade(
        ERC20Detailed _srcToken,
        uint256 _srcAmount,
        ERC20Detailed _destToken,
        bytes memory _calldata
    )
        internal
        returns (
            uint256 _destPriceInSrc,
            uint256 _srcPriceInDest,
            uint256 _actualDestAmount,
            uint256 _actualSrcAmount
        )
    {
        require(_srcToken != _destToken);

        uint256 beforeSrcBalance = getBalance(_srcToken, address(this));
        uint256 beforeDestBalance = getBalance(_destToken, address(this));
        // Note: _actualSrcAmount is being used as msgValue here, because otherwise we'd run into the stack too deep error
        if (_srcToken != ETH_TOKEN_ADDRESS) {
            _actualSrcAmount = 0;
            _srcToken.safeApprove(ONEINCH_ADDR, 0);
            _srcToken.safeApprove(ONEINCH_ADDR, _srcAmount);
        } else {
            _actualSrcAmount = _srcAmount;
        }

        // trade through 1inch proxy
        (bool success, ) = ONEINCH_ADDR.call.value(_actualSrcAmount)(_calldata);
        require(success);

        // calculate trade amounts and price
        _actualDestAmount = getBalance(_destToken, address(this)).sub(
            beforeDestBalance
        );
        _actualSrcAmount = beforeSrcBalance.sub(
            getBalance(_srcToken, address(this))
        );
        require(_actualDestAmount > 0 && _actualSrcAmount > 0);
        _destPriceInSrc = calcRateFromQty(
            _actualDestAmount,
            _actualSrcAmount,
            getDecimals(_destToken),
            getDecimals(_srcToken)
        );
        _srcPriceInDest = calcRateFromQty(
            _actualSrcAmount,
            _actualDestAmount,
            getDecimals(_srcToken),
            getDecimals(_destToken)
        );
    }

    /**
     * @notice Checks if an Ethereum account is a smart contract
     * @param _addr the account to be checked
     * @return True if the account is a smart contract, false otherwise
     */
    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        if (_addr == address(0)) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function toPayableAddr(address _addr)
        internal
        pure
        returns (address payable)
    {
        return address(uint160(_addr));
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IPeakToken.sol";

/**
 * @title SafePeakToken
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafePeakToken {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IPeakToken token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IPeakToken token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IPeakToken token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IPeakToken token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IPeakToken token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IPeakToken token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity 0.5.17;


interface IPeakToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mint(address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

pragma solidity 0.5.17;

interface IPeakDeFiFund {
    enum CyclePhase {
        Intermission,
        Manage
    }

    enum VoteDirection {
        Empty,
        For,
        Against
    }

    enum Subchunk {
        Propose,
        Vote
    }

    function initParams(
        address payable _devFundingAccount,
        uint256[2] calldata _phaseLengths,
        uint256 _devFundingRate,
        address payable _previousVersion,
        address _usdcAddr,
        address payable _kyberAddr,
        address _compoundFactoryAddr,
        address _peakdefiLogic,
        address _peakdefiLogic2,
        address _peakdefiLogic3,
        uint256 _startCycleNumber,
        address payable _oneInchAddr,
        address _peakRewardAddr,
        address _peakStakingAddr
    ) external;

    function initOwner() external;

    function cyclePhase() external view returns (CyclePhase phase);

    function isInitialized() external view returns (bool);

    function devFundingAccount() external view returns (uint256);

    function previousVersion() external view returns (uint256);

    function cycleNumber() external view returns (uint256);

    function totalFundsInUSDC() external view returns (uint256);

    function totalFundsAtManagePhaseStart() external view returns (uint256);

    function totalLostFundAmount() external view returns (uint256);

    function totalFundsAtManagePhaseEnd() external view returns (uint256);

    function startTimeOfCyclePhase() external view returns (uint256);

    function startTimeOfLastManagementPhase() external view returns (uint256);

    function devFundingRate() external view returns (uint256);

    function totalCommissionLeft() external view returns (uint256);

    function totalSharesAtLastManagePhaseStart() external view returns (uint256);

    function peakReferralTotalCommissionLeft() external view returns (uint256);

    function peakManagerStakeRequired() external view returns (uint256);

    function peakReferralToken() external view returns (uint256);

    function peakReward() external view returns (address);

    function peakStaking() external view returns (address);

    function isPermissioned() external view returns (bool);

    function initInternalTokens(
        address _repAddr,
        address _sTokenAddr,
        address _peakReferralTokenAddr
    ) external;

    function initRegistration(
        uint256 _newManagerRepToken,
        uint256 _maxNewManagersPerCycle,
        uint256 _reptokenPrice,
        uint256 _peakManagerStakeRequired,
        bool _isPermissioned
    ) external;

    function initTokenListings(
        address[] calldata _acceptedTokens,
        address[] calldata _compoundTokens
    ) external;

    function setProxy(address payable proxyAddr) external;

    function developerInitiateUpgrade(address payable _candidate) external returns (bool _success);

    function migrateOwnedContractsToNextVersion() external;

    function transferAssetToNextVersion(address _assetAddress) external;

    function investmentsCount(address _userAddr)
        external
        view
        returns (uint256 _count);

    function nextVersion()
        external
        view
        returns (address payable);

    function transferOwnership(address newOwner) external;

    function compoundOrdersCount(address _userAddr)
        external
        view
        returns (uint256 _count);

    function getPhaseLengths()
        external
        view
        returns (uint256[2] memory _phaseLengths);

    function commissionBalanceOf(address _manager)
        external
        returns (uint256 _commission, uint256 _penalty);

    function commissionOfAt(address _manager, uint256 _cycle)
        external
        returns (uint256 _commission, uint256 _penalty);

    function changeDeveloperFeeAccount(address payable _newAddr) external;

    function changeDeveloperFeeRate(uint256 _newProp) external;

    function listKyberToken(address _token) external;

    function listCompoundToken(address _token) external;

    function nextPhase() external;

    function registerWithUSDC() external;

    function registerWithETH() external payable;

    function registerWithToken(address _token, uint256 _donationInTokens) external;

    function depositEther(address _referrer) external payable;

    function depositEtherAdvanced(
        bool _useKyber,
        bytes calldata _calldata,
        address _referrer
    ) external payable;

    function depositUSDC(uint256 _usdcAmount, address _referrer) external;

    function depositToken(
        address _tokenAddr,
        uint256 _tokenAmount,
        address _referrer
    ) external;

    function depositTokenAdvanced(
        address _tokenAddr,
        uint256 _tokenAmount,
        bool _useKyber,
        bytes calldata _calldata,
        address _referrer
    ) external;

    function withdrawEther(uint256 _amountInUSDC) external;

    function withdrawEtherAdvanced(
        uint256 _amountInUSDC,
        bool _useKyber,
        bytes calldata _calldata
    ) external;

    function withdrawUSDC(uint256 _amountInUSDC) external;

    function withdrawToken(address _tokenAddr, uint256 _amountInUSDC) external;

    function withdrawTokenAdvanced(
        address _tokenAddr,
        uint256 _amountInUSDC,
        bool _useKyber,
        bytes calldata _calldata
    ) external;

    function redeemCommission(bool _inShares) external;

    function redeemCommissionForCycle(bool _inShares, uint256 _cycle) external;

    function sellLeftoverToken(address _tokenAddr, bytes calldata _calldata)
        external;

    function sellLeftoverCompoundOrder(address payable _orderAddress) external;

    function burnDeadman(address _deadman) external;

    function createInvestment(
        address _tokenAddress,
        uint256 _stake,
        uint256 _maxPrice
    ) external;

    function createInvestmentV2(
        address _sender,
        address _tokenAddress,
        uint256 _stake,
        uint256 _maxPrice,
        bytes calldata _calldata,
        bool _useKyber
    ) external;

    function sellInvestmentAsset(
        uint256 _investmentId,
        uint256 _tokenAmount,
        uint256 _minPrice
    ) external;

    function sellInvestmentAssetV2(
        address _sender,
        uint256 _investmentId,
        uint256 _tokenAmount,
        uint256 _minPrice,
        bytes calldata _calldata,
        bool _useKyber
    ) external;

    function createCompoundOrder(
        address _sender,
        bool _orderType,
        address _tokenAddress,
        uint256 _stake,
        uint256 _minPrice,
        uint256 _maxPrice
    ) external;

    function sellCompoundOrder(
        address _sender,
        uint256 _orderId,
        uint256 _minPrice,
        uint256 _maxPrice
    ) external;

    function repayCompoundOrder(
        address _sender,
        uint256 _orderId,
        uint256 _repayAmountInUSDC
    ) external;

    function emergencyExitCompoundTokens(
        address _sender,
        uint256 _orderId,
        address _tokenAddr,
        address _receiver
    ) external;

    function peakReferralCommissionBalanceOf(address _referrer) external returns (uint256 _commission);

    function peakReferralCommissionOfAt(address _referrer, uint256 _cycle) external returns (uint256 _commission);

    function peakReferralRedeemCommission() external;

    function peakReferralRedeemCommissionForCycle(uint256 _cycle) external;

    function peakChangeManagerStakeRequired(uint256 _newValue) external;
}

pragma solidity 0.5.17;

// interface for contract_v6/UniswapOracle.sol
interface IUniswapOracle {
    function update() external returns (bool success);

    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);
}

pragma solidity 0.5.17;


interface IProtectionStaking {
    function calculateCompensating(address _investor, uint256 _peakPriceInUsdc) external view returns (uint256);

    function claimCompensation() external;

    function requestProtection(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function protectShares(uint256 _amount) external;

    function withdrawShares(uint256 _amount) external;

    function setPeakMintCap(uint256 _amount) external;
}

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
contract Context {
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

pragma solidity ^0.5.0;

import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

/**
 * @title The interface for the Kyber Network smart contract
 * @author Zefram Lou (Zebang Liu)
 */
interface IKyberNetwork {
    function getExpectedRate(
        ERC20Detailed src,
        ERC20Detailed dest,
        uint256 srcQty
    ) external view returns (uint256 expectedRate, uint256 slippageRate);

    function tradeWithHint(
        ERC20Detailed src,
        uint256 srcAmount,
        ERC20Detailed dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address walletId,
        bytes calldata hint
    ) external payable returns (uint256);
}

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

