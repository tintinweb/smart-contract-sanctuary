// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CVNX.sol";
import "./ICVNXGovernance.sol";

/// @notice Governance contract for CVNX token.
contract CVNXGovernance is ICVNXGovernance, Ownable {
    CVNX private cvnx;

    /// @notice Emit when new poll created.
    event PollCreated(uint256 indexed pollNum);

    /// @notice Emit when address vote in poll.
    event PollVoted(address voterAddress, VoteType indexed voteType, uint256 indexed voteWeight);

    /// @notice Emit when poll stopped.
    event PollStop(uint256 indexed pollNum, uint256 indexed stopTimestamp);

    /// @notice Contain all polls. Index - poll number.
    Poll[] public polls;

    /// @notice Contain Vote for addresses that vote in poll.
    mapping(uint256 => mapping(address => Vote)) public voted;

    /// @notice Shows whether tokens are locked for a certain pool at a certain address.
    mapping(uint256 => mapping(address => bool)) public isTokenLockedInPoll;

    /// @notice List of verified addresses for PRIVATE poll.
    mapping(uint256 => mapping(address => bool)) public verifiedToVote;

    /// @notice Possibility to create new poll in contract.
    bool private isAvailableToCreate = true;

    /// @param _cvnxTokenAddress CVNX token address.
    constructor(address _cvnxTokenAddress) {
        cvnx = CVNX(_cvnxTokenAddress);
    }

    /// @notice Return variable isAvailableToCreate.
    function getIsAvailableToCreate() external view override returns (bool) {
        return isAvailableToCreate;
    }

    /// @notice Enable or disable possibility to create new poll in contract.
    function setIsAvailableToCreate() external override onlyOwner() {
        isAvailableToCreate = !isAvailableToCreate;
    }

    /// @notice Modifier check minimal CVNX token balance before method call.
    /// @param _minimalBalance Minimal balance on address (Wei)
    modifier onlyWithBalanceNoLess(uint256 _minimalBalance) {
        require(cvnx.balanceOf(msg.sender) > _minimalBalance, "[E-34] - Your balance is too low.");
        _;
    }

    /// @notice Create PROPOSAL poll.
    /// @param _pollDeadline Poll deadline
    /// @param _pollInfo Info about poll
    function createProposalPoll(uint64 _pollDeadline, string memory _pollInfo) external override {
        _createPoll(PollType.PROPOSAL, _pollDeadline, _pollInfo);
    }

    /// @notice Create EXECUTIVE poll.
    /// @param _pollDeadline Poll deadline
    /// @param _pollInfo Info about poll
    function createExecutivePoll(uint64 _pollDeadline, string memory _pollInfo) external override onlyOwner {
        _createPoll(PollType.EXECUTIVE, _pollDeadline, _pollInfo);
    }

    /// @notice Create EVENT poll.
    /// @param _pollDeadline Poll deadline
    /// @param _pollInfo Info about poll
    function createEventPoll(uint64 _pollDeadline, string memory _pollInfo) external override onlyOwner {
        _createPoll(PollType.EVENT, _pollDeadline, _pollInfo);
    }

    /// @notice Create PRIVATE poll.
    /// @param _pollDeadline Poll deadline
    /// @param _pollInfo Info about poll
    /// @param _verifiedAddresses Array of verified addresses for poll
    function createPrivatePoll(
        uint64 _pollDeadline,
        string memory _pollInfo,
        address[] memory _verifiedAddresses
    ) external override onlyOwner {
        uint256 _verifiedAddressesCount = _verifiedAddresses.length;
        require(_verifiedAddressesCount > 1, "[E-35] - Verified addresses not set.");

        uint256 _pollNum = _createPoll(PollType.PRIVATE, _pollDeadline, _pollInfo);

        for (uint256 i = 0; i < _verifiedAddressesCount; i++) {
            verifiedToVote[_pollNum][_verifiedAddresses[i]] = true;
        }
    }

    /// @notice Send tokens as vote in poll. Tokens will be lock.
    /// @param _pollNum Poll number
    /// @param _voteType Vote type (FOR, AGAINST)
    /// @param _voteWeight Vote weight in CVNX tokens
    function vote(
        uint256 _pollNum,
        VoteType _voteType,
        uint256 _voteWeight
    ) external override onlyWithBalanceNoLess(10000000000000000000) {
        require(polls[_pollNum].pollStopped > block.timestamp, "[E-37] - Poll ended.");

        if (polls[_pollNum].pollType == PollType.PRIVATE) {
            require(verifiedToVote[_pollNum][msg.sender] == true, "[E-38] - You are not verify to vote in this poll.");
        }

        // Lock tokens
        cvnx.lock(msg.sender, _voteWeight);
        isTokenLockedInPoll[_pollNum][msg.sender] = true;

        uint256 _voterVoteWeightBefore = voted[_pollNum][msg.sender].voteWeight;

        // Set vote type
        if (_voterVoteWeightBefore > 0) {
            require(
                voted[_pollNum][msg.sender].voteType == _voteType,
                "[E-39] - The voice type does not match the first one."
            );
        } else {
            voted[_pollNum][msg.sender].voteType = _voteType;
        }

        // Increase vote weight for voter
        voted[_pollNum][msg.sender].voteWeight = _voterVoteWeightBefore + _voteWeight;

        // Increase vote weight in poll
        if (_voteType == VoteType.FOR) {
            polls[_pollNum].forWeight += _voteWeight;
        } else {
            polls[_pollNum].againstWeight += _voteWeight;
        }

        emit PollVoted(msg.sender, _voteType, _voteWeight);
    }

    /// @notice Unlock tokens for poll. Poll should be ended.
    /// @param _pollNum Poll number
    function unlockTokensInPoll(uint256 _pollNum) external override {
        require(polls[_pollNum].pollStopped <= block.timestamp, "[E-81] - Poll is not ended.");
        require(isTokenLockedInPoll[_pollNum][msg.sender] == true, "[E-82] - Tokens not locked for this poll.");

        isTokenLockedInPoll[_pollNum][msg.sender] = false;

        // Unlock tokens
        cvnx.unlock(msg.sender, voted[_pollNum][msg.sender].voteWeight);
    }

    /// @notice Stop poll before deadline.
    /// @param _pollNum Poll number
    function stopPoll(uint256 _pollNum) external override {
        require(
            owner() == msg.sender || polls[_pollNum].pollOwner == msg.sender,
            "[E-91] - Not a contract or poll owner."
        );
        require(block.timestamp < polls[_pollNum].pollDeadline, "[E-92] - Poll ended.");

        polls[_pollNum].pollStopped = uint64(block.timestamp);

        emit PollStop(_pollNum, block.timestamp);
    }

    /// @notice Return poll status (PENDING, APPROVED, REJECTED, DRAW).
    /// @param _pollNum Poll number
    /// @return Poll number and status
    function getPollStatus(uint256 _pollNum) external view override returns (uint256, PollStatus) {
        if (polls[_pollNum].pollStopped > block.timestamp) {
            return (_pollNum, PollStatus.PENDING);
        }

        uint256 _forWeight = polls[_pollNum].forWeight;
        uint256 _againstWeight = polls[_pollNum].againstWeight;

        if (_forWeight > _againstWeight) {
            return (_pollNum, PollStatus.APPROVED);
        } else if (_forWeight < _againstWeight) {
            return (_pollNum, PollStatus.REJECTED);
        } else {
            return (_pollNum, PollStatus.DRAW);
        }
    }

    /// @notice Return the poll expiration timestamp.
    /// @param _pollNum Poll number
    /// @return Poll deadline
    function getPollExpirationTime(uint256 _pollNum) external view override returns (uint64) {
        return polls[_pollNum].pollDeadline;
    }

    /// @notice Return the poll stop timestamp.
    /// @param _pollNum Poll number
    /// @return Poll stop time
    function getPollStopTime(uint256 _pollNum) external view override returns (uint64) {
        return polls[_pollNum].pollStopped;
    }

    /// @notice Return the complete list of polls an address has voted in.
    /// @param _voter Voter address
    /// @return Index - poll number. True - if address voted in poll
    function getPollHistory(address _voter) external view override returns (bool[] memory) {
        uint256 _pollsCount = polls.length;
        bool[] memory _pollNums = new bool[](_pollsCount);

        for (uint256 i = 0; i < _pollsCount; i++) {
            if (voted[i][_voter].voteWeight > 0) {
                _pollNums[i] = true;
            }
        }

        return _pollNums;
    }

    /// @notice Return the vote info for a given poll for an address.
    /// @param _pollNum Poll number
    /// @param _voter Voter address
    /// @return Info about voter vote
    function getPollInfoForVoter(uint256 _pollNum, address _voter) external view override returns (Vote memory) {
        return voted[_pollNum][_voter];
    }

    /// @notice Checks if a user address has voted for a specific poll.
    /// @param _pollNum Poll number
    /// @param _voter Voter address
    /// @return True if address voted in poll
    function getIfUserHasVoted(uint256 _pollNum, address _voter) external view override returns (bool) {
        return voted[_pollNum][_voter].voteWeight > 0;
    }

    /// @notice Return the amount of tokens that are locked for a given voter address.
    /// @param _voter Voter address
    /// @return Poll number
    function getLockedAmount(address _voter) external view override returns (uint256) {
        return cvnx.lockedAmount(_voter);
    }

    /// @notice Return the amount of locked tokens of the specific poll.
    /// @param _pollNum Poll number
    /// @param _voter Voter address
    /// @return Locked tokens amount for specific poll
    function getPollLockedAmount(uint256 _pollNum, address _voter) external view override returns (uint256) {
        if (isTokenLockedInPoll[_pollNum][_voter]) {
            return voted[_pollNum][_voter].voteWeight;
        } else {
            return 0;
        }
    }

    /// @notice Create poll process.
    /// @param _pollType Poll type
    /// @param _pollDeadline Poll deadline adn stop timestamp
    /// @param _pollInfo Poll info
    /// @return Poll number
    function _createPoll(
        PollType _pollType,
        uint64 _pollDeadline,
        string memory _pollInfo
    ) private onlyWithBalanceNoLess(0) returns (uint256) {
        require(_pollDeadline > block.timestamp, "[E-41] - The deadline must be longer than the current time.");
        require(isAvailableToCreate, "[E-42] - Possibility to create new poll is disabled.");

        Poll memory _poll = Poll(_pollDeadline, _pollDeadline, _pollType, msg.sender, _pollInfo, 0, 0);

        uint256 _pollNum = polls.length;
        polls.push(_poll);

        emit PollCreated(_pollNum);

        return _pollNum;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

/// @notice ICVNXGovernance interface for CVNXGovernance contract.
interface ICVNXGovernance {
    enum PollType {PROPOSAL, EXECUTIVE, EVENT, PRIVATE}
    enum PollStatus {PENDING, APPROVED, REJECTED, DRAW}
    enum VoteType {FOR, AGAINST}

    /// @notice Poll structure.
    struct Poll {
        uint64 pollDeadline;
        uint64 pollStopped;
        PollType pollType;
        address pollOwner;
        string pollInfo;
        uint256 forWeight;
        uint256 againstWeight;
    }

    /// @notice Address vote structure.
    struct Vote {
        VoteType voteType;
        uint256 voteWeight;
    }

    /// @notice Return variable isAvailableToCreate.
    function getIsAvailableToCreate() external view returns (bool);

    /// @notice Enable or disable possibility to create new poll in contract.
    function setIsAvailableToCreate() external;

    /// @notice Create PROPOSAL poll.
    /// @param _pollDeadline Poll deadline
    /// @param _pollInfo Info about poll
    function createProposalPoll(uint64 _pollDeadline, string memory _pollInfo) external;

    /// @notice Create EXECUTIVE poll.
    /// @param _pollDeadline Poll deadline
    /// @param _pollInfo Info about poll
    function createExecutivePoll(uint64 _pollDeadline, string memory _pollInfo) external;

    /// @notice Create EVENT poll.
    /// @param _pollDeadline Poll deadline
    /// @param _pollInfo Info about poll
    function createEventPoll(uint64 _pollDeadline, string memory _pollInfo) external;

    /// @notice Create PRIVATE poll.
    /// @param _pollDeadline Poll deadline
    /// @param _pollInfo Info about poll
    /// @param _verifiedAddresses Array of verified addresses for poll
    function createPrivatePoll(
        uint64 _pollDeadline,
        string memory _pollInfo,
        address[] memory _verifiedAddresses
    ) external;

    /// @notice Send tokens as vote in poll. Tokens will be lock.
    /// @param _pollNum Poll number
    /// @param _voteType Vote type (FOR, AGAINST)
    /// @param _voteWeight Vote weight in CVNX tokens
    function vote(
        uint256 _pollNum,
        VoteType _voteType,
        uint256 _voteWeight
    ) external;

    /// @notice Unlock tokens for poll. Poll should be ended.
    /// @param _pollNum Poll number
    function unlockTokensInPoll(uint256 _pollNum) external;

    /// @notice Stop poll before deadline.
    /// @param _pollNum Poll number
    function stopPoll(uint256 _pollNum) external;

    /// @notice Return poll status (PENDING, APPROVED, REJECTED, DRAW).
    /// @param _pollNum Poll number
    /// @return Poll number and status
    function getPollStatus(uint256 _pollNum) external view returns (uint256, PollStatus);

    /// @notice Return the poll expiration timestamp.
    /// @param _pollNum Poll number
    /// @return Poll deadline
    function getPollExpirationTime(uint256 _pollNum) external view returns (uint64);

    /// @notice Return the poll stop timestamp.
    /// @param _pollNum Poll number
    /// @return Poll stop time
    function getPollStopTime(uint256 _pollNum) external view returns (uint64);

    /// @notice Return the complete list of polls an address has voted in.
    /// @param _voter Voter address
    /// @return Index - poll number. True - if address voted in poll
    function getPollHistory(address _voter) external view returns (bool[] memory);

    /// @notice Return the vote info for a given poll for an address.
    /// @param _pollNum Poll number
    /// @param _voter Voter address
    /// @return Info about voter vote
    function getPollInfoForVoter(uint256 _pollNum, address _voter) external view returns (Vote memory);

    /// @notice Checks if a user address has voted for a specific poll.
    /// @param _pollNum Poll number
    /// @param _voter Voter address
    /// @return True if address voted in poll
    function getIfUserHasVoted(uint256 _pollNum, address _voter) external view returns (bool);

    /// @notice Return the amount of tokens that are locked for a given voter address.
    /// @param _voter Voter address
    /// @return Poll number
    function getLockedAmount(address _voter) external view returns (uint256);

    /// @notice Return the amount of locked tokens of the specific poll.
    /// @param _pollNum Poll number
    /// @param _voter Voter address
    /// @return Locked tokens amount for specific poll
    function getPollLockedAmount(uint256 _pollNum, address _voter) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice ICVNX interface for CVNX contract.
interface ICVNX is IERC20 {
    /// @notice Mint new CVNX tokens.
    /// @param _account Address that receive tokens
    /// @param _amount Tokens amount
    function mint(address _account, uint256 _amount) external;

    /// @notice Lock tokens on holder balance.
    /// @param _tokenOwner Token holder
    /// @param _tokenAmount Amount to lock
    function lock(address _tokenOwner, uint256 _tokenAmount) external;

    /// @notice Unlock tokens on holder balance.
    /// @param _tokenOwner Token holder
    /// @param _tokenAmount Amount to lock
    function unlock(address _tokenOwner, uint256 _tokenAmount) external;

    /// @notice Swap CVN to CVNX tokens
    /// @param _amount Token amount to swap
    function swap(uint256 _amount) external returns (bool);

    /// @notice Transfer stuck tokens
    /// @param _token Token contract address
    /// @param _to Receiver address
    /// @param _amount Token amount
    function transferStuckERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external;

    /// @notice Set CVNXGovernance contract.
    /// @param _address CVNXGovernance contract address
    function setCvnxGovernanceContract(address _address) external;

    /// @notice Set limit params.
    /// @param _percent Percentage of the total balance available for transfer
    /// @param _limitAmount Max amount available for transfer
    /// @param _period Lock period when user can't transfer tokens
    function setLimit(uint256 _percent, uint256 _limitAmount, uint256 _period) external;

    /// @notice Add address to 'from' whitelist
    /// @param _newAddress New address
    function addFromWhitelist(address _newAddress) external;

    /// @notice Remove address from 'from' whitelist
    /// @param _oldAddress Old address
    function removeFromWhitelist(address _oldAddress) external;

    /// @notice Add address to 'to' whitelist
    /// @param _newAddress New address
    function addToWhitelist(address _newAddress) external;

    /// @notice Remove address from 'to' whitelist
    /// @param _oldAddress Old address
    function removeToWhitelist(address _oldAddress) external;

    /// @notice Change limit activity status.
    function changeLimitActivityStatus() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICVNXGovernance.sol";
import "./ICVNX.sol";

/// @notice CVNX token contract.
contract CVNX is ICVNX, ERC20("CVNX", "CVNX"), Ownable {
    event TokenLocked(uint256 indexed amount, address tokenOwner);
    event TokenUnlocked(uint256 indexed amount, address tokenOwner);

    /// @notice Governance contract.
    ICVNXGovernance public cvnxGovernanceContract;
    IERC20Metadata public cvnContract;

    struct Limit {
        uint256 percent;
        uint256 limitAmount;
        uint256 period;
    }

    Limit public limit;
    bool public isLimitsActive;
    mapping(address => uint256) public addressToEndLockTimestamp;
    mapping(address => bool) public fromLimitWhitelist;
    mapping(address => bool) public toLimitWhitelist;

    /// @notice Locked token amount for each address.
    mapping(address => uint256) public lockedAmount;

    /// @notice Governance contract created in constructor.
    constructor(address _cvnContract) {
        uint256 _toMint = 15000000000000000000000000;

        _mint(msg.sender, _toMint);
        approve(address(this), _toMint);

        cvnContract = IERC20Metadata(_cvnContract);
    }

    /// @notice Modifier describe that call available only from governance contract.
    modifier onlyGovContract() {
        require(msg.sender == address(cvnxGovernanceContract), "[E-31] - Not a governance contract.");
        _;
    }

    /// @notice Lock tokens on holder balance.
    /// @param _tokenOwner Token holder
    /// @param _tokenAmount Amount to lock
    function lock(address _tokenOwner, uint256 _tokenAmount) external override onlyGovContract {
        require(_tokenAmount > 0, "[E-41] - The amount to be locked must be greater than zero.");

        uint256 _balance = balanceOf(_tokenOwner);
        uint256 _toLock = lockedAmount[_tokenOwner] + _tokenAmount;

        require(_toLock <= _balance, "[E-42] - Not enough token on account.");
        lockedAmount[_tokenOwner] = _toLock;

        emit TokenLocked(_tokenAmount, _tokenOwner);
    }

    /// @notice Unlock tokens on holder balance.
    /// @param _tokenOwner Token holder
    /// @param _tokenAmount Amount to lock
    function unlock(address _tokenOwner, uint256 _tokenAmount) external override onlyGovContract {
        uint256 _lockedAmount = lockedAmount[_tokenOwner];

        if (_tokenAmount > _lockedAmount) {
            _tokenAmount = _lockedAmount;
        }

        lockedAmount[_tokenOwner] = _lockedAmount - _tokenAmount;

        emit TokenUnlocked(_tokenAmount, _tokenOwner);
    }

    /// @notice Swap CVN to CVNX tokens
    /// @param _amount Token amount to swap
    function swap(uint256 _amount) external override returns (bool) {
        cvnContract.transferFrom(msg.sender, 0x4e07dc9D1aBCf1335d1EaF4B2e28b45d5892758E, _amount);

        uint256 _newAmount = _amount * (10 ** (decimals() - cvnContract.decimals()));
        this.transferFrom(owner(), msg.sender, _newAmount);
        return true;
    }

    /// @notice Transfer stuck tokens
    /// @param _token Token contract address
    /// @param _to Receiver address
    /// @param _amount Token amount
    function transferStuckERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external override onlyOwner {
        require(_token.transfer(_to, _amount), "[E-56] - Transfer failed.");
    }

    /// @notice Set CVNXGovernance contract.
    /// @param _address CVNXGovernance contract address
    function setCvnxGovernanceContract(address _address) external override onlyOwner {
        if (address(cvnxGovernanceContract) != address(0)) {
            require(!cvnxGovernanceContract.getIsAvailableToCreate(), "[E-92] - Old governance contract still active.");
        }

        cvnxGovernanceContract = ICVNXGovernance(_address);
    }

    /// @notice Mint new CVNX tokens.
    /// @param _account Address that receive tokens
    /// @param _amount Tokens amount
    function mint(address _account, uint256 _amount) external override onlyOwner {
        require(totalSupply() + _amount <= 60000000000000000000000000, "[E-71] - Can't mint more.");
        _mint(_account, _amount);
    }

    /// @notice Set limit params.
    /// @param _percent Percentage of the total balance available for transfer
    /// @param _limitAmount Max amount available for transfer
    /// @param _period Lock period when user can't transfer tokens
    function setLimit(uint256 _percent, uint256 _limitAmount, uint256 _period) external override onlyOwner {
        require(_percent <= getDecimals(), "[E-89] - Percent should be less than 1.");
        require(_percent > 0, "[E-90] - Percent can't be a zero.");
        require(_limitAmount > 0, "[E-90] - Limit amount can't be a zero.");

        limit.percent = _percent;
        limit.limitAmount = _limitAmount;
        limit.period = _period;
    }

    /// @notice Add address to 'from' whitelist
    /// @param _newAddress New address
    function addFromWhitelist(address _newAddress) external override onlyOwner {
        fromLimitWhitelist[_newAddress] = true;
    }

    /// @notice Remove address from 'from' whitelist
    /// @param _oldAddress Old address
    function removeFromWhitelist(address _oldAddress) external override onlyOwner {
        fromLimitWhitelist[_oldAddress] = false;
    }

    /// @notice Add address to 'to' whitelist
    /// @param _newAddress New address
    function addToWhitelist(address _newAddress) external override onlyOwner {
        toLimitWhitelist[_newAddress] = true;
    }

    /// @notice Remove address from 'to' whitelist
    /// @param _oldAddress Old address
    function removeToWhitelist(address _oldAddress) external override onlyOwner {
        toLimitWhitelist[_oldAddress] = false;
    }

    /// @notice Change limit activity status.
    function changeLimitActivityStatus() external override onlyOwner {
        isLimitsActive = !isLimitsActive;
    }

    /// @notice Check that locked amount less then transfer amount.
    /// @notice Check limits.
    /// @param _from From address
    /// @param _to To address
    /// @param _amount Token amount
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override {
        if (_from != address(0)) {
            uint256 _availableAmount = balanceOf(_from) - lockedAmount[_from];
            require(_availableAmount >= _amount, "[E-61] - Transfer amount exceeds available tokens.");

            if (isLimitsActive && fromLimitWhitelist[_from] == false && toLimitWhitelist[_to] == false) {
                require(block.timestamp > addressToEndLockTimestamp[_from], "[E-62] - Tokens are locked until the end of the period.");
                require(_amount <= limit.limitAmount, "[E-63] - The maximum limit has been reached.");
                require(_amount <= _availableAmount * limit.percent / getDecimals(), "[E-64] - The maximum limit has been reached.");

                addressToEndLockTimestamp[_from] = block.timestamp + limit.period;
            }
        }
    }

    function getDecimals() private pure returns (uint256) {
        return 10 ** 27;
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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}