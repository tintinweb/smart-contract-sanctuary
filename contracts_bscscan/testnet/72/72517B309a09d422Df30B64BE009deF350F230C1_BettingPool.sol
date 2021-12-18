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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IFactory.sol";
import "./interface/IPriceContract.sol";
import "./interface/IBettingContract.sol";
import "./interface/IFreeBettingContract.sol";
import "./interface/IStandardPrizeBettingContract.sol";
import "./interface/IGuaranteedPrizeBettingContract.sol";
import "./interface/ICommunityBettingContract.sol";

contract BettingPool is Ownable {
    using SafeERC20 for IERC20;
    IPriceContract public priceContract;
    IFactory public factory;

    address public tokenPool;
    address[] public pool;
    mapping(address => address) public creator;
    uint256 public poolLength;
    mapping(address => bool) private existed;
    mapping(PrizeBetting => uint256[]) public rewardRate;

    uint256 private fee;
    uint256 private maxTimeWaitForRefunding;

    enum PrizeBetting {
        GuaranteedPrizeBettingContract,
        StandardPrizeBettingContract,
        CommunityBettingContract,
        FreeBettingContract
    }

    event NewBetting(
        uint256 indexed _index,
        address indexed _address,
        PrizeBetting _typeBetting,
        uint256 _feeForPool
    );
    event UpdatePriceContract(address indexed _old, address indexed _new);
    event UpdateTokenPool(address indexed _old, address indexed _new);
    event UpDateFee(uint256 _old, uint256 _new);
    event UpdateFactory(address _old, address _new);
    event MaxTimeWaitFulfill(uint256 _old, uint256 _new);
    event UpdateRewardRate(RewardRate[] _rewardRateList);

    struct RewardRate {
        PrizeBetting _betting;
        uint256 _rewardForWinner;
        uint256 _rewardForCreator;
        uint256 _decimal;
    }

    constructor(
        address _priceContract,
        address _tokenPool,
        address _factory,
        uint256 _fee
    ) {
        priceContract = IPriceContract(_priceContract);
        tokenPool = _tokenPool;
        factory = IFactory(_factory);
        fee = _fee;
    }

    modifier onlyExistedPool(address _pool) {
        require(existed[_pool], "BETTING_POOL: Pool not found");
        _;
    }

    modifier onlyBettingOwner(address _pool) {
        require(creator[_pool] == msg.sender, "BETTING_POOL: Only Creator");
        _;
    }

    modifier onlyRewardRateExists(PrizeBetting _type) {
        require(
            rewardRate[_type][0] + rewardRate[_type][1] ==
                10**(rewardRate[_type][2] + 2)
        );
        _;
    }

    function setFactory(address _factory) external onlyOwner {
        emit UpdateFactory(address(factory), _factory);
        factory = IFactory(_factory);
    }

    function setTokenPool(address _token) external onlyOwner {
        require(_token != address(0));
        emit UpdateTokenPool(tokenPool, _token);
        tokenPool = _token;
    }

    function setPriceContract(address _priceContract) external onlyOwner {
        emit UpdatePriceContract(address(priceContract), _priceContract);
        priceContract = IPriceContract(_priceContract);
    }

    function setMaxTimeWaitForRefunding(uint256 _time) external onlyOwner {
        require(_time > 300);
        emit MaxTimeWaitFulfill(maxTimeWaitForRefunding, _time);
        maxTimeWaitForRefunding = _time;
    }

    function setRewardRate(RewardRate[] memory _rewardRateList)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _rewardRateList.length; i++) {
            require(_rewardRateList[i]._decimal <= 18);
            require(
                _rewardRateList[i]._rewardForWinner +
                    _rewardRateList[i]._rewardForCreator ==
                    10**(_rewardRateList[i]._decimal + 2)
            );
            rewardRate[_rewardRateList[i]._betting] = [
                _rewardRateList[i]._rewardForWinner,
                _rewardRateList[i]._rewardForCreator,
                _rewardRateList[i]._decimal
            ];
        }
        emit UpdateRewardRate(_rewardRateList);
    }

    function setFee(uint256 _fee) external onlyOwner {
        emit UpDateFee(fee, _fee);
        fee = _fee;
    }

    function getFee() external view returns (uint256) {
        return fee;
    }

    function createNewFreeBetting(
        address _tokenBet,
        uint256 _award,
        uint256 _bracketsDecimals,
        uint256[] memory _bracketsPrice,
        uint256 _priceValidationTimestamp,
        uint256 _lastBetPlaced,
        uint256 _minEntrant,
        uint256 _maxEntrant
    ) public returns (address) {
        // IERC20(tokenPool).safeTransferFrom(msg.sender, address(this), fee);
        address betting = factory.createNewFreeBettingContract(
            payable(address(this)),
            payable(msg.sender),
            tokenPool,
            fee
        );
        pool.push(betting);
        existed[betting] = true;
        creator[betting] = msg.sender;
        poolLength = pool.length;
        emit NewBetting(
            poolLength - 1,
            betting,
            PrizeBetting.FreeBettingContract,
            fee
        );
        setupBettingContract(
            betting,
            _tokenBet,
            0,
            _bracketsDecimals,
            _bracketsPrice,
            _priceValidationTimestamp,
            _lastBetPlaced
        );
        IFreeBettingContract(betting).setMinAndMaxEntrant(
            _minEntrant,
            _maxEntrant
        );
        IFreeBettingContract(betting).setAward(_award);
        IERC20(tokenPool).safeTransferFrom(msg.sender, betting, _award + fee);
        _start(betting);
        return betting;
    }

    function createNewCommunityBetting(
        address _tokenBet,
        uint256 _ticketPrice,
        uint256 _bracketsDecimals,
        uint256[] memory _bracketsPrice,
        uint256 _priceValidationTimestamp,
        uint256 _lastBetPlaced,
        uint256 _minEntrant
    ) public returns (address) {
        // IERC20(tokenPool).safeTransferFrom(msg.sender, address(this), fee);
        address betting = factory.createNewCommunityBettingContract(
            payable(address(this)),
            payable(msg.sender),
            tokenPool,
            fee
        );
        pool.push(betting);
        existed[betting] = true;
        creator[betting] = msg.sender;
        poolLength = pool.length;
        emit NewBetting(
            poolLength - 1,
            betting,
            PrizeBetting.CommunityBettingContract,
            fee
        );
        setupBettingContract(
            betting,
            _tokenBet,
            _ticketPrice,
            _bracketsDecimals,
            _bracketsPrice,
            _priceValidationTimestamp,
            _lastBetPlaced
        );
        ICommunityBettingContract(betting).setMinEntrant(_minEntrant);
        IERC20(tokenPool).safeTransferFrom(msg.sender, betting, fee);
        _start(betting);
        return betting;
    }

    function createNewStandardPrizeBetting(
        address _tokenBet,
        uint256 _ticketPrice,
        uint256 _bracketsDecimals,
        uint256[] memory _bracketsPrice,
        uint256 _priceValidationTimestamp,
        uint256 _lastBetPlaced,
        uint256 _minEntrant,
        uint256 _maxEntrant
    )
        public
        onlyRewardRateExists(PrizeBetting.StandardPrizeBettingContract)
        returns (address)
    {
        // IERC20(tokenPool).safeTransferFrom(msg.sender, address(this), fee);
        address betting = factory.createNewStandardBettingContract(
            payable(address(this)),
            payable(msg.sender),
            tokenPool,
            rewardRate[PrizeBetting.StandardPrizeBettingContract][0],
            rewardRate[PrizeBetting.StandardPrizeBettingContract][1],
            rewardRate[PrizeBetting.StandardPrizeBettingContract][2],
            fee
        );
        pool.push(betting);
        existed[betting] = true;
        creator[betting] = msg.sender;
        poolLength = pool.length;
        emit NewBetting(
            poolLength - 1,
            betting,
            PrizeBetting.StandardPrizeBettingContract,
            fee
        );
        setupBettingContract(
            betting,
            _tokenBet,
            _ticketPrice,
            _bracketsDecimals,
            _bracketsPrice,
            _priceValidationTimestamp,
            _lastBetPlaced
        );
        IStandardPrizeBettingContract(betting).setMinAndMaxEntrant(
            _minEntrant,
            _maxEntrant
        );
        IERC20(tokenPool).safeTransferFrom(
            msg.sender,
            betting,
            IStandardPrizeBettingContract(betting).getUpfrontLockedFunds() + fee
        );
        _start(betting);
        return betting;
    }

    function createNewGuaranteedPrizeBetting(
        address _tokenBet,
        uint256 _ticketPrice,
        uint256 _bracketsDecimals,
        uint256[] memory _bracketsPrice,
        uint256 _priceValidationTimestamp,
        uint256 _lastBetPlaced,
        uint256 _minEntrant,
        uint256 _maxEntrant
    )
        public
        onlyRewardRateExists(PrizeBetting.GuaranteedPrizeBettingContract)
        returns (address)
    {
        // IERC20(tokenPool).safeTransferFrom(msg.sender, address(this), fee);
        address betting = factory.createNewGuaranteedBettingContract(
            payable(address(this)),
            payable(msg.sender),
            tokenPool,
            rewardRate[PrizeBetting.GuaranteedPrizeBettingContract][0],
            rewardRate[PrizeBetting.GuaranteedPrizeBettingContract][1],
            rewardRate[PrizeBetting.GuaranteedPrizeBettingContract][2],
            fee
        );
        pool.push(betting);
        existed[betting] = true;
        creator[betting] = msg.sender;
        poolLength = pool.length;
        emit NewBetting(
            poolLength - 1,
            betting,
            PrizeBetting.GuaranteedPrizeBettingContract,
            fee
        );
        setupBettingContract(
            betting,
            _tokenBet,
            _ticketPrice,
            _bracketsDecimals,
            _bracketsPrice,
            _priceValidationTimestamp,
            _lastBetPlaced
        );
        IGuaranteedPrizeBettingContract(betting).setMinAndMaxEntrant(
            _minEntrant,
            _maxEntrant
        );
        IERC20(tokenPool).safeTransferFrom(
            msg.sender,
            betting,
            IGuaranteedPrizeBettingContract(betting).getUpfrontLockedFunds() +
                fee
        );
        _start(betting);
        return betting;
    }

    function setupBettingContract(
        address _pool,
        address _tokenAddress,
        uint256 _tickerPrice,
        uint256 _bracketsDecimals,
        uint256[] memory _bracketsPrice,
        uint256 _priceValidationTimestamp,
        uint256 _lastBetPlaced
    ) internal returns (bool) {
        IBettingContract(_pool).setBracketsPrice(_bracketsPrice);
        IBettingContract(_pool).setBasic(
            _tokenAddress,
            _tickerPrice,
            _bracketsDecimals,
            _priceValidationTimestamp,
            _lastBetPlaced
        );

        return true;
    }

    function _start(address _pool) internal {
        IBettingContract(_pool).start{value: msg.value}(priceContract);
    }

    function buyTicket(address _betting, uint256 _guessValue)
        public
        onlyExistedPool(_betting)
    {
        uint256 totalFee = IBettingContract(_betting).getTicketPrice() +
            IBettingContract(_betting).getFee();
        if (totalFee > 0) {
            IERC20(tokenPool).safeTransferFrom(msg.sender, _betting, totalFee);
        }

        IBettingContract(_betting).buyTicket(_guessValue, msg.sender);
    }

    function withdrawToken(
        address _token_address,
        address _receiver,
        uint256 _value
    ) public onlyOwner {
        IERC20(_token_address).safeTransfer(_receiver, _value);
    }

    function checkBettingContractExist(address _pool)
        public
        view
        returns (bool)
    {
        return existed[_pool];
    }

    function checkRefund(address _betting) external view returns (bool) {
        (
            bytes32 _resultId,
            ,
            uint256 _priceValidationTimestamp
        ) = IBettingContract(_betting).getDataToCheckRefund();
        if (
            block.timestamp >
            (_priceValidationTimestamp + maxTimeWaitForRefunding) &&
            !priceContract.checkFulfill(_resultId)
        ) return true; //refund

        return false; //don't refund
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "./IPriceContract.sol";

interface IBettingContract {
    event Ticket(
        address indexed _buyer,
        uint256 indexed _bracketIndex,
        uint256 _feeForPool
    );
    event Ready(uint256 _timestamp);
    event Close(uint256 _timestamp, uint256 _price, uint256 _reward);

    enum Status {
        Lock,
        Open,
        End,
        Refund
    }

    struct ResultID {
        bytes32 id;
        uint256 timestamp;
    }

    function setBasic(
        address _tokenAddress,
        uint256 price,
        uint256 decimals,
        uint256 unixtime,
        uint256 _seconds
    ) external;

    function setBracketsPrice(uint256[] calldata _bracketsPrice) external;

    function start(IPriceContract _priceContract) external payable;

    function distributeReward() external;

    function buyTicket(uint256 guess_value, address _user) external;

    function getPrice(uint256 _decimals) external payable;

    function getTicket(address user) external view returns (uint256);

    function getTotalToken() external view returns (uint256);

    function getDataToCheckRefund()
        external
        view
        returns (
            bytes32,
            uint256,
            uint256
        );

    function getTicketPrice() external view returns (uint256);

    function getFee() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "./IPriceContract.sol";

interface ICommunityBettingContract {
    event Ticket(address indexed _buyer, uint256 indexed _bracketIndex);
    event Ready(uint256 _timestamp, bytes32 _resultId);
    event Close(
        uint256 _timestamp,
        uint256 _price,
        address[] _winers,
        uint256 _reward
    );

    enum Status {
        Lock,
        Open,
        End,
        Refund
    }

    function setBasic(
        address _tokenAddress,
        uint256 price,
        uint256 decimals,
        uint256 unixtime,
        uint256 _seconds
    ) external;

    function setMinEntrant(uint256 _minEntrant) external;

    function setBracketsPrice(uint256[] calldata _bracketsPrice) external;

    function start(IPriceContract _priceContract) external payable;

    function close() external;

    function buyTicket(uint256 guess_value) external;

    function getPrice(uint256 _decimals) external payable;

    function getTicket() external view returns (uint256[] memory);

    function getTotalToken() external view returns (uint256);

    function getUpfrontLockedFunds() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IFactory {
    function createNewFreeBettingContract(
        address payable _owner,
        address payable _creator,
        address _tokenPool,
        uint256 _fee
    ) external returns (address);

    function createNewCommunityBettingContract(
        address payable _owner,
        address payable _creator,
        address _tokenPool,
        uint256 _fee
    ) external returns (address);

    function createNewStandardBettingContract(
        address payable _owner,
        address payable _creater,
        address _tokenPool,
        uint256 _rewardForWinner,
        uint256 _rewardForCreator,
        uint256 _decimal,
        uint256 _fee
    ) external returns (address);

    function createNewGuaranteedBettingContract(
        address payable _owner,
        address payable _creater,
        address _tokenPool,
        uint256 _rewardForWinner,
        uint256 _rewardForCreator,
        uint256 _decimal,
        uint256 _fee
    ) external returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "./IPriceContract.sol";

interface IFreeBettingContract {
    event Ticket(address indexed _buyer, uint256 indexed _bracketIndex);
    event Ready(uint256 _timestamp, bytes32 _resultId);
    event Close(
        uint256 _timestamp,
        uint256 _price,
        address[] _winers,
        uint256 _reward
    );

    enum Status {
        Lock,
        Open,
        End,
        Refund
    }

    function setBasic(
        address _tokenAddress,
        uint256 price,
        uint256 decimals,
        uint256 unixtime,
        uint256 _seconds
    ) external;

    function setMinAndMaxEntrant(uint256 _minEntrant, uint256 _maxEntrant)
        external;

    function setAward(uint256 _award) external;

    function setBracketsPrice(uint256[] calldata _bracketsPrice) external;

    function start(IPriceContract _priceContract) external payable;

    function close() external;

    function buyTicket(uint256 guess_value) external;

    function getPrice(uint256 _decimals) external payable;

    function getTicket() external view returns (uint256[] memory);

    function getTotalToken() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "./IPriceContract.sol";

interface IGuaranteedPrizeBettingContract {
    event Ticket(address indexed _buyer, uint256 indexed _bracketIndex);
    event Ready(uint256 _timestamp, bytes32 _resultId);
    event Close(
        uint256 _timestamp,
        uint256 _price,
        address[] _winers,
        uint256 _reward
    );

    enum Status {
        Lock,
        Open,
        End,
        Refund
    }

    function setBasic(
        address _tokenAddress,
        uint256 price,
        uint256 decimals,
        uint256 unixtime,
        uint256 _seconds
    ) external;
    
    function setMinAndMaxEntrant(uint256 _minEntrant, uint256 _maxEntrant)
        external;

    function setBracketsPrice(uint256[] calldata _bracketsPrice) external;

    function start(IPriceContract _priceContract) external payable;

    function close() external;

    function buyTicket(uint256 guess_value) external;

    function getPrice(uint256 _decimals) external payable;

    function getTicket() external view returns (uint256[] memory);

    function getTotalToken() external view returns (uint256);
    
    function getUpfrontLockedFunds() external view returns(uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPriceContract {
    struct Price {
        uint256 value;
        uint256 decimals;
    }

    event GetPrice(bytes32 _id, string _query, uint256 _timestamp);
    event ReceivePrice(bytes32 _id, uint256 _value, uint256 decimals);

    function updatePrice(
        uint256 _time,
        address _tokens,
        uint256 _priceDecimals
    ) external returns (bytes32);

    function checkFulfill(bytes32 _requestId) external view returns (bool);

    function getPrice(bytes32 _id)
        external
        view
        returns (uint256 value, uint256 decimals);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "./IPriceContract.sol";

interface IStandardPrizeBettingContract {
    event Ticket(address indexed _buyer, uint256 indexed _bracketIndex);
    event Ready(uint256 _timestamp, bytes32 _resultId);
    event Close(
        uint256 _timestamp,
        uint256 _price,
        address[] _winers,
        uint256 _reward
    );

    enum Status {
        Lock,
        Open,
        End,
        Refund
    }

    function setBasic(
        address _tokenAddress,
        uint256 price,
        uint256 decimals,
        uint256 unixtime,
        uint256 _seconds
    ) external;

    function setMinAndMaxEntrant(uint256 _minEntrant, uint256 _maxEntrant)
        external;

    function setBracketsPrice(uint256[] calldata _bracketsPrice) external;

    function start(IPriceContract _priceContract) external payable;

    function close() external;

    function buyTicket(uint256 guess_value) external;

    function getPrice(uint256 _decimals) external payable;

    function getTicket() external view returns (uint256[] memory);

    function getTotalToken() external view returns (uint256);

    function getUpfrontLockedFunds() external view returns (uint256);
}