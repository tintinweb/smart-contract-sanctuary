/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.8.0;
pragma abicoder v2;



// Part: I_LearningCurve

interface I_LearningCurve {
    function mintForAddress(address, uint256) external;

    function balanceOf(address) external view returns (uint256);
}

// Part: I_Registry

interface I_Registry {
    function latestVault(address) external view returns (address);
}

// Part: I_Vault

interface I_Vault {
    function token() external view returns (address);

    function underlying() external view returns (address);

    function pricePerShare() external view returns (uint256);

    function deposit(uint256) external returns (uint256);

    function depositAll() external;

    function withdraw(uint256) external returns (uint256);

    function withdraw() external returns (uint256);

    function balanceOf(address) external returns (uint256);
}

// Part: OpenZeppelin/[email protected]/Address

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

// Part: OpenZeppelin/[email protected]/Counters

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/SafeERC20

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: KernelFactory.sol

/**
 * @title Kernel Factory
 * @author kjr217
 * @notice Deploys new courses and interacts with the learning curve directly to mint LEARN.
 */

contract KernelFactory {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    struct Course {
        uint256 checkpoints; // number of checkpoints the course should have
        uint256 fee; // the fee for entering the course
        uint256 checkpointBlockSpacing; // the block spacing between checkpoints
        string url; // url containing course data
        address creator; // address to receive any yield from a redeem call
    }

    struct Learner {
        uint256 blockRegistered; // used to decide when a learner can claim their registration fee back
        uint256 yieldBatchId; // the batch id for this learner's Yield bearing deposit
        uint256 checkpointReached; // what checkpoint the learner has reached
    }

    // containing course data mapped by a courseId
    mapping(uint256 => Course) public courses;
    // containing learner data mapped by a courseId and address
    mapping(uint256 => mapping(address => Learner)) learnerData;

    // containing the total underlying amount for a yield batch mapped by batchId
    mapping(uint256 => uint256) batchTotal;
    // containing the total amount of yield token for a yield batch mapped by batchId
    mapping(uint256 => uint256) batchYieldTotal;
    // containing the vault address of the the yield token for a yield batch mapped by batchId
    mapping(uint256 => address) batchYieldAddress;
    // containing the underlying amount a learner deposited in a specific batchId
    mapping(uint256 => mapping(address => uint256)) learnerDeposit;
    // tracker for the batchId, current represents the current batch
    Counters.Counter private batchIdTracker;
    // the stablecoin used by the contract, DAI
    IERC20 public stable;
    // the yearn resgistry used by the contract, to determine what the yDai address is.
    I_Registry public registry;
    // yield rewards for an eligible address
    mapping(address => uint256) yieldRewards;

    // tracker for the courseId, current represents the id of the next course
    Counters.Counter private courseIdTracker;
    // interface for the learning curve
    I_LearningCurve public learningCurve;

    event CourseCreated(
        uint256 indexed courseId,
        uint256 checkpoints,
        uint256 fee,
        uint256 checkpointBlockSpacing,
        string url,
        address creator
    );

    event LearnerRegistered(uint256 indexed courseId, address learner);
    event FeeRedeemed(uint256 courseId, address learner, uint256 amount);
    event LearnMintedFromCourse(
        uint256 courseId,
        address learner,
        uint256 stableConverted,
        uint256 learnMinted
    );
    event BatchDeposited(
        uint256 batchId,
        uint256 batchAmount,
        uint256 batchYieldAmount
    );
    event CheckpointUpdated(
        uint256 courseId,
        uint256 checkpointReached,
        address learner
    );
    event YieldRewardRedeemed(address redeemer, uint256 yieldRewarded);

    constructor(
        address _stable,
        address _learningCurve,
        address _registry
    ) {
        stable = IERC20(_stable);
        learningCurve = I_LearningCurve(_learningCurve);
        registry = I_Registry(_registry);
    }

    /**
     * @notice                         create a course
     * @param  _fee                    fee for a learner to register
     * @param  _checkpoints            number of checkpoints on the course
     * @param  _checkpointBlockSpacing block spacing between subsequent checkpoints
     * @param  _url                    url leading to course details
     * @param  _creator        the address that excess yield will be sent to on a redeem
     */
    function createCourse(
        uint256 _fee,
        uint256 _checkpoints,
        uint256 _checkpointBlockSpacing,
        string calldata _url,
        address _creator
    ) external {
        require(_fee > 0, "createCourse: fee must be greater than 0");
        require(
            _checkpointBlockSpacing > 0,
            "createCourse: checkpointBlockSpacing must be greater than 0"
        );
        require(
            _checkpoints > 0,
            "createCourse: checkpoint must be greater than 0"
        );
        require(
            _creator != address(0),
            "createCourse: creator cannot be 0 address"
        );
        uint256 courseId_ = courseIdTracker.current();
        courseIdTracker.increment();
        courses[courseId_] = Course(
            _checkpoints,
            _fee,
            _checkpointBlockSpacing,
            _url,
            _creator
        );
        emit CourseCreated(
            courseId_,
            _checkpoints,
            _fee,
            _checkpointBlockSpacing,
            _url,
            _creator
        );
    }

    /**
     * @notice deposit the current batch of DAI in the contract to yearn.
     *         the batching mechanism is used to reduce gas for each learner,
     *         so at any point someone can call this function and deploy all
     *         funds in a specific "batch" to yearn, allowing the funds to gain
     *         interest.
     */
    function batchDeposit() external {
        uint256 batchId_ = batchIdTracker.current();
        // initiate the next batch
        uint256 batchAmount_ = batchTotal[batchId_];
        batchIdTracker.increment();
        require(batchAmount_ > 0, "batchDeposit: no funds to deposit");
        // get the address of the vault from the yRegistry
        I_Vault vault = I_Vault(registry.latestVault(address(stable)));
        // approve the vault
        stable.approve(address(vault), batchAmount_);
        // mint y from the vault
        uint256 yTokens = vault.deposit(batchAmount_);
        batchYieldTotal[batchId_] = yTokens;
        batchYieldAddress[batchId_] = address(vault);
        emit BatchDeposited(batchId_, batchAmount_, yTokens);
    }

    /**
     * @notice handles learner registration
     * @param  _courseId course id the learner would like to register to
     */
    function register(uint256 _courseId) external {
        require(
            _courseId < courseIdTracker.current(),
            "register: courseId does not exist"
        );
        uint256 batchId_ = batchIdTracker.current();
        require(
            learnerData[_courseId][msg.sender].blockRegistered == 0,
            "register: already registered"
        );
        Course storage course = courses[_courseId];

        stable.safeTransferFrom(msg.sender, address(this), course.fee);

        learnerData[_courseId][msg.sender].blockRegistered = block.number;
        learnerData[_courseId][msg.sender].yieldBatchId = batchId_;
        batchTotal[batchId_] += course.fee;
        learnerDeposit[batchId_][msg.sender] += course.fee;

        emit LearnerRegistered(_courseId, msg.sender);
    }

    /**
     * @notice           handles checkpoint verification
     *                   All course are deployed with a given number of checkpoints
     *                   allowing learners to receive a portion of their fees back
     *                   at various stages in the course.
     *
     *                   This is a helper function that checks where a learner is
     *                   in a course and is used by both redeem() and mint() to figure out
     *                   the proper amount required.
     *
     * @param  learner   address of the learner to verify
     * @param  _courseId course id to verify for the learner
     * @return           the checkpoint that the learner has reached
     */
    function verify(address learner, uint256 _courseId)
        public
        view
        returns (uint256)
    {
        require(
            _courseId < courseIdTracker.current(),
            "verify: courseId does not exist"
        );
        require(
            learnerData[_courseId][learner].blockRegistered != 0,
            "verify: not registered to this course"
        );
        return _verify(learner, _courseId);
    }

    /**
     * @notice                   handles checkpoint verification
     *                           All course are deployed with a given number of checkpoints
     *                           allowing learners to receive a portion of their fees back
     *                           at various stages in the course.
     *
     *                           This is a helper function that checks where a learner is
     *                           in a course and is used by both redeem() and mint() to figure out
     *                           the proper amount required.
     *
     * @param  learner           address of the learner to verify
     * @param  _courseId         course id to verify for the learner
     * @return checkpointReached the checkpoint that the learner has reached.
     */
    function _verify(address learner, uint256 _courseId)
        internal
        view
        returns (uint256 checkpointReached)
    {
        uint256 blocksSinceRegister = block.number -
            learnerData[_courseId][learner].blockRegistered;
        checkpointReached =
            blocksSinceRegister /
            courses[_courseId].checkpointBlockSpacing;
        if (courses[_courseId].checkpoints < checkpointReached) {
            checkpointReached = courses[_courseId].checkpoints;
        }
    }

    /**
     * @notice           handles fee redemption into stable
     *                   if a learner is redeeming rather than minting, it means
     *                   they are simply requesting their initial fee back (whether
     *                   they have completed the course or not).
     *                   In this case, it checks what proportion of `fee` (set when
     *                   the course is deployed) must be returned and sends it back
     *                   to the learner.
     *
     *                   Whatever yield they earned is sent to the course configured address.
     *
     * @param  _courseId course id to redeem the fee from
     */
    function redeem(uint256 _courseId) external {
        uint256 shares;
        uint256 learnerShares;
        bool deployed;
        require(
            learnerData[_courseId][msg.sender].blockRegistered != 0,
            "redeem: not a learner on this course"
        );
        uint256 checkpointReached = learnerData[_courseId][msg.sender]
            .checkpointReached;
        (learnerShares, deployed) = determineEligibleAmount(_courseId);
        uint256 latestCheckpoint = learnerData[_courseId][msg.sender]
            .checkpointReached;
        if (deployed) {
            I_Vault vault = I_Vault(
                batchYieldAddress[
                    learnerData[_courseId][msg.sender].yieldBatchId
                ]
            );
            shares = vault.withdraw(learnerShares);
            uint256 fee_ = ((latestCheckpoint - checkpointReached) *
                courses[_courseId].fee) / courses[_courseId].checkpoints;
            if (fee_ < shares) {
                yieldRewards[courses[_courseId].creator] += shares - fee_;
                emit FeeRedeemed(_courseId, msg.sender, fee_);
                stable.safeTransfer(msg.sender, fee_);
            } else {
                emit FeeRedeemed(_courseId, msg.sender, shares);
                stable.safeTransfer(msg.sender, shares);
            }
        } else {
            emit FeeRedeemed(_courseId, msg.sender, learnerShares);
            stable.safeTransfer(msg.sender, learnerShares);
        }
    }

    /**
     * @notice           handles learner minting new LEARN
     *                   checks via verify() what proportion of the fee to send to the
     *                   Learning Curve, any yield earned on the original fee is sent to
     *                   the creator's designated address, and returns all
     *                   the resulting LEARN tokens to the learner.
     * @param  _courseId course id to mint LEARN from
     */
    function mint(uint256 _courseId) external {
        uint256 shares;
        bool deployed;
        require(
            learnerData[_courseId][msg.sender].blockRegistered != 0,
            "mint: not a learner on this course"
        );
        uint256 checkpointReached = learnerData[_courseId][msg.sender]
            .checkpointReached;
        (shares, deployed) = determineEligibleAmount(_courseId);
        uint256 latestCheckpoint = learnerData[_courseId][msg.sender]
            .checkpointReached;
        if (deployed) {
            I_Vault vault = I_Vault(
                batchYieldAddress[
                    learnerData[_courseId][msg.sender].yieldBatchId
                ]
            );
            shares = vault.withdraw(shares);
        }
        uint256 fee_ = ((latestCheckpoint - checkpointReached) *
            courses[_courseId].fee) / courses[_courseId].checkpoints;
        if (fee_ < shares) {
            yieldRewards[courses[_courseId].creator] += shares - fee_;
            stable.approve(address(learningCurve), fee_);
            uint256 balanceBefore = learningCurve.balanceOf(msg.sender);
            learningCurve.mintForAddress(msg.sender, fee_);
            emit LearnMintedFromCourse(
                _courseId,
                msg.sender,
                fee_,
                learningCurve.balanceOf(msg.sender) - balanceBefore
            );
        } else {
            stable.approve(address(learningCurve), shares);
            uint256 balanceBefore = learningCurve.balanceOf(msg.sender);
            learningCurve.mintForAddress(msg.sender, shares);
            emit LearnMintedFromCourse(
                _courseId,
                msg.sender,
                shares,
                learningCurve.balanceOf(msg.sender) - balanceBefore
            );
        }
    }

    /**
     * @notice Gets the amount of dai that an address is eligible, addresses become eligible if
     *         they are the designated reward receiver for a specific course and a learner on that
     *         course decided to redeem, meaning yield was reserved for the reward receiver
     */
    function withdrawYieldRewards() external {
        uint256 withdrawableReward = getYieldRewards(msg.sender);
        yieldRewards[msg.sender] = 0;
        emit YieldRewardRedeemed(msg.sender, withdrawableReward);
        stable.safeTransfer(msg.sender, withdrawableReward);
    }

    /**
     * @notice                get and update the amount of funds that a learner is eligible for at this timestamp
     * @param  _courseId      course id to mint LEARN from
     * @return eligibleShares the number of shares the learner can withdraw
     *                        (if bool deployed is true will return yDai amount, if it is false it will
     *                        return the Dai amount)
     * @return deployed       whether the funds to be redeemed were deployed to yearn
     */
    function determineEligibleAmount(uint256 _courseId)
        internal
        returns (uint256 eligibleShares, bool deployed)
    {
        uint256 fee = learnerDeposit[_courseId][msg.sender];
        require(fee > 0, "no fee to redeem");
        uint256 checkpointReached = verify(msg.sender, _courseId);
        require(
            checkpointReached >
                learnerData[_courseId][msg.sender].checkpointReached,
            "fee redeemed at this checkpoint"
        );
        uint256 eligibleAmount = ((checkpointReached -
            learnerData[_courseId][msg.sender].checkpointReached) *
            courses[_courseId].fee) / courses[_courseId].checkpoints;

        learnerData[_courseId][msg.sender]
            .checkpointReached = checkpointReached;

        emit CheckpointUpdated(_courseId, checkpointReached, msg.sender);

        if (eligibleAmount > fee) {
            eligibleAmount = fee;
        }
        uint256 batchId_ = learnerData[_courseId][msg.sender].yieldBatchId;
        if (batchId_ == batchIdTracker.current()) {
            deployed = false;
            eligibleShares = eligibleAmount;
        } else {
            uint256 temp = (eligibleAmount * 1e18) / batchTotal[batchId_];
            deployed = true;
            eligibleShares = (temp * batchYieldTotal[batchId_]) / 1e18;
        }
        learnerDeposit[_courseId][msg.sender] -= eligibleAmount;
    }

    function getCurrentBatchTotal() external view returns (uint256) {
        return batchTotal[batchIdTracker.current()];
    }

    function getBlockRegistered(address learner, uint256 courseId)
        external
        view
        returns (uint256)
    {
        return learnerData[courseId][learner].blockRegistered;
    }

    function getCurrentBatchId() external view returns (uint256) {
        return batchIdTracker.current();
    }

    function getNextCourseId() external view returns (uint256) {
        return courseIdTracker.current();
    }

    /// @dev rough calculation used for frontend work
    function getLearnerCourseEligibleFunds(address learner, uint256 _courseId)
        external
        view
        returns (uint256)
    {
        uint256 checkPointReached = verify(learner, _courseId);
        uint256 checkPointRedeemed = learnerData[_courseId][learner]
            .checkpointReached;
        if (checkPointReached <= checkPointRedeemed) {
            return 0;
        }
        uint256 batchId_ = learnerData[_courseId][msg.sender].yieldBatchId;
        uint256 eligibleFunds = (courses[_courseId].fee /
            courses[_courseId].checkpoints) *
            (checkPointReached - checkPointRedeemed);
        if (batchId_ == batchIdTracker.current()) {
            return eligibleFunds;
        } else {
            uint256 temp = (eligibleFunds * 1e18) / batchTotal[batchId_];
            uint256 eligibleShares = (temp * batchYieldTotal[batchId_]) / 1e18;
            I_Vault vault = I_Vault(
                batchYieldAddress[
                    learnerData[_courseId][msg.sender].yieldBatchId
                ]
            );
            return (eligibleShares * vault.pricePerShare()) / 1e18;
        }
    }

    /// @dev rough calculation used for frontend work
    function getLearnerCourseFundsRemaining(address learner, uint256 _courseId)
        external
        view
        returns (uint256)
    {
        uint256 checkPointReached = verify(learner, _courseId);
        uint256 checkPointRedeemed = learnerData[_courseId][learner]
            .checkpointReached;
        uint256 batchId_ = learnerData[_courseId][msg.sender].yieldBatchId;
        uint256 eligibleFunds = (courses[_courseId].fee /
            courses[_courseId].checkpoints) *
            (courses[_courseId].checkpoints - checkPointRedeemed);
        if (batchId_ == batchIdTracker.current()) {
            return eligibleFunds;
        } else {
            uint256 temp = (eligibleFunds * 1e18) / batchTotal[batchId_];
            uint256 eligibleShares = (temp * batchYieldTotal[batchId_]) / 1e18;
            I_Vault vault = I_Vault(
                batchYieldAddress[
                    learnerData[_courseId][msg.sender].yieldBatchId
                ]
            );
            return (eligibleShares * vault.pricePerShare()) / 1e18;
        }
    }

    function getCourseUrl(uint256 _courseId)
        external
        view
        returns (string memory)
    {
        return courses[_courseId].url;
    }

    function getYieldRewards(address redeemer) public view returns (uint256) {
        return yieldRewards[redeemer];
    }
}