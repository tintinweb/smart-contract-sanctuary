/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/PredictZ.sol

pragma solidity 0.8.7;


contract PredictZ is Ownable {

    event CreateMatch(address indexed creator,Match match_);
    event CloseMatch(address indexed setter,Match match_);
    event Bet(address indexed better, uint256 matchId, uint256 teamId,uint256 amount);
    event EditMatch(address indexed editor, Match match_);
    event Claim(address indexed claimer,uint256 matchId,uint256 amount);
    event SetOperatorAndTreasuryAddress(address operatorAddress,address treasuryAddress);
    
    enum Result {
        Pending,
        Draw,
        TeamAWins,
        TeamBWins,
        Cancelled
    }

    enum Status {
        Pending,
        Claimable
    }

    struct Match {
        uint256 id;
        uint256 leagueId;
        uint256 teamAId;
        uint256 teamBId;
        uint256 startTime;
        uint256 endTime;
        uint256 accTeamABets;
        uint256 accTeamBBets;
        uint256 accDrawBets;
        uint256 scoreTeamA;
        uint256 scoreTeamB;
        Result result;
        Status status;
    }
    
    // mapping(matchId => Match)
    mapping(uint256 => Match) public matches;

    // mapping(matchId => mapping(user => mapping(teamId => amount)))
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public userBets;

    // mapping(matchId => mapping(user => claim))
    mapping(uint256 => mapping(address => bool)) public userClaims;
    
    address public treasuryAddress;
    address public operatorAddress;
    uint256 public latestMatchId;
    uint256 public fee;

    constructor (uint256 fee_,address operatorAddress_,address treasuryAddress_) {
        require(fee_>= 1 && fee_ <= 20,"PredictZ: Invalid fee");
        require(operatorAddress_ != address(0), "PredictZ: Cannot be zero address");
        require(treasuryAddress_ != address(0), "PredictZ: Cannot be zero address");
        operatorAddress = operatorAddress_;
        treasuryAddress = treasuryAddress_;
        fee = fee_;
    }

    function setFee(uint256 fee_) external onlyOwner {
        require(fee_>= 1 && fee_ <= 20,"PredictZ: Invalid fee");
        fee = fee_;
    }

    function setOperatorAndTreasuryAddress(address operatorAddress_,address treasuryAddress_) external onlyOwner {
        require(operatorAddress_ != address(0), "PredictZ: Cannot be zero address");
        require(treasuryAddress_ != address(0), "PredictZ: Cannot be zero address");
        operatorAddress = operatorAddress_;
        treasuryAddress = treasuryAddress_;

        emit SetOperatorAndTreasuryAddress(operatorAddress,treasuryAddress);
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "PredictZ: Not operator");
        _;
    }

    function createMatch(uint256 leagueId,uint256 teamAId,uint256 teamBId,uint256 endTime) external onlyOperator {
        require(teamAId!=0,"PredictZ: Invalid teamAId");
        require(teamBId!=0,"PredictZ: Invalid teamBId");
        require(endTime>=block.timestamp,"PredictZ: Invalid endTime");
        require(teamAId!=teamBId,"PredictZ: Invalid teamId");

        latestMatchId++;
        matches[latestMatchId] = Match({
            id: latestMatchId,
            leagueId: leagueId,
            teamAId: teamAId,
            teamBId: teamBId,
            startTime: block.timestamp,
            endTime: endTime,
            accTeamABets: 0,
            accTeamBBets: 0,
            accDrawBets: 0,
            result: Result.Pending,
            scoreTeamA: 0,
            scoreTeamB: 0,
            status: Status.Pending
        });

        emit CreateMatch(msg.sender,matches[latestMatchId]);
    }
    
    function editMatch(uint256 matchId,uint256 endTime,Result result,uint256 scoreTeamA, uint256 scoreTeamB) external onlyOperator {
        require(endTime!=0,"PredictZ: Invalid endTime");
        
        matches[matchId].endTime = endTime;
        matches[matchId].scoreTeamA = scoreTeamA;
        matches[matchId].scoreTeamB = scoreTeamB;
        matches[matchId].result = result;
        
        emit EditMatch(msg.sender, matches[matchId]);
    }

    function closeMatch(uint256 matchId,Result result, uint256 scoreTeamA, uint256 scoreTeamB) external onlyOperator {
        require(matches[matchId].status==Status.Pending,"PredictZ: Status must be pending");
        require(result!=Result.Pending,"PredictZ: Result cannot be pending");

        matches[matchId].result = result;
        matches[matchId].scoreTeamA = scoreTeamA;
        matches[matchId].scoreTeamB = scoreTeamB;
        matches[matchId].status = Status.Claimable;

        if (result!=Result.Cancelled) {
            uint256 totalBet = totalBets(matchId);
            transferBNB(treasuryAddress,(totalBet*fee)/100);
        }
        
        emit CloseMatch(msg.sender,matches[matchId]);
    }
    
    function bet(uint256 matchId, uint256 teamId) external payable {
        require(msg.value>=10**16,"PredictZ: Minimum amount");
        require(matches[matchId].endTime>block.timestamp,"PredictZ: Time's up");
        require(matches[matchId].status==Status.Pending,"PredictZ: Status must be pending");
        userBets[matchId][msg.sender][teamId] += msg.value;

        if (teamId==0) {
            matches[matchId].accDrawBets += msg.value;
        } else if (teamId==matches[matchId].teamAId) {
            matches[matchId].accTeamABets += msg.value;
        } else if (teamId==matches[matchId].teamBId) {
            matches[matchId].accTeamBBets += msg.value;
        } else {
            revert("PredictZ: Invalid teamId");
        }

        emit Bet(msg.sender,matchId,teamId,msg.value);
    }

    function totalBets(uint256 matchId) public view returns(uint256) {
        return matches[matchId].accDrawBets + matches[matchId].accTeamABets + matches[matchId].accTeamBBets;
    }

    function viewPrize(uint256 matchId,address user) public view returns(uint256) {
        require(matches[matchId].status==Status.Claimable,"PredictZ: Status must be claimable");
        
        uint256 totalBet = totalBets(matchId);
        uint256 totalBetWithoutFee = (totalBet * (100 - fee)) / 100;

        uint256 amount;
        if (matches[matchId].result==Result.Draw) {
            if (matches[matchId].accDrawBets==0) {
                return 0;
            }

            amount = (totalBetWithoutFee * userBets[matchId][user][0])/matches[matchId].accDrawBets;

        } else if (matches[matchId].result==Result.TeamAWins) {
            if (matches[matchId].accTeamABets==0) {
                return 0;
            }

            amount = (totalBetWithoutFee * userBets[matchId][user][matches[matchId].teamAId])/matches[matchId].accTeamABets;

        } else if (matches[matchId].result==Result.TeamBWins) {
            if (matches[matchId].accTeamBBets==0) {
                return 0;
            }

            amount = (totalBetWithoutFee * userBets[matchId][user][matches[matchId].teamBId])/matches[matchId].accTeamBBets;

        } else if (matches[matchId].result==Result.Cancelled) {
            amount += userBets[matchId][user][0];
            amount += userBets[matchId][user][matches[matchId].teamAId];
            amount += userBets[matchId][user][matches[matchId].teamBId];
            
        } else {
            revert("PredictZ: Invalid result");
        }

        return amount;
    }

    function claim(uint256 matchId) external {
        require(userClaims[matchId][msg.sender]==false,"PredictZ: Claimed");
        
        userClaims[matchId][msg.sender] = true;
        uint256 amount = viewPrize(matchId,msg.sender);
        payable(msg.sender).transfer(amount);

        emit Claim(msg.sender, matchId, amount);
    }

    function transfer(address token_,address to,uint256 amount) external onlyOwner{
        require(token_ != address(0), "PredictZ: Cannot be zero address");
        require(to != address(0), "PredictZ: Cannot be zero address");
        require(amount != 0, "PredictZ: Cannot be zero");
        IERC20(token_).transfer(to,amount);
    }

    function transferBNB(address to,uint256 amount) public onlyOwner {
        require(to != address(0), "PredictZ: Cannot be zero address");
        require(amount != 0, "PredictZ: Cannot be zero");
        payable(to).transfer(amount);
    }

    function viewMatches(uint256 _cursor, uint256 _size) external view returns (
        Match[] memory
        ) {
        uint256 length = _size;
        if (length > (latestMatchId - _cursor + 1)) {
            length = latestMatchId - _cursor + 1;
        }

        Match[] memory matches_ = new Match[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 newCursor = i + _cursor;
            matches_[i] = matches[newCursor];
        }

        return (matches_);
    }

    function viewUserMatches(address _user,uint256 _cursor, uint256 _size) external view returns (
        uint256[] memory teamABets,
        uint256[] memory teamBBets,
        uint256[] memory drawBets,
        bool[] memory claims
        ) {
        uint256 length = _size;
        if (length > (latestMatchId - _cursor + 1)) {
            length = latestMatchId - _cursor + 1;
        }

        teamABets = new uint256[](length);
        teamBBets = new uint256[](length);
        drawBets = new uint256[](length);
        claims = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 newCursor = i + _cursor;
            teamABets[i] = userBets[matches[newCursor].id][_user][matches[newCursor].teamAId];
            teamBBets[i] = userBets[matches[newCursor].id][_user][matches[newCursor].teamBId];
            drawBets[i] = userBets[matches[newCursor].id][_user][0];
            claims[i] = userClaims[matches[newCursor].id][_user];
        }

    }
}