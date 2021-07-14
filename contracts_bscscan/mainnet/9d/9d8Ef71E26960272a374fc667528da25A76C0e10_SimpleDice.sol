// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Address.sol";

contract GambleBase {
    using Address for address;

    modifier noContract() {
        // solium-disable
        require(msg.sender == tx.origin && !address(msg.sender).isContract(), "no indirect calls");
        // solium-enable
        _;
    }

    function unsafeRand() internal view returns(uint256) {
        // solium-disable
        uint256 random = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit +
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));
        // solium-enable
        return (random - ((random / 1000) * 1000));
    }

    function rand(bytes32 seed) internal pure returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(seed)));
        return (random - ((random / 1000) * 1000));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Base/GambleBase.sol";

contract SimpleDice is GambleBase, Ownable {
    using SafeERC20 for IERC20;

    mapping(address => BetResult) public lastResult;
    mapping(address => uint256) public tokenBurn;

    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public minBet = 100000000000000;
    uint256 public maxPercWin = 100; // Percentage points

    uint256 public houseEdge = 200; // Percentage points

    mapping(bytes32 => uint256) public unfinishedBetHashToTimestamp;

    event BetStarted(bytes32 indexed betHash, Bet bet);
    event Roll(bytes32 indexed betHash, Bet bet, uint256 result, uint256 payout);
    event BetExpired(bytes32 indexed betHash, address user, uint256 betAmount);

    struct Bet
    {
        IERC20 token;
        address gambler;
        bytes32 commit;
        bytes32 userSeed;
        uint256 blockNumber;
        uint256[3] rollIntegerVariables;
    }

    struct BetResult {
        uint256 roll;
        uint256 reward;
    }

    function maxWin(IERC20 _token) public view returns(uint256) {
        return budget(_token) * maxPercWin / 10000;
    }

    function budget(IERC20 _token) public view returns(uint256) {
        return _token.balanceOf(address(this));
    }

    // Get the expected win amount after house edge is subtracted.
    function getWinAmount(uint256 amount, uint256 modulo, uint256 odds) public view returns (uint256 winAmount) {
        require (0 < odds && odds <= modulo, "Win probability out of range.");
        uint256 houseEdgeFee = amount * houseEdge / 10000;
        winAmount = (amount - houseEdgeFee) * modulo / odds;
    }

    function setMaxPercWin(uint256 _perc) external onlyOwner {
        require(_perc <= 10000, "use percentage points");
        maxPercWin = _perc;
    }

    function setBurnPerc(address _tokenAddress, uint256 _perc) external onlyOwner {
        require(_perc <= 10000, "use percentage points");
        tokenBurn[_tokenAddress] = _perc;
    }

    function setBurnAddress(address _burnAddress) external onlyOwner {
        require(_burnAddress != address(0), "Real null, not allowed");
        burnAddress = _burnAddress;
    }

    function setMinBet(uint256 _value) external onlyOwner {
        minBet = _value;
    }

    function withdraw(IERC20 _token, uint256 _amount) external onlyOwner {
        require(budget(_token) >= _amount, "Insufficient funds");
        _token.safeTransfer(msg.sender, _amount);
    }

    function _roll(bytes32 seed) internal pure returns (uint256) {
        return rand(seed) % 100;
    }

    /**
    * uint256[] _rollIntegerVariables array contains:
    * _rollIntegerVariables[0] = _predictionNUmber;
    * _rollIntegerVariables[1] = _rollUnderOrOver;    // 0 = roll under, 1 = roll over
    * _rollIntegerVariables[2] = _amount;

    *
    **/
    function startBet(IERC20 _token, uint256[3] memory _rollIntegerVariables, bytes32 _userSeed, bytes32 _houseCommit) external payable noContract {

        uint256 amount = _rollIntegerVariables[2];
        // The main bet must be at least the minimum main bet
        require(amount >= minBet, "Main bet amount too low");

         _token.safeTransferFrom(msg.sender, address(this), amount);

        // Ensure that:
        // _rollIntegerVariables[0] >= 0 && _rollIntegerVariables[0] < 100
        // _rollIntegerVariables[1] == 0 || _rollIntegerVariables[1] == 1
        // require(_rollIntegerVariables[0] >= 0 && _rollIntegerVariables[0] < 100, "Invalid prediction number");
        require(_rollIntegerVariables[1] == 0 || _rollIntegerVariables[1] == 1, "Invalid roll under or roll over number");

        if(_rollIntegerVariables[1] == 0) require(_rollIntegerVariables[0] > 0 && _rollIntegerVariables[0] < 97 , "Invalid prediction number");
        if(_rollIntegerVariables[1] == 1) require(_rollIntegerVariables[0] > 2 && _rollIntegerVariables[0] < 99 , "Invalid prediction number");

        Bet memory betObject = createBetObject(_token, msg.sender, _houseCommit, _userSeed, block.number, _rollIntegerVariables);
        bytes32 betHash = calculateBetHash(betObject);

        require(unfinishedBetHashToTimestamp[betHash] == 0, "Bet hash already exists");

        // Store the bet hash
        /* solium-disable-next-line */
        unfinishedBetHashToTimestamp[betHash] = block.timestamp;

        emit BetStarted(betHash, betObject);
    }

    function finishBet(IERC20 _token, address _gambler,uint256 _blockNumber, uint256[3] memory _rollIntegerVariables, bytes32 _userSeed, bytes32 _houseReveal) external {

        bytes32 houseCommit = hashBytes(_houseReveal);
        Bet memory betObject = createBetObject(_token, _gambler, houseCommit, _userSeed, _blockNumber, _rollIntegerVariables);
        bytes32 betHash = calculateBetHash(betObject);

        uint256 betTimestamp = unfinishedBetHashToTimestamp[betHash];
        
        // If the bet has already been finished, do nothing
        require(betTimestamp != 0, "Bet not found");

        // If the bet has expired...
        if (betObject.blockNumber < block.number-256)
        {
            // Mark bet as finished
            unfinishedBetHashToTimestamp[betHash] = 0;
            emit BetExpired(betHash, betObject.gambler, betObject.rollIntegerVariables[2]);
            _token.safeTransferFrom(address(this), betObject.gambler, betObject.rollIntegerVariables[2]);
            return;
        }

        uint256 roll = _roll(keccak256(abi.encodePacked(_houseReveal, betHash, blockhash(betObject.blockNumber))));
        uint256 payout = 0;

        if (betObject.rollIntegerVariables[1] == 0 && roll < betObject.rollIntegerVariables[0]) {
            payout = getWinAmount(betObject.rollIntegerVariables[2], 100, betObject.rollIntegerVariables[0]);
        }
        else if (betObject.rollIntegerVariables[1] != 0 && roll > betObject.rollIntegerVariables[0]) {
            payout = getWinAmount(betObject.rollIntegerVariables[2], 100, 99 - betObject.rollIntegerVariables[0]);
        }

        // Mark bet as finished
        unfinishedBetHashToTimestamp[betHash] = 0;

        if (payout > betObject.rollIntegerVariables[2]) {
            // If profit bigger than maxWin refund bet
            if (payout - betObject.rollIntegerVariables[2] >= maxWin(_token)) _token.safeTransferFrom(address(this), betObject.gambler, betObject.rollIntegerVariables[2]);
            else _token.safeTransferFrom(address(this), betObject.gambler, payout);
        } else if (tokenBurn[address(_token)] != 0) {
            uint256 burnAmount = (betObject.rollIntegerVariables[2] * tokenBurn[address(_token)]) / 10000;
            _token.safeTransfer(burnAddress, burnAmount);
        }

        lastResult[msg.sender] = BetResult({
            roll: roll,
            reward: payout
        });

        emit Roll(betHash, betObject, roll, payout);
    }

    function createBetObject(
        IERC20 _token,
        address _gambler,
        bytes32 _commit,
        bytes32 _userSeed,
        uint256 _blockNumber,
        uint256[3] memory _rollIntegerVariables) private pure returns (Bet memory bet)
    {
        return Bet({
            token: _token,
            gambler: _gambler,
            commit: _commit,
            userSeed: _userSeed,
            blockNumber: _blockNumber,
            rollIntegerVariables: _rollIntegerVariables
        });
    }

    function calculateBetHash(Bet memory _bet) public pure returns (bytes32)
    {
        return keccak256(abi.encode(_bet));
    }

    function hashBytes(bytes32 _toHash) public pure returns (bytes32)
    {
        return keccak256(abi.encode(_toHash));
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}