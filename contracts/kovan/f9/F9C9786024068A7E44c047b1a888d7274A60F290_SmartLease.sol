// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "SafeERC20.sol";
import "KeeperCompatibleInterface.sol";

contract SmartLease is KeeperCompatibleInterface {
    //contract leasecontract {
    // ERC20 Variable
    using SafeERC20 for IERC20;
    IERC20 private _token;

    // Chainlink Keeper
    uint256 public immutable interval;
    uint256 public lastTimeStamp;
    uint256 public counter;

    // Time Variable
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // Lease Params
    uint256 public sign_time_limit; //Minute !!Testing Only!!
    uint256 public amount;
    uint256 public deposit_amount; //WEI
    uint256 public refund_token_amount; //WEI
    string public payment_method; //String : ADV or ARR
    string public payment_cycle; //Monthly
    uint256 public start_date; //Epoch
    uint256 public end_date; //Epoch

    // Other Variable
    address public adminAddress;
    address public lessorAddress;
    address public lessieAddress;
    uint256 public inception_date;

    // Mapping
    mapping(address => uint256) public addressToDeposit;

    // Smart Lease Contract State
    enum STATE {
        DEACTIVATE,
        READY,
        LESSOR_DEPOSIT,
        LESSIE_DEPOSIT,
        LEASE_PROCESS,
        LEASE_COMPLETE,
        FREEZE
    }
    STATE public state;
    STATE public prev_state;

    // Modifier
    modifier onlyAdmin() {
        require(msg.sender == adminAddress);
        _;
    }

    modifier onlyLessorLessie() {
        require(msg.sender == lessorAddress || msg.sender == lessieAddress);
        _;
    }

    modifier onlyLessor() {
        require(msg.sender == lessorAddress, "Only Lessor");
        _;
    }

    modifier onlyLessie() {
        require(msg.sender == lessieAddress, "Only Lessie");
        _;
    }

    // Rinkeby DAI : 0x5eD8BD53B0c3fa3dEaBd345430B1A3a6A4e8BD7C
    // Kovan ABG   : 0xB89a3292BD8604Ba72C2ab9979F0573d23A631fA,1
    constructor(IERC20 _erc20Token, uint256 updateInterval) public {
        state = STATE.DEACTIVATE;
        prev_state = STATE.DEACTIVATE;
        _token = _erc20Token;
        adminAddress = msg.sender;
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
    }

    function getContractTokenBalance() public view returns (uint256) {
        uint256 erc20balance = _token.balanceOf(address(this));
        return erc20balance;
    }

    // 2 minute, 2 token, lessor, lessie
    // 120,2000000000000000000,0x98e92d9133642e4429b46EE40a94A30A4544a8CA,0x5125400b37859318554c93f8a87e85D93D570f02
    // function lease_inception(
    // uint256 _sign_time_limit,
    // uint256 _amount,
    // uint256 _deposit_amount,
    // string memory _payment_method,
    // string memory _payment_cycle,
    // uint256 _start_year,
    // uint256 _start_month,
    // uint256 _start_date,
    // uint256 _end_year,
    // uint256 _end_month,
    // uint256 _end_date
    function lease_inception(
        uint256 _sign_time_limit,
        uint256 _deposit_amount,
        address _lessorAddress,
        address _lessieAddress
    ) public onlyAdmin {
        require(state == STATE.DEACTIVATE);
        state = STATE.READY;
        prev_state = STATE.DEACTIVATE;

        inception_date = block.timestamp;
        sign_time_limit = _sign_time_limit;
        // amount = _amount;
        lessorAddress = _lessorAddress;
        lessieAddress = _lessieAddress;
        deposit_amount = _deposit_amount;
        // payment_method = _payment_method;
        // payment_cycle = _payment_cycle;

        // start_year = _start_year;
        // start_month = _start_month;
        // start_date = _start_date;

        // end_year = _end_year;
        // end_month = _end_month;
        // end_date = _end_date;
        refund_token_amount = 0;
    }

    // Contract Sign + Deposit
    function lessorSignDeposit() public onlyLessor {
        // !!! Add require (now - inception_date <= sign_time_limit) !!!
        require(state == STATE.READY, "lease inception is needed!");
        uint256 contract_token_balance = getContractTokenBalance();
        if (deposit_amount == contract_token_balance) {
            addressToDeposit[lessorAddress] = deposit_amount;
            state = STATE.LESSOR_DEPOSIT;
            prev_state = STATE.READY;
        } else {
            // Send token to unknown refund
            refund_token_amount += contract_token_balance;
            state = STATE.FREEZE;
            prev_state = STATE.READY;
        }
    }

    // Lessie Sign Contract + Deposit
    function lessieSignDeposit() public onlyLessie {
        // !!! Add require (now - inception_date <= sign_time_limit) !!!
        require(
            state == STATE.LESSOR_DEPOSIT,
            "please wait lessor to deposit!"
        );
        uint256 contract_token_balance = getContractTokenBalance();
        if ((deposit_amount * 2) == contract_token_balance) {
            addressToDeposit[lessorAddress] = deposit_amount;
            state = STATE.LESSIE_DEPOSIT;
            prev_state = STATE.LESSOR_DEPOSIT;
        } else {
            // Refund Lessor Token Deposit
            uint256 lessor_depo = addressToDeposit[lessorAddress];
            addressToDeposit[lessieAddress] = 0;
            _token.transfer(lessorAddress, lessor_depo);
            // Send token to unknown refund
            refund_token_amount += contract_token_balance;
            state = STATE.FREEZE;
            prev_state = STATE.LESSOR_DEPOSIT;
        }
    }

    // Sign Time Limit Exceeded !! Internal Function, Testing Only!!
    function TLE_Sign() public {
        uint256 contract_token_balance = getContractTokenBalance();
        uint256 currentTimestamp = block.timestamp;
        uint256 diff_min = diffSeconds(inception_date, currentTimestamp);
        // !!! In Second, Testing Only !!!
        if (diff_min > sign_time_limit) {
            // lessor already deposit?
            if (addressToDeposit[lessorAddress] != 0) {
                uint256 lessor_depo = addressToDeposit[lessorAddress];
                addressToDeposit[lessieAddress] = 0;
                _token.transfer(lessorAddress, lessor_depo);
                // unknown refund token
                refund_token_amount += contract_token_balance;
            } else {
                refund_token_amount += contract_token_balance;
            }
            // Set To Freeze State
            state = STATE.FREEZE;
        }
    }

    // Admin Widhraw
    function collectUnknownWithdraw() public onlyAdmin {
        // Require (state=FREEZE or time_exeed)
        require(state == STATE.FREEZE);
        // Reset all variable
        state = STATE.DEACTIVATE;
        prev_state = STATE.FREEZE;
        uint256 erc20balance = _token.balanceOf(address(this));
        _token.transfer(adminAddress, amount);
    }

    // Lessor Lessie Withdraw Deposit
    function withdrawDeposit() public onlyLessorLessie {
        require(state == STATE.LEASE_COMPLETE);
        uint256 deposit_amount = addressToDeposit[msg.sender];
        addressToDeposit[msg.sender] = 0;
        _token.transfer(msg.sender, deposit_amount);
        if (
            addressToDeposit[lessorAddress] == 0 &&
            addressToDeposit[lessieAddress] == 0
        ) {
            state = STATE.DEACTIVATE;
            // Reset all variable
        }
    }

    // Simulate contract finish !!! Testing Only !!!
    function setComplete() public onlyAdmin {
        state = STATE.LEASE_COMPLETE;
    }

    // Chainlink function
    function checkUpkeep(bytes calldata checkData)
        external
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata performData) external override {
        lastTimeStamp = block.timestamp;
        counter = counter + 1;
        // Status Checker
    }

    // Time Function
    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _minutes)
    {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _seconds)
    {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}