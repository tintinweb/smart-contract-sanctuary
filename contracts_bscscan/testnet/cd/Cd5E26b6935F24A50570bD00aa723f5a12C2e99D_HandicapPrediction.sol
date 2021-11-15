// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libraries/DataTypes.sol";
import "./interfaces/IMatch.sol";

contract HandicapPrediction is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping (address => bool) admins;
    mapping (uint256 => DataTypes.HandicapPrediction) public predictions;
    mapping (address => mapping (uint256 => DataTypes.HandicapPredictionStats)) public predictionStats;
    mapping (address => mapping(uint256 => DataTypes.HandicapPredictHistory[])) public predictHistories;
    mapping (address => mapping(uint256 => bool)) public withdrawable;
    uint256 public nPredictions;
    uint256 constant ZOOM = 10000;
    uint256 public fee = 50;

    IMatch public matchData;

    /* ========== PUBLIC FUNCTIONS ========== */

    function createPrediction(uint256 _matchId, address _token, uint256 _hardCap, uint256 _minPredict, DataTypes.Handicap memory _handicap, uint256 _chosenTeam)
    external payable
    returns (uint256 _idx)
    {
        DataTypes.Match memory _match = matchData.info(_matchId);
        require(_match.status == DataTypes.MatchStatus.AVAILABLE, 'match-not-available');
        require(_handicap.side == 1 || _handicap.side == 2, 'handicap-invalid');
        require(_chosenTeam == 1 || _chosenTeam == 2, 'chosen_team-invalid');
        if (_token == address(0)) {
            _hardCap = msg.value;
        } else {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _hardCap);
        }
        _idx = nPredictions;
        if (_hardCap > 0) {
            predictions[_idx] = DataTypes.HandicapPrediction(
                msg.sender,
                _token,
                _matchId,
                _minPredict,
                _hardCap,
                _handicap,
                _chosenTeam,
                0,
                DataTypes.HandicapPredictionStatus.ENABLE
            );
            withdrawable[msg.sender][_idx] = true;
            nPredictions++;
            emit PredictionCreated(_idx, msg.sender, _matchId, _minPredict, _hardCap, _handicap);
        }
    }

    function cancelPrediction(uint256 _predictionId) external {
        DataTypes.HandicapPrediction storage _prediction = predictions[_predictionId];
        require(msg.sender == _prediction.dealer, 'not-dealer');
        require(_prediction.totalUserDeposit == 0, 'user-has-deposit');
        require(_prediction.status == DataTypes.HandicapPredictionStatus.ENABLE, '!enable');

        _prediction.status = DataTypes.HandicapPredictionStatus.DISABLE;
        transferMoney(_prediction.token, msg.sender, _prediction.hardCap);
    }

    function predict(uint256 _predictionId, uint256 _amount) payable external {
        uint256 _predictValue = msg.value;
        DataTypes.HandicapPrediction memory _prediction = predictions[_predictionId];
        if (_prediction.token != address(0)) {
            _predictValue = _amount;
            IERC20(_prediction.token).safeTransferFrom(msg.sender, address(this), _amount);
        }
        require(_predictValue > 0, 'predict-value = 0');
        require(_prediction.dealer != address(0), 'prediction-not-exist');
        require(_prediction.status == DataTypes.HandicapPredictionStatus.ENABLE, 'prediction-not-enable');
        require(_prediction.totalUserDeposit + _predictValue <= _prediction.hardCap, 'reach-hard-cap');
        require(_predictValue >= _prediction.minPredict, '< min_predict');

        DataTypes.Match memory _match = matchData.info(_prediction.matchId);
        require(_match.startTime <= block.timestamp && block.timestamp <= _match.endTime, 'invalid-predict-time');
        require(_match.status == DataTypes.MatchStatus.AVAILABLE, 'match-not-available');

        predictHistories[msg.sender][_predictionId].push(DataTypes.HandicapPredictHistory(_predictValue, block.timestamp));
        predictInternal(_predictionId, msg.sender, _predictValue);
        emit PredictCreated(msg.sender, _predictionId, _predictValue);
    }

    function claimReward(uint256 _predictionId) external {
        DataTypes.HandicapPrediction memory _prediction = predictions[_predictionId];
        DataTypes.Match memory _match = matchData.info(_prediction.matchId);
        DataTypes.Score memory _score = _match.score;
        DataTypes.Handicap memory _handicap = _prediction.handicap;

        require(_match.status == DataTypes.MatchStatus.FINISH, 'match-not-finish');
        require(_match.endTime <= block.timestamp, 'end_time > timestamp');

        DataTypes.HandicapPredictionStats storage _predictionStats = predictionStats[msg.sender][_predictionId];
        if (_predictionStats.availableAmount > 0) {
            uint256 _reward = calculateReward(_score, _handicap, _predictionStats.availableAmount, 3 - _prediction.chosenTeam);
            _predictionStats.availableAmount = 0;
            if (_reward > 0) {
                transferMoney(_prediction.token, msg.sender, _reward);
            }
        }
    }

    function dealerWithdraw(uint256 _predictionId) external {
        DataTypes.HandicapPrediction memory _prediction = predictions[_predictionId];
        require(msg.sender == _prediction.dealer, 'not-dealer');
        DataTypes.Match memory _match = matchData.info(_prediction.matchId);
        DataTypes.Score memory _score = _match.score;
        DataTypes.Handicap memory _handicap = _prediction.handicap;

        require(_match.status == DataTypes.MatchStatus.FINISH, 'match-not-finish');
        require(_match.endTime <= block.timestamp, 'end_time > timestamp');
        require(withdrawable[msg.sender][_predictionId], 'can_not-withdraw');

        uint256 _totalUserReward = calculateReward(_score, _handicap, _prediction.totalUserDeposit, 3 -  _prediction.chosenTeam);

        if (_prediction.hardCap + _prediction.totalUserDeposit >= _totalUserReward) {
            transferMoney(_prediction.token, msg.sender, _prediction.hardCap + _prediction.totalUserDeposit - _totalUserReward);
            withdrawable[msg.sender][_predictionId] = false;
        }
    }

    function calculateReward(DataTypes.Score memory _score, DataTypes.Handicap memory _handicap, uint256 _amount, uint256 _option)
    public pure returns(uint256)
    {
        if (_option == 1 || _option == 2) {
            //calculate win-side  1 - first | 2 - second
            uint256 _reward = 0;
            uint256 _winSide = 1;
            if (_score.firstTeam < _score.secondTeam) {
                _winSide++;
            }
            uint256 _diffScore = getDiffScore(_score);
            uint256 _integerPath = getIntegerPath(_handicap.value);
            uint256 _fractionalPath = getFractionalPath(_handicap.value);

            if (_fractionalPath == 0) {
                if (_diffScore == _integerPath) {
                    _reward = _amount;
                }
                if (_diffScore > _integerPath && _option == _winSide) {
                    _reward = _amount * 2;
                }
            }
            if (_fractionalPath == 2500) {
                if (_diffScore == _integerPath) {
                    _reward = _amount / 2 + _amount * (1 - isWin(_option, _winSide));
                }
                if (_diffScore > _integerPath && _option == _winSide) {
                    _reward = _amount * 2;
                }
            }
            if (_fractionalPath == 5000) {
                if (_diffScore > _integerPath && _option == _winSide) {
                    _reward = _amount * 2;
                }
            }
            if (_fractionalPath == 7500) {
                if (_diffScore == _integerPath + 1) {
                    _reward = _amount / 2 + _amount * isWin(_option, _winSide);
                }
                if (_diffScore > (_integerPath + 1) && _option == _winSide) {
                    _reward = _amount * 2;
                }
            }
            return _reward;
        }
        return 0;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setMatchData(address _matchData) external onlyOwner {
        matchData = IMatch(_matchData);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function predictInternal(uint256 _predictionId, address _predictor, uint256 _predictValue) internal {
        DataTypes.HandicapPredictionStats storage _predictionStats = predictionStats[_predictor][_predictionId];
        _predictionStats.totalAmount += _predictValue;
        _predictionStats.availableAmount += _predictValue;
        DataTypes.HandicapPrediction storage _prediction = predictions[_predictionId];
        _prediction.totalUserDeposit += _predictValue;
    }

    function transferMoney(address _token, address _toAddress, uint256 _amount) internal {
        if (_token == address(0)) {
            payable(_toAddress).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(_toAddress, _amount);
        }
    }

    function getDiffScore(DataTypes.Score memory _score) internal pure returns(uint256 _res) {
        _res = _score.firstTeam > _score.secondTeam ? _score.firstTeam - _score.secondTeam : _score.secondTeam - _score.firstTeam;
    }

    function getIntegerPath(uint256 _num) internal pure returns(uint256) {
        return _num / ZOOM;
    }

    function getFractionalPath(uint256 _num) internal pure returns(uint256) {
        return _num % ZOOM;
    }

    function isWin(uint256 _option, uint256 _winSide) internal pure returns(uint256) {
        if (_option == _winSide) {
            return 1;
        }
        return 0;
    }

    /* =============== EVENTS ==================== */

    event PredictCreated(address predicttor, uint256 predictionId, uint256 predictValue);
    event PredictionCreated(uint256 idx, address dealer, uint256 matchId, uint256 minPredict, uint256 hardCap, DataTypes.Handicap handicap);
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

    constructor () {
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.4;

library DataTypes {
    enum MatchStatus {NOT_EXISTED, AVAILABLE, FINISH, CANCEL, SUSPEND}
    enum HandicapPredictionStatus {ENABLE, DISABLE}
    struct Score {
        uint256 firstTeam;
        uint256 secondTeam;
    }
    struct Match {
        bytes32 description;
        uint256 startTime;
        uint256 endTime;
        Score score;
        MatchStatus status;
    }

    struct Handicap{
        uint256 side;
        uint256 value;
    }
    struct HandicapPrediction {
        address dealer;
        address token;
        uint256 matchId;
        uint256 minPredict;
        uint256 hardCap;
        Handicap handicap;
        uint256 chosenTeam;
        uint256 totalUserDeposit;
        HandicapPredictionStatus status;
    }

    struct HandicapPredictHistory {
        uint256 predictValue;
        uint256 timeStamp;
    }

    struct HandicapPredictionStats {
        uint256 totalAmount;
        uint256 availableAmount;
    }

    struct GroupPredictStats {
       uint256[3] predictionAmount; // 0 : draw, 1 - first_team, 2 - second_team
    }

    struct GroupPrediction {
        uint256[3] predictionAmount;
        bool claimed;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.4;

import "../libraries/DataTypes.sol";
pragma experimental ABIEncoderV2;

interface IMatch {
    function info(uint256 _matchId) external view returns(DataTypes.Match memory _match);
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

