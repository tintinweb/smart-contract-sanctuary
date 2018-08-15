pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts\CryptoCult.sol

contract CryptoCult is Ownable {


    struct PlayerInfo {
        bytes32 name;
        uint256 actionEnd;
        uint256 flightEnd;

        uint16 currentCity;
        uint8[] lastActions;
        uint16[] lastCities;
        uint256[] lastRates;
        uint256 globalActionIndex;
    }

    struct ActionInfo {
        bytes32 name;
        bytes32 actionString;
        string desc;
        uint256 power;
        bool up;
        uint256 duration;
        uint256 cooldown;
        uint256 reward;
        uint256 penalty;
        bytes32 button;
    }

    struct CityInfo {
        bytes32 name;
        uint256 posX;
        uint256 posY;
    }

    struct FlightInfo {
        uint256 duration;
        uint256 cost;
    }

    event PriceChanged(uint256 userId, int256 change, uint256 value);
    event PlayerAction(uint256 userId, uint8 action, uint16 city);
    event PlayerFlight(uint256 userId, uint16 from, uint16 to);
    event PlayerScoreUpdate(uint256 userId, uint256 score);
    event PlayerAdded(address player, uint256 userId);
    event Sent(address indexed payee, uint256 amount, uint256 balance);

    constructor() public {
        playerAddresses.push(address(0));
        scores.push(0);
        cETHPrice = 500;
    }

    modifier ownerOrSender(address addr)
    {
        require(addr != address(0));
        require (addr == msg.sender || msg.sender == owner);
        _;
    }

    modifier ownerOrPlayer(uint256 playerId)
    {
        require(playerId > 0);
        require (playerAddresses[playerId] == msg.sender || msg.sender == owner);
        _;
    }

    mapping(uint256 => PlayerInfo) players;
    mapping(address => uint256) playerIds;
    address[] playerAddresses;
    // userId => city => action => cooldown
    mapping(uint256 => mapping (uint16 => mapping(uint16 => uint256))) cooldowns;

    // global vars
    mapping(uint8 => ActionInfo) actions;
    mapping(uint16 => CityInfo) cities;
    mapping(uint16 => mapping(uint16 => FlightInfo)) flights;
    mapping(uint16 => uint16[]) flightConnections;
    uint256[] scores;

    uint8[] actionHistory;

    uint16 _citiesCount;
    uint8 _actionsCount;



    uint256 cETHPrice;

    // Player actions

    function innerPlayerFlight(uint256 playerId, uint16 to, uint256 duration) private
    {

        require(duration > 0);
        require(playerId > 0);

        require(players[playerId].flightEnd <= block.timestamp);
        require(players[playerId].actionEnd <= block.timestamp);

        uint16 from = players[playerId].currentCity;
        players[playerId].currentCity = to;
        players[playerId].flightEnd = block.timestamp + duration;

        emit PlayerFlight(playerId, from, to);
    }

    function registerPlayer(address player, bytes32 name) public ownerOrSender(player)
    {
        uint256 playerId = playerIds[player];
        require(playerId == 0);

        playerId = playerAddresses.length;
        playerIds[player] = playerId;
        playerAddresses.push(player);
        scores.push(0);
        players[playerId].name = name;
        players[playerId].actionEnd = 0;
        players[playerId].flightEnd = 0;
        players[playerId].currentCity = 1;

        /*
        uint16[] lastActions;
        uint16[] lastCities;
        uint256[] lastRates;*/

        emit PlayerAdded(player, playerId);

    }
    function getPlayerId(address player) public view returns (uint256)
    {
        return playerIds[player];
    }

    function getPlayers() public view returns (address[])
    {
        return playerAddresses;
    }

    function getCooldown(uint256 userId, uint16 cityId, uint8 actionId) public view returns (uint256)
    {
        return cooldowns[userId][cityId][actionId];
    }

    function playersCount() public view returns (uint256)
    {
        return playerAddresses.length-1;
    }

    function actionsCount() public view returns (uint256)
    {
        return _actionsCount;
    }

    function citiesCount() public view returns (uint256)
    {
        return _citiesCount;
    }

    function playerFlight(uint256 playerId, uint16 to) public ownerOrPlayer(playerId)
    {
        uint16 from = players[playerId].currentCity;
        uint256 duration = flights[from][to].duration;
        innerPlayerFlight(playerId, to, duration);
    }

    function addRate(uint256 playerId, uint256 change) private
    {
        cETHPrice += change;
        emit PriceChanged(playerId, int256(change), cETHPrice);
    }

    function removeRate(uint256 playerId, uint256 change) private
    {
        uint256 value = change > cETHPrice ? cETHPrice : change;
        cETHPrice -= value;

        emit PriceChanged(playerId, -int256(change), cETHPrice);
    }

    function addScore(uint256 playerId, uint256 change) private
    {
        scores[playerId] += change;
        emit PlayerScoreUpdate(playerId, scores[playerId]);
    }

    function removeScore(uint256 playerId, uint256 change) private
    {
        if(change >= scores[playerId])
        {
            scores[playerId] = 0;
        }
        else
        {
            scores[playerId] -= change;
        }
        emit PlayerScoreUpdate(playerId, scores[playerId]);
    }

    function playerFastFlight(uint256 playerId, uint16 to) public payable ownerOrPlayer(playerId)
    {
        uint16 from = players[playerId].currentCity;
        FlightInfo storage info = flights[from][to];
        require(info.cost > 0);
        require(msg.value >= info.cost);

        uint256 duration = info.duration;
        innerPlayerFlight(playerId, to, duration / 10);
    }

    function getRateScore(uint256 fromIndex) public view returns (uint256, uint256)
    {
        uint256 upCount = 0;
        uint256 downCount = 0;

        for(uint256 i = fromIndex; i < actionHistory.length; i++)
        {
            ActionInfo storage action = actions[actionHistory[i]];
            if(action.up)
            {
                upCount += action.power;
            }
            else
            {
                downCount += action.power;
            }
        }

        return (upCount, downCount);
    }
    function getReward(uint playerId) public view returns (uint256, uint256)
    {
        // TODO: add formula for reward based on changes
        PlayerInfo storage player = players[playerId];
        if(player.lastActions.length == 0)
        {
            return (0, 0);
        }

        ActionInfo storage lastAction = actions[player.lastActions[player.lastActions.length - 1]];
        uint256 lastRate = player.lastRates[player.lastRates.length - 1];
        uint256 upCount;
        uint256 downCount;
        uint256 reward = 0;
        uint256 penalty = 0;
        (upCount, downCount) = getRateScore(player.globalActionIndex);
        if((cETHPrice > lastRate && lastAction.up) || (cETHPrice < lastRate && !lastAction.up))
        {
            // correct
            reward = lastAction.reward * (1 + ((lastAction.up ? (downCount / upCount) : (upCount / downCount) )));
            if(player.lastActions.length > 1)
            {
                if(player.lastCities[player.lastCities.length - 1] == player.lastCities[player.lastCities.length - 2])
                {
                    reward = (reward * 80) / 100;
                }

                ActionInfo storage prevAction = actions[player.lastActions[player.lastActions.length - 2]];
                if(lastAction.up == prevAction.up)
                {
                    reward = (reward * 75) / 100;
                }
            }
        }
        else if((cETHPrice > lastRate && !lastAction.up) || (cETHPrice < lastRate && lastAction.up))
        {
            // wrong
            penalty = lastAction.penalty * (1 + ((lastAction.up ? (upCount / downCount) : (downCount / upCount))));
        }

        return (reward, penalty);
    }
    function playerAction(uint256 playerId, uint8 actionId) public ownerOrPlayer(playerId)
    {
        PlayerInfo storage player = players[playerId];
        require(player.flightEnd <= block.timestamp); // not on flight
        require(player.actionEnd <= block.timestamp); // not on action
        require(cooldowns[playerId][player.currentCity][actionId] <= block.timestamp); // action not on cooldown
        require(actionId > 0);

        ActionInfo storage action = actions[actionId];
        require(action.duration > 0);

        // Previous action results
        uint256 reward = 0;
        uint256 penalty = 0;

        (reward, penalty) = getReward(playerId);

        if(reward > 0)
        {
            addScore(playerId, reward);
        }

        if(penalty > 0)
        {
            removeScore(playerId, penalty);
        }

        player.actionEnd = block.timestamp + action.duration; // set action end time
        cooldowns[playerId][player.currentCity][actionId] = block.timestamp + action.cooldown; // set action cooldown

        player.lastActions.push(actionId);
        player.lastCities.push(player.currentCity);
        player.lastRates.push(cETHPrice);
        player.globalActionIndex = actionHistory.length;

        actionHistory.push(actionId);


        if(action.up)
        {
            addRate(playerId, action.power);
        }
        else
        {
            removeRate(playerId, action.power);
        }
        emit PlayerAction(playerId, actionId, player.currentCity);
    }

    ///////////////////////////////////////////////////////
    // Admin
    ///////////////////////////////////////////////////////

    function addAction(bytes32 name, bytes32 actionString, string desc, uint256 power, bool up, uint256 duration, uint256 cooldown, uint256 reward, uint256 penalty, bytes32 button) public onlyOwner
    {
        _actionsCount++;
        uint8 id = _actionsCount;
        actions[id] = ActionInfo(name, actionString, desc, power, up, duration, cooldown, reward, penalty, button);

    }

    function addCities(bytes32[] names, uint256[] posXs, uint256[] posYs) public onlyOwner
    {
        require(names.length == posXs.length);
        require(posXs.length == posYs.length);

        for(uint i = 0; i < names.length; i++)
        {
            _citiesCount++;
            uint16 id = _citiesCount;
            cities[id] = CityInfo(names[i], posXs[i], posYs[i]);
        }
    }

    function addCity(bytes32 name, uint256 posX, uint256 posY) public onlyOwner
    {
        _citiesCount++;
        uint16 id = _citiesCount;
        cities[id] = CityInfo(name, posX, posY);

    }

    function setFlight(uint16 id1, uint16 id2, uint256 duration, uint256 cost) public onlyOwner
    {
        flights[id1][id2] = FlightInfo(duration, cost);
        flightConnections[id1].push(id2);
    }

    function setFlights(uint16[] ids1, uint16[] ids2, uint256[] durations, uint256[] costs) public onlyOwner
    {

        require(ids1.length == ids2.length);
        require(durations.length == costs.length);
        require(durations.length == ids1.length);

        for(uint i = 0; i < ids1.length; i++)
        {

            flights[ids1[i]][ids2[i]] = FlightInfo(durations[i], costs[i]);
            flightConnections[ids1[i]].push(ids2[i]);
        }
    }

    ///////////////////////////////////////////////////////

    function getPrice() public view returns (uint256)
    {
        return cETHPrice;
    }

    function getFlightConnections(uint16 cityId) public view returns (uint16[])
    {
        return flightConnections[cityId];
    }
    function getPlayer(uint256 playerId) public view returns (bytes32, uint256, uint256, uint16)
    {
        PlayerInfo storage player = players[playerId];
        return (player.name, player.actionEnd, player.flightEnd, player.currentCity);
    }

    function getCity(uint16 cityId) public view returns (bytes32, uint256, uint256)
    {
        CityInfo storage info = cities[cityId];
        return  (info.name, info.posX, info.posY);
    }

    function getAction(uint8 actionId) public view returns (bytes32, bytes32, string, uint256, bool, uint256,uint256, uint256,uint256, bytes32)
    {

        ActionInfo storage action = actions[actionId];
        return  (action.name, action.actionString, action.desc, action.power, action.up, action.duration, action.cooldown, action.reward, action.penalty, action.button);
    }

    function getFlight(uint16 id1, uint16 id2) public view returns (uint256, uint256)
    {
        FlightInfo storage flightInfo = flights[id1][id2];
        return (flightInfo.duration, flightInfo.cost);
    }

    function getScores() public view returns (uint256[])
    {
        return scores;
    }


    /**
   * @dev wallet can send funds
   */
    function sendTo(address _payee, uint256 _amount) public onlyOwner {
        require(_payee != address(0) && _payee != address(this));
        require(_amount > 0);
        _payee.transfer(_amount);
        emit Sent(_payee, _amount, address(this).balance);
    }
}