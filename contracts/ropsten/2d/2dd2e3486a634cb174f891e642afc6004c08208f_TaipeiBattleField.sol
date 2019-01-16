pragma solidity ^0.4.25;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
library SafeMath32 {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint32 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint32 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    require(b <= a);
    uint32 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint32 a, uint32 b) internal pure returns (uint32) {
    require(b != 0);
    return a % b;
  }
}

library SafeMath64 {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint64 a, uint64 b) internal pure returns (uint64) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint64 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint64 a, uint64 b) internal pure returns (uint64) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint64 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint64 a, uint64 b) internal pure returns (uint64) {
    require(b <= a);
    uint64 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint64 a, uint64 b) internal pure returns (uint64) {
    uint64 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint64 a, uint64 b) internal pure returns (uint64) {
    require(b != 0);
    return a % b;
  }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint a, uint b) internal pure returns (uint) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint a, uint b) internal pure returns (uint) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    uint c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint a, uint b) internal pure returns (uint) {
    require(b != 0);
    return a % b;
  }
}

contract BattleFieldBasic is Ownable{
    using SafeMath32 for uint32;
    using SafeMath64 for uint64;
    using SafeMath for uint;

    mapping (address => uint32) public playerIDMap;
    mapping (uint32 => Player) public playerMap;  // playerID => Player, key range: 10 < id < uint32 max
    mapping (uint8 => Land) public landMap;  // key range: 0 <= id < landCount
    mapping (uint8 => uint64) public leagueContributionMap;
    mapping (uint8 => bool) public winningLeagueMap;

    uint32 public currentPlayerIndex = 10;
    uint8 internal landCount = 36;
    uint8 internal leagueCount = 3;

    uint8 public profitPercentage = 2;
    uint8 internal nobodyID = 0;

    uint64 public winningContribution = 0;
    bool public ownerTransfered = false;

    uint public winningUintValue = 0;
    uint public ownerValue = 0;

    // Minion price: 0.000001 eth for a minion
    uint public minionFee = 1 szabo;
    uint public minimumMinionFee = 1000 szabo;  // 0.001 ether
    uint public moveFee = 1000 szabo;  // 0.001 ether
    uint public changeSloganFee = 10000 szabo;  // 0.010 ether

    // Deadline of the game.
    //uint public lastDay = 1543060800;  // 2018/11/24 12:00 UTC+0

    uint public lastDay = 1542117600;

    struct Defender {
        uint32 playerID;
        uint64 minions;
        uint32 prevID;
        uint32 nextID;
        uint32 playerPrevID;
        uint32 playerNextID;
    }

    struct Player {
        bool transfered;
        uint8 leagueID;
        uint64 contribution;
        string name;
        mapping (uint8 => uint64) minionMap;  // land id => counts
    }

    struct Land {
        uint8 ID;
        uint8 leagueID;
        uint8 weight;  // 1 ~ 100

        uint32 firstDefenderID;
        uint32 lastDefenderID;
        bool stronghold;

        uint8[] neighborsID;
        string slogan;
        mapping(uint32 => uint32) playerFirstDefenderID;  // player id => Defender address
        mapping(uint32 => Defender) defenderMap;  // Defender address => Defender
    }

    event PlayerRegister(
        address indexed playerAddress,
        uint32 playerID,
        string name,
        uint8 leagueID
    );

    event PlayerBuy(
        uint32 indexed playerID,
        uint8 landID,
        uint64 minions
    );

    event PlayerMove(
        uint32 indexed playerID,
        uint8 fromLandID,
        uint8 toLandID,
        uint64 minions
    );

    event PlayerWithdraw(
        uint32 indexed playerID,
        uint value
    );

    function setWinner() internal {
        if (winningContribution != 0) {
            return;
        }

        uint8 i;
        uint64 max = 0;
        for (i = 1; i <= leagueCount; i++) {
            if (leagueContributionMap[i] > max) {
                max = leagueContributionMap[i];
            }
        }

        for (i = 1; i <= leagueCount; i++) {
            if (leagueContributionMap[i] == max) {
                winningLeagueMap[i] = true;
                winningContribution = winningContribution.add(max);
            }
        }
        uint playerTotalValue = address(this).balance.div(100).mul(uint(100).sub(profitPercentage));
        winningUintValue = playerTotalValue.div(winningContribution);

        playerTotalValue = winningUintValue.mul(winningContribution);
        ownerValue = address(this).balance.sub(playerTotalValue);
    }

    modifier gameNotOver() {
        require(now < lastDay);
        _;
    }

    modifier gameOver() {
        require(now >= lastDay);
        setWinner();
        _;
    }

    modifier registered() {
        require(playerIDMap[msg.sender] != nobodyID);
        _;
    }

    function _addMinions(uint32 playerID, uint8 landID, uint64 minions) internal {
        if (minions == 0) {
            return;
        }

        Player storage player = playerMap[playerID];
        Land storage land = landMap[landID];

        uint32 thisDefenderID = land.lastDefenderID.add(1);
        Defender memory defender = Defender({
            playerID: playerID,
            minions: minions,
            prevID: thisDefenderID.sub(1),
            nextID: nobodyID,
            playerPrevID: thisDefenderID,
            playerNextID: thisDefenderID
        });

        uint32 playerFirstDefenderID = land.playerFirstDefenderID[playerID];

        if (playerFirstDefenderID == nobodyID) {
            land.playerFirstDefenderID[playerID] = thisDefenderID;
        } else {
            uint32 playerLastDefenderID = land.defenderMap[playerFirstDefenderID].playerPrevID;
            defender.playerPrevID = playerLastDefenderID;
            defender.playerNextID = playerFirstDefenderID;
            land.defenderMap[playerLastDefenderID].playerNextID = thisDefenderID;
            land.defenderMap[playerFirstDefenderID].playerPrevID = thisDefenderID;
        }

        if (thisDefenderID == 1){
            land.firstDefenderID = thisDefenderID;
        }
        else {
            land.defenderMap[thisDefenderID.sub(1)].nextID = thisDefenderID;
        }

        player.minionMap[landID] = player.minionMap[landID].add(minions);
        land.defenderMap[thisDefenderID] = defender;
        land.lastDefenderID = land.lastDefenderID.add(1);
    }

    function _deleteMinion(uint32 playerID, uint8 landID, uint64 minions) internal {
        Land storage land = landMap[landID];

        uint32 thisDefenderID;
        while (minions > 0) {
            thisDefenderID = land.playerFirstDefenderID[playerID];
            require(thisDefenderID != nobodyID);

            Defender storage defender = land.defenderMap[thisDefenderID];
            if (defender.minions > minions) {
                defender.minions = defender.minions.sub(minions);
                break;
            }
            minions = minions.sub(defender.minions);
            _deleteDefender(thisDefenderID, landID);
        }
    }

    function _deleteDefender(uint32 thisDefenderID, uint8 landID) internal {
        Land storage land = landMap[landID];
        Defender memory defender = land.defenderMap[thisDefenderID];
        uint32 thisPlayerID = defender.playerID;

        if (defender.playerNextID == thisDefenderID) {
            land.playerFirstDefenderID[thisPlayerID] = nobodyID;
        }
        else {
            land.defenderMap[defender.playerPrevID].playerNextID = defender.playerNextID;
            land.defenderMap[defender.playerNextID].playerPrevID = defender.playerPrevID;
            land.playerFirstDefenderID[thisPlayerID] = defender.playerNextID;
        }

        if (defender.prevID != nobodyID) {
            land.defenderMap[defender.prevID].nextID = defender.nextID;
        }
        if (defender.nextID != nobodyID) {
            land.defenderMap[defender.nextID].prevID = defender.prevID;
        }

        if (land.firstDefenderID == thisDefenderID) {
            land.firstDefenderID = defender.nextID;
        }
        if (land.lastDefenderID == thisDefenderID) {
            land.lastDefenderID = defender.prevID;
        }

        delete land.defenderMap[thisDefenderID];
    }

    function _calculateContribution(uint32 playerID, uint8 landID, uint64 minionsCont) internal {
        Player storage player = playerMap[playerID];
        uint8 weight = landMap[landID].weight;
        uint64 contribution = minionsCont.mul(weight);

        player.contribution = player.contribution.add(contribution);
        leagueContributionMap[player.leagueID] = leagueContributionMap[player.leagueID].add(contribution);
    }

    function _isValidLandID(uint8 landID) internal view returns (bool) {
        if (landID >= 0 && landID < landCount) {
            return true;
        }
        return false;
    }

    function _isMyLeague(uint8 landID) internal view returns (bool) {
        if (landMap[landID].leagueID == playerMap[playerIDMap[msg.sender]].leagueID) {
            return true; 
        }
        return false;
    }
}

contract BattleFieldRegister is BattleFieldBasic {
    function register(string name, uint8 leagueID) external gameNotOver validLeagueID(leagueID) onceRegister() {
        playerMap[currentPlayerIndex] = Player(false, leagueID, 0, name);
        playerIDMap[msg.sender] = currentPlayerIndex;

        emit PlayerRegister(msg.sender, currentPlayerIndex, name, leagueID);
        currentPlayerIndex = currentPlayerIndex.add(1);
    }

    modifier validLeagueID(uint8 leagueID){
        require(leagueID > 0 && leagueID <= leagueCount);
        _;
    }

    modifier onceRegister(){
        require(playerIDMap[msg.sender] == nobodyID);
        _;
    }
}

contract BattleFieldBuy is BattleFieldBasic {
    function buyMinions(uint8 landID) external payable registered gameNotOver {
        require(msg.value >= minimumMinionFee);
        require(_isValidLandID(landID));
        require(_isMyLeague(landID));

        uint64 minions = _getMinions(msg.value);
        uint32 playerID = playerIDMap[msg.sender];
        _addMinions(playerID, landID, minions);
        _calculateContribution(playerID, landID, minions);
        emit PlayerBuy(playerID, landID, minions);
    }

    function addSlogan(uint8 landID, string newSlogan) external payable registered gameNotOver {
        require(msg.value >= changeSloganFee);
        require(_isValidLandID(landID));
        require(_isMyLeague(landID));
        landMap[landID].slogan = newSlogan;
    }

    function _getMinions(uint value) private view returns (uint64) {
        return uint64(value / minionFee);
    }
}

contract BattleFieldMove is BattleFieldBasic {
    function moveMinions(uint8 fromLandID, uint8 toLandID, uint32 minions) external payable registered gameNotOver {
        require(msg.value >= moveFee);
        require(_isValidLandID(fromLandID) && _isValidLandID(toLandID) && fromLandID != toLandID);
        require(_isMyLeague(fromLandID));
        require(_isNeighbor(fromLandID, toLandID));

        uint32 playerID = playerIDMap[msg.sender];
        Player storage player = playerMap[playerID];

        require(player.minionMap[fromLandID] >= minions);
        player.minionMap[fromLandID] = player.minionMap[fromLandID].sub(minions);
        _deleteMinion(playerID, fromLandID, minions);

        // move
        if (landMap[toLandID].leagueID == player.leagueID) {
            _addMinions(playerID, toLandID, minions);
        // attack
        } else {
            uint64 remainMinions = _attack(playerID, toLandID, minions);
            if (remainMinions > 0) {
                _addMinions(playerID, fromLandID, remainMinions);
            }
        }
        emit PlayerMove(playerID, fromLandID, toLandID, minions);
    }

    function _isNeighbor(uint8 fromLandID, uint8 toLandID) internal view returns (bool) {
        Land memory fromLand = landMap[fromLandID];
        for (uint8 i = 0; i < fromLand.neighborsID.length; i++) {
            if (fromLand.neighborsID[i] == toLandID) {
                return true;
            }
        }
        return false;
    }

    function _attack(uint32 playerID, uint8 landID, uint64 minions) internal returns (uint64) {
        uint8 leagueID = playerMap[playerID].leagueID;
        Land storage land = landMap[landID];

        if (land.leagueID == nobodyID) {
            land.leagueID = leagueID;
            _addMinions(playerID, landID, minions);
            return 0;
        }

        uint32 thisDefenderID;
        bool crash = false;
        while (minions > 0) {
            thisDefenderID = land.firstDefenderID;
            if (thisDefenderID == nobodyID) {
                crash = true;
                break;
            }

            Defender storage defender = land.defenderMap[thisDefenderID];

            if (defender.minions > minions) {
                defender.minions = defender.minions.sub(minions);
                _calculateContribution(playerID, landID, minions);

                playerMap[defender.playerID].minionMap[landID] = playerMap[defender.playerID].minionMap[landID].sub(minions);
                _calculateContribution(defender.playerID, landID, minions);
                return 0;
            }

            minions = minions.sub(defender.minions);
            _calculateContribution(playerID, landID, defender.minions);

            playerMap[defender.playerID].minionMap[landID] = playerMap[defender.playerID].minionMap[landID].sub(defender.minions);
            _calculateContribution(defender.playerID, landID, defender.minions);

            _deleteDefender(thisDefenderID, landID);
        }

        if (crash && !land.stronghold) {
            require(minions > 0);
            land.leagueID = leagueID;
            _addMinions(playerID, landID, minions);
            return 0;
        }
        return minions;
    }
}

contract TaipeiBattleField is BattleFieldRegister, BattleFieldBuy, BattleFieldMove {
    function withdraw() external registered gameOver {
        uint32 playerID = playerIDMap[msg.sender];
        Player storage player = playerMap[playerID];

        if (!winningLeagueMap[player.leagueID] || player.transfered) {
            revert("not win or transfered");
        }
        player.transfered = true;
        uint value = winningUintValue.mul(player.contribution);
        msg.sender.transfer(value);
        emit PlayerWithdraw(playerID, value);
    }

    function ownerWithdraw() external onlyOwner gameOver {
        if (ownerTransfered) {
            revert("ownerTransfered != false");
        }
        ownerTransfered = true;
        owner().transfer(ownerValue);
    }

    function setLand(uint8 ID, uint8 leagueID, uint8 weight, bool stronghold, uint8[] neighborsID) external onlyOwner {
        landMap[ID] = Land({
            ID: ID,
            leagueID: leagueID,
            weight: weight,
            stronghold: stronghold,
            neighborsID: neighborsID,
            slogan: "",
            firstDefenderID: 0,
            lastDefenderID: 0
        });
    }

    function getLandDefender(uint8 landID, uint32 defenderID) view external returns (uint32, uint64, uint32, uint32, uint32, uint32) {
        require(_isValidLandID(landID));
        Defender memory d = landMap[landID].defenderMap[defenderID];
        return (d.playerID, d.minions, d.prevID, d.nextID, d.playerPrevID, d.playerNextID);
    }

    function getLandplayerFirstDefenderID(uint8 landID, uint32 playerID) view external returns (uint32) {
        require(_isValidLandID(landID));
        return landMap[landID].playerFirstDefenderID[playerID];
    }

    function getPlayerMinions(uint32 playerID, uint8 landID) view external returns (uint64) {
        require(_isValidLandID(landID));
        return playerMap[playerID].minionMap[landID];
    }
}