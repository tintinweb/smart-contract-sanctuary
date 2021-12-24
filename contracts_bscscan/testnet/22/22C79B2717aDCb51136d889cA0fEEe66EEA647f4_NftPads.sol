// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC20/IERC20Burnable.sol";
import "../ERC20/SafeERC20Burnable.sol";

import {Launchpad, Register} from "../common/Structs.sol";

/**
 * todo: Modifier, external
 * - wait for BA's update of level when user refund
 * - Add constraint when adding launchpad
 * - remove unnesscesary field

 * - Check function calculate depositable amount 
 */

contract NftPads is Ownable {
    using SafeERC20Burnable for IERC20Burnable;

    address public stakingToken;
    address public USDT;
    address public BUSD;

    /**
     * @dev Explain mappings
     * - launchpadExisted: either launchpad existed or not
     * - projectToRegisterUser: project -> address -> Register (information of user)
     * - projectToLaunchpad: project => Launchpad (information of launchpad)
     */

    // Note: Maybe add deposit function  to avoid manual checking of user deposit (in suggestion)
    string[] public allProjects;

    //either if the launchpad existed
    mapping(string => bool) public launchPadExisted;
    mapping(string => Launchpad) public projectToLaunchpads;
    mapping(string => mapping(address => Register))
        public projectToRegisterUser;

    mapping(string => mapping(uint256 => address[]))
        public projectToAddressAtLevel;

    event LaunchpadCreated(string indexed launchpad);
    event Registered(
        string indexed launchpad,
        address indexed user,
        uint256 indexed level
    );
    event Deposited(
        address indexed user,
        string indexed launchpad,
        uint256 indexed amount
    );

    constructor(address stakingToken_) {
        setStakingToken(stakingToken_);
    }

    function setStakingToken(address stakingToken_) public onlyOwner {
        stakingToken = stakingToken_;
    }

    function setUSDTAddress(address USDTAddress_) public onlyOwner {
        USDT = USDTAddress_;
    }

    function setBUSDAddress(address BUSDAddress_) public onlyOwner {
        BUSD = BUSDAddress_;
    }

    /**
     * @dev Launchpad
     */
    function createLaunchPad(
        string memory launchPad_,
        uint256[] memory times, // 0: start time, 1: end time, 2: refunduration: in hours
        uint256[] memory entryDates_,
        uint256[] memory numberOfTickets_,
        uint256[] memory ticketPrices_,
        uint256[] memory allocation_, //0: min allocation, 1: max allocation, 2: deposit time, 3: intial price
        address depositFundAddress_,
        address rewardTokenAddress_
    ) public onlyOwner {
        require(!launchPadExisted[launchPad_], "launchpad is already existed");
        require(
            times[1] > block.timestamp,
            "Endtime is smaller than current time"
        );

        require(
            entryDates_.length == numberOfTickets_.length &&
                entryDates_.length == ticketPrices_.length,
            "Invalid length of array input"
        );
        uint256[] memory ticketSolds_ = new uint256[](entryDates_.length);

        Launchpad memory launchpad = Launchpad({
            startTime: times[0],
            endTime: times[1],
            refundDuration: times[2],
            entryDates: entryDates_,
            numberOfTickets: numberOfTickets_,
            ticketPrices: ticketPrices_,
            ticketSolds: ticketSolds_,
            minAllocation: allocation_[0],
            maxAllocation: allocation_[1],
            depositTime: allocation_[2],
            initalPrice: allocation_[3],
            totalTicketSold: 0,
            depositFundAddress: depositFundAddress_,
            rewardTokenAddress: rewardTokenAddress_
        });
        projectToLaunchpads[launchPad_] = launchpad;
        launchPadExisted[launchPad_] = true;

        allProjects.push(launchPad_);
        emit LaunchpadCreated(launchPad_);
    }

    function calculateEntryLevel(string memory launchPad_)
        public
        view
        returns (bool, uint256)
    {
        Launchpad storage launchpad = projectToLaunchpads[launchPad_];

        uint256 totalLength = launchpad.entryDates.length;

        if (block.timestamp > launchpad.entryDates[totalLength - 1]) {
            return (false, 0);
        }

        //In the first period
        if (
            block.timestamp >= launchpad.startTime &&
            block.timestamp < launchpad.entryDates[0]
        ) {
            if (launchpad.ticketSolds[0] < launchpad.numberOfTickets[0]) {
                return (true, 0);
            } else {
                for (uint256 k = 1; k < totalLength; k++) {
                    if (
                        launchpad.ticketSolds[k] < launchpad.numberOfTickets[k]
                    ) {
                        return (true, k);
                    }
                }
                return (false, 0);
            }
        }

        // In the second period
        for (uint256 i = 1; i < totalLength; i++) {
            if (
                block.timestamp > launchpad.entryDates[i - 1] &&
                block.timestamp < launchpad.entryDates[i]
            ) {
                // if ticket are avail at level i
                if (launchpad.ticketSolds[i] < launchpad.numberOfTickets[i]) {
                    return (true, i);
                } else {
                    //if tickets are not avail at level i ==> get ticket at the next level
                    for (uint256 j = i + 1; j < totalLength; j++) {
                        if (
                            launchpad.ticketSolds[j] <
                            launchpad.numberOfTickets[j]
                        ) {
                            return (true, j);
                        }
                    }
                    return (false, 0);
                }
            }
        }

        return (false, 0);
    }

    /**
     * @dev User register for a launchpad
     * - Prerequisite: user approve for contract to take the token
     */
    function register(string memory launchpad_) public {
        bool registerable;
        uint256 level;

        (registerable, level) = calculateEntryLevel(launchpad_);

        require(stakingToken != address(0), "Invalid staking token");

        require(registerable, "No entries are available!");
        require(
            !isUserRegistered(launchpad_, msg.sender),
            "You'are already registered"
        );

        Launchpad storage launchpad = projectToLaunchpads[launchpad_];

        IERC20Burnable(stakingToken).safeTransferFrom(
            msg.sender,
            address(this),
            launchpad.ticketPrices[level]
        );

        //Add register user
        Register memory registerUser = Register({
            enterTime: block.timestamp,
            enterLevel: level,
            ticketNumber: launchpad.totalTicketSold,
            depositedTime: 0,
            depositedAmount: 0,
            claimableAmount: 0
        });

        projectToRegisterUser[launchpad_][msg.sender] = registerUser;
        projectToAddressAtLevel[launchpad_][level].push(msg.sender);

        //user is registred
        launchpad.totalTicketSold += 1;
        launchpad.ticketSolds[level] += 1;

        emit Registered(launchpad_, msg.sender, level);
    }

    function deposit(
        string memory launchpad_,
        address stableCoinAddress_,
        uint256 amount_
    ) public {
        require(
            stableCoinAddress_ == USDT || stableCoinAddress_ == BUSD,
            "Stable coin not supported"
        );

        require(
            isUserRegistered(launchpad_, msg.sender),
            "user has not registered yet"
        );

        (uint256 minA, uint256 maxA) = calculateDepositableAmount(
            launchpad_,
            msg.sender
        );

        require(maxA > 0, "Not in deposit time");
        require(amount_ >= minA && amount_ <= maxA, "Deposit amount not valid");

        //note: transfer token to deposit fund address
        IERC20Burnable(stableCoinAddress_).transferFrom(
            msg.sender,
            projectToLaunchpads[launchpad_].depositFundAddress,
            amount_
        );

        Register storage registerUser = projectToRegisterUser[launchpad_][
            msg.sender
        ];

        registerUser.depositedAmount += amount_;
        registerUser.depositedTime = block.timestamp;

        uint256 intialPrice = projectToLaunchpads[launchpad_].initalPrice;
        registerUser.claimableAmount =
            (registerUser.depositedAmount / intialPrice) *
            1000000000000000000;

        emit Deposited(msg.sender, launchpad_, amount_);
    }

    /**
     * @dev User can redeem token in refund period
     */
    function refund(string memory launchpad_) public {
        require(stakingToken != address(0), "Invalid staking token");
        require(
            projectToRegisterUser[launchpad_][msg.sender].depositedAmount == 0,
            "User who deposited cannot refund"
        );

        Register storage registerUser = projectToRegisterUser[launchpad_][
            msg.sender
        ];

        // amount of withdrawable token
        uint256 _amount = projectToLaunchpads[launchpad_].ticketPrices[
            registerUser.enterLevel
        ];
        require(_amount > 0, "pads: you have no token to withdraw");
        require(
            block.timestamp <
                registerUser.enterTime +
                    projectToLaunchpads[launchpad_].refundDuration *
                    1 hours,
            "pads: Not in refund period"
        );

        //refund token back to register user
        IERC20Burnable(stakingToken).safeTransfer(msg.sender, _amount);

        // delete the address at level
        delete projectToAddressAtLevel[launchpad_][registerUser.enterLevel][
            registerUser.ticketNumber
        ];

        // Allow user to register again
        registerUser.enterTime = 0;

        // return the ticket
        projectToLaunchpads[launchpad_].ticketSolds[
            registerUser.enterLevel
        ] -= 1;
    }

    function getBalance() public view returns (uint256) {
        return IERC20Burnable(stakingToken).balanceOf(address(this));
    }

    /**
     * @dev Owner can withdraw all funds (incase of error)
     */
    function withdrawAll() public onlyOwner {
        uint256 totalBalance = IERC20Burnable(stakingToken).balanceOf(
            address(this)
        );
        IERC20Burnable(stakingToken).safeTransfer(owner(), totalBalance);
    }

    /**
     * @dev Get num of ticket solds, total ticket at level of launchpad, and price
     */

    function getTicketsAtLevel(string memory launchPad_, uint256 level_)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        Launchpad storage launchpad = projectToLaunchpads[launchPad_];

        return (
            launchpad.ticketSolds[level_],
            launchpad.numberOfTickets[level_],
            launchpad.ticketPrices[level_]
        );
    }

    /**
     */
    function getAddressesAtLevel(string memory launchPad_, uint256 level_)
        public
        view
        returns (address[] memory)
    {
        return projectToAddressAtLevel[launchPad_][level_];
    }

    /**
     * @dev check whether a user has registered or not
     */
    function isUserRegistered(string memory launchpad_, address user_)
        public
        view
        returns (bool)
    {
        return projectToRegisterUser[launchpad_][user_].enterTime != 0;
    }

    /**
     * @dev Calculate how many stable coin a registere user can deposit
     * Return: minA - maxA: range that user can deposit
     */

    //todo: return minAllocaiton, maxAllocation
    function calculateDepositableAmount(string memory launchpad_, address user_)
        public
        view
        returns (uint256, uint256)
    {
        Launchpad storage launchpad = projectToLaunchpads[launchpad_];

        if (
            block.timestamp < launchpad.depositTime ||
            block.timestamp > launchpad.endTime
        ) {
            return (0, 0);
        }

        uint256 depositedAmount = projectToRegisterUser[launchpad_][user_]
            .depositedAmount;

        uint256 minA;
        uint256 maxA;

        if (depositedAmount >= launchpad.minAllocation) {
            minA = 1;
            maxA = launchpad.maxAllocation - depositedAmount;
        } else {
            minA = launchpad.minAllocation;
            maxA = launchpad.maxAllocation;
        }

        return (minA, maxA);
    }

    /**
     * @dev Get how many level a launchpad have
     */
    function getNumberOfLevel(string memory launchpad_)
        public
        view
        returns (uint256)
    {
        return projectToLaunchpads[launchpad_].entryDates.length;
    }

    /**
     * @dev Burn token
     */
    function getTotalVPKAmount() public view returns (uint256) {
        return IERC20Burnable(stakingToken).balanceOf(address(this));
    }

    function burnVPK(uint256 percent_) public onlyOwner {
        require(percent_ <= 100, "VPK: Cannot burn more than 100%");

        uint256 burnAmount = (IERC20Burnable(stakingToken).balanceOf(
            address(this)
        ) * percent_) / 100;

        IERC20Burnable(stakingToken).burnFrom(address(this), burnAmount);
    }

    /**
     * @dev use for testing
     */
    function blockTime() public view returns (uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.1;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Burnable is IERC20 {
    event Burned(address indexed burnee, uint256 indexed amount);

    function burnFrom(address burnee, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Burnable {
    using Address for address;

    function safeTransfer(
        IERC20Burnable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20Burnable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Burnable token,
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20Burnable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20Burnable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Burnable token, bytes memory data)
        private
    {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

struct Launchpad {
    uint256 startTime;
    uint256 endTime;
    uint256 refundDuration; // duration when user can redeem their staking fund after register
    uint256[] entryDates;
    uint256[] numberOfTickets;
    uint256[] ticketPrices;
    uint256[] ticketSolds;
    uint256 minAllocation;
    uint256 maxAllocation;
    uint256 depositTime;
    uint256 initalPrice;
    uint256 totalTicketSold;
    address depositFundAddress;
    address rewardTokenAddress;
}

struct Register {
    uint256 enterTime;
    uint256 enterLevel;
    uint256 ticketNumber;
    uint256 depositedTime;
    uint256 depositedAmount;
    uint256 claimableAmount;
}

/**
 * @dev Grant explanation
 * - recipient: account to recieve vesting
 * - amount: total amount the user can receive
 * - claimDates: (unix time): the time the user can receive tokens
 * - claimPercents: mapping to claims date: Percentage of total amount that the user can receive
 * - totalClaimed: the amount of token that the user claimed
 */
struct Grant {
    uint256 amount;
    uint256[] claimDates;
    uint256[] claimPercents;
    uint256 totalClaimed;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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