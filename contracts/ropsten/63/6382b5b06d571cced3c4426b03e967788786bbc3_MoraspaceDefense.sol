pragma solidity ^0.4.24;

// File: contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: contracts/NameFilter.sol

library NameFilter {
  /**
    * @dev filters name strings
    * -makes sure it does not start/end with a space
    * -makes sure it does not contain multiple spaces in a row
    * -cannot be only numbers
    * -cannot start with 0x
    * -restricts characters to A-Z, a-z, 0-9, and space.
    * @return reprocessed string in bytes32 format
    */
  function nameFilter(string _input) internal pure returns (bytes32) {
    bytes memory _name = bytes(_input);
    require(_name.length <= 32 && _name.length > 0, "Name must be between 1 and 32 characters!");
    require(_name[0] != 0x20 && _name[_name.length-1] != 0x20, "Name cannot start neither end with spaces!");
    if (_name[0] == 0x30) {
      require(_name[1] != 0x78, "Name cannot start with 0x");
      require(_name[1] != 0x58, "Name cannot start with 0X");
    }
    bool _hasAlphaChar = false;
    byte c;
    for (uint8 i = 0; i < _name.length; ++i) {
      c = _name[i];
      //require(c==b, "c and b must be the same");
      //if uppercase A-Z OR lowercase a-z
      if ((c > 0x40 && c < 0x5b) || (c > 0x60 && c < 0x7b)) {
        if (_hasAlphaChar == false) _hasAlphaChar = true;
      } else {
        // require character is a space OR 0-9
        require (c == 0x20 || (c > 0x2f && c < 0x3a),
          "Name contains invalid characters. Other than A-Z, a-z, 0-9, and space."
        );
        // make sure theres not 2x spaces in a row
        if (c == 0x20 && i < (_name.length-2)) require( _name[i+1] != 0x20, "Name cannot contain consecutive spaces");
      }
    }
    require(_hasAlphaChar == true, "Name cannot be only numbers");
    bytes32 _ret;
    assembly { // https://ethereum.stackexchange.com/questions/9142/how-to-convert-a-string-to-bytes32
        _ret := mload(add(_name, 32))
    }
    return (_ret);
  }
}

// File: contracts/DataSets.sol

library DataSets {

  struct Rocket {
    uint8 accuracy; // percentag eg.: 50 => 50% stay statuc during the round.
    uint8 merit; // this amount of merit will be debited after each hits.
    uint8 knockback; //extend Round.mayFinish with knockack from hits.
    uint256 cost; // current rocket price cost. it varies during the round.
    uint256 launches; // number of launches in the current round.
    uint8 discount; // foreign key of discount.
  }

  struct Discount {
    bool valid; // the discount become offer if any of the feqture expire or run out.
    uint256 duration; // for time limited offer.
    uint256 qty; // for quantity limited offer.
    uint256 cost; // discount price.
    uint8 next; //when current discont expired can replaced by the next.
  }

  struct Launchpad {
    // size = 0  means out of use
    uint256 size; // batch size of how many rockets can be launched in one time.
  }

  struct PrizeDist {
    uint8 hero; // hero jackpot.
    uint8 bounty; // bounty pool.
    uint8 next; // next round pot.
    uint8 partners; // affiliate partners.
    uint8 moraspace; // contract owner.
  }

  struct Round {
    bool over; // true means game over.
    uint256 started; // static value of time stamp when the round started.
    uint256 duration; // statuc value of initial duration.
    uint256 mayImpactAt; // impact timestamp. can be knockback (increment) with hits before this time reached.
    uint256 merit; // total merit on the winner launchpads.
    uint256 jackpot; // jackpot amount eg.: 50% of the pot.
    uint256 bounty; // bounty for each merits on winning launchpad.
    address hero; // last hero.
    uint8 launchpad; // last launchpad.
  }

  struct Player {
    uint16 round; // last participated round.
    address addr; // ETH address of the player.
    uint32[] merit; // accumilated merits on each launchpads.
    uint256 earnings; // Withdrawable amount.
    uint256 updated; // last modified.
  }

  struct Hero {
    address addr;
    bytes32 name;
  }
}

// File: contracts/MoraspaceDefense.sol

/**
 * Owned contract
 */
contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner, "Only owner can do that!");
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner, "Only new owner can do that!");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}

/**
 * @title MoraspaceDefense contract implementation
 */
contract MoraspaceDefense is Owned {
  using SafeMath for *; // solity directive using A for B;
  using NameFilter for string;
  uint256 public pot = 0;
  DataSets.PrizeDist public prizeDist;
  mapping (uint8 => DataSets.Rocket) public rocketClass;
  mapping (uint8 => DataSets.Rocket) public rocketSupply;
  uint8 public rocketClasses;
  mapping (uint8 => DataSets.Discount) public discount;
  uint8 public discounts;
  mapping (uint8 => DataSets.Launchpad) public launchpad;
  uint8 public launchpads;
  mapping (uint16 => DataSets.Hero) public hero;
  mapping (uint16 => DataSets.Round) public round;
  uint16 public rounds;
  uint32[] public merit;
  mapping (uint256 => DataSets.Player) public player;
  address[] public playerDict;

  event potWithdraw(uint256 indexed _eth, address indexed _to);
  event roundStart(uint16 indexed _round, uint256 indexed _started, uint256 indexed _mayImpactAt);
  event roundFinish(uint16 indexed _round, uint256 indexed _jackpot, address indexed _hero);
  event rocketLaunch(uint8 indexed _hits, uint256 indexed _mayImpactAt);
  event roundHero(uint16 indexed _round, bytes32 indexed _name);

  /**
   * @dev allows things happen before the new round started
   */
  modifier onlyBeforeARound {
    require(round[rounds].over == true, "Sorry the round has begun!");
    _;
  }

  /**
   * @dev allows things happen before the new round started
   */
  modifier beforeNotTooLate {
    require(round[rounds].mayImpactAt > now, "Sorry it is too late!");
    _;
  }

  /**
   * @dev allows things happen only during the live round
   */
  modifier onlyLiveRound {
    require(round[rounds].over == false, "Sorry the new round has not started yet!");
    _;
  }

  /**
   * @dev prevents contracts from interacting with
   */
  modifier isHuman(address _addr) {
    uint256 _codeSize;
    assembly {_codeSize := extcodesize(_addr)}
    require(_codeSize == 0, "Sorry humans only!");
    _;
  }

  /**
   * @dev The constructor responsible to set and reset variables.
   * - initial settings can be modified later by owner
   * - mapping index starts with 1, 0 is used to terminate reference
   */
  constructor() public {
    round[0].over       = true;
    rounds              = 0;
// these settings can be done by additional transactions
// truffle develop can&#39;t migrate / test with heavy constructor
//    launchpad[1]        = DataSets.Launchpad(100);
//    launchpad[2]        = DataSets.Launchpad(100);
//    launchpad[3]        = DataSets.Launchpad(100);
//    launchpad[4]        = DataSets.Launchpad(100);
//    launchpads          = 4;
//    discount[1]         = DataSets.Discount(true, 604800, 0, 800000000000000, 0);
//    discounts           = 1;
//    rocketClass[1]      = DataSets.Rocket(100,  1,  30, 1000000000000000, 0, 1);
//    rocketClass[2]      = DataSets.Rocket( 75,  5,  60, 3000000000000000, 0, 0);
//    rocketClass[3]      = DataSets.Rocket( 50, 12, 120, 5000000000000000, 0, 0);
//    rocketClasses       = 3;
//    prizeDist.hero      = 50;
//    prizeDist.bounty    = 24;
//    prizeDist.next      = 11;
//    prizeDist.partners  = 10;
//    prizeDist.moraspace = 5;
//    player[0]           = DataSets.Player(0, address(0), new uint32[](0), 0, 0);
    playerDict.push(address(0));
  }

  /**
   * @dev creates, deletes and modifies launchpad
   */
  function prepareLaunchpad (
    uint8 _i,
    uint256 _size //0 means out of use
  ) external onlyOwner() onlyBeforeARound() {
    require(_i > 0  && _i <= launchpads + 1, "Index must be grater than 0 and lesser than number of items +1 !");
    require(!(_size == 0 && _i != launchpads), "You can remove only the last item.");
    launchpad[_i].size = _size;
    if (_size == 0) --launchpads;
    else if (_i == launchpads + 1) ++launchpads;
  }

  /**
   * @dev creates, deletes and modifies rocket classes before the round starts
   * - although it prevents set links to invalid discount, it allows to remove linked discounts
   */
  function adjustRocket(
    uint8 _i,
    uint8 _accuracy, //0 means removed
    uint8 _merit,
    uint8 _knockback,
    uint256 _cost,
    uint8 _discount // link to discount
  ) external onlyOwner() onlyBeforeARound() {
    require(_i > 0  && _i <= rocketClasses + 1, "Index must be grater than 0 and lesser than number of items +1 !");
    require(!(_accuracy == 0 && _i != rocketClasses), "You can remove only the last item!");
    require(_accuracy <= 100, "Maxumum accuracy is 100!");
    require(!(_discount > 0 && (_discount > discounts || !discount[_discount].valid)),
      "The linked discount must exists and need to be valid");
    rocketClass[_i].accuracy  = _accuracy;
    rocketClass[_i].merit     = _merit;
    rocketClass[_i].knockback = _knockback;
    rocketClass[_i].cost      = _cost;
    rocketClass[_i].discount  = _discount;
    if (_accuracy == 0) --rocketClasses;
    else if (_i == rocketClasses + 1) ++rocketClasses;
  }

  /**
   * @dev creates, deletes and modifies discount before the round starts
   * - although it prevents set links to invalid records, it allows to remove linked records
   */
  function prepareDiscount (
    uint8 _i,
    bool _valid, //false means removed
    uint256 _duration,
    uint256 _qty,
    uint256 _cost,
    uint8 _nextDiscount //when current discount expired can replaced by the next.
  ) external onlyOwner() onlyBeforeARound() {
    require(_i > 0  && _i <= discounts + 1, "Index must be grater than 0 and lesser than number of items +1 !");
    require(!(_valid == false && _i != discounts), "You can remove only the last item!");
    require(!(_nextDiscount > 0 && !discount[_nextDiscount].valid), "Invalid next discount!");
    discount[_i].valid    = _valid;
    discount[_i].duration = _duration;
    discount[_i].qty      = _qty;
    discount[_i].cost     = _cost;
    discount[_i].next     = _nextDiscount;
    if (_valid == false) --discounts;
    else if (_i == discounts + 1) ++discounts;
  }

  /**
   * @dev sets the pie chart distribution for the prize
   * - the partners and moraspace share is not implemented, all stays in the pod,
   *   what can be manually withdraw with potWithdrawTo()
   */
  function updatePrizeDist(
    uint8 _hero,
    uint8 _bounty,
    uint8 _next,
    uint8 _partners,
    uint8 _moraspace
  ) external onlyOwner() onlyBeforeARound() {
    require(_hero + _bounty + _next + _partners + _moraspace == 100,
      "O.o The sum of pie char should be around 100!");
    prizeDist.hero      = _hero;
    prizeDist.bounty    = _bounty;
    prizeDist.next      = _next;
    prizeDist.partners  = _partners;
    prizeDist.moraspace = _moraspace;
  }

  /**
   * @dev sets the prize or increments it
   */
  function () external payable {
    require(msg.value > 0, "The payment must be more than 0!");
    pot = pot.add(msg.value);
  }

  /**
   * @dev Withdraws from remaining pot and sends to given address
   */
  function potWithdrawTo(uint256 _eth, address _to) external onlyOwner() onlyBeforeARound() {
    require(_eth > 0, "The requested amount need to be explicit!");
    require(_eth <= pot, "Insufficient found!");
    require(_to != address(0), "Address can not be zero!");
    emit potWithdraw(_eth, _to);
    pot = pot.sub(_eth);
    _to.transfer(_eth);
  }

  /**
   * @dev start a new round
   */
  function start(uint256 _duration) external onlyOwner() onlyBeforeARound() {
    require(prizeDist.hero + prizeDist.bounty + prizeDist.next + prizeDist.partners + prizeDist.moraspace == 100,
      "O.o The sum of pie char should be around 100!");
    require(rocketClasses > 0, "No rockets in the game!");
    require(launchpads > 0, "No launchpads in the game!");
    //require(_duration > 59, "Round duration must be at least 1 minute!");
    for (uint8 i = 0; i <= rocketClasses; ++i) {
      rocketSupply[i] = rocketClass[i];
    }
    ++rounds;
    round[rounds].over      = false;
    round[rounds].duration  = _duration;
    round[rounds].started   = now;
    round[rounds].mayImpactAt = now.add(_duration);
    for (i = 0; i < launchpads; ++i) {
      if (i >= merit.length) merit.push(0);
      else merit[i]=0;
    }
    emit roundStart(rounds, round[rounds].started, round[rounds].mayImpactAt);
  }

  function getPlayerMerits(address _addr, uint256 _index) public view returns (uint32[]) {
    require(address(0) != _addr && _index < playerDict.length, "Player not found!");
    _index = findPlayerIndex(_addr, _index);
    require(_index > 0, "Player not found!");
    return player[_index].merit;
  }

  function findPlayerIndex(address _addr, uint256 _index) public view returns (uint256) {
    require(address(0) != _addr && _index < playerDict.length, "Player not found!");
    require(!(_index > 0 && _addr != playerDict[_index]), "Forbidden!");
    if (_index == 0) {
      for (uint i = 0; i < playerDict.length; i++) {
        if (playerDict[i]==_addr) {
          _index = i;
          break;
        }
      }
    }
    return _index;
  }

  function maintainPlayer(address _addr, uint256 _index) internal returns (uint256) {
    require(address(0) != _addr && _index < playerDict.length, "Player not found!");
    require(!(_index > 0 && _addr != playerDict[_index]), "Forbidden!");
    if (_index == 0) {
      _index = findPlayerIndex(_addr, _index);
      if (_index == 0) {
        player[_index] = DataSets.Player(0, address(0), new uint32[](0), 0, 0);
        _index = playerDict.push(_addr) - 1;
      }
    }
    DataSets.Player storage _p = player[_index];
    if (_p.updated == 0) { // new user
      _p.addr = _addr;
      _p.round = rounds;
      _p.updated = now;
      for (uint256 i = 0; i < launchpads; ++i) {
        _p.merit.push(0);
      }
    } else if (_p.round != rounds || round[rounds].over) {
      // played in previous round therefore must maintain the prize
      DataSets.Round storage _r = round[_p.round];
      if (_p.merit[_r.launchpad-1] > 0) {
        _p.earnings = _p.merit[_r.launchpad-1].mul(_r.bounty);
      }
      for (i = 0; i < _p.merit.length; i++) {
        _p.merit[i] = 0;
      }
      for (i = _p.merit.length; i < launchpads; i++) {
        _p.merit.push(0);
      }
      _p.round   = rounds;
      _p.updated = now;
    }
    return _index;
  }

  function consumeDiscount(uint8 _rocket, uint8 _amount) internal returns (uint256) {
    require(_rocket <= rocketClasses, "Undefined rocket!");
    DataSets.Rocket storage _r = rocketSupply[_rocket];
    uint256 _cost = _r.cost;
    if (_r.discount > 0) { //check if already expired
      DataSets.Discount storage _exp = discount[_r.discount];
      if (_exp.duration > 0 && now > round[rounds].started.add(_exp.duration)) {
        _exp.valid = false;
        _r.discount = _exp.next;
      }
    }
    if (_r.discount > 0) {
      DataSets.Discount storage _d = discount[_r.discount];
      _cost = _d.cost;
      if (_d.qty > 0) {
        if (_d.qty <= _amount) {
          _d.valid = false;
          _r.discount = _d.next;
        } else {
          _d.qty = _d.qty.sub(_amount);
        }
      }
    }
    return _cost.mul(_amount);
  }

  /**
   * @dev uses the previous block hash for random generation
   */
  function getRandom(uint8 _maxRan, uint256 _salt) public view returns(uint8) {
      uint256 _genNum = uint256(keccak256(abi.encodePacked(blockhash(block.number-1), _salt)));
      return uint8(_genNum % _maxRan);
  }

  /**
    * @dev launches Rockets
    * -price and discount for n+1 rocket is same as for 1st rocket, regardless of limited discount or price tier.
    */
  function launchRocket (
    uint8 _rocket,
    uint8 _amount,
    uint8 _launchpad,
    uint256 _player // performance improvement. Let web3 find the user index
  ) external payable onlyLiveRound() isHuman(msg.sender) returns(uint8 _hits) {
    require(round[rounds].mayImpactAt > now, "Sorry it is too late!");
    require(_launchpad > 0 && _launchpad <= launchpads, "Undefined launchpad!");
    require(_amount > 0 && _amount <= launchpad[_launchpad].size,
      "Rockets need to be more than one and maximum as much as the launchpad can handle");
    uint256 _totalCost = consumeDiscount(_rocket, _amount);
    require(_totalCost <= msg.value, "Insufficient found!");
    DataSets.Rocket storage _rt    = rocketSupply[_rocket];
    require(_rt.cost.mul(_amount) >= msg.value, "We do not accept tips!");
    uint256 _pIndex = maintainPlayer(msg.sender, _player);
    DataSets.Player storage _pr    = player[_pIndex];
    DataSets.Round storage _rd     = round[rounds];
    pot = pot.add(_totalCost);
    for (uint8 i = 0; i < _amount; ++i)
      if (getRandom(100, now + i) < _rt.accuracy)
        ++_hits;
    if (_hits > 0) {
      uint256 _m               = _rt.merit.mul(_hits);
      _pr.merit[_launchpad-1]  = uint32(_pr.merit[_launchpad-1].add(_m));
      merit[_launchpad-1]      = uint32(merit[_launchpad-1].add(_m));
      _rd.mayImpactAt          = _rd.mayImpactAt.add(_rt.knockback.mul(_hits));
      _rd.hero                 = msg.sender;
      _rd.launchpad            = _launchpad;
    }
    if (_totalCost < msg.value) {
      msg.sender.transfer(msg.value.sub(_totalCost));
    }
    emit rocketLaunch(_hits, _rd.mayImpactAt);
    return _hits;
  }

  function timeTillImpact() public view returns (uint256) {
    if (round[rounds].mayImpactAt > now){
      return round[rounds].mayImpactAt.sub(now);
    } else {
      return 0;
    }
  }

  function finish(uint256 _player) public onlyOwner() onlyLiveRound() {
    require(timeTillImpact() == 0, "Not yet!");
    DataSets.Round storage _rd   = round[rounds];
    if (_rd.hero != address(0)) {
      _player                      = maintainPlayer(_rd.hero, _player);
      DataSets.Player storage _pr  = player[_player];
      hero[rounds].addr            = _rd.hero;
      _rd.merit                    = merit[_rd.launchpad-1].sub(_pr.merit[_rd.launchpad-1]);
      _rd.jackpot                  = pot.div(100).mul(prizeDist.hero);
      if (_rd.merit > 0) {
        _rd.bounty                 = pot.div(100).mul(prizeDist.bounty).div(_rd.merit);
        pot                        = pot.sub(_rd.jackpot).sub(_rd.merit.mul(_rd.bounty));
      } else {
        pot                        = pot.sub(_rd.jackpot);
      }
      _pr.merit[_rd.launchpad-1]   = 0;
      _pr.earnings                 = _rd.jackpot;
    }
    _rd.over                       = true;
    emit roundFinish(rounds, _rd.jackpot, _pr.addr);
  }

  function prizeWithdrawTo(uint256 _eth, address _to, uint256 _player) public {
    require(_to != address(0), "Address can not be zero!");
    _player                      = findPlayerIndex(msg.sender, _player);
    require(_player != 0, "Unknow player!");
    _player                      = maintainPlayer(msg.sender, _player);
    DataSets.Player storage _pr  = player[_player];
    require(_eth <= _pr.earnings, "Insufficient found!");
    if (_eth == 0) _eth = _pr.earnings; //max if unspecified
    _pr.earnings = _pr.earnings.sub(_eth);
    _to.transfer(_eth);
  }

  function setHeroName(uint16 _round, string _name) external payable {
    require(msg.sender == hero[_round].addr, "The address does not match with the hero!");
    require(10000000000000000 == msg.value, "The payment must be 0.01ETH!");
    pot              += 10000000000000000; // temporary goes to pot
    hero[_round].name = _name.nameFilter();
    emit roundHero(_round, hero[_round].name);
  }
}