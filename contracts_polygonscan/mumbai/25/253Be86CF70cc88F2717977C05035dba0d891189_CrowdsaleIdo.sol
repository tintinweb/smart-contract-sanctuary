// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./library/INonStandardERC20.sol";
import "./library/TransferHelper.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interface/IUniswapRouter01.sol";
import "./interface/IUniswapFactory.sol";
import "./interface/IUniswapV2Pair.sol";

contract CrowdsaleIdo is ReentrancyGuard {
    using SafeMath for uint256;

    address public owner;

    //@notice the amount of token investor will recieve against 1 stableCoin
    uint256 public rate;

    ///@notice TokenAddress available for purchase in this Crowdsale
    IERC20 public token;

    /// @notice decimal of token that is available for purchase in this Crowdsale
    uint256 public tokenDecimal;

    uint256 public tokenRemainingForSale;

    /// @notice of LaunchpadFactory Contract
    address public LaunchpadFactory;

    IUniswapV2Router01 public shibaSwapRouter;

    IERC20 private usdc = IERC20(0x284F81e23cf7D9B91D42A94395ff60E28365aEdC); //0xb7a4F3E9097C08dA09517b5aB877F7a917224ede mainnet addresses
    IERC20 private dai = IERC20(0xdFBc69639C3816CFc6895552E594a23Abc12FA1a); //0xdFBc69639C3816CFc6895552E594a23Abc12FA1a
    IERC20 private usdt = IERC20(0xa5e964afe67fc1a5364e661df92f1a744ef6BF0C); //0x07de306FF27a2B630B1141956844eB1552B956B5
    IERC20 private weth = IERC20(0x6a5Bc4B1c7868c7F6e0dB7a562F70A22C19A145e);
    // Leash Token
    IERC20 public LeashToken =
        IERC20(0xaa1949F76B208e704Dd86Fd8a97EDC59B3F52049);
    IERC20 public ShibaToken =
        IERC20(0x15968B07FB48568E20f7A3E9Dd24a804D2d13656);

    /// @notice start of vesting period as a timestamp
    uint256 public vestingStart;

    /// @notice unlock duration from start time
    // uint256 public unlockPeriod = 30 days;
    uint256 public unlockPeriod = 1000; // 3 minutes

    /// @notice start of crowdsale as a timestamp
    uint256 public crowdsaleStartTime;

    /// @notice end of crowdsale as a timestamp
    uint256 public crowdsaleEndTime;

    /// @notice end of vesting period as a timestamp
    uint256 public vestingEnd;

    /// @notice Number of Tokens Allocated for crowdsale
    uint256 public crowdsaleTokenAllocated;

    /// @notice cliff duration in seconds
    uint256 public cliffDuration;

    /// @notice amount vested for a investor.
    mapping(address => uint256) public vestedAmount;

    /// @notice cumulative total of tokens drawn down (and transferred from the deposit account) per investor
    mapping(address => uint256) public totalDrawn;

    /// @notice last drawn down time (seconds) per investor
    mapping(address => uint256) public lastDrawnAt;

    mapping(address => uint256) public totalUsdAmountInvested;

    mapping(address => bool) public hasUserInvested;

    uint256 public totalUsersInvested;

    uint256 public leashLockPeriod;

    uint256 public maxUserUsdLimit;

    struct UserInfo {
        uint256 amountLocked; // How many leash tokens the user has provided.
        uint256 unlockTokenTime; //
        bool isParticipating;
    }

    mapping(address => UserInfo) public userInfo;
    /**
     * Event for Tokens purchase logging
     * @param investor who invested & got the tokens
     * @param investedAmount of stableCoin paid for purchase
     * @param tokenPurchased amount
     * @param stableCoin address used to invest
     * @param tokenRemaining amount of token still remaining for sale in crowdsale
     */
    event TokenPurchase(
        address indexed investor,
        uint256 investedAmount,
        uint256 indexed tokenPurchased,
        IERC20 indexed stableCoin,
        uint256 tokenRemaining
    );

    /// @notice event emitted when a successful drawn down of vesting tokens is made
    event DrawDown(
        address indexed _investor,
        uint256 _amount,
        uint256 indexed drawnTime
    );

    /// @notice event emitted when crowdsale is ended manually
    event CrowdsaleEndedManually(uint256 indexed crowdsaleEndedManuallyAt);

    /// @notice event emitted when the crowdsale raised funds are withdrawn by the owner
    event FundsWithdrawn(
        address indexed beneficiary,
        IERC20 indexed _token,
        uint256 amount
    );

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _owner, address _launchpad) public {
        require(_owner != address(0));
        require(_launchpad != address(0));

        LaunchpadFactory = _launchpad;
        owner = _owner;
        shibaSwapRouter = IUniswapV2Router01(
            0x9CdE82F96ce4b2aCCDDA0df66d838927c7e9bEc8
        );
    }

    /**
     * @notice initialize the Crowdsale contract. This is called only once upon Crowdsale creation and the LaunchpadFactory ensures the Crowdsale has the correct paramaters
     */

    function init(
        IERC20 _tokenAddress,
        uint256 _amount,
        uint256 _rate,
        uint256 _crowdsaleStartTime,
        uint256 _crowdsaleEndTime,
        uint256 _vestingStartTime,
        uint256 _vestingEndTime,
        uint256 _leashLockPeriod,
        uint256 _maxUserUsdLimit
    ) public {
        // require(msg.sender == address(LaunchpadFactory), "FORBIDDEN");
        TransferHelper.safeTransferFrom(
            address(_tokenAddress),
            msg.sender,
            address(this),
            _amount
        );
        token = _tokenAddress;
        rate = _rate;
        crowdsaleStartTime = _crowdsaleStartTime;
        crowdsaleEndTime = _crowdsaleEndTime;
        vestingStart = _vestingStartTime;
        vestingEnd = _vestingStartTime.add(unlockPeriod.mul(2));
        crowdsaleTokenAllocated = _amount;
        tokenRemainingForSale = _amount;
        cliffDuration = 0;
        tokenDecimal = token.decimals();
        leashLockPeriod = _leashLockPeriod;
        maxUserUsdLimit = _maxUserUsdLimit;
    }

    modifier isCrowdsaleOver() {
        require(
            _getNow() >= crowdsaleEndTime && crowdsaleEndTime != 0,
            "Crowdsale Not Ended Yet"
        );
        _;
    }

    function getQuoteToTokenAmount(
        uint256 _fromTokenAmount,
        address _fromTokenAddress,
        address _toTokenAddress
    ) public view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(
            IUniswapV2Factory(shibaSwapRouter.factory()).getPair(
                _fromTokenAddress,
                _toTokenAddress
            )
        );
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        address tokenA = pair.token0();
        (uint256 reserveA, uint256 reserveB) = _fromTokenAddress == tokenA
            ? (res0, res1)
            : (res1, res0);
        uint256 toTokenAmount = shibaSwapRouter.quote(
            _fromTokenAmount,
            reserveA,
            reserveB
        );
        return toTokenAmount;
    }

    function buyFromWhiteListCrypto(
        IERC20 _whiteListCrypto,
        uint256 _whiteListCryptoAmount
    ) external payable nonReentrant {
        require(_getNow() >= crowdsaleStartTime, "Crowdsale isnt started yet");
        require(
            address(_whiteListCrypto) == address(LeashToken) ||
                address(_whiteListCrypto) == address(ShibaToken)
        );
        if (crowdsaleEndTime != 0) {
            require(_getNow() < crowdsaleEndTime, "Crowdsale Ended");
        }

        uint256 cryptoPrice = getQuoteToTokenAmount(
            1e18,
            address(_whiteListCrypto),
            address(usdt)
        );

        uint256 leashPrice = getQuoteToTokenAmount(
            1e18,
            address(LeashToken),
            address(usdt)
        );

        uint256 amountUserCanInvest = maxUserUsdLimit.sub(
            totalUsdAmountInvested[msg.sender]
        );
        require(
            _whiteListCryptoAmount <=
                (amountUserCanInvest.mul(1e18)).div(cryptoPrice.mul(1e12))
        );

        uint256 tokenPurchased = _whiteListCryptoAmount
            .mul(cryptoPrice)
            .mul(rate)
            .div(1e6);

        tokenPurchased = tokenDecimal >= 36
            ? tokenPurchased.mul(10**(tokenDecimal - 36))
            : tokenPurchased.div(10**(36 - tokenDecimal));

        require(
            tokenPurchased <= tokenRemainingForSale,
            "Exceeding purchase amount"
        );
        // tokenPurchased / 2 / rate = dollar invested
        // leash price = dollars
        // total leash to be staked = dollar invested / leash price

        require(
            lockLeash(
                ((tokenPurchased.mul(1e18)).div(rate).div(2).mul(1e6)).div(
                    leashPrice
                )
            )
        );

        _whiteListCrypto.transferFrom(
            msg.sender,
            address(this),
            _whiteListCryptoAmount
        );

        if (!hasUserInvested[msg.sender]) {
            totalUsersInvested = totalUsersInvested.add(1);
            hasUserInvested[msg.sender] = true;
        }

        totalUsdAmountInvested[msg.sender] = totalUsdAmountInvested[msg.sender]
            .add((_whiteListCryptoAmount.mul(cryptoPrice.mul(1e12))).div(1e18));

        tokenRemainingForSale = tokenRemainingForSale.sub(tokenPurchased);
        _updateVestingSchedule(msg.sender, tokenPurchased);

        emit TokenPurchase(
            msg.sender,
            msg.value,
            tokenPurchased,
            weth,
            tokenRemainingForSale
        );
    }

    function lockLeash(uint256 _stakeAmount) internal returns (bool) {
        require(block.timestamp < crowdsaleEndTime, "Ido has started");
        require(
            LeashToken.balanceOf(msg.sender) >= _stakeAmount,
            "low balance of leash"
        );
        require(
            _stakeAmount > 0,
            "leash stake amount should be greater than zero"
        );

        UserInfo storage user = userInfo[msg.sender];

        // transfer leash amount that is unlockable
        if (block.timestamp >= user.unlockTokenTime && user.amountLocked > 0) {
            TransferHelper.safeTransfer(
                address(LeashToken),
                msg.sender,
                user.amountLocked
            );
        }

        TransferHelper.safeTransferFrom(
            address(LeashToken),
            msg.sender,
            address(this),
            _stakeAmount
        );
        user.amountLocked = user.amountLocked.add(_stakeAmount);
        user.isParticipating = true;
        user.unlockTokenTime = block.timestamp.add(leashLockPeriod);
        return true;
    }

    function unLockLeash() external nonReentrant returns (bool) {
        UserInfo storage user = userInfo[msg.sender];
        require(block.timestamp >= user.unlockTokenTime, "Ido has started");
        require(user.amountLocked > 0, "Not enough Leash Staked");

        uint256 _amountUnlocked = user.unlockTokenTime;
        user.unlockTokenTime = 0;
        TransferHelper.safeTransfer(
            address(LeashToken),
            msg.sender,
            _amountUnlocked
        );
        return true;
    }

    function _updateVestingSchedule(address _investor, uint256 _amount)
        internal
    {
        require(_investor != address(0), "Beneficiary cannot be empty");
        require(_amount > 0, "Amount cannot be empty");

        vestedAmount[_investor] = vestedAmount[_investor].add(_amount);
    }

    /**
     * @notice Vesting schedule and associated data for an investor
     * @return _amount
     * @return _totalDrawn
     * @return _lastDrawnAt
     * @return _remainingBalance
     * @return _availableForDrawDown
     */
    function vestingScheduleForBeneficiary(address _investor)
        external
        view
        returns (
            uint256 _amount,
            uint256 _totalDrawn,
            uint256 _lastDrawnAt,
            uint256 _remainingBalance,
            uint256 _availableForDrawDown
        )
    {
        return (
            vestedAmount[_investor],
            totalDrawn[_investor],
            lastDrawnAt[_investor],
            vestedAmount[_investor].sub(totalDrawn[_investor]),
            _availableDrawDownAmount(_investor)
        );
    }

    /**
     * @notice Draw down amount currently available (based on the block timestamp)
     * @param _investor beneficiary of the vested tokens
     * @return _amount tokens due from vesting schedule
     */
    function availableDrawDownAmount(address _investor)
        external
        view
        returns (uint256 _amount)
    {
        return _availableDrawDownAmount(_investor);
    }

    function _availableDrawDownAmount(address _investor)
        internal
        view
        returns (uint256 _amount)
    {
        uint256 firstUnlock = vestingStart.add(unlockPeriod);

        // Cliff Period
        if (_getNow() <= vestingStart.add(cliffDuration) || vestingStart == 0) {
            // the cliff period has not ended, no tokens to draw down
            return 0;
        }

        // Schedule complete
        if (_getNow() >= vestingEnd) {
            _amount = vestedAmount[_investor].sub(totalDrawn[_investor]);
            return _amount;
        }

        if (_getNow() >= firstUnlock && _getNow() < vestingEnd) {
            uint256 maxClaimable = (vestedAmount[_investor].mul(66)).div(100);
            uint256 userTotalClaimed = totalDrawn[_investor];
            if (userTotalClaimed < maxClaimable) {
                _amount = maxClaimable - userTotalClaimed;
            }
            return _amount;
        }

        if (
            _getNow() >= vestingStart.add(cliffDuration) &&
            _getNow() < firstUnlock
        ) {
            uint256 maxClaimable = (vestedAmount[_investor].mul(33)).div(100);
            uint256 userTotalClaimed = totalDrawn[_investor];
            if (userTotalClaimed < maxClaimable) {
                _amount = maxClaimable - userTotalClaimed;
                return _amount;
            }
        }
    }

    /**
     * @notice Draws down any vested tokens due
     * @dev Must be called directly by the investor assigned the tokens in the schedule
     */
    function drawDown() external nonReentrant isCrowdsaleOver {
        _drawDown(msg.sender);
    }

    function _drawDown(address _investor) internal {
        require(
            vestedAmount[_investor] > 0,
            "There is no schedule currently in flight"
        );

        uint256 amount = _availableDrawDownAmount(_investor);
        require(amount > 0, "No allowance left to withdraw");

        // Update last drawn to now
        lastDrawnAt[_investor] = _getNow();

        // Increase total drawn amount
        totalDrawn[_investor] = totalDrawn[_investor].add(amount);

        // Safety measure - this should never trigger
        require(
            totalDrawn[_investor] <= vestedAmount[_investor],
            "Safety Mechanism - Drawn exceeded Amount Vested"
        );

        // Issue tokens to investor
        require(token.transfer(_investor, amount), "Unable to transfer tokens");

        emit DrawDown(_investor, amount, _getNow());
    }

    function _getNow() internal view returns (uint256) {
        return block.timestamp;
    }

    function getContractTokenBalance(IERC20 _token)
        public
        view
        returns (uint256)
    {
        return _token.balanceOf(address(this));
    }

    /**
     * @notice Balance remaining in vesting schedule
     * @param _investor beneficiary of the vested tokens
     * @return _remainingBalance tokens still due (and currently locked) from vesting schedule
     */
    function remainingBalance(address _investor) public view returns (uint256) {
        return vestedAmount[_investor].sub(totalDrawn[_investor]);
    }

    function endCrowdsale(
        uint256 _vestingStartTime,
        uint256 _vestingEndTime,
        uint256 _cliffDurationInSecs
    ) external onlyOwner {
        require(
            crowdsaleEndTime == 0,
            "Crowdsale would end automatically after endTime"
        );
        crowdsaleEndTime = _getNow();
        require(
            _vestingStartTime >= crowdsaleEndTime,
            "Vesting Start time should be greater or equal to Crowdsale EndTime"
        );
        require(
            _vestingEndTime > _vestingStartTime.add(_cliffDurationInSecs),
            "Vesting End Time should be after the cliffPeriod"
        );

        vestingStart = _vestingStartTime;
        vestingEnd = _vestingEndTime;
        cliffDuration = _cliffDurationInSecs;
        if (tokenRemainingForSale != 0) {
            withdrawFunds(token, tokenRemainingForSale); //when crowdsaleEnds withdraw unsold tokens to the owner
        }
        emit CrowdsaleEndedManually(crowdsaleEndTime);
    }

    function withdrawFunds(IERC20 _token, uint256 amount)
        public
        isCrowdsaleOver
        onlyOwner
    {
        require(
            getContractTokenBalance(_token) >= amount,
            "the contract doesnt have tokens"
        );

        if (_token == usdt) {
            return doTransferOut(address(_token), msg.sender, amount);
        }

        _token.transfer(msg.sender, amount);

        emit FundsWithdrawn(msg.sender, _token, amount);
    }

    function changeUniswapAddress(address payable _shibaSwapRouter)
        external
        onlyOwner
    {
        shibaSwapRouter = IUniswapV2Router01(_shibaSwapRouter);
    }

    /**
     * @dev Performs a transfer in, reverting upon failure. Returns the amount actually transferred to the protocol, in case of a fee.
     *  This may revert due to insufficient balance or insufficient allowance.
     */
    function doTransferIn(
        address tokenAddress,
        address from,
        uint256 amount
    ) internal returns (uint256) {
        INonStandardERC20 _token = INonStandardERC20(tokenAddress);
        uint256 balanceBefore = IERC20(tokenAddress).balanceOf(address(this));
        _token.transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was actually transferred
        uint256 balanceAfter = IERC20(tokenAddress).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter.sub(balanceBefore); // underflow already checked above, just subtract
    }

    /**
     * @dev Performs a transfer out, ideally returning an explanatory error code upon failure tather than reverting.
     *  If caller has not called checked protocol's balance, may revert due to insufficient cash held in the contract.
     *  If caller has checked protocol's balance, and verified it is >= amount, this should not revert in normal conditions.
     */
    function doTransferOut(
        address tokenAddress,
        address to,
        uint256 amount
    ) internal {
        INonStandardERC20 _token = INonStandardERC20(tokenAddress);
        _token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a complaint ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface INonStandardERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external;

    function approve(address spender, uint256 amount)
        external
        returns (bool success);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;


library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

interface IUniswapV2Router01 {
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

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

pragma solidity >=0.6.0 <0.8.0;

interface IUniswapV2Factory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

pragma solidity >=0.6.0 <0.8.0;

interface IUniswapV2Pair {
  function token0() external pure returns (address);

  function token1() external pure returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 _reserve0,
      uint112 _reserve1,
      uint32 _blockTimestampLast
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
     function decimals() external returns(uint8);
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

pragma solidity >=0.6.2 <0.8.0;

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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}