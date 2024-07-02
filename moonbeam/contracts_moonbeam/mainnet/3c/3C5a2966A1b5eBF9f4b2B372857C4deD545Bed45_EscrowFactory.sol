pragma solidity ^0.7.5;
import "./Escrow.sol";

contract EscrowFactory {
    // all Escrows will have this duration.
    uint256 constant STANDARD_DURATION = 8640000;

    uint256 public counter;
    mapping(address => uint256) public escrowCounters;
    address public lastEscrow;
    address public eip20;
    event Launched(address eip20, address escrow);

    constructor(address _eip20) public {
        eip20 = _eip20;
    }

    function createEscrow(address[] memory trustedHandlers)
        public
        returns (address)
    {
        Escrow escrow = new Escrow(
            eip20,
            msg.sender,
            STANDARD_DURATION,
            trustedHandlers
        );
        counter++;
        escrowCounters[address(escrow)] = counter;
        lastEscrow = address(escrow);
        emit Launched(eip20, lastEscrow);
        return lastEscrow;
    }

    function isChild(address _child) public view returns (bool) {
        return escrowCounters[_child] == counter;
    }

    function hasEscrow(address _address) public view returns (bool) {
        return escrowCounters[_address] != 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.7.5;

interface HMTokenInterface {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance The balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transferBulk(
        address[] calldata _tos,
        uint256[] calldata _values,
        uint256 _txId
    ) external returns (uint256 _bulkCount);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);
}

pragma solidity ^0.7.5;

import "./HMTokenInterface.sol";
import "./SafeMath.sol";

contract Escrow {
    using SafeMath for uint256;
    event IntermediateStorage(string _url, string _hash);
    event Pending(string manifest, string hash);

    enum EscrowStatuses {
        Launched,
        Pending,
        Partial,
        Paid,
        Complete,
        Cancelled
    }
    EscrowStatuses public status;

    address public reputationOracle;
    address public recordingOracle;
    address public launcher;
    address payable public canceler;

    uint256 public reputationOracleStake;
    uint256 public recordingOracleStake;

    address public eip20;

    string public manifestUrl;
    string public manifestHash;

    string public finalResultsUrl;
    string public finalResultsHash;

    uint256 public duration;

    uint256[] public finalAmounts;
    bool public bulkPaid;

    mapping(address => bool) public areTrustedHandlers;

    constructor(
        address _eip20,
        address payable _canceler,
        uint256 _duration,
        address[] memory _handlers
    ) public {
        eip20 = _eip20;
        status = EscrowStatuses.Launched;
        duration = _duration.add(block.timestamp); // solhint-disable-line not-rely-on-time
        launcher = msg.sender;
        canceler = _canceler;
        areTrustedHandlers[_canceler] = true;
        areTrustedHandlers[msg.sender] = true;
        addTrustedHandlers(_handlers);
    }

    function getBalance() public view returns (uint256) {
        return HMTokenInterface(eip20).balanceOf(address(this));
    }

    function addTrustedHandlers(address[] memory _handlers) public {
        require(
            areTrustedHandlers[msg.sender],
            "Address calling cannot add trusted handlers"
        );
        for (uint256 i = 0; i < _handlers.length; i++) {
            areTrustedHandlers[_handlers[i]] = true;
        }
    }

    // The escrower puts the Token in the contract without an agentless
    // and assigsn a reputation oracle to payout the bounty of size of the
    // amount specified
    function setup(
        address _reputationOracle,
        address _recordingOracle,
        uint256 _reputationOracleStake,
        uint256 _recordingOracleStake,
        string memory _url,
        string memory _hash
    ) public trusted notExpired {
        require(
            _reputationOracle != address(0),
            "Invalid or missing token spender"
        );
        require(
            _recordingOracle != address(0),
            "Invalid or missing token spender"
        );

        uint256 totalStake = _reputationOracleStake.add(_recordingOracleStake);
        require(totalStake >= 0 && totalStake <= 100, "Stake out of bounds");
        require(
            status == EscrowStatuses.Launched,
            "Escrow not in Launched status state"
        );

        reputationOracle = _reputationOracle;
        recordingOracle = _recordingOracle;
        areTrustedHandlers[reputationOracle] = true;
        areTrustedHandlers[recordingOracle] = true;

        reputationOracleStake = _reputationOracleStake;
        recordingOracleStake = _recordingOracleStake;

        manifestUrl = _url;
        manifestHash = _hash;
        status = EscrowStatuses.Pending;
        emit Pending(manifestUrl, manifestHash);
    }

    function abort() public trusted notComplete notPaid {
        if (getBalance() != 0) {
            cancel();
        }
        selfdestruct(canceler);
    }

    function cancel()
        public
        trusted
        notBroke
        notComplete
        notPaid
        returns (bool)
    {
        bool success = HMTokenInterface(eip20).transfer(canceler, getBalance());
        status = EscrowStatuses.Cancelled;
        return success;
    }

    function complete() public notExpired {
        require(
            msg.sender == reputationOracle || areTrustedHandlers[msg.sender],
            "Address calling is not trusted"
        );
        require(status == EscrowStatuses.Paid, "Escrow not in Paid state");
        status = EscrowStatuses.Complete;
    }

    function storeResults(string memory _url, string memory _hash)
        public
        trusted
        notExpired
    {
        require(
            status == EscrowStatuses.Pending ||
                status == EscrowStatuses.Partial,
            "Escrow not in Pending or Partial status state"
        );
        emit IntermediateStorage(_url, _hash);
    }

    function bulkPayOut(
        address[] memory _recipients,
        uint256[] memory _amounts,
        string memory _url,
        string memory _hash,
        uint256 _txId
    ) public trusted notBroke notLaunched notPaid notExpired returns (bool) {
        uint256 balance = getBalance();
        bulkPaid = false;
        uint256 aggregatedBulkAmount = 0;
        for (uint256 i; i < _amounts.length; i++) {
            aggregatedBulkAmount += _amounts[i];
        }

        if (balance < aggregatedBulkAmount) {
            return bulkPaid;
        }

        bool writeOnchain = bytes(_hash).length != 0 || bytes(_url).length != 0;
        if (writeOnchain) {
            // Be sure they are both zero if one of them is
            finalResultsUrl = _url;
            finalResultsHash = _hash;
        }

        (
            uint256 reputationOracleFee,
            uint256 recordingOracleFee
        ) = finalizePayouts(_amounts);
        HMTokenInterface token = HMTokenInterface(eip20);
        if (
            token.transferBulk(_recipients, finalAmounts, _txId) ==
            _recipients.length
        ) {
            delete finalAmounts;
            bulkPaid =
                token.transfer(reputationOracle, reputationOracleFee) &&
                token.transfer(recordingOracle, recordingOracleFee);
        }

        balance = getBalance();
        if (bulkPaid) {
            if (status == EscrowStatuses.Pending) {
                status = EscrowStatuses.Partial;
            }
            if (balance == 0 && status == EscrowStatuses.Partial) {
                status = EscrowStatuses.Paid;
            }
        }
        return bulkPaid;
    }

    function finalizePayouts(uint256[] memory _amounts)
        internal
        returns (uint256, uint256)
    {
        uint256 reputationOracleFee = 0;
        uint256 recordingOracleFee = 0;
        for (uint256 j; j < _amounts.length; j++) {
            uint256 singleReputationOracleFee = reputationOracleStake
                .mul(_amounts[j])
                .div(100);
            uint256 singleRecordingOracleFee = recordingOracleStake
                .mul(_amounts[j])
                .div(100);
            uint256 amount = _amounts[j].sub(singleReputationOracleFee).sub(
                singleRecordingOracleFee
            );
            reputationOracleFee = reputationOracleFee.add(
                singleReputationOracleFee
            );
            recordingOracleFee = recordingOracleFee.add(
                singleRecordingOracleFee
            );
            finalAmounts.push(amount);
        }
        return (reputationOracleFee, recordingOracleFee);
    }

    modifier trusted() {
        require(areTrustedHandlers[msg.sender], "Address calling not trusted");
        _;
    }

    modifier notBroke() {
        require(getBalance() != 0, "EIP20 contract out of funds");
        _;
    }

    modifier notComplete() {
        require(
            status != EscrowStatuses.Complete,
            "Escrow in Complete status state"
        );
        _;
    }

    modifier notPaid() {
        require(status != EscrowStatuses.Paid, "Escrow in Paid status state");
        _;
    }

    modifier notLaunched() {
        require(
            status != EscrowStatuses.Launched,
            "Escrow in Launched status state"
        );
        _;
    }

    modifier notExpired() {
        require(duration > block.timestamp, "Contract expired"); // solhint-disable-line not-rely-on-time
        _;
    }
}