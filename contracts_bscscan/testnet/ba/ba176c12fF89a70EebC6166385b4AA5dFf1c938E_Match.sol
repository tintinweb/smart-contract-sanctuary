// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/DataTypes.sol";

contract Match is Ownable {

    uint256 public nMatches;

    mapping (address => bool) admins;
    mapping (uint256 => DataTypes.Match) public matches;

    /* ========== MODIFIERS ========== */

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || admins[msg.sender] == true, "!owner && admin");
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setAdminPermission(address _admin, bool _status) external onlyOwner {
        admins[_admin] = _status;
    }

    function createMatches(bytes32[] calldata _descriptions, uint256[] calldata _startTimes, uint256[] calldata _endTimes)
    external onlyOwnerOrAdmin
    returns (uint256[] memory)
    {
        uint256[] memory _ids = new uint[](_descriptions.length);
        require(_descriptions.length == _startTimes.length && _startTimes.length == _endTimes.length, 'not-same-size');
        require(_descriptions.length > 0, 'size = 0');
        for (uint256 i = 0; i < _descriptions.length; i++) {
            _ids[i] = createSingleMatch(_descriptions[i], _startTimes[i], _endTimes[i]);
        }
        return _ids;
    }

    function updateMatchScores(uint256[] calldata _matchIds, uint256[] calldata _point1, uint256[] calldata _point2)
    external onlyOwnerOrAdmin {
        require(_matchIds.length > 0, 'size = 0');
        require(_matchIds.length == _point1.length && _point1.length == _point2.length, 'not-same-size');

        for (uint256 i = 0; i < _matchIds.length; i++) {
            updateMatchScore(_matchIds[i], DataTypes.Score(_point1[i], _point2[i]));
        }
    }

    function updateMatchStatuses(uint256[] memory _matchIds, DataTypes.MatchStatus[] memory _status)
    external onlyOwnerOrAdmin
    {
        require(_matchIds.length > 0, 'size = 0');
        require(_matchIds.length == _status.length, 'not-same-size');
        for (uint256 i = 0; i < _matchIds.length; i++) {
            updateMatchStatus(_matchIds[i], _status[i]);
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function info(uint256 _matchId) external view returns(DataTypes.Match memory _match) {
        _match = matches[_matchId];
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function createSingleMatch(bytes32 _description, uint256 _startTime, uint256 _endTime) internal returns(uint256 _idx)
    {
        _idx = nMatches;
        matches[_idx] = DataTypes.Match(
            _description,
            _startTime,
            _endTime,
            DataTypes.Score(0, 0),
            DataTypes.MatchStatus.AVAILABLE
        );
        nMatches++;
    }

    function updateMatchScore(uint256 _matchId, DataTypes.Score memory _score) internal {
        DataTypes.Match storage _match = matches[_matchId];
        _match.score = _score;
        emit MatchScoreUpdated(msg.sender, _matchId, _score);
    }

    function updateMatchStatus(uint256 _matchId, DataTypes.MatchStatus _status) internal {
        DataTypes.Match storage _match = matches[_matchId];
        _match.status = _status;
        emit MatchStatusUpdated(msg.sender, _matchId, _status);
    }


    /* =============== EVENTS ==================== */

    event MatchScoreUpdated(address caller, uint256 matchId, DataTypes.Score score);
    event MatchStatusUpdated(address caller, uint256 matchId, DataTypes.MatchStatus status);
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

