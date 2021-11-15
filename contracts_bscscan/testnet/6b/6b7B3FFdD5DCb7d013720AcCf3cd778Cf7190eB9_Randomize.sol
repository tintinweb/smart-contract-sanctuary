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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

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
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import './libraries/SafeBEP20.sol';
import "./interfaces/IPrediction.sol";
import "./interfaces/IVRFOracleOraichain.sol";
import "./interfaces/IRandom.sol";

contract Randomize is Ownable, IRandom {
    using SafeBEP20 for IBEP20;

    address public orai;
    address public oracle;
    mapping (bytes32 => uint256) public randomResults;
    mapping (bytes32 => uint256) public pids;

    address public prediction;
    
    modifier onlyPrediction() {
        require(
            msg.sender == prediction,
            "RAMDOMIZE: Only call by prediction"
        );
        _;
    }

    /**
     * Reference: https://docs.orai.io/vrf/get-a-random-number
     * @param _prediction New prediction contract address
     * @param _orai ORAI token address on the corresponding network
     * @param _oracle Oracel address on the corresponding network
     */
    constructor(
        address _prediction,
        address _orai,
        address _oracle
    ) {
        orai = _orai;
        oracle = _oracle; 
        prediction = _prediction;
    }

    /**
     * @dev Withdraw any token in contract, only by Owner
     * @param token Token address to withdraw
     * @param amount Amount to withdraw
     * @param to Wallet address of receiver
     */
    function withdrawTokens(address token, uint256 amount, address to) public onlyOwner {
        IBEP20(token).safeTransfer(to, amount);
    } 
    
    /** 
     * @dev Requests randomness from prediction for a pool, only by prediction contract
     * @param pid pool id in prediction contract
     * @return requestId request id of this request
     */
    function getRandomNumber(uint256 pid) public override onlyPrediction returns (bytes32 requestId) 
    {
        IBEP20(orai).approve(oracle, IVRFOracleOraichain(oracle).fee());

        bytes memory data = abi.encode(address(this), this.fulfillRandomness.selector);

        uint256 seed = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        requestId = IVRFOracleOraichain(oracle).randomnessRequest(seed, data);

        pids[requestId] = pid;
    }

    /**
     * Callback function used by VRF Coordinator
     * @param requestId request id of this callback
     * @param randomness a randomness number
     */
    function fulfillRandomness(bytes32 requestId, bytes32 randomness) external override {
        require(msg.sender == oracle, "RANDOMIZE: Only called by oracle");
        IPrediction(prediction).numbersDrawn(
            pids[requestId],
            requestId,
            uint256(randomness)
        );
        pids[requestId] = uint256(randomness);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @dev Interface of the BEP20 standard.
 */
interface IBEP20 {
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
    
    function burn(uint256 amount) external returns(bool success);

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
pragma solidity 0.8.0;

import "./IBEP20.sol";

interface IPrediction {
    /**
     * @dev Status of pool
     */
    enum Status {
        Open,
        Lock,
        End
    }
    
     /**
     * @dev Pool infomation that has not changed or changed very little
     */
    struct Pool {
        address oraclePriceCaller;
        string description;
        uint256 priceDecimals;
        uint256 betTime;
        uint256 ticketPriceStart;
        uint256 ticketFeeStart;
        uint8 ticketNumberInit;
    }
    
    /**
     * @dev Pool infomation that has not changed or changed very little
     */
    struct Round {
        uint256 startTime;
        uint256 endTime;
        
        uint256 startPrice;
        uint256 closePrice;
        
        Status status;
        
        uint256 rewardAmount;
        uint256 lotteryRewardAmount;
    }
    
    /**
     * @dev Pool specification that change frequently during operation
     */
    struct Specification {
        uint256 redTicketNumber;
        uint256 blueTicketNumber;
        
        uint256 redPool;
        uint256 bluePool;
        uint256 feePool;

        uint256 additionalReward;

        bytes32 lotteryWinningRequestId;
        bool oracleCalled;
        uint256 lotteryWinningNumber;
    }
    
    /**
     * @dev Ticket infomation
     * label=true if blue ticket, label=false if red ticket
     */
    struct Bought {
        bool label;
        uint256 quantity;
        uint256 price;
        uint256 fee;
        uint256 lotteryNumber;
        bool claimed;
    }
    
    event NewPool(uint256 indexed pid, address indexed creator);
    event StartRound(uint256 indexed pid, uint256 indexed epoch, uint256 startTime, uint256 endTime, uint256 startPrice);
    event LockRound(
        uint256 indexed pid, 
        uint256 indexed epoch, 
        uint256 closePrice, 
        uint256 bluePool,
        uint256 redPool,
        uint256 blueTicket,
        uint256 redTicket
    );
    event EndRound(uint256 indexed pid, uint256 indexed epoch, uint256 price);
    event OracleResponse(uint256 indexed pid, uint256 indexed epoch, bytes32 requestId);
    event BurnFee(uint256 indexed pid, uint256 indexed epoch, uint256 fee);
    event BoughtTicket(
        address indexed buyer, 
        bool label, 
        uint256 indexed pid, 
        uint256 indexed epoch, 
        uint256 tid, 
        uint256 quantity, 
        uint256 lotteryNumber, 
        uint256 price, 
        uint256 fee,
        uint256 timestamp
    );
    event Claim(uint256 indexed pid, uint256 indexed epoch, address indexed owner, address to, uint256 amount, uint256[] tids);
    event ClaimTreasury(uint256 amount);
    event ClaimReferralReward(address caller, address receiver, uint256 amount);
    event RewardsCalculated(
        uint256 indexed pid,
        uint256 indexed epoch,
        uint256 rewardAmount,
        uint256 lotteryAmount,
        uint256 lotteryWinningNumber,
        uint8 result,
        uint256 timestamp
    );
    event UpdatedRandomService(address indexed _old, address indexed _new);
    event UpdatedPriceService(address indexed _old, address indexed _new);
    event UpdatedAchievementService(address indexed _old, address indexed _new);
    event UpdatedLotteryRatio(uint256 indexed _old, uint256 indexed _new);
    event UpdatedOperator(address indexed _old, address indexed _new);
    /**
     * @dev Callback function used by Randomize contract
     * @param _pid id of pool
     * @param _requestId id was returned by chainlink when request a randomness number (https://docs.chain.link/docs/get-a-random-number)
     * @param _randomNumber a randomness number was returned by chainlink
     */
    function numbersDrawn(uint256 _pid, bytes32 _requestId, uint256 _randomNumber) external;
    function tokenReward() view external returns(IBEP20);
    function rounds(uint256 _pid, uint256 _epoch) view external returns(
        uint256 startTime,
        uint256 endTime,
        uint256 startPrice,
        uint256 closePrice,
        Status status,
        uint256 rewardAmount,
        uint256 lotteryRewardAmount
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IRandom {
    function getRandomNumber(uint256 pid) external returns (bytes32 requestId);

    function fulfillRandomness(bytes32 requestId, bytes32 randomness) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVRFOracleOraichain {
    function randomnessRequest(uint256 _seed, bytes calldata _data) external returns (bytes32);

    function fee() external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../interfaces/IBEP20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeBEP20: decreased allowance below zero");
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
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

