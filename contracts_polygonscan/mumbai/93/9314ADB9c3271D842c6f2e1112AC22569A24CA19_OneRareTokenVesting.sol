/*
    Copyright 2021 https://propel.xyz
    SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ITokenVesting.sol";
import "./VestingConfig.sol";

contract OneRareTokenVesting is ITokenVesting, Ownable, VestingConfig {
    using SafeERC20 for IERC20;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev all the details are hard coded
     */
    constructor(
        address oRareToken_,
        address team_,
        address ecosystem_,
        address reserves_
    ) {
        oRare = IERC20(oRareToken_);
        uint256 totalSupply = oRare.totalSupply();

        _addRound(
            Round.SEED,
            (totalSupply * _SEED_SUPPLY_PERCENT) / _PERCENTAGE_MULTIPLIER,
            _SEED_INITIAL_RELEASE_PERCENT,
            _SEED_CLIFF_PERIOD,
            _SEED_VESTING_PERIOD,
            _SEED_NO_OF_VESTINGS
        );

        _addRound(
            Round.PRIVATE1,
            (totalSupply * _PRIVATE1_SUPPLY_PERCENT) / _PERCENTAGE_MULTIPLIER,
            _PRIVATE1_INITIAL_RELEASE_PERCENT,
            _PRIVATE1_CLIFF_PERIOD,
            _PRIVATE1_VESTING_PERIOD,
            _PRIVATE1_NO_OF_VESTINGS
        );

        _addRound(
            Round.PRIVATE2,
            (totalSupply * _PRIVATE2_SUPPLY_PERCENT) / _PERCENTAGE_MULTIPLIER,
            _PRIVATE2_INITIAL_RELEASE_PERCENT,
            _PRIVATE2_CLIFF_PERIOD,
            _PRIVATE2_VESTING_PERIOD,
            _PRIVATE2_NO_OF_VESTINGS
        );

        _addRound(
            Round.PUBLIC,
            (totalSupply * _PUBLIC_SUPPLY_PERCENT) / _PERCENTAGE_MULTIPLIER,
            _PUBLIC_INITIAL_RELEASE_PERCENT,
            _PUBLIC_CLIFF_PERIOD,
            _PUBLIC_VESTING_PERIOD,
            _PUBLIC_NO_OF_VESTINGS
        );

        _addTeam(
            Round.TEAM,
            team_,
            (totalSupply * _TEAM_SUPPLY_PERCENT) / _PERCENTAGE_MULTIPLIER,
            _TEAM_INITIAL_RELEASE_PERCENT,
            _TEAM_CLIFF_PERIOD,
            _TEAM_VESTING_PERIOD,
            _TEAM_NO_OF_VESTINGS
        );

        _addTeam(
            Round.ECOSYSTEM,
            ecosystem_,
            (totalSupply * _ECOSYSTEM_SUPPLY_PERCENT) / _PERCENTAGE_MULTIPLIER,
            _ECOSYSTEM_INITIAL_RELEASE_PERCENT,
            _ECOSYSTEM_CLIFF_PERIOD,
            _ECOSYSTEM_VESTING_PERIOD,
            _ECOSYSTEM_NO_OF_VESTINGS
        );

        _addTeam(
            Round.RESERVES,
            reserves_,
            (totalSupply * _RESERVES_SUPPLY_PERCENT) / _PERCENTAGE_MULTIPLIER,
            _RESERVES_INITIAL_RELEASE_PERCENT,
            _RESERVES_CLIFF_PERIOD,
            _RESERVES_VESTING_PERIOD,
            _RESERVES_NO_OF_VESTINGS
        );
    }

    /* ========== ADMIN FUNCTIONS ========== */

    function startOrUpdateStartTime(uint256 startTime_) external onlyOwner {
        if (startTime != 0) {
            require(block.timestamp < startTime, "ALREADY_STARTED");
        }

        if (startTime_ == 0) {
            startTime_ = block.timestamp;
        }

        _massUpdateCliffEndTime(startTime_);

        startTime = startTime_;

        emit StartVesting(startTime_);
    }

    function addOrUpdateInvestor(
        Round roundType_,
        address investor_,
        uint256 allocation_
    ) external onlyOwner isValidRound(roundType_) {
        require(investor_ != address(0), "INVALID_ADDRESS");

        RoundInfo storage round = roundInfo[roundType_];
        Investor storage investor = investorInfo[roundType_][investor_];

        if (investor.totalAssigned == 0) {
            require(round.supplyLeft >= allocation_, "INSUFFICIENT_SUPPLY");

            _investors[roundType_].push(investor_);
            round.supplyLeft -= allocation_;
        } else {
            require(round.supplyLeft + investor.totalAssigned >= allocation_, "INSUFFICIENT_SUPPLY");
            require(!investor.initialClaimReleased, "ALREADY_STARTED_CLAIMING");
            round.supplyLeft = round.supplyLeft + investor.totalAssigned - allocation_;
        }

        investor.totalAssigned = allocation_;

        if (round.noOfVestings > 0) {
            investor.vestingTokens =
                (allocation_ - ((allocation_ * round.initialReleasePercent) / _PERCENTAGE_MULTIPLIER)) /
                round.noOfVestings;
        }

        emit InvestorAdded(roundType_, investor_, allocation_);
    }

    /**
     * @notice function to add, update or remove multiples investors
     */
    function addOrUpdateInvestors(
        Round roundType_,
        address[] memory investors_,
        uint256[] memory allocation_
    ) external onlyOwner isValidRound(roundType_) {
        uint256 length = investors_.length;
        require(allocation_.length == length, "INVALID_ARGUMENTS");

        RoundInfo storage round = roundInfo[roundType_];
        Investor storage investor;
        uint256 supplyLeft = round.supplyLeft;
        uint256 i = 0;

        for (i; i < length; i++) {
            require(investors_[i] != address(0), "INVALID_ADDRESS");
            investor = investorInfo[roundType_][investors_[i]];

            if (investor.totalAssigned == 0) {
                require(supplyLeft >= allocation_[i], "INSUFFICIENT_SUPPLY");
                _investors[roundType_].push(investors_[i]);
            } else {
                supplyLeft += investor.totalAssigned;
                require(supplyLeft >= allocation_[i], "INSUFFICIENT_SUPPLY");
                require(!investor.initialClaimReleased, "ALREADY_STARTED_CLAIMING");
            }
            supplyLeft -= allocation_[i];
            investor.totalAssigned = allocation_[i];

            if (round.noOfVestings > 0) {
                investor.vestingTokens =
                    (allocation_[i] - ((allocation_[i] * round.initialReleasePercent) / _PERCENTAGE_MULTIPLIER)) /
                    round.noOfVestings;
            }
        }
        round.supplyLeft = supplyLeft;

        emit InvestorsAdded(roundType_, investors_, allocation_);
    }

    function recoverToken(
        address token_,
        address to_,
        uint256 amount_
    ) external onlyOwner {
        IERC20(token_).safeTransfer(to_, amount_);
        emit RecoverToken(token_, to_, amount_);
    }

    /* ========== FUNCTIONS ========== */

    function claimUnlockedTokens(Round roundType_) external onlyInvestor(roundType_) {
        require(startTime != 0 && block.timestamp > startTime, "NOT_STARTED_YET");

        RoundInfo memory round = roundInfo[roundType_];
        Investor memory investor = investorInfo[roundType_][_msgSender()];

        require(
            round.noOfVestings > 0 ? investor.vestingsClaimed < round.noOfVestings : !investor.initialClaimReleased,
            "ALREADY_CLAIMED"
        );

        uint256 unlockedTokens;

        if (block.timestamp >= round.cliffEndTime) {
            uint256 claimableVestingLeft;
            (unlockedTokens, claimableVestingLeft) = _getUnlockedTokensAndVestingLeft(round, investor);

            investorInfo[roundType_][_msgSender()].vestingsClaimed += claimableVestingLeft;
        }

        if (!investor.initialClaimReleased) {
            unlockedTokens += ((investor.totalAssigned * round.initialReleasePercent) / _PERCENTAGE_MULTIPLIER);
            investorInfo[roundType_][_msgSender()].initialClaimReleased = true;
        }

        require(unlockedTokens > 0, "NO_UNLOCKED_TOKENS_AVAILABLE");

        oRare.safeTransfer(_msgSender(), unlockedTokens);

        emit TokensClaimed(roundType_, _msgSender(), unlockedTokens);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _addTeam(
        Round roundType_,
        address beneficiary_,
        uint256 totalSupply_,
        uint256 initialReleasePercent_,
        uint256 cliffPeriod_,
        uint256 vestingPeriod_,
        uint256 noOfVestings_
    ) private {
        require(beneficiary_ != address(0), "INVALID_ADDRESS");
        if (vestingPeriod_ == 0) {
            require(noOfVestings_ == 0 || noOfVestings_ == 1, "INVALID_VESTING_PERIOD");
        }
        if (noOfVestings_ == 0) {
            require(vestingPeriod_ == 0 && initialReleasePercent_ == 10000, "INVALID_NO_OF_VESTING");
        }

        RoundInfo memory newRoundInfo;

        newRoundInfo.totalSupply = totalSupply_;
        newRoundInfo.initialReleasePercent = initialReleasePercent_;
        newRoundInfo.cliffPeriod = cliffPeriod_;
        newRoundInfo.vestingPeriod = vestingPeriod_;
        newRoundInfo.noOfVestings = noOfVestings_;

        roundInfo[roundType_] = newRoundInfo;

        Investor storage investor = investorInfo[roundType_][beneficiary_];
        _investors[roundType_].push(beneficiary_);

        investor.totalAssigned = totalSupply_;

        if (noOfVestings_ > 0) {
            uint256 initialReleaseTokens = (totalSupply_ * initialReleasePercent_) / _PERCENTAGE_MULTIPLIER;
            investor.vestingTokens = (totalSupply_ - initialReleaseTokens) / noOfVestings_;
        }
    }

    function _addRound(
        Round roundType_,
        uint256 totalSupply_,
        uint256 initialReleasePercent_,
        uint256 cliffPeriod_,
        uint256 vestingPeriod_,
        uint256 noOfVestings_
    ) private {
        if (vestingPeriod_ == 0) {
            require(noOfVestings_ == 0 || noOfVestings_ == 1, "INVALID_VESTING_PERIOD");
        }
        if (noOfVestings_ == 0) {
            require(vestingPeriod_ == 0 && initialReleasePercent_ == 10000, "INVALID_NO_OF_VESTING");
        }

        RoundInfo memory newRoundInfo;

        newRoundInfo.totalSupply = totalSupply_;
        newRoundInfo.supplyLeft = totalSupply_;
        newRoundInfo.initialReleasePercent = initialReleasePercent_;
        newRoundInfo.cliffPeriod = cliffPeriod_;
        newRoundInfo.vestingPeriod = vestingPeriod_;
        newRoundInfo.noOfVestings = noOfVestings_;

        roundInfo[roundType_] = newRoundInfo;
    }

    function _massUpdateCliffEndTime(uint256 startTime_) private {
        for (uint256 i = 0; i < 7; i++) {
            roundInfo[Round(i)].cliffEndTime = startTime_ + roundInfo[Round(i)].cliffPeriod;
        }
    }

    function _getUnlockedTokensAndVestingLeft(RoundInfo memory round_, Investor memory investor_)
        private
        view
        returns (uint256, uint256)
    {
        if (round_.noOfVestings == 0) return (0, 0); // 100% initial release
        if (round_.noOfVestings == 1) return (investor_.vestingTokens, 1); // initial + cliff release

        uint256 totalClaimableVesting = ((block.timestamp - round_.cliffEndTime) / round_.vestingPeriod) + 1;

        uint256 claimableVestingLeft = totalClaimableVesting > round_.noOfVestings
            ? round_.noOfVestings - investor_.vestingsClaimed
            : totalClaimableVesting - investor_.vestingsClaimed;

        uint256 unlockedTokens = investor_.vestingTokens * claimableVestingLeft;

        return (unlockedTokens, claimableVestingLeft);
    }

    /* ========== VIEWS ========== */

    function getClaimableTokens(Round roundType_, address account_) external view returns (uint256) {
        RoundInfo memory round = roundInfo[roundType_];
        Investor memory investor = investorInfo[roundType_][account_];

        if (
            startTime == 0 ||
            block.timestamp < startTime ||
            (investor.initialClaimReleased && investor.vestingsClaimed == round.noOfVestings)
        ) return 0;

        uint256 unlockedTokens;
        if (block.timestamp >= round.cliffEndTime) {
            (unlockedTokens, ) = _getUnlockedTokensAndVestingLeft(round, investor);
        }

        if (!investor.initialClaimReleased) {
            unlockedTokens =
                unlockedTokens +
                ((investor.totalAssigned * round.initialReleasePercent) / _PERCENTAGE_MULTIPLIER);
        }

        return unlockedTokens;
    }

    function getInvestors(Round roundType_) external view returns (address[] memory) {
        return _investors[roundType_];
    }

    /* ========== MODIFIERS ========== */

    modifier onlyInvestor(Round roundType_) {
        require(investorInfo[roundType_][_msgSender()].totalAssigned > 0, "CALLER_NOT_AUTHORIZED");
        _;
    }

    modifier isValidRound(Round roundType_) {
        require(
            roundType_ != Round.TEAM && roundType_ != Round.ECOSYSTEM && roundType_ != Round.RESERVES,
            "INVALID_ROUND"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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

pragma solidity 0.8.9;

import "../VestingConfig.sol";

interface ITokenVesting {
    /* ========== ADMIN FUNCTIONS ========== */

    function startOrUpdateStartTime(uint256 startTime_) external;

    function addOrUpdateInvestor(
        VestingConfig.Round roundType_,
        address investor_,
        uint256 allocation_
    ) external;

    function addOrUpdateInvestors(
        VestingConfig.Round roundType_,
        address[] memory investor_,
        uint256[] memory allocation_
    ) external;

    function recoverToken(
        address token_,
        address to_,
        uint256 amount_
    ) external;

    /* ========== USER FUNCTION ========== */

    function claimUnlockedTokens(VestingConfig.Round roundType_) external;

    /* ========== VIEWS ========== */

    function getClaimableTokens(VestingConfig.Round roundType_, address account_) external view returns (uint256);

    function getInvestors(VestingConfig.Round roundType_) external view returns (address[] memory);

    /* ========== EVENTS ========== */

    event StartVesting(uint256 startTime);

    event InvestorAdded(VestingConfig.Round indexed roundType, address investors, uint256 allocation);

    event InvestorsAdded(VestingConfig.Round roundType, address[] investors, uint256[] allocation);

    event TokensClaimed(VestingConfig.Round indexed roundType, address indexed investor, uint256 amount);

    event RecoverToken(address indexed token, address indexed to, uint256 indexed amount);
}

/*
    Copyright 2021 https://propel.xyz
    SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./VestingDetails.sol";

contract VestingConfig is VestingDetails {
    /* ========== TYPES  ========== */

    enum Round {
        SEED,
        PRIVATE1,
        PRIVATE2,
        PUBLIC,
        TEAM,
        ECOSYSTEM,
        RESERVES
    }

    /**
     * totalSupply : total supply allocated to the round
     * supplyLeft : available supply that can be assigned to investor
     * initialReleasePercent : percent to tokens which will be given at the tge
     * cliffPeriod : duration of cliff period (starts after listing period)
     * cliffEndTime : time at which cliff ends (first vesting will be given at this time)
     * vestingPeriod : duration of individual vesting
     * noOfVestings : total no of vesting to give
     */
    struct RoundInfo {
        uint256 totalSupply;
        uint256 supplyLeft;
        uint256 initialReleasePercent;
        uint256 cliffPeriod;
        uint256 cliffEndTime;
        uint256 vestingPeriod;
        uint256 noOfVestings;
    }

    /**
     * totalAssigned : total tokens assigned to the investor
     * vestingTokens : no of tokens to give at each vesting
     * vestingsClaimed : total no of vesting which will be given
     * initialClaimReleased : tells whether tokens released at tge are received or not
     * listingClaimReleased : tells whether tokens released after listing period are received or not
     */
    struct Investor {
        uint256 totalAssigned;
        uint256 vestingTokens;
        uint256 vestingsClaimed;
        bool initialClaimReleased;
    }

    /* ========== STATE VARIABLES  ========== */

    mapping(Round => RoundInfo) public roundInfo;
    mapping(Round => mapping(address => Investor)) public investorInfo;
    mapping(Round => address[]) internal _investors;

    IERC20 public oRare;
    uint256 public startTime;

    /* ========== CONSTANTS ========== */

    /*
     * all value which are in percent are multiplied with MULTIPLIER(100) to handle precision up to 2 places
     */
    uint256 internal constant _PERCENTAGE_MULTIPLIER = 10000;
}

// SPDX-License-Identifier: MIT

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

/*
    Copyright 2021 https://propel.xyz
    SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.9;

contract VestingDetails {
    /**
    flow 
      (tge) [initial release] ---- (cliff period ends) [1st vesting] ------ (vesting period) [2nd vesting] ---
   */

    /**
    supply : 5%
    initial release : 5%
    cliff period: 1 months, 
    vesting schedule : linear vesting for 15 months 
    single vesting period : 1 (single vesting period is of 1 sec)
    no of vestings : sec in 15 months  (as for each sec tokens will be released)
  */
    uint256 internal constant _SEED_SUPPLY_PERCENT = 500;
    uint256 internal constant _SEED_INITIAL_RELEASE_PERCENT = 500;
    uint256 internal constant _SEED_CLIFF_PERIOD = 30 days + 10 hours;
    uint256 internal constant _SEED_VESTING_PERIOD = 1;
    uint256 internal constant _SEED_NO_OF_VESTINGS = 450 days + 150 hours;

    /**
    supply : 5%
    initial release : 5%
    cliff period: 1 months, 
    vesting schedule : linear vesting for 12 months 
    single vesting period : 1 (single vesting period is of 1 sec)
    no of vestings : sec in 12 months  (as for each sec tokens will be released)
  */
    uint256 internal constant _PRIVATE1_SUPPLY_PERCENT = 500;
    uint256 internal constant _PRIVATE1_INITIAL_RELEASE_PERCENT = 500;
    uint256 internal constant _PRIVATE1_CLIFF_PERIOD = 30 days + 10 hours;
    uint256 internal constant _PRIVATE1_VESTING_PERIOD = 1;
    uint256 internal constant _PRIVATE1_NO_OF_VESTINGS = 360 days + 120 hours;

    /**
    supply : 5%
    initial release : 5%
    cliff period: 1 months, 
    vesting schedule : linear vesting for 9 months 
    single vesting period : 1 (single vesting period is of 1 sec)
    no of vestings : sec in 9 months  (as for each sec tokens will be released)
  */
    uint256 internal constant _PRIVATE2_SUPPLY_PERCENT = 500;
    uint256 internal constant _PRIVATE2_INITIAL_RELEASE_PERCENT = 500;
    uint256 internal constant _PRIVATE2_CLIFF_PERIOD = 30 days + 10 hours;
    uint256 internal constant _PRIVATE2_VESTING_PERIOD = 1;
    uint256 internal constant _PRIVATE2_NO_OF_VESTINGS = 270 days + 90 hours;

    /**
    supply : 1.5%
    initial release : 50%
    cliff period: 1 months, 
    vesting schedule : 50% cliff ends
    single vesting period : 0
    no of vestings : 1
  */
    uint256 internal constant _PUBLIC_SUPPLY_PERCENT = 150;
    uint256 internal constant _PUBLIC_INITIAL_RELEASE_PERCENT = 5000;
    uint256 internal constant _PUBLIC_CLIFF_PERIOD = 30 days + 10 hours;
    uint256 internal constant _PUBLIC_VESTING_PERIOD = 0;
    uint256 internal constant _PUBLIC_NO_OF_VESTINGS = 1;

    /**
    supply : 20%
    initial release : 0%
    cliff period: 6 months, 
    vesting schedule : monthly unlock over 18 months 
    single vesting period : 1 month
    no of vestings : 18
  */
    uint256 internal constant _TEAM_SUPPLY_PERCENT = 2000;
    uint256 internal constant _TEAM_INITIAL_RELEASE_PERCENT = 0;
    uint256 internal constant _TEAM_CLIFF_PERIOD = 180 days + 60 hours;
    uint256 internal constant _TEAM_VESTING_PERIOD = 30 days + 10 hours;
    uint256 internal constant _TEAM_NO_OF_VESTINGS = 18;

    /**
    supply : 40%
    initial release : 20%
    cliff period: 1 months, 
    vesting schedule : linear vesting for 21 months 
    single vesting period : 1 (single vesting period is of 1 sec)
    no of vestings : sec in 21 months  (as for each sec tokens will be released)
  */
    uint256 internal constant _ECOSYSTEM_SUPPLY_PERCENT = 4000;
    uint256 internal constant _ECOSYSTEM_INITIAL_RELEASE_PERCENT = 2000;
    uint256 internal constant _ECOSYSTEM_CLIFF_PERIOD = 30 days + 10 hours;
    uint256 internal constant _ECOSYSTEM_VESTING_PERIOD = 1;
    uint256 internal constant _ECOSYSTEM_NO_OF_VESTINGS = 630 days + 210 hours;

    /**
    supply : 23.50%
    initial release : 20%
    cliff period: 1 months, 
    vesting schedule : linear vesting for 21 months 
    single vesting period : 1 (single vesting period is of 1 sec)
    no of vestings : sec in 21 months  (as for each sec tokens will be released)
  */
    uint256 internal constant _RESERVES_SUPPLY_PERCENT = 2350;
    uint256 internal constant _RESERVES_INITIAL_RELEASE_PERCENT = 2000;
    uint256 internal constant _RESERVES_CLIFF_PERIOD = 30 days + 10 hours;
    uint256 internal constant _RESERVES_VESTING_PERIOD = 1;
    uint256 internal constant _RESERVES_NO_OF_VESTINGS = 630 days + 210 hours;
}