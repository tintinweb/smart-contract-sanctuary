// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./RegularCompetitionContract.sol";
import "./interface/ICompetitionFactory.sol";

contract CompetitionFactory is ICompetitionFactory {
    function createCompetitionCOntract(
        address _owner,
        address _creator
    ) public override returns (address) {
        RegularCompetitionContract regularcontract = new RegularCompetitionContract(
                _owner,
                _creator
            );
        return address(regularcontract);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRegularCompetitionContract {
    struct Competition {
        uint256 competitionId;
        string sportType;
        string matchName;
        string player1;
        string player2;
        Player playerWon;
        uint256 winerReward;
    }
    struct Voting {
        uint256 player1;
        uint256 player2;
    }

    enum Privacy {
        Private,
        Public
    }
    enum Status {
        Lock,
        Open,
        End
    }
    enum Player {
        NoPlayer,
        Player1,
        Player2
    }

    event PlaceBet(
        address indexed buyer,
        uint256 numberOfVotesPlayer1,
        uint256 numberOfVotesPlayer2
    );
    event Ready(uint256 timestamp);
    event Close(
        uint256 timestamp,
        Player playerWon,
        uint256 winerReward
    );

    function setBasic(
        bool _isPublic,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _entryFee
    ) external returns (bool);

    function depositEth() external payable;

    function start() external;

    function placeBet(
        uint256 _numberOfVotesPlayer1,
        uint256 _numberOfVotesPlayer2
    ) external payable;
    
    function placeBet(
        address _user,
        uint256 _numberOfVotesPlayer1,
        uint256 _numberOfVotesPlayer2
    ) external payable;

    function close() external;

    function getEntryFee() external view returns (uint256);

    function getTotalBalance() external view returns (uint256);

    function setRewardRate(uint256[] calldata _rewardRate) external;
    
    function setOracle(address _oracle) external;

    function setCompetition(
        uint256 _competitionId,
        string memory _sportType,
        string memory _matchName,
        string memory _player1,
        string memory _player2
    ) external;

    function withdrawReward() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
interface ICompetitionFactory{
    function createCompetitionCOntract(address  _owner, address  _creator)
        external
        returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
interface IChainLinkOracleSportData{
    
    struct Competition {
        string sportType;
        string matchName;
        string player1;
        string player2;
    }
    function getPayment() external returns (uint256);
    
    function requestData(uint256 _competitionId) external returns (bytes32);
    
    function requestInfoCompetition(uint256 _competitionId)
        external
        returns (bytes32);
        
    function getData(bytes32 _id) external view returns (uint256[] memory);
    
     function getInfoCompetition(bytes32 _id)
        external
        view
        returns (Competition memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interface/IChainLinkOracleSportData.sol";
import "./interface/IRegularCompetitionContract.sol";

contract RegularCompetitionContract is IRegularCompetitionContract {
    Competition public competition;
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    uint256 public entryFee;

    uint256[] public rewardRate; //[creator, owner, winner]
    address public oracle;
    mapping(address => Voting) public buyerToAmount;
    Voting public totalVote;
    // uint256 public reward;
    mapping(address => bool) public withdrawn;
    address public  owner;
    address public immutable creator;

    Privacy privacy;
    Status public status = Status.Lock;

    constructor(address _owner, address _creator) {
        owner = _owner;
        creator = _creator;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "RegularCompetitionContract: Only owner");
        _;
    }

    modifier onlyCreator() {
        require(
            creator == msg.sender,
            "RegularCompetitionContract: Only creator"
        );
        _;
    }

    modifier onlyOwnerOrCreator() {
        require(
            owner == msg.sender || creator == msg.sender,
            "RegularCompetitionContract: Only owner or creator"
        );
        _;
    }

    modifier onlyOpen() {
        require(
            status == Status.Open,
            "RegularCompetitionContract: Required Open"
        );
        _;
    }

    modifier onlyLock() {
        require(
            status == Status.Lock,
            "RegularCompetitionContract: Required NOT start"
        );
        _;
    }

    modifier onlyEnd() {
        require(
            status == Status.End,
            "RegularCompetitionContract: Required NOT end"
        );
        _;
    }

    modifier betable() {
        require(
            block.timestamp >= startTimestamp &&
                block.timestamp <= endTimestamp,
            "BETTING: No betable"
        );
        _;
    }
    
    function setOracle(address _oracle) public override onlyOwner {
        oracle= _oracle;
    }

    function getEntryFee() public override view returns (uint256) {
        return entryFee;
    }

    function setRewardRate(uint256[] memory _rewardRate) public override onlyOwner{
        rewardRate = _rewardRate;
    }

    function setBasic(
        bool _isPublic,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _entryFee
    ) public override onlyOwner onlyLock returns (bool) {
        require(
            block.timestamp <= _startTimestamp,
            "RegularCompetitionContract: Time is illegal"
        );
        require(
            _startTimestamp < _endTimestamp,
            "RegularCompetitionContract: endTime < startTime"
        );
        _setPrivacy(_isPublic);
        _setStartTimestamp(_startTimestamp);
        _setEndTimestamp(_endTimestamp);
        _setEntryFee(_entryFee);
        return true;
    }

    function setCompetition(
        uint256 _competitionId,
        string memory _sportType,
        string memory _matchName,
        string memory _player1,
        string memory _player2
    ) public override onlyOwner onlyLock {
        competition = Competition(
            _competitionId,
            _sportType,
            _matchName,
            _player1,
            _player2,
            Player.NoPlayer,
            0
        );
    }

    function depositEth() public override payable onlyOwnerOrCreator onlyLock {}

    function start() public override onlyOwner onlyLock {
        require(
            endTimestamp >= block.timestamp,
            "RegularCompetitionContract: expired"
        );

        status = Status.Open;
        emit Ready(block.timestamp);
    }

    function placeBet(
        uint256 _numberOfVotesPlayer1,
        uint256 _numberOfVotesPlayer2
    ) public payable override onlyOpen betable {
        require(
            msg.value ==
                entryFee * (_numberOfVotesPlayer1 + _numberOfVotesPlayer2),
            "RegularCompetitionContract: Required ETH == entryFee * amountBet"
        );
        _placeBet(msg.sender, _numberOfVotesPlayer1, _numberOfVotesPlayer2);
    }

    function placeBet(
        address user,
        uint256 _numberOfVotesPlayer1,
        uint256 _numberOfVotesPlayer2
    ) external payable override onlyOpen betable onlyOwner {
        require(
            msg.value ==
                entryFee * (_numberOfVotesPlayer1 + _numberOfVotesPlayer2),
            "RegularCompetitionContract: Required ETH == entryFee * amountBet"
        );
        _placeBet(user, _numberOfVotesPlayer1, _numberOfVotesPlayer2);
    }

    function _placeBet(
        address user,
        uint256 _numberOfVotesPlayer1,
        uint256 _numberOfVotesPlayer2
    ) private {
        require(
            user != creator,
            "RegularCompetitionContract: Creator cannot bet"
        );
        buyerToAmount[user].player1 += _numberOfVotesPlayer1;
        buyerToAmount[user].player2 += _numberOfVotesPlayer2;
        totalVote.player1 += _numberOfVotesPlayer1;
        totalVote.player2 += _numberOfVotesPlayer2;
        emit PlaceBet(user, _numberOfVotesPlayer1, _numberOfVotesPlayer2);
    }

    function close() public override onlyOpen {
        require(
            block.timestamp > endTimestamp,
            "RegularCompetitionContract: Please waiting for end time"
        );
        (bool player1, bool player2, bool success) = _getResult(competition.competitionId);

        status = Status.End;

        uint256 creatorReward = 0;
        uint256 ownerReward = 0;
        uint256 winnerReward = 0;
        uint256 totalReward = getTotalBalance();
        if (!success) {
            winnerReward = totalReward / (totalVote.player1 + totalVote.player2);
        } else {
            uint256 winnerCount;
            if (player1 && !player2) {
                competition.playerWon=Player.Player1;
                winnerCount = totalVote.player1;
            } else if (!player1 && player2) {
                competition.playerWon=Player.Player2;
                winnerCount = totalVote.player2;
            }
            ownerReward = totalReward * rewardRate[1] / 100;
            if (winnerCount > 0) {
                creatorReward = totalReward * rewardRate[0] / 100;
                winnerReward = (totalReward - ownerReward - creatorReward) / winnerCount;
            } else {
                creatorReward = totalReward - ownerReward;
            }
        }
        if (creatorReward > 0) {
            Address.sendValue(payable(creator), creatorReward);
        }

        if (ownerReward > 0) {
            Address.sendValue(payable(owner), ownerReward);
        }
        competition.winerReward = winnerReward;

        emit Close(block.timestamp, competition.playerWon, competition.winerReward);
    }

    function destroyContract() public onlyEnd onlyOwner {
        require (getTotalBalance() == 0, "RegularCompetitionContract: There is still reward");
        selfdestruct(payable(owner));
    }

    function claimable(address user) public view returns(bool canClaim, uint256 amount) {
        Voting memory voted = buyerToAmount[user];
        if (status != Status.End) {
            return (false, 0);
        }
        if (withdrawn[msg.sender]) {
            return (false, 0);
        }
        if (competition.winerReward == 0) {
            return (false, 0);
        }
        if (competition.playerWon == Player.Player1 && voted.player1 > 0) {
            return (true, voted.player1 * competition.winerReward);
        }
        if (competition.playerWon == Player.Player2 && voted.player2 > 0) {
            return (true, voted.player2 * competition.winerReward);
        }
        if (competition.playerWon == Player.NoPlayer) {
            return (true, (voted.player1 + voted.player2) * competition.winerReward);
        }
        return (false, 0);
    }

    function withdrawReward() external override onlyEnd {
        (bool canClaim, uint256 amount) = claimable(msg.sender);
        require(canClaim, "RegularCompetitionContract: Not claimable");
        withdrawn[msg.sender] = true;
        Address.sendValue(
            payable(msg.sender),
            amount
        );
    }

    function getTotalBalance() public override view returns (uint256) {
        return address(this).balance;
    }

    function _getResult(uint256 _competitionId)
        public
        returns (
            bool _player1Win,
            bool _player2Win,
            bool _success
        )
    {
        bytes32 requestID = IChainLinkOracleSportData(oracle).requestData(_competitionId);
        uint256[] memory result = IChainLinkOracleSportData(oracle).getData(requestID);
        if (result[0] > result[1]) {
            return (true, false, true);
        }else
        if (result[0] < result[1]) {
            return (false, true, true);
        }else
        if (result[0] == result[1]) {
            return (false, false, true);
        }else
        return (false, false, false);
    }

    function _setPrivacy(bool _isPublic) private {
        if (_isPublic) {
            privacy = Privacy.Public;
        } else {
            privacy = Privacy.Private;
        }
    }

    function _setStartTimestamp(uint256 _startTimestamp) private {
        startTimestamp = _startTimestamp;
    }

    function _setEndTimestamp(uint256 _endTimestamp) private {
        endTimestamp = _endTimestamp;
    }

    function _setEntryFee(uint256 _entryFee) private {
        entryFee = _entryFee;
    }

    function _sendValue(address payable recipient, uint256 amount) private {
        require(
            address(this).balance >= amount,
            "RegularCompetitionContract: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "RegularCompetitionContract: unable to send value, recipient may have reverted"
        );
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