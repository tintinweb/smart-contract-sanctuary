// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { WarriorHelper, TournamentHelper, RoleHelper } from "./Libs.sol";

interface IWETH {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface ITRVBPToken {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract TRVBPTournament is Ownable {
    using WarriorHelper for WarriorHelper.WarriorRecord;
    using TournamentHelper for TournamentHelper.Store;
    using TournamentHelper for TournamentHelper.TournamentByState;
    using RoleHelper for RoleHelper.TournamentRoles;

    // defination
    enum TournamentState {
        AVAILABLE,
        READY,
        COMPLETED,
        CANCELLED
    }

    struct Warrior {
        uint16 id;
        uint16 style;
    }

    struct TournamentInfo {
        TournamentState state; // 1 = ready, 0 = available, 2 = completed
        uint256 prize_pool;
        Warrior[] warriors;
    }

    // constansts
    address public TRVBP_ADDRESS = 0x4055e3503D1221Af4b187CF3B4aa8744332A4d0b;
    address public WETH_ADDRESS = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

    // variables
    uint256 public platformShare;
    mapping(uint256 => TournamentInfo) public tournaments;
    mapping(uint16 => WarriorHelper.WarriorRecord) private warriorRecords;

    TournamentHelper.Store public sizeTickets;
    TournamentHelper.Store public feeTickets;

    uint256 public countReady;
    uint256 public countComplete;
    uint256 public countCancel;

    // roles
    bytes32 public constant SET_WINNER_ROLE = keccak256("SET_WINNER_ROLE");
    bytes32 public constant CANCEL_ROLE = keccak256("CANCEL_ROLE");
    RoleHelper.TournamentRoles private roles;

    // checkpoint max tournament id at the moment => for query easier
    uint256 public ceilTournamentId;

    // checkpoint for tournament ready at the moment => for query from backend
    TournamentHelper.TournamentByState private tournamentsByReady;

    // events
    event JoinedTournament(uint256 indexed tournamentId, uint16 indexed warriorId, uint256 amount, uint16 styleName);
    event CancelledTournament(uint256 indexed tournamentId);
    event SettedWinners(uint256 indexed tournamentId, uint16 indexed firstWinner, uint16 indexed secondWinner);
    event SettedSize(uint256 indexed start, uint256 indexed end, uint256 size);
    event SettedFee(uint256 indexed start, uint256 indexed end, uint256 fee);
    event TournamentReady(uint256 indexed tournamentId);

    constructor() {}

    // roles

    // verified
    function hasRole(bytes32 _role, address _account) public view returns (bool) {
        return roles.hasRole(_role, _account);
    }

    // verified
    function setupRole(bytes32 _role, address _account) external onlyOwner {
        roles.setupRole(_role, _account);
    }

    // verified
    function revokeRole(bytes32 _role, address _account) external onlyOwner {
        roles.revokeRole(_role, _account);
    }

    // interactive

    // verified
    function joinTournament(uint256 _tournamentId, uint16 _warriorId, uint16 _styleName) external {
        address ownerOfWarrior = ITRVBPToken(TRVBP_ADDRESS).ownerOf(_warriorId);
        
        // can not join tournament not available
        require(tournaments[_tournamentId].state == TournamentState.AVAILABLE, "Not available");
        // one player can not using warrior id of other players
        require(msg.sender == ownerOfWarrior, "Not allowed");
        // one champion can not join again
        require(!warriorRecords[_warriorId].containsTournament(_tournamentId), "Already joined tournament.");

        // compute fee to join
        uint256 amount = getFee(_tournamentId);

        // pay fee of tournament
        IWETH(WETH_ADDRESS).transferFrom(ownerOfWarrior, address(this), amount);

        // add warrior statistic
        warriorRecords[_warriorId].addTournament(_tournamentId);

        // init some data
        tournaments[_tournamentId].warriors.push(Warrior(_warriorId, _styleName));
        tournaments[_tournamentId].prize_pool += amount;

        // add some events
        emit JoinedTournament(_tournamentId, _warriorId, amount, _styleName);

        // set state = ready if full room
        if (tournaments[_tournamentId].warriors.length == getSize(_tournamentId)) {
            tournaments[_tournamentId].state = TournamentState.READY;
            countReady += 1;
            // add tournament
            tournamentsByReady.addTournament(_tournamentId);
            emit TournamentReady(_tournamentId);
        }
    }

    // verified
    function cancelTournament(uint256 _tournamentId) external {
        require(msg.sender == owner() || hasRole(CANCEL_ROLE, msg.sender), "Caller has not permission.");
        require(tournaments[_tournamentId].state == TournamentState.AVAILABLE, "Tournament not available");

        // set state = cancelled
        tournaments[_tournamentId].state = TournamentState.CANCELLED;

        // counting cancel
        countCancel += 1;

        uint256 warriorsCount = tournaments[_tournamentId].warriors.length;
        for (uint256 i = 0; i < warriorsCount; i++) {
            // get warrior joined this tournament
            Warrior memory warrior = tournaments[_tournamentId].warriors[i];

            // get owner of warrior
            address ownerOfWarrior = ITRVBPToken(TRVBP_ADDRESS).ownerOf(warrior.id);

            // compute fee of tournament
            uint256 amount = getFee(_tournamentId);

            // cashback fee to owner of warrior
            IWETH(WETH_ADDRESS).transfer(ownerOfWarrior, amount);

            // update statistic data
            warriorRecords[warrior.id].removeTournament(_tournamentId);
        }

        // emit event
        emit CancelledTournament(_tournamentId);
    }

    // verified
    function setWinner(uint256 _tournamentId, uint16 _firstBest, uint16 _secondBest) external {
        require(msg.sender == owner() || hasRole(SET_WINNER_ROLE, msg.sender), "Caller has not permission.");
        // can not set winner for not ready tournament
        require(tournaments[_tournamentId].state == TournamentState.READY, "Invalid state.");

        // confirm if winnerA and winnerB are in this tournament
        require(warriorRecords[_firstBest].containsTournament(_tournamentId), "Warrior first mismatch tournament.");
        require(warriorRecords[_secondBest].containsTournament(_tournamentId), "Warrior second mismatch tournament.");

        // remove tournament ready
        tournamentsByReady.removeTournament(_tournamentId);
        // update counting
        countReady -= 1;
        countComplete += 1;

        tournaments[_tournamentId].state = TournamentState.COMPLETED;
        address ownerOfFistBest = ITRVBPToken(TRVBP_ADDRESS).ownerOf(_firstBest);
        address ownerOfSecondBest = ITRVBPToken(TRVBP_ADDRESS).ownerOf(_secondBest);
        uint256 totalPrize = tournaments[_tournamentId].prize_pool;

        // transfer award
        uint256 bestPrize = totalPrize * 70 / 100;
        uint256 secondPrize = totalPrize * 275 / 1000;
        IWETH(WETH_ADDRESS).transfer(ownerOfFistBest, bestPrize); // 70%
        IWETH(WETH_ADDRESS).transfer(ownerOfSecondBest, secondPrize); // 27.5%
        platformShare += (tournaments[_tournamentId].prize_pool - bestPrize - secondPrize);

        // update warrior statistic data
        warriorRecords[_firstBest].firstWins += 1;
        warriorRecords[_secondBest].secondWins += 1;
        uint256 warriorSize = tournaments[_tournamentId].warriors.length;
        for (uint256 i = 0; i < warriorSize; i++) {
            uint16 warriorId = tournaments[_tournamentId].warriors[i].id;
            if (warriorId != _firstBest && warriorId != _secondBest) {
                warriorRecords[warriorId].losses += 1;
            }
        }

        // emit event
        emit SettedWinners(_tournamentId, _firstBest, _secondBest);
    }

    // utility

    // verified
    function canChangeValue(uint256 _start, uint256 _end) public view returns (bool) {
        for (uint i = _start; i <= _end; i++) {
            // if tournament not available or exists player joined will can not change size and fee
            if (tournaments[i].state != TournamentState.AVAILABLE || tournaments[i].warriors.length > 0) {
                return false;
            }
        }
        return true;
    }

    // verified
    function setTournamentSize(uint256 _start, uint256 _end, uint256 _size) external onlyOwner {
        require(_end >= _start, "Input invalid.");
        require(_start <= sizeTickets.currentEnd + 1, "Value not continuous.");
        require(_size > 0, "Value invalid.");
        if (_start < sizeTickets.currentEnd + 1) {
            require(canChangeValue(_start, _end), "Tournament can not be changed.");
        }

        // set ceil tournament token id
        ceilTournamentId = ceilTournamentId > _end ? ceilTournamentId : _end;
        sizeTickets.addTicket(_start, _end, _size);
        emit SettedSize(_start, _end, _size);
    }

    // verified
    function getSize(uint256 _tournamentId) public view returns (uint256) {
        (bool success, uint256 index) = sizeTickets.findTicket(_tournamentId);
        require(success, "Can not found tournament size.");
        return sizeTickets.getValue(index);
    }

    // verified
    function setTournamentFee(uint256 _start, uint256 _end, uint256 _fee) external onlyOwner {
        require(_end >= _start, "Input invalid.");
        require(_start <= feeTickets.currentEnd + 1, "Value not continuous.");
        require(_fee > 0, "Value invalid.");
        if (_start < feeTickets.currentEnd + 1) {
            require(canChangeValue(_start, _end), "Tournament can not be changed.");
        }

        feeTickets.addTicket(_start, _end, _fee);
        emit SettedFee(_start, _end, _fee);
    }

    // verified
    function getFee(uint256 _tournamentId) public view returns (uint256) {
        (bool success, uint256 index) = feeTickets.findTicket(_tournamentId);
        require(success, "Can not found tournament fee.");
        return feeTickets.getValue(index);
    }

    // verified
    function getWarriorRecords(uint16 _warriorId) public view returns (uint256 matches, uint256[] memory tournamentIds, uint256 firstWins, uint256 secondWins, uint256 losses) { // tournamentIds, wins, losses
        matches = warriorRecords[_warriorId].tournamentIds.length;
        tournamentIds = warriorRecords[_warriorId].tournamentIds;
        firstWins = warriorRecords[_warriorId].firstWins;
        secondWins = warriorRecords[_warriorId].secondWins;
        losses = warriorRecords[_warriorId].losses;
    }

    // verified
    function getTournamentsByReady() public view returns (TournamentInfo[] memory) {
        uint256 size = tournamentsByReady.tournamentIds.length;
        TournamentInfo[] memory tournamentsInfo = new TournamentInfo[](size);
        for (uint256 i = 0; i < size; i++) {
            (tournamentsInfo[i],,) = getTournamentDetail(tournamentsByReady.tournamentIds[i]);
        }
        return tournamentsInfo;
    }

    // verified
    function getTournaments(uint256 _start, uint256 _end) public view returns (TournamentInfo[] memory) {
        uint256 size = _end - _start + 1;
        TournamentInfo[] memory tournamentsInfo = new TournamentInfo[](size);
        for (uint256 i = _start; i <= _end; i++) {
            (tournamentsInfo[i],,) = getTournamentDetail(i);
        }
        return tournamentsInfo;
    }

    // verified
    function getTournamentsByState(uint256 _start, uint256 _end, TournamentState _state) public view returns (TournamentInfo[] memory) {
        uint256 size = _end - _start + 1;
        TournamentInfo[] memory tournamentsInfo = new TournamentInfo[](size);
        for (uint256 i = _start; i <= _end; i++) {
            if (tournaments[i].state == _state) {
                (tournamentsInfo[i],,) = getTournamentDetail(i);
            }
        }
        return tournamentsInfo;
    }

    // verified
    function getTournamentDetail(uint256 _tournamentId) public view returns (TournamentInfo memory, uint256 size, uint256 fee) { // size, fee
        (bool sizeSuccess, uint256 sizeIndex) = sizeTickets.findTicket(_tournamentId);
        size = sizeSuccess ? sizeTickets.getValue(sizeIndex) : 0;

        (bool feeSuccess, uint256 feeIndex) = feeTickets.findTicket(_tournamentId);
        fee = feeSuccess ? feeTickets.getValue(feeIndex) : 0;

        return (tournaments[_tournamentId], size, fee);
    }

    // done
    function withdrawFees() external onlyOwner { // withdraw WETH
        IWETH(WETH_ADDRESS).transfer(msg.sender, platformShare);
    }

    // done
    function withdraw() external onlyOwner { // withdraw matic
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
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
pragma solidity ^0.8.9;

library WarriorHelper {

    struct WarriorRecord {
        uint256[] tournamentIds;
        mapping(uint256 => uint256) indexes; // tournament_id value to index
        uint256 firstWins;
        uint256 secondWins;
        uint256 losses;
    }

    // verified
    function addTournament(WarriorRecord storage _warrior, uint256 _tournamentId) internal {
        if (_warrior.indexes[_tournamentId] != 0) return; // already exists
        _warrior.tournamentIds.push(_tournamentId);
        // The value is stored at length-1, but adding 1 to all indexes
        // and use 0 as a sentinel value
        _warrior.indexes[_tournamentId] = _warrior.tournamentIds.length;
    }

    // verified
    function removeTournament(WarriorRecord storage _warrior, uint256 _tournamentId) internal {
        uint256 valueIndex = _warrior.indexes[_tournamentId];

        if (valueIndex == 0) return; // removed not exists value

        uint256 toDeleteIndex = valueIndex - 1; // when add we not sub for 1 so now must sub 1 (for not out of bound)
        uint256 lastIndex = _warrior.tournamentIds.length - 1;

        if (lastIndex != toDeleteIndex) { // swap
            uint256 lastvalue = _warrior.tournamentIds[lastIndex];

            // Move the last value to the index where the value to delete is
            _warrior.tournamentIds[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            _warrior.indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
        }

        // Delete the slot where the moved value was stored
        _warrior.tournamentIds.pop();

        // Delete the index for the deleted slot
        _warrior.indexes[_tournamentId] = 0; // set to 0
    }

    // verified
    function containsTournament(WarriorRecord storage _warrior, uint256 _tournamentId) internal view returns (bool) {
        return _warrior.indexes[_tournamentId] != 0;
    }
}

library TournamentHelper {
    struct Ticket {
        uint256 startIdx;
        uint256 endIdx;
        uint256 value;
    }

    struct Store {
        uint256 currentEnd;
        Ticket[] values;
    }

    function addTicket(Store storage _tournaments, uint256 _start, uint256 _end, uint256 _value) internal {
        _tournaments.values.push(Ticket(_start, _end, _value));
        _tournaments.currentEnd = max(_tournaments.currentEnd, _end);
    }

    function findTicket(Store storage _tournaments, uint256 _element) internal view returns (bool, uint256) {
        uint256 len = _tournaments.values.length;

        for (uint256 i = len; i > 0; i--) {
            Ticket memory ticket = _tournaments.values[i - 1];
            if (ticket.startIdx <= _element && ticket.endIdx >= _element) { // finding first element match
                return (true, i - 1);
            }
        }
        return (false, 0);
    }

    function getValue(Store storage _tournaments, uint256 _index) internal view returns (uint256) {
        return _tournaments.values[_index].value;
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }


    struct TournamentByState {
        uint256[] tournamentIds;
        mapping(uint256 => uint256) indexes; // tournament_id value to index
    }

    // verified
    function addTournament(TournamentByState storage _tournament, uint256 _tournamentId) internal {
        if (_tournament.indexes[_tournamentId] != 0) return; // already exists
        _tournament.tournamentIds.push(_tournamentId);
        // The value is stored at length-1, but adding 1 to all indexes
        // and use 0 as a sentinel value
        _tournament.indexes[_tournamentId] = _tournament.tournamentIds.length;
    }

    // verified
    function removeTournament(TournamentByState storage _tournament, uint256 _tournamentId) internal {
        uint256 valueIndex = _tournament.indexes[_tournamentId];

        if (valueIndex == 0) return; // removed not exists value

        uint256 toDeleteIndex = valueIndex - 1; // when add we not sub for 1 so now must sub 1 (for not out of bound)
        uint256 lastIndex = _tournament.tournamentIds.length - 1;

        if (lastIndex != toDeleteIndex) { // swap
            uint256 lastvalue = _tournament.tournamentIds[lastIndex];

            // Move the last value to the index where the value to delete is
            _tournament.tournamentIds[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            _tournament.indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
        }

        // Delete the slot where the moved value was stored
        _tournament.tournamentIds.pop();

        // Delete the index for the deleted slot
        _tournament.indexes[_tournamentId] = 0; // set to 0
    }

    // verified
    function containsTournament(TournamentByState storage _tournament, uint256 _tournamentId) internal view returns (bool) {
        return _tournament.indexes[_tournamentId] != 0;
    }
}

library RoleHelper {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 role;
    }

    struct TournamentRoles {
        mapping(bytes32 => RoleData) roles;
    }

    function hasRole(TournamentRoles storage _tournamentRoles, bytes32 _role, address _account) internal view returns (bool) {
        return _tournamentRoles.roles[_role].members[_account];
    }

    function setupRole(TournamentRoles storage _tournamentRoles, bytes32 _role, address _account) internal {
        if (!hasRole(_tournamentRoles, _role, _account)) {
            _tournamentRoles.roles[_role].members[_account] = true;
        }
    }

    function revokeRole(TournamentRoles storage _tournamentRoles, bytes32 _role, address _account) internal {
        if (hasRole(_tournamentRoles, _role, _account)) {
            _tournamentRoles.roles[_role].members[_account] = false;
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