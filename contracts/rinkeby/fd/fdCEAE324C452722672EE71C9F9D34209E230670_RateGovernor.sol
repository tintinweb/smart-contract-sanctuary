pragma solidity ^0.8.0;
// SPDX-License-Identifier: UNLICENSED

import "../tokens/xASKO.sol";
import "../proposals/Proposals.sol";
import "../utils/interfaces/IDAOAccess.sol";
import "./interfaces/IRateGovernor.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RateGovernor is IRateGovernor {
    // import libraries for usage
    using SafeMath for uint256;
    using Proposals for Proposals.RateReceipt;

    /// @notice xASKO token
    xAsko public _xAsko;

    /// @notice DAOAccess
    IDAOAccess public daoAccess;

    // voting can happen immediatly
    uint256 votingBlock = block.number;

    // number of blocks until the next voting opening
    uint256 blockInterval;

    /// @notice keeps track of rate vote
    struct GlobalRate {
        uint256 weightedSum; // this is right shifted by 2 decimal places.
        uint256 delegatedSupply;
        uint256 blockNumber;
        bool isLocked;
    }

    /** @notice Stores the global rates.
     *      0 - DAO Tax Rate
     *      1 - Development Tax Rate
     *      2 - Yes Rate
     *      3 - Approval Rate
     *      4 - Product Proposal Continuation Rate
     */
    GlobalRate[5] public globalRates;

    /// @notice reciept map for all
    mapping(address => Proposals.RateReceipt)[5] public rateReceipts;

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint8 rateId, uint256 rate, uint256 votes);
    event VoteLock(uint8 rateId, uint256 rate);

    /**
     * @notice Initialize the RateGovernor. See also DAOAccess.
     * @param _daoAccess Address of DAOAccess.
     * @param xAskoAddress Address of the xASKO Token.
     * @param startingBlock Block to start at
     * @param _blockInterval number of blocks before the rates are reset.
     * @param defaultRates The default rates that the guardian will automatically vote for
     *      with their xASKO. See rates variable for more information.
     */
    constructor(
        address _daoAccess,
        address xAskoAddress,
        uint256 startingBlock,
        uint256 _blockInterval,
        uint256[5] memory defaultRates
    ) {

        // setup block intervals
        daoAccess = IDAOAccess(_daoAccess);
        _xAsko = xAsko(xAskoAddress);
        blockInterval = _blockInterval;
        votingBlock = startingBlock;

        // cast default votes
        for (uint8 i = 0; i < 5; i++) {
            if (i == 3) {
                _voteRate(msg.sender, i, defaultRates[i] * 100);
            } else {
                _voteRate(msg.sender, i, defaultRates[i]);
            }
        }
    }

    /**
     * Restricts access to only the guardian
     */
    modifier onlyGuardian(){
        require(daoAccess.isGuardian(msg.sender), "Must have guardian permissions");
        _;
    }

    /**
     * Returns the current rate. see rates variable for more information.
     * @param rateId RateID of the returned rate.
     * @return The rate * 100.
     */
    function getRate(uint8 rateId) public view override returns (uint256) {
        return _computeRate(rateId);
    }

    /**
     * Cast a vote to a rate, see rates variable for more information.
     * @param rateId Vote for the selected rate.
     * @param rate The value of what the percentage should be * 100 if rateId != 3,
     *             otherwise value between 1-10.
     */
    function voteRate(uint8 rateId, uint256 rate) public {
        if (rateId == 3) {
            _voteRate(msg.sender, rateId, rate * 100);
        } else {
            _voteRate(msg.sender, rateId, rate);
        }
        emit VoteLock(rateId, rate);
    }

    /**
     * Locks rates for the period to the given rate, see rates variable for more information.
     * @param rateId Selected rate to lock.
     * @param rate The value of what the percentage should be * 100 if rateId != 3,
     *             otherwise value between 1-10.
     */
    function lockRate(uint8 rateId, uint256 rate) public onlyGuardian {
        if (rateId == 3) {
            _lockRate(rateId, rate * 100);
        } else {
            _lockRate(rateId, rate);
        }
    }

    function _updateBlock() internal {
        while (votingBlock + blockInterval < block.number) {
            votingBlock += blockInterval;
        }
    }

    function _lockRate(uint8 rateId, uint256 rate) internal {
        require(4 >= rateId, "Invalid rateId");
        require(rateId == 3 || rate <= 100, "Invalid rate");
        require(rateId != 3 || (rate <= 1000 && rate >= 100), "Invalid rate");
        _updateBlock();
        globalRates[rateId].weightedSum = rate;
        globalRates[rateId].delegatedSupply = 1;
        globalRates[rateId].isLocked = true;
        globalRates[rateId].blockNumber = votingBlock;
    }

    function _voteRate(
        address voter,
        uint8 rateId,
        uint256 rate
    ) internal {
        // check if valid
        require(4 >= rateId, "Invalid rateId");
        require(rateId == 3 || rate <= 100, "Invalid rate");
        require(rateId != 3 || (rate <= 1000 && rate >= 100), "Invalid rate");
        Proposals.RateReceipt storage receipt = rateReceipts[rateId][voter];
        _updateBlock();

        // check if the user has voted for already for this rate
        require(
            receipt.hasVoted == false || receipt.blockPeriod != votingBlock,
            "User has already voted"
        );

        // set rate values if they are not locked
        uint96 votes = _xAsko.getPriorVotes(voter, votingBlock);
        if (globalRates[rateId].blockNumber != votingBlock) {
            globalRates[rateId].weightedSum = rate * votes;
            globalRates[rateId].delegatedSupply = votes;
            globalRates[rateId].isLocked = false;
        } else {
            require(
                globalRates[rateId].isLocked == false,
                "Rate is locked, please try again at a later time"
            );
            globalRates[rateId].weightedSum += rate * votes;
            globalRates[rateId].delegatedSupply += votes;
        }
        globalRates[rateId].blockNumber = votingBlock;

        // set receipt values
        receipt.hasVoted = true;
        receipt.votes = votes;
        receipt.blockPeriod = votingBlock;

        emit VoteCast(voter, rateId, rate, votes);
    }

    function _computeRate(uint8 rateId) internal view returns (uint256) {
        require(4 >= rateId, "Invalid rateId");
        if (globalRates[rateId].delegatedSupply == 0) {
            return 0; // TODO: should this be the case for rateId == 1?
        }
        return globalRates[rateId].weightedSum / globalRates[rateId].delegatedSupply;
    }
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: Unlicense

import "./MaticComp.sol";

contract xAsko is MaticComp {
    constructor(address childChainManager)
        MaticComp("xASKO Token", "xASKO", 18, childChainManager)
    {}
}

pragma solidity ^0.8.0;

//SPDX-License-Identifier: Unlicensed

library Proposals {
    /// @notice For determining type of entity
    enum EntityType {
        DEVELOPMENT,
        PRODUCT,
        RATE,
        NULL
    }

    /** @notice For proposal states
     * PROPOSED: For proposals not approved by an admin (product only)
     *     OPEN: For product proposals that have been approved by an admin
     *           For development proposals that have been opened up
     * ACCEPTED: For proposals that meet the yes rate (product only)
     * APPROVED: For proposals that have been approved for the current interval (product only)
     * EXECUTED: For proposals that recieved their budget in whole
     *  REMOVED: For proposals that have expired or have been vetoed out
     */
    enum ProposalState {
        PROPOSED,
        OPEN,      
        ACCEPTED,  
        APPROVED,  
        EXECUTED,  
        REMOVED    
    }

    /// @notice Rate types
    enum RateType {
        DAO_TAX_RATE,
        DEVELOPMENT_TAX_RATE,
        YES_RATE,
        APPROVAL_RATE,
        CONTINUATION_RATE
    }

    /// @notice For rates
    struct Rate {
        // rate for action to take place (needs RateGovernor) * 100
        uint256 threshold;
        // current votes for
        uint256 forVotes;
        // current votes against
        uint256 againstVotes;
        // start time
        uint256 startTime;
        // starting block
        uint256 startBlock;
    }

    /// @notice for storing proposal rates
    struct ProductProposalRates {
        // DAO Tax Rate
        uint256 daoTaxRate;
        // Development Tax Rate
        uint256 devTaxRate;
        // yes rate at the time it was proposed
        Rate yes;
        // Number of vetoes for the proposal (Product only)
        Rate adminVetos;
        // Approval rate at the time it was proposed (Product only)
        Rate approval;
        // Product proposal continuation rate at the time it was proposed (Product only)
        Rate productCont;
    }

    /// @notice for storing dev days information
    struct DevDays {
        // Interval for recieving budget (product only)
        uint256 interval;
        // The current interval (product only)
        uint256 currentInterval;
        // Number of dev days (product only)
        uint256 devDays;
    }

    struct DevelopmentProposal {
        // Unique id for looking up a development proposal
        uint256 id;
        // Budget
        uint256 budget;
        // address for where the budget should go
        address receiver;
        // address for who proposed
        address proposer;
        // Description
        string description;
        // DAO Tax Rate
        uint256 daoTaxRate;
        // Development Tax Rate
        uint256 devTaxRate;
        // DDF Approval rate
        Rate approval;
        // proposal state
        ProposalState proposalState;
    }

    struct ProductProposal {
        // name of the proposal (product only)
        string name;
        // Unique id for looking up a product proposal
        uint256 id;
        // Budget
        uint256 budget;
        // Telegram Handle
        string TGHandle;
        // url to project/product
        string URL;
        // address for where the budget should go
        address receiver;
        // address for who proposed
        address proposer;
        // Developer
        string developer;
        // Description
        string description;
        // Stores devDays information (product only)
        DevDays devDays;
        // Rates
        ProductProposalRates proposalRates;
        // proposal state
        ProposalState proposalState;
    }

    /// @notice Ballot receipt record for a rate
    struct RateReceipt {
        // Whether or not a vote has been cast
        bool hasVoted;
        // The number of votes the voter had, which were cast
        uint96 votes;
        // Which proposal/rate they voted for
        uint256 entityId;
        // At which block number (corresponds to voting period)
        uint256 blockPeriod;
    }

    /// @notice Ballot receipt record for a proposal
    struct ProposalReceipt {
        // Whether or not a vote has been cast
        bool hasVoted;
        // The number of votes the voter had, which were cast
        uint96 votes;
        // Which proposal/rate they voted for
        uint256 entityId;
        // At which block period
        uint256 blockPeriod;
        // At which state was the vote cast?
        ProposalState proposalState;
    }

}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: UNLICENSED

interface IDAOAccess {

    function isGuardian(address sender) external view returns (bool);

    function isDDF(address sender, uint256 blockNumber) external view returns (bool);

    function isAdmin(address sender) external view returns (bool);

}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED

interface IRateGovernor {
    function getRate(uint8 rateId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: BSD-3-Clause License

/**
 * Copyright 2020 Compound Labs, Inc.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import "@openzeppelin/contracts/access/AccessControl.sol";

contract MaticComp is AccessControl {
    /// @notice EIP-20 token name for this token
    string public name;

    /// @notice EIP-20 token symbol for this token
    string public symbol;

    /// @notice EIP-20 token decimals for this token
    uint8 public decimals;

    /// @notice Total number of tokens in circulation
    mapping(uint32 => Checkpoint) public supplyCheckpoints;

    /// @notice The number of checkpoints for the supply
    uint32 public numSupplyCheckpoints = 0;

    // Allowance amounts on behalf of others
    mapping(address => mapping(address => uint96)) internal allowances;

    // Official record of token balances for each account
    mapping(address => uint96) internal balances;

    /// @notice A record of each accounts delegate
    mapping(address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice Address of childChainManager
    address public childChainManager;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    modifier depositorOnly() {
        require(
            msg.sender == childChainManager,
            "Needs to be a depositor in order to preform this action"
        );
        _;
    }

    /**
     * @notice Construct a new Comp token
     * @param _name Name of the MaticComp token.
     * @param _symbol Symbol of the MaticComp token.
     * @param _decimals Number of decimals.
     * @param _childChainManager Address of child chain manager.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _childChainManager
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        childChainManager = _childChainManager;
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender)
        external
        view
        returns (uint256)
    {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 rawAmount)
        external
        returns (bool)
    {
        uint96 amount;
        if (rawAmount == type(uint256).max) {
            amount = type(uint96).max;
        } else {
            amount = safe96(rawAmount, "Comp::approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 rawAmount) external returns (bool) {
        uint96 amount = safe96(
            rawAmount,
            "Comp::transfer: amount exceeds 96 bits"
        );
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 rawAmount
    ) external returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(
            rawAmount,
            "Comp::approve: amount exceeds 96 bits"
        );

        if (spender != src && spenderAllowance != type(uint96).max) {
            uint96 newAllowance = sub96(
                spenderAllowance,
                amount,
                "Comp::transferFrom: transfer amount exceeds spender allowance"
            );
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "Comp::delegateBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "Comp::delegateBySig: invalid nonce"
        );
        require(
            block.timestamp <= expiry,
            "Comp::delegateBySig: signature expired"
        );
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return
            nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber)
        public
        view
        returns (uint96)
    {
        return
            _getPriorVotes(
                checkpoints[account],
                numCheckpoints[account],
                blockNumber
            );
    }

    /**
     * @notice Determine the total number of votes from all users prior to the block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorSupply(uint256 blockNumber) public view returns (uint96) {
        return
            _getPriorVotes(
                supplyCheckpoints,
                numSupplyCheckpoints,
                blockNumber
            );
    }

    /**
     * @notice Gets total amount of checkpoints
     * @return The number of current votes for `account`
     */
    function getCurrentSupply() external view returns (uint96) {
        return
            numSupplyCheckpoints > 0
                ? supplyCheckpoints[numSupplyCheckpoints - 1].votes
                : 0;
    }

    /**
     * @notice Mints amount tokens to the user from mainnet.
     * @param user Reciever of tokens.
     * @param depositData Amount of tokens the user should recieve stored in depositData.
     */
    function deposit(address user, bytes calldata depositData)
        external
        depositorOnly
    {
        uint96 amount = abi.decode(depositData, (uint96));
        _mint(user, amount);
    }

    /**
     * @notice Withdraws token back to root.
     * @param amount Amount of tokens to withdraw (burn).
     */
    function withdraw(uint96 amount) external {
        _burn(msg.sender, amount);
    }

    function _delegate(address delegator, address delegatee) internal {
        require(
            !_existCheckpoint(checkpoints[delegator], numCheckpoints[delegator]),
            "CompMatic:: src already has checkpoint at that block, try again later."
        );
        require(
            !_existCheckpoint(checkpoints[delegatee], numCheckpoints[delegatee]),
            "CompMatic:: dst already has checkpoint at that block, try again later."
        );
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(
        address src,
        address dst,
        uint96 amount
    ) internal {
        require(
            !_existCheckpoint(checkpoints[src], numCheckpoints[src]),
            "CompMatic:: src already has checkpoint at that block, try again later."
        );
        require(
            !_existCheckpoint(checkpoints[dst], numCheckpoints[dst]),
            "CompMatic:: dst already has checkpoint at that block, try again later."
        );
        require(
            src != address(0),
            "Comp::_transferTokens: cannot transfer from the zero address"
        );
        if (dst == address(0)) {
            _moveSupply(amount, false);
        }

        balances[src] = sub96(
            balances[src],
            amount,
            "Comp::_transferTokens: transfer amount exceeds balance"
        );
        balances[dst] = add96(
            balances[dst],
            amount,
            "Comp::_transferTokens: transfer amount overflows"
        );
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint96 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0
                    ? checkpoints[srcRep][srcRepNum - 1].votes
                    : 0;
                uint96 srcRepNew = sub96(
                    srcRepOld,
                    amount,
                    "Comp::_moveVotes: vote amount underflows"
                );
                _writeUserCheckpoint(srcRep, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0
                    ? checkpoints[dstRep][dstRepNum - 1].votes
                    : 0;
                uint96 dstRepNew = add96(
                    dstRepOld,
                    amount,
                    "Comp::_moveVotes: vote amount overflows"
                );
                _writeUserCheckpoint(dstRep, dstRepOld, dstRepNew);
            }
        }
    }

    function _moveSupply(uint96 amount, bool isMintAmount) internal {
        uint96 oldSupply = numSupplyCheckpoints > 0
            ? supplyCheckpoints[numSupplyCheckpoints - 1].votes
            : 0;
        uint96 newSupply;
        if (isMintAmount) {
            newSupply = add96(
                oldSupply,
                amount,
                "Comp::_moveVotes: vote amount overflows"
            );
        } else {
            newSupply = sub96(
                oldSupply,
                amount,
                "Comp::_moveVotes: vote amount underflows"
            );
        }
        _writeSupplyCheckpoint(newSupply);
    }

    function _writeSupplyCheckpoint(uint96 newVotes) internal {
        _writeCheckpoint(supplyCheckpoints, numSupplyCheckpoints, newVotes);
        numSupplyCheckpoints++;
    }

    function _writeUserCheckpoint(
        address delegatee,
        uint96 oldVotes,
        uint96 newVotes
    ) internal {
        _writeCheckpoint(
            checkpoints[delegatee],
            numCheckpoints[delegatee],
            newVotes
        );
        numCheckpoints[delegatee]++;
        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function _existCheckpoint(
        mapping(uint32 => Checkpoint) storage _checkpoints,
        uint32 nCheckpoints
    ) internal view returns (bool) {
        if(nCheckpoints < 1)
        {
            return false;
        }
        return _checkpoints[nCheckpoints - 1].fromBlock == block.number;
    }

    function _writeCheckpoint(
        mapping(uint32 => Checkpoint) storage _checkpoints,
        uint32 nCheckpoints,
        uint96 newVotes
    ) internal {
        // TODO: Add require statement here!
        uint32 blockNumber = safe32(
            block.number,
            "CompMatic::_writeCheckpoint: block number exceeds 32 bits"
        );

        if (
            nCheckpoints > 0 &&
            _checkpoints[nCheckpoints - 1].fromBlock == blockNumber
        ) {
            _checkpoints[nCheckpoints - 1].votes = newVotes;
        } else {
            _checkpoints[nCheckpoints] = Checkpoint(blockNumber, newVotes);
        }
    }

    function _mint(address account, uint96 amount) internal virtual {
        require(account != address(0), "Cannot mint to the zero address");
        balances[account] = amount;
        _moveSupply(amount, true);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint96 amount) internal virtual {
        require(account != address(0), "Cannot burn from the zero address");
        require(amount <= balances[account], "Burn amount exceeds balance");
        _transferTokens(account, address(0), amount);
        emit Transfer(account, address(0), amount);
    }

    function safe32(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint96)
    {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function _getPriorVotes(
        mapping(uint32 => Checkpoint) storage checkpointMap,
        uint32 _numCheckpoints,
        uint256 blockNumber
    ) internal view returns (uint96) {
        require(
            blockNumber < block.number,
            "CompMatic::_getPriorVotes: not yet determined"
        );

        if (_numCheckpoints == 0) {
            return 0;
        }

        // check the most recent balance
        if (checkpointMap[_numCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpointMap[_numCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpointMap[0].fromBlock > blockNumber) {
            return 0;
        }

        // binary search to get the desired checkpoint
        uint32 lower = 0;
        uint32 upper = _numCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpointMap[center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpointMap[lower].votes;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

