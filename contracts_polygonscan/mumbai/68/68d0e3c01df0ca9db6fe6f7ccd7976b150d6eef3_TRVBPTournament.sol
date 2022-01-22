// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { AdminControl } from "./AdminControl.sol";
import { TRVBPWarrior } from "./Warrior.sol";
import { Map } from "./Libs.sol";
import { IWETH } from "./Interfaces.sol";

contract TRVBPTournament is TRVBPWarrior, AdminControl, ReentrancyGuard {
  using Map for Map.Record;

  // defination
  enum TournamentState {
    AVAILABLE,
    READY,
    COMPLETED,
    CANCELLED
  }

  struct TournamentInfo {
    TournamentState state; // 1 = ready, 0 = available, 2 = completed
    uint256 prize_pool;
    Warrior[] warriors;
    uint256 first_winner;
    uint256 second_winner;
    uint256[] third_winners;
    uint256[] fourth_winners;
    string hashKey;
  }

  // variables
  uint256 public countReady;
  uint256 public countComplete;
  uint256 public countCancel;

  uint256 public platformShare;
  mapping(uint256 => TournamentInfo) private tournaments;
  Map.Record private tournamentsByReady;

  // events
  event JoinedTournament(uint256 indexed tournamentId, uint256 indexed warriorId, uint256 amount, uint16 style, CLASSES class);
  event TournamentReady(uint256 indexed tournamentId);
  event CancelledTournament(uint256 indexed tournamentId);
  event SetWinners(uint256 indexed tournamentId, uint256 indexed firstWinner, uint256 indexed secondWinner);

  constructor() AdminControl() {}

  // verified
  function joinTournament(
    uint256 _tournamentId,
    uint256 _warriorId,
    uint16 _style
  ) external {
    address ownerOfWarrior = TRVBPWarrior.getOwnerOf(TRVBP_ADDRESSES, _warriorId);

    // can not join tournament not available
    require(tournaments[_tournamentId].state == TournamentState.AVAILABLE, "Not available");
    // one player can not using warrior id of other players
    require(msg.sender == ownerOfWarrior, "Not allowed");

    // compute fee to join
    (bool feeSuccess, uint256 amount) = getFee(_tournamentId);
    require(feeSuccess, "Non-exists fee");

    // compute size to join
    (bool sizeSuccess, uint256 size) = getSize(_tournamentId);
    require(sizeSuccess, "Non-exists size");

    // compute class to join
    (bool classSuccess, uint256 class) = getClass(_tournamentId);
    require(classSuccess, "Non-exists class");

    // check champion joinable
    TRVBPWarrior.checkJoinable(_tournamentId, _warriorId, getMaxFightingPerChamp(_warriorId), uint8(class));

    // pay fee of tournament
    IWETH(WETH_ADDRESS).transferFrom(ownerOfWarrior, address(this), amount);

    // add warrior statistic
    TRVBPWarrior.updateJoinedStatistic(_tournamentId, _warriorId);

    // add tournament data
    tournaments[_tournamentId].warriors.push(Warrior(_warriorId, _style));
    tournaments[_tournamentId].prize_pool += amount;

    // add some events
    emit JoinedTournament(_tournamentId, _warriorId, amount, _style, CLASSES(class));

    // set state = ready if full room
    if (tournaments[_tournamentId].warriors.length == size) {
      tournaments[_tournamentId].state = TournamentState.READY;
      countReady++;
      // add tournament
      tournamentsByReady.addValue(_tournamentId);
      emit TournamentReady(_tournamentId);
    }
  }

  // verified
  function cancelTournament(uint256 _tournamentId) external nonReentrant onlyRoler(CANCEL_ROLE) {
    require(tournaments[_tournamentId].state == TournamentState.AVAILABLE, "Tournament not available");

    // set state = cancelled
    tournaments[_tournamentId].state = TournamentState.CANCELLED;

    // counting cancel
    countCancel++;

    uint256 warriorsCount = tournaments[_tournamentId].warriors.length;
    uint256 amount = tournaments[_tournamentId].prize_pool / warriorsCount;
    tournaments[_tournamentId].prize_pool = 0;
    for (uint256 i = 0; i < warriorsCount; i++) {
      // get warrior joined this tournament
      Warrior memory warrior = tournaments[_tournamentId].warriors[i];

      // get owner of warrior
      address ownerOfWarrior = TRVBPWarrior.getOwnerOf(TRVBP_ADDRESSES, warrior.id);

      // cashback fee to owner of warrior
      IWETH(WETH_ADDRESS).transfer(ownerOfWarrior, amount);

      // update statistic data
      TRVBPWarrior.updateCancelledStatistic(_tournamentId, warrior.id);
    }

    // emit event
    emit CancelledTournament(_tournamentId);
  }

  // verified
  function setWinner(
    uint256 _tournamentId,
    uint256 _firstWinner,
    uint256 _secondWinner,
    uint256[] calldata _thirdWinners,
    uint256[] calldata _fourthWinners,
    string calldata _hashKey
  ) external nonReentrant {
    TournamentInfo storage tournamentInfo = tournaments[_tournamentId];
    require(msg.sender == owner() || hasRole(SET_WINNER_ROLE, msg.sender), "Caller does not have permission");
    // can not set winner for not ready tournament
    require(tournamentInfo.state == TournamentState.READY, "Invalid state");
    (, uint256 size) = getSize(_tournamentId);
    require(1 + 1 + _thirdWinners.length + _fourthWinners.length == size, "Input mismatch");

    // confirm if winnerA and winnerB are in this tournament
    TRVBPWarrior.checkWinners(_tournamentId, _firstWinner, _secondWinner, _thirdWinners, _fourthWinners);

    // remove tournament ready
    tournamentsByReady.removeValue(_tournamentId);
    // update counting
    if (countReady > 0) {
      countReady--;
    }
    countComplete++;

    // update tournament data
    tournamentInfo.state = TournamentState.COMPLETED;
    tournamentInfo.first_winner = _firstWinner;
    tournamentInfo.second_winner = _secondWinner;
    tournamentInfo.third_winners = _thirdWinners;
    tournamentInfo.fourth_winners = _fourthWinners;
    tournamentInfo.hashKey = _hashKey;

    // reward
    address ownerOfFistBest = TRVBPWarrior.getOwnerOf(TRVBP_ADDRESSES, _firstWinner);
    address ownerOfSecondBest = TRVBPWarrior.getOwnerOf(TRVBP_ADDRESSES, _secondWinner);
    IWETH(WETH_ADDRESS).transfer(ownerOfFistBest, (tournamentInfo.prize_pool * 700) / 1000); // 70%
    IWETH(WETH_ADDRESS).transfer(ownerOfSecondBest, (tournamentInfo.prize_pool * 275) / 1000); // 27.5%
    platformShare += (tournamentInfo.prize_pool * 25) / 1000;
    tournamentInfo.prize_pool = 0;

    // update warrior statistic data
    (, uint256 _class) = getClass(_tournamentId);
    TRVBPWarrior.updateCompletedStatistic(_firstWinner, _secondWinner, tournamentInfo.warriors, CLASSES(_class) == CLASSES.BLOODING);
    TRVBPWarrior.updatePoints(_firstWinner, _secondWinner, _fourthWinners);

    // emit event
    emit SetWinners(_tournamentId, _firstWinner, _secondWinner);
  }

  // utility

  // verified
  function canChangeValue(uint256 _start, uint256 _end) public view virtual override returns (bool) {
    for (uint256 i = _start; i <= _end; i++) {
      // if tournament not available or exists player joined will can not change size and fee
      if (tournaments[i].state != TournamentState.AVAILABLE || tournaments[i].warriors.length > 0) {
        return false;
      }
    }
    return true;
  }

  // verified
  function getTournamentsByReady() public view returns (TournamentInfo[] memory) {
    uint256 size = tournamentsByReady.ids.length;
    TournamentInfo[] memory tournamentsInfo = new TournamentInfo[](size);
    for (uint256 i = 0; i < size; i++) {
      (tournamentsInfo[i], , , ) = getTournamentDetail(tournamentsByReady.ids[i]);
    }
    return tournamentsInfo;
  }

  // verified
  function getTournaments(uint256 _start, uint256 _end)
    public
    view
    returns (
      TournamentInfo[] memory,
      uint256[] memory,
      uint256[] memory,
      uint256[] memory
    )
  {
    uint256 size = _end - _start + 1;
    TournamentInfo[] memory tournamentsInfo = new TournamentInfo[](size);
    uint256[] memory sizeList = new uint256[](size);
    uint256[] memory feeList = new uint256[](size);
    uint256[] memory classList = new uint256[](size);
    for (uint256 i = _start; i <= _end; i++) {
      (tournamentsInfo[i], sizeList[i], feeList[i], classList[i]) = getTournamentDetail(i);
    }
    return (tournamentsInfo, sizeList, feeList, classList);
  }

  // verified
  function getTournamentsByState(
    uint256 _start,
    uint256 _end,
    TournamentState _state
  ) public view returns (TournamentInfo[] memory) {
    uint256 size = _end - _start + 1;
    TournamentInfo[] memory tournamentsInfo = new TournamentInfo[](size);
    for (uint256 i = _start; i <= _end; i++) {
      if (tournaments[i].state == _state) {
        (tournamentsInfo[i], , , ) = getTournamentDetail(i);
      }
    }
    return tournamentsInfo;
  }

  function getTournamentByIds(uint256[] calldata _ids)
    public
    view
    returns (
      TournamentInfo[] memory,
      uint256[] memory,
      uint256[] memory,
      uint256[] memory
    )
  {
    uint256 size = _ids.length;
    TournamentInfo[] memory tournamentsInfo = new TournamentInfo[](size);
    uint256[] memory sizeList = new uint256[](size);
    uint256[] memory feeList = new uint256[](size);
    uint256[] memory classList = new uint256[](size);
    for (uint256 i = 0; i < size; i++) {
      (tournamentsInfo[i], sizeList[i], feeList[i], classList[i]) = getTournamentDetail(_ids[i]);
    }
    return (tournamentsInfo, sizeList, feeList, classList);
  }

  function getTournamentConfigs(uint256 _start, uint256 _end)
    public
    view
    returns (
      uint256[] memory,
      uint256[] memory,
      uint256[] memory
    )
  {
    uint256 size = _end - _start + 1;
    uint256[] memory sizeList = new uint256[](size);
    uint256[] memory feeList = new uint256[](size);
    uint256[] memory classList = new uint256[](size);
    for (uint256 i = _start; i <= _end; i++) {
      (, sizeList[i], feeList[i], classList[i]) = getTournamentDetail(i);
    }
    return (sizeList, feeList, classList);
  }

  // verified
  function getTournamentDetail(uint256 _tournamentId)
    public
    view
    returns (
      TournamentInfo memory,
      uint256 size,
      uint256 fee,
      uint256 class
    )
  {
    // size, fee
    (, size) = getSize(_tournamentId);
    (, fee) = getFee(_tournamentId);
    (, class) = getClass(_tournamentId);
    return (tournaments[_tournamentId], size, fee, class);
  }

  // done
  function withdrawFees() external onlyOwner {
    // withdraw WETH
    uint256 balance = platformShare;
    platformShare = 0;
    IWETH(WETH_ADDRESS).transfer(TREASURY_ADDRESS, balance);
  }

  // done
  function withdraw() external onlyOwner {
    // withdraw matic
    uint256 balance = address(this).balance;
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

    constructor() {
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
pragma solidity ^0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Stores, RoleHelper } from "./Libs.sol";

abstract contract AdminControl is Ownable {
  using Stores for Stores.Store;
  using RoleHelper for RoleHelper.Roles;

  enum CLASSES {
    BLOODING,
    CLASS_3,
    CLASS_2,
    CLASS_1,
    BLOODBATH
  }

  // contracts
  address[] public TRVBP_ADDRESSES;
  address public WETH_ADDRESS = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
  address public TREASURY_ADDRESS = 0x909680a5E46a3401D4dD75148B61E129451fa266;

  // roles
  bytes32 public constant SET_SIZE_ROLE = keccak256("SET_SIZE_ROLE");
  bytes32 public constant SET_FEE_ROLE = keccak256("SET_FEE_ROLE");
  bytes32 public constant SET_MAX_FIGHT_ROLE = keccak256("SET_MAX_FIGHT_ROLE");
  bytes32 public constant SET_CLASS_ROLE = keccak256("SET_CLASS_ROLE");
  bytes32 public constant SET_WINNER_ROLE = keccak256("SET_WINNER_ROLE");
  bytes32 public constant CANCEL_ROLE = keccak256("CANCEL_ROLE");
  RoleHelper.Roles private roles;

  // stores
  Stores.Store public classTickets;
  Stores.Store public sizeTickets;
  Stores.Store public feeTickets;
  Stores.Store public maxFightingPerChampTickets;

  constructor() {
    TRVBP_ADDRESSES.push(0x4055e3503D1221Af4b187CF3B4aa8744332A4d0b);
  }

  modifier onlyRoler(bytes32 _role) {
    require(msg.sender == owner() || hasRole(_role, msg.sender), "Caller does not have permission");
    _;
  }

  /* EXTERNAL CONTRACTS */
  // verified
  function setTokenAddress(address[] calldata _tokens) external onlyOwner {
    TRVBP_ADDRESSES = _tokens;
  }

  // verified
  function addTokenAddress(address[] calldata _tokens) external onlyOwner {
    for (uint16 i = 0; i < _tokens.length; i++) {
      TRVBP_ADDRESSES.push(_tokens[i]);
    }
  }

  function setWethAddress(address _weth) external onlyOwner {
    WETH_ADDRESS = _weth;
  }

  /* ROLES */
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

  /* CONFIGS */
  function canChangeValue(uint256 _start, uint256 _end) public view virtual returns (bool);

  // verified
  function setMaxFightingPerChamp(
    uint256 _start,
    uint256 _end,
    uint256 _count
  ) public onlyRoler(SET_MAX_FIGHT_ROLE) {
    require(_end >= _start, "Input invalid.");
    require(_start <= maxFightingPerChampTickets.currentEnd + 1, "Value not continuous.");

    maxFightingPerChampTickets.addTicket(_start, _end, _count);
  }

  // verified
  function getMaxFightingPerChamp(uint256 _championId) public view returns (uint256) {
    (bool success, uint256 index) = maxFightingPerChampTickets.findTicket(_championId);
    if (!success) {
      return 0;
    }
    return maxFightingPerChampTickets.getValue(index);
  }

  // verified
  function setSize(
    uint256 _start,
    uint256 _end,
    uint256 _size
  ) public onlyRoler(SET_SIZE_ROLE) {
    require(_end >= _start, "Input invalid.");
    require(_start <= sizeTickets.currentEnd + 1, "Value not continuous.");
    require(_size > 0, "Value invalid.");
    if (_start < sizeTickets.currentEnd + 1) {
      require(canChangeValue(_start, _end), "Tournament can not be changed.");
    }

    sizeTickets.addTicket(_start, _end, _size);
  }

  // verified
  function getSize(uint256 _tournamentId) public view returns (bool, uint256) {
    (bool success, uint256 index) = sizeTickets.findTicket(_tournamentId);
    if (!success) {
      return (false, 0);
    }
    return (true, sizeTickets.getValue(index));
  }

  // verified
  function setFee(
    uint256 _start,
    uint256 _end,
    uint256 _fee
  ) public onlyRoler(SET_FEE_ROLE) {
    require(_end >= _start, "Input invalid.");
    require(_start <= feeTickets.currentEnd + 1, "Value not continuous.");
    if (_start < feeTickets.currentEnd + 1) {
      require(canChangeValue(_start, _end), "Tournament can not be changed.");
    }

    feeTickets.addTicket(_start, _end, _fee);
  }

  // verified
  function getFee(uint256 _tournamentId) public view returns (bool, uint256) {
    (bool success, uint256 index) = feeTickets.findTicket(_tournamentId);
    if (!success) {
      return (false, 0);
    }
    return (true, feeTickets.getValue(index));
  }

  function setClass(
    uint256 _start,
    uint256 _end,
    CLASSES _class
  ) public onlyRoler(SET_CLASS_ROLE) {
    require(_end >= _start, "Input invalid.");
    require(_start <= classTickets.currentEnd + 1, "Value not continuous.");
    if (_start < classTickets.currentEnd + 1) {
      require(canChangeValue(_start, _end), "Tournament can not be changed.");
    }

    classTickets.addTicket(_start, _end, uint256(_class));
  }

  // verified
  function getClass(uint256 _tournamentId) public view returns (bool, uint256) {
    (bool success, uint256 index) = classTickets.findTicket(_tournamentId);
    if (!success) {
      return (false, 0);
    }
    return (true, classTickets.getValue(index));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Map, Guard } from "./Libs.sol";
import { ITRVBPToken } from "./Interfaces.sol";

contract TRVBPWarrior {
  using Map for Map.Record;

  struct Warrior {
    uint256 id;
    uint16 style;
  }

  struct WarriorRecord {
    Map.Record records;
    uint256 firstWins;
    uint256 secondWins;
    uint256 losses;
    uint256 bloodingWins;
    uint256 bloodingCount;
    uint256 fightingCount;
    uint256 fought;
    uint256 points;
  }

  uint8 public constant MIN_POINT = 1;
  mapping(uint256 => WarriorRecord) internal warriorRecords;

  // fought count, points, blooding count, blooding wins count, wins count
  function(uint256, uint256, uint256, uint256, uint256) internal pure returns (bool)[5] classGuards = [Guard.blooding, Guard.class3, Guard.class2, Guard.class1, Guard.bloodbath];

  function eligibleClass(uint8 _class, uint256 _warriorId) public view returns (bool) {
    uint256 fought = warriorRecords[_warriorId].fought;
    uint256 points = warriorRecords[_warriorId].points;
    uint256 bloodingCount = warriorRecords[_warriorId].bloodingCount;
    uint256 bloodingWins = warriorRecords[_warriorId].bloodingWins;
    uint256 wins = warriorRecords[_warriorId].firstWins + warriorRecords[_warriorId].secondWins;
    return classGuards[_class](fought, points, bloodingCount, bloodingWins, wins);
  }

  function checkJoinable(
    uint256 _tournamentId,
    uint256 _warriorId,
    uint256 _maxFight,
    uint8 _class
  ) internal view {
    // one champion can not join exceed max fighting
    require(warriorRecords[_warriorId].fightingCount + 1 <= _maxFight, "Exceed max fighting");
    // one champion can not join again
    require(!warriorRecords[_warriorId].records.containsValue(_tournamentId), "Already joined");
    // must pass guard
    require(eligibleClass(_class, _warriorId), "Not eligible");
  }

  function getOriginalPoints(uint256 _warriorId) internal pure returns (uint16) {
    if (_warriorId < 5000) return 80;
    if (_warriorId >= 5000 && _warriorId < 11000) return 75;
    return 70;
  }

  function getOwnerOf(address[] memory _tokens, uint256 _warriorId) internal view returns (address) {
    if (_warriorId < 5000) {
      return ITRVBPToken(_tokens[0]).ownerOf(_warriorId);
    }
    return ITRVBPToken(_tokens[1]).ownerOf(_warriorId);
  }

  function checkWinners(
    uint256 _tournamentId,
    uint256 _firstWinner,
    uint256 _secondWinner,
    uint256[] memory _thirdWinners,
    uint256[] memory _fourthWinners
  ) internal view {
    require(warriorRecords[_firstWinner].records.containsValue(_tournamentId), "First winner mismatch tournament");
    require(warriorRecords[_secondWinner].records.containsValue(_tournamentId), "Second winner mismatch tournament");
    for (uint16 i = 0; i < _thirdWinners.length; i++) {
      require(warriorRecords[_thirdWinners[i]].records.containsValue(_tournamentId), "Third winners mismatch tournament");
    }
    for (uint16 i = 0; i < _fourthWinners.length; i++) {
      require(warriorRecords[_fourthWinners[i]].records.containsValue(_tournamentId), "Fourth winners mismatch tournament");
    }
  }

  function updateJoinedStatistic(uint256 _tournamentId, uint256 _warriorId) internal {
    warriorRecords[_warriorId].records.addValue(_tournamentId);
    warriorRecords[_warriorId].fightingCount++; // increase fighting count
  }

  function updateCancelledStatistic(uint256 _tournamentId, uint256 _warriorId) internal {
    warriorRecords[_warriorId].records.removeValue(_tournamentId);
    if (warriorRecords[_warriorId].fightingCount > 0) {
      warriorRecords[_warriorId].fightingCount--; // descrease fighting count
    }
  }

  function updateCompletedStatistic(
    uint256 _firstWinner,
    uint256 _secondWinner,
    Warrior[] memory _warriors,
    bool _isBloodingClass
  ) internal {
    // increase wins count
    warriorRecords[_firstWinner].firstWins++;
    warriorRecords[_secondWinner].secondWins++;

    // increase blooding wins count
    if (_isBloodingClass) {
      warriorRecords[_firstWinner].bloodingWins++;
      warriorRecords[_secondWinner].bloodingWins++;
    }

    uint256 warriorSize = _warriors.length;
    for (uint256 i = 0; i < warriorSize; i++) {
      if (_isBloodingClass) {
        warriorRecords[_warriors[i].id].bloodingCount++;
      }

      warriorRecords[_warriors[i].id].fought++;

      if (warriorRecords[_warriors[i].id].fightingCount > 0) {
        warriorRecords[_warriors[i].id].fightingCount--; // descrease fighting count
      }
      if (_warriors[i].id != _firstWinner && _warriors[i].id != _secondWinner) {
        warriorRecords[_warriors[i].id].losses++;
      }
    }
  }

  function updatePoints(
    uint256 _firstWinner,
    uint256 _secondWinner,
    uint256[] memory _fourthWinners
  ) internal {
    if (warriorRecords[_firstWinner].points == 0) {
      // = 0 means null
      warriorRecords[_firstWinner].points = getOriginalPoints(_firstWinner) + MIN_POINT + 3;
    } else {
      warriorRecords[_firstWinner].points += 3;
    }

    if (warriorRecords[_secondWinner].points == 0) {
      // = 0 means null
      warriorRecords[_secondWinner].points = getOriginalPoints(_secondWinner) + MIN_POINT + 2;
    } else {
      warriorRecords[_secondWinner].points += 2;
    }

    for (uint256 i = 0; i < _fourthWinners.length; i++) {
      if (warriorRecords[_fourthWinners[i]].points == 0) {
        warriorRecords[_fourthWinners[i]].points = getOriginalPoints(_fourthWinners[i]) + MIN_POINT - 1;
      } else if (warriorRecords[_fourthWinners[i]].points > MIN_POINT) {
        // min will be 1 so need to greater than or equal 2
        warriorRecords[_fourthWinners[i]].points--;
      }
    }
  }

  function getWarriorRecords(uint256 _warriorId)
    public
    view
    returns (
      uint256 matches,
      uint256[] memory tournamentIds,
      uint256 firstWins,
      uint256 secondWins,
      uint256 losses,
      uint256 bloodingWins,
      uint256 bloodingCount,
      uint256 fightingCount,
      uint256 fought,
      uint256 points
    )
  {
    matches = warriorRecords[_warriorId].records.ids.length;
    tournamentIds = warriorRecords[_warriorId].records.ids;
    firstWins = warriorRecords[_warriorId].firstWins;
    secondWins = warriorRecords[_warriorId].secondWins;
    losses = warriorRecords[_warriorId].losses;
    fightingCount = warriorRecords[_warriorId].fightingCount;
    fought = warriorRecords[_warriorId].fought;
    if (warriorRecords[_warriorId].points == 0) {
      points = getOriginalPoints(_warriorId);
    } else {
      points = warriorRecords[_warriorId].points - 1;
    }
    bloodingWins = warriorRecords[_warriorId].bloodingWins;
    bloodingCount = warriorRecords[_warriorId].bloodingCount;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Map {
  struct Record {
    uint256[] ids;
    mapping(uint256 => uint256) indexes; // value to index
  }

  function addValue(Record storage _record, uint256 _value) internal {
    if (_record.indexes[_value] != 0) return; // already exists
    _record.ids.push(_value);
    _record.indexes[_value] = _record.ids.length;
  }

  function removeValue(Record storage _record, uint256 _value) internal {
    uint256 valueIndex = _record.indexes[_value];
    if (valueIndex == 0) return; // removed not exists value
    uint256 toDeleteIndex = valueIndex - 1; // when add we not sub for 1 so now must sub 1 (for not out of bound)
    uint256 lastIndex = _record.ids.length - 1;
    if (lastIndex != toDeleteIndex) {
      uint256 lastvalue = _record.ids[lastIndex];
      _record.ids[toDeleteIndex] = lastvalue;
      _record.indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
    }
    _record.ids.pop();
    _record.indexes[_value] = 0; // set to 0
  }

  function containsValue(Record storage _record, uint256 _value) internal view returns (bool) {
    return _record.indexes[_value] != 0;
  }
}

library RoleHelper {
  struct RoleData {
    mapping(address => bool) members;
    bytes32 role;
  }

  struct Roles {
    mapping(bytes32 => RoleData) roles;
  }

  function hasRole(
    Roles storage _roles,
    bytes32 _role,
    address _account
  ) internal view returns (bool) {
    return _roles.roles[_role].members[_account];
  }

  function setupRole(
    Roles storage _roles,
    bytes32 _role,
    address _account
  ) internal {
    if (!hasRole(_roles, _role, _account)) {
      _roles.roles[_role].members[_account] = true;
    }
  }

  function revokeRole(
    Roles storage _roles,
    bytes32 _role,
    address _account
  ) internal {
    if (hasRole(_roles, _role, _account)) {
      _roles.roles[_role].members[_account] = false;
    }
  }
}

library Stores {
  struct Ticket {
    uint256 startIdx;
    uint256 endIdx;
    uint256 value;
  }

  struct Store {
    uint256 currentEnd;
    Ticket[] values;
  }

  function addTicket(
    Store storage _store,
    uint256 _start,
    uint256 _end,
    uint256 _value
  ) internal {
    _store.values.push(Ticket(_start, _end, _value));
    _store.currentEnd = max(_store.currentEnd, _end);
  }

  function findTicket(Store storage _store, uint256 _element) internal view returns (bool, uint256) {
    uint256 len = _store.values.length;

    for (uint256 i = len; i > 0; i--) {
      Ticket memory ticket = _store.values[i - 1];
      if (ticket.startIdx <= _element && ticket.endIdx >= _element) {
        // finding first element match
        return (true, i - 1);
      }
    }
    return (false, 0);
  }

  function getValue(Store storage _store, uint256 _index) internal view returns (uint256) {
    return _store.values[_index].value;
  }

  /**
   * @dev Returns the largest of two numbers.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }
}

library Guard {
  function blooding(
    uint256,
    uint256,
    uint256,
    uint256,
    uint256 _wins
  ) internal pure returns (bool) {
    return _wins == 0;
  }

  function class3(
    uint256 _foughtCount,
    uint256 _points,
    uint256,
    uint256 _bloodingWins,
    uint256
  ) internal pure returns (bool) {
    return (_foughtCount >= 5 || _bloodingWins >= 1) && (_points < 80);
  }

  function class2(
    uint256 _foughtCount,
    uint256 _points,
    uint256,
    uint256 _bloodingWins,
    uint256
  ) internal pure returns (bool) {
    return (_foughtCount >= 5 || _bloodingWins >= 1) && (_points >= 80 && _points <= 100);
  }

  function class1(
    uint256 _foughtCount,
    uint256 _points,
    uint256,
    uint256 _bloodingWins,
    uint256
  ) internal pure returns (bool) {
    return (_foughtCount >= 5 || _bloodingWins >= 1) && (_points > 100);
  }

  function bloodbath(
    uint256,
    uint256,
    uint256 _bloodingCount,
    uint256 _bloodingWins,
    uint256
  ) internal pure returns (bool) {
    return (_bloodingCount >= 5) || (_bloodingWins >= 1);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IWETH {
  function allowance(address owner, address spender) external view returns (uint256);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function transfer(address recipient, uint256 amount) external returns (bool);
}

interface ITRVBPToken {
  function ownerOf(uint256 tokenId) external view returns (address owner);
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