// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @dev ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721
{

  /**
   * @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
   * created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
   * number of NFTs may be created and assigned without emitting Transfer. At the time of any
   * transfer, the approved address for that NFT (if any) is reset to none.
   */
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
   * address indicates there is no approved address. When a Transfer event emits, this also
   * indicates that the approved address for that NFT (if any) is reset to none.
   */
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
   * all NFTs of the owner.
   */
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT.
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they may be permanently lost.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Set or reaffirm the approved address for an NFT.
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @param _approved The new approved NFT controller.
   * @param _tokenId The NFT to approve.
   */
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets. It also emits the ApprovalForAll event.
   * @notice The contract MUST allow multiple operators per owner.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @param _owner Address for whom to query the balance.
   * @return Balance of _owner.
   */
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to the zero address are
   * considered invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   * @return Address of _tokenId owner.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @dev Get the approved address for a single NFT.
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId The NFT to find the approved address for.
   * @return Address that _tokenId is approved for.
   */
  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @dev Returns true if `_operator` is an approved operator for `_owner`, false otherwise.
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   * @return True if approved for all, false otherwise.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

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
pragma solidity 0.8.0;

import "./0-context.sol";

/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code at:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */
contract Ownable is Context
{

  /**
   * @dev Error constants.
   */
  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  /**
   * @dev Current owner address.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    public
    virtual
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface AdventureTypes {
  struct Monster {
    uint256 id;
    AdventureTypes.PetClass cl;
    uint256 map;
    uint256 power;
    bool active;
  }
  
  enum PetClass {
    TEAL,
    SILVER,
    BURGUNDY,
    BLOND,
    PURPLE
  }
    
  struct Pet {
    uint256 id;
    uint256 level;
    uint256 hp;
    uint256 mp;
    uint256 st;
    uint256 ag;
    uint256 it;
    PetClass cl;
  }
}

interface IWheel {
  function isWin(AdventureTypes.Pet memory pet, AdventureTypes.Monster memory monster, uint256 exp, IPetNft petNft) external returns(bool);
}

interface IPetNft {
  function balanceOf(address account) external view returns (uint256);
  function pets(uint256 petId) external view returns (AdventureTypes.Pet memory);
  function ownerOf(uint256 petId) external view returns (address);
  function PET_PRICES(uint256 level) external view returns (uint256);
  function createdTokenCount() external view returns (uint256);
  function buyWithHigherRate(uint256 level, uint256 quantity) external;
  
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  function adventureMint(
    uint256 level,
    uint256 quantity
  )
    external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./0-context.sol";
import "./0-ownable.sol";
import "./0-ierc20.sol";
import "./0-erc721.sol";
import "./9-adventure-type.sol";
import "./9-blacklister.sol";

contract AdventureHook is Ownable {
  function beforeBuy(address sender, uint256 level, uint256 quantity) external view {}
  
  function withdrawMatic() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function withdrawToken(uint256 amount, IERC20 erc20) public onlyOwner {
    erc20.transfer(owner, amount);
  }
}

contract Adventure is Ownable {
  IPetNft petNft;
  IERC20 erc20Token;
  IWheel wheel;
  Blacklister public blacklister;

  constructor(
    IPetNft _petNft,
    IERC20 _erc20Token,
    IWheel _wheel,
    Blacklister _blacklister
  ) {
    petNft = _petNft;
    erc20Token = _erc20Token;
    wheel = _wheel;
    blacklister = _blacklister;
    startAt = block.timestamp;
  }

  function setBlacklister(Blacklister _blacklister) public onlyOwner {
    blacklister = _blacklister;
  }

  function setWheel(IWheel _wheel) public onlyOwner {
    wheel = _wheel;
  }

  mapping(uint256 => AdventureTypes.Monster) public monsters;

  uint256 public monsterCount = 0;

  function updateMonster(AdventureTypes.Monster memory monster) public onlyOwner {
    require(monster.id < monsterCount, "MONSTER_NOT_FOUND");
    monsters[monster.id] = monster;
  }

  function createMonster(AdventureTypes.Monster memory monster) public onlyOwner {
    monster.id = monsterCount;
    monsters[monsterCount] = monster;
    monsterCount++;
  }

  function createMonsters(AdventureTypes.Monster[] memory _monsters) public onlyOwner {
    for (uint256 index = 0; index < _monsters.length; index++) {
      createMonster(_monsters[index]);
    }
  }
  
  struct DetailedMonster {
    uint256 id;
    AdventureTypes.PetClass cl;
    uint256 map;
    uint256 power;
    bool active;
    uint256 fightCount;
  }

  function getMonsters() public view returns(DetailedMonster[] memory result) {
    uint256 length = monsterCount;
    result = new DetailedMonster[](length);
    for (uint256 index = 0; index < length; index++) {
      AdventureTypes.Monster memory monster = monsters[index];
      result[index] = DetailedMonster({
        id: monster.id,
        cl: monster.cl,
        map: monster.map,
        active: monster.active,
        power: monster.power,
        fightCount: getMonsterFight(monster)
      });
    }
    return result;
  }

  mapping(uint256 => uint256) public exps;
  
  function max(uint256 a, uint256 b) private pure returns(uint256) {
    return a > b ? a : b;
  }

  function min(uint256 a, uint256 b) private pure returns(uint256) {
    return a < b ? a : b;
  }

  uint256 public MAX_EXP = 100;

  function getExp(uint256 petId) public view returns(uint256) {
    return exps[petId];
  }

  function increaseExp(uint256 petId) internal {
    exps[petId] = min(exps[petId] + 1, MAX_EXP);
  }

  uint256 public MIN_EXP = 0;

  function decreaseExp(uint256 petId) internal {
    if (exps[petId] == MIN_EXP) return;
    exps[petId] = exps[petId] - 1;
  }

  struct AdventurePet {
    uint256 id;
    uint256 fightCount;
    uint256 exp;
  }
  
  function getAdventurePets(uint256[] memory ids) public view returns(AdventurePet[] memory result) {
    uint256 length = ids.length;
    result = new AdventurePet[](length);
    for (uint256 index = 0; index < length; index++) {
      uint256 id = ids[index];
      result[index] = AdventurePet({
        id: id,
        exp: getExp(id),
        fightCount: getPetFight(id)
      });
    }
  }

  function getNumberOfDays() public view returns(uint256) {
    uint256 ONE_DAY = 86400;
    return getNow() / ONE_DAY;
  }
  
  uint256 public monsterFightLimitPerDay = 1000000000000;
  uint256 public petFightLimitPerDay = 5;

  function setDailyLimits(uint256 _monsterFightLimitPerDay, uint256 _petFightLimitPerDay) public onlyOwner {
    monsterFightLimitPerDay = _monsterFightLimitPerDay;
    petFightLimitPerDay = _petFightLimitPerDay;
  }

  mapping(uint256 => mapping(uint256 => uint256)) public monsterFightsByDay;
  mapping(uint256 => mapping(uint256 => uint256)) public petFightsByDay;

  function getPetFight(uint256 petId) public virtual view returns(uint256) {
    return petFightsByDay[getNumberOfDays()][petId];
  }

  function getMonsterFight(AdventureTypes.Monster memory monster) public view returns(uint256) {
    return monsterFightsByDay[getNumberOfDays()][monster.id];
  }

  function increaseMonsterFight(AdventureTypes.Monster memory monster) internal {
    monsterFightsByDay[getNumberOfDays()][monster.id]++;
  }
  
  function increasePetFight(AdventureTypes.Pet memory pet) internal {
    petFightsByDay[getNumberOfDays()][pet.id]++;
  }

  function ensureMonsterIsFightable(AdventureTypes.Monster memory monster) internal view {
    require(monsterFightLimitPerDay > getMonsterFight(monster), "MONSTER_EXHAUSTED");
    require(monster.active, "MONSTER_INACTIVE");
  }

  function ensurePetIsFightable(AdventureTypes.Pet memory pet) public virtual view {
    require(petFightLimitPerDay > getPetFight(pet.id), "PET_EXHAUSTED");
  }
  
  uint256 public MAX_PET_COUNT = 1000;
  
  function setMaxPetCount(uint256 maxPetCount) public onlyOwner {
    MAX_PET_COUNT = maxPetCount;
  }
  
  function ensureAccountFightable() internal view {
    require(petNft.balanceOf(_msgSender()) < MAX_PET_COUNT, "OWN_TOO_MANY_PETS");
  }
  
  function getPet(uint256 petId) public view returns(AdventureTypes.Pet memory) {
    return petNft.pets(petId);
  }

  function ensureUserOwnsPet(AdventureTypes.Pet memory pet) internal view {
    require (petNft.ownerOf(pet.id) == _msgSender(), "ONLY_PET_OWNER");
  }

  mapping(uint256 => uint256) public rateByFightCounts;
  
  uint256 public BASE_PRIZE_RATE = 1500; // 1.5%
  uint256 public REPEAT_AFTER = 500;
  uint256 public REDUCE_EACH_TIME = 100000; // 1 / 100000 = 0.001%

  function setPrizeConfig(uint256 newBasePrizeRate, uint256 newRepeatAfter, uint256 newReduceEachTime) public onlyOwner {
    BASE_PRIZE_RATE = newBasePrizeRate;
    REPEAT_AFTER = newRepeatAfter;
    REDUCE_EACH_TIME = newReduceEachTime;
  }

  function buildRates(uint256 from, uint256 to) public onlyOwner {
    uint256 base = BASE_PRIZE_RATE;
    for (uint256 fightCount = from; fightCount <= to; fightCount++) {
      if (fightCount == 0) {
        rateByFightCounts[0] = base;
        continue;
      }

      uint256 prev = rateByFightCounts[fightCount - 1];
      require(prev != 0, "INVALID_STEP");
      rateByFightCounts[fightCount] = prev * (REDUCE_EACH_TIME - 1) / REDUCE_EACH_TIME;
    }
  }

  function getRateByFightCount(uint256 fightCount) public view returns(uint256) {
    return rateByFightCounts[fightCount % REPEAT_AFTER];
  }

  function getPetPower(AdventureTypes.Pet memory pet, AdventureTypes.Monster memory monster) public view returns(uint256) {
    uint256 price = petNft.PET_PRICES(pet.level);
    uint256 basePoint = price * (pet.hp + pet.mp + pet.st + pet.ag + pet.it) / 100;
    uint256 pointWithMonster = pet.cl == monster.cl ? basePoint * 115 / 100 : basePoint * 85 / 100;
    uint256 exp = getExp(pet.id);
    return pointWithMonster + exp / 10;
  }

  uint256 public PRIZE_RATE = 100;
  
  function setPrizeRate(uint256 prizeRate) public onlyOwner {
    PRIZE_RATE = prizeRate;
  }

  function getPrize(AdventureTypes.Monster memory monster) public view returns(uint256) {
    uint256 fightCount = getMonsterFight(monster);
    return monster.power * getRateByFightCount(fightCount) * PRIZE_RATE / 100 / 100000;
  }

  function isContract(address account) internal view returns (bool) {
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly { codehash := extcodehash(account) }
    return (codehash != accountHash && codehash != 0x0);
  }
  
  uint256 public FIGHT_FEE = 0 ether;

  function setFightFee(uint256 fightFee) public onlyOwner {
    FIGHT_FEE = fightFee;
  }

  function fight(uint256 petId, uint256 monsterId) public {
    require(!isContract(_msgSender()), "PREVENT_CONTRACT_CALL");
    if (FIGHT_FEE != 0) {
      erc20Token.transferFrom(_msgSender(), address(this), FIGHT_FEE);
    }
    ensureAccountFightable();

    AdventureTypes.Pet memory pet = getPet(petId);
    AdventureTypes.Monster memory monster = monsters[monsterId];

    ensurePetIsFightable(pet);
    ensureMonsterIsFightable(monster);
    ensureUserOwnsPet(pet);
    wheel.isWin(pet, monster, getExp(petId), petNft) ? onWin(pet, monster) : onLose(pet, monster);
    increasePetFight(pet);
    increaseMonsterFight(monster);
  }

  event Win(address account, uint256 petId, uint256 monsterId, uint256 prize);
  
  function onWin(AdventureTypes.Pet memory pet, AdventureTypes.Monster memory monster) internal {
    uint256 prize = getPrize(monster);
    rewards[_msgSender()] += prize;
    emit Win(_msgSender(), pet.id, monster.id, prize);
    increaseExp(pet.id);
  }

  event Lose(address account, uint256 petId, uint256 monsterId);
  function onLose(AdventureTypes.Pet memory pet, AdventureTypes.Monster memory monster) internal {
    emit Lose(_msgSender(), pet.id, monster.id);
    decreaseExp(pet.id);
  }

  function ownerWithdrawMatic() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function ownerWithdrawToken(uint256 amount, IERC20 erc20) public onlyOwner {
    erc20.transfer(owner, amount);
  }

  mapping(address => uint256) public rewards;
  mapping(address => uint256) public lastWithdrawAts;
  uint256 startAt;

  function getDaysFromLastWithdraw(address account) public virtual view returns(uint256) {
    uint256 lastWithdrawAt = lastWithdrawAts[account];
    uint256 normalizedLastWithdrawAt = lastWithdrawAt == 0 ? startAt : lastWithdrawAt;
    if (getNow() == normalizedLastWithdrawAt) return 0;
    return (getNow() - normalizedLastWithdrawAt) / 86400;
  }

  uint256 public skippedTime = 0;

  function skipMilis(uint256 milis) public {
    skippedTime += milis;
  }

  function getNow() public view returns(uint256) {
    return skippedTime + block.timestamp;
  }
  /*
  function getNow() public view returns(uint256) {
    return block.timestamp;
  }
  */

  uint256 public MIN_DAYS_BETWEEN_WITHDRAWS = 1;
  uint256 public WITHDRAW_FEE = 15;
  uint256 public SKIP_WITHDRAW_FEE_DAYS = 5;
  uint256 public WITHDRAW_PERCENTAGE_EACH_TIME = 10;

  function setWithdrawValues(uint256 _MIN_DAYS_BETWEEN_WITHDRAWS, uint256 _WITHDRAW_FEE, uint256 _SKIP_WITHDRAW_FEE_DAYS, uint256 _WITHDRAW_PERCENTAGE_EACH_TIME) public onlyOwner {
    MIN_DAYS_BETWEEN_WITHDRAWS = _MIN_DAYS_BETWEEN_WITHDRAWS;
    WITHDRAW_FEE= _WITHDRAW_FEE;
    SKIP_WITHDRAW_FEE_DAYS = _SKIP_WITHDRAW_FEE_DAYS;
    WITHDRAW_PERCENTAGE_EACH_TIME = _WITHDRAW_PERCENTAGE_EACH_TIME;
  }

  event Withdraw(address account, uint256 value, uint256 feeRate);

  function getPendingReward(address account) public virtual view returns(uint256) {
    return rewards[account] - withdrewRewards[_msgSender()];
  }

  mapping(address => uint256) public withdrewRewards;

  function withdraw() public {
    require(getDaysFromLastWithdraw(_msgSender()) > 0, "WAIT_MORE");
    blacklister.ensureAccountNotInBlacklist(_msgSender());
    uint256 reward = getPendingReward(_msgSender());
    uint amount = reward * WITHDRAW_PERCENTAGE_EACH_TIME / 100;
    uint256 remain = amount * (100 - WITHDRAW_FEE) / 100;
    emit Withdraw(_msgSender(), remain, WITHDRAW_FEE);
    erc20Token.transfer(_msgSender(), remain);
    lastWithdrawAts[_msgSender()] = getNow();
    withdrewRewards[_msgSender()] += amount;
  }

  event BuyPetWithPending(address account, uint256 value);

  AdventureHook adventureHook;

  function setAdventureHook(AdventureHook _adventureHook) public onlyOwner {
    adventureHook = _adventureHook;
  }

  function buyPet(uint256 level, uint256 quantity) public {
    if (address(adventureHook) != address(0)) {
      adventureHook.beforeBuy(_msgSender(), level, quantity);
    }
    blacklister.ensureAccountNotInBlacklist(_msgSender());
    uint256 value = petNft.PET_PRICES(level) * quantity;
    require(value <= getPendingReward(_msgSender()), "PENDING_REWARD_NOT_ENOUGH");
    petNft.adventureMint(level, quantity);
    
    uint256 firstId = petNft.createdTokenCount();
    for (uint id = 1; id <= quantity; id++) {
      petNft.safeTransferFrom(address(this), _msgSender(), firstId + id);
    }
    withdrewRewards[_msgSender()] += value;
    emit BuyPetWithPending(_msgSender(), value);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./0-ownable.sol";
import "./0-ierc20.sol";

contract Blacklister is Ownable {

  mapping(address => bool) public accountBlackList;

  event AddAccountBlacklist(address account);

  function addAccountBackList(address[] memory accounts) public onlyOwner {
    uint256 length = accounts.length;
    for (uint256 index = 0; index < length; index++) {
      accountBlackList[accounts[index]] = true;
      emit AddAccountBlacklist(accounts[index]);
    }
  }

  event RemoveAccountBlacklist(address account);

  function removeAccountBlackList(address[] memory accounts) public onlyOwner {
    uint256 length = accounts.length;
    for (uint256 index = 0; index < length; index++) {
      accountBlackList[accounts[index]] = false;
      emit RemoveAccountBlacklist(accounts[index]);
    }
  }

  function ensureAccountNotInBlacklist(address account) public view {
    require(!accountBlackList[account], "BLACKLISTED");
  }

  mapping(uint256 => bool) public petBlackList;

  event AddPetBlacklist(uint256 id);

  function addPetBackList(uint256[] memory ids) public onlyOwner {
    uint256 length = ids.length;
    for (uint256 index = 0; index < length; index++) {
      petBlackList[ids[index]] = true;
      emit AddPetBlacklist(ids[index]);
    }
  }

  event RemovePetBlacklist(uint256 id);

  function removePetBlackList(uint256[] memory ids) public onlyOwner {
    uint256 length = ids.length;
    for (uint256 index = 0; index < length; index++) {
      petBlackList[ids[index]] = false;
      emit RemovePetBlacklist(ids[index]);
    }
  }

  function ensurePetNotInBlacklist(uint256 id) public view {
    require(!petBlackList[id], "BLACKLISTED");
  }

  function withdrawMatic() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function withdrawToken(uint256 amount, IERC20 erc20) public onlyOwner {
    erc20.transfer(owner, amount);
  }
}