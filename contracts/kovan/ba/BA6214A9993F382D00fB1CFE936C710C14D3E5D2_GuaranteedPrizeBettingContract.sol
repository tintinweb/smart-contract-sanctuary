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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IBettingContract.sol";

abstract contract AbstractBettingContract is IBettingContract {
    address payable public immutable owner;
    address payable public immutable creator;

    address public tokenAddress;
    address public tokenPool;

    uint256 public lastBetPlaced; // seconds
    uint256 public priceValidationTimestamp; // timestamp

    uint8 public bracketsPriceDecimals;
    uint256[] public bracketsPrice;

    Status public status = Status.Lock;

    address[] public listBuyer;
    mapping(address => uint256[]) public buyers;
    mapping(uint256 => address[]) public ticketSell;
    uint256 public gapValidatePriceTime = 300;
    IPriceContract public priceContract;
    bytes32 public resultId;

    constructor(
        address payable _owner,
        address payable _creator,
        address _tokenPool
    ) {
        owner = _owner;
        creator = _creator;
        tokenPool = _tokenPool;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    modifier decimalsLength(uint8 decimals) {
        require(decimals >= 0 && decimals <= 18);
        _;
    }

    modifier onlyOpen() {
        require(status == Status.Open);
        _;
    }

    modifier onlyLock() {
        require(status == Status.Lock);
        _;
    }

    modifier betable() {
        require(block.timestamp <= priceValidationTimestamp - lastBetPlaced);
        _;
    }

    modifier onlyPriceClosed() {
        require(block.timestamp > priceValidationTimestamp);
        _;
    }

    //Example: [1, 2, 3, 4] ==>  1 <= bracket1 < 2, 2 <= bracket2 < 3, 3 <= bracket3 < 4
    function setBracketsPrice(uint256[] calldata _bracketsPrice)
        external
        override
        onlyOwner
        onlyLock
    {
        for (uint256 i = 1; i < _bracketsPrice.length; i++) {
            require(_bracketsPrice[i] > _bracketsPrice[i - 1]);
        }
        bracketsPrice = _bracketsPrice;
    }

    function getPrice(uint8 _decimals)
        external
        payable
        override
        onlyOpen
        decimalsLength(_decimals)
    {
        require(
            block.timestamp >= priceValidationTimestamp + gapValidatePriceTime
        );
        resultId = priceContract.updatePrice{value: msg.value}(
            priceValidationTimestamp,
            tokenAddress,
            payable(msg.sender),
            _decimals,
            owner
        );
    }

    function getTicket() public view override returns (uint256[] memory) {
        return buyers[msg.sender];
    }

    function getTotalToken() public view override returns (uint256) {
        return IERC20(tokenPool).balanceOf(address(this));
    }

    function _getResult()
        internal
        view
        returns (
            uint256 price,
            uint256 index,
            bool success
        )
    {
        (uint256 _price, uint16 _decimals) = IPriceContract(priceContract)
            .getPrice(resultId);

        if (bracketsPriceDecimals >= _decimals) {
            price = _price * 10**(bracketsPriceDecimals - _decimals);
        } else {
            price = _price / 10**(_decimals - bracketsPriceDecimals);
        }

        if (price == 0) {
            return (price, 0, false);
        }

        if (price < bracketsPrice[0]) {
            return (price, 0, true);
        }
        if (price >= bracketsPrice[bracketsPrice.length - 1]) {
            return (price, bracketsPrice.length, true);
        }
        for (uint256 i = 0; i < bracketsPrice.length - 1; i++) {
            if (bracketsPrice[i] <= price && price < bracketsPrice[i + 1]) {
                return (price, i + 1, true);
            }
        }

        return (price, 0, false);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./AbstractBettingContract.sol";

contract GuaranteedPrizeBettingContract is AbstractBettingContract {
    using SafeERC20 for IERC20;

    uint256 public maxEntrants;
    uint256 public ticketPrice;
    uint256 public upfrontLockedFunds;
    uint256 public rewardForWinner = 95;
    uint256 public rewardForCreator = 5;
    uint256 decimalOfRate;

    constructor(
        address payable _owner,
        address payable _creator,
        address _tokenPool,
        uint256 _rewardForWinner,
        uint256 _rewardForCreator,
        uint256 _decimalOfRate
    ) AbstractBettingContract(_owner, _creator, _tokenPool) {
        rewardForWinner = _rewardForWinner;
        rewardForCreator = _rewardForCreator;
        decimalOfRate = _decimalOfRate;
    }

    modifier onlySlotAvailable() {
        require(listBuyer.length < maxEntrants);
        _;
    }

    function getUpfrontLockedFunds() external view returns (uint256) {
        return upfrontLockedFunds;
    }

    function setBasic(
        address _tokenAddress,
        uint256 price,
        uint8 decimals,
        uint256 unixtime,
        uint256 _seconds
    ) external override onlyOwner onlyLock decimalsLength(decimals) {
        require(_tokenAddress != address(0));
        require(block.timestamp < unixtime);
        tokenAddress = _tokenAddress;
        ticketPrice = price;
        bracketsPriceDecimals = decimals;
        priceValidationTimestamp = unixtime;
        lastBetPlaced = _seconds;
    }

    function setMaxEntrant(uint256 _maxEntrant) external onlyOwner onlyLock {
        maxEntrants = _maxEntrant;
        upfrontLockedFunds = _maxEntrant * ticketPrice;
    }

    function start(IPriceContract _priceContract)
        external
        payable
        override
        onlyOwner
        onlyLock
    {
        require(priceValidationTimestamp > block.timestamp);
        require(priceValidationTimestamp - block.timestamp > lastBetPlaced);
        require(bracketsPrice.length > 0);
        require(tokenAddress != address(0x0));
        require(
            IERC20(tokenPool).balanceOf(address(this)) == upfrontLockedFunds
        );
        priceContract = _priceContract;
        status = Status.Open;
        emit Ready(block.timestamp);
    }

    function close() external override onlyPriceClosed onlyOpen {
        (uint256 price, uint256 result, bool success) = _getResult();
        status = Status.End;
        address[] memory winners;
        if (!success) {
            winners = listBuyer;
        } else {
            winners = ticketSell[result];
        }
        uint256 reward = 0;
        if (winners.length > 0) {
            reward =
                (upfrontLockedFunds * rewardForWinner) /
                (winners.length * 10**(decimalOfRate + 2));
            for (uint256 i = winners.length - 1; i >= 0; i--) {
                if (winners[i] != address(0x0)) {
                    address winner = winners[i];
                    delete winners[i];
                    IERC20(tokenPool).safeTransfer(winner, reward);
                }
            }
        }

        IERC20(tokenPool).safeTransfer(creator, getTotalToken());
        emit Close(block.timestamp, price, winners, reward);
        selfdestruct(owner);
    }

    // guess_value = real_value * 10**bracketsPriceDecimals
    function buyTicket(uint256 _bracketIndex)
        public
        override
        onlyOpen
        onlySlotAvailable
        betable
    {
        require(msg.sender != creator);

        IERC20(tokenPool).safeTransferFrom(
            msg.sender,
            address(this),
            ticketPrice
        );

        if (_bracketIndex > bracketsPrice.length - 1) {
            _bracketIndex = bracketsPrice.length;
        }
        buyers[msg.sender].push(_bracketIndex);
        ticketSell[_bracketIndex].push(msg.sender);
        listBuyer.push(msg.sender);
        emit Ticket(msg.sender, _bracketIndex);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "./IPriceContract.sol";

interface IBettingContract {
    event Ticket(address indexed _buyer, uint256 indexed _bracketIndex);
    event Ready(uint256 _timestamp);
    event Close(
        uint256 _timestamp,
        uint256 _price,
        address[] _winers,
        uint256 _reward
    );

    enum Status {
        Lock,
        Open,
        End
    }

    function setBasic(
        address _tokenAddress,
        uint256 price,
        uint8 decimals,
        uint256 unixtime,
        uint256 _seconds
    ) external;

    function setBracketsPrice(uint256[] calldata _bracketsPrice) external;

    function start(IPriceContract _priceContract) external payable;

    function close() external;

    function buyTicket(uint256 guess_value) external;

    function getPrice(uint8 _decimals) external payable;

    function getTicket() external view returns (uint256[] memory);

    function getTotalToken() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPriceContract {
    struct Price {
        uint256 value;
        uint8 decimals;
    }

    event GetPrice(bytes32 _id, string _query, uint256 _timestamp);
    event ReceivePrice(bytes32 _id, uint256 _value, uint8 decimals);

    function updatePrice(
        uint256 _time,
        address _tokens,
        address payable _refund,
        uint8 _priceDecimals,
        address _ownerPool
    ) external payable returns (bytes32);

    function getPrice(bytes32 _id)
        external
        view
        returns (uint256 value, uint8 decimals);
}