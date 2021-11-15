// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SportPrediction is Ownable {
    enum MatchResult {
        NONE,
        A,
        B,
        AB
    }

    struct IMatch {
        uint256 matchId;
        uint256 startTime;
        uint256 endTime;
        uint256 balance;
        uint256 aBalance;
        uint256 bBalance;
        uint256 aRate;
        uint256 bRate;
        uint256 matchType;
        MatchResult matchResult;
    }

    struct IParticipant {
        address owner;
        uint256 amount;
        MatchResult vote;
        bool isClaimed;
    }

    // Sport matches
    mapping(uint256 => IMatch) public matches;
    uint256 public matchesCount;

    // Match Participants
    mapping(uint256 => IParticipant[]) public participants;
    mapping(uint256 => uint256) public participantsCount;

    // ERC20
    IERC20 gfx_;

    uint256 private fee_;
    uint256 private digits_;

    // New Match
    event NewMatch(
        uint256 matchId,
        uint256 startTime,
        uint256 endTime,
        uint256 matchType
    );

    // Match Ended
    event MatchEnded(uint256 matchId, string matchResult);

    // New Participant
    event NewParticipantJoined(
        uint256 matchId,
        address participant,
        uint256 deposit,
        string vote
    );

    event GFXClaimed(uint256 matchId, address owner, uint256 amount);

    event MatchRateUpdated(
        uint256 matchId,
        uint256 balance,
        uint256 aRate,
        uint256 bRate
    );

    event WithdrawBalance(address target, address token, uint256 amount);

    constructor() {
        matchesCount = 0;
        fee_ = 1;
        digits_ = 0;
    }

    // Modifiers
    modifier _canParticipate(
        uint256 _matchId,
        string memory _vote,
        uint256 _amount
    ) {
        require(
            block.timestamp < matches[_matchId].startTime,
            "SportPrediction: Locked"
        );

        require(
            keccak256(abi.encodePacked(_vote)) ==
                keccak256(abi.encodePacked("A")) ||
                keccak256(abi.encodePacked(_vote)) ==
                keccak256(abi.encodePacked("B")),
            "SportPrediction: Invalid vote"
        );

        require(_amount > 0, "SportPrediction: Wrong amount");

        bool flag = false;
        for (uint256 i = 0; i < participants[_matchId].length; i++) {
            if (participants[_matchId][i].owner == msg.sender) {
                flag = true;
            }
        }

        require(!flag, "SportPrediction: Already participated");
        _;
    }

    modifier _canEndMatch(uint256 _matchId, string memory _result) {
        require(
            block.timestamp > matches[_matchId].endTime,
            "SportPrediction: Not ready to end"
        );

        require(
            keccak256(abi.encodePacked(_result)) ==
                keccak256(abi.encodePacked("A")) ||
                keccak256(abi.encodePacked(_result)) ==
                keccak256(abi.encodePacked("B")) ||
                keccak256(abi.encodePacked(_result)) ==
                keccak256(abi.encodePacked("AB")),
            "SportPrediction: Invalid result"
        );
        _;
    }

    function initialize(address _gfx) public onlyOwner {
        gfx_ = IERC20(_gfx);
    }

    function createNewMatch(
        uint256 _matchId,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _matchType
    ) public onlyOwner returns (uint256) {
        require(
            _startTime > block.timestamp,
            "SportPrediction: StartTime is gone"
        );
        require(_endTime > _startTime, "SportPrediction: Wront EndTime");

        IMatch memory newMatch;
        newMatch.matchId = _matchId;
        newMatch.startTime = _startTime;
        newMatch.endTime = _endTime;
        newMatch.matchType = _matchType;
        newMatch.matchResult = MatchResult.NONE;
        newMatch.aRate = 0;
        newMatch.bRate = 0;
        newMatch.aBalance = 0;
        newMatch.bBalance = 0;
        matches[_matchId] = newMatch;

        matchesCount++;

        emit NewMatch(_matchId, _startTime, _endTime, _matchType);

        return _matchId;
    }

    function participateMatch(
        uint256 _matchId,
        string memory _vote,
        uint256 _amount
    ) public _canParticipate(_matchId, _vote, _amount) {
        require(_amount > 0, "SportPrediction: Can't participate");

        require(
            gfx_.transferFrom(msg.sender, address(this), _amount),
            "SportPrediction: Not allowed to transfer"
        );

        IParticipant memory newParticipant;
        newParticipant.owner = msg.sender;
        newParticipant.amount = _amount;
        newParticipant.isClaimed = false;

        if (
            keccak256(abi.encodePacked(_vote)) ==
            keccak256(abi.encodePacked("A"))
        ) {
            newParticipant.vote = MatchResult.A;
            matches[_matchId].aBalance += _amount;
        } else {
            newParticipant.vote = MatchResult.B;
            matches[_matchId].bBalance += _amount;
        }

        participants[_matchId].push(newParticipant);
        participantsCount[_matchId]++;

        matches[_matchId].balance =
            matches[_matchId].aBalance +
            matches[_matchId].bBalance;

        matches[_matchId].aRate = matches[_matchId].aBalance == 0
            ? 0
            : (matches[_matchId].balance * 100) / matches[_matchId].aBalance;
        matches[_matchId].bRate = matches[_matchId].bBalance == 0
            ? 0
            : (matches[_matchId].balance * 100) / matches[_matchId].bBalance;

        emit NewParticipantJoined(_matchId, msg.sender, _amount, _vote);
        emit MatchRateUpdated(
            _matchId,
            matches[_matchId].balance,
            matches[_matchId].aRate,
            matches[_matchId].bRate
        );
    }

    function endMatch(uint256 _matchId, string memory _result)
        public
        onlyOwner
        _canEndMatch(_matchId, _result)
    {
        if (
            keccak256(abi.encodePacked(_result)) ==
            keccak256(abi.encodePacked("A"))
        ) {
            matches[_matchId].matchResult = MatchResult.A;
        } else if (
            keccak256(abi.encodePacked(_result)) ==
            keccak256(abi.encodePacked("B"))
        ) {
            matches[_matchId].matchResult = MatchResult.B;
        } else {
            matches[_matchId].matchResult = MatchResult.AB;
        }
        emit MatchEnded(_matchId, _result);
    }

    function claimGFX(uint256 _matchId) public {
        require(
            participantsCount[_matchId] > 0,
            "SportPrediction: No participant"
        );
        require(
            matches[_matchId].matchResult != MatchResult.NONE,
            "SportPrediction: Match is not ended"
        );

        bool claimed = false;

        for (uint256 i = 0; i < participantsCount[_matchId]; i++) {
            if (
                participants[_matchId][i].owner == msg.sender &&
                !participants[_matchId][i].isClaimed
            ) {
                if (matches[_matchId].matchResult == MatchResult.AB) {
                    _transferGFX(
                        _matchId,
                        msg.sender,
                        participants[_matchId][i].amount,
                        true
                    );
                } else if (
                    matches[_matchId].matchResult == MatchResult.A &&
                    participants[_matchId][i].vote == MatchResult.A
                ) {
                    uint256 amount = (participants[_matchId][i].amount *
                        matches[_matchId].aRate) / 100;

                    _transferGFX(_matchId, msg.sender, amount, false);
                } else if (
                    matches[_matchId].matchResult == MatchResult.B &&
                    participants[_matchId][i].vote == MatchResult.B
                ) {
                    uint256 amount = (participants[_matchId][i].amount *
                        matches[_matchId].bRate) / 100;

                    _transferGFX(_matchId, msg.sender, amount, false);
                }
                participants[_matchId][i].isClaimed = true;
                claimed = true;
                break;
            }
        }

        require(claimed, "SportPrediction: Loser can't claim award");
    }

    function _transferGFX(
        uint256 _matchId,
        address _owner,
        uint256 _amount,
        bool _noFee
    ) private {
        uint256 amount = _amount;
        if (!_noFee) {
            amount = (_amount * fee_) / (10**digits_);
        }

        require(gfx_.transfer(_owner, amount), "Failed to transfer");

        emit GFXClaimed(_matchId, _owner, amount);
    }

    function withdrawBalance(
        address _target,
        address _token,
        uint256 _amount
    ) external onlyOwner {
        require(_target != address(0), "Invalid Target Address");
        require(_token != address(0), "Invalid Token Address");
        require(_amount > 0, "Amount should be bigger than 0");

        IERC20 token = IERC20(_token);
        require(token.transfer(_target, _amount), "Withdraw failed");

        emit WithdrawBalance(_target, _token, _amount);
    }

    function getFee() public view onlyOwner returns (uint256, uint256) {
        return (fee_, digits_);
    }

    function setFee(uint256 _rate, uint256 _digits) public onlyOwner {
        fee_ = _rate;
        digits_ = _digits;
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

