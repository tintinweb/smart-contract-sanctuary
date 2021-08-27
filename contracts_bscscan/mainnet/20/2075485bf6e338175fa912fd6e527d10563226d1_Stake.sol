/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
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
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: contracts/Address.sol

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
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks
     * -effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html
     * ?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// File: contracts/IERC20.sol
interface IERC20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

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
}

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
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
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

contract Stake {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public token;

    mapping(address => bool) public adminList;

    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
        adminList[msg.sender] = true;
    }

    struct StakePlan {
        uint256 startDate;
        uint256 endDate;
        uint256 maturityDate;
        bool isFixedMaturityDate;
        uint16 fixedDays;
        uint256 maxCap;
        uint256 minContribution;
        uint256 maxContribution;
        uint256 interestRate;
        uint256 totalStaked;
    }

    struct FixedStake {
        uint256 createdDate;
        uint256 maturityDate;
        uint256 tokens;
        uint256 interestRate;
    }

    StakePlan[] public stakePlans;
    uint8 totalPlans = 0;
    mapping(uint8 => bool) public activePlan;
    mapping(uint8 => mapping(address => uint256)) public userStakedTokensByPlan;
    mapping(uint8 => mapping(address => FixedStake[])) public fixedStakes;
    mapping(uint8 => mapping(address => uint8)) public fixedStakeLengthByUser;
    mapping(address => uint256) public userStakedTokensByContract;

    // Events
    event Staked(
        address indexed sender,
        uint8 indexed plan,
        uint256 indexed amount
    );
    event Withdrawn(
        address indexed sender,
        uint8 indexed plan,
        uint256 indexed amount
    );
    event AdminWithdrawn(address indexed admin, uint256 indexed amount);
    event AdminDeposit(address indexed admin, uint256 indexed amount);
    event AdminAdded(address indexed admin, address indexed newAdmin);
    event AdminRemoved(address indexed admin, address indexed oldAdmin);
    event PlanAdded(
        uint8 indexed plan,
        uint256 startDate,
        uint256 endDate,
        uint256 maturityDate,
        bool indexed isFixedMaturityDate,
        uint16 fixedDays,
        uint256 maxCap,
        uint256 minContribution,
        uint256 maxContribution,
        uint256 interestRate
    );
    event PlanUpdated(
        uint8 indexed plan,
        uint256 startDate,
        uint256 endDate,
        uint16 fixedDays,
        uint256 maxCap,
        uint256 minContribution,
        uint256 maxContribution,
        uint256 interestRate
    );
    event PlaneEnabled(uint8 indexed plan);
    event PlaneDisable(uint8 indexed plan);

    function addPlan(
        uint256 _startDate,
        uint256 _endDate,
        uint256 _maturityDate,
        bool _isFixedMaturityDate,
        uint16 _fixedDays,
        uint256 _maxCap,
        uint256 _minContribution,
        uint256 _maxContribution,
        uint256 _interestRate
    ) external onlyOwner {
        StakePlan memory stakePlan;
        stakePlan.startDate = _startDate;
        stakePlan.endDate = _endDate;
        stakePlan.maturityDate = _maturityDate;
        stakePlan.isFixedMaturityDate = _isFixedMaturityDate;
        stakePlan.fixedDays = _fixedDays;
        stakePlan.maxCap = _maxCap;
        stakePlan.minContribution = _minContribution;
        stakePlan.maxContribution = _maxContribution;
        stakePlan.interestRate = _interestRate;
        stakePlan.totalStaked = 0;
        stakePlans.push(stakePlan);
        activePlan[totalPlans] = true;
        emit PlanAdded(
            totalPlans,
            _startDate,
            _endDate,
            _maturityDate,
            _isFixedMaturityDate,
            _fixedDays,
            _maxCap,
            _minContribution,
            _maxContribution,
            _interestRate
        );
        totalPlans += 1;
    }

    // update plan
    function updatePlan(
        uint8 _index,
        uint256 _startDate,
        uint256 _endDate,
        uint16 _fixedDays,
        uint256 _maxCap,
        uint256 _minContribution,
        uint256 _maxContribution,
        uint256 _interestRate
    ) external onlyOwner {
        require(activePlan[_index], "Plan is not available");
        StakePlan storage stakePlan = stakePlans[_index];
        stakePlan.startDate = _startDate;
        stakePlan.endDate = _endDate;
        stakePlan.fixedDays = _fixedDays;
        stakePlan.maxCap = _maxCap;
        stakePlan.minContribution = _minContribution;
        stakePlan.maxContribution = _maxContribution;
        stakePlan.interestRate = _interestRate;
        emit PlanUpdated(
            _index,
            _startDate,
            _endDate,
            _fixedDays,
            _maxCap,
            _minContribution,
            _maxContribution,
            _interestRate
        );
    }

    // enable Plan

    function enablePlan(uint8 _index) external onlyOwner {
        require(totalPlans >= _index, "Plan doesn't exist");
        require(activePlan[_index], "Plan Already Available");
        activePlan[_index] = true;
        emit PlaneEnabled(_index);
    }

    // disable Plan

    function disablePlan(uint8 _index) external onlyOwner {
        require(totalPlans >= _index, "Plan doesn't exist");
        require(!activePlan[_index], "Plan disabled only");
        activePlan[_index] = false;
        emit PlaneDisable(_index);
    }

    // Accepts the stake by meeting following condition
    // 1. Stake should be done after start Date
    // 2. Stake should be done before End Date
    // 3. Minimum Stake amount should be met
    // 4. Maximum Stake amount should not be exhausted
    // 5. Total Staked amount should be within Max Cap for this stake
    function stake(uint8 _plan, uint256 _tokens) external {
        require(totalPlans >= _plan, "Plan doesn't exist");
        require(activePlan[_plan], "Plan is not Active");
        StakePlan storage stakePlan = stakePlans[_plan];
        require(stakePlan.startDate <= block.timestamp, "Staking Not Started");
        require(stakePlan.endDate >= block.timestamp, "Staking Closed");
        require(
            token.allowance(msg.sender, address(this)) >= _tokens,
            "Token allowance too low"
        );
        require(token.balanceOf(msg.sender) >= _tokens, "Not Enough Balance");
        require(stakePlan.minContribution <= _tokens, "Not Enough Token");
        uint256 previouslyStaked = userStakedTokensByPlan[_plan][msg.sender];
        require(
            stakePlan.maxContribution >= previouslyStaked.add(_tokens),
            "Limit Reached"
        );
        require(
            stakePlan.maxCap >= stakePlan.totalStaked.add(_tokens),
            "Target Reached"
        );
        token.safeTransferFrom(msg.sender, address(this), _tokens);
        userStakedTokensByPlan[_plan][msg.sender] = userStakedTokensByPlan[
            _plan
        ][msg.sender].add(_tokens);
        userStakedTokensByContract[msg.sender] = userStakedTokensByContract[
            msg.sender
        ].add(_tokens);
        stakePlan.totalStaked = stakePlan.totalStaked.add(_tokens);
        if (stakePlan.isFixedMaturityDate) {
            if (fixedStakes[_plan][msg.sender].length == 0) {
                FixedStake memory fixedStake;
                fixedStake.createdDate = block.timestamp;
                fixedStake.maturityDate = stakePlan.maturityDate;
                fixedStake.tokens = _tokens;
                fixedStake.interestRate = stakePlan.interestRate;
                fixedStakes[_plan][msg.sender].push(fixedStake);
            } else {
                fixedStakes[_plan][msg.sender][0].tokens = fixedStakes[_plan][
                    msg.sender
                ][0].tokens.add(_tokens);
            }
            fixedStakeLengthByUser[_plan][msg.sender] = 1;
        } else {
            FixedStake memory fixedStake;
            fixedStake.createdDate = block.timestamp;
            fixedStake.maturityDate =
                block.timestamp +
                stakePlan.fixedDays *
                1 days;
            fixedStake.tokens = _tokens;
            fixedStake.interestRate = stakePlan.interestRate;
            fixedStakes[_plan][msg.sender].push(fixedStake);
            fixedStakeLengthByUser[_plan][msg.sender] += 1;
        }
        emit Staked(msg.sender, _plan, _tokens);
    }

    function withdraw(uint8 _plan, uint8 _index) external {
        require(totalPlans >= _plan, "Plan doesn't exist");
        StakePlan storage stakePlan = stakePlans[_plan];
        require(
            fixedStakes[_plan][msg.sender].length >= _index,
            "No token to withdraw"
        );
        FixedStake memory fixedStake = fixedStakes[_plan][msg.sender][_index];
        require(fixedStake.maturityDate <= block.timestamp, "Not Right Time");
        stakePlan.totalStaked = stakePlan.totalStaked.sub(fixedStake.tokens);
        userStakedTokensByPlan[_plan][msg.sender] = userStakedTokensByPlan[
            _plan
        ][msg.sender].sub(fixedStake.tokens);
        userStakedTokensByContract[msg.sender] = userStakedTokensByContract[
            msg.sender
        ].sub(fixedStake.tokens);
        uint256 interestToken = fixedStake
            .tokens
            .mul(fixedStake.interestRate)
            .div(100000000000000000000);
        uint256 maturityToken = interestToken.add(fixedStake.tokens);
        removeArray(_plan, _index);
        require(
            token.balanceOf(address(this)) >= maturityToken,
            "Not Enough Balance"
        );
        token.safeTransfer(msg.sender, maturityToken);
        fixedStakeLengthByUser[_plan][msg.sender] -= 1;
        emit Withdrawn(msg.sender, _plan, maturityToken);
    }

    function stakeInfo(
        uint8 _plan,
        address _address,
        uint256 _index
    )
        external
        view
        returns (
            uint256 _interestToken,
            uint256 _maturityToken,
            uint256 _stakedToken,
            uint256 _createdDate,
            uint256 _maturityDate
        )
    {
        FixedStake memory fixedStake = fixedStakes[_plan][_address][_index];
        uint256 interestToken = fixedStake
            .tokens
            .mul(fixedStake.interestRate)
            .div(100000000000000000000);
        uint256 maturityToken = interestToken.add(fixedStake.tokens);
        return (
            interestToken,
            maturityToken,
            fixedStake.tokens,
            fixedStake.createdDate,
            fixedStake.maturityDate
        );
    }

    function withdrawAdmin(uint256 _tokens) external onlyOwner {
        require(
            token.balanceOf(address(this)) >= _tokens,
            "Not Enough Balance"
        );
        token.safeTransfer(msg.sender, _tokens);
        emit AdminWithdrawn(msg.sender, _tokens);
    }

    function deposit(uint256 _tokens) external {
        require(
            token.allowance(msg.sender, address(this)) >= _tokens,
            "Token allowance too low"
        );
        require(token.balanceOf(msg.sender) >= _tokens, "Not Enough Balance");
        token.safeTransferFrom(msg.sender, address(this), _tokens);
        emit AdminDeposit(msg.sender, _tokens);
    }

    function removeArray(uint8 _plan, uint256 index) internal {
        // Move the last element into the place to delete
        fixedStakes[_plan][msg.sender][index] = fixedStakes[_plan][msg.sender][
            fixedStakes[_plan][msg.sender].length - 1
        ];
        // Remove the last element
        fixedStakes[_plan][msg.sender].pop();
    }

    function addAdmin(address _newAdmin)
        external
        onlyOwner
        validAddress(_newAdmin)
    {
        adminList[_newAdmin] = true;
        emit AdminAdded(msg.sender, _newAdmin);
    }

    function removeAdmin(address _oldAdmin)
        external
        onlyOwner
        validAddress(_oldAdmin)
    {
        require(adminList[_oldAdmin], "Not an Admin");
        adminList[_oldAdmin] = false;
        emit AdminRemoved(msg.sender, _oldAdmin);
    }

    modifier onlyOwner() {
        require(adminList[msg.sender], "Not owner");
        _;
    }

    // address passed in is not the zero address.
    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }
}